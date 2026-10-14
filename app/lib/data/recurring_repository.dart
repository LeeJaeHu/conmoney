import 'dart:convert';

import 'package:drift/drift.dart';

import '../core/models.dart';
import '../core/recurring.dart';
import 'database.dart';

enum MonthState { paid, skipped, upcoming, overdue, envelope }

/// 정기 지출 1개와 이번 달 상태(정기 지출 화면).
class RecurringView {
  const RecurringView(this.item, this.state, this.due, {this.paidAmount, this.envelopeUsed = 0});

  final RecurringItemRow item;
  final MonthState state;
  final DateTime due;
  final int? paidAmount;

  /// 월 예약형: 이번 달 실제로 쓴 금액.
  final int envelopeUsed;

  int get envelopeRemaining => item.amount - envelopeUsed > 0 ? item.amount - envelopeUsed : 0;
}

/// 월 예약형으로 제안할 가맹점 묶음(10/14: 토스 후불교통·신한 모바일후불티머니 → 교통).
const envelopeCandidates = [(name: '교통(후불)', pattern: '후불')];

class EnvelopeSuggestion {
  const EnvelopeSuggestion(this.name, this.pattern, this.amount, this.perDay, this.weekdays);

  final String name;
  final String pattern;
  final int amount;
  final int perDay;
  final int weekdays;
}

