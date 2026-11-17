import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../data/models.dart';
import '../domain/period_stats.dart';
import '../domain/validation.dart';
import 'common_widgets.dart';
import 'format.dart';
import 'rate_chart.dart';
import 'theme.dart';

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
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          ScreenHeader(
            title: widget.title,
            caption: 'Сравнение · ${widget.days} дней',
          ),
          const SizedBox(height: 16),
          PairSelector(controller: _c),
          const SizedBox(height: 20),
          if (pairError != null)
            ErrorView(message: pairError, icon: Icons.compare_arrows_rounded)
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
                return _FadeIn(
                  key: ValueKey(_pairKey),
                  child: _content(context, snap.requireData),
                );
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
        if (stats == null)
          const ErrorView(
            icon: Icons.event_busy_rounded,
            message:
                'Нет данных за этот период. ЕЦБ не публикует курсы в '
                'выходные и праздники — попробуйте обновить позже.',
          )
        else
          _TrendHero(
            stats: stats,
            base: _c.base,
            quote: _c.quote,
            start: start,
            end: end,
          ),
        const SizedBox(height: 16),
        FreshnessBanner(loaded: loaded),
        if (stats != null) ...[
          const SizedBox(height: 16),
          SoftCard(
            padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 12),
                  child: Row(
                    children: [
                      Text(
                        'Динамика ${_c.base}/${_c.quote}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${fmtShortDate(start)} — ${fmtShortDate(end)}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 220,
                  child: RateChart(
                    points: points,
                    start: start,
                    end: end,
                    stats: stats,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _StatsGrid(stats: stats, quote: _c.quote),
          const SizedBox(height: 12),
          Text(
            'Дней с курсом: ${stats.count} из ${widget.days} '
            '(в выходные и праздники ЕЦБ курс не публикует).'
            '${loaded.data.skipped > 0 ? ' Пропущено некорректных записей: ${loaded.data.skipped}.' : ''}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

/// Fades and slides its child in once.
class _FadeIn extends StatelessWidget {
  const _FadeIn({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: const Duration(milliseconds: 450),
    curve: Curves.easeOutCubic,
    builder: (context, t, child) => Opacity(
      opacity: t,
      child: Transform.translate(offset: Offset(0, 24 * (1 - t)), child: child),
    ),
    child: child,
  );
}

class _TrendHero extends StatelessWidget {
  const _TrendHero({
    required this.stats,
    required this.base,
    required this.quote,
    required this.start,
    required this.end,
  });

  final PeriodStats stats;
  final String base;
  final String quote;
  final DateTime start;
  final DateTime end;

  @override
  Widget build(BuildContext context) {
    const white70 = TextStyle(color: Colors.white70, fontSize: 13);
    return GradientCard(
      gradient: AppColors.trendGradient(stats.trend),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  AppColors.trendIcon(stats.trend),
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Тенденция: ${stats.trend.label}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              fmtPercent(stats.percentChange),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.5,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${fmtSignedRate(stats.absoluteChange, stats.last.rate)} $quote '
            'за период',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Было', style: white70),
                    Text(
                      fmtRate(stats.first.rate),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.east_rounded, color: Colors.white70),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Стало', style: white70),
                    Text(
                      fmtRate(stats.last.rate),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '1 $base в $quote · ${fmtDate(start)} — ${fmtDate(end)}',
            style: white70,
          ),
        ],
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
      (
        'Минимум',
        fmtRate(stats.min.rate),
        fmtDate(stats.min.date),
        Icons.south_rounded,
        const Color(0xFF3B82F6),
      ),
      (
        'Максимум',
        fmtRate(stats.max.rate),
        fmtDate(stats.max.date),
        Icons.north_rounded,
        const Color(0xFFF59E0B),
      ),
      (
        'Среднее',
        fmtRate(stats.average),
        '$quote за период',
        Icons.functions_rounded,
        const Color(0xFF8B5CF6),
      ),
      (
        'Изменение',
        fmtSignedRate(stats.absoluteChange, stats.last.rate),
        fmtPercent(stats.percentChange),
        AppColors.trendIcon(stats.trend),
        AppColors.trendColor(stats.trend),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final (label, value, hint, icon, color) in tiles)
              SizedBox(
                width: width,
                child: _StatTile(
                  label: label,
                  value: value,
                  hint: hint,
                  icon: icon,
                  color: color,
                ),
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
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String hint;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SoftCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: t.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 2),
          Text(hint, style: t.bodySmall?.copyWith(color: color)),
        ],
      ),
    );
  }
}
