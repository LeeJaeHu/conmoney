// 일상 대화형 상담 툴(10/16): plan_recovery, compare_spending
import 'package:conmoney/core/agent_tools.dart';
import 'package:conmoney/core/budget_engine.dart';
import 'package:conmoney/core/category_summary.dart';
import 'package:conmoney/core/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 7~9월: 20일 식비 10만, 25일 쇼핑 6만, 20일 통신 5만(줄이기 어려움). 10월: 5일 식비 30만, 3일 쇼핑 20만
  final rows = <(int, DateTime, int, String)>[
    for (final m in [7, 8, 9]) ...[
      (m * 10 + 1, DateTime(2026, m, 20), 100000, '식비'),
      (m * 10 + 2, DateTime(2026, m, 25), 60000, '쇼핑'),
      (m * 10 + 3, DateTime(2026, m, 20), 50000, '통신'),
    ],
    (101, DateTime(2026, 10, 5), 300000, '식비'),
    (102, DateTime(2026, 10, 3), 200000, '쇼핑'),
  ];
  final engine = BudgetEngine(Ledger(
    txns: [for (final (id, d, a, _) in rows) Txn(id: id, amount: a, date: d)],
    installments: const [],
    firstRecordDate: DateTime(2026, 7, 1),
  ));
  final items = [
    for (final (id, d, a, c) in rows) SpendItem(txnId: id, date: d, amount: a, merchant: 'x', categoryName: c),
  ];
  AgentToolbox tb(int budget) =>
      AgentToolbox(engine: engine, budget: budget, items: items, now: DateTime(2026, 10, 17, 12));

  test('plan_recovery: 평소대로 쓰면 넘는 금액, 하루 줄일 금액, 줄일 곳 후보(고정성 지출 제외)', () {
    final r = tb(500000).run('plan_recovery', {});
    // P(17일~말일) = 21만, S = 50만 → 월말 예상 초과 21만, 남은 15일
    expect(r['projected_over_if_usual'], 210000);
    expect(r['days_left'], 15);
    expect(r['daily_cut_needed'], 14000);
    expect(r['daily_spend_target'], 0);
    expect(r['status'], 'recoverable');
    final c = (r['cut_candidates'] as List).cast<Map>();
    expect(c.map((e) => e['category']), ['식비', '쇼핑']);
    expect(c.first['half_saves_text'], '50,000원');
  });

  test('plan_recovery: 예산 안이면 on_track, 0원으로 버텨도 넘으면 not_recoverable', () {
    expect(tb(800000).run('plan_recovery', {})['status'], 'on_track');
    final r = tb(400000).run('plan_recovery', {});
    expect(r['status'], 'not_recoverable_this_month');
    expect(r['over_even_if_zero_spend'], 100000);
    expect(r.containsKey('daily_cut_needed'), isFalse);
  });

  test('compare_spending: 이번 달 1일~오늘을 지난 달들 같은 기간과 비교, 많이 쓴 순', () {
    final r = tb(500000).run('compare_spending', {'window': 'this_month'});
    final c = (r['categories'] as List).cast<Map>();
    expect(c.first['category'], '식비');
    expect(c.first['diff'], 300000);
    final last = tb(500000).run('compare_spending', {'window': 'last_month'});
    expect(last['total'], 210000); // 9월 전체
    expect(last['total_diff'], 0); // 7·8월과 같음
  });
}
