import 'budget_engine.dart';
import 'budget_plan.dart';
import 'category_summary.dart';
import 'models.dart';

/// 구매 상담 에이전트의 툴을 앱 안에서 실행한다(PRD 5장).
/// 서버에는 여기서 만든 집계 숫자만 간다. 거래 원본·가맹점 목록은 보내지 않는다.
/// 금액마다 `*_text`(예: "216,000원")를 같이 넣어 LLM이 그대로 인용하게 한다.
class AgentToolbox {
  AgentToolbox({
    required this.engine,
    required this.budget,
    required this.items,
    required this.now,
    this.budgets = const [],
  });

  final BudgetEngine engine;

  /// 이번 달 예산. 없으면 null.
  final int? budget;
  final List<SpendItem> items;
  final DateTime now;

  /// 월별 예산 목록. 미래 달 예산이 없으면 직전 달 예산을 이어 쓴다(10/15 결정).
  final List<MonthlyBudget> budgets;

  /// 상담이 제안한 예정 지출. 사용자가 화면에서 [등록]을 눌러야 저장된다.
  final List<({String name, int amount, DateTime date})> proposedPlans = [];

  static String won(int v) {
    final s = v.abs().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
    return '${v < 0 ? '-' : ''}$s원';
  }

  static Map<String, Object?> _money(String key, int v) => {key: v, '${key}_text': won(v)};

