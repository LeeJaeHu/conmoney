import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../core/proactive.dart';
import 'proactive_service.dart';

/// Android 로컬 알림. 먼저 알려주기 채널(proactive)은 결제 확인 채널과 분리한다(Spec F3·F7).
class LocalNotifier implements AlertNotifier {
  LocalNotifier._(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  static Future<LocalNotifier> create() async {
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(
      settings: const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')),
    );
    return LocalNotifier._(plugin);
  }

  /// Android 13+ 알림 표시 권한 요청. 앱 화면에서만 부른다(백그라운드에서는 물을 수 없음).
  Future<bool> requestPermission() async =>
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission() ??
      false;

  @override
  Future<void> show(ProactiveAlert alert) => _plugin.show(
    id: 7000 + alert.type.index,
    title: alert.title,
    body: alert.body,
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        'proactive',
        '먼저 알려주기',
        channelDescription: '하루 최대 한 번, 예산이 빠듯해질 때만 보내요',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
    ),
  );
}
