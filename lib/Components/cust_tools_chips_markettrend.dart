import 'package:flutter/material.dart';
import 'package:optionxi/Components/cust_tool_card.dart';
import 'package:optionxi/Main_Pages/AlgoDeploy/algo_page.dart';
import 'package:optionxi/Main_Pages/StockPages/act_alert_stocks.dart';
import 'package:optionxi/Main_Pages/BollingerBreakouts/act_breakout_page.dart';
import 'package:optionxi/Main_Pages/News/act_news.dart';
import 'package:optionxi/Main_Pages/Sectorwise/act_sectorwise_page.dart';
import 'package:optionxi/Main_Pages/TopGainers-Recommended/act_topgainers_losers.dart';

// ─────────────────────────────────────────────
// Main Section Widget
// ─────────────────────────────────────────────
class StockChipsSectionMarketTrend extends StatefulWidget {
  const StockChipsSectionMarketTrend({Key? key}) : super(key: key);

  @override
  State<StockChipsSectionMarketTrend> createState() =>
      _StockChipsSectionMarketTrendState();
}

class _StockChipsSectionMarketTrendState
    extends State<StockChipsSectionMarketTrend>
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
        label: 'Movers',
        sublabel: 'Market movers',
        icon: Icons.trending_up_rounded,
        lightColor: const Color(0xFF059669),
        darkColor: const Color(0xFF34D399),
        onTap: () => Navigator.push(
          context,
          _fadeRoute(
              TopGainersLosersPage(initialTab: StockMarketTab.topGainers)),
        ),
      ),
      ChipItem(
        label: 'Sector Pulse',
        sublabel: 'Sector view',
        icon: Icons.grid_view_rounded,
        lightColor: const Color(0xFFD97706),
        darkColor: const Color(0xFFFBBF24),
        onTap: () => Navigator.push(context, _fadeRoute(SectorAnalysisPage())),
      ),
      ChipItem(
        label: 'Breakouts',
        sublabel: 'Bollinger bands',
        icon: Icons.ssid_chart_rounded,
        lightColor: const Color(0xFF0891B2),
        darkColor: const Color(0xFF22D3EE),
        onTap: () =>
            Navigator.push(context, _fadeRoute(BollingerBreakoutsPage())),
      ),
      ChipItem(
        label: 'Stock Alerts',
        sublabel: 'Breakout Signals',
        icon: Icons.trending_up_rounded,
        lightColor: const Color(0xFFEA580C), // orange
        darkColor: const Color(0xFFFB923C),
        onTap: () => Navigator.push(context, _fadeRoute(StockAlertsPage(null))),
      ),
      ChipItem(
        label: 'News',
        sublabel: 'Live market updates',
        icon: Icons.bolt_rounded, // live/real-time energy
        lightColor: const Color(0xFF0EA5E9), // sky blue
        darkColor: const Color(0xFF38BDF8),
        onTap: () => Navigator.push(context, _fadeRoute(NewsFeedPage())),
      ),
      ChipItem(
        label: 'Algo Trade',
        sublabel: 'Automate your strategy',
        icon: Icons.auto_graph_rounded,
        lightColor: const Color(0xFF059669), // emerald
        darkColor: const Color(0xFF34D399),
        onTap: () => Navigator.push(context, _fadeRoute(AlgoTradingPage())),
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

    // Pair up chips into rows; last chip spans full width if odd count
    final List<Widget> rows = [];
    for (int i = 0; i < _chips.length; i += 2) {
      final bool isLastSingle = i + 1 >= _chips.length;

      rows.add(
        Row(
          children: [
            Expanded(
              child: _buildAnimatedCard(
                index: i,
                isDark: isDark,
                slideDirection: -1,
              ),
            ),
            if (!isLastSingle) ...[
              const SizedBox(width: 8),
              Expanded(
                child: _buildAnimatedCard(
                  index: i + 1,
                  isDark: isDark,
                  slideDirection: 1,
                ),
              ),
            ],
            // Full-width spacer when last chip is alone
            if (isLastSingle) const Expanded(child: SizedBox.shrink()),
          ],
        ),
      );

      if (i + 2 < _chips.length) rows.add(const SizedBox(height: 8));
    }

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
                  'MARKET TREND',
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

          // ── Chip rows ───────────────────────────
          ...rows,
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
