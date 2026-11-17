# Currency Trends — Lab 4

An Android app built with **Flutter (Dart)**: a currency converter with weekly and monthly exchange-rate comparison screens.

## Features

- **Converter.** Enter an amount (`100`, `12,5`, `1 500,50`), pick a currency pair, swap the currencies, see the direct and inverse rate.
- **Weekly comparison** (last 7 calendar days) and **monthly comparison** (last 30 days). Each screen shows:
  - a line chart of the rate by day, with the average marked as a dashed line;
  - the minimum and maximum with their dates, and the average value;
  - the change over the period in currency units and in percent;
  - an explicit trend: rising, falling or no change (threshold 0.01 %).
- **Offline mode.** The last successful responses are stored in `SharedPreferences` and survive app restarts. Without a network the app shows the saved data with an "offline" banner and the date and time the data was received.
- **Error handling.** No network, timeout, HTTP error, empty response, non-JSON body and malformed records all produce a clear message with a "Retry" button; the app never crashes.
- The selected pair is remembered between launches. Pull down on any screen to refresh.

The UI language is Russian.

Data source: [Frankfurter API](https://frankfurter.dev) — European Central Bank reference rates, free, no API key. Its limitations are described in [REPORT.md](REPORT.md).

## Requirements

- Flutter 3.x (tested with Flutter 3.47.5 / Dart 3.13.4)
- Android SDK and an emulator or a device running Android

## Run

```bash
flutter pub get
flutter emulators --launch Pixel_8a
flutter run
```

## Tests

All unit and widget tests run with one command:

```bash
flutter test
```

| File | What is tested |
|---|---|
| `test/frankfurter_parser_test.dart` | parsing API responses: currencies, latest rates, time series; malformed records, empty response, non-JSON |
| `test/period_stats_test.dart` | minimum, maximum, average, absolute and percent change, trend, empty data set, "last N days" window |
| `test/validation_test.dart` | amount and currency pair validation |
| `test/rates_repository_test.dart` | cache, offline fallback, surviving a restart, HTTP errors |
| `test/widget_test.dart` | screens end to end: conversion, weekly stats, offline without and with cache |

## Project structure

```
lib/
  main.dart                  entry point, bottom navigation
  app_controller.dart        selected pair, currency list, shared history request
  data/
    frankfurter_client.dart  HTTP requests, timeout, errors -> exceptions
    frankfurter_parser.dart  JSON -> models
    rates_cache.dart         persistent response cache
    rates_repository.dart    network first, cache as fallback
    models.dart, errors.dart
  domain/
    period_stats.dart        period statistics and trend
    validation.dart          input validation
  ui/
    converter_screen.dart, trend_screen.dart, rate_chart.dart, ...
```

## Git workflow

Each stage of the work has its own branch, merged into `main` through a Pull Request:

| Branch | Stage |
|---|---|
| `feature/data-layer` | models, parser, HTTP client, cache, repository |
| `feature/analytics` | statistics for the comparison screens |
| `feature/ui` | validation, converter, weekly and monthly screens |
| `docs/report` | README and REPORT.md |
| `feature/visual-redesign` | custom theme, gradients, currency picker, new chart style |
