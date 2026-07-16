import 'dart:math';
import 'package:flutter/material.dart';
import 'package:optionxi/Components/cust_ai_chooser_component.dart';
import 'package:optionxi/Main_Pages/AIPages/act_ai_optionxi.dart';
import 'package:optionxi/Main_Pages/AISummary/act_nifty_ai_summary.dart';
import 'package:optionxi/Main_Pages/AISummary/act_stock_ai_summary.dart';

// ─────────────────────────────────────────────
//  Theme-aware color tokens
// ─────────────────────────────────────────────
class _CardTheme {
  final Color cardBgStart;
  final Color cardBgEnd;
  final Color tagBg;
  final Color titleColor;
  final Color subtitleColor;
  final Color borderBase;

  const _CardTheme({
    required this.cardBgStart,
    required this.cardBgEnd,
    required this.tagBg,
    required this.titleColor,
    required this.subtitleColor,
    required this.borderBase,
  });

  static _CardTheme of(BuildContext context, Color accent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return _CardTheme(
        cardBgStart: const Color(0xFF111827),
        cardBgEnd: const Color(0xFF0D1520),
        tagBg: accent.withOpacity(0.14),
        titleColor: const Color(0xFFF1F5F9),
        subtitleColor: const Color(0xFF94A3B8),
        borderBase: accent.withOpacity(0.12),
      );
    } else {
      return _CardTheme(
        cardBgStart: Colors.white,
        cardBgEnd: const Color(0xFFF8FAFC),
        tagBg: accent.withOpacity(0.10),
        titleColor: const Color(0xFF0F172A),
        subtitleColor: const Color(0xFF64748B),
        borderBase: accent.withOpacity(0.18),
      );
    }
  }
}

// ─────────────────────────────────────────────
//  Section
// ─────────────────────────────────────────────
class AiSentimentSection extends StatelessWidget {
  const AiSentimentSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6E3BF6), Color(0xFF0CC8A8)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'AI Intelligence',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFFF1F5F9)
                      : const Color(0xFF0F172A),
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _SentimentCard(
            title: 'Market Pulse',
            subtitle: 'Overall market mood & nifty breakouts',
            tag: 'NIFTY 50',
            accentColor: const Color(0xFF0CC8A8),
            badge: _CardBadge.newBadge,
            icon: const _PulseIcon(),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NiftyAiSummaryPage(),
                  ));
            },
          ),
          const SizedBox(height: 10),
          _SentimentCard(
            title: 'Stock Sentiment',
            subtitle: 'AI reads techincals, finanicals & breakout signals',
            tag: 'STOCKS',
            accentColor: const Color(0xFF7B4FE0),
            badge: _CardBadge.beta,
            icon: const _BrainIcon(),
            onTap: () {
              showAIActionSheet(
                context,
                startOnSearch: true, // ← no _Step needed, no import issues
                onChat: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(),
                    )),
                onAnalyse: (symbol) => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StockAiAnalysisPage(symbol: symbol),
                    )),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Badge type
// ─────────────────────────────────────────────
enum _CardBadge { newBadge, beta }

// ─────────────────────────────────────────────
//  Individual card
// ─────────────────────────────────────────────
class _SentimentCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String tag;
  final Color accentColor;
  final Widget icon;
  final VoidCallback onTap;
  final _CardBadge? badge;

  const _SentimentCard({
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.accentColor,
    required this.icon,
    required this.onTap,
    this.badge,
  });

  @override
  State<_SentimentCard> createState() => _SentimentCardState();
}

