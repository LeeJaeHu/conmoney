import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/budget_engine.dart';
import 'core/budget_plan.dart';
import 'core/models.dart';
import 'data/database.dart';
import 'data/ledger_repository.dart';
import 'data/recurring_repository.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final repositoryProvider = Provider<LedgerRepository>((ref) => LedgerRepository(ref.watch(databaseProvider)));

/// 테스트에서 날짜를 고정할 수 있게 현재 시각도 provider로 둔다.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// 단계적 목표의 현재 단계(예: 1/3단계).
class PlanStep {
  const PlanStep(this.index, this.total, this.targetAmount);

  final int index;
  final int total;
  final int targetAmount;
}

class HomeData {
  const HomeData({
    required this.month,
    required this.status,
    required this.upcoming,
    required this.unconfirmed,
    this.planStep,
    this.nextBudget,
    this.recurringSuggestions = 0,
  });

  final YearMonth month;

  /// 이번 달 예산이 없으면 null.
  final BudgetStatus? status;
  final List<(RecurringItem, DateTime, int)> upcoming;
  final int unconfirmed;
  final PlanStep? planStep;

  /// 이번 달 예산은 없지만 다음 달부터 시작하는 계획이 있으면 그 달과 금액.
  final MonthlyBudget? nextBudget;

  /// 등록 안 된 정기 지출 후보 수(F5 자동 탐지).
  final int recurringSuggestions;
}

final homeProvider = FutureProvider<HomeData>((ref) async {
  final repo = ref.watch(repositoryProvider);
  final now = ref.watch(clockProvider)();
  final month = YearMonth.of(now);

  final budgets = await repo.budgets();
  final budget = budgetFor(budgets, month);
  final engine = BudgetEngine(await repo.loadLedger());

  PlanStep? step;
  final plan = await repo.latestPlan();
  if (plan != null && plan.mode == 'STEP') {
    final start = YearMonth.parse(plan.startMonth);
    final index = (month.year * 12 + month.month) - (start.year * 12 + start.month) + 1;
    if (index >= 1 && index <= plan.months) step = PlanStep(index, plan.months, plan.targetAmount);
  }

  final future = budgets.where((b) => b.month.compareTo(month) > 0).toList()
    ..sort((a, b) => a.month.compareTo(b.month));

  return HomeData(
    month: month,
    status: budget == null ? null : engine.status(now, budget),
    upcoming: await repo.upcomingRecurring(now),
    unconfirmed: await repo.unconfirmedCount(),
    planStep: step,
    nextBudget: budget == null && future.isNotEmpty ? future.first : null,
    recurringSuggestions: (await RecurringRepository(ref.watch(databaseProvider)).suggestions(now)).length,
  );
});
