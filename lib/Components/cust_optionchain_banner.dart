import 'package:flutter/material.dart';
import 'package:optionxi/Components/cust_tools_chips_options.dart';

// ─────────────────────────────────────────────────────────────
// OptionChainHomepageBanner
//
// A single fixed-height banner for the home page. Tapping it opens a
// modal bottom sheet that hosts the existing OptionsToolsSection
// (Option Chain, FNO Budget, OI Activity) exactly as it was.
//
// Usage:
//   const OptionChainHomepageBanner()
// ─────────────────────────────────────────────────────────────
class OptionChainHomepageBanner extends StatefulWidget {
  /// Fixed banner height. Same on every screen size.
  static const double kHeight = 92;

  final EdgeInsetsGeometry margin;

  const OptionChainHomepageBanner({
    Key? key,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  }) : super(key: key);

  @override
  State<OptionChainHomepageBanner> createState() =>
      _OptionChainHomepageBannerState();
}

class _OptionChainHomepageBannerState extends State<OptionChainHomepageBanner> {
  bool _pressed = false;

  // Same hues as the "Option Chain" tool card so the banner and the
  // sheet feel like one system.
  static const Color _pink = Color(0xFFDB2777);
  static const Color _pinkSoft = Color(0xFFF472B6);
  static const Color _teal = Color(0xFF0D9488);
  static const Color _tealSoft = Color(0xFF2DD4BF);

  void _openSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (_) => const _OptionToolsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      button: true,
      label:
          'Option chain tools. Opens option chain, FNO budget and OI activity.',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: _openSheet,
        child: AnimatedScale(
          scale: _pressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: Container(
            height: OptionChainHomepageBanner.kHeight,
            padding: const EdgeInsets.fromLTRB(14, 0, 12, 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: isDark
                    ? const [Color(0xFF2A1526), Color(0xFF17151F)]
                    : const [Color(0xFFFDF2F8), Colors.white],
              ),
              border: Border.all(
                color: isDark ? Colors.white10 : _pink.withOpacity(0.12),
              ),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? Colors.black : _pink)
                      .withOpacity(isDark ? 0.30 : 0.10),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon badge
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_pink, _pinkSoft],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _pink.withOpacity(0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.account_tree_rounded,
                    color: Colors.white,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 13),

                // Text
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Option Chain',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color:
                              isDark ? Colors.white : const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Live chain, budget picker and OI activity',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.3,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Mini OI ladder: calls on the left, puts on the right.
                SizedBox(
                  width: 52,
                  height: 44,
                  child: CustomPaint(
                    painter: _OiLadderPainter(
                      callColor: isDark ? _pinkSoft : _pink,
                      putColor: isDark ? _tealSoft : _teal,
                      axisColor: isDark ? Colors.white24 : Colors.black12,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_up_rounded,
                  color: isDark ? Colors.white38 : Colors.black26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Bottom sheet — hosts the untouched OptionsToolsSection.
// ─────────────────────────────────────────────────────────────
class _OptionToolsSheet extends StatelessWidget {
  const _OptionToolsSheet();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0E0C14) : const Color(0xFFF6F7FB),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 12),
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                physics: const BouncingScrollPhysics(),
                child: const OptionsToolsSection(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Tiny decorative OI ladder: 5 strikes, the middle one is "ATM".
// ─────────────────────────────────────────────────────────────
class _OiLadderPainter extends CustomPainter {
  final Color callColor;
  final Color putColor;
  final Color axisColor;

  const _OiLadderPainter({
    required this.callColor,
    required this.putColor,
    required this.axisColor,
  });

  static const List<double> _calls = [0.35, 0.62, 0.95, 0.5, 0.28];
  static const List<double> _puts = [0.22, 0.45, 0.8, 1.0, 0.6];

  @override
  void paint(Canvas canvas, Size size) {
    const rows = 5;
    const gap = 3.0;
    const centerGap = 2.0;
    final rowH = size.height / rows;
    final barH = rowH - gap;
    final mid = size.width / 2;
    final maxW = mid - centerGap;

    // centre axis
    canvas.drawRect(
      Rect.fromLTWH(mid - 0.5, 0, 1, size.height),
      Paint()..color = axisColor,
    );

    for (int i = 0; i < rows; i++) {
      final top = i * rowH + gap / 2;
      final atm = i == 2;
      final alpha = atm ? 1.0 : 0.6;

      final callW = maxW * _calls[i];
      final putW = maxW * _puts[i];

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(mid - centerGap - callW, top, callW, barH),
          const Radius.circular(2),
        ),
        Paint()..color = callColor.withOpacity(alpha),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(mid + centerGap, top, putW, barH),
          const Radius.circular(2),
        ),
        Paint()..color = putColor.withOpacity(alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OiLadderPainter old) =>
      old.callColor != callColor ||
      old.putColor != putColor ||
      old.axisColor != axisColor;
}
