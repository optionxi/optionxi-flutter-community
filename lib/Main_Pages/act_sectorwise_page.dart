import 'package:flutter/material.dart';
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

  Color _getSecondaryCardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2D2D2F)
        : const Color(0xFFF5F5F5);
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

  Widget _buildAdvanceDeclineRatio(SectorTrend sector) {
    double ratio = sector.negativeStocks > 0
        ? sector.positiveStocks / sector.negativeStocks
        : sector.positiveStocks.toDouble();

    String ratioText;
    Color ratioColor;

    if (ratio > 3) {
      ratioText = 'Very Strong';
      ratioColor = _getPositiveColor(context);
    } else if (ratio > 2) {
      ratioText = 'Strong';
      ratioColor = _getPositiveColor(context).withOpacity(0.9);
    } else if (ratio > 1.5) {
      ratioText = 'Moderate';
      ratioColor = Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFFFFAA00)
          : const Color(0xFFFF8F00);
    } else if (ratio > 0.5) {
      ratioText = 'Weak';
      ratioColor = _getNegativeColor(context).withOpacity(0.8);
    } else {
      ratioText = 'Very Weak';
      ratioColor = _getNegativeColor(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'A/D Ratio',
          style: TextStyle(
            color:
                Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
            fontSize: 10,
          ),
        ),
        Text(
          '${ratio.toStringAsFixed(1)}:1',
          style: TextStyle(
            color: ratioColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          ratioText,
          style: TextStyle(
            color: ratioColor,
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
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
            Icon(
              isBullish ? Icons.trending_up : Icons.trending_down,
              size: 64,
              color: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.color
                  ?.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No ${isBullish ? 'bullish' : 'bearish'} sectors found',
              style: TextStyle(
                color: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.color
                    ?.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: sectors.length,
      itemBuilder: (context, index) {
        final sector = sectors[index];
        final isPositive = isBullish;
        final upPercentage = (sector.positiveStocks / sector.totalStocks * 100);
        final downPercentage =
            (sector.negativeStocks / sector.totalStocks * 100);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Get.to(() => SectorStocksPage(
                      sectorName: sector.sectorName,
                      stocks: _sectorData[sector.sectorName] ?? [],
                    ));
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _getCardColor(context),
                      _getSecondaryCardColor(context),
                    ],
                    stops: const [0.0, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).shadowColor.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Animated trend indicator
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 5,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: isPositive
                                ? [
                                    _getPositiveColor(context),
                                    _getPositiveColor(context).withOpacity(0.8),
                                  ]
                                : [
                                    _getNegativeColor(context),
                                    _getNegativeColor(context).withOpacity(0.8),
                                  ],
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            bottomLeft: Radius.circular(20),
                          ),
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
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
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.color
                                            ?.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${sector.totalStocks} stocks',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.color
                                              ?.withOpacity(0.8),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Performance badge and A/D ratio
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  // A/D ratio above the score
                                  _buildAdvanceDeclineRatio(sector),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: isPositive
                                            ? [
                                                _getPositiveColor(context)
                                                    .withOpacity(0.2),
                                                _getPositiveColor(context)
                                                    .withOpacity(0.1),
                                              ]
                                            : [
                                                _getNegativeColor(context)
                                                    .withOpacity(0.2),
                                                _getNegativeColor(context)
                                                    .withOpacity(0.1),
                                              ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isPositive
                                            ? _getPositiveColor(context)
                                                .withOpacity(0.3)
                                            : _getNegativeColor(context)
                                                .withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      '${isPositive ? '+' : ''}${sector.averageChange.toStringAsFixed(2)}%',
                                      style: TextStyle(
                                        color: isPositive
                                            ? _getPositiveColor(context)
                                            : _getNegativeColor(context),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 18,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Trend strength indicator
                          _buildEnhancedTrendIndicator(sector, isBullish),

                          const SizedBox(height: 20),

                          // Gainers and Losers in the same row
                          Row(
                            children: [
                              Expanded(
                                child: _buildEnhancedMetricCard(
                                  'Gainers',
                                  sector.positiveStocks.toString(),
                                  '${upPercentage.toStringAsFixed(0)}%',
                                  _getPositiveColor(context),
                                  Icons.trending_up_rounded,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildEnhancedMetricCard(
                                  'Losers',
                                  sector.negativeStocks.toString(),
                                  '${downPercentage.toStringAsFixed(0)}%',
                                  _getNegativeColor(context),
                                  Icons.trending_down_rounded,
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
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedMetricCard(
    String title,
    String count,
    String percentage,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(
                icon,
                size: 16,
                color: color,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                count,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                percentage,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedTrendIndicator(dynamic sector, bool isBullish) {
    final strength =
        (isBullish ? sector.bullishScore : sector.bearishScore.abs()) / 100;
    final clampedStrength = strength.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Trend Strength',
              style: TextStyle(
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withOpacity(0.8),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${(clampedStrength * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                color: isBullish
                    ? _getPositiveColor(context)
                    : _getNegativeColor(context),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.color
                    ?.withOpacity(0.1),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              height: 6,
              width: MediaQuery.of(context).size.width * 0.7 * clampedStrength,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isBullish
                      ? [
                          _getPositiveColor(context),
                          _getPositiveColor(context).withOpacity(0.8),
                        ]
                      : [
                          _getNegativeColor(context),
                          _getNegativeColor(context).withOpacity(0.8),
                        ],
                ),
                borderRadius: BorderRadius.circular(3),
                boxShadow: [
                  BoxShadow(
                    color: (isBullish
                            ? _getPositiveColor(context)
                            : _getNegativeColor(context))
                        .withOpacity(0.4),
                    blurRadius: 4,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
            ),
          ],
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
