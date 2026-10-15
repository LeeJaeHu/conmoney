import 'package:drift/drift.dart';

import 'database.dart';

/// 예정 지출(축의금 등, 10/15 결정). 낼 날짜가 속한 달의 F에 들어가고,
/// [냈어요]를 누르면 같은 금액의 MANUAL 거래가 생기며 F에서 빠진다.
class PlannedRepository {
  PlannedRepository(this.db);

  final AppDatabase db;

  /// 아직 안 낸 것(날짜순) 다음에 최근에 낸 것.
  Future<List<PlannedExpenseRow>> list() async {
    final rows = await db.select(db.plannedExpenses).get();
    final open = rows.where((r) => r.doneOn == null).toList()..sort((a, b) => a.date.compareTo(b.date));
    final done = rows.where((r) => r.doneOn != null).toList()..sort((a, b) => b.doneOn!.compareTo(a.doneOn!));
    return [...open, ...done];
  }

  Future<int> add({required String name, required int amount, required DateTime date, String source = 'USER'}) =>
      db
          .into(db.plannedExpenses)
          .insert(PlannedExpensesCompanion.insert(name: name, amount: amount, date: _ymd(date), source: Value(source)));

  Future<void> update(int id, {required String name, required int amount, required DateTime date}) =>
      (db.update(db.plannedExpenses)..where((p) => p.id.equals(id))).write(
        PlannedExpensesCompanion(name: Value(name), amount: Value(amount), date: Value(_ymd(date))),
      );

  /// [냈어요]: 오늘 날짜로 MANUAL 거래를 만든다. 경조사성 이름이면 경조사·선물로 분류.
  /// 한 번만 나가는 지출이라 평소 패턴(P)에는 넣지 않는다(특이 지출로 표시).
  Future<void> markPaid(int id, DateTime now, {int? amount}) {
    return db.transaction(() async {
      final p = await (db.select(db.plannedExpenses)..where((x) => x.id.equals(id))).getSingle();
      if (p.doneOn != null) return;
      final paid = amount ?? p.amount;
      final category = RegExp('축의|조의|부조|결혼|돌잔치|장례|선물|생일').hasMatch(p.name) ? '경조사·선물' : null;
      final categoryId = category == null
          ? null
          : (await (db.select(db.categories)..where((c) => c.name.equals(category))).getSingleOrNull())?.id;
      final today = _ymd(now);
      final txnId = await db
          .into(db.transactions)
          .insert(
            TransactionsCompanion.insert(
              kind: 'MANUAL',
              amount: paid,
              merchantRaw: p.name,
              merchantNorm: p.name,
              approvedAt: now,
              localDate: today,
              categoryId: Value(categoryId),
              suggestedCategoryId: Value(categoryId),
              suggestSource: const Value('PLANNED'),
              isUnusual: const Value(true),
              confirmed: Value(categoryId != null),
              sourcePackage: const Value('PLANNED'),
              dedupeKey: 'PLANNED|${p.id}',
            ),
          );
      await (db.update(db.plannedExpenses)..where((x) => x.id.equals(id))).write(
        PlannedExpensesCompanion(doneOn: Value(today), transactionId: Value(txnId), amount: Value(paid)),
      );
    });
  }

  /// 지운다. 이미 낸 것이면 그때 만든 거래도 같이 지운다.
  Future<void> delete(int id) {
    return db.transaction(() async {
      final p = await (db.select(db.plannedExpenses)..where((x) => x.id.equals(id))).getSingleOrNull();
      if (p == null) return;
      if (p.transactionId != null) {
        await (db.delete(db.transactions)..where((t) => t.id.equals(p.transactionId!))).go();
      }
      await (db.delete(db.plannedExpenses)..where((x) => x.id.equals(id))).go();
    });
  }

  static String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
