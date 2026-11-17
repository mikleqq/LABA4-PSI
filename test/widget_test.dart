import 'dart:io';

import 'package:currency_trends/app_controller.dart';
import 'package:currency_trends/data/frankfurter_client.dart';
import 'package:currency_trends/data/rates_cache.dart';
import 'package:currency_trends/data/rates_repository.dart';
import 'package:currency_trends/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final now = DateTime(2026, 11, 17, 18);

  Future<AppController> controller(MockClientHandler handler) async {
    final prefs = await SharedPreferences.getInstance();
    final repo = RatesRepository(
      client: FrankfurterClient(httpClient: MockClient(handler)),
      cache: RatesCache(prefs),
      now: () => now,
    );
    return AppController(repo, prefs);
  }

  Future<http.Response> online(http.Request r) async {
    if (r.url.path.endsWith('/latest')) {
      return http.Response(
        '{"base":"USD","date":"2026-11-17","rates":{"EUR":0.9}}',
        200,
      );
    }
    return http.Response(
      '{"base":"USD","rates":{"2026-11-11":{"EUR":0.8},'
      '"2026-11-17":{"EUR":0.9}}}',
      200,
    );
  }

  Future<http.Response> offline(http.Request _) async =>
      throw const SocketException('offline');

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('converts amount and validates input', (tester) async {
    await tester.pumpWidget(CurrencyApp(controller: await controller(online)));
    await tester.pumpAndSettle();
    expect(find.textContaining('90,00 EUR'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'abc');
    await tester.pump();
    expect(find.textContaining('положительным числом'), findsOneWidget);
  });

  testWidgets('week screen shows trend and stats', (tester) async {
    await tester.pumpWidget(CurrencyApp(controller: await controller(online)));
    await tester.tap(find.text('Неделя').last);
    await tester.pumpAndSettle();
    expect(find.text('Тенденция: Рост'), findsOneWidget);
    expect(find.text('Минимум'), findsOneWidget);
    expect(find.text('Максимум'), findsOneWidget);
    expect(find.text('Среднее'), findsOneWidget);
    expect(find.textContaining('+12,50 %'), findsWidgets);
  });

  testWidgets('offline without cache shows error, no crash', (tester) async {
    await tester.pumpWidget(
      CurrencyApp(controller: await controller(offline)),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Нет подключения'), findsOneWidget);
    expect(find.text('Повторить'), findsOneWidget);
  });

  testWidgets('offline with cache shows cached data and its date', (
    tester,
  ) async {
    // First launch online fills the cache.
    await tester.pumpWidget(CurrencyApp(controller: await controller(online)));
    await tester.pumpAndSettle();
    // "Restart" offline.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      CurrencyApp(controller: await controller(offline)),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Офлайн-режим'), findsOneWidget);
    expect(find.textContaining('17.11.2026 18:00'), findsOneWidget);
    expect(find.textContaining('90,00 EUR'), findsOneWidget);
  });
}
