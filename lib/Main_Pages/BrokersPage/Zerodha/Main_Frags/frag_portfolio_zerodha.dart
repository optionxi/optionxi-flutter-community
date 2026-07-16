import 'package:flutter/material.dart';
import 'package:optionxi/Main_Pages/BrokersPage/OrderPage/act_buy_sell_live_zerodha.dart';
import 'package:optionxi/Main_Pages/BrokersPage/Zerodha/error_state.dart';
import 'package:optionxi/Main_Pages/BrokersPage/Zerodha/utils/zerodha_controller.dart';
import 'package:optionxi/Main_Pages/BrokersPage/Zerodha/utils/zerodha_datamodel.dart';

// ─────────────────────────────────────────────────────────────
//  Portfolio Page — Zerodha
//  Changes from original:
//    • EnhancedHoldingCard: "Buy More" + "Sell" action buttons
//    • PositionCard: "Add" + "Exit" action buttons
//    • Both navigate to ZerodhaOrderPage with pre-filled stock/side
// ─────────────────────────────────────────────────────────────

class PortfolioPageZerodha extends StatefulWidget {
  const PortfolioPageZerodha({Key? key}) : super(key: key);

  @override
  State<PortfolioPageZerodha> createState() => _PortfolioPageZerodhaState();
}

