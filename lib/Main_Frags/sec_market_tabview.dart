import 'package:flutter/material.dart';
import 'package:optionxi/Main_Frags/sec_bollingerbreakouts.dart';
import 'package:optionxi/Main_Frags/sec_market_sentiment.dart';

class MarketInsightsTabs extends StatefulWidget {
  const MarketInsightsTabs({Key? key}) : super(key: key);

  @override
  State<MarketInsightsTabs> createState() => _MarketInsightsTabsState();
}

class _MarketInsightsTabsState extends State<MarketInsightsTabs>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging ||
          _tabController.index != _currentIndex) {
        setState(() {
          _currentIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // --- 1. Custom Tab Bar ---
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color:
                  isDark ? colorScheme.primary.withOpacity(0.2) : Colors.white,
              border: isDark
                  ? Border.all(color: colorScheme.primary.withOpacity(0.5))
                  : null,
              boxShadow: isDark
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: isDark ? colorScheme.primary : Colors.black87,
            unselectedLabelColor: isDark ? Colors.grey[500] : Colors.grey[600],
            labelStyle:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            padding: const EdgeInsets.all(4),
            tabs: const [
              Tab(text: "Sentiment"),
              Tab(text: "Bollinger"),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // --- 2. Content Area with Dynamic Height ---
        // AnimatedSize ensures the height change is smooth when switching
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: _currentIndex == 0
              ? const AtlasOutputWidget(key: ValueKey('Atlas'))
              : const BollingerBreakoutsScreen(key: ValueKey('Bollinger')),
        ),
      ],
    );
  }
}
