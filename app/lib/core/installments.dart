import 'models.dart';

/// n개월 할부 금액을 회차별로 나눈다(Spec 4.5).
/// 회차 금액은 100원 단위 내림, 나머지는 1회차에 더한다(현대카드 명세서로 확인).
List<int> splitInstallment(int amount, int months) {
  if (months <= 1) return [amount];
  final rest = amount ~/ months ~/ 100 * 100;
  return [amount - rest * (months - 1), for (var i = 1; i < months; i++) rest];
}

/// 승인 월을 1회차로 하는 할부 일정.
List<InstallmentRow> buildSchedule(Txn txn) {
  final first = YearMonth.of(txn.date);
  final parts = splitInstallment(txn.amount, txn.installmentMonths);
  return [
    for (var i = 0; i < parts.length; i++)
      InstallmentRow(txnId: txn.id, seq: i + 1, month: first.plus(i), amount: parts[i]),
  ];
}
