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

// ─────────────────────────────────────────────
//  Design Tokens
// ─────────────────────────────────────────────
class _T {
  // Semantic colors
  static const profit = Color(0xFF22C55E);
  static const profitSoft = Color(0xFF16A34A);
  static const profitBg = Color(0xFFF0FDF4);
  static const profitBgDark = Color(0xFF052E16);

  static const loss = Color(0xFFEF4444);
  static const lossSoft = Color(0xFFDC2626);
  static const lossBg = Color(0xFFFFF1F2);
  static const lossBgDark = Color(0xFF4C0519);

  static const amber = Color(0xFFF59E0B);
  static const amberBg = Color(0xFFFFFBEB);
  static const amberBgDark = Color(0xFF451A03);

  static const blue = Color(0xFF3B82F6);
  static const blueBg = Color(0xFFEFF6FF);
  static const blueBgDark = Color(0xFF172554);

  // Light
  static const bgLight = Color(0xFFF5F7FA);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surface2Light = Color(0xFFF8FAFC);
  static const borderLight = Color(0xFFE8ECF0);
  static const textLight = Color(0xFF0F172A);
  static const text2Light = Color(0xFF64748B);
  static const text3Light = Color(0xFF94A3B8);

  // Dark
  static const bgDark = Color(0xFF080B12);
  static const surfaceDark = Color(0xFF111827);
  static const surface2Dark = Color(0xFF1A2030);
  static const borderDark = Color(0xFF1E2A3B);
  static const textDark = Color(0xFFF8FAFC);
  static const text2Dark = Color(0xFF94A3B8);
  static const text3Dark = Color(0xFF475569);

  // Resolvers
  static bool _dark(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark;

  static Color bg(BuildContext c) => _dark(c) ? bgDark : bgLight;
  static Color surface(BuildContext c) => _dark(c) ? surfaceDark : surfaceLight;
  static Color surface2(BuildContext c) =>
      _dark(c) ? surface2Dark : surface2Light;
  static Color border(BuildContext c) => _dark(c) ? borderDark : borderLight;
  static Color text(BuildContext c) => _dark(c) ? textDark : textLight;
  static Color text2(BuildContext c) => _dark(c) ? text2Dark : text2Light;
  static Color text3(BuildContext c) => _dark(c) ? text3Dark : text3Light;

  static Color profitBgCtx(BuildContext c) =>
      _dark(c) ? profitBgDark : profitBg;
  static Color lossBgCtx(BuildContext c) => _dark(c) ? lossBgDark : lossBg;
  static Color amberBgCtx(BuildContext c) => _dark(c) ? amberBgDark : amberBg;
  static Color blueBgCtx(BuildContext c) => _dark(c) ? blueBgDark : blueBg;
}

// ─────────────────────────────────────────────
//  Typography helpers
// ─────────────────────────────────────────────
TextStyle _caption(BuildContext c, {double size = 11, Color? color}) =>
    GoogleFonts.inter(
      fontSize: size,
      fontWeight: FontWeight.w500,
      color: color ?? _T.text2(c),
      letterSpacing: 0.2,
    );

TextStyle _body(BuildContext c,
        {double size = 13, FontWeight? weight, Color? color}) =>
    GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight ?? FontWeight.w400,
      color: color ?? _T.text(c),
    );

TextStyle _heading(BuildContext c,
        {double size = 15, FontWeight? weight, Color? color}) =>
    GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight ?? FontWeight.w600,
      color: color ?? _T.text(c),
      letterSpacing: -0.2,
    );

