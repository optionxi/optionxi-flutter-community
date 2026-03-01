import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:optionxi/Components/cust_market_trend_loader.dart';
import 'package:optionxi/Helpers/constants.dart';
import 'package:optionxi/Main_Pages/act_topgainers_losers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MarketMoversScreen extends StatefulWidget {
  const MarketMoversScreen({Key? key}) : super(key: key);

  @override
  State<MarketMoversScreen> createState() => _MarketMoversScreenState();
}

class _MarketMoversScreenState extends State<MarketMoversScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _gainers = [];
  List<Map<String, dynamic>> _losers = [];
  List<Map<String, dynamic>> _volume = [];

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // 1. Add listener to rebuild UI when tab changes
    _tabController.addListener(_handleTabSelection);
    _fetchData();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    // ... (Your existing fetch logic remains exactly the same)
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _supabase
            .from('top_gainers_all')
            .select()
            .order('pcnt', ascending: false)
            .limit(5),
        _supabase
            .from('top_losers_all')
            .select()
            .order('pcnt', ascending: true)
            .limit(5),
        _supabase
            .from('top_volume_all')
            .select()
            .order('vol', ascending: false)
            .limit(5),
      ]);

      setState(() {
        _gainers = List<Map<String, dynamic>>.from(results[0]);
        _losers = List<Map<String, dynamic>>.from(results[1]);
        _volume = List<Map<String, dynamic>>.from(results[2]);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // Important for fitting in ScrollView
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Market Movers',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                                color: colorScheme.onBackground,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Track trending stocks',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            height: 1.3,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TopGainersLosersPage(),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Text(
                  'View All',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              )
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
              ),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: colorScheme.primary,
            unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
            indicatorColor: colorScheme.primary,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
            // Use onTap to ensure state updates immediately
            onTap: (index) {
              setState(() {});
            },
            tabs: const [
              Tab(text: 'Top Gainers'),
              Tab(text: 'Top Losers'),
              Tab(text: 'Most Active'),
            ],
          ),
        ),

        // 2. REMOVED SizedBox(height: 800) and TabBarView
        // Instead, we directly render the content based on the index
        if (_isLoading)
          _buildShimmerList(isDark)
        else if (_error != null)
          _buildErrorState()
        else
          _getCurrentTabContent(),
      ],
    );
  }

  // Helper to switch content based on tab index
  Widget _getCurrentTabContent() {
    switch (_tabController.index) {
      case 0:
        return _buildStockList(_gainers, true);
      case 1:
        return _buildStockList(_losers, false);
      case 2:
        return _buildStockList(_volume, null);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildShimmerList(bool isDark) {
    return CustomShimmer(
      isDark: isDark,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true, // 3. Added shrinkWrap
        padding: const EdgeInsets.all(24),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                const ShimmerContainer(
                  width: 48,
                  height: 48,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerContainer(
                        width: 120,
                        height: 16,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 6),
                      ShimmerContainer(
                        width: 80,
                        height: 14,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ShimmerContainer(
                      width: 60,
                      height: 16,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 6),
                    ShimmerContainer(
                      width: 50,
                      height: 14,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: isDark ? Colors.grey[400] : Colors.grey[500],
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load data',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _fetchData,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildStockList(List<Map<String, dynamic>> stocks, bool? isGainer) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap:
          true, // 4. Added shrinkWrap - Vital for ScrollView compatibility
      padding: const EdgeInsets.all(16),
      itemCount: stocks.length,
      itemBuilder: (context, index) {
        // ... (Your existing Item Builder logic remains exactly the same)
        final stock = stocks[index];
        final stckname = stock['stckname'] ?? '';
        var symbol = stock['symbol'] ?? stckname;
        symbol = symbol
            .toString()
            .replaceAll("NSE:", "")
            .replaceAll("-EQ", "")
            .replaceAll("-BZ", "");
        final fname = stock['fname'] ?? stckname;
        final close = (stock['close'] ?? 0).toDouble();
        final pcnt = (stock['pcnt'] ?? 0).toDouble();
        final vol = stock['vol'] ?? 0;

        final isPositive = isGainer == null ? null : pcnt >= 0;
        final changeColor = isPositive == null
            ? isDark
                ? Colors.grey[400]!
                : Colors.grey[600]!
            : (isPositive ? Colors.green : Colors.red);

        return InkWell(
          onTap: () {
            // Navigate to stock detail
            Get.toNamed('/stocks/${stckname.toUpperCase()}');
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    height: 48,
                    width: 48,
                    imageUrl: "${Constants.OptionXiS3Loc}$symbol.png",
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Image.asset(
                      'assets/images/stockdefault.png',
                      fit: BoxFit.cover,
                      height: 48,
                      width: 48,
                    ),
                    errorWidget: (context, url, error) => Image.asset(
                      'assets/images/stockdefault.png',
                      fit: BoxFit.cover,
                      height: 48,
                      width: 48,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        symbol,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onBackground,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        fname.length > 30
                            ? '${fname.substring(0, 30)}...'
                            : fname,
                        style: TextStyle(
                          fontSize: 10,
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
                      '₹${close.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onBackground,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (isGainer != null)
                          Icon(
                            isPositive!
                                ? Icons.arrow_drop_up
                                : Icons.arrow_drop_down,
                            color: changeColor,
                            size: 20,
                          ),
                        Text(
                          isGainer == null
                              ? _formatVolume(vol)
                              : '${pcnt.abs().toStringAsFixed(2)}%',
                          style: TextStyle(
                            fontSize: 14,
                            color: changeColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatVolume(int volume) {
    if (volume >= 10000000) {
      return '${(volume / 10000000).toStringAsFixed(1)}Cr';
    } else if (volume >= 100000) {
      return '${(volume / 100000).toStringAsFixed(1)}L';
    } else if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(1)}K';
    }
    return volume.toString();
  }
}
