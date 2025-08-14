import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:optionxi/Auth_Service/auth_service.dart';
import 'package:optionxi/Components/cust_contact_us.dart';
import 'package:optionxi/Components/cust_virtual_balance_section.dart';
import 'package:optionxi/Helpers/open_url.dart';
import 'package:optionxi/Main_Pages/act_leaderboard.dart';
import 'package:optionxi/Main_Pages/act_news.dart';
import 'package:optionxi/Main_Pages/act_portfolio.dart';
import 'package:optionxi/Main_Pages/act_predictions.dart';
import 'package:optionxi/Main_Pages/act_tradingideas.dart';
import 'package:optionxi/MobileLink/link_phone_screen.dart';
import 'package:optionxi/Theme/theme_controller.dart';
import 'package:optionxi/VirtualTrading/act_broker_connectpage.dart';

class TradingProfilePage extends StatefulWidget {
  @override
  _TradingProfilePageState createState() => _TradingProfilePageState();
}

class _TradingProfilePageState extends State<TradingProfilePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  // Add these variables
  bool _privacyMode = false;
  bool _isLoading = true;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    // Fetch user data on init
    _fetchUserData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Add this method to fetch user data
  Future<void> _fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final snapshot = await _database.child('regusers/${user.uid}').get();

        if (snapshot.exists) {
          final data = snapshot.value as Map<dynamic, dynamic>;
          setState(() {
            _privacyMode = data['rg_privacy'] ?? false;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Add this method to update privacy setting
  Future<void> _updatePrivacySetting(bool value) async {
    final theme = Theme.of(context);
    // String up_message = value ? "Privacy turned on" : "Privacy turn off";
    String up_message = "Will be updated after market hours..";
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _database.child('regusers/${user.uid}/rg_privacy').set(value);
        setState(() {
          _privacyMode = value;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(up_message,
                style: GoogleFonts.inter(color: theme.colorScheme.onPrimary)),
            backgroundColor: theme
                .colorScheme.primary, // SnackBar consistent with primary color
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: Duration(milliseconds: 1500),
            // margin: EdgeInsets.only(bottom: 70), // Add bottom margin
          ),
        );
      }
    } catch (e) {
      print('Error updating privacy setting: $e');
      // Revert the UI change if update fails
      setState(() {
        _privacyMode = !value;
      });
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
          physics: BouncingScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(theme),
              BalanceCard(),
              // Padding(
              //   padding: const EdgeInsets.all(16.0),
              //   child: LeaderboardWidgetMain(),
              // ),
              // TopTradingTutorsScreen(),
              // const SizedBox(height: 24),
              // ProfileStatsWidget(),
              _buildOptionsLists(theme),
              InkWell(
                  onTap: () {
                    OpenHelper.open_url(
                        "https://github.com/optionxi/optionxi-flutter-community");
                  },
                  child: _buildFooter(isDark)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final primaryColor = theme.colorScheme.primary;
    final secondaryColor = theme.colorScheme.secondary;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardColor;

    return FadeTransition(
      opacity: _controller,
      child: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            InkWell(
              onTap: () {
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(builder: (context) => ContributorsPage()),
                // );
              },
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [primaryColor, secondaryColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(color: cardColor, width: 4),
                    ),
                    child: FirebaseAuth.instance.currentUser != null &&
                            FirebaseAuth.instance.currentUser!.photoURL != null
                        ? Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [primaryColor, secondaryColor],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(60),
                            ),
                            padding: EdgeInsets.all(2),
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: backgroundColor,
                              backgroundImage: NetworkImage(
                                  FirebaseAuth.instance.currentUser!.photoURL!),
                            ),
                          )
                        : Icon(Icons.person,
                            size: 60, color: theme.colorScheme.onPrimary),
                  ),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.edit,
                        size: 20, color: theme.colorScheme.onPrimary),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Text(
              FirebaseAuth.instance.currentUser?.displayName ?? "OptionXi",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onBackground,
              ),
            ),
            // SizedBox(height: 8),
            // Text(
            //   "Professional Trader",
            //   style: TextStyle(
            //     color: theme.colorScheme.onBackground.withValues(alpha: 0.6),
            //     fontSize: 16,
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsLists(ThemeData theme) {
    final theme = Theme.of(context);
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(0, 0.2),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Interval(0.4, 0.6, curve: Curves.easeOut),
      )),
      child: Container(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AdSectionProfilePrev(),
            _buildSection(
                "Trading",
                [
                  OptionItem("Leaderboard", FontAwesomeIcons.trophy,
                      badgeText: "Beta", onTap: goToLeaderBoardPage),
                  OptionItem("Broker Connect", FontAwesomeIcons.robot,
                      badgeText: "Beta", onTap: gotoBrokerConnect),
                  OptionItem("Oraganisations", FontAwesomeIcons.building,
                      badgeText: "Soon", onTap: showCommingSoon),
                  OptionItem("Live virtual trading", Icons.bolt,
                      badgeText: "Soon", onTap: showCommingSoon),
                  OptionItem(
                    "Privacy Mode",
                    Icons.privacy_tip,
                    trailing: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Switch(
                            value: _privacyMode,
                            onChanged: (value) => _updatePrivacySetting(value),
                            activeColor: theme.colorScheme.primary,
                          ),
                  ),
                ],
                theme),
            _buildSection(
                "Account",
                [
                  OptionItem(
                    "Verification Status",
                    Icons.verified,
                    trailing: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Verified",
                        style: TextStyle(color: Colors.green),
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => LinkPhoneScreen()),
                      );
                    },
                  ),
                  // OptionItem("Payment Methods", Icons.payment),
                  OptionItem(
                    "Logout",
                    Icons.exit_to_app,
                    onTap: () {
                      AuthService().logOut();
                    },
                  ),
                  // OptionItem("Security Settings", Icons.security),
                ],
                theme),
            _buildSection(
                "Preferences",
                [
                  OptionItem("Feature Request", Icons.settings, onTap: () {
                    OpenHelper.open_url(
                        "https://app.optionxi.com/feature-request");
                  }),
                  OptionItem("Webview", Icons.language, onTap: () {
                    OpenHelper.open_url("https://app.optionxi.com");
                  }),
                  OptionItem(
                    "Dark Mode",
                    ThemeController.instance.isDarkMode
                        ? Icons.light_mode
                        : Icons.dark_mode,
                    trailing: GetBuilder<ThemeController>(
                      builder: (controller) {
                        return Switch(
                          value: controller.isDarkMode,
                          onChanged: (value) => controller.toggleTheme(),
                          activeColor: theme.colorScheme.primary,
                        );
                      },
                    ),
                  ),
                  OptionItem("Customer Support", Icons.help_outline,
                      onTap: () async {
                    showContactOptions(context);
                  }),
                ],
                theme),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<OptionItem> items, ThemeData theme) {
    final borderColor = theme.brightness == Brightness.dark
        ? Colors.grey[850]
        : Colors.grey[300];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onBackground,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor!, width: 1),
          ),
          child: Column(
            children:
                items.map((item) => _buildOptionItem(item, theme)).toList(),
          ),
        ),
      ],
    );
  }

  void changetoLightandDarkMode() {
    final themeController = Get.find<ThemeController>();
    themeController.toggleTheme();
  }

  Widget _buildOptionItem(OptionItem item, ThemeData theme) {
    final borderColor = theme.brightness == Brightness.dark
        ? Colors.grey[850]
        : Colors.grey[300];

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: borderColor!,
            width: 1,
          ),
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            item.icon,
            color: theme.colorScheme.primary,
          ),
        ),
        title: Text(
          item.title,
          style: TextStyle(
            color: theme.colorScheme.onBackground,
            fontSize: 16,
          ),
        ),
        trailing: item.trailing ??
            (item.badgeText != null
                ? Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.badgeText!,
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 12,
                      ),
                    ),
                  )
                : Icon(Icons.chevron_right,
                    color:
                        theme.colorScheme.onBackground.withValues(alpha: 0.6))),
        onTap: item.onTap,
      ),
    );
  }

  void goToPortfolioPage() {
    //Go to OTP entering Page
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PortfolioPage()),
    );
  }

  void goToLeaderBoardPage() {
    //Go to OTP entering Page
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LeaderboardPage()),
    );
  }

  void gotoBrokerConnect() {
    //Go to OTP entering Page
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BrokerConnectPage()),
    );
  }

  void showCommingSoon() {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('This feature will be comming soon!, Stay tuned',
            style: GoogleFonts.inter(color: theme.colorScheme.onPrimary)),
        backgroundColor:
            theme.colorScheme.primary, // SnackBar consistent with primary color
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void goToMarketNews() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => TradingNewsPage()));
  }

  void goToTradersPredictions() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => PredictionPage()));
  }

  void goToTradingIdeas() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => TradingIdeasPage()));
  }
}

