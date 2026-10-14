import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_providers.dart';
import '../../core/category_summary.dart';
import '../../data/spending_repository.dart';

final spendingRepositoryProvider = Provider((ref) => SpendingRepository(ref.watch(databaseProvider)));

/// 모든 지출 항목. 거래를 고치면 invalidate 한다.
final spendItemsProvider = FutureProvider<List<SpendItem>>((ref) => ref.watch(spendingRepositoryProvider).items());
