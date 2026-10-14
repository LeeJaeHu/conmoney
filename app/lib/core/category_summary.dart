import 'models.dart';

/// 카테고리 보기(F8)에 쓰는 지출 1건. 할부는 회차마다 1건이다.
class SpendItem {
  const SpendItem({
    required this.txnId,
    required this.date,
    required this.amount,
    required this.merchant,
    this.categoryId,
    this.categoryName,
    this.memo,
    this.isUnusual = false,
    this.installmentSeq,
    this.installmentMonths = 1,
    this.cardName,
  });

  final int txnId;

  /// 일시불은 승인일, 할부 1회차는 승인일, 2회차부터는 그 달 1일(Spec F8).
  final DateTime date;
  final int amount;
  final String merchant;
  final int? categoryId;
  final String? categoryName;
  final String? memo;
  final bool isUnusual;
  final int? installmentSeq;
  final int installmentMonths;
  final String? cardName;
}

class CategoryTotal {
  const CategoryTotal(this.categoryId, this.name, this.total, this.count, this.ratio);

  final int? categoryId;

  /// 카테고리가 없으면 '미확인'.
  final String name;
  final int total;
  final int count;

  /// 기간 총액 대비 비율(0~1). 총액이 0 이하이면 0.
  final double ratio;
}

class CategorySummary {
  const CategorySummary(this.total, this.categories, this.items);

  final int total;

  /// 금액 큰 순.
  final List<CategoryTotal> categories;
  final List<SpendItem> items;

  List<SpendItem> itemsOf(int? categoryId) => [
    for (final i in items)
      if (i.categoryId == categoryId) i,
  ]..sort((a, b) => b.date.compareTo(a.date));
}

const unconfirmedCategoryName = '미확인';

/// [from]~[to](둘 다 포함) 기간의 카테고리별 합계. [includeUnusual]이 false면 특이 지출을 뺀다.
CategorySummary summarize(List<SpendItem> all, DateTime from, DateTime to, {bool includeUnusual = true}) {
  final start = dateOnly(from), end = dateOnly(to);
  final items = [
    for (final i in all)
      if (!dateOnly(i.date).isBefore(start) && !dateOnly(i.date).isAfter(end) && (includeUnusual || !i.isUnusual)) i,
  ];

  final totals = <int?, (String, int, int)>{};
  for (final i in items) {
    final (name, sum, count) = totals[i.categoryId] ?? (i.categoryName ?? unconfirmedCategoryName, 0, 0);
    totals[i.categoryId] = (name, sum + i.amount, count + 1);
  }
  final total = items.fold(0, (s, i) => s + i.amount);
  final categories = [
    for (final e in totals.entries)
      CategoryTotal(e.key, e.value.$1, e.value.$2, e.value.$3, total > 0 && e.value.$2 > 0 ? e.value.$2 / total : 0),
  ]..sort((a, b) => b.total.compareTo(a.total));
  return CategorySummary(total, categories, items);
}

/// 최근 [months]개월(이번 달 포함) 카테고리별 월 합계. 상위 [top]개만 따로 두고 나머지는 '그 외'로 묶는다.
class MonthlyTrend {
  const MonthlyTrend(this.months, this.series, this.monthTotals);

  final List<YearMonth> months;

  /// (카테고리 이름, 월별 합계). 마지막 항목은 '그 외'일 수 있다.
  final List<(String, List<int>)> series;
  final List<int> monthTotals;
}

const otherSeriesName = '그 외';

MonthlyTrend monthlyTrend(
  List<SpendItem> all,
  DateTime now, {
  int months = 6,
  int top = 5,
  bool includeUnusual = true,
}) {
  final last = YearMonth.of(now);
  final range = [for (var k = months - 1; k >= 0; k--) last.plus(-k)];
  final index = {for (var i = 0; i < range.length; i++) range[i]: i};

  final byCat = <String, List<int>>{};
  for (final i in all) {
    if (!includeUnusual && i.isUnusual) continue;
    final idx = index[YearMonth.of(i.date)];
    if (idx == null) continue;
    (byCat[i.categoryName ?? unconfirmedCategoryName] ??= List.filled(range.length, 0))[idx] += i.amount;
  }

  final ranked = byCat.entries.toList()
    ..sort((a, b) => b.value.fold(0, (s, v) => s + v).compareTo(a.value.fold(0, (s, v) => s + v)));
  final series = <(String, List<int>)>[for (final e in ranked.take(top)) (e.key, e.value)];
  if (ranked.length > top) {
    final rest = List.filled(range.length, 0);
    for (final e in ranked.skip(top)) {
      for (var i = 0; i < rest.length; i++) {
        rest[i] += e.value[i];
      }
    }
    series.add((otherSeriesName, rest));
  }
  final monthTotals = [for (var i = 0; i < range.length; i++) series.fold(0, (s, e) => s + e.$2[i])];
  return MonthlyTrend(range, series, monthTotals);
}
