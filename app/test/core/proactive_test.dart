import 'package:conmoney/core/budget_engine.dart';
import 'package:conmoney/core/models.dart';
import 'package:conmoney/core/proactive.dart';
import 'package:flutter_test/flutter_test.dart';

DateTime d(int m, int day, [int h = 9]) => DateTime(2026, m, day, h);

const telecom = RecurringItem(id: 1, name: '통신비', amount: 65000, dueDay: 15);
const small = RecurringItem(id: 2, name: '구독', amount: 9900, dueDay: 15);

BudgetEngine engineOf(
  List<Txn> txns, {
  List<RecurringItem> items = const [],
  List<RecurringMatch> matches = const [],
}) => BudgetEngine(
  Ledger(
    txns: txns,
    installments: const [],
    recurringItems: items,
    recurringMatches: matches,
    firstRecordDate: DateTime(2026, 10, 1),
  ),
);

ProactiveAlert? run(BudgetEngine e, DateTime now, AlertTrigger t, {int budget = 1000000, bool sent = false}) =>
    evaluate(engine: e, budget: budget, now: now, trigger: t, alreadySentToday: sent);

void main() {
  group('공통 조건', () {
    test('하루 1회: 오늘 이미 보냈으면 보내지 않는다', () {
      final e = engineOf([Txn(id: 1, amount: 900000, date: d(10, 13))]);
      expect(run(e, d(10, 13, 12), AlertTrigger.afterTransaction), isNotNull);
      expect(run(e, d(10, 13, 12), AlertTrigger.afterTransaction, sent: true), isNull);
    });

    test('N4 조용한 시간(23시~8시)에는 보내지 않는다', () {
      final e = engineOf([Txn(id: 1, amount: 900000, date: d(10, 13))]);
      expect(run(e, d(10, 13, 23), AlertTrigger.afterTransaction), isNull);
      expect(run(e, d(10, 14, 7), AlertTrigger.morning), isNull);
      expect(QuietHours.standard.contains(DateTime(2026, 10, 13, 8)), isFalse);
      expect(const QuietHours(1, 6).contains(DateTime(2026, 10, 13, 3)), isTrue);
    });

    test('예산이 없으면 보내지 않는다', () {
      expect(
        evaluate(
          engine: engineOf(const []),
          budget: null,
          now: d(10, 13),
          trigger: AlertTrigger.morning,
          alreadySentToday: false,
        ),
        isNull,
      );
    });
  });

  group('1. 오늘 초과(결제 직후)', () {
    test('오늘 쓸 수 있는 금액을 넘으면 초과액과 내일 하루 금액', () {
      // 10/13, B=1,000,000, 13일 전 600,000 → 하루 21,052. 오늘 30,000 → 8,948 초과
      final e = engineOf([Txn(id: 1, amount: 600000, date: d(10, 5)), Txn(id: 2, amount: 30000, date: d(10, 13))]);
      final a = run(e, d(10, 13, 12), AlertTrigger.afterTransaction)!;
      expect(a.type, AlertType.todayOver);
      expect(a.title, '오늘 정한 금액을 8,948원 넘었어요');
      expect(a.body, '내일부터 하루 20,555원으로 맞추면 돼요.');
    });

    test('아직 넘지 않았으면 결제 직후에는 보내지 않는다', () {
      final e = engineOf([Txn(id: 1, amount: 5000, date: d(10, 13))]);
      expect(run(e, d(10, 13, 12), AlertTrigger.afterTransaction), isNull);
    });
  });

  group('2. 큰 정기 지출 2일 전(아침)', () {
    test('모레 나가는 기준 이상 정기 지출을 알린다. 작은 항목·이미 낸 항목은 제외', () {
      final e = engineOf(const [], items: const [telecom, small]);
      final a = run(e, d(10, 13), AlertTrigger.morning)!;
      expect(a.type, AlertType.bigFixedSoon);
      expect(a.title, '모레 통신비 65,000원이 나가요');
      expect(a.body, contains('이미 반영'));

      final paid = engineOf(
        const [],
        items: const [telecom, small],
        matches: [
          RecurringMatch(
            itemId: 1,
            month: const YearMonth(2026, 10),
            status: RecurringMatchStatus.paid,
            decidedOn: d(10, 12),
          ),
        ],
      );
      expect(run(paid, d(10, 13), AlertTrigger.morning)?.type, isNot(AlertType.bigFixedSoon));
      expect(run(e, d(10, 11), AlertTrigger.morning), isNull); // 4일 전은 아직
    });

    test('기준액은 max(30,000원, 예산의 3%)', () {
      expect(bigFixedThreshold(540000), 30000);
      expect(bigFixedThreshold(2000000), 60000);
    });
  });

  group('3. 월말 초과 예상이 처음 생긴 날(아침)', () {
    test('어제까지는 예산 안이었는데 오늘 기준 예상 월말 지출이 넘으면 알린다', () {
      // 어제(10/12) 큰 결제로 예상이 넘어감. P는 이번 달 일평균 기반(과거 데이터 없음)
      final e = engineOf([Txn(id: 1, amount: 100000, date: d(10, 1)), Txn(id: 2, amount: 300000, date: d(10, 12))]);
      final a = run(e, d(10, 13), AlertTrigger.morning, budget: 600000)!;
      expect(a.type, AlertType.pace);
      expect(a.title, startsWith('지금 속도면 월말에'));
      expect(a.body, contains('남은 19일 동안 하루'));
    });

    test('이미 어제부터 넘을 예상이었으면 다시 보내지 않는다', () {
      final e = engineOf([Txn(id: 1, amount: 500000, date: d(10, 2)), Txn(id: 2, amount: 1000, date: d(10, 12))]);
      expect(run(e, d(10, 13), AlertTrigger.morning, budget: 600000), isNull);
    });

    test('N3 같은 날 조건이 여러 개면 우선순위가 높은 것 하나만', () {
      final e = engineOf(
        [Txn(id: 1, amount: 100000, date: d(10, 1)), Txn(id: 2, amount: 300000, date: d(10, 12))],
        items: const [telecom],
      );
      expect(run(e, d(10, 13), AlertTrigger.morning, budget: 600000)!.type, AlertType.bigFixedSoon);
    });
  });
}
