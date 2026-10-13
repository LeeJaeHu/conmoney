import 'installments.dart';
import 'models.dart';

/// 계산에 필요한 원장 전체. DB에서 읽어 만든다.
class Ledger {
  Ledger({
    required this.txns,
    required this.installments,
    this.recurringItems = const [],
    this.recurringMatches = const [],
    this.firstRecordDate,
  });

  final List<Txn> txns;
  final List<InstallmentRow> installments;
  final List<RecurringItem> recurringItems;
  final List<RecurringMatch> recurringMatches;

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

enum Verdict { ok, conditional, postpone, nextMonth }

class PurchaseSimulation {
  const PurchaseSimulation({
    required this.verdict,
    required this.remainingAfter,
    required this.todayAvailableAfter,
    required this.projectedMonthEnd,
    required this.projectedOver,
    required this.pattern,
  });

  final Verdict verdict;
  final int remainingAfter;
  final int todayAvailableAfter;
  final int projectedMonthEnd;

  /// 예상 월말 초과액(음수면 남음).
  final int projectedOver;
  final Pattern pattern;
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
  int unusualSpent(YearMonth m) =>
      ledger.txns.where((t) => t.isUnusual).fold(0, (s, t) => s + contrib(t, m));

  /// 오늘 승인·취소된 거래의 기여분.
  int _todayContrib(DateTime today) {
    final m = YearMonth.of(today);
    return ledger.txns
        .where((t) => dateOnly(t.date) == today)
        .fold(0, (s, t) => s + contrib(t, m));
  }

  /// F: 이번 달 아직 처리(PAID/SKIPPED)되지 않은 활성 정기 지출 예정액.
  /// [decidedBefore]를 주면 그 날 이후에 생긴 처리 기록은 없던 것으로 본다(오늘 0시 기준 F).
  int upcomingFixed(YearMonth m, {DateTime? decidedBefore}) {
    final handled = <int>{
      for (final x in ledger.recurringMatches)
        if (x.month == m && (decidedBefore == null || dateOnly(x.decidedOn).isBefore(decidedBefore)))
          x.itemId,
    };
    return ledger.recurringItems
        .where((i) => i.active && !handled.contains(i.id))
        .fold(0, (s, i) => s + i.amount);
  }

  /// 오늘 정기 지출에 매칭된 거래의 예정액 합(이미 F로 빼 두었던 금액).
  int _expectedMatchedToday(DateTime today) {
    final m = YearMonth.of(today);
    final byId = {for (final i in ledger.recurringItems) i.id: i};
    var sum = 0;
    for (final x in ledger.recurringMatches) {
      if (x.month == m && x.status == RecurringMatchStatus.paid && dateOnly(x.decidedOn) == today) {
        sum += byId[x.itemId]?.amount ?? 0;
      }
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

  static int _median(List<int> xs) {
    final s = [...xs]..sort();
    final mid = s.length ~/ 2;
    return s.length.isOdd ? s[mid] : (s[mid - 1] + s[mid]) ~/ 2;
  }

  // ---------------------------------------------------------------- 3.8 구매 판단

  PurchaseSimulation simulatePurchase(
    DateTime now,
    int budget,
    int amount, {
    DateTime? date,
    int installmentMonths = 1,
  }) {
    final st = status(now, budget);
    final p = pattern(now);
    final today = dateOnly(now);
    final thisMonth = splitInstallment(amount, installmentMonths).first;
    final projected = st.spent + st.upcomingFixed + p.amount + thisMonth;
    final over = projected - budget;

    final Verdict verdict;
    if (date != null && YearMonth.of(date).compareTo(YearMonth.of(today)) > 0) {
      verdict = Verdict.nextMonth;
    } else if (over <= 0) {
      verdict = Verdict.ok;
    } else if (over <= budget ~/ 10) {
      verdict = Verdict.conditional;
    } else {
      verdict = Verdict.postpone;
    }

    return PurchaseSimulation(
      verdict: verdict,
      remainingAfter: st.remaining - thisMonth,
      todayAvailableAfter: st.available - thisMonth,
      projectedMonthEnd: projected,
      projectedOver: over,
      pattern: p,
    );
  }
}
