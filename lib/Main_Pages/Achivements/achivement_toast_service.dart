// ============================================================
//  OptionXi — achivement_toast_service.dart  (v5)
//
//  Changes from v4:
//   • Light / dark theme compatible — all colours derived from
//     Theme.of(context) / MediaQuery brightness instead of
//     hardcoded dark hex values.
//   • Badge icon now renders icon_svg from the database via
//     flutter_svg (SvgPicture.string) — no more custom painter
//     drawing code in the toast.  The _ToastBadgePainter class
//     is kept only for the shaped background; the symbol is gone.
//   • _C colour constants replaced with _TC(context) helper so
//     every widget reads the live theme.
//
//  pubspec.yaml addition needed:
//    flutter_svg: ^2.0.10
// ============================================================

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:optionxi/Main_Pages/Achivements/fastapi_achivement.dart';
import 'package:optionxi/Main_Pages/Achivements/act_achievement_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// THEME HELPER  — reads live Brightness so dark/light just works
// ─────────────────────────────────────────────────────────────────────────────

class _TC {
  final bool _dark;
  _TC(BuildContext ctx) : _dark = Theme.of(ctx).brightness == Brightness.dark;

  // Backgrounds
  Color get bg => _dark ? const Color(0xFF111520) : const Color(0xFFF8F9FF);
  Color get border => _dark ? const Color(0xFF222840) : const Color(0xFFD0D4E8);

  // Text
  Color get textPri =>
      _dark ? const Color(0xFFF0F3FF) : const Color(0xFF0D1120);
  Color get textSec =>
      _dark ? const Color(0xFF8891AA) : const Color(0xFF4A5270);

  // Accents (same in both modes — vivid is vivid)
  Color get gold => const Color(0xFFFFBC30);
  Color get green => const Color(0xFF28CF8A);
  Color get fire => const Color(0xFFFF8C00);

  // Shadow
  Color get shadow =>
      _dark ? Colors.black54 : const Color(0xFF9099C0).withOpacity(.28);

  static Color rarityColor(AchievementRarity r) => switch (r) {
        AchievementRarity.common => const Color(0xFF7A8599),
        AchievementRarity.rare => const Color(0xFF4DB8FF),
        AchievementRarity.epic => const Color(0xFFC278FF),
        AchievementRarity.legendary => const Color(0xFFFFD060),
      };

