import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../ui/format.dart';
import 'spending_providers.dart';

/// 결제 확인 시트(Spec F3): 결제 정보 → 카테고리 → 특이 지출 → 메모 → 저장.
/// 카테고리 보기(F8)에서 거래를 고칠 때도 같은 시트를 쓴다. 저장하면 true를 돌려준다.
Future<bool?> showTransactionSheet(BuildContext context, int txnId) => showModalBottomSheet<bool>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  useSafeArea: true,
  builder: (_) => TransactionSheet(txnId: txnId),
);

class TransactionSheet extends ConsumerStatefulWidget {
  const TransactionSheet({super.key, required this.txnId});

  final int txnId;

  @override
  ConsumerState<TransactionSheet> createState() => _TransactionSheetState();
}

class _TransactionSheetState extends ConsumerState<TransactionSheet> {
  TransactionRow? _txn;
  List<CategoryRow> _categories = const [];
  int? _categoryId;
  bool _unusual = false;
  final _memo = TextEditingController();
  final _won = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _memo.dispose();
    _won.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final repo = ref.read(spendingRepositoryProvider);
    final t = await repo.transaction(widget.txnId);
    final cats = await repo.categories();
    if (!mounted) return;
    setState(() {
      _txn = t;
      _categories = cats;
      _categoryId = t.categoryId ?? t.suggestedCategoryId;
      _unusual = t.isUnusual;
      _memo.text = t.memo ?? '';
      if (t.reviewReason == 'FOREIGN_ESTIMATE') _won.text = '${t.amount}';
    });
  }

  Future<void> _save() async {
    await ref
        .read(spendingRepositoryProvider)
        .saveReview(
          widget.txnId,
          categoryId: _categoryId,
          isUnusual: _unusual,
          memo: _memo.text,
          amount: int.tryParse(_won.text.replaceAll(RegExp(r'[^\d]'), '')),
        );
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final t = _txn;
    final theme = Theme.of(context);
    if (t == null) return const SizedBox(height: 240, child: Center(child: CircularProgressIndicator()));

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t.merchantNorm, style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              '${won(t.amount, exact: true)}'
              '${t.installmentMonths > 1 ? ' · ${t.installmentMonths}개월 할부' : ''}'
              '${t.isForeign ? ' · 해외' : ''}',
              style: theme.textTheme.titleMedium,
            ),
            Text(t.localDate, style: theme.textTheme.bodySmall),
            // 원화 금액 없이 온 해외 승인·못 읽은 알림은 0원이라 예산에 안 잡힌다 → 명세서·카드 앱의 원화 금액을 넣는다
            if (t.amount == 0 || t.reviewReason == 'FOREIGN_ESTIMATE') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _won,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '원화 금액',
                  suffixText: '원',
                  helperText: switch ((t.reviewReason, t.originalAmount)) {
                    ('FOREIGN_ESTIMATE', final o) => '$o 결제예요. 누적금액 차이로 계산한 추정이라 카드 앱 금액과 다르면 고쳐 주세요',
                    (_, final o?) => '$o 결제예요. 카드 앱·명세서의 원화 금액을 넣어 주세요',
                    _ => '알림에서 금액을 읽지 못했어요. 결제 금액을 넣어 주세요',
                  },
                  helperMaxLines: 2,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text('카테고리', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final c in _categories)
                  ChoiceChip(
                    label: Text(c.name),
                    selected: _categoryId == c.id,
                    onSelected: (_) => setState(() => _categoryId = c.id),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _unusual,
              onChanged: (v) => setState(() => _unusual = v),
              title: const Text('특이 지출'),
              subtitle: const Text('예산에는 포함되고, 평소 소비 통계에서는 빠져요'),
            ),
            TextField(
              controller: _memo,
              maxLength: 100,
              decoration: const InputDecoration(labelText: '메모', hintText: '예: 동기 생일 선물'),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: _save, child: const Text('저장')),
            ),
          ],
        ),
      ),
    );
  }
}
