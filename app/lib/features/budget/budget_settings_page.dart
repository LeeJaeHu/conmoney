import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_providers.dart';
import '../../core/budget_plan.dart';
import '../../core/models.dart';
import '../../data/database.dart';
import '../../ui/format.dart';

enum _Mode { fixed, step }

/// 예산 설정(Spec F4): 고정 또는 단계적 목표. 금액은 만 원 단위로 입력한다.
class BudgetSettingsPage extends ConsumerStatefulWidget {
  const BudgetSettingsPage({super.key});

  @override
  ConsumerState<BudgetSettingsPage> createState() => _BudgetSettingsPageState();
}

class _BudgetSettingsPageState extends ConsumerState<BudgetSettingsPage> {
  _Mode _mode = _Mode.step;
  bool _startNextMonth = true;
  int _months = 3;
  final _fixed = TextEditingController(text: '54');
  final _start = TextEditingController();
  final _target = TextEditingController(text: '54');
  int? _suggestedStart;

  @override
  void initState() {
    super.initState();
    _loadDefaults();
  }

  @override
  void dispose() {
    _fixed.dispose();
    _start.dispose();
    _target.dispose();
    super.dispose();
  }

  Future<void> _loadDefaults() async {
    final repo = ref.read(repositoryProvider);
    final now = ref.read(clockProvider)();
    final suggested = defaultStartAmount(await repo.recentMonthlyTotals(now));
    final plan = await repo.latestPlan();
    if (!mounted) return;
    setState(() {
      _suggestedStart = suggested;
      if (plan != null) {
        _mode = plan.mode == 'STEP' ? _Mode.step : _Mode.fixed;
        _months = plan.months.clamp(2, 6);
        _target.text = '${plan.targetAmount ~/ 10000}';
        _fixed.text = '${plan.targetAmount ~/ 10000}';
        _start.text = '${plan.startAmount ~/ 10000}';
      } else if (suggested > 0) {
        _start.text = '${suggested ~/ 10000}';
      }
    });
  }

  YearMonth get _startMonth {
    final m = YearMonth.of(ref.read(clockProvider)());
    return _startNextMonth ? m.plus(1) : m;
  }

  int? _man(TextEditingController c) {
    final v = int.tryParse(c.text.trim());
    return v == null || v <= 0 ? null : v * 10000;
  }

  List<MonthlyBudget>? get _plan {
    if (_mode == _Mode.fixed) {
      final amount = _man(_fixed);
      return amount == null ? null : [MonthlyBudget(_startMonth, amount, BudgetSource.fixed)];
    }
    final start = _man(_start), target = _man(_target);
    if (start == null || target == null) return null;
    return stepPlan(start: _startMonth, startAmount: start, targetAmount: target, months: _months);
  }

  Future<void> _save() async {
    final plan = _plan;
    if (plan == null) return;
    await ref.read(repositoryProvider).saveBudgets(
          _startMonth,
          plan,
          setting: BudgetPlansCompanion.insert(
            mode: _mode == _Mode.step ? 'STEP' : 'FIXED',
            startMonth: _startMonth.toString(),
            startAmount: plan.first.amount,
            targetAmount: plan.last.amount,
            months: _mode == _Mode.step ? _months : 1,
            createdAt: Value(DateTime.now()),
          ),
        );
    if (mounted) Navigator.of(context).pop();
  }

  Widget _manField(TextEditingController c, String label, {String? helper}) => TextField(
        controller: c,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(labelText: label, suffixText: '만 원', helperText: helper, border: const OutlineInputBorder()),
        onChanged: (_) => setState(() {}),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plan = _plan;
    final thisMonth = YearMonth.of(ref.read(clockProvider)());

    return Scaffold(
      appBar: AppBar(title: const Text('예산 설정')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<_Mode>(
            segments: const [
              ButtonSegment(value: _Mode.fixed, label: Text('고정')),
              ButtonSegment(value: _Mode.step, label: Text('단계적')),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => setState(() => _mode = s.first),
          ),
          const SizedBox(height: 8),
          Text(
            _mode == _Mode.fixed ? '매달 같은 금액을 목표로 해요.' : '지금 쓰는 금액에서 몇 달에 걸쳐 목표까지 내려가요.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: false, label: Text('이번 달(${thisMonth.month}월)부터')),
              ButtonSegment(value: true, label: Text('다음 달(${thisMonth.plus(1).month}월)부터')),
            ],
            selected: {_startNextMonth},
            onSelectionChanged: (s) => setState(() => _startNextMonth = s.first),
          ),
          const SizedBox(height: 20),
          if (_mode == _Mode.fixed)
            _manField(_fixed, '월 목표')
          else ...[
            _manField(
              _start,
              '시작 금액',
              helper: _suggestedStart != null && _suggestedStart! > 0
                  ? '최근 3개월 평균(특이 지출 제외) ${manWon(_suggestedStart!)}'
                  : null,
            ),
            const SizedBox(height: 16),
            _manField(_target, '최종 목표'),
            const SizedBox(height: 16),
            Text('기간 $_months개월', style: theme.textTheme.titleSmall),
            Slider(
              value: _months.toDouble(),
              min: 2,
              max: 6,
              divisions: 4,
              label: '$_months개월',
              onChanged: (v) => setState(() => _months = v.round()),
            ),
          ],
          const SizedBox(height: 8),
          if (plan != null)
            Card(
              child: Column(
                children: [
                  for (final b in plan)
                    ListTile(dense: true, title: Text('${b.month.year}년 ${b.month.month}월'), trailing: Text(manWon(b.amount))),
                  if (_mode == _Mode.step)
                    const ListTile(dense: true, title: Text('그 이후'), trailing: Text('최종 목표 유지')),
                ],
              ),
            ),
          const SizedBox(height: 16),
          FilledButton(onPressed: plan == null ? null : _save, child: const Text('저장')),
        ],
      ),
    );
  }
}
