import 'package:flutter/material.dart';
import 'package:optionxi/Components/cust_upgrade_to_pro.dart';

/// A fixed-height, theme-aware "Backtesting" section for the homepage.
///
/// This links out to three existing report screens:
///   • Nifty    → "Atlas x Nifty" — direction-confidence calls (e.g. "70%
///                bullish") checked against what actually happened in the
///                next 5–15 minute window.
///   • Scanner  → "Screener History" — stocks flagged by scanners (volume
///                jump, 52-week breakout, weekly breakout, etc.), especially
///                ones flagged by several scanners at once.
///   • AI Picks → "AI Picks Portfolio" — stocks the AI shortlisted using
///                scanner count + current-day high/low breakout strength,
///                checked against what happened next.
///
/// The homepage card and the option list below only show a one-line,
/// plain-English summary of each. The fuller "how this works" explanation
/// (the part that could feel like data overload) sits behind a small
/// expandable toggle on each row, so nobody is forced to read it.
///
/// ```dart
/// BacktestingSection(
///   onNiftyTap: () => Navigator.pushNamed(context, '/backtest/nifty'),
///   onAiPicksTap: () => Navigator.pushNamed(context, '/backtest/ai-picks'),
///   onScreenerTap: () => Navigator.pushNamed(context, '/backtest/screener'),
/// )
/// ```
class BacktestingSection extends StatelessWidget {
  const BacktestingSection({
    super.key,
    this.onNiftyTap,
    this.onAiPicksTap,
    this.onScreenerTap,
    this.height = 128,
  });

