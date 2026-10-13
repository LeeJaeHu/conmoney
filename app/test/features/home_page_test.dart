import 'dart:io';

import 'package:conmoney/app_providers.dart';
import 'package:conmoney/core/budget_plan.dart';
import 'package:conmoney/core/models.dart';
import 'package:conmoney/data/csv_import.dart';
import 'package:conmoney/data/database.dart';
import 'package:conmoney/data/ledger_repository.dart';
import 'package:conmoney/features/home/home_page.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> pumpHome(WidgetTester tester, DateTime now) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db), clockProvider.overrideWithValue(() => now)],
          child: const MaterialApp(home: HomePage()),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();
  }

  testWidgets('예산이 없으면 예산 정하기 안내', (tester) async {
    await pumpHome(tester, DateTime(2026, 10, 2, 12));
    expect(find.text('월 예산을 정하면 오늘 쓸 수 있는 금액을 알려드려요'), findsOneWidget);
  });

  testWidgets('C17 홈: 오늘 초과액, 내일 기준액, 남은 예산, 단계 표시', (tester) async {
    await tester.runAsync(() async {
      final rows = parseTransactionsCsv(File('test/fixtures/sample_transactions.csv').readAsStringSync());
      await importTransactions(db, rows);
      final plan = stepPlan(start: const YearMonth(2026, 10), startAmount: 150000, targetAmount: 100000, months: 2);
      await LedgerRepository(db).saveBudgets(
        const YearMonth(2026, 10),
        plan,
        setting: BudgetPlansCompanion.insert(
          mode: 'STEP',
          startMonth: '2026-10',
          startAmount: 150000,
          targetAmount: 100000,
          months: 2,
        ),
      );
    });

    // 10/2: 13일 전 S = 할부 이월 100,000 + 10/1 교통 1,500, 오늘 12,000
    // R0 = 48,500 → 하루 1,616 − 12,000 = −10,384 → 0원, 오늘 10,384원 초과(표시 10,300원)
    await pumpHome(tester, DateTime(2026, 10, 2, 12));

    expect(find.text('0원'), findsOneWidget);
    expect(find.text('오늘 10,300원 넘었어요 · 내일부터 하루 1,200원'), findsOneWidget);
    expect(find.text('이번 달 남은 예산 36,500원'), findsOneWidget);
    expect(find.text('남은 30일'), findsOneWidget);
    expect(find.text('10월 목표 15만 원 · 1/2단계 (최종 10만 원)'), findsOneWidget);
    expect(find.textContaining('총'), findsNothing); // 총 사용액은 홈에 없음
  });
}
