import 'dart:convert';
import 'dart:io';

import 'package:conmoney/core/agent_tools.dart';
import 'package:conmoney/core/budget_engine.dart';
import 'package:conmoney/core/models.dart';
import 'package:conmoney/data/agent_client.dart';
import 'package:conmoney/data/csv_import.dart';
import 'package:conmoney/data/database.dart';
import 'package:conmoney/data/ledger_repository.dart';
import 'package:conmoney/data/recurring_repository.dart';
import 'package:conmoney/data/spending_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  final now = DateTime(2026, 10, 2, 12);

  Future<AgentToolbox> toolbox({int? budget = 300000}) async => AgentToolbox(
    engine: BudgetEngine(await LedgerRepository(db).loadLedger()),
    budget: budget,
    items: await SpendingRepository(db).items(),
    now: now,
  );

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await importTransactions(db, parseTransactionsCsv(File('test/fixtures/sample_transactions.csv').readAsStringSync()));
    await RecurringRepository(db).add(name: '가짜통신', amount: 40000, dueDay: 12, isEstimate: false);
  });
  tearDown(() => db.close());

  test('get_budget_status: 금액마다 *_text를 붙인다', () async {
    final r = (await toolbox()).run('get_budget_status', {});
    // 10/2: S = 할부 100,000 + 1,500 + 12,000, F = 40,000
    expect(r['spent'], 113500);
    expect(r['upcoming_fixed_text'], '40,000원');
    expect(r['remaining'], 300000 - 113500 - 40000);
    expect(r['remaining_text'], '146,500원');
    expect(r['days_left'], 30);
  });

  test('simulate_purchase: 엔진 판단을 문자열로, 예산 없으면 오류 안내', () async {
    final tb = await toolbox();
    final r = tb.run('simulate_purchase', {'amount': 150000, 'date': null, 'installment_months': null});
    expect(r['verdict'], isIn(['ok', 'conditional', 'postpone']));
    expect(r['amount_text'], '150,000원');
    expect(r['remaining_after'], 146500 - 150000);
    expect(r['remaining_after_text'], '-3,500원');
    final none = (await toolbox(budget: null)).run('simulate_purchase', {'amount': 1000});
    expect(none['error'], contains('예산'));
  });

  test('get_upcoming_fixed와 get_category_summary', () async {
    final tb = await toolbox();
    final up = tb.run('get_upcoming_fixed', {'days': 14});
    expect((up['items'] as List).single, {
      'name': '가짜통신',
      'amount': 40000,
      'amount_text': '40,000원',
      'due_date': '2026-10-12',
    });
    final cat = tb.run('get_category_summary', {'period': 'last_month', 'include_unusual': false});
    expect(cat['total'], 120550 - 100000);
    expect(jsonEncode(cat), isNot(contains('가짜커피'))); // 가맹점 이름은 서버로 보내지 않는다
  });

  // 로컬 서버(server/: uvicorn app.main:app --port 8080)가 떠 있을 때만: 앱 코드 → 서버 → OpenAI 전체 흐름
  final live = Platform.environment['CONMONEY_LIVE_SERVER'];
  test(
    '실서버: 키보드 15만 원 상담이 툴 호출 → 최종 답(검증 통과)까지 간다',
    () async {
      final token = (jsonDecode(File('config/dev.json').readAsStringSync()) as Map)['CONMONEY_TOKEN'] as String;
      final client = AgentClient(baseUrl: live!, token: token);
      final tb = await toolbox();
      final items = <Map<String, Object?>>[
        {'role': 'user', 'content': '키보드 15만 원 살까?'},
      ];
      AgentReply? reply;
      for (var round = 1; round <= 5; round++) {
        reply = await client.step(items, round);
        items.addAll(reply.items);
        if (reply.status == 'final') break;
        for (final c in reply.toolCalls) {
          items.add({'type': 'function_call_output', 'call_id': c.callId, 'output': jsonEncode(tb.run(c.name, c.arguments))});
        }
      }
      // ignore: avoid_print
      print('${reply!.verdict} / ${reply.verified} / ${reply.krw}원\n${reply.text}');
      expect(reply.status, 'final');
      expect(reply.verified, isTrue);
      expect(reply.verdict, isNotNull);
      expect(await client.categorize('메가엠지씨커피 화양사거리점', ['식비', '카페·간식', '교통']), isNotNull);
    },
    skip: live == null ? 'CONMONEY_LIVE_SERVER 없음' : false,
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test('YearMonth 경계에서 정기 지출 다음 달 예정도 포함', () async {
    final tb = AgentToolbox(
      engine: BudgetEngine(
        Ledger(
          txns: const [],
          installments: const [],
          recurringItems: const [RecurringItem(id: 1, name: '월초 구독', amount: 9900, dueDay: 3)],
        ),
      ),
      budget: 100000,
      items: const [],
      now: DateTime(2026, 10, 30),
    );
    final up = tb.run('get_upcoming_fixed', {'days': 7});
    expect((up['items'] as List).single['due_date'], '2026-11-03');
  });
}
