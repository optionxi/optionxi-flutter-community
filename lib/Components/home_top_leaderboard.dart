import 'package:flutter/material.dart';
import 'package:optionxi/Main_Pages/act_leaderboard.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ---------------------------------------------------------------------------
// DATA MODEL
// ---------------------------------------------------------------------------

class LeaderboardEntry {
  final String suid;
  final double balance;
  final String displayname;
  final String? imgurl;
  final int rank;

  const LeaderboardEntry({
    required this.suid,
    required this.balance,
    required this.displayname,
    this.imgurl,
    required this.rank,
  });
}

// ---------------------------------------------------------------------------
// STATEFUL WRAPPER (Supabase data-fetching logic unchanged)
// ---------------------------------------------------------------------------

class LeaderboardWidgetMain extends StatefulWidget {
  const LeaderboardWidgetMain({Key? key}) : super(key: key);

  @override
  State<LeaderboardWidgetMain> createState() => _LeaderboardWidgetMainState();
}

class _LeaderboardWidgetMainState extends State<LeaderboardWidgetMain> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<LeaderboardEntry> leaderboardData = [];
  bool isLoading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadLeaderboardData();
  }

  Future<void> _loadLeaderboardData() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final response = await _supabase
          .from('prev_balance')
          .select('suid, balance, displayname, imgurl')
          .order('balance', ascending: false)
          .limit(3);

      final entries = <LeaderboardEntry>[];
      for (int i = 0; i < response.length; i++) {
        final d = response[i];
        entries.add(LeaderboardEntry(
          suid: d['suid'] as String,
          balance: (d['balance'] as num).toDouble(),
          displayname: d['displayname'] ?? 'Unknown',
          imgurl: d['imgurl'] as String?,
          rank: i + 1,
        ));
      }

      if (mounted)
        setState(() {
          leaderboardData = entries;
          isLoading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          error = e.toString();
          isLoading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return EnhancedLeaderboardWidget(
      leaderboardData: leaderboardData,
      isLoading: isLoading,
      error: error,
      onViewAll: () {
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => LeaderboardPage()));
      },
    );
  }
}

// ---------------------------------------------------------------------------
// DESIGN TOKENS
// ---------------------------------------------------------------------------

class _LBColors {
  // Rank accent palette
  static const gold = Color(0xFFF5C842);
  static const silver = Color(0xFF9EC4E8);
  static const bronze = Color(0xFFE8956A);

  // Dark-mode surface
  static const darkBg = Color(0xFF0D1117);
  static const darkSurface = Color(0xFF161B22);
  static const darkBorder = Color(0xFF2D3748);

  // Light-mode surface
  static const lightBg = Color(0xFFF6F8FB);
  static const lightCard = Color(0xFFF0F4FA);
  static const lightBorder = Color(0xFFDDE3EE);

  static Color rankColor(int rank) {
    switch (rank) {
      case 1:
        return gold;
      case 2:
        return silver;
      case 3:
        return bronze;
      default:
        return const Color(0xFF8899AA);
    }
  }
}

// ---------------------------------------------------------------------------
// MAIN WIDGET
// ---------------------------------------------------------------------------

class EnhancedLeaderboardWidget extends StatelessWidget {
  final List<LeaderboardEntry> leaderboardData;
  final bool isLoading;
  final String? error;
  final VoidCallback? onViewAll;

