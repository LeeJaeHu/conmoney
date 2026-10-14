import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import '../core/proactive.dart';
import '../data/database.dart';
import 'local_notifier.dart';
import 'proactive_service.dart';

const proactiveTask = 'proactive-check';

/// WorkManager가 앱 밖에서 부르는 진입점. 1시간마다 깨어나 조용한 시간이 끝난 뒤 첫 실행에서만 아침 검사를 한다
/// (정확히 08:00을 보장할 수 없는 Android 배터리 정책 때문에 "8시 이후 첫 실행"으로 둔다).
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    final db = AppDatabase();
    try {
      await ProactiveService(db, await LocalNotifier.create(), DateTime.now).check(AlertTrigger.morning);
      return true;
    } catch (_) {
      return false;
    } finally {
      await db.close();
    }
  });
}

Future<void> registerBackgroundWork() async {
  await Workmanager().initialize(callbackDispatcher);
  await Workmanager().registerPeriodicTask(
    proactiveTask,
    proactiveTask,
    frequency: const Duration(hours: 1),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
  );
}
