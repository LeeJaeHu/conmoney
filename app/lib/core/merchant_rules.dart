// 가맹점 정규화와 내장 카테고리 규칙(Spec F3 2단계 BUILTIN_RULE).
// tools/import_statements.py의 norm_merchant·CATEGORY_RULES를 옮긴 것이다. 한쪽을 고치면 다른 쪽도 고친다.

final _pgPrefix = RegExp(r'^(KCP|나이스|\(주\)이니시스|토스페이먼츠(주식회사)?|한국정보통신|카카오|씨제이시스템즈\(주\)|다날|KG모빌리언스|신한은행)\s*-\s*');

String normMerchant(String raw) {
  var s = raw.replaceFirst(_pgPrefix, '');
  s = s.replaceFirst(RegExp(r',(USD|KRW|JPY|EUR):[\d.]+$'), '');
  s = s.replaceAll(RegExp(r'^\(주\)|^㈜|\(주\)$|㈜$'), '').trim();
  if (s.contains('우아한형제들') || s.contains('배민')) return s.contains('배민클럽_') ? '배민클럽' : '배달의민족';
  if (s.contains('쿠팡')) return s.contains('와우') ? '쿠팡 와우멤버십' : '쿠팡';
  if (s.startsWith('#KT통')) return 'KT 휴대폰';
  if (s.startsWith('#한국전력공사')) return '한국전력 전기료';
  if (s.contains('비케이알')) return '버거킹(비케이알)';
  if (s.contains('구글페이먼트')) return '구글플레이';
  if (s.startsWith('CURSOR')) return 'Cursor';
  if (s.startsWith('STEAM')) return 'Steam';
  if (s.startsWith('네이버플러스')) return '네이버플러스 멤버십';
  if (s.contains('네이버페이')) return '네이버페이';
  if (s == '카카오페이' || s == '주식회사 카카오') return '카카오';
  return s;
}

/// 위에서부터 처음 맞는 규칙.
final _categoryRules = <(String, RegExp)>[
  ('통신', RegExp(r'KT 휴대폰|KT인터넷', caseSensitive: false)),
  ('공과금', RegExp(r'한국전력|yesco|도시가스', caseSensitive: false)),
  ('연회비', RegExp(r'연회비', caseSensitive: false)),
  ('API', RegExp(r'OPENAI|GROK|ANLATAN|TYPESAFE', caseSensitive: false)),
  (
    '구독',
    RegExp(r'와우멤버십|배민클럽|네이버플러스|유투브프리미엄|유튜브|컬리_멤버스|피클플러스|^Apple$|^카카오$|CURSOR|야쿠르트', caseSensitive: false),
  ),
  ('교통', RegExp(r'티머니|택시|고속버스|시외버스|현장발권|후불교통|코레일|SRT', caseSensitive: false)),
  ('카페·간식', RegExp(r'커피|컴포즈|메가|스타벅스|이디야|투썸|빽다방|엔제리너스|카페|아이스|빵|베이커리|디저트', caseSensitive: false)),
  (
    '식비',
    RegExp(r'배달의민족|요기요|버거|KFC|초밥|훠궈|샤브|쿠우쿠우|맘스|식당|김밥|마트|컬리|이마트|편의점|세븐일레븐|GS\)?25|지에스|씨유|CU', caseSensitive: false),
  ),
  ('게임', RegExp(r'닌텐도|구글플레이|스팀|STEAM|넥슨|BOARDGAM', caseSensitive: false)),
  ('교육', RegExp(r'교보문고|와이비엠|YBM|크몽', caseSensitive: false)),
  ('의료', RegExp(r'약국|의원|병원|치과', caseSensitive: false)),
  ('경조사·선물', RegExp(r'선물하기', caseSensitive: false)),
  ('쇼핑', RegExp(r'쿠팡|유니클로|에스에스지|SSG|안경|무신사|올리브영|다이소|글리티|KW JAPAN|네이버페이', caseSensitive: false)),
  ('영화', RegExp(r'시네마|씨지브이|CGV|메가박스', caseSensitive: false)),
];

/// 내장 규칙으로 정한 카테고리 이름. 없으면 null.
String? builtinCategory(String merchant, int amount) {
  // 가맹점 이름만으로 정할 수 없는 경우(10/13 검수)
  if (merchant == '구글클라우드코리아') return amount >= 10000 ? '기타' : 'API';
  for (final (category, pattern) in _categoryRules) {
    if (pattern.hasMatch(merchant)) return category;
  }
  return null;
}