class _PortfolioPageZerodhaState extends State<PortfolioPageZerodha>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Custom Tab Bar (unchanged)
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: isDark ? Colors.blue[600] : Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: Colors.white,
                unselectedLabelColor:
                    isDark ? Colors.grey[400] : Colors.grey[600],
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Holdings'),
                  Tab(text: 'Positions'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  HoldingsTab(),
                  PositionsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Navigation helper — shared by both tabs
// ─────────────────────────────────────────────────────────────

Future<void> _openOrderPage(
  BuildContext context, {
  required String symbol,
  required String segment,
  required bool tosell,
}) async {
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ZerodhaOrderPage(
        stockname: symbol,
        segment: segment,
        tosell: tosell,
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────
//  Holdings Tab  (unchanged logic, updated card)
// ─────────────────────────────────────────────────────────────

class HoldingsTab extends StatefulWidget {
  const HoldingsTab({Key? key}) : super(key: key);

  @override
  State<HoldingsTab> createState() => _HoldingsTabState();
}

class _HoldingsTabState extends State<HoldingsTab>
    with SingleTickerProviderStateMixin {
  Future<List<HoldingModel>>? _holdingsFuture;
  final ZerodhaRepository _repository = ZerodhaRepository();
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _holdingsFuture = _repository.getHoldings();
    _setupShimmerAnimation();
  }

  void _setupShimmerAnimation() {
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
    _shimmerController.repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _refreshHoldings() async {
    setState(() => _holdingsFuture = _repository.getHoldings());
    _shimmerController.repeat();
  }

  Map<String, dynamic> _calculateHoldingsSummary(List<HoldingModel> holdings) {
    double totalInvestment = 0;
    double totalCurrentValue = 0;
    double totalPnl = 0;
    int totalStocks = holdings.length;
    int totalQuantity = 0;
    int totalT1Quantity = 0;
    int totalUsedQuantity = 0;
    int totalSettledQuantity = 0;

    for (var h in holdings) {
      totalInvestment += h.investmentValue;
      totalCurrentValue += h.currentValue;
      totalPnl += h.pnl;
      totalQuantity += h.quantity;
      totalT1Quantity += h.t1Quantity;
      totalUsedQuantity += h.usedQuantity;
      totalSettledQuantity += (h.quantity - h.t1Quantity);
    }

    double pnlPercentage =
        totalInvestment > 0 ? (totalPnl / totalInvestment) * 100 : 0;

    return {
      'totalInvestment': totalInvestment,
      'totalCurrentValue': totalCurrentValue,
      'totalPnl': totalPnl,
      'pnlPercentage': pnlPercentage,
      'totalStocks': totalStocks,
      'totalQuantity': totalQuantity,
      'totalT1Quantity': totalT1Quantity,
      'totalUsedQuantity': totalUsedQuantity,
      'totalSettledQuantity': totalSettledQuantity,
      'availableQuantity': totalQuantity - totalUsedQuantity - totalT1Quantity,
    };
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshHoldings,
      child: FutureBuilder<List<HoldingModel>>(
        future: _holdingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            _shimmerController.repeat();
            return _buildLoadingSkeleton(context);
          } else if (snapshot.hasError) {
            _shimmerController.stop();
            return buildErrorStateBroker(
                _refreshHoldings, snapshot.error, context);
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            _shimmerController.stop();
            return _buildEmptyState('No holdings found');
          }

          _shimmerController.stop();
          final holdings = snapshot.data!;
          final summary = _calculateHoldingsSummary(holdings);

          return ListView(
            children: [
              // ── Summary card (unchanged) ──────────────────────
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: summary['totalPnl'] >= 0
                        ? [Colors.green[400]!, Colors.green[600]!]
                        : [Colors.red[400]!, Colors.red[600]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (summary['totalPnl'] >= 0 ? Colors.green : Colors.red)
                              .withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Holdings',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500)),
                        Text('${summary['totalStocks']} stocks',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Current Value',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                            Text(
                              '₹${summary['totalCurrentValue'].toStringAsFixed(2)}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Total P&L',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                            Text(
                              '${summary['totalPnl'] >= 0 ? '+' : ''}₹${summary['totalPnl'].toStringAsFixed(2)}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${summary['pnlPercentage'] >= 0 ? '+' : ''}${summary['pnlPercentage'].toStringAsFixed(2)}%',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(height: 1, color: Colors.white24),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Investment: ₹${summary['totalInvestment'].toStringAsFixed(2)}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                    if (summary['totalT1Quantity'] > 0 ||
                        summary['totalUsedQuantity'] > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (summary['totalT1Quantity'] > 0)
                            Text('T1 Holdings: ${summary['totalT1Quantity']}',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 11)),
                          if (summary['totalUsedQuantity'] > 0)
                            Text('Used: ${summary['totalUsedQuantity']}',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // ── Holdings list (now uses updated card) ─────────
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: holdings.length,
                itemBuilder: (context, index) =>
                    EnhancedHoldingCard(holding: holdings[index]),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoadingSkeleton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return ListView(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildShimmerBox(width: 120, height: 16, isDark: isDark),
                      _buildShimmerBox(width: 80, height: 14, isDark: isDark),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildShimmerBox(
                                width: 90, height: 12, isDark: isDark),
                            const SizedBox(height: 8),
                            _buildShimmerBox(
                                width: 120, height: 20, isDark: isDark),
                          ]),
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _buildShimmerBox(
                                width: 70, height: 12, isDark: isDark),
                            const SizedBox(height: 8),
                            _buildShimmerBox(
                                width: 90, height: 18, isDark: isDark),
                          ]),
                    ],
                  ),
                ],
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: 5,
              itemBuilder: (_, __) =>
                  HoldingSkeletonCard(shimmerAnimation: _shimmerAnimation),
            ),
          ],
        );
      },
    );
  }

  Widget _buildShimmerBox(
      {required double width, required double height, required bool isDark}) {
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: const Alignment(-1.0, 0.0),
          end: const Alignment(1.0, 0.0),
          colors: [baseColor, highlightColor, baseColor],
          stops: [
            (_shimmerAnimation.value - 1.0).clamp(0.0, 1.0),
            _shimmerAnimation.value.clamp(0.0, 1.0),
            (_shimmerAnimation.value + 1.0).clamp(0.0, 1.0),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined,
                size: 64, color: isDark ? Colors.grey[600] : Colors.grey[400]),
            const SizedBox(height: 16),
            Text(message,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[300] : Colors.grey[700])),
            const SizedBox(height: 8),
            Text(
              'Your holdings will appear here once you make investments',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[500] : Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Enhanced Holding Card  ← MODIFIED: Buy More + Sell buttons
// ─────────────────────────────────────────────────────────────

class EnhancedHoldingCard extends StatelessWidget {
  final HoldingModel holding;

  const EnhancedHoldingCard({Key? key, required this.holding})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isProfit = holding.pnl >= 0;
    final profitColor = isProfit ? Colors.green : Colors.red;

    // Derive segment from exchange — NSE/BSE = EQ
    final segment =
        (holding.exchange == 'NFO' || holding.exchange == 'MCX') ? 'FNO' : 'EQ';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey).withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: symbol + price ────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(holding.tradingSymbol,
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black)),
                        if (holding.hasT1Holdings) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('T1',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange[700])),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      '${holding.exchange} • ${holding.product}',
                      style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₹${holding.lastPrice.toStringAsFixed(2)}',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black)),
                  Text(
                    '${isProfit ? '+' : ''}₹${holding.pnl.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontSize: 12,
                        color: profitColor,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
              height: 1, color: isDark ? Colors.grey[800] : Colors.grey[200]),
          const SizedBox(height: 12),

          // ── Quantity row (unchanged) ──────────────────────────
          Row(
            children: [
              Expanded(
                  child: _buildInfoItem(
                      'Net Qty', holding.netQuantity.toString(), isDark)),
              if (holding.t1Quantity > 0)
                Expanded(
                    child: _buildInfoItem(
                        'T1 Qty', holding.t1Quantity.toString(), isDark,
                        color: Colors.orange[600])),
              if (holding.usedQuantity > 0)
                Expanded(
                    child: _buildInfoItem(
                        'Used', holding.usedQuantity.toString(), isDark,
                        color: Colors.blue[600])),
              Expanded(
                  child: _buildInfoItem(
                      'Available', holding.availableQuantity.toString(), isDark,
                      color: Colors.green[600])),
            ],
          ),
          const SizedBox(height: 12),

          // ── Price row (unchanged) ─────────────────────────────
          Row(
            children: [
              Expanded(
                  child: _buildInfoItem('Avg Price',
                      '₹${holding.averagePrice.toStringAsFixed(2)}', isDark)),
              Expanded(
                  child: _buildInfoItem(
                'Day Change',
                '${holding.dayChangePercentage >= 0 ? '+' : ''}${holding.dayChangePercentage.toStringAsFixed(2)}%',
                isDark,
                color: holding.dayChangePercentage >= 0
                    ? Colors.green
                    : Colors.red,
              )),
              Expanded(
                  child: _buildInfoItem(
                'P&L %',
                '${holding.pnlPercentage >= 0 ? '+' : ''}${holding.pnlPercentage.toStringAsFixed(2)}%',
                isDark,
                color: holding.pnlPercentage >= 0 ? Colors.green : Colors.red,
              )),
            ],
          ),

          if (holding.investmentValue > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.grey[50],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                      'Invested: ₹${holding.investmentValue.toStringAsFixed(2)}',
                      style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey[400] : Colors.grey[600])),
                  Text('Current: ₹${holding.currentValue.toStringAsFixed(2)}',
                      style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey[400] : Colors.grey[600])),
                ],
              ),
            ),
          ],

          // ── NEW: Buy More / Sell action buttons ───────────────
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'Buy More',
                  icon: Icons.add_rounded,
                  color: const Color(0xFF10B981),
                  isDark: isDark,
                  onTap: () => _openOrderPage(
                    context,
                    symbol: holding.tradingSymbol,
                    segment: segment,
                    tosell: false,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  label: 'Sell',
                  icon: Icons.remove_rounded,
                  color: const Color(0xFFEF4444),
                  isDark: isDark,
                  onTap: () => _openOrderPage(
                    context,
                    symbol: holding.tradingSymbol,
                    segment: segment,
                    tosell: true,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, bool isDark,
      {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.grey[500] : Colors.grey[600])),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color ?? (isDark ? Colors.white : Colors.black))),
      ],
    );
  }
}

