import '../core/proactive.dart';
import '../data/database.dart';
import '../data/notification_ingest.dart';
import '../platform/notification_channel.dart';
import 'local_notifier.dart';
import 'proactive_service.dart';

/// 리스너가 모아 둔 결제 알림을 거래로 옮긴다(Spec F2). 앱을 열 때·다시 돌아올 때·홈을 당겨 새로고침할 때 부른다.
/// 새 승인이 있으면 결제 직후 먼저 알려주기 검사(F7 "오늘 쓸 수 있는 금액을 넘었을 때")도 한 번 한다.
Future<IngestResult> syncPaymentNotifications(
  AppDatabase db, {
  NotificationChannel? channel,
  AlertNotifier? notifier,
  DateTime Function() clock = DateTime.now,
}) async {
  final ch = channel ?? NotificationChannel();
  final raws = <RawPaymentNotification>[];
  var after = 0;
  while (true) {
    final page = await ch.fetchRaw(afterId: after);
    if (page.isEmpty) break;
    raws.addAll([
      for (final n in page)
        RawPaymentNotification(id: n.id, packageName: n.packageName, title: n.title, body: n.body, postedAt: n.postedAt),
    ]);
    after = page.last.id;
  }
  final result = await NotificationIngestor(db).ingest(raws);
  if (result.newApprovals.isNotEmpty) {
    await ProactiveService(db, notifier ?? await LocalNotifier.create(), clock).check(AlertTrigger.afterTransaction);
  }
  return result;
}
