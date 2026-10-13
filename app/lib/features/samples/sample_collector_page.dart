import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/masking.dart';
import '../../platform/notification_channel.dart';

/// 1단계: 결제 알림 샘플 수집 화면(Spec 9장 10/14).
/// 받은 원문을 보여주고, 식별 정보를 가린 JSON을 복사해 PC로 옮길 수 있게 한다.
class SampleCollectorPage extends StatefulWidget {
  const SampleCollectorPage({super.key, this.channel});

  final NotificationChannel? channel;

  @override
  State<SampleCollectorPage> createState() => _SampleCollectorPageState();
}

class _SampleCollectorPageState extends State<SampleCollectorPage> with WidgetsBindingObserver {
  late final NotificationChannel _channel = widget.channel ?? NotificationChannel();
  bool? _granted;
  List<RawNotification> _items = const [];
  List<SeenPackage> _packages = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 알림 접근 설정에서 돌아오면 권한 상태를 다시 읽는다
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final granted = await _channel.isPermissionGranted();
    final items = await _channel.fetchRaw();
    final packages = await _channel.seenPackages();
    if (!mounted) return;
    setState(() {
      _granted = granted;
      _items = items.reversed.toList();
      _packages = packages;
    });
  }

  Future<void> _copyMasked() async {
    final json = const JsonEncoder.withIndent('  ').convert([
      for (final n in _items.reversed)
        {
          'package': n.packageName,
          'postedAt': n.postedAt.toIso8601String(),
          'title': maskIdentifiers(n.title),
          'text': maskIdentifiers(n.text),
          'bigText': maskIdentifiers(n.bigText),
          'subText': maskIdentifiers(n.subText),
        },
    ]);
    await Clipboard.setData(ClipboardData(text: json));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${_items.length}건을 복사했어요(카드번호·승인번호는 가림)')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('결제 알림 샘플'),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh), tooltip: '새로고침'),
          IconButton(
            onPressed: _items.isEmpty ? null : _copyMasked,
            icon: const Icon(Icons.copy),
            tooltip: '가린 JSON 복사',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_granted == false)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.notifications_off_outlined),
                  title: const Text('알림 접근 권한이 필요해요'),
                  subtitle: const Text('카드사 결제 알림만 저장하고, 다른 앱은 이름만 셉니다.'),
                  trailing: FilledButton(onPressed: _channel.openPermissionSettings, child: const Text('허용하기')),
                ),
              ),
            Text('받은 결제 알림 ${_items.length}건', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (_items.isEmpty)
              const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Text('아직 없어요. 카드로 결제하면 여기에 쌓입니다.')),
            for (final n in _items)
              Card(
                child: ListTile(
                  title: Text(n.title ?? '(제목 없음)'),
                  subtitle: Text('${n.body}\n${n.packageName} · ${n.postedAt}'),
                  isThreeLine: true,
                ),
              ),
            const SizedBox(height: 24),
            Text('알림을 보낸 앱 (본문 저장 안 함)', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('현대카드 앱의 패키지명을 여기서 찾아 SourceFilter에 넣으세요.', style: theme.textTheme.bodySmall),
            for (final p in _packages) ListTile(dense: true, title: Text(p.packageName), trailing: Text('${p.count}회')),
          ],
        ),
      ),
    );
  }
}
