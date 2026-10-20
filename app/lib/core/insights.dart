// 소비 특징과 아낄 수 있는 곳(10/20). 지출 분석 화면의 카드와 상담 툴 get_spending_insights가 같은 계산을 쓴다.
// 모든 금액은 여기서 계산하고, AI는 이 결과를 해석·설명만 한다. 서버에는 카테고리 단위 집계만 간다(가맹점 이름 없음).
import 'analysis.dart';
import 'budget_engine.dart';
import 'category_summary.dart';
import 'models.dart';

/// 줄이기 어려운 카테고리(아낄 곳 후보에서 뺀다). 상담의 회복 계획과 같은 기준.
const hardToCutCategories = {'통신', '공과금', '구독', '연회비', '교통', '의료', '교육'};

/// 이 금액 미만 결제를 "소액 결제"로 본다.
const smallPurchaseLimit = 10000;

int _median(List<int> xs) {
  if (xs.isEmpty) return 0;
  final s = [...xs]..sort();
  final mid = s.length ~/ 2;
  return s.length.isOdd ? s[mid] : (s[mid - 1] + s[mid]) ~/ 2;
}

int _down100(int v) => v <= 0 ? 0 : v ~/ 100 * 100;

class CategoryInsight {
  const CategoryInsight(this.name, this.usualMonthly, this.share, this.change);

  final String name;

  /// 최근 완료 3개월 월 합계의 중앙값.
  final int usualMonthly;

  /// 평소 한 달 변동 지출 중 비율(0~1).
  final double share;

  /// 최근 3개월 평균 − 그 전 달들(2~3개월) 평균. 비교할 달이 2개 미만이면 null.
  final int? change;
}

enum SavingKind { categoryLow, smallPurchases, subscriptions }

class SavingCandidate {
  const SavingCandidate(this.kind, this.monthly, this.basis, {this.category});

  final SavingKind kind;
  final String? category;

  /// 한 달에 아낄 수 있는 금액(100원 단위 내림).
  final int monthly;

  /// 근거(화면·상담에 그대로 쓰는 한 줄).
  final String basis;
}

class SpendingInsights {
  const SpendingInsights({
    required this.months,
    required this.usualMonth,
    required this.budget,
    required this.trendChange,
    required this.categories,
    required this.smallCountPerMonth,
    required this.smallTotalPerMonth,
    required this.weekendShare,
    required this.busiestWeekday,
    required this.lateNightShare,
    required this.timedCount,
    required this.fixedMonthly,
    required this.candidates,
    this.merchantsByCategory = const {},
    this.subscriptions = const [],
    this.smallTopMerchants = const [],
  });

  /// 최근 완료 달(최대 6개, 오래된 순)과 그 달 지출(특이 지출 제외).
  final List<(YearMonth, int)> months;

  /// 평소 한 달 지출 = 최근 완료 3개월 중앙값(특이 지출 제외).
  final int usualMonth;
  final int? budget;

  /// 최근 3개월 평균 − 그 전 달들(2~3개월) 평균. 비교할 달이 2개 미만이면 null.
  final int? trendChange;

  /// 평소 금액 큰 순(최대 6개).
  final List<CategoryInsight> categories;
  final int smallCountPerMonth;
  final int smallTotalPerMonth;

  /// 최근 완료 3개월 지출 중 토·일 비율.
  final double weekendShare;

  /// 하루 평균 지출이 가장 큰 요일(1=월 … 7=일).
  final int busiestWeekday;

  /// 시각을 아는 결제 중 밤 10시~새벽 4시 금액 비율. 시각을 아는 결제가 10건 미만이면 null.
  final double? lateNightShare;
  final int timedCount;

  /// 등록된 정기 지출의 한 달 합(고정비).
  final int fixedMonthly;

  /// 아낄 수 있는 곳(월 절약액 큰 순, 최대 4개).
  final List<SavingCandidate> candidates;

  /// 카테고리별 많이 쓴 가맹점 상위 3곳(이름, 최근 3개월 월평균). 10/20 사용자 결정으로 상담에 가맹점 이름을 보낸다.
  final Map<String, List<(String, int)>> merchantsByCategory;

  /// 지난달 구독(이름, 금액) 큰 순.
  final List<(String, int)> subscriptions;

  /// 소액 결제가 잦은 가맹점(이름, 월평균 건수) 상위 3곳.
  final List<(String, int)> smallTopMerchants;

  /// 평소 한 달 − 예산(양수면 예산보다 많이 씀).
  int? get gapToBudget => budget == null ? null : usualMonth - budget!;
  int get savingTop3 => candidates.take(3).fold(0, (s, c) => s + c.monthly);
}

