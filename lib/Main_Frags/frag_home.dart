import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:optionxi/Components/cust_contact_us.dart';
import 'package:optionxi/Components/cust_notice_section.dart';
import 'package:optionxi/Components/cust_top_tutors.dart';
import 'package:optionxi/Components/custom_searchbar.dart';
import 'package:optionxi/Components/home_top_leaderboard.dart';
// import 'package:optionxi/Components/trade_community_section.dart';
import 'package:optionxi/Components/trending_stocks_section.dart';
import 'package:optionxi/Helpers/badge_service.dart';
import 'package:optionxi/Main_Pages/act_search_stocks.dart';
import 'package:optionxi/Theme/theme_controller.dart';

class TradingHomeScreen extends StatefulWidget {
  @override
  _TradingHomeScreenState createState() => _TradingHomeScreenState();
}

class _TradingHomeScreenState extends State<TradingHomeScreen>
    with TickerProviderStateMixin {
  final String username =
      FirebaseAuth.instance.currentUser?.displayName ?? "OptionXi";

  late AnimationController _controller;
  final ThemeController themeController = Get.put(ThemeController());

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..forward();
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
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeTransition(
                      opacity: Tween<double>(begin: 0, end: 1).animate(
                        CurvedAnimation(
                          parent: _controller,
                          curve: Interval(0.0, 0.2, curve: Curves.easeOut),
                        ),
                      ),
                      child: _buildHeader(),
                    ),
                    const SizedBox(height: 24),
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: Offset(0, 0.2),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: _controller,
                          curve: Interval(0.1, 0.3, curve: Curves.easeOut),
                        ),
                      ),
                      child: FadeTransition(
                        opacity: Tween<double>(begin: 0, end: 1).animate(
                          CurvedAnimation(
                            parent: _controller,
                            curve: Interval(0.1, 0.3, curve: Curves.easeOut),
                          ),
                        ),
                        child: _buildTitle(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: Offset(0, 0.2),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: _controller,
                          curve: Interval(0.2, 0.4, curve: Curves.easeOut),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        StockSearchPage(false)),
                              );
                            },
                            child: AbsorbPointer(
                              child: ModernSearchBar(),
                            ),
                          ),
                        ],
                      ),
                    ),

                    NoticesSection(),
                    // SlideTransition(
                    //   position: Tween<Offset>(
                    //     begin: Offset(0, 0.2),
                    //     end: Offset.zero,
                    //   ).animate(
                    //     CurvedAnimation(
                    //       parent: _controller,
                    //       curve: Interval(0.3, 0.5, curve: Curves.easeOut),
                    //     ),
                    //   ),
                    //   child: buildTradingIdeas(context, _controller),
                    // ),
                    // const SizedBox(height: 24),
                    // Divider(),
                    TrendingStocksSection(),
                    const SizedBox(height: 24),
                    Divider(),
                    TopTradingTutorsScreen(),
                    // const SizedBox(height: 24),
                    Divider(),
                    LeaderboardWidgetMain(),
                    const SizedBox(height: 24),
                    _buildCtaSection(),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: CircleAvatar(
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  backgroundImage:
                      const AssetImage('assets/images/option_xi_w.png')
                          as ImageProvider,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "OptionXi",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Row(
            children: [
              // _buildIconButton(Icons.notifications_outlined,
              //     onPressed: gotoNofitication),
              _buildNotificationIcon(Icons.notifications_outlined,
                  onPressed: gotoNofitication),
              const SizedBox(width: 8),
              Obx(() => _buildIconButton(
                    themeController.isDarkMode
                        ? Icons.light_mode
                        : Icons.dark_mode,
                    onPressed: () => themeController.toggleTheme(),
                  )),
              const SizedBox(width: 8),
              InkWell(
                onTap: () async {
                  // await BadgeService.incrementNotificationsBadge();
                },
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  padding: EdgeInsets.all(2),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    backgroundImage:
                        FirebaseAuth.instance.currentUser?.photoURL != null
                            ? NetworkImage(
                                FirebaseAuth.instance.currentUser!.photoURL!)
                            : const AssetImage('assets/images/option_xi_w.png')
                                as ImageProvider,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, {VoidCallback? onPressed}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        color: Theme.of(context).iconTheme.color,
      ),
    );
  }

  Widget _buildNotificationIcon(IconData icon, {VoidCallback? onPressed}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: onPressed ??
              () {
                // GlobalSnackBarGet().showGetSucess(
                //     "Comming Soon", "Please wait while our team iworks on it");
              },
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                icon,
                color: Theme.of(context).iconTheme.color,
              ),
              onPressed: null, // Disabled since GestureDetector handles the tap
            ),
          ),
        ),
        Positioned(
          right: -4,
          top: -4,
          child: StreamBuilder<int>(
            stream: BadgeService
                .notificationsStreamWithInitial, // Use the enhanced stream
            builder: (context, snapshot) {
              // Show loading state while waiting for initial data
              if (!snapshot.hasData) {
                return const SizedBox.shrink();
              }

              final count = snapshot.data!;
              if (count == 0) return const SizedBox.shrink();

              return Container(
                // Add minimum width and height to ensure circular shape
                constraints: const BoxConstraints(
                  minWidth: 20,
                  minHeight: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle, // This makes it a perfect circle
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text(
                      count.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        )
      ],
    );
  }

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Hey, $username 👋",
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Text(
          "Simple, Fast Trading\nOpen Source",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 28,
                height: 1.2,
              ),
        ),
      ],
    );
  }

  void gotoNofitication() async {
    await BadgeService.clearNotificationsBadge();
    await Navigator.pushNamed(
      context,
      '/messages',
      arguments: {},
    );
    setState(() {});
  }

  Widget _buildCtaSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Ready to Deploy Your Algorithm?",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Get started with our professional trading infrastructure and deploy your strategies at scale.",
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              // Main CTA Button
              Expanded(
                child: ElevatedButton(
                  onPressed: () => showContactOptions(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.rocket_launch, size: 20),
                      SizedBox(width: 8),
                      Text(
                        "Get Started Now",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Contact Options Button
              ElevatedButton(
                onPressed: () => showContactOptions(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Icon(Icons.chat_bubble_outline, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
