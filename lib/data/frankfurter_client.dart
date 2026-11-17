import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'errors.dart';

/// Thin HTTP wrapper over https://frankfurter.dev (ECB reference rates,
/// free, no API key). Returns raw bodies; parsing is done elsewhere so the
/// same body can be cached and re-parsed after a restart.
class FrankfurterClient {
  FrankfurterClient({
    http.Client? httpClient,
    this.baseUrl = 'https://api.frankfurter.dev/v1',
    this.timeout = const Duration(seconds: 10),
  }) : _http = httpClient ?? http.Client();

  final http.Client _http;
  final String baseUrl;
  final Duration timeout;

  static final _day = DateFormat('yyyy-MM-dd');

  Future<String> fetchCurrencies() => _get('/currencies');

  Future<String> fetchLatest(String base) => _get('/latest', {'base': base});

  Future<String> fetchTimeSeries({
    required String base,
    required String quote,
    required DateTime start,
    required DateTime end,
  }) => _get('/${_day.format(start)}..${_day.format(end)}', {
    'base': base,
    'symbols': quote,
  });

  Future<String> _get(String path, [Map<String, String>? query]) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final http.Response response;
    try {
      response = await _http.get(uri).timeout(timeout);
    } on TimeoutException {
      throw const NetworkException('Сервер не ответил вовремя.');
    } on SocketException {
      throw const NetworkException();
    } on http.ClientException {
      throw const NetworkException();
    } on HandshakeException {
      throw const NetworkException('Ошибка защищённого соединения.');
    }
    if (response.statusCode != 200) {
      throw SourceException(response.statusCode, _errorDetails(response));
    }
    return utf8.decode(response.bodyBytes);
  }

  /// Frankfurter answers errors as `{"message": "not found"}`.
  String? _errorDetails(http.Response r) {
    try {
      final json = jsonDecode(utf8.decode(r.bodyBytes));
      if (json is Map && json['message'] is String) return json['message'];
    } catch (_) {}
    return null;
  }

  void close() => _http.close();
}
