import 'package:flutter/material.dart';
import 'package:optionxi/Main_Pages/act_alert_stocks.dart';
import 'package:optionxi/Main_Pages/act_atlas_page.dart';
import 'package:optionxi/Main_Pages/act_breakout_page.dart';
import 'package:optionxi/Main_Pages/act_scanner_page.dart';
import 'package:optionxi/Main_Pages/act_sectorwise_page.dart';
import 'package:optionxi/Main_Pages/act_topgainers_losers.dart';

// ─────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────
class _ChipItem {
  final String label;
  final String sublabel;
  final IconData icon;
  final Color lightColor;
  final Color darkColor;
  final VoidCallback onTap;

  const _ChipItem({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.lightColor,
    required this.darkColor,
    required this.onTap,
  });
}

// ─────────────────────────────────────────────
// Main Section Widget
// ─────────────────────────────────────────────
class StockChipsSection extends StatefulWidget {
  const StockChipsSection({Key? key}) : super(key: key);

  @override
  State<StockChipsSection> createState() => _StockChipsSectionState();
}

class _StockChipsSectionState extends State<StockChipsSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Animation<double>> _animations = [];
  late List<_ChipItem> _chips;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _buildChips();
  }

  void _buildChips() {
    _chips = [
      _ChipItem(
        label: 'Top Gainers',
        sublabel: 'Movers up',
        icon: Icons.trending_up_rounded,
        lightColor: const Color(0xFF059669),
        darkColor: const Color(0xFF34D399),
        onTap: () => Navigator.push(
          context,
          _fadeRoute(
              TopGainersLosersPage(initialTab: StockMarketTab.topGainers)),
        ),
      ),
      _ChipItem(
        label: 'Top Losers',
        sublabel: 'Movers down',
        icon: Icons.trending_down_rounded,
        lightColor: const Color(0xFFDC2626),
        darkColor: const Color(0xFFF87171),
        onTap: () => Navigator.push(
          context,
          _fadeRoute(
              TopGainersLosersPage(initialTab: StockMarketTab.topLosers)),
        ),
      ),
      _ChipItem(
        label: 'Top Volume',
        sublabel: 'High activity',
        icon: Icons.bar_chart_rounded,
        lightColor: const Color(0xFF7C3AED),
        darkColor: const Color(0xFFA78BFA),
        onTap: () => Navigator.push(
          context,
          _fadeRoute(
              TopGainersLosersPage(initialTab: StockMarketTab.topVolume)),
        ),
      ),
      _ChipItem(
        label: 'Heat Map',
        sublabel: 'Sector view',
        icon: Icons.grid_view_rounded,
        lightColor: const Color(0xFFD97706),
        darkColor: const Color(0xFFFBBF24),
        onTap: () => Navigator.push(context, _fadeRoute(SectorAnalysisPage())),
      ),
      _ChipItem(
        label: 'Screeners',
        sublabel: 'Filter stocks',
        icon: Icons.filter_alt_rounded,
        lightColor: const Color(0xFF9333EA),
        darkColor: const Color(0xFFC084FC),
        onTap: () => Navigator.push(context, _fadeRoute(StockScreenerPage())),
      ),
      _ChipItem(
        label: 'Sentiment',
        sublabel: 'Market mood',
        icon: Icons.psychology_rounded,
        lightColor: const Color(0xFFDB2777),
        darkColor: const Color(0xFFF472B6),
        onTap: () => Navigator.push(context, _fadeRoute(AtlasOutputPage())),
      ),
      _ChipItem(
        label: 'Breakouts',
        sublabel: 'Bollinger bands',
        icon: Icons.rocket_launch_rounded,
        lightColor: const Color(0xFF0891B2),
        darkColor: const Color(0xFF22D3EE),
        onTap: () =>
            Navigator.push(context, _fadeRoute(BollingerBreakoutsPage())),
      ),
      _ChipItem(
        label: 'Stock Alerts',
        sublabel: 'Your watchlist',
        icon: Icons.notifications_active_rounded,
        lightColor: const Color(0xFFEA580C),
        darkColor: const Color(0xFFFB923C),
        onTap: () => Navigator.push(context, _fadeRoute(StockAlertsPage(null))),
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

    for (int i = 0; i < 8; i++) {
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
                  'QUICK ACCESS',
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
      child: _GridCard(chip: _chips[index], isDark: isDark),
    );
  }
}

// ─────────────────────────────────────────────
// Individual grid card
// ─────────────────────────────────────────────
class _GridCard extends StatefulWidget {
  final _ChipItem chip;
  final bool isDark;

  const _GridCard({required this.chip, required this.isDark});

  @override
  State<_GridCard> createState() => _GridCardState();
}

class _GridCardState extends State<_GridCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  Color get _accent =>
      widget.isDark ? widget.chip.darkColor : widget.chip.lightColor;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final color = _accent;

    final bgColor = isDark
        ? Color.lerp(const Color(0xFF1C1C2E), color, 0.10)!
        : Color.lerp(Colors.white, color, 0.07)!;

    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) {
        _pressCtrl.reverse();
        widget.chip.onTap();
      },
      onTapCancel: () => _pressCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnim.value, child: child),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(isDark ? 0.28 : 0.18),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.25)
                    : color.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon badge
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(widget.chip.icon, color: color, size: 18),
                ),
              ),
              const SizedBox(width: 10),
              // Text — Expanded ensures both columns stay equal width
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.chip.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.chip.sublabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color: isDark ? Colors.white38 : Colors.black38,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              // Chevron
              Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: color.withOpacity(0.45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
