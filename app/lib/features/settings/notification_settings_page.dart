import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_providers.dart';
import '../../core/proactive.dart';
import '../../services/local_notifier.dart';
import '../../services/proactive_service.dart';
import '../../ui/insets.dart';

/// 먼저 알려주기 설정(Spec F7): 켜기/끄기, 조용한 시간, 지금 검사.
class NotificationSettingsPage extends ConsumerStatefulWidget {
  const NotificationSettingsPage({super.key, this.notifier});

  /// 테스트용. 없으면 실제 로컬 알림을 쓴다.
  final AlertNotifier? notifier;

  @override
  ConsumerState<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends ConsumerState<NotificationSettingsPage> {
  bool _enabled = true;
  QuietHours _quiet = QuietHours.standard;
  String? _result;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<AlertNotifier> _notifier() async => widget.notifier ?? await LocalNotifier.create();

  ProactiveService _service(AlertNotifier n) =>
      ProactiveService(ref.read(databaseProvider), n, ref.read(clockProvider));

  Future<void> _load() async {
    final s = _service(widget.notifier ?? _NoopNotifier());
    final enabled = await s.enabled();
    final quiet = await s.quietHours();
    if (mounted) {
      setState(() {
        _enabled = enabled;
        _quiet = quiet;
      });
    }
  }

  Future<void> _put(String key, String value) => ref.read(databaseProvider).putSetting(key, value);

  Future<void> _pickHour(bool start) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: start ? _quiet.startHour : _quiet.endHour, minute: 0),
      initialEntryMode: TimePickerEntryMode.dial,
    );
    if (picked == null) return;
    await _put(start ? ProactiveService.quietStartKey : ProactiveService.quietEndKey, '${picked.hour}');
    await _load();
  }

  Future<void> _checkNow() async {
    final n = await _notifier();
    if (n is LocalNotifier) await n.requestPermission();
    final alert = await _service(n).check(AlertTrigger.morning, force: true);
    setState(() => _result = alert == null ? '지금은 알릴 내용이 없어요.' : '보냈어요: ${alert.title}');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('먼저 알려주기')),
      body: ListView(
        padding: pagePadding(context),
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _enabled,
            title: const Text('먼저 알려주기'),
            subtitle: const Text('하루 최대 한 번, 예산이 빠듯해질 때만 알려드려요'),
            onChanged: (v) async {
              await _put(ProactiveService.enabledKey, v ? '1' : '0');
              await _load();
            },
          ),
          const Divider(),
          Text('이럴 때 알려드려요', style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          const Text(
            '• 오늘 쓸 수 있는 금액을 넘었을 때(결제 직후)\n'
            '• 큰 정기 지출이 이틀 안에 나갈 때(아침)\n'
            '• 지금 속도면 월말에 예산을 넘을 것 같을 때(아침, 처음 한 번)',
          ),
          const Divider(height: 32),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('조용한 시간'),
            subtitle: Text('${_quiet.startHour}시 ~ ${_quiet.endHour}시에는 보내지 않아요'),
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(onPressed: () => _pickHour(true), child: Text('${_quiet.startHour}시부터')),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(onPressed: () => _pickHour(false), child: Text('${_quiet.endHour}시까지')),
              ),
            ],
          ),
          const Divider(height: 32),
          FilledButton.tonal(onPressed: _checkNow, child: const Text('지금 검사해 보기')),
          if (_result != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_result!)),
        ],
      ),
    );
  }
}

class _NoopNotifier implements AlertNotifier {
  @override
  Future<void> show(ProactiveAlert alert) async {}
}
