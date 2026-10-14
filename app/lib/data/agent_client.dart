import 'dart:convert';

import 'package:http/http.dart' as http;

/// 서버 주소·토큰. `flutter run --dart-define-from-file=config/dev.json`으로 넣는다(app/config/example.json 참고).
const serverUrl = String.fromEnvironment('CONMONEY_SERVER');
const serverToken = String.fromEnvironment('CONMONEY_TOKEN');

class ToolCall {
  ToolCall(this.callId, this.name, this.arguments);

  final String callId;
  final String name;
  final Map<String, Object?> arguments;
}

class AgentReply {
  AgentReply({
    required this.status,
    required this.items,
    this.toolCalls = const [],
    this.text,
    this.verdict,
    this.verified = true,
    this.krw = 0,
  });

  /// `tool_calls` 또는 `final`
  final String status;

  /// 대화 기록에 그대로 이어 붙일 항목(추론 항목은 암호화된 채로 들어 있음).
  final List<Map<String, Object?>> items;
  final List<ToolCall> toolCalls;
  final String? text;
  final String? verdict;
  final bool verified;
  final double krw;
}

class AgentException implements Exception {
  AgentException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 서버 `/v1/agent`, `/v1/categorize` 호출(Spec 5장).
class AgentClient {
  AgentClient({http.Client? client, this.baseUrl = serverUrl, this.token = serverToken})
    : _http = client ?? http.Client();

  final http.Client _http;
  final String baseUrl;
  final String token;

  bool get configured => baseUrl.isNotEmpty && token.isNotEmpty;

  Future<Map<String, Object?>> _post(String path, Map<String, Object?> body) async {
    if (!configured) throw AgentException('서버 주소가 설정되지 않았어요(config/dev.json).');
    final http.Response r;
    try {
      r = await _http
          .post(
            Uri.parse('$baseUrl$path'),
            headers: {'content-type': 'application/json', 'x-app-token': token},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 60));
    } on Exception catch (e) {
      throw AgentException('서버에 연결하지 못했어요: $e');
    }
    if (r.statusCode == 429) throw AgentException('요청이 너무 많아요. 잠시 후 다시 시도해 주세요.');
    if (r.statusCode != 200) throw AgentException('서버 오류(${r.statusCode})');
    return jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, Object?>;
  }

  /// [session]은 한 질문의 여러 라운드를 서버 로그에서 묶는 임의 ID.
  Future<AgentReply> step(List<Map<String, Object?>> items, int round, {String? session}) async {
    final j = await _post('/v1/agent', {'items': items, 'round': round, 'session': ?session});
    return AgentReply(
      status: j['status'] as String,
      items: [for (final i in j['items'] as List) (i as Map).cast<String, Object?>()],
      toolCalls: [
        for (final c in (j['tool_calls'] as List?) ?? const [])
          ToolCall(
            c['call_id'] as String,
            c['name'] as String,
            (jsonDecode(c['arguments'] as String) as Map).cast<String, Object?>(),
          ),
      ],
      text: j['text'] as String?,
      verdict: j['verdict'] as String?,
      verified: j['verified'] as bool? ?? true,
      krw: ((j['usage'] as Map?)?['krw'] as num?)?.toDouble() ?? 0,
    );
  }

  /// 처음 보는 가맹점 분류(F3). 실패하면 null.
  Future<({String category, double? confidence, bool ambiguous})?> categorize(
    String merchant,
    List<String> categories,
  ) async {
    try {
      final j = await _post('/v1/categorize', {'merchant': merchant, 'categories': categories});
      final c = j['category'] as String;
      if (c == 'NONE') return null;
      return (
        category: c,
        confidence: (j['confidence'] as num?)?.toDouble(),
        ambiguous: j['ambiguous'] as bool? ?? true,
      );
    } on AgentException {
      return null;
    }
  }
}
