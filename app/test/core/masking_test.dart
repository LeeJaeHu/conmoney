import 'package:conmoney/core/masking.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('카드번호·승인번호·휴대폰·긴 숫자를 가린다', () {
    expect(maskIdentifiers('카드 1234-56**-****-7890 승인'), '카드 ****-****-****-**** 승인');
    expect(maskIdentifiers('승인번호 30968403'), '승인번호 ******');
    expect(maskIdentifiers('문의 010-1234-5678'), '문의 010-****-****');
    expect(maskIdentifiers('계좌 74891123450505'), '계좌 ******');
  });

  test('금액·날짜·시각은 남긴다', () {
    const s = '롯데카드 16,500원 일시불 10/13 09:14 누적 1,234,567원 2026-10-13';
    expect(maskIdentifiers(s), s);
  });
}
