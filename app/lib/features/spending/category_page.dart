import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_providers.dart';
import '../../core/category_summary.dart';
import '../../core/models.dart';
import '../../ui/format.dart';
import '../../ui/insets.dart';
import 'spending_providers.dart';
import 'transaction_sheet.dart';

enum _Period { thisMonth, lastMonth, last3Months, custom }

/// 카테고리·기간 보기(Spec F8). 총액은 여기서만 보여준다.
class CategoryPage extends ConsumerStatefulWidget {
  const CategoryPage({super.key});

  @override
  ConsumerState<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends ConsumerState<CategoryPage> {
  _Period _period = _Period.thisMonth;
  DateTimeRange? _custom;
  bool _includeUnusual = true;

  (DateTime, DateTime) _range(DateTime now) {
    final m = YearMonth.of(now);
    return switch (_period) {
      _Period.thisMonth => (m.firstDay, dateOnly(now)),
      _Period.lastMonth => (m.plus(-1).firstDay, m.plus(-1).lastDay),
      _Period.last3Months => (m.plus(-2).firstDay, dateOnly(now)),
      _Period.custom => (_custom?.start ?? m.firstDay, _custom?.end ?? dateOnly(now)),
    };
  }

  Future<void> _pickCustom(DateTime now) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: dateOnly(now),
      initialDateRange: _custom,
    );
    if (picked != null) {
      setState(() {
        _custom = picked;
        _period = _Period.custom;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = ref.watch(clockProvider)();
    final items = ref.watch(spendItemsProvider);
    final theme = Theme.of(context);
    final (from, to) = _range(now);

    return Scaffold(
      appBar: AppBar(title: const Text('카테고리별 지출')),
      body: items.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('불러오지 못했어요: $e')),
        data: (all) {
          final summary = summarize(all, from, to, includeUnusual: _includeUnusual);
          final trend = monthlyTrend(all, now, includeUnusual: _includeUnusual);
          return ListView(
            padding: pagePadding(context),
            children: [
              Wrap(
                spacing: 8,
                children: [
                  for (final (p, label) in [
                    (_Period.thisMonth, '이번 달'),
                    (_Period.lastMonth, '지난달'),
                    (_Period.last3Months, '최근 3개월'),
                  ])
                    ChoiceChip(
                      label: Text(label),
                      selected: _period == p,
                      onSelected: (_) => setState(() => _period = p),
                    ),
                  ChoiceChip(
                    label: Text(_period == _Period.custom ? '${_md(from)}~${_md(to)}' : '직접 지정'),
                    selected: _period == _Period.custom,
                    onSelected: (_) => _pickCustom(now),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('${_md(from)} ~ ${_md(to)}', style: theme.textTheme.bodySmall),
              Text('총 ${won(summary.total)}', style: theme.textTheme.headlineSmall),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _includeUnusual,
                onChanged: (v) => setState(() => _includeUnusual = v),
                title: const Text('특이 지출 포함'),
              ),
              const SizedBox(height: 4),
              if (summary.categories.isEmpty)
                const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Text('이 기간에는 지출이 없어요')),
              for (final c in summary.categories)
                _CategoryBar(
                  total: c,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => _CategoryDetailPage(
                        title: c.name,
                        categoryId: c.categoryId,
                        from: from,
                        to: to,
                        includeUnusual: _includeUnusual,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 28),
              Text('최근 6개월', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              _TrendChart(trend: trend),
            ],
          );
        },
      ),
    );
  }
}

String _md(DateTime d) => '${d.month}/${d.day}';

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({required this.total, required this.onTap});

  final CategoryTotal total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = (total.ratio * 100).round();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('${total.name} · ${total.count}건', style: theme.textTheme.bodyLarge)),
                Text(won(total.total), style: theme.textTheme.bodyLarge),
                SizedBox(
                  width: 44,
                  child: Text('$pct%', textAlign: TextAlign.end, style: theme.textTheme.bodySmall),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: total.ratio.clamp(0, 1),
                minHeight: 8,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 월별 누적 막대. 상위 5개 카테고리 + '그 외'. 색은 순서 고정(Cove 팔레트), '그 외'는 회색.
class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.trend});

  final MonthlyTrend trend;

