import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:optionxi/Main_Pages/act_breakout_page.dart';
import 'package:optionxi/Main_Pages/act_traderprofile.dart';

// ─────────────────────────────────────────────────────────────
//  DESIGN SYSTEM
// ─────────────────────────────────────────────────────────────
class _DS {
  // Gold / Silver / Bronze accent stops
  static const gold = Color(0xFFFFBF00);
  static const silver = Color(0xFFC0C8D8);
  static const bronze = Color(0xFFCD7F32);

  static Color rankAccent(int rank) {
    switch (rank) {
      case 1:
        return gold;
      case 2:
        return silver;
      case 3:
        return bronze;
      default:
        return const Color(0xFF6C8EF5);
    }
  }

  // Adaptive colours
  static Color surface(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? const Color(0xFF131620)
          : const Color(0xFFF4F6FC);

  static Color card(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? const Color(0xFF1C2030)
          : Colors.white;

  static Color cardBorder(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? const Color(0xFF2A3050)
          : const Color(0xFFE8ECF6);

  static Color textPrimary(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? const Color(0xFFECEFF9)
          : const Color(0xFF131620);

  static Color textSecondary(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? const Color(0xFF7A85A8)
          : const Color(0xFF8891B4);

  static Color shimmerBase(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? const Color(0xFF1C2030)
          : const Color(0xFFE8ECF6);

  static Color shimmerHighlight(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? const Color(0xFF252A40)
          : const Color(0xFFF4F6FC);
}

// ─────────────────────────────────────────────────────────────
//  DATA MODEL
// ─────────────────────────────────────────────────────────────
class LeaderboardEntry {
  final int rank;
  final String username;
  final double points;
  final String level;
  final String imageUrl;
  final String suid;

  const LeaderboardEntry({
    required this.rank,
    required this.username,
    required this.points,
    required this.level,
    required this.imageUrl,
    required this.suid,
  });
}

// ─────────────────────────────────────────────────────────────
//  HELPERS
// ─────────────────────────────────────────────────────────────
String _formatBalance(double v) {
  if (v >= 1e7) return '₹${(v / 1e7).toStringAsFixed(1)}Cr';
  if (v >= 1e5) return '₹${(v / 1e5).toStringAsFixed(1)}L';
  if (v >= 1e3) return '₹${(v / 1e3).toStringAsFixed(1)}K';
  return '₹${v.toStringAsFixed(0)}';
}

// ─────────────────────────────────────────────────────────────
//  LEADERBOARD PAGE
// ─────────────────────────────────────────────────────────────
class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({Key? key}) : super(key: key);

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _listAnim;
  List<LeaderboardEntry> leaderboardEntries = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _listAnim = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _loadLeaderboardData();
  }

  Future<void> _loadLeaderboardData() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final response = await supabase
          .from('prev_balance')
          .select('suid, balance, displayname, imgurl')
          .order('balance', ascending: false)
          .limit(30); // Top 30 users by balance

      final List<LeaderboardEntry> entries = [];
      for (int i = 0; i < response.length; i++) {
        final data = response[i];
        entries.add(LeaderboardEntry(
          rank: i + 1,
          username: data['displayname'] ?? 'Unknown User',
          points: (data['balance'] as num).toDouble(),
          level: "Trader",
          imageUrl: data['imgurl'] ?? 'https://via.placeholder.com/150',
          suid: data['suid'],
        ));
      }

      setState(() {
        leaderboardEntries = entries;
        isLoading = false;
      });

      _listAnim.forward(from: 0);
    } catch (e) {
      setState(() {
        error = 'Failed to load leaderboard. Pull to refresh.';
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _listAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _DS.surface(context),
      body: RefreshIndicator(
        color: const Color(0xFF6C8EF5),
        onRefresh: _loadLeaderboardData,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Handles status bar height at the very top
            SliverToBoxAdapter(
              child: SizedBox(height: MediaQuery.of(context).padding.top),
            ),
            _SliverHeader(),
            if (isLoading)
              SliverToBoxAdapter(child: _SkeletonList())
            else if (error != null)
              SliverFillRemaining(
                  child: _ErrorState(error!, _loadLeaderboardData))
            else if (leaderboardEntries.isEmpty)
              SliverFillRemaining(child: _EmptyState())
            else
              _LeaderboardSliver(
                entries: leaderboardEntries,
                controller: _listAnim,
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                child: _PrivacyNotice(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SLIVER HEADER
// ─────────────────────────────────────────────────────────────
class _SliverHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Nav row: back + title inline ──────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Back button — minimal, tap-friendly
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(50),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                        color: _DS.textPrimary(context),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Trophy icon
                ShaderMask(
                  shaderCallback: (r) => const LinearGradient(
                    colors: [Color(0xFF6C8EF5), Color(0xFFA78BFA)],
                  ).createShader(r),
                  child: const Icon(Icons.emoji_events_rounded,
                      color: Colors.white, size: 26),
                ),
                const SizedBox(width: 8),
                // Title
                Text(
                  'Leaderboard',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.4,
                    color: _DS.textPrimary(context),
                  ),
                ),
              ],
            ),
          ),
          // ── Subtitle ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(52, 2, 16, 14),
            child: Text(
              'Virtual trading rankings — not real trades.',
              style: TextStyle(
                fontSize: 12.5,
                color: _DS.textSecondary(context),
                letterSpacing: 0.1,
              ),
            ),
          ),
          // ── Divider ───────────────────────────────────────
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6C8EF5).withOpacity(0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  LEADERBOARD SLIVER
// ─────────────────────────────────────────────────────────────
class _LeaderboardSliver extends StatelessWidget {
  final List<LeaderboardEntry> entries;
  final AnimationController controller;

  const _LeaderboardSliver({required this.entries, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (ctx, i) {
            final e = entries[i];
            final startT = math.min(i * 0.05, 0.75);
            final endT = math.min(startT + 0.25, 1.0);
            final anim = CurvedAnimation(
              parent: controller,
              curve: Interval(startT, endT, curve: Curves.easeOutCubic),
            );
            return AnimatedBuilder(
              animation: anim,
              builder: (_, child) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: _LeaderboardCard(entry: e),
            );
          },
          childCount: entries.length,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  LEADERBOARD CARD
// ─────────────────────────────────────────────────────────────
class _LeaderboardCard extends StatelessWidget {
  final LeaderboardEntry entry;

  const _LeaderboardCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final accent = _DS.rankAccent(entry.rank);
    final isTop3 = entry.rank <= 3;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _DS.card(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isTop3
              ? accent.withOpacity(dark ? 0.35 : 0.25)
              : _DS.cardBorder(context),
          width: isTop3 ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isTop3
                ? accent.withOpacity(dark ? 0.08 : 0.06)
                : Colors.black.withOpacity(dark ? 0.2 : 0.04),
            blurRadius: isTop3 ? 16 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => TraderProfilePage(entry)));
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // ── Rank badge ──────────────────────────────
                _RankBadge(rank: entry.rank, accent: accent),
                const SizedBox(width: 14),
                // ── Name + balance ──────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.username,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                              isTop3 ? FontWeight.w700 : FontWeight.w600,
                          color: _DS.textPrimary(context),
                          letterSpacing: -0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: accent.withOpacity(dark ? 0.15 : 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _formatBalance(entry.points),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: accent,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // ── Avatar ──────────────────────────────────
                _Avatar(
                  imageUrl: entry.imageUrl,
                  accent: accent,
                  isTop3: isTop3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  RANK BADGE
// ─────────────────────────────────────────────────────────────
class _RankBadge extends StatelessWidget {
  final int rank;
  final Color accent;

  const _RankBadge({required this.rank, required this.accent});

  IconData? _icon() {
    switch (rank) {
      case 1:
        return Icons.emoji_events_rounded;
      case 2:
        return Icons.military_tech_rounded;
      case 3:
        return Icons.workspace_premium_rounded;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final icon = _icon();
    if (icon != null) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: accent.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: accent, size: 26),
      );
    }
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: _DS.cardBorder(context),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$rank',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _DS.textSecondary(context),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  AVATAR
// ─────────────────────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final String imageUrl;
  final Color accent;
  final bool isTop3;

  const _Avatar(
      {required this.imageUrl, required this.accent, required this.isTop3});

  @override
  Widget build(BuildContext context) {
    final size = isTop3 ? 48.0 : 42.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: isTop3
            ? Border.all(color: accent, width: 2)
            : Border.all(color: _DS.cardBorder(context), width: 1),
      ),
      child: ClipOval(
        child: Image.network(
          imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: accent.withOpacity(0.15),
            child: Icon(Icons.person_rounded, color: accent, size: size * 0.55),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SKELETON LOADER
// ─────────────────────────────────────────────────────────────
class _SkeletonList extends StatefulWidget {
  @override
  State<_SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<_SkeletonList>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: List.generate(
          8,
          (i) => AnimatedBuilder(
            animation: _shimmer,
            builder: (_, __) {
              final gradient = LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  _DS.shimmerBase(context),
                  _DS.shimmerHighlight(context),
                  _DS.shimmerBase(context),
                ],
                stops: [
                  (_shimmer.value - 0.3).clamp(0.0, 1.0),
                  _shimmer.value.clamp(0.0, 1.0),
                  (_shimmer.value + 0.3).clamp(0.0, 1.0),
                ],
              );

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: _DS.card(context),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _DS.cardBorder(context)),
                ),
                child: Row(
                  children: [
                    // Badge circle
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: gradient,
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Name + balance
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 14,
                            width: 120 + i * 4.0,
                            decoration: BoxDecoration(
                              gradient: gradient,
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 12,
                            width: 70,
                            decoration: BoxDecoration(
                              gradient: gradient,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Avatar circle
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: gradient,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  ERROR STATE
// ─────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState(this.message, this.onRetry);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off_rounded,
                  size: 40, color: Colors.redAccent),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: _DS.textSecondary(context),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try again'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6C8EF5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  EMPTY STATE
// ─────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF6C8EF5).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emoji_events_outlined,
                size: 48, color: Color(0xFF6C8EF5)),
          ),
          const SizedBox(height: 20),
          Text(
            'No rankings yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _DS.textPrimary(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to make it to the leaderboard!',
            style: TextStyle(
              fontSize: 14,
              color: _DS.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  PRIVACY NOTICE
// ─────────────────────────────────────────────────────────────
class _PrivacyNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1A2040) : const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: dark ? const Color(0xFF2A3A70) : const Color(0xFFD0D9FF),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6C8EF5).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.shield_outlined,
                color: Color(0xFF6C8EF5), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Privacy Mode',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: dark
                        ? const Color(0xFF9EB4FF)
                        : const Color(0xFF3A5AF5),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Enable privacy mode in your profile to hide your name and photo from this leaderboard.',
                  style: TextStyle(
                    fontSize: 12,
                    color: _DS.textSecondary(context),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
