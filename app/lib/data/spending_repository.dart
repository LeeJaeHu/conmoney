import 'package:drift/drift.dart';

import '../core/category_summary.dart';
import '../core/models.dart';
import 'database.dart';
import 'metrics_repository.dart';

/// 가맹점 이름만으로 카테고리를 알 수 없는 결제대행형 가맹점(Spec F3).
/// 사용자가 카테고리를 바꿔도 MerchantRule로 학습하지 않는다.
const ambiguousMerchants = {'네이버페이', '카카오페이', '토스페이', '페이코', '구글플레이', '구글클라우드코리아'};

/// 카테고리 보기(F8)와 거래 수정(확인 시트) 저장소.
class SpendingRepository {
  SpendingRepository(this.db);

  final AppDatabase db;

  Future<List<CategoryRow>> categories() =>
      (db.select(db.categories)
            ..where((c) => c.hidden.equals(false))
            ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
          .get();

  /// 모든 지출 항목. 취소된 승인·합계 제외 행은 뺀다.
  Future<List<SpendItem>> items() async {
    final cats = {for (final c in await db.select(db.categories).get()) c.id: c.name};
    final cards = {for (final c in await db.select(db.cards).get()) c.id: c.productName};
    final rows = <int, List<InstallmentScheduleRow>>{};
    for (final r in await (db.select(db.installmentSchedules)..where((r) => r.voided.equals(false))).get()) {
      rows.putIfAbsent(r.transactionId, () => []).add(r);
    }

    final out = <SpendItem>[];
    for (final t in await db.select(db.transactions).get()) {
      if (t.excludedFromSums || (t.kind == 'APPROVAL' && t.status == 'CANCELLED')) continue;
      final date = DateTime.parse(t.localDate);
      SpendItem item(DateTime d, int amount, {int? seq}) => SpendItem(
        txnId: t.id,
        date: d,
        amount: amount,
        merchant: t.merchantNorm,
        categoryId: t.categoryId,
        categoryName: cats[t.categoryId],
        memo: t.memo,
        isUnusual: t.isUnusual,
        installmentSeq: seq,
        installmentMonths: t.installmentMonths,
        cardName: cards[t.cardId],
      );

      if (t.kind == 'APPROVAL' && t.installmentMonths > 1) {
        for (final r in rows[t.id] ?? const <InstallmentScheduleRow>[]) {
          final d = r.seq == 1 ? date : YearMonth.parse(r.month).firstDay;
          out.add(item(d, r.amount, seq: r.seq));
        }
      } else {
        out.add(item(date, t.amount));
      }
    }
    return out;
  }

  Future<TransactionRow> transaction(int id) => (db.select(db.transactions)..where((t) => t.id.equals(id))).getSingle();

  /// 확인 시트 저장(Spec F3). 추천과 다른 카테고리면 같은 가맹점의 다음 결제부터 그 카테고리를 추천한다.
  Future<void> saveReview(int txnId, {required int? categoryId, required bool isUnusual, required String? memo}) {
    return db.transaction(() async {
      final t = await transaction(txnId);
      await (db.update(db.transactions)..where((x) => x.id.equals(txnId))).write(
        TransactionsCompanion(
          categoryId: Value(categoryId),
          isUnusual: Value(isUnusual),
          memo: Value(memo == null || memo.trim().isEmpty ? null : memo.trim()),
          confirmed: const Value(true),
        ),
      );
      await MetricsRepository(db).categoryReview(
        suggestSource: t.suggestSource,
        accepted: categoryId != null && categoryId == t.suggestedCategoryId,
        hadSuggestion: t.suggestedCategoryId != null,
      );
      if (categoryId != null && categoryId != t.suggestedCategoryId && !ambiguousMerchants.contains(t.merchantNorm)) {
        await db
            .into(db.merchantRules)
            .insertOnConflictUpdate(
              MerchantRulesCompanion.insert(
                merchantNorm: t.merchantNorm,
                categoryId: categoryId,
                updatedAt: Value(DateTime.now()),
              ),
            );
      }
    });
  }
}
