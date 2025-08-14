import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:optionxi/Helpers/constants.dart';
import 'package:optionxi/Helpers/conversions.dart';
import 'package:optionxi/Main_Pages/act_leaderboard.dart';
import 'package:optionxi/VirtualTradeJournal/bottom_exit_position_dialog.dart';
import 'package:optionxi/VirtualTradeJournal/edit_basket_page.dart';
import 'package:optionxi/VirtualTradeJournal/edit_journal_page.dart';
import 'package:optionxi/VirtualTradeJournal/portfolio_journal_controller.dart';
import 'package:optionxi/VirtualTrading/VComponents/cust_pulsating_effect.dart';
import 'package:optionxi/VirtualTrading/VDataModel/v_holdings_journal.dart';
import 'package:optionxi/VirtualTrading/VDataModel/v_tradehistory.dart';
import 'package:timeago/timeago.dart' as timeago;

class PortfolioFragmentJournal extends StatefulWidget {
  final LeaderboardEntry? user;
  const PortfolioFragmentJournal(this.user, {Key? key}) : super(key: key);

  @override
  State<PortfolioFragmentJournal> createState() =>
      _PortfolioFragmentJournalState();
}

class _PortfolioFragmentJournalState extends State<PortfolioFragmentJournal>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late PortfolioJournalController controller;

  // State to manage the expansion of the reason text in trade cards
  final Map<int, bool> _isTradeCardExpanded = {};

  @override
  void initState() {
    super.initState();
    controller = Get.put(PortfolioJournalController(suid: widget.user?.suid));
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
                // ### MODIFIED: Wrapped stats card in GestureDetector to make it clickable ###
                GestureDetector(
                  onTap: () => _showStatisticsBottomSheet(context),
                  child: _buildCollapsibleStats(),
                ),
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
            ? const Center(child: CircularProgressIndicator())
            : _buildTabBarView(),
      );
    });
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Virtual Basket',
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
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'LIVE',
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
                        'Portfolio',
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
                    PulsatingEffect(
                      value: controller.totalProfit.value,
                      child: Text(
                        '₹${convertToKMB(controller.totalProfit.value.toStringAsFixed(2))}',
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
                const SizedBox(width: 16),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primary.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: Icon(
                      Icons.info,
                      size: 20,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
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
      tabs: const [
        Tab(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.autorenew, size: 18),
                SizedBox(width: 8),
                Text('Portfolio'),
              ],
            ),
          ),
        ),
        Tab(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 18),
                SizedBox(width: 8),
                Text('Journal'),
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
            onRefresh: () async => controller.fetchAllData(),
            child: _buildUnrealisedTab()),
        RefreshIndicator(
            onRefresh: () async => controller.fetchAllData(),
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
                message: 'No basket holdings yet',
                subtitle: 'Add stock from watchlist',
              );
            }
            return ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: controller.holdings
                  .map((longholding) => InkWell(
                        onTap: () => showExitPositionDialog(
                            context,
                            longholding,
                            controller.getLtp(longholding.symbol),
                            false),
                        child: ModernPositionCard(
                            userholding: longholding,
                            controller: controller,
                            isShort: false),
                      ))
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
                  .map((shortholding) => InkWell(
                        onTap: () => showExitPositionDialog(
                            context,
                            shortholding,
                            controller.getLtp(shortholding.symbol),
                            true),
                        child: ModernPositionCard(
                            userholding: shortholding,
                            controller: controller,
                            isShort: true),
                      ))
                  .toList(),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildUnrealisedStats() {
    final unrealisedPnl = controller.unrealisedPnl.value;
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
          PulsatingEffect(
            value: unrealisedPnl,
            child: Text(
              '${unrealisedPnl >= 0 ? '+' : ''}₹${convertToKMB(unrealisedPnl.toStringAsFixed(2))}',
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
                  message: 'No journal history',
                  subtitle: 'Your exited journal entries will appear here',
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
          // Use a unique identifier for the trade if available, otherwise use index.
          final tradeId = trade.hashCode;
          return _buildModernTradeCard(trade, tradeId);
        },
      );
    });
  }

  Widget _buildRealisedStats() {
    final realisedPnl = controller.realisedPnl.value;
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
          PulsatingEffect(
            value: realisedPnl,
            child: Text(
              '${realisedPnl >= 0 ? '+' : ''}₹${convertToKMB(realisedPnl.toStringAsFixed(2))}',
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

  // ### NEW: Helper function to get a clean display symbol for the logo URL ###
  String _getDisplaySymbol(String symbol) {
    // Tries to extract the base symbol (e.g., "RELIANCE" from "NSE:RELIANCE-EQ")
    try {
      if (symbol.contains(':')) {
        symbol = symbol.split(':')[1];
      }
      if (symbol.contains('-')) {
        symbol = symbol.split('-')[0];
      }
      return symbol;
    } catch (e) {
      return symbol; // Fallback to original symbol on parsing error
    }
  }

  Widget _buildModernTradeCard(JournalTradeHistory trade, int tradeId) {
    final theme = Theme.of(context);
    final isExpanded = _isTradeCardExpanded[tradeId] ?? false;
    final isProfitable = trade.profitLoss >= 0;
    final profitColor =
        isProfitable ? const Color(0xFF00C896) : const Color(0xFFFF4757);

    // Calculate percentage
    final percentage =
        ((trade.profitLoss / (trade.entryPrice * trade.quantity)) * 100);
    final exitTime = DateFormat('h:mm a').format(trade.exitDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () =>
              setState(() => _isTradeCardExpanded[tradeId] = !isExpanded),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Main trade info row
                Row(
                  children: [
                    // Stock icon with colored border
                    Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: profitColor.withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                          imageUrl:
                              "${Constants.OptionXiS3Loc}${_getDisplaySymbol(trade.symbol)}.png",
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: theme.colorScheme.surfaceVariant,
                            child: Icon(
                              Icons.candlestick_chart_rounded,
                              size: 20,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: theme.colorScheme.surfaceVariant,
                            child: Icon(
                              Icons.candlestick_chart_rounded,
                              size: 20,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Stock name and quantity
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getDisplaySymbol(trade.symbol),
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: theme.textTheme.titleLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${trade.quantity} shares',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // P&L and percentage (right aligned)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isProfitable
                                  ? Icons.arrow_drop_up
                                  : Icons.arrow_drop_down,
                              color: profitColor,
                              size: 20,
                            ),
                            Text(
                              '₹${convertToKMB(trade.profitLoss.abs().toStringAsFixed(2))}',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: profitColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: profitColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${isProfitable ? '+' : ''}${percentage.toStringAsFixed(2)}%',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: profitColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Secondary info row
                Row(
                  children: [
                    // Exit price with icon
                    Row(
                      children: [
                        Icon(
                          Icons.exit_to_app,
                          size: 16,
                          color: theme.textTheme.bodyMedium?.color
                              ?.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '₹${trade.exitPrice.toStringAsFixed(2)}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ],
                    ),

                    // Spacer
                    const SizedBox(width: 24),

                    // Exit time
                    Text(
                      exitTime,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),

                    const Spacer(),

                    // Time ago
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: theme.textTheme.bodyMedium?.color
                              ?.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timeago.format(trade.exitDate),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(
                  height: 16,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left: LONG/SHORT label
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (trade.isShortSell
                            ? Colors.orange.withOpacity(0.1)
                            : Colors.green.withOpacity(0.1)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        trade.isShortSell ? 'SHORT' : 'LONG',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: trade.isShortSell
                              ? Colors.orange.shade700
                              : Colors.green.shade700,
                        ),
                      ),
                    ),

                    // Right: Edit Journal button
                    InkWell(
                      onTap: () {
                        _editJournal(trade);
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.blue.shade200,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.edit,
                              size: 16,
                              color: Colors.blue.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Edit Journal Entry',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Show More button
                if (!isExpanded) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    height: 36,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.2),
                        width: 0.5,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => setState(
                            () => _isTradeCardExpanded[tradeId] = true),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Show More',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],

                // Expanded content with detailed information
                if (isExpanded) ...[
                  const SizedBox(height: 16),
                  Container(
                    height: 0.5,
                    color: theme.dividerColor.withOpacity(0.2),
                  ),
                  const SizedBox(height: 16),

                  // Buy and Sell Prices
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailItem(
                          'Buy Price',
                          '₹${trade.entryPrice.toStringAsFixed(2)}',
                          Colors.green.shade600,
                          Icons.call_made,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDetailItem(
                          'Sell Price',
                          '₹${trade.exitPrice.toStringAsFixed(2)}',
                          Colors.red.shade600,
                          Icons.call_received,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // SL and Target row
                  if ((trade.stopLossPrice != null &&
                          trade.stopLossPrice! > 0) ||
                      (trade.targetPrice != null &&
                          trade.targetPrice! > 0)) ...[
                    Row(
                      children: [
                        if (trade.stopLossPrice != null &&
                            trade.stopLossPrice! > 0) ...[
                          Expanded(
                            child: _buildDetailItem(
                              'Stop Loss',
                              '₹${trade.stopLossPrice!.toStringAsFixed(2)}',
                              Colors.red.shade500,
                              Icons.shield_outlined,
                            ),
                          ),
                          if (trade.targetPrice != null &&
                              trade.targetPrice! > 0)
                            const SizedBox(width: 16),
                        ],
                        if (trade.targetPrice != null &&
                            trade.targetPrice! > 0) ...[
                          Expanded(
                            child: _buildDetailItem(
                              'Target',
                              '₹${trade.targetPrice!.toStringAsFixed(2)}',
                              Colors.green.shade600,
                              Icons.flag_outlined,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Date and time information
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailItem(
                          'Entry Date',
                          _formatDateTime(trade.entryDate),
                          theme.colorScheme.primary,
                          Icons.login,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDetailItem(
                          'Exit Date',
                          _formatDateTime(trade.exitDate),
                          theme.colorScheme.secondary,
                          Icons.logout,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Timeframe
                  _buildDetailItem(
                    'Timeframe',
                    trade.timeframe,
                    theme.textTheme.bodyMedium?.color ?? Colors.grey,
                    Icons.schedule,
                  ),

                  // Analysis section
                  if (trade.reason != null && trade.reason!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            theme.colorScheme.surfaceVariant.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.psychology_outlined,
                                size: 16,
                                color: theme.textTheme.bodyMedium?.color,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Analysis',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: theme.textTheme.bodyMedium?.color,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            trade.reason!,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              height: 1.4,
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Show Less button
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    height: 36,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => setState(
                            () => _isTradeCardExpanded[tradeId] = false),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.expand_less,
                              size: 16,
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Show Less',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: theme.textTheme.bodyMedium?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],

                // Expand/Collapse indicator
                if (!isExpanded) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _editJournal(JournalTradeHistory trade) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditJournalPage(journal: trade),
      ),
    );
  }

// Helper function to format date time
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year.toString().substring(2)} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

// Helper widget for detail items
  Widget _buildDetailItem(
      String label, String value, Color color, IconData icon) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: color.withOpacity(0.7),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ### NEW: Function to show the statistics bottom sheet ###
  void _showStatisticsBottomSheet(BuildContext context) {
    final theme = Theme.of(context);
    final totalTrades =
        controller.totalWins.value + controller.totalLosses.value;
    final winRatio = totalTrades > 0
        ? (controller.totalWins.value / totalTrades) * 100
        : 0.0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            border: Border(
              top: BorderSide(
                color: theme.dividerColor.withOpacity(0.5),
                width: 1.5,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Performance Stats',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 24),
              _buildStatRow(
                Icons.account_balance_wallet_outlined,
                'Portfolio',
                '₹${convertToKMB(controller.totalInvestment.value.toStringAsFixed(2))}',
                theme.colorScheme.primary,
              ),
              const Divider(height: 32),
              _buildStatRow(
                Icons.check_circle_outline,
                'Realised P&L',
                '₹${convertToKMB(controller.realisedPnl.value.toStringAsFixed(2))}',
                controller.realisedPnl.value >= 0 ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 16),
              _buildStatRow(
                Icons.hourglass_empty_rounded,
                'Unrealised P&L',
                '₹${convertToKMB(controller.unrealisedPnl.value.toStringAsFixed(2))}',
                controller.unrealisedPnl.value >= 0 ? Colors.green : Colors.red,
              ),
              const Divider(height: 32),
              _buildStatRow(
                Icons.trending_up,
                'Total Wins',
                '${controller.totalWins.value}',
                Colors.green.shade400,
              ),
              const SizedBox(height: 16),
              _buildStatRow(
                Icons.trending_down,
                'Total Losses',
                '${controller.totalLosses.value}',
                Colors.red.shade400,
              ),
              const SizedBox(height: 16),
              _buildStatRow(
                Icons.pie_chart_outline_rounded,
                'Win / Loss Ratio',
                '${winRatio.toStringAsFixed(1)}%',
                theme.colorScheme.secondary,
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value, Color color) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 16),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: theme.textTheme.bodyMedium?.color,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    Get.delete<PortfolioJournalController>();
    super.dispose();
  }
}

// ... (ModernPositionCard, TabBarDelegate, showExitPositionDialog, and Data Models remain the same)
// NOTE: Make sure the controller and data models support all the required fields.

class ModernPositionCard extends StatefulWidget {
  final BasketUserHolding userholding;
  final PortfolioJournalController controller;
  final bool isShort;

  const ModernPositionCard({
    Key? key,
    required this.userholding,
    required this.controller,
    this.isShort = false,
  }) : super(key: key);

  @override
  _ModernPositionCardState createState() => _ModernPositionCardState();
}

class _ModernPositionCardState extends State<ModernPositionCard> {
  bool _isExpanded = false;

  Widget _buildProgressBar(
    String title,
    double min,
    double max,
    double current,
    String minLabel,
    String maxLabel,
  ) {
    final isShort = widget.isShort;
    final effectiveMin = isShort ? max : min;
    final effectiveMax = isShort ? min : max;

    final range = (effectiveMax - effectiveMin).abs();
    final position = range > 0
        ? (current - effectiveMin) / (effectiveMax - effectiveMin)
        : 0.0;
    final clampedPosition = position.clamp(0.0, 1.0);

    String positionText;
    Color color;

    if (isShort) {
      if (current >= effectiveMax) {
        positionText = 'SL Hit';
        color = Colors.red.shade400;
      } else if (current <= effectiveMin) {
        positionText = 'Target Hit';
        color = Colors.green.shade400;
      } else if (clampedPosition <= 0.2) {
        positionText = 'Near Target';
        color = Colors.green.shade400;
      } else if (clampedPosition >= 0.8) {
        positionText = 'Near SL';
        color = Colors.red.shade400;
      } else {
        positionText = 'In Range';
        color = Colors.blue.shade400;
      }
    } else {
      // For long positions
      if (current <= effectiveMin) {
        positionText = 'SL Hit';
        color = Colors.red.shade400;
      } else if (current >= effectiveMax) {
        positionText = 'Target Hit';
        color = Colors.green.shade400;
      } else if (clampedPosition >= 0.8) {
        positionText = 'Near Target';
        color = Colors.green.shade400;
      } else if (clampedPosition <= 0.2) {
        positionText = 'Near SL';
        color = Colors.red.shade400;
      } else {
        positionText = 'In Range';
        color = Colors.blue.shade400;
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color.withOpacity(0.8),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'LTP: ₹${current.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color.withOpacity(0.9),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 8,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: clampedPosition,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment(clampedPosition * 2 - 1, 0),
                  child: Container(
                    width: 4,
                    height: 12,
                    decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.7), width: 1)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                minLabel,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  positionText,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color.withOpacity(0.8),
                  ),
                ),
              ),
              Text(
                maxLabel,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
      String title, String value, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey.shade800.withOpacity(0.3)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedSLTargetInfo() {
    List<Widget> cards = [];

    final slPrice = widget.userholding.stopLossPrice;
    if (slPrice != null) {
      cards.add(
        _buildInfoCard(
          'Stop-Loss Price',
          '₹${slPrice.toStringAsFixed(2)}',
          'Position will be exited to limit loss',
          Colors.red.shade400,
        ),
      );
    }

    final targetPrice = widget.userholding.targetPrice;
    if (targetPrice != null) {
      cards.add(
        Padding(
          padding: EdgeInsets.only(top: slPrice != null ? 8.0 : 0),
          child: _buildInfoCard(
            'Target Price',
            '₹${targetPrice.toStringAsFixed(2)}',
            'Position will be exited to book profit',
            Colors.green.shade400,
          ),
        ),
      );
    }

    if (cards.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(children: cards);
  }

  String _getDisplaySymbol(String symbol) {
    try {
      if (symbol.contains(':')) {
        symbol = symbol.split(':')[1];
      }
      if (symbol.contains('-')) {
        symbol = symbol.split('-')[0];
      }
      return symbol;
    } catch (e) {
      return symbol;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ltp = widget.controller.getLtp(widget.userholding.symbol);
    final pnl = (ltp - widget.userholding.averagePrice) *
        widget.userholding.quantity *
        (widget.isShort ? -1 : 1);
    final pnlColor = pnl >= 0 ? Colors.green : Colors.red;
    final pnlPrefix = pnl >= 0 ? '+' : '';
    final pnlPercentage = widget.userholding.averagePrice != 0
        ? ((ltp - widget.userholding.averagePrice) /
            widget.userholding.averagePrice *
            100 *
            (widget.isShort ? -1 : 1))
        : 0.0;

    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color;
    final secondaryTextColor = theme.textTheme.bodySmall?.color;
    final hasSlAndTarget = widget.userholding.stopLossPrice != null &&
        widget.userholding.targetPrice != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    height: 48,
                    width: 48,
                    imageUrl:
                        "${Constants.OptionXiS3Loc}${_getDisplaySymbol(widget.userholding.symbol)}.png",
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Image.asset(
                      'assets/images/stockdefault.png',
                      fit: BoxFit.cover,
                    ),
                    errorWidget: (context, url, error) => Image.asset(
                      'assets/images/stockdefault.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getDisplaySymbol(widget.userholding.symbol),
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: theme.textTheme.titleLarge?.color,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${widget.userholding.quantity} shares',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.7),
                          ),
                        ),
                        if (widget.isShort) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
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
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const SizedBox(height: 2),
                  PulsatingEffect(
                    value: ltp,
                    child: Text(
                      '₹${ltp.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  Container(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _editBasket,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.blue.shade200,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.edit,
                                size: 16,
                                color: Colors.blue.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Edit Basket',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Secondary info row
          Row(
            children: [
              // Exit price with icon
              Row(
                children: [
                  Icon(
                    Icons.exit_to_app,
                    size: 16,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Entry: ₹${widget.userholding.entryPrice.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),

              // Spacer
              const SizedBox(width: 24),

              const Spacer(),

              // Time ago
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    timeago.format(widget.userholding.entryDate),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color:
                          theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMetricItem(
                  'Invested',
                  '₹${convertToKMB((widget.userholding.averagePrice * widget.userholding.quantity).toStringAsFixed(2))}',
                  crossAxisAlignment: CrossAxisAlignment.start,
                ),
                _buildMetricItem(
                  '$pnlPrefix₹${convertToKMB(pnl.toStringAsFixed(2))} ',
                  '${pnlPercentage.toStringAsFixed(1)}%',
                  valueColor: pnlColor,
                  crossAxisAlignment: CrossAxisAlignment.end,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (hasSlAndTarget) ...[
            _buildProgressBar(
              'Trade Progress',
              widget.userholding.stopLossPrice!,
              widget.userholding.targetPrice!,
              ltp,
              'SL: ₹${widget.userholding.stopLossPrice!.toStringAsFixed(2)}',
              'TGT: ₹${widget.userholding.targetPrice!.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 16),
          ],
          if (widget.userholding.reason != null &&
              widget.userholding.reason!.isNotEmpty)
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isExpanded) ...[
                    const Divider(height: 24),
                    if (hasSlAndTarget) ...[
                      _buildDetailedSLTargetInfo(),
                      const SizedBox(height: 16),
                    ],
                    Text(
                      'Analysis / Reason',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.userholding.reason!,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: secondaryTextColor,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Center(
                    child: TextButton.icon(
                      icon: Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 20,
                      ),
                      label: Text(_isExpanded ? 'View Less' : 'View More'),
                      onPressed: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        textStyle: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _editBasket() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditBasketPage(basket: widget.userholding),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value,
      {Color? valueColor, required CrossAxisAlignment crossAxisAlignment}) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: valueColor ?? Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ],
    );
  }
}

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
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) => false;
}

Future<bool?> showExitPositionDialog(
  BuildContext context,
  BasketUserHolding userholding,
  double currentLtp,
  bool isshort,
) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ExitPositionDialog(
        userholding: userholding, currentLtp: currentLtp, isshort: isshort),
  );
}
