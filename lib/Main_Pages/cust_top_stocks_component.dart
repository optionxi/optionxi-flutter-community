import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:optionxi/Helpers/constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// models/top_stock.dart
class TopStock {
  final String symbol;
  final String stockName;
  final int signalCount;
  final double lastPrice;
  final double percentChange;
  final double open;
  final double high;
  final double low;
  final double close;
  final String? sector;

  TopStock({
    required this.symbol,
    required this.stockName,
    required this.signalCount,
    required this.lastPrice,
    required this.percentChange,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    this.sector,
  });

  factory TopStock.fromJson(Map<String, dynamic> json) {
    return TopStock(
      symbol: json['symbol'] ?? '',
      stockName: json['stockName'] ?? '',
      signalCount: json['signalCount'] ?? 0,
      lastPrice: (json['lastPrice'] ?? 0).toDouble(),
      percentChange: (json['percentChange'] ?? 0).toDouble(),
      open: (json['open'] ?? 0).toDouble(),
      high: (json['high'] ?? 0).toDouble(),
      low: (json['low'] ?? 0).toDouble(),
      close: (json['close'] ?? 0).toDouble(),
      sector: json['sector'],
    );
  }
}

class StockService {
  final SupabaseClient supabase;

  StockService(this.supabase);

  Future<List<TopStock>> fetchTopStocks({
    required String category, // 'bullish' or 'bearish'
    int limit = 10,
  }) async {
    try {
      // First, get stocks that appear most frequently in screener results for the given category
      final response = await supabase
          .from('screener_results')
          .select('''
            id,
            screener_id,
            scan_date,
            close,
            high,
            low,
            open,
            pcnt,
            sec,
            stckname,
            vol,
            screener_names!inner(category)
          ''')
          .eq('screener_names.category', category)
          .order('scan_date', ascending: false);

      // The response is already the data - no need to check for error property
      final data = response as List<dynamic>;

      // Process the data to count occurrences and get latest data for each stock
      final stockSignalMap = <String, TopStock>{};

      for (final item in data) {
        // Use stckname as the symbol identifier
        final symbol = item['stckname'] as String?;
        if (symbol == null) continue;

        if (!stockSignalMap.containsKey(symbol)) {
          stockSignalMap[symbol] = TopStock(
            symbol: symbol,
            stockName: item['stckname'] as String? ?? symbol,
            signalCount: 1,
            lastPrice: (item['close'] as num?)?.toDouble() ?? 0,
            percentChange: (item['pcnt'] as num?)?.toDouble() ?? 0,
            open: (item['open'] as num?)?.toDouble() ?? 0,
            high: (item['high'] as num?)?.toDouble() ?? 0,
            low: (item['low'] as num?)?.toDouble() ?? 0,
            close: (item['close'] as num?)?.toDouble() ?? 0,
            sector: item['sec'] as String?,
          );
        } else {
          final stockData = stockSignalMap[symbol]!;
          stockSignalMap[symbol] = TopStock(
            symbol: stockData.symbol,
            stockName: stockData.stockName,
            signalCount: stockData.signalCount + 1,
            lastPrice:
                (item['close'] as num?)?.toDouble() ?? stockData.lastPrice,
            percentChange:
                (item['pcnt'] as num?)?.toDouble() ?? stockData.percentChange,
            open: (item['open'] as num?)?.toDouble() ?? stockData.open,
            high: (item['high'] as num?)?.toDouble() ?? stockData.high,
            low: (item['low'] as num?)?.toDouble() ?? stockData.low,
            close: (item['close'] as num?)?.toDouble() ?? stockData.close,
            sector: item['sec'] as String? ?? stockData.sector,
          );
        }
      }

      // Convert map to array and sort by signal count
      final topStocks = stockSignalMap.values.toList()
        ..sort((a, b) => b.signalCount.compareTo(a.signalCount));

      return topStocks.take(limit).toList();
    } catch (error) {
      print('Error fetching top stocks: $error');
      return [];
    }
  }
}

class StockItemHeatMap extends StatefulWidget {
  final TopStock stock;
  final VoidCallback? onTap;

  const StockItemHeatMap({
    Key? key,
    required this.stock,
    this.onTap,
  }) : super(key: key);

  @override
  State<StockItemHeatMap> createState() => _StockItemHeatMapState();
}

