// ============================================================
//  OptionXi — leaderboard_page.dart
//
//  Shows top players ranked by total achievement XP.
//  Data from: Supabase — public.xi_leaderboard
//
//  Navigate:
//    Navigator.push(context, MaterialPageRoute(
//      builder: (_) => const LeaderboardAchivementPage()));
// ============================================================

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────────────────────────────────────

class LeaderboardEntry {
  final String firebaseUid;
  final String? displayName;
  final String? avatarUrl;
  final int totalXP;
  final int unlockedCount;
  final int rank;

  const LeaderboardEntry({
    required this.firebaseUid,
    required this.totalXP,
    required this.unlockedCount,
    required this.rank,
    this.displayName,
    this.avatarUrl,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> j,
          {required int rank}) =>
      LeaderboardEntry(
        firebaseUid: j['firebase_uid'] as String,
        displayName: j['display_name'] as String?,
        avatarUrl: j['avatar_url'] as String?,
        totalXP: j['total_xp'] as int,
        unlockedCount: j['unlocked_count'] as int,
        rank: rank,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// SUPABASE FETCH
// ─────────────────────────────────────────────────────────────────────────────

final _db = Supabase.instance.client;

Future<List<LeaderboardEntry>> fetchLeaderboard() async {
  final response = await _db
      .from('xi_leaderboard')
      .select()
      .order('total_xp', ascending: false)
      .limit(30);

  final rows = response as List<dynamic>;
  return rows
      .asMap()
      .entries
      .map((e) => LeaderboardEntry.fromJson(
            e.value as Map<String, dynamic>,
            rank: e.key + 1,
          ))
      .toList();
}

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS — static (dark)
// ─────────────────────────────────────────────────────────────────────────────

abstract class _TD {
  static const bg = Color(0xFF07090F);
  static const surface = Color(0xFF0D1018);
  static const card = Color(0xFF141826);
  static const cardBorder = Color(0xFF1E2438);
  static const textPri = Color(0xFFF0F3FF);
  static const textSec = Color(0xFF8891AA);
  static const textMuted = Color(0xFF3E4562);
  static const gold = Color(0xFFFFBC30);
  static const blue = Color(0xFF4E91FF);
  static const purple = Color(0xFFAC70FF);
  static const orange = Color(0xFFFF6F40);
  static const orangeDim = Color(0x26FF6F40);
  static const rank1 = Color(0xFFFFD060);
  static const rank2 = Color(0xFFB8C8E0);
  static const rank3 = Color(0xFFD4895A);
  // base is visibly distinct from card (0xFF141826); highlight pops against it
  static const shimBase = Color(0xFF1C2235);
  static const shimHigh = Color(0xFF2E3A55);
}

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS — static (light)
// ─────────────────────────────────────────────────────────────────────────────

abstract class _TL {
  static const bg = Color(0xFFF4F6FB);
  static const surface = Color(0xFFFFFFFF);
  static const card = Color(0xFFFFFFFF);
  static const cardBorder = Color(0xFFDDE3F0);
  static const textPri = Color(0xFF0D1018);
  static const textSec = Color(0xFF5A6380);
  static const textMuted = Color(0xFFAAB2C8);
  static const gold = Color(0xFFD49A00);
  static const blue = Color(0xFF2B72F0);
  static const purple = Color(0xFF7C4FCC);
  static const orange = Color(0xFFE05520);
  static const orangeDim = Color(0x1AE05520);
  static const rank1 = Color(0xFFB8860B);
  static const rank2 = Color(0xFF607D8B);
  static const rank3 = Color(0xFFA0522D);
  // base is a soft blue-grey that reads against white cards; highlight sweeps brighter
  static const shimBase = Color(0xFFDDE3F0);
  static const shimHigh = Color(0xFFF4F7FF);
}

// ─────────────────────────────────────────────────────────────────────────────
// THEME CONTEXT HELPER
// ─────────────────────────────────────────────────────────────────────────────

class _TC {
  final bool _dark;
  _TC(BuildContext ctx) : _dark = Theme.of(ctx).brightness == Brightness.dark;

  Color get bg => _dark ? _TD.bg : _TL.bg;
  Color get surface => _dark ? _TD.surface : _TL.surface;
  Color get card => _dark ? _TD.card : _TL.card;
  Color get cardBorder => _dark ? _TD.cardBorder : _TL.cardBorder;
  Color get textPri => _dark ? _TD.textPri : _TL.textPri;
  Color get textSec => _dark ? _TD.textSec : _TL.textSec;
  Color get textMuted => _dark ? _TD.textMuted : _TL.textMuted;
  Color get gold => _dark ? _TD.gold : _TL.gold;
  Color get blue => _dark ? _TD.blue : _TL.blue;
  Color get purple => _dark ? _TD.purple : _TL.purple;
  Color get orange => _dark ? _TD.orange : _TL.orange;
  Color get orangeDim => _dark ? _TD.orangeDim : _TL.orangeDim;
  Color get rank1 => _dark ? _TD.rank1 : _TL.rank1;
  Color get rank2 => _dark ? _TD.rank2 : _TL.rank2;
  Color get rank3 => _dark ? _TD.rank3 : _TL.rank3;
  Color get shimBase => _dark ? _TD.shimBase : _TL.shimBase;
  Color get shimHigh => _dark ? _TD.shimHigh : _TL.shimHigh;
}

// ─────────────────────────────────────────────────────────────────────────────
// SHIMMER ENGINE
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// SHIMMER ENGINE — reads theme from context so it always stays in sync
// ─────────────────────────────────────────────────────────────────────────────

class _Shimmer extends StatefulWidget {
  final Widget child;
  const _Shimmer({required this.child});

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
    final t = _TC(context);
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) => LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            t.shimBase,
            t.shimBase,
            t.shimHigh,
            t.shimBase,
            t.shimBase,
          ],
          stops: [
            0.0,
            (_anim.value - 0.35).clamp(0.0, 1.0),
            _anim.value.clamp(0.0, 1.0),
            (_anim.value + 0.35).clamp(0.0, 1.0),
            1.0,
          ],
        ).createShader(bounds),
        child: child,
      ),
      child: widget.child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SKELETON ROW
