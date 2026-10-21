// 가맹점 하나를 콕 집은 질문(10/21): "스타벅스에 이번 달 얼마 썼어?", "배민 지난달 몇 번 시켰어?".
// 폰 안에서 이름으로 찾아 합계·횟수만 계산한다. 서버에는 사용자가 말한 이름과 찾은 가맹점 이름, 숫자만 간다.
// Flutter에 의존하지 않는다.
import 'analysis.dart';
import 'category_summary.dart';
import 'merchant_rules.dart';
import 'models.dart';

/// 줄임말 → 가맹점 이름에 들어 있는 말. normMerchant가 이미 처리하는 것(배민, 쿠팡 등)은 넣지 않는다.
const _aliases = {'스벅': '스타벅스', '맥날': '맥도날드', '버킹': '버거킹', '롯리': '롯데리아', '메가커피': '메가', '투썸플레이스': '투썸'};

String _key(String s) => s.toLowerCase().replaceAll(RegExp(r'\(주\)|[\s()㈜·_\-.,]'), '');

/// 이름 [merchant]가 질문 [query]의 가맹점인지. 부분 일치("스타벅스" ↔ "스타벅스 강남점").
bool merchantMatches(String merchant, String query) {
  final q = _key(_aliases[query.trim()] ?? normMerchant(query.trim()));
  final m = _key(merchant);
  if (q.length < 2 || m.isEmpty) return q.isNotEmpty && m == q;
  return m.contains(q) || (m.length >= 2 && q.contains(m));
}

class MerchantSpending {
  const MerchantSpending({
    required this.query,
    required this.from,
    required this.to,
    required this.total,
    required this.count,
    required this.names,
    required this.usualMonthly,
    required this.monthsUsed,
    required this.lastDate,
    required this.everFound,
  });

  final String query;
  final DateTime from;
  final DateTime to;
  final int total;

  /// 결제 건수(할부는 1건).
  final int count;

  /// 기간 안에서 찾은 가맹점 이름과 합계(많은 순, 최대 5개).
  final List<(String, int)> names;

  /// 최근 완료 [monthsUsed]개월의 월 합계 중앙값. 기록이 없으면 null.
  final int? usualMonthly;
  final int monthsUsed;

  /// 기간과 상관없이 마지막 결제일. 없으면 null.
  final DateTime? lastDate;

  /// 기간 밖이라도 이 이름의 결제가 한 번이라도 있었는지.
  final bool everFound;
}

/// [period]: this_month(1일~오늘) / last_month / last_3_months(전전달 1일~오늘) / all.
/// 특이 지출도 포함한다(실제로 쓴 돈을 묻는 질문이라서). 할부는 회차가 그 달에 들어간다(예산 계산과 같음).
MerchantSpending merchantSpending(List<SpendItem> items, String query, String period, DateTime now, DateTime? firstRecord) {
  final m = YearMonth.of(now);
  final today = dateOnly(now);
  final matched = items.where((i) => merchantMatches(i.merchant, query)).toList();
  final first = matched.isEmpty ? today : matched.map((i) => dateOnly(i.date)).reduce((a, b) => a.isBefore(b) ? a : b);
  final (from, to) = switch (period) {
    'last_month' => (m.plus(-1).firstDay, m.plus(-1).lastDay),
    'last_3_months' => (m.plus(-2).firstDay, today),
    'all' => (first, today),
    _ => (m.firstDay, today),
  };
  final inRange = matched.where((i) => !dateOnly(i.date).isBefore(from) && !dateOnly(i.date).isAfter(to)).toList();

  final byName = <String, int>{};
  for (final i in inRange) {
    byName[i.merchant] = (byName[i.merchant] ?? 0) + i.amount;
  }
  final names = byName.entries.map((e) => (e.key, e.value)).toList()..sort((a, b) => b.$2.compareTo(a.$2));

  final months = recentFullMonths(now, firstRecord);
  int? usual;
  if (months.isNotEmpty && matched.isNotEmpty) {
    final totals = [
      for (final mo in months) matched.where((i) => mo.contains(i.date)).fold(0, (s, i) => s + i.amount),
    ]..sort();
    final mid = totals.length ~/ 2;
    usual = totals.length.isOdd ? totals[mid] : (totals[mid - 1] + totals[mid]) ~/ 2;
  }

  return MerchantSpending(
    query: query,
    from: from,
    to: to,
    total: inRange.fold(0, (s, i) => s + i.amount),
    count: {for (final i in inRange) i.txnId}.length,
    names: names.take(5).toList(),
    usualMonthly: usual,
    monthsUsed: months.length,
    // 할부 다음 회차는 미래 달 1일로 잡혀 있으므로 오늘까지만 본다
    lastDate: [
      for (final i in matched)
        if (!dateOnly(i.date).isAfter(today)) dateOnly(i.date),
    ].fold<DateTime?>(null, (a, d) => a == null || d.isAfter(a) ? d : a),
    everFound: matched.isNotEmpty,
  );
}
