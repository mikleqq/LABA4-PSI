import 'errors.dart';

/// Exchange rate of one currency pair on one day.
class RatePoint {
  const RatePoint(this.date, this.rate);

  /// Calendar day (time part is always midnight, local).
  final DateTime date;

  /// How many units of the quote currency one unit of the base buys.
  final double rate;

  @override
  bool operator ==(Object other) =>
      other is RatePoint && other.date == date && other.rate == rate;

  @override
  int get hashCode => Object.hash(date, rate);

  @override
  String toString() => 'RatePoint($date, $rate)';
}

/// Latest rates of one base currency against all others.
class LatestRates {
  const LatestRates({
    required this.base,
    required this.date,
    required this.rates,
  });

  final String base;

  /// The day the central bank published these rates.
  final DateTime date;

  /// Quote currency code -> rate.
  final Map<String, double> rates;

  double? rateFor(String quote) => quote == base ? 1.0 : rates[quote];
}

/// A rate history for one pair over the requested window.
class RateSeries {
  const RateSeries({
    required this.base,
    required this.quote,
    required this.points,
    this.skipped = 0,
  });

  final String base;
  final String quote;

  /// Sorted by date ascending.
  final List<RatePoint> points;

  /// Number of malformed entries the parser dropped.
  final int skipped;
}

/// Data plus where it came from. When [fromCache] is true, [error]
/// explains why fresh data could not be fetched.
class Loaded<T> {
  const Loaded({
    required this.data,
    required this.fetchedAt,
    required this.fromCache,
    this.error,
  });

  final T data;

  /// When this data was successfully received from the network.
  final DateTime fetchedAt;
  final bool fromCache;
  final AppException? error;
}

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