// ─────────────────────────────────────────────────────────────────────────────

class _SkeletonRow extends StatelessWidget {
  final int index;
  const _SkeletonRow({required this.index});

  @override
  Widget build(BuildContext context) {
    final t = _TC(context);
    const nameWidths = [110.0, 90.0, 130.0, 100.0, 115.0, 95.0, 120.0];
    const badgeWidths = [80.0, 70.0, 95.0, 75.0, 88.0, 65.0, 82.0];
    final nameW = nameWidths[index % nameWidths.length];
    final badgeW = badgeWidths[index % badgeWidths.length];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.cardBorder),
      ),
      child: Row(
        children: [
          _Shimmer(
            child: Container(
              width: 28,
              height: 14,
              decoration: BoxDecoration(
                color: t.shimBase,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _Shimmer(
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: t.shimBase,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _Shimmer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: nameW,
                    height: 12,
                    decoration: BoxDecoration(
                      color: t.shimBase,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    width: badgeW,
                    height: 9,
                    decoration: BoxDecoration(
                      color: t.shimBase,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _Shimmer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 38,
                  height: 13,
                  decoration: BoxDecoration(
                    color: t.shimBase,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 18,
                  height: 8,
                  decoration: BoxDecoration(
                    color: t.shimBase,
                    borderRadius: BorderRadius.circular(4),
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

// ─────────────────────────────────────────────────────────────────────────────
// PODIUM SKELETON
// ─────────────────────────────────────────────────────────────────────────────

class _PodiumSkeleton extends StatelessWidget {
  const _PodiumSkeleton();

  @override
  Widget build(BuildContext context) {
    final t = _TC(context);
    const heights = [100.0, 130.0, 80.0];

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: t.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (i) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Shimmer(
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: t.shimBase,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _Shimmer(
                    child: Container(
                      width: 20,
                      height: 16,
                      decoration: BoxDecoration(
                        color: t.shimBase,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  _Shimmer(
                    child: Container(
                      width: 52,
                      height: 10,
                      decoration: BoxDecoration(
                        color: t.shimBase,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  _Shimmer(
                    child: Container(
                      width: 36,
                      height: 9,
                      decoration: BoxDecoration(
                        color: t.shimBase,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Podium bar — static structural chrome, no shimmer
                  Container(
                    height: heights[i],
                    decoration: BoxDecoration(
                      color: t.shimBase,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE
// ─────────────────────────────────────────────────────────────────────────────

class LeaderboardAchivementPage extends StatefulWidget {
  const LeaderboardAchivementPage({super.key});
  @override
  State<LeaderboardAchivementPage> createState() =>
      _LeaderboardAchivementPageState();
}

class _LeaderboardAchivementPageState extends State<LeaderboardAchivementPage> {
  List<LeaderboardEntry> _entries = [];
  bool _loading = true;
  String? _error;
  String? _myUid;

  @override
  void initState() {
    super.initState();
    _myUid = FirebaseAuth.instance.currentUser?.uid;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await fetchLeaderboard();
      if (mounted)
        setState(() {
          _entries = data;
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

  LeaderboardEntry? get _myEntry => _myUid == null
      ? null
      : _entries.where((e) => e.firebaseUid == _myUid).firstOrNull;

  @override
  Widget build(BuildContext context) {
    final t = _TC(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: t._dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: t.bg,
        body: SafeArea(
          child: Column(children: [
            _buildHeader(t),
            Expanded(
              child: _loading
                  ? _buildSkeleton()
                  : _error != null
                      ? _buildError(t)
                      : _entries.isEmpty
                          ? _buildEmpty(t)
                          : _buildBody(t),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildHeader(_TC t) => Container(
        decoration: BoxDecoration(
          color: t.surface,
          border: Border(bottom: BorderSide(color: t.cardBorder)),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: t.card,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: t.cardBorder),
                  ),
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                      size: 16, color: t.textSec),
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.emoji_events_rounded, size: 20, color: t.gold),
              const SizedBox(width: 8),
              Text(
                'Top Performers',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: t.textPri,
                  letterSpacing: -.3,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _load,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: t.card,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: t.cardBorder),
                  ),
                  child:
                      Icon(Icons.refresh_rounded, size: 16, color: t.textSec),
                ),
              ),
            ]),
          ),
        ),
      );

  Widget _buildSkeleton() => Column(
        children: [
          const _PodiumSkeleton(),
          const SizedBox(height: 4),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 100),
              itemCount: 8,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (_, i) => _SkeletonRow(index: i),
            ),
          ),
        ],
      );

  Widget _buildBody(_TC t) => CustomScrollView(slivers: [
        if (_entries.length >= 3)
          SliverToBoxAdapter(
              child: _Podium(entries: _entries.take(3).toList(), t: t)),
        if (_myEntry != null && _myEntry!.rank > 3)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 2),
              child:
                  _RankRow(entry: _myEntry!, isMe: true, animate: false, t: t),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 32),
          sliver: SliverList.separated(
            itemCount: _entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (_, i) {
              final e = _entries[i];
              return TweenAnimationBuilder<double>(
                key: ValueKey(e.firebaseUid),
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 200 + (i * 25).clamp(0, 600)),
                curve: Curves.easeOutCubic,
                builder: (_, v, child) => Opacity(
                  opacity: v,
                  child: Transform.translate(
                      offset: Offset(0, (1 - v) * 20), child: child),
                ),
                child: _RankRow(entry: e, isMe: e.firebaseUid == _myUid, t: t),
              );
            },
          ),
        ),
      ]);

  // ── Empty state ───────────────────────────────────────────────────────────

  Widget _buildEmpty(_TC t) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: t.gold.withOpacity(.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.emoji_events_outlined, size: 34, color: t.gold),
            ),
            const SizedBox(height: 18),
            Text(
              'No players yet',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800, color: t.textPri),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to unlock achievements\nand claim the top spot!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: t.textSec, height: 1.5),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _load,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: t.gold.withOpacity(.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: t.gold.withOpacity(.3)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.refresh_rounded, size: 14, color: t.gold),
                  const SizedBox(width: 6),
                  Text(
                    'Refresh',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: t.gold),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      );

  // ── Error state ───────────────────────────────────────────────────────────

  Widget _buildError(_TC t) {
    // Strip noisy Supabase/Dart prefixes for a friendlier message.
    final raw = _error ?? '';
    final friendly = raw.contains(':') ? raw.split(':').last.trim() : raw;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: t.orangeDim,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.cloud_off_rounded, size: 32, color: t.orange),
          ),
          const SizedBox(height: 18),
          Text(
            'Could not load leaderboard',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w800, color: t.textPri),
          ),
          const SizedBox(height: 8),
          if (friendly.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: t.orange.withOpacity(.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: t.orange.withOpacity(.2)),
              ),
              child: Text(
                friendly,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.5, color: t.orange, height: 1.5),
              ),
            ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded, size: 14),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: t.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              textStyle:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PODIUM WIDGET (rank 1-2-3)
// ─────────────────────────────────────────────────────────────────────────────

class _Podium extends StatelessWidget {
  final List<LeaderboardEntry> entries;
  final _TC t;
  const _Podium({required this.entries, required this.t});

  @override
  Widget build(BuildContext context) {
    final order = [entries[1], entries[0], entries[2]];
    final heights = [100.0, 130.0, 80.0];
    final colors = [t.rank2, t.rank1, t.rank3];

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [t.gold.withOpacity(.06), t.card, t.card],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: t.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          3,
          (i) => Expanded(
            child: _PodiumSlot(
              entry: order[i],
              color: colors[i],
              height: heights[i],
              realRank: order[i].rank,
              t: t,
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
  final double height;
  final int realRank;
  final _TC t;
  const _PodiumSlot({
    required this.entry,
    required this.color,
    required this.height,
    required this.realRank,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final medal = ['🥇', '🥈', '🥉'][realRank - 1];
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [color.withOpacity(.8), color.withOpacity(.4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: color.withOpacity(.6), width: 2),
          boxShadow: [BoxShadow(color: color.withOpacity(.25), blurRadius: 10)],
        ),
        child: entry.avatarUrl != null
            ? ClipOval(
                child: Image.network(
                  entry.avatarUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      _initials(entry.displayName, color),
                ),
              )
            : _initials(entry.displayName, color),
      ),
      const SizedBox(height: 5),
      Text(medal, style: const TextStyle(fontSize: 16)),
      const SizedBox(height: 3),
      Text(
        _shortName(entry.displayName),
        style: TextStyle(
            fontSize: 10.5, fontWeight: FontWeight.w700, color: color),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 2),
      Text(
        '${entry.totalXP} XP',
        style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: color.withOpacity(.75)),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 8),
      Container(
        height: height,
        // AFTER — uniform border color, borderRadius now works:
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(.22), color.withOpacity(.07)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border.all(color: color.withOpacity(.35), width: 1.5),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        ),
        child: Center(
          child: Text(
            '#$realRank',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: color.withOpacity(.4)),
          ),
        ),
      ),
    ]);
  }

  Widget _initials(String? name, Color c) {
    final init = (name?.trim().isNotEmpty == true)
        ? name!
            .trim()
            .split(' ')
            .map((w) => w.isEmpty ? '' : w[0].toUpperCase())
            .take(2)
            .join()
        : '?';
    return Center(
      child: Text(init,
          style:
              TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: c)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RANK ROW
// ─────────────────────────────────────────────────────────────────────────────

class _RankRow extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool isMe;
  final bool animate;
  final _TC t;
  const _RankRow({
    required this.entry,
    required this.isMe,
    required this.t,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    Color rankColor = t.textMuted;
    if (entry.rank == 1)
      rankColor = t.rank1;
    else if (entry.rank == 2)
      rankColor = t.rank2;
    else if (entry.rank == 3)
      rankColor = t.rank3;
    else if (entry.rank <= 10) rankColor = t.blue;

    return GestureDetector(
      onTap: () => HapticFeedback.selectionClick(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? t.blue.withOpacity(.08) : t.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isMe ? t.blue.withOpacity(.35) : t.cardBorder,
            width: isMe ? 1.2 : 1.0,
          ),
        ),
        child: Row(children: [
          SizedBox(
            width: 32,
            child: Text(
              '#${entry.rank}',
              style: TextStyle(
                fontSize: entry.rank <= 3 ? 14 : 12,
                fontWeight: FontWeight.w800,
                color: rankColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: isMe
                    ? [t.blue, t.purple]
                    : [
                        t.textMuted.withOpacity(.5),
                        t.textMuted.withOpacity(.2),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: isMe ? t.blue.withOpacity(.5) : t.cardBorder,
                width: 1.5,
              ),
            ),
            child: entry.avatarUrl != null
                ? ClipOval(
                    child: Image.network(
                      entry.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _initials(t),
                    ),
                  )
                : _initials(t),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.displayName ?? 'Trader #${entry.rank}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isMe ? t.blue : t.textPri,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(children: [
                  Icon(Icons.military_tech, size: 10, color: t.gold),
                  const SizedBox(width: 2),
                  Text(
                    '${entry.unlockedCount} achievements',
                    style: TextStyle(fontSize: 10, color: t.textMuted),
                  ),
                ]),
              ],
            ),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Row(children: [
              Icon(Icons.bolt, size: 10, color: t.gold),
              const SizedBox(width: 2),
              Text(
                '${entry.totalXP}',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w800, color: t.gold),
              ),
            ]),
            Text('XP', style: TextStyle(fontSize: 9, color: t.textMuted)),
          ]),
          if (isMe) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: t.blue.withOpacity(.18),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: t.blue.withOpacity(.35)),
              ),
              child: Text(
                'YOU',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  color: t.blue,
                  letterSpacing: .5,
                ),
              ),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _initials(_TC t) {
    final init = (entry.displayName?.trim().isNotEmpty == true)
        ? entry.displayName!
            .trim()
            .split(' ')
            .map((w) => w.isEmpty ? '' : w[0].toUpperCase())
            .take(2)
            .join()
        : '?';
    return Center(
      child: Text(init,
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// UTILS
// ─────────────────────────────────────────────────────────────────────────────

String _shortName(String? name) {
  if (name == null || name.trim().isEmpty) return 'Trader';
  final parts = name.trim().split(' ');
  if (parts.length == 1) return parts[0];
  return '${parts[0]} ${parts[1][0]}.';
}
