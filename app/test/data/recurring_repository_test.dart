import 'dart:io';

import 'package:conmoney/core/budget_engine.dart';
import 'package:conmoney/core/models.dart';
import 'package:conmoney/data/csv_import.dart';
import 'package:conmoney/data/database.dart';
import 'package:conmoney/data/ledger_repository.dart';
import 'package:conmoney/data/recurring_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

ImportRow row(String merchant, DateTime date, int amount) => ImportRow(
  date: date,
  time: '',
  card: '현대 ZERO',
  merchant: merchant,
  merchantRaw: merchant,
  amount: amount,
  installmentMonths: 1,
  isForeign: false,
  currency: 'KRW',
  originalAmount: '',
  cancelled: false,
  category: '',
  isUnusual: false,
  source: 'test',
);

void main() {
  late AppDatabase db;
  late RecurringRepository recurring;
  late LedgerRepository ledger;
  final now = DateTime(2026, 10, 13, 12);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    recurring = RecurringRepository(db);
    ledger = LedgerRepository(db);
    await importTransactions(db, [
      for (final m in [8, 9, 10]) row('KT 휴대폰', DateTime(2026, m, 12), 38000),
      for (final m in [8, 9]) row('넷플릭스', DateTime(2026, m, 20), 13500),
      row('배달의민족', DateTime(2026, 9, 3), 18000),
      row('배달의민족', DateTime(2026, 10, 5), 21000),
    ]);
  });
  tearDown(() => db.close());

  test('제안 → 등록하면 지난 결제와 연결되고, 이번 달 낸 것은 F에서 빠진다', () async {
    final s = await recurring.suggestions(now);
    expect([for (final x in s) x.merchant], ['KT 휴대폰', '넷플릭스']);

    for (final x in s) {
      await recurring.addSuggestion(x);
    }
    expect(await recurring.suggestions(now), isEmpty);

    final engine = BudgetEngine(await ledger.loadLedger());
    final st = engine.status(now, 500000);
    expect(st.upcomingFixed, 13500); // KT는 10/12에 냈고 넷플릭스는 10/20 예정
    // KT 결제는 정기 지출로 연결돼 평소 패턴 P에서 빠진다
    expect(engine.varSpend(const YearMonth(2026, 9), 1, 30), 18000);

    final view = await recurring.view(now);
    expect(view.map((v) => v.state), [MonthState.paid, MonthState.upcoming]);
    expect(view.first.paidAmount, 38000);

    // 예정일 + 3일이 지나면 "아직 결제 안 됨"
    final late = await recurring.view(DateTime(2026, 10, 24));
    expect(late.last.state, MonthState.overdue);
  });

  test('relink는 여러 번 실행해도 연결이 늘지 않는다', () async {
    for (final x in await recurring.suggestions(now)) {
      await recurring.addSuggestion(x);
    }
    await recurring.relink();
    await recurring.relink(reset: true);
    expect(await db.select(db.recurringMatches).get(), hasLength(5)); // KT 3 + 넷플릭스 2
  });

  test('[아니요]한 가맹점은 다시 제안하지 않고, [이번 달 없음]은 F에서 뺀다', () async {
    await recurring.dismiss('넷플릭스');
    final s = await recurring.suggestions(now);
    expect([for (final x in s) x.merchant], ['KT 휴대폰']);

    final id = await recurring.add(name: '넷플릭스', amount: 13500, dueDay: 20, isEstimate: false);
    await recurring.skipMonth(id, DateTime(2026, 10, 25));
    final st = BudgetEngine(await ledger.loadLedger()).status(DateTime(2026, 10, 25), 500000);
    expect(st.upcomingFixed, 0);
  });

  test('E5 교통비 예약 제안 → 예약하면 승차 결제가 모두 연결되고 남은 예약분이 F에 들어간다', () async {
    final rides = [
      for (final day in [1, 2, 5, 6, 7, 8, 12, 13]) ...[
        row('후불교통 버스', DateTime(2026, 10, day), 1500),
        row('후불교통 지하철', DateTime(2026, 10, day), 1600),
      ],
    ];
    await importTransactions(db, rides);
    final e = (await recurring.envelopeSuggestions(now)).single;
    expect(e.name, '교통(후불)');
    expect(e.amount, 69000);

    await recurring.addEnvelope(e);
    expect(await recurring.envelopeSuggestions(now), isEmpty);
    final linked = (await db.select(db.transactions).get()).where((t) => t.merchantNorm.startsWith('후불'));
    expect(linked.every((t) => t.recurringItemId != null), isTrue);

    final view = (await recurring.view(now)).firstWhere((v) => v.item.isEnvelope);
    expect(view.state, MonthState.envelope);
    expect(view.envelopeUsed, 8 * 3100);
    expect(view.envelopeRemaining, 69000 - 8 * 3100);

    final st = BudgetEngine(await ledger.loadLedger()).status(now, 500000);
    expect(st.spentToday, 0); // 오늘(10/13) 탄 3,100원은 예약분 안
    expect(st.upcomingFixed, 69000 - 8 * 3100);
    await recurring.relink(reset: true);
    expect(BudgetEngine(await ledger.loadLedger()).status(now, 500000).upcomingFixed, 69000 - 8 * 3100);
  });

  final real = File('../data/transactions_v3.csv');
  test('실데이터: 제안을 모두 등록하면 10/13 기준 F와 하루 금액', () async {
    await db.delete(db.transactions).go();
    await importTransactions(db, parseTransactionsCsv(real.readAsStringSync()));
    for (final x in await recurring.suggestions(now)) {
      await recurring.addSuggestion(x);
    }
    for (final e in await recurring.envelopeSuggestions(now)) {
      await recurring.addEnvelope(e);
    }
    final engine = BudgetEngine(await ledger.loadLedger());
    final st = engine.status(now, 540000);
    final p = engine.pattern(now);
    // ignore: avoid_print
    print(
      'F=${st.upcomingFixed} R=${st.remaining} 하루=${st.dailyBase} P=${p.amount} '
      '예정: ${[for (final v in await recurring.view(now))
        if (v.state != MonthState.paid) '${v.due.day}일 ${v.item.name}']}',
    );
    expect(st.upcomingFixed, greaterThan(0));
  }, skip: real.existsSync() ? false : 'data/transactions_v3.csv 없음');
}
