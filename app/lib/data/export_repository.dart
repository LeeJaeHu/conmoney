import 'dart:io';

import 'package:csv/csv.dart';
import 'package:drift/drift.dart';

import 'database.dart';

/// 내 기록을 PC로 옮겨 SQL로 분석하려고 내보낸다(11/2 사용자 요청). 실제 결제 내역이므로
/// 받은 파일은 git·외부 서비스에 올리지 않는다(CLAUDE.md 데이터 규칙).
class ExportRepository {
  ExportRepository(this.db);

  final AppDatabase db;

  /// DB 전체를 SQLite 파일 하나로. 쓰는 중인 DB를 그대로 복사하지 않고 `VACUUM INTO`로 일관된 사본을 만든다.
  /// 날짜·시각 열은 drift 기본값대로 유닉스 초(정수)로 들어 있다.
  Future<Uint8List> sqliteSnapshot(Directory tempDir) async {
    final file = File('${tempDir.path}/conmoney_export_${DateTime.now().millisecondsSinceEpoch}.sqlite');
    try {
      await db.customStatement('VACUUM INTO ?', [file.path]);
      return await file.readAsBytes();
    } finally {
      if (await file.exists()) await file.delete();
    }
  }

  /// 거래 한 건이 한 줄인 CSV. 카드·카테고리는 이름으로 풀어 두고, 알림 원문(raw_text)은 뺀다.
  Future<String> transactionsCsv() async {
    final cards = {for (final c in await db.select(db.cards).get()) c.id: c};
    final cats = {for (final c in await db.select(db.categories).get()) c.id: c.name};
    final txns = await (db.select(db.transactions)
          ..orderBy([(t) => OrderingTerm.asc(t.approvedAt), (t) => OrderingTerm.asc(t.id)]))
        .get();
    String two(int v) => v.toString().padLeft(2, '0');
    String dt(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}:${two(d.second)}';
    return Csv().encode([
      [
        'id', 'local_date', 'approved_at', 'issuer', 'card', 'kind', 'amount', 'currency', 'original_amount', //
        'merchant', 'merchant_raw', 'category', 'suggested_category', 'suggest_source', 'installment_months',
        'is_foreign', 'is_unusual', 'status', 'excluded_from_sums', 'cancel_of_id', 'confirmed', 'needs_review',
        'review_reason', 'memo', 'source',
      ],
      for (final t in txns)
        [
          t.id, t.localDate, dt(t.approvedAt), cards[t.cardId]?.issuer ?? '', cards[t.cardId]?.productName ?? '', //
          t.kind, t.amount, t.currency, t.originalAmount ?? '', t.merchantNorm, t.merchantRaw,
          cats[t.categoryId] ?? '', cats[t.suggestedCategoryId] ?? '', t.suggestSource ?? '', t.installmentMonths,
          t.isForeign ? 1 : 0, t.isUnusual ? 1 : 0, t.status, t.excludedFromSums ? 1 : 0, t.cancelOfId ?? '',
          t.confirmed ? 1 : 0, t.needsReview ? 1 : 0, t.reviewReason ?? '', t.memo ?? '',
          // 가져오기는 IMPORT:파일명, 알림은 패키지명 → 출처만 남긴다
          switch (t.sourcePackage) {
            final s? when s.startsWith('IMPORT:') => 'IMPORT',
            null => t.kind == 'MANUAL' ? 'MANUAL' : '',
            _ => 'NOTIFICATION',
          },
        ],
    ]);
  }
}
