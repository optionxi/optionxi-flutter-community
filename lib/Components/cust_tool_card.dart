// ─────────────────────────────────────────────
// Individual grid card
// ─────────────────────────────────────────────

import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────
class ChipItem {
  final String label;
  final String sublabel;
  final IconData icon;
  final Color lightColor;
  final Color darkColor;
  final VoidCallback onTap;

  /// Set to true for user-owned items like "My Alerts", "My Screeners",
  /// "My Journals", "Top Picks" — gives the card a distinct personal look.
  final bool isPersonal;

  const ChipItem({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.lightColor,
    required this.darkColor,
    required this.onTap,
    this.isPersonal = false,
  });
}

class GridCard extends StatefulWidget {
  final ChipItem chip;
  final bool isDark;

  const GridCard({required this.chip, required this.isDark});

  @override
  State<GridCard> createState() => _GridCardState();
}

class _GridCardState extends State<GridCard>
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
    final isPersonal = widget.chip.isPersonal;
    final color = _accent;

    // ── Personal cards get a slightly warmer/tinted background
    final bgColor = isDark
        ? Color.lerp(
            const Color(0xFF1C1C2E),
            color,
            isPersonal ? 0.14 : 0.08,
          )!
        : Color.lerp(
            Colors.white,
            color,
            isPersonal ? 0.09 : 0.05,
          )!;

    // ── Personal cards get a more visible border
    final borderColor = color.withOpacity(
      isPersonal ? (isDark ? 0.35 : 0.25) : (isDark ? 0.20 : 0.14),
    );

    // ── Personal cards get a subtle glow in the shadow
    final shadow = BoxShadow(
      color: isPersonal
          ? color.withOpacity(isDark ? 0.22 : 0.14)
          : (isDark ? Colors.black.withOpacity(0.18) : color.withOpacity(0.06)),
      blurRadius: isPersonal ? 10 : 6,
      offset: const Offset(0, 2),
    );

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
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 11),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: borderColor, width: isPersonal ? 1.0 : 0.8),
            boxShadow: [shadow],
          ),
          child: Row(
            children: [
              // ── Icon badge ──
              // Personal: solid filled badge with white icon
              // Standard: tinted translucent badge with accent icon
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: isPersonal
                      ? color.withOpacity(isDark ? 0.85 : 0.90)
                      : color.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(isPersonal ? 10 : 9),
                ),
                child: Center(
                  child: Icon(
                    widget.chip.icon,
                    color: isPersonal ? Colors.white : color,
                    size: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // ── Labels ──
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
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        // Personal sublabel is slightly more visible
                        color: isPersonal
                            ? (isDark ? Colors.white54 : Colors.black45)
                            : (isDark ? Colors.white38 : Colors.black38),
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              // ── Chevron — personal gets full accent opacity ──
              Icon(
                Icons.chevron_right_rounded,
                size: 14,
                color: color.withOpacity(isPersonal ? 0.70 : 0.40),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
