import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:optionxi/Components/cust_ai_chooser_component.dart';
import 'package:optionxi/Main_Pages/AIPages/act_ai_optionxi.dart';
import 'package:optionxi/Main_Pages/AISummary/act_nifty_ai_summary.dart';
import 'package:optionxi/Main_Pages/AISummary/act_stock_ai_summary.dart';

// ─────────────────────────────────────────────
//  Tokens
// ─────────────────────────────────────────────
class _Palette {
  static const violet = Color(0xFF7B4FE0);
  static const teal = Color(0xFF0CC8A8);
  static const amber = Color(0xFFF59E0B);

  // Banner is intentionally dark in both themes – it's the "hero" moment.
  static const bannerA = Color(0xFF160F3A);
  static const bannerB = Color(0xFF0A2733);
}

const double _kBannerHeight = 136;
const double _kBannerRadius = 24;

// ─────────────────────────────────────────────
//  Public section  (drop-in replacement)
// ─────────────────────────────────────────────
class AiSentimentSection extends StatelessWidget {
  const AiSentimentSection({super.key});

  void _openSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (sheetCtx) => _AiSheet(
        onMarketPulse: () {
          Navigator.pop(sheetCtx);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => NiftyAiSummaryPage()),
          );
        },
        onStockSentiment: () {
          Navigator.pop(sheetCtx);
          showAIActionSheet(
            context,
            startOnSearch: true,
            onChat: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ChatScreen()),
            ),
            onAnalyse: (symbol) => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StockAiAnalysisPage(symbol: symbol),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: _AiBanner(onTap: () => _openSheet(context)),
    );
  }
}

// ─────────────────────────────────────────────
//  Shared: tiny looping-animation helper
// ─────────────────────────────────────────────
class _Looping extends StatefulWidget {
  final Duration duration;
  final Widget Function(BuildContext context, double t) builder;

  const _Looping({required this.duration, required this.builder});

  @override
  State<_Looping> createState() => _LoopingState();
}

class _LoopingState extends State<_Looping>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration)..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (ctx, _) => widget.builder(ctx, _c.value),
      );
}

// ─────────────────────────────────────────────
//  Banner  (fixed height)
// ─────────────────────────────────────────────
class _AiBanner extends StatefulWidget {
  final VoidCallback onTap;
  const _AiBanner({required this.onTap});

  @override
  State<_AiBanner> createState() => _AiBannerState();
}

class _AiBannerState extends State<_AiBanner> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: Container(
          height: _kBannerHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_kBannerRadius),
            boxShadow: [
              BoxShadow(
                color: _Palette.violet.withOpacity(0.28),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: _Looping(
            duration: const Duration(seconds: 8),
            builder: (context, t) => CustomPaint(
              foregroundPainter: _BannerBorderPainter(t),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_kBannerRadius),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 1. Base gradient
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_Palette.bannerA, _Palette.bannerB],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    // 2. Drifting aurora glows
                    CustomPaint(painter: _AuroraPainter(t)),
                    // 3. Static dot grid (never repaints)
                    const RepaintBoundary(
                      child: CustomPaint(painter: _DotGridPainter()),
                    ),
                    // 4. Constellation + CTA on the right
                    Positioned(
                      right: 14,
                      top: 0,
                      bottom: 0,
                      width: 112,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _ConstellationPainter(t),
                            ),
                          ),
                          const _GlassArrow(),
                        ],
                      ),
                    ),
                    // 5. Copy
                    Positioned(
                      left: 20,
                      top: 0,
                      bottom: 0,
                      right: 132,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.auto_awesome_rounded,
                                  size: 14, color: _Palette.teal),
                              const SizedBox(width: 6),
                              Text(
                                'Powered by AI',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.72),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'AI Intelligence',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.6,
                                height: 1.1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Market mood and stock signals, read for you.',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.35,
                              color: Colors.white.withOpacity(0.68),
                            ),
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
      ),
    );
  }
}

class _GlassArrow extends StatelessWidget {
  const _GlassArrow();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.22),
            Colors.white.withOpacity(0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withOpacity(0.28), width: 1),
      ),
      child:
          const Icon(Icons.north_east_rounded, size: 20, color: Colors.white),
    );
  }
}

// ── Banner painters ──────────────────────────

class _AuroraPainter extends CustomPainter {
  final double t;
  const _AuroraPainter(this.t);

  void _glow(Canvas c, Offset o, double r, Color col, double op) {
    final rect = Rect.fromCircle(center: o, radius: r);
    c.drawCircle(
      o,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [col.withOpacity(op), col.withOpacity(0)],
        ).createShader(rect),
    );
  }

  @override
  void paint(Canvas canvas, Size s) {
    final a = t * 2 * pi;
    _glow(
      canvas,
      Offset(
          s.width * (0.86 + 0.05 * cos(a)), s.height * (0.22 + 0.16 * sin(a))),
      s.height * 1.15,
      _Palette.teal,
      0.50,
    );
    _glow(
      canvas,
      Offset(
          s.width * (0.10 + 0.08 * sin(a)), s.height * (0.95 + 0.10 * cos(a))),
      s.height * 1.25,
      _Palette.violet,
      0.55,
    );
  }

  @override
  bool shouldRepaint(_AuroraPainter old) => old.t != t;
}

