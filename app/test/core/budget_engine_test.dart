// Spec 8장 수락 테스트(계산). 테스트 이름의 ID는 Spec 표의 ID와 같다.
import 'package:conmoney/core/budget_engine.dart';
import 'package:conmoney/core/budget_plan.dart';
import 'package:conmoney/core/installments.dart';
import 'package:conmoney/core/models.dart';
import 'package:flutter_test/flutter_test.dart';

DateTime d(int m, int day, [int year = 2026]) => DateTime(year, m, day);
YearMonth ym(int m, [int year = 2026]) => YearMonth(year, m);

const telecom = RecurringItem(id: 1, name: '통신비', amount: 65000, dueDay: 15);
const gas = RecurringItem(id: 2, name: '가스비', amount: 50000, dueDay: 25, isEstimate: true);

/// Spec 3.6 계산 예: 10/13, B=1,000,000, 13일 전 지출 600,000, F=115,000.
List<Txn> baseTxns() => [Txn(id: 1, amount: 600000, date: d(10, 5))];

Ledger ledgerOf(
  List<Txn> txns, {
  List<RecurringItem> items = const [telecom, gas],
  List<RecurringMatch> matches = const [],
  List<PlannedExpense> planned = const [],
  DateTime? firstRecordDate,
}) => Ledger(
  txns: txns,
  installments: [
    for (final t in txns)
      if (t.isInstallment) ...buildSchedule(t),
  ],
  recurringItems: items,
  recurringMatches: matches,
  plannedExpenses: planned,
  firstRecordDate: firstRecordDate,
);