  static List<Color> rarityGradient(AchievementRarity r) => switch (r) {
        AchievementRarity.common => [
            const Color(0xFF9EB0C8),
            const Color(0xFF4A5878)
          ],
        AchievementRarity.rare => [
            const Color(0xFF80D8FF),
            const Color(0xFF1A80CC)
          ],
        AchievementRarity.epic => [
            const Color(0xFFDCB4FF),
            const Color(0xFF8C38F8)
          ],
        AchievementRarity.legendary => [
            const Color(0xFFFFF0A0),
            const Color(0xFFFFA800),
            const Color(0xFFE07000)
          ],
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// SERVICE
// ─────────────────────────────────────────────────────────────────────────────

class AchievementToastService {
  AchievementToastService._();

  static final _queue = <_ToastItem>[];
  static bool _showing = false;

  /// Fire an event and show toasts for whatever the server returns.
  /// Fire-and-forget — never throws, never blocks UI.
  static void trackAndShow(String event,
      {Map<String, dynamic> meta = const {}}) {
    _doTrack(event, meta: meta);
  }

  static Future<void> _doTrack(String event,
      {Map<String, dynamic> meta = const {}}) async {
    try {
      final result = await AchievementClient.track(event, meta: meta);

      if (result.unlocked.isEmpty && result.progressed.isEmpty) return;

      final unlockedSet = result.unlocked.toSet();
      final progressedSet = result.progressed.toSet();

      for (final info in result.toastData) {
        if (unlockedSet.contains(info.id)) {
          _enqueue(_ToastItem(info: info, isProgress: false));
        } else if (progressedSet.contains(info.id)) {
          _enqueue(_ToastItem(info: info, isProgress: true));
        }
      }
    } catch (_) {
      // Silent — achievements must never affect app flow.
    }
  }

  static void _enqueue(_ToastItem item) {
    _queue.add(item);
    if (!_showing) _next();
  }

  static void _next() {
    if (_queue.isEmpty) {
      _showing = false;
      return;
    }
    final ctx = Get.overlayContext;
    if (ctx == null) {
      _showing = false;
      return;
    }

    _showing = true;
    final item = _queue.removeAt(0);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _AchievementToast(
        info: item.info,
        isProgress: item.isProgress,
        onDone: () {
          entry.remove();
          Future.delayed(const Duration(milliseconds: 200), _next);
        },
      ),
    );
    Overlay.of(ctx).insert(entry);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QUEUE ITEM
// ─────────────────────────────────────────────────────────────────────────────

class _ToastItem {
  final ToastInfo info;
  final bool isProgress;
  const _ToastItem({required this.info, required this.isProgress});
}

// ─────────────────────────────────────────────────────────────────────────────
// TOAST WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class _AchievementToast extends StatefulWidget {
  final ToastInfo info;
  final VoidCallback onDone;
  final bool isProgress;
  const _AchievementToast({
    required this.info,
    required this.onDone,
    required this.isProgress,
  });
  @override
  State<_AchievementToast> createState() => _AchievementToastState();
}

class _AchievementToastState extends State<_AchievementToast>
    with TickerProviderStateMixin {
  late final AnimationController _enter;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  late final AnimationController _shim;
  late final AnimationController _timer;
  late final AnimationController _pulse;

  static const _displayDuration = Duration(seconds: 4);

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();

    _enter = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 480));
    _slide = Tween(begin: const Offset(0, -1.5), end: Offset.zero)
        .animate(CurvedAnimation(parent: _enter, curve: Curves.easeOutBack));
    _fade = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _enter, curve: const Interval(0, .45)));

    _shim =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();

    _timer =
        AnimationController(vsync: this, duration: _displayDuration, value: 1.0)
          ..addStatusListener((s) {
            if (s == AnimationStatus.dismissed) _dismiss();
          });

    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    final r = widget.info.rarity;
    if (r == AchievementRarity.legendary || r == AchievementRarity.epic) {
      _pulse.repeat(reverse: true);
    }

    _enter.forward();
    _timer.reverse();
  }

  void _dismissAndNavigate() {
    if (!mounted) return;
    _timer.stop();
    _enter.reverse().then((_) {
      if (mounted) {
        widget.onDone();
        Get.to(() => const AchievementsPage(),
            transition: Transition.cupertino,
            duration: const Duration(milliseconds: 320));
      }
    });
  }

  void _dismiss() {
    if (!mounted) return;
    _timer.stop();
    _enter.reverse().then((_) {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _enter.dispose();
    _shim.dispose();
    _timer.dispose();
    _pulse.dispose();
    super.dispose();
  }

  AchievementRarity get _rarity => widget.info.rarity;

  bool get _isStreakAch => const {'fire_3', 'fire_7', 'fire_30', 'trophy_year'}
      .contains(widget.info.iconKey);

  String _progressBody() {
    final cur = widget.info.progress;
    final max = widget.info.progressMax;
    if (cur == null || max == null) return widget.info.description;
    final remaining = max - cur;
    if (_isStreakAch) {
      return '$cur / $max days · $remaining more to unlock';
    }
    return '$cur / $max · $remaining more to unlock';
  }

  @override
  Widget build(BuildContext context) {
    final tc = _TC(context);
    final rc = _TC.rarityColor(_rarity);
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      right: 16,
      child: GestureDetector(
        onTap: _dismissAndNavigate,
        onVerticalDragEnd: (d) {
          if ((d.primaryVelocity ?? 0) < -80) _dismiss();
        },
        child: SlideTransition(
          position: _slide,
          child: FadeTransition(
            opacity: _fade,
            child: AnimatedBuilder(
              animation: Listenable.merge([_shim, _pulse, _timer]),
              builder: (_, __) => _buildCard(context, tc, rc),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, _TC tc, Color rc) {
    final info = widget.info;
    final isP = widget.isProgress;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: tc.bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: rc.withOpacity(.55), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: rc.withOpacity(
                  _rarity == AchievementRarity.legendary ? .42 : .22),
              blurRadius: _rarity == AchievementRarity.legendary ? 32 : 16,
              spreadRadius: _rarity == AchievementRarity.legendary ? 2 : 0,
            ),
            BoxShadow(
                color: tc.shadow, blurRadius: 20, offset: const Offset(0, 6)),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child:
                Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              // ── Badge (shape + SVG icon from DB) ─────────────────────────
              Transform.scale(
                scale: 1.0 + _pulse.value * .06,
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: Stack(alignment: Alignment.center, children: [
                    // Shaped gradient background
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _ToastBadgePainter(
                          rarity: _rarity,
                          shimOffset: _rarity == AchievementRarity.legendary
                              ? _shim.value
                              : 0,
                        ),
                      ),
                    ),
                    // SVG icon — currentColor replaced with #ffffff
                    if (info.iconSvg.isNotEmpty)
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: SvgPicture.string(
                          info.iconSvg.replaceAll('currentColor', '#ffffff'),
                          fit: BoxFit.contain,
                        ),
                      ),
                  ]),
                ),
              ),
              const SizedBox(width: 12),

              // ── Text ─────────────────────────────────────────────────────
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status pill
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isP ? tc.fire : tc.green).withOpacity(.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                          color: (isP ? tc.fire : tc.green).withOpacity(.4),
                          width: .8),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(
                          isP
                              ? (_isStreakAch
                                  ? Icons.local_fire_department
                                  : Icons.trending_up)
                              : Icons.military_tech,
                          size: 10,
                          color: isP ? tc.fire : tc.green),
                      const SizedBox(width: 3),
                      Text(
                        isP
                            ? (_isStreakAch ? 'STREAK +1 DAY' : 'IN PROGRESS')
                            : 'ACHIEVEMENT UNLOCKED',
                        style: TextStyle(
                            fontSize: 7.5,
                            fontWeight: FontWeight.w900,
                            color: isP ? tc.fire : tc.green,
                            letterSpacing: .7),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 5),

                  // Title
                  Text(info.title,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: tc.textPri,
                          letterSpacing: -.3,
                          height: 1.2),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),

                  // Body — progress label or description
                  Text(isP ? _progressBody() : info.description,
                      style: TextStyle(
                          fontSize: 11.5, color: tc.textSec, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              )),
              const SizedBox(width: 10),

              // ── Rarity + XP ──────────────────────────────────────────────
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                        color: rc.withOpacity(.14),
                        borderRadius: BorderRadius.circular(6),
                        border:
                            Border.all(color: rc.withOpacity(.4), width: .8)),
                    child: Text(_cap(info.rarity.name),
                        style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            color: rc,
                            letterSpacing: .5)),
                  ),
                  const SizedBox(height: 6),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.bolt, size: 11, color: tc.gold),
                    const SizedBox(width: 2),
                    Text('+${info.xpReward} XP',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: tc.gold)),
                  ]),
                ],
              ),
            ]),
          ),

          // ── Countdown drain bar ──────────────────────────────────────────
          AnimatedBuilder(
            animation: _timer,
            builder: (_, __) => LinearProgressIndicator(
              value: _timer.value,
              minHeight: 3,
              backgroundColor: tc.border,
              valueColor: AlwaysStoppedAnimation(rc.withOpacity(.75)),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BADGE SHAPE PAINTER  (background only — symbol now comes from icon_svg)
// ─────────────────────────────────────────────────────────────────────────────

class _ToastBadgePainter extends CustomPainter {
  final AchievementRarity rarity;
  final double shimOffset;
  const _ToastBadgePainter({required this.rarity, this.shimOffset = 0});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final r = size.shortestSide * 0.44;
    final shape = _shape(cx, cy, r);
    final rc = _TC.rarityColor(rarity);

    // Gradient fill
    canvas.drawPath(
        shape,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _TC.rarityGradient(rarity),
          ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r))
          ..style = PaintingStyle.fill);

    // Glow stroke
    canvas.drawPath(
        shape,
        Paint()
          ..color = rc.withOpacity(.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));

    // Rim highlight
    canvas.drawPath(
        shape,
        Paint()
          ..color = Colors.white.withOpacity(.20)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);

    // Shimmer for legendary
    if (rarity == AchievementRarity.legendary && shimOffset > 0) {
      canvas.save();
      canvas.clipPath(shape);
      canvas.drawRect(
          Rect.fromLTWH(
              cx - r + shimOffset * size.width * 2.4 - 18, 0, 18, size.height),
          Paint()
            ..color = Colors.white.withOpacity(.32)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
      canvas.restore();
    }
  }

  Path _shape(double cx, double cy, double r) => switch (rarity) {
        AchievementRarity.legendary => _star(cx, cy, r, r * 0.53, 8),
        AchievementRarity.epic => _poly(cx, cy, r, 5, -pi / 2),
        AchievementRarity.rare => _shield(cx, cy, r),
        AchievementRarity.common => _hexRound(cx, cy, r),
      };

  Path _poly(double cx, double cy, double r, int n, double start) {
    final p = Path();
    for (int i = 0; i < n; i++) {
      final a = start + 2 * pi / n * i;
      i == 0
          ? p.moveTo(cx + r * cos(a), cy + r * sin(a))
          : p.lineTo(cx + r * cos(a), cy + r * sin(a));
    }
    return p..close();
  }

  Path _star(double cx, double cy, double ro, double ri, int pts) {
    final p = Path();
    for (int i = 0; i < pts * 2; i++) {
      final a = pi / pts * i - pi / 2;
      final rad = i.isEven ? ro : ri;
      i == 0
          ? p.moveTo(cx + rad * cos(a), cy + rad * sin(a))
          : p.lineTo(cx + rad * cos(a), cy + rad * sin(a));
    }
    return p..close();
  }

  Path _shield(double cx, double cy, double r) => Path()
    ..moveTo(cx, cy - r)
    ..lineTo(cx + r * .88, cy - r * .30)
    ..lineTo(cx + r * .88, cy + r * .28)
    ..quadraticBezierTo(cx + r * .88, cy + r * .72, cx, cy + r)
    ..quadraticBezierTo(cx - r * .88, cy + r * .72, cx - r * .88, cy + r * .28)
    ..lineTo(cx - r * .88, cy - r * .30)
    ..close();

  Path _hexRound(double cx, double cy, double r) {
    const n = 6;
    final verts = List.generate(n, (i) {
      final a = 2 * pi / n * i;
      return Offset(cx + r * cos(a), cy + r * sin(a));
    });
    final rnd = r * 0.18;
    final p = Path();
    for (int i = 0; i < n; i++) {
      final prev = verts[(i - 1 + n) % n];
      final curr = verts[i];
      final next = verts[(i + 1) % n];
      Offset dir(Offset a, Offset b) {
        final dx = b.dx - a.dx, dy = b.dy - a.dy;
        final d = sqrt(dx * dx + dy * dy);
        return d == 0 ? Offset.zero : Offset(dx / d, dy / d);
      }

      final p1 = curr - dir(prev, curr) * rnd;
      final p2 = curr - dir(next, curr) * rnd;
      if (i == 0)
        p.moveTo(p1.dx, p1.dy);
      else
        p.lineTo(p1.dx, p1.dy);
      p.quadraticBezierTo(curr.dx, curr.dy, p2.dx, p2.dy);
    }
    return p..close();
  }

  @override
  bool shouldRepaint(_ToastBadgePainter o) =>
      o.rarity != rarity || o.shimOffset != shimOffset;
}

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
