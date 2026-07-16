// ============================================================
//  OptionXi — act_achievement_page.dart  (v4)
//
//  Changes from v3:
//   • Sleeker header — single compact row: back | avatar+name | spacer | leaderboard btn | level badge
//   • XP progress bar stays below the row, minimal height
//   • Category filter + Rarity filter both live in ONE row as pills
//   • Leaderboard button moved from Level badge to a dedicated trophy button
//   • When "All" category is selected, achievements are grouped by category
//     with styled section headers instead of a flat grid
// ============================================================

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:optionxi/Components/cust_bottom_sheet_beta_alert.dart';
import 'package:optionxi/Main_Pages/Achivements/act_leaderboard_achivement.dart';
import 'package:optionxi/Main_Pages/Achivements/fastapi_achivement.dart';
import 'package:optionxi/Main_Pages/Achivements/streak_card_loading.dart';
import 'package:optionxi/Main_Pages/Achivements/streak_card_widget.dart';

// ─────────────────────────────────────────────────────────────────────────────
// STATIC ACCENT TOKENS
// ─────────────────────────────────────────────────────────────────────────────

abstract class _T {
  static const gold = Color(0xFFFFBC30);
  static const blue = Color(0xFF4E91FF);
  static const green = Color.fromRGBO(40, 207, 138, 1);
  // static const purple = Color(0xFFAC70FF);
  static const orange = Color(0xFFFF6F40);

  static Color rarColor(AchievementRarity r) => switch (r) {
        AchievementRarity.common => const Color(0xFF7A8599),
        AchievementRarity.rare => const Color(0xFF4DB8FF),
        AchievementRarity.epic => const Color(0xFFC278FF),
        AchievementRarity.legendary => const Color(0xFFFFD060),
      };