// Skeleton card (unchanged)
class HoldingSkeletonCard extends StatelessWidget {
  final Animation<double> shimmerAnimation;
  const HoldingSkeletonCard({Key? key, required this.shimmerAnimation})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _shimBox(100, 16, isDark),
                const SizedBox(height: 4),
                _shimBox(60, 12, isDark),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                _shimBox(80, 16, isDark),
                const SizedBox(height: 4),
                _shimBox(60, 12, isDark),
              ]),
            ],
          ),
          const SizedBox(height: 12),
          Container(
              height: 1, color: isDark ? Colors.grey[800] : Colors.grey[200]),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _shimBox(double.infinity, 12, isDark)),
              const SizedBox(width: 8),
              Expanded(child: _shimBox(double.infinity, 12, isDark)),
              const SizedBox(width: 8),
              Expanded(child: _shimBox(double.infinity, 12, isDark)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _shimBox(double w, double h, bool isDark) {
    final base = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final hi = isDark ? Colors.grey[700]! : Colors.grey[100]!;
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: LinearGradient(
          begin: const Alignment(-1.0, 0.0),
          end: const Alignment(1.0, 0.0),
          colors: [base, hi, base],
          stops: [
            (shimmerAnimation.value - 1.0).clamp(0.0, 1.0),
            shimmerAnimation.value.clamp(0.0, 1.0),
            (shimmerAnimation.value + 1.0).clamp(0.0, 1.0),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Positions Tab  (unchanged logic, updated position card)
// ─────────────────────────────────────────────────────────────

class PositionsTab extends StatefulWidget {
  const PositionsTab({Key? key}) : super(key: key);

  @override
  State<PositionsTab> createState() => _PositionsTabState();
}

class _PositionsTabState extends State<PositionsTab>
    with SingleTickerProviderStateMixin {
  Future<List<PositionModel>>? _positionsFuture;
  final ZerodhaRepository _repository = ZerodhaRepository();
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _positionsFuture = _repository.getPositions();
    _setupShimmerAnimation();
  }

  void _setupShimmerAnimation() {
    _shimmerController = AnimationController(
        duration: const Duration(milliseconds: 1500), vsync: this);
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
        CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut));
    _shimmerController.repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _refreshPositions() async {
    setState(() => _positionsFuture = _repository.getPositions());
    _shimmerController.repeat();
  }

  Map<String, dynamic> _calculatePositionsSummary(
      List<PositionModel> positions) {
    double totalPnl = 0;
    double totalM2M = 0;
    int totalPositions = positions.length;
    int openPositions = 0;

    for (var p in positions) {
      totalPnl += p.pnl;
      totalM2M += p.m2m;
      if (p.quantity != 0) openPositions++;
    }

    return {
      'totalPnl': totalPnl,
      'totalM2M': totalM2M,
      'totalPositions': totalPositions,
      'openPositions': openPositions,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: _refreshPositions,
      child: FutureBuilder<List<PositionModel>>(
        future: _positionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            _shimmerController.repeat();
            return _buildLoadingSkeleton(isDark);
          } else if (snapshot.hasError) {
            _shimmerController.stop();
            return buildErrorStateBroker(
                _refreshPositions, snapshot.error, context);
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            _shimmerController.stop();
            return _buildEmptyState(isDark);
          }

          _shimmerController.stop();
          final positions = snapshot.data!;
          final summary = _calculatePositionsSummary(positions);

          return ListView(
            children: [
              // ── Summary card (unchanged) ──────────────────────
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: summary['totalPnl'] >= 0
                        ? [Colors.green[400]!, Colors.green[600]!]
                        : [Colors.red[400]!, Colors.red[600]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (summary['totalPnl'] >= 0 ? Colors.green : Colors.red)
                              .withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Positions Overview',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500)),
                        Text('${summary['openPositions']} open',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Day P&L',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 12)),
                              Text(
                                '${summary['totalPnl'] >= 0 ? '+' : ''}₹${summary['totalPnl'].toStringAsFixed(2)}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold),
                              ),
                            ]),
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('M2M',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 12)),
                              Text(
                                '${summary['totalM2M'] >= 0 ? '+' : ''}₹${summary['totalM2M'].toStringAsFixed(2)}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              ),
                            ]),
                      ],
                    ),
                  ],
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: positions.length,
                itemBuilder: (context, index) =>
                    _PositionCard(position: positions[index]),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoadingSkeleton(bool isDark) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (_, __) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (_, __) =>
            PositionSkeletonCard(shimmerAnimation: _shimmerAnimation),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_outlined,
                size: 64, color: isDark ? Colors.grey[600] : Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No positions found',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[300] : Colors.grey[700])),
            const SizedBox(height: 8),
            Text('Your open and closed positions appear here',
                style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[500] : Colors.grey[500])),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Position Card  ← MODIFIED: Add / Exit buttons
// ─────────────────────────────────────────────────────────────

class _PositionCard extends StatelessWidget {
  final PositionModel position;
  const _PositionCard({required this.position});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isProfit = position.pnl >= 0;
    final profitColor = isProfit ? Colors.green : Colors.red;
    final isOpen = position.quantity != 0;

    final segment = (position.exchange == 'NFO' || position.exchange == 'MCX')
        ? 'FNO'
        : 'EQ';

    // For an open long position, Add = BUY, Exit = SELL
    // For an open short position (negative qty), Add = SELL, Exit = BUY
    final isLong = position.quantity > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey).withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(position.tradingSymbol,
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                isOpen ? Colors.orange[100] : Colors.grey[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(isOpen ? 'OPEN' : 'CLOSED',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isOpen
                                      ? Colors.orange[700]
                                      : Colors.grey[700])),
                        ),
                      ],
                    ),
                    Text('${position.exchange} • ${position.product}',
                        style: TextStyle(
                            fontSize: 12,
                            color:
                                isDark ? Colors.grey[400] : Colors.grey[600])),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₹${position.lastPrice.toStringAsFixed(2)}',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black)),
                  Text(
                    '${isProfit ? '+' : ''}₹${position.pnl.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontSize: 12,
                        color: profitColor,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
              height: 1, color: isDark ? Colors.grey[800] : Colors.grey[200]),
          const SizedBox(height: 12),

          // ── Info row (unchanged) ──────────────────────────────
          Row(
            children: [
              Expanded(
                  child: _buildInfoItem(
                      'Net Qty', position.quantity.toString(), isDark)),
              Expanded(
                  child: _buildInfoItem('Avg',
                      '₹${position.averagePrice.toStringAsFixed(2)}', isDark)),
              Expanded(
                  child: _buildInfoItem(
                'M2M',
                '${position.m2m >= 0 ? '+' : ''}₹${position.m2m.toStringAsFixed(2)}',
                isDark,
                color: position.m2m >= 0 ? Colors.green : Colors.red,
              )),
            ],
          ),

          // ── NEW: Add / Exit buttons (only for open positions) ─
          if (isOpen) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: isLong ? 'Add Long' : 'Add Short',
                    icon: Icons.add_rounded,
                    color: isLong
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                    isDark: isDark,
                    onTap: () => _openOrderPage(
                      context,
                      symbol: position.tradingSymbol,
                      segment: segment,
                      tosell: !isLong, // short → sell more
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionButton(
                    label: 'Exit',
                    icon: Icons.close_rounded,
                    color: isLong
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF10B981),
                    isDark: isDark,
                    onTap: () => _openOrderPage(
                      context,
                      symbol: position.tradingSymbol,
                      segment: segment,
                      tosell: isLong, // long → sell to exit
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, bool isDark,
      {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[500] : Colors.grey[600])),
        Text(value,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color ?? (isDark ? Colors.white : Colors.black))),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Shared action button widget
