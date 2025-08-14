import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:optionxi/Components/cust_stock_info_card.dart';
import 'package:optionxi/Components/trending_stocks_section.dart';
import 'package:optionxi/Main_Pages/cust_top_stocks_component.dart';

class TopRecommendedStockPage extends StatefulWidget {
  final StockData? stock;

  const TopRecommendedStockPage({Key? key, this.stock}) : super(key: key);

  @override
  State<TopRecommendedStockPage> createState() =>
      _TopRecommendedStockPageState();
}

class _TopRecommendedStockPageState extends State<TopRecommendedStockPage>
    with TickerProviderStateMixin {
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
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    if (widget.stock != null) ...[
                      InkWell(
                          onTap: () {
                            Get.toNamed(
                                '/stocks/${widget.stock!.symbol.toUpperCase()}');
                          },
                          child: ModernStockCard(stock: widget.stock!)),
                      const SizedBox(height: 24),
                    ],

                    // Header
                    Row(
                      crossAxisAlignment: CrossAxisAlignment
                          .start, // Good for multi-line text alignment

                      children: [
                        Expanded(
                          child: Text(
                            'These stock selections are filtered using technical indicators and are provided for educational purposes only. They do not constitute financial advice.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: _showInfoDialog,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildStocksTabSection(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStocksTabSection() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withValues(alpha: 0.08),
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
            labelColor: Colors.white,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurface,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
            tabs: const [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.trending_up, size: 20),
                    SizedBox(width: 8),
                    Text('Bullish'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.trending_down, size: 20),
                    SizedBox(width: 8),
                    Text('Bearish'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AnimatedBuilder(
          animation: _tabController,
          builder: (context, _) {
            return IndexedStack(
              index: _tabController.index,
              children: const [
                TopStocksHeatMap(category: 'bullish'),
                TopStocksHeatMap(category: 'bearish'),
              ],
            );
          },
        ),
      ],
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'About Signal Count',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'The signal count represents the number of technical screeners that have identified this stock with a bullish/bearish trend.',
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 12),
              Text(
                'A higher signal count indicates stronger consensus across multiple technical indicators, suggesting a higher probability of price movement in the bullish/bearish direction.',
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 12),
              const Text(
                'This metric combines various technical analyses to provide a comprehensive view of market sentiment, helping you identify stocks with the strongest directional signals.',
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).dividerColor.withOpacity(0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Trending Stocks",
                    style: TextStyle(
                      fontSize: isTablet ? 32.0 : 28.0,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                      letterSpacing: -0.8,
                    ),
                  ),
                  Text(
                    "Market insights & analysis",
                    style: TextStyle(
                      color: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.color
                          ?.withOpacity(0.6),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
