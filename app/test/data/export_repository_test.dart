import 'dart:io';

import 'package:conmoney/data/database.dart';
import 'package:conmoney/data/export_repository.dart';
import 'package:csv/csv.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('conmoney_export');
    db = AppDatabase(NativeDatabase.memory());
    final card = await db.into(db.cards).insert(CardsCompanion.insert(issuer: 'LOTTE', productName: '롯데카드 LOCA LIKIT Eat'));
    final food = (await db.select(db.categories).get()).firstWhere((c) => c.name == '식비').id;
    await db.into(db.transactions).insert(TransactionsCompanion.insert(
      cardId: Value(card),
      kind: 'APPROVAL',
      amount: 9300,
      merchantRaw: '버거킹 강남역점',
      merchantNorm: '버거킹 강남역점',
      approvedAt: DateTime(2026, 10, 17, 12, 34),
      localDate: '2026-10-17',
      categoryId: Value(food),
      memo: const Value('점심, "세트"'),
      rawText: const Value('알림 원문'),
      sourcePackage: const Value('com.kakao.talk'),
      dedupeKey: 'k1',
    ));
    await db.into(db.transactions).insert(TransactionsCompanion.insert(
      kind: 'APPROVAL',
      amount: 0,
      currency: const Value('USD'),
      originalAmount: const Value('USD 5.00'),
      merchantRaw: 'ACME AI',
      merchantNorm: 'ACME AI',
      approvedAt: DateTime(2026, 10, 31, 13, 9),
      localDate: '2026-10-31',
      isForeign: const Value(true),
      sourcePackage: const Value('IMPORT:lotte.xls'),
      dedupeKey: 'k2',
    ));
  });
  tearDown(() async {
    await db.close();
    await tmp.delete(recursive: true);
  });

  test('거래 CSV: 한 건 한 줄, 카드·카테고리 이름, 쉼표·따옴표 메모, 알림 원문은 없음', () async {
    final csv = await ExportRepository(db).transactionsCsv();
    final rows = Csv(autoDetect: false).decode(csv);
    expect(rows, hasLength(3));
    final h = rows.first.map((c) => '$c').toList();
    Map<String, String> row(int i) => {for (var j = 0; j < h.length; j++) h[j]: '${rows[i][j]}'};
    expect(row(1)['approved_at'], '2026-10-17 12:34:00');
    expect(row(1)['card'], '롯데카드 LOCA LIKIT Eat');
    expect(row(1)['category'], '식비');
    expect(row(1)['memo'], '점심, "세트"');
    expect(row(1)['source'], 'NOTIFICATION');
    expect(row(2)['original_amount'], 'USD 5.00');
    expect(row(2)['is_foreign'], '1');
    expect(row(2)['source'], 'IMPORT');
    expect(h, isNot(contains('raw_text')));
    expect(csv, isNot(contains('알림 원문')));
  });

  test('SQLite 사본: 다른 도구로 열어 SQL로 조회할 수 있고, 임시 파일은 지운다', () async {
    final bytes = await ExportRepository(db).sqliteSnapshot(tmp);
    expect(tmp.listSync(), isEmpty);
    final out = File('${tmp.path}/out.sqlite')..writeAsBytesSync(bytes);
    final copy = AppDatabase(NativeDatabase(out));
    final r = await copy.customSelect('SELECT COUNT(*) AS n, SUM(amount) AS s FROM transactions').getSingle();
    expect(r.read<int>('n'), 2);
    expect(r.read<int>('s'), 9300);
    await copy.close();
  });
}
