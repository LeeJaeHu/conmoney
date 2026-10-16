import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_providers.dart';
import '../../data/database.dart';
import '../../ui/format.dart';
import '../../ui/insets.dart';
import 'spending_providers.dart';
import 'transaction_sheet.dart';

final _unconfirmedProvider = FutureProvider<List<TransactionRow>>((ref) => ref.watch(repositoryProvider).unconfirmed());

/// 확인 안 한 결제 목록(10/16). 항목을 누르면 확인 시트(F3)에서 카테고리를 정하고 저장하면 목록에서 빠진다.
/// 결제 직후 알림으로 여는 F3 흐름은 F2(알림 파서) 이후.
class ReviewPage extends ConsumerWidget {
  const ReviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(_unconfirmedProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('확인 안 한 결제')),
      body: rows.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('불러오지 못했어요: $e')),
        data: (list) => ListView(
          padding: pagePadding(context, all: 0),
          children: [
            if (list.isEmpty)
              const Padding(padding: EdgeInsets.all(24), child: Text('모두 확인했어요'))
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text('누르면 카테고리를 정할 수 있어요. 저장하면 목록에서 빠져요.', style: theme.textTheme.bodySmall),
              ),
            for (final t in list)
              ListTile(
                leading: Text(_md(t.localDate)),
                title: Text(t.merchantNorm, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  t.reviewReason ??
                      switch (t.kind) {
                        'MANUAL' => '직접 기록한 지출 · 카테고리 미확인',
                        _ => '카테고리 미확인',
                      },
                ),
                trailing: Text(won(t.amount, exact: true)),
                onTap: () async {
                  final saved = await showTransactionSheet(context, t.id);
                  if (saved == true) {
                    ref.invalidate(_unconfirmedProvider);
                    ref.invalidate(spendItemsProvider);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}

String _md(String ymd) {
  final d = DateTime.parse(ymd);
  return '${d.month}/${d.day}';
}