// ─────────────────────────────────────────────
//  Main Page
// ─────────────────────────────────────────────
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
  final Map<int, bool> _expandedTrades = {};

  @override
  void initState() {
    super.initState();
    controller = Get.put(PortfolioJournalController(suid: widget.user?.suid));
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    Get.delete<PortfolioJournalController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bg(context),
      body: widget.user != null ? _body() : SafeArea(child: _body()),
    );
  }

  Widget _body() => Obx(() => NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          SliverToBoxAdapter(child: _header()),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabDelegate(tabBar: _tabBar()),
          ),
        ],
        body: controller.isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : _tabView(),
      ));

  // ── HEADER ────────────────────────────────────
  // In PortfolioFragmentJournal class, update the _header method:

  Widget _header() {
    return GestureDetector(
      onTap: () => _showStats(),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: _T.surface(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _T.border(context), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_T._dark(context) ? 0.25 : 0.07),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Value + PnL
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Open Position', style: _caption(context, size: 12)),
                      const SizedBox(height: 5),
                      Obx(() => Text(
                            // 👈 Added Obx here
                            '₹${convertToKMB(controller.totalInvestment.value.toStringAsFixed(2))}',
                            style: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: _T.text(context),
                              letterSpacing: -1,
                            ),
                          )),
                    ],
                  ),
                ),
                Obx(() => _PnLPill(
                      // 👈 Added Obx here
                      value: controller.totalProfit.value,
                      isPositive: controller.totalProfit.value >= 0,
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── TAB BAR ───────────────────────────────────
  TabBar _tabBar() => TabBar(
        controller: _tabController,
        padding: EdgeInsets.zero,
        labelPadding: EdgeInsets.zero,
        indicatorPadding: EdgeInsets.zero,
        labelColor: Colors.white,
        unselectedLabelColor: _T.text2(context),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: _T.blue,
        ),
        labelStyle:
            GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
        unselectedLabelStyle:
            GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13),
        tabs: const [
          Tab(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart_rounded, size: 15),
                  SizedBox(width: 7),
                  Text('Positions'),
                ],
              ),
            ),
          ),
          Tab(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 15),
                  SizedBox(width: 7),
                  Text('Journal'),
                ],
              ),
            ),
          ),
        ],
      );

  // ── TAB VIEW ──────────────────────────────────
  Widget _tabView() => TabBarView(
        controller: _tabController,
        children: [
          RefreshIndicator(
            onRefresh: () async => controller.fetchAllData(),
            child: _positionsTab(),
          ),
          RefreshIndicator(
            onRefresh: () async => controller.fetchAllData(),
            child: _journalTab(),
          ),
        ],
      );

  // ── POSITIONS TAB ─────────────────────────────
  Widget _positionsTab() => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PnLBanner(
                label: 'Unrealised P&L', pnl: controller.unrealisedPnl.value),
            const SizedBox(height: 24),
            _SectionHeader(
                label: 'Long Positions',
                icon: Icons.trending_up_rounded,
                color: _T.profit),
            const SizedBox(height: 10),
            Obx(() {
              if (controller.holdings.isEmpty) {
                return _Empty(
                    icon: Icons.inbox_outlined,
                    title: 'No long positions',
                    subtitle: 'Add stocks from watchlist to get started');
              }
              return Column(
                children: controller.holdings
                    .map((h) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GestureDetector(
                            onTap: () => showExitPositionDialog(
                                context, h, controller.getLtp(h.symbol), false),
                            child: PositionCard(
                                holding: h,
                                controller: controller,
                                isShort: false),
                          ),
                        ))
                    .toList(),
              );
            }),
            const SizedBox(height: 24),
            _SectionHeader(
                label: 'Short Positions',
                icon: Icons.trending_down_rounded,
                color: _T.amber),
            const SizedBox(height: 10),
            Obx(() {
              if (controller.shortPositions.isEmpty) {
                return _Empty(
                    icon: Icons.trending_down_outlined,
                    title: 'No short positions',
                    subtitle: 'Short positions will appear here');
              }
              return Column(
                children: controller.shortPositions
                    .map((h) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GestureDetector(
                            onTap: () => showExitPositionDialog(
                                context, h, controller.getLtp(h.symbol), true),
                            child: PositionCard(
                                holding: h,
                                controller: controller,
                                isShort: true),
                          ),
                        ))
                    .toList(),
              );
            }),
          ],
        ),
      );

  // ── JOURNAL TAB ───────────────────────────────
  Widget _journalTab() => Obx(() {
        final isEmpty = controller.tradeHistory.isEmpty;
        if (isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _PnLBanner(
                    label: 'Realised P&L', pnl: controller.realisedPnl.value),
                const SizedBox(height: 10),
                _JournalFilterBar(controller: controller),
                const SizedBox(height: 30),
                Expanded(
                  child: _Empty(
                      icon: Icons.history_toggle_off_outlined,
                      title: 'No trade history',
                      subtitle: 'Closed positions will be logged here'),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          itemCount: controller.tradeHistory.length + 2,
          itemBuilder: (_, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _PnLBanner(
                    label: 'Realised P&L', pnl: controller.realisedPnl.value),
              );
            }
            if (i == 1) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _JournalFilterBar(controller: controller),
              );
            }
            final trade = controller.tradeHistory[i - 2];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _JournalCard(
                trade: trade,
                isExpanded: _expandedTrades[trade.hashCode] ?? false,
                onToggle: () => setState(() => _expandedTrades[trade.hashCode] =
                    !(_expandedTrades[trade.hashCode] ?? false)),
                onEdit: () => _editJournal(trade),
                displaySymbol: _toDisplaySymbol(trade.symbol),
              ),
            );
          },
        );
      });

  // ── STATS SHEET ───────────────────────────────
  void _showStats() {
    final total = controller.totalWins.value + controller.totalLosses.value;
    final wr = total > 0 ? controller.totalWins.value / total * 100 : 0.0;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _StatsSheet(
        totalInvestment: controller.totalInvestment.value,
        realisedPnl: controller.realisedPnl.value,
        unrealisedPnl: controller.unrealisedPnl.value,
        wins: controller.totalWins.value,
        losses: controller.totalLosses.value,
        winRate: wr,
      ),
    );
  }

  void _editJournal(JournalTradeHistory trade) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => EditJournalPage(journal: trade)));

  String _toDisplaySymbol(String s) {
    try {
      if (s.contains(':')) s = s.split(':')[1];
      if (s.contains('-')) s = s.split('-')[0];
      return s;
    } catch (_) {
      return s;
    }
  }
}

