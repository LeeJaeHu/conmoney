import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_providers.dart';
import '../../data/database.dart';
import '../../data/planned_repository.dart';
import '../../ui/format.dart';
import '../../ui/insets.dart';

final plannedRepositoryProvider = Provider((ref) => PlannedRepository(ref.watch(databaseProvider)));

final _plannedProvider = FutureProvider<List<PlannedExpenseRow>>((ref) => ref.watch(plannedRepositoryProvider).list());

/// 예정 지출 화면(10/15 결정): 축의금처럼 한 번 나갈 지출을 미리 적어 두면 그 달 예산에서 미리 뺀다.
/// 상담 중 "다음 주 축의금 10만 원"이라고 하면 상담 화면에서도 [등록]할 수 있다.
class PlannedPage extends ConsumerWidget {
  const PlannedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(_plannedProvider);
    final repo = ref.read(plannedRepositoryProvider);
    final now = ref.read(clockProvider)();

    Future<void> run(Future<void> Function() action) async {
      await action();
      ref.invalidate(_plannedProvider);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('예정 지출')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final input = await showDialog<_PlanInput>(context: context, builder: (_) => _PlanDialog(today: now));
          if (input != null) await run(() => repo.add(name: input.name, amount: input.amount, date: input.date));
        },
        icon: const Icon(Icons.add),
        label: const Text('추가'),
      ),
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('불러오지 못했어요: $e')),
        data: (rows) {
          final theme = Theme.of(context);
          return ListView(
            padding: pagePadding(context, bottom: 96),
            children: [
              Text('축의금처럼 한 번 나갈 돈을 적어 두면 그 달 예산에서 미리 빼요.', style: theme.textTheme.bodySmall),
              const SizedBox(height: 8),
              if (rows.isEmpty) const Card(child: ListTile(title: Text('아직 없어요. [추가]로 적어 두세요'))),
              for (final r in rows)
                Card(
                  child: ListTile(
                    enabled: r.doneOn == null,
                    leading: Text(_md(r.date)),
                    title: Text(r.name),
                    subtitle: Text(
                      r.doneOn == null ? won(r.amount, exact: true) : '${won(r.amount, exact: true)} · ${_md(r.doneOn!)}에 냄',
                    ),
                    trailing: r.doneOn == null
                        ? FilledButton.tonal(
                            onPressed: () => run(() => repo.markPaid(r.id, now)),
                            child: const Text('냈어요'),
                          )
                        : null,
                    onTap: () async {
                      final input = await showDialog<_PlanInput>(
                        context: context,
                        builder: (_) => _PlanDialog(today: now, initial: r),
                      );
                      if (input == null) return;
                      if (input.delete) {
                        await run(() => repo.delete(r.id));
                      } else {
                        await run(() => repo.update(r.id, name: input.name, amount: input.amount, date: input.date));
                      }
                    },
                    onLongPress: r.doneOn == null ? null : () => run(() => repo.delete(r.id)),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  static String _md(String ymd) {
    final d = DateTime.parse(ymd);
    return '${d.month}/${d.day}';
  }
}

class _PlanInput {
  const _PlanInput(this.name, this.amount, this.date, {this.delete = false});

  final String name;
  final int amount;
  final DateTime date;
  final bool delete;
}

class _PlanDialog extends StatefulWidget {
  const _PlanDialog({required this.today, this.initial});

  final DateTime today;
  final PlannedExpenseRow? initial;

  @override
  State<_PlanDialog> createState() => _PlanDialogState();
}

class _PlanDialogState extends State<_PlanDialog> {
  late final _name = TextEditingController(text: widget.initial?.name ?? '');
  late final _amount = TextEditingController(text: widget.initial?.amount.toString() ?? '');
  late DateTime _date = widget.initial == null
      ? widget.today.add(const Duration(days: 7))
      : DateTime.parse(widget.initial!.date);

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amount = int.tryParse(_amount.text) ?? 0;
    final valid = _name.text.trim().isNotEmpty && amount > 0;
    return AlertDialog(
      title: Text(widget.initial == null ? '예정 지출 추가' : '예정 지출 수정'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: '이름(예: 친구 축의금)'),
            onChanged: (_) => setState(() {}),
          ),
          TextField(
            controller: _amount,
            decoration: InputDecoration(labelText: '금액(원)', helperText: amount > 0 ? won(amount, exact: true) : null),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('${_date.year}. ${_date.month}. ${_date.day}.'),
            subtitle: const Text('낼 날짜. 이 날이 속한 달 예산에서 빠져요'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(widget.today.year, widget.today.month),
                lastDate: DateTime(widget.today.year + 1, widget.today.month + 1, 0),
              );
              if (picked != null) setState(() => _date = picked);
            },
          ),
        ],
      ),
      actions: [
        if (widget.initial != null)
          TextButton(
            onPressed: () => Navigator.pop(context, _PlanInput('', 0, _date, delete: true)),
            child: const Text('삭제'),
          ),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
        FilledButton(
          onPressed: valid ? () => Navigator.pop(context, _PlanInput(_name.text.trim(), amount, _date)) : null,
          child: const Text('저장'),
        ),
      ],
    );
  }
}
