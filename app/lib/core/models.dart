// 예산 계산에 쓰는 순수 데이터 모델. Flutter·DB에 의존하지 않는다(Spec 2장).
// 금액은 모두 원 단위 int, 날짜는 KST 기준 날짜(시각 없음)로 다룬다.

/// 날짜에서 시각을 버린 값. 모든 비교는 이 값으로 한다.
DateTime dateOnly(DateTime t) => DateTime(t.year, t.month, t.day);

/// `yyyy-MM` 단위 월.
class YearMonth implements Comparable<YearMonth> {
  const YearMonth(this.year, this.month);

  factory YearMonth.of(DateTime t) => YearMonth(t.year, t.month);

  /// `2026-10` 형식.
  factory YearMonth.parse(String s) {
    final parts = s.split('-');
    return YearMonth(int.parse(parts[0]), int.parse(parts[1]));
  }

  final int year;
  final int month;

  YearMonth plus(int months) {
    final index = year * 12 + (month - 1) + months;
    return YearMonth(index ~/ 12, index % 12 + 1);
  }

  int get days => DateTime(year, month + 1, 0).day;
  DateTime get firstDay => DateTime(year, month, 1);
  DateTime get lastDay => DateTime(year, month, days);

  /// 결제일이 그 달 일수보다 크면 말일로 본다(Spec 3.4).
  DateTime dayClamped(int day) => DateTime(year, month, day > days ? days : day);

  bool contains(DateTime t) => t.year == year && t.month == month;

  @override
  int compareTo(YearMonth other) => (year * 12 + month).compareTo(other.year * 12 + other.month);

  @override
  bool operator ==(Object other) => other is YearMonth && other.year == year && other.month == month;

  @override
  int get hashCode => year * 12 + month;

  @override
  String toString() => '$year-${month.toString().padLeft(2, '0')}';
}

enum TxnKind { approval, cancel, manual }

/// 결제 1건(Spec 2.1 transactions의 계산용 부분).
class Txn {
  const Txn({
    required this.id,
    required this.amount,
    required this.date,
    this.kind = TxnKind.approval,
    this.installmentMonths = 1,
    this.cancelled = false,
    this.excludedFromSums = false,
    this.isUnusual = false,
    this.recurringItemId,
  });

  final int id;

  /// 승인은 양수, 취소는 음수.
  final int amount;

  /// 승인(또는 취소) 날짜.
  final DateTime date;
  final TxnKind kind;
  final int installmentMonths;

  /// 전액 취소되어 합계에서 빠진 승인 건(status=CANCELLED).
  final bool cancelled;

  /// 같은 달 전액 취소로 원거래를 상쇄한 CANCEL 행처럼 합계에서 제외할 행(Spec 4.4-2).
  final bool excludedFromSums;
  final bool isUnusual;

  /// 매칭된 정기 지출. 있으면 평소 패턴 P에서 제외한다(Spec 3.7).
  final int? recurringItemId;

  bool get isInstallment => kind == TxnKind.approval && installmentMonths > 1;
}

/// 할부 회차(Spec 2.1 installment_schedules).
class InstallmentRow {
  const InstallmentRow({
    required this.txnId,
    required this.seq,
    required this.month,
    required this.amount,
    this.voided = false,
  });

  final int txnId;
  final int seq;
  final YearMonth month;
  final int amount;
  final bool voided;
}

/// 정기 지출 항목(Spec 2.1 recurring_items).
class RecurringItem {
  const RecurringItem({
    required this.id,
    required this.name,
    required this.amount,
    required this.dueDay,
    this.isEstimate = false,
    this.active = true,
    this.matchPattern = '',
    this.amountTolerancePct = 30,
    this.isEnvelope = false,
  });

  final int id;
  final String name;
  final int amount;
  final int dueDay;
  final bool isEstimate;
  final bool active;

  /// 실제 결제의 가맹점(merchant_norm)에 이 문구가 들어 있으면 매칭 후보(Spec F5).
  final String matchPattern;

  /// 예정액 대비 허용 오차(%). null이면 금액을 보지 않는다(전기·가스처럼 금액이 크게 변하는 항목).
  final int? amountTolerancePct;

  /// 월 예약형(교통비처럼 한 달에 여러 번 나눠 나가는 지출, 10/14 결정).
  /// 매달 [amount]를 미리 떼어 두고, 가맹점이 [matchPattern]에 맞는 결제가 들어올 때마다 그만큼 줄어든다.
  final bool isEnvelope;
}

/// 한 번만 나갈 예정인 지출(축의금, 경조사비 등). 그 달 예산에서 미리 뺀다(10/15 결정).
class PlannedExpense {
  const PlannedExpense({required this.id, required this.name, required this.amount, required this.date, this.doneOn});

  final int id;
  final String name;
  final int amount;

  /// 낼 날짜. 이 날이 속한 달의 F에 들어간다.
  final DateTime date;

  /// [냈어요]를 누른 날(그때 실제 지출이 MANUAL 거래로 기록된다). null이면 아직 예정.
  final DateTime? doneOn;
}

enum RecurringMatchStatus { paid, skipped }

/// 정기 지출의 월별 처리 기록(Spec 2.1 recurring_matches).
class RecurringMatch {
  const RecurringMatch({
    required this.itemId,
    required this.month,
    required this.status,
    required this.decidedOn,
    this.txnId,
  });

  final int itemId;
  final YearMonth month;
  final RecurringMatchStatus status;

  /// 매칭(또는 [이번 달 없음])이 생긴 날. 오늘 0시 기준 F를 다시 만들 때 쓴다(Spec 3.6).
  final DateTime decidedOn;
  final int? txnId;
}
