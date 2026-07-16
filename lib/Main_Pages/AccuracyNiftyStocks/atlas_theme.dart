// =============================================================================
// Atlas × Nifty — DESIGN SYSTEM (v2)
// -----------------------------------------------------------------------------
// What changed from v1, and why:
//   • Sheets ("InfoButton" / showAtlasSheet) used to force a
//     DraggableScrollableSheet sized 0.3–0.95 of the screen — a two-line
//     explainer ended up with a huge blank panel underneath it. Sheets now
//     hug their content (ConstrainedBox + SingleChildScrollView, capped at
//     ~88% of the screen) and only take the space they need.
//   • timeago is now used everywhere a timestamp is shown alongside its
//     absolute value ("3h ago" next to "14:20") — faster to scan than doing
//     the math yourself.
//   • Accuracy used to just be a big number. It's now also an AccuracyRing
//     (a colored progress ring) so it reads as "mostly full / mostly green"
//     at a glance before you even read the digits.
//   • Risk vs reward (max favorable vs max adverse move) used to be two
//     separate KvRows you had to compare mentally. RiskRewardBar draws them
//     as a single vertical bar around a shared zero line — reward growing
//     up, risk growing down — so the shape of the trade is visible
//     instantly.
//   • Cards got a softer elevation (subtle shadow, not just a flat border),
//     slightly larger corner radius, and more supporting icons throughout.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;

// -----------------------------------------------------------------------------
// TIMEAGO SETUP — call once, e.g. in main() before runApp().
// -----------------------------------------------------------------------------
void initAtlasTimeago() {
  timeago.setLocaleMessages('en_short', timeago.EnShortMessages());
}

/// "3h ago", "2d ago" — compact relative time for anywhere space is tight
/// (list rows, chips). Pass the already-IST DateTime.
String timeAgoShort(DateTime dt) =>
    timeago.format(dt, locale: 'en_short', clock: DateTime.now());

/// "3 hours ago" — full relative time for sheet/detail contexts.
String timeAgoFull(DateTime dt) => timeago.format(dt, clock: DateTime.now());

// -----------------------------------------------------------------------------
// PALETTE
// -----------------------------------------------------------------------------
class AtlasColors {
  final bool isDark;
  AtlasColors(this.isDark);

  Color get bg => isDark ? const Color(0xFF0A0C10) : const Color(0xFFF6F7FB);
  Color get surface => isDark ? const Color(0xFF14171E) : Colors.white;
  Color get surfaceAlt =>
      isDark ? const Color(0xFF1B1F28) : const Color(0xFFEFF1F7);
  Color get border =>
      isDark ? const Color(0xFF262B36) : const Color(0xFFE3E6EE);
  Color get textPrimary =>
      isDark ? const Color(0xFFF2F4F8) : const Color(0xFF14171E);
  Color get textSecondary =>
      isDark ? const Color(0xFF9BA3B4) : const Color(0xFF6A7182);
  Color get textFaint =>
      isDark ? const Color(0xFF5C6272) : const Color(0xFFA0A6B5);

  Color get bull => const Color(0xFF22C58B);
  Color get bear => const Color(0xFFF0554F);
  Color get accent => const Color(0xFF5B8CFF);
  Color get accent2 =>
      const Color(0xFF8B7BFF); // secondary accent for gradients
  Color get warn => const Color(0xFFE8A63D);

  Color bullSoft() => bull.withOpacity(isDark ? 0.16 : 0.12);
  Color bearSoft() => bear.withOpacity(isDark ? 0.16 : 0.12);
  Color accentSoft() => accent.withOpacity(isDark ? 0.16 : 0.12);

  Color pnl(double v) => v >= 0 ? bull : bear;

  /// Traffic-light color for an accuracy/win-rate percentage.
  Color accuracyColor(double pct) =>
      pct >= 60 ? bull : (pct >= 45 ? warn : bear);

  List<BoxShadow> cardShadow() => [
        BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.28 : 0.05),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];
}

AtlasColors atlasColors(BuildContext ctx) =>
    AtlasColors(Theme.of(ctx).brightness == Brightness.dark);

