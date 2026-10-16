import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_providers.dart';
import '../../data/metrics_repository.dart';
import '../../ui/insets.dart';

final _summaryProvider = FutureProvider.autoDispose<MetricsSummary>(
  (ref) => MetricsRepository(ref.watch(databaseProvider)).summary(),
);

/// 실사용 지표(PRD 8장): 상담 품질·비용·속도, 카테고리 추천 수락률, 보낸 알림 수.
class MetricsPage extends ConsumerWidget {
  const MetricsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(_summaryProvider);
    String pct(double? v) => v == null ? '-' : '${(v * 100).toStringAsFixed(0)}%';
    return Scaffold(
      appBar: AppBar(
        title: const Text('사용 기록'),
        actions: [
          IconButton(
            tooltip: 'JSON 복사',
            icon: const Icon(Icons.copy),
            onPressed: () async {
              final json = await MetricsRepository(ref.read(databaseProvider)).exportJson();
              await Clipboard.setData(ClipboardData(text: json));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('사용 기록을 복사했어요(수치만 있음)')));
              }
            },
          ),
        ],
      ),
      body: summary.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('불러오지 못했어요: $e')),
        data: (s) => ListView(
          padding: pagePadding(context),
          children: [
            if (s.since != null)
              Text('${s.since!.month}/${s.since!.day}부터 기록', style: Theme.of(context).textTheme.bodySmall),
            const _Header('구매 상담'),
            _Row('상담 수', '${s.consults}회 (오류 ${s.consultErrors}회)'),
            _Row('숫자 검증 통과', pct(s.verifiedRate)),
            _Row('평균 비용', '${s.avgKrw.toStringAsFixed(1)}원'),
            _Row('평균 응답 시간', '${(s.avgLatencyMs / 1000).toStringAsFixed(1)}초'),
            _Row('평균 라운드', s.avgRounds.toStringAsFixed(1)),
            const _Header('카테고리 추천'),
            _Row('확인한 결제', '${s.reviews}건'),
            _Row('추천 그대로 받음', pct(s.acceptRate)),
            for (final e in s.acceptBySource.entries) _Row('  ${e.key}', pct(e.value)),
            const _Header('먼저 알려주기'),
            _Row('보낸 알림', '${s.alerts}회'),
            const SizedBox(height: 16),
            Text('대화 내용·가맹점 이름은 기록하지 않아요.', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 4),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) =>
      ListTile(dense: true, contentPadding: EdgeInsets.zero, title: Text(label), trailing: Text(value));
}
