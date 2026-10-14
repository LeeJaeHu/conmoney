import 'dart:io';

import 'package:conmoney/core/budget_engine.dart';
import 'package:conmoney/core/category_summary.dart';
import 'package:conmoney/core/models.dart';
import 'package:conmoney/data/csv_import.dart';
import 'package:conmoney/data/database.dart';
import 'package:conmoney/data/ledger_repository.dart';
import 'package:conmoney/data/spending_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late SpendingRepository repo;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = SpendingRepository(db);
    await importTransactions(
      db,
      parseTransactionsCsv(File('test/fixtures/sample_transactions.csv').readAsStringSync()),
    );
  });
  tearDown(() => db.close());

  test('F8 카테고리 합계: 취소 제외, 할부는 회차별, 2회차부터는 그 달 1일', () async {
    final items = await repo.items();
    final sep = summarize(items, DateTime(2026, 9, 1), DateTime(2026, 9, 30));
    expect(sep.total, 100000 + 6900 + 1800 + 1800 - 5300 + 15350);
    final byName = {for (final c in sep.categories) c.name: c};
    expect(byName['게임']!.total, 100000);
    expect(byName['교통']!.total, -5300 + 15350); // 취소된 13,200은 빠짐
    expect(byName['카페·간식']!.count, 2);
    expect(sep.categories.first.name, '게임'); // 금액 큰 순

    final game = sep.itemsOf(byName['게임']!.categoryId).single;
    expect(game.installmentSeq, 2);
    expect(game.date, DateTime(2026, 9, 1));

    final noUnusual = summarize(items, DateTime(2026, 9, 1), DateTime(2026, 9, 30), includeUnusual: false);
    expect(noUnusual.total, sep.total - 100000);
  });

  test('최근 6개월 추이: 상위 카테고리 + 그 외', () async {
    final trend = monthlyTrend(await repo.items(), DateTime(2026, 10, 14), top: 2);
    expect(trend.months.first, const YearMonth(2026, 5));
    expect(trend.months.last, const YearMonth(2026, 10));
    expect(trend.series.map((s) => s.$1), ['게임', '식비', otherSeriesName]);
    expect(trend.monthTotals[3], 120000); // 8월: 배달 20,000 + 할부 1회차 100,000
  });

  test('F3 확인 시트 저장: 추천과 다른 카테고리면 가맹점 규칙 학습, 결제대행형 가맹점은 학습 안 함', () async {
    final cats = {for (final c in await repo.categories()) c.name: c.id};
    final coffee = await (db.select(db.transactions)..where((t) => t.merchantNorm.equals('가짜커피'))).get();
    await repo.saveReview(coffee.first.id, categoryId: cats['식비'], isUnusual: false, memo: '  아침 ');

    final t = await repo.transaction(coffee.first.id);
    expect(t.categoryId, cats['식비']);
    expect(t.memo, '아침');
    final rule = await (db.select(db.merchantRules)..where((r) => r.merchantNorm.equals('가짜커피'))).getSingle();
    expect(rule.categoryId, cats['식비']);

    final id = await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            kind: 'APPROVAL',
            amount: 5200,
            merchantRaw: '서울시 네이버페이',
            merchantNorm: '네이버페이',
            approvedAt: DateTime(2026, 10, 3),
            localDate: '2026-10-03',
            dedupeKey: 'test-naverpay',
          ),
        );
    await repo.saveReview(id, categoryId: cats['기타'], isUnusual: false, memo: null);
    expect(await (db.select(db.merchantRules)..where((r) => r.merchantNorm.equals('네이버페이'))).get(), isEmpty);
  });

  final real = File('../data/transactions_v3.csv');
  test('실데이터: 달마다 카테고리 합계의 합이 S와 같다', () async {
    await db.delete(db.installmentSchedules).go();
    await db.delete(db.transactions).go();
    await importTransactions(db, parseTransactionsCsv(real.readAsStringSync()));
    final items = await repo.items();
    final engine = BudgetEngine(await LedgerRepository(db).loadLedger());
    for (var m = 5; m <= 10; m++) {
      final ym = YearMonth(2026, m);
      expect(summarize(items, ym.firstDay, ym.lastDay).total, engine.spent(ym), reason: '$ym');
    }
    final sep = summarize(items, DateTime(2026, 9, 1), DateTime(2026, 9, 30), includeUnusual: false);
    // ignore: avoid_print
    print('9월(특이 제외): ${[for (final c in sep.categories) '${c.name} ${c.total}'].join(', ')}');
  }, skip: real.existsSync() ? false : 'data/transactions_v3.csv 없음');
}
