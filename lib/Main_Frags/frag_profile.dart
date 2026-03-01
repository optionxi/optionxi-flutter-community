import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:optionxi/Auth_Service/auth_service.dart';
import 'package:optionxi/Components/cust_alert_section_new.dart';
import 'package:optionxi/Components/cust_contact_us.dart';
import 'package:optionxi/Components/cust_virtual_balance_section.dart';
import 'package:optionxi/Helpers/badge_service.dart';
import 'package:optionxi/Helpers/open_url.dart';
import 'package:optionxi/Main_Pages/act_health_monitors.dart';
import 'package:optionxi/Main_Pages/act_leaderboard.dart';
import 'package:optionxi/Main_Pages/act_org_onboarding.dart';
import 'package:optionxi/Main_Pages/act_setalert_page_all.dart';
// import 'package:optionxi/MobileLink/link_phone_screen.dart';
import 'package:optionxi/Theme/theme_controller.dart';
import 'package:optionxi/VirtualTradeJournal/act_basket_fullpage.dart';
import 'package:optionxi/VirtualTrading/act_broker_connectpage.dart';

class TradingProfilePage extends StatefulWidget {
  @override
  _TradingProfilePageState createState() => _TradingProfilePageState();
}

class _TradingProfilePageState extends State<TradingProfilePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _privacyMode = false;
  // bool _isLoading = true;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
    _fetchUserData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    try {
      if (currentUser != null) {
        final snapshot =
            await _database.child('regusers/${currentUser!.uid}').get();
        if (snapshot.exists) {
          final data = snapshot.value as Map<dynamic, dynamic>;
          if (mounted) {
            setState(() {
              _privacyMode = data['rg_privacy'] ?? false;
              // _isLoading = false;
            });
          }
        } else {
          // if (mounted) setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      // if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePrivacySetting(bool value) async {
    try {
      if (currentUser != null) {
        await _database
            .child('regusers/${currentUser!.uid}/rg_privacy')
            .set(value);
        setState(() => _privacyMode = value);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Privacy mode updated (takes effect next session)",
                style: GoogleFonts.inter(color: Colors.white)),
            backgroundColor: Colors.black87,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      setState(() => _privacyMode = !value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildModernHeader(theme),

              const SizedBox(height: 10),

              // Balance Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: BalanceCard(),
              ),

              const SizedBox(height: 20),

              // Alerts Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildAlertsWrapper(context, isDark),
              ),

              const SizedBox(height: 24),

              // Trading Hub Grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "Trading Hub",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onBackground,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildTradingGrid(theme),

              const SizedBox(height: 24),

              // Settings Lists
              _buildSettingsSection(theme, isDark),

              const SizedBox(height: 24),

              // Footer
              InkWell(
                onTap: () => OpenHelper.open_url(
                    "https://github.com/optionxi/optionxi-flutter-community"),
                child: _buildCleanFooter(isDark),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. MODERN HEADER
  // ---------------------------------------------------------------------------
  Widget _buildModernHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          // Avatar
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.2), width: 2),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ],
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: theme.cardColor,
              backgroundImage: currentUser?.photoURL != null
                  ? NetworkImage(currentUser!.photoURL!)
                  : null,
              child: currentUser?.photoURL == null
                  ? Icon(Icons.person, color: theme.colorScheme.primary)
                  : null,
            ),
          ),
          const SizedBox(width: 16),

          // Name & Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentUser?.displayName ?? "Trader",
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onBackground,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const SizedBox(width: 8),
                    Text(
                      currentUser?.email ?? "",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: theme.colorScheme.onBackground.withOpacity(0.5),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Logout Icon Button
          IconButton(
            onPressed: () => AuthService().logOut(),
            icon: Icon(Icons.logout_rounded, color: theme.colorScheme.error),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.error.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          )
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. ALERT WRAPPER
  // ---------------------------------------------------------------------------
  Widget _buildAlertsWrapper(BuildContext context, bool isDark) {
    return InkWell(
      onTap: () async {
        await BadgeService.clearAlertsBadge();
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => AlertsPage()));
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: isDark ? Colors.white10 : Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: AlertsSection(), // Your existing widget
          ),
          Positioned(
            right: -2,
            top: -2,
            child: StreamBuilder<int>(
              stream: BadgeService.alertsStreamWithInitial,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data == 0)
                  return const SizedBox.shrink();
                return Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    snapshot.data!.toString(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. TRADING GRID (Replaces simple list)
  // ---------------------------------------------------------------------------
  Widget _buildTradingGrid(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
        children: [
          _buildGridCard(
            title: "Leaderboard",
            subtitle: "Global Rank",
            icon: FontAwesomeIcons.trophy,
            color: Colors.amber,
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (c) => LeaderboardPage())),
            theme: theme,
          ),
          _buildGridCard(
            title: "Broker Connect",
            subtitle: "Manage API",
            icon: FontAwesomeIcons.link,
            color: Colors.blueAccent,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (c) => BrokerConnectPage())),
            theme: theme,
          ),
          _buildGridCard(
            title: "My Basket",
            subtitle: "Saved Strategies",
            icon: FontAwesomeIcons.basketShopping,
            color: Colors.purpleAccent,
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (c) => BasketFullPage())),
            theme: theme,
            isNew: true,
          ),
          _buildGridCard(
            title: "Organizations",
            subtitle: "Manage Teams",
            icon: FontAwesomeIcons.building,
            color: Colors.teal,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (c) => OrganizationOnboardingPage())),
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildGridCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required ThemeData theme,
    bool isNew = false,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: isDark ? Colors.white10 : Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: FaIcon(icon, size: 16, color: color),
                  ),
                  if (isNew)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text("NEW",
                          style: GoogleFonts.inter(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: Colors.red)),
                    )
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onBackground,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: theme.colorScheme.onBackground.withOpacity(0.6),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. PREFERENCES LIST (Grouped)
  // ---------------------------------------------------------------------------
  Widget _buildSettingsSection(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              "Preferences",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onBackground,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: isDark ? Colors.white10 : Colors.grey.shade200),
            ),
            child: Column(
              children: [
                _buildModernTile(
                  title: "Privacy Mode",
                  icon: Icons.privacy_tip_outlined,
                  color: Colors.orange,
                  theme: theme,
                  trailing: SizedBox(
                    height: 24,
                    child: Switch(
                      value: _privacyMode,
                      onChanged: _updatePrivacySetting,
                      activeColor: theme.colorScheme.primary,
                    ),
                  ),
                ),
                // _buildDivider(isDark),
                // _buildModernTile(
                //   title: "Verification Status",
                //   icon: Icons.verified_user_outlined,
                //   color: Colors.green,
                //   theme: theme,
                //   trailing: const Icon(Icons.arrow_forward_ios,
                //       size: 14, color: Colors.grey),
                //   onTap: () => Navigator.push(context,
                //       MaterialPageRoute(builder: (c) => LinkPhoneScreen())),
                // ),
                _buildDivider(isDark),
                GetBuilder<ThemeController>(
                  builder: (controller) {
                    return _buildModernTile(
                      title: "Dark Mode",
                      icon: controller.isDarkMode
                          ? Icons.dark_mode
                          : Icons.light_mode,
                      color: Colors.indigo,
                      theme: theme,
                      trailing: SizedBox(
                        height: 24,
                        child: Switch(
                          value: controller.isDarkMode,
                          onChanged: (val) => controller.toggleTheme(),
                          activeColor: theme.colorScheme.primary,
                        ),
                      ),
                    );
                  },
                ),
                _buildDivider(isDark),
                _buildModernTile(
                  title: "Help & Support",
                  icon: Icons.headset_mic_outlined,
                  color: Colors.pinkAccent,
                  theme: theme,
                  trailing: const Icon(Icons.arrow_forward_ios,
                      size: 14, color: Colors.grey),
                  onTap: () => showContactOptions(context),
                ),
                _buildModernTile(
                  title: "Health Status",
                  icon: Icons.favorite_rounded,
                  color: const Color(0xFFE53935), // modern medical red
                  theme: theme,
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.grey,
                  ),
                  onTap: () => openHealthMonitorPage(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void openHealthMonitorPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HealthDashboard()),
    );
  }

  Widget _buildModernTile({
    required String title,
    required IconData icon,
    required Color color,
    required ThemeData theme,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: theme.colorScheme.onBackground,
        ),
      ),
      trailing: trailing,
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 60,
      color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
    );
  }

  // ---------------------------------------------------------------------------
  // 5. CLEAN FOOTER
  // ---------------------------------------------------------------------------
  Widget _buildCleanFooter(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
              : [const Color(0xFFF8FAFC), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(FontAwesomeIcons.github,
                  size: 18, color: isDark ? Colors.white70 : Colors.black87),
              const SizedBox(width: 8),
              Text(
                'Open Source Community',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Built by traders, for traders.',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
