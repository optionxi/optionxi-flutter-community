import 'package:flutter/material.dart';
import 'package:optionxi/Main_Pages/Leaderboard/act_leaderboard.dart';
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

  @override
  void initState() {
    super.initState();
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

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: backgroundColor,
              child: Column(
                children: [
                  _buildProfileHeader(),
                  TabBar(
                    controller: _tabController,
                    labelColor: primaryColor,
                    unselectedLabelColor:
                        theme.textTheme.titleSmall?.color ?? Colors.grey[400]!,
                    indicatorColor: primaryColor,
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                    tabs: const [
                      Tab(text: 'Portfolio'),
                      Tab(text: 'Orders'),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  Container(
                    color: backgroundColor,
                    child: PortfolioFragmentPrev(widget.user),
                  ),
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 24, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Back button — flush, no wasted space
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),

          // Avatar
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: primaryColor, width: 2.5),
              image: DecorationImage(
                image: NetworkImage(widget.user.imageUrl.toString()),
                fit: BoxFit.cover,
              ),
            ),
          ),

          const SizedBox(width: 14),

          // Name + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.user.username.toString(),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Virtual trading dashboard",
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 13,
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
