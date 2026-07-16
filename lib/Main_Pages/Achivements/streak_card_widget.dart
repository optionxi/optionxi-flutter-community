// ============================================================
//  OptionXi — streak_card_widget.dart  (v2)
//
//  Changes from v1:
//   • Light / dark theme compatible — colours derived from
//     Theme brightness, not hardcoded dark hex.
//   • Two public widgets:
//
//       StreakCard()
//         — fetches BOTH streak state AND streak achievements
//           (milestone dots + progress bar).  Same as before.
//
//       StreakMiniCard()   ← NEW
//         — fetches ONLY xi_streak_state (one fast query).
//           Shows days, next milestone, progress bar.
//           No achievement list, no milestone dot row.
//           Drop into any ScrollView — self-contained fetch + dispose.
//
//  Usage:
//    StreakCard()       ← full card with milestone achievement dots
//    StreakMiniCard()   ← lightweight, streak-only, any scroll view
// ============================================================

import 'package:flutter/material.dart';
import 'package:optionxi/Main_Pages/Achivements/fastapi_achivement.dart';
import 'package:optionxi/Main_Pages/Achivements/streak_card_loading.dart';

// ─────────────────────────────────────────────────────────────────────────────
// THEME HELPER
// ─────────────────────────────────────────────────────────────────────────────

class _TC {
  final bool dark;
  _TC(BuildContext ctx) : dark = Theme.of(ctx).brightness == Brightness.dark;

  // Lifted the dark card background slightly for better depth
  Color get card => dark ? const Color(0xFF1B2030) : const Color(0xFFF2F4FF);

  // Brightened the border in dark mode for clearer widget separation
  Color get cardBorder =>
      dark ? const Color(0xFF2B3248) : const Color(0xFFD6DAF0);

  // Softer white in dark mode to prevent eye strain / glare
  Color get textPri => dark ? const Color(0xFFE2E8F0) : const Color(0xFF0D1120);

  // Adjusted secondary text for clearer contrast
  Color get textSec => dark ? const Color(0xFFA0AABF) : const Color(0xFF4A5270);

  // Significantly brightened muted text in dark mode so it's actually readable
  Color get textMuted =>
      dark ? const Color(0xFF6B7794) : const Color(0xFFB0B8D4);

  // Softer orange in dark mode to prevent "blooming" against the dark background
  Color get streakOrange =>
      dark ? const Color(0xFFFF9B5A) : const Color(0xFFFF8C42);
}

// ─────────────────────────────────────────────────────────────────────────────
// FULL STREAK CARD  (streak state + milestone achievement dots)
// ─────────────────────────────────────────────────────────────────────────────

class StreakCard extends StatefulWidget {
  /// Optional: pass pre-fetched data to skip the internal fetch.
  final StreakState? streakState;
  final List<Achievement>? streakAchs;

  const StreakCard({super.key, this.streakState, this.streakAchs});

  @override
  State<StreakCard> createState() => _StreakCardState();
}

