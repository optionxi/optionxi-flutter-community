import 'package:flutter/material.dart';
import 'package:optionxi/Main_Pages/AIIndexPick/act_index_pick.dart';
import 'package:optionxi/Main_Pages/AIStockPick/act_stock_pick.dart';

/// A sleek, small 2-grid section showing Stock Breakouts and Index Breakouts.
/// Fully compatible with light and dark themes.
class BreakoutsSection extends StatelessWidget {
  const BreakoutsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _BreakoutCard(
                title: 'Stock Breakouts',
                subtitle: 'Volume + Price surge',
                icon: Icons.trending_up,
                accentColor: const Color(0xFF185FA5),
                lightBgColor: const Color(0xFFEBF3FD),
                lightBorderColor: const Color(0xFFB5D4F4),
                darkTextColor: const Color(0xFF042C53),
                darkGradientColors: [
                  const Color(0xFF0C447C),
                  const Color(0xFF185FA5),
                ],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AIPickedStocksPage()),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _BreakoutCard(
                title: 'Index Breakouts',
                subtitle: 'Nifty & Bank Nifty',
                icon: Icons.area_chart,
                accentColor: const Color(0xFF534AB7),
                lightBgColor: const Color(0xFFEEEDFE),
                lightBorderColor: const Color(0xFFCECBF6),
                darkTextColor: const Color(0xFF26215C),
                darkGradientColors: [
                  const Color(0xFF3C3489),
                  const Color(0xFF534AB7),
                ],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AIPickedIndexPage()),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BreakoutCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  /// The main accent color (button bg, icon bg, subtitle text in light mode).
  final Color accentColor;

  /// Card background in light mode.
  final Color lightBgColor;

  /// Border and badge background in light mode.
  final Color lightBorderColor;

  /// Title and badge text color in light mode.
  final Color darkTextColor;

  /// Two-stop gradient used as card background in dark mode.
  final List<Color> darkGradientColors;

  final VoidCallback onTap;

  const _BreakoutCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.lightBgColor,
    required this.lightBorderColor,
    required this.darkTextColor,
    required this.darkGradientColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ── Colors resolved per mode ────────────────────────────────────────────
    final Color cardBg = isDark ? darkGradientColors[0] : lightBgColor;
    final Color borderColor =
        isDark ? Colors.white.withOpacity(0.10) : lightBorderColor;
    final Color iconBg = isDark ? Colors.white.withOpacity(0.15) : accentColor;
    final Color titleColor = isDark ? Colors.white : darkTextColor;
    final Color subtitleColor =
        isDark ? Colors.white.withOpacity(0.70) : accentColor;
    final Color badgeBg =
        isDark ? Colors.white.withOpacity(0.15) : lightBorderColor;
    final Color badgeTextColor =
        isDark ? Colors.white.withOpacity(0.80) : darkTextColor;
    final Color btnBg = isDark ? Colors.white.withOpacity(0.18) : accentColor;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? null : cardBg,
          gradient: isDark
              ? LinearGradient(
                  colors: darkGradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: icon + badge ───────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: Colors.white),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'NEW',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: badgeTextColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Title ───────────────────────────────────────────────────────
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: titleColor,
                letterSpacing: -0.2,
              ),
            ),

            const SizedBox(height: 4),

            // ── Subtitle ────────────────────────────────────────────────────
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: subtitleColor,
              ),
            ),

            const SizedBox(height: 14),

            // ── CTA button ──────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: btnBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  'Analyse →',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
