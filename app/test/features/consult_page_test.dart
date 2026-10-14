import 'dart:convert';

import 'package:conmoney/app_providers.dart';
import 'package:conmoney/data/agent_client.dart';
import 'package:conmoney/data/database.dart';
import 'package:conmoney/features/agent/consult_page.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('F6 상담: 툴 호출을 앱에서 실행해 결과를 보내고 최종 답과 판단을 보여준다', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final requests = <Map<String, dynamic>>[];

    final fake = MockClient((req) async {
      final body = jsonDecode(req.body) as Map<String, dynamic>;
      requests.add(body);
      final round = body['round'] as int;
      final reply = round == 1
          ? {
              'status': 'tool_calls',
              'items': [
                {'type': 'function_call', 'call_id': 'c1', 'name': 'simulate_purchase', 'arguments': '{"amount":150000}'},
              ],
              'tool_calls': [
                {'call_id': 'c1', 'name': 'simulate_purchase', 'arguments': '{"amount":150000}'},
              ],
              'usage': {'krw': 1.0},
            }
          : {
              'status': 'final',
              'text': '[판단] 미루는 걸 추천\n[근거] 예산이 설정되지 않았어요',
              'items': [
                {'role': 'assistant', 'content': '...'},
              ],
              'verdict': 'postpone',
              'verified': true,
              'usage': {'krw': 2.0},
            };
      return http.Response.bytes(utf8.encode(jsonEncode(reply)), 200, headers: {'content-type': 'application/json'});
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(() => DateTime(2026, 10, 14, 12)),
          agentClientProvider.overrideWithValue(AgentClient(client: fake, baseUrl: 'http://test', token: 't')),
        ],
        child: const MaterialApp(home: ConsultPage()),
      ),
    );

    await tester.runAsync(() async {
      await tester.tap(find.text('키보드 15만 원 살까?'));
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();

    expect(requests, hasLength(2));
    final sent = (requests[1]['items'] as List).last as Map;
    expect(sent['type'], 'function_call_output');
    expect(sent['call_id'], 'c1');
    expect(jsonDecode(sent['output'] as String)['error'], contains('예산')); // 예산 미설정 → 앱이 오류를 툴 결과로 보냄
    expect(find.text('미루는 걸 추천'), findsOneWidget); // 판단 칩
    expect(find.textContaining('[근거]'), findsOneWidget);
  });
}