// ─────────────────────────────────────────────
//  Journal Filter Bar
// ─────────────────────────────────────────────
class _JournalFilterBar extends StatelessWidget {
  final PortfolioJournalController controller;
  const _JournalFilterBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.selectedDays.value;
      return SizedBox(
        height: 32,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.zero,
          physics: const BouncingScrollPhysics(),
          itemCount: PortfolioJournalController.filterOptions.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (context, i) {
            final opt = PortfolioJournalController.filterOptions[i];
            final isActive = selected == opt.days;
            return GestureDetector(
              onTap: () => controller.onFilterChanged(opt.days),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive ? _T.blue : _T.surface(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive ? _T.blue : _T.border(context),
                    width: 1,
                  ),
                ),
                child: Text(
                  opt.label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? Colors.white : _T.text2(context),
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────
//  Journal Card (stateless, no ripple animation)
// ─────────────────────────────────────────────
class _JournalCard extends StatelessWidget {
  final JournalTradeHistory trade;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final String displaySymbol;

  const _JournalCard({
    required this.trade,
    required this.isExpanded,
    required this.onToggle,
    required this.onEdit,
    required this.displaySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final isPnlPos = trade.profitLoss >= 0;
    final pnlColor = isPnlPos ? _T.profitSoft : _T.lossSoft;
    final pct = (trade.profitLoss / (trade.entryPrice * trade.quantity)) * 100;

    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: _T.surface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _T.border(context), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_T._dark(context) ? 0.2 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Row 1: Logo + Name + PnL ──
              Row(
                children: [
                  _Logo(symbol: displaySymbol, color: pnlColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(displaySymbol,
                            style: _heading(context,
                                size: 15, weight: FontWeight.w700)),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            _DirBadge(isShort: trade.isShortSell),
                            const SizedBox(width: 6),
                            Text(
                              '${trade.quantity} shares',
                              style: _caption(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${isPnlPos ? '+' : ''}₹${convertToKMB(trade.profitLoss.abs().toStringAsFixed(2))}',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: pnlColor,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _PctTag(pct: pct, color: pnlColor),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Row 2: Entry → Exit prices ──
              _PriceRow(
                entryPrice: trade.entryPrice,
                exitPrice: trade.exitPrice,
                pnlColor: pnlColor,
              ),
              const SizedBox(height: 10),

              // ── Row 3: Time + actions ──
              Row(
                children: [
                  Icon(Icons.access_time_rounded,
                      size: 12, color: _T.text3(context)),
                  const SizedBox(width: 4),
                  Text(
                    timeago.format(trade.exitDate),
                    style: _caption(context, size: 11),
                  ),
                  const Spacer(),
                  _ActionBtn(
                    label: 'Edit',
                    icon: Icons.edit_outlined,
                    onTap: onEdit,
                  ),
                  const SizedBox(width: 8),
                  _ChevronBtn(isExpanded: isExpanded),
                ],
              ),

              // ── Expanded details ──
              if (isExpanded) ...[
                const SizedBox(height: 14),
                Divider(height: 1, color: _T.border(context)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _InfoCell(
                        label: 'Entry Date',
                        value: DateFormat('d MMM yy, HH:mm')
                            .format(trade.entryDate),
                        icon: Icons.login_rounded,
                        color: _T.profit,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _InfoCell(
                        label: 'Exit Date',
                        value: DateFormat('d MMM yy, HH:mm')
                            .format(trade.exitDate),
                        icon: Icons.logout_rounded,
                        color: _T.loss,
                      ),
                    ),
                  ],
                ),
                if ((trade.stopLossPrice != null && trade.stopLossPrice! > 0) ||
                    (trade.targetPrice != null && trade.targetPrice! > 0)) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (trade.stopLossPrice != null &&
                          trade.stopLossPrice! > 0)
                        Expanded(
                          child: _InfoCell(
                            label: 'Stop Loss',
                            value:
                                '₹${trade.stopLossPrice!.toStringAsFixed(2)}',
                            icon: Icons.shield_outlined,
                            color: _T.loss,
                          ),
                        ),
                      if (trade.stopLossPrice != null &&
                          trade.stopLossPrice! > 0 &&
                          trade.targetPrice != null &&
                          trade.targetPrice! > 0)
                        const SizedBox(width: 10),
                      if (trade.targetPrice != null && trade.targetPrice! > 0)
                        Expanded(
                          child: _InfoCell(
                            label: 'Target',
                            value: '₹${trade.targetPrice!.toStringAsFixed(2)}',
                            icon: Icons.flag_outlined,
                            color: _T.profit,
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                _InfoCell(
                  label: 'Timeframe',
                  value: trade.timeframe,
                  icon: Icons.schedule_rounded,
                  color: _T.blue,
                ),
                if (trade.reason != null && trade.reason!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _AnalysisBlock(reason: trade.reason!),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Position Card
// ─────────────────────────────────────────────
class PositionCard extends StatefulWidget {
  final BasketUserHolding holding;
  final PortfolioJournalController controller;
  final bool isShort;
  const PositionCard({
    Key? key,
    required this.holding,
    required this.controller,
    this.isShort = false,
  }) : super(key: key);

  @override
  _PositionCardState createState() => _PositionCardState();
}

class _PositionCardState extends State<PositionCard> {
  bool _expanded = false;

  String _symbol(String s) {
    try {
      if (s.contains(':')) s = s.split(':')[1];
      if (s.contains('-')) s = s.split('-')[0];
      return s;
    } catch (_) {
      return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    final invested = widget.holding.averagePrice * widget.holding.quantity;
    final sym = _symbol(widget.holding.symbol);
    final hasSL = widget.holding.stopLossPrice != null &&
        widget.holding.targetPrice != null;

    return Obx(() {
      final ltp = widget.controller.getLtp(widget.holding.symbol);
      final pnl = (ltp - widget.holding.averagePrice) *
          widget.holding.quantity *
          (widget.isShort ? -1 : 1);
      final isPnlPos = pnl >= 0;
      final pnlColor = isPnlPos ? _T.profitSoft : _T.lossSoft;
      final pnlPct = widget.holding.averagePrice != 0
          ? ((ltp - widget.holding.averagePrice) /
              widget.holding.averagePrice *
              100 *
              (widget.isShort ? -1 : 1))
          : 0.0;

      return Container(
        decoration: BoxDecoration(
          color: _T.surface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _T.border(context), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_T._dark(context) ? 0.2 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _Logo(symbol: sym, color: pnlColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(sym,
                            style: _heading(context,
                                size: 15, weight: FontWeight.w700)),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            _DirBadge(isShort: widget.isShort),
                            const SizedBox(width: 6),
                            Text('${widget.holding.quantity} shares',
                                style: _caption(context)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      PulsatingEffect(
                        value: ltp,
                        child: Text(
                          '₹${ltp.toStringAsFixed(2)}',
                          style: _heading(context,
                              size: 16, weight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 4),
                      _ActionBtn(
                        label: 'Edit',
                        icon: Icons.edit_outlined,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                EditBasketPage(basket: widget.holding),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Metrics strip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: _T.surface2(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _T.border(context), width: 1),
                ),
                child: Row(
                  children: [
                    _MetricCell(
                        label: 'Invested',
                        value: '₹${convertToKMB(invested.toStringAsFixed(2))}',
                        color: _T.text(context)),
                    _Vline(),
                    _MetricCell(
                        label: 'Avg Price',
                        value:
                            '₹${widget.holding.averagePrice.toStringAsFixed(2)}',
                        color: _T.text(context),
                        align: CrossAxisAlignment.center),
                    _Vline(),
                    _MetricCell(
                      label:
                          '${isPnlPos ? '+' : ''}${pnlPct.toStringAsFixed(1)}%',
                      value:
                          '${isPnlPos ? '+' : ''}₹${convertToKMB(pnl.toStringAsFixed(2))}',
                      color: pnlColor,
                      align: CrossAxisAlignment.end,
                    ),
                  ],
                ),
              ),

              if (hasSL) ...[
                const SizedBox(height: 10),
                _ProgressBar(
                  sl: widget.holding.stopLossPrice!,
                  target: widget.holding.targetPrice!,
                  ltp: ltp,
                  isShort: widget.isShort,
                ),
              ],

              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    Icon(Icons.access_time_rounded,
                        size: 12, color: _T.text3(context)),
                    const SizedBox(width: 4),
                    Text(timeago.format(widget.holding.entryDate),
                        style: _caption(context, size: 11)),
                    const Spacer(),
                    if (widget.holding.reason != null &&
                        widget.holding.reason!.isNotEmpty)
                      GestureDetector(
                        onTap: () => setState(() => _expanded = !_expanded),
                        child: _ChevronBtn(isExpanded: _expanded),
                      ),
                  ],
                ),
              ),

              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                child: _expanded &&
                        widget.holding.reason != null &&
                        widget.holding.reason!.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: _AnalysisBlock(reason: widget.holding.reason!),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _PnLPill extends StatelessWidget {
  final double value;
  final bool isPositive;
  const _PnLPill({required this.value, required this.isPositive});
  @override
  Widget build(BuildContext context) {
    final color = isPositive ? _T.profitSoft : _T.lossSoft;
    final bg = isPositive ? _T.profitBgCtx(context) : _T.lossBgCtx(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Builder(builder: (context) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('Total P&L', style: _caption(context, size: 10, color: color)),
            const SizedBox(height: 3),
            PulsatingEffect(
              value: value,
              child: Text(
                '${isPositive ? '+' : ''}₹${convertToKMB(value.toStringAsFixed(2))}',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _Vline extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(height: 26, width: 1, color: _T.border(context));
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _SectionHeader(
      {required this.label, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 8),
          Text(label,
              style: _heading(context, size: 15, weight: FontWeight.w600)),
        ],
      );
}

class _PnLBanner extends StatelessWidget {
  final String label;
  final double pnl;
  const _PnLBanner({required this.label, required this.pnl});
  @override
  Widget build(BuildContext context) {
    final isPos = pnl >= 0;
    final color = isPos ? _T.profitSoft : _T.lossSoft;
    final bg = isPos ? _T.profitBgCtx(context) : _T.lossBgCtx(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: _T.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _T.border(context), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: _body(context, size: 14, weight: FontWeight.w600)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(9),
            ),
            child: PulsatingEffect(
              value: pnl,
              child: Text(
                '${isPos ? '+' : ''}₹${convertToKMB(pnl.toStringAsFixed(2))}',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  final String symbol;
  final Color color;
  const _Logo({required this.symbol, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: CachedNetworkImage(
            imageUrl: '${Constants.OptionXiS3Loc}$symbol.png',
            fit: BoxFit.cover,
            placeholder: (_, __) => _LogoFallback(),
            errorWidget: (_, __, ___) => _LogoFallback(),
          ),
        ),
      );
}

class _LogoFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        color: _T.surface2(context),
        child: Icon(Icons.candlestick_chart_rounded,
            size: 18, color: _T.text3(context)),
      );
}

class _DirBadge extends StatelessWidget {
  final bool isShort;
  const _DirBadge({required this.isShort});
  @override
  Widget build(BuildContext context) {
    final color = isShort ? _T.amber : _T.profit;
    final bg = isShort ? _T.amberBgCtx(context) : _T.profitBgCtx(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isShort ? 'SHORT' : 'LONG',
        style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.3),
      ),
    );
  }
}

class _PctTag extends StatelessWidget {
  final double pct;
  final Color color;
  const _PctTag({required this.pct, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(2)}%',
          style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w700, color: color),
        ),
      );
}

class _PriceRow extends StatelessWidget {
  final double entryPrice, exitPrice;
  final Color pnlColor;
  const _PriceRow(
      {required this.entryPrice,
      required this.exitPrice,
      required this.pnlColor});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: _T.surface2(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _T.border(context), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Entry on left
            _PriceLabel(
                label: 'Entry',
                value: '₹${entryPrice.toStringAsFixed(2)}',
                color: _T.profit),

            // Arrow in the middle
            Icon(Icons.arrow_forward_rounded,
                size: 13, color: _T.text3(context)),

            // Exit on right end
            _PriceLabel(
                label: 'Exit',
                value: '₹${exitPrice.toStringAsFixed(2)}',
                color: pnlColor),
          ],
        ),
      );
}

class _PriceLabel extends StatelessWidget {
  final String label, value;
  final Color color;
  const _PriceLabel(
      {required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: _caption(context, size: 10, color: color)),
          const SizedBox(height: 2),
          Text(value, style: _body(context, size: 13, weight: FontWeight.w600)),
        ],
      );
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.label, required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _T.blueBgCtx(context),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _T.blue.withOpacity(0.2), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: _T.blue),
              const SizedBox(width: 4),
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _T.blue)),
            ],
          ),
        ),
      );
}

class _ChevronBtn extends StatelessWidget {
  final bool isExpanded;
  const _ChevronBtn({required this.isExpanded});
  @override
  Widget build(BuildContext context) => Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: _T.surface2(context),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: _T.border(context), width: 1),
        ),
        child: Icon(
          isExpanded
              ? Icons.keyboard_arrow_up_rounded
              : Icons.keyboard_arrow_down_rounded,
          size: 16,
          color: _T.text2(context),
        ),
      );
}

class _InfoCell extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _InfoCell(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: _T.surface2(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.12), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 28,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: _caption(context, size: 10)),
                  const SizedBox(height: 2),
                  Text(value,
                      style: _body(context, size: 12, weight: FontWeight.w600)),
                ],
              ),
            ),
            Icon(icon, size: 14, color: color.withOpacity(0.5)),
          ],
        ),
      );
}

class _AnalysisBlock extends StatelessWidget {
  final String reason;
  const _AnalysisBlock({required this.reason});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _T.blueBgCtx(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _T.blue.withOpacity(0.12), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology_outlined, size: 13, color: _T.blue),
                const SizedBox(width: 5),
                Text('Analysis',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _T.blue)),
              ],
            ),
            const SizedBox(height: 7),
            Text(reason,
                style: _body(context, size: 13).copyWith(height: 1.55)),
          ],
        ),
      );
}

