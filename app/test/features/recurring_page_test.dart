import 'package:conmoney/app_providers.dart';
import 'package:conmoney/data/csv_import.dart';
import 'package:conmoney/data/database.dart';
import 'package:conmoney/features/recurring/recurring_page.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
  testWidgets('제안을 [모두 등록]하면 등록 목록과 이번 달 상태가 보인다', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final now = DateTime(2026, 10, 13, 12);

    Future<void> settle() async {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
      await tester.pump();
    }

    await tester.runAsync(() async {
      await importTransactions(db, [
        for (final m in [8, 9, 10]) row('KT 휴대폰', DateTime(2026, m, 12), 38000),
        for (final m in [8, 9]) row('넷플릭스', DateTime(2026, m, 20), 13500),
      ]);
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db), clockProvider.overrideWithValue(() => now)],
        child: const MaterialApp(home: RecurringPage()),
      ),
    );
    await settle();

    expect(find.text('등록된 정기 지출 0개'), findsOneWidget);
    expect(find.text('매달 나가는 것 같아요'), findsOneWidget);
    expect(find.text('3개월째 매달 12일쯤 · 38,000원'), findsOneWidget);

    await tester.tap(find.text('모두 등록'));
    await settle();
    await settle();

    expect(find.text('등록된 정기 지출 2개'), findsOneWidget);
    expect(find.text('매달 나가는 것 같아요'), findsNothing);
    expect(find.text('결제됨\n38,000원'), findsOneWidget);
    expect(find.text('10/20 예정'), findsOneWidget);
  });
}
