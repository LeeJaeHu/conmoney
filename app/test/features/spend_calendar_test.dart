import 'dart:io';

import 'package:conmoney/app_providers.dart';
import 'package:conmoney/data/csv_import.dart';
import 'package:conmoney/data/database.dart';
import 'package:conmoney/features/home/spend_calendar.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('홈 달력: 폰 폭(360)에서 넘치지 않고, 날짜를 누르면 그날 지출, 이전 달로 이동', (tester) async {
    // 360×780dp, 아래 내비게이션 바 48dp
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    tester.view.viewPadding = const FakeViewPadding(bottom: 144);
    addTearDown(tester.view.reset);

    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await tester.runAsync(
      () async => importTransactions(
        db,
        parseTransactionsCsv(File('test/fixtures/sample_transactions.csv').readAsStringSync()),
      ),
    );
    Future<void> settle() async {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
      await tester.pumpAndSettle();
    }

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(() => DateTime(2026, 10, 14, 12)),
        ],
        child: MaterialApp(
          home: Scaffold(body: ListView(children: const [SpendCalendar(upcomingDays: {20})])),
        ),
      ),
    );
    await settle();
    expect(find.text('2026년 10월'), findsOneWidget);
    expect(find.text('정기·예정 지출이 남은 날'), findsOneWidget);
    expect(tester.takeException(), isNull); // RenderFlex overflow 등

    await tester.tap(find.bySemanticsLabel(RegExp(r'^2일 ')));
    await settle();
    expect(find.textContaining('10월 2일 ·'), findsOneWidget);
    Navigator.of(tester.element(find.textContaining('10월 2일 ·'))).pop();
    await settle();

    await tester.tap(find.byTooltip('이전 달'));
    await settle();
    expect(find.text('2026년 9월'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