  static String _verdict(Verdict v) => switch (v) {
    Verdict.ok => 'ok',
    Verdict.conditional => 'conditional',
    Verdict.postpone => 'postpone',
  };

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
    'simulate_range' => simulateRange(
      (args['min'] as num?)?.toInt() ?? 0,
      (args['max'] as num?)?.toInt() ?? 0,
      date: args['date'] == null ? null : DateTime.tryParse(args['date'] as String),
    ),
    'get_category_summary' => categorySummary(
      args['period'] as String? ?? 'this_month',
      args['include_unusual'] as bool? ?? true,
    ),
    'add_planned_expense' => proposePlanned(
      args['name'] as String? ?? '예정 지출',
      (args['amount'] as num?)?.toInt() ?? 0,
      DateTime.tryParse(args['date'] as String? ?? ''),
    ),
    'plan_recovery' => planRecovery(),
    'compare_spending' => compareSpending(args['window'] as String? ?? 'this_month'),
    _ => {'error': 'unknown tool $name'},
  };

  /// 줄이기 어려운 카테고리(회복 계획의 "줄일 곳" 후보에서 뺀다).
  static const _hardToCut = {'통신', '공과금', '구독', '연회비', '교통', '의료', '교육'};

  /// 카테고리별 [fromDay]~[toDay] 지출(특이 지출 제외)의 최근 완료 달(최대 3개) 중앙값. 그 달에 없던 카테고리는 0으로 센다.
  Map<String, int> _usualByCategory(int fromDay, int toDay) {
    final m = YearMonth.of(now);
    final first = engine.ledger.firstRecordDate;
    final months = [
      for (var k = 1; k <= 3; k++)
        if (first == null || !m.plus(-k).firstDay.isBefore(dateOnly(first))) m.plus(-k),
    ];
    if (months.isEmpty) return {};
    final perMonth = [for (final pm in months) _byCategory(pm, fromDay, toDay)];
    final names = {for (final x in perMonth) ...x.keys};
    return {
      for (final n in names) n: _median([for (final x in perMonth) x[n] ?? 0]),
    };
  }

  Map<String, int> _byCategory(YearMonth m, int fromDay, int toDay) {
    final out = <String, int>{};
    final to = toDay > m.days ? m.days : toDay;
    for (final i in items) {
      if (i.isUnusual || !m.contains(i.date) || i.date.day < fromDay || i.date.day > to) continue;
      final n = i.categoryName ?? unconfirmedCategoryName;
      out[n] = (out[n] ?? 0) + i.amount;
    }
    return out;
  }

  static int _median(List<int> xs) {
    final s = [...xs]..sort();
    final mid = s.length ~/ 2;
    return s.length.isOdd ? s[mid] : (s[mid - 1] + s[mid]) ~/ 2;
  }

  /// 이미 넘었거나 넘을 것 같을 때: 하루 얼마를 줄여야 하는지, 어디서 줄일 수 있는지(10/16, 일상 대화형 상담).
  Map<String, Object?> planRecovery() {
    final b = budget;
    if (b == null) return _noBudget();
    final st = engine.status(now, b);
    final p = engine.pattern(now).amount;
    final over = st.spent + st.upcomingFixed + p - b; // 평소대로 쓰면 월말 초과액
    final days = st.daysLeft;
    final target = p - over; // 남은 기간에 쓸 수 있는 변동 지출
    final d = dateOnly(now).day;
    final m = YearMonth.of(now);
    final usualRest = _usualByCategory(d, m.days);
    final cuttable = usualRest.entries.where((e) => !_hardToCut.contains(e.key) && e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    int up100(int v) => v <= 0 ? 0 : (v + 99) ~/ 100 * 100;
    int down100(int v) => v <= 0 ? 0 : v ~/ 100 * 100;
    return {
      ..._money('budget', b),
      ..._money('spent', st.spent),
      ..._money('upcoming_fixed', st.upcomingFixed),
      'days_left': days,
      ..._money('month_over_now', st.monthOver),
      ..._money('usual_rest_of_month', p),
      ..._money('projected_over_if_usual', over),
      'status': over <= 0 ? 'on_track' : (target >= 0 ? 'recoverable' : 'not_recoverable_this_month'),
      if (over > 0) ..._money('total_cut_needed', over),
      // 못 메우는 달에는 하루 감축액이 평소 하루 소비보다 커서 실현할 수 없는 조언이 된다(평가 v4) → 넣지 않는다
      if (over > 0 && target >= 0) ..._money('daily_cut_needed', up100((over + days - 1) ~/ days)),
      if (over > 0 && target >= 0) ..._money('daily_spend_target', down100(target ~/ days)),
      if (over > 0 && target < 0) ..._money('over_even_if_zero_spend', -target),
      'cut_candidates': [
        for (final e in cuttable.take(3))
          {'category': e.key, ..._money('usual_rest', e.value), ..._money('half_saves', down100(e.value ~/ 2))},
      ],
      'note': '평소대로 쓰면 월말에 얼마나 넘는지 기준. cut_candidates는 지난 몇 달의 같은 남은 기간 카테고리 소비 중앙값(특이 지출 제외, 고정성 지출 제외). 계산된 값만 인용',
    };
  }

  /// 카테고리별 평소 대비. this_month = 이번 달 1일~오늘 vs 지난 달들의 같은 기간, last_month = 지난 달 전체 vs 그 전 달들.
  Map<String, Object?> compareSpending(String window) {
    final m = YearMonth.of(now);
    final Map<String, int> cur;
    final Map<String, int> usual;
    if (window == 'last_month') {
      final lm = m.plus(-1);
      cur = _byCategory(lm, 1, lm.days);
      final first = engine.ledger.firstRecordDate;
      final months = [
        for (var k = 2; k <= 4; k++)
          if (first == null || !m.plus(-k).firstDay.isBefore(dateOnly(first))) m.plus(-k),
      ];
      final per = [for (final pm in months) _byCategory(pm, 1, pm.days)];
      final names = {for (final x in per) ...x.keys};
      usual = {for (final n in names) n: per.isEmpty ? 0 : _median([for (final x in per) x[n] ?? 0])};
    } else {
      final d = dateOnly(now).day;
      cur = _byCategory(m, 1, d);
      usual = _usualByCategory(1, d);
    }
    final names = {...cur.keys, ...usual.keys};
    final rows = [
      for (final n in names) (n, cur[n] ?? 0, usual[n] ?? 0),
    ]..sort((a, b) => (b.$2 - b.$3).compareTo(a.$2 - a.$3));
    final curTotal = cur.values.fold(0, (s, v) => s + v), usualTotal = usual.values.fold(0, (s, v) => s + v);
    return {
      'window': window,
      ..._money('total', curTotal),
      ..._money('usual_total', usualTotal),
      ..._money('total_diff', curTotal - usualTotal),
      'categories': [
        for (final (n, c, u) in rows)
          {'category': n, ..._money('amount', c), ..._money('usual', u), ..._money('diff', c - u)},
      ],
      'note': '특이 지출 제외. usual은 지난 몇 달 같은 기간의 카테고리별 중앙값. diff가 양수면 평소보다 많이 씀',
    };
  }

  Map<String, Object?> _noBudget() => {'error': '이번 달 예산이 설정되지 않았어요. 예산 설정에서 먼저 정해 주세요.'};

  /// 그 달 예산과, 그 달 예산이 따로 없어 직전 달 값을 이어 썼는지.
  (int?, bool) _budgetOf(YearMonth m) {
    final b = budgets.isEmpty && m == YearMonth.of(now) ? budget : budgetFor(budgets, m);
    final carried = budgets.isNotEmpty && !budgets.any((x) => x.month == m);
    return (b ?? budget, carried || (budgets.isEmpty && m != YearMonth.of(now)));
  }

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
    final end = today.add(Duration(days: days.clamp(1, 62)));
    final handled = {for (final x in engine.ledger.recurringMatches) '${x.itemId}|${x.month}'};
    final list = <Map<String, Object?>>[];
    for (var m = YearMonth.of(today); !m.firstDay.isAfter(end); m = m.plus(1)) {
      for (final i in engine.ledger.recurringItems) {
        if (!i.active || i.isEnvelope || handled.contains('${i.id}|$m')) continue;
        final due = m.dayClamped(i.dueDay);
        if (due.isBefore(today) || due.isAfter(end)) continue;
        list.add({
          'name': i.name,
          'kind': 'recurring',
          'amount': i.amount,
          'amount_text': '${i.isEstimate ? '약 ' : ''}${won(i.amount)}',
          'due_date': _ymd(due),
        });
      }
    }
    for (final p in engine.ledger.plannedExpenses) {
      final d = dateOnly(p.date);
      if (p.doneOn != null || d.isAfter(end)) continue;
      list.add({'name': p.name, 'kind': 'planned', 'amount': p.amount, 'amount_text': won(p.amount), 'due_date': _ymd(d)});
    }
    list.sort((a, b) => (a['due_date'] as String).compareTo(b['due_date'] as String));
    final month = YearMonth.of(today);
    for (final i in engine.ledger.recurringItems) {
      if (!i.active || !i.isEnvelope) continue;
      final left = engine.envelopeRemaining(i, month);
      if (left <= 0) continue;
      list.add({
        'name': '${i.name}(이번 달 남은 예약분)',
        'kind': 'envelope',
        'amount': left,
        'amount_text': '약 ${won(left)}',
        'due_date': null,
      });
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
    final sim = engine.simulatePurchase(
      now,
      b,
      amount,
      date: date,
      installmentMonths: installmentMonths,
      budgetOf: (m) => _budgetOf(m).$1,
    );
    final thisMonth = sim.month == YearMonth.of(now);
    final carried = _budgetOf(sim.month).$2;
    return {
      'verdict': _verdict(sim.verdict),
      'rule': '예상 월말 지출 ≤ 예산이면 ok, 초과액이 예산의 10% 이하면 conditional, 그 이상이면 postpone',
      'judged_month': '${sim.month.year}-${sim.month.month.toString().padLeft(2, '0')}',
      'judged_month_text': thisMonth ? '이번 달(${sim.month.month}월)' : '${sim.month.month}월',
      if (!thisMonth)
        'month_note': carried
            ? '${sim.month.month}월 예산이 아직 없어 직전 달 예산을 이어 썼고, 정기 지출 전체·예정 지출·평소 한 달 소비로 예상함'
            : '${sim.month.month}월 예산과 정기 지출 전체·예정 지출·평소 한 달 소비로 예상함',
      ..._money('amount', amount),
      if (parts.length > 1) 'parts_text': parts.map(won).join(' + '),
      'installment_months': installmentMonths,
      ..._money('remaining_after', sim.remainingAfter),
      if (sim.todayAvailableAfter != null)
        ..._money('today_available_after', sim.todayAvailableAfter! < 0 ? 0 : sim.todayAvailableAfter!),
      ..._money('projected_month_end', sim.projectedMonthEnd),
      ..._money('projected_over', sim.projectedOver),
      ..._money(thisMonth ? 'usual_rest_of_month' : 'usual_month', sim.pattern),
      ..._money('budget', sim.budget),
      if (sim.installmentOptions.isNotEmpty)
        'installment_options': [
          for (final o in sim.installmentOptions)
            {
              'months': o.months,
              'worst_verdict': _verdict(o.worst),
              'per_month': [
                for (final (m, part, v, over) in o.perMonth)
                  {'month': '${m.month}월', ..._money('amount', part), 'verdict': _verdict(v), ..._money('projected_over', over)},
              ],
            },
        ],
      if (sim.installmentOptions.isNotEmpty) 'installment_note': '2·3개월 무이자 할부는 카드사·가맹점마다 다르므로 결제 전에 카드사 앱에서 확인',
    };
  }

  /// 금액 범위 질문: 범위를 판단별 구간으로 나눈다(일시불 기준, 10/15 결정).
  Map<String, Object?> simulateRange(int min, int max, {DateTime? date}) {
    if (min <= 0 || max < min) return {'error': 'min ≤ max인 원 단위 금액 범위가 필요해요.'};
    final b = budget;
    if (b == null) return _noBudget();
    final (okMax, condMax, month, _) = engine.thresholds(now, b, date: date, budgetOf: (m) => _budgetOf(m).$1);
    final segments = <Map<String, Object?>>[];
    void seg(int from, int to, Verdict v) {
      if (from > max || to < min || to < from) return;
      final f = from < min ? min : from;
      final t = to > max ? max : to;
      // 구간 시작 금액은 넣지 않는다(301,001원 같은 숫자를 그대로 인용해서, 평가 v3)
      if (f <= t) segments.add({..._money('up_to', t), 'verdict': _verdict(v)});
    }

    seg(min, okMax, Verdict.ok);
    seg(okMax < 0 ? min : okMax + 1, condMax, Verdict.conditional);
    seg(condMax < 0 ? min : condMax + 1, max, Verdict.postpone);
    final thisMonth = month == YearMonth.of(now);
    return {
      'judged_month_text': thisMonth ? '이번 달(${month.month}월)' : '${month.month}월',
      if (!thisMonth && _budgetOf(month).$2) 'month_note': '${month.month}월 예산이 아직 없어 직전 달 예산을 이어 씀',
      ..._money('min', min),
      ..._money('max', max),
      'segments': segments,
      'note': '일시불 기준. 경계는 1,000원 단위로 내림. 구간은 min부터 순서대로, 각 구간은 up_to까지',
    };
  }

  /// 상담이 예정 지출 등록을 제안. 여기서는 저장하지 않고 화면에 [등록] 버튼을 띄운다.
  Map<String, Object?> proposePlanned(String name, int amount, DateTime? date) {
    if (amount <= 0 || date == null) return {'error': '예정 지출은 금액과 날짜(yyyy-MM-dd)가 필요해요. 사용자에게 물어보세요.'};
    proposedPlans.add((name: name, amount: amount, date: date));
    return {
      'status': 'needs_user_confirmation',
      'name': name,
      ..._money('amount', amount),
      'date': _ymd(date),
      'note': '아직 등록 안 됨. 사용자가 화면의 [등록] 버튼을 눌러야 예산에 반영된다. 등록 전 계산에는 포함되지 않았다',
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
