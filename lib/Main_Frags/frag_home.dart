import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:optionxi/Components/cust_upgrade_to_pro.dart';
import 'package:optionxi/Main_Frags/home_sections/sec_broker_list.dart';
import 'package:optionxi/Components/cust_ai_sentiment_section.dart';
import 'package:optionxi/Components/cust_market_glance.dart';
import 'package:optionxi/Components/cust_market_trend_section.dart';
import 'package:optionxi/Components/cust_pratice_trading.dart';
import 'package:optionxi/Components/cust_tools_chips_markettrend.dart';
import 'package:optionxi/Components/cust_tools_chips_options.dart';
import 'package:optionxi/Components/cust_tools_chips_research.dart';
import 'package:optionxi/Components/cust_tools_chips_mytools.dart';
import 'package:optionxi/Components/cust_top_tutors.dart';
import 'package:optionxi/Components/cust_searchbar.dart';
import 'package:optionxi/Components/cust_floating_ai.dart';
import 'package:optionxi/Main_Frags/home_sections/sec_market_sentiments.dart';
import 'package:optionxi/Main_Frags/home_sections/sec_top_leaderboard.dart';
import 'package:optionxi/Helpers/badge_service.dart';
import 'package:optionxi/Main_Frags/home_sections/sec_backtesting.dart';
import 'package:optionxi/Main_Frags/home_sections/sec_breakout_section_stock_nd_index.dart';
import 'package:optionxi/Main_Pages/Achivements/fastapi_achivement.dart';
import 'package:optionxi/Main_Pages/AIPages/act_ai_optionxi.dart';
import 'package:optionxi/Main_Pages/Search/act_search_stocks_meili.dart';
import 'package:optionxi/Main_Pages/Sectorwise/act_sectorwise_page.dart';
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
    AchievementEvents.dailyActivity();
    return Scaffold(
      floatingActionButton: MagicalAIButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(),
            ),
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
                    SizedBox(height: 24),
                    PracticeTradeCard(),
                    SizedBox(height: 8),
                    StockChipsSectionMarketTrend(),
                    SizedBox(height: 16),
                    ProUpgradeButton(),
                    SizedBox(height: 8),
                    MarketSentimentSection(),
                    SizedBox(height: 8),
                    BreakoutsSection(),
                    SizedBox(height: 8),
                    StockChipsSectionResearch(),
                    SizedBox(height: 8),
                    BacktestingSection(
                      onNiftyTap: () => Get.toNamed('/backtest/nifty'),
                      onAiPicksTap: () => Get.toNamed('/backtest/ai-picks'),
                      onScreenerTap: () => Get.toNamed('/backtest/screener'),
                    ),
                    SizedBox(height: 8),
                    OptionsToolsSection(),
                    SizedBox(height: 8),
                    StockChipsSectionMyTools(),
                    SizedBox(height: 24),
                    const AiSentimentSection(),
                    SizedBox(height: 24),

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
                      child: buildBrokerHub(context, _controller),
                    ),
                    // SizedBox(height: 24),
                    // TrendingStocksSection(),
                    SizedBox(height: 8),
                    MarketTrendsSection(
                      onViewAll: gotoSectorWise,
                    ),
                    const SizedBox(height: 8),
                    Divider(),
                    TopTradingTutorsScreen(),
                    LeaderboardWidgetMain(),
                    const SizedBox(height: 24),
                    GestureDetector(
                        onTap: () => {Get.toNamed('/deploy-algo')},
                        child: _buildCtaSection()),
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

  // ─────────────────────────────────────────────────────────────
  //  HEADER
  // ─────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Obx(() {
        // Read the observable INSIDE Obx so GetX can track it correctly
        final isDark = themeController.isDarkMode;

        return Row(
          children: [
            // ── Greeting + name ──────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _greetingText(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.45)
                          : const Color(0xFF8A8A9A),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    username,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0D0D12),
                      letterSpacing: -0.5,
                      height: 1.15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // ── Action cluster ────────────────────────────────────
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dark/light pill toggle — isDark already reactive here
                _buildThemePill(isDark, colorScheme),
                const SizedBox(width: 10),

                // Notification bell with badge
                _buildNotificationIcon(
                  Icons.notifications_outlined,
                  onPressed: gotoNofitication,
                ),
                const SizedBox(width: 10),

                // User avatar with online dot
                _buildUserAvatar(colorScheme),
              ],
            ),
          ],
        );
      }),
    );
  }

  // ── Greeting helper ───────────────────────────────────────────
  String _greetingText() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good morning 🌤";
    if (hour < 17) return "Good afternoon ☀️";
    return "Good evening 🌙";
  }

  // ── Sun / Moon pill toggle ────────────────────────────────────
  Widget _buildThemePill(bool isDark, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: () => themeController.toggleTheme(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 68,
        height: 36,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2A) : const Color(0xFFF0F0F6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.07),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Sliding knob
            AnimatedAlign(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 30,
                height: 30,
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF6C63FF), const Color(0xFF3B82F6)]
                        : [const Color(0xFFFFB347), const Color(0xFFFF7043)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark
                              ? const Color(0xFF6C63FF)
                              : const Color(0xFFFFB347))
                          .withValues(alpha: 0.45),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    isDark ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                    size: 15,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // Dim icon on the inactive side
            Align(
              alignment: isDark ? Alignment.centerLeft : Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 9),
                child: Icon(
                  isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                  size: 14,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.25)
                      : Colors.black.withValues(alpha: 0.20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Notification bell ─────────────────────────────────────────
  Widget _buildNotificationIcon(IconData icon, {VoidCallback? onPressed}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _buildIconButton(icon, onPressed: onPressed),
        Positioned(
          right: -3,
          top: -3,
          child: StreamBuilder<int>(
            stream: BadgeService.notificationsStreamWithInitial,
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data == 0) {
                return const SizedBox.shrink();
              }
              final count = snapshot.data!;
              return IgnorePointer(
                child: Container(
                  constraints:
                      const BoxConstraints(minWidth: 18, minHeight: 18),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF3B5C),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: Text(
                        count > 9 ? '9+' : count.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── User avatar with online dot ───────────────────────────────
  Widget _buildUserAvatar(ColorScheme colorScheme) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colorScheme.primary, colorScheme.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.30),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(2.5),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: SizedBox(
              width: 36,
              height: 36,
              child: FirebaseAuth.instance.currentUser?.photoURL != null
                  ? Image.network(
                      FirebaseAuth.instance.currentUser!.photoURL!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.asset(
                        'assets/images/option_xi_w.png',
                        fit: BoxFit.cover,
                      ),
                    )
                  : Image.asset(
                      'assets/images/option_xi_w.png',
                      fit: BoxFit.cover,
                    ),
            ),
          ),
        ),
        // Online / active dot
        Positioned(
          right: -1,
          bottom: -1,
          child: Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E),
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).scaffoldBackgroundColor,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Base icon button (shared) ─────────────────────────────────
  Widget _buildIconButton(IconData icon, {VoidCallback? onPressed}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2A) : const Color(0xFFF0F0F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 20),
        onPressed: onPressed,
        color: Theme.of(context).iconTheme.color,
      ),
    );
  }

  // ── Notification tap handler ──────────────────────────────────
  void gotoNofitication() async {
    await BadgeService.clearNotificationsBadge();
    await Navigator.pushNamed(
      context,
      '/notifications',
      arguments: {},
    );
    if (mounted) setState(() {});
  }

  // ─────────────────────────────────────────────────────────────
  //  CTA SECTION (unchanged)
  // ─────────────────────────────────────────────────────────────

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
            Positioned.fill(
              child: Container(
                color:
                    isDark ? const Color(0xFF141418) : const Color(0xFFFAFAFC),
              ),
            ),
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
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  Container(
                    height: 1,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.06),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
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
                      const SizedBox(width: 16),
                      Container(
                        width: 1,
                        height: 28,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.08),
                      ),
                      const SizedBox(width: 16),
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
}
