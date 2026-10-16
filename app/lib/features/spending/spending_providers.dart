import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_providers.dart';
import '../../core/budget_engine.dart';
import '../../core/budget_plan.dart';
import '../../core/category_summary.dart';
import '../../core/models.dart';
import '../../data/spending_repository.dart';

final spendingRepositoryProvider = Provider((ref) => SpendingRepository(ref.watch(databaseProvider)));

/// 모든 지출 항목. 거래를 고치면 invalidate 한다.
final spendItemsProvider = FutureProvider<List<SpendItem>>((ref) => ref.watch(spendingRepositoryProvider).items());

/// 분석 그래프용: 계산 엔진, 이번 달 예산(없으면 null), 첫 기록일.
final analysisBaseProvider = FutureProvider<({BudgetEngine engine, int? budget, DateTime? firstRecord})>((ref) async {
  // 거래를 고치면(spendItemsProvider 무효화) 같이 다시 계산되게 묶어 둔다
  await ref.watch(spendItemsProvider.future);
  final repo = ref.watch(repositoryProvider);
  final now = ref.watch(clockProvider)();
  final ledger = await repo.loadLedger();
  final budgets = await repo.budgets();
  return (engine: BudgetEngine(ledger), budget: budgetFor(budgets, YearMonth.of(now)), firstRecord: ledger.firstRecordDate);
});
