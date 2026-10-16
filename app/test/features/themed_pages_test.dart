import 'package:conmoney/app_providers.dart';
import 'package:conmoney/core/proactive.dart';
import 'package:conmoney/data/csv_import.dart';
import 'package:conmoney/data/database.dart';
import 'package:conmoney/data/planned_repository.dart';
import 'package:conmoney/features/planned/planned_page.dart';
import 'package:conmoney/features/recurring/recurring_page.dart';
import 'package:conmoney/features/settings/notification_settings_page.dart';
import 'package:conmoney/services/proactive_service.dart';
import 'package:conmoney/ui/theme.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _SilentNotifier implements AlertNotifier {
  @override
  Future<void> show(ProactiveAlert alert) async {}
}

ImportRow _row(String merchant, DateTime date, int amount) => ImportRow(
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

/// 10/17 회귀: 앱 테마(버튼 최소 너비)를 입힌 상태에서 trailing·Row 안 버튼이 있는 화면이
/// 레이아웃 오류 없이 그려지는지. 테마 없이 그리던 기존 테스트는 이 오류를 못 잡았다.
void main() {
  final now = DateTime(2026, 10, 13, 12);
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> pumpPage(WidgetTester tester, Widget page) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db), clockProvider.overrideWithValue(() => now)],
        child: MaterialApp(theme: buildTheme(Brightness.light), home: page),
      ),
    );
    await settle(tester);
  }

  testWidgets('예정 지출: [냈어요] → 확인 → 지출로 기록', (tester) async {
    await tester.runAsync(() => PlannedRepository(db).add(name: '친구 축의금', amount: 100000, date: DateTime(2026, 10, 20)));
    await pumpPage(tester, const PlannedPage());

    expect(tester.takeException(), isNull);
    await tester.tap(find.text('냈어요'));
    await tester.pumpAndSettle();
    expect(find.textContaining('오늘 쓴 돈으로 기록할까요?'), findsOneWidget);

    await tester.tap(find.text('기록'));
    await tester.pump();
    await settle(tester);
    await settle(tester);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, '냈어요'), findsNothing);
    expect(find.text('친구 축의금을(를) 지출로 기록했어요'), findsOneWidget);
    expect(find.textContaining('에 냄'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('예정 지출 추가 창: 키보드가 올라와도 넘치지 않는다', (tester) async {
    await pumpPage(tester, const PlannedPage());
    await tester.tap(find.text('추가'));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 900); // 키보드
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('예정 지출 추가'), findsOneWidget);
  });

  testWidgets('먼저 알려주기 화면이 그려진다', (tester) async {
    await pumpPage(tester, NotificationSettingsPage(notifier: _SilentNotifier()));
    expect(tester.takeException(), isNull);
    expect(find.text('${QuietHours.standard.startHour}시부터'), findsOneWidget);
    expect(find.text('지금 검사해 보기'), findsOneWidget);
  });

  testWidgets('정기 지출(홈 다가오는 지출에서 여는 화면): 제안 버튼이 있어도 그려진다', (tester) async {
    await tester.runAsync(
      () => importTransactions(db, [
        for (final m in [8, 9, 10]) _row('KT 휴대폰', DateTime(2026, m, 12), 38000),
      ]),
    );
    await pumpPage(tester, const RecurringPage());
    expect(tester.takeException(), isNull);
    expect(find.text('등록'), findsOneWidget);
  });
}

Future<void> settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
  await tester.pump();
}
