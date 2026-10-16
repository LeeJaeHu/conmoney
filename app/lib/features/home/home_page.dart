import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_providers.dart';
import '../../core/budget_engine.dart';
import '../../core/models.dart';
import '../../ui/format.dart';
import '../../ui/insets.dart';
import '../../ui/theme.dart';
import '../agent/consult_page.dart';
import '../budget/budget_settings_page.dart';
import '../dev/import_page.dart';
import '../planned/planned_page.dart';
import '../recurring/recurring_page.dart';
import '../samples/sample_collector_page.dart';
import '../settings/metrics_page.dart';
import '../settings/notification_settings_page.dart';
import '../spending/category_page.dart';
import '../spending/review_page.dart';
import '../spending/spending_providers.dart';
import 'spend_calendar.dart';

/// 홈 화면(Spec F4): 오늘 쓸 수 있는 금액(크게) + 이번 달 남은 예산(작게). 총 사용액은 보여주지 않는다.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(homeProvider);

    Future<void> open(Widget page) async {
      await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
      ref.invalidate(homeProvider);
      ref.invalidate(spendItemsProvider);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('conmoney'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) => switch (v) {
              'budget' => open(const BudgetSettingsPage()),
              'import' => open(const ImportPage()),
              'recurring' => open(const RecurringPage()),
              'planned' => open(const PlannedPage()),
              'category' => open(const CategoryPage()),
              'alerts' => open(const NotificationSettingsPage()),
              'metrics' => open(const MetricsPage()),
              _ => open(const SampleCollectorPage()),
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'budget', child: Text('예산 설정')),
              PopupMenuItem(value: 'recurring', child: Text('정기 지출')),
              PopupMenuItem(value: 'planned', child: Text('예정 지출(축의금 등)')),
              PopupMenuItem(value: 'category', child: Text('지출 분석')),
              PopupMenuItem(value: 'alerts', child: Text('먼저 알려주기')),
              PopupMenuItem(value: 'metrics', child: Text('사용 기록')),
              PopupMenuItem(value: 'import', child: Text('과거 기록 가져오기')),
              PopupMenuItem(value: 'samples', child: Text('결제 알림 샘플')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(homeProvider.future),
        child: home.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            children: [Padding(padding: const EdgeInsets.all(24), child: Text('불러오지 못했어요: $e'))],
          ),
          data: (data) => ListView(
            padding: pagePadding(context),
            children: [
              if (data.status case final st?)
                _TodayCard(status: st, data: data)
              else
                _NoBudgetCard(data: data, onSetup: () => open(const BudgetSettingsPage())),
              const SizedBox(height: 5),
              SpendCalendar(
                upcomingDays: {
                  for (final (item, due, _) in data.upcoming)
                    if (!item.isEnvelope && due.month == data.month.month) due.day,
                },
              ),
              if (data.unconfirmed > 0)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.pending_actions_outlined),
                    title: Text('확인 안 한 결제 ${data.unconfirmed}건'),
                    subtitle: const Text('카테고리를 정해 주세요'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => open(const ReviewPage()),
                  ),
                ),
              _UpcomingCard(data: data, onOpen: () => open(const RecurringPage())),
              const SizedBox(height: 5),
              OutlinedButton.icon(
                onPressed: () => open(const CategoryPage()),
                icon: const Icon(Icons.insights_outlined),
                label: const Text('지출 분석 보기'),
              ),
            ],
          ),
        ),
      ),
      // 상담은 어디까지 내려도 보이게 화면 아래 고정(10/16 디자인)
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: () => open(const ConsultPage()),
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('살까 말까 물어보기'),
          ),
        ),
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.status, required this.data});

  final BudgetStatus status;
  final HomeData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 초과는 빨간색 대신 주황 계열(스트레스 최소화 원칙)
    final overColor = AppColors.warm(theme.brightness);
    final secondary = theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('오늘 쓸 수 있는 금액', style: secondary),
            const SizedBox(height: 2),
            Text(
              won(status.availableShown),
              style: theme.textTheme.displaySmall?.copyWith(color: theme.colorScheme.onSurface),
            ),
            if (status.todayOver > 0) ...[
              const SizedBox(height: 4),
              Text(
                '오늘 ${won(status.todayOver)} 넘었어요'
                '${status.tomorrowBase != null && status.monthOver == 0 ? ' · 내일부터 하루 ${won(status.tomorrowBase! < 0 ? 0 : status.tomorrowBase!)}' : ''}',
                style: theme.textTheme.bodyMedium?.copyWith(color: overColor),
              ),
            ],
            const SizedBox(height: 14),
            BudgetGauge(status: status, month: data.month),
            const SizedBox(height: 14),
            if (status.monthOver > 0) ...[
              Text(
                '이번 달 예산을 ${won(status.monthOver)} 넘었어요',
                style: theme.textTheme.titleMedium?.copyWith(color: overColor),
              ),
              if (status.overOnlyAfterFixed)
                Text('예정된 정기·예정 지출 ${won(status.upcomingFixed)}을 반영한 금액이에요', style: secondary),
            ] else
              Text('이번 달 남은 예산 ${won(status.remaining)}', style: theme.textTheme.titleMedium),
            const SizedBox(height: 2),
            Text(
              '남은 ${status.daysLeft}일'
              '${status.upcomingFixed > 0 ? ' · 정기·예정 지출 ${won(status.upcomingFixed)} 미리 뺌' : ''}',
              style: secondary,
            ),
            if (data.planStep case final step?)
              Text(
                '${data.month.month}월 목표 ${manWon(status.budget)} · ${step.index}/${step.total}단계 (최종 ${manWon(step.targetAmount)})',
                style: secondary,
              ),
          ],
        ),
      ),
    );
  }
}

