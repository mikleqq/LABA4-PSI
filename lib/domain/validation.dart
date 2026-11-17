/// Result of validating user input: either a [value] or an [error].
class Validated<T> {
  const Validated.ok(T this.value) : error = null;
  const Validated.fail(String this.error) : value = null;

  final T? value;
  final String? error;

  bool get isValid => error == null;
}

/// Largest amount accepted by the converter.
const maxAmount = 1e12;

/// Maximum number of digits after the decimal separator.
const maxFractionDigits = 6;

final _amountRe = RegExp(r'^\d+(\.\d+)?$');

/// Parses the amount typed by the user.
///
/// Accepts `1500`, `1 500,50`, `0.25`. Rejects empty input, letters,
/// signs, several separators, zero, more than [maxFractionDigits]
/// decimals and amounts above [maxAmount].
Validated<double> validateAmount(String input) {
  final normalized = input
      .trim()
      .replaceAll(RegExp(r'[\s  ]'), '')
      .replaceAll(',', '.');
  if (normalized.isEmpty) {
    return const Validated.fail('Введите сумму.');
  }
  if (!_amountRe.hasMatch(normalized)) {
    return const Validated.fail(
      'Сумма должна быть положительным числом, например 100 или 12,5.',
    );
  }
  final dot = normalized.indexOf('.');
  if (dot >= 0 && normalized.length - dot - 1 > maxFractionDigits) {
    return const Validated.fail(
      'Не больше $maxFractionDigits знаков после запятой.',
    );
  }
  final value = double.parse(normalized);
  if (value <= 0) {
    return const Validated.fail('Сумма должна быть больше нуля.');
  }
  if (value > maxAmount) {
    return const Validated.fail('Слишком большая сумма (максимум 10¹²).');
  }
  return Validated.ok(value);
}

final _codeRe = RegExp(r'^[A-Z]{3}$');

bool isCurrencyCode(String code) => _codeRe.hasMatch(code);

/// A pair is valid for the analytics screens when both codes are ISO-like
/// and differ (a currency against itself is always 1).
String? validatePair(String base, String quote) {
  if (!isCurrencyCode(base) || !isCurrencyCode(quote)) {
    return 'Неверный код валюты.';
  }
  if (base == quote) {
    return 'Выберите две разные валюты.';
  }
  return null;
}
