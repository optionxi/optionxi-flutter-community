import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:optionxi/Main_Pages/act_leaderboard.dart';
import 'package:optionxi/VirtualTrading/VComponents/cust_info_section_item.dart';
import 'package:optionxi/VirtualTrading/act_broker_connectpage.dart';

class FragTradingHub extends StatefulWidget {
  const FragTradingHub({
    Key? key,
  }) : super(key: key);

  @override
  _FragTradingHubState createState() => _FragTradingHubState();
}

class _FragTradingHubState extends State<FragTradingHub>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [Color(0xFF0A0E1A), Color(0xFF1A1F35)]
                : [Color(0xFFF8FAFF), Color(0xFFE8F2FF)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Column(
              children: [
                // _buildHeader(isDark),
                _buildQuickActionsSection(isDark, theme),
                _buildTradingInfoSection(isDark, theme),
                _buildPremiumInfoSection(isDark, theme),
                _buildFooter(isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget _buildHeader(bool isDark) {
  //   return SlideTransition(
  //     position: Tween<Offset>(
  //       begin: Offset(0, -0.3),
  //       end: Offset.zero,
  //     ).animate(CurvedAnimation(
  //       parent: _controller,
  //       curve: Interval(0.0, 0.3, curve: Curves.easeOutCubic),
  //     )),
  //     child: Container(
  //       padding: EdgeInsets.all(24),
  //       child: Row(
  //         children: [
  //           Expanded(
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Text(
  //                   'Trading Hub',
  //                   style: GoogleFonts.poppins(
  //                     fontSize: 28,
  //                     fontWeight: FontWeight.bold,
  //                     color: isDark ? Colors.white : Colors.black87,
  //                   ),
  //                 ),
  //                 SizedBox(height: 4),
  //                 Text(
  //                   'Your gateway to live trades, tools & analytics',
  //                   style: GoogleFonts.inter(
  //                     fontSize: 14,
  //                     color: isDark ? Colors.grey[400] : Colors.grey[600],
  //                     fontWeight: FontWeight.w500,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildQuickActionsSection(bool isDark, ThemeData theme) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(0, 0.4),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Interval(0.2, 0.6, curve: Curves.easeOutCubic),
      )),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            SizedBox(height: 16),
            buildActionItem(
              title: 'Leaderboard',
              subtitle: 'Show top traders and rankings',
              icon: FontAwesomeIcons.trophy,
              color: Color(0xFFFF6B6B),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LeaderboardPage()),
                );
              },
              isDark: isDark,
            ),
            SizedBox(height: 12),
            buildActionItem(
              title: 'Organizational Request',
              subtitle: 'Request custom demo sessions & requirements',
              icon: FontAwesomeIcons.building,
              color: Color(0xFF4ECDC4),
              onTap: () {
                showCommingSoon();
              },
              isDark: isDark,
            ),
            SizedBox(height: 12),
            buildActionItem(
              title: 'Broker Connect',
              subtitle: 'Deploy algo, place orders via app, needs API access',
              icon: FontAwesomeIcons.robot,
              color: Color(0xFF9B59B6),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BrokerConnectPage()),
                );
              },
              isDark: isDark,
              badge: 'API',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTradingInfoSection(bool isDark, ThemeData theme) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(0.4, 0.8, curve: Curves.easeIn),
        ),
      ),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trading Information',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey[200]!,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildInfoItem(
                    icon: FontAwesomeIcons.clock,
                    title: 'Trading Hours',
                    content:
                        'Regular Market: 9:15 AM - 3:30 PM\nMonday - Friday',
                    isDark: isDark,
                    iconColor: Color(0xFF10B981),
                    isFirst: true,
                  ),
                  _buildInfoItem(
                    icon: FontAwesomeIcons.database,
                    title: 'Data Source',
                    content:
                        'Virtual trading uses previous day data as restricted by NSE and SEBI',
                    isDark: isDark,
                    iconColor: Color(0xFFEF4444),
                  ),
                  _buildInfoItem(
                    icon: FontAwesomeIcons.rotateRight,
                    title: 'Record Reset',
                    content:
                        'All trade records are cleared after market ends at 3:30 PM',
                    isDark: isDark,
                    iconColor: Color(0xFF8B5CF6),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumInfoSection(bool isDark, ThemeData theme) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(0.4, 0.8, curve: Curves.easeIn),
        ),
      ),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paid Features',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey[200]!,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildInfoItem(
                    icon: FontAwesomeIcons.clock,
                    title: 'Extended Trading Hours',
                    content:
                        'Regular Market: 9:15 AM - 3:30 PM\nAfter Market: 4:00 PM - 10:15 PM',
                    isDark: isDark,
                    iconColor: Color(0xFF10B981),
                    isFirst: true,
                  ),
                  _buildInfoItem(
                    icon: FontAwesomeIcons.calendar,
                    title: 'Weekend Trading',
                    content:
                        'Available on Saturday & Sunday for educational purposes',
                    isDark: isDark,
                    iconColor: Color(0xFF3B82F6),
                  ),
                  _buildInfoItem(
                    icon: FontAwesomeIcons.rotateRight,
                    title: 'Record Keep',
                    content: 'All trade records are kept for 30 days',
                    isDark: isDark,
                    iconColor: Color(0xFF8B5CF6),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String content,
    required bool isDark,
    required Color iconColor,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : BorderSide(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey[200]!,
                  width: 1,
                ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: FaIcon(
              icon,
              color: iconColor,
              size: 16,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  content,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isDark) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(0.8, 1.0, curve: Curves.easeIn),
        ),
      ),
      child: Container(
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
                _buildFooterItem('Secure', FontAwesomeIcons.shield,
                    Color(0xFF10B981), isDark),
                _buildFooterItem(
                    'Smart', FontAwesomeIcons.brain, Color(0xFF3B82F6), isDark),
                _buildFooterItem(
                    'Fast', FontAwesomeIcons.bolt, Color(0xFFEF4444), isDark),
                _buildFooterItem('Reliable', FontAwesomeIcons.heartPulse,
                    Color(0xFF8B5CF6), isDark),
              ],
            ),
            SizedBox(height: 16),
            Divider(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[300],
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
      ),
    );
  }

  Widget _buildFooterItem(
      String label, IconData icon, Color color, bool isDark) {
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
}
