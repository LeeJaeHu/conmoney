import 'installments.dart';
import 'models.dart';

/// 계산에 필요한 원장 전체. DB에서 읽어 만든다.
class Ledger {
  Ledger({
    required this.txns,
    required this.installments,
    this.recurringItems = const [],
    this.recurringMatches = const [],
    this.plannedExpenses = const [],
    this.firstRecordDate,
  });

  final List<Txn> txns;
  final List<InstallmentRow> installments;
  final List<RecurringItem> recurringItems;
  final List<RecurringMatch> recurringMatches;
  final List<PlannedExpense> plannedExpenses;

  /// 첫 기록일. 이 날이 속한 달이 1일부터 시작하지 않으면 P 계산에서 뺀다(Spec 3.7).
  final DateTime? firstRecordDate;

  late final Map<int, List<InstallmentRow>> _rowsByTxn = () {
    final m = <int, List<InstallmentRow>>{};
    for (final r in installments) {
      m.putIfAbsent(r.txnId, () => []).add(r);
    }
    return m;
  }();
}

enum PatternSource { history, thisMonthPace, none }

class Pattern {
  const Pattern(this.amount, this.source, this.monthsUsed);

  final int amount;
  final PatternSource source;
  final int monthsUsed;
}

/// 홈 화면과 `get_budget_status` 툴이 쓰는 값(Spec 3.5, 3.6, F4).
class BudgetStatus {
  const BudgetStatus({
    required this.budget,
    required this.spent,
    required this.upcomingFixed,
    required this.daysLeft,
    required this.dailyBase,
    required this.spentToday,
    this.tomorrowBase,
  });

  /// B
  final int budget;

  /// S
  final int spent;

  /// F (지금 기준)
  final int upcomingFixed;

  /// N, 오늘 포함 남은 일수
  final int daysLeft;

  /// 오늘 0시 기준 하루 기준액(음수 가능)
  final int dailyBase;
  final int spentToday;

  /// 내일 하루 기준액 미리보기. 오늘이 말일이면 null.
  final int? tomorrowBase;

  /// R = B − S − F
  int get remaining => budget - spent - upcomingFixed;

  int get available => dailyBase - spentToday;

  /// 화면 큰 숫자. 음수면 0원(Spec 3.6).
  int get availableShown => available < 0 ? 0 : available;

  /// 오늘 넘은 금액(넘지 않았으면 0).
  int get todayOver => available < 0 ? -available : 0;

  /// 이번 달 넘은 금액(넘지 않았으면 0).
  int get monthOver => remaining < 0 ? -remaining : 0;

  /// 정기 지출을 빼기 전엔 남지만 뺀 뒤 초과인 경우(Spec F4 초과 표시 3번째 줄).
  bool get overOnlyAfterFixed => remaining < 0 && budget - spent >= 0;
}

enum Verdict { ok, conditional, postpone }

Verdict judgeOver(int over, int budget) =>
    over <= 0 ? Verdict.ok : (over <= budget ~/ 10 ? Verdict.conditional : Verdict.postpone);

/// 미래 달의 예상(다음 달 구매 판단, 할부 뒷 회차용).
class MonthProjection {
  const MonthProjection(this.month, this.known, this.fixed, this.usual);

  final YearMonth month;

  /// 이미 정해진 지출: 할부 이월 회차 등 그 달에 기여하는 기존 거래
  final int known;

  /// 정기 지출 전체 + 예정 지출
  final int fixed;

  /// 평소 한 달 소비(최근 완료된 달들의 중앙값, 특이·정기 지출 제외)
  final int usual;

  int get total => known + fixed + usual;
}

/// 2·3개월 할부로 샀을 때 달마다의 영향.
class InstallmentOption {
  const InstallmentOption(this.months, this.perMonth);

  final int months;

  /// (달, 그 달에 잡히는 회차 금액, 그 달 판단, 그 달 예상 초과액)
  final List<(YearMonth, int, Verdict, int)> perMonth;

  Verdict get worst => perMonth.map((e) => e.$3).reduce((a, b) => a.index >= b.index ? a : b);
}

class PurchaseSimulation {
  const PurchaseSimulation({
    required this.verdict,
    required this.month,
    required this.budget,
    required this.remainingAfter,
    required this.todayAvailableAfter,
    required this.projectedMonthEnd,
    required this.projectedOver,
    required this.pattern,
    this.installmentOptions = const [],
  });

  final Verdict verdict;

  /// 판단 기준 달(구매일이 다음 달이면 그 달).
  final YearMonth month;

  /// 판단에 쓴 그 달 예산.
  final int budget;
  final int remainingAfter;

  /// 이번 달 구매일 때만 의미 있음.
  final int? todayAvailableAfter;
  final int projectedMonthEnd;

