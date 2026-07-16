import 'package:flutter/material.dart';
import 'package:optionxi/Main_Pages/BrokersPage/Fyers/utils/fyers_controller.dart';
import 'package:optionxi/Main_Pages/BrokersPage/Fyers/utils/fyers_datamodel.dart';

// Portfolio Page for Fyers
class PortfolioPageFyers extends StatefulWidget {
  const PortfolioPageFyers({
    Key? key,
  }) : super(key: key);

  @override
  State<PortfolioPageFyers> createState() => _PortfolioPageFyersState();
}

class _PortfolioPageFyersState extends State<PortfolioPageFyers>
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
            // Custom Tab Bar
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
            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  const FyersHoldingsTab(),
                  const FyersPositionsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Holdings Tab
class FyersHoldingsTab extends StatefulWidget {
  const FyersHoldingsTab({
    Key? key,
  }) : super(key: key);

  @override
  State<FyersHoldingsTab> createState() => _FyersHoldingsTabState();
}

class _FyersHoldingsTabState extends State<FyersHoldingsTab>
    with SingleTickerProviderStateMixin {
  Future<FyersHoldingsResponse>? _holdingsFuture;
  final FyersRepository _repository = FyersRepository();
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

    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));

    _shimmerController.repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _refreshHoldings() async {
    setState(() {
      _holdingsFuture = _repository.getHoldings();
    });
    _shimmerController.repeat();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshHoldings,
      child: FutureBuilder<FyersHoldingsResponse>(
        future: _holdingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            _shimmerController.repeat();
            return _buildLoadingSkeleton();
          } else if (snapshot.hasError) {
            _shimmerController.stop();
            return _buildErrorState(() {
              _refreshHoldings();
            }, snapshot.error);
          } else if (!snapshot.hasData || snapshot.data!.holdings.isEmpty) {
            _shimmerController.stop();
            return _buildEmptyState('No holdings found');
          }
          _shimmerController.stop();
          final response = snapshot.data!;
          return ListView(
            children: [
              _buildSummaryCard(response.overall),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: response.holdings.length,
                itemBuilder: (context, index) {
                  return FyersHoldingCard(holding: response.holdings[index]);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(FyersOverallSummary overall) {
    final isProfit = overall.totalPl >= 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isProfit
              ? [Colors.green[400]!, Colors.green[600]!]
              : [Colors.red[400]!, Colors.red[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isProfit ? Colors.green : Colors.red).withOpacity(0.3),
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
              const Text(
                'Total Holdings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${overall.countTotal} stocks',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem('Current Value',
                  '₹${overall.totalCurrentValue.toStringAsFixed(2)}',
                  isMain: true),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildSummaryItem('Total P&L',
                      '${isProfit ? '+' : ''}₹${overall.totalPl.toStringAsFixed(2)}'),
                  Text(
                    '${isProfit ? '+' : ''}${overall.pnlPerc.toStringAsFixed(2)}%',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 1,
            color: Colors.white24,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Investment: ₹${overall.totalInvestment.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, {bool isMain = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: isMain ? 20 : 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingSkeleton() {
    return AnimatedBuilder(
        animation: _shimmerAnimation,
        builder: (context, child) {
          return ListView(
            children: [
              FyersHoldingSkeletonCard(shimmerAnimation: _shimmerAnimation),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: 5,
                itemBuilder: (context, index) => FyersHoldingSkeletonCard(
                    shimmerAnimation: _shimmerAnimation),
              ),
            ],
          );
        });
  }

  Widget _buildErrorState(VoidCallback onRetry, dynamic error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load holdings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              error.toString(),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
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
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your holdings will appear here once you make investments',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[500] : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Positions Tab
class FyersPositionsTab extends StatefulWidget {
  const FyersPositionsTab({
    Key? key,
  }) : super(key: key);

  @override
  State<FyersPositionsTab> createState() => _FyersPositionsTabState();
}

class _FyersPositionsTabState extends State<FyersPositionsTab>
    with SingleTickerProviderStateMixin {
  Future<FyersPositionsResponse>? _positionsFuture;
  final FyersRepository _repository = FyersRepository();
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
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));

    _shimmerController.repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _refreshPositions() async {
    setState(() {
      _positionsFuture = _repository.getPositions();
    });
    _shimmerController.repeat();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshPositions,
      child: FutureBuilder<FyersPositionsResponse>(
        future: _positionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            _shimmerController.repeat();
            return _buildLoadingSkeleton();
          } else if (snapshot.hasError) {
            _shimmerController.stop();
            return _buildErrorState(() {
              _refreshPositions();
            }, snapshot.error);
          } else if (!snapshot.hasData || snapshot.data!.netPositions.isEmpty) {
            _shimmerController.stop();
            return _buildEmptyState('No positions found');
          }
          _shimmerController.stop();
          final response = snapshot.data!;
          return ListView(
            children: [
              _buildPositionsSummaryCard(response.overall),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: response.netPositions.length,
                itemBuilder: (context, index) {
                  return FyersPositionCard(
                      position: response.netPositions[index]);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPositionsSummaryCard(FyersOverallPositionsSummary overall) {
    final totalPnl = overall.pnlRealized + overall.pnlUnrealized;
    final isProfit = totalPnl >= 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isProfit
              ? [Colors.green[400]!, Colors.green[600]!]
              : [Colors.red[400]!, Colors.red[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isProfit ? Colors.green : Colors.red).withOpacity(0.3),
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
              const Text(
                'Open Positions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${overall.totalCount} active',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem('Total P&L',
                  '${isProfit ? '+' : ''}₹${totalPnl.toStringAsFixed(2)}',
                  isMain: true),
              // Column(
              //   crossAxisAlignment: CrossAxisAlignment.end,
              //   children: [
              //     _buildSummaryItem('Realized P&L',
              //         '₹${overall.pnlRealized.toStringAsFixed(2)}'),
              //     _buildSummaryItem('Unrealized P&L',
              //         '₹${overall.pnlUnrealized.toStringAsFixed(2)}'),
              //   ],
              // ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, {bool isMain = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: isMain ? 20 : 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingSkeleton() {
    return AnimatedBuilder(
        animation: _shimmerAnimation,
        builder: (context, child) {
          return ListView(
            children: [
              FyersPositionSkeletonCard(shimmerAnimation: _shimmerAnimation),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: 5,
                itemBuilder: (context, index) => FyersPositionSkeletonCard(
                    shimmerAnimation: _shimmerAnimation),
              ),
            ],
          );
        });
  }

  Widget _buildErrorState(VoidCallback onRetry, dynamic error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load positions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              error.toString(),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
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
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your trading positions will appear here',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[500] : Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Fyers Holding Card
class FyersHoldingCard extends StatelessWidget {
  final FyersHoldingModel holding;

  const FyersHoldingCard({Key? key, required this.holding}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isProfit = holding.pl >= 0;
    final profitColor = isProfit ? Colors.green : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      holding.symbol,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      holding.holdingType,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${holding.ltp.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    '${isProfit ? '+' : ''}₹${holding.pl.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: profitColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 1,
            color: isDark ? Colors.grey[800] : Colors.grey[200],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child:
                    _buildInfoItem('Qty', holding.quantity.toString(), isDark),
              ),
              Expanded(
                child: _buildInfoItem(
                    'Avg', '₹${holding.costPrice.toStringAsFixed(2)}', isDark),
              ),
              Expanded(
                child: _buildInfoItem(
                  'P&L %',
                  '${holding.pnlPercentage >= 0 ? '+' : ''}${holding.pnlPercentage.toStringAsFixed(2)}%',
                  isDark,
                  color: holding.pnlPercentage >= 0 ? Colors.green : Colors.red,
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
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[500] : Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: color ?? (isDark ? Colors.white : Colors.black),
          ),
        ),
      ],
    );
  }
}

// Fyers Position Card
class FyersPositionCard extends StatelessWidget {
  final FyersPositionModel position;

  const FyersPositionCard({Key? key, required this.position}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isProfit = position.pl >= 0;
    final profitColor = isProfit ? Colors.green : Colors.red;
    final isOpen = position.netQty != 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          position.symbol,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                isOpen ? Colors.orange[100] : Colors.grey[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isOpen ? 'OPEN' : 'CLOSED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isOpen
                                  ? Colors.orange[700]
                                  : Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${position.segment} • ${position.productType}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${position.ltp.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    '${isProfit ? '+' : ''}₹${position.pl.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: profitColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 1,
            color: isDark ? Colors.grey[800] : Colors.grey[200],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                    'Net Qty', position.netQty.toString(), isDark),
              ),
              Expanded(
                child: _buildInfoItem(
                    'Avg', '₹${position.buyAvg.toStringAsFixed(2)}', isDark),
              ),
              Expanded(
                child: _buildInfoItem(
                  'Unrealized',
                  '${position.unrealizedProfit >= 0 ? '+' : ''}₹${position.unrealizedProfit.toStringAsFixed(2)}',
                  isDark,
                  color: position.unrealizedProfit >= 0
                      ? Colors.green
                      : Colors.red,
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
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[500] : Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: color ?? (isDark ? Colors.white : Colors.black),
          ),
        ),
      ],
    );
  }
}

// Skeleton Cards
class FyersHoldingSkeletonCard extends StatelessWidget {
  final Animation<double> shimmerAnimation;
  const FyersHoldingSkeletonCard({Key? key, required this.shimmerAnimation})
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
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSkeletonBox(width: 100, height: 16, isDark: isDark),
                  const SizedBox(height: 4),
                  _buildSkeletonBox(width: 60, height: 12, isDark: isDark),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildSkeletonBox(width: 80, height: 16, isDark: isDark),
                  const SizedBox(height: 4),
                  _buildSkeletonBox(width: 60, height: 12, isDark: isDark),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 1,
            color: isDark ? Colors.grey[800] : Colors.grey[200],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _buildSkeletonBox(
                      width: double.infinity, height: 28, isDark: isDark)),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildSkeletonBox(
                      width: double.infinity, height: 28, isDark: isDark)),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildSkeletonBox(
                      width: double.infinity, height: 28, isDark: isDark)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonBox(
      {required double width, required double height, required bool isDark}) {
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: LinearGradient(
          begin: const Alignment(-1.0, 0.0),
          end: const Alignment(1.0, 0.0),
          colors: [
            baseColor,
            highlightColor,
            baseColor,
          ],
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

class FyersPositionSkeletonCard extends StatelessWidget {
  final Animation<double> shimmerAnimation;
  const FyersPositionSkeletonCard({Key? key, required this.shimmerAnimation})
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
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSkeletonBox(width: 120, height: 16, isDark: isDark),
                  const SizedBox(height: 4),
                  _buildSkeletonBox(width: 80, height: 12, isDark: isDark),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildSkeletonBox(width: 80, height: 16, isDark: isDark),
                  const SizedBox(height: 4),
                  _buildSkeletonBox(width: 60, height: 12, isDark: isDark),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 1,
            color: isDark ? Colors.grey[800] : Colors.grey[200],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _buildSkeletonBox(
                      width: double.infinity, height: 28, isDark: isDark)),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildSkeletonBox(
                      width: double.infinity, height: 28, isDark: isDark)),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildSkeletonBox(
                      width: double.infinity, height: 28, isDark: isDark)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonBox(
      {required double width, required double height, required bool isDark}) {
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: LinearGradient(
          begin: const Alignment(-1.0, 0.0),
          end: const Alignment(1.0, 0.0),
          colors: [
            baseColor,
            highlightColor,
            baseColor,
          ],
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
