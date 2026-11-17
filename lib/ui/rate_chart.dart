import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../data/models.dart';
import '../domain/period_stats.dart';
import 'format.dart';

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
    final lineColor = switch (stats.trend) {
      Trend.up => Colors.green.shade600,
      Trend.down => Colors.red.shade600,
      Trend.flat => scheme.primary,
    };
    final spread = stats.max.rate - stats.min.rate;
    final pad = spread == 0 ? stats.max.rate * 0.001 : spread * 0.15;
    final totalDays = _x(end);
    final labelEvery = totalDays <= 7 ? 1.0 : 7.0;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: totalDays,
        minY: stats.min.rate - pad,
        maxY: stats.max.rate + pad,
        lineBarsData: [
          LineChartBarData(
            spots: [for (final p in points) FlSpot(_x(p.date), p.rate)],
            color: lineColor,
            barWidth: 3,
            isCurved: false,
            dotData: FlDotData(show: points.length <= 31),
            belowBarData: BarAreaData(
              show: true,
              color: lineColor.withValues(alpha: 0.12),
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
        gridData: const FlGridData(drawVerticalLine: false),
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
