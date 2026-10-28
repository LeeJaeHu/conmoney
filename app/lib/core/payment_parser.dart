// 결제 알림 파서(Spec F2). 출처별 규칙은 실제 알림 샘플을 보고 만든다(Spec F2 "샘플 → 정규식 → 회귀 테스트").
// 샘플: 롯데카드 카카오 알림톡(10/17), 현대카드 앱(10/18). 토스는 샘플이 생기면 추가한다.

/// 알림을 보낸 곳. [key]는 cards.source와 같은 값(csv_import.dart cardInfo).
enum PaymentSource {
  lotteKakao('KAKAO_LOTTE', '롯데카드 LOCA LIKIT Eat'),
  hyundaiApp('HYUNDAI_APP', '현대카드 ZERO'),
  tossApp('TOSS_APP', '토스뱅크카드');

  const PaymentSource(this.key, this.product);

  final String key;
  final String product;

  /// 리스너가 받은 패키지·제목으로 출처를 정한다(Kotlin SourceFilter와 같은 기준).
  static PaymentSource? of(String package, String? title) => switch (package) {
    'com.kakao.talk' when title?.contains('롯데카드') ?? false => lotteKakao,
    'com.hyundaicard.appcard' => hyundaiApp,
    'viva.republica.toss' => tossApp,
    _ => null,
  };
}

class ParsedPayment {
  const ParsedPayment({
    required this.source,
    required this.amount,
    required this.merchant,
    required this.approvedAt,
    this.isCancel = false,
    this.installmentMonths = 1,
    this.isForeign = false,
    this.foreignAmount,
  });

  final PaymentSource source;

  /// 원화 금액(양수). 해외 결제에 원화가 없으면 0이고 [foreignAmount]에 "USD 12.99".
  final int amount;
  final String merchant;

  /// 본문 시각이 있으면 그것, 없으면 알림 게시 시각.
  final DateTime approvedAt;
  final bool isCancel;
  final int installmentMonths;
  final bool isForeign;
  final String? foreignAmount;
}

sealed class ParseOutcome {
  const ParseOutcome();
}

/// 결제 알림으로 해석함.
class Parsed extends ParseOutcome {
  const Parsed(this.payment);

  final ParsedPayment payment;
}

/// 결제 같은데 해석하지 못함 → 확인 필요 거래로 남긴다(조용히 버리지 않음).
class ParseFailed extends ParseOutcome {
  const ParseFailed(this.reason);

  final String reason;
}

/// 광고·안내 등 결제가 아님.
class NotPayment extends ParseOutcome {
  const NotPayment();
}

/// 이 출처의 파서가 아직 없음(샘플 필요). 원문은 남겨 두고 파서가 생기면 다시 처리한다.
class Unsupported extends ParseOutcome {
  const Unsupported();
}

ParseOutcome parsePaymentNotification({
  required PaymentSource source,
  required String? title,
  required String body,
  required DateTime postedAt,
}) => switch (source) {
  PaymentSource.lotteKakao => _parseLotte(body, postedAt),
  PaymentSource.hyundaiApp => _parseHyundai(body, postedAt),
  PaymentSource.tossApp => const Unsupported(),
};

List<String> _lines(String body) => [
  for (final l in body.split('\n'))
    if (l.trim().isNotEmpty) l.trim(),
];

/// "승인 없는 안내"는 무시하고, 승인·취소와 금액이 있는데 못 읽으면 실패로 남긴다.
ParseOutcome _unreadable(String body, String reason) =>
    RegExp('승인|취소').hasMatch(body) && RegExp(r'[\d,]+\s*원').hasMatch(body) ? ParseFailed(reason) : const NotPayment();

/// 현대카드 앱(10/18 샘플). 긴 본문(big_text)에만 가맹점이 있다:
/// ```
/// 홍길동 님, 현대 ZERO 승인 20,900원 일시불, 10/18 4:04
/// ㈜우아한형제들
/// 누적142,396원
/// ```
/// 취소·해외·할부는 아직 샘플이 없어 공통 키워드로 추정한다 `[확인 필요]`.
ParseOutcome _parseHyundai(String body, DateTime postedAt) {
  final lines = _lines(body);
  final head = RegExp(
    r'(승인취소|취소|승인)\s*(?:(' + _currencies + r')\s*)?([\d,]+(?:\.\d+)?)\s*(원|' + _currencies + r')?',
  );
  final idx = lines.indexWhere(head.hasMatch);
  if (idx < 0) {
    // 기존 규칙으로 못 읽을 때만 자동납부 형식을 시도한다(잘 읽히던 알림은 결과가 바뀌지 않게, 10/28)
    if (lines.any((l) => l.contains('자동납부'))) return _parseHyundaiAutoPay(lines, postedAt);
    return _unreadable(body, '승인 줄을 찾지 못함');
  }
  final merchant = lines.skip(idx + 1).where((l) => !l.startsWith('누적')).firstOrNull;
  // 짧은 본문(text)만 있으면 가맹점이 없다
  if (merchant == null) return const ParseFailed('가맹점 줄이 없음');

  final m = head.firstMatch(lines[idx])!;
  final currency = m[2] ?? (m[4] == '원' || m[4] == null ? null : m[4]);
  final number = m[3]!.replaceAll(',', '');
  final amount = currency != null ? 0 : int.tryParse(number);
  if (amount == null) return ParseFailed('금액을 읽지 못함: ${m[3]}');
  final months = RegExp(r'(\d+)\s*개월').firstMatch(lines[idx]);
  return Parsed(
    ParsedPayment(
      source: PaymentSource.hyundaiApp,
      amount: amount,
      merchant: merchant,
      approvedAt: _dateTime(lines[idx], postedAt) ?? postedAt,
      isCancel: m[1] != '승인',
      installmentMonths: months == null ? 1 : int.parse(months[1]!),
      isForeign: currency != null || lines[idx].contains('해외'),
      foreignAmount: currency != null ? '$currency $number' : null,
    ),
  );
}

