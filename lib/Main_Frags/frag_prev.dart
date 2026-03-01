import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:optionxi/Components/cust_notice_section.dart';
import 'package:optionxi/Helpers/badge_service.dart';
import 'package:optionxi/VirtualTrading/MainFrags/vt_frag_portfolio.dart';
import 'package:optionxi/VirtualTrading/MainFrags/vt_frag_watchlist.dart';
// import 'package:optionxi/VirtualTrading/MainFrags/vt_frag_tradinghub.dart';
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

    final List<Widget> pages = [
      FNOPage(),
      OrdersPage(null),
      PortfolioFragmentPrev(null),
      // FragTradingHub(),
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
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final tabs = [
      _NavTab(
          icon: Icons.visibility_outlined,
          activeIcon: Icons.visibility_rounded,
          label: 'Watchlist'),
      _NavTab(
          icon: Icons.list_alt_outlined,
          activeIcon: Icons.list_alt_rounded,
          label: 'Orders',
          badge: _ordersBadgeCount),
      _NavTab(
          icon: Icons.donut_small_outlined,
          activeIcon: Icons.donut_small_rounded,
          label: 'Portfolio',
          badge: _portfolioBadgeCount),
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color.fromARGB(255, 16, 16, 22) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.07)
                : Colors.black.withOpacity(0.06),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.4)
                : Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: List.generate(tabs.length, (index) {
              final tab = tabs[index];
              final isSelected = _currentPageIndex == index;

              return Expanded(
                child: GestureDetector(
                  onTap: () => _onBottomNavItemTapped(index),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary
                              .withOpacity(isDark ? 0.18 : 0.10)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon with badge
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                isSelected ? tab.activeIcon : tab.icon,
                                key: ValueKey(isSelected),
                                size: 22,
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : (isDark
                                        ? Colors.white.withOpacity(0.45)
                                        : Colors.black.withOpacity(0.40)),
                              ),
                            ),
                            if (tab.badge > 0)
                              Positioned(
                                right: -8,
                                top: -6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isDark
                                          ? const Color(0xFF1A1A2E)
                                          : Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                  constraints: const BoxConstraints(
                                      minWidth: 16, minHeight: 16),
                                  child: Text(
                                    tab.badge > 99 ? '99+' : '${tab.badge}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        // Label
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : (isDark
                                    ? Colors.white.withOpacity(0.45)
                                    : Colors.black.withOpacity(0.40)),
                            letterSpacing: isSelected ? 0.2 : 0,
                          ),
                          child: Text(tab.label),
                        ),
                        // Active indicator dot
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          width: isSelected ? 18 : 0,
                          height: 3,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Helper model class — add outside the State class (at file bottom)
// ─────────────────────────────────────────────

class _NavTab {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int badge;

  const _NavTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badge = 0,
  });
}
