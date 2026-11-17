import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../data/models.dart';
import '../domain/validation.dart';
import 'common_widgets.dart';
import 'currency_picker.dart';
import 'format.dart';
import 'theme.dart';

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

  static const _popularPairs = [
    ('USD', 'EUR'),
    ('EUR', 'GBP'),
    ('EUR', 'CHF'),
    ('USD', 'JPY'),
    ('EUR', 'PLN'),
    ('GBP', 'USD'),
  ];

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
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([_load(), _c.loadCurrencies()]);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          _hero(context, validation),
          const SizedBox(height: 20),
          if (_error != null)
            ErrorView(message: errorText(_error!), onRetry: _load)
          else if (_latest != null) ...[
            FreshnessBanner(loaded: _latest!, dataDate: _latest!.data.date),
            const SizedBox(height: 16),
            _rateDetails(context),
          ],
          const SizedBox(height: 20),
          Text('Популярные пары', style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (b, q) in _popularPairs)
                _PairChip(
                  base: b,
                  quote: q,
                  selected: _c.base == b && _c.quote == q,
                  onTap: () => _c.setPair(b, q),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Источник: Frankfurter (справочные курсы ЕЦБ). '
            'Курсы публикуются в рабочие дни около 16:00 CET.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultText(Validated<double> amount) {
    final rate = _latest?.data.rateFor(_c.quote);
    if (_latest == null) {
      return Text(
        _loading ? 'Загрузка…' : '—',
        key: const ValueKey('empty'),
        style: const TextStyle(color: Colors.white70, fontSize: 32),
      );
    }
    if (rate == null) {
      return Text(
        'Источник не публикует курс ${_c.base}/${_c.quote}. '
        'Выберите другую валюту.',
        key: const ValueKey('norate'),
        style: const TextStyle(color: Colors.white, fontSize: 15),
      );
    }
    if (!amount.isValid) {
      return const Text(
        'Введите корректную сумму для пересчёта.',
        key: ValueKey('invalid'),
        style: TextStyle(color: Colors.white70, fontSize: 15),
      );
    }
    final value = fmtAmount(amount.value! * rate);
    return FittedBox(
      key: ValueKey('$value${_c.quote}'),
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: value,
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ),
            TextSpan(
              text: ' ${_c.quote}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _hero(BuildContext context, Validated<double> amount) {
    const label = TextStyle(
      color: Colors.white70,
      fontWeight: FontWeight.w600,
      fontSize: 13,
    );
    final divider = Expanded(
      child: Divider(color: Colors.white.withValues(alpha: 0.25)),
    );
    return GradientCard(
      gradient: AppColors.heroGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: ScreenHeader(
                  title: 'Конвертер',
                  caption: 'Курсы ЕЦБ',
                  onGradient: true,
                ),
              ),
              if (_loading)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(child: Text('Вы отдаёте', style: label)),
              CurrencyPill(
                code: _c.base,
                onGradient: true,
                onTap: () => pickBase(context, _c),
              ),
            ],
          ),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            cursorColor: Colors.white,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              hintText: '0',
              hintStyle: const TextStyle(color: Colors.white38),
              errorText: amount.error,
              errorMaxLines: 2,
              errorStyle: const TextStyle(
                color: Color(0xFFFFE4E6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              divider,
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: SwapButton(onPressed: _c.swap, vertical: true),
              ),
              divider,
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(child: Text('Вы получаете', style: label)),
              CurrencyPill(
                code: _c.quote,
                onGradient: true,
                onTap: () => pickQuote(context, _c),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0, 0.15),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            ),
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.centerLeft,
              children: [...previous, ?current],
            ),
            child: _resultText(amount),
          ),
        ],
      ),
    );
  }

  Widget _rateDetails(BuildContext context) {
    final rate = _latest!.data.rateFor(_c.quote);
    if (rate == null) return const SizedBox.shrink();
    final t = Theme.of(context).textTheme;
    Widget line(String from, String to, double r) => Row(
      children: [
        Text(flagFor(from), style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Text('1 $from', style: t.titleSmall),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Icon(Icons.arrow_forward_rounded, size: 18),
        ),
        Expanded(
          child: Text(
            '${fmtRate(r)} $to',
            style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
    return SoftCard(
      child: Column(
        children: [
          line(_c.base, _c.quote, rate),
          if (_c.base != _c.quote) ...[
            const Divider(height: 24),
            line(_c.quote, _c.base, 1 / rate),
          ],
        ],
      ),
    );
  }
}

class _PairChip extends StatelessWidget {
  const _PairChip({
    required this.base,
    required this.quote,
    required this.selected,
    required this.onTap,
  });

  final String base;
  final String quote;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? AppColors.brand : Theme.of(context).cardTheme.color,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            '${flagFor(base)} $base / ${flagFor(quote)} $quote',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
