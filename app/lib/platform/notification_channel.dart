import 'package:flutter/services.dart';

/// Kotlin 알림 리스너(PaymentNotificationListener)가 저장한 원문을 읽는다.
class RawNotification {
  RawNotification.fromMap(Map<Object?, Object?> m)
    : id = (m['id'] as num).toInt(),
      packageName = m['package'] as String,
      title = m['title'] as String?,
      text = m['text'] as String?,
      bigText = m['bigText'] as String?,
      subText = m['subText'] as String?,
      postedAt = DateTime.fromMillisecondsSinceEpoch((m['postedAt'] as num).toInt());

  final int id;
  final String packageName;
  final String? title;
  final String? text;
  final String? bigText;
  final String? subText;
  final DateTime postedAt;

  /// 본문은 큰 텍스트가 있으면 그걸 쓴다(알림톡은 긴 본문이 big_text에 있다).
  String get body => (bigText?.isNotEmpty ?? false) ? bigText! : (text ?? '');
}

class SeenPackage {
  SeenPackage.fromMap(Map<Object?, Object?> m)
    : packageName = m['package'] as String,
      count = (m['count'] as num).toInt(),
      lastSeen = DateTime.fromMillisecondsSinceEpoch((m['lastSeen'] as num).toInt());

  final String packageName;
  final int count;
  final DateTime lastSeen;
}

class NotificationChannel {
  static const _channel = MethodChannel('conmoney/notifications');

  Future<bool> isPermissionGranted() async => await _channel.invokeMethod<bool>('isPermissionGranted') ?? false;

  Future<void> openPermissionSettings() => _channel.invokeMethod('openPermissionSettings');

  Future<List<RawNotification>> fetchRaw({int afterId = 0, int limit = 500}) async {
    final rows =
        await _channel.invokeListMethod<Map<Object?, Object?>>('fetchRaw', {'afterId': afterId, 'limit': limit}) ??
        const [];
    return rows.map(RawNotification.fromMap).toList();
  }

  Future<List<SeenPackage>> seenPackages() async {
    final rows = await _channel.invokeListMethod<Map<Object?, Object?>>('seenPackages') ?? const [];
    return rows.map(SeenPackage.fromMap).toList();
  }
}
