import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:optionxi/Components/cust_badge_widget.dart';
import 'package:optionxi/Components/cust_notice_section.dart';
import 'package:optionxi/Helpers/badge_service.dart';
import 'package:optionxi/VirtualTrading/MainFrags/vt_frag_portfolio.dart';
import 'package:optionxi/VirtualTrading/MainFrags/vt_frag_watchlist.dart';
import 'package:optionxi/VirtualTrading/MainFrags/vt_frag_tradinghub.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optionxi/VirtualTrading/MainFrags/vt_frag_orders.dart';

class VirtualTradingFragment extends StatefulWidget {
  final int? initialFragIndex;

  const VirtualTradingFragment({Key? key, this.initialFragIndex})
      : super(key: key);

  @override
  State<VirtualTradingFragment> createState() => _VirtualTradingFragmentState();
}

class _VirtualTradingFragmentState extends State<VirtualTradingFragment>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _currentPageIndex = 0;
  bool _hasShownPopup = false;

  // Badge counts
  int _ordersBadgeCount = 0;
  int _portfolioBadgeCount = 0;

  @override
  void initState() {
    super.initState();
    _currentPageIndex = widget.initialFragIndex ?? 0;

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    // Load badge counts
    _loadBadgeCounts();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showEducationalPopup();
    });
  }

  // Load badge counts from SharedPreferences
  Future<void> _loadBadgeCounts() async {
    final ordersBadge = await BadgeService.getOrdersBadgeCount();
    final portfolioBadge = await BadgeService.getPortfolioBadgeCount();

    setState(() {
      _ordersBadgeCount = ordersBadge;
      _portfolioBadgeCount = portfolioBadge;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showEducationalPopup() async {
    if (_hasShownPopup) return;

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final lastDismissedStr = prefs.getString('educationalPopupDismissedAt');

    if (lastDismissedStr != null) {
      final lastDismissed = DateTime.tryParse(lastDismissedStr);
      if (lastDismissed != null && now.difference(lastDismissed).inHours < 24) {
        return;
      }
    }

    bool dontShowAgain = false;

    final theme = Theme.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: theme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.info_outline,
                  color: Colors.orange,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Educational Mode',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This section displays previous day data, as required by regulatory guidelines (SEBI and NSE) for virtual trading platforms.',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  height: 1.4,
                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.school_outlined,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'It\'s perfect for learning and practicing trading strategies in a simulated environment!',
                        style: GoogleFonts.inter(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: dontShowAgain,
                    onChanged: (val) {
                      setState(() {
                        dontShowAgain = val ?? false;
                      });
                    },
                  ),
                  Expanded(
                    child: Text(
                      "Don't show again for today",
                      style: GoogleFonts.inter(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                if (dontShowAgain) {
                  await prefs.setString(
                      'educationalPopupDismissedAt', now.toIso8601String());
                }
                Navigator.pop(context);
                setState(() {
                  _hasShownPopup = true;
                });
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Got it!'),
            ),
          ],
        ),
      ),
    );
  }

  void _onBottomNavItemTapped(int index) async {
    // Clear badge when user taps on the respective tab
    if (index == 1) {
      // Orders tab
      await BadgeService.clearOrdersBadge();
      setState(() {
        _ordersBadgeCount = 0;
      });
    } else if (index == 2) {
      // Portfolio tab
      await BadgeService.clearPortfolioBadge();
      setState(() {
        _portfolioBadgeCount = 0;
      });
    }

    setState(() {
      _currentPageIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final List<Widget> pages = [
      FNOPage(),
      OrdersPage(null),
      PortfolioFragmentPrev(null),
      FragTradingHub(),
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // NoticesSection at the top - normal flow
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
              child: NoticesSection(),
            ),
          ),
          // Main content - takes remaining space
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: pages[_currentPageIndex],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.08),
              width: 1,
            ),
          ),
        ),
        child: Stack(
          children: [
            BottomNavigationBar(
              currentIndex: _currentPageIndex,
              onTap: _onBottomNavItemTapped,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: theme.colorScheme.primary,
              unselectedItemColor: theme.colorScheme.onSurface.withOpacity(0.6),
              backgroundColor: theme.scaffoldBackgroundColor,
              selectedLabelStyle:
                  GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12),
              unselectedLabelStyle:
                  GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 12),
              elevation: 0,
              items: [
                BottomNavigationBarItem(
                  icon: Icon(Icons.visibility_outlined),
                  activeIcon: Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.visibility,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  label: 'Watchlist',
                ),
                BottomNavigationBarItem(
                  icon: BadgeWidget(
                    count: _ordersBadgeCount,
                    child: Icon(Icons.list_alt_outlined),
                  ),
                  activeIcon: BadgeWidget(
                    count: _ordersBadgeCount,
                    child: Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.list_alt,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  label: 'Orders',
                ),
                BottomNavigationBarItem(
                  icon: BadgeWidget(
                    count: _portfolioBadgeCount,
                    child: Icon(Icons.donut_small_outlined),
                  ),
                  activeIcon: BadgeWidget(
                    count: _portfolioBadgeCount,
                    child: Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.donut_small,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  label: 'Portfolio',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.wallet),
                  activeIcon: Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.wallet,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  label: 'Trade Hub',
                ),
              ],
            ),
            // Selection border indicator
            Positioned(
              top: 0,
              left:
                  (_currentPageIndex * MediaQuery.of(context).size.width / 4) +
                      (MediaQuery.of(context).size.width / 4 - 40) / 2,
              child: Container(
                width: 40,
                height: 3,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