String _ymd(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// 정기 지출 등록·탐지·매칭(Spec F5).
class RecurringRepository {
  RecurringRepository(this.db);

  final AppDatabase db;
  static const _dismissedKey = 'recurring_dismissed';

  Future<List<SpendRecord>> _records() async => [
    for (final t in await db.select(db.transactions).get())
      SpendRecord(
        id: t.id,
        merchant: t.merchantNorm,
        date: DateTime.parse(t.localDate),
        amount: t.amount,
        isUnusual: t.isUnusual,
        cancelled: t.status == 'CANCELLED',
        cardId: t.cardId,
        recurringItemId: t.recurringItemId,
      ),
  ];

  RecurringItem _toCore(RecurringItemRow r) => RecurringItem(
    id: r.id,
    name: r.name,
    amount: r.amount,
    dueDay: r.dueDay,
    isEstimate: r.isEstimate,
    active: r.active,
    matchPattern: r.matchPattern,
    amountTolerancePct: r.amountTolerancePct,
    isEnvelope: r.isEnvelope,
  );

  Future<Set<String>> dismissed() async {
    final raw = await db.setting(_dismissedKey);
    return raw == null ? {} : {...(jsonDecode(raw) as List).cast<String>()};
  }

  /// 등록 제안. 이미 등록한 항목에 걸리는 가맹점과 [아니요]한 가맹점은 뺀다.
  Future<List<RecurringSuggestion>> suggestions(DateTime now) async {
    final records = await _records();
    final items = await (db.select(db.recurringItems)..where((i) => i.active.equals(true))).get();
    final patterns = [for (final i in items) i.matchPattern.toLowerCase()];
    final covered = {
      for (final r in records)
        if (r.recurringItemId != null || patterns.any((p) => p.isNotEmpty && r.merchant.toLowerCase().contains(p)))
          r.merchant,
    };
    return detectRecurring(records, now, excludedMerchants: {...covered, ...await dismissed()});
  }

  /// 월 예약형 제안(교통비 등). 이미 같은 문구의 항목이 있거나 [아니요]했으면 제안하지 않는다.
  Future<List<EnvelopeSuggestion>> envelopeSuggestions(DateTime now) async {
    final records = await _records();
    final items = await (db.select(db.recurringItems)..where((i) => i.active.equals(true))).get();
    final no = await dismissed();
    return [
      for (final c in envelopeCandidates)
        if (!no.contains(c.name) && !items.any((i) => i.matchPattern == c.pattern))
          if (estimateEnvelope([
                for (final r in records)
                  if (r.merchant.contains(c.pattern)) r,
              ], now)
              case final e?)
            EnvelopeSuggestion(c.name, c.pattern, e.amount, e.perDay, e.days),
    ];
  }

  Future<void> addEnvelope(EnvelopeSuggestion e) =>
      add(name: e.name, amount: e.amount, dueDay: 1, isEstimate: true, matchPattern: e.pattern, isEnvelope: true);

  Future<void> dismiss(String merchant) async =>
      db.putSetting(_dismissedKey, jsonEncode([...await dismissed(), merchant]));

  Future<int> add({
    required String name,
    required int amount,
    required int dueDay,
    required bool isEstimate,
    String? matchPattern,
    int? cardId,
    bool isEnvelope = false,
  }) async {
    final id = await db
        .into(db.recurringItems)
        .insert(
          RecurringItemsCompanion.insert(
            name: name,
            amount: amount,
            dueDay: dueDay,
            isEstimate: Value(isEstimate),
            cardId: Value(cardId),
            matchPattern: (matchPattern == null || matchPattern.trim().isEmpty) ? name : matchPattern.trim(),
            // 금액이 크게 변하는 항목은 금액을 보지 않고 가맹점·날짜로만 매칭
            amountTolerancePct: Value(isEstimate || isEnvelope ? null : 30),
            isEnvelope: Value(isEnvelope),
          ),
        );
    await relink();
    return id;
  }

  Future<void> addSuggestion(RecurringSuggestion s) => add(
    name: s.merchant,
    amount: s.amount,
    dueDay: s.dueDay,
    isEstimate: s.isEstimate,
    matchPattern: s.merchant,
    cardId: s.cardId,
  );

  Future<void> update(RecurringItemRow item) async {
    await db
        .update(db.recurringItems)
        .replace(item.copyWith(amountTolerancePct: Value(item.isEstimate ? null : (item.amountTolerancePct ?? 30))));
    await relink(reset: true);
  }

  /// 삭제는 비활성화로 한다(지난 기록과 연결은 유지).
  Future<void> deactivate(int id) async {
    await (db.update(
      db.recurringItems,
    )..where((i) => i.id.equals(id))).write(const RecurringItemsCompanion(active: Value(false)));
  }

  /// [이번 달 없음]: 이번 달 F에서 뺀다.
  Future<void> skipMonth(int itemId, DateTime now) async {
    await db
        .into(db.recurringMatches)
        .insert(
          RecurringMatchesCompanion.insert(
            recurringItemId: itemId,
            month: YearMonth.of(now).toString(),
            status: 'SKIPPED',
            decidedOn: _ymd(now),
          ),
        );
  }

  /// 정기 지출과 실제 결제를 연결한다. 몇 번 실행해도 결과가 같다.
  /// 지난 달 결제도 연결해야 평소 패턴 P에서 정기 지출이 빠진다(Spec 3.7).
  /// [reset]이면 자동으로 만든 연결(PAID)을 지우고 다시 만든다(항목 수정 후).
  Future<void> relink({bool reset = false}) => db.transaction(() async {
    if (reset) {
      await (db.delete(db.recurringMatches)..where((m) => m.status.equals('PAID'))).go();
      await db.update(db.transactions).write(const TransactionsCompanion(recurringItemId: Value(null)));
    }
    final items = [
      for (final r in await (db.select(db.recurringItems)..where((i) => i.active.equals(true))).get()) _toCore(r),
    ];
    if (items.isEmpty) return;
    final handled = <String>{
      for (final m in await db.select(db.recurringMatches).get()) '${m.recurringItemId}|${m.month}',
    };
    final records = (await _records()).where((r) => r.recurringItemId == null).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    for (final r in records) {
      final month = YearMonth.of(r.date).toString();
      // 월 예약형: 맞는 결제를 모두 연결만 한다(월별 처리 기록 없음)
      final envelope = items.where((i) => i.isEnvelope && matchesRecurring(i, r)).firstOrNull;
      if (envelope != null) {
        await (db.update(
          db.transactions,
        )..where((t) => t.id.equals(r.id))).write(TransactionsCompanion(recurringItemId: Value(envelope.id)));
        continue;
      }
      final paid = {
        for (final i in items)
          if (handled.contains('${i.id}|$month')) i.id,
      };
      final item = bestMatch(
        [
          for (final i in items)
            if (!i.isEnvelope) i,
        ],
        r,
        alreadyPaid: paid,
      );
      if (item == null) continue;
      handled.add('${item.id}|$month');
      await db
          .into(db.recurringMatches)
          .insert(
            RecurringMatchesCompanion.insert(
              recurringItemId: item.id,
              month: month,
              transactionId: Value(r.id),
              status: 'PAID',
              decidedOn: _ymd(r.date),
            ),
          );
      await (db.update(
        db.transactions,
      )..where((t) => t.id.equals(r.id))).write(TransactionsCompanion(recurringItemId: Value(item.id)));
    }
  });

  Future<List<RecurringView>> view(DateTime now) async {
    final month = YearMonth.of(now);
    final today = dateOnly(now);
    final items =
        await (db.select(db.recurringItems)
              ..where((i) => i.active.equals(true))
              ..orderBy([(i) => OrderingTerm.asc(i.dueDay)]))
            .get();
    final matches = await (db.select(db.recurringMatches)..where((m) => m.month.equals(month.toString()))).get();
    final linked = await (db.select(db.transactions)..where((t) => t.recurringItemId.isNotNull())).get();
    final amounts = {for (final t in linked) t.id: t.amount};
    int usedThisMonth(int itemId) => linked
        .where(
          (t) => t.recurringItemId == itemId && t.status != 'CANCELLED' && month.contains(DateTime.parse(t.localDate)),
        )
        .fold(0, (s, t) => s + t.amount);

    return [
      for (final item in items)
        () {
          final due = month.dayClamped(item.dueDay);
          if (item.isEnvelope) {
            return RecurringView(item, MonthState.envelope, due, envelopeUsed: usedThisMonth(item.id));
          }
          final m = matches.where((x) => x.recurringItemId == item.id).firstOrNull;
          if (m?.status == 'PAID') {
            return RecurringView(item, MonthState.paid, due, paidAmount: amounts[m!.transactionId]);
          }
          if (m?.status == 'SKIPPED') return RecurringView(item, MonthState.skipped, due);
          // 예정일 + 3일이 지나도 결제가 없으면 "아직 결제 안 됨"(Spec 3.4)
          final overdue = today.isAfter(due.add(const Duration(days: 3)));
          return RecurringView(item, overdue ? MonthState.overdue : MonthState.upcoming, due);
        }(),
    ];
  }
}
