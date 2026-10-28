import 'package:drift/drift.dart';

import '../core/installments.dart';
import '../core/merchant_rules.dart';
import '../core/models.dart';
import '../core/payment_parser.dart';
import 'database.dart';
import 'recurring_repository.dart';
import 'spending_repository.dart';

/// 리스너가 저장한 알림 원문 1건(네이티브 raw_notifications 행). 플랫폼 채널과 떨어뜨려 테스트할 수 있게 둔다.
class RawPaymentNotification {
  const RawPaymentNotification({
    required this.id,
    required this.packageName,
    required this.title,
    required this.body,
    required this.postedAt,
  });

  final int id;
  final String packageName;
  final String? title;
  final String body;
  final DateTime postedAt;
}

class IngestResult {
  IngestResult();

  int saved = 0;
  int duplicates = 0;
  int cancels = 0;
  int failed = 0;
  int ignored = 0;
  int unsupported = 0;

  /// 새로 저장한 승인 거래(결제 직후 먼저 알려주기 검사에 쓴다).
  final List<int> newApprovals = [];

  bool get changed => saved + cancels + failed > 0;
}

/// 결제 알림 → 거래(Spec F2 처리 순서 3~5). 같은 원문을 다시 넣어도 한 번만 처리한다.
class NotificationIngestor {
  NotificationIngestor(this.db);

  final AppDatabase db;

  Future<IngestResult> ingest(List<RawPaymentNotification> raws) async {
    final result = IngestResult();
    final previous = await db.select(db.notificationResults).get();
    // 파서가 없던 출처(UNSUPPORTED)와 못 읽은 결제(PARSE_FAIL)는 파서가 고쳐졌을 수 있어 매번 다시 본다(10/28)
    final done = {
      for (final r in previous)
        if (r.result != 'UNSUPPORTED' && r.result != 'PARSE_FAIL') r.rawId,
    };
    final failedBefore = {
      for (final r in previous)
        if (r.result == 'PARSE_FAIL') r.rawId: r.transactionId,
    };
    for (final raw in raws) {
      if (done.contains(raw.id)) continue;
      await db.transaction(() => _one(raw, result, failedTxnId: failedBefore[raw.id], failedBefore: failedBefore.containsKey(raw.id)));
    }
    if (result.changed) await RecurringRepository(db).relink();
    return result;
  }

  Future<void> _one(RawPaymentNotification raw, IngestResult out, {int? failedTxnId, bool failedBefore = false}) async {
    Future<void> record(String r, [int? txnId]) => db
        .into(db.notificationResults)
        .insertOnConflictUpdate(
          NotificationResultsCompanion.insert(
            rawId: Value(raw.id),
            result: r,
            transactionId: Value(txnId),
            processedAt: DateTime.now(),
          ),
        );

    final source = PaymentSource.of(raw.packageName, raw.title);
    if (source == null) {
      out.ignored++;
      return record('IGNORED');
    }
    final outcome = parsePaymentNotification(source: source, title: raw.title, body: raw.body, postedAt: raw.postedAt);
    if (failedBefore) {
      // 여전히 못 읽으면 이미 남긴 확인 필요 거래(0원)를 그대로 두고 아무것도 하지 않는다
      if (outcome is ParseFailed) return;
      // 이제 읽히면 그때 남긴 0원 자리 거래를 지우고 아래에서 정상 처리한다
      if (failedTxnId != null) {
        await (db.delete(db.transactions)..where((t) => t.id.equals(failedTxnId) & t.amount.equals(0))).go();
      }
    }
    switch (outcome) {
      case NotPayment():
        out.ignored++;
        return record('IGNORED');
      case Unsupported():
        out.unsupported++;
        return record('UNSUPPORTED');
      case ParseFailed(:final reason):
        out.failed++;
        return record('PARSE_FAIL', await _saveFailure(raw, source, reason));
      case Parsed(:final payment):
        final cardId = await _cardId(source);
        if (await _isDuplicate(payment, cardId)) {
          out.duplicates++;
          return record('DUP');
        }
        if (payment.isCancel) {
          out.cancels++;
          return record('CANCEL', await _saveCancel(raw, payment, cardId));
        }
        final id = await _saveApproval(raw, payment, cardId);
        out.saved++;
        out.newApprovals.add(id);
        return record('SAVED', id);
    }
  }