class _StreakCardState extends State<StreakCard> {
  StreakState? _streakState;
  List<Achievement> _streakAchs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.streakState != null && widget.streakAchs != null) {
      _streakState = widget.streakState;
      _streakAchs = widget.streakAchs!;
      _loading = false;
    } else {
      _fetch();
    }
  }

  Future<void> _fetch() async {
    try {
      final results = await Future.wait([
        AchievementClient.fetchStreakState(),
        AchievementClient.fetchAll(),
      ]);
      if (!mounted) return;
      setState(() {
        _streakState = results[0] as StreakState;
        final all = results[1] as List<Achievement>;
        _streakAchs =
            all.where((a) => a.category == AchievementCategory.streak).toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return StreakCardSkeleton();
    if (_streakState == null) return const SizedBox.shrink();
    return _StreakCardView(streakState: _streakState!, streakAchs: _streakAchs);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FULL CARD VIEW (with milestone dots)
// ─────────────────────────────────────────────────────────────────────────────

class _StreakCardView extends StatelessWidget {
  final StreakState streakState;
  final List<Achievement> streakAchs;

  const _StreakCardView({required this.streakState, required this.streakAchs});

  @override
  Widget build(BuildContext context) {
    final tc = _TC(context);
    final currentDays = streakState.streakDays;

    const milestones = [3, 7, 30, 365];
    const ids = ['streak_3', 'streak_7', 'streak_30', 'streak_365'];

    int nextMilestone = milestones.last;
    for (final m in milestones) {
      if (currentDays < m) {
        nextMilestone = m;
        break;
      }
    }

    final pct = (currentDays / nextMilestone).clamp(0.0, 1.0);

    bool isUnlocked(String id) =>
        streakAchs.where((a) => a.id == id).firstOrNull?.isUnlocked ?? false;

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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header row ──────────────────────────────────────────────────────
        Row(children: [
          Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                  color: tc.streakOrange.withOpacity(.18),
                  borderRadius: BorderRadius.circular(9)),
              child: Icon(Icons.local_fire_department_rounded,
                  size: 18, color: tc.streakOrange)),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Trading Streak',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: tc.textPri)),
            Text(
                '$currentDays day${currentDays == 1 ? '' : 's'} · Next: $nextMilestone days',
                style: TextStyle(fontSize: 10.5, color: tc.textSec)),
          ]),
          const Spacer(),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: tc.streakOrange.withOpacity(.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: tc.streakOrange.withOpacity(.3))),
              child: Text('🔥 $currentDays',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: tc.streakOrange))),
        ]),
        const SizedBox(height: 12),

        // ── Milestone dots ───────────────────────────────────────────────────
        Row(
            children: List.generate(milestones.length, (i) {
          final reached = currentDays >= milestones[i];
          final done = isUnlocked(ids[i]);
          final active = reached || done;

          return Expanded(
            child: Padding(
              padding:
                  EdgeInsets.only(right: i < milestones.length - 1 ? 6 : 0),
              child: Column(children: [
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                      color: active ? tc.streakOrange : tc.cardBorder,
                      borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 4),
                Text('${milestones[i]}d',
                    style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                        color: active ? tc.streakOrange : tc.textMuted)),
              ]),
            ),
          );
        })),
        const SizedBox(height: 8),

        // ── Progress bar ─────────────────────────────────────────────────────
        ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
                value: pct,
                minHeight: 5,
                backgroundColor: tc.cardBorder,
                valueColor: AlwaysStoppedAnimation(tc.streakOrange))),
        const SizedBox(height: 5),
        Text('$currentDays / $nextMilestone days to next milestone',
            style: TextStyle(fontSize: 9.5, color: tc.textMuted)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// StreakMiniCard  — NEW
//
//  Self-contained. Fetches ONLY xi_streak_state (fast).
//  No achievements query, no milestone dot row.
//  Drop anywhere in a ScrollView.
//
//  Usage:  StreakMiniCard()
// ─────────────────────────────────────────────────────────────────────────────

class StreakMiniCard extends StatefulWidget {
  const StreakMiniCard({super.key});

  @override
  State<StreakMiniCard> createState() => _StreakMiniCardState();
}

class _StreakMiniCardState extends State<StreakMiniCard> {
  StreakState? _state;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final s = await AchievementClient.fetchStreakState();
      if (!mounted) return;
      setState(() {
        _state = s;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return StreakMiniCardSkeleton();
    if (_state == null) return const SizedBox.shrink();
    return _StreakMiniView(state: _state!);
  }
}

class _StreakMiniView extends StatelessWidget {
  final StreakState state;
  const _StreakMiniView({required this.state});

  @override
  Widget build(BuildContext context) {
    final tc = _TC(context);
    final days = state.streakDays;

    const milestones = [3, 7, 30, 365];
    int nextMilestone = milestones.last;
    for (final m in milestones) {
      if (days < m) {
        nextMilestone = m;
        break;
      }
    }
    final pct = (days / nextMilestone).clamp(0.0, 1.0);
    final remaining = nextMilestone - days;

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
        // ── Flame badge ──────────────────────────────────────────────────────
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
              color: tc.streakOrange.withOpacity(.18),
              borderRadius: BorderRadius.circular(14)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.local_fire_department_rounded,
                size: 20, color: tc.streakOrange),
            const SizedBox(height: 1),
            Text('$days',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: tc.streakOrange,
                    height: 1)),
          ]),
        ),
        const SizedBox(width: 14),

        // ── Label + bar ──────────────────────────────────────────────────────
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('Trading Streak',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: tc.textPri)),
              const Spacer(),
              Text('$remaining day${remaining == 1 ? '' : 's'} to go',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: tc.streakOrange)),
            ]),
            const SizedBox(height: 6),
            ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 5,
                    backgroundColor: tc.cardBorder,
                    valueColor: AlwaysStoppedAnimation(tc.streakOrange))),
            const SizedBox(height: 5),
            Text('$days / $nextMilestone days · next milestone 🎯',
                style: TextStyle(fontSize: 10, color: tc.textMuted)),
          ]),
        ),
      ]),
    );
  }
}
