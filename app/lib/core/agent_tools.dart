import 'budget_engine.dart';
import 'category_summary.dart';
import 'models.dart';

/// 구매 상담 에이전트의 툴을 앱 안에서 실행한다(PRD 5장).
/// 서버에는 여기서 만든 집계 숫자만 간다. 거래 원본·가맹점 목록은 보내지 않는다.
/// 금액마다 `*_text`(예: "216,000원")를 같이 넣어 LLM이 그대로 인용하게 한다.
class AgentToolbox {
  AgentToolbox({required this.engine, required this.budget, required this.items, required this.now});

  final BudgetEngine engine;

  /// 이번 달 예산. 없으면 null.
  final int? budget;
  final List<SpendItem> items;
  final DateTime now;

  static String won(int v) {
    final s = v.abs().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
    return '${v < 0 ? '-' : ''}$s원';
  }

  static Map<String, Object?> _money(String key, int v) => {key: v, '${key}_text': won(v)};

  Map<String, Object?> run(String name, Map<String, Object?> args) => switch (name) {
    'get_budget_status' => budgetStatus(),
    'get_upcoming_fixed' => upcomingFixed((args['days'] as num?)?.toInt() ?? 7),
    'get_spending_pattern' => spendingPattern(args['window'] as String? ?? 'rest_of_month'),
    'simulate_purchase' => simulatePurchase(
      // 여러 건이면 amounts의 합계(LLM이 아니라 코드가 더한다, 평가 v2)
      ((args['amounts'] as List?)?.isNotEmpty ?? false)
          ? (args['amounts'] as List).fold<int>(0, (s, v) => s + (v as num).toInt())
          : (args['amount'] as num).toInt(),
      parts: [for (final v in (args['amounts'] as List?) ?? const []) (v as num).toInt()],
      date: args['date'] == null ? null : DateTime.tryParse(args['date'] as String),
      installmentMonths: (args['installment_months'] as num?)?.toInt() ?? 1,
    ),
    'get_category_summary' => categorySummary(
      args['period'] as String? ?? 'this_month',
      args['include_unusual'] as bool? ?? true,
    ),
    _ => {'error': 'unknown tool $name'},
  };

  Map<String, Object?> _noBudget() => {'error': '이번 달 예산이 설정되지 않았어요. 예산 설정에서 먼저 정해 주세요.'};

  Map<String, Object?> budgetStatus() {
    final b = budget;
    if (b == null) return _noBudget();
    final st = engine.status(now, b);
    return {
      'today': _ymd(now),
      ..._money('budget', st.budget),
      ..._money('spent', st.spent),
      ..._money('upcoming_fixed', st.upcomingFixed),
      ..._money('remaining', st.remaining),
      'days_left': st.daysLeft,
      ..._money('today_available', st.availableShown),
      ..._money('today_over', st.todayOver),
      ..._money('month_over', st.monthOver),
    };
  }

  Map<String, Object?> upcomingFixed(int days) {
    final today = dateOnly(now);
    final end = today.add(Duration(days: days.clamp(1, 31)));
    final handled = {for (final x in engine.ledger.recurringMatches) '${x.itemId}|${x.month}'};
    final list = <Map<String, Object?>>[];
    for (var m = YearMonth.of(today); !m.firstDay.isAfter(end); m = m.plus(1)) {
      for (final i in engine.ledger.recurringItems) {
        if (!i.active || i.isEnvelope || handled.contains('${i.id}|$m')) continue;
        final due = m.dayClamped(i.dueDay);
        if (due.isBefore(today) || due.isAfter(end)) continue;
        list.add({
          'name': i.name,
          'amount': i.amount,
          'amount_text': '${i.isEstimate ? '약 ' : ''}${won(i.amount)}',
          'due_date': _ymd(due),
        });
      }
    }
    list.sort((a, b) => (a['due_date'] as String).compareTo(b['due_date'] as String));
    final month = YearMonth.of(today);
    for (final i in engine.ledger.recurringItems) {
      if (!i.active || !i.isEnvelope) continue;
      final left = engine.envelopeRemaining(i, month);
      if (left <= 0) continue;
      list.add({'name': '${i.name}(이번 달 남은 예약분)', 'amount': left, 'amount_text': '약 ${won(left)}', 'due_date': null});
    }
    return {'days': days, 'items': list, ..._money('total', list.fold(0, (s, e) => s + (e['amount'] as int)))};
  }