// -----------------------------------------------------------------------------
// TYPE SCALE — one font family, weight does the work
// -----------------------------------------------------------------------------
class AtlasText {
  final AtlasColors c;
  AtlasText(this.c);

  TextStyle get display => GoogleFonts.inter(
      fontSize: 30,
      fontWeight: FontWeight.w800,
      color: c.textPrimary,
      height: 1.1,
      letterSpacing: -0.5);
  TextStyle get h1 => GoogleFonts.inter(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: c.textPrimary,
      letterSpacing: -0.2);
  TextStyle get h2 => GoogleFonts.inter(
      fontSize: 16, fontWeight: FontWeight.w700, color: c.textPrimary);
  TextStyle get body => GoogleFonts.inter(
      fontSize: 14, fontWeight: FontWeight.w500, color: c.textPrimary);
  TextStyle get bodyMuted => GoogleFonts.inter(
      fontSize: 13, fontWeight: FontWeight.w500, color: c.textSecondary);
  TextStyle get caption => GoogleFonts.inter(
      fontSize: 11.5,
      fontWeight: FontWeight.w600,
      color: c.textFaint,
      letterSpacing: 0.3);
  TextStyle get numberLg => GoogleFonts.robotoMono(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: c.textPrimary,
      letterSpacing: -0.5);
  TextStyle get numberMd => GoogleFonts.robotoMono(
      fontSize: 15, fontWeight: FontWeight.w600, color: c.textPrimary);
  TextStyle get numberSm => GoogleFonts.robotoMono(
      fontSize: 12.5, fontWeight: FontWeight.w600, color: c.textPrimary);
}

AtlasText atlasText(BuildContext ctx) => AtlasText(atlasColors(ctx));

// -----------------------------------------------------------------------------
// SPACING
// -----------------------------------------------------------------------------
class Sp {
  static const xs = 4.0, sm = 8.0, md = 12.0, lg = 16.0, xl = 24.0, xxl = 32.0;
}

ThemeData atlasThemeData(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final c = AtlasColors(isDark);
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: c.bg,
    fontFamily: GoogleFonts.inter().fontFamily,
    splashFactory: InkRipple.splashFactory,
    colorScheme: ColorScheme.fromSeed(
      seedColor: c.accent,
      brightness: brightness,
      surface: c.surface,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: c.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: c.surface,
      indicatorColor: c.accentSoft(),
      elevation: 0,
      height: 64,
    ),
    dividerColor: c.border,
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: c.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.border),
      ),
      textStyle: TextStyle(color: c.textPrimary, fontSize: 12),
    ),
  );
}

// =============================================================================
// REUSABLE WIDGETS
// =============================================================================

/// A tap target that shows extra context in a bottom sheet instead of
/// cramming it onto the screen. Use for anything a curious user might want
/// but most users don't need to see by default.
class InfoButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget Function(BuildContext) bodyBuilder;
  const InfoButton({
    super.key,
    required this.title,
    required this.bodyBuilder,
    this.icon = Icons.info_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final c = atlasColors(context);
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => showAtlasSheet(context,
          title: title, icon: icon, builder: bodyBuilder),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 17, color: c.textFaint),
      ),
    );
  }
}