  Future<int> _cardId(PaymentSource source) async {
    final existing = await (db.select(db.cards)..where((c) => c.source.equals(source.key))).get();
    if (existing.isNotEmpty) return existing.first.id;
    return db
        .into(db.cards)
        .insert(
          CardsCompanion.insert(
            issuer: switch (source) {
              PaymentSource.lotteKakao => 'LOTTE',
              PaymentSource.hyundaiApp => 'HYUNDAI',
              PaymentSource.tossApp => 'TOSS',
            },
            productName: source.product,
            source: Value(source.key),
          ),
        );
  }

  static String _key(ParsedPayment p) =>
      'NOTIF|${p.source.key}|${p.approvedAt.toIso8601String()}|${p.amount}|${p.merchant}|${p.isCancel ? 'C' : 'A'}';

  /// 같은 알림이 다시 온 것, 또는 카드사 내역 파일로 이미 가져온 결제(Spec 4.3).
  /// 가져온 기록은 시각이 없는 경우가 많아 같은 카드·날짜·금액·가맹점으로 비교한다.
  Future<bool> _isDuplicate(ParsedPayment p, int cardId) async {
    final key = _key(p);
    final same = await (db.select(db.transactions)..where((t) => t.dedupeKey.equals(key))).getSingleOrNull();
    if (same != null) return true;
    final amount = p.isCancel ? -p.amount : p.amount;
    final candidates =
        await (db.select(db.transactions)..where(
              (t) =>
                  t.cardId.equals(cardId) &
                  t.localDate.equals(_ymd(p.approvedAt)) &
                  t.amount.equals(amount) &
                  t.sourcePackage.like('IMPORT:%'),
            ))
            .get();
    return candidates.any((t) => _sameMerchant(t, p.merchant));
  }

  /// 롯데 내역 파일은 가맹점 뒤에 "_법인명"이 붙고, 알림에는 없다.
  static bool _sameMerchant(TransactionRow t, String merchant) =>
      t.merchantRaw == merchant ||
      t.merchantRaw.startsWith('${merchant}_') ||
      t.merchantNorm == normMerchant(merchant) ||
      (merchant.length >= 6 && t.merchantRaw.startsWith(merchant.substring(0, 6)));

