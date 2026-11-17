import 'package:flutter/material.dart';

import 'theme.dart';

/// Flag emoji for an ISO 4217 code: the first two letters are usually the
/// ISO 3166 country code (USD -> US). The euro has its own EU flag.
String flagFor(String code) {
  if (code == 'EUR') return '🇪🇺';
  if (code.length < 2) return '🏳️';
  const base = 0x1F1E6; // regional indicator 'A'
  final a = code.codeUnitAt(0) - 0x41;
  final b = code.codeUnitAt(1) - 0x41;
  if (a < 0 || a > 25 || b < 0 || b > 25) return '🏳️';
  return String.fromCharCodes([base + a, base + b]);
}

/// Opens a searchable bottom sheet and returns the chosen code.
Future<String?> showCurrencyPicker(
  BuildContext context, {
  required Map<String, String> currencies,
  required String selected,
  required String title,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _CurrencySheet(
      currencies: currencies,
      selected: selected,
      title: title,
    ),
  );
}

class _CurrencySheet extends StatefulWidget {
  const _CurrencySheet({
    required this.currencies,
    required this.selected,
    required this.title,
  });

  final Map<String, String> currencies;
  final String selected;
  final String title;

  @override
  State<_CurrencySheet> createState() => _CurrencySheetState();
}

class _CurrencySheetState extends State<_CurrencySheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final items = widget.currencies.entries
        .where(
          (e) =>
              q.isEmpty ||
              e.key.toLowerCase().contains(q) ||
              e.value.toLowerCase().contains(q),
        )
        .toList();
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.75,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                TextField(
                  autofocus: false,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Поиск: код или название',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text('Ничего не найдено'))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final e = items[i];
                      final selected = e.key == widget.selected;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          tileColor: selected
                              ? AppColors.brand.withValues(alpha: 0.12)
                              : null,
                          leading: Text(
                            flagFor(e.key),
                            style: const TextStyle(fontSize: 28),
                          ),
                          title: Text(
                            e.key,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(e.value),
                          trailing: selected
                              ? Icon(
                                  Icons.check_circle_rounded,
                                  color: scheme.primary,
                                )
                              : null,
                          onTap: () => Navigator.pop(context, e.key),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Rounded "🇺🇸 USD ▾" button that opens the picker.
class CurrencyPill extends StatelessWidget {
  const CurrencyPill({
    super.key,
    required this.code,
    required this.onTap,
    this.onGradient = false,
    this.expand = false,
  });

  final String code;
  final VoidCallback onTap;

  /// White translucent style for use on top of a gradient.
  final bool onGradient;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = onGradient
        ? Colors.white.withValues(alpha: 0.18)
        : scheme.surfaceContainerHighest.withValues(alpha: 0.6);
    final fg = onGradient ? Colors.white : scheme.onSurface;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(40),
      child: InkWell(
        borderRadius: BorderRadius.circular(40),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(flagFor(code), style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(
                code,
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.expand_more_rounded, color: fg, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// Circular swap button that spins on every tap.
class SwapButton extends StatefulWidget {
  const SwapButton({super.key, required this.onPressed, this.vertical = false});

  final VoidCallback onPressed;
  final bool vertical;

  @override
  State<SwapButton> createState() => _SwapButtonState();
}

class _SwapButtonState extends State<SwapButton> {
  double _turns = 0;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Поменять местами',
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 6,
        shadowColor: AppColors.brand.withValues(alpha: 0.4),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            setState(() => _turns += 0.5);
            widget.onPressed();
          },
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: AnimatedRotation(
              turns: _turns,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutBack,
              child: Icon(
                widget.vertical
                    ? Icons.swap_vert_rounded
                    : Icons.swap_horiz_rounded,
                color: AppColors.brand,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
