import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:optionxi/Components/broker_list_section.dart';
import 'package:optionxi/Components/cust_ai_chooser_component.dart';
import 'package:optionxi/Components/cust_contact_us.dart';
import 'package:optionxi/Components/cust_market_glance.dart';
import 'package:optionxi/Components/cust_market_trend_section.dart';
import 'package:optionxi/Components/cust_tools_chips.dart';
import 'package:optionxi/Components/cust_top_tutors.dart';
import 'package:optionxi/Components/custom_searchbar.dart';
import 'package:optionxi/Components/floating_ai.dart';
import 'package:optionxi/Components/home_top_leaderboard.dart';
import 'package:optionxi/Components/trending_stocks_section.dart';
import 'package:optionxi/Helpers/badge_service.dart';
import 'package:optionxi/Main_Pages/AlgoPage/algo_deployment_page.dart';
import 'package:optionxi/Main_Pages/act_ai_optionxi.dart';
import 'package:optionxi/Main_Pages/act_search_stocks_meili.dart';
import 'package:optionxi/Main_Pages/act_sectorwise_page.dart';
import 'package:optionxi/Main_Pages/act_stock_ai_summary.dart';
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
      floatingActionButton: MagicalAIButton(
        isDark: themeController.isDarkMode,
        onPressed: () {
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(
          //     builder: (context) => ChatScreen(),
          //   ),
          // );
          showAIActionSheet(
            context,
            onChat: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(),
                )),
            onAnalyse: (symbol) => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StockAiAnalysisPage(symbol: symbol),
                )),
          );
        },
      ),
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
                    const SizedBox(height: 8),
                    IndicesGlance(),
                    // const SizedBox(height: 24),
                    // SlideTransition(
                    //   position: Tween<Offset>(
                    //     begin: Offset(0, 0.2),
                    //     end: Offset.zero,
                    //   ).animate(
                    //     CurvedAnimation(
                    //       parent: _controller,
                    //       curve: Interval(0.1, 0.3, curve: Curves.easeOut),
                    //     ),
                    //   ),
                    //   child: FadeTransition(
                    //     opacity: Tween<double>(begin: 0, end: 1).animate(
                    //       CurvedAnimation(
                    //         parent: _controller,
                    //         curve: Interval(0.1, 0.3, curve: Curves.easeOut),
                    //       ),
                    //     ),
                    //     child: _buildTitle(),
                    //   ),
                    // ),
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
                                    builder: (context) => AllSearchPageMeili()),
                              );
                            },
                            child: AbsorbPointer(
                              child: ModernSearchBar(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 16,
                    ),
                    StockChipsSection(),
                    SizedBox(
                      height: 8,
                    ),

                    // NoticesSection(),
                    SizedBox(
                      height: 24,
                    ),
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: Offset(0, 0.2),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: _controller,
                          curve: Interval(0.3, 0.5, curve: Curves.easeOut),
                        ),
                      ),
                      // child: buildTradingIdeas(context, _controller),
                      child: buildBrokerHub(context, _controller),
                    ),
                    SizedBox(
                      height: 24,
                    ),
                    TrendingStocksSection(),
                    SizedBox(
                      height: 8,
                    ),
                    // const SizedBox(height: 8),
                    MarketTrendsSection(
                      onViewAll: gotoSectorWise,
                    ),
                    const SizedBox(height: 8),
                    Divider(),
                    TopTradingTutorsScreen(),
                    // const SizedBox(height: 24),
                    // Divider(),
                    LeaderboardWidgetMain(),
                    const SizedBox(height: 24),
                    _buildCtaSection(),
                    const SizedBox(height: 12),
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
              Container(
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

  void gotoNofitication() async {
    await BadgeService.clearNotificationsBadge();
    await Navigator.pushNamed(
      context,
      '/messages',
      arguments: {},
    );
    if (mounted) {
      setState(() {});
    }
  }

  Widget _buildCtaSection() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.07),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.35)
                : colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 32,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Background
            Positioned.fill(
              child: Container(
                color:
                    isDark ? const Color(0xFF141418) : const Color(0xFFFAFAFC),
              ),
            ),

            // Subtle top-right glow accent
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      colorScheme.primary
                          .withValues(alpha: isDark ? 0.18 : 0.10),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: status chip + icon
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              "Infrastructure Ready",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.primary,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.primary,
                              colorScheme.secondary,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  colorScheme.primary.withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.rocket_launch_rounded,
                          color: Colors.white,
                          size: 17,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Title
                  Text(
                    "Deploy Your Algorithm",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0D0D12),
                      letterSpacing: -0.4,
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Subtitle
                  Text(
                    "Professional trading infrastructure built for scale. Connect, configure, and go live in minutes.",
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.45)
                          : const Color(0xFF6B6B7B),
                      height: 1.5,
                      letterSpacing: 0.1,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Divider
                  Container(
                    height: 1,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.06),
                  ),

                  const SizedBox(height: 16),

                  // Bottom row: CTA on LEFT, stats after it, right side free for FAB
                  Row(
                    children: [
                      // CTA button — leftmost
                      GestureDetector(
                        onTap: () => showContactOptions(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                colorScheme.primary,
                                colorScheme.secondary,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    colorScheme.primary.withValues(alpha: 0.30),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                "Get Started",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.1,
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Divider between button and stats
                      Container(
                        width: 1,
                        height: 28,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.08),
                      ),

                      const SizedBox(width: 16),

                      // Stats — to the right of button
                      _buildStat(context, "99.9%", "Uptime"),
                      const SizedBox(width: 12),
                      Container(
                        width: 1,
                        height: 28,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.08),
                      ),
                      const SizedBox(width: 12),
                      _buildStat(context, "<10ms", "Latency"),
                      // Right side intentionally empty — space for floating button
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(BuildContext context, String value, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0D0D12),
            letterSpacing: -0.2,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark
                ? Colors.white.withValues(alpha: 0.35)
                : const Color(0xFF9B9BAA),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void gotoSectorWise() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SectorAnalysisPage()),
    );
  }

  void openAlgoDeploy() {
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(builder: (context) => AlgoDesignerPage()),
    // );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AlgoDeploymentPage()),
    );
  }
}
