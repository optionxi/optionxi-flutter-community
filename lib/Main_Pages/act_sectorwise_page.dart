import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:optionxi/Main_Pages/act_sectorwise_stocks.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SectorAnalysisPage extends StatefulWidget {
  const SectorAnalysisPage({Key? key}) : super(key: key);

  @override
  State<SectorAnalysisPage> createState() => _SectorAnalysisPageState();
}

class _SectorAnalysisPageState extends State<SectorAnalysisPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final SupabaseClient _supabase = Supabase.instance.client;

  Map<String, List<StockData>> _sectorData = {};
  List<SectorTrend> _bullishSectors = [];
  List<SectorTrend> _bearishSectors = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchData();
  }

  // Helper method to get theme-aware colors
  Color _getPositiveColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF00FF88)
        : const Color(0xFF00B85F);
  }

  Color _getNegativeColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFFF4444)
        : const Color(0xFFE53935);
  }

  Color _getCardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1E1E1F)
        : Colors.white;
  }

  Color _getSkeletonColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2A2A2B)
        : const Color(0xFFE0E0E0);
  }

  Color _getSkeletonBaseColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1A1A1B)
        : const Color(0xFFF0F0F0);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await _supabase
          .from('generated_values')
          .select(
              'stckname, pcnt, close, high, low, open, vol, sec, rsi14, ema20, sma20')
          .not('sec', 'is', null);

      final List<dynamic> data = response as List<dynamic>;

      // Group stocks by sector
      Map<String, List<StockData>> tempSectorData = {};

      for (var item in data) {
        final stock = StockData.fromJson(item);
        final sector = stock.sector ?? 'Others';

        if (!tempSectorData.containsKey(sector)) {
          tempSectorData[sector] = [];
        }
        tempSectorData[sector]!.add(stock);
      }

      // Calculate sector trends
      List<SectorTrend> bullishTrends = [];
      List<SectorTrend> bearishTrends = [];

      tempSectorData.forEach((sector, stocks) {
        final trend = _calculateSectorTrend(sector, stocks);

        if (trend.bullishScore > 0) {
          bullishTrends.add(trend);
        } else {
          bearishTrends.add(trend);
        }
      });

      // Sort by scores
      bullishTrends.sort((a, b) => b.bullishScore.compareTo(a.bullishScore));
      bearishTrends.sort((a, b) => a.bearishScore.compareTo(b.bearishScore));

      setState(() {
        _sectorData = tempSectorData;
        _bullishSectors = bullishTrends;
        _bearishSectors = bearishTrends;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  SectorTrend _calculateSectorTrend(String sector, List<StockData> stocks) {
    int totalStocks = stocks.length;
    int positiveStocks = stocks.where((s) => s.pcnt > 0).length;
    int above5Percent = stocks.where((s) => s.pcnt > 5).length;
    int above2Percent = stocks.where((s) => s.pcnt > 2).length;
    int negativeStocks = stocks.where((s) => s.pcnt < 0).length;
    int below2Percent = stocks.where((s) => s.pcnt < -2).length;
    int below5Percent = stocks.where((s) => s.pcnt < -5).length;

    double avgChange =
        stocks.fold(0.0, (sum, stock) => sum + stock.pcnt) / totalStocks;
    double totalVolume = stocks.fold(0.0, (sum, stock) => sum + stock.vol);

    // Calculate bullish score (0-100)
    double bullishScore = 0;
    if (avgChange > 0) {
      bullishScore = (positiveStocks / totalStocks * 40) +
          (above5Percent / totalStocks * 30) +
          (above2Percent / totalStocks * 20) +
          (avgChange > 0 ? avgChange * 2 : 0);
    }

    // Calculate bearish score (0 to -100)
    double bearishScore = 0;
    if (avgChange < 0) {
      bearishScore = -(negativeStocks / totalStocks * 40) -
          (below5Percent / totalStocks * 30) -
          (below2Percent / totalStocks * 20) +
          (avgChange < 0 ? avgChange * 2 : 0);
    }

    return SectorTrend(
      sectorName: sector,
      totalStocks: totalStocks,
      positiveStocks: positiveStocks,
      negativeStocks: negativeStocks,
      above5Percent: above5Percent,
      above2Percent: above2Percent,
      below2Percent: below2Percent,
      below5Percent: below5Percent,
      averageChange: avgChange,
      bullishScore: bullishScore,
      bearishScore: bearishScore,
      totalVolume: totalVolume,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        title: Text(
          'Sector Trends',
          style: TextStyle(
            color: Theme.of(context).textTheme.headlineSmall?.color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: Theme.of(context).iconTheme.color,
            ),
            onPressed: _fetchData,
          ),
        ],
      ),
      body: _isLoading
          ? _buildSkeletonLoader()
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error: $_error',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _buildStocksTabSection(),
    );
  }

  Widget _buildStocksTabSection() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Theme.of(context).colorScheme.onPrimary,
            unselectedLabelColor: Theme.of(context).textTheme.bodyLarge?.color,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.trending_up, size: 20),
                    const SizedBox(width: 8),
                    Text('Bullish (${_bullishSectors.length})'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.trending_down, size: 20),
                    const SizedBox(width: 8),
                    Text('Bearish (${_bearishSectors.length})'),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) {
              return IndexedStack(
                index: _tabController.index,
                children: [
                  _buildSectorList(_bullishSectors, true),
                  _buildSectorList(_bearishSectors, false),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonLoader() {
    return Column(
      children: [
        // Tab skeleton
        Container(
          margin: const EdgeInsets.all(16),
          height: 50,
          decoration: BoxDecoration(
            color: _getSkeletonBaseColor(context),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getSkeletonColor(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getSkeletonColor(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Sector cards skeleton
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 6,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                height: 140,
                decoration: BoxDecoration(
                  color: _getSkeletonBaseColor(context),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 150,
                            height: 20,
                            decoration: BoxDecoration(
                              color: _getSkeletonColor(context),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            width: 60,
                            height: 20,
                            decoration: BoxDecoration(
                              color: _getSkeletonColor(context),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            width: 50,
                            height: 30,
                            decoration: BoxDecoration(
                              color: _getSkeletonColor(context),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 50,
                            height: 30,
                            decoration: BoxDecoration(
                              color: _getSkeletonColor(context),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _getSkeletonColor(context),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectorList(List<SectorTrend> sectors, bool isBullish) {
    if (sectors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.color
                    ?.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isBullish
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                size: 48,
                color: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.color
                    ?.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No ${isBullish ? 'bullish' : 'bearish'} sectors',
              style: TextStyle(
                color: Theme.of(context).textTheme.headlineSmall?.color,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for market updates',
              style: TextStyle(
                color: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.color
                    ?.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: sectors.length,
      itemBuilder: (context, index) {
        final sector = sectors[index];
        final isPositive = isBullish;
        final upPercentage = (sector.positiveStocks / sector.totalStocks * 100);
        final downPercentage =
            (sector.negativeStocks / sector.totalStocks * 100);

        // Calculate trend strength for visual elements
        final strength =
            (isBullish ? sector.bullishScore : sector.bearishScore.abs()) / 100;
        final clampedStrength = strength.clamp(0.0, 1.0);

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                // Add haptic feedback for modern feel
                HapticFeedback.lightImpact();
                Get.to(() => SectorStocksPage(
                      sectorName: sector.sectorName,
                      stocks: _sectorData[sector.sectorName] ?? [],
                    ));
              },
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _getCardColor(context),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isPositive
                          ? _getPositiveColor(context).withOpacity(0.08)
                          : _getNegativeColor(context).withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                      spreadRadius: -4,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header with sector name and performance
                    Row(
                      children: [
                        // Sector icon/indicator
                        // Container(
                        //   width: 48,
                        //   height: 48,
                        //   decoration: BoxDecoration(
                        //     gradient: LinearGradient(
                        //       begin: Alignment.topLeft,
                        //       end: Alignment.bottomRight,
                        //       colors: isPositive
                        //           ? [
                        //               _getPositiveColor(context)
                        //                   .withOpacity(0.15),
                        //               _getPositiveColor(context)
                        //                   .withOpacity(0.25),
                        //             ]
                        //           : [
                        //               _getNegativeColor(context)
                        //                   .withOpacity(0.15),
                        //               _getNegativeColor(context)
                        //                   .withOpacity(0.25),
                        //             ],
                        //     ),
                        //     borderRadius: BorderRadius.circular(16),
                        //   ),
                        //   child: Icon(
                        //     isPositive
                        //         ? Icons.trending_up_rounded
                        //         : Icons.trending_down_rounded,
                        //     color: isPositive
                        //         ? _getPositiveColor(context)
                        //         : _getNegativeColor(context),
                        //     size: 24,
                        //   ),
                        // ),

                        const SizedBox(width: 16),

                        // Sector name and stock count
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sector.sectorName,
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.color,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${sector.totalStocks} stocks',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color
                                      ?.withOpacity(0.6),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Performance percentage
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isPositive
                                ? _getPositiveColor(context).withOpacity(0.12)
                                : _getNegativeColor(context).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${isPositive ? '+' : ''}${sector.averageChange.toStringAsFixed(2)}%',
                            style: TextStyle(
                              color: isPositive
                                  ? _getPositiveColor(context)
                                  : _getNegativeColor(context),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Stats row
                    Row(
                      children: [
                        Expanded(
                          child: _buildModernStatItem(
                            'Gainers',
                            sector.positiveStocks.toString(),
                            '${upPercentage.toStringAsFixed(0)}%',
                            _getPositiveColor(context),
                            Icons.arrow_upward_rounded,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildModernStatItem(
                            'Losers',
                            sector.negativeStocks.toString(),
                            '${downPercentage.toStringAsFixed(0)}%',
                            _getNegativeColor(context),
                            Icons.arrow_downward_rounded,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildAdvanceDeclineCompact(sector),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Modern trend strength bar
                    Row(
                      children: [
                        Text(
                          'Strength',
                          style: TextStyle(
                            color: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.color
                                ?.withOpacity(0.7),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${(clampedStrength * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: isPositive
                                ? _getPositiveColor(context)
                                : _getNegativeColor(context),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Glassmorphism progress bar
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.color
                            ?.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 1200),
                            curve: Curves.easeOutCubic,
                            width: (MediaQuery.of(context).size.width - 88) *
                                clampedStrength,
                            height: 6,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isPositive
                                    ? [
                                        _getPositiveColor(context),
                                        _getPositiveColor(context)
                                            .withOpacity(0.7),
                                      ]
                                    : [
                                        _getNegativeColor(context),
                                        _getNegativeColor(context)
                                            .withOpacity(0.7),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernStatItem(
    String title,
    String count,
    String percentage,
    Color color,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 16,
          color: color,
        ),
        const SizedBox(height: 6),
        Text(
          count,
          style: TextStyle(
            color: Theme.of(context).textTheme.headlineSmall?.color,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            color:
                Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.6),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          percentage,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildAdvanceDeclineCompact(SectorTrend sector) {
    double ratio = sector.negativeStocks > 0
        ? sector.positiveStocks / sector.negativeStocks
        : sector.positiveStocks.toDouble();

    Color ratioColor;
    if (ratio > 2) {
      ratioColor = _getPositiveColor(context);
    } else if (ratio > 1) {
      ratioColor = Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFFFFAA00)
          : const Color(0xFFFF8F00);
    } else {
      ratioColor = _getNegativeColor(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.balance_rounded,
          size: 16,
          color: ratioColor,
        ),
        const SizedBox(height: 6),
        Text(
          '${ratio.toStringAsFixed(1)}',
          style: TextStyle(
            color: Theme.of(context).textTheme.headlineSmall?.color,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        Text(
          'A/D Ratio',
          style: TextStyle(
            color:
                Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.6),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          ratio > 2
              ? 'Strong'
              : ratio > 1
                  ? 'Moderate'
                  : 'Weak',
          style: TextStyle(
            color: ratioColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class SectorTrend {
  final String sectorName;
  final int totalStocks;
  final int positiveStocks;
  final int negativeStocks;
  final int above5Percent;
  final int above2Percent;
  final int below2Percent;
  final int below5Percent;
  final double averageChange;
  final double bullishScore;
  final double bearishScore;
  final double totalVolume;

  SectorTrend({
    required this.sectorName,
    required this.totalStocks,
    required this.positiveStocks,
    required this.negativeStocks,
    required this.above5Percent,
    required this.above2Percent,
    required this.below2Percent,
    required this.below5Percent,
    required this.averageChange,
    required this.bullishScore,
    required this.bearishScore,
    required this.totalVolume,
  });
}
