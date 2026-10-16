// 지출 분석 계산(10/16). 분석 화면의 그래프와 상담 툴(compare_spending, plan_recovery)이 같은 함수를 쓴다.
// Flutter에 의존하지 않는다.
import 'budget_engine.dart';
import 'category_summary.dart';
import 'models.dart';

int _median(List<int> xs) {
  final s = [...xs]..sort();
  final mid = s.length ~/ 2;
  return s.length.isOdd ? s[mid] : (s[mid - 1] + s[mid]) ~/ 2;
}

/// [now] 기준 [from]번째 전 달부터 [count]개월 중 기록이 처음부터 있는 달(첫 기록일 이후).
List<YearMonth> recentFullMonths(DateTime now, DateTime? firstRecord, {int from = 1, int count = 3}) {
  final m = YearMonth.of(now);
  return [
    for (var k = from; k < from + count; k++)
      if (firstRecord == null || !m.plus(-k).firstDay.isBefore(dateOnly(firstRecord))) m.plus(-k),
  ];
}

/// [m]의 [fromDay]~[toDay]일 카테고리별 지출(특이 지출 제외).
Map<String, int> categoryTotalsInDays(List<SpendItem> items, YearMonth m, int fromDay, int toDay) {
  final out = <String, int>{};
  final to = toDay > m.days ? m.days : toDay;
  for (final i in items) {
    if (i.isUnusual || !m.contains(i.date) || i.date.day < fromDay || i.date.day > to) continue;
    final n = i.categoryName ?? unconfirmedCategoryName;
    out[n] = (out[n] ?? 0) + i.amount;
  }
  return out;
}

/// 카테고리별 "평소": [months] 각각의 [fromDay]~[toDay] 지출의 중앙값. 그 달에 없던 카테고리는 0으로 센다.
Map<String, int> usualByCategory(List<SpendItem> items, List<YearMonth> months, int fromDay, int toDay) {
  if (months.isEmpty) return {};
  final per = [for (final pm in months) categoryTotalsInDays(items, pm, fromDay, toDay)];
  final names = {for (final x in per) ...x.keys};
  return {for (final n in names) n: _median([for (final x in per) x[n] ?? 0])};
}

class CategoryDiff {
  const CategoryDiff(this.name, this.amount, this.usual);

  final String name;
  final int amount;
  final int usual;
  int get diff => amount - usual;
}

class CategoryComparison {
  const CategoryComparison(this.rows, this.monthsUsed);

  /// 평소보다 많이 쓴 순.
  final List<CategoryDiff> rows;

  /// "평소" 계산에 쓴 달 수(0이면 비교할 기록이 없음).
  final int monthsUsed;

  int get total => rows.fold(0, (s, r) => s + r.amount);
  int get usualTotal => rows.fold(0, (s, r) => s + r.usual);
}

/// 카테고리별 평소 대비. 이번 달 = 1일~오늘 vs 지난 달들(최대 3개)의 같은 기간,
/// [lastMonth]면 지난달 전체 vs 그 전 달들(최대 3개). 특이 지출 제외.
CategoryComparison compareCategories(List<SpendItem> items, DateTime now, DateTime? firstRecord, {bool lastMonth = false}) {
  final m = YearMonth.of(now);
  final Map<String, int> cur;
  final List<YearMonth> months;
  final int fromDay = 1;
  final int toDay;
  if (lastMonth) {
    final lm = m.plus(-1);
    cur = categoryTotalsInDays(items, lm, 1, lm.days);
    months = recentFullMonths(now, firstRecord, from: 2);
    toDay = 31;
  } else {
    toDay = dateOnly(now).day;
    cur = categoryTotalsInDays(items, m, 1, toDay);
    months = recentFullMonths(now, firstRecord);
  }
  final usual = usualByCategory(items, months, fromDay, toDay);
  final rows = [
    for (final n in {...cur.keys, ...usual.keys}) CategoryDiff(n, cur[n] ?? 0, usual[n] ?? 0),
  ]..sort((a, b) => b.diff.compareTo(a.diff));
  return CategoryComparison(rows, months.length);
}

/// 이번 달 페이스 그래프용(10/16).
class MonthPace {
  const MonthPace({
    required this.month,
    required this.today,
    required this.actual,
    required this.usual,
    required this.budget,
    required this.projectedEnd,
  });

  final YearMonth month;
  final int today;

  /// 1일~오늘 누적 지출(길이 = today).
  final List<int> actual;

  /// 지난 달들 같은 날짜까지의 누적 지출 중앙값(길이 = 이번 달 일수). 기록이 없으면 null.
  final List<int>? usual;
  final int budget;

  /// 지금까지 + 남은 정기·예정 지출 + 평소 남은 기간 소비(엔진의 E, Spec 3.8과 같은 식).
  final int projectedEnd;

  int get spentSoFar => actual.isEmpty ? 0 : actual.last;
  int get projectedOver => projectedEnd - budget;
}

MonthPace monthPace(List<SpendItem> items, BudgetEngine engine, DateTime now, int budget) {
  final m = YearMonth.of(now);
  final today = dateOnly(now).day;
  List<int> cumulative(List<int> daily) {
    var s = 0;
    return [for (final v in daily) s += v];
  }

  final actual = cumulative(dailyTotals(items, m)).sublist(0, today);
  final months = recentFullMonths(now, engine.ledger.firstRecordDate);
  List<int>? usual;
  if (months.isNotEmpty) {
    final per = [for (final pm in months) cumulative(dailyTotals(items, pm))];
    // 이번 달이 더 길면 그 달의 말일 값을 이어 쓴다
    usual = [
      for (var d = 0; d < m.days; d++) _median([for (final c in per) c[d < c.length ? d : c.length - 1]]),
    ];
  }
  final st = engine.status(now, budget);
  final spent = actual.isEmpty ? 0 : actual.last;
  return MonthPace(
    month: m,
    today: today,
    actual: actual,
    usual: usual,
    budget: budget,
    projectedEnd: spent + st.upcomingFixed + engine.pattern(now).amount,
  );
}
