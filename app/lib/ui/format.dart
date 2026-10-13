import 'package:intl/intl.dart';

final _won = NumberFormat('#,##0', 'ko_KR');

/// 계산은 원 단위, 화면 표시는 100원 단위 내림(Spec 0장).
String won(int amount, {bool exact = false}) {
  final shown = exact ? amount : (amount >= 0 ? amount ~/ 100 * 100 : -((-amount) ~/ 100 * 100));
  return '${_won.format(shown)}원';
}

/// 54만 원, 106만 원처럼 만 원 단위 표기(예산 목표용).
String manWon(int amount) {
  if (amount % 10000 == 0) return '${_won.format(amount ~/ 10000)}만 원';
  return won(amount, exact: true);
}
