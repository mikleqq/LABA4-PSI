import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../data/models.dart';
import '../domain/period_stats.dart';
import '../domain/validation.dart';
import 'common_widgets.dart';
import 'format.dart';
import 'rate_chart.dart';

/// Rate dynamics of the selected pair over the last [days] calendar days.
class TrendScreen extends StatefulWidget {
  const TrendScreen({
    super.key,
    required this.controller,
    required this.days,
    required this.title,
  });

  final AppController controller;
  final int days;
  final String title;

  @override
  State<TrendScreen> createState() => _TrendScreenState();
}

class _TrendScreenState extends State<TrendScreen> {
  Future<Loaded<RateSeries>>? _future;
  String? _pairKey;

  AppController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _c.addListener(_onPairChanged);
    _reload();
  }

  @override
  void dispose() {
    _c.removeListener(_onPairChanged);
    super.dispose();
  }

  void _onPairChanged() {
    if (_c.pairKey != _pairKey) setState(_reload);
  }

  void _reload({bool refresh = false}) {
    _pairKey = _c.pairKey;
    _future = validatePair(_c.base, _c.quote) == null
        ? _c.history(refresh: refresh)
        : null;
  }

  Future<void> _refresh() async {
    setState(() => _reload(refresh: true));
    try {
      await _future;
    } catch (_) {
      // Shown by the FutureBuilder.
    }
  }

  @override
  Widget build(BuildContext context) {
    final pairError = validatePair(_c.base, _c.quote);
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          PairSelector(controller: _c),
          const SizedBox(height: 12),
          if (pairError != null)
            ErrorView(message: pairError)
          else
            FutureBuilder<Loaded<RateSeries>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snap.hasError) {
                  return ErrorView(
                    message: errorText(snap.error!),
                    onRetry: _refresh,
                  );
                }
                return _content(context, snap.requireData);
              },
            ),
        ],
      ),
    );
  }

  Widget _content(BuildContext context, Loaded<RateSeries> loaded) {
    // The window ends on the day the data was fetched, so cached data is
    // still shown for the period it actually covers.
    final end = dateOnly(loaded.fetchedAt);
    final start = end.subtract(Duration(days: widget.days - 1));
    final points = lastDays(loaded.data.points, widget.days, end);
    final stats = computeStats(points);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${widget.title}: ${_c.base}/${_c.quote}',
          style: theme.textTheme.titleLarge,
        ),
        Text(
          '${fmtDate(start)} — ${fmtDate(end)}',
          style: theme.textTheme.bodyMedium,
        ),
        FreshnessBanner(loaded: loaded),
        if (stats == null)
          const ErrorView(
            message:
                'Нет данных за этот период. ЕЦБ не публикует курсы в '
                'выходные и праздники — попробуйте обновить позже.',
          )
        else ...[
          _TrendBadge(stats: stats),
          const SizedBox(height: 12),
          SizedBox(
            height: 240,
            child: RateChart(
              points: points,
              start: start,
              end: end,
              stats: stats,
            ),
          ),
          const SizedBox(height: 12),
          _StatsGrid(stats: stats, quote: _c.quote),
          const SizedBox(height: 8),
          Text(
            'Дней с курсом: ${stats.count} из ${widget.days} '
            '(в выходные и праздники ЕЦБ курс не публикует).'
            '${loaded.data.skipped > 0 ? ' Пропущено некорректных записей: ${loaded.data.skipped}.' : ''}',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}

class _TrendBadge extends StatelessWidget {
  const _TrendBadge({required this.stats});

  final PeriodStats stats;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (stats.trend) {
      Trend.up => (Icons.trending_up, Colors.green.shade700),
      Trend.down => (Icons.trending_down, Colors.red.shade700),
      Trend.flat => (Icons.trending_flat, Colors.blueGrey.shade600),
    };
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.12),
      child: ListTile(
        leading: Icon(icon, color: color, size: 36),
        title: Text(
          'Тенденция: ${stats.trend.label}',
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${fmtSignedRate(stats.absoluteChange, stats.last.rate)} '
          '(${fmtPercent(stats.percentChange)}) за период',
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats, required this.quote});

  final PeriodStats stats;
  final String quote;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      ('Минимум', fmtRate(stats.min.rate), fmtDate(stats.min.date)),
      ('Максимум', fmtRate(stats.max.rate), fmtDate(stats.max.date)),
      ('Среднее', fmtRate(stats.average), '$quote за период'),
      (
        'Изменение',
        fmtSignedRate(stats.absoluteChange, stats.last.rate),
        fmtPercent(stats.percentChange),
      ),
      ('Начало', fmtRate(stats.first.rate), fmtDate(stats.first.date)),
      ('Конец', fmtRate(stats.last.rate), fmtDate(stats.last.date)),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 8) / 2;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (label, value, hint) in tiles)
              SizedBox(
                width: width,
                child: _StatTile(label: label, value: value, hint: hint),
              ),
          ],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.hint,
  });

  final String label;
  final String value;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: t.labelMedium),
            const SizedBox(height: 4),
            Text(
              value,
              style: t.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            Text(hint, style: t.bodySmall),
          ],
        ),
      ),
    );
  }
}
