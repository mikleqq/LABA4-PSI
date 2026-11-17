import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../data/errors.dart';
import '../data/models.dart';
import 'currency_picker.dart';
import 'format.dart';
import 'theme.dart';

String errorText(Object error) =>
    error is AppException ? error.message : 'Неизвестная ошибка: $error';

/// Large screen title with a small caption above it.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    required this.caption,
    this.onGradient = false,
  });

  final String title;
  final String caption;
  final bool onGradient;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final fg = onGradient ? Colors.white : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          caption.toUpperCase(),
          style: t.labelSmall?.copyWith(
            letterSpacing: 1.6,
            fontWeight: FontWeight.w700,
            color: onGradient
                ? Colors.white.withValues(alpha: 0.75)
                : AppColors.brand,
          ),
        ),
        const SizedBox(height: 4),
        Text(title, style: t.headlineMedium?.copyWith(color: fg)),
      ],
    );
  }
}

/// Shows when the data was received and, for cached data, why the network
/// copy is not shown.
class FreshnessBanner extends StatelessWidget {
  const FreshnessBanner({super.key, required this.loaded, this.dataDate});

  final Loaded<Object?> loaded;

  /// The date the rates themselves refer to (ECB publication day).
  final DateTime? dataDate;

  @override
  Widget build(BuildContext context) {
    final dataLine = dataDate == null ? '' : 'Курс на ${fmtDate(dataDate!)}. ';
    if (!loaded.fromCache) {
      return Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.up,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$dataLineОбновлено ${fmtDateTime(loaded.fetchedAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      );
    }
    const amber = Color(0xFFB45309);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFCD34D)),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFFDE68A),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cloud_off_rounded, color: amber, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Офлайн-режим: показаны сохранённые данные от '
              '${fmtDateTime(loaded.fetchedAt)}. $dataLine\n'
              '${loaded.error == null ? '' : errorText(loaded.error!)}',
              style: const TextStyle(color: Color(0xFF78350F), height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.wifi_off_rounded,
  });

  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SoftCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.errorContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: scheme.onErrorContainer),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brand,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Повторить'),
            ),
          ],
        ],
      ),
    );
  }
}

/// "🇺🇸 USD ⇄ 🇪🇺 EUR" selector used on the comparison screens.
class PairSelector extends StatelessWidget {
  const PairSelector({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => SoftCard(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Expanded(
              child: CurrencyPill(
                code: controller.base,
                expand: true,
                onTap: () => pickBase(context, controller),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: SwapButton(onPressed: controller.swap),
            ),
            Expanded(
              child: CurrencyPill(
                code: controller.quote,
                expand: true,
                onTap: () => pickQuote(context, controller),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> pickBase(BuildContext context, AppController c) async {
  final code = await showCurrencyPicker(
    context,
    currencies: c.currencies,
    selected: c.base,
    title: 'Из какой валюты',
  );
  if (code != null) c.setBase(code);
}

Future<void> pickQuote(BuildContext context, AppController c) async {
  final code = await showCurrencyPicker(
    context,
    currencies: c.currencies,
    selected: c.quote,
    title: 'В какую валюту',
  );
  if (code != null) c.setQuote(code);
}
