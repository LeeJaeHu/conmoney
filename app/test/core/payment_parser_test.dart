import 'package:conmoney/core/merchant_rules.dart';
import 'package:conmoney/core/payment_parser.dart';
import 'package:flutter_test/flutter_test.dart';

// 10/17 실제 롯데카드 알림톡의 형식을 그대로 두고 금액·가맹점·이름만 바꾼 샘플(실데이터는 저장소에 올리지 않음).
const lotteApproval = '롯데리아 강남역점\n9,300원 승인\n홍*동 LOCA LIKIT Eat(1*2*)\n일시불, 10/17 12:34\n누적금액 123,456원';

ParseOutcome lotte(String body, [DateTime? postedAt]) => parsePaymentNotification(
  source: PaymentSource.lotteKakao,
  title: '롯데카드',
  body: body,
  postedAt: postedAt ?? DateTime(2026, 10, 17, 12, 35),
);

ParsedPayment parsed(ParseOutcome o) => (o as Parsed).payment;

void main() {
  test('출처: 카카오톡은 롯데카드 제목만, 나머지 카드사 앱은 패키지로', () {
    expect(PaymentSource.of('com.kakao.talk', '롯데카드'), PaymentSource.lotteKakao);
    expect(PaymentSource.of('com.kakao.talk', '친구'), isNull);
    expect(PaymentSource.of('viva.republica.toss', null), PaymentSource.tossApp);
    expect(PaymentSource.of('com.example.game', '이벤트'), isNull);
  });

  test('롯데 승인: 가맹점·금액·일시불·본문 시각', () {
    final p = parsed(lotte(lotteApproval));
    expect(p.merchant, '롯데리아 강남역점');
    expect(p.amount, 9300);
    expect(p.isCancel, isFalse);
    expect(p.installmentMonths, 1);
    expect(p.isForeign, isFalse);
    expect(p.approvedAt, DateTime(2026, 10, 17, 12, 34));
  });

  test('롯데 할부·취소 [가정: 샘플 없음, 공통 키워드]', () {
    final inst = parsed(lotte(lotteApproval.replaceFirst('일시불', '3개월')));
    expect(inst.installmentMonths, 3);
    final cancel = parsed(lotte(lotteApproval.replaceFirst('승인', '승인취소')));
    expect(cancel.isCancel, isTrue);
    expect(cancel.amount, 9300);
  });

  test('롯데 해외: 원화 금액이 없으면 0과 원통화', () {
    final p = parsed(lotte(lotteApproval.replaceFirst('9,300원 승인', 'USD 12.99 승인')));
    expect(p.isForeign, isTrue);
    expect(p.amount, 0);
    expect(p.foreignAmount, 'USD 12.99');
  });

  test('1월에 받은 12월 날짜는 전년', () {
    final p = parsed(lotte(lotteApproval.replaceFirst('10/17', '12/31'), DateTime(2027, 1, 1, 0, 2)));
    expect(p.approvedAt, DateTime(2026, 12, 31, 12, 34));
  });

  test('결제가 아닌 안내는 무시, 결제 같은데 못 읽으면 실패로 남김', () {
    expect(lotte('10월 결제예정금액 안내\n결제일 11/14'), isA<NotPayment>());
    expect(lotte('승인 내역을 확인해 주세요\n합계 9,300 원'), isA<ParseFailed>());
    expect(lotte('9,300원 승인\n일시불, 10/17 12:34'), isA<ParseFailed>()); // 가맹점 줄 없음
  });

  // 10/18 실제 현대카드 앱 알림 형식(\r 포함)에 이름·금액·가맹점만 바꾼 샘플
  const hyundaiApproval = '홍길동 님, 현대 ZERO 승인 15,400원 일시불, 10/18 4:04 \r\n㈜우아한형제들 \r\n누적123,456원';
  ParseOutcome hyundai(String body) => parsePaymentNotification(
    source: PaymentSource.hyundaiApp,
    title: '현대카드',
    body: body,
    postedAt: DateTime(2026, 10, 18, 4, 5),
  );

  test('현대 승인: 첫 줄의 금액·일시불·시각(한 자리 시), 다음 줄 가맹점', () {
    final p = parsed(hyundai(hyundaiApproval));
    expect(p.merchant, '㈜우아한형제들');
    expect(p.amount, 15400);
    expect(p.isCancel, isFalse);
    expect(p.installmentMonths, 1);
    expect(p.approvedAt, DateTime(2026, 10, 18, 4, 4));
    expect(normMerchant(p.merchant), '배달의민족');
    expect(builtinCategory(normMerchant(p.merchant), p.amount), '식비');
  });

  test('현대 할부·취소 [가정: 샘플 없음]', () {
    expect(parsed(hyundai(hyundaiApproval.replaceFirst('일시불', '3개월'))).installmentMonths, 3);
    final cancel = parsed(hyundai(hyundaiApproval.replaceFirst('승인', '승인취소')));
    expect(cancel.isCancel, isTrue);
    expect(cancel.amount, 15400);
  });

  test('현대: 짧은 본문만 있어 가맹점이 없으면 실패로 남김, 안내 알림은 무시', () {
    expect(hyundai('홍길동 님, 현대 ZERO 승인 15,400원 일시불, 10/18 4:04 \r'), isA<ParseFailed>());
    expect(hyundai('이번 달 혜택을 확인하세요'), isA<NotPayment>());
  });

  test('토스는 샘플이 생길 때까지 보류', () {
    final o = parsePaymentNotification(
      source: PaymentSource.tossApp,
      title: '토스',
      body: '9,300원 결제',
      postedAt: DateTime(2026, 10, 17),
    );
    expect(o, isA<Unsupported>());
  });

  test('가맹점 정규화·내장 카테고리(가져오기 도구와 같은 규칙)', () {
    expect(normMerchant('KCP - 스타벅스 강남점'), '스타벅스 강남점');
    expect(builtinCategory('롯데리아 강남역점', 9300), isNull);
    expect(builtinCategory('버거킹 강남역점', 9300), '식비');
    expect(builtinCategory('스타벅스 강남점', 5000), '카페·간식');
    expect(builtinCategory('구글클라우드코리아', 12000), '기타');
  });

  // 10/27 실기기 제보: 현대카드 자동납부(전기요금) 첫 줄 "자동납부 승인 이*후님 한국전력공사 10월…"만 확인. 나머지 모양은 추정
  ParseOutcome autoPay(String body) => parsePaymentNotification(
    source: PaymentSource.hyundaiApp,
    title: '현대카드',
    body: body,
    postedAt: DateTime(2026, 10, 27, 9, 1),
  );

  test('현대 자동납부: 금액이 같은 줄에 있을 때', () {
    final p = parsed(autoPay('자동납부 승인 홍*동님 한국전력공사 10월분 45,320원'));
    expect(p.merchant, '한국전력공사');
    expect(p.amount, 45320);
    expect(p.isCancel, isFalse);
    expect(p.approvedAt, DateTime(2026, 10, 27, 9, 1));
  });

  test('현대 자동납부: 금액·날짜가 다음 줄, 누적 줄은 무시', () {
    final p = parsed(autoPay('자동납부 승인 홍*동님 한국전력공사 10월 전기요금\n45,320원 일시불 10/27 08:59\n누적 512,000원'));
    expect(p.merchant, '한국전력공사');
    expect(p.amount, 45320);
    expect(p.approvedAt, DateTime(2026, 10, 27, 8, 59));
  });

  test('현대 자동납부: 가맹점이 다음 줄, 취소', () {
    final p = parsed(autoPay('홍*동님 자동납부 승인취소\n한국전력공사 10월분\n45,320원'));
    expect(p.merchant, '한국전력공사');
    expect(p.isCancel, isTrue);
    expect(autoPay('자동납부 승인 홍*동님 한국전력공사'), isA<ParseFailed>()); // 금액 없음
    expect(builtinCategory(normMerchant('한국전력공사'), 45320), '공과금');
  });
}
