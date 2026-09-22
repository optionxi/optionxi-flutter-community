// ─────────────────────────────────────────────────────────────────────────
// Backtesting Homepage Banner Section
// Drop this on your homepage. Whole card is tappable — wire onTap to
// navigate to your backtest list / SavedBacktestDetailPage flow.
//
// Usage:
//   BacktestingHomeSection(
//     onTap: () => Navigator.push(context,
//         MaterialPageRoute(builder: (_) => YourBacktestListPage())),
//   )
// ─────────────────────────────────────────────────────────────────────────

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:optionxi/Main_Pages/IndicatorBacktest/algo_marketplace.dart';
import 'package:optionxi/Main_Pages/IndicatorBacktest/indicator-backtest.dart';

// ─────────────────────────────────────────────
// THEME (self-contained, won't clash with other files)
// ─────────────────────────────────────────────
class _BT {
  static const accent = Color(0xFF5B7FFF);
  static const green = Color(0xFF00C896);
  static const red = Color(0xFFFF4D6D);

  static List<Color> cardGradient(bool d) => d
      ? const [Color(0xFF1B1F3B), Color(0xFF12142A)]
      : const [Color(0xFFEDF0FF), Color(0xFFF8F9FF)];

  static Color border(bool d) =>
      d ? const Color(0xFF2B2F55) : const Color(0xFFE1E5FA);
  static Color text(bool d) =>
      d ? const Color(0xFFF1F2FF) : const Color(0xFF14162B);
  static Color sub(bool d) =>
      d ? const Color(0xFFA0A6D0) : const Color(0xFF6B7094);
  static Color chipBg(bool d) =>
      d ? Colors.white.withOpacity(0.06) : Colors.white;
}

// ─────────────────────────────────────────────
// MAIN SECTION WIDGET
// ─────────────────────────────────────────────
class BacktestingHomeSection extends StatelessWidget {
  const BacktestingHomeSection({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openAlgoPicker(context),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 18, 8, 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _BT.border(dark)),
            gradient: LinearGradient(
              colors: _BT.cardGradient(dark),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: dark
                ? []
                : [
                    BoxShadow(
                      color: _BT.accent.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Text column ──────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _badge(dark),
                    const SizedBox(height: 10),
                    Text(
                      'Backtest your algos on past data',
                      style: TextStyle(
                        fontSize: 17,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                        color: _BT.text(dark),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'See how your idea would\'ve played out before you risk real money — takes seconds.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        color: _BT.sub(dark),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _miniChip(dark, Icons.bolt_rounded, 'Instant results'),
                        const SizedBox(width: 8),
                        _miniChip(
                            dark, Icons.verified_rounded, 'No real money'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // ── Illustration ─────────────────────────
              SizedBox(
                width: 108,
                height: 118,
                child: _BacktestIllustration(dark: dark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(bool dark) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _BT.accent.withOpacity(0.14),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_toggle_off_rounded, size: 12, color: _BT.accent),
            const SizedBox(width: 5),
            Text(
              'BACKTESTING',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: _BT.accent,
              ),
            ),
          ],
        ),
      );

  Widget _miniChip(bool dark, IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: _BT.chipBg(dark),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _BT.border(dark)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: _BT.green),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: _BT.sub(dark),
              ),
            ),
          ],
        ),
      );
}

void _openAlgoPicker(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => const _AlgoPickerSheet(),
  );
}

/* ════════════════════════════════════════════════════════════════════════
   Algo picker bottom sheet
   ════════════════════════════════════════════════════════════════════════ */
// Keep your existing imports for dotenv, BacktestApiService,
// CommunityAlgosBrowsePage and SavedBacktestsPage.

/// Bottom sheet that lets the user browse community algos or build their own.
///
/// Drop-in replacement: same class names, same constructor, same navigation.
/// Changes: Material 3 theme colors (light + dark), non-deprecated color API,
/// pressed-state feedback, haptics, safe navigation after pop, semantics.
class _AlgoPickerSheet extends StatelessWidget {
  const _AlgoPickerSheet();

  void _go(BuildContext context, WidgetBuilder builder) {
    // Grab the navigator first: `context` is no longer safe to use once the
    // sheet has been popped.
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(MaterialPageRoute(builder: builder));
  }

  void _browseAlgos(BuildContext context) {
    final apiBaseUrl = dotenv.env['BACKTEST_API_BASE_URL']!;
    _go(
      context,
      (_) => CommunityAlgosBrowsePage(
        api: BacktestApiService(baseUrl: apiBaseUrl),
      ),
    );
  }

