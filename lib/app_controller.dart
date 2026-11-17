import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/models.dart';
import 'data/rates_repository.dart';
import 'domain/validation.dart';

/// Shared state of the app: the list of currencies and the selected pair.
/// The pair is remembered between launches.
class AppController extends ChangeNotifier {
  AppController(this.repository, this._prefs) {
    final saved = _prefs.getStringList(_pairKey);
    if (saved != null &&
        saved.length == 2 &&
        isCurrencyCode(saved[0]) &&
        isCurrencyCode(saved[1])) {
      _base = saved[0];
      _quote = saved[1];
    }
  }

  final RatesRepository repository;
  final SharedPreferences _prefs;

  static const _pairKey = 'selected_pair';

  /// Used until the real list is loaded, and when it cannot be loaded at
  /// all (first launch without network).
  static const fallbackCurrencies = {
    'EUR': 'Euro',
    'USD': 'United States Dollar',
    'GBP': 'British Pound',
    'CHF': 'Swiss Franc',
    'JPY': 'Japanese Yen',
    'CNY': 'Chinese Renminbi Yuan',
    'PLN': 'Polish Złoty',
    'RON': 'Romanian Leu',
    'TRY': 'Turkish Lira',
  };

  Map<String, String> _currencies = fallbackCurrencies;
  Map<String, String> get currencies => _currencies;

  String _base = 'USD';
  String _quote = 'EUR';
  String get base => _base;
  String get quote => _quote;
  String get pairKey => '$_base/$_quote';

  final Map<String, Future<Loaded<RateSeries>>> _history = {};

  Future<void> loadCurrencies() async {
    try {
      final loaded = await repository.currencies();
      _currencies = Map.fromEntries(
        loaded.data.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
      );
      notifyListeners();
    } catch (_) {
      // Keep the fallback list; screens report network problems themselves.
    }
  }

  void setBase(String code) => _setPair(code, _quote);
  void setQuote(String code) => _setPair(_base, code);
  void swap() => _setPair(_quote, _base);
  void setPair(String base, String quote) => _setPair(base, quote);

  void _setPair(String base, String quote) {
    if (base == _base && quote == _quote) return;
    _base = base;
    _quote = quote;
    _prefs.setStringList(_pairKey, [base, quote]);
    notifyListeners();
  }

  /// 30-day history of the selected pair. Memoized per pair for the session
  /// so the weekly and monthly screens share one request.
  Future<Loaded<RateSeries>> history({bool refresh = false}) {
    final key = pairKey;
    if (refresh) _history.remove(key);
    final future = _history.putIfAbsent(
      key,
      () => repository.history(_base, _quote),
    );
    // Do not keep failures memoized, so "retry" actually retries.
    future.then<void>(
      (_) {},
      onError: (Object _) {
        if (identical(_history[key], future)) _history.remove(key);
      },
    );
    return future;
  }
}