  static List<Color> rarGradient(AchievementRarity r) => switch (r) {
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

  // Category accent colours for section headers
  static Color catColor(String cat) => switch (cat.toLowerCase()) {
        'trading' => const Color(0xFF4E91FF),
        'options' => const Color(0xFF28CF8A),
        'screener' => const Color(0xFFAC70FF),
        'streak' => const Color(0xFFFFBC30),
        'social' => const Color(0xFFFF6F40),
        'special' => const Color(0xFFFFD060),
        _ => const Color(0xFF7A8599),
      };

  static IconData catIcon(String cat) => switch (cat.toLowerCase()) {
        'trading' => Icons.candlestick_chart_rounded,
        'options' => Icons.layers_rounded,
        'screener' => Icons.search_rounded,
        'streak' => Icons.local_fire_department_rounded,
        'social' => Icons.people_rounded,
        'special' => Icons.auto_awesome_rounded,
        _ => Icons.military_tech_rounded,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// THEME COLOUR HELPER
// ─────────────────────────────────────────────────────────────────────────────

class _TC {
  final bool dark;
  _TC(BuildContext ctx) : dark = Theme.of(ctx).brightness == Brightness.dark;

  Color get bg => dark ? const Color(0xFF07090F) : const Color(0xFFF0F2FF);
  Color get surface => dark ? const Color(0xFF0D1018) : const Color(0xFFF8F9FF);
  Color get card => dark ? const Color(0xFF141826) : const Color(0xFFECEFF9);
  Color get cardLocked =>
      dark ? const Color(0xFF0F1218) : const Color(0xFFDDE1F0);
  Color get cardBorder =>
      dark ? const Color(0xFF1E2438) : const Color(0xFFCDD3EC);
  Color get textPri => dark ? const Color(0xFFF0F3FF) : const Color(0xFF0D1120);
  Color get textSec => dark ? const Color(0xFF8891AA) : const Color(0xFF4A5270);
  Color get textMuted =>
      dark ? const Color(0xFF3E4562) : const Color(0xFFB0B8D4);
  Color get orangeDim => dark
      ? const Color(0xFF26FF6F40)
      : const Color(0xFFFF6F40).withOpacity(.12);
  Color get lockOverlay => dark
      ? Colors.black.withOpacity(.38)
      : const Color(0xFF8A97C0).withOpacity(.18);
  Color get lockIcon =>
      dark ? const Color(0xFF2A3050) : const Color(0xFF8A97C0);
  Color get sectionHeaderBg =>
      dark ? const Color(0xFF0A0C14) : const Color(0xFFE8ECFA);
}

// ─────────────────────────────────────────────────────────────────────────────
// BADGE PAINTER
// ─────────────────────────────────────────────────────────────────────────────

class _BadgePainter extends CustomPainter {
  final AchievementRarity rarity;
  final bool unlocked;
  final double shimOffset;
  final _TC tc;

  const _BadgePainter({
    required this.rarity,
    required this.unlocked,
    required this.tc,
    this.shimOffset = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.shortestSide * 0.44;
    final shape = _shape(cx, cy, r);

    if (unlocked) {
      canvas.drawPath(
          shape,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _T.rarGradient(rarity),
            ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r))
            ..style = PaintingStyle.fill);

      canvas.drawPath(
          shape,
          Paint()
            ..color = _T.rarColor(rarity).withOpacity(0.55)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));

      canvas.drawPath(
          shape,
          Paint()
            ..color = Colors.white.withOpacity(0.22)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2);

      if (rarity == AchievementRarity.legendary && shimOffset > 0) {
        canvas.save();
        canvas.clipPath(shape);
        canvas.drawRect(
          Rect.fromLTWH(
              cx - r + shimOffset * size.width * 2.4 - 24, 0, 24, size.height),
          Paint()
            ..color = Colors.white.withOpacity(0.28)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
        canvas.restore();
      }
    } else {
      canvas.drawPath(
          shape,
          Paint()
            ..color = tc.card
            ..style = PaintingStyle.fill);
      canvas.drawPath(
          shape,
          Paint()
            ..color = tc.cardBorder
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2);
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
  bool shouldRepaint(_BadgePainter o) =>
      o.rarity != rarity ||
      o.unlocked != unlocked ||
      o.shimOffset != shimOffset ||
      o.tc.dark != tc.dark;
}

// ─────────────────────────────────────────────────────────────────────────────
// BADGE WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class _BadgeWidget extends StatelessWidget {
  final Achievement a;
  final double size;
  final double shimOffset;
  final _TC tc;

  const _BadgeWidget({
    required this.a,
    required this.tc,
    this.size = 52,
    this.shimOffset = 0,
  });

  String _resolvedSvg(Color color) {
    final hex =
        '#${color.red.toRadixString(16).padLeft(2, '0')}${color.green.toRadixString(16).padLeft(2, '0')}${color.blue.toRadixString(16).padLeft(2, '0')}';
    return a.iconSvg.replaceAll('currentColor', hex);
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = a.isUnlocked ? Colors.white : tc.lockIcon;
    final iconSize = size * 0.46;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(alignment: Alignment.center, children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _BadgePainter(
              rarity: a.rarity,
              unlocked: a.isUnlocked,
              tc: tc,
              shimOffset: shimOffset,
            ),
          ),
        ),
        if (a.iconSvg.isNotEmpty)
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: SvgPicture.string(
              _resolvedSvg(iconColor),
              fit: BoxFit.contain,
            ),
          ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BADGE CARD
// ─────────────────────────────────────────────────────────────────────────────

class _BadgeCard extends StatefulWidget {
  final Achievement a;
  final VoidCallback onTap;
  const _BadgeCard({required this.a, required this.onTap});
  @override
  State<_BadgeCard> createState() => _BadgeCardState();
}

class _BadgeCardState extends State<_BadgeCard> with TickerProviderStateMixin {
  late final AnimationController _shim;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _shim =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    if (widget.a.isUnlocked &&
        (widget.a.rarity == AchievementRarity.legendary ||
            widget.a.rarity == AchievementRarity.epic)) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _shim.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tc = _TC(context);
    final a = widget.a;
    final rc = _T.rarColor(a.rarity);

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_shim, _pulse]),
        builder: (_, __) => Transform.scale(
          scale: a.isUnlocked ? 1.0 + _pulse.value * .025 : 1.0,
          child: Container(
            decoration: BoxDecoration(
              color: a.isUnlocked ? null : tc.cardLocked,
              gradient: a.isUnlocked
                  ? LinearGradient(
                      colors: [rc.withOpacity(.18), tc.card],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: a.isUnlocked ? rc.withOpacity(.55) : tc.cardBorder,
                  width: a.isUnlocked ? 1.4 : 1.0),
              boxShadow: a.isUnlocked
                  ? [
                      BoxShadow(
                          color: rc.withOpacity(
                              a.rarity == AchievementRarity.legendary
                                  ? .28
                                  : .10),
                          blurRadius:
                              a.rarity == AchievementRarity.legendary ? 18 : 6,
                          spreadRadius:
                              a.rarity == AchievementRarity.legendary ? 1 : 0)
                    ]
                  : null,
            ),
            child: Stack(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(5, 10, 5, 8),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  _BadgeWidget(
                    a: a,
                    tc: tc,
                    size: 52,
                    shimOffset: a.rarity == AchievementRarity.legendary
                        ? _shim.value
                        : 0,
                  ),
                  const SizedBox(height: 6),
                  Text(a.title,
                      style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                          color: a.isUnlocked ? tc.textPri : tc.textMuted),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1.5),
                      decoration: BoxDecoration(
                          color: a.isUnlocked
                              ? rc.withOpacity(.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: a.isUnlocked
                                  ? rc.withOpacity(.38)
                                  : tc.textMuted.withOpacity(.25),
                              width: .7)),
                      child: Text(_cap(a.rarity.name),
                          style: TextStyle(
                              fontSize: 6.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .5,
                              color: a.isUnlocked ? rc : tc.textMuted))),
                  if (!a.isUnlocked &&
                      a.progressMax != null &&
                      a.progress > 0) ...[
                    const SizedBox(height: 5),
                    Stack(children: [
                      // glow layer underneath
                      Container(
                        height: 2.5,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: [
                            BoxShadow(
                              color: rc.withOpacity(.55),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        // width-constrained glow matches progress %
                        child: FractionallySizedBox(
                          widthFactor: a.progressPercent,
                          child: Container(
                            decoration: BoxDecoration(
                              color: rc,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                      // actual bar on top
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: a.progressPercent,
                          minHeight: 2.5,
                          backgroundColor: tc.cardBorder,
                          valueColor: AlwaysStoppedAnimation(rc),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 2),
                    Text('${a.progress}/${a.progressMax}',
                        style:
                            TextStyle(fontSize: 7, color: rc.withOpacity(.75))),
                  ],
                  const SizedBox(height: 4),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.bolt,
                        size: 8, color: a.isUnlocked ? _T.gold : tc.textMuted),
                    const SizedBox(width: 1),
                    Text('${a.xpReward} XP',
                        style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: a.isUnlocked ? _T.gold : tc.textMuted)),
                  ]),
                ]),
              ),
              if (!a.isUnlocked)
                Positioned.fill(
                    child: Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: tc.lockOverlay),
                        child: Align(
                            alignment: const Alignment(0, -.25),
                            child: Icon(Icons.lock_rounded,
                                size: 14, color: tc.lockIcon)))),
              if (a.isNew)
                Positioned(
                    top: 5,
                    right: 5,
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1.5),
                        decoration: BoxDecoration(
                            color: _T.green,
                            borderRadius: BorderRadius.circular(3)),
                        child: const Text('NEW',
                            style: TextStyle(
                                fontSize: 6,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: .4)))),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DETAIL BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _DetailSheet extends StatefulWidget {
  final Achievement a;
  const _DetailSheet({required this.a});
  @override
  State<_DetailSheet> createState() => _DetailSheetState();
}

