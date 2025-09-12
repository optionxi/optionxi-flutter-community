import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:optionxi/BrokersPage/Upstox/Main_Frags/frag_orders_upstox.dart';
import 'package:optionxi/BrokersPage/Upstox/Main_Frags/frag_portfolio_upstox.dart';
import 'package:optionxi/BrokersPage/Upstox/Main_Frags/frag_profile_upstox.dart';
import 'package:optionxi/BrokersPage/frag_watchlist_broker.dart';
import 'package:optionxi/Components/custom_nav_bar_real.dart';
import 'package:optionxi/Theme/theme_controller.dart';

class HomepageUpstox extends StatefulWidget {
  final int initialIndex;
  final int? tradeFragIndex;
  final String apikey;
  final String accesstoken;

  const HomepageUpstox({
    Key? key,
    this.initialIndex = 0,
    this.tradeFragIndex,
    required this.apikey,
    required this.accesstoken,
  }) : super(key: key);

  @override
  State<HomepageUpstox> createState() => _HomepageUpstoxState();
}

class _HomepageUpstoxState extends State<HomepageUpstox> {
  int currentIndex = 0;
  final ThemeController themeController = Get.put(ThemeController());

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex; // Set initial index
  }

  void onTap(int index) {
    setState(() => currentIndex = index);
  }

  Widget getPage(int index) {
    switch (index) {
      case 0:
        return WatchlistFragmentBroker(
          whichbroker: 'Upstox',
        );
      case 1:
        return OrdersPageUpstox();
      case 2:
        return PortfolioPageUpstox();
      case 3:
        return ProfilePageUpstox();
      default:
        return WatchlistFragmentBroker(
          whichbroker: 'Upstox',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Upstox Connected'),
            const SizedBox(width: 8),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0), // margin on the right
            child: Obx(() => _buildIconButton(
                  themeController.isDarkMode
                      ? Icons.light_mode
                      : Icons.dark_mode,
                  onPressed: () => themeController.toggleTheme(),
                )),
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: 400.ms,
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: getPage(currentIndex), // <-- rebuilt dynamically
        ),
      ),
      bottomNavigationBar: ModernTradingBottomNavFloating(
        currentIndex: currentIndex,
        onTap: onTap,
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
}
