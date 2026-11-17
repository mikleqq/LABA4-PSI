import 'dart:io';

import 'package:currency_trends/data/errors.dart';
import 'package:currency_trends/data/frankfurter_client.dart';
import 'package:currency_trends/data/rates_cache.dart';
import 'package:currency_trends/data/rates_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _latestBody =
    '{"amount":1.0,"base":"USD","date":"2026-11-17","rates":{"EUR":0.91}}';

void main() {
  late RatesCache cache;
  final t1 = DateTime(2026, 11, 17, 12, 30);
  final t2 = DateTime(2026, 11, 18, 9, 0);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    cache = RatesCache(await SharedPreferences.getInstance());
  });

  RatesRepository repo(MockClientHandler handler, DateTime now) =>
      RatesRepository(
        client: FrankfurterClient(httpClient: MockClient(handler)),
        cache: cache,
        now: () => now,
      );

  Future<http.Response> ok(http.Request _) async =>
      http.Response(_latestBody, 200);
  Future<http.Response> offline(http.Request _) async =>
      throw const SocketException('no network');

  test('fresh data is returned and cached', () async {
    final r = await repo(ok, t1).latest('USD');
    expect(r.fromCache, isFalse);
    expect(r.fetchedAt, t1);
    expect(r.data.rateFor('EUR'), 0.91);
    expect(cache.get(RatesCache.latestKey('USD'))?.savedAt, t1);
  });

  test('offline falls back to cache with original timestamp', () async {
    await repo(ok, t1).latest('USD');
    final r = await repo(offline, t2).latest('USD');
    expect(r.fromCache, isTrue);
    expect(r.fetchedAt, t1, reason: 'date of the cached data, not now');
    expect(r.error, isA<NetworkException>());
    expect(r.data.rateFor('EUR'), 0.91);
  });

  test('cache survives restart (new prefs instance)', () async {
    await repo(ok, t1).latest('USD');
    cache = RatesCache(await SharedPreferences.getInstance());
    final r = await repo(offline, t2).latest('USD');
    expect(r.fromCache, isTrue);
  });

  test('offline with empty cache rethrows NetworkException', () {
    expect(
      repo(offline, t1).latest('USD'),
      throwsA(isA<NetworkException>()),
    );
  });

  test('HTTP error maps to SourceException with details', () async {
    final r = repo(
      (_) async => http.Response('{"message":"not found"}', 404),
      t1,
    );
    await expectLater(
      r.latest('XXX'),
      throwsA(
        isA<SourceException>()
            .having((e) => e.statusCode, 'statusCode', 404)
            .having((e) => e.message, 'message', contains('not found')),
      ),
    );
  });

  test('malformed response does not overwrite good cache', () async {
    await repo(ok, t1).latest('USD');
    final r = await repo((_) async => http.Response('garbage', 200), t2)
        .latest('USD');
    expect(r.fromCache, isTrue);
    expect(r.error, isA<DataFormatException>());
    expect(cache.get(RatesCache.latestKey('USD'))?.savedAt, t1);
  });

  test('history requests a 30-day window ending today', () async {
    late Uri requested;
    final r = await repo((req) async {
      requested = req.url;
      return http.Response(
        '{"base":"USD","rates":{"2026-11-17":{"EUR":0.91}}}',
        200,
      );
    }, t1).history('USD', 'EUR');
    expect(requested.path, endsWith('/2026-10-19..2026-11-17'));
    expect(requested.queryParameters, {'base': 'USD', 'symbols': 'EUR'});
    expect(r.data.points, hasLength(1));
  });

  test('empty history is an error and falls back to cache', () async {
    final empty = repo(
      (_) async => http.Response('{"base":"USD","rates":{}}', 200),
      t1,
    );
    await expectLater(
      empty.history('USD', 'EUR'),
      throwsA(isA<EmptyDataException>()),
    );
  });
}
