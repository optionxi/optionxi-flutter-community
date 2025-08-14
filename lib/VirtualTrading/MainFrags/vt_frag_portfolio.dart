import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:optionxi/Helpers/conversions.dart';
import 'package:optionxi/Main_Pages/act_leaderboard.dart';
import 'package:optionxi/VirtualTrading/VComponents/cust_pulsating_effect.dart';
import 'package:optionxi/VirtualTrading/VControllers/portfolio_prev_controller.dart';
import 'package:optionxi/VirtualTrading/VDataModel/v_holdings.dart';
import 'package:optionxi/VirtualTrading/act_buyandsell_prev.dart';
import 'package:timeago/timeago.dart' as timeago;

class PortfolioFragmentPrev extends StatefulWidget {
  final LeaderboardEntry? user;
  const PortfolioFragmentPrev(this.user, {Key? key}) : super(key: key);

  @override
  State<PortfolioFragmentPrev> createState() => _PortfolioFragmentPrevState();
}

class _PortfolioFragmentPrevState extends State<PortfolioFragmentPrev>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late PortfolioController controller;
  // final PortfolioController controller = Get.put(PortfolioController());
  // final PortfolioController controller = Get.put(PortfolioController(suid: widget.user?.suid));

  bool isStatsExpanded = false;

  @override
  void initState() {
    super.initState();
    // Safely use widget.user inside initState
    controller = Get.put(PortfolioController(suid: widget.user?.suid));
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: widget.user != null
          ? _fragPortfolio()
          : SafeArea(
              child: _fragPortfolio(),
            ),
    );
  }

  Obx _fragPortfolio() {
    return Obx(() {
      return NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildHeader(),
                _buildCollapsibleStats(),
              ],
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: TabBarDelegate(
              tabBar: _buildTabBar(),
            ),
          ),
        ],
        body: controller.isLoading.value
            ? Center(child: CircularProgressIndicator())
            : _buildTabBarView(),
      );
    });
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Obx(() {
  //     if (controller.isLoading.value) {
  //       return Center(child: CircularProgressIndicator());
  //     }

  //     return CustomScrollView(
  //       // Use CustomScrollView instead of NestedScrollView
  //       slivers: [
  //         // Header section
  //         SliverToBoxAdapter(
  //           child: Column(
  //             children: [
  //               _buildHeader(),
  //               _buildCollapsibleStats(),
  //             ],
  //           ),
  //         ),
  //         // Tab bar
  //         SliverPersistentHeader(
  //           pinned: true,
  //           delegate: TabBarDelegate(
  //             tabBar: _buildTabBar(),
  //           ),
  //         ),
  //         // Tab content
  //         SliverFillRemaining(
  //           child: _buildTabBarView(),
  //         ),
  //       ],
  //     );
  //   });
  // }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Portfolio',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'DELAYED',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsibleStats() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Investment',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '₹${convertToKMB(controller.totalInvestment.value.toStringAsFixed(2))}',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Total P&L',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // ### MODIFIED: Wrapped Total P&L with PulsatingEffect ###
                    PulsatingEffect(
                      value: controller.totalProfit.value,
                      child: Text(
                        '₹${controller.totalProfit.value.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: controller.totalProfit.value >= 0
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                // Container(
                //   padding: const EdgeInsets.all(8),
                //   decoration: BoxDecoration(
                //     color: (controller.totalProfit.value >= 0
                //             ? Colors.green
                //             : Colors.red)
                //         .withOpacity(0.1),
                //     borderRadius: BorderRadius.circular(8),
                //   ),
                //   child: Icon(
                //     controller.totalProfit.value >= 0
                //         ? Icons.trending_up_rounded
                //         : Icons.trending_down_rounded,
                //     size: 18,
                //     color: controller.totalProfit.value >= 0
                //         ? Colors.green
                //         : Colors.red,
                //   ),
                // ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  TabBar _buildTabBar() {
    return TabBar(
      controller: _tabController,
      labelColor: Colors.white,
      unselectedLabelColor: Theme.of(context).textTheme.bodyMedium?.color,
      indicatorSize: TabBarIndicatorSize.tab,
      indicator: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
      unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500),
      tabs: [
        Tab(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.autorenew, size: 18),
                SizedBox(width: 8),
                Text('Unrealised'),
              ],
            ),
          ),
        ),
        Tab(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 18),
                SizedBox(width: 8),
                Text('Realised'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: [
        RefreshIndicator(
            onRefresh: () async {
              await controller.fetchAllData();
            },
            child: _buildUnrealisedTab()),
        RefreshIndicator(
            onRefresh: () async {
              await controller.fetchAllData();
            },
            child: _buildRealisedTab()),
      ],
    );
  }

  Widget _buildUnrealisedTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUnrealisedStats(),
          const SizedBox(height: 24),
          _buildSectionHeader('Holdings', Icons.trending_up_rounded, true),
          const SizedBox(height: 12),
          Obx(() {
            if (controller.holdings.isEmpty) {
              return _buildEmptyState(
                icon: Icons.inventory_2_outlined,
                message: 'No holdings yet',
                subtitle: 'Your stock positions will appear here',
              );
            }
            return ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: controller.holdings
                  .map((pos) => InkWell(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => BuyandSellPagePrev(
                                    pos.symbol, pos.segment, false)));
                      },
                      child: _buildModernPositionCard(pos)))
                  .toList(),
            );
          }),
          const SizedBox(height: 24),
          _buildSectionHeader(
              'Short Positions', Icons.trending_down_rounded, false),
          const SizedBox(height: 12),
          Obx(() {
            if (controller.shortPositions.isEmpty) {
              return _buildEmptyState(
                icon: Icons.trending_down_outlined,
                message: 'No short positions',
                subtitle: 'Your short positions will appear here',
              );
            }
            return ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: controller.shortPositions
                  .map((pos) => InkWell(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => BuyandSellPagePrev(
                                    pos.symbol, pos.segment, false)));
                      },
                      child: _buildModernPositionCard(pos, isShort: true)))
                  .toList(),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildUnrealisedStats() {
    final unrealisedPnl = _calculateUnrealisedPnL();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Unrealised P/L',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          // ### MODIFIED: Wrapped Unrealised P/L with PulsatingEffect ###
          PulsatingEffect(
            value: unrealisedPnl,
            child: Text(
              '${unrealisedPnl >= 0 ? '+' : ''}₹${unrealisedPnl.toStringAsFixed(2)}',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: unrealisedPnl >= 0 ? Colors.green : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealisedTab() {
    return Obx(() {
      if (controller.tradeHistory.isEmpty) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildRealisedStats(),
              Expanded(
                child: _buildEmptyState(
                  icon: Icons.history_toggle_off_outlined,
                  message: 'No trade history',
                  subtitle: 'Your completed trades will appear here',
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.tradeHistory.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildRealisedStats(),
            );
          }

          final trade = controller.tradeHistory[index - 1];
          return InkWell(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => BuyandSellPagePrev(
                          trade.symbol, trade.segment, false)));
            },
            child: _buildModernTradeCard(trade),
          );
        },
      );
    });
  }

  Widget _buildRealisedStats() {
    final realisedPnl =
        controller.tradeHistory.fold(0.0, (sum, item) => sum + item.profitLoss);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Realised P/L',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          // ### MODIFIED: Wrapped Realised P/L with PulsatingEffect ###
          PulsatingEffect(
            value: realisedPnl,
            child: Text(
              '${realisedPnl >= 0 ? '+' : ''}₹${realisedPnl.toStringAsFixed(2)}',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: realisedPnl >= 0 ? Colors.green : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isBullish) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isBullish ? Colors.green : Colors.red,
            // color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildModernPositionCard(Holding pos, {bool isShort = false}) {
    final ltp = controller.getLtp(pos.symbol);
    final pnl = (ltp - pos.averagePrice) * pos.quantity * (isShort ? -1 : 1);
    final pnlColor = pnl >= 0 ? Colors.green : Colors.red;
    final pnlPrefix = pnl >= 0 ? '+' : '';
    final pnlPercentage = pos.averagePrice != 0
        ? ((ltp - pos.averagePrice) /
            pos.averagePrice *
            100 *
            (isShort ? -1 : 1))
        : 0.0;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onBackground;
    final secondaryTextColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            pos.symbol,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color:
                                  Theme.of(context).textTheme.titleLarge?.color,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isShort)
                          Container(
                            margin: EdgeInsets.all(8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'SHORT',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${pos.quantity} shares',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${timeago.format(pos.updatedAt.toLocal())}',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // ### MODIFIED: Wrapped LTP with PulsatingEffect ###
                  Text(
                    'LTP',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  PulsatingEffect(
                    value: ltp,
                    child: Text(
                      '₹${ltp.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 14,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  DateFormat('MMM dd yyyy').format(pos.updatedAt.toLocal()),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                // const SizedBox(width: 12),
                const Spacer(),
                Icon(
                  Icons.schedule_rounded,
                  size: 14,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
                const SizedBox(width: 6),
                Text(
                  DateFormat('hh:mm a').format(pos.updatedAt.toLocal()),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                // const Spacer(),
                // Container(
                //   padding:
                //       const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                //   decoration: BoxDecoration(
                //     color: Theme.of(context)
                //         .colorScheme
                //         .secondary
                //         .withOpacity(0.1),
                //     borderRadius: BorderRadius.circular(6),
                //   ),
                //   child: Text(
                //     'Qty: ${pos.quantity}',
                //     style: GoogleFonts.inter(
                //       fontSize: 11,
                //       fontWeight: FontWeight.w600,
                //       color: Theme.of(context).colorScheme.secondary,
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Avg Price',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${pos.averagePrice.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Theme.of(context).dividerColor.withOpacity(0.3),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Icon(
                          //   pnl >= 0
                          //       ? Icons.trending_up_rounded
                          //       : Icons.trending_down_rounded,
                          //   color: pnlColor,
                          //   size: 16,
                          // ),
                          // const SizedBox(width: 4),
                          Text(
                            'P&L',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color:
                                  Theme.of(context).textTheme.bodySmall?.color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // ### MODIFIED: Wrapped P&L Column with PulsatingEffect ###
                      PulsatingEffect(
                        value: pnl,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$pnlPrefix₹${pnl.toStringAsFixed(2)}',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: pnlColor,
                              ),
                            ),
                            Text(
                              '${pnlPercentage >= 0 ? '+' : ''}${pnlPercentage.toStringAsFixed(2)}%',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: pnlColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 16,
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total value',
                    style: TextStyle(fontSize: 12, color: secondaryTextColor)),
                Text('₹${(pos.averagePrice * pos.quantity).toStringAsFixed(2)}',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTradeCard(TradeHistory trade) {
    final pnlColor = trade.profitLoss >= 0 ? Colors.green : Colors.red;
    final pnlPrefix = trade.profitLoss >= 0 ? '+' : '';
    final DateFormat dateFormatter = DateFormat('MMM dd, yyyy');
    final DateFormat timeFormatter = DateFormat('hh:mm a');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    // Container(
                    //   width: 40,
                    //   height: 40,
                    //   decoration: BoxDecoration(
                    //     color: pnlColor.withOpacity(0.15),
                    //     borderRadius: BorderRadius.circular(10),
                    //     border: Border.all(
                    //       color: pnlColor.withOpacity(0.2),
                    //     ),
                    //   ),
                    //   child: Icon(
                    //     trade.profitLoss >= 0
                    //         ? Icons.trending_up_rounded
                    //         : Icons.trending_down_rounded,
                    //     color: pnlColor,
                    //     size: 20,
                    //   ),
                    // ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trade.symbol,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color:
                                  Theme.of(context).textTheme.titleLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 12,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${trade.quantity.toInt()} shares',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.access_time_rounded,
                                size: 12,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                timeago.format(trade.executionTime),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (trade.isShortSell)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    'SHORT',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 14,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  dateFormatter.format(trade.executionTime.toLocal()),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                // const SizedBox(width: 12),
                const Spacer(),
                Icon(
                  Icons.schedule_rounded,
                  size: 14,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
                const SizedBox(width: 6),
                Text(
                  timeFormatter.format(trade.executionTime.toLocal()),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                // const Spacer(),
                // Container(
                //   padding:
                //       const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                //   decoration: BoxDecoration(
                //     color: Theme.of(context)
                //         .colorScheme
                //         .secondary
                //         .withOpacity(0.1),
                //     borderRadius: BorderRadius.circular(6),
                //   ),
                //   child: Text(
                //     'Qty: ${trade.quantity.toInt()}',
                //     style: GoogleFonts.inter(
                //       fontSize: 11,
                //       fontWeight: FontWeight.w600,
                //       color: Theme.of(context).colorScheme.secondary,
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).dividerColor.withOpacity(0.2),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        'Close Price',
                        '₹${trade.price.toStringAsFixed(2)}',
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Total Value',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color:
                                  Theme.of(context).textTheme.bodySmall?.color,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${convertToKMB((trade.price * trade.quantity).toStringAsFixed(2))}',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color:
                                  Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'P/L',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color:
                                  Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$pnlPrefix₹${convertToKMB(trade.profitLoss.toStringAsFixed(2))}',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: pnlColor,
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
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required String subtitle,
  }) {
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              size: 32,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.titleMedium?.color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateUnrealisedPnL() {
    double unrealisedPnl = 0;
    for (var holding in controller.holdings) {
      final ltp = controller.getLtp(holding.symbol);
      unrealisedPnl += (ltp - holding.averagePrice) * holding.quantity;
    }
    for (var short in controller.shortPositions) {
      final ltp = controller.getLtp(short.symbol);
      unrealisedPnl += (short.averagePrice - ltp) * short.quantity;
    }
    return unrealisedPnl;
  }

  @override
  void dispose() {
    _tabController.dispose();
    Get.delete<PortfolioController>();
    super.dispose();
  }
}

// This delegate is used to make the TabBar sticky under the header
class TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  TabBarDelegate({required this.tabBar});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: tabBar,
      ),
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height + 16;

  @override
  double get minExtent => tabBar.preferredSize.height + 16;

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