  Future<int> _saveApproval(RawPaymentNotification raw, ParsedPayment p, int cardId) async {
    final norm = normMerchant(p.merchant);
    final (categoryId, source) = await _suggest(p.merchant, norm, p.amount);
    final foreignWithoutWon = p.isForeign && p.amount == 0;
    final id = await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            cardId: Value(cardId),
            kind: 'APPROVAL',
            amount: p.amount,
            currency: Value(p.foreignAmount?.split(' ').first ?? 'KRW'),
            originalAmount: Value(p.foreignAmount),
            merchantRaw: p.merchant,
            merchantNorm: norm,
            approvedAt: p.approvedAt,
            localDate: _ymd(p.approvedAt),
            installmentMonths: Value(p.installmentMonths),
            isForeign: Value(p.isForeign),
            suggestedCategoryId: Value(categoryId),
            suggestSource: Value(source),
            // 해외 결제에 원화 금액이 없으면 확인 시트에서 입력받는다(Spec F2)
            needsReview: Value(foreignWithoutWon),
            reviewReason: Value(foreignWithoutWon ? 'FOREIGN_AMOUNT' : null),
            rawText: Value(raw.body),
            sourcePackage: Value(raw.packageName),
            dedupeKey: _key(p),
          ),
        );
    if (p.installmentMonths > 1) {
      final txn = Txn(id: id, amount: p.amount, date: p.approvedAt, installmentMonths: p.installmentMonths);
      await db.batch(
        (b) => b.insertAll(db.installmentSchedules, [
          for (final row in buildSchedule(txn))
            InstallmentSchedulesCompanion.insert(
              transactionId: id,
              seq: row.seq,
              month: row.month.toString(),
              amount: row.amount,
            ),
        ]),
      );
    }
    return id;
  }

  /// 카테고리 추천(Spec F3): 내 규칙 → 내장 규칙 → 같은 가맹점의 과거 확정 거래. LLM 추천은 아직 연결 안 함.
  Future<(int?, String)> _suggest(String merchant, String norm, int amount) async {
    final rule = await (db.select(db.merchantRules)..where((r) => r.merchantNorm.equals(norm))).getSingleOrNull();
    if (rule != null) return (rule.categoryId, 'USER_RULE');
    final cats = {for (final c in await db.select(db.categories).get()) c.name: c.id};
    if (!ambiguousMerchants.contains(norm)) {
      if (builtinCategory(norm, amount) case final name? when cats[name] != null) return (cats[name], 'BUILTIN_RULE');
    }
    final past = await (db.select(db.transactions)..where((t) => t.confirmed.equals(true) & t.categoryId.isNotNull())).get();
    final counts = <int, int>{};
    for (final t in past) {
      if (_sameMerchant(t, merchant)) counts[t.categoryId!] = (counts[t.categoryId!] ?? 0) + 1;
    }
    if (counts.isNotEmpty) {
      final best = counts.entries.reduce((a, b) => a.value >= b.value ? a : b);
      return (best.key, 'HISTORY');
    }
    return (null, 'NONE');
  }

  /// 취소(Spec 4.4): 원거래를 찾아 같은 달이면 원거래를 취소 처리, 이전 달이면 이번 달에 음수로 반영.
  Future<int> _saveCancel(RawPaymentNotification raw, ParsedPayment p, int cardId) async {
    final since = _ymd(p.approvedAt.subtract(const Duration(days: 90)));
    final candidates =
        await (db.select(db.transactions)
              ..where(
                (t) =>
                    t.cardId.equals(cardId) &
                    t.kind.equals('APPROVAL') &
                    t.status.equals('ACTIVE') &
                    t.amount.equals(p.amount) &
                    t.localDate.isBiggerOrEqualValue(since),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.approvedAt)]))
            .get();
    final original = candidates.where((t) => _sameMerchant(t, p.merchant)).firstOrNull;
    final month = YearMonth.of(p.approvedAt);
    final sameMonth = original != null && YearMonth.of(DateTime.parse(original.localDate)) == month;
    var amount = -p.amount;

    if (original != null) {
      final schedules = await (db.select(db.installmentSchedules)..where((s) => s.transactionId.equals(original.id))).get();
      if (sameMonth) {
        await (db.update(db.transactions)..where((t) => t.id.equals(original.id))).write(
          const TransactionsCompanion(status: Value('CANCELLED')),
        );
        await (db.update(db.installmentSchedules)..where((s) => s.transactionId.equals(original.id))).write(
          const InstallmentSchedulesCompanion(voided: Value(true)),
        );
      } else if (schedules.isNotEmpty) {
        // 할부: 이번 달 이후 회차만 무효로 하고, 그만큼만 이번 달에 빼 준다 [가정]
        final remaining = schedules.where((s) => !s.voided && YearMonth.parse(s.month).compareTo(month) >= 0);
        amount = -remaining.fold(0, (sum, s) => sum + s.amount);
        for (final s in remaining) {
          await (db.update(db.installmentSchedules)..where((x) => x.id.equals(s.id))).write(
            const InstallmentSchedulesCompanion(voided: Value(true)),
          );
        }
      }
    }

    return db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            cardId: Value(cardId),
            kind: 'CANCEL',
            amount: amount,
            merchantRaw: p.merchant,
            merchantNorm: normMerchant(p.merchant),
            approvedAt: p.approvedAt,
            localDate: _ymd(p.approvedAt),
            cancelOfId: Value(original?.id),
            categoryId: Value(original?.categoryId),
            // 같은 달 취소는 원거래가 빠지므로 이 행은 합계에서 뺀다
            excludedFromSums: Value(sameMonth),
            confirmed: Value(original != null),
            needsReview: Value(original == null),
            reviewReason: Value(original == null ? 'CANCEL_UNMATCHED' : null),
            rawText: Value(raw.body),
            sourcePackage: Value(raw.packageName),
            dedupeKey: _key(p),
          ),
        );
  }

  /// 결제 같은데 해석 못 한 알림: 금액 0, 확인 필요로 남긴다(조용히 버리지 않음).
  Future<int> _saveFailure(RawPaymentNotification raw, PaymentSource source, String reason) async {
    final firstLine = raw.body.split('\n').firstWhere((l) => l.trim().isNotEmpty, orElse: () => raw.title ?? '알 수 없음');
    return db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            cardId: Value(await _cardId(source)),
            kind: 'APPROVAL',
            amount: 0,
            merchantRaw: firstLine.trim(),
            merchantNorm: firstLine.trim(),
            approvedAt: raw.postedAt,
            localDate: _ymd(raw.postedAt),
            needsReview: const Value(true),
            reviewReason: Value('PARSE_FAIL: $reason'),
            rawText: Value(raw.body),
            sourcePackage: Value(raw.packageName),
            dedupeKey: 'NOTIF_FAIL|${raw.id}',
          ),
        );
  }
}

String _ymd(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
