import 'package:csv/csv.dart';
import 'package:drift/drift.dart';

import '../core/installments.dart';
import '../core/models.dart';
import 'database.dart';

/// `tools/import_statements.py`가 만든 CSV 1행(Spec 3.7 개발자용 가져오기).
class ImportRow {
  ImportRow({
    required this.date,
    required this.time,
    required this.card,
    required this.merchant,
    required this.merchantRaw,
    required this.amount,
    required this.installmentMonths,
    required this.isForeign,
    required this.currency,
    required this.originalAmount,
    required this.cancelled,
    required this.category,
    required this.isUnusual,
    required this.source,
  });

  final DateTime date;
  final String time;
  final String card;
  final String merchant;
  final String merchantRaw;
  final int amount;
  final int installmentMonths;
  final bool isForeign;
  final String currency;
  final String originalAmount;
  final bool cancelled;

  /// 검수 라벨(category)이 있으면 그것, 없으면 규칙 추정값(category_guess).
  final String category;
  final bool isUnusual;
  final String source;

  DateTime get approvedAt {
    final m = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(time);
    if (m == null) return date;
    return DateTime(date.year, date.month, date.day, int.parse(m[1]!), int.parse(m[2]!));
  }
}

bool _bool(Object? v) => v.toString().trim().toUpperCase() == 'TRUE';

/// CSV 문자열을 행으로 바꾼다. 머리글 이름으로 열을 찾으므로 열 순서가 바뀌어도 된다.
List<ImportRow> parseTransactionsCsv(String content) {
  final text = content.startsWith('﻿') ? content.substring(1) : content;
  final rows = Csv(autoDetect: false).decode(text).where((r) => r.any((c) => '$c'.isNotEmpty)).toList();
  if (rows.isEmpty) return const [];
  final header = [for (final h in rows.first) '$h'.trim()];
  int col(String name) => header.indexOf(name);
  String get(List<dynamic> r, String name) {
    final i = col(name);
    return i < 0 || i >= r.length ? '' : '${r[i]}'.trim();
  }

  return [
    for (final r in rows.skip(1))
      ImportRow(
        date: DateTime.parse(get(r, 'date')),
        time: get(r, 'time'),
        card: get(r, 'card'),
        merchant: get(r, 'merchant'),
        merchantRaw: get(r, 'merchant_raw'),
        amount: int.parse(get(r, 'amount')),
        installmentMonths: int.tryParse(get(r, 'installment_months')) ?? 1,
        isForeign: _bool(get(r, 'is_foreign')),
        currency: get(r, 'currency').isEmpty ? 'KRW' : get(r, 'currency'),
        originalAmount: get(r, 'original_amount'),
        cancelled: _bool(get(r, 'cancelled')),
        category: get(r, 'category').isNotEmpty ? get(r, 'category') : get(r, 'category_guess'),
        isUnusual: _bool(get(r, 'is_unusual')),
        source: get(r, 'source'),
      ),
  ];
}

/// CSV의 카드 이름 → 카드사·상품명·알림 출처(Spec F1).
({String issuer, String product, String? source, bool active}) cardInfo(String card) {
  final first = card.split(' ').first;
  return switch (first) {
    '현대' => (issuer: 'HYUNDAI', product: '현대카드 ZERO', source: 'HYUNDAI_APP', active: true),
    '롯데' => (issuer: 'LOTTE', product: '롯데카드 LOCA LIKIT Eat', source: 'KAKAO_LOTTE', active: true),
    '토스뱅크' => (issuer: 'TOSS', product: '토스뱅크카드', source: 'TOSS_APP', active: true),
    // 신한은 앞으로 쓰지 않음: 과거 기록만 가져오고 알림 대상에서 제외(10/13 결정)
    '신한' => (issuer: 'SHINHAN', product: '신한카드', source: null, active: false),
    _ => (issuer: 'OTHER', product: card, source: null, active: false),
  };
}

class ImportResult {
  const ImportResult(this.inserted, this.skipped, this.firstDate);

  final int inserted;