class _MetricCell extends StatelessWidget {
  final String label, value;
  final Color color;
  final CrossAxisAlignment align;
  const _MetricCell({
    required this.label,
    required this.value,
    required this.color,
    this.align = CrossAxisAlignment.start,
  });
  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          crossAxisAlignment: align,
          children: [
            Text(label, style: _caption(context, size: 10)),
            const SizedBox(height: 3),
            Text(value,
                style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      );
}

class _Empty extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  const _Empty(
      {required this.icon, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Container(
        height: 180,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _T.surface2(context),
                shape: BoxShape.circle,
                border: Border.all(color: _T.border(context), width: 1),
              ),
              child: Icon(icon, size: 24, color: _T.text3(context)),
            ),
            const SizedBox(height: 12),
            Text(title,
                style: _heading(context, size: 14, weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: _caption(context, size: 12),
                textAlign: TextAlign.center),
          ],
        ),
      );
}

// ─────────────────────────────────────────────
//  Progress Bar
// ─────────────────────────────────────────────
class _ProgressBar extends StatelessWidget {
  final double sl, target, ltp;
  final bool isShort;
  const _ProgressBar(
      {required this.sl,
      required this.target,
      required this.ltp,
      required this.isShort});

  @override
  Widget build(BuildContext context) {
    final effectiveMin = isShort ? target : sl;
    final effectiveMax = isShort ? sl : target;
    final range = (effectiveMax - effectiveMin).abs();
    final raw = range > 0 ? (ltp - effectiveMin) / range : 0.0;
    final pos = raw.clamp(0.0, 1.0);

    String label;
    Color color;
    if (isShort) {
      if (ltp >= sl) {
        label = 'SL Hit';
        color = _T.loss;
      } else if (ltp <= target) {
        label = 'Target Hit';
        color = _T.profit;
      } else if (pos <= 0.25) {
        label = 'Near Target';
        color = _T.profit;
      } else if (pos >= 0.75) {
        label = 'Near SL';
        color = _T.loss;
      } else {
        label = 'In Range';
        color = _T.blue;
      }
    } else {
      if (ltp <= sl) {
        label = 'SL Hit';
        color = _T.loss;
      } else if (ltp >= target) {
        label = 'Target Hit';
        color = _T.profit;
      } else if (pos >= 0.75) {
        label = 'Near Target';
        color = _T.profit;
      } else if (pos <= 0.25) {
        label = 'Near SL';
        color = _T.loss;
      } else {
        label = 'In Range';
        color = _T.blue;
      }
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.12), width: 1),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Progress', style: _caption(context, size: 10)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: color)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 5,
              child: Stack(
                children: [
                  Container(color: color.withOpacity(0.1)),
                  FractionallySizedBox(
                    widthFactor: pos,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 7),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('SL ₹${sl.toStringAsFixed(2)}',
                  style: _caption(context, size: 10, color: _T.loss)),
              Text('LTP ₹${ltp.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                      fontSize: 10, fontWeight: FontWeight.w700, color: color)),
              Text('TGT ₹${target.toStringAsFixed(2)}',
                  style: _caption(context, size: 10, color: _T.profit)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Stats Bottom Sheet
// ─────────────────────────────────────────────
class _StatsSheet extends StatelessWidget {
  final double totalInvestment, realisedPnl, unrealisedPnl, winRate;
  final int wins, losses;
  const _StatsSheet({
    required this.totalInvestment,
    required this.realisedPnl,
    required this.unrealisedPnl,
    required this.wins,
    required this.losses,
    required this.winRate,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 36),
        decoration: BoxDecoration(
          color: _T.surface(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          border: Border(top: BorderSide(color: _T.border(context), width: 1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 32,
                height: 3,
                decoration: BoxDecoration(
                  color: _T.border(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text('Performance',
                style: _heading(context, size: 19, weight: FontWeight.w700)),
            const SizedBox(height: 18),
            _SheetTile(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Portfolio Value',
              value: '₹${convertToKMB(totalInvestment.toStringAsFixed(2))}',
              color: _T.blue,
            ),
            Divider(height: 24, color: _T.border(context)),
            _SheetTile(
              icon: Icons.check_circle_outline,
              label: 'Realised P&L',
              value: '₹${convertToKMB(realisedPnl.toStringAsFixed(2))}',
              color: realisedPnl >= 0 ? _T.profit : _T.loss,
              colored: true,
            ),
            const SizedBox(height: 12),
            _SheetTile(
              icon: Icons.hourglass_bottom_rounded,
              label: 'Unrealised P&L',
              value: '₹${convertToKMB(unrealisedPnl.toStringAsFixed(2))}',
              color: unrealisedPnl >= 0 ? _T.profit : _T.loss,
              colored: true,
            ),
            Divider(height: 24, color: _T.border(context)),
            Row(
              children: [
                Expanded(
                    child: _SheetBox(
                        label: 'Wins',
                        value: '$wins',
                        color: _T.profit,
                        bg: _T.profitBgCtx(context))),
                const SizedBox(width: 10),
                Expanded(
                    child: _SheetBox(
                        label: 'Losses',
                        value: '$losses',
                        color: _T.loss,
                        bg: _T.lossBgCtx(context))),
                const SizedBox(width: 10),
                Expanded(
                    child: _SheetBox(
                        label: 'Win Rate',
                        value: '${winRate.toStringAsFixed(1)}%',
                        color: _T.blue,
                        bg: _T.blueBgCtx(context))),
              ],
            ),
          ],
        ),
      );
}

class _SheetTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  final bool colored;
  const _SheetTile(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color,
      this.colored = false});
  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Text(label, style: _body(context, size: 14, weight: FontWeight.w500)),
          const Spacer(),
          Text(value,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: colored ? color : _T.text(context),
              )),
        ],
      );
}

class _SheetBox extends StatelessWidget {
  final String label, value;
  final Color color, bg;
  const _SheetBox(
      {required this.label,
      required this.value,
      required this.color,
      required this.bg});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value,
                style: GoogleFonts.inter(
                    fontSize: 19, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 3),
            Text(label, style: _caption(context, size: 10)),
          ],
        ),
      );
}

// ─────────────────────────────────────────────
//  Tab Delegate
// ─────────────────────────────────────────────
class _TabDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _TabDelegate({required this.tabBar});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool _) => Container(
        color: _T.bg(context),
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
        child: Container(
          decoration: BoxDecoration(
            color: _T.surface(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _T.border(context), width: 1),
          ),
          padding: const EdgeInsets.all(4),
          child: tabBar,
        ),
      );

  @override
  double get maxExtent => tabBar.preferredSize.height + 20;
  @override
  double get minExtent => tabBar.preferredSize.height + 20;
  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate _) => false;
}

// ─────────────────────────────────────────────
//  Exit dialog (unchanged signature)
// ─────────────────────────────────────────────
Future<bool?> showExitPositionDialog(
  BuildContext context,
  BasketUserHolding userholding,
  double currentLtp,
  bool isshort,
) =>
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExitPositionDialog(
        userholding: userholding,
        currentLtp: currentLtp,
        isshort: isshort,
      ),
    );
