import 'package:flutter/material.dart';
import 'package:optionxi/Main_Pages/AIStockPick/act_stock_pick.dart' hide Theme;
import 'package:optionxi/Main_Pages/MarketSentiments/act_market_sentiments.dart';

/// Single fixed-height banner. Tap opens a bottom sheet to pick
/// Stock Breakouts or Index Breakouts. Light/dark theme aware.
class BreakoutsSection extends StatelessWidget {
  const BreakoutsSection({super.key});

  static const double bannerHeight = 112;

  void _openSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (sheetContext) => _BreakoutSheet(
        options: [
          _BreakoutOption(
            title: 'Stock Breakouts',
            subtitle: 'Volume and price surge',
            icon: Icons.trending_up_rounded,
            accent: const Color(0xFF2F7DE1),
            pageBuilder: (_) => AIPickedStocksPage(),
          ),
          _BreakoutOption(
            title: 'Index Breakouts',
            subtitle: 'Nifty and Bank Nifty',
            icon: Icons.candlestick_chart_rounded,
            accent: const Color(0xFF7A5AF8),
            pageBuilder: (_) => MarketSentimentPage(),
          ),
        ],
        onSelected: (option) {
          Navigator.pop(sheetContext);
          Navigator.push(
            context,
            MaterialPageRoute(builder: option.pageBuilder),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bg = isDark ? const Color(0xFF111A2B) : const Color(0xFFF2F6FC);
    final Color border =
        isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFDCE5F2);
    final Color ink = isDark ? Colors.white : const Color(0xFF0E1A2E);
    final Color muted =
        isDark ? Colors.white.withOpacity(0.62) : const Color(0xFF55647D);
    final Color up = isDark ? const Color(0xFF3DDC84) : const Color(0xFF16A34A);
    final Color down =
        isDark ? const Color(0xFFF0616D) : const Color(0xFFDC4B57);
    final Color pillBg = isDark ? Colors.white : const Color(0xFF0E1A2E);
    final Color pillFg = isDark ? const Color(0xFF0E1A2E) : Colors.white;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SizedBox(
        height: bannerHeight,
        width: double.infinity,
        child: Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: border, width: 0.8),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _openSheet(context),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Breakouts',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                              color: ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Stocks and indices breaking out',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: muted),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: pillBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Explore',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: pillFg,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.keyboard_arrow_up_rounded,
                                    size: 16, color: pillFg),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 112,
                      height: double.infinity,
                      child: CustomPaint(
                        painter: _BreakoutChartPainter(
                          up: up,
                          down: down,
                          resistance: muted.withOpacity(0.55),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Candle chart: consolidation under a resistance line, then a breakout.
// ─────────────────────────────────────────────────────────────────────────────

class _BreakoutChartPainter extends CustomPainter {
  final Color up;
  final Color down;
  final Color resistance;

  const _BreakoutChartPainter({
    required this.up,
    required this.down,
    required this.resistance,
  });

  // [open, close, high, low] — normalised 0..1, bottom to top.
  static const List<List<double>> _candles = [
    [0.40, 0.46, 0.50, 0.36],
    [0.46, 0.42, 0.52, 0.38],
    [0.42, 0.50, 0.54, 0.40],
    [0.50, 0.47, 0.56, 0.44],
    [0.47, 0.55, 0.58, 0.45],
    [0.55, 0.52, 0.60, 0.49],
    [0.53, 0.68, 0.72, 0.52],
    [0.68, 0.80, 0.84, 0.66],
    [0.80, 0.92, 0.96, 0.78],
  ];
  static const double _resistanceLevel = 0.60;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    double y(double v) => h - v * h;

    // Resistance (dashed)
    final dash = Paint()
      ..color = resistance
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final double ry = y(_resistanceLevel);
    for (double x = 0; x < w; x += 7) {
      canvas.drawLine(Offset(x, ry), Offset((x + 3.5).clamp(0, w), ry), dash);
    }

    // Candles
    final double slot = w / _candles.length;
    final double bodyW = slot * 0.52;
    for (int i = 0; i < _candles.length; i++) {
      final c = _candles[i];
      final bool isUp = c[1] >= c[0];
      final Color color = isUp ? up : down;
      final double cx = slot * (i + 0.5);

      final wick = Paint()
        ..color = color
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(cx, y(c[2])), Offset(cx, y(c[3])), wick);

      final double top = y(isUp ? c[1] : c[0]);
      final double bottom = y(isUp ? c[0] : c[1]);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(cx - bodyW / 2, top, cx + bodyW / 2,
              bottom < top + 2 ? top + 2 : bottom),
          const Radius.circular(1.5),
        ),
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BreakoutChartPainter old) =>
      old.up != up || old.down != down || old.resistance != resistance;
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _BreakoutOption {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final WidgetBuilder pageBuilder;

  const _BreakoutOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.pageBuilder,
  });
}

class _BreakoutSheet extends StatelessWidget {
  final List<_BreakoutOption> options;
  final ValueChanged<_BreakoutOption> onSelected;

  const _BreakoutSheet({required this.options, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color sheetBg =
        isDark ? const Color(0xFF111A2B) : const Color(0xFFFFFFFF);
    final Color ink = isDark ? Colors.white : const Color(0xFF0E1A2E);
    final Color muted =
        isDark ? Colors.white.withOpacity(0.62) : const Color(0xFF55647D);
    final Color rowBg =
        isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF2F6FC);
    final Color rowBorder =
        isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFDCE5F2);

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: muted.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Choose a breakout scan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pick what you want to analyse.',
              style: TextStyle(fontSize: 13, color: muted),
            ),
            const SizedBox(height: 16),
            for (int i = 0; i < options.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _OptionTile(
                option: options[i],
                ink: ink,
                muted: muted,
                bg: rowBg,
                border: rowBorder,
                onTap: () => onSelected(options[i]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final _BreakoutOption option;
  final Color ink;
  final Color muted;
  final Color bg;
  final Color border;
  final VoidCallback onTap;

  const _OptionTile({
    required this.option,
    required this.ink,
    required this.muted,
    required this.bg,
    required this.border,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: 0.8),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: option.accent.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(option.icon, size: 22, color: option.accent),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        option.subtitle,
                        style: TextStyle(fontSize: 12, color: muted),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