class _DetailSheetState extends State<_DetailSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale, _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 480));
    _scale = Tween(begin: .5, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fade = CurvedAnimation(parent: _ctrl, curve: const Interval(0, .45));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tc = _TC(context);
    final a = widget.a;
    final rc = _T.rarColor(a.rarity);

    return Container(
      decoration: BoxDecoration(
          color: tc.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: SafeArea(
          top: false,
          child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                margin: const EdgeInsets.only(top: 10),
                width: 32,
                height: 3.5,
                decoration: BoxDecoration(
                    color: tc.textMuted,
                    borderRadius: BorderRadius.circular(2))),
            Padding(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 34),
                child: Column(children: [
                  FadeTransition(
                      opacity: _fade,
                      child: ScaleTransition(
                          scale: _scale,
                          child: Stack(alignment: Alignment.center, children: [
                            if (a.isUnlocked)
                              Container(
                                  width: 110,
                                  height: 110,
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(colors: [
                                        rc.withOpacity(.2),
                                        Colors.transparent
                                      ]))),
                            _BadgeWidget(a: a, tc: tc, size: 92),
                          ]))),
                  const SizedBox(height: 18),
                  Text(a.title,
                      style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          color: tc.textPri,
                          letterSpacing: -.4),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  Wrap(
                      spacing: 7,
                      runSpacing: 5,
                      alignment: WrapAlignment.center,
                      children: [
                        _pill(rc, _cap(a.rarity.name)),
                        _pill(_T.blue, _cap(a.category.name)),
                      ]),
                  const SizedBox(height: 16),
                  Text(a.description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13.5, height: 1.6, color: tc.textSec)),
                  if (!a.isUnlocked) ...[
                    const SizedBox(height: 14),
                    Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                            color: rc.withOpacity(.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: rc.withOpacity(.2))),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.lightbulb_outline_rounded,
                                  size: 15, color: rc),
                              const SizedBox(width: 9),
                              Expanded(
                                  child: Text(a.hint,
                                      style: TextStyle(
                                          fontSize: 12.5,
                                          height: 1.5,
                                          color: tc.textSec,
                                          fontStyle: FontStyle.italic))),
                            ])),
                  ],
                  if (!a.isUnlocked && a.progressMax != null) ...[
                    const SizedBox(height: 14),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Progress',
                                    style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: tc.textSec)),
                                Text('${a.progress} / ${a.progressMax}',
                                    style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: rc)),
                              ]),
                          const SizedBox(height: 6),
                          ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: LinearProgressIndicator(
                                  value: a.progressPercent,
                                  minHeight: 7,
                                  backgroundColor: tc.cardBorder,
                                  valueColor: AlwaysStoppedAnimation(rc))),
                        ]),
                  ],
                  const SizedBox(height: 18),
                  Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      alignment: WrapAlignment.center,
                      children: [
                        _chip(Icons.bolt, '${a.xpReward} XP', _T.gold),
                        _chip(
                            a.isUnlocked
                                ? Icons.check_circle_outline
                                : Icons.lock_outline,
                            a.isUnlocked ? 'EARNED' : 'LOCKED',
                            a.isUnlocked ? _T.green : tc.textMuted),
                        if (a.isUnlocked && a.unlockedAt != null)
                          _chip(
                              Icons.calendar_today_outlined,
                              DateFormat('dd MMM yyyy').format(a.unlockedAt!),
                              tc.textSec),
                      ]),
                ])),
          ]))),
    );
  }

  Widget _pill(Color c, String txt) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
      decoration: BoxDecoration(
          color: c.withOpacity(.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.withOpacity(.32))),
      child: Text(txt,
          style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: c,
              letterSpacing: .8)));

  Widget _chip(IconData icon, String label, Color c) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
          color: c.withOpacity(.09),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: c.withOpacity(.18))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: c),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 10.5, fontWeight: FontWeight.w700, color: c)),
      ]));
}