// ─────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.30), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Position skeleton card (unchanged, kept for completeness)
// ─────────────────────────────────────────────────────────────

class PositionSkeletonCard extends StatelessWidget {
  final Animation<double> shimmerAnimation;
  const PositionSkeletonCard({Key? key, required this.shimmerAnimation})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _shimBox(120, 16, isDark),
                const SizedBox(height: 4),
                _shimBox(80, 12, isDark),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                _shimBox(80, 16, isDark),
                const SizedBox(height: 4),
                _shimBox(60, 12, isDark),
              ]),
            ],
          ),
          const SizedBox(height: 12),
          Container(
              height: 1, color: isDark ? Colors.grey[800] : Colors.grey[200]),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _shimBox(double.infinity, 12, isDark)),
              const SizedBox(width: 8),
              Expanded(child: _shimBox(double.infinity, 12, isDark)),
              const SizedBox(width: 8),
              Expanded(child: _shimBox(double.infinity, 12, isDark)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _shimBox(double w, double h, bool isDark) {
    final base = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final hi = isDark ? Colors.grey[700]! : Colors.grey[100]!;
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: LinearGradient(
          begin: const Alignment(-1.0, 0.0),
          end: const Alignment(1.0, 0.0),
          colors: [base, hi, base],
          stops: [
            (shimmerAnimation.value - 1.0).clamp(0.0, 1.0),
            shimmerAnimation.value.clamp(0.0, 1.0),
            (shimmerAnimation.value + 1.0).clamp(0.0, 1.0),
          ],
        ),
      ),
    );
  }
}
