// Modified _buildContent method in your LeaderboardPage

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:optionxi/Components/custom_leaderboard_loading.dart';
import 'package:optionxi/Helpers/conversions.dart';
import 'package:optionxi/Main_Pages/act_traderprofile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:optionxi/Theme/theme_controller.dart';

class LeaderboardPage extends StatefulWidget {
  @override
  _LeaderboardPageState createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final ThemeController themeController = Get.find<ThemeController>();
  final SupabaseClient supabase = Supabase.instance.client;

  List<LeaderboardEntry> leaderboardEntries = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
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

      // Start animation after data is loaded
      _controller.forward();
    } catch (e) {
      setState(() {
        error = 'Failed to load leaderboard: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    await _loadLeaderboardData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // Header is always shown - no loading state here
                _buildHeader(context),
                // Only the content area shows loading
                _buildContent(context),
                PrivacyModeNotice()
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final fontSize = isTablet ? 32.0 : 28.0;
    final descriptionSize = isTablet ? 18.0 : 16.0;
    final padding = isTablet ? 24.0 : 20.0;

    return Container(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Theme.of(context).dividerColor, width: 1),
                  ),
                  child: Icon(Icons.navigate_before,
                      color: Theme.of(context).textTheme.titleSmall?.color),
                ),
              ),
              SizedBox(width: 20),
              Text(
                "Leaderboard",
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            "Where each traders are ranked according to their performance in virtual trading, this does not represent real trades.",
            style: TextStyle(
              color: Theme.of(context).textTheme.titleSmall?.color,
              fontSize: descriptionSize,
            ),
          ),
        ],
      ),
    );
  }

  // MODIFIED: This is where the loading component is used
  Widget _buildContent(BuildContext context) {
    if (isLoading) {
      // REPLACE THIS SECTION: Instead of the old loading UI, use the new custom loading
      return LeaderboardLoadingList(
        itemCount: 10, // Show 10 skeleton items
      );

      // ALTERNATIVE: For a more minimal approach, use:
      // return MinimalCenterLoader();
    }

    if (error != null) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              SizedBox(height: 16),
              Text(
                error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _refreshData,
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (leaderboardEntries.isEmpty) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withOpacity(0.3),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.emoji_events_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No rankings yet',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Be the first to make it to the leaderboard!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return _buildLeaderboardList(context);
  }

  Widget _buildLeaderboardList(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final padding = isTablet ? 16.0 : 8.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: Column(
        children: [
          ...leaderboardEntries.asMap().entries.map((entry) {
            final index = entry.key;
            final leaderboardEntry = entry.value;
            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          TraderProfilePage(leaderboardEntry)),
                );
              },
              child: ModernLeaderboardCard(
                entry: leaderboardEntry,
                index: index,
                controller: _controller,
              ),
            );
          }).toList(),
          SizedBox(height: 20), // Bottom padding
        ],
      ),
    );
  }
}

// Rest of your code remains the same...
class ModernLeaderboardCard extends StatelessWidget {
  final LeaderboardEntry entry;
  final int index;
  final AnimationController controller;

  const ModernLeaderboardCard({
    Key? key,
    required this.entry,
    required this.index,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Fix the animation interval calculation to prevent values > 1.0
    // final maxItems = 30; // Maximum expected items
    final delayIncrement = 0.05; // Smaller increment to fit more items
    final maxDelay = 0.8; // Maximum delay to ensure we don't exceed 1.0
    final animationDuration = 0.2; // Duration for each item's animation

    final startTime = math.min(index * delayIncrement, maxDelay);
    final endTime = math.min(startTime + animationDuration, 1.0);

    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(
          startTime,
          endTime,
          curve: Curves.easeOut,
        ),
      ),
    );

    final isTablet = MediaQuery.of(context).size.width > 600;
    final cardPadding = isTablet ? 16.0 : 12.0;
    final fontSize = isTablet ? 18.0 : 16.0;
    final rankSize = isTablet ? 32.0 : 28.0;
    final avatarSize = isTablet ? 60.0 : 50.0;
    final iconSize = isTablet ? 36.0 : 32.0;