void main() {
  group('하루 기준액·오늘 쓸 수 있는 금액 (3.6)', () {
    test('C1 계산 예: 기준액 15,000 → 스타벅스 후 8,500 → 통신비 66,000 매칭 후 7,500', () {
      final now = DateTime(2026, 10, 13, 9);
      var st = BudgetEngine(ledgerOf(baseTxns())).status(now, 1000000);
      expect(st.daysLeft, 19);
      expect(st.dailyBase, 15000);
      expect(st.available, 15000);

      final withCoffee = [...baseTxns(), Txn(id: 2, amount: 6500, date: d(10, 13))];
      st = BudgetEngine(ledgerOf(withCoffee)).status(now, 1000000);
      expect(st.available, 8500);

      final withTelecom = [...withCoffee, Txn(id: 3, amount: 66000, date: d(10, 13), recurringItemId: 1)];
      final matches = [
        RecurringMatch(itemId: 1, month: ym(10), status: RecurringMatchStatus.paid, decidedOn: d(10, 13), txnId: 3),
      ];
      st = BudgetEngine(ledgerOf(withTelecom, matches: matches)).status(now, 1000000);
      expect(st.dailyBase, 15000);
      expect(st.spentToday, 7500);
      expect(st.available, 7500);
      expect(st.upcomingFixed, 50000);
    });

    test('C2 같은 날 결제가 여러 번 들어와도 기준액은 그대로', () {
      final now = DateTime(2026, 10, 13, 20);
      final txns = [...baseTxns(), for (var i = 0; i < 5; i++) Txn(id: 10 + i, amount: 3000, date: d(10, 13))];
      final st = BudgetEngine(ledgerOf(txns)).status(now, 1000000);
      expect(st.dailyBase, 15000);
      expect(st.available, 0);
    });

    test('C3 0시 작업 없이 09:00에 계산해도 0시 계산과 같은 기준액', () {
      final matches = [
        RecurringMatch(itemId: 1, month: ym(10), status: RecurringMatchStatus.paid, decidedOn: d(10, 13), txnId: 3),
      ];
      final txns = [...baseTxns(), Txn(id: 3, amount: 65000, date: d(10, 13), recurringItemId: 1)];
      final engine = BudgetEngine(ledgerOf(txns, matches: matches));
      final atMidnight = BudgetEngine(ledgerOf(baseTxns())).status(DateTime(2026, 10, 13, 0, 1), 1000000);
      expect(engine.status(DateTime(2026, 10, 13, 9), 1000000).dailyBase, atMidnight.dailyBase);
    });

    test('C4 예산 금액을 바꾸면 그날 기준액을 다시 계산', () {
      final engine = BudgetEngine(ledgerOf(baseTxns()));
      final now = DateTime(2026, 10, 13, 15);
      expect(engine.status(now, 1000000).dailyBase, 15000);
      expect(engine.status(now, 1019000).dailyBase, 16000);
    });

    test('C5 R0 < 0이면 0원 표시와 월 초과액', () {
      final st = BudgetEngine(ledgerOf(baseTxns())).status(DateTime(2026, 10, 13), 700000);
      expect(st.dailyBase, lessThan(0));
      expect(st.availableShown, 0);
      expect(st.monthOver, 15000);
    });
  });

  group('할부·취소 (3.2, 4.4, 4.5)', () {
    test('C6 100,000원 3개월 할부: 33,400 / 33,300 / 33,300, 이월 회차는 11/1에 S로', () {
      expect(splitInstallment(100000, 3), [33400, 33300, 33300]);
      final t = Txn(id: 1, amount: 100000, date: d(10, 13), installmentMonths: 3);
      final engine = BudgetEngine(ledgerOf([t], items: const []));
      expect(engine.spent(ym(10)), 33400);
      expect(engine.spent(ym(11)), 33300);
      expect(engine.spent(ym(12)), 33300);
      expect(engine.spent(ym(1, 2027)), 0);

      final nov1 = engine.status(DateTime(2026, 11, 1, 0, 1), 300000);
      expect(nov1.spentToday, 0);
      expect(nov1.dailyBase, floorDiv(300000 - 33300, 30));
    });

    test('C6 현대카드 실제 할부 사례와 같은 분할', () {
      expect(splitInstallment(718000, 3), [239400, 239300, 239300]);
      expect(splitInstallment(104600, 3), [35000, 34800, 34800]);
      expect(splitInstallment(54160, 2), [27160, 27000]);
      expect(splitInstallment(15900, 2), [8000, 7900]);
    });

    test('C7 같은 달 전액 취소: S 원상복구, 할부 회차 무효', () {
      final original = Txn(id: 1, amount: 90000, date: d(10, 3), installmentMonths: 3, cancelled: true);
      final cancelRow = Txn(id: 2, amount: -90000, date: d(10, 10), kind: TxnKind.cancel, excludedFromSums: true);
      final rows = [
        for (final r in buildSchedule(original))
          InstallmentRow(txnId: r.txnId, seq: r.seq, month: r.month, amount: r.amount, voided: true),
      ];
      final engine = BudgetEngine(Ledger(txns: [original, cancelRow], installments: rows));
      expect(engine.spent(ym(10)), 0);
      expect(engine.spent(ym(11)), 0);
    });

    test('C8 지난달 거래를 이번 달에 취소: 지난달 S 그대로, 이번 달 −금액', () {
      final engine = BudgetEngine(
        ledgerOf([
          Txn(id: 1, amount: 13200, date: d(9, 15)),
          Txn(id: 2, amount: -13200, date: d(10, 2), kind: TxnKind.cancel),
        ], items: const []),
      );
      expect(engine.spent(ym(9)), 13200);
      expect(engine.spent(ym(10)), -13200);
    });

    test('C9 원거래 없는 취소는 음수로 반영', () {
      final engine = BudgetEngine(
        ledgerOf([Txn(id: 1, amount: -5300, date: d(10, 2), kind: TxnKind.cancel)], items: const []),
      );
      expect(engine.spent(ym(10)), -5300);
    });
  });

  group('정기 지출 F (3.4)', () {
    test('C10 결제일 31일은 30일인 달에서 말일로', () {
      expect(ym(11).dayClamped(31), d(11, 30));
      expect(ym(2, 2027).dayClamped(31), d(2, 28, 2027));
    });

    test('C11 예정일이 지나도 결제가 없으면 월말까지 F에 남는다', () {
      final engine = BudgetEngine(ledgerOf(const []));
      expect(engine.status(DateTime(2026, 10, 30), 1000000).upcomingFixed, 115000);
    });

    test('[이번 달 없음](SKIPPED)이면 F에서 빠진다', () {
      final engine = BudgetEngine(
        ledgerOf(
          const [],
          matches: [
            RecurringMatch(itemId: 2, month: ym(10), status: RecurringMatchStatus.skipped, decidedOn: d(10, 28)),
          ],
        ),
      );
      expect(engine.status(DateTime(2026, 10, 30), 1000000).upcomingFixed, 65000);
    });
  });

  group('평소 패턴 P (3.7)', () {
    test('C12 특이 지출은 S에 포함, P에서 제외', () {
      final engine = BudgetEngine(
        ledgerOf([
          Txn(id: 1, amount: 200000, date: d(9, 20), isUnusual: true),
          Txn(id: 2, amount: 10000, date: d(9, 20)),
        ], items: const []),
      );
      expect(engine.spent(ym(9)), 210000);
      expect(engine.varSpend(ym(9), 1, 30), 10000);
    });

    test('C13 정기 지출에 매칭된 거래와 할부 이월 회차는 P에서 제외', () {
      final engine = BudgetEngine(
        ledgerOf([
          Txn(id: 1, amount: 65000, date: d(9, 15), recurringItemId: 1),
          Txn(id: 2, amount: 90000, date: d(8, 20), installmentMonths: 3),
          Txn(id: 3, amount: 12000, date: d(9, 21)),
        ], items: const []),
      );
      expect(engine.spent(ym(9)), 65000 + 30000 + 12000);
      expect(engine.varSpend(ym(9), 1, 30), 12000);
    });

    test('C14 과거 데이터가 없으면 이번 달 일평균 × 남은 일수', () {
      final txns = [for (var day = 1; day <= 12; day++) Txn(id: day, amount: 10000, date: d(10, day))];
      final engine = BudgetEngine(ledgerOf(txns, items: const [], firstRecordDate: d(10, 1)));
      final p = engine.pattern(DateTime(2026, 10, 13));
      expect(p.source, PatternSource.thisMonthPace);
      expect(p.amount, 120000 * 19 ~/ 12);
      expect(engine.pattern(DateTime(2026, 10, 1)).source, PatternSource.none);
    });

    test('P는 최근 3개월 같은 남은 기간의 중앙값, 짧은 달은 말일로 맞춤', () {
      final engine = BudgetEngine(
        ledgerOf(
          [
            Txn(id: 1, amount: 100000, date: d(7, 31)),
            Txn(id: 2, amount: 300000, date: d(8, 31)),
            Txn(id: 3, amount: 200000, date: d(9, 30)), // 9월은 30일까지 → 30일부터 셈
            Txn(id: 4, amount: 999999, date: d(9, 29)), // 남은 기간 밖
          ],
          items: const [],
          firstRecordDate: d(5, 1),
        ),
      );
      final p = engine.pattern(DateTime(2026, 10, 31));
      expect(p.source, PatternSource.history);
      expect(p.monthsUsed, 3);
      expect(p.amount, 200000);
    });

    test('기록이 달 중간에 시작한 달은 P에서 뺀다', () {
      final engine = BudgetEngine(
        ledgerOf(
          [Txn(id: 1, amount: 50000, date: d(9, 20))],
          items: const [],
          firstRecordDate: d(9, 10),
        ),
      );
      expect(engine.pattern(DateTime(2026, 10, 13)).source, PatternSource.thisMonthPace);
    });
  });

  group('구매 판단 (3.8)', () {
    test('C15 경계: over = 0 / B×10% / B×10%+1', () {
      final engine = BudgetEngine(ledgerOf(const [], items: const [], firstRecordDate: d(10, 1)));
      final now = DateTime(2026, 10, 1, 10);
      expect(engine.simulatePurchase(now, 1000000, 1000000).verdict, Verdict.ok);
      expect(engine.simulatePurchase(now, 1000000, 1100000).verdict, Verdict.conditional);
      expect(engine.simulatePurchase(now, 1000000, 1100001).verdict, Verdict.postpone);
    });

    test('할부 구매는 이번 달 1회차만 반영', () {
      final engine = BudgetEngine(ledgerOf(const [], items: const [], firstRecordDate: d(10, 1)));
      final now = DateTime(2026, 10, 1, 10);
      final sim = engine.simulatePurchase(now, 1000000, 150000, installmentMonths: 3);
      expect(sim.projectedMonthEnd, 50000);
    });

    test('C19 다음 달 구매는 그 달 예산(없으면 직전 달 이어 씀)과 예상으로 판단', () {
      final engine = BudgetEngine(ledgerOf(const [], items: const [telecom], firstRecordDate: d(10, 1)));
      final now = DateTime(2026, 10, 1, 10);
      // 11월 예상 = 정기 65,000 + 평소 0 + 구매 150,000 = 215,000
      final sim = engine.simulatePurchase(now, 1000000, 150000, date: d(11, 3), budgetOf: (_) => 205000);
      expect(sim.month, ym(11));
      expect(sim.budget, 205000);
      expect(sim.projectedMonthEnd, 215000);
      expect(sim.verdict, Verdict.conditional);
      expect(sim.todayAvailableAfter, isNull);
      // budgetOf가 없으면 이번 달 예산을 쓴다
      expect(engine.simulatePurchase(now, 1000000, 150000, date: d(11, 3)).verdict, Verdict.ok);
    });

    test('C20 일시불이 괜찮아요가 아니면 2·3개월 할부안을 같이 계산', () {
      final engine = BudgetEngine(ledgerOf(const [], items: const [], firstRecordDate: d(10, 1)));
      final now = DateTime(2026, 10, 1, 10);
      final sim = engine.simulatePurchase(now, 100000, 300000);
      expect(sim.verdict, Verdict.postpone);
      expect(sim.installmentOptions.map((o) => o.months), [2, 3]);
      final three = sim.installmentOptions[1];
      expect(three.perMonth.map((e) => e.$1), [ym(10), ym(11), ym(12)]);
      expect(three.perMonth.map((e) => e.$2), [100000, 100000, 100000]);
      expect(three.worst, Verdict.ok);
      expect(sim.installmentOptions[0].worst, Verdict.postpone);
      expect(engine.simulatePurchase(now, 1000000, 300000).installmentOptions, isEmpty);
    });

    test('C22 금액 범위: ok·조건부 경계를 1,000원 단위로 내림', () {
      final engine = BudgetEngine(ledgerOf(const [], items: const [telecom], firstRecordDate: d(10, 1)));
      final now = DateTime(2026, 10, 1, 10);
      // 여유 = 200,000 - 65,000 = 135,000, 조건부는 +20,000
      final (okMax, condMax, month, b) = engine.thresholds(now, 200000);
      expect((okMax, condMax, month, b), (135000, 155000, ym(10), 200000));
      expect(engine.thresholds(now, 50000).$1, -1);
    });

    test('C21 예정 지출은 그 달 F에 들어가고, 낸 뒤에는 빠진다', () {
      final now = DateTime(2026, 10, 13, 9);
      final gift = PlannedExpense(id: 1, name: "축의금", amount: 50000, date: d(10, 20));
      final st = BudgetEngine(ledgerOf(baseTxns(), planned: [gift])).status(now, 1000000);
      expect(st.upcomingFixed, 165000);
      expect(st.remaining, 235000);
      final nov = PlannedExpense(id: 2, name: '축의금', amount: 100000, date: d(11, 7));
      final engine = BudgetEngine(ledgerOf(baseTxns(), planned: [nov]));
      expect(engine.status(now, 1000000).upcomingFixed, 115000);
      expect(engine.project(now, ym(11)).fixed, 115000 + 100000);
      final paid = PlannedExpense(id: 1, name: '축의금', amount: 50000, date: d(10, 20), doneOn: d(10, 10));
      expect(BudgetEngine(ledgerOf(baseTxns(), planned: [paid])).status(now, 1000000).upcomingFixed, 115000);
    });
  });

  group('예산 목표·초과 표시 (F4)', () {
    test('C16 단계적 목표 80만 → 54만, 3개월', () {
      final plan = stepPlan(start: ym(11), startAmount: 800000, targetAmount: 540000, months: 3);
      expect(plan.map((b) => b.amount), [800000, 670000, 540000]);
      expect(budgetFor(plan, ym(2, 2027)), 540000);
      expect(budgetFor(plan, ym(10)), isNull);

      final edited = overrideMonth(plan, ym(12), 700000);
      expect(edited.map((b) => b.source), [BudgetSource.stepPlan, BudgetSource.manual, BudgetSource.stepPlan]);
      expect(budgetFor(edited, ym(12)), 700000);
      expect(budgetFor(edited, ym(1, 2027)), 540000);
    });

    test('시작 금액 기본값은 최근 월평균을 1만 원 단위로 내림', () {
      expect(defaultStartAmount([1078266, 1003986, 1103130]), 1060000);
    });

    test('C17 오늘만 3,000원 초과: 0원 표시, 오늘 초과액, 내일 기준액 미리보기', () {
      final txns = [...baseTxns(), Txn(id: 2, amount: 18000, date: d(10, 13))];
      final st = BudgetEngine(ledgerOf(txns)).status(DateTime(2026, 10, 13, 21), 1000000);
      expect(st.availableShown, 0);
      expect(st.todayOver, 3000);
      expect(st.monthOver, 0);
      expect(st.tomorrowBase, floorDiv(1000000 - 618000 - 115000, 18));
    });

    test('C18 이번 달 20,000원 초과', () {
      final st = BudgetEngine(ledgerOf([Txn(id: 1, amount: 520000, date: d(10, 5))], items: const []))
          .status(DateTime(2026, 10, 13), 500000);
      expect(st.availableShown, 0);
      expect(st.monthOver, 20000);
      expect(st.overOnlyAfterFixed, isFalse);
    });

    test('정기 지출을 반영해서야 초과되는 경우 구분', () {
      final st = BudgetEngine(ledgerOf([Txn(id: 1, amount: 400000, date: d(10, 5))], items: const [telecom, gas]))
          .status(DateTime(2026, 10, 13), 500000);
      expect(st.monthOver, 15000);
      expect(st.overOnlyAfterFixed, isTrue);
    });
  });

  group('월 예약형 (교통비, 10/14)', () {
    const transit = RecurringItem(
      id: 9,
      name: '교통(후불)',
      amount: 68200,
      dueDay: 1,
      isEnvelope: true,
      matchPattern: '후불',
    );
    Txn ride(int id, int day, [int amount = 3100]) => Txn(id: id, amount: amount, date: d(10, day), recurringItemId: 9);

    test('E1 남은 예약분 = 예상액 − 이번 달 실제 교통비(0 아래로 안 내려감)', () {
      final engine = BudgetEngine(ledgerOf([ride(1, 1), ride(2, 2), ride(3, 6)], items: const [transit]));
      expect(engine.envelopeRemaining(transit, ym(10)), 68200 - 9300);
      expect(engine.status(DateTime(2026, 10, 13), 1000000).upcomingFixed, 68200 - 9300);
      final over = BudgetEngine(ledgerOf([for (var i = 1; i <= 25; i++) ride(i, 1)], items: const [transit]));
      expect(over.envelopeRemaining(transit, ym(10)), 0);
    });

    test('E2 오늘 탄 교통비는 예약분 안이면 오늘 쓸 수 있는 금액을 줄이지 않는다', () {
      final before = BudgetEngine(ledgerOf([ride(1, 12)], items: const [transit]))
          .status(DateTime(2026, 10, 13, 8), 1000000);
      final after = BudgetEngine(ledgerOf([ride(1, 12), ride(2, 13)], items: const [transit]))
          .status(DateTime(2026, 10, 13, 9), 1000000);
      expect(after.dailyBase, before.dailyBase);
      expect(after.spentToday, 0);
      expect(after.available, before.available);
      expect(after.remaining, before.remaining); // S가 늘고 F가 같은 만큼 줄어 R은 그대로
    });

    test('E3 예약분을 넘은 만큼만 오늘 지출로 친다', () {
      const small = RecurringItem(id: 9, name: '교통', amount: 5000, dueDay: 1, isEnvelope: true, matchPattern: '후불');
      final st = BudgetEngine(ledgerOf([ride(1, 12), ride(2, 13)], items: const [small]))
          .status(DateTime(2026, 10, 13, 9), 1000000);
      // 0시 기준 남은 예약 1,900원, 오늘 3,100원 → 1,200원만 오늘 지출
      expect(st.spentToday, 1200);
    });

    test('E4 교통비(예약형에 연결된 결제)는 평소 패턴 P에서 빠진다', () {
      final engine = BudgetEngine(
        ledgerOf([ride(1, 2), Txn(id: 2, amount: 10000, date: d(10, 2))], items: const [transit]),
      );
      expect(engine.varSpend(ym(10), 1, 31), 10000);
    });
  });
}
