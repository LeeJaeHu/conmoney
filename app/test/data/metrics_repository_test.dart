import 'package:conmoney/data/database.dart';
import 'package:conmoney/data/metrics_repository.dart';
import 'package:conmoney/data/spending_repository.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late MetricsRepository metrics;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    metrics = MetricsRepository(db);
  });
  tearDown(() => db.close());

  test('상담 지표: 검증 통과율·평균 비용·오류 수', () async {
    await metrics.consult(rounds: 2, krw: 6, latencyMs: 4000, verdict: 'ok', verified: true, tools: ['simulate_purchase']);
    await metrics.consult(rounds: 3, krw: 10, latencyMs: 8000, verdict: null, verified: false, tools: const []);
    await metrics.consult(rounds: 1, krw: 0, latencyMs: 500, verdict: null, verified: false, tools: const [], error: true);
    final s = await metrics.summary();
    expect(s.consults, 3);
    expect(s.consultErrors, 1);
    expect(s.verifiedRate, 0.5);
    expect(s.avgKrw, 8);
    expect(s.avgLatencyMs, 6000);
  });

  test('카테고리 추천 수락률: 추천을 그대로 받았는지, 과거 기록 수정은 제외', () async {
    final cats = {for (final c in await SpendingRepository(db).categories()) c.name: c.id};
    Future<int> txn(String key, String source) => db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            kind: 'APPROVAL',
            amount: 1000,
            merchantRaw: key,
            merchantNorm: key,
            approvedAt: DateTime(2026, 10, 14),
            localDate: '2026-10-14',
            dedupeKey: key,
          ).copyWith(
            suggestedCategoryId: Value(cats['식비']),
            suggestSource: Value(source),
          ),
        );
    final spending = SpendingRepository(db);
    await spending.saveReview(await txn('a', 'USER_RULE'), categoryId: cats['식비'], isUnusual: false, memo: null);
    await spending.saveReview(await txn('b', 'LLM'), categoryId: cats['쇼핑'], isUnusual: false, memo: null);
    await spending.saveReview(await txn('c', 'LLM'), categoryId: cats['식비'], isUnusual: false, memo: null);
    await spending.saveReview(await txn('d', 'IMPORT'), categoryId: cats['쇼핑'], isUnusual: false, memo: null);

    final s = await metrics.summary();
    expect(s.reviews, 3);
    expect(s.acceptRate, closeTo(2 / 3, 1e-9));
    expect(s.acceptBySource, {'USER_RULE': 1.0, 'LLM': 0.5});
    expect(await metrics.exportJson(), isNot(contains('merchant')));
  });
}