SpendingInsights computeInsights(List<SpendItem> items, BudgetEngine engine, DateTime now, {int? budget}) {
  final first = engine.ledger.firstRecordDate;
  final variable = [for (final i in items) if (!i.isUnusual) i];
  int monthTotal(YearMonth m) => variable.where((i) => m.contains(i.date)).fold(0, (s, i) => s + i.amount);

  final recent6 = recentFullMonths(now, first, count: 6).reversed.toList(); // 오래된 순
  // 앞쪽 달 중 지출이 나머지 중앙값의 1/3도 안 되면 기록이 덜 들어온 달로 보고 뺀다
  // (실데이터: 예전 할부 승인일 때문에 첫 기록일이 당겨져 4월이 66,500원뿐 → 추세·절약액이 부풀었음, 10/20)
  while (recent6.length > 3) {
    final restMedian = _median([for (final m in recent6.skip(1)) monthTotal(m)]);
    if (monthTotal(recent6.first) * 3 >= restMedian) break;
    recent6.removeAt(0);
  }
  final last3 = recent6.length <= 3 ? recent6 : recent6.sublist(recent6.length - 3);
  final prev3 = recent6.length >= 5 ? recent6.sublist(0, recent6.length - 3) : const <YearMonth>[];
  final months = [for (final m in recent6) (m, monthTotal(m))];
  final usualMonth = _median([for (final m in last3) monthTotal(m)]);
  int avg(List<YearMonth> ms) => ms.isEmpty ? 0 : ms.fold(0, (s, m) => s + monthTotal(m)) ~/ ms.length;
  final trend = prev3.isEmpty ? null : avg(last3) - avg(prev3);

  // 카테고리
  final perMonth = {for (final m in recent6) m: categoryTotalsInDays(items, m, 1, 31)};
  final names = {for (final m in last3) ...perMonth[m]!.keys};
  int catUsual(String n) => _median([for (final m in last3) perMonth[m]![n] ?? 0]);
  int catAvg(String n, List<YearMonth> ms) => ms.isEmpty ? 0 : ms.fold(0, (s, m) => s + (perMonth[m]![n] ?? 0)) ~/ ms.length;
  final cats = [
    for (final n in names)
      CategoryInsight(
        n,
        catUsual(n),
        usualMonth > 0 ? catUsual(n) / usualMonth : 0,
        prev3.isEmpty ? null : catAvg(n, last3) - catAvg(n, prev3),
      ),
  ]..sort((a, b) => b.usualMonthly.compareTo(a.usualMonthly));

  // 소액 결제
  final smallCounts = <int>[], smallTotals = <int>[];
  for (final m in last3) {
    final small = variable.where(
      (i) => m.contains(i.date) && i.amount > 0 && i.amount < smallPurchaseLimit && !hardToCutCategories.contains(i.categoryName),
    );
    smallCounts.add(small.length);
    smallTotals.add(small.fold(0, (s, i) => s + i.amount));
  }

  // 요일
  final byWeekday = List.filled(8, 0), weekdayDays = List.filled(8, 0);
  var total3 = 0;
  for (final m in last3) {
    for (var d = 1; d <= m.days; d++) {
      weekdayDays[DateTime(m.year, m.month, d).weekday]++;
    }
    for (final i in variable.where((i) => m.contains(i.date))) {
      byWeekday[i.date.weekday] += i.amount;
      total3 += i.amount;
    }
  }
  var busiest = 1;
  for (var w = 2; w <= 7; w++) {
    final a = weekdayDays[w] == 0 ? 0 : byWeekday[w] / weekdayDays[w];
    final b = weekdayDays[busiest] == 0 ? 0 : byWeekday[busiest] / weekdayDays[busiest];
    if (a > b) busiest = w;
  }

  // 심야(시각을 아는 결제만)
  final timed = variable.where((i) => i.hour != null && last3.any((m) => m.contains(i.date))).toList();
  final timedSum = timed.fold(0, (s, i) => s + i.amount);
  final lateSum = timed.where((i) => i.hour! >= 22 || i.hour! < 4).fold(0, (s, i) => s + i.amount);

  // 고정비
  final fixed = engine.ledger.recurringItems.where((r) => r.active).fold(0, (s, r) => s + r.amount);

  // 아낄 수 있는 곳 — 모두 "이미 해 본 수준"이나 "절반" 같은 실현 가능한 기준만
  final candidates = <SavingCandidate>[];
  if (last3.isNotEmpty) {
    for (final c in cats) {
      if (hardToCutCategories.contains(c.name) || c.usualMonthly <= 0) continue;
      // 기준은 "실제로 써 본 달" 중 가장 적었던 달. 0원인 달은 그 카테고리 기록이 없던 달일 수 있어 뺀다
      final spentMonths = [for (final m in recent6) perMonth[m]![c.name] ?? 0].where((v) => v > 0).toList();
      if (spentMonths.length < 2) continue;
      final low = spentMonths.reduce((a, b) => a < b ? a : b);
      // 해 본 수준이라도 평소의 절반 넘게 줄이라고 하지는 않는다
      final saving = _down100((c.usualMonthly - low).clamp(0, c.usualMonthly ~/ 2));
      if (saving >= 5000) {
        candidates.add(SavingCandidate(
          SavingKind.categoryLow,
          saving,
          '${c.name}: 평소 월 ${_won(c.usualMonthly)}, 최근 ${recent6.length}개월 중 가장 적었던 달 ${_won(low)} 수준이면',
          category: c.name,
        ));
      }
    }
    // 이미 카테고리 후보로 잡힌 카테고리의 소액 결제는 빼서 같은 돈을 두 번 세지 않는다
    final taken = {for (final c in candidates) c.category};
    final smallFree = [
      for (final m in last3)
        variable
            .where((i) => m.contains(i.date) && i.amount > 0 && i.amount < smallPurchaseLimit)
            .where((i) => !hardToCutCategories.contains(i.categoryName) && !taken.contains(i.categoryName))
            .fold(0, (s, i) => s + i.amount),
    ];
    final smallMedian = _median(smallFree);
    if (_down100(smallMedian ~/ 2) >= 5000) {
      candidates.add(SavingCandidate(
        SavingKind.smallPurchases,
        _down100(smallMedian ~/ 2),
        '1만 원 미만 결제가 월 ${_median(smallCounts)}건, 합 ${_won(smallMedian)}. 횟수를 절반으로 줄이면',
      ));
    }
    final subs = catUsual('구독');
    final lastMonth = last3.last;
    final subCount = {
      for (final i in items)
        if (lastMonth.contains(i.date) && i.categoryName == '구독') i.merchant,
    }.length;
    if (subCount >= 2 && _down100(subs ~/ subCount) >= 3000) {
      candidates.add(SavingCandidate(
        SavingKind.subscriptions,
        _down100(subs ~/ subCount),
        '구독 $subCount개, 월 ${_won(subs)}. 하나를 정리하면 평균',
        category: '구독',
      ));
    }
  }
  candidates.sort((a, b) => b.monthly.compareTo(a.monthly));

  // 가맹점: 최근 3개월 기준, 특이 지출 제외
  final n3 = last3.isEmpty ? 1 : last3.length;
  final inLast3 = [for (final i in variable) if (last3.any((m) => m.contains(i.date))) i];
  List<(String, int)> top(Iterable<SpendItem> xs, int Function(Iterable<SpendItem>) value) {
    final by = <String, List<SpendItem>>{};
    for (final i in xs) {
      by.putIfAbsent(i.merchant, () => []).add(i);
    }
    final list = [for (final e in by.entries) (e.key, value(e.value) ~/ n3)]..sort((a, b) => b.$2.compareTo(a.$2));
    return list.where((e) => e.$2 > 0).take(3).toList();
  }

  final merchantsByCategory = {
    for (final c in cats.take(6))
      c.name: top(inLast3.where((i) => (i.categoryName ?? unconfirmedCategoryName) == c.name), (xs) => xs.fold(0, (s, i) => s + i.amount)),
  };
  final subTotals = <String, int>{};
  if (last3.isNotEmpty) {
    for (final i in items) {
      if (last3.last.contains(i.date) && i.categoryName == '구독') subTotals[i.merchant] = (subTotals[i.merchant] ?? 0) + i.amount;
    }
  }
  final subscriptions = [for (final e in subTotals.entries) (e.key, e.value)]..sort((a, b) => b.$2.compareTo(a.$2));
  final smallTop = top(
    inLast3.where((i) => i.amount > 0 && i.amount < smallPurchaseLimit && !hardToCutCategories.contains(i.categoryName)),
    (xs) => xs.length,
  );

  return SpendingInsights(
    months: months,
    usualMonth: usualMonth,
    budget: budget,
    trendChange: trend,
    categories: cats.take(6).toList(),
    smallCountPerMonth: _median(smallCounts),
    smallTotalPerMonth: _median(smallTotals),
    weekendShare: total3 > 0 ? (byWeekday[6] + byWeekday[7]) / total3 : 0,
    busiestWeekday: busiest,
    lateNightShare: timed.length >= 10 && timedSum > 0 ? lateSum / timedSum : null,
    timedCount: timed.length,
    fixedMonthly: fixed,
    candidates: candidates.take(4).toList(),
    merchantsByCategory: merchantsByCategory,
    subscriptions: subscriptions,
    smallTopMerchants: smallTop,
  );
}

String _won(int v) {
  final s = v.abs().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
  return '${v < 0 ? '-' : ''}$s원';
}

const weekdayNames = ['', '월', '화', '수', '목', '금', '토', '일'];