/// 예산 게이지(10/16 디자인 B2): 이번 달 예산을 쓴 비율(막대)과 달이 지난 비율(세로선)을 겹쳐 보여준다.
/// 막대가 선보다 길면 날짜보다 빨리 쓰는 중. 판단 색은 쓰지 않고, 예산을 넘었을 때만 주황.
class BudgetGauge extends StatelessWidget {
  const BudgetGauge({super.key, required this.status, required this.month});

  final BudgetStatus status;
  final YearMonth month;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final b = theme.brightness;
    final used = status.budget > 0 ? status.spent / status.budget : 0.0;
    final day = month.days - status.daysLeft + 1;
    final elapsed = day / month.days;
    final over = used > 1;
    final fill = over ? AppColors.warm(b) : (b == Brightness.dark ? AppColors.blueDark : AppColors.blueLight);
    final label = theme.textTheme.labelMedium?.copyWith(fontFeatures: tabular);
    return Semantics(
      label: '이번 달 예산의 ${(used * 100).round()}%를 썼고, 달은 ${(elapsed * 100).round()}% 지났어요',
      child: ExcludeSemantics(
        child: Column(
          children: [
            SizedBox(
              height: 10,
              child: LayoutBuilder(
                builder: (context, c) => Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(color: AppColors.track(b), borderRadius: BorderRadius.circular(5)),
                    ),
                    Container(
                      width: c.maxWidth * used.clamp(0.0, 1.0),
                      decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(5)),
                    ),
                    Positioned(
                      left: (c.maxWidth * elapsed - 1).clamp(0.0, c.maxWidth - 2),
                      top: 0,
                      bottom: 0,
                      child: Container(width: 2, color: theme.colorScheme.onSurface),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text('예산 ${(used * 100).round()}% 씀', style: label?.copyWith(color: fill)),
                const Spacer(),
                Text('$day일째 · 달의 ${(elapsed * 100).round()}%', style: label?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NoBudgetCard extends StatelessWidget {
  const _NoBudgetCard({required this.data, required this.onSetup});

  final HomeData data;
  final VoidCallback onSetup;

  @override
  Widget build(BuildContext context) {
    final next = data.nextBudget;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              next == null
                  ? '월 예산을 정하면 오늘 쓸 수 있는 금액을 알려드려요'
                  : '${next.month.month}월 1일부터 목표 ${manWon(next.amount)}으로 시작해요',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: onSetup, child: Text(next == null ? '예산 정하기' : '예산 설정 보기')),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({required this.data, required this.onOpen});

  final HomeData data;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  children: [
                    Expanded(child: Text('다가오는 지출', style: theme.textTheme.titleSmall)),
                    const Icon(Icons.chevron_right, size: 20),
                  ],
                ),
              ),
              if (data.upcoming.isEmpty)
                ListTile(
                  dense: true,
                  title: Text(
                    data.recurringSuggestions > 0
                        ? '매달 나가는 결제 ${data.recurringSuggestions}개를 찾았어요. 등록하면 예산에서 미리 빼 드려요'
                        : '정기 지출을 등록하면 예산에서 미리 빼 드려요',
                  ),
                ),
              for (final (item, due, amount) in data.upcoming)
                ListTile(
                  dense: true,
                  leading: Text(item.isEnvelope ? '이번 달' : '${due.month}/${due.day}'),
                  title: Text(item.isEnvelope ? '${item.name} 남은 예약' : item.name),
                  trailing: Text('${item.isEstimate ? '약 ' : ''}${won(amount)}'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
