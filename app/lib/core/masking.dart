// 서버로 보내거나 앱 밖으로 내보내기 전에 식별 정보를 가린다(Spec 6장 가드레일).
// 금액(쉼표 포함), 날짜, 시각은 남긴다.

final _rules = <(RegExp, String)>[
  (RegExp(r'[\d*]{4}-[\d*]{4}-[\d*]{4}-[\d*]{3,4}'), '****-****-****-****'), // 카드번호
  (RegExp(r'(승인\s*번호|승인No\.?)\s*[:：]?\s*\d+'), r'승인번호 ******'),
  (RegExp(r'01\d-?\d{3,4}-?\d{4}'), '010-****-****'), // 휴대폰 번호
  (RegExp(r'(?<![\d,.])\d{6,}(?![\d,])'), '******'), // 쉼표 없는 6자리 이상 숫자(계좌·승인번호 등)
];

String maskIdentifiers(String? input) {
  if (input == null) return '';
  var s = input;
  for (final (pattern, replacement) in _rules) {
    s = s.replaceAll(pattern, replacement);
  }
  return s;
}
