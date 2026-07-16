import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:optionxi/Main_Pages/BollingerBreakouts/act_breakout_page.dart';
import 'package:optionxi/Main_Pages/Profile/act_traderprofile.dart';

// ─────────────────────────────────────────────────────────────
//  DESIGN SYSTEM
// ─────────────────────────────────────────────────────────────
class _DS {
  static const gold = Color(0xFFFFBF00);
  static const silver = Color(0xFFC0C8D8);
  static const bronze = Color(0xFFCD7F32);
  static const accent = Color(0xFF6C8EF5);

  static Color rankAccent(int rank) {
    switch (rank) {
      case 1:
        return gold;
      case 2:
        return silver;
      case 3:
        return bronze;
      default:
        return accent;
    }
  }

  static bool dark(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark;

  static Color surface(BuildContext ctx) =>
      dark(ctx) ? const Color(0xFF0E1117) : const Color(0xFFF2F4FB);

  static Color card(BuildContext ctx) =>
      dark(ctx) ? const Color(0xFF171C2A) : Colors.white;

  static Color cardBorder(BuildContext ctx) =>
      dark(ctx) ? const Color(0xFF252D45) : const Color(0xFFE4E9F4);

  static Color textPrimary(BuildContext ctx) =>
      dark(ctx) ? const Color(0xFFECEFF9) : const Color(0xFF111827);

  static Color textSecondary(BuildContext ctx) =>
      dark(ctx) ? const Color(0xFF6B7594) : const Color(0xFF8891B4);

  static Color shimBase(BuildContext ctx) =>
      dark(ctx) ? const Color(0xFF171C2A) : const Color(0xFFE4E9F4);

  static Color shimHigh(BuildContext ctx) =>
      dark(ctx) ? const Color(0xFF232A40) : const Color(0xFFF4F6FC);
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
//  SHIMMER ENGINE  —  single controller per shimmer item,
//  ShaderMask sweep, zero plugins
// ─────────────────────────────────────────────────────────────
class _Shimmer extends StatefulWidget {
  final Widget child;
  final Color base;
  final Color highlight;

  const _Shimmer({
    required this.child,
    required this.base,
    required this.highlight,
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
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _anim = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine),
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
      builder: (_, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) => LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            widget.base,
            widget.base,
            widget.highlight,
            widget.base,
            widget.base,
          ],
          stops: [
            0.0,
            (_anim.value - 0.3).clamp(0.0, 1.0),
            _anim.value.clamp(0.0, 1.0),
            (_anim.value + 0.3).clamp(0.0, 1.0),
            1.0,
          ],
        ).createShader(bounds),
        child: child,
      ),
      child: widget.child,
    );
  }
}

// Primitive blocks used inside skeleton items
class _ShimPill extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  const _ShimPill(this.width, this.height, {this.radius = 7});

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: _DS.shimBase(context),
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}

class _ShimCircle extends StatelessWidget {
  final double size;
  const _ShimCircle(this.size);

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: _DS.shimBase(context),
          shape: BoxShape.circle,
        ),
      );
}

// ─────────────────────────────────────────────────────────────
//  SKELETON CARD  —  structural chrome is static (border, bg,
//  spacing); only the dynamic content areas shimmer.
// ─────────────────────────────────────────────────────────────
class _SkeletonCard extends StatelessWidget {
  final int index;
  const _SkeletonCard({required this.index});

