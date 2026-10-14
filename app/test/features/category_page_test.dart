import 'dart:io';

import 'package:conmoney/app_providers.dart';
import 'package:conmoney/data/csv_import.dart';
import 'package:conmoney/data/database.dart';
import 'package:conmoney/features/spending/category_page.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('F8 기간 전환, 특이 지출 토글, 카테고리 상세', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
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
        child: const MaterialApp(home: CategoryPage()),
      ),
    );
    await settle();

    // 10월: 할부 3회차 100,000 + 교통 1,500 + 마켓 12,000
    expect(find.text('총 113,500원'), findsOneWidget);
    expect(find.text('최근 6개월'), findsOneWidget);

    await tester.tap(find.text('지난달'));
    await settle();
    expect(find.text('9/1 ~ 9/30'), findsOneWidget);
    expect(find.text('총 120,500원'), findsOneWidget); // 120,550원 → 100원 단위 내림 표시

    await tester.tap(find.text('특이 지출 포함'));
    await settle();
    expect(find.text('총 20,500원'), findsOneWidget);

    await tester.tap(find.text('특이 지출 포함'));
    await settle();
    await tester.tap(find.text('게임 · 1건'));
    await settle();
    expect(find.text('가짜게임기'), findsOneWidget);
    expect(find.text('할부 2/3 · ★ 특이 지출 · 현대카드 ZERO'), findsOneWidget);
  });
}
