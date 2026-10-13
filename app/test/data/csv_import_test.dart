import 'dart:io';

import 'package:conmoney/core/budget_engine.dart';
import 'package:conmoney/core/models.dart';
import 'package:conmoney/data/csv_import.dart';
import 'package:conmoney/data/database.dart';
import 'package:conmoney/data/ledger_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

YearMonth ym(int m) => YearMonth(2026, m);

void main() {
  late AppDatabase db;
  late LedgerRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = LedgerRepository(db);
  });
  tearDown(() => db.close());

  test('합성 CSV: 할부·취소·특이 지출·라벨 없는 행까지 가져오고 월 합계가 맞다', () async {
    final rows = parseTransactionsCsv(File('test/fixtures/sample_transactions.csv').readAsStringSync());
    expect(rows, hasLength(10));
    expect(rows[2].merchant, 'FAKE AI, INC.'); // 따옴표 안의 쉼표
    expect(rows[3].approvedAt, DateTime(2026, 9, 10, 9, 14));
    expect(rows.last.category, '식비'); // category가 비면 category_guess

    final result = await importTransactions(db, rows);
    expect(result.inserted, 10); // 같은 날 같은 커피 2잔도 각각 저장
    expect(result.firstDate, DateTime(2026, 8, 2));
    expect(await db.setting('first_record_date'), '2026-08-02');

    final engine = BudgetEngine(await repo.loadLedger());
    expect(engine.spent(ym(8)), 20000 + 100000);
    expect(engine.unusualSpent(ym(8)), 100000);
    expect(engine.spent(ym(9)), 100000 + 6900 + 1800 + 1800 - 5300 + 15350); // 취소된 13,200 제외
    expect(engine.spent(ym(10)), 100000 + 1500 + 12000);

    final shinhan = await (db.select(db.cards)..where((c) => c.issuer.equals('SHINHAN'))).getSingle();
    expect(shinhan.active, isFalse);
    expect(shinhan.source, isNull);
    expect(await repo.unconfirmedCount(), 0);
  });

  test('같은 파일을 다시 가져와도 중복되지 않는다', () async {
    final rows = parseTransactionsCsv(File('test/fixtures/sample_transactions.csv').readAsStringSync());
    await importTransactions(db, rows);
    final again = await importTransactions(db, rows);
    expect(again.inserted, 0);
    expect(again.skipped, 10);
    expect(await db.select(db.transactions).get(), hasLength(10));
    expect(await db.select(db.installmentSchedules).get(), hasLength(3));
  });

  // 실제 카드 내역(git에 없음)이 있으면 Python 분석(Spec 부록 A)과 같은 월 합계가 나오는지 확인한다.
  final real = File('../data/transactions_v3.csv');
  test('실데이터: 월 합계가 부록 A와 일치', () async {
    await importTransactions(db, parseTransactionsCsv(real.readAsStringSync()));
    final engine = BudgetEngine(await repo.loadLedger());
    expect(engine.spent(ym(5)), 803489);
    expect(engine.spent(ym(6)), 1481996);
    expect(engine.spent(ym(7)), 1332566);
    expect(engine.spent(ym(8)), 1258186);
    expect(engine.spent(ym(9)), 1148030);
    expect(engine.spent(ym(10)), 544359);
    expect(engine.spent(ym(9)) - engine.unusualSpent(ym(9)), 1103130);

    final st = engine.status(DateTime(2026, 10, 13, 12), 540000);
    // ignore: avoid_print
    print(
      '10/13 B=540,000 → R=${st.remaining}, 기준액=${st.dailyBase}, 오늘 지출=${st.spentToday}, '
      'P=${engine.pattern(DateTime(2026, 10, 13)).amount}, 시작금액 기본값 후보=${await repo.recentMonthlyTotals(DateTime(2026, 10, 13))}',
    );
  }, skip: real.existsSync() ? false : 'data/transactions_v3.csv 없음');
}
