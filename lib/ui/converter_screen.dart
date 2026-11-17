import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../data/models.dart';
import '../domain/validation.dart';
import 'common_widgets.dart';
import 'format.dart';

class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  final _amount = TextEditingController(text: '100');
  Loaded<LatestRates>? _latest;
  Object? _error;
  bool _loading = false;
  String? _loadedBase;

  AppController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _c.addListener(_onPairChanged);
    _amount.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _c.removeListener(_onPairChanged);
    _amount.dispose();
    super.dispose();
  }

  void _onPairChanged() {
    // Latest rates are per base; changing only the quote needs no request.
    if (_c.base != _loadedBase) _load();
    setState(() {});
  }

  Future<void> _load() async {
    final base = _c.base;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _c.repository.latest(base);
      if (!mounted || base != _c.base) return;
      setState(() {
        _latest = result;
        _loadedBase = base;
      });
    } catch (e) {
      if (!mounted || base != _c.base) return;
      setState(() {
        _error = e;
        _latest = null;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final validation = validateAmount(_amount.text);
    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([_load(), _c.loadCurrencies()]);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Сумма',
              border: const OutlineInputBorder(),
              errorText: validation.error,
              suffixText: _c.base,
            ),
          ),
          const SizedBox(height: 16),
          PairSelector(controller: _c),
          const SizedBox(height: 16),
          if (_loading) const LinearProgressIndicator(),
          if (_error != null)
            ErrorView(message: errorText(_error!), onRetry: _load)
          else if (_latest != null)
            _result(context, validation),
        ],
      ),
    );
  }

  Widget _result(BuildContext context, Validated<double> amount) {
    final latest = _latest!;
    final rate = latest.data.rateFor(_c.quote);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: rate == null
                ? Text(
                    'Источник не публикует курс ${_c.base}/${_c.quote}. '
                    'Выберите другую валюту.',
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (amount.isValid) ...[
                        Text(
                          '${fmtAmount(amount.value!)} ${_c.base} =',
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          '${fmtAmount(amount.value! * rate)} ${_c.quote}',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ] else
                        const Text('Введите корректную сумму для пересчёта.'),
                      const SizedBox(height: 8),
                      Text(
                        '1 ${_c.base} = ${fmtRate(rate)} ${_c.quote}',
                        style: theme.textTheme.bodyMedium,
                      ),
                      if (_c.base != _c.quote)
                        Text(
                          '1 ${_c.quote} = ${fmtRate(1 / rate)} ${_c.base}',
                          style: theme.textTheme.bodyMedium,
                        ),
                    ],
                  ),
          ),
        ),
        FreshnessBanner(loaded: latest, dataDate: latest.data.date),
        const SizedBox(height: 8),
        Text(
          'Источник: Frankfurter (справочные курсы ЕЦБ). '
          'Курсы публикуются в рабочие дни около 16:00 CET.',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}