  Map<String, Object?> spendingPattern(String window) {
    final today = dateOnly(now);
    if (window == 'rest_of_month') {
      final p = engine.pattern(now);
      return {
        'window': window,
        ..._money('median', p.amount),
        'months_used': p.monthsUsed,
        'source': switch (p.source) {
          PatternSource.history => 'history',
          PatternSource.thisMonthPace => 'this_month_pace',
          PatternSource.none => 'none',
        },
        'note': '특이 지출·정기 지출 제외. 지난 몇 달의 같은 남은 기간 소비 중앙값',
      };
    }
    final from = window == 'this_week'
        ? today.subtract(Duration(days: today.weekday - 1))
        : today.subtract(const Duration(days: 6));
    final sum = items
        .where((i) => !i.isUnusual && !dateOnly(i.date).isBefore(from) && !dateOnly(i.date).isAfter(today))
        .fold(0, (s, i) => s + i.amount);
    return {'window': window, 'from': _ymd(from), 'to': _ymd(today), ..._money('spent', sum), 'note': '특이 지출 제외'};
  }

  Map<String, Object?> simulatePurchase(
    int amount, {
    DateTime? date,
    int installmentMonths = 1,
    List<int> parts = const [],
  }) {
    // 금액 없는 질문에 0원으로 부르는 경우가 있어(평가 v1) 계산하지 않고 되묻게 한다
    if (amount <= 0) return {'error': '금액을 모르면 이 툴을 부르지 말고 사용자에게 금액을 물어보세요.'};
    final b = budget;
    if (b == null) return _noBudget();
    final sim = engine.simulatePurchase(now, b, amount, date: date, installmentMonths: installmentMonths);
    return {
      'verdict': switch (sim.verdict) {
        Verdict.ok => 'ok',
        Verdict.conditional => 'conditional',
        Verdict.postpone => 'postpone',
        Verdict.nextMonth => 'next_month',
      },
      'rule': '예상 월말 지출 ≤ 예산이면 ok, 초과액이 예산의 10% 이하면 conditional, 그 이상이면 postpone',
      ..._money('amount', amount),
      if (parts.length > 1) 'parts_text': parts.map(won).join(' + '),
      'installment_months': installmentMonths,
      ..._money('remaining_after', sim.remainingAfter),
      ..._money('today_available_after', sim.todayAvailableAfter < 0 ? 0 : sim.todayAvailableAfter),
      ..._money('projected_month_end', sim.projectedMonthEnd),
      ..._money('projected_over', sim.projectedOver),
      ..._money('usual_rest_of_month', sim.pattern.amount),
      ..._money('budget', b),
    };
  }

  Map<String, Object?> categorySummary(String period, bool includeUnusual) {
    final m = YearMonth.of(now);
    final (from, to) = switch (period) {
      'last_month' => (m.plus(-1).firstDay, m.plus(-1).lastDay),
      'last_3_months' => (m.plus(-2).firstDay, dateOnly(now)),
      _ => (m.firstDay, dateOnly(now)),
    };
    final s = summarize(items, from, to, includeUnusual: includeUnusual);
    return {
      'period': period,
      'from': _ymd(from),
      'to': _ymd(to),
      ..._money('total', s.total),
      'categories': [
        for (final c in s.categories) {'category': c.name, ..._money('total', c.total), 'count': c.count},
      ],
    };
  }

  static String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
