import 'package:flutter/material.dart';
import 'package:optionxi/Main_Frags/home_sections/sec_market_movers.dart';
import 'package:optionxi/Main_Frags/home_sections/sec_market_tabview.dart';
import 'package:optionxi/Main_Frags/home_sections/sec_stock_scanners.dart';
import 'package:optionxi/Main_Frags/home_sections/sec_stock_screeners.dart';

class AdvancedTradingToolsPageV2 extends StatefulWidget {
  const AdvancedTradingToolsPageV2({Key? key}) : super(key: key);

  @override
  _AdvancedTradingToolsPageV2State createState() =>
      _AdvancedTradingToolsPageV2State();
}

class _AdvancedTradingToolsPageV2State extends State<AdvancedTradingToolsPageV2>
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
    // Use Theme.of(context) to get current theme
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(
            children: [
              // _buildHeader(isDark),
              MarketMoversScreen(),
              LiveScannerWidget(),
              SizedBox(
                height: 12,
              ),

              ScreenersScreen(),
              SizedBox(
                height: 12,
              ),
              MarketInsightsTabs()
            ],
          ),
        ),
      ),
    );
  }
}
