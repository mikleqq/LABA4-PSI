import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../data/errors.dart';
import '../data/models.dart';
import 'format.dart';

String errorText(Object error) =>
    error is AppException ? error.message : 'Неизвестная ошибка: $error';

/// Shows when the data was received and, for cached data, why the network
/// copy is not shown.
class FreshnessBanner extends StatelessWidget {
  const FreshnessBanner({super.key, required this.loaded, this.dataDate});

  final Loaded<Object?> loaded;

  /// The date the rates themselves refer to (ECB publication day).
  final DateTime? dataDate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dataLine = dataDate == null ? '' : 'Курс на ${fmtDate(dataDate!)}. ';
    if (!loaded.fromCache) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          '$dataLineОбновлено ${fmtDateTime(loaded.fetchedAt)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }
    return Card(
      color: scheme.tertiaryContainer,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.cloud_off, color: scheme.onTertiaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Офлайн-режим: показаны сохранённые данные от '
                '${fmtDateTime(loaded.fetchedAt)}. $dataLine\n'
                '${loaded.error == null ? '' : errorText(loaded.error!)}',
                style: TextStyle(color: scheme.onTertiaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Повторить'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// "USD ⇄ EUR" selector shared by all screens.
class PairSelector extends StatelessWidget {
  const PairSelector({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Row(
        children: [
          Expanded(
            child: _CurrencyDropdown(
              label: 'Из',
              value: controller.base,
              currencies: controller.currencies,
              onChanged: controller.setBase,
            ),
          ),
          IconButton(
            tooltip: 'Поменять местами',
            onPressed: controller.swap,
            icon: const Icon(Icons.swap_horiz),
          ),
          Expanded(
            child: _CurrencyDropdown(
              label: 'В',
              value: controller.quote,
              currencies: controller.currencies,
              onChanged: controller.setQuote,
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrencyDropdown extends StatelessWidget {
  const _CurrencyDropdown({
    required this.label,
    required this.value,
    required this.currencies,
    required this.onChanged,
  });

  final String label;
  final String value;
  final Map<String, String> currencies;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    // The saved pair may not be in the fallback list; keep it selectable.
    final items = {value: currencies[value] ?? value, ...currencies};
    return DropdownButtonFormField<String>(
      initialValue: value,
      key: ValueKey('$label-$value-${items.length}'),
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      selectedItemBuilder: (_) => [
        for (final code in items.keys) Text(code, overflow: TextOverflow.fade),
      ],
      items: [
        for (final e in items.entries)
          DropdownMenuItem(
            value: e.key,
            child: Text(
              '${e.key} — ${e.value}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
