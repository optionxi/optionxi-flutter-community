import 'package:flutter/material.dart';
import 'package:optionxi/Components/cust_tool_card.dart';
import 'package:optionxi/Main_Pages/ScreenerPro/act_custom_screener_pro.dart';
import 'package:optionxi/Main_Pages/Scanner/act_scanner_page.dart';
import 'package:optionxi/Main_Pages/TopGainers-Recommended/act_top_recommended_stock_page.dart';

// ─────────────────────────────────────────────
// Main Section Widget
// ─────────────────────────────────────────────
class StockChipsSectionResearch extends StatefulWidget {
  const StockChipsSectionResearch({Key? key}) : super(key: key);

  @override
  State<StockChipsSectionResearch> createState() =>
      _StockChipsSectionResearchState();
}

class _StockChipsSectionResearchState extends State<StockChipsSectionResearch>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Animation<double>> _animations = [];
  late List<ChipItem> _chips;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _buildChips();
  }

  void _buildChips() {
    _chips = [
      ChipItem(
        label: 'Screener',
        sublabel: 'Discover opportunities',
        icon: Icons.manage_search_rounded, // purposeful search feel
        lightColor: const Color(0xFF2563EB), // blue
        darkColor: const Color(0xFF60A5FA),
        onTap: () => Navigator.push(context, _fadeRoute(StockScreenerPage())),
      ),
      ChipItem(
        label: 'Screener Pro',
        sublabel: 'Advanced filters & signals',
        icon: Icons.analytics_rounded, // pro = deeper analytics
        lightColor:
            const Color(0xFFD97706), // amber-700 (more saturated/premium)
        darkColor: const Color(0xFFFBBF24),
        onTap: () =>
            Navigator.push(context, _fadeRoute(StockScreenerPagePro())),
      ),
      ChipItem(
        label: 'Top Picks',
        sublabel: 'AI curated stocks',
        icon: Icons.workspace_premium_rounded, // premium curation > sparkles
        lightColor: const Color(0xFF7C3AED), // violet
        darkColor: const Color(0xFFA78BFA),
        onTap: () => Navigator.push(
          context,
          _fadeRoute(const TopRecommendedStockPage()),
        ),
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );

    for (int i = 0; i < 9; i++) {
      final start = i * 0.07;
      final end = (start + 0.45).clamp(0.0, 1.0);
      _animations.add(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeOutQuint),
        ),
      );
    }

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  PageRoute _fadeRoute(Widget page) => PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 280),
      );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rowCount = (_chips.length / 2).ceil();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section header ──────────────────────
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Row(
              children: [
                Text(
                  'RESEARCH',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [Colors.white12, Colors.transparent]
                            : [Colors.black12, Colors.transparent],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── 2-column grid ───────────────────────
          for (int row = 0; row < rowCount; row++) ...[
            Row(
              children: [
                // Left column
                Expanded(
                  child: _buildAnimatedCard(
                    index: row * 2,
                    isDark: isDark,
                    slideDirection: -1, // slide from left
                  ),
                ),
                const SizedBox(width: 8),
                // Right column
                Expanded(
                  child: row * 2 + 1 < _chips.length
                      ? _buildAnimatedCard(
                          index: row * 2 + 1,
                          isDark: isDark,
                          slideDirection: 1, // slide from right
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
            if (row < rowCount - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildAnimatedCard({
    required int index,
    required bool isDark,
    required int slideDirection,
  }) {
    return AnimatedBuilder(
      animation: _animations[index],
      builder: (context, child) {
        final v = _animations[index].value;
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(slideDirection * 14 * (1 - v), 0),
            child: child,
          ),
        );
      },
      child: GridCard(chip: _chips[index], isDark: isDark),
    );
  }
}