/// Standard bottom sheet shell. Sizes itself to its content (capped at 88%
/// of the screen height, scrollable past that) instead of forcing a fixed
/// fraction of the screen — short content no longer leaves a slab of empty
/// space below it.
Future<void> showAtlasSheet(
  BuildContext context, {
  required String title,
  required Widget Function(BuildContext) builder,
  IconData? icon,
}) {
  final c = atlasColors(context);
  final t = atlasText(context);
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final maxH = MediaQuery.of(ctx).size.height * 0.88;
      final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
      return Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: Container(
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                          color: c.border,
                          borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  // Fixed header — never scrolls
                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(Sp.lg, Sp.md, Sp.sm, Sp.sm),
                    child: Row(
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: 18, color: c.accent),
                          const SizedBox(width: 8),
                        ],
                        Expanded(child: Text(title, style: t.h1)),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  // Scrollable body only
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: Sp.xl),
                      child: Padding(
                        padding:
                            const EdgeInsets.fromLTRB(Sp.lg, 0, Sp.lg, Sp.sm),
                        child: builder(ctx),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// The big number at the top of a screen. Use sparingly — 1 hero per screen.
class HeroStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final String? sublabel;
  final IconData? icon;

  /// Optional 0-100 value to render as an AccuracyRing beside the number —
  /// use for accuracy/win-rate heroes so the shape reads before the digits.
  final double? ringValue;
  const HeroStat({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.sublabel,
    this.icon,
    this.ringValue,
  });

  @override
  Widget build(BuildContext context) {
    final c = atlasColors(context);
    final t = atlasText(context);
    final textColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: c.textFaint),
            const SizedBox(width: 6),
          ],
          Text(label.toUpperCase(), style: t.caption),
        ]),
        const SizedBox(height: 6),
        Text(value,
            style: t.display.copyWith(color: valueColor ?? t.display.color)),
        if (sublabel != null) ...[
          const SizedBox(height: 2),
          Text(sublabel!, style: t.bodyMuted),
        ],
      ],
    );

    if (ringValue == null) return textColumn;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AccuracyRing(value: ringValue!, size: 76),
        const SizedBox(width: Sp.lg),
        Expanded(child: textColumn),
      ],
    );
  }
}

/// A colored progress ring for a 0-100 percentage (accuracy, win rate).
/// Reads at a glance as "mostly green / mostly full" before the digits
/// register — faster to scan than a bare number, especially in a list.
class AccuracyRing extends StatelessWidget {
  final double value;
  final double size;
  final String? centerLabel;
  const AccuracyRing({
    super.key,
    required this.value,
    this.size = 72,
    this.centerLabel,
  });

  @override
  Widget build(BuildContext context) {
    final c = atlasColors(context);
    final color = c.accuracyColor(value);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: (value / 100).clamp(0, 1),
              strokeWidth: size * 0.1,
              strokeCap: StrokeCap.round,
              backgroundColor: c.surfaceAlt,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${value.toStringAsFixed(0)}%',
                  style: GoogleFonts.robotoMono(
                    fontSize: size * 0.23,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: -0.3,
                  )),
              if (centerLabel != null)
                Text(centerLabel!,
                    style: GoogleFonts.inter(
                      fontSize: size * 0.1,
                      fontWeight: FontWeight.w600,
                      color: c.textFaint,
                    )),
            ],
          ),
        ],
      ),
    );
  }
}

/// Vertical risk/reward indicator built around a shared zero baseline —
/// reward grows up in green, risk grows down in red, both scaled to the
/// same max so their relative size is directly comparable. Reading this
/// bar's *shape* ("mostly tall and green" vs "short green, long red") is
/// faster than comparing two separate percentages, which is the main
/// upgrade over the old two-line KvRow layout.
class RiskRewardBar extends StatelessWidget {
  final double rewardPcnt; // e.g. max favorable move, positive
  final double riskPcnt; // e.g. max adverse move, positive magnitude
  final double height;
  final double barWidth;
  final bool showLabels;
  const RiskRewardBar({
    super.key,
    required this.rewardPcnt,
    required this.riskPcnt,
    this.height = 56,
    this.barWidth = 10,
    this.showLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    final c = atlasColors(context);
    final t = atlasText(context);
    final reward = rewardPcnt.abs();
    final risk = riskPcnt.abs();
    final maxVal = [reward, risk, 0.01].reduce((a, b) => a > b ? a : b);

    // Account for the 1.5px divider in the height calculation
    final dividerThickness = 1.5;
    final availableHeight = height - dividerThickness;
    final half = availableHeight / 2;
    final rewardH = (reward / maxVal) * half;
    final riskH = (risk / maxVal) * half;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabels)
          Text('+${reward.toStringAsFixed(2)}%',
              style: t.caption.copyWith(color: c.bull, fontSize: 10)),
        if (showLabels) const SizedBox(height: 3),
        SizedBox(
          height: height,
          width: barWidth + 8,
          child: Column(
            children: [
              SizedBox(
                height: half,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: rewardH.clamp(2, half),
                    width: barWidth,
                    decoration: BoxDecoration(
                      color: c.bull,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ),
                ),
              ),
              Container(height: 1.5, width: barWidth + 8, color: c.border),
              SizedBox(
                height: half,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    height: riskH.clamp(2, half),
                    width: barWidth,
                    decoration: BoxDecoration(
                      color: c.bear,
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(4)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showLabels) const SizedBox(height: 3),
        if (showLabels)
          Text('-${risk.toStringAsFixed(2)}%',
              style: t.caption.copyWith(color: c.bear, fontSize: 10)),
      ],
    );
  }
}

/// A row of small metric chips — for the 3-4 secondary numbers that support
/// the hero stat without competing with it.
class StatChipRow extends StatelessWidget {
  final List<StatChip> chips;
  const StatChipRow({super.key, required this.chips});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < chips.length; i++) ...[
          Expanded(child: chips[i]),
          if (i != chips.length - 1) const SizedBox(width: Sp.sm),
        ],
      ],
    );
  }
}

class StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final IconData? icon;
  const StatChip({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final c = atlasColors(context);
    final t = atlasText(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: Sp.sm, horizontal: Sp.sm),
      decoration: BoxDecoration(
        color: c.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: c.textFaint),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(label,
                  style: t.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
          ]),
          const SizedBox(height: 4),
          Text(value,
              style:
                  t.numberMd.copyWith(color: valueColor ?? t.numberMd.color)),
        ],
      ),
    );
  }
}

/// Section header with optional (i) button — replaces the old bordered
/// "SectionLabel" with something lighter.
class AtlasSectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final String? trailingText;
  final VoidCallback? onInfoTap;
  final String? infoTitle;
  final Widget Function(BuildContext)? infoBuilder;
  const AtlasSectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.trailingText,
    this.onInfoTap,
    this.infoTitle,
    this.infoBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final c = atlasColors(context);
    final t = atlasText(context);
    return Padding(
      padding: const EdgeInsets.only(top: Sp.lg, bottom: Sp.sm),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: c.accent),
            const SizedBox(width: 6),
          ],
          Expanded(child: Text(title, style: t.h2)),
          if (trailingText != null) Text(trailingText!, style: t.bodyMuted),
          if (infoBuilder != null)
            InfoButton(title: infoTitle ?? title, bodyBuilder: infoBuilder!),
          if (onInfoTap != null && infoBuilder == null)
            IconButton(
              icon: Icon(Icons.info_outline_rounded,
                  size: 17, color: c.textFaint),
              onPressed: onInfoTap,
            ),
        ],
      ),
    );
  }
}

/// Direction pill (Bull/Bear) — small, consistent everywhere.
class DirectionPill extends StatelessWidget {
  final String direction;
  final bool compact;
  const DirectionPill(this.direction, {super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final c = atlasColors(context);
    final isBull = direction == 'Bull';
    final color = isBull ? c.bull : c.bear;
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 9, vertical: compact ? 2 : 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
              isBull
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              size: compact ? 11 : 12,
              color: color),
          const SizedBox(width: 3),
          Text(direction,
              style: TextStyle(
                  color: color,
                  fontSize: compact ? 10 : 11,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// Small pill showing relative + absolute time together, e.g. "3h ago".
/// Tap-friendly tooltip reveals the exact timestamp.
class TimeAgoChip extends StatelessWidget {
  final DateTime dt;
  final String? exactLabel;
  const TimeAgoChip(this.dt, {super.key, this.exactLabel});

  @override
  Widget build(BuildContext context) {
    final c = atlasColors(context);
    final t = atlasText(context);
    return Tooltip(
      message: exactLabel ?? dt.toString(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule_rounded, size: 11, color: c.textFaint),
          const SizedBox(width: 3),
          Text(timeAgoShort(dt), style: t.caption),
        ],
      ),
    );
  }
}

/// Generic rounded card container — soft shadow instead of a flat border
/// only, slightly larger radius for a more modern feel.
class AtlasCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  const AtlasCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Sp.lg),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = atlasColors(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: Sp.sm),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.border),
        boxShadow: c.cardShadow(),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// A card that expands in place to reveal more rows — the replacement for