  /// 예상 월말 초과액(음수면 남음).
  final int projectedOver;

  /// 남은 기간(이번 달) 또는 한 달 전체(미래 달)의 평소 소비.
  final int pattern;

  /// 일시불 판단이 괜찮아요가 아닐 때 2·3개월 할부안(대안, 10/15 결정).
  final List<InstallmentOption> installmentOptions;
}

/// 음수에서도 내림이 되는 정수 나눗셈(Dart의 `~/`는 0 쪽으로 자른다).
int floorDiv(int a, int b) {
  final q = a ~/ b;
  return (a % b != 0 && (a < 0) != (b < 0)) ? q - 1 : q;
}

/// Spec 3장의 계산을 담당한다. 모든 함수는 `now`를 받는 순수 함수다.
class BudgetEngine {
  BudgetEngine(this.ledger);

  final Ledger ledger;

  // ---------------------------------------------------------------- 3.2 기여액

  /// 거래의 월 기여액.
  int contrib(Txn t, YearMonth m) {
    if (t.excludedFromSums) return 0;
    if (t.kind == TxnKind.approval) {
      if (t.cancelled) return 0;
      if (t.isInstallment) {
        var sum = 0;
        for (final r in ledger._rowsByTxn[t.id] ?? const <InstallmentRow>[]) {
          if (!r.voided && r.month == m) sum += r.amount;
        }
        return sum;
      }
    }
    return m.contains(t.date) ? t.amount : 0;
  }

  // ---------------------------------------------------------------- 3.3 S, 3.4 F

  int spent(YearMonth m) => ledger.txns.fold(0, (s, t) => s + contrib(t, m));

  /// S 중 특이 지출 부분(할부 회차 포함).
  int unusualSpent(YearMonth m) => ledger.txns.where((t) => t.isUnusual).fold(0, (s, t) => s + contrib(t, m));

  /// 오늘 승인·취소된 거래의 기여분.
  int _todayContrib(DateTime today) {
    final m = YearMonth.of(today);
    return ledger.txns.where((t) => dateOnly(t.date) == today).fold(0, (s, t) => s + contrib(t, m));
  }

  /// F: 이번 달 아직 처리(PAID/SKIPPED)되지 않은 활성 정기 지출 예정액.
  /// [decidedBefore]를 주면 그 날 이후에 생긴 처리 기록은 없던 것으로 본다(오늘 0시 기준 F).
  int upcomingFixed(YearMonth m, {DateTime? decidedBefore}) {
    final handled = <int>{
      for (final x in ledger.recurringMatches)
        if (x.month == m && (decidedBefore == null || dateOnly(x.decidedOn).isBefore(decidedBefore))) x.itemId,
    };
    var sum = 0;
    for (final i in ledger.recurringItems) {
      if (!i.active || handled.contains(i.id)) continue;
      sum += i.isEnvelope ? envelopeRemaining(i, m, before: decidedBefore) : i.amount;
    }
    return sum + plannedIn(m, decidedBefore: decidedBefore);
  }

  /// 그 달에 아직 내지 않은 예정 지출 합. [decidedBefore] 이후에 낸 것은 아직 안 낸 것으로 본다(0시 기준 F).
  int plannedIn(YearMonth m, {DateTime? decidedBefore}) {
    var sum = 0;
    for (final p in ledger.plannedExpenses) {
      if (!m.contains(p.date)) continue;
      final done = p.doneOn != null && (decidedBefore == null || dateOnly(p.doneOn!).isBefore(decidedBefore));
      if (!done) sum += p.amount;
    }
    return sum;
  }

  /// 월 예약형에 연결된 이번 달 실제 지출. [before]가 있으면 그 날 이전 결제만.
  int envelopeUsed(RecurringItem item, YearMonth m, {DateTime? before}) {
    var used = 0;
    for (final t in ledger.txns) {
      if (t.recurringItemId != item.id || !m.contains(t.date)) continue;
      if (before != null && !dateOnly(t.date).isBefore(before)) continue;
      used += contrib(t, m);
    }
    return used;
  }

  /// 월 예약형의 남은 예약분 = max(0, 예상액 − 이번 달 실제 지출).
  int envelopeRemaining(RecurringItem item, YearMonth m, {DateTime? before}) {
    final left = item.amount - envelopeUsed(item, m, before: before);
    return left > 0 ? left : 0;
  }

