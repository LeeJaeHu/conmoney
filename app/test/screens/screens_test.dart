import 'dart:io';

import 'package:conmoney/app_providers.dart';
import 'package:conmoney/data/csv_import.dart';
import 'package:conmoney/data/database.dart';
import 'package:conmoney/data/recurring_repository.dart';
import 'package:conmoney/features/home/home_page.dart';
import 'package:conmoney/features/spending/category_page.dart';
import 'package:conmoney/ui/theme.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> loadFonts() async {
  ByteData bytes(String path) => ByteData.sublistView(File(path).readAsBytesSync());
  final f = FontLoader(appFont);
  for (final w in ['Regular', 'SemiBold', 'Bold']) {
    f.addFont(Future.value(bytes('assets/fonts/Pretendard-$w.otf')));
  }
  await f.load();
  await (FontLoader('MaterialIcons')
        ..addFont(Future.value(bytes('${Platform.environment['FLUTTER_ROOT'] ?? 'C:/flutter'}/bin/cache/artifacts/material_fonts/materialicons-regular.otf'))))
      .load();
}

ThemeData themed(Brightness b) => buildTheme(b, fontFamily: appFont);

/// 화면 캡처(10/16): 가짜 데이터로 홈·지출 분석을 360dp 폰 크기로 그려 docs/design/에 PNG로 남긴다.
/// 글꼴은 앱과 같은 Pretendard(assets/fonts). 평소 테스트에서는 건너뛴다. 캡처할 때:
///   SCREENSHOTS=1 flutter test test/screens --update-goldens
void main() {
  final skip = Platform.environment['SCREENSHOTS'] != '1';
  for (final b in Brightness.values) {
    for (final page in ['home', 'analysis']) {
      testWidgets('$page $b', skip: skip, (tester) async {
        await tester.runAsync(loadFonts);
        tester.view.physicalSize = const Size(1080, 2340);
        tester.view.devicePixelRatio = 3;
        tester.view.viewPadding = const FakeViewPadding(top: 72, bottom: 144);
        addTearDown(tester.view.reset);
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        await tester.runAsync(() async {
          await importTransactions(db, parseTransactionsCsv(File('test/fixtures/sample_transactions.csv').readAsStringSync()));
          await db.into(db.budgets).insert(BudgetsCompanion.insert(month: '2026-10', amount: 300000, source: 'FIXED'));
          await RecurringRepository(db).add(name: '통신비', amount: 40000, dueDay: 20, isEstimate: false);
        });
        await tester.pumpWidget(ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db), clockProvider.overrideWithValue(() => DateTime(2026, 10, 14, 12))],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: themed(Brightness.light),
            darkTheme: themed(Brightness.dark),
            themeMode: b == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
            home: page == 'home' ? const HomePage() : const CategoryPage(),
          ),
        ));
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));
        await tester.pumpAndSettle();
        await expectLater(find.byType(MaterialApp), matchesGoldenFile('../../../docs/design/${page}_${b.name}.png'));
      });
    }
  }
}