  static const _light = [Color(0xFF2A78D6), Color(0xFFEB6834), Color(0xFF1BAF7A), Color(0xFFEDA100), Color(0xFFE87BA4)];
  static const _dark = [Color(0xFF3987E5), Color(0xFFD95926), Color(0xFF199E70), Color(0xFFC98500), Color(0xFFD55181)];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    Color colorOf(int i, String name) =>
        name == otherSeriesName ? const Color(0xFF898781) : (dark ? _dark : _light)[i % _light.length];
    const chartHeight = 160.0;
    // 막대 높이는 양수 구간의 합 기준(취소로 음수인 카테고리는 그리지 않음). 구간 사이 2px 간격만큼 뺀다
    const gap = 2.0;
    var maxStack = 1;
    for (var m = 0; m < trend.months.length; m++) {
      final stack = trend.series.fold(0, (s, e) => s + (e.$2[m] > 0 ? e.$2[m] : 0));
      if (stack > maxStack) maxStack = stack;
    }
    final barSpace = chartHeight - gap * trend.series.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            for (var i = 0; i < trend.series.length; i++)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: colorOf(i, trend.series[i].$1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(trend.series[i].$1, style: theme.textTheme.bodySmall),
                ],
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var m = 0; m < trend.months.length; m++)
              Expanded(
                child: Tooltip(
                  message: [
                    '${trend.months[m].month}월 ${won(trend.monthTotals[m])}',
                    for (final (name, values) in trend.series)
                      if (values[m] > 0) '$name ${won(values[m])}',
                  ].join('\n'),
                  child: Column(
                    children: [
                      Text(manWonShort(trend.monthTotals[m]), style: theme.textTheme.labelSmall),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: chartHeight,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            for (var i = trend.series.length - 1; i >= 0; i--)
                              if (trend.series[i].$2[m] > 0)
                                Container(
                                  width: 24,
                                  height: barSpace * trend.series[i].$2[m] / maxStack,
                                  margin: const EdgeInsets.only(top: gap),
                                  decoration: BoxDecoration(
                                    color: colorOf(i, trend.series[i].$1),
                                    borderRadius: i == trend.series.length - 1
                                        ? const BorderRadius.vertical(top: Radius.circular(4))
                                        : null,
                                  ),
                                ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('${trend.months[m].month}월', style: theme.textTheme.labelSmall),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// 차트 라벨용: 124만, 5.4만.
String manWonShort(int amount) {
  if (amount <= 0) return '0';
  final man = amount / 10000;
  return man >= 10 ? '${man.round()}만' : '${man.toStringAsFixed(1)}만';
}

class _CategoryDetailPage extends ConsumerWidget {
  const _CategoryDetailPage({
    required this.title,
    required this.categoryId,
    required this.from,
    required this.to,
    required this.includeUnusual,
  });

  final String title;
  final int? categoryId;
  final DateTime from;
  final DateTime to;
  final bool includeUnusual;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final items = ref.watch(spendItemsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: items.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('불러오지 못했어요: $e')),
        data: (all) {
          final list = summarize(all, from, to, includeUnusual: includeUnusual).itemsOf(categoryId);
          final sum = list.fold(0, (s, i) => s + i.amount);
          return ListView(
            padding: EdgeInsets.only(bottom: MediaQuery.viewPaddingOf(context).bottom + 16),
            children: [
              ListTile(
                title: Text('${_md(from)} ~ ${_md(to)} · ${list.length}건'),
                trailing: Text(won(sum), style: theme.textTheme.titleMedium),
              ),
              const Divider(height: 1),
              for (final i in list)
                ListTile(
                  leading: Text(_md(i.date)),
                  title: Text(i.merchant, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    [
                      if (i.installmentSeq != null) '할부 ${i.installmentSeq}/${i.installmentMonths}',
                      if (i.isUnusual) '★ 특이 지출',
                      if (i.memo != null) i.memo!,
                      if (i.cardName != null) i.cardName!,
                    ].join(' · '),
                  ),
                  trailing: Text(won(i.amount, exact: true)),
                  onTap: () async {
                    final saved = await showTransactionSheet(context, i.txnId);
                    if (saved == true) ref.invalidate(spendItemsProvider);
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}