  /// 오늘 결제 중 이미 F로 빼 두었던 금액. 이만큼은 "오늘 쓴 금액"에서 뺀다(이중 차감 방지, Spec 3.6).
  /// 일반 정기 지출은 예정액 전체, 월 예약형은 오늘 0시 기준 남은 예약분 안에서 오늘 쓴 만큼.
  int _expectedMatchedToday(DateTime today) {
    final m = YearMonth.of(today);
    final byId = {for (final i in ledger.recurringItems) i.id: i};
    var sum = 0;
    for (final x in ledger.recurringMatches) {
      if (x.month == m && x.status == RecurringMatchStatus.paid && dateOnly(x.decidedOn) == today) {
        final item = byId[x.itemId];
        if (item != null && !item.isEnvelope) sum += item.amount;
      }
    }
    // 오늘 [냈어요]한 예정 지출(그 금액의 MANUAL 거래가 오늘 지출로 들어오므로)
    for (final p in ledger.plannedExpenses) {
      if (p.doneOn != null && dateOnly(p.doneOn!) == today && m.contains(p.date)) sum += p.amount;
    }
    for (final i in ledger.recurringItems) {
      if (!i.active || !i.isEnvelope) continue;
      final usedToday = envelopeUsed(i, m) - envelopeUsed(i, m, before: today);
      final reservedAtMidnight = envelopeRemaining(i, m, before: today);
      sum += usedToday < reservedAtMidnight ? usedToday : reservedAtMidnight;
    }
    return sum;
  }

  // ---------------------------------------------------------------- 3.5, 3.6

  BudgetStatus status(DateTime now, int budget) {
    final today = dateOnly(now);
    final m = YearMonth.of(today);
    final daysLeft = m.days - today.day + 1;

    final s = spent(m);
    final todayContrib = _todayContrib(today);
    final r0 = budget - (s - todayContrib) - upcomingFixed(m, decidedBefore: today);
    final f = upcomingFixed(m);

    return BudgetStatus(
      budget: budget,
      spent: s,
      upcomingFixed: f,
      daysLeft: daysLeft,
      dailyBase: floorDiv(r0, daysLeft),
      spentToday: todayContrib - _expectedMatchedToday(today),
      tomorrowBase: daysLeft > 1 ? floorDiv(budget - s - f, daysLeft - 1) : null,
    );
  }

  // ---------------------------------------------------------------- 3.7 P

  /// 평소 패턴 계산용 지출: 특이 지출, 정기 지출 매칭, 이전 달 할부 이월 회차를 뺀다.
  int varSpend(YearMonth m, int fromDay, int toDay) {
    var sum = 0;
    for (final t in ledger.txns) {
      if (t.isUnusual || t.recurringItemId != null) continue;
      if (!m.contains(t.date)) continue; // 이전 달 할부의 이월 회차 제외
      final d = t.date.day;
      if (d < fromDay || d > toDay) continue;
      sum += contrib(t, m);
    }
    return sum;
  }

  bool _hasFullMonth(YearMonth m) {
    final first = ledger.firstRecordDate;
    return first == null || !m.firstDay.isBefore(dateOnly(first));
  }

  Pattern pattern(DateTime now) {
    final today = dateOnly(now);
    final m = YearMonth.of(today);
    final d = today.day;

    final samples = <int>[];
    for (var k = 1; k <= 3; k++) {
      final pm = m.plus(-k);
      if (!_hasFullMonth(pm)) break;
      final from = d < pm.days ? d : pm.days;
      samples.add(varSpend(pm, from, pm.days));
    }
    if (samples.isNotEmpty) {
      return Pattern(_median(samples), PatternSource.history, samples.length);
    }
    if (d == 1) return const Pattern(0, PatternSource.none, 0);
    final daysLeft = m.days - d + 1;
    final pace = varSpend(m, 1, d - 1) * daysLeft ~/ (d - 1);
    return Pattern(pace, PatternSource.thisMonthPace, 0);
  }

  /// 평소 한 달 소비: 최근 완료된 달(최대 3개) 전체 기간 varSpend의 중앙값.
  /// 없으면 이번 달 일평균 × 그 달 일수(데이터 부족).
  int usualMonth(DateTime now, YearMonth target) {
    final m = YearMonth.of(dateOnly(now));
    final samples = <int>[
      for (var k = 1; k <= 3; k++)
        if (_hasFullMonth(m.plus(-k))) varSpend(m.plus(-k), 1, m.plus(-k).days),
    ];
    if (samples.isNotEmpty) return _median(samples);
    final d = dateOnly(now).day;
    if (d <= 1) return 0;
    return varSpend(m, 1, d - 1) * target.days ~/ (d - 1);
  }

  /// 미래 달 예상: 이미 정해진 할부 회차 + 정기 지출 전체 + 예정 지출 + 평소 한 달 소비.
  MonthProjection project(DateTime now, YearMonth target) {
    final known = ledger.txns.fold(0, (s, t) => s + contrib(t, target));
    var fixed = 0;
    for (final i in ledger.recurringItems) {
      if (i.active) fixed += i.amount;
    }
    fixed += plannedIn(target);
    return MonthProjection(target, known, fixed, usualMonth(now, target));
  }

