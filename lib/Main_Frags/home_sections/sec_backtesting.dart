import 'package:flutter/material.dart';
import 'package:optionxi/Components/cust_upgrade_to_pro.dart';

/// Backtesting entry point for the homepage.
///
/// In plain words: "Did our calls actually work?"
///
/// Tapping the card opens a sheet with three track-record reports:
///   • Nifty      → were our up/down calls on the market right?
///   • Scanner    → did stocks our scanners flagged actually move?
///   • AI Picks   → did the stocks our AI shortlisted do well afterwards?
///
/// Each report row shows a one-line summary. A small "Explain it simply"
/// toggle opens a friendly explanation + example, so nobody is forced to
/// read it, but it is always one tap away.
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
    this.height = 136,
  });

  final VoidCallback? onNiftyTap;
  final VoidCallback? onAiPicksTap;
  final VoidCallback? onScreenerTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final radius = BorderRadius.circular(26);

    return SizedBox(
      height: height,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _a(cs.primary, isDark ? 0.20 : 0.10),
                _a(cs.primary, isDark ? 0.04 : 0.02),
              ],
            ),
            border: Border.all(
              color: _a(cs.primary, isDark ? 0.28 : 0.14),
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: _a(cs.primary, 0.08),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: () => _openBacktestSheet(
              context,
              onNiftyTap: onNiftyTap,
              onAiPicksTap: onAiPicksTap,
              onScreenerTap: onScreenerTap,
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: Stack(
                children: [
                  // Decorative sparkline, purely visual (not real data).
                  Positioned(
                    right: 0,
                    bottom: 20,
                    width: 170,
                    height: 76,
                    child: CustomPaint(
                      painter: _SparklinePainter(color: cs.primary),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'See our track record',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'See how our past calls really turned out',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: _a(cs.onSurface, 0.62),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: cs.primary,
                              ),
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                size: 18,
                                color: cs.onPrimary,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const _IconStack(),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                'Nifty, Scanner and AI Picks',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: _a(cs.onSurface, 0.75),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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

// ─────────────────────────────────────────────────────────────────────────────
// Shared bits
// ─────────────────────────────────────────────────────────────────────────────

const Color _kNifty = Color(0xFF3B82F6);
const Color _kScanner = Color(0xFF10B981);
const Color _kAi = Color(0xFF8B5CF6);

/// Opacity helper that works on every Flutter version.
Color _a(Color c, double opacity) =>
    c.withAlpha((opacity.clamp(0.0, 1.0) * 255).round());

/// Three small overlapping icons, one per report.
class _IconStack extends StatelessWidget {
  const _IconStack();

  static const _size = 28.0;
  static const _step = 20.0;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = <(IconData, Color)>[
      (Icons.show_chart_rounded, _kNifty),
      (Icons.radar_rounded, _kScanner),
      (Icons.auto_awesome_rounded, _kAi),
    ];

    return SizedBox(
      width: _size + _step * (items.length - 1),
      height: _size,
      child: Stack(
        children: [
          for (var i = 0; i < items.length; i++)
            Positioned(
              left: i * _step,
              child: Container(
                width: _size,
                height: _size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color.alphaBlend(_a(items[i].$2, 0.22), cs.surface),
                  border: Border.all(color: cs.surface, width: 2),
                ),
                child: Icon(items[i].$1, size: 14, color: items[i].$2),
              ),
            ),
        ],
      ),
    );
  }
}

/// Soft, smooth line with a faded fill, used as a background flourish.
class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.color});

  final Color color;

  static const _points = [0.28, 0.40, 0.33, 0.52, 0.44, 0.62, 0.55, 0.78, 0.88];

  @override
  void paint(Canvas canvas, Size size) {
    const padX = 8.0;
    const padY = 10.0;
    final dx = (size.width - padX) / (_points.length - 1);

    Offset at(int i) => Offset(
          i * dx,
          padY + (size.height - padY * 2) * (1 - _points[i]),
        );

    final line = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < _points.length; i++) {
      final a = at(i - 1);
      final b = at(i);
      final mx = (a.dx + b.dx) / 2;
      line.cubicTo(mx, a.dy, mx, b.dy, b.dx, b.dy);
    }

    final fill = Path.from(line)
      ..lineTo(at(_points.length - 1).dx, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_a(color, 0.22), _a(color, 0.0)],
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      line,
      Paint()
        ..color = _a(color, 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );

    final end = at(_points.length - 1);
    canvas.drawCircle(end, 6, Paint()..color = _a(color, 0.18));
    canvas.drawCircle(end, 3.2, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SparklinePainter old) => old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

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
    useSafeArea: true,
    builder: (_) => _BacktestOptionsSheet(
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

    void go(VoidCallback? cb) {
      Navigator.of(context).pop();
      cb?.call();
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: _a(cs.onSurface, 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Text(
              'Did our calls work?',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Every call we make is checked against what really happened '
              'afterwards. Pick a report to see the score.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: _a(cs.onSurface, 0.62),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            const _ProcessStrip(),
            const SizedBox(height: 16),
            _ReportCard(
              icon: Icons.show_chart_rounded,
              color: _kNifty,
              title: 'Nifty',
              summary: 'When we said the market would go up or down, '
                  'were we right?',
              explainer: 'We tell you how sure we are about Nifty\'s next '
                  'move, for example "70% sure it goes up". Then we wait '
                  '5 to 15 minutes and see what really happened. This '
                  'report shows how often we were right.',
              example: 'Out of every time we were 70% or more sure of a '
                  'rise, how many times did Nifty really rise?',
              note: 'Result checked 5 to 15 minutes later',
              onTap: () => go(onNiftyTap),
            ),
            const SizedBox(height: 12),
            _ReportCard(
              icon: Icons.radar_rounded,
              color: _kScanner,
              title: 'Scanner',
              summary: 'Stocks we flagged as interesting. Did they really '
                  'move?',
              explainer: 'Our scanners watch the market and raise a flag '
                  'when a stock does something unusual, like a sudden burst '
                  'of trading or its highest price in a year. When many '
                  'flags go off on the same stock, it deserves a closer '
                  'look. This report shows what happened next.',
              example: 'Stocks flagged by 3 or more scanners today: how '
                  'did they do afterwards?',
              note: 'Tracks each stock after it was flagged',
              onTap: () => go(onScreenerTap),
            ),
            const SizedBox(height: 12),
            _ReportCard(
              icon: Icons.auto_awesome_rounded,
              color: _kAi,
              title: 'AI Picks',
              summary: 'Our AI\'s shortlist of stocks. How did they do '
                  'afterwards?',
              explainer: 'The AI shortlists stocks that many scanners '
                  'agree on and that are also pushing past today\'s highest '
                  'or lowest price so far. Lots of signals pointing the '
                  'same way is a good sign. This report checks whether '
                  'those picks really moved as expected.',
              example: '8 out of 10 picks moved the way we expected.',
              note: 'Checked shortly after and again by end of day',
              onTap: () => go(onAiPicksTap),
            ),
            const SizedBox(height: 18),
            Center(
              child: Text(
                'Past results do not guarantee future returns.',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: _a(cs.onSurface, 0.45),
                ),
              ),
            ),
            const SizedBox(height: 14),
            ProUpgradeButton(),
          ],
        ),
      ),
    );
  }
}

