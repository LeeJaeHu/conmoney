import 'package:drift/drift.dart';

import '../core/budget_engine.dart';
import '../core/budget_plan.dart';
import '../core/models.dart';
import 'database.dart';

/// DB 행 → 계산 엔진 입력(Ledger)으로 바꾸고, 예산 설정을 읽고 쓴다.
class LedgerRepository {
  LedgerRepository(this.db);

  final AppDatabase db;

  Future<Ledger> loadLedger() async {
    final txRows = await db.select(db.transactions).get();
    final rows = await db.select(db.installmentSchedules).get();
    final items = await db.select(db.recurringItems).get();
    final matches = await db.select(db.recurringMatches).get();
    final first = await db.setting('first_record_date');

    return Ledger(
      txns: [
        for (final t in txRows)
          Txn(
            id: t.id,
            amount: t.amount,
            date: DateTime.parse(t.localDate),
            kind: switch (t.kind) {
              'CANCEL' => TxnKind.cancel,
              'MANUAL' => TxnKind.manual,
              _ => TxnKind.approval,
            },
            installmentMonths: t.installmentMonths,
            cancelled: t.status == 'CANCELLED',
            excludedFromSums: t.excludedFromSums,
            isUnusual: t.isUnusual,
            recurringItemId: t.recurringItemId,
          ),
      ],
      installments: [
        for (final r in rows)
          InstallmentRow(
            txnId: r.transactionId,
            seq: r.seq,
            month: YearMonth.parse(r.month),
            amount: r.amount,
            voided: r.voided,
          ),
      ],
      recurringItems: [
        for (final i in items)
          RecurringItem(
            id: i.id,
            name: i.name,
            amount: i.amount,
            dueDay: i.dueDay,
            isEstimate: i.isEstimate,
            active: i.active,
            matchPattern: i.matchPattern,
            amountTolerancePct: i.amountTolerancePct,
            isEnvelope: i.isEnvelope,
          ),
      ],
      recurringMatches: [
        for (final m in matches)
          RecurringMatch(
            itemId: m.recurringItemId,
            month: YearMonth.parse(m.month),
            status: m.status == 'SKIPPED' ? RecurringMatchStatus.skipped : RecurringMatchStatus.paid,
            decidedOn: DateTime.parse(m.decidedOn),
            txnId: m.transactionId,
          ),
      ],
      firstRecordDate: first == null ? null : DateTime.parse(first),
    );
  }

  Future<List<MonthlyBudget>> budgets() async => [
    for (final b in await db.select(db.budgets).get())
      MonthlyBudget(YearMonth.parse(b.month), b.amount, switch (b.source) {
        'STEP_PLAN' => BudgetSource.stepPlan,
        'MANUAL' => BudgetSource.manual,
        _ => BudgetSource.fixed,
      }),
  ];

  /// 이번 달부터 새 예산을 적용한다. 지난 달 값은 그대로 둔다(Spec F4).
  /// 이번 달 이후에 남아 있던 이전 계획은 지운다.
  Future<void> saveBudgets(YearMonth from, List<MonthlyBudget> plan, {required BudgetPlansCompanion setting}) {
    return db.transaction(() async {
      await (db.delete(db.budgets)..where((b) => b.month.isBiggerOrEqualValue(from.toString()))).go();
      await db.batch(
        (b) => b.insertAll(db.budgets, [
          for (final m in plan)
            BudgetsCompanion.insert(
              month: m.month.toString(),
              amount: m.amount,
              source: switch (m.source) {
                BudgetSource.stepPlan => 'STEP_PLAN',
                BudgetSource.manual => 'MANUAL',
                BudgetSource.fixed => 'FIXED',
              },
            ),
        ]),
      );
      await db.into(db.budgetPlans).insert(setting);
    });
  }

  Future<BudgetPlanRow?> latestPlan() =>
      (db.select(db.budgetPlans)
            ..orderBy([(p) => OrderingTerm.desc(p.id)])
            ..limit(1))
          .getSingleOrNull();

  /// 최근 완료된 달들의 월 지출(특이 지출 제외). 단계적 목표의 시작 금액 기본값에 쓴다.
  Future<List<int>> recentMonthlyTotals(DateTime now, {int months = 3}) async {
    final engine = BudgetEngine(await loadLedger());
    final m = YearMonth.of(now);
    final first = engine.ledger.firstRecordDate;
    return [
      for (var k = 1; k <= months; k++)
        if (first == null || !m.plus(-k).firstDay.isBefore(first))
          engine.spent(m.plus(-k)) - engine.unusualSpent(m.plus(-k)),
    ];
  }

  Future<int> unconfirmedCount() async {
    final c = db.transactions.id.count();
    final q = db.selectOnly(db.transactions)
      ..addColumns([c])
      ..where(db.transactions.confirmed.equals(false) | db.transactions.needsReview.equals(true));
    return (await q.getSingle()).read(c) ?? 0;
  }

  /// 이번 달 아직 처리되지 않은 정기 지출(홈 "다가오는 정기 지출").
  /// (항목, 예정일, 이번 달 남은 금액). 월 예약형은 남은 예약분이 있을 때만, 맨 위에.
  Future<List<(RecurringItem, DateTime, int)>> upcomingRecurring(DateTime now) async {
    final ledger = await loadLedger();
    final engine = BudgetEngine(ledger);
    final m = YearMonth.of(now);
    final handled = {
      for (final x in ledger.recurringMatches)
        if (x.month == m) x.itemId,
    };
    final list = <(RecurringItem, DateTime, int)>[
      for (final i in ledger.recurringItems)
        if (i.active && !handled.contains(i.id))
          (i, m.dayClamped(i.dueDay), i.isEnvelope ? engine.envelopeRemaining(i, m) : i.amount),
    ].where((e) => e.$3 > 0).toList()..sort((a, b) => a.$2.compareTo(b.$2));
    return list;
  }
}