// ─────────────────────────────────────────────────────────────────────────────
// ACHIEVEMENTS PAGE
// ─────────────────────────────────────────────────────────────────────────────

class AchievementsPage extends StatefulWidget {
  const AchievementsPage({super.key});

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  List<Achievement> _all = [];
  bool _loading = true;
  String? _error;
  String _catFilter = 'All';
  AchievementRarity? _rarFilter;

  // String? _displayName;
  // String? _avatarUrl;

  static const _cats = [
    'All',
    'Trading',
    'Options',
    'Screener',
    'Streak',
    'Social',
    'Special'
  ];

  @override
  void initState() {
    super.initState();
    // final user = FirebaseAuth.instance.currentUser;
    // _displayName = user?.displayName;
    // _avatarUrl = user?.photoURL;
    _load();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      showBetaBottomSheet(context);
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final all = await AchievementClient.fetchAll();
      if (mounted)
        setState(() {
          _all = all;
          _loading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString();
          _loading = false;
        });
    }
  }

  // int get _totalXP =>
  //     _all.where((a) => a.isUnlocked).fold(0, (s, a) => s + a.xpReward);
  // int get _unlocked => _all.where((a) => a.isUnlocked).length;
  // int get _level => (_totalXP ~/ 500) + 1;
  // int get _levelXP => _totalXP % 500;

  List<Achievement> get _filtered {
    var list = _all;
    if (_catFilter != 'All')
      list = list
          .where(
              (a) => a.category.name.toLowerCase() == _catFilter.toLowerCase())
          .toList();
    if (_rarFilter != null)
      list = list.where((a) => a.rarity == _rarFilter).toList();
    return [
      ...list.where((a) => a.isUnlocked),
      ...list.where((a) => !a.isUnlocked)
    ];
  }

  /// Returns a map of category name → achievements, preserving _cats order.
  /// Only includes categories that have achievements after rarity filtering.
  Map<String, List<Achievement>> get _groupedByCategory {
    final result = <String, List<Achievement>>{};
    for (final cat in _cats.where((c) => c != 'All')) {
      var list = _all
          .where((a) => a.category.name.toLowerCase() == cat.toLowerCase())
          .toList();
      if (_rarFilter != null)
        list = list.where((a) => a.rarity == _rarFilter).toList();
      if (list.isEmpty) continue;
      result[cat] = [
        ...list.where((a) => a.isUnlocked),
        ...list.where((a) => !a.isUnlocked),
      ];
    }

    final sorted = result.entries.toList()
      ..sort((a, b) {
        final pctA = a.value.isEmpty
            ? 0.0
            : a.value.where((x) => x.isUnlocked).length / a.value.length;
        final pctB = b.value.isEmpty
            ? 0.0
            : b.value.where((x) => x.isUnlocked).length / b.value.length;
        return pctB.compareTo(pctA);
      });

    return {for (final e in sorted) e.key: e.value};
  }

  List<Achievement> get _streakAchs =>
      _all.where((a) => a.category == AchievementCategory.streak).toList();

  @override
  Widget build(BuildContext context) {
    final tc = _TC(context);
    final isDark = tc.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: tc.bg),
      child: Scaffold(
        backgroundColor: tc.bg,
        body: Column(children: [
          _buildHeader(tc),
          Expanded(
              child: _loading
                  ? _buildSkeleton(tc)
                  : _error != null
                      ? _buildError(tc)
                      : _buildContent(tc)),
        ]),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  // Ultra-minimal: [←]  [avatar · name]  ——spacer——  [🏆 Global List]

  Widget _buildHeader(_TC tc) {
    return Container(
      decoration: BoxDecoration(
          color: tc.surface,
          border: Border(bottom: BorderSide(color: tc.cardBorder))),
      child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
            child:
                Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              // Back
              GestureDetector(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                          color: tc.card,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: tc.cardBorder)),
                      child: Icon(Icons.arrow_back_ios_new_rounded,
                          size: 14, color: tc.textSec))),
              const SizedBox(width: 10),

              // Avatar
              // _buildAvatar(tc),
              const SizedBox(width: 9),

              // Name only — XP/progress lives in the body card
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                    Text('ACHIEVEMENTS',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: tc.textPri,
                            letterSpacing: -.2),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    // Text('Achievements',
                    //     style: TextStyle(
                    //         fontSize: 10.5,
                    //         color: tc.textMuted,
                    //         fontWeight: FontWeight.w500)),
                  ])),

              const SizedBox(width: 8),

              // Global List button
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => LeaderboardAchivementPage()),
                  );
                },
                child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                        color: _T.gold.withOpacity(.10),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: _T.gold.withOpacity(.30))),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.emoji_events_rounded,
                          size: 14, color: _T.gold),
                      const SizedBox(width: 5),
                      Text('Global List',
                          style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: _T.gold)),
                    ])),
              ),
            ]),
          )),
    );
  }

  // Widget _buildAvatar(_TC tc) {
  //   final init = (_displayName?.trim().isNotEmpty == true)
  //       ? _displayName!
  //           .trim()
  //           .split(' ')
  //           .map((w) => w.isEmpty ? '' : w[0].toUpperCase())
  //           .take(2)
  //           .join()
  //       : '?';
  //   return Container(
  //       width: 36,
  //       height: 36,
  //       decoration: BoxDecoration(
  //           shape: BoxShape.circle,
  //           gradient: const LinearGradient(
  //               colors: [_T.blue, _T.purple],
  //               begin: Alignment.topLeft,
  //               end: Alignment.bottomRight),
  //           border: Border.all(color: _T.blue.withOpacity(.35), width: 1.5)),
  //       child: _avatarUrl != null
  //           ? ClipOval(
  //               child: Image.network(_avatarUrl!,
  //                   fit: BoxFit.cover,
  //                   errorBuilder: (_, __, ___) => Center(
  //                       child: Text(init,
  //                           style: const TextStyle(
  //                               fontSize: 13,
  //                               fontWeight: FontWeight.w900,
  //                               color: Colors.white)))))
  //           : Center(
  //               child: Text(init,
  //                   style: const TextStyle(
  //                       fontSize: 13,
  //                       fontWeight: FontWeight.w900,
  //                       color: Colors.white))));
  // }

  // ── XP / level card — shown at top of body scroll ─────────────────────────

  // ── Filter row (categories + rarity in one line) ───────────────────────────

  Widget _buildFilterRow(_TC tc) {
    return Padding(
      padding: EdgeInsets.fromLTRB(0, 4, 0, 4),
      child: SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
            children: [
              // Category pills
              ..._cats.map((cat) {
                final sel = cat == _catFilter;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _catFilter = cat);
                      },
                      child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 11, vertical: 4),
                          decoration: BoxDecoration(
                              color: sel ? _T.blue : tc.card,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: sel ? _T.blue : tc.cardBorder)),
                          child: Text(cat,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight:
                                      sel ? FontWeight.w700 : FontWeight.w500,
                                  color: sel ? Colors.white : tc.textSec)))),
                );
              }),

              // Divider
              Container(
                  width: 1,
                  height: 22,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  color: tc.cardBorder),

              // Rarity pills: All + each rarity
              _rarPill(null, 'All ✦', tc),
              ...AchievementRarity.values
                  .map((r) => _rarPill(r, _cap(r.name), tc)),
            ],
          )),
    );
  }

  Widget _rarPill(AchievementRarity? r, String label, _TC tc) {
    final sel = _rarFilter == r;
    final c = r != null ? _T.rarColor(r) : tc.textSec;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _rarFilter = r);
          },
          child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: sel ? c.withOpacity(.15) : tc.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: sel ? c.withOpacity(.5) : tc.cardBorder)),
              child: Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                      color: sel ? c : tc.textSec)))),
    );
  }

  // ── Main content ───────────────────────────────────────────────────────────

  Widget _buildContent(_TC tc) {
    final isAll = _catFilter == 'All';

    return Column(children: [
      _buildFilterRow(tc),

      // // Count hint
      // Padding(
      //     padding: const EdgeInsets.fromLTRB(14, 2, 14, 2),
      //     child: Row(children: [
      //       const Spacer(),
      //       Text(
      //           isAll
      //               ? '${_all.where((a) => _rarFilter == null || a.rarity == _rarFilter).length} achievements'
      //               : '${_filtered.length} achievement${_filtered.length == 1 ? '' : 's'}',
      //           style: TextStyle(fontSize: 9.5, color: tc.textMuted)),
      //     ])),

      Expanded(
          child: isAll ? _buildAllGrouped(tc) : _buildFlatGrid(tc, _filtered)),
    ]);
  }

  // ── All view — grouped by category ────────────────────────────────────────

  Widget _buildAllGrouped(_TC tc) {
    final grouped = _groupedByCategory;

    if (grouped.isEmpty) {
      return _emptyState(tc);
    }

    // Build one big sliver list: streak card first, then per-category sections
    return RefreshIndicator(
        onRefresh: _load,
        color: _T.gold,
        backgroundColor: tc.surface,
        child: CustomScrollView(slivers: [
          // XP card
          // SliverToBoxAdapter(child: _buildXpCard(tc)),

          // Streak card
          if (_streakAchs.isNotEmpty)
            SliverToBoxAdapter(
                child: Container(
                    margin: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                    child: StreakCard())),

          // Per-category sections
          for (final entry in grouped.entries) ...[
            SliverToBoxAdapter(
                child: _SectionHeader(
                    cat: entry.key,
                    total: entry.value.length,
                    unlocked: entry.value.where((a) => a.isUnlocked).length,
                    tc: tc)),
            SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 4),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 9,
                      mainAxisSpacing: 9,
                      childAspectRatio: .73),
                  delegate: SliverChildBuilderDelegate((_, i) {
                    final a = entry.value[i];
                    return TweenAnimationBuilder<double>(
                        key: ValueKey(a.id),
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: Duration(
                            milliseconds: 200 + (i * 30).clamp(0, 360)),
                        curve: Curves.easeOutBack,
                        builder: (_, v, child) => Transform.scale(
                            scale: v,
                            child: Opacity(
                                opacity: v.clamp(0.0, 1.0), child: child)),
                        child: _BadgeCard(
                            a: a,
                            onTap: () => showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => _DetailSheet(a: a))));
                  }, childCount: entry.value.length),
                )),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ]));
  }

  // ── Single-category flat grid ──────────────────────────────────────────────

  Widget _buildFlatGrid(_TC tc, List<Achievement> items) {
    final showStreak = _catFilter == 'Streak';

    if (items.isEmpty && !showStreak) return _emptyState(tc);

    return RefreshIndicator(
        onRefresh: _load,
        color: _T.gold,
        backgroundColor: tc.surface,
        child: CustomScrollView(slivers: [
          // XP card
          // SliverToBoxAdapter(child: _buildXpCard(tc)),

          if (showStreak && _streakAchs.isNotEmpty)
            SliverToBoxAdapter(
                child: Container(
                    margin: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                    child: StreakCard())),
          if (items.isEmpty)
            SliverFillRemaining(hasScrollBody: false, child: _emptyState(tc))
          else
            SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 100),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 9,
                      mainAxisSpacing: 9,
                      childAspectRatio: .73),
                  delegate: SliverChildBuilderDelegate((_, i) {
                    final a = items[i];
                    return TweenAnimationBuilder<double>(
                        key: ValueKey(a.id),
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: Duration(
                            milliseconds: 240 + (i * 30).clamp(0, 480)),
                        curve: Curves.easeOutBack,
                        builder: (_, v, child) => Transform.scale(
                            scale: v,
                            child: Opacity(
                                opacity: v.clamp(0.0, 1.0), child: child)),
                        child: _BadgeCard(
                            a: a,
                            onTap: () => showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => _DetailSheet(a: a))));
                  }, childCount: items.length),
                )),
        ]));
  }

  Widget _emptyState(_TC tc) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.military_tech_outlined,
            size: 48, color: tc.textMuted.withOpacity(.35)),
        const SizedBox(height: 10),
        Text('No achievements here',
            style: TextStyle(fontSize: 13, color: tc.textMuted))
      ]));

  // ── Skeleton ───────────────────────────────────────────────────────────────
  Widget _buildSkeleton(_TC tc) {
    return CustomScrollView(slivers: [
      // ── Static XP card (chrome, no shimmer) ──────────────────────────

      // ── Static filter row (all pills rendered, no shimmer) ───────────
      SliverToBoxAdapter(child: _buildFilterRow(tc)),

      // ── Static streak card shell ──────────────────────────────────────
      // ── Static streak card shell ──────────────────────────────────────────────
      SliverToBoxAdapter(
        child: Container(
          margin: const EdgeInsets.fromLTRB(14, 8, 14, 4),
          child: StreakCardSkeleton(), // ← replaces the hand-rolled shell
        ),
      ),

      // ── Three category sections, each with static header + shimmer grid ─
      for (final section in _skeletonSections(tc)) ...[
        SliverToBoxAdapter(child: section.header),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 4),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 9,
              mainAxisSpacing: 9,
              childAspectRatio: .73,
            ),
            delegate: SliverChildBuilderDelegate(
              (_, i) => _SkeletonBadgeCard(tc: tc, delayMs: i * 80),
              childCount: section.count,
            ),
          ),
        ),
      ],

      const SliverToBoxAdapter(child: SizedBox(height: 100)),
    ]);
  }

  List<({Widget header, int count})> _skeletonSections(_TC tc) => [
        (
          header: _skeletonSectionHeader('Trading',
              Icons.candlestick_chart_rounded, _T.catColor('trading'), .55, tc),
          count: 3
        ),
        (
          header: _skeletonSectionHeader(
              'Options', Icons.layers_rounded, _T.catColor('options'), .30, tc),
          count: 6
        ),
        (
          header: _skeletonSectionHeader('Screener', Icons.search_rounded,
              _T.catColor('screener'), .20, tc),
          count: 3
        ),
      ];

  Widget _skeletonSectionHeader(
      String label, IconData icon, Color c, double progressHint, _TC tc) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: tc.sectionHeaderBg,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: c.withOpacity(.22)),
      ),
      child: Row(children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: c.withOpacity(.14),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, size: 15, color: c),
        ),
        const SizedBox(width: 10),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: tc.textPri,
                      letterSpacing: -.1)),
              const SizedBox(width: 6),
              _Shimmer(width: 36, height: 10, tc: tc, delay: 100),
            ]),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progressHint, // hint so layout is stable
                minHeight: 2.5,
                backgroundColor: tc.cardBorder,
                valueColor: AlwaysStoppedAnimation(c.withOpacity(.55)),
              ),
            ),
          ]),
        ),
        const SizedBox(width: 10),
        _Shimmer(width: 28, height: 11, tc: tc, delay: 200),
      ]),
    );
  }

  // ── Error ──────────────────────────────────────────────────────────────────

  Widget _buildError(_TC tc) => Center(
      child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 68,
                height: 68,
                decoration:
                    BoxDecoration(color: tc.orangeDim, shape: BoxShape.circle),
                child:
                    Icon(Icons.cloud_off_rounded, size: 32, color: _T.orange)),
            const SizedBox(height: 18),
            Text('Could not load achievements',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: tc.textPri)),
            const SizedBox(height: 7),
            Text(_error ?? 'An unexpected error occurred.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: tc.textSec)),
            const SizedBox(height: 22),
            ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded, size: 15),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: _T.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 26, vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13)),
                    textStyle: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13.5))),
          ])));
}

