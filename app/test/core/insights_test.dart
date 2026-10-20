// 소비 특징·아낄 수 있는 곳(10/20)
import 'package:conmoney/core/agent_tools.dart';
import 'package:conmoney/core/budget_engine.dart';
import 'package:conmoney/core/category_summary.dart';
import 'package:conmoney/core/insights.dart';
import 'package:conmoney/core/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 4~9월(완료 6개월). 식비 20·22·18·25·24·26만, 쇼핑 매달 5만, 통신 5만(줄이기 어려움),
  // 7~9월에 카페 4천 원 × 10건(밤 11시), 구독 2개(1만·5천). 8월 특이 지출 100만(제외)
  var id = 0;
  SpendItem it(int m, int d, int amount, String cat, {String merchant = 'x', int? hour, bool unusual = false}) =>
      SpendItem(txnId: ++id, date: DateTime(2026, m, d), amount: amount, merchant: merchant, categoryName: cat, hour: hour, isUnusual: unusual);
  final food = {4: 200000, 5: 220000, 6: 180000, 7: 250000, 8: 240000, 9: 260000};
  final items = [
    for (final m in [4, 5, 6, 7, 8, 9]) ...[
      it(m, 15, food[m]!, '식비'),
      it(m, 20, 50000, '쇼핑'),
      it(m, 25, 50000, '통신'),
    ],
    for (final m in [7, 8, 9]) ...[
      for (var d = 1; d <= 10; d++) it(m, d, 4000, '카페·간식', hour: 23),
      it(m, 3, 10000, '구독', merchant: '구독A'),
      it(m, 4, 5000, '구독', merchant: '구독B'),
    ],
    it(8, 10, 1000000, '게임', unusual: true),
  ];
  final engine = BudgetEngine(Ledger(
    txns: const [],
    installments: const [],
    recurringItems: const [RecurringItem(id: 1, name: '통신', amount: 50000, dueDay: 25)],
    firstRecordDate: DateTime(2026, 4, 1),
  ));
  final now = DateTime(2026, 10, 20, 12);

  test('평소 한 달·추세·카테고리·소액 결제·심야·고정비', () {
    final x = computeInsights(items, engine, now, budget: 350000);
    expect(x.months.length, 6);
    expect(x.usualMonth, 405000); // 7~9월 405·395·415만 원대의 중앙값(특이 지출 제외)
    expect(x.gapToBudget, 55000);
    expect(x.trendChange, isNotNull);
    expect(x.categories.first.name, '식비');
    expect(x.categories.first.usualMonthly, 250000);
    expect(x.categories.first.change, 50000); // 7~9월 평균 25만 − 4~6월 평균 20만
    expect(x.smallCountPerMonth, 10);
    expect(x.smallTotalPerMonth, 40000);
    expect(x.lateNightShare, 1.0); // 시각을 아는 결제(카페)는 모두 밤 11시
    expect(x.fixedMonthly, 50000);
  });

  test('아낄 수 있는 곳: 해 본 적 있는 수준·소액 절반·구독 하나, 줄이기 어려운 카테고리는 제외', () {
    final x = computeInsights(items, engine, now, budget: 350000);
    expect(x.candidates.map((c) => c.kind), [SavingKind.categoryLow, SavingKind.smallPurchases, SavingKind.subscriptions]);
    expect(x.candidates[0].category, '식비');
    expect(x.candidates[0].monthly, 70000); // 평소 25만 − 가장 적었던 6월 18만
    expect(x.candidates[1].monthly, 20000);
    expect(x.candidates[2].monthly, 7500);
    expect(x.candidates.any((c) => c.category == '통신' || c.category == '쇼핑'), isFalse);
    expect(x.savingTop3, 97500);
  });

  test('상담 툴 get_spending_insights: 금액마다 *_text, 기록 없으면 오류 안내', () {
    final tb = AgentToolbox(engine: engine, budget: 350000, items: items, now: now);
    final r = tb.run('get_spending_insights', {});
    expect(r['usual_month_text'], '405,000원');
    expect((r['saving_candidates'] as List).first, containsPair('monthly_saving_text', '70,000원'));
    expect(r['gap_after_savings'], 55000 - 97500);
    expect(r['late_night_share'], '100%');
    final empty = AgentToolbox(
      engine: BudgetEngine(Ledger(txns: const [], installments: const [], firstRecordDate: DateTime(2026, 10, 1))),
      budget: 350000,
      items: const [],
      now: now,
    ).run('get_spending_insights', {});
    expect(empty['error'], contains('기록'));
  });

  test('같은 돈을 두 번 세지 않는다: 카테고리 후보에 잡힌 카테고리의 소액 결제는 소액 후보에서 뺀다', () {
    // 카페를 4~6월에도 2만 원씩 썼다면(써 본 달 기준 최저 2만) 카페 자체가 후보가 되고 소액 후보에서는 빠진다
    final more = [...items, for (final m in [4, 5, 6]) it(m, 5, 20000, '카페·간식')];
    final x = computeInsights(more, engine, now, budget: 350000);
    final cafe = x.candidates.firstWhere((c) => c.category == '카페·간식');
    expect(cafe.monthly, 20000); // 평소 4만 − 써 본 달 최저 2만
    expect(x.candidates.where((c) => c.kind == SavingKind.smallPurchases), isEmpty);
  });

  test('기록이 덜 들어온 앞쪽 달은 빼고, 절약액은 평소의 절반까지만', () {
    // 3월에 쇼핑 1천 원만(기록이 덜 들어온 달처럼). 첫 기록일을 3월로 당긴다
    final partial = [...items, it(3, 28, 1000, '쇼핑')];
    final e = BudgetEngine(Ledger(txns: const [], installments: const [], firstRecordDate: DateTime(2026, 3, 1)));
    final x = computeInsights(partial, e, now, budget: 350000);
    expect(x.months.first.$1, const YearMonth(2026, 4)); // 3월(1천 원)은 빠짐
    // 식비 하나만 크게 줄였던 달이 있어도 평소(25만)의 절반 이하로
    final lowFood = [...items, it(6, 16, -170000, '식비')]; // 6월 식비 1만 원
    expect(computeInsights(lowFood, engine, now).candidates.first.monthly, 125000);
  });

  test('가맹점(10/20): 카테고리별 상위 가맹점 월평균, 구독 목록, 소액 결제가 잦은 곳 — 상담 툴에 이름이 실림', () {
    final named = [
      ...items,
      for (final m in [7, 8, 9]) ...[it(m, 12, 30000, '쇼핑', merchant: '가짜몰'), it(m, 13, 6000, '쇼핑', merchant: '편의점A')],
    ];
    final x = computeInsights(named, engine, now, budget: 350000);
    expect(x.merchantsByCategory['쇼핑']!.first, ('x', 50000));
    expect(x.merchantsByCategory['쇼핑']![1], ('가짜몰', 30000));
    expect(x.subscriptions, [('구독A', 10000), ('구독B', 5000)]);
    expect(x.smallTopMerchants.first.$2, 10); // 카페(x) 월 10건
    final r = AgentToolbox(engine: engine, budget: 350000, items: named, now: now).run('get_spending_insights', {});
    final subs = (r['subscriptions'] as List).cast<Map>();
    expect(subs.first['name'], '구독A');
    expect(subs.first['monthly_text'], '10,000원');
  });
}
