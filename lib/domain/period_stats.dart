import '../data/models.dart';

enum Trend {
  up('Рост'),
  down('Падение'),
  flat('Без изменений');

  const Trend(this.label);

  final String label;
}

/// Summary of a rate series over a period.
class PeriodStats {
  const PeriodStats({
    required this.min,
    required this.max,
    required this.average,
    required this.first,
    required this.last,
    required this.absoluteChange,
    required this.percentChange,
    required this.trend,
    required this.count,
  });

  /// Lowest / highest point (rate and the day it happened).
  final RatePoint min;
  final RatePoint max;
  final double average;

  /// First and last day of the period that have a rate.
  final RatePoint first;
  final RatePoint last;

  /// `last - first`, in quote currency units.
  final double absoluteChange;

  /// `(last - first) / first * 100`.
  final double percentChange;
  final Trend trend;

  /// Number of days with data.
  final int count;
}

/// Changes smaller than this (in percent) are reported as [Trend.flat], so
/// floating-point noise like 0.910000001 vs 0.91 is not called "growth".
const flatThresholdPercent = 0.01;

/// Computes statistics for [points]. Returns null for an empty list.
/// Points with a non-finite or non-positive rate are ignored.
PeriodStats? computeStats(
  List<RatePoint> points, {
  double flatThreshold = flatThresholdPercent,
}) {
  final valid = points.where((p) => p.rate.isFinite && p.rate > 0).toList()
    ..sort((a, b) => a.date.compareTo(b.date));
  if (valid.isEmpty) return null;

  var min = valid.first;
  var max = valid.first;
  var sum = 0.0;
  for (final p in valid) {
    if (p.rate < min.rate) min = p;
    if (p.rate > max.rate) max = p;
    sum += p.rate;
  }

  final first = valid.first;
  final last = valid.last;
  final abs = last.rate - first.rate;
  final pct = abs / first.rate * 100;

  final Trend trend;
  if (pct.abs() < flatThreshold) {
    trend = Trend.flat;
  } else {
    trend = pct > 0 ? Trend.up : Trend.down;
  }

  return PeriodStats(
    min: min,
    max: max,
    average: sum / valid.length,
    first: first,
    last: last,
    absoluteChange: abs,
    percentChange: pct,
    trend: trend,
    count: valid.length,
  );
}

/// Points that fall into the last [days] calendar days ending at [end]
/// (inclusive). For `days: 7, end: 17 Nov` that is 11..17 Nov.
List<RatePoint> lastDays(List<RatePoint> points, int days, DateTime end) {
  if (days <= 0) return const [];
  final to = dateOnly(end);
  final from = to.subtract(Duration(days: days - 1));
  return points
      .where((p) => !p.date.isBefore(from) && !p.date.isAfter(to))
      .toList();
}
