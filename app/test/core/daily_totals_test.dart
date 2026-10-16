// 홈 달력(10/16): 날짜별 합계와 짧은 금액 표기
import 'package:conmoney/core/category_summary.dart';
import 'package:conmoney/core/models.dart';
import 'package:conmoney/ui/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  SpendItem item(int id, DateTime d, int amount, {bool unusual = false}) =>
      SpendItem(txnId: id, date: d, amount: amount, merchant: 'x', isUnusual: unusual);

  test('dailyTotals: 그 달 날짜별 합계, 취소는 빼고, 다른 달은 무시', () {
    final all = [
      item(1, DateTime(2026, 10, 3), 12000),
      item(2, DateTime(2026, 10, 3, 18), 4500),
      item(3, DateTime(2026, 10, 3), -2000), // 부분 취소
      item(4, DateTime(2026, 10, 31), 100000, unusual: true),
      item(5, DateTime(2026, 9, 30), 7000),
    ];
    final t = dailyTotals(all, const YearMonth(2026, 10));
    expect(t.length, 31);
    expect(t[2], 14500);
    expect(t[30], 100000);
    expect(dailyTotals(all, const YearMonth(2026, 10), includeUnusual: false)[30], 0);
    expect(t.fold(0, (s, v) => s + v), 114500);
  });

  test('compactWon: 달력 칸용 짧은 금액', () {
    expect(compactWon(500), '500');
    expect(compactWon(8000), '8천');
    expect(compactWon(8500), '8.5천');
    expect(compactWon(12300), '1.2만');
    expect(compactWon(10000), '1만');
    expect(compactWon(123000), '12만');
    expect(compactWon(-2000), '-2천');
  });
}
