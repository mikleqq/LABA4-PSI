import 'errors.dart';
import 'frankfurter_client.dart';
import 'frankfurter_parser.dart';
import 'models.dart';
import 'rates_cache.dart';

/// Network first, cache as fallback.
///
/// A successful, valid response is cached and returned with
/// `fromCache: false`. If the request or parsing fails, the last good
/// cached response is returned with `fromCache: true` and the error that
/// caused the fallback. With nothing cached the error is rethrown.
class RatesRepository {
  RatesRepository({
    required this._client,
    required this._cache,
    this._parser = const FrankfurterParser(),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final FrankfurterClient _client;
  final RatesCache _cache;
  final FrankfurterParser _parser;
  final DateTime Function() _now;

  /// How many calendar days of history are downloaded. Both the weekly and
  /// the monthly screen are cut from this one series.
  static const historyDays = 30;

  Future<Loaded<Map<String, String>>> currencies() => _load(
    RatesCache.currenciesKey(),
    _client.fetchCurrencies,
    _parser.parseCurrencies,
  );

  Future<Loaded<LatestRates>> latest(String base) => _load(
    RatesCache.latestKey(base),
    () => _client.fetchLatest(base),
    _parser.parseLatest,
  );

  /// Rates of [base]/[quote] for the last [historyDays] calendar days
  /// (today included).
  Future<Loaded<RateSeries>> history(String base, String quote) {
    final end = dateOnly(_now());
    final start = end.subtract(const Duration(days: historyDays - 1));
    return _load(
      RatesCache.seriesKey(base, quote),
      () => _client.fetchTimeSeries(
        base: base,
        quote: quote,
        start: start,
        end: end,
      ),
      (body) {
        final series = _parser.parseTimeSeries(body, quote: quote);
        if (series.points.isEmpty) {
          throw const EmptyDataException('Нет курсов за выбранный период.');
        }
        return series;
      },
    );
  }

  Future<Loaded<T>> _load<T>(
    String key,
    Future<String> Function() fetch,
    T Function(String body) parse,
  ) async {
    try {
      final body = await fetch();
      final data = parse(body); // validate before overwriting the cache
      final now = _now();
      await _cache.put(key, body, now);
      return Loaded(data: data, fetchedAt: now, fromCache: false);
    } on AppException catch (error) {
      final cached = _cache.get(key);
      if (cached != null) {
        try {
          return Loaded(
            data: parse(cached.body),
            fetchedAt: cached.savedAt,
            fromCache: true,
            error: error,
          );
        } on AppException {
          await _cache.remove(key); // corrupted entry, drop it
        }
      }
      rethrow;
    }
  }
}