  @override
  Widget build(BuildContext context) {
    const nameWidths = [130.0, 100.0, 150.0, 115.0, 90.0, 140.0, 105.0, 125.0];
    final nw = nameWidths[index % nameWidths.length];
    final base = _DS.shimBase(context);
    final high = _DS.shimHigh(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      // ── Static chrome ──────────────────────────────────────
      decoration: BoxDecoration(
        color: _DS.card(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _DS.cardBorder(context)),
      ),
      child: Row(children: [
        // Badge circle — shimmers
        _Shimmer(base: base, highlight: high, child: _ShimCircle(44)),
        const SizedBox(width: 14),
        // Name + balance — shimmer
        Expanded(
          child: _Shimmer(
            base: base,
            highlight: high,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShimPill(nw, 14),
                const SizedBox(height: 8),
                _ShimPill(72, 24, radius: 7), // chip-shaped balance placeholder
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Avatar — shimmer
        _Shimmer(base: base, highlight: high, child: _ShimCircle(42)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  PODIUM SKELETON  —  mirrors _Podium layout exactly.
//  Bars are static chrome; only avatars, name lines, balance
//  lines shimmer (the dynamic data slots).
// ─────────────────────────────────────────────────────────────
class _PodiumSkeleton extends StatelessWidget {
  const _PodiumSkeleton();

  @override
  Widget build(BuildContext context) {
    final dark = _DS.dark(context);
    final base = _DS.shimBase(context);
    final high = _DS.shimHigh(context);

    // mirror _Podium: display order 2nd | 1st | 3rd
    const avatarSizes = [48.0, 58.0, 48.0]; // centre is bigger (rank 1)
    const barHeights = [88.0, 116.0, 72.0];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      padding: const EdgeInsets.fromLTRB(8, 20, 8, 0),
      // ── Static chrome ──────────────────────────────────────
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: dark
              ? [
                  const Color(0xFF1A2040),
                  const Color(0xFF171C2A),
                  const Color(0xFF171C2A)
                ]
              : [const Color(0xFFEFF2FF), Colors.white, Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: dark ? const Color(0xFF252D45) : const Color(0xFFE4E9F4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(3, (i) {
          final isCenter = i == 1; // rank 1 slot
          final sz = avatarSizes[i];

          return Expanded(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Crown placeholder (rank 1 only) — shimmer
              if (isCenter) ...[
                _Shimmer(
                  base: base,
                  highlight: high,
                  child: _ShimPill(22, 18, radius: 5),
                ),
                const SizedBox(height: 4),
              ] else
                const SizedBox(height: 22),

              // Avatar — shimmer
              _Shimmer(
                base: base,
                highlight: high,
                child: _ShimCircle(sz),
              ),
              const SizedBox(height: 6),

              // Medal emoji placeholder — shimmer
              _Shimmer(
                base: base,
                highlight: high,
                child: _ShimPill(20, 15, radius: 5),
              ),
              const SizedBox(height: 4),

              // Name line — shimmer
              _Shimmer(
                base: base,
                highlight: high,
                child: _ShimPill(isCenter ? 56 : 48, 11),
              ),
              const SizedBox(height: 3),

              // Balance line — shimmer
              _Shimmer(
                base: base,
                highlight: high,
                child: _ShimPill(40, 9),
              ),
              const SizedBox(height: 8),

              // Podium bar — STATIC structural chrome, no shimmer
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(10)),
                child: Container(
                  height: barHeights[i],
                  decoration: BoxDecoration(
                    color: base.withOpacity(0.6),
                    border: Border.all(color: base, width: 1.5),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(10)),
                  ),
                ),
              ),
            ]),
          );
        }),
      ),
    );
  }
}

class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _PodiumSkeleton(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: List.generate(6, (i) => _SkeletonCard(index: i)),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  LEADERBOARD PAGE
// ─────────────────────────────────────────────────────────────
class LeaderboardPage extends StatefulWidget {
  final bool header;

  const LeaderboardPage({Key? key, this.header = true}) : super(key: key);

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
          .limit(30);

      final List<LeaderboardEntry> entries = [];
      for (int i = 0; i < response.length; i++) {
        final data = response[i];
        entries.add(LeaderboardEntry(
          rank: i + 1,
          username: data['displayname'] ?? 'Unknown User',
          points: (data['balance'] as num).toDouble(),
          level: 'Trader',
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
      body: SafeArea(
        child: RefreshIndicator(
          color: _DS.accent,
          onRefresh: _loadLeaderboardData,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              if (widget.header) _SliverHeader(),
              if (isLoading)
                const SliverToBoxAdapter(child: _SkeletonList())
              else if (error != null)
                SliverFillRemaining(
                    child: _ErrorState(error!, _loadLeaderboardData))
              else if (leaderboardEntries.isEmpty)
                SliverFillRemaining(child: _EmptyState())
              else ...[
                if (leaderboardEntries.length >= 3)
                  SliverToBoxAdapter(
                    child:
                        _Podium(entries: leaderboardEntries.take(3).toList()),
                  ),
                _LeaderboardSliver(
                  entries: leaderboardEntries.length >= 3
                      ? leaderboardEntries.skip(3).toList()
                      : leaderboardEntries,
                  controller: _listAnim,
                ),
              ],
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  child: _PrivacyNotice(),
                ),
              ),
            ],
          ),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(50),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Icon(Icons.arrow_back_ios_new_rounded,
                          size: 20, color: _DS.textPrimary(context)),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                ShaderMask(
                  shaderCallback: (r) => const LinearGradient(
                    colors: [Color(0xFF6C8EF5), Color(0xFFA78BFA)],
                  ).createShader(r),
                  child: const Icon(Icons.emoji_events_rounded,
                      color: Colors.white, size: 26),
                ),
                const SizedBox(width: 8),
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
//  PODIUM  (top 3 centrepiece)
// ─────────────────────────────────────────────────────────────
class _Podium extends StatelessWidget {
  final List<LeaderboardEntry> entries;
  const _Podium({required this.entries});

  @override
  Widget build(BuildContext context) {
    final dark = _DS.dark(context);
    // display order: 2nd | 1st | 3rd
    final order = [entries[1], entries[0], entries[2]];
    final heights = [88.0, 116.0, 72.0];
    final colors = [_DS.silver, _DS.gold, _DS.bronze];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      padding: const EdgeInsets.fromLTRB(8, 20, 8, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: dark
              ? [
                  const Color(0xFF1A2040),
                  const Color(0xFF171C2A),
                  const Color(0xFF171C2A)
                ]
              : [const Color(0xFFEFF2FF), Colors.white, Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: dark ? const Color(0xFF252D45) : const Color(0xFFE4E9F4),
        ),
        boxShadow: [
          BoxShadow(
            color: _DS.gold.withOpacity(dark ? 0.06 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(
          3,
          (i) => Expanded(
            child: _PodiumSlot(
              entry: order[i],
              color: colors[i],
              barHeight: heights[i],
            ),
          ),
        ),
      ),
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  final LeaderboardEntry entry;
  final Color color;
  final double barHeight;
  const _PodiumSlot({
    required this.entry,
    required this.color,
    required this.barHeight,
  });

  static const _medals = ['🥇', '🥈', '🥉'];

  @override
  Widget build(BuildContext context) {
    final dark = _DS.dark(context);
    final isFirst = entry.rank == 1;
    final medal = _medals[entry.rank - 1];
    final sz = isFirst ? 58.0 : 48.0;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TraderProfilePage(entry)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Crown only for #1
        isFirst
            ? const Text('👑', style: TextStyle(fontSize: 18))
            : const SizedBox(height: 18),
        const SizedBox(height: 4),
        // Avatar
        Container(
          width: sz,
          height: sz,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: isFirst ? 2.5 : 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(dark ? 0.3 : 0.2),
                blurRadius: isFirst ? 16 : 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipOval(
            child: Image.network(
              entry.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: color.withOpacity(0.15),
                child:
                    Icon(Icons.person_rounded, color: color, size: sz * 0.52),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(medal, style: const TextStyle(fontSize: 15)),
        const SizedBox(height: 3),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            _firstWord(entry.username),
            style: TextStyle(
              fontSize: isFirst ? 11.5 : 10.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _formatBalance(entry.points),
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: color.withOpacity(0.75),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        // Podium bar — static, structural, deliberately NOT shimmering
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
          child: Container(
            height: barHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(dark ? 0.22 : 0.18),
                  color.withOpacity(dark ? 0.07 : 0.05),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: Border.all(
                color: color.withOpacity(0.25),
                width: 1.5,
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Center(
              child: Text(
                '#${entry.rank}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: color.withOpacity(0.35),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  String _firstWord(String name) {
    final parts = name.trim().split(' ');
    return parts.isEmpty ? name : parts[0];
  }
}

// ─────────────────────────────────────────────────────────────
//  LEADERBOARD SLIVER  (rank 4+)
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
                    begin: const Offset(0, 0.25),
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
    final dark = _DS.dark(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _DS.card(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _DS.cardBorder(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(dark ? 0.18 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TraderProfilePage(entry)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              _RankBadge(rank: entry.rank, accent: accent),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.username,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _DS.textPrimary(context),
                        letterSpacing: -0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(dark ? 0.14 : 0.1),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        _formatBalance(entry.points),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: accent,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _Avatar(imageUrl: entry.imageUrl, accent: accent),
            ]),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: accent.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$rank',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: accent,
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
  const _Avatar({required this.imageUrl, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _DS.cardBorder(context), width: 1.5),
      ),
      child: ClipOval(
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: accent.withOpacity(0.12),
            child: Icon(Icons.person_rounded, color: accent, size: 22),
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
        child: Column(mainAxisSize: MainAxisSize.min, children: [
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
          Text(message,
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 14, color: _DS.textSecondary(context))),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Try again'),
            style: FilledButton.styleFrom(
              backgroundColor: _DS.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ]),
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
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _DS.accent.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.emoji_events_outlined,
              size: 48, color: _DS.accent),
        ),
        const SizedBox(height: 20),
        Text('No rankings yet',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _DS.textPrimary(context))),
        const SizedBox(height: 8),
        Text('Be the first to make it to the leaderboard!',
            style: TextStyle(fontSize: 14, color: _DS.textSecondary(context))),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  PRIVACY NOTICE
// ─────────────────────────────────────────────────────────────
class _PrivacyNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final dark = _DS.dark(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1A2040) : const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: dark ? const Color(0xFF2A3A70) : const Color(0xFFD0D9FF),
        ),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _DS.accent.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.shield_outlined, color: _DS.accent, size: 18),
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
                  color:
                      dark ? const Color(0xFF9EB4FF) : const Color(0xFF3A5AF5),
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
      ]),
    );
  }
}