    Color getRankColor() {
      switch (entry.rank) {
        case 1:
          return Colors.amber;
        case 2:
          return Colors.grey.shade400;
        case 3:
          return Colors.brown.shade300;
        default:
          return Theme.of(context)
              .colorScheme
              .primary
              .withAlpha(179); // 0.7 alpha
      }
    }

    Widget getRankIcon() {
      switch (entry.rank) {
        case 1:
          return Icon(
            Icons.emoji_events, // Crown/Trophy icon
            size: iconSize,
            color: Colors.amber,
          );
        case 2:
          return Icon(
            Icons.military_tech, // Medal icon
            size: iconSize,
            color: Colors.grey.shade400,
          );
        case 3:
          return Icon(
            Icons.workspace_premium, // Premium badge icon
            size: iconSize,
            color: Colors.brown.shade300,
          );
        default:
          return Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: getRankColor().withAlpha(51), // 0.2 alpha
            ),
            child: Center(
              child: Text(
                "${entry.rank}",
                style: TextStyle(
                  fontSize: rankSize,
                  fontWeight: FontWeight.bold,
                  color: getRankColor(),
                ),
              ),
            ),
          );
      }
    }

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.5),
          end: Offset.zero,
        ).animate(animation),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Card(
            elevation: entry.rank <= 3 ? 8 : 4, // Higher elevation for top 3
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: entry.rank <= 3
                  ? BorderSide(
                      color: getRankColor().withAlpha(77), // 0.3 alpha
                      width: 2,
                    )
                  : BorderSide.none,
            ),
            child: Container(
              decoration: entry.rank <= 3
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          getRankColor().withAlpha(13), // 0.05 alpha
                          Colors.transparent,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    )
                  : null,
              child: Padding(
                padding: EdgeInsets.all(cardPadding),
                child: Row(
                  children: [
                    // Rank Number
                    SizedBox(width: 4),
                    Text(
                      "${entry.rank}",
                      style: TextStyle(
                        fontSize: rankSize,
                        fontWeight: FontWeight.bold,
                        color: getRankColor(),
                      ),
                    ),
                    SizedBox(width: 12),
                    // Crown Icon (only for top 3)
                    if (entry.rank <= 3) ...[
                      getRankIcon(),
                      SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.username,
                            style: TextStyle(
                              fontSize: fontSize,
                              fontWeight: entry.rank <= 3
                                  ? FontWeight.w800
                                  : FontWeight.bold,
                              color:
                                  Theme.of(context).textTheme.titleLarge?.color,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Text(
                            "₹${convertToKMB(entry.points.toStringAsFixed(0))}",
                            style: TextStyle(
                              fontSize: fontSize,
                              fontWeight: FontWeight.bold,
                              color: entry.rank <= 3
                                  ? getRankColor()
                                  : Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Avatar Image on the right
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          width: avatarSize,
                          height: avatarSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: getRankColor().withAlpha(51), // 0.2 alpha
                            border: entry.rank <= 3
                                ? Border.all(
                                    color: getRankColor(),
                                    width: 2,
                                  )
                                : null,
                          ),
                          child: ClipOval(
                            child: Image.network(
                              entry.imageUrl,
                              width: avatarSize,
                              height: avatarSize,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Text(
                                    "${entry.rank}",
                                    style: TextStyle(
                                      fontSize: rankSize,
                                      fontWeight: FontWeight.bold,
                                      color: getRankColor(),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
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

class LeaderboardEntry {
  final int rank;
  final String username;
  final double points;
  final String level;
  final String imageUrl;
  final String suid;

  LeaderboardEntry({
    required this.rank,
    required this.username,
    required this.points,
    required this.level,
    required this.imageUrl,
    required this.suid,
  });
}

class PrivacyModeNotice extends StatelessWidget {
  const PrivacyModeNotice({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade50,
            Colors.indigo.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.shade100,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.privacy_tip_outlined,
              color: Colors.blue.shade700,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Privacy Mode',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade800,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Turn on privacy mode in your profle, and your name and image will not be shown in leaderboard',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    height: 1.4,
                    letterSpacing: 0.2,
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
