// ============================================================
//  OptionXi — streak_card_skeleton.dart
//
//  Loading skeletons that match StreakCard and StreakMiniCard
//  pixel-for-pixel.
//
//  Widgets:
//    StreakCardSkeleton()      ← matches StreakCard full layout
//    StreakMiniCardSkeleton()  ← matches StreakMiniCard layout
//
//  Design principles:
//   • Static: icon, labels ("Trading Streak", "Next:", milestone
//     labels, "days to next milestone") — same as real UI.
//   • Shimmer: day count badge, progress bar, dot bars, sub-text
//     numbers.
//   • Size/padding matches real widgets exactly so swap-in is
//     seamless (no layout jump).
// ============================================================

import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// THEME HELPER  (mirrors _TC from streak_card_widget.dart)
// ─────────────────────────────────────────────────────────────────────────────

class _TC {
  final bool dark;
  _TC(BuildContext ctx) : dark = Theme.of(ctx).brightness == Brightness.dark;

  Color get card => dark ? const Color(0xFF141826) : const Color(0xFFF2F4FF);
  Color get cardBorder =>
      dark ? const Color(0xFF1E2438) : const Color(0xFFD6DAF0);
  Color get textPri => dark ? const Color(0xFFF0F3FF) : const Color(0xFF0D1120);
  Color get textSec => dark ? const Color(0xFF8891AA) : const Color(0xFF4A5270);
  Color get textMuted =>
      dark ? const Color(0xFF3E4562) : const Color(0xFFB0B8D4);
  Color get streakOrange => const Color(0xFFFF8C42);
  Color get shimmerBase =>
      dark ? const Color(0xFF1E2438) : const Color(0xFFD6DAF0);
  Color get shimmerHighlight =>
      dark ? const Color(0xFF2A3050) : const Color(0xFFEBEEFA);
}

// ─────────────────────────────────────────────────────────────────────────────
// SHIMMER ENGINE
// ─────────────────────────────────────────────────────────────────────────────

class _Shimmer extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final _TC tc;

  const _Shimmer({
    required this.width,
    required this.height,
    required this.tc,
    this.borderRadius = 4,
  });

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _anim = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            stops: const [0.0, 0.45, 0.55, 1.0],
            colors: [
              widget.tc.shimmerBase,
              widget.tc.shimmerHighlight,
              widget.tc.shimmerHighlight,
              widget.tc.shimmerBase,
            ],
            transform: _SlideTransform(_anim.value),
          ),
        ),
      ),
    );
  }
}

class _SlideTransform extends GradientTransform {
  final double slide;
  const _SlideTransform(this.slide);
  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * slide, 0, 0);
}

// ─────────────────────────────────────────────────────────────────────────────
// STREAK CARD SKELETON  (matches StreakCard / _StreakCardView)
// ─────────────────────────────────────────────────────────────────────────────

class StreakCardSkeleton extends StatelessWidget {
  const StreakCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final tc = _TC(context);

