import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:optionxi/Components/trending_stocks_section.dart';
import 'package:optionxi/Helpers/constants.dart';
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
                          child: _buildStockInfo(context)),
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

  Card _buildStockInfo(BuildContext context) {
    final bool isBullish = widget.stock!.sentiment == 'BULLISH';
    final Color sentimentColor = isBullish ? Colors.green : Colors.red;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  // Stock logo
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      height: 44,
                      width: 44,
                      imageUrl: Constants.OptionXiS3Loc +
                          widget.stock!.symbol
                              .replaceAll('-EQ', '')
                              .replaceAll('NSE:', '') +
                          ".png",
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 44,
                        width: 44,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Image.asset(
                          'assets/images/stockdefault.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 44,
                        width: 44,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Image.asset(
                          'assets/images/stockdefault.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Stock info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.stock!.symbol
                              .replaceAll('-EQ', '')
                              .replaceAll('NSE:', ''),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${widget.stock!.price.toStringAsFixed(2)}',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: sentimentColor,
                                letterSpacing: -0.3,
                              ),
                        ),
                      ],
                    ),
                  ),
                  // Sentiment indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: sentimentColor.withOpacity(isDark ? 0.15 : 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.stock!.sentiment,
                      style: TextStyle(
                        color: sentimentColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Description
              Text(
                widget.stock!.shortDescription,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                      height: 1.4,
                    ),
              ),
              if (widget.stock!.dataChecked.isNotEmpty) ...[
                const SizedBox(height: 16),
                // Signals
                ...widget.stock!.dataChecked.map((signal) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            height: 4,
                            width: 4,
                            decoration: BoxDecoration(
                              color: sentimentColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              signal,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.8),
                                    fontWeight: FontWeight.w500,
                                    height: 1.3,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final fontSize = isTablet ? 32.0 : 28.0;
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Theme.of(context).dividerColor, width: 1),
                  ),
                  child: Icon(Icons.navigate_before,
                      color: Theme.of(context).textTheme.titleSmall?.color),
                ),
              ),
              SizedBox(width: 20),
              Text(
                "Trending Stocks",
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          // Text(
          //   "Where each traders are ranked according to their performance in virtual trading, this does not represent real trades.",
          //   style: TextStyle(
          //     color: Theme.of(context).textTheme.titleSmall?.color,
          //     fontSize: descriptionSize,
          //   ),
          // ),
        ],
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
}