/// "We make a call → time passes → we check" in three quick steps.
class _ProcessStrip extends StatelessWidget {
  const _ProcessStrip();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    Widget step(IconData icon, String label) => Expanded(
          child: Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _a(cs.primary, isDark ? 0.22 : 0.12),
                ),
                child: Icon(icon, size: 18, color: cs.primary),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _a(cs.onSurface, 0.75),
                  height: 1.25,
                ),
              ),
            ],
          ),
        );

    Widget arrow() => Padding(
          padding: const EdgeInsets.only(bottom: 22),
          child: Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: _a(cs.onSurface, 0.3),
          ),
        );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: _a(cs.onSurface, isDark ? 0.05 : 0.035),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          step(Icons.flag_rounded, 'We make a call'),
          arrow(),
          step(Icons.schedule_rounded, 'Time passes'),
          arrow(),
          step(Icons.fact_check_rounded, 'We check the result'),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Report card
// ─────────────────────────────────────────────────────────────────────────────

/// One report row.
///
/// Tap the top part to open the report. Tap "Explain it simply" to expand
/// the friendly explanation in place. The two are separate tap targets, so
/// reading never accidentally navigates away.
class _ReportCard extends StatefulWidget {
  const _ReportCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.summary,
    required this.explainer,
    required this.example,
    required this.note,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String summary;
  final String explainer;
  final String example;
  final String note;
  final VoidCallback onTap;

  @override
  State<_ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<_ReportCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final color = widget.color;

    return Material(
      color: _a(cs.onSurface, isDark ? 0.05 : 0.035),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: _a(cs.onSurface, 0.07)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Main tap area → opens the report.
          InkWell(
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color,
                          Color.lerp(color, Colors.black, 0.18)!,
                        ],
                      ),
                    ),
                    child: Icon(widget.icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.summary,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _a(cs.onSurface, 0.65),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _a(color, isDark ? 0.22 : 0.12),
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(height: 1, color: _a(cs.onSurface, 0.06)),
          ),
          // Toggle → expands the plain-English explanation.
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                children: [
                  Icon(Icons.help_outline_rounded, size: 16, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _expanded ? 'Hide explanation' : 'Explain it simply',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(14, 2, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.explainer,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _a(cs.onSurface, 0.72),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _a(color, isDark ? 0.14 : 0.08),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.lightbulb_outline_rounded,
                                size: 16,
                                color: color,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'For example',
                                      style:
                                          theme.textTheme.labelSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: color,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      widget.example,
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: _a(cs.onSurface, 0.75),
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 13,
                              color: _a(cs.onSurface, 0.45),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                widget.note,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: _a(cs.onSurface, 0.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}