    // Matches the exact decoration from _StreakCardView
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [tc.streakOrange.withOpacity(.12), tc.card],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tc.streakOrange.withOpacity(.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ─────────────────────────────────────────────────────
          Row(children: [
            // Static: flame icon badge
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: tc.streakOrange.withOpacity(.18),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(Icons.local_fire_department_rounded,
                  size: 18, color: tc.streakOrange),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Static: title label
                Text(
                  'Trading Streak',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: tc.textPri,
                  ),
                ),
                const SizedBox(height: 2),
                // Shimmer: "X days · Next: Y days" — dynamic numbers
                Row(children: [
                  _Shimmer(width: 22, height: 9, tc: tc, borderRadius: 3),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(' days · Next: ',
                        style: TextStyle(fontSize: 10.5, color: tc.textSec)),
                  ),
                  _Shimmer(width: 18, height: 9, tc: tc, borderRadius: 3),
                  Text(' days',
                      style: TextStyle(fontSize: 10.5, color: tc.textSec)),
                ]),
              ],
            ),
            const Spacer(),
            // Shimmer: day count badge (🔥 N)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: tc.streakOrange.withOpacity(.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: tc.streakOrange.withOpacity(.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('🔥 ', style: TextStyle(fontSize: 13)),
                _Shimmer(width: 18, height: 13, tc: tc, borderRadius: 3),
              ]),
            ),
          ]),
          const SizedBox(height: 12),

          // ── Milestone dot rows ─────────────────────────────────────────────
          // Static label positions; shimmer on the bars themselves
          Row(
            children: List.generate(4, (i) {
              const labels = ['3d', '7d', '30d', '365d'];
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 3 ? 6 : 0),
                  child: Column(children: [
                    // Shimmer bar (replaces the coloured/grey segment bar)
                    _Shimmer(
                      width: double.infinity,
                      height: 3,
                      tc: tc,
                      borderRadius: 2,
                    ),
                    const SizedBox(height: 4),
                    // Static milestone label
                    Text(
                      labels[i],
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                        color: tc.textMuted,
                      ),
                    ),
                  ]),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),

          // ── Progress bar ───────────────────────────────────────────────────
          // Shimmer replaces LinearProgressIndicator fill
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: _Shimmer(
              width: double.infinity,
              height: 5,
              tc: tc,
              borderRadius: 4,
            ),
          ),
          const SizedBox(height: 5),

          // Shimmer: "X / Y days to next milestone"
          Row(children: [
            _Shimmer(width: 28, height: 9, tc: tc, borderRadius: 3),
            Text(' / ', style: TextStyle(fontSize: 9.5, color: tc.textMuted)),
            _Shimmer(width: 20, height: 9, tc: tc, borderRadius: 3),
            Text(' days to next milestone',
                style: TextStyle(fontSize: 9.5, color: tc.textMuted)),
          ]),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STREAK MINI CARD SKELETON  (matches StreakMiniCard / _StreakMiniView)
// ─────────────────────────────────────────────────────────────────────────────

class StreakMiniCardSkeleton extends StatelessWidget {
  const StreakMiniCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final tc = _TC(context);

    // Matches the exact margin/padding/decoration from _StreakMiniView
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 6, 14, 2),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [tc.streakOrange.withOpacity(.14), tc.card],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tc.streakOrange.withOpacity(.32)),
      ),
      child: Row(children: [
        // ── Flame badge ─────────────────────────────────────────────────────
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: tc.streakOrange.withOpacity(.18),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Static: flame icon
              Icon(Icons.local_fire_department_rounded,
                  size: 20, color: tc.streakOrange),
              const SizedBox(height: 1),
              // Shimmer: day count number
              _Shimmer(width: 20, height: 11, tc: tc, borderRadius: 3),
            ],
          ),
        ),
        const SizedBox(width: 14),

        // ── Label + bar ──────────────────────────────────────────────────────
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                // Static: title
                Text(
                  'Trading Streak',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: tc.textPri,
                  ),
                ),
                const Spacer(),
                // Shimmer: "X days to go"
                Row(mainAxisSize: MainAxisSize.min, children: [
                  _Shimmer(width: 16, height: 10, tc: tc, borderRadius: 3),
                  Text(
                    ' days to go',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: tc.streakOrange,
                    ),
                  ),
                ]),
              ]),
              const SizedBox(height: 6),

              // Shimmer: progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: _Shimmer(
                  width: double.infinity,
                  height: 5,
                  tc: tc,
                  borderRadius: 4,
                ),
              ),
              const SizedBox(height: 5),

              // Shimmer: "X / Y days · next milestone 🎯"
              Row(children: [
                _Shimmer(width: 22, height: 9, tc: tc, borderRadius: 3),
                Text(' / ',
                    style: TextStyle(fontSize: 10, color: tc.textMuted)),
                _Shimmer(width: 18, height: 9, tc: tc, borderRadius: 3),
                Text(' days · next milestone 🎯',
                    style: TextStyle(fontSize: 10, color: tc.textMuted)),
              ]),
            ],
          ),
        ),
      ]),
    );
  }
}