/// wide DataTables. Collapsed by default; header always shows the essentials.
class ExpandableCard extends StatefulWidget {
  final Widget header;
  final Widget details;
  final bool initiallyExpanded;
  const ExpandableCard({
    super.key,
    required this.header,
    required this.details,
    this.initiallyExpanded = false,
  });

  @override
  State<ExpandableCard> createState() => _ExpandableCardState();
}

class _ExpandableCardState extends State<ExpandableCard> {
  late bool _open = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final c = atlasColors(context);
    return AtlasCard(
      padding: const EdgeInsets.all(Sp.md),
      // onTap: removed from here            // <-- REMOVE card-wide onTap
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            // <-- ADD: scoped just to header
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  vertical: 4), // small hit-area padding
              child: Row(
                children: [
                  Expanded(child: widget.header),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(Icons.keyboard_arrow_down_rounded,
                        color: c.textFaint, size: 20),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 180),
            crossFadeState:
                _open ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.only(top: Sp.md),
              child: widget.details,
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

/// Compact key/value row used inside expanded details.
class KvRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final IconData? icon;
  const KvRow(this.label, this.value, {super.key, this.valueColor, this.icon});

  @override
  Widget build(BuildContext context) {
    final c = atlasColors(context);
    final t = atlasText(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: c.textFaint),
              const SizedBox(width: 5),
            ],
            Text(label, style: t.bodyMuted),
          ]),
          Text(value,
              style:
                  t.numberSm.copyWith(color: valueColor ?? t.numberSm.color)),
        ],
      ),
    );
  }
}

class AtlasEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  const AtlasEmptyState({
    super.key,
    this.icon = Icons.inbox_rounded,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final c = atlasColors(context);
    final t = atlasText(context);
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.symmetric(vertical: Sp.xxl, horizontal: Sp.lg),
        child: Column(
          mainAxisSize:
              MainAxisSize.min, // <-- ADD (don't force max height either)

          children: [
            Icon(icon, size: 36, color: c.textFaint),
            const SizedBox(height: Sp.md),
            Text(title, style: t.h2, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(message, style: t.bodyMuted, textAlign: TextAlign.center),
            if (actionLabel != null) ...[
              const SizedBox(height: Sp.lg),
              OutlinedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.tune_rounded, size: 16),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AtlasChipToggle extends StatelessWidget {
  final String label;
  final bool selected;
  final Color activeColor;
  final ValueChanged<bool> onChanged;
  final IconData? icon;
  const AtlasChipToggle({
    super.key,
    required this.label,
    required this.selected,
    required this.onChanged,
    this.activeColor = Colors.blue,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final c = atlasColors(context);
    return ChoiceChip(
      avatar: icon != null
          ? Icon(icon,
              size: 15, color: selected ? activeColor : c.textSecondary)
          : null,
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: onChanged,
      selectedColor: activeColor.withOpacity(0.18),
      backgroundColor: c.surfaceAlt,
      labelStyle: TextStyle(
        color: selected ? activeColor : c.textSecondary,
        fontWeight: FontWeight.w600,
        fontSize: 12.5,
      ),
      side: BorderSide(color: selected ? activeColor : c.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}

/// Thin gradient loader for when data is being fetched — a touch more
/// modern than a flat single-color bar.
class AtlasLoadingBar extends StatelessWidget {
  const AtlasLoadingBar({super.key});
  @override
  Widget build(BuildContext context) {
    final c = atlasColors(context);
    return SizedBox(
      height: 2.5,
      child: LinearProgressIndicator(
        backgroundColor: c.surfaceAlt,
        valueColor: AlwaysStoppedAnimation(c.accent),
      ),
    );
  }
}