  void _createAlgo(BuildContext context) {
    _go(context, (_) => SavedBacktestsPage());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Material(
      color: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 10, 20, bottomInset + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'What do you want to do?',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Browse existing algos or build your own from scratch.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 22),
            _AlgoOptionCard(
              label: 'Browse algos',
              subtitle: 'Explore saved and shared strategies',
              icon: Icons.travel_explore_rounded,
              color: const Color(0xFF2563EB),
              onTap: () => _browseAlgos(context),
            ),
            const SizedBox(height: 12),
            _AlgoOptionCard(
              label: 'Create algo',
              subtitle: 'Build a strategy yourself',
              icon: Icons.auto_awesome_rounded,
              color: const Color(0xFF0D9488),
              onTap: () => _createAlgo(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlgoOptionCard extends StatefulWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AlgoOptionCard({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_AlgoOptionCard> createState() => _AlgoOptionCardState();
}

class _AlgoOptionCardState extends State<_AlgoOptionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = widget.color;

    // Tint the card from the theme surface so it works in light and dark mode.
    final cardColor = Color.alphaBlend(
      color.withValues(alpha: 0.07),
      scheme.surfaceContainerHigh,
    );

    return Semantics(
      button: true,
      label: '${widget.label}. ${widget.subtitle}',
      excludeSemantics: true,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Material(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onHighlightChanged: (v) => setState(() => _pressed = v),
            splashColor: color.withValues(alpha: 0.12),
            highlightColor: color.withValues(alpha: 0.06),
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onTap();
            },
            child: Ink(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withValues(alpha: 0.22)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color.lerp(color, Colors.white, 0.18)!,
                          color,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.28),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(widget.icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.label,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: 0.12),
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ILLUSTRATION — hand-drawn candlestick chart
// with a "hit" pin, no external image assets needed.
// (Inspired by the simple bar/chart promo cards you see
// on Groww, Zerodha Kite and INDmoney feature banners.)
// ─────────────────────────────────────────────
class _BacktestIllustration extends StatelessWidget {
  final bool dark;
  const _BacktestIllustration({required this.dark});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CandlePainter(dark: dark),
      child: const SizedBox.expand(),
    );
  }
}

class _CandlePainter extends CustomPainter {
  final bool dark;
  _CandlePainter({required this.dark});

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..color = (dark ? Colors.white : _BT.accent).withOpacity(0.05);
    final rrect =
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(18));
    canvas.drawRRect(rrect, bg);

    // Candle data: [open, close, high, low] normalized 0..1 (1 = top)
    final candles = [
      [0.75, 0.6, 0.8, 0.55],
      [0.6, 0.68, 0.65, 0.75],
      [0.68, 0.42, 0.72, 0.4],
      [0.42, 0.5, 0.55, 0.38],
      [0.5, 0.22, 0.52, 0.2],
    ];

    final chartTop = size.height * 0.14;
    final chartBottom = size.height * 0.78;
    final chartH = chartBottom - chartTop;
    final n = candles.length;
    final gap = size.width / (n + 1);

    for (int i = 0; i < n; i++) {
      final cx = gap * (i + 1);
      final o = chartTop + candles[i][0] * chartH;
      final c = chartTop + candles[i][1] * chartH;
      final h = chartTop + candles[i][2] * chartH;
      final l = chartTop + candles[i][3] * chartH;
      final isUp = c < o;
      final color = isUp ? _BT.green : _BT.red;

      final wickPaint = Paint()
        ..color = color.withOpacity(0.9)
        ..strokeWidth = 1.4;
      canvas.drawLine(Offset(cx, h), Offset(cx, l), wickPaint);

      final bodyPaint = Paint()..color = color;
      final bodyTop = math.min(o, c);
      final bodyBottom = math.max(o, c);
      final bodyRect = RRect.fromRectAndRadius(
        Rect.fromLTRB(
            cx - 3.2, bodyTop, cx + 3.2, math.max(bodyBottom, bodyTop + 3)),
        const Radius.circular(1.5),
      );
      canvas.drawRRect(bodyRect, bodyPaint);

      // "Hit" marker pin on the last candle — mirrors the alert dots
      // used on the detail chart, so the two screens feel connected.
      if (i == n - 1) {
        final pinCenter = Offset(cx, h - 10);
        final ringPaint = Paint()
          ..color = _BT.accent.withOpacity(0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawCircle(pinCenter, 9, ringPaint);

        final dotPaint = Paint()..color = _BT.accent;
        canvas.drawCircle(pinCenter, 4.5, dotPaint);

        final dotBorder = Paint()
          ..color = dark ? const Color(0xFF12142A) : Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6;
        canvas.drawCircle(pinCenter, 4.5, dotBorder);
      }
    }

    // Baseline
    final basePaint = Paint()
      ..color = _BT.border(dark)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(6, chartBottom + 4),
      Offset(size.width - 6, chartBottom + 4),
      basePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CandlePainter oldDelegate) =>
      oldDelegate.dark != dark;
}