// ── Shimmer pulse widget ────────────────────────────────────────────────────

class _Shimmer extends StatefulWidget {
  final double width, height;
  final _TC tc;
  final int delay;
  final double radius;
  const _Shimmer({
    required this.width,
    required this.height,
    required this.tc,
    this.delay = 0,
    this.radius = 6,
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
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tc = widget.tc;
    final base = tc.dark ? const Color(0xFF141826) : const Color(0xFFE2E6F4);
    final hi = tc.dark ? const Color(0xFF1E2848) : const Color(0xFFF0F3FF);

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final t = _anim.value;
        return Container(
          width: widget.width == double.infinity ? null : widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: const Alignment(-1, 0),
              end: const Alignment(1, 0),
              stops: [
                (t - .3).clamp(0.0, 1.0),
                t.clamp(0.0, 1.0),
                (t + .3).clamp(0.0, 1.0),
              ],
              colors: [base, hi, base],
            ),
          ),
        );
      },
    );
  }
}

// ── Skeleton badge card ─────────────────────────────────────────────────────

class _SkeletonBadgeCard extends StatelessWidget {
  final _TC tc;
  final int delayMs;
  const _SkeletonBadgeCard({required this.tc, this.delayMs = 0});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tc.cardBorder),
      ),
      padding: const EdgeInsets.fromLTRB(5, 10, 5, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _Shimmer(width: 52, height: 52, tc: tc, radius: 26, delay: delayMs),
          const SizedBox(height: 6),
          _Shimmer(
              width: double.infinity, height: 9, tc: tc, delay: delayMs + 30),
          const SizedBox(height: 4),
          _Shimmer(width: 40, height: 8, tc: tc, delay: delayMs + 60),
          const SizedBox(height: 6),
          _Shimmer(width: 30, height: 8, tc: tc, delay: delayMs + 90),
        ],
      ),
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────────
// SECTION HEADER  (used in grouped "All" view)
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String cat;
  final int total;
  final int unlocked;
  final _TC tc;

  const _SectionHeader(
      {required this.cat,
      required this.total,
      required this.unlocked,
      required this.tc});

  @override
  Widget build(BuildContext context) {
    final c = _T.catColor(cat);
    final icon = _T.catIcon(cat);
    final pct = total == 0 ? 0.0 : unlocked / total;

    return Container(
        margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
            color: tc.sectionHeaderBg,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: c.withOpacity(.22))),
        child: Row(children: [
          Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                  color: c.withOpacity(.14),
                  borderRadius: BorderRadius.circular(7)),
              child: Icon(icon, size: 15, color: c)),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(children: [
                  Text(cat,
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: tc.textPri,
                          letterSpacing: -.1)),
                  const SizedBox(width: 6),
                  Text('$unlocked / $total',
                      style: TextStyle(fontSize: 10.5, color: tc.textMuted)),
                ]),
                const SizedBox(height: 4),
                ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 2.5,
                        backgroundColor: tc.cardBorder,
                        valueColor: AlwaysStoppedAnimation(c))),
              ])),
          const SizedBox(width: 10),
          Text('${(pct * 100).round()}%',
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: c)),
        ]));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// UTILS
// ─────────────────────────────────────────────────────────────────────────────

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
