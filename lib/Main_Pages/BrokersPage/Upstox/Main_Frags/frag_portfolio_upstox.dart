import 'package:flutter/material.dart';
import 'package:optionxi/Main_Pages/BrokersPage/Upstox/utils/upstox_controller.dart';
import 'package:optionxi/Main_Pages/BrokersPage/Upstox/utils/upstox_datamodel.dart';

class PortfolioPageUpstox extends StatefulWidget {
  const PortfolioPageUpstox({Key? key}) : super(key: key);

  @override
  State<PortfolioPageUpstox> createState() => _PortfolioPageUpstoxState();
}

class _PortfolioPageUpstoxState extends State<PortfolioPageUpstox>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final UpstoxRepository _repository = UpstoxRepository();

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
                  HoldingsTab(repository: _repository),
                  PositionsTab(repository: _repository),
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
class HoldingsTab extends StatefulWidget {
  final UpstoxRepository repository;

  const HoldingsTab({Key? key, required this.repository}) : super(key: key);

  @override
  State<HoldingsTab> createState() => _HoldingsTabState();
}

class _HoldingsTabState extends State<HoldingsTab>
    with TickerProviderStateMixin {
  Future<UpstoxHoldingsResponse>? _holdingsFuture;
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _holdingsFuture = widget.repository.getHoldings();
    _setupAnimations();
  }

  void _setupAnimations() {
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _holdingsFuture = widget.repository.getHoldings();
        });
      },
      child: FutureBuilder<UpstoxHoldingsResponse>(
        future: _holdingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingSkeleton();
          } else if (snapshot.hasError) {
            return _buildErrorState(() {
              setState(() {
                _holdingsFuture = widget.repository.getHoldings();
              });
            });
          } else if (!snapshot.hasData || snapshot.data!.holdings.isEmpty) {
            return _buildEmptyState('No holdings found');
          }

          final holdingsResponse = snapshot.data!;
          final overall = holdingsResponse.overall;

          return ListView(
            children: [
              // Summary Card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: overall.totalPnl >= 0
                        ? [Colors.green[400]!, Colors.green[600]!]
                        : [Colors.red[400]!, Colors.red[600]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (overall.totalPnl >= 0 ? Colors.green : Colors.red)
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Current Value',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '₹${overall.totalCurrentValue.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Total P&L',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${overall.totalPnl >= 0 ? '+' : ''}₹${overall.totalPnl.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${overall.pnlPercentage >= 0 ? '+' : ''}${overall.pnlPercentage.toStringAsFixed(2)}%',
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
              ),
              // Holdings List
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: holdingsResponse.holdings.length,
                itemBuilder: (context, index) {
                  return HoldingCard(holding: holdingsResponse.holdings[index]);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildShimmerBox(
      {required double width, required double height, double radius = 8}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
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

  Widget _buildLoadingSkeleton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return ListView(
          children: [
            // Summary skeleton
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
                      _buildShimmerBox(width: 120, height: 16),
                      _buildShimmerBox(width: 80, height: 14),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildShimmerBox(width: 90, height: 12),
                          const SizedBox(height: 8),
                          _buildShimmerBox(width: 120, height: 20),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildShimmerBox(width: 70, height: 12),
                          const SizedBox(height: 8),
                          _buildShimmerBox(width: 90, height: 18),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(height: 1, color: Colors.grey[800]),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildShimmerBox(width: 150, height: 12),
                    ],
                  ),
                ],
              ),
            ),
            // List skeleton
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: 5,
              itemBuilder: (context, index) => _buildHoldingSkeletonItem(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHoldingSkeletonItem() {
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
                  _buildShimmerBox(width: 100, height: 16),
                  const SizedBox(height: 8),
                  _buildShimmerBox(width: 140, height: 12),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildShimmerBox(width: 80, height: 16),
                  const SizedBox(height: 8),
                  _buildShimmerBox(width: 60, height: 12),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: isDark ? Colors.grey[800] : Colors.grey[200]),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(3, (_) => _buildSkeletonInfoItem()),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(3, (_) => _buildSkeletonInfoItem()),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonInfoItem() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildShimmerBox(width: 50, height: 12),
          const SizedBox(height: 4),
          _buildShimmerBox(width: 70, height: 14),
        ],
      ),
    );
  }

  Widget _buildErrorState(VoidCallback onRetry) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load holdings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Contact support at optionxi24@gmail.com',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
class PositionsTab extends StatefulWidget {
  final UpstoxRepository repository;

  const PositionsTab({Key? key, required this.repository}) : super(key: key);

  @override
  State<PositionsTab> createState() => _PositionsTabState();
}

