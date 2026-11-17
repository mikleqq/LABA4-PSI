import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../data/models.dart';
import '../domain/period_stats.dart';
import 'format.dart';
import 'theme.dart';

/// Line chart of the rate over a period. X is the day offset from [start],
/// so days without a rate (weekends) show up as gaps in time, not as
/// evenly spaced points.
class RateChart extends StatelessWidget {
  const RateChart({
    super.key,
    required this.points,
    required this.start,
    required this.end,
    required this.stats,
  });

  final List<RatePoint> points;
  final DateTime start;
  final DateTime end;
  final PeriodStats stats;

  double _x(DateTime d) => dateOnly(d).difference(start).inHours / 24;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final gradient = AppColors.trendGradient(stats.trend);
    final lineColor = AppColors.trendColor(stats.trend);
    final spread = stats.max.rate - stats.min.rate;
    final pad = spread == 0 ? stats.max.rate * 0.001 : spread * 0.15;
    final totalDays = _x(end);
    final labelEvery = totalDays <= 7 ? 1.0 : 7.0;
    final weekly = points.length <= 8;

    return LineChart(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      LineChartData(
        minX: 0,
        maxX: totalDays,
        minY: stats.min.rate - pad,
        maxY: stats.max.rate + pad,
        lineBarsData: [
          LineChartBarData(
            spots: [for (final p in points) FlSpot(_x(p.date), p.rate)],
            gradient: LinearGradient(colors: gradient.colors),
            barWidth: 4,
            isCurved: true,
            curveSmoothness: 0.25,
            preventCurveOverShooting: true,
            isStrokeCapRound: true,
            dotData: FlDotData(
              // Every point on the weekly chart, only the last one monthly.
              checkToShowDot: (spot, bar) => weekly || spot == bar.spots.last,
              getDotPainter: (spot, _, bar, i) => FlDotCirclePainter(
                radius: spot == bar.spots.last ? 6 : 4,
                color: Theme.of(context).cardTheme.color ?? Colors.white,
                strokeWidth: 3,
                strokeColor: lineColor,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  lineColor.withValues(alpha: 0.35),
                  lineColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: stats.average,
              color: scheme.outline,
              strokeWidth: 1,
              dashArray: [6, 4],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                style: TextStyle(color: scheme.outline, fontSize: 11),
                labelResolver: (_) => 'среднее',
              ),
            ),
          ],
        ),
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
            strokeWidth: 1,
            dashArray: [4, 6],
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 64,
              getTitlesWidget: (value, meta) {
                if (value == meta.min || value == meta.max) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    value
                        .toStringAsFixed(rateDecimals(stats.max.rate))
                        .replaceAll('.', ','),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: labelEvery,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                // fl_chart always adds a label at maxX; skip it when it is
                // off the regular step, otherwise it overlaps its neighbour.
                if (value % labelEvery != 0) return const SizedBox.shrink();
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    fmtShortDate(start.add(Duration(days: value.round()))),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => scheme.inverseSurface,
            getTooltipItems: (spots) => [
              for (final s in spots)
                LineTooltipItem(
                  '${fmtDate(start.add(Duration(days: s.x.round())))}\n'
                  '${fmtRate(s.y)}',
                  TextStyle(color: scheme.onInverseSurface),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
