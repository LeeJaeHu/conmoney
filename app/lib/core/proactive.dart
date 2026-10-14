import 'budget_engine.dart';
import 'models.dart';

/// 먼저 알려주기(Spec F7). 결제 확인 알림과 별개로 하루 최대 1회, 조용한 시간에는 보내지 않는다.
enum AlertType { todayOver, bigFixedSoon, pace }

enum AlertTrigger {
  /// 아침 검사(08:00 이후 첫 백그라운드 실행)
  morning,

  /// 결제가 저장된 직후
  afterTransaction,
}

class ProactiveAlert {
  const ProactiveAlert(this.type, this.title, this.body);

  final AlertType type;
  final String title;
  final String body;

  String get logType => switch (type) {
    AlertType.todayOver => 'TODAY_OVER',
    AlertType.bigFixedSoon => 'BIG_FIXED_SOON',
    AlertType.pace => 'PACE',
  };
}

class QuietHours {
  const QuietHours(this.startHour, this.endHour);

  /// 23시 ~ 8시(Spec F7 기본값)
  static const standard = QuietHours(23, 8);

  final int startHour;
  final int endHour;

  bool contains(DateTime t) =>
      startHour > endHour ? (t.hour >= startHour || t.hour < endHour) : (t.hour >= startHour && t.hour < endHour);
}

String _won(int v) => '${v.abs().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',')}원';

/// "큰 정기 지출" 기준: max(30,000원, 예산의 3%)(Spec F7 `[가정]`).
int bigFixedThreshold(int budget) {
  final pct = budget * 3 ~/ 100;
  return pct > 30000 ? pct : 30000;
}

/// 예상 월말 지출 E = S + F + P(남은 기간).
int projectedMonthEnd(BudgetEngine engine, DateTime now) {
  final m = YearMonth.of(now);
  return engine.spent(m) + engine.upcomingFixed(m) + engine.pattern(now).amount;
}

/// [cutoff] 이전에 있던 거래·처리 기록만 남긴 원장(어제 0시 기준 E를 다시 계산할 때).
Ledger ledgerAsOf(Ledger l, DateTime cutoff) {
  final day = dateOnly(cutoff);
  final txns = [
    for (final t in l.txns)
      if (dateOnly(t.date).isBefore(day)) t,
  ];
  final ids = {for (final t in txns) t.id};
  return Ledger(
    txns: txns,
    installments: [
      for (final r in l.installments)
        if (ids.contains(r.txnId)) r,
    ],
    recurringItems: l.recurringItems,
    recurringMatches: [
      for (final x in l.recurringMatches)
        if (dateOnly(x.decidedOn).isBefore(day)) x,
    ],
    firstRecordDate: l.firstRecordDate,
  );
}

/// 오늘 보낼 알림 하나를 고른다. 보낼 것이 없으면 null.
/// 우선순위: 오늘 초과(결제 직후) > 큰 정기 지출 2일 전(아침) > 월말 초과 예상이 처음 생김(아침).
ProactiveAlert? evaluate({
  required BudgetEngine engine,
  required int? budget,
  required DateTime now,
  required AlertTrigger trigger,
  required bool alreadySentToday,
  QuietHours quiet = QuietHours.standard,
}) {
  if (budget == null || alreadySentToday || quiet.contains(now)) return null;
  final today = dateOnly(now);
  final st = engine.status(now, budget);

  // 1. 오늘 쓸 수 있는 금액을 넘음
  if (trigger == AlertTrigger.afterTransaction) {
    if (st.available >= 0) return null;
    final tomorrow = st.tomorrowBase;
    return ProactiveAlert(
      AlertType.todayOver,
      '오늘 정한 금액을 ${_won(st.todayOver)} 넘었어요',
      tomorrow == null ? '이번 달 마지막 날이에요. 다음 달 예산으로 새로 시작해요.' : '내일부터 하루 ${_won(tomorrow < 0 ? 0 : tomorrow)}으로 맞추면 돼요.',
    );
  }

  // 2. 큰 정기 지출이 2일 안에 나감(이미 F로 빼 둔 금액이라 하루 금액은 그대로)
  final m = YearMonth.of(today);
  final handled = {
    for (final x in engine.ledger.recurringMatches)
      if (x.month == m) x.itemId,
  };
  final threshold = bigFixedThreshold(budget);
  final soon = [
    for (final i in engine.ledger.recurringItems)
      if (i.active && !i.isEnvelope && !handled.contains(i.id) && i.amount >= threshold)
        (i, m.dayClamped(i.dueDay).difference(today).inDays),
  ].where((e) => e.$2 >= 0 && e.$2 <= 2).toList()..sort((a, b) => a.$2.compareTo(b.$2));
  if (soon.isNotEmpty) {
    final (item, days) = soon.first;
    final when = const ['오늘', '내일', '모레'][days];
    return ProactiveAlert(
      AlertType.bigFixedSoon,
      '$when ${item.name} ${item.isEstimate ? '약 ' : ''}${_won(item.amount)}이 나가요',
      '오늘 쓸 수 있는 금액에는 이미 반영돼 있어요.',
    );
  }

  // 3. 월말 초과 예상이 오늘 처음 생김(Spec 3.9)
  final projected = projectedMonthEnd(engine, now);
  if (projected > budget) {
    final yesterday = today.subtract(const Duration(days: 1));
    final wasOver =
        YearMonth.of(yesterday) == m &&
        projectedMonthEnd(BudgetEngine(ledgerAsOf(engine.ledger, today)), yesterday) > budget;
    if (!wasOver) {
      final perDay = st.remaining > 0 ? st.remaining ~/ st.daysLeft : 0;
      return ProactiveAlert(
        AlertType.pace,
        '지금 속도면 월말에 ${_won(projected - budget)} 정도 넘을 수 있어요',
        perDay > 0 ? '남은 ${st.daysLeft}일 동안 하루 ${_won(perDay)} 정도로 쓰면 맞출 수 있어요.' : '이번 달은 꼭 필요한 곳에만 써 볼까요?',
      );
    }
  }
  return null;
}
