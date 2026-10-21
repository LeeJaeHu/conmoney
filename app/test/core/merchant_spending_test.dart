import 'package:conmoney/core/budget_engine.dart';
import 'package:conmoney/core/agent_tools.dart';
import 'package:conmoney/core/category_summary.dart';
import 'package:conmoney/core/merchant_spending.dart';
import 'package:flutter_test/flutter_test.dart';

// 가짜 가맹점·금액(실데이터 아님)
var _id = 0;
SpendItem item(String merchant, DateTime date, int amount, {int? txnId, int? seq, bool unusual = false}) => SpendItem(
  txnId: txnId ?? ++_id,
  date: date,
  amount: amount,
  merchant: merchant,
  isUnusual: unusual,
  installmentSeq: seq,
  installmentMonths: seq == null ? 1 : 3,
);

final now = DateTime(2026, 10, 21, 12);
final items = [
  item('스타벅스 강남점', DateTime(2026, 10, 3), 6500),
  item('스타벅스 역삼점', DateTime(2026, 10, 15), 5800),
  item('스타벅스 강남점', DateTime(2026, 9, 10), 4500),
  item('스타벅스 강남점', DateTime(2026, 8, 10), 9000),
  item('스타벅스 강남점', DateTime(2026, 7, 10), 3000),
  item('배달의민족', DateTime(2026, 9, 2), 21000),
  item('배달의민족', DateTime(2026, 9, 20), 18000, unusual: true),
  item('가짜전자', DateTime(2026, 10, 5), 100000, txnId: 900, seq: 1),
  item('가짜전자', DateTime(2026, 11, 1), 100000, txnId: 900, seq: 2),
];

void main() {
  test('가맹점 이름 맞추기: 부분 일치, 줄임말, (주)·띄어쓰기 무시', () {
    expect(merchantMatches('스타벅스 강남점', '스타벅스'), isTrue);
    expect(merchantMatches('스타벅스 강남점', '스벅'), isTrue);
    expect(merchantMatches('배달의민족', '배민'), isTrue);
    expect(merchantMatches('(주)가짜마트', '가짜 마트'), isTrue);
    expect(merchantMatches('스타벅스 강남점', '투썸'), isFalse);
    expect(merchantMatches('스타벅스 강남점', '스'), isFalse); // 한 글자는 거의 다 걸리므로 부분 일치 안 함
  });

  test('이번 달: 여러 지점 합계·건수·지점별, 평소(최근 3개월 중앙값)', () {
    final r = merchantSpending(items, '스타벅스', 'this_month', now, DateTime(2026, 5, 1));
    expect(r.total, 12300);
    expect(r.count, 2);
    expect(r.names, [('스타벅스 강남점', 6500), ('스타벅스 역삼점', 5800)]);
    expect(r.usualMonthly, 4500); // 7·8·9월 3000·9000·4500의 중앙값
    expect(r.lastDate, DateTime(2026, 10, 15));
  });

  test('지난달: 특이 지출 포함', () {
    final r = merchantSpending(items, '배민', 'last_month', now, null);
    expect(r.total, 39000);
    expect(r.count, 2);
  });

  test('할부는 이번 달 회차만, 마지막 결제일은 미래 회차가 아니라 실제 결제일', () {
    final r = merchantSpending(items, '가짜전자', 'this_month', now, null);
    expect(r.total, 100000);
    expect(r.count, 1);
    expect(r.lastDate, DateTime(2026, 10, 5));
  });

  test('툴 결과: 찾으면 *_text 금액, 없으면 found=false로 숫자 없이', () {
    final box = AgentToolbox(engine: BudgetEngine(Ledger(txns: const [], installments: const [])), budget: null, items: items, now: now);
    final ok = box.run('get_merchant_spending', {'query': '스타벅스', 'period': 'this_month'});
    expect(ok['found'], isTrue);
    expect(ok['total_text'], '12,300원');
    expect(ok['count'], 2);
    final none = box.run('get_merchant_spending', {'query': '없는가게', 'period': 'this_month'});
    expect(none['found'], isFalse);
    expect(none.containsKey('total'), isFalse);
    expect(box.run('get_merchant_spending', {'query': '스', 'period': 'all'}).containsKey('error'), isTrue);
  });
}
