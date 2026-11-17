import 'package:currency_trends/data/errors.dart';
import 'package:currency_trends/data/frankfurter_parser.dart';
import 'package:currency_trends/data/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = FrankfurterParser();

  group('parseCurrencies', () {
    test('reads code -> name map', () {
      final result = parser.parseCurrencies(
        '{"EUR":"Euro","USD":"United States Dollar"}',
      );
      expect(result, {'EUR': 'Euro', 'USD': 'United States Dollar'});
    });

    test('drops entries with invalid code or name', () {
      final result = parser.parseCurrencies(
        '{"EUR":"Euro","usd":"lower","GBPX":"long","JPY":5,"CHF":""}',
      );
      expect(result, {'EUR': 'Euro'});
    });

    test('empty object is EmptyDataException', () {
      expect(
        () => parser.parseCurrencies('{}'),
        throwsA(isA<EmptyDataException>()),
      );
    });
  });

  group('parseLatest', () {
    test('reads base, date and rates', () {
      final r = parser.parseLatest(
        '{"amount":1.0,"base":"USD","date":"2026-11-17",'
        '"rates":{"EUR":0.91,"JPY":154}}',
      );
      expect(r.base, 'USD');
      expect(r.date, DateTime(2026, 11, 17));
      expect(r.rates, {'EUR': 0.91, 'JPY': 154.0});
      expect(r.rateFor('EUR'), 0.91);
      expect(r.rateFor('USD'), 1.0, reason: 'same currency');
      expect(r.rateFor('XXX'), isNull);
    });

    test('skips non-numeric, zero and negative rates', () {
      final r = parser.parseLatest(
        '{"base":"USD","date":"2026-11-17",'
        '"rates":{"EUR":0.91,"GBP":"0.8","CHF":0,"JPY":-1,"PLN":null}}',
      );
      expect(r.rates.keys, ['EUR']);
    });

    test('all rates invalid is EmptyDataException', () {
      expect(
        () => parser.parseLatest(
          '{"base":"USD","date":"2026-11-17","rates":{}}',
        ),
        throwsA(isA<EmptyDataException>()),
      );
    });

    test('missing base, date or rates is DataFormatException', () {
      for (final body in [
        '{"date":"2026-11-17","rates":{"EUR":1}}',
        '{"base":"USD","rates":{"EUR":1}}',
        '{"base":"USD","date":"17.11.2026","rates":{"EUR":1}}',
        '{"base":"USD","date":"2026-02-31","rates":{"EUR":1}}',
        '{"base":"USD","date":"2026-11-17"}',
        '{"base":"USD","date":"2026-11-17","rates":[1,2]}',
      ]) {
        expect(
          () => parser.parseLatest(body),
          throwsA(isA<DataFormatException>()),
          reason: body,
        );
      }
    });
  });

  group('parseTimeSeries', () {
    const body =
        '{"amount":1.0,"base":"USD","start_date":"2026-11-10",'
        '"end_date":"2026-11-17","rates":{'
        '"2026-11-13":{"EUR":0.90481},'
        '"2026-11-10":{"EUR":0.89174},'
        '"2026-11-11":{"EUR":0.89871}}}';

    test('reads points sorted by date', () {
      final s = parser.parseTimeSeries(body, quote: 'EUR');
      expect(s.base, 'USD');
      expect(s.quote, 'EUR');
      expect(s.points, [
        RatePoint(DateTime(2026, 11, 10), 0.89174),
        RatePoint(DateTime(2026, 11, 11), 0.89871),
        RatePoint(DateTime(2026, 11, 13), 0.90481),
      ]);
      expect(s.skipped, 0);
    });

    test('skips malformed days and counts them', () {
      final s = parser.parseTimeSeries(
        '{"base":"USD","rates":{'
        '"2026-11-10":{"EUR":0.9},'
        '"2026-11-11":{"GBP":0.8},'
        '"bad-date":{"EUR":0.9},'
        '"2026-11-12":{"EUR":"x"},'
        '"2026-11-13":"oops"}}',
        quote: 'EUR',
      );
      expect(s.points, [RatePoint(DateTime(2026, 11, 10), 0.9)]);
      expect(s.skipped, 4);
    });

    test('no days gives an empty series, not an error', () {
      final s = parser.parseTimeSeries(
        '{"base":"USD","rates":{}}',
        quote: 'EUR',
      );
      expect(s.points, isEmpty);
    });
  });

  group('malformed bodies', () {
    test('empty body is EmptyDataException', () {
      expect(
        () => parser.parseLatest('   '),
        throwsA(isA<EmptyDataException>()),
      );
    });

    test('non-JSON is DataFormatException', () {
      expect(
        () => parser.parseLatest('<html>502 Bad Gateway</html>'),
        throwsA(isA<DataFormatException>()),
      );
    });

    test('JSON array is DataFormatException', () {
      expect(
        () => parser.parseCurrencies('["EUR"]'),
        throwsA(isA<DataFormatException>()),
      );
    });
  });
}
