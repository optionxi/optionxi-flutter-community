import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:optionxi/Helpers/constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Added import

// Modern Category Selector replacement
class ModernCategorySelector extends StatelessWidget {
  final String selectedCategory;
  final Function(String) onCategoryChanged;

  const ModernCategorySelector({
    Key? key,
    required this.selectedCategory,
    required this.onCategoryChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final categories = [
      {'value': 'all', 'label': 'All'},
      {'value': 'nifty50', 'label': 'Nifty 50'},
      {'value': 'nifty200', 'label': 'Nifty 200'},
    ];

    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDarkMode ? Colors.grey[850] : Colors.grey[200],
      ),
      child: Row(
        children: categories.map((category) {
          final isSelected = selectedCategory == category['value'];
          return Expanded(
            child: GestureDetector(
              onTap: () => onCategoryChanged(category['value']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    category['label']!,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : isDarkMode
                              ? Colors.white70
                              : Colors.black87,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

enum StockMarketTab { topGainers, topLosers, topVolume }

class TopGainersLosersPage extends StatefulWidget {
  final StockMarketTab? initialTab;

  const TopGainersLosersPage({
    Key? key,
    this.initialTab,
  }) : super(key: key);

  @override
  State<TopGainersLosersPage> createState() => _TopGainersLosersPageState();
}

class _TopGainersLosersPageState extends State<TopGainersLosersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab?.index ?? 0,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _changeCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  Widget _buildStocksTabSection() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    Icon(Icons.trending_up, size: 18),
                    SizedBox(width: 8),
                    Text('Gainers'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.trending_down, size: 18),
                    SizedBox(width: 8),
                    Text('Losers'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bar_chart, size: 18),
                    SizedBox(width: 8),
                    Text('Volume'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ModernCategorySelector(
          selectedCategory: _selectedCategory,
          onCategoryChanged: _changeCategory,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) {
              return IndexedStack(
                index: _tabController.index,
                children: [
                  TopGainersSection(selectedCategory: _selectedCategory),
                  TopLosersSection(selectedCategory: _selectedCategory),
                  TopVolumeSection(selectedCategory: _selectedCategory),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Market Movers'),
      ),
      body: _buildStocksTabSection(),
    );
  }
}

// Model class
class TopGainerLoserData {
  final String stckname; // Used as stockSymbol for logo
  final double close;
  final double open;
  final double high;
  final double low;
  final double vol;
  final double vol2;
  final double vol3;
  final double vol4;
  final double vol5;
  final double pcnt;
  final String sec;
  final double pc;
  final double pc2;
  final double pc3;
  final double pc4;
  final double pc5;
  final double pc6;
  final double pc7;
  final String fname;
  final double max52;
  final double min52;

  TopGainerLoserData({
    required this.stckname,
    required this.close,
    required this.open,
    required this.high,
    required this.low,
    required this.vol,
    required this.vol2,
    required this.vol3,
    required this.vol4,
    required this.vol5,
    required this.pcnt,
    required this.sec,
    required this.pc,
    required this.pc2,
    required this.pc3,
    required this.pc4,
    required this.pc5,
    required this.pc6,
    required this.pc7,
    required this.fname,
    required this.max52,
    required this.min52,
  });

  factory TopGainerLoserData.fromJson(Map<String, dynamic> json) {
    return TopGainerLoserData(
      stckname: json['stckname'] ?? '',
      close: (json['close'] ?? 0).toDouble(),
      open: (json['open'] ?? 0).toDouble(),
      high: (json['high'] ?? 0).toDouble(),
      low: (json['low'] ?? 0).toDouble(),
      vol: (json['vol'] ?? 0).toDouble(),
      vol2: (json['vol2'] ?? 0).toDouble(),
      vol3: (json['vol3'] ?? 0).toDouble(),
      vol4: (json['vol4'] ?? 0).toDouble(),
      vol5: (json['vol5'] ?? 0).toDouble(),
      pcnt: (json['pcnt'] ?? 0).toDouble(),
      sec: json['sec'] ?? '',
      pc: (json['pc'] ?? 0).toDouble(),
      pc2: (json['pc2'] ?? 0).toDouble(),
      pc3: (json['pc3'] ?? 0).toDouble(),
      pc4: (json['pc4'] ?? 0).toDouble(),
      pc5: (json['pc5'] ?? 0).toDouble(),
      pc6: (json['pc6'] ?? 0).toDouble(),
      pc7: (json['pc7'] ?? 0).toDouble(),
      fname: json['fname'] ?? '',
      max52: (json['max52'] ?? 0).toDouble(),
      min52: (json['min52'] ?? 0).toDouble(),
    );
  }

  List<double> get performanceList => [pc7, pc6, pc5, pc4, pc3, pc2, pc];
  List<double> get closePrices => [pc7, pc6, pc5, pc4, pc3, pc2, pc, close];

  double get averageVolume => (vol + vol2 + vol3 + vol4 + vol5) / 5;
}

// Supabase service
class StockDataService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<TopGainerLoserData>> fetchTopGainers(String category) async {
    String tableName;

    switch (category.toLowerCase()) {
      case 'all':
        tableName = 'top_gainers_all';
        break;
      case 'nifty50':
        tableName = 'top_gainers_nifty50';
        break;
      case 'nifty200':
        tableName = 'top_gainers_nifty200';
        break;
      default:
        throw Exception('Invalid category specified');
    }

    try {
      final response = await _supabase
          .from(tableName)
          .select()
          .order('pcnt', ascending: false);

      return (response as List)
          .map((record) => TopGainerLoserData.fromJson(record))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch top gainers: $e');
    }
  }

  Future<List<TopGainerLoserData>> fetchTopLosers(String category) async {
    String tableName;

    switch (category.toLowerCase()) {
      case 'all':
        tableName = 'top_losers_all';
        break;
      case 'nifty50':
        tableName = 'top_losers_nifty50';
        break;
      case 'nifty200':
        tableName = 'top_losers_nifty200';
        break;
      default:
        throw Exception('Invalid category specified');
    }

    try {
      final response = await _supabase
          .from(tableName)
          .select()
          .order('pcnt', ascending: true);

      return (response as List)
          .map((record) => TopGainerLoserData.fromJson(record))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch top losers: $e');
    }
  }

  Future<List<TopGainerLoserData>> fetchTopVolume(String category) async {
    String tableName;

    switch (category.toLowerCase()) {
      case 'all':
        tableName = 'top_volume_all';
        break;
      case 'nifty50':
        tableName = 'top_volume_nifty50';
        break;
      case 'nifty200':
        tableName = 'top_volume_nifty200';
        break;
      default:
        throw Exception('Invalid category specified');
    }

    try {
      final response = await _supabase
          .from(tableName)
          .select()
          .order('vol', ascending: false);

      return (response as List)
          .map((record) => TopGainerLoserData.fromJson(record))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch top volume: $e');
    }
  }
}

class StockCardSkeleton extends StatefulWidget {
  const StockCardSkeleton({Key? key}) : super(key: key);

  @override
  State<StockCardSkeleton> createState() => _StockCardSkeletonState();
}

class _StockCardSkeletonState extends State<StockCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final skeletonColor = isDarkMode ? Colors.grey[800] : Colors.grey[300];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Opacity(
              opacity: _animation.value,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Logo and Stock Info Skeleton
                      Expanded(
                        child: Row(
                          children: [
                            // Logo skeleton
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: skeletonColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Stock name skeleton
                                  Container(
                                    height: 16,
                                    width: 80,
                                    decoration: BoxDecoration(
                                      color: skeletonColor,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Sector skeleton
                                  Container(
                                    height: 12,
                                    width: 120,
                                    decoration: BoxDecoration(
                                      color: skeletonColor,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Price and Percentage Skeleton
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Price skeleton
                          Container(
                            height: 16,
                            width: 60,
                            decoration: BoxDecoration(
                              color: skeletonColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Percentage skeleton
                          Container(
                            height: 14,
                            width: 50,
                            decoration: BoxDecoration(
                              color: skeletonColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Chart skeleton
                  Container(
                    height: 80,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: skeletonColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Bottom info skeleton
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 12,
                            width: 60,
                            decoration: BoxDecoration(
                              color: skeletonColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 14,
                            width: 100,
                            decoration: BoxDecoration(
                              color: skeletonColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            height: 12,
                            width: 40,
                            decoration: BoxDecoration(
                              color: skeletonColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 14,
                            width: 50,
                            decoration: BoxDecoration(
                              color: skeletonColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class TopGainersSection extends StatefulWidget {
  final String selectedCategory;

  const TopGainersSection({
    Key? key,
    required this.selectedCategory,
  }) : super(key: key);

  @override
  State<TopGainersSection> createState() => _TopGainersSectionState();
}

class _TopGainersSectionState extends State<TopGainersSection> {
  final StockDataService _stockDataService = StockDataService();
  List<TopGainerLoserData> _stocksData = [];
  bool _loading = true;
  // String? _selectedStock; // Not strictly needed here if details are in bottom sheet

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void didUpdateWidget(TopGainersSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCategory != widget.selectedCategory) {
      _fetchData();
    }
  }

  Future<void> _fetchData() async {
    setState(() {
      _loading = true;
    });

    try {
      final data =
          await _stockDataService.fetchTopGainers(widget.selectedCategory);
      setState(() {
        _stocksData = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      if (mounted) {
        // Check if widget is still in the tree
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching data: $e')),
        );
      }
    }
  }

  void _showStockDetails(TopGainerLoserData stock) {
    // setState(() { // Not needed to set _selectedStock here if not used elsewhere
    //   _selectedStock = stock.stckname;
    // });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => StockDetailBottomSheet(
        stockData: stock,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return ListView.builder(
        itemCount: 10, // Show 10 skeleton cards
        itemBuilder: (context, index) => const StockCardSkeleton(),
      );
    }

    if (_stocksData.isEmpty) {
      return Center(child: _buildEmptyState());
    }

    return ListView.builder(
      itemCount: _stocksData.length,
      itemBuilder: (context, index) {
        final stock = _stocksData[index];
        return StockCard(
          stock: stock,
          onTap: () => _showStockDetails(stock),
        );
      },
    );
  }
}

class TopLosersSection extends StatefulWidget {
  final String selectedCategory;

  const TopLosersSection({
    Key? key,
    required this.selectedCategory,
  }) : super(key: key);

  @override
  State<TopLosersSection> createState() => _TopLosersSectionState();
}

class _TopLosersSectionState extends State<TopLosersSection> {
  final StockDataService _stockDataService = StockDataService();
  List<TopGainerLoserData> _stocksData = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void didUpdateWidget(TopLosersSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCategory != widget.selectedCategory) {
      _fetchData();
    }
  }

  Future<void> _fetchData() async {
    setState(() {
      _loading = true;
    });

    try {
      final data =
          await _stockDataService.fetchTopLosers(widget.selectedCategory);
      setState(() {
        _stocksData = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching data: $e')),
        );
      }
    }
  }

  void _showStockDetails(TopGainerLoserData stock) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => StockDetailBottomSheet(
        stockData: stock,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return ListView.builder(
        itemCount: 10, // Show 10 skeleton cards
        itemBuilder: (context, index) => const StockCardSkeleton(),
      );
    }

    if (_stocksData.isEmpty) {
      return Center(child: _buildEmptyState());
    }

    return ListView.builder(
      itemCount: _stocksData.length,
      itemBuilder: (context, index) {
        final stock = _stocksData[index];
        return StockCard(
          stock: stock,
          onTap: () => _showStockDetails(stock),
        );
      },
    );
  }
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
          'No stocks found',
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

class TopVolumeSection extends StatefulWidget {
  final String selectedCategory;

  const TopVolumeSection({
    Key? key,
    required this.selectedCategory,
  }) : super(key: key);

  @override
  State<TopVolumeSection> createState() => _TopVolumeSectionState();
}

class _TopVolumeSectionState extends State<TopVolumeSection> {
  final StockDataService _stockDataService = StockDataService();
  List<TopGainerLoserData> _stocksData = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void didUpdateWidget(TopVolumeSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCategory != widget.selectedCategory) {
      _fetchData();
    }
  }

  Future<void> _fetchData() async {
    setState(() {
      _loading = true;
    });

    try {
      final data =
          await _stockDataService.fetchTopVolume(widget.selectedCategory);
      setState(() {
        _stocksData = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching data: $e')),
        );
      }
    }
  }

  void _showStockDetails(TopGainerLoserData stock) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => StockDetailBottomSheet(
        stockData: stock,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return ListView.builder(
        itemCount: 10, // Show 10 skeleton cards
        itemBuilder: (context, index) => const StockCardSkeleton(),
      );
    }

    if (_stocksData.isEmpty) {
      return Center(child: _buildEmptyState());
    }

    return ListView.builder(
      itemCount: _stocksData.length,
      itemBuilder: (context, index) {
        final stock = _stocksData[index];
        return StockCard(
          stock: stock,
          onTap: () => _showStockDetails(stock),
        );
      },
    );
  }
}

class StockCard extends StatelessWidget {
  final TopGainerLoserData stock;
  final VoidCallback onTap;

  const StockCard({
    Key? key,
    required this.stock,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final percentageColor = stock.pcnt >= 0 ? Colors.green : Colors.red;
    final currencyFormatter = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 2,
    );
    final percentFormatter = NumberFormat.percentPattern();
    percentFormatter.maximumFractionDigits = 2;
    final volumeFormatter = NumberFormat.compact();
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final String stockSymbol = stock.stckname;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo and Stock Info
                  Expanded(
                    child: Row(
                      children: [
                        CachedNetworkImage(
                          height: 40,
                          width: 40,
                          imageUrl: Constants.OptionXiS3Loc +
                              stockSymbol.split("-")[0].split(":")[1] +
                              ".png",
                          fit: BoxFit
                              .contain, // BoxFit.cover might crop, contain is safer
                          placeholder: (context, url) => Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? Colors.grey[800]
                                  : Colors.grey[200],
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
                            borderRadius: BorderRadius.circular(
                                20), // Circular for consistency with placeholder
                            child: Image.asset(
                              // Ensure this asset exists in your project
                              'assets/images/stockdefault.png',
                              height: 40,
                              width: 40,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stock.stckname.split("-")[0].split(":")[1],
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                stock.sec,
                                style: theme.textTheme.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8), // Spacing before price column
                  // Price and Percentage
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currencyFormatter.format(stock.close),
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            stock.pcnt >= 0
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            color: percentageColor,
                            size: 16,
                          ),
                          Text(
                            percentFormatter.format(stock.pcnt / 100),
                            style: TextStyle(
                              color: percentageColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 80,
                child: SfCartesianChart(
                  margin: EdgeInsets.zero,
                  plotAreaBorderWidth: 0,
                  primaryXAxis: NumericAxis(isVisible: false),
                  primaryYAxis: NumericAxis(isVisible: false),
                  series: <CartesianSeries>[
                    LineSeries<double, int>(
                      dataSource: stock.closePrices,
                      xValueMapper: (_, index) => index,
                      yValueMapper: (value, _) => value,
                      color: percentageColor,
                      width: 2,
                    )
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Day Range',
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        '${currencyFormatter.format(stock.low)} - ${currencyFormatter.format(stock.high)}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Volume',
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        volumeFormatter.format(stock.vol),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StockDetailBottomSheet extends StatelessWidget {
  final TopGainerLoserData stockData;

  const StockDetailBottomSheet({
    Key? key,
    required this.stockData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final percentageColor = stockData.pcnt >= 0 ? Colors.green : Colors.red;
    final currencyFormatter = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 2,
    );
    final percentFormatter = NumberFormat.percentPattern();
    percentFormatter.maximumFractionDigits = 2;
    final volumeFormatter = NumberFormat.compact();
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final String stockSymbol = stockData.stckname;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Padding(
          // Added padding around the sheet content
          padding: const EdgeInsets.only(
              top: 16.0, left: 16.0, right: 16.0, bottom: 8.0),
          child: ListView(
            controller: scrollController,
            // padding: const EdgeInsets.all(16), // Removed padding from ListView, added to parent
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CachedNetworkImage(
                    height: 50,
                    width: 50,
                    imageUrl: Constants.OptionXiS3Loc +
                        stockSymbol.split("-")[0].split(":")[1] +
                        ".png",
                    fit: BoxFit.contain,
                    placeholder: (context, url) => Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          stockSymbol.isNotEmpty ? stockSymbol[0] : 'S',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: theme.textTheme.titleLarge?.color,
                          ),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: Image.asset(
                        'assets/images/stockdefault.png', // Ensure this asset exists
                        height: 50,
                        width: 50,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stockData.stckname.split("-")[0].split(":")[1],
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          stockData.fname,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          stockData.sec,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    currencyFormatter.format(stockData.close),
                    style: theme.textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Icon(
                        stockData.pcnt >= 0
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        color: percentageColor,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        percentFormatter.format(stockData.pcnt / 100),
                        style: TextStyle(
                          color: percentageColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                height: 44,
                margin: const EdgeInsets.only(bottom: 16),
                child: ElevatedButton(
                  onPressed: () {
                    Get.toNamed('/stocks/${stockSymbol.toUpperCase()}');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ).copyWith(
                    overlayColor: MaterialStateProperty.resolveWith<Color?>(
                      (Set<MaterialState> states) {
                        if (states.contains(MaterialState.pressed)) {
                          return Colors.white.withValues(alpha: 0.1);
                        }
                        if (states.contains(MaterialState.hovered)) {
                          return Colors.white.withValues(alpha: 0.05);
                        }
                        return null;
                      },
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        size: 18,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'More Stock Details',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 200,
                child: SfCartesianChart(
                  margin: EdgeInsets.zero,
                  plotAreaBorderWidth: 0,
                  primaryXAxis: NumericAxis(isVisible: false),
                  primaryYAxis: NumericAxis(
                      isVisible: false,
                      opposedPosition: true), // Shows axis on right
                  series: <CartesianSeries>[
                    LineSeries<double, int>(
                      dataSource: stockData.closePrices,
                      xValueMapper: (_, index) => index,
                      yValueMapper: (value, _) => value,
                      color: percentageColor,
                      width: 2.5,
                    )
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Price Information',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                context,
                'Open',
                currencyFormatter.format(stockData.open),
                'Prev. Close', // Changed label for clarity
                currencyFormatter.format(
                    stockData.pc), // Using stockData.pc for Previous Close
              ),
              const Divider(height: 20),
              _buildDetailRow(
                context,
                'Day High',
                currencyFormatter.format(stockData.high),
                'Day Low',
                currencyFormatter.format(stockData.low),
              ),
              const Divider(height: 20),
              _buildDetailRow(
                context,
                '52W High',
                currencyFormatter.format(stockData.max52),
                '52W Low',
                currencyFormatter.format(stockData.min52),
              ),
              const SizedBox(height: 24),
              Text(
                'Volume Information',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                context,
                'Volume',
                volumeFormatter.format(stockData.vol),
                'Avg Volume (5D)',
                volumeFormatter.format(stockData.averageVolume),
              ),
              const SizedBox(height: 24),
              Text(
                'Historical Prices',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildHistoricalPricesTable(
                  context, stockData, currencyFormatter, percentFormatter),
              const SizedBox(height: 20), // Add some padding at the bottom
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label1,
    String value1,
    String label2,
    String value2,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label1,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value1,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label2,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value2,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistoricalPricesTable(
    BuildContext context,
    TopGainerLoserData stock,
    NumberFormat currencyFormatter,
    NumberFormat percentFormatter, // Pass the formatter
  ) {
    final theme = Theme.of(context);
    final historicalPriceData = [
      {'label': 'Today', 'current': stock.close, 'previous': stock.pc},
      {'label': 'Day 1 (Prev)', 'current': stock.pc, 'previous': stock.pc2},
      {'label': 'Day 2', 'current': stock.pc2, 'previous': stock.pc3},
      {'label': 'Day 3', 'current': stock.pc3, 'previous': stock.pc4},
      {'label': 'Day 4', 'current': stock.pc4, 'previous': stock.pc5},
      {'label': 'Day 5', 'current': stock.pc5, 'previous': stock.pc6},
      {'label': 'Day 6', 'current': stock.pc6, 'previous': stock.pc7},
      {
        'label': 'Day 7',
        'current': stock.pc7,
        'previous': null
      }, // No previous for the oldest data point
    ];

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1.2), // Period
        1: FlexColumnWidth(1.5), // Close Price
        2: FlexColumnWidth(1.3), // Change %
      },
      border: TableBorder(
        horizontalInside: BorderSide(
          color: theme.dividerColor,
          width: 1,
        ),
        // Optional: add a bottom border to the header
        // top: BorderSide(color: theme.dividerColor, width: 1),
        bottom: BorderSide(color: theme.dividerColor, width: 1),
      ),
      children: [
        TableRow(
          decoration: BoxDecoration(
              color: theme.highlightColor.withValues(alpha: 0.05)),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: Text('Period',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: Text('Close Price',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: Text('Change %',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        ...historicalPriceData.map((priceData) {
          double? percentageChange;
          Color changeColor = theme.textTheme.bodyMedium?.color ?? Colors.black;

          if (priceData['previous'] != null &&
              (priceData['previous'] as double) != 0) {
            percentageChange = ((priceData['current'] as double) -
                    (priceData['previous'] as double)) /
                (priceData['previous'] as double);
            if (percentageChange > 0) {
              changeColor = Colors.green;
            } else if (percentageChange < 0) {
              changeColor = Colors.red;
            }
          }

          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Text(priceData['label'] as String,
                    style: theme.textTheme.bodyMedium),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Text(
                  currencyFormatter.format(priceData['current']),
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Text(
                  percentageChange != null
                      ? percentFormatter.format(percentageChange)
                      : 'N/A',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: changeColor,
                    fontWeight: percentageChange != null
                        ? FontWeight.w500
                        : FontWeight.normal,
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ],
    );
  }
}
