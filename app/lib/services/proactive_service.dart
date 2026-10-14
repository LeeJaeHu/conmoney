import 'package:drift/drift.dart';

import '../core/budget_engine.dart';
import '../core/budget_plan.dart';
import '../core/models.dart';
import '../core/proactive.dart';
import '../data/database.dart';
import '../data/ledger_repository.dart';

/// 알림을 실제로 띄우는 쪽. 테스트에서는 가짜로 바꾼다.
abstract interface class AlertNotifier {
  Future<void> show(ProactiveAlert alert);
}

/// 먼저 알려주기(Spec F7) 실행: 조건 검사 → 알림 → 기록.
class ProactiveService {
  ProactiveService(this.db, this.notifier, this.clock);

  final AppDatabase db;
  final AlertNotifier notifier;
  final DateTime Function() clock;

  static const enabledKey = 'proactive_enabled';
  static const quietStartKey = 'quiet_start';
  static const quietEndKey = 'quiet_end';
  static const _morningChecked = 'MORNING_CHECKED';

  static String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<bool> enabled() async => (await db.setting(enabledKey)) != '0';

  Future<QuietHours> quietHours() async => QuietHours(
    int.tryParse(await db.setting(quietStartKey) ?? '') ?? QuietHours.standard.startHour,
    int.tryParse(await db.setting(quietEndKey) ?? '') ?? QuietHours.standard.endHour,
  );

  Future<List<NotificationLogRow>> _logsOn(DateTime day) =>
      (db.select(db.notificationLogs)..where((l) => l.localDate.equals(_ymd(day)))).get();

  Future<void> _log(String type, DateTime now, [String? summary]) => db
      .into(db.notificationLogs)
      .insert(NotificationLogsCompanion.insert(type: type, sentAt: now, localDate: _ymd(now), summary: Value(summary)));

  /// 아침 검사는 하루 한 번(조용한 시간이 끝난 뒤 첫 실행), 결제 직후 검사는 결제마다 부른다.
  /// [force]는 설정 화면의 "지금 검사" 버튼용으로 하루 1회 제한과 아침 1회 제한을 무시한다.
  Future<ProactiveAlert?> check(AlertTrigger trigger, {bool force = false}) async {
    if (!await enabled()) return null;
    final now = clock();
    final quiet = await quietHours();
    final logs = await _logsOn(now);
    if (!force && trigger == AlertTrigger.morning) {
      if (quiet.contains(now) || logs.any((l) => l.type == _morningChecked)) return null;
      await _log(_morningChecked, now);
    }
    final sentToday = logs.any((l) => l.type != 'CONFIRM' && l.type != _morningChecked);

    final repo = LedgerRepository(db);
    final alert = evaluate(
      engine: BudgetEngine(await repo.loadLedger()),
      budget: budgetFor(await repo.budgets(), YearMonth.of(now)),
      now: now,
      trigger: trigger,
      alreadySentToday: sentToday && !force,
      quiet: force ? const QuietHours(0, 0) : quiet,
    );
    if (alert == null) return null;
    await notifier.show(alert);
    await _log(alert.logType, now, alert.title);
    return alert;
  }
}
