import 'package:currency_trends/data/models.dart';
import 'package:currency_trends/domain/period_stats.dart';
import 'package:flutter_test/flutter_test.dart';

RatePoint p(int day, double rate) => RatePoint(DateTime(2026, 11, day), rate);

void main() {
  group('computeStats', () {
    test('min, max, average, change for a rising series', () {
      final s = computeStats([
        p(10, 0.90),
        p(11, 0.88),
        p(12, 0.95),
        p(13, 0.99),
      ])!;
      expect(s.min, p(11, 0.88));
      expect(s.max, p(13, 0.99));
      expect(s.average, closeTo(0.93, 1e-12));
      expect(s.first, p(10, 0.90));
      expect(s.last, p(13, 0.99));
      expect(s.absoluteChange, closeTo(0.09, 1e-12));
      expect(s.percentChange, closeTo(10.0, 1e-9));
      expect(s.trend, Trend.up);
      expect(s.count, 4);
    });

    test('falling series', () {
      final s = computeStats([p(10, 100), p(17, 80)])!;
      expect(s.absoluteChange, -20);
      expect(s.percentChange, closeTo(-20, 1e-12));
      expect(s.trend, Trend.down);
    });

    test('unsorted input is sorted by date before first/last', () {
      final s = computeStats([p(13, 2), p(10, 1)])!;
      expect(s.first.date.day, 10);
      expect(s.last.date.day, 13);
      expect(s.percentChange, 100);
    });

    test('equal first and last is flat even if it moved inside', () {
      final s = computeStats([p(10, 1), p(11, 2), p(12, 1)])!;
      expect(s.absoluteChange, 0);
      expect(s.percentChange, 0);
      expect(s.trend, Trend.flat);
    });

    test('change below threshold is flat', () {
      final s = computeStats([p(10, 1.0), p(11, 1.00005)])!; // 0.005 %
      expect(s.trend, Trend.flat);
      expect(s.percentChange, closeTo(0.005, 1e-9));
    });

    test('single point: min == max == average, no change', () {
      final s = computeStats([p(10, 0.91)])!;
      expect(s.min, s.max);
      expect(s.average, 0.91);
      expect(s.absoluteChange, 0);
      expect(s.percentChange, 0);
      expect(s.trend, Trend.flat);
      expect(s.count, 1);
    });

    test('empty list gives null', () {
      expect(computeStats([]), isNull);
    });

    test('invalid rates are ignored; only invalid gives null', () {
      expect(computeStats([p(10, 0), p(11, -1), p(12, double.nan)]), isNull);
      final s = computeStats([p(10, 0), p(11, 2), p(12, double.infinity)])!;
      expect(s.count, 1);
      expect(s.min.rate, 2);
    });
  });

  group('lastDays', () {
    final all = [for (var d = 1; d <= 17; d++) p(d, d.toDouble())];

    test('7 days ending on 17th is 11..17 inclusive', () {
      final week = lastDays(all, 7, DateTime(2026, 11, 17, 23, 59));
      expect(week.map((e) => e.date.day), [11, 12, 13, 14, 15, 16, 17]);
    });

    test('window larger than data returns everything', () {
      expect(lastDays(all, 30, DateTime(2026, 11, 17)), hasLength(17));
    });

    test('window with no data returns empty, stats are null', () {
      final w = lastDays(all, 7, DateTime(2026, 12, 31));
      expect(w, isEmpty);
      expect(computeStats(w), isNull);
    });

    test('non-positive window is empty', () {
      expect(lastDays(all, 0, DateTime(2026, 11, 17)), isEmpty);
    });
  });
}