class _SentimentCardState extends State<_SentimentCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = _CardTheme.of(context, widget.accentColor);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            return CustomPaint(
              painter: _GlowBorderPainter(
                _ctrl.value,
                widget.accentColor,
                isDark: isDark,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [theme.cardBgStart, theme.cardBgEnd],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      // Subtle shadow for light mode depth
                      boxShadow: isDark
                          ? [
                              BoxShadow(
                                color: widget.accentColor.withOpacity(0.06),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                              BoxShadow(
                                color: widget.accentColor.withOpacity(0.08),
                                blurRadius: 20,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Row(
                      children: [
                        // Left: text content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Tag pill
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: theme.tagBg,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  widget.tag,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: widget.accentColor,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Title
                              Text(
                                widget.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: theme.titleColor,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 3),
                              // Subtitle
                              Text(
                                widget.subtitle,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: theme.subtitleColor,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 12),
                              // CTA row
                              Row(
                                children: [
                                  Text(
                                    'Analyse',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: widget.accentColor,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.arrow_forward_rounded,
                                      size: 12, color: widget.accentColor),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Right: animated icon
                        SizedBox(width: 54, height: 54, child: widget.icon),
                      ],
                    ),
                  ),
                  // Top-right badge
                  if (widget.badge != null)
                    Positioned(
                      top: -1,
                      right: 12,
                      child: _BadgeWidget(
                        badge: widget.badge!,
                        accentColor: widget.accentColor,
                        isDark: isDark,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Top-right badge widget
// ─────────────────────────────────────────────
class _BadgeWidget extends StatefulWidget {
  final _CardBadge badge;
  final Color accentColor;
  final bool isDark;

  const _BadgeWidget({
    required this.badge,
    required this.accentColor,
    required this.isDark,
  });

  @override
  State<_BadgeWidget> createState() => _BadgeWidgetState();
}

class _BadgeWidgetState extends State<_BadgeWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _shimmer = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.badge == _CardBadge.newBadge;
    final label = isNew ? 'NEW' : 'BETA';

    // NEW → amber/gold, BETA → uses card accent
    final Color badgeColor =
        isNew ? const Color(0xFFF59E0B) : widget.accentColor;
    final Color bgColor = isNew
        ? (widget.isDark ? const Color(0xFF2D1F00) : const Color(0xFFFFF7E6))
        : (widget.isDark
            ? badgeColor.withOpacity(0.15)
            : badgeColor.withOpacity(0.10));

    return AnimatedBuilder(
      animation: _shimmer,
      builder: (_, __) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(6),
              bottomRight: Radius.circular(6),
              topLeft: Radius.circular(2),
              topRight: Radius.circular(2),
            ),
            border: Border.all(
              color: badgeColor.withOpacity(widget.isDark ? 0.35 : 0.30),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: badgeColor.withOpacity(0.25 + _shimmer.value * 0.15),
                blurRadius: 8 + _shimmer.value * 4,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isNew)
                Padding(
                  padding: const EdgeInsets.only(right: 3),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: 8,
                    color: badgeColor,
                  ),
                ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  color: badgeColor,
                  letterSpacing: 1.1,
                  height: 1.0,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
//  Rotating glow border painter
// ─────────────────────────────────────────────
class _GlowBorderPainter extends CustomPainter {
  final double progress;
  final Color accent;
  final bool isDark;

  _GlowBorderPainter(this.progress, this.accent, {required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    const radius = Radius.circular(16);
    final rrect = RRect.fromRectAndRadius(rect, radius);
    final angle = progress * 2 * pi;

    // In light mode, tone down the glow significantly
    final maxOpacity = isDark ? 0.85 : 0.5;

    final gradient = SweepGradient(
      colors: [
        accent.withOpacity(0.0),
        accent.withOpacity(maxOpacity * 0.5),
        accent.withOpacity(maxOpacity),
        accent.withOpacity(maxOpacity * 0.4),
        accent.withOpacity(0.0),
      ],
      stops: const [0.0, 0.2, 0.45, 0.65, 1.0],
      transform: GradientRotation(angle),
    );

    // Crisp border line
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Soft glow halo (less intense in light mode)
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isDark ? 3.5 : 2.5
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, isDark ? 6 : 4),
    );
  }

  @override
  bool shouldRepaint(_GlowBorderPainter old) =>
      old.progress != progress || old.isDark != isDark;
}

// ─────────────────────────────────────────────
//  Pulse wave icon (Market Pulse)
// ─────────────────────────────────────────────
class _PulseIcon extends StatefulWidget {
  const _PulseIcon();

  @override
  State<_PulseIcon> createState() => _PulseIconState();
}

class _PulseIconState extends State<_PulseIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return CustomPaint(
          painter: _PulseWavePainter(_ctrl.value, isDark: isDark),
        );
      },
    );
  }
}

class _PulseWavePainter extends CustomPainter {
  final double t;
  final bool isDark;
  _PulseWavePainter(this.t, {required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    const accent = Color(0xFF0CC8A8);
    final w = size.width;
    final h = size.height;
    final mid = h / 2;

    final path = Path();
    final points = [
      Offset(0, mid),
      Offset(w * 0.18, mid),
      Offset(w * 0.28, mid - h * 0.30),
      Offset(w * 0.38, mid + h * 0.34),
      Offset(w * 0.50, mid - h * 0.44),
      Offset(w * 0.60, mid + h * 0.10),
      Offset(w * 0.70, mid),
      Offset(w, mid),
    ];

    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    final baseOpacity = isDark ? 0.18 : 0.25;

    // Base dim line
    canvas.drawPath(
      path,
      Paint()
        ..color = accent.withOpacity(baseOpacity)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Traveling highlight
    final metrics = path.computeMetrics().first;
    final total = metrics.length;
    final end = (t * total).clamp(0.0, total);
    final start = (end - total * 0.28).clamp(0.0, total);

    if (end > start) {
      final highlight = metrics.extractPath(start, end);
      canvas.drawPath(
        highlight,
        Paint()
          ..color = accent
          ..strokeWidth = 1.8
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
      );
    }
  }

  @override
  bool shouldRepaint(_PulseWavePainter old) =>
      old.t != t || old.isDark != isDark;
}

// ─────────────────────────────────────────────
//  Neural icon (Stock Sentiment)
// ─────────────────────────────────────────────
class _BrainIcon extends StatefulWidget {
  const _BrainIcon();

  @override
  State<_BrainIcon> createState() => _BrainIconState();
}

class _BrainIconState extends State<_BrainIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return CustomPaint(
          painter: _NeuralDotsPainter(_ctrl.value, isDark: isDark),
        );
      },
    );
  }
}

class _NeuralDotsPainter extends CustomPainter {
  final double t;
  final bool isDark;
  _NeuralDotsPainter(this.t, {required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    const color = Color(0xFF7B4FE0);

    final lineOpacity = isDark ? 0.22 : 0.30;
    final nodeBaseOpacity = isDark ? 0.55 : 0.65;

    final linePaint = Paint()
      ..color = color.withOpacity(lineOpacity)
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke;

    final nodes = [
      Offset(size.width * 0.15, size.height * 0.22),
      Offset(size.width * 0.50, size.height * 0.08),
      Offset(size.width * 0.85, size.height * 0.22),
      Offset(size.width * 0.08, size.height * 0.62),
      Offset(size.width * 0.50, size.height * 0.50),
      Offset(size.width * 0.92, size.height * 0.62),
      Offset(size.width * 0.28, size.height * 0.90),
      Offset(size.width * 0.72, size.height * 0.90),
    ];

    const connections = [
      [0, 1],
      [1, 2],
      [0, 3],
      [1, 4],
      [2, 5],
      [3, 4],
      [4, 5],
      [3, 6],
      [4, 7],
      [5, 7],
    ];

    for (final conn in connections) {
      canvas.drawLine(nodes[conn[0]], nodes[conn[1]], linePaint);
    }

    // Traveling pulse dot
    final activeIdx = (t * connections.length).floor() % connections.length;
    final frac = (t * connections.length) % 1.0;
    final activeConn = connections[activeIdx];
    final from = nodes[activeConn[0]];
    final to = nodes[activeConn[1]];
    final lerped = Offset.lerp(from, to, frac)!;

    canvas.drawCircle(
      lerped,
      2.8,
      Paint()
        ..color = color.withOpacity(isDark ? 0.9 : 0.8)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, isDark ? 3.5 : 2.5),
    );

    // Static nodes with breathing pulse
    for (int i = 0; i < nodes.length; i++) {
      final pulse = (sin(t * 2 * pi + i * 0.9) * 0.25 + 0.75);
      canvas.drawCircle(
        nodes[i],
        2.0,
        Paint()..color = color.withOpacity(nodeBaseOpacity * pulse),
      );
    }
  }

  @override
  bool shouldRepaint(_NeuralDotsPainter old) =>
      old.t != t || old.isDark != isDark;
}
