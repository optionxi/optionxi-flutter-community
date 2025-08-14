import 'package:flutter/material.dart';
import 'package:optionxi/Main_Pages/act_leaderboard.dart';
import 'package:optionxi/VirtualTrading/MainFrags/vt_frag_orders.dart';
import 'package:optionxi/VirtualTrading/MainFrags/vt_frag_portfolio.dart';

class TraderProfilePage extends StatefulWidget {
  final LeaderboardEntry user;
  const TraderProfilePage(this.user, {Key? key}) : super(key: key);

  @override
  State<TraderProfilePage> createState() => _TraderProfilePageState();
}

class _TraderProfilePageState extends State<TraderProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isFollowing = false;

  @override
  void initState() {
    super.initState();
    // Fixed: Changed from 4 to 2 to match the actual number of tabs
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final textColor = theme.colorScheme.onBackground;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Fixed header section
            Container(
              color: backgroundColor,
              child: Column(
                children: [
                  // App bar section
                  Container(
                    height: 50,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Image.network(
                        //   'https://images-wixmp-ed30a86b8c4ca887773594c2.wixmp.com/f/733b5da9-efe6-4697-a4f9-9e9d4975f828/de8g75a-a128f1ac-ec63-4485-b913-3b0f00fb9b63.jpg?token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1cm46YXBwOjdlMGQxODg5ODIyNjQzNzNhNWYwZDQxNWVhMGQyNmUwIiwiaXNzIjoidXJuOmFwcDo3ZTBkMTg4OTgyMjY0MzczYTVmMGQ0MTVlYTBkMjZlMCIsIm9iaiI6W1t7InBhdGgiOiJcL2ZcLzczM2I1ZGE5LWVmZTYtNDY5Ny1hNGY5LTllOWQ0OTc1ZjgyOFwvZGU4Zzc1YS1hMTI4ZjFhYy1lYzYzLTQ0ODUtYjkxMy0zYjBmMDBmYjliNjMuanBnIn1dXSwiYXVkIjpbInVybjpzZXJ2aWNlOmZpbGUuZG93bmxvYWQiXX0.fPT4Y-EkXONFPgkECDHazkxjlCs1ipyyO1XE_K7aRCM',
                        //   fit: BoxFit.cover,
                        // ),
                        // Container(
                        //   decoration: BoxDecoration(
                        //     gradient: LinearGradient(
                        //       begin: Alignment.topCenter,
                        //       end: Alignment.bottomCenter,
                        //       colors: [
                        //         Colors.transparent,
                        //         backgroundColor.withValues(alpha: 0.9),
                        //       ],
                        //     ),
                        //   ),
                        // ),
                        // Back button
                        Positioned(
                          top: 8,
                          left: 8,
                          child: SafeArea(
                            child: IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: Icon(
                                Icons.arrow_back_ios_new,
                                color: textColor,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Profile header
                  _buildProfileHeader(),
                  // Tab bar
                  Container(
                    color: backgroundColor,
                    child: TabBar(
                      controller: _tabController,
                      labelColor: primaryColor,
                      unselectedLabelColor: theme.textTheme.titleSmall?.color ??
                          Colors.grey[400]!,
                      indicatorColor: primaryColor,
                      indicatorWeight: 3,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                      tabs: const [
                        Tab(text: 'Portfolio'),
                        Tab(text: 'Orders'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Tab content - takes remaining space
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Portfolio tab - wrap to prevent conflicts
                  Container(
                    color: backgroundColor,
                    child: PortfolioFragmentPrev(widget.user),
                  ),
                  // Orders tab - wrap to prevent conflicts
                  Container(
                    color: backgroundColor,
                    child: OrdersPage(widget.user),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final textColor = theme.colorScheme.onBackground;
    final subtitleColor = theme.textTheme.titleSmall?.color;

    return Container(
      padding: const EdgeInsets.all(24),
      color: theme.scaffoldBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: primaryColor, width: 3),
                  image: DecorationImage(
                    image: NetworkImage(widget.user.imageUrl.toString()),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.user.username.toString(),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      // widget.user.rank.toString() + " in leaderboard",
                      "Virtual trading dashboard",
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              // _buildFollowButton(),
            ],
          ),
        ],
      ),
    );
  }

  // Widget _buildFollowButton() {
  //   final theme = Theme.of(context);
  //   final primaryColor = theme.colorScheme.primary;

  //   return AnimatedContainer(
  //     duration: const Duration(milliseconds: 300),
  //     child: ElevatedButton(
  //       onPressed: () {
  //         setState(() {
  //           isFollowing = !isFollowing;
  //         });
  //       },
  //       style: ElevatedButton.styleFrom(
  //         backgroundColor:
  //             isFollowing ? theme.colorScheme.surface : primaryColor,
  //         foregroundColor: isFollowing
  //             ? theme.colorScheme.onSurface
  //             : theme.colorScheme.onPrimary,
  //         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(12),
  //         ),
  //         elevation: 0,
  //       ),
  //       child: Text(
  //         isFollowing ? 'Following' : 'Follow',
  //         style: const TextStyle(fontWeight: FontWeight.bold),
  //       ),
  //     ),
  //   );
  // }
}
