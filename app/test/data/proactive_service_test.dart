import 'package:conmoney/core/budget_plan.dart';
import 'package:conmoney/core/models.dart';
import 'package:conmoney/core/proactive.dart';
import 'package:conmoney/data/csv_import.dart';
import 'package:conmoney/data/database.dart';
import 'package:conmoney/data/ledger_repository.dart';
import 'package:conmoney/data/recurring_repository.dart';
import 'package:conmoney/services/proactive_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeNotifier implements AlertNotifier {
  final shown = <ProactiveAlert>[];

  @override
  Future<void> show(ProactiveAlert alert) async => shown.add(alert);
}

ImportRow row(String merchant, DateTime date, int amount) => ImportRow(
  date: date,
  time: '',
  card: '현대 ZERO',
  merchant: merchant,
  merchantRaw: merchant,
  amount: amount,
  installmentMonths: 1,
  isForeign: false,
  currency: 'KRW',
  originalAmount: '',
  cancelled: false,
  category: '',
  isUnusual: false,
  source: 'test',
);

void main() {
  late AppDatabase db;
  late FakeNotifier notifier;
  var now = DateTime(2026, 10, 13, 9);

  ProactiveService service() => ProactiveService(db, notifier, () => now);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    notifier = FakeNotifier();
    now = DateTime(2026, 10, 13, 9);
    await LedgerRepository(db).saveBudgets(
      const YearMonth(2026, 10),
      [const MonthlyBudget(YearMonth(2026, 10), 1000000, BudgetSource.fixed)],
      setting: BudgetPlansCompanion.insert(
        mode: 'FIXED',
        startMonth: '2026-10',
        startAmount: 1000000,
        targetAmount: 1000000,
        months: 1,
      ),
    );
    await RecurringRepository(db).add(name: '통신비', amount: 65000, dueDay: 15, isEstimate: false);
  });
  tearDown(() => db.close());

  test('아침 검사는 하루 한 번, 보낸 알림은 기록된다', () async {
    final a = await service().check(AlertTrigger.morning);
    expect(a?.title, '모레 통신비 65,000원이 나가요');
    expect(notifier.shown, hasLength(1));

    now = DateTime(2026, 10, 13, 10);
    expect(await service().check(AlertTrigger.morning), isNull);
    final logs = await db.select(db.notificationLogs).get();
    expect(logs.map((l) => l.type), containsAll(['MORNING_CHECKED', 'BIG_FIXED_SOON']));
  });

  test('N3 아침에 보냈으면 같은 날 결제 직후 초과 알림은 보내지 않는다(하루 1회)', () async {
    await service().check(AlertTrigger.morning);
    await importTransactions(db, [row('큰 결제', DateTime(2026, 10, 13), 900000)]);
    now = DateTime(2026, 10, 13, 15);
    expect(await service().check(AlertTrigger.afterTransaction), isNull);
    expect(notifier.shown, hasLength(1));
  });

  test('조용한 시간의 백그라운드 실행은 아침 검사로 치지 않는다', () async {
    now = DateTime(2026, 10, 13, 6);
    expect(await service().check(AlertTrigger.morning), isNull);
    now = DateTime(2026, 10, 13, 8, 30);
    expect(await service().check(AlertTrigger.morning), isNotNull);
  });

  test('끄면 보내지 않고, "지금 검사"는 하루 제한을 무시한다', () async {
    await db.putSetting(ProactiveService.enabledKey, '0');
    expect(await service().check(AlertTrigger.morning), isNull);
    await db.putSetting(ProactiveService.enabledKey, '1');
    await service().check(AlertTrigger.morning);
    expect(await service().check(AlertTrigger.morning, force: true), isNotNull);
    expect(notifier.shown, hasLength(2));
  });
}
