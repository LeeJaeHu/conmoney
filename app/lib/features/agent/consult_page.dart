import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_providers.dart';
import '../../core/agent_tools.dart';
import '../../core/budget_engine.dart';
import '../../core/budget_plan.dart';
import '../../core/models.dart';
import '../../data/agent_client.dart';
import '../../data/metrics_repository.dart';
import '../spending/spending_providers.dart';

final agentClientProvider = Provider<AgentClient>((ref) => AgentClient());

/// 툴 실행기를 질문할 때마다 최신 데이터로 만든다. 의존성은 await 전에 모두 읽어 둔다.
Future<AgentToolbox> buildToolbox(WidgetRef ref) async {
  final repo = ref.read(repositoryProvider);
  final spending = ref.read(spendingRepositoryProvider);
  final now = ref.read(clockProvider)();
  return AgentToolbox(
    engine: BudgetEngine(await repo.loadLedger()),
    budget: budgetFor(await repo.budgets(), YearMonth.of(now)),
    items: await spending.items(),
    now: now,
  );
}

const _toolLabels = {
  'get_budget_status': '이번 달 예산 확인',
  'get_upcoming_fixed': '다가오는 정기 지출 확인',
  'get_spending_pattern': '평소 소비 패턴 확인',
  'simulate_purchase': '샀을 때 계산',
  'get_category_summary': '카테고리별 지출 확인',
};

class _Msg {
  _Msg.user(this.text) : fromUser = true, verdict = null, verified = true;
  _Msg.assistant(this.text, {this.verdict, this.verified = true}) : fromUser = false;

  final bool fromUser;
  final String text;
  final String? verdict;
  final bool verified;
}

/// 구매 상담(Spec F6). P0에서는 대화를 저장하지 않는다(화면을 나가면 사라짐).
class ConsultPage extends ConsumerStatefulWidget {
  const ConsultPage({super.key});

  @override
  ConsumerState<ConsultPage> createState() => _ConsultPageState();
}

class _ConsultPageState extends ConsumerState<ConsultPage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <_Msg>[];
  final _items = <Map<String, Object?>>[];
  String? _progress;
  bool get _busy => _progress != null;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _ask(String question) async {
    final q = question.trim();
    if (q.isEmpty || _busy) return;
    _input.clear();
    setState(() {
      _messages.add(_Msg.user(q));
      _progress = '생각하는 중';
    });
    _items.add({'role': 'user', 'content': q});

    final client = ref.read(agentClientProvider);
    final metrics = MetricsRepository(ref.read(databaseProvider));
    final session = '${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(1 << 20)}';
    final watch = Stopwatch()..start();
    final tools = <String>[];
    var krw = 0.0;
    var rounds = 0;
    try {
      final toolbox = await buildToolbox(ref);
      for (var round = 1; round <= 5; round++) {
        rounds = round;
        final reply = await client.step(_items, round, session: session, today: _ymd(toolbox.now));
        krw += reply.krw;
        _items.addAll(reply.items);
        if (reply.status == 'final') {
          setState(
            () => _messages.add(_Msg.assistant(reply.text ?? '', verdict: reply.verdict, verified: reply.verified)),
          );
          await metrics.consult(
            rounds: round,
            krw: krw,
            latencyMs: watch.elapsedMilliseconds,
            verdict: reply.verdict,
            verified: reply.verified,
            tools: tools,
          );
          return;
        }
        for (final c in reply.toolCalls) {
          tools.add(c.name);
          setState(() => _progress = _toolLabels[c.name] ?? '확인 중');
          _items.add({
            'type': 'function_call_output',
            'call_id': c.callId,
            'output': jsonEncode(toolbox.run(c.name, c.arguments)),
          });
        }
      }
      setState(() => _messages.add(_Msg.assistant('답을 정리하지 못했어요. 질문을 조금 바꿔서 다시 물어봐 주세요.', verified: false)));
      await metrics.consult(
        rounds: rounds,
        krw: krw,
        latencyMs: watch.elapsedMilliseconds,
        verdict: null,
        verified: false,
        tools: tools,
        error: true,
      );
    } on AgentException catch (e) {
      _items.removeLast();
      setState(() => _messages.add(_Msg.assistant(e.message, verified: false)));
      await metrics.consult(
        rounds: rounds,
        krw: krw,
        latencyMs: watch.elapsedMilliseconds,
        verdict: null,
        verified: false,
        tools: tools,
        error: true,
      );
    } finally {
      if (mounted) setState(() => _progress = null);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('살까 말까')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              children: [
                if (_messages.isEmpty) ...[
                  Text('사고 싶은 것과 금액을 알려주세요. 남은 예산과 평소 소비를 보고 같이 판단해 드려요.', style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final ex in ['키보드 15만 원 살까?', '이번 주말에 5만 원 써도 돼?', '이번 달 어디에 많이 썼어?'])
                        ActionChip(label: Text(ex), onPressed: () => _ask(ex)),
                    ],
                  ),
                ],
                for (final m in _messages) _Bubble(m),
                if (_busy)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                        const SizedBox(width: 8),
                        Text('$_progress…', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      enabled: !_busy,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _ask,
                      decoration: const InputDecoration(hintText: '예: 운동화 12만 원 살까?', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _busy ? null : () => _ask(_input.text),
                    icon: const Icon(Icons.send),
                    tooltip: '보내기',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble(this.m);

  final _Msg m;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final verdictLabel = switch (m.verdict) {
      'ok' => '괜찮아요',
      'conditional' => '조건부',
      'postpone' => '미루는 걸 추천',
      'next_month' => '다음 달 기준',
      _ => null,
    };
    return Align(
      alignment: m.fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 520),
        decoration: BoxDecoration(
          color: m.fromUser ? scheme.primaryContainer : scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (verdictLabel != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Chip(label: Text(verdictLabel), visualDensity: VisualDensity.compact),
              ),
            Text(m.text, style: theme.textTheme.bodyMedium),
            if (!m.fromUser && !m.verified)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('숫자를 확인하지 못한 답이에요', style: theme.textTheme.bodySmall?.copyWith(color: scheme.error)),
              ),
          ],
        ),
      ),
    );
  }
}

String _ymd(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
