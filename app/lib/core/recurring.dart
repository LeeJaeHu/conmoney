import 'models.dart';

/// 정기 지출 탐지·매칭에 쓰는 거래 요약.
class SpendRecord {
  const SpendRecord({
    required this.id,
    required this.merchant,
    required this.date,
    required this.amount,
    this.isUnusual = false,
    this.cancelled = false,
    this.cardId,
    this.recurringItemId,
  });

  final int id;

  /// merchant_norm
  final String merchant;
  final DateTime date;
  final int amount;
  final bool isUnusual;
  final bool cancelled;
  final int? cardId;
  final int? recurringItemId;
}

/// "정기 지출로 등록할까요?" 제안(Spec F5 자동 탐지).
class RecurringSuggestion {
  const RecurringSuggestion({
    required this.merchant,
    required this.amount,
    required this.dueDay,
    required this.isEstimate,
    required this.months,
    this.cardId,
  });

  final String merchant;

  /// 고정이면 가장 최근 금액, 추정이면 최근 3개월 중앙값.
  final int amount;
  final int dueDay;

  /// 금액이 달마다 10% 넘게 변하는 공과금형.
  final bool isEstimate;

  /// 연속으로 나온 개월 수.
  final int months;
  final int? cardId;
}

int _median(List<int> xs) {
  final s = [...xs]..sort();
  final mid = s.length ~/ 2;
  return s.length.isOdd ? s[mid] : (s[mid - 1] + s[mid]) ~/ 2;
}

/// 정기 지출 후보를 찾는다(Spec F5).
/// - 가장 최근 달부터 거꾸로, 한 달에 정확히 한 번씩 연속으로 나온 구간만 본다
/// - 구간 안에서 결제일 차이 ≤ [dayTolerance]일
/// - 금액 차이 ≤ 10%면 고정, 넘으면 추정(공과금형). 추정형은 우연한 반복(편의점 등)을 거르려고 3개월 이상만
/// - 마지막 결제가 이번 달이나 지난달이어야 한다(끊긴 구독은 제외)
/// - 특이 지출·취소 건 제외, [excludedMerchants](이미 등록됨·[아니요]) 제외
List<RecurringSuggestion> detectRecurring(
  List<SpendRecord> records,
  DateTime now, {
  Set<String> excludedMerchants = const {},
  int minMonths = 2,
  int minMonthsEstimate = 3,
  int dayTolerance = 3,
}) {
  final byMerchant = <String, Map<YearMonth, List<SpendRecord>>>{};
  for (final r in records) {
    if (r.isUnusual || r.cancelled || r.amount <= 0) continue;
    if (excludedMerchants.contains(r.merchant)) continue;
    byMerchant.putIfAbsent(r.merchant, () => {}).putIfAbsent(YearMonth.of(r.date), () => []).add(r);
  }

  final thisMonth = YearMonth.of(now);
  final suggestions = <RecurringSuggestion>[];

  byMerchant.forEach((merchant, months) {
    final latest = months.keys.reduce((a, b) => a.compareTo(b) > 0 ? a : b);
    if (latest.compareTo(thisMonth.plus(-1)) < 0) return;
    // 이번 달은 아직 안 나왔을 수 있으므로, 이번 달에 없으면 지난달부터 센다
    final run = <SpendRecord>[];
    for (var m = latest; ; m = m.plus(-1)) {
      final inMonth = months[m];
      if (inMonth == null || inMonth.length != 1) break;
      final r = inMonth.single;
      if (run.isNotEmpty && (r.date.day - run.first.date.day).abs() > dayTolerance) break;
      run.add(r);
    }
    if (run.length < minMonths) return;
    // 가장 최근 달에 여러 번 나온 가맹점(배달·쇼핑)은 위 루프에서 바로 끊겨 여기 오지 않는다

    final amounts = [for (final r in run) r.amount];
    final lo = amounts.reduce((a, b) => a < b ? a : b);
    final hi = amounts.reduce((a, b) => a > b ? a : b);
    final isEstimate = (hi - lo) > lo * 0.1;
    if (isEstimate && run.length < minMonthsEstimate) return;
    suggestions.add(
      RecurringSuggestion(
        merchant: merchant,
        amount: isEstimate ? _median(amounts.take(3).toList()) : run.first.amount,
        dueDay: _median([for (final r in run) r.date.day]),
        isEstimate: isEstimate,
        months: run.length,
        cardId: run.first.cardId,
      ),
    );
  });

  suggestions.sort((a, b) => a.dueDay.compareTo(b.dueDay));
  return suggestions;
}

/// 실제 결제가 이 정기 지출의 이번 달 결제인지(Spec F5 매칭 조건). 카드는 보지 않는다.
bool matchesRecurring(RecurringItem item, SpendRecord r, {int dayWindow = 5}) {
  if (!item.active || r.cancelled) return false;
  final pattern = (item.matchPattern.isEmpty ? item.name : item.matchPattern).toLowerCase();
  if (!r.merchant.toLowerCase().contains(pattern)) return false;
  // 월 예약형은 가맹점만 맞으면 금액·날짜와 상관없이 모두 연결(환불도 연결해 사용액에서 빠지게)
  if (item.isEnvelope) return r.amount != 0;
  if (r.amount <= 0) return false;
  final tol = item.amountTolerancePct;
  if (tol != null && (r.amount - item.amount).abs() * 100 > item.amount * tol) return false;
  final due = YearMonth.of(r.date).dayClamped(item.dueDay);
  return (dateOnly(r.date).difference(due).inDays).abs() <= dayWindow;
}

/// 여러 항목이 맞으면 예정일이 가장 가까운 항목 하나(Spec F5).
RecurringItem? bestMatch(List<RecurringItem> items, SpendRecord r, {Set<int> alreadyPaid = const {}}) {
  RecurringItem? best;
  var bestGap = 1 << 30;
  for (final i in items) {
    if (alreadyPaid.contains(i.id) || !matchesRecurring(i, r)) continue;
    final gap = dateOnly(r.date).difference(YearMonth.of(r.date).dayClamped(i.dueDay)).inDays.abs();
    if (gap < bestGap) {
      best = i;
      bestGap = gap;
    }
  }
  return best;
}

/// 월 예약형 예상액: 최근 [lookbackDays]일 중 결제가 있던 날의 하루 합계 중앙값 × 이번 달 평일 수.
/// 1,000원 단위로 올린다. 결제한 날이 [minDays]일보다 적으면 null(예: 교통비 → 출근일 × 3,100원).
({int amount, int perDay, int days})? estimateEnvelope(
  List<SpendRecord> matching,
  DateTime now, {
  int lookbackDays = 30,
  int minDays = 5,
}) {
  final today = dateOnly(now);
  final from = today.subtract(Duration(days: lookbackDays));
  final daily = <DateTime, int>{};
  for (final r in matching) {
    final day = dateOnly(r.date);
    if (r.cancelled || day.isBefore(from) || day.isAfter(today)) continue;
    daily[day] = (daily[day] ?? 0) + r.amount;
  }
  final totals = [
    for (final v in daily.values)
      if (v > 0) v,
  ];
  if (totals.length < minDays) return null;
  final perDay = _median(totals);
  final m = YearMonth.of(today);
  final weekdays = [
    for (var d = 1; d <= m.days; d++)
      if (DateTime(m.year, m.month, d).weekday <= DateTime.friday) d,
  ].length;
  final amount = ((perDay * weekdays) + 999) ~/ 1000 * 1000;
  return (amount: amount, perDay: perDay, days: weekdays);
}
