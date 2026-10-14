import 'dart:io';

import 'package:conmoney/core/models.dart';
import 'package:conmoney/core/recurring.dart';
import 'package:conmoney/data/csv_import.dart';
import 'package:flutter_test/flutter_test.dart';

DateTime d(int m, int day) => DateTime(2026, m, day);

var _id = 0;
SpendRecord rec(String merchant, int m, int day, int amount, {bool unusual = false}) =>
    SpendRecord(id: ++_id, merchant: merchant, date: d(m, day), amount: amount, isUnusual: unusual);

void main() {
  group('자동 탐지 (F5)', () {
    final now = DateTime(2026, 10, 13);

    test('매달 같은 날 같은 금액 → 고정 정기 지출', () {
      final s = detectRecurring([
        rec('넷플릭스', 8, 12, 13500),
        rec('넷플릭스', 9, 12, 13500),
        rec('넷플릭스', 10, 11, 13500),
      ], now);
      expect(s, hasLength(1));
      expect(s.single.amount, 13500);
      expect(s.single.dueDay, 12);
      expect(s.single.isEstimate, isFalse);
      expect(s.single.months, 3);
    });

    test('금액이 10% 넘게 바뀌면 추정(공과금형), 예정액은 최근 3개월 중앙값', () {
      final s = detectRecurring([
        rec('한국전력 전기료', 6, 26, 17400),
        rec('한국전력 전기료', 7, 27, 50400),
        rec('한국전력 전기료', 8, 25, 68410),
        rec('한국전력 전기료', 9, 28, 50030),
      ], now);
      expect(s.single.isEstimate, isTrue);
      expect(s.single.amount, 50400); // 9·8·7월 중앙값
    });

    test('한 달에 여러 번 나오는 가맹점, 1개월뿐인 가맹점, 특이 지출, 끊긴 구독은 제외', () {
      final s = detectRecurring([
        rec('배달의민족', 9, 3, 18000),
        rec('배달의민족', 10, 2, 17000),
        rec('배달의민족', 10, 5, 21000),
        rec('한번만', 10, 1, 5000),
        rec('게임기', 8, 15, 300000, unusual: true),
        rec('게임기', 9, 15, 300000, unusual: true),
        rec('끊긴구독', 6, 5, 9900),
        rec('끊긴구독', 7, 5, 9900),
      ], now);
      expect(s, isEmpty);
    });

    test('금액이 바뀌는 항목이 2개월뿐이면 제안하지 않는다(우연한 반복)', () {
      final s = detectRecurring([rec('편의점', 9, 7, 5000), rec('편의점', 10, 7, 11650)], now);
      expect(s, isEmpty);
    });

    test('결제일이 3일 넘게 벗어나면 연속 구간이 끊긴다', () {
      final s = detectRecurring([rec('앱', 9, 3, 1100), rec('앱', 10, 17, 1100)], now);
      expect(s, isEmpty);
    });

    test('이미 등록했거나 [아니요]한 가맹점은 제안하지 않는다', () {
      final s = detectRecurring(
        [rec('넷플릭스', 9, 12, 13500), rec('넷플릭스', 10, 12, 13500)],
        now,
        excludedMerchants: {'넷플릭스'},
      );
      expect(s, isEmpty);
    });
  });

  group('실제 결제와 매칭 (F5)', () {
    const kt = RecurringItem(id: 1, name: 'KT 휴대폰', amount: 38000, dueDay: 12, matchPattern: 'KT 휴대폰');
    const power = RecurringItem(
      id: 2,
      name: '전기료',
      amount: 50000,
      dueDay: 26,
      isEstimate: true,
      matchPattern: '한국전력',
      amountTolerancePct: null,
    );

    test('가맹점·금액(±30%)·날짜(±5일)가 맞으면 매칭, 카드는 보지 않는다', () {
      expect(matchesRecurring(kt, rec('KT 휴대폰', 10, 12, 43740)), isTrue);
      expect(matchesRecurring(kt, rec('KT 휴대폰', 10, 12, 60000)), isFalse); // 금액 초과
      expect(matchesRecurring(kt, rec('KT 휴대폰', 10, 20, 38000)), isFalse); // 날짜 벗어남
      expect(matchesRecurring(kt, rec('KT인터넷제휴납부', 10, 12, 38000)), isFalse);
    });

    test('금액이 크게 변하는 항목은 금액을 보지 않는다', () {
      expect(matchesRecurring(power, rec('한국전력 전기료', 8, 25, 68410)), isTrue);
    });

    test('결제일 31일 항목은 30일인 달의 말일 기준', () {
      const rent = RecurringItem(id: 3, name: '월세', amount: 500000, dueDay: 31, matchPattern: '월세');
      expect(matchesRecurring(rent, rec('월세', 11, 30, 500000)), isTrue);
    });

    test('여러 항목이 맞으면 예정일이 가까운 것, 이미 낸 항목은 건너뜀', () {
      const a = RecurringItem(id: 10, name: 'A', amount: 10000, dueDay: 5, matchPattern: '구독');
      const b = RecurringItem(id: 11, name: 'B', amount: 10000, dueDay: 9, matchPattern: '구독');
      final r = rec('구독서비스', 10, 8, 10000);
      expect(bestMatch([a, b], r)?.id, 11);
      expect(bestMatch([a, b], r, alreadyPaid: {11})?.id, 10);
    });
  });

  final real = File('../data/transactions_v3.csv');
  test('R1 실데이터: 9개 항목 제안, 배민·쿠팡·구글플레이는 제안 안 함', () {
    final rows = parseTransactionsCsv(real.readAsStringSync());
    final records = [
      for (var i = 0; i < rows.length; i++)
        SpendRecord(
          id: i,
          merchant: rows[i].merchant,
          date: rows[i].date,
          amount: rows[i].amount,
          isUnusual: rows[i].isUnusual,
          cancelled: rows[i].cancelled,
        ),
    ];
    final s = detectRecurring(records, DateTime(2026, 10, 13));
    final names = {for (final x in s) x.merchant};
    // ignore: avoid_print
    print(
      [for (final x in s) '${x.dueDay}일 ${x.merchant} ${x.isEstimate ? '약 ' : ''}${x.amount} (${x.months}개월)']
          .join('\n'),
    );

    for (final m in ['KT 휴대폰', 'KT인터넷제휴납부', 'Cursor', '한국전력 전기료', 'yesco자동이체', '카카오', '네이버플러스 멤버십', 'Apple']) {
      expect(names, contains(m));
    }
    expect(names.any((n) => n.startsWith('피클플러스')), isTrue);
    expect(names, isNot(contains('배달의민족')));
    expect(names, isNot(contains('쿠팡')));
    expect(names, isNot(contains('구글플레이')));
    expect(names.any((n) => n.startsWith('이마트24')), isFalse); // 2개월 추정형은 거름
    expect(s.firstWhere((x) => x.merchant == '한국전력 전기료').isEstimate, isTrue);
  }, skip: real.existsSync() ? false : 'data/transactions_v3.csv 없음');

  group('월 예약형 예상액', () {
    test('타는 날 하루 합계 중앙값 × 이번 달 평일 수, 1,000원 단위 올림', () {
      final rides = [
        for (final day in [1, 2, 5, 6, 7, 8, 12]) ...[
          rec('후불교통 버스', 10, day, 1500),
          rec('후불교통 지하철', 10, day, 50),
          rec('후불교통 지하철', 10, day, 1550),
        ],
      ];
      final e = estimateEnvelope(rides, DateTime(2026, 10, 13))!;
      expect(e.perDay, 3100);
      expect(e.days, 22); // 2026년 10월 평일
      expect(e.amount, 69000); // 68,200 → 1,000원 단위 올림
    });

    test('탄 날이 5일보다 적으면 제안하지 않는다', () {
      expect(estimateEnvelope([rec('후불교통 버스', 10, 1, 1500)], DateTime(2026, 10, 13)), isNull);
    });

    test('월 예약형 매칭은 가맹점만 본다(금액·날짜 무관, 0원 환승 제외)', () {
      const transit = RecurringItem(id: 9, name: '교통', amount: 68000, dueDay: 1, isEnvelope: true, matchPattern: '후불');
      expect(matchesRecurring(transit, rec('후불교통 지하철', 10, 20, 50)), isTrue);
      expect(matchesRecurring(transit, rec('모바일후불티머니이용 0014건/월', 9, 11, 15350)), isTrue);
      expect(matchesRecurring(transit, rec('후불교통 버스', 10, 20, 0)), isFalse);
      expect(matchesRecurring(transit, rec('배달의민족', 10, 20, 15000)), isFalse);
    });
  });
}
