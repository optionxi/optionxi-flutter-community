import 'package:flutter/material.dart';
import 'package:optionxi/Main_Pages/act_leaderboard.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LeaderboardEntry {
  final String suid;
  final double balance;
  final String displayname;
  final String? imgurl;
  final int rank;

  LeaderboardEntry({
    required this.suid,
    required this.balance,
    required this.displayname,
    this.imgurl,
    required this.rank,
  });
}

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

      final List<LeaderboardEntry> entries = [];
      for (int i = 0; i < response.length; i++) {
        final data = response[i];
        entries.add(LeaderboardEntry(
          suid: data['suid'],
          balance: (data['balance'] as num).toDouble(),
          displayname: data['displayname'] ?? 'Unknown',
          imgurl: data['imgurl'],
          rank: i + 1,
        ));
      }

      if (mounted) {
        setState(() {
          leaderboardData = entries;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return EnhancedLeaderboardWidget(
      leaderboardData: leaderboardData,
      isLoading: isLoading,
      error: error,
      onViewAll: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => LeaderboardPage()));
      },
    );
  }
}

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
    if (isLoading) {
      return _buildLoadingState(context);
    }

    if (error != null) {
      return _buildEmptyState();
    }

    if (leaderboardData.length <= 2) {
      return _buildEmptyState();
    }

    final top3Entries = leaderboardData.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top Leaderboard',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              TextButton(
                onPressed: onViewAll,
                child: Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: onViewAll,
          child: Container(
            height: 280,
            child: _buildTop3Podium(context, top3Entries),
          ),
        ),
        const SizedBox(height: 16),
        // Ensure that we only build rows for the entries that exist in top3Entries
        // ...top3Entries.map((entry) => _buildLeaderboardRow(context, entry)),
        // const SizedBox(height: 16),
        Divider(),
      ],
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.surfaceVariant,
            Theme.of(context).colorScheme.secondaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container();
  }

  Widget _buildTop3Podium(
      BuildContext context, List<LeaderboardEntry> top3Entries) {
    final entries = List<LeaderboardEntry?>.filled(3, null);
    for (int i = 0; i < top3Entries.length && i < 3; i++) {
      entries[i] = top3Entries[i];
    }

    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          // Always use the dark theme's gradient for the podium background
          colors: [
            const Color(0xFF1A1A2E),
            const Color(0xFF16213E),
            const Color(0xFF0F3460),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            // Adjust shadow color to work well in both dark and potentially light contexts
            color: Colors.black.withOpacity(0.3), // Consistent shadow
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Subtle geometric background patterns
          Positioned.fill(
            child: CustomPaint(
              painter: _ModernBackgroundPainter(
                isDark:
                    isDark, // Still pass isDark to potentially adjust pattern color
                primaryColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          // Position 2 (Left)
          if (entries[1] != null)
            Positioned(
              left: 20,
              bottom: 30,
              child: _buildModernPodiumCard(context, entries[1]!, 2),
            ),
          // Position 3 (Right)
          if (entries[2] != null)
            Positioned(
              right: 20,
              bottom: 30,
              child: _buildModernPodiumCard(context, entries[2]!, 3),
            ),
          // Position 1 (Center)
          if (entries[0] != null)
            Positioned(
              bottom: 60,
              child: _buildModernPodiumCard(context, entries[0]!, 1),
            ),
        ],
      ),
    );
  }

  Widget _buildModernPodiumCard(
      BuildContext context, LeaderboardEntry entry, int position) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Modern vibrant colors that work in both themes
    Color primaryColor;
    IconData icon;
    double avatarSize;

    switch (position) {
      case 1:
        primaryColor = const Color(0xFFFFD700); // Gold
        icon = Icons.emoji_events_outlined;
        avatarSize = 90;
        break;
      case 2:
        primaryColor = const Color(0xFF00D4FF); // Cyan
        icon = Icons.military_tech_outlined;
        avatarSize = 75;
        break;
      case 3:
        primaryColor = const Color(0xFFFF6B6B); // Coral
        icon = Icons.stars_outlined;
        avatarSize = 65;
        break;
      default:
        primaryColor = Theme.of(context).colorScheme.primary;
        icon = Icons.emoji_events_outlined;
        avatarSize = 65;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Crown/Medal icon with glow effect
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                primaryColor.withOpacity(0.3),
                primaryColor.withOpacity(0.1),
                Colors.transparent,
              ],
              stops: const [0.0, 0.7, 1.0],
            ),
          ),
          child: Icon(
            icon,
            color: primaryColor,
            size: position == 1 ? 32 : 28,
          ),
        ),
        const SizedBox(height: 8),

        // Avatar with modern styling
        Container(
          width: avatarSize,
          height: avatarSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primaryColor.withOpacity(0.8),
                primaryColor.withOpacity(0.6),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(3.0),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // Avatar background color adapts to theme
                color: isDark ? Colors.grey[900] : Colors.white,
              ),
              child: ClipOval(
                child: entry.imgurl != null
                    ? Image.network(
                        entry.imgurl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildAvatarFallback(
                              entry.displayname, primaryColor, avatarSize);
                        },
                      )
                    : _buildAvatarFallback(
                        entry.displayname, primaryColor, avatarSize),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Name with modern typography
        SizedBox(
          width: 120,
          child: Text(
            entry.displayname,
            style: TextStyle(
              fontSize: position == 1 ? 16 : 14,
              fontWeight: FontWeight.w700,
              // Text color adapts to theme
              color: isDark ? Colors.white : Colors.white,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),

        // Position indicator
        Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: primaryColor.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Text(
            '#$position',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarFallback(String name, Color color, double avatarSize) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.8),
            color.withOpacity(0.6),
          ],
        ),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: avatarSize * 0.4,
          ),
        ),
      ),
    );
  }
}

class _ModernBackgroundPainter extends CustomPainter {
  final bool isDark;
  final Color primaryColor;

  _ModernBackgroundPainter({
    required this.isDark,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Subtle geometric shapes
    // Adjust opacity and color based on theme for better visibility
    paint.color =
        isDark ? primaryColor.withOpacity(0.05) : Colors.grey.withOpacity(0.08);

    // Top-right triangle
    final path1 = Path();
    path1.moveTo(size.width * 0.8, 0);
    path1.lineTo(size.width, 0);
    path1.lineTo(size.width, size.height * 0.3);
    path1.close();
    canvas.drawPath(path1, paint);

    // Bottom-left arc
    paint.color =
        isDark ? primaryColor.withOpacity(0.03) : Colors.grey.withOpacity(0.05);
    final path2 = Path();
    path2.moveTo(0, size.height * 0.7);
    path2.quadraticBezierTo(
        size.width * 0.3, size.height * 0.8, size.width * 0.4, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
