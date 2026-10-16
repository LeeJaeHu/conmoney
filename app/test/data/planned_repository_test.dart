import 'package:conmoney/core/budget_engine.dart';
import 'package:conmoney/core/models.dart';
import 'package:conmoney/data/database.dart';
import 'package:conmoney/data/ledger_repository.dart';
import 'package:conmoney/data/planned_repository.dart';
import 'package:conmoney/data/spending_repository.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late PlannedRepository planned;
  late LedgerRepository ledger;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    planned = PlannedRepository(db);
    ledger = LedgerRepository(db);
  });
  tearDown(() => db.close());

  test('예정 지출: 등록하면 그 달 F에, [냈어요]하면 MANUAL 거래(경조사·선물, 특이)로 바뀌고 F에서 빠진다', () async {
    final now = DateTime(2026, 10, 13, 9);
    final id = await planned.add(name: '친구 축의금', amount: 100000, date: DateTime(2026, 10, 20));
    await planned.add(name: '조카 돌 선물', amount: 50000, date: DateTime(2026, 11, 7));

    var engine = BudgetEngine(await ledger.loadLedger());
    expect(engine.status(now, 1000000).upcomingFixed, 100000);
    expect(engine.project(now, const YearMonth(2026, 11)).fixed, 50000);
    expect((await ledger.upcomingRecurring(now)).single.$1.name, '친구 축의금(예정)');

    await planned.markPaid(id, now);
    engine = BudgetEngine(await ledger.loadLedger());
    final st = engine.status(now, 1000000);
    expect(st.spent, 100000);
    expect(st.upcomingFixed, 0);
    // 0시 기준 F에는 남아 있어 오늘 금액이 이중으로 줄지 않는다
    expect(st.available, st.dailyBase);

    final txn = await db.select(db.transactions).getSingle();
    expect(txn.kind, 'MANUAL');
    expect(txn.isUnusual, isTrue);
    final cat = await (db.select(db.categories)..where((c) => c.id.equals(txn.categoryId!))).getSingle();
    expect(cat.name, '경조사·선물');

    await planned.delete(id);
    expect(await db.select(db.transactions).get(), isEmpty);
  });

  test('확인 안 한 결제(10/16): 카테고리를 정할 수 없는 [냈어요] 지출이 목록에 뜨고, 확인 시트에서 저장하면 빠진다', () async {
    final now = DateTime(2026, 10, 13, 9);
    final id = await planned.add(name: '동아리 회비', amount: 30000, date: DateTime(2026, 10, 13));
    await planned.markPaid(id, now);
    expect(await ledger.unconfirmedCount(), 1);
    final row = (await ledger.unconfirmed()).single;
    expect(row.merchantNorm, '동아리 회비');

    // 다시 봐야 함 표시가 붙은 결제도 저장하면 같이 풀린다
    await (db.update(db.transactions)..where((t) => t.id.equals(row.id))).write(
      const TransactionsCompanion(needsReview: Value(true), reviewReason: Value('금액이 평소와 다름')),
    );
    final etc = await (db.select(db.categories)..where((c) => c.name.equals('기타'))).getSingle();
    await SpendingRepository(db).saveReview(row.id, categoryId: etc.id, isUnusual: true, memo: null);
    expect(await ledger.unconfirmedCount(), 0);
    expect(await ledger.unconfirmed(), isEmpty);
  });
}
