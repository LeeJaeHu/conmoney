import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_providers.dart';
import '../../core/recurring.dart';
import '../../data/database.dart';
import '../../data/recurring_repository.dart';
import '../../ui/format.dart';
import '../../ui/insets.dart';

final recurringRepositoryProvider = Provider((ref) => RecurringRepository(ref.watch(databaseProvider)));

final _recurringProvider = FutureProvider<(List<RecurringView>, List<RecurringSuggestion>, List<EnvelopeSuggestion>)>((
  ref,
) async {
  final repo = ref.watch(recurringRepositoryProvider);
  final now = ref.watch(clockProvider)();
  return (await repo.view(now), await repo.suggestions(now), await repo.envelopeSuggestions(now));
});

/// 정기 지출 화면(Spec F5): 등록된 항목의 이번 달 상태, 자동 탐지 제안, 직접 추가.
class RecurringPage extends ConsumerWidget {
  const RecurringPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(_recurringProvider);
    final repo = ref.read(recurringRepositoryProvider);
    final now = ref.read(clockProvider)();

    Future<void> run(Future<void> Function() action) async {
      await action();
      ref.invalidate(_recurringProvider);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('정기 지출')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final input = await showDialog<_ItemInput>(context: context, builder: (_) => const _ItemDialog());
          if (input != null) {
            await run(
              () => repo.add(
                name: input.name,
                amount: input.amount,
                dueDay: input.dueDay,
                isEstimate: input.isEstimate || input.isEnvelope,
                matchPattern: input.matchPattern,
                isEnvelope: input.isEnvelope,
              ),
            );
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('직접 추가'),
      ),
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('불러오지 못했어요: $e')),
        data: (d) {
          final (items, suggestions, envelopes) = d;
          final theme = Theme.of(context);
          return ListView(
            padding: pagePadding(context, bottom: 96),
            children: [
              Text('등록된 정기 지출 ${items.length}개', style: theme.textTheme.titleMedium),
              Text('아직 안 나간 금액은 이번 달 예산에서 미리 빼요.', style: theme.textTheme.bodySmall),
              const SizedBox(height: 8),
              if (items.isEmpty) const Card(child: ListTile(title: Text('아래 제안에서 등록하거나 직접 추가해 주세요'))),
              for (final v in items)
                Card(
                  child: ListTile(
                    title: Text(v.item.name),
                    subtitle: Text(
                      v.item.isEnvelope
                          ? '매달 약 ${won(v.item.amount, exact: true)} 예약 · "${v.item.matchPattern}" 결제가 들어오면 줄어요'
                          : '매달 ${v.item.dueDay}일 · ${v.item.isEstimate ? '약 ' : ''}${won(v.item.amount, exact: true)}',
                    ),
                    trailing: _StateChip(view: v, onSkip: () => run(() => repo.skipMonth(v.item.id, now))),
                    onTap: () async {
                      final input = await showDialog<_ItemInput>(
                        context: context,
                        builder: (_) => _ItemDialog(initial: v.item),
                      );
                      if (input == null) return;
                      if (input.delete) {
                        await run(() => repo.deactivate(v.item.id));
                      } else {
                        await run(
                          () => repo.update(
                            v.item.copyWith(
                              name: input.name,
                              amount: input.amount,
                              dueDay: input.dueDay,
                              isEstimate: input.isEstimate || input.isEnvelope,
                              isEnvelope: input.isEnvelope,
                              matchPattern: input.matchPattern.isEmpty ? input.name : input.matchPattern,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
              for (final e in envelopes) ...[
                const SizedBox(height: 24),
                Text('매달 미리 떼어 둘까요?', style: theme.textTheme.titleMedium),
                Card(
                  child: ListTile(
                    title: Text('${e.name} 약 ${won(e.amount, exact: true)}'),
                    subtitle: Text(
                      '타는 날 하루 ${won(e.perDay, exact: true)} × 이번 달 평일 ${e.weekdays}일. '
                      '탈 때마다 알림이 없어도 예산에서 미리 빼 두고, 실제 결제가 들어오면 그만큼 줄어요.',
                    ),
                    isThreeLine: true,
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FilledButton.tonal(onPressed: () => run(() => repo.addEnvelope(e)), child: const Text('예약')),
                        TextButton(onPressed: () => run(() => repo.dismiss(e.name)), child: const Text('아니요')),
                      ],
                    ),
                  ),
                ),
              ],
              if (suggestions.isNotEmpty) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: Text('매달 나가는 것 같아요', style: theme.textTheme.titleMedium)),
                    TextButton(
                      onPressed: () => run(() async {
                        for (final s in suggestions) {
                          await repo.addSuggestion(s);
                        }
                      }),
                      child: const Text('모두 등록'),
                    ),
                  ],
                ),
                for (final s in suggestions)
                  Card(
                    child: ListTile(
                      title: Text(s.merchant),
                      subtitle: Text(
                        '${s.months}개월째 매달 ${s.dueDay}일쯤 · ${s.isEstimate ? '약 ' : ''}${won(s.amount, exact: true)}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(onPressed: () => run(() => repo.dismiss(s.merchant)), child: const Text('아니요')),
                          FilledButton.tonal(
                            onPressed: () => run(() => repo.addSuggestion(s)),
                            child: const Text('등록'),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _StateChip extends StatelessWidget {
  const _StateChip({required this.view, required this.onSkip});

  final RecurringView view;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return switch (view.state) {
      MonthState.paid => Text(
        '결제됨${view.paidAmount != null ? '\n${won(view.paidAmount!, exact: true)}' : ''}',
        textAlign: TextAlign.end,
        style: theme.textTheme.bodySmall,
      ),
      MonthState.skipped => Text('이번 달 없음', style: theme.textTheme.bodySmall),
      MonthState.upcoming => Text('${view.due.month}/${view.due.day} 예정', style: theme.textTheme.bodySmall),
      MonthState.envelope => Text(
        '이번 달 ${won(view.envelopeUsed, exact: true)} 씀\n남은 예약 ${won(view.envelopeRemaining, exact: true)}',
        textAlign: TextAlign.end,
        style: theme.textTheme.bodySmall,
      ),
      MonthState.overdue => TextButton(
        onPressed: onSkip,
        child: const Text('아직 결제 안 됨\n이번 달 없음', textAlign: TextAlign.center),
      ),
    };
  }
}

class _ItemInput {
  const _ItemInput({
    required this.name,
    required this.amount,
    required this.dueDay,
    required this.isEstimate,
    required this.matchPattern,
    this.isEnvelope = false,
  }) : delete = false;

  const _ItemInput.delete()
    : name = '',
      amount = 0,
      dueDay = 1,
      isEstimate = false,
      matchPattern = '',
      isEnvelope = false,
      delete = true;

  final String name;
  final int amount;
  final int dueDay;
  final bool isEstimate;
  final String matchPattern;
  final bool isEnvelope;
  final bool delete;
}

class _ItemDialog extends StatefulWidget {
  const _ItemDialog({this.initial});

  final RecurringItemRow? initial;

  @override
  State<_ItemDialog> createState() => _ItemDialogState();
}

class _ItemDialogState extends State<_ItemDialog> {
  late final _name = TextEditingController(text: widget.initial?.name ?? '');
  late final _amount = TextEditingController(text: widget.initial?.amount.toString() ?? '');
  late final _day = TextEditingController(text: widget.initial?.dueDay.toString() ?? '');
  late final _pattern = TextEditingController(text: widget.initial?.matchPattern ?? '');
  late bool _estimate = widget.initial?.isEstimate ?? false;
  late bool _envelope = widget.initial?.isEnvelope ?? false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _amount, _day, _pattern]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    final amount = int.tryParse(_amount.text);
    // 월 예약형은 결제일이 없다
    final day = _envelope ? 1 : int.tryParse(_day.text);
    if (_name.text.trim().isEmpty || amount == null || amount <= 0 || day == null || day < 1 || day > 31) {
      setState(() => _error = '이름, 금액, 결제일(1~31)을 확인해 주세요');
      return;
    }
    Navigator.of(context).pop(
      _ItemInput(
        name: _name.text.trim(),
        amount: amount,
        dueDay: day,
        isEstimate: _estimate,
        matchPattern: _pattern.text.trim(),
        isEnvelope: _envelope,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final digits = [FilteringTextInputFormatter.digitsOnly];
    return AlertDialog(
      title: Text(widget.initial == null ? '정기 지출 추가' : '정기 지출 수정'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: '이름'),
            ),
            TextField(
              controller: _amount,
              keyboardType: TextInputType.number,
              inputFormatters: digits,
              decoration: const InputDecoration(labelText: '금액', suffixText: '원'),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _envelope,
              onChanged: (v) => setState(() => _envelope = v ?? false),
              title: const Text('월 예약형 (교통비처럼 여러 번 나눠 나가요)'),
            ),
            if (!_envelope)
              TextField(
                controller: _day,
                keyboardType: TextInputType.number,
                inputFormatters: digits,
                decoration: const InputDecoration(labelText: '결제일', suffixText: '일'),
              ),
            if (!_envelope)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _estimate,
                onChanged: (v) => setState(() => _estimate = v ?? false),
                title: const Text('금액이 달마다 달라요 (추정)'),
              ),
            TextField(
              controller: _pattern,
              decoration: const InputDecoration(labelText: '결제 내역의 가맹점 이름(일부)', helperText: '비우면 이름으로 찾아요'),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13)),
              ),
          ],
        ),
      ),
      actions: [
        if (widget.initial != null)
          TextButton(onPressed: () => Navigator.of(context).pop(const _ItemInput.delete()), child: const Text('삭제')),
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('취소')),
        FilledButton(onPressed: _submit, child: const Text('저장')),
      ],
    );
  }
}
