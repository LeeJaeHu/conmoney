import 'package:flutter/material.dart';

import '../../core/analysis.dart';
import '../../ui/format.dart';

/// 초과·평소보다 많음은 빨강 대신 주황(스트레스 최소화 원칙, 홈과 같은 색).
Color _warm(ThemeData t) => t.brightness == Brightness.dark ? Colors.orange.shade300 : Colors.orange.shade800;

/// 이번 달 흐름(10/16): 누적 지출(실선), 평소대로 쓰면 월말까지(점선), 지난 달들 같은 날 누적(회색), 예산(가로 점선).
class PaceChart extends StatelessWidget {
  const PaceChart({super.key, required this.pace});

  final MonthPace pace;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final over = pace.projectedOver;
    final small = theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    final muted = scheme.onSurfaceVariant.withValues(alpha: 0.45);

    Widget legend(Color c, String label, {bool dashed = false}) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: 16, height: 10, child: CustomPaint(painter: _LegendLine(c, dashed))),
        const SizedBox(width: 4),
        Text(label, style: small),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('지금까지 ${won(pace.spentSoFar)} · 평소대로 쓰면 월말 약 ${won(pace.projectedEnd)}', style: theme.textTheme.bodyMedium),
        Text(
          over > 0 ? '예산보다 ${won(over)} 많아요' : '예산 안이에요 (${won(-over)} 여유)',
          style: theme.textTheme.titleSmall?.copyWith(color: over > 0 ? _warm(theme) : scheme.primary),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            legend(scheme.primary, '이번 달'),
            legend(scheme.primary, '평소대로 쓰면', dashed: true),
            if (pace.usual != null) legend(muted, '지난 달들 평소'),
            legend(scheme.onSurface, '예산', dashed: true),
          ],
        ),
        const SizedBox(height: 8),
        Semantics(
          label:
              '이번 달 누적 지출 그래프. 오늘까지 ${won(pace.spentSoFar)}, 월말 예상 ${won(pace.projectedEnd)}, 예산 ${won(pace.budget)}',
          child: SizedBox(
            height: 180,
            width: double.infinity,
            child: CustomPaint(
              painter: _PacePainter(
                pace,
                line: scheme.primary,
                muted: muted,
                ink: scheme.onSurface,
                grid: scheme.outlineVariant,
                label: theme.textTheme.labelSmall!.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendLine extends CustomPainter {
  _LegendLine(this.color, this.dashed);

  final Color color;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 2;
    final y = size.height / 2;
    if (!dashed) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    } else {
      for (var x = 0.0; x < size.width; x += 6) {
        canvas.drawLine(Offset(x, y), Offset((x + 3).clamp(0, size.width), y), p);
      }
    }
  }

  @override
  bool shouldRepaint(_LegendLine old) => old.color != color || old.dashed != dashed;
}

class _PacePainter extends CustomPainter {
  _PacePainter(this.pace, {required this.line, required this.muted, required this.ink, required this.grid, required this.label});

  final MonthPace pace;
  final Color line, muted, ink, grid;
  final TextStyle label;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 4.0, right = 52.0, top = 8.0, bottom = 20.0;
    final days = pace.month.days;
    final maxY = [
          pace.budget,
          pace.projectedEnd,
          pace.spentSoFar,
          if (pace.usual != null) pace.usual!.last,
        ].reduce((a, b) => a > b ? a : b) *
        1.08;
    final w = size.width - left - right, h = size.height - top - bottom;
    double x(num day) => left + (day - 1) / (days - 1) * w;
    double y(num v) => top + h - (v / maxY).clamp(0.0, 1.0) * h;

    void text(String s, Offset at, {bool alignRight = false}) {
      final tp = TextPainter(text: TextSpan(text: s, style: label), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(alignRight ? at.dx - tp.width : at.dx, at.dy - tp.height / 2));
    }

    void dashed(Offset a, Offset b, Paint p, {double dash = 5, double gap = 4}) {
      final d = b - a;
      final len = d.distance;
      if (len == 0) return;
      final u = d / len;
      for (var t = 0.0; t < len; t += dash + gap) {
        canvas.drawLine(a + u * t, a + u * (t + dash).clamp(0, len), p);
      }
    }

    // 바닥선, x축 날짜
    canvas.drawLine(Offset(left, top + h), Offset(left + w, top + h), Paint()..color = grid);
    for (final d in {1, 10, 20, days}) {
      text('$d일', Offset(x(d) - (d == 1 ? 0 : 8), size.height - 8));
    }
    // 예산 가로선 + 오른쪽 라벨
    final by = y(pace.budget);
    dashed(Offset(left, by), Offset(left + w, by), Paint()
      ..color = ink.withValues(alpha: 0.7)
      ..strokeWidth = 1.2);
    text('예산 ${manWonLabel(pace.budget)}', Offset(left + w + 4, by));

    // 지난 달들 평소(회색)
    if (pace.usual case final u?) {
      final path = Path()..moveTo(x(1), y(u[0]));
      for (var d = 1; d < u.length; d++) {
        path.lineTo(x(d + 1), y(u[d]));
      }
      canvas.drawPath(path, Paint()
        ..color = muted
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5);
    }
    // 오늘 세로선
    canvas.drawLine(Offset(x(pace.today), top), Offset(x(pace.today), top + h), Paint()..color = grid);
    // 이번 달 누적(실선)
    final strong = Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final a = pace.actual;
    final path = Path()..moveTo(x(1), y(a.isEmpty ? 0 : a[0]));
    for (var d = 1; d < a.length; d++) {
      path.lineTo(x(d + 1), y(a[d]));
    }
    canvas.drawPath(path, strong);
    // 평소대로 쓰면(점선): 오늘 → 말일
    if (pace.today < days) {
      dashed(Offset(x(pace.today), y(pace.spentSoFar)), Offset(x(days), y(pace.projectedEnd)), Paint()
        ..color = line
        ..strokeWidth = 2);
      // 예산 라벨과 겹치면 14px 비켜 놓는다
      var py = y(pace.projectedEnd);
      if ((py - by).abs() < 14) py = by + (py < by ? -14 : 14);
      text(manWonLabel(pace.projectedEnd), Offset(left + w + 4, py));
    }
    canvas.drawCircle(Offset(x(pace.today), y(pace.spentSoFar)), 3.5, Paint()..color = line);
  }

  @override
  bool shouldRepaint(_PacePainter old) => old.pace != pace || old.line != line;
}

/// 그래프 라벨용 만 원 단위: 54만, 71.2만.
String manWonLabel(int amount) {
  final man = amount / 10000;
  return man >= 100 || man == man.roundToDouble() ? '${man.round()}만' : '${man.toStringAsFixed(1)}만';
}

/// 카테고리 평소 대비(10/16): 가운데 0 기준으로 평소보다 많이 쓴 만큼 오른쪽(주황), 덜 쓴 만큼 왼쪽.
class CompareChart extends StatelessWidget {
  const CompareChart({super.key, required this.comparison, required this.periodLabel, this.maxRows = 6});

  final CategoryComparison comparison;
  final String periodLabel;
  final int maxRows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final small = theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    if (comparison.monthsUsed == 0) {
      return Text('비교할 지난 기록이 아직 없어요', style: small);
    }
    final rows = [...comparison.rows.where((r) => r.diff != 0)]
      ..sort((a, b) => b.diff.abs().compareTo(a.diff.abs()));
    final shown = rows.take(maxRows).toList()..sort((a, b) => b.diff.compareTo(a.diff));
    final maxAbs = shown.fold(1, (m, r) => r.diff.abs() > m ? r.diff.abs() : m);
    final totalDiff = comparison.total - comparison.usualTotal;
    String signed(int v) => '${v > 0 ? '+' : ''}${compactWon(v)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$periodLabel 전체 ${totalDiff == 0 ? '평소와 같아요' : '평소보다 ${won(totalDiff.abs())} ${totalDiff > 0 ? '많이' : '적게'} 썼어요'}',
          style: theme.textTheme.bodyMedium,
        ),
        Text('특이 지출 제외 · 평소 = 지난 ${comparison.monthsUsed}개월 같은 기간 중앙값', style: small),
        const SizedBox(height: 8),
        if (shown.isEmpty) Text('평소와 다른 카테고리가 없어요', style: small),
        for (final r in shown)
          Tooltip(
            message: '${r.name}: ${won(r.amount)} (평소 ${won(r.usual)})',
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  SizedBox(
                    width: 72,
                    child: Text(r.name, style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  Expanded(
                    child: SizedBox(
                      height: 18,
                      child: CustomPaint(
                        painter: _DivergingBar(
                          r.diff / maxAbs,
                          r.diff > 0 ? _warm(theme) : scheme.primary,
                          scheme.outlineVariant,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 56,
                    child: Text(
                      signed(r.diff),
                      textAlign: TextAlign.right,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: r.diff > 0 ? _warm(theme) : scheme.primary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _DivergingBar extends CustomPainter {
  _DivergingBar(this.ratio, this.color, this.axis);

  final double ratio;
  final Color color, axis;

  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.width / 2;
    canvas.drawLine(Offset(mid, 0), Offset(mid, size.height), Paint()..color = axis);
    final len = (mid - 2) * ratio.abs();
    final r = ratio >= 0 ? Rect.fromLTWH(mid, 3, len, size.height - 6) : Rect.fromLTWH(mid - len, 3, len, size.height - 6);
    canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), Paint()..color = color);
  }

  @override
  bool shouldRepaint(_DivergingBar old) => old.ratio != ratio || old.color != color;
}