  /// 이미 가져온 거래(같은 중복 키)라 건너뛴 수.
  final int skipped;
  final DateTime? firstDate;
}

/// 가져온 거래를 DB에 넣는다. 같은 파일을 다시 가져와도 중복되지 않는다.
/// 과거 기록이므로 모두 확인된 거래로 넣는다(확인 알림을 보내지 않음).
Future<ImportResult> importTransactions(AppDatabase db, List<ImportRow> rows) {
  return db.transaction(() async {
    final cardIds = <String, int>{};
    final categoryIds = {for (final c in await db.select(db.categories).get()) c.name: c.id};
    final seen = <String, int>{};
    // INSERT OR IGNORE는 무시돼도 이전 rowid를 돌려주므로 기존 키를 먼저 읽어 둔다
    final existing = {
      for (final k in await (db.selectOnly(db.transactions)..addColumns([db.transactions.dedupeKey])).get())
        k.read(db.transactions.dedupeKey)!,
    };
    var inserted = 0;
    DateTime? first;

    Future<int> cardIdFor(String card) async {
      final info = cardInfo(card);
      if (cardIds[info.product] case final id?) return id;
      final existing = await (db.select(db.cards)..where((c) => c.productName.equals(info.product))).getSingleOrNull();
      final id = existing?.id ??
          await db.into(db.cards).insert(CardsCompanion.insert(
                issuer: info.issuer,
                productName: info.product,
                source: Value(info.source),
                active: Value(info.active),
              ));
      return cardIds[info.product] = id;
    }

    Future<int?> categoryIdFor(String name) async {
      if (name.isEmpty) return null;
      return categoryIds[name] ??= await db.into(db.categories).insert(
            CategoriesCompanion.insert(name: name, sortOrder: Value(categoryIds.length)),
          );
    }

    for (final r in rows) {
      final base = 'IMPORT|${_ymd(r.date)}|${r.card}|${r.merchantRaw}|${r.amount}';
      final n = seen[base] = (seen[base] ?? 0) + 1;
      if (existing.contains('$base|$n')) continue;
      final categoryId = await categoryIdFor(r.category);
      final id = await db.into(db.transactions).insert(
            TransactionsCompanion.insert(
              cardId: Value(await cardIdFor(r.card)),
              kind: r.amount < 0 ? 'CANCEL' : 'APPROVAL',
              amount: r.amount,
              currency: Value(r.currency),
              originalAmount: Value(r.originalAmount.isEmpty ? null : r.originalAmount),
              merchantRaw: r.merchantRaw,
              merchantNorm: r.merchant,
              approvedAt: r.approvedAt,
              localDate: _ymd(r.date),
              installmentMonths: Value(r.installmentMonths),
              isForeign: Value(r.isForeign),
              status: Value(r.cancelled ? 'CANCELLED' : 'ACTIVE'),
              categoryId: Value(categoryId),
              suggestedCategoryId: Value(categoryId),
              suggestSource: const Value('IMPORT'),
              isUnusual: Value(r.isUnusual),
              confirmed: const Value(true),
              sourcePackage: Value('IMPORT:${r.source}'),
              dedupeKey: '$base|$n',
            ),
          );
      inserted++;
      if (first == null || r.date.isBefore(first)) first = r.date;

      if (r.installmentMonths > 1) {
        final txn = Txn(id: id, amount: r.amount, date: r.date, installmentMonths: r.installmentMonths);
        await db.batch((b) => b.insertAll(db.installmentSchedules, [
              for (final row in buildSchedule(txn))
                InstallmentSchedulesCompanion.insert(
                  transactionId: id,
                  seq: row.seq,
                  month: row.month.toString(),
                  amount: row.amount,
                ),
            ]));
      }
    }

    if (first != null) {
      final saved = await db.setting('first_record_date');
      if (saved == null || first.isBefore(DateTime.parse(saved))) {
        await db.putSetting('first_record_date', _ymd(first));
      }
    }
    return ImportResult(inserted, rows.length - inserted, first);
  });
}

String _ymd(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
