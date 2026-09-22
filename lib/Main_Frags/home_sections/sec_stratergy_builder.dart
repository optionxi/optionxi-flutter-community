// ─────────────────────────────────────────────────────────────────────────
// Strategy Builder — Home banner + index picker.
//
// Drop this file into your app (e.g. lib/widgets/strategy_builder_banner.dart)
// and place `const StrategyBuilderBanner()` anywhere on your home screen.
//
// Tapping the banner opens a bottom sheet asking "NIFTY or BANKNIFTY?" and
// then pushes StrategyBuilderPage with that index pre-selected.
//
// REQUIRED ONE-TIME CHANGE to strategy_builder_page.dart:
// Add an optional constructor param so the picker can preselect the index:
//
//   class StrategyBuilderPage extends StatefulWidget {
//     final String? initialIndex;                              // ADD THIS
//     const StrategyBuilderPage({super.key, this.initialIndex}); // CHANGE THIS
//     ...
//   }
//
// and in _StrategyBuilderPageState, change:
//   String indexName = kIndexOptions[0];
// to set it inside initState instead:
//   String indexName = kIndexOptions[0];   // keep as default fallback
//   ...
//   @override
//   void initState() {
//     super.initState();
//     indexName = widget.initialIndex ?? kIndexOptions[0];      // ADD THIS LINE
//     _tabController = TabController(length: 3, vsync: this);
//     _loadExpiries();
//     _loadCandles();
//   }
//
// No external SVG package is used — all icons below are hand-drawn with
// CustomPainter so there's zero asset/dependency overhead.
// ─────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:optionxi/StrategyBuilder/strategy_builder.dart';

/* ════════════════════════════════════════════════════════════════════════
   Home banner (fixed height, drop-in anywhere)
   ════════════════════════════════════════════════════════════════════════ */

class StrategyBuilderBanner extends StatelessWidget {
  /// Fixed height of the banner. Defaults to 150 so it behaves predictably
  /// wherever you place it on the home screen.
  final double height;

  const StrategyBuilderBanner({super.key, this.height = 150});

  void _openIndexPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => const _IndexPickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openIndexPicker(context),
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF1E3A8A), Color(0xFF7C3AED)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 14,
                offset: const Offset(0, 6)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Decorative faint candlestick illustration in the corner.
              Positioned(
                right: -18,
                bottom: -18,
                child: Opacity(
                  opacity: 0.22,
                  child: CustomPaint(
                    size: const Size(170, 130),
                    painter: _MiniCandleIconPainter(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const CustomPaintIcon(),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Strategy Builder',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      'Build virtual option positions and see how they play out — test strategies and straddles risk-free.',
                      style: TextStyle(
                          color: Colors.white70, fontSize: 12.5, height: 1.35),
                    ),
                    Row(
                      children: const [
                        Text(
                          'Tap to pick NIFTY or BANKNIFTY',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios,
                            color: Colors.white, size: 12),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small badge icon shown in the banner header (a simple up-trend line with
/// a dot, drawn as a vector so it's crisp at any size).
class CustomPaintIcon extends StatelessWidget {
  const CustomPaintIcon({super.key});
  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(22, 22), painter: _TrendGlyphPainter());
  }
}

/* ════════════════════════════════════════════════════════════════════════
   Index picker bottom sheet
   ════════════════════════════════════════════════════════════════════════ */

class _IndexPickerSheet extends StatelessWidget {
  const _IndexPickerSheet();

  void _goToBuilder(BuildContext context, String index) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StrategyBuilderPage(initialIndex: index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).padding.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 18),
          const Text('Which index do you want to trade?',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('You can switch anytime inside the builder.',
              style: TextStyle(fontSize: 12.5, color: Colors.grey)),
          const SizedBox(height: 20),
          _IndexOptionCard(
            label: 'NIFTY',
            subtitle: 'Option Chain',
            color: const Color(0xFF2563EB),
            onTap: () => _goToBuilder(context, 'NIFTY'),
          ),
          const SizedBox(height: 12),
          _IndexOptionCard(
            label: 'BANKNIFTY',
            subtitle: 'Option Chain',
            color: const Color(0xFF0D9488),
            onTap: () => _goToBuilder(context, 'BANKNIFTY'),
          ),
        ],
      ),
    );
  }
}

class _IndexOptionCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _IndexOptionCard({
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.25)),
          borderRadius: BorderRadius.circular(16),
          color: color.withOpacity(0.06),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: CustomPaint(
                size: const Size(26, 26),
                painter: _CandleGlyphPainter(color: color),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: color)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style:
                          const TextStyle(fontSize: 11.5, color: Colors.grey)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    );
  }
}

/* ════════════════════════════════════════════════════════════════════════
   Hand-drawn vector icons (no SVG package / asset files needed)
   ════════════════════════════════════════════════════════════════════════ */

/// A tiny up-trend line + dot, used as the banner's header badge.
class _TrendGlyphPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(2, size.height - 4)
      ..lineTo(size.width * 0.4, size.height * 0.45)
      ..lineTo(size.width * 0.6, size.height * 0.65)
      ..lineTo(size.width - 2, 3);
    canvas.drawPath(path, paint);
    canvas.drawCircle(
        Offset(size.width - 2, 3), 2.4, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Three simple candlesticks (2 green, 1 red) — used inside the option cards.
class _CandleGlyphPainter extends CustomPainter {
  final Color color;
  _CandleGlyphPainter({this.color = Colors.blue});

  @override
  void paint(Canvas canvas, Size size) {
    final upPaint = Paint()..color = color;
    final downPaint = Paint()..color = color.withOpacity(0.45);
    final wickPaint = Paint()
      ..color = color
      ..strokeWidth = 1.4;

    final w = size.width / 3;

    void candle(int i, double bodyTop, double bodyH, double wickTop,
        double wickBottom, Paint p) {
      final cx = w * i + w / 2;
      canvas.drawLine(Offset(cx, wickTop), Offset(cx, wickBottom), wickPaint);
      canvas.drawRect(
        Rect.fromLTWH(cx - w * 0.22, bodyTop, w * 0.44, bodyH),
        p,
      );
    }

    candle(0, size.height * 0.35, size.height * 0.35, size.height * 0.1,
        size.height * 0.9, upPaint);
    candle(1, size.height * 0.15, size.height * 0.3, size.height * 0.05,
        size.height * 0.6, downPaint);
    candle(2, size.height * 0.25, size.height * 0.45, size.height * 0.05,
        size.height * 0.95, upPaint);
  }

  @override
  bool shouldRepaint(covariant _CandleGlyphPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Larger, faint decorative candlestick cluster for the banner background.
class _MiniCandleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final green = Paint()..color = Colors.greenAccent;
    final red = Paint()..color = Colors.redAccent;
    final wick = Paint()
      ..color = Colors.white
      ..strokeWidth = 2;

    final bars = [
      (0.10, 0.55, 0.30, green),
      (0.30, 0.35, 0.45, red),
      (0.50, 0.45, 0.35, green),
      (0.70, 0.20, 0.55, green),
      (0.90, 0.60, 0.25, red),
    ];

    final w = size.width * 0.1;
    for (final b in bars) {
      final cx = size.width * b.$1;
      final bodyTop = size.height * b.$2;
      final bodyH = size.height * b.$3;
      canvas.drawLine(
          Offset(cx, bodyTop - 10), Offset(cx, bodyTop + bodyH + 10), wick);
      canvas.drawRect(
        Rect.fromLTWH(cx - w / 2, bodyTop, w, bodyH),
        b.$4,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
