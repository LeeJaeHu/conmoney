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
  testWidgets('지출 분석(10/16): 이번 달 흐름·평소 대비 그래프가 360dp 폭에서 넘치지 않고, 맨 아래가 내비게이션 바 위에서 끝난다', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    tester.view.viewPadding = const FakeViewPadding(bottom: 144); // 48dp 내비게이션 바
    addTearDown(tester.view.reset);

    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await tester.runAsync(() async {
      await importTransactions(
        db,
        parseTransactionsCsv(File('test/fixtures/sample_transactions.csv').readAsStringSync()),
      );
      await db.into(db.budgets).insert(BudgetsCompanion.insert(month: '2026-10', amount: 300000, source: 'FIXED'));
    });
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
    expect(find.text('이번 달 흐름'), findsOneWidget);
    expect(find.textContaining('평소대로 쓰면 월말 약'), findsOneWidget);

    final list = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(find.text('이번 달, 평소와 비교'), 300, scrollable: list);
    await settle();
    expect(find.textContaining('특이 지출 제외 · 평소 ='), findsOneWidget);

    // 맨 아래까지 내리면 마지막 내용(6개월 그래프 월 라벨)이 내비게이션 바(아래 48dp) 위에 있어야 한다
    await tester.drag(list, const Offset(0, -5000));
    await settle();
    final last = tester.getRect(find.text('10월').last);
    expect(last.bottom, lessThanOrEqualTo(780 - 48));

    await tester.drag(list, const Offset(0, 5000));
    await settle();
    await tester.tap(find.widgetWithText(ChoiceChip, '지난달'));
    await settle();
    expect(find.text('이번 달 흐름'), findsNothing);
    await tester.scrollUntilVisible(find.text('지난달, 평소와 비교'), 300, scrollable: list);
    expect(tester.takeException(), isNull);
  });
}
