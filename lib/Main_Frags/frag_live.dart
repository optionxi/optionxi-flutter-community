import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:optionxi/Components/cust_badge_widget.dart';
import 'package:optionxi/Helpers/badge_service_obx.dart';
import 'package:optionxi/VirtualTradeJournal/frag_watchlist.dart';
import 'package:optionxi/VirtualTradeJournal/vt_frag_portfolio_journal.dart';

class WatchlistFragmentMain extends StatefulWidget {
  final int? initialFragIndex;

  const WatchlistFragmentMain({Key? key, this.initialFragIndex})
      : super(key: key);

  @override
  State<WatchlistFragmentMain> createState() => _WatchlistFragmentMainState();
}

class _WatchlistFragmentMainState extends State<WatchlistFragmentMain>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentPageIndex = widget.initialFragIndex ?? 0;

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onBottomNavItemTapped(int index) async {
    if (index == 1) {
      // Clear basket badge when user taps on basket tab
      await BasketBadgeServiceObx.clearBasketBadge();
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
      WatchlistFragment(),
      PortfolioFragmentJournal(null),
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
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
                  icon: Obx(() => BadgeWidget(
                        count: BasketBadgeServiceObx.basketBadgeCount.value,
                        child: Icon(Icons.donut_small_outlined),
                      )),
                  activeIcon: Container(
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
                  label: 'Basket',
                ),
              ],
            ),
            // Selection border indicator
            Positioned(
              top: 0,
              left:
                  (_currentPageIndex * MediaQuery.of(context).size.width / 2) +
                      (MediaQuery.of(context).size.width / 2 - 40) / 2,
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
