import 'package:flutter/material.dart';

import '../domain/period_stats.dart';

/// Brand palette and gradients used across the app.
abstract final class AppColors {
  static const brand = Color(0xFF5B4BFF);

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4338CA), Color(0xFF6D28D9), Color(0xFFC026D3)],
  );

  static const upGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF059669), Color(0xFF10B981), Color(0xFF34D399)],
  );

  static const downGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFBE123C), Color(0xFFE11D48), Color(0xFFFB7185)],
  );

  static const flatGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF334155), Color(0xFF475569), Color(0xFF64748B)],
  );

  static const up = Color(0xFF10B981);
  static const down = Color(0xFFE11D48);
  static const flat = Color(0xFF64748B);

  static LinearGradient trendGradient(Trend t) => switch (t) {
    Trend.up => upGradient,
    Trend.down => downGradient,
    Trend.flat => flatGradient,
  };

  static Color trendColor(Trend t) => switch (t) {
    Trend.up => up,
    Trend.down => down,
    Trend.flat => flat,
  };

  static IconData trendIcon(Trend t) => switch (t) {
    Trend.up => Icons.trending_up_rounded,
    Trend.down => Icons.trending_down_rounded,
    Trend.flat => Icons.trending_flat_rounded,
  };
}

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.brand,
    brightness: brightness,
    surface: dark ? const Color(0xFF12131F) : const Color(0xFFF5F6FC),
  );
  final cardColor = dark ? const Color(0xFF1C1D2E) : Colors.white;
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    cardTheme: CardThemeData(
      color: cardColor,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: cardColor,
      elevation: 0,
      height: 72,
      indicatorColor: AppColors.brand.withValues(alpha: dark ? 0.35 : 0.14),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontSize: 12,
          fontWeight: s.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
        ),
      ),
    ),
    textTheme: const TextTheme(
      displaySmall: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -1),
      headlineMedium: TextStyle(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      titleLarge: TextStyle(fontWeight: FontWeight.w700),
    ),
  );
}

/// Soft card used for content blocks.
class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: dark
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF4338CA).withValues(alpha: 0.07),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      padding: padding,
      child: child,
    );
  }
}

/// Rounded container with a gradient and a coloured glow.
class GradientCard extends StatelessWidget {
  const GradientCard({
    super.key,
    required this.gradient,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 28,
  });

  final Gradient gradient;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final glow = gradient is LinearGradient
        ? (gradient as LinearGradient).colors[1]
        : AppColors.brand;
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: glow.withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          children: [
            // Decorative translucent circles.
            Positioned(
              right: -40,
              top: -50,
              child: _Bubble(size: 160, opacity: 0.12),
            ),
            Positioned(
              left: -30,
              bottom: -60,
              child: _Bubble(size: 140, opacity: 0.08),
            ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: opacity),
    ),
  );
}
