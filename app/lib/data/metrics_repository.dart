import 'dart:convert';

import 'package:drift/drift.dart';

import 'database.dart';

/// 실사용 지표 기록과 요약(PRD 8장 "실사용: 2~4주 본인 사용 기록").
class MetricsRepository {
  MetricsRepository(this.db, [DateTime Function()? clock]) : clock = clock ?? DateTime.now;

  final AppDatabase db;
  final DateTime Function() clock;

  Future<void> record(String type, Map<String, Object?> data) =>
      db.into(db.metricEvents).insert(MetricEventsCompanion.insert(type: type, at: clock(), data: jsonEncode(data)));

  /// 구매 상담 1건이 끝났을 때.
  Future<void> consult({
    required int rounds,
    required double krw,
    required int latencyMs,
    required String? verdict,
    required bool verified,
    required List<String> tools,
    bool error = false,
  }) => record('CONSULT', {
    'rounds': rounds,
    'krw': krw,
    'latency_ms': latencyMs,
    'verdict': verdict,
    'verified': verified,
    'tools': tools,
    'error': error,
  });

  /// 확인 시트에서 카테고리를 저장했을 때. 추천을 그대로 받았는지가 실사용 정확도다.
  Future<void> categoryReview({
    required String? suggestSource,
    required bool accepted,
    required bool hadSuggestion,
    double? confidence,
  }) => record('CATEGORY_REVIEW', {
    'source': suggestSource,
    'accepted': accepted,
    'had_suggestion': hadSuggestion,
    'confidence': confidence,
  });

  Future<void> alert(String type) => record('ALERT', {'type': type});

  Future<List<MetricEventRow>> all() => (db.select(db.metricEvents)..orderBy([(e) => OrderingTerm.asc(e.id)])).get();

  Future<MetricsSummary> summary() async {
    final events = await all();
    Map<String, Object?> d(MetricEventRow e) => jsonDecode(e.data) as Map<String, Object?>;
    final consults = [
      for (final e in events)
        if (e.type == 'CONSULT') d(e),
    ];
    final reviews = [
      for (final e in events)
        // 과거 기록 가져오기로 들어온 거래를 고친 것은 추천 정확도와 무관하므로 뺀다
        if (e.type == 'CATEGORY_REVIEW' && d(e)['had_suggestion'] == true && d(e)['source'] != 'IMPORT') d(e),
    ];
    final ok = consults.where((c) => c['error'] != true).toList();
    double avg(Iterable<num> xs) => xs.isEmpty ? 0 : xs.reduce((a, b) => a + b) / xs.length;
    final bySource = <String, (int, int)>{};
    for (final r in reviews) {
      final key = (r['source'] as String?) ?? 'NONE';
      final (n, acc) = bySource[key] ?? (0, 0);
      bySource[key] = (n + 1, acc + (r['accepted'] == true ? 1 : 0));
    }
    return MetricsSummary(
      consults: consults.length,
      consultErrors: consults.length - ok.length,
      verifiedRate: ok.isEmpty ? null : ok.where((c) => c['verified'] == true).length / ok.length,
      avgKrw: avg(ok.map((c) => c['krw'] as num)),
      avgLatencyMs: avg(ok.map((c) => c['latency_ms'] as num)),
      avgRounds: avg(ok.map((c) => c['rounds'] as num)),
      reviews: reviews.length,
      acceptRate: reviews.isEmpty ? null : reviews.where((r) => r['accepted'] == true).length / reviews.length,
      acceptBySource: {for (final e in bySource.entries) e.key: e.value.$2 / e.value.$1},
      alerts: events.where((e) => e.type == 'ALERT').length,
      since: events.isEmpty ? null : events.first.at,
    );
  }

  /// 분석용 내보내기(JSON). 수치만 있으므로 그대로 PC로 옮겨도 된다.
  Future<String> exportJson() async => const JsonEncoder.withIndent('  ').convert([
    for (final e in await all()) {'type': e.type, 'at': e.at.toIso8601String(), ...jsonDecode(e.data) as Map},
  ]);
}

class MetricsSummary {
  const MetricsSummary({
    required this.consults,
    required this.consultErrors,
    required this.verifiedRate,
    required this.avgKrw,
    required this.avgLatencyMs,
    required this.avgRounds,
    required this.reviews,
    required this.acceptRate,
    required this.acceptBySource,
    required this.alerts,
    required this.since,
  });

  final int consults;
  final int consultErrors;
  final double? verifiedRate;
  final double avgKrw;
  final double avgLatencyMs;
  final double avgRounds;
  final int reviews;

  /// 카테고리 추천을 그대로 받은 비율(실사용 정확도).
  final double? acceptRate;
  final Map<String, double> acceptBySource;
  final int alerts;
  final DateTime? since;
}