  const EnhancedLeaderboardWidget({
    Key? key,
    required this.leaderboardData,
    required this.isLoading,
    this.error,
    this.onViewAll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) return _LoadingState();
    if (error != null || leaderboardData.length < 3)
      return const SizedBox.shrink();

    final top3 = leaderboardData.take(3).toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        _Header(onViewAll: onViewAll),
        const SizedBox(height: 12),
        _PodiumSection(entries: top3, onTap: onViewAll, isDark: isDark),
        const SizedBox(height: 20),
        _Divider(isDark: isDark),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// HEADER
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  final VoidCallback? onViewAll;
  const _Header({this.onViewAll});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final accentColor = isDark ? _LBColors.gold : const Color(0xFF1D6FAB);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.leaderboard_rounded, color: accentColor, size: 22),
              const SizedBox(width: 8),
              Text(
                'Top Leaderboard',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: onViewAll,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: accentColor.withOpacity(0.3)),
              ),
              child: Text(
                'View All',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PODIUM SECTION
// ---------------------------------------------------------------------------

class _PodiumSection extends StatelessWidget {
  final List<LeaderboardEntry> entries;
  final VoidCallback? onTap;
  final bool isDark;

  const _PodiumSection({
    required this.entries,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Display order: 2nd | 1st | 3rd
    final order = [entries[1], entries[0], entries[2]];
    // Heights for podium steps (2nd, 1st, 3rd)
    final podiumHeights = [70.0, 100.0, 55.0];
    // Avatar sizes
    final avatarSizes = [64.0, 82.0, 56.0];
    // Top extra space to lift 1st place avatar higher
    final topPad = [20.0, 0.0, 28.0];

    final bgGradient = isDark
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D1117), Color(0xFF161B22), Color(0xFF1A2236)],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEEF2FA), Color(0xFFE4ECFB), Color(0xFFDDE8F8)],
          );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 290,
        decoration: BoxDecoration(
          gradient: bgGradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? _LBColors.darkBorder : _LBColors.lightBorder,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.4)
                  : Colors.black.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Subtle mesh background
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: CustomPaint(painter: _MeshPainter(isDark: isDark)),
              ),
            ),

            // Podium columns + avatar cards
            Align(
              alignment: Alignment.bottomCenter,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(3, (i) {
                  final entry = order[i];
                  final rank = entry.rank;
                  final color = _LBColors.rankColor(rank);

                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        i == 0 ? 12 : 6,
                        topPad[i],
                        i == 2 ? 12 : 6,
                        0,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Avatar
                          _AvatarCard(
                            entry: entry,
                            size: avatarSizes[i],
                            color: color,
                            isDark: isDark,
                            rank: rank,
                          ),
                          const SizedBox(height: 8),
                          // Name
                          Text(
                            entry.displayname,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: rank == 1 ? 14 : 12,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF111827),
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Balance chip
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _formatBalance(entry.balance),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Podium step
                          _PodiumStep(
                            height: podiumHeights[i],
                            color: color,
                            rank: rank,
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatBalance(double v) {
    if (v >= 100000) return '₹${(v / 1000).toStringAsFixed(0)}K';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}K';
    return '₹${v.toStringAsFixed(0)}';
  }
}

// ---------------------------------------------------------------------------
// AVATAR CARD
// ---------------------------------------------------------------------------

class _AvatarCard extends StatelessWidget {
  final LeaderboardEntry entry;
  final double size;
  final Color color;
  final bool isDark;
  final int rank;

  const _AvatarCard({
    required this.entry,
    required this.size,
    required this.color,
    required this.isDark,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Glow ring
        Container(
          width: size + 10,
          height: size + 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.35),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
        // Border ring
        Container(
          width: size + 6,
          height: size + 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              colors: [color, color.withOpacity(0.3), color],
            ),
          ),
        ),
        // Avatar
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? const Color(0xFF1C2330) : Colors.white,
          ),
          child: ClipOval(
            child: entry.imgurl != null
                ? Image.network(
                    entry.imgurl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _Initials(
                      name: entry.displayname,
                      color: color,
                      size: size,
                    ),
                  )
                : _Initials(name: entry.displayname, color: color, size: size),
          ),
        ),
        // Rank badge
        Positioned(
          top: -4,
          right: -4,
          child: _RankBadge(rank: rank, color: color),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// RANK BADGE
// ---------------------------------------------------------------------------

class _RankBadge extends StatelessWidget {
  final int rank;
  final Color color;
  const _RankBadge({required this.rank, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.5), blurRadius: 6),
        ],
      ),
      child: Center(
        child: Text(
          '${rank}',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PODIUM STEP
// ---------------------------------------------------------------------------

class _PodiumStep extends StatelessWidget {
  final double height;
  final Color color;
  final int rank;
  final bool isDark;

  const _PodiumStep({
    required this.height,
    required this.color,
    required this.rank,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withOpacity(0.85),
            color.withOpacity(0.55),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '#$rank',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// INITIALS AVATAR FALLBACK
// ---------------------------------------------------------------------------

class _Initials extends StatelessWidget {
  final String name;
  final Color color;
  final double size;

  const _Initials(
      {required this.name, required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    final letter = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      color: color.withOpacity(0.18),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: size * 0.38,
            letterSpacing: -1,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// LOADING STATE
// ---------------------------------------------------------------------------

class _LoadingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 290,
      decoration: BoxDecoration(
        color: isDark ? _LBColors.darkSurface : _LBColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? _LBColors.darkBorder : _LBColors.lightBorder,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation(
                isDark ? _LBColors.gold : const Color(0xFF1D6FAB),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Loading leaderboard…',
            style: TextStyle(
              fontSize: 13,
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.4),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// DIVIDER
// ---------------------------------------------------------------------------

class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Divider(
      color: isDark ? _LBColors.darkBorder : _LBColors.lightBorder,
      thickness: 1,
    );
  }
}

// ---------------------------------------------------------------------------
// MESH BACKGROUND PAINTER
// ---------------------------------------------------------------------------

class _MeshPainter extends CustomPainter {
  final bool isDark;
  const _MeshPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.stroke;
    final color = isDark ? Colors.white : Colors.black;

    // Subtle circular arcs
    paint
      ..color = color.withOpacity(0.03)
      ..strokeWidth = 1;

    for (double r = 40; r < 300; r += 55) {
      canvas.drawCircle(
          Offset(size.width * 0.85, size.height * 0.15), r, paint);
    }

    // Faint diagonal lines
    paint
      ..color = color.withOpacity(0.025)
      ..strokeWidth = 0.8;

    for (double x = -100; x < size.width + 100; x += 36) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height * 0.5, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MeshPainter old) => old.isDark != isDark;
}

// ---------------------------------------------------------------------------
// DEMO APP (remove in production)
// ---------------------------------------------------------------------------

void main() => runApp(const _DemoApp());

class _DemoApp extends StatefulWidget {
  const _DemoApp();
  @override
  State<_DemoApp> createState() => _DemoAppState();
}

class _DemoAppState extends State<_DemoApp> {
  bool _dark = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: _dark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        colorSchemeSeed: const Color(0xFF1D6FAB),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFFF5C842),
        useMaterial3: true,
      ),
      home: Scaffold(
        backgroundColor: _dark ? _LBColors.darkBg : _LBColors.lightBg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'OptionXi',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: _dark ? Colors.white : Colors.black,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                _dark ? Icons.wb_sunny_outlined : Icons.dark_mode_outlined,
                color: _dark ? _LBColors.gold : const Color(0xFF1D6FAB),
              ),
              onPressed: () => setState(() => _dark = !_dark),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: LeaderboardWidgetMain(),
        ),
      ),
    );
  }
}