class _PositionsTabState extends State<PositionsTab>
    with TickerProviderStateMixin {
  Future<UpstoxPositionsResponse>? _positionsFuture;
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _positionsFuture = widget.repository.getPositions();
    _setupAnimations();
  }

  void _setupAnimations() {
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _positionsFuture = widget.repository.getPositions();
        });
      },
      child: FutureBuilder<UpstoxPositionsResponse>(
        future: _positionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingSkeleton();
          } else if (snapshot.hasError) {
            return _buildErrorState(() {
              setState(() {
                _positionsFuture = widget.repository.getPositions();
              });
            });
          } else if (!snapshot.hasData || snapshot.data!.positions.isEmpty) {
            return _buildEmptyState('No positions found');
          }

          final positionsResponse = snapshot.data!;
          final overall = positionsResponse.overall;

          return ListView(
            children: [
              // Summary Card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: overall.pnlUnrealized >= 0
                        ? [Colors.green[400]!, Colors.green[600]!]
                        : [Colors.red[400]!, Colors.red[600]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (overall.pnlUnrealized >= 0
                              ? Colors.green
                              : Colors.red)
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
                        const Text(
                          'Open Positions',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${overall.countOpen} active',
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Unrealized P&L',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${overall.pnlUnrealized >= 0 ? '+' : ''}₹${overall.pnlUnrealized.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Realized P&L',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${overall.pnlRealized >= 0 ? '+' : ''}₹${overall.pnlRealized.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
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
                          'Total positions: ${overall.countTotal}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Positions List
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: positionsResponse.positions.length,
                itemBuilder: (context, index) {
                  return PositionCard(
                      position: positionsResponse.positions[index]);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildShimmerBox(
      {required double width, required double height, double radius = 8}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
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

  Widget _buildLoadingSkeleton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return ListView(
          children: [
            // Summary skeleton
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
                      _buildShimmerBox(width: 120, height: 16),
                      _buildShimmerBox(width: 80, height: 14),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildShimmerBox(width: 90, height: 12),
                          const SizedBox(height: 8),
                          _buildShimmerBox(width: 120, height: 20),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildShimmerBox(width: 70, height: 12),
                          const SizedBox(height: 8),
                          _buildShimmerBox(width: 90, height: 18),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(height: 1, color: Colors.grey[800]),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildShimmerBox(width: 150, height: 12),
                    ],
                  ),
                ],
              ),
            ),
            // List skeleton
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: 5,
              itemBuilder: (context, index) => _buildPositionSkeletonItem(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPositionSkeletonItem() {
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
                  _buildShimmerBox(width: 100, height: 16),
                  const SizedBox(height: 8),
                  _buildShimmerBox(width: 140, height: 12),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildShimmerBox(width: 80, height: 16),
                  const SizedBox(height: 8),
                  _buildShimmerBox(width: 60, height: 12),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: isDark ? Colors.grey[800] : Colors.grey[200]),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(3, (_) => _buildSkeletonInfoItem()),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonInfoItem() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildShimmerBox(width: 50, height: 12),
          const SizedBox(height: 4),
          _buildShimmerBox(width: 70, height: 14),
        ],
      ),
    );
  }

  Widget _buildErrorState(VoidCallback onRetry) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load positions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Contact support at optionxi24@gmail.com',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
            ),
          ],
        ),
      ),
    );
  }
}

// Holding Card
class HoldingCard extends StatelessWidget {
  final UpstoxHoldingModel holding;

  const HoldingCard({Key? key, required this.holding}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isProfit = holding.pnl >= 0;
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
                      holding.tradingsymbol,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    if (holding.company.isNotEmpty)
                      Text(
                        holding.company,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    Text(
                      holding.exchange,
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
                    '₹${holding.lastPrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    '${isProfit ? '+' : ''}₹${holding.pnl.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: profitColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${holding.pnlPercentage >= 0 ? '+' : ''}${holding.pnlPercentage.toStringAsFixed(2)}%',
                    style: TextStyle(
                      fontSize: 11,
                      color: profitColor,
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
                child: _buildInfoItem('Avg',
                    '₹${holding.averagePrice.toStringAsFixed(2)}', isDark),
              ),
              Expanded(
                child: _buildInfoItem(
                  'Day Change',
                  '${holding.dayChangePercentage >= 0 ? '+' : ''}${holding.dayChangePercentage.toStringAsFixed(2)}%',
                  isDark,
                  color: holding.dayChangePercentage >= 0
                      ? Colors.green
                      : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem('Investment',
                    '₹${holding.totalInvestment.toStringAsFixed(2)}', isDark),
              ),
              Expanded(
                child: _buildInfoItem('Current',
                    '₹${holding.currentValue.toStringAsFixed(2)}', isDark),
              ),
              Expanded(
                child: _buildInfoItem(
                    'LTP', '₹${holding.lastPrice.toStringAsFixed(2)}', isDark),
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

// Position Card
class PositionCard extends StatelessWidget {
  final UpstoxPositionModel position;

  const PositionCard({Key? key, required this.position}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isProfit = position.unrealisedPnl >= 0;
    final profitColor = isProfit ? Colors.green : Colors.red;
    final isOpen = position.quantity != 0;

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
                          position.tradingsymbol,
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
                      '${position.exchange} • ${position.productType}',
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
                    '₹${position.lastPrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    '${isProfit ? '+' : ''}₹${position.unrealisedPnl.toStringAsFixed(2)}',
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
                    'Net Qty', position.quantity.toString(), isDark),
              ),
              Expanded(
                child: _buildInfoItem('Avg',
                    '₹${position.averagePrice.toStringAsFixed(2)}', isDark),
              ),
              Expanded(
                child: _buildInfoItem(
                  'Realized',
                  '${position.realisedPnl >= 0 ? '+' : ''}₹${position.realisedPnl.toStringAsFixed(2)}',
                  isDark,
                  color: position.realisedPnl >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          if (position.buyQuantity > 0 || position.sellQuantity > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (position.buyQuantity > 0)
                  Expanded(
                    child: _buildInfoItem(
                        'Buy Qty', position.buyQuantity.toString(), isDark),
                  ),
                if (position.sellQuantity > 0)
                  Expanded(
                    child: _buildInfoItem(
                        'Sell Qty', position.sellQuantity.toString(), isDark),
                  ),
                Expanded(
                  child: _buildInfoItem(
                      'Multiplier', position.multiplier.toString(), isDark),
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
