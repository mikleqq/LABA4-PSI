import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A raw response body saved together with the moment it was received.
class CacheEntry {
  const CacheEntry(this.body, this.savedAt);

  final String body;
  final DateTime savedAt;
}

/// Persistent key-value cache of raw API responses (SharedPreferences,
/// survives app restarts). Bodies are stored unparsed and re-parsed on
/// read, so a corrupted entry is detected by the same parser.
class RatesCache {
  RatesCache(this._prefs);

  final SharedPreferences _prefs;

  static const _prefix = 'cache:';

  static String currenciesKey() => 'currencies';
  static String latestKey(String base) => 'latest:$base';
  static String seriesKey(String base, String quote) =>
      'series:$base:$quote';

  Future<void> put(String key, String body, DateTime savedAt) =>
      _prefs.setString(
        '$_prefix$key',
        jsonEncode({'savedAt': savedAt.toIso8601String(), 'body': body}),
      );

  /// Returns null when nothing is cached or the entry is unreadable.
  CacheEntry? get(String key) {
    final raw = _prefs.getString('$_prefix$key');
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return CacheEntry(
        json['body'] as String,
        DateTime.parse(json['savedAt'] as String),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> remove(String key) => _prefs.remove('$_prefix$key');
}
