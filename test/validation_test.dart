import 'package:currency_trends/domain/validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validateAmount accepts', () {
    for (final (input, expected) in [
      ('100', 100.0),
      ('0.25', 0.25),
      ('12,5', 12.5),
      ('  42  ', 42.0),
      ('1 500,50', 1500.5),
      ('1 000', 1000.0),
      ('0.000001', 0.000001),
      ('1000000000000', 1e12),
    ]) {
      test('"$input" -> $expected', () {
        final r = validateAmount(input);
        expect(r.isValid, isTrue, reason: r.error);
        expect(r.value, expected);
      });
    }
  });

  group('validateAmount rejects', () {
    for (final (input, why) in [
      ('', 'empty'),
      ('   ', 'blank'),
      ('abc', 'letters'),
      ('12a', 'trailing letter'),
      ('-5', 'negative'),
      ('+5', 'plus sign'),
      ('1.2.3', 'two separators'),
      ('1,2.3', 'mixed separators'),
      ('.5', 'no integer part'),
      ('5.', 'no fraction digits'),
      ('0', 'zero'),
      ('0,000', 'zero with decimals'),
      ('0.0000001', 'too many decimals'),
      ('1000000000001', 'above max'),
      ('1e5', 'exponent'),
    ]) {
      test('"$input" ($why)', () {
        final r = validateAmount(input);
        expect(r.isValid, isFalse);
        expect(r.value, isNull);
        expect(r.error, isNotEmpty);
      });
    }
  });

  test('error messages are specific', () {
    expect(validateAmount('').error, 'Введите сумму.');
    expect(validateAmount('0').error, 'Сумма должна быть больше нуля.');
    expect(validateAmount('1.1234567').error, contains('знаков'));
    expect(validateAmount('9' * 14).error, contains('большая'));
  });

  group('currency codes and pairs', () {
    test('isCurrencyCode', () {
      expect(isCurrencyCode('USD'), isTrue);
      expect(isCurrencyCode('usd'), isFalse);
      expect(isCurrencyCode('US'), isFalse);
      expect(isCurrencyCode('USDT'), isFalse);
    });

    test('validatePair', () {
      expect(validatePair('USD', 'EUR'), isNull);
      expect(validatePair('USD', 'USD'), contains('разные'));
      expect(validatePair('USD', 'eur'), contains('код'));
    });
  });
}