class _StockItemHeatMapState extends State<StockItemHeatMap>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  ColorScheme _getColorScheme(double percentage) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (percentage >= 15) {
      return ColorScheme(
        background: isDark ? const Color(0x4D4CAF50) : const Color(0x334CAF50),
        text: isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32),
        border: isDark ? const Color(0x664CAF50) : const Color(0x4D4CAF50),
      );
    } else if (percentage >= 10) {
      return ColorScheme(
        background: isDark ? const Color(0x4D66BB6A) : const Color(0x3366BB6A),
        text: isDark ? const Color(0xFFA5D6A7) : const Color(0xFF388E3C),
        border: isDark ? const Color(0x6666BB6A) : const Color(0x4D66BB6A),
      );
    } else if (percentage >= 5) {
      return ColorScheme(
        background: isDark ? const Color(0x4D81C784) : const Color(0x3381C784),
        text: isDark ? const Color(0xFFC8E6C9) : const Color(0xFF43A047),
        border: isDark ? const Color(0x6681C784) : const Color(0x4D81C784),
      );
    } else if (percentage >= 2) {
      return ColorScheme(
        background: isDark ? const Color(0x4DA5D6A7) : const Color(0x33A5D6A7),
        text: isDark ? const Color(0xFFE8F5E9) : const Color(0xFF4CAF50),
        border: isDark ? const Color(0x66A5D6A7) : const Color(0x4DA5D6A7),
      );
    } else if (percentage >= 0) {
      return ColorScheme(
        background: isDark ? const Color(0x4DC8E6C9) : const Color(0x33C8E6C9),
        text: isDark ? const Color(0xFFE8F5E9) : const Color(0xFF66BB6A),
        border: isDark ? const Color(0x66C8E6C9) : const Color(0x4DC8E6C9),
      );
    } else if (percentage >= -2) {
      return ColorScheme(
        background: isDark ? const Color(0x4DFFCDD2) : const Color(0x33FFCDD2),
        text: isDark ? const Color(0xFFFFCDD2) : const Color(0xFFE53935),
        border: isDark ? const Color(0x66FFCDD2) : const Color(0x4DFFCDD2),
      );
    } else if (percentage >= -5) {
      return ColorScheme(
        background: isDark ? const Color(0x4DEF9A9A) : const Color(0x33EF9A9A),
        text: isDark ? const Color(0xFFEF9A9A) : const Color(0xFFD32F2F),
        border: isDark ? const Color(0x66EF9A9A) : const Color(0x4DEF9A9A),
      );
    } else if (percentage >= -10) {
      return ColorScheme(
        background: isDark ? const Color(0x4DE57373) : const Color(0x33E57373),
        text: isDark ? const Color(0xFFE57373) : const Color(0xFFC62828),
        border: isDark ? const Color(0x66E57373) : const Color(0x4DE57373),
      );
    } else if (percentage >= -15) {
      return ColorScheme(
        background: isDark ? const Color(0x4DF44336) : const Color(0x33F44336),
        text: isDark ? const Color(0xFFF44336) : const Color(0xFFB71C1C),
        border: isDark ? const Color(0x66F44336) : const Color(0x4DF44336),
      );
    } else {
      return ColorScheme(
        background: isDark ? const Color(0x4DC62828) : const Color(0x33C62828),
        text: isDark ? const Color(0xFFEF5350) : const Color(0xFFB71C1C),
        border: isDark ? const Color(0x66C62828) : const Color(0x4DC62828),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = _getColorScheme(widget.stock.percentChange);
    final stockSymbol = widget.stock.stockName.split(":").length > 1
        ? widget.stock.stockName.split(":")[1].split("-")[0]
        : widget.stock.stockName;
    final exchange = widget.stock.stockName.split(":")[0];

    final theme = Theme.of(context);
    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  margin: const EdgeInsets.all(4),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colorScheme.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Stock Logo
                      CachedNetworkImage(
                        height: 40,
                        width: 40,
                        imageUrl:
                            Constants.OptionXiS3Loc + stockSymbol + ".png",
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              stockSymbol.isNotEmpty ? stockSymbol[0] : 'S',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: theme.textTheme.titleLarge?.color,
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: Image.asset(
                            'assets/images/stockdefault.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Stock Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  stockSymbol,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.text,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    // color: Colors.white.withValues(alpha:0.8),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    widget.stock.percentChange >= 0
                                        ? Icons.trending_up
                                        : Icons.trending_down,
                                    size: 12,
                                    color: colorScheme.text,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              exchange,
                              style: TextStyle(
                                fontSize: 12,
                                // color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Price Info
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${widget.stock.lastPrice.toStringAsFixed(1)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            '${widget.stock.percentChange.toStringAsFixed(2)}%',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.text,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Signal Count Badge - iOS style notification
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      widget.stock.signalCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class ColorScheme {
  final Color background;
  final Color text;
  final Color border;

  ColorScheme({
    required this.background,
    required this.text,
    required this.border,
  });
}

class LoadingSkeleton extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const LoadingSkeleton({
    Key? key,
    this.width,
    this.height,
    this.borderRadius,
  }) : super(key: key);

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                (_animation.value - 1).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 1).clamp(0.0, 1.0),
              ],
              colors: isDark
                  ? [
                      Colors.grey[800]!,
                      Colors.grey[700]!,
                      Colors.grey[800]!,
                    ]
                  : [
                      Colors.grey[300]!,
                      Colors.grey[200]!,
                      Colors.grey[300]!,
                    ],
            ),
          ),
        );
      },
    );
  }
}

