// 지출 분석 그래프 계산(10/16): 이번 달 페이스, 카테고리 평소 대비
import 'package:conmoney/core/analysis.dart';
import 'package:conmoney/core/budget_engine.dart';
import 'package:conmoney/core/category_summary.dart';
import 'package:conmoney/core/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 7~9월: 20일 식비 10만·통신 5만, 25일 쇼핑 6만. 10월: 3일 쇼핑 20만, 5일 식비 30만
  final rows = <(int, DateTime, int, String)>[
    for (final m in [7, 8, 9]) ...[
      (m * 10 + 1, DateTime(2026, m, 20), 100000, '식비'),
      (m * 10 + 2, DateTime(2026, m, 25), 60000, '쇼핑'),
      (m * 10 + 3, DateTime(2026, m, 20), 50000, '통신'),
    ],
    (101, DateTime(2026, 10, 5), 300000, '식비'),
    (102, DateTime(2026, 10, 3), 200000, '쇼핑'),
  ];
  final first = DateTime(2026, 7, 1);
  final engine = BudgetEngine(Ledger(
    txns: [for (final (id, d, a, _) in rows) Txn(id: id, amount: a, date: d)],
    installments: const [],
    firstRecordDate: first,
  ));
  final items = [
    for (final (id, d, a, c) in rows) SpendItem(txnId: id, date: d, amount: a, merchant: 'x', categoryName: c),
  ];
  final now = DateTime(2026, 10, 17, 12);

  test('monthPace: 오늘까지 누적, 지난 달들 같은 날 누적 중앙값, 월말 예상 = 지금까지 + F + P', () {
    final p = monthPace(items, engine, now, 500000);
    expect(p.actual.length, 17);
    expect(p.actual[1], 0);
    expect(p.actual[2], 200000);
    expect(p.spentSoFar, 500000);
    expect(p.usual!.length, 31);
    expect(p.usual![18], 0);
    expect(p.usual![19], 150000);
    expect(p.usual![30], 210000); // 9월은 30일까지 → 말일 값을 이어 씀
    expect(p.projectedEnd, 710000);
    expect(p.projectedOver, 210000);
  });

  test('compareCategories: 이번 달 1일~오늘 vs 같은 기간 평소, 지난달 vs 그 전 달들', () {
    final c = compareCategories(items, now, first);
    expect(c.monthsUsed, 3);
    expect(c.rows.first.name, '식비');
    expect(c.rows.first.diff, 300000);
    final last = compareCategories(items, now, first, lastMonth: true);
    expect(last.monthsUsed, 2); // 7·8월(6월은 첫 기록 전)
    expect(last.total, 210000);
    expect(last.total - last.usualTotal, 0);
    expect(compareCategories(items, now, DateTime(2026, 10, 1)).monthsUsed, 0);
  });
}