class OptionItem {
  final String title;
  final IconData icon;
  final String? badgeText;
  final Widget? trailing;
  final VoidCallback? onTap;

  OptionItem(this.title, this.icon,
      {this.badgeText, this.trailing, this.onTap});
}

Widget _buildFooter(bool isDark) {
  return Container(
    margin: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    padding: EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: isDark ? Color(0xFF1E293B) : Colors.grey[50],
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200]!,
      ),
    ),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildFooterItem(
                'Smart', FontAwesomeIcons.brain, Color(0xFF3B82F6), isDark),
            _buildFooterItem(
                'Fast', FontAwesomeIcons.bolt, Color(0xFFEF4444), isDark),
            _buildFooterItem('Reliable', FontAwesomeIcons.heartPulse,
                Color(0xFF8B5CF6), isDark),
          ],
        ),
        SizedBox(height: 20),
        Divider(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[300],
        ),
        SizedBox(height: 20),

        // GitHub Section
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200]!,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FaIcon(
                    FontAwesomeIcons.github,
                    size: 20,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Open Source',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'optionxi/optionxi-flutter-community',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(0xFFFBBF24).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Color(0xFFFBBF24).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FaIcon(
                          FontAwesomeIcons.star,
                          size: 12,
                          color: Color(0xFFFBBF24),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Star us',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFFBBF24),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FaIcon(
                          FontAwesomeIcons.externalLinkAlt,
                          size: 10,
                          color: Colors.white,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'View on GitHub',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        SizedBox(height: 16),
        Text(
          '© 2025 OptionXi. Built for traders, by traders.',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: isDark ? Colors.grey[500] : Colors.grey[600],
          ),
        ),
      ],
    ),
  );
}

Widget _buildFooterItem(String label, IconData icon, Color color, bool isDark) {
  return Column(
    children: [
      Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: FaIcon(
          icon,
          size: 16,
          color: color,
        ),
      ),
      SizedBox(height: 6),
      Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}