class StockItemSkeleton extends StatelessWidget {
  const StockItemSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo skeleton
          LoadingSkeleton(
            width: 40,
            height: 40,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(width: 12),

          // Content skeleton
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    LoadingSkeleton(
                      width: 60,
                      height: 16,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(width: 8),
                    LoadingSkeleton(
                      width: 20,
                      height: 20,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LoadingSkeleton(
                  width: 40,
                  height: 12,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),

          // Price skeleton
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              LoadingSkeleton(
                width: 70,
                height: 16,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 4),
              LoadingSkeleton(
                width: 50,
                height: 14,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TopStocksHeatMap extends StatefulWidget {
  final String category; // 'bullish' or 'bearish'
  final int limit;
  final Function(TopStock)? onStockTap;

  const TopStocksHeatMap({
    Key? key,
    required this.category,
    this.limit = 10,
    this.onStockTap,
  }) : super(key: key);

  @override
  State<TopStocksHeatMap> createState() => _TopStocksHeatMapState();
}

class _TopStocksHeatMapState extends State<TopStocksHeatMap> {
  List<TopStock> stocks = [];
  bool isLoading = true;
  String? errorMessage;
  bool showInfoDialog = false;

  @override
  void initState() {
    super.initState();

    _loadStocks();
  }

  @override
  void didUpdateWidget(TopStocksHeatMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category != widget.category ||
        oldWidget.limit != widget.limit) {
      _loadStocks();
    }
  }

  Future<void> _loadStocks() async {
    if (!mounted) return; // Check if widget is still in the tree
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Call fetchTopStocks on the _stockService instance
      final supabase = Supabase.instance.client;
      final stockService = StockService(supabase);
      final fetchedStocks = await stockService.fetchTopStocks(
        category: widget.category,
        limit: widget.limit,
      );

      if (!mounted) return; // Check again before updating state
      setState(() {
        stocks = fetchedStocks;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        // Provide a user-friendly message and log the detailed error
        errorMessage = 'Failed to load stock data. Please try again.';
        debugPrint('Error in _loadStocks: $e'); // Use debugPrint for Flutter
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Content
          if (isLoading)
            _buildLoadingState()
          else if (errorMessage != null)
            _buildErrorState()
          else if (stocks.isEmpty)
            _buildEmptyState()
          else
            _buildStocksList(),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: List.generate(
        10,
        (index) => const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: StockItemSkeleton(),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red[600],
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              errorMessage!,
              style: TextStyle(
                color: Colors.red[600],
                fontSize: 14,
              ),
            ),
          ),
          TextButton(
            onPressed: _loadStocks,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.trending_up,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No ${widget.category} stocks found',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try refreshing or check back later',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStocksList() {
    return Column(
      children: stocks.map((stock) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: StockItemHeatMap(
            stock: stock,
            onTap: () {
              Get.toNamed('/stocks/${(stock.stockName.toUpperCase())}');
            },
          ),
        );
      }).toList(),
    );
  }
}

// Separate components for bullish and bearish
class BullishStocksHeatMap extends StatelessWidget {
  final int limit;
  final Function(TopStock)? onStockTap;

  const BullishStocksHeatMap({
    Key? key,
    this.limit = 10,
    this.onStockTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TopStocksHeatMap(
      category: 'bullish',
      limit: limit,
      onStockTap: onStockTap,
    );
  }
}

class BearishStocksHeatMap extends StatelessWidget {
  final int limit;
  final Function(TopStock)? onStockTap;

  const BearishStocksHeatMap({
    Key? key,
    this.limit = 10,
    this.onStockTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TopStocksHeatMap(
      category: 'bearish',
      limit: limit,
      onStockTap: onStockTap,
    );
  }
}