/// 현대카드 자동납부(10/27 실기기 제보: 전기요금이 "승인 줄을 찾지 못함"으로 실패). 첫 줄이
/// `자동납부 승인 이*후님 한국전력공사 10월…`처럼 "승인" 뒤에 이름·가맹점이 와서 일반 승인 줄 규칙에 안 맞는다.
/// 원문 전체는 아직 못 봐서 너그럽게 읽는다 `[확인 필요]`:
/// - 금액: 그 줄부터 "누적" 줄을 빼고 처음 나오는 "N원"
/// - 가맹점: "님" 뒤에서 "N월", "N원", "일시불", 날짜 앞까지. 비면 다음 줄
ParseOutcome _parseHyundaiAutoPay(List<String> lines, DateTime postedAt) {
  final idx = lines.indexWhere((l) => l.contains('자동납부'));
  final head = lines[idx];
  int? amount;
  for (final l in lines.skip(idx)) {
    if (l.startsWith('누적')) continue;
    final m = RegExp(r'([\d,]+)\s*원').firstMatch(l);
    if (m != null) {
      amount = int.tryParse(m[1]!.replaceAll(',', ''));
      break;
    }
  }
  if (amount == null) return const ParseFailed('자동납부 금액을 찾지 못함');

  String cut(String s) => s
      .replaceAll(RegExp('자동납부|승인취소|승인|취소'), '')
      .replaceFirst(RegExp(r'^[,\s]+'), '')
      .split(RegExp(r'\s*(\d{1,2}월|[\d,]+\s*원|일시불|\d{1,2}/\d{1,2})'))
      .first
      .trim();
  final afterName = head.contains('님') ? head.substring(head.indexOf('님') + 1) : head.replaceFirst(RegExp(r'^.*?(승인취소|취소|승인)'), '');
  var merchant = cut(afterName);
  if (merchant.isEmpty && idx + 1 < lines.length && !lines[idx + 1].startsWith('누적')) merchant = cut(lines[idx + 1]);
  if (merchant.isEmpty) return const ParseFailed('자동납부 가맹점을 찾지 못함');
  return Parsed(
    ParsedPayment(
      source: PaymentSource.hyundaiApp,
      amount: amount,
      merchant: merchant,
      approvedAt: _dateTime(lines.skip(idx).join(' '), postedAt) ?? postedAt,
      isCancel: head.contains('취소'),
    ),
  );
}

const _currencies = 'USD|EUR|JPY|CNY|GBP|HKD|SGD|AUD|CAD|CHF|TWD|THB|VND|PHP';

/// 롯데카드 알림톡(10/17 샘플):
/// ```
/// 버거킹 건대입구역점
/// 11,800원 승인
/// 이*후 LOCA LIKIT Eat(5*1*)
/// 일시불, 10/17 11:57
/// 누적금액 470,844원
/// ```
/// 취소·해외·할부는 아직 샘플이 없어 공통 키워드(Spec F2)로 추정한다 `[확인 필요]`.
ParseOutcome _parseLotte(String body, DateTime postedAt) {
  final lines = _lines(body);
  // "11,800원 승인", "11,800원 승인취소", "USD 12.99 승인", "12.99USD 승인"
  final amountLine = RegExp(
    r'^(?:(' + _currencies + r')\s*)?([\d,]+(?:\.\d+)?)\s*(원|' + _currencies + r')?\s*(승인취소|취소|승인)',
  );
  final idx = lines.indexWhere(amountLine.hasMatch);
  // 결제 예정·명세서 안내 같은 알림톡은 "승인"이 없다
  if (idx < 0) return _unreadable(body, '금액 줄을 찾지 못함');
  if (idx == 0) return const ParseFailed('가맹점 줄이 없음');

  final m = amountLine.firstMatch(lines[idx])!;
  final currency = m[1] ?? (m[3] == '원' || m[3] == null ? null : m[3]);
  final number = m[2]!.replaceAll(',', '');
  final isForeign = currency != null;
  final amount = isForeign ? 0 : int.tryParse(number);
  if (amount == null) return ParseFailed('금액을 읽지 못함: ${m[2]}');

  final rest = lines.skip(idx + 1).join('\n');
  final months = RegExp(r'(\d+)\s*개월').firstMatch(rest);
  return Parsed(
    ParsedPayment(
      source: PaymentSource.lotteKakao,
      amount: amount,
      merchant: lines[idx - 1],
      approvedAt: _dateTime(rest, postedAt) ?? postedAt,
      isCancel: m[4] != '승인',
      installmentMonths: months == null ? 1 : int.parse(months[1]!),
      isForeign: isForeign || RegExp('해외').hasMatch(body),
      foreignAmount: isForeign ? '$currency $number' : null,
    ),
  );
}

/// "10/17 11:57" → 연도는 게시 시각에서. 1월에 12월 날짜가 오면 전년(Spec F2).
DateTime? _dateTime(String text, DateTime postedAt) {
  final m = RegExp(r'(\d{1,2})/(\d{1,2})\s+(\d{1,2}):(\d{2})').firstMatch(text);
  if (m == null) return null;
  final month = int.parse(m[1]!);
  final year = postedAt.month == 1 && month == 12 ? postedAt.year - 1 : postedAt.year;
  return DateTime(year, month, int.parse(m[2]!), int.parse(m[3]!), int.parse(m[4]!));
}