  static int _median(List<int> xs) {
    final s = [...xs]..sort();
    final mid = s.length ~/ 2;
    return s.length.isOdd ? s[mid] : (s[mid - 1] + s[mid]) ~/ 2;
  }

  // ---------------------------------------------------------------- 3.8 구매 판단

  /// 구매 판단(Spec 3.8). 구매일이 다음 달 이후면 그 달 예산·예상으로 판단한다(10/15 결정).
  /// [budgetOf]는 그 달 예산(없으면 직전 달 예산을 이어 쓴 값)을 돌려준다.
  PurchaseSimulation simulatePurchase(
    DateTime now,
    int budget,
    int amount, {
    DateTime? date,
    int installmentMonths = 1,
    int? Function(YearMonth)? budgetOf,
    bool withOptions = true,
  }) {
    final today = dateOnly(now);
    final thisM = YearMonth.of(today);
    final target = date != null && YearMonth.of(date).compareTo(thisM) > 0 ? YearMonth.of(date) : thisM;
    final parts = splitInstallment(amount, installmentMonths);

    late final PurchaseSimulation sim;
    if (target == thisM) {
      final st = status(now, budget);
      final p = pattern(now).amount;
      final projected = st.spent + st.upcomingFixed + p + parts.first;
      final over = projected - budget;
      sim = PurchaseSimulation(
        verdict: judgeOver(over, budget),
        month: thisM,
        budget: budget,
        remainingAfter: st.remaining - parts.first,
        todayAvailableAfter: st.available - parts.first,
        projectedMonthEnd: projected,
        projectedOver: over,
        pattern: p,
      );
    } else {
      final b = budgetOf?.call(target) ?? budget;
      final proj = project(now, target);
      final projected = proj.total + parts.first;
      sim = PurchaseSimulation(
        verdict: judgeOver(projected - b, b),
        month: target,
        budget: b,
        remainingAfter: b - proj.known - proj.fixed - parts.first,
        todayAvailableAfter: null,
        projectedMonthEnd: projected,
        projectedOver: projected - b,
        pattern: proj.usual,
      );
    }
    if (!withOptions || installmentMonths > 1 || sim.verdict == Verdict.ok) return sim;
    return PurchaseSimulation(
      verdict: sim.verdict,
      month: sim.month,
      budget: sim.budget,
      remainingAfter: sim.remainingAfter,
      todayAvailableAfter: sim.todayAvailableAfter,
      projectedMonthEnd: sim.projectedMonthEnd,
      projectedOver: sim.projectedOver,
      pattern: sim.pattern,
      installmentOptions: [for (final n in [2, 3]) _installmentOption(now, budget, amount, n, target, budgetOf)],
    );
  }

  /// 금액 범위 질문("10만 원대")용 경계(10/15 결정): 일시불로 이 금액까지는 ok, 그다음 금액까지는 conditional.
  /// 1,000원 단위로 내려(보수적으로) 읽기 쉽게 한다. 음수면 그 판단이 나오는 금액이 없다.
  (int okMax, int conditionalMax, YearMonth month, int budget) thresholds(
    DateTime now,
    int budget, {
    DateTime? date,
    int? Function(YearMonth)? budgetOf,
  }) {
    final base = simulatePurchase(now, budget, 0, date: date, budgetOf: budgetOf, withOptions: false);
    int floor(int v) => v < 0 ? -1 : v ~/ 1000 * 1000;
    return (floor(-base.projectedOver), floor(base.budget ~/ 10 - base.projectedOver), base.month, base.budget);
  }

  /// n개월 할부일 때 달마다(구매 달부터) 그 회차를 더한 예상과 판단.
  InstallmentOption _installmentOption(
    DateTime now,
    int budget,
    int amount,
    int n,
    YearMonth start,
    int? Function(YearMonth)? budgetOf,
  ) {
    final parts = splitInstallment(amount, n);
    final thisM = YearMonth.of(dateOnly(now));
    final rows = <(YearMonth, int, Verdict, int)>[];
    for (var k = 0; k < n; k++) {
      final m = start.plus(k);
      if (m == thisM) {
        final st = status(now, budget);
        final over = st.spent + st.upcomingFixed + pattern(now).amount + parts[k] - budget;
        rows.add((m, parts[k], judgeOver(over, budget), over));
      } else {
        final b = budgetOf?.call(m) ?? budget;
        final over = project(now, m).total + parts[k] - b;
        rows.add((m, parts[k], judgeOver(over, b), over));
      }
    }
    return InstallmentOption(n, rows);
  }
}