  final VoidCallback? onNiftyTap;
  final VoidCallback? onAiPicksTap;
  final VoidCallback? onScreenerTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _openBacktestSheet(
          context,
          onNiftyTap: onNiftyTap,
          onAiPicksTap: onAiPicksTap,
          onScreenerTap: onScreenerTap,
        ),
        child: Container(
          height: height,
          padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [cs.primary.withOpacity(0.22), cs.primary.withOpacity(0.06)]
                  : [
                      cs.primary.withOpacity(0.12),
                      cs.primary.withOpacity(0.03)
                    ],
            ),
            border: Border.all(
              color: cs.primary.withOpacity(isDark ? 0.30 : 0.16),
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -6,
                bottom: -6,
                child: Opacity(
                  opacity: isDark ? 0.10 : 0.07,
                  child: Icon(
                    Icons.show_chart_rounded,
                    size: 96,
                    color: cs.primary,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cs.primary.withOpacity(isDark ? 0.24 : 0.12),
                        ),
                        child: Icon(Icons.query_stats_rounded,
                            color: cs.primary, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Backtesting',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Did our calls actually play out? Check the track record',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cs.surface.withOpacity(isDark ? 0.35 : 0.7),
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _PreviewChip(
                        icon: Icons.show_chart_rounded,
                        color: const Color(0xFF3B82F6),
                        label: 'Nifty',
                      ),
                      const SizedBox(width: 8),
                      _PreviewChip(
                        icon: Icons.filter_alt_rounded,
                        color: const Color(0xFF10B981),
                        label: 'Scanner',
                      ),
                      const SizedBox(width: 8),
                      _PreviewChip(
                        icon: Icons.auto_awesome_rounded,
                        color: const Color(0xFF8B5CF6),
                        label: 'AI Picks',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewChip extends StatelessWidget {
  const _PreviewChip({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(isDark ? 0.35 : 0.75),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

void _openBacktestSheet(
  BuildContext context, {
  VoidCallback? onNiftyTap,
  VoidCallback? onAiPicksTap,
  VoidCallback? onScreenerTap,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _BacktestOptionsSheet(
      onNiftyTap: onNiftyTap,
      onAiPicksTap: onAiPicksTap,
      onScreenerTap: onScreenerTap,
    ),
  );
}

class _BacktestOptionsSheet extends StatelessWidget {
  const _BacktestOptionsSheet({
    this.onNiftyTap,
    this.onAiPicksTap,
    this.onScreenerTap,
  });

  final VoidCallback? onNiftyTap;
  final VoidCallback? onAiPicksTap;
  final VoidCallback? onScreenerTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: cs.onSurface.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Text(
            'Backtest Performance',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Every call we make gets checked against what actually '
            'happened next. Pick a report to see the track record.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurface.withOpacity(0.6),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          _OptionTile(
            icon: Icons.show_chart_rounded,
            iconColor: const Color(0xFF3B82F6), // blue
            title: 'Nifty',
            shortDescription: 'How accurate our bullish/bearish calls are',
            howItWorks:
                'Our algorithm scores Nifty\'s next move as a confidence % '
                '— like "70% bullish". This report checks how often calls '
                'at a given confidence actually moved that way within the '
                'next 5–15 minutes.',
            example: 'e.g. "Of all 70%+ bullish calls, how many went up?"',
            onTap: () {
              Navigator.of(context).pop();
              onNiftyTap?.call();
            },
          ),
          const SizedBox(height: 10),
          _OptionTile(
            icon: Icons.filter_alt_rounded,
            iconColor: const Color(0xFF10B981), // green
            title: 'Scanner',
            shortDescription: 'How often flagged stocks actually moved',
            howItWorks: 'Scanners flag stocks for things like a volume jump, a '
                '52-week high, or a breakout from the week\'s range. A '
                'stock flagged by several scanners at once tends to have '
                'a stronger chance of moving — this shows how that '
                'played out.',
            example: 'e.g. "Stocks flagged by 3+ scanners today"',
            onTap: () {
              Navigator.of(context).pop();
              onScreenerTap?.call();
            },
          ),
          const SizedBox(height: 10),
          _OptionTile(
            icon: Icons.auto_awesome_rounded,
            iconColor: const Color(0xFF8B5CF6), // purple
            title: 'AI Picks',
            shortDescription: 'How our shortlisted stocks performed after',
            howItWorks:
                'A pick combines how many scanners a stock triggered with '
                'the strength of its current-day high/low breakout — '
                'together they signal a stronger move. This tracks '
                'whether that combination paid off in the next window or '
                'across the day.',
            example: 'e.g. "8 of 10 AI picks hit their target"',
            onTap: () {
              Navigator.of(context).pop();
              onAiPicksTap?.call();
            },
          ),
          const SizedBox(height: 20),
          ProUpgradeButton(),
        ],
      ),
    );
  }
}

/// A single backtest option row.
///
/// Tapping the main body (icon, title, short description) navigates to the
/// report, exactly like before. Tapping "How this works" instead expands an
/// inline explanation in place — so the extra detail is one tap away but
/// never forced on anyone by default.
class _OptionTile extends StatefulWidget {
  const _OptionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.shortDescription,
    required this.howItWorks,
    required this.onTap,
    this.example,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String shortDescription;
  final String howItWorks;
  final String? example;
  final VoidCallback onTap;

  @override
  State<_OptionTile> createState() => _OptionTileState();
}

class _OptionTileState extends State<_OptionTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;

    return Material(
      color: isDark
          ? Colors.white.withOpacity(0.04)
          : Colors.black.withOpacity(0.03),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.iconColor.withOpacity(isDark ? 0.22 : 0.12),
                    ),
                    child: Icon(widget.icon, color: widget.iconColor, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.shortDescription,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurface.withOpacity(0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: cs.onSurface.withOpacity(0.35),
                  ),
                ],
              ),
            ),
          ),
          // "How this works" toggle — separate tap target from the row
          // above, so expanding detail never accidentally navigates away.
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Row(
                children: [
                  const SizedBox(width: 58),
                  Text(
                    _expanded ? 'Hide details' : 'How this works',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: widget.iconColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 16,
                    color: widget.iconColor,
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 58),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.howItWorks,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurface.withOpacity(0.6),
                              height: 1.4,
                            ),
                          ),
                          if (widget.example != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: widget.iconColor
                                    .withOpacity(isDark ? 0.14 : 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                widget.example!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                  color: cs.onSurface.withOpacity(0.55),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}
