import 'package:intl/intl.dart';

final _dateTime = DateFormat('dd.MM.yyyy HH:mm');
final _date = DateFormat('dd.MM.yyyy');
final _shortDate = DateFormat('dd.MM');

String fmtDateTime(DateTime d) => _dateTime.format(d);
String fmtDate(DateTime d) => _date.format(d);
String fmtShortDate(DateTime d) => _shortDate.format(d);

/// Rates span from 0.0001 (e.g. IDR per X) to 10 000+; keep ~5 significant
/// digits so small moves stay visible.
int rateDecimals(double v) {
  final a = v.abs();
  if (a >= 1000) return 2;
  if (a >= 100) return 3;
  if (a >= 1) return 4;
  if (a >= 0.01) return 5;
  return 7;
}

String fmtRate(double v) => _withSpaces(v.toStringAsFixed(rateDecimals(v)));

/// Change with an explicit sign, in the same precision as [reference].
String fmtSignedRate(double v, double reference) {
  final s = v.abs().toStringAsFixed(rateDecimals(reference) + 1);
  return '${v < 0 ? '−' : '+'}${_withSpaces(s)}';
}

String fmtPercent(double v) {
  final s = v.abs().toStringAsFixed(2).replaceAll('.', ',');
  return '${v < 0 ? '−' : '+'}$s %';
}

String fmtAmount(double v) {
  final decimals = v.abs() >= 1 ? 2 : rateDecimals(v);
  return _withSpaces(v.toStringAsFixed(decimals));
}

/// `1234567.89` -> `1 234 567,89`.
String _withSpaces(String fixed) {
  final parts = fixed.split('.');
  final buf = StringBuffer();
  final digits = parts[0];
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(' ');
    buf.write(digits[i]);
  }
  if (parts.length > 1) buf.write(',${parts[1]}');
  return buf.toString();
}
