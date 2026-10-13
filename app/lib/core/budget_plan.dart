import 'models.dart';

enum BudgetSource { fixed, stepPlan, manual }

class MonthlyBudget {
  const MonthlyBudget(this.month, this.amount, this.source);

  final YearMonth month;
  final int amount;
  final BudgetSource source;
}

int _roundTo10k(num v) => (v / 10000).round() * 10000;

/// 단계적 목표(Spec F4): 시작 금액에서 최종 목표까지 같은 폭씩 내리고 1만 원 단위로 반올림한다.
/// 마지막 달은 최종 목표 그대로다. 그 이후 달은 [budgetFor]가 마지막 값을 이어 쓴다.
List<MonthlyBudget> stepPlan({
  required YearMonth start,
  required int startAmount,
  required int targetAmount,
  required int months,
}) {
  if (months < 2) {
    return [MonthlyBudget(start, targetAmount, BudgetSource.stepPlan)];
  }
  return [
    for (var k = 0; k < months; k++)
      MonthlyBudget(
        start.plus(k),
        k == months - 1
            ? targetAmount
            : _roundTo10k(startAmount + (targetAmount - startAmount) * k / (months - 1)),
        BudgetSource.stepPlan,
      ),
  ];
}

/// 단계적 목표의 시작 금액 기본값: 최근 월평균(특이 지출 제외)을 1만 원 단위로 내림.
int defaultStartAmount(List<int> recentMonthlyTotals) {
  if (recentMonthlyTotals.isEmpty) return 0;
  final avg = recentMonthlyTotals.reduce((a, b) => a + b) / recentMonthlyTotals.length;
  return avg ~/ 10000 * 10000;
}

/// 특정 달만 직접 고친다. 나머지 계획은 그대로 둔다.
List<MonthlyBudget> overrideMonth(List<MonthlyBudget> plan, YearMonth month, int amount) => [
      for (final b in plan)
        b.month == month ? MonthlyBudget(month, amount, BudgetSource.manual) : b,
    ];

/// 그 달 예산. 행이 없으면 그 이전 가장 최근 달의 값을 이어 쓴다(Spec 2.1 budgets).
int? budgetFor(List<MonthlyBudget> budgets, YearMonth month) {
  MonthlyBudget? best;
  for (final b in budgets) {
    if (b.month.compareTo(month) <= 0 && (best == null || b.month.compareTo(best.month) > 0)) {
      best = b;
    }
  }
  return best?.amount;
}
