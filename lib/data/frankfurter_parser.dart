import 'dart:convert';

import 'errors.dart';
import 'models.dart';

/// Turns raw Frankfurter API responses into models.
///
/// Every function throws [DataFormatException] when the JSON does not have
/// the expected shape and [EmptyDataException] when it has no data at all.
class FrankfurterParser {
  const FrankfurterParser();

  /// `GET /currencies` -> `{"EUR": "Euro", "USD": "United States Dollar"}`.
  Map<String, String> parseCurrencies(String body) {
    final json = _decodeObject(body);
    final result = <String, String>{};
    json.forEach((code, name) {
      if (_isCurrencyCode(code) && name is String && name.isNotEmpty) {
        result[code] = name;
      }
    });
    if (result.isEmpty) {
      throw const EmptyDataException('Источник вернул пустой список валют.');
    }
    return result;
  }

  /// `GET /latest?base=USD` ->
  /// `{"amount":1.0,"base":"USD","date":"2026-11-17","rates":{"EUR":0.91}}`.
  LatestRates parseLatest(String body) {
    final json = _decodeObject(body);
    final base = json['base'];
    if (base is! String || !_isCurrencyCode(base)) {
      throw const DataFormatException('нет поля base');
    }
    final date = _parseDate(json['date']);
    if (date == null) {
      throw const DataFormatException('нет или неверное поле date');
    }
    final rawRates = json['rates'];
    if (rawRates is! Map) {
      throw const DataFormatException('нет поля rates');
    }
    final rates = <String, double>{};
    rawRates.forEach((code, value) {
      final rate = _parseRate(value);
      if (code is String && _isCurrencyCode(code) && rate != null) {
        rates[code] = rate;
      }
    });
    if (rates.isEmpty) {
      throw const EmptyDataException('Источник не вернул ни одного курса.');
    }
    return LatestRates(base: base, date: date, rates: rates);
  }

  /// `GET /2026-10-19..2026-11-17?base=USD&symbols=EUR` ->
  /// `{"base":"USD","start_date":..,"end_date":..,
  ///   "rates":{"2026-11-10":{"EUR":0.89},...}}`.
  ///
  /// Days with a missing or invalid rate are skipped and counted in
  /// [RateSeries.skipped]. A response without any days gives an empty
  /// series (not an error): weekends and holidays have no rates.
  RateSeries parseTimeSeries(String body, {required String quote}) {
    final json = _decodeObject(body);
    final base = json['base'];
    if (base is! String || !_isCurrencyCode(base)) {
      throw const DataFormatException('нет поля base');
    }
    final rawRates = json['rates'];
    if (rawRates is! Map) {
      throw const DataFormatException('нет поля rates');
    }
    final points = <RatePoint>[];
    var skipped = 0;
    rawRates.forEach((day, perDay) {
      final date = _parseDate(day);
      final rate = perDay is Map ? _parseRate(perDay[quote]) : null;
      if (date == null || rate == null) {
        skipped++;
      } else {
        points.add(RatePoint(date, rate));
      }
    });
    points.sort((a, b) => a.date.compareTo(b.date));
    return RateSeries(
      base: base,
      quote: quote,
      points: points,
      skipped: skipped,
    );
  }

  Map<String, dynamic> _decodeObject(String body) {
    if (body.trim().isEmpty) {
      throw const EmptyDataException();
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      throw const DataFormatException('ответ не является JSON');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const DataFormatException('ожидался JSON-объект');
    }
    return decoded;
  }

  static final _codeRe = RegExp(r'^[A-Z]{3}$');
  static final _dateRe = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  bool _isCurrencyCode(Object? s) => s is String && _codeRe.hasMatch(s);

  /// Accepts only real calendar days in `YYYY-MM-DD` form.
  DateTime? _parseDate(Object? raw) {
    if (raw is! String || !_dateRe.hasMatch(raw)) return null;
    final parts = raw.split('-').map(int.parse).toList();
    final d = DateTime(parts[0], parts[1], parts[2]);
    // DateTime silently rolls 2026-02-31 over to March; reject that.
    if (d.year != parts[0] || d.month != parts[1] || d.day != parts[2]) {
      return null;
    }
    return d;
  }

  double? _parseRate(Object? raw) {
    if (raw is! num) return null;
    final v = raw.toDouble();
    if (!v.isFinite || v <= 0) return null;
    return v;
  }
}