class _DotGridPainter extends CustomPainter {
  const _DotGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const gap = 16.0;
    final pts = <Offset>[];
    for (double x = gap / 2; x < size.width; x += gap) {
      for (double y = gap / 2; y < size.height; y += gap) {
        pts.add(Offset(x, y));
      }
    }
    canvas.drawPoints(
      PointMode.points,
      pts,
      Paint()
        ..color = Colors.white.withOpacity(0.06)
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _ConstellationPainter extends CustomPainter {
  final double t;
  const _ConstellationPainter(this.t);

  static const _base = [
    Offset(0.10, 0.30),
    Offset(0.45, 0.06),
    Offset(0.90, 0.22),
    Offset(0.94, 0.72),
    Offset(0.55, 0.94),
    Offset(0.08, 0.75),
  ];

  @override
  void paint(Canvas canvas, Size s) {
    final a = t * 2 * pi;
    final hub = Offset(s.width / 2, s.height / 2);

    final nodes = List<Offset>.generate(_base.length, (i) {
      final b = _base[i];
      return Offset(
        b.dx * s.width + sin(a + i * 1.1) * 2.5,
        b.dy * s.height + cos(a + i * 1.7) * 2.5,
      );
    });

    final line = Paint()
      ..color = Colors.white.withOpacity(0.14)
      ..strokeWidth = 0.8;

    // Rim + spokes
    for (int i = 0; i < nodes.length; i++) {
      canvas.drawLine(nodes[i], nodes[(i + 1) % nodes.length], line);
      canvas.drawLine(hub, nodes[i], line);
    }

    // Data pulses travelling along spokes
    for (int i = 0; i < nodes.length; i++) {
      final phase = (t * 2 + i / nodes.length) % 1.0;
      final p = Offset.lerp(hub, nodes[i], phase)!;
      final fade = sin(pi * phase);
      canvas.drawCircle(
        p,
        2.6,
        Paint()
          ..color = _Palette.teal.withOpacity(0.9 * fade)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
      );
    }

    // Nodes
    for (int i = 0; i < nodes.length; i++) {
      final breathe = 0.65 + 0.35 * sin(a + i);
      canvas.drawCircle(
        nodes[i],
        2.4,
        Paint()
          ..color = (i.isEven ? Colors.white : _Palette.teal)
              .withOpacity(0.85 * breathe),
      );
    }

    // Expanding ripple around the hub
    final r = (t * 2) % 1.0;
    canvas.drawCircle(
      hub,
      26 + 14 * r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = _Palette.teal.withOpacity(0.35 * (1 - r)),
    );
  }

  @override
  bool shouldRepaint(_ConstellationPainter old) => old.t != t;
}

class _BannerBorderPainter extends CustomPainter {
  final double t;
  const _BannerBorderPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(0.5),
      const Radius.circular(_kBannerRadius),
    );
    final base = Colors.white.withOpacity(0.10);
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = SweepGradient(
          colors: [
            base,
            base,
            _Palette.teal.withOpacity(0.95),
            _Palette.violet.withOpacity(0.7),
            base,
          ],
          stops: const [0.0, 0.5, 0.72, 0.86, 1.0],
          transform: GradientRotation(t * 2 * pi),
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(_BannerBorderPainter old) => old.t != t;
}

// ─────────────────────────────────────────────
//  Bottom sheet
// ─────────────────────────────────────────────
class _AiSheet extends StatelessWidget {
  final VoidCallback onMarketPulse;
  final VoidCallback onStockSentiment;

  const _AiSheet({
    required this.onMarketPulse,
    required this.onStockSentiment,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF0F172A) : Colors.white;
    final title = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final sub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(isDark ? 0.08 : 0),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: sub.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Header
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [_Palette.violet, _Palette.teal],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded,
                        size: 20, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Intelligence',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: title,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'What do you want to look at?',
                          style: TextStyle(fontSize: 12.5, color: sub),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _OptionTile(
                title: 'Market Pulse',
                subtitle: 'Overall market mood and Nifty breakouts',
                accent: _Palette.teal,
                badge: _Badge.isNew,
                icon: const _Looping(
                  duration: Duration(milliseconds: 2200),
                  builder: _pulseIconBuilder,
                ),
                onTap: onMarketPulse,
              ),
              const SizedBox(height: 12),
              _OptionTile(
                title: 'Stock Sentiment',
                subtitle:
                    'AI reads technicals, financials and breakout signals',
                accent: _Palette.violet,
                badge: _Badge.beta,
                icon: const _Looping(
                  duration: Duration(milliseconds: 2400),
                  builder: _neuralIconBuilder,
                ),
                onTap: onStockSentiment,
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'AI-generated insights are not investment advice.',
                  style: TextStyle(
                    fontSize: 11,
                    color: sub.withOpacity(0.85),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _pulseIconBuilder(BuildContext c, double t) => CustomPaint(
      painter: _PulseWavePainter(t, _Palette.teal),
    );

Widget _neuralIconBuilder(BuildContext c, double t) => CustomPaint(
      painter: _NeuralPainter(t, _Palette.violet),
    );

// ─────────────────────────────────────────────
//  Option tile
// ─────────────────────────────────────────────
enum _Badge { isNew, beta }

class _OptionTile extends StatefulWidget {
  final String title;
  final String subtitle;
  final Color accent;
  final _Badge? badge;
  final Widget icon;
  final VoidCallback onTap;

  const _OptionTile({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.icon,
    required this.onTap,
    this.badge,
  });

  @override
  State<_OptionTile> createState() => _OptionTileState();
}

class _OptionTileState extends State<_OptionTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final sub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final a = widget.accent;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
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
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                a.withOpacity(isDark ? 0.14 : 0.10),
                a.withOpacity(isDark ? 0.04 : 0.03),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: a.withOpacity(isDark ? 0.28 : 0.30)),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black.withOpacity(0.30) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: a.withOpacity(0.25)),
                ),
                child: widget.icon,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.title,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: title,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        if (widget.badge != null) ...[
                          const SizedBox(width: 8),
                          _BadgePill(
                            badge: widget.badge!,
                            accent: a,
                            isDark: isDark,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, height: 1.35, color: sub),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: a.withOpacity(isDark ? 0.18 : 0.14),
                ),
                child: Icon(Icons.arrow_forward_rounded, size: 16, color: a),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BadgePill extends StatelessWidget {
  final _Badge badge;
  final Color accent;
  final bool isDark;

  const _BadgePill({
    required this.badge,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isNew = badge == _Badge.isNew;
    final c = isNew ? _Palette.amber : accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: c.withOpacity(isDark ? 0.18 : 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withOpacity(0.40), width: 0.8),
      ),
      child: Text(
        isNew ? 'New' : 'Beta',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: c,
          height: 1.0,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Option icons
// ─────────────────────────────────────────────
class _PulseWavePainter extends CustomPainter {
  final double t;
  final Color color;
  const _PulseWavePainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height, mid = h / 2;
    final pts = [
      Offset(0, mid),
      Offset(w * 0.18, mid),
      Offset(w * 0.28, mid - h * 0.30),
      Offset(w * 0.38, mid + h * 0.34),
      Offset(w * 0.50, mid - h * 0.44),
      Offset(w * 0.60, mid + h * 0.10),
      Offset(w * 0.70, mid),
      Offset(w, mid),
    ];
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color.withOpacity(0.25)
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final m = path.computeMetrics().first;
    final end = t * m.length;
    final start = max(0.0, end - m.length * 0.3);
    if (end > start) {
      canvas.drawPath(
        m.extractPath(start, end),
        Paint()
          ..color = color
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2),
      );
    }
  }

  @override
  bool shouldRepaint(_PulseWavePainter old) => old.t != t;
}

class _NeuralPainter extends CustomPainter {
  final double t;
  final Color color;
  const _NeuralPainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size s) {
    final nodes = [
      Offset(s.width * 0.15, s.height * 0.20),
      Offset(s.width * 0.50, s.height * 0.06),
      Offset(s.width * 0.85, s.height * 0.20),
      Offset(s.width * 0.08, s.height * 0.62),
      Offset(s.width * 0.50, s.height * 0.50),
      Offset(s.width * 0.92, s.height * 0.62),
      Offset(s.width * 0.28, s.height * 0.94),
      Offset(s.width * 0.72, s.height * 0.94),
    ];
    const conns = [
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

    final line = Paint()
      ..color = color.withOpacity(0.30)
      ..strokeWidth = 0.9;
    for (final c in conns) {
      canvas.drawLine(nodes[c[0]], nodes[c[1]], line);
    }

    final idx = (t * conns.length).floor() % conns.length;
    final frac = (t * conns.length) % 1.0;
    final dot = Offset.lerp(nodes[conns[idx][0]], nodes[conns[idx][1]], frac)!;
    canvas.drawCircle(
      dot,
      3,
      Paint()
        ..color = color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
    );

    for (int i = 0; i < nodes.length; i++) {
      final pulse = sin(t * 2 * pi + i * 0.9) * 0.25 + 0.75;
      canvas.drawCircle(
        nodes[i],
        2.1,
        Paint()..color = color.withOpacity(0.75 * pulse),
      );
    }
  }

  @override
  bool shouldRepaint(_NeuralPainter old) => old.t != t;
}
