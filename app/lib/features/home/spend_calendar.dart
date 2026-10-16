import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_providers.dart';
import '../../core/category_summary.dart';
import '../../core/models.dart';
import '../../ui/format.dart';
import '../spending/spending_providers.dart';
import '../spending/transaction_sheet.dart';

/// 홈 달력(10/16): 날짜마다 그날 쓴 금액. 칸 색이 진할수록 많이 쓴 날.
/// 판단(초과 등)은 하지 않는다 — 날마다 빨간 칸이 생기면 스트레스가 되므로(PRD 원칙).
/// 이번 달의 남은 날에는 정기·예정 지출이 있는 날에 점을 찍는다.
class SpendCalendar extends ConsumerStatefulWidget {
  const SpendCalendar({super.key, this.upcomingDays = const {}});

  /// 이번 달에 정기·예정 지출이 남은 날짜(일).
  final Set<int> upcomingDays;

  @override
  ConsumerState<SpendCalendar> createState() => _SpendCalendarState();
}

class _SpendCalendarState extends ConsumerState<SpendCalendar> {
  YearMonth? _month;

  @override
  Widget build(BuildContext context) {
    final now = ref.watch(clockProvider)();
    final thisMonth = YearMonth.of(now);
    final month = _month ?? thisMonth;
    final items = ref.watch(spendItemsProvider);
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
        child: items.when(
          loading: () => const SizedBox(height: 280, child: Center(child: CircularProgressIndicator())),
          error: (e, _) => Padding(padding: const EdgeInsets.all(16), child: Text('불러오지 못했어요: $e')),
          data: (all) {
            final totals = dailyTotals(all, month);
            final sum = totals.fold(0, (s, v) => s + v);
            final maxDay = totals.fold(0, (m, v) => v > m ? v : m);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: '이전 달',
                      onPressed: () => setState(() => _month = month.plus(-1)),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text('${month.year}년 ${month.month}월', style: theme.textTheme.titleSmall),
                          Text('쓴 금액 ${won(sum)}', style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: '다음 달',
                      onPressed: month == thisMonth ? null : () => setState(() => _month = month.plus(1)),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _Grid(
                  month: month,
                  totals: totals,
                  maxDay: maxDay,
                  today: month == thisMonth ? now.day : null,
                  marked: month == thisMonth ? widget.upcomingDays : const {},
                  onTap: (day) => _openDay(context, all, DateTime(month.year, month.month, day)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _openDay(BuildContext context, List<SpendItem> all, DateTime day) async {
    final list = [
      for (final i in all)
        if (dateOnly(i.date) == day) i,
    ]..sort((a, b) => b.amount.compareTo(a.amount));
    final changed = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => _DaySheet(day: day, items: list),
    );
    if (changed == true) {
      ref.invalidate(spendItemsProvider);
      ref.invalidate(homeProvider);
    }
  }
}

class _Grid extends StatelessWidget {
  const _Grid({
    required this.month,
    required this.totals,
    required this.maxDay,
    required this.today,
    required this.marked,
    required this.onTap,
  });

  final YearMonth month;
  final List<int> totals;
  final int maxDay;
  final int? today;
  final Set<int> marked;
  final void Function(int day) onTap;

  static const _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final lead = month.firstDay.weekday - 1; // 월요일 시작
    final cells = lead + month.days;
    final rows = (cells + 6) ~/ 7;
    final small = theme.textTheme.labelSmall;

    Widget cell(int index) {
      final day = index - lead + 1;
      if (day < 1 || day > month.days) return const SizedBox.shrink();
      final amount = totals[day - 1];
      final future = today != null && day > today!;
      // 색 진하기: 그 달 가장 많이 쓴 날 대비(0.06~0.45)
      final t = maxDay > 0 && amount > 0 ? amount / maxDay : 0.0;
      final bg = amount > 0 ? scheme.primary.withValues(alpha: 0.06 + 0.39 * t) : null;
      return Padding(
        padding: const EdgeInsets.all(1.5),
        child: Material(
          color: bg ?? Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: day == today ? BorderSide(color: scheme.primary, width: 1.5) : BorderSide.none,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: future ? null : () => onTap(day),
            child: Semantics(
              label: '$day일 ${amount != 0 ? won(amount) : '지출 없음'}',
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$day',
                    style: small?.copyWith(
                      color: future ? scheme.onSurfaceVariant.withValues(alpha: 0.6) : null,
                      fontWeight: day == today ? FontWeight.w700 : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (amount != 0)
                    Text(
                      compactWon(amount),
                      maxLines: 1,
                      style: small?.copyWith(fontSize: 10, fontFeatures: const [FontFeature.tabularFigures()]),
                    )
                  else if (marked.contains(day))
                    Icon(Icons.circle, size: 5, color: scheme.primary)
                  else
                    const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            for (final w in _weekdays)
              Expanded(
                child: Center(child: Text(w, style: small?.copyWith(color: scheme.onSurfaceVariant))),
              ),
          ],
        ),
        const SizedBox(height: 4),
        for (var r = 0; r < rows; r++)
          SizedBox(
            height: 46,
            child: Row(children: [for (var c = 0; c < 7; c++) Expanded(child: cell(r * 7 + c))]),
          ),
        if (marked.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 8),
            child: Row(
              children: [
                Icon(Icons.circle, size: 5, color: scheme.primary),
                const SizedBox(width: 6),
                Text('정기·예정 지출이 남은 날', style: small?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
      ],
    );
  }
}

class _DaySheet extends StatelessWidget {
  const _DaySheet({required this.day, required this.items});

  final DateTime day;
  final List<SpendItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sum = items.fold(0, (s, i) => s + i.amount);
    return ListView(
      shrinkWrap: true,
      padding: EdgeInsets.only(bottom: 16 + MediaQuery.viewPaddingOf(context).bottom),
      children: [
        ListTile(
          title: Text('${day.month}월 ${day.day}일 · ${items.length}건', style: theme.textTheme.titleMedium),
          trailing: Text(won(sum), style: theme.textTheme.titleMedium),
        ),
        const Divider(height: 1),
        if (items.isEmpty) const ListTile(title: Text('이날은 쓴 돈이 없어요')),
        for (final i in items)
          ListTile(
            title: Text(i.merchant, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(
              [
                i.categoryName ?? unconfirmedCategoryName,
                if (i.installmentSeq != null) '할부 ${i.installmentSeq}/${i.installmentMonths}회차',
                if (i.isUnusual) '특이 지출',
              ].join(' · '),
            ),
            trailing: Text(won(i.amount, exact: true)),
            onTap: () async {
              final changed = await showTransactionSheet(context, i.txnId);
              if (changed == true && context.mounted) Navigator.pop(context, true);
            },
          ),
      ],
    );
  }
}
