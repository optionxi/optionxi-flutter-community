import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:optionxi/Components/cust_market_trend_loader.dart';
import 'package:optionxi/Main_Pages/act_scanner_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class ScreenersScreen extends StatefulWidget {
  const ScreenersScreen({Key? key}) : super(key: key);

  @override
  State<ScreenersScreen> createState() => _ScreenersScreenState();
}

class _ScreenersScreenState extends State<ScreenersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _bullishScreeners = [];
  List<Map<String, dynamic>> _bearishScreeners = [];

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Add listener to rebuild when tab changes
    _tabController.addListener(_handleTabSelection);
    _fetchData();
  }

  // Triggers rebuild to switch list content without TabBarView
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
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _supabase
            .from('screener_names')
            .select()
            .eq('category', 'bullish')
            .order('signal_count', ascending: false),
        _supabase
            .from('screener_names')
            .select()
            .eq('category', 'bearish')
            .order('signal_count', ascending: false),
      ]);

      if (mounted) {
        setState(() {
          _bullishScreeners = List<Map<String, dynamic>>.from(results[0]);
          _bearishScreeners = List<Map<String, dynamic>>.from(results[1]);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // Important for embedding in ScrollView
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
                      'Market Screeners',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                                color: colorScheme.onBackground,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Discover trading opportunities',
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
                  // Navigate to all screeners page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StockScreenerPage(),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  backgroundColor: isDark ? Colors.grey[800] : Colors.grey[100],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Text(
                  'View All',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
              ),
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
            tabs: const [
              Tab(text: 'Bullish Signals'),
              Tab(text: 'Bearish Signals'),
            ],
          ),
        ),
        // Removed SizedBox(height: 500) and TabBarView.
        // Instead, we simply display the content corresponding to the selected tab.
        _isLoading
            ? _buildShimmerList(isDark)
            : _error != null
                ? _buildErrorState()
                : AnimatedSize(
                    // Adds a smooth transition height effect
                    duration: const Duration(milliseconds: 300),
                    alignment: Alignment.topCenter,
                    child: _tabController.index == 0
                        ? _buildScreenerList(_bullishScreeners, 'bullish')
                        : _buildScreenerList(_bearishScreeners, 'bearish'),
                  ),
      ],
    );
  }

  Widget _buildErrorState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: isDark ? Colors.grey[400] : Colors.grey[500],
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load screeners',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error occurred',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScreenerList(
      List<Map<String, dynamic>> screeners, String category) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    if (screeners.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: isDark ? Colors.grey[800] : Colors.grey[300],
              ),
              const SizedBox(height: 16),
              Text(
                'No screeners available',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isDark ? Colors.grey[500] : Colors.grey[500],
                    ),
              ),
            ],
          ),
        ),
      );
    }

    final isBullish = category == 'bullish';
    // Define the accent color based on category
    final accentColor = isBullish
        ? const Color(0xFF00C853) // Sleek Green
        : const Color(0xFFFF3D00); // Sleek Red

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      // Reduced side padding slightly to give it a 'less width' feel visually
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: screeners.length,
      itemBuilder: (context, index) {
        final screener = screeners[index];
        final name = screener['name'] ?? '';
        final description = screener['description'] ?? '';
        final signalCount = screener['signal_count'] ?? 0;
        final timeframe = screener['timeframe'] ?? 'daily';
        final lastUpdate = screener['last_update'] != null
            ? DateTime.parse(screener['last_update']).toLocal()
            : null;

        final formattedTime =
            lastUpdate != null ? DateFormat('HH:mm').format(lastUpdate) : '';

        final timeAgo = lastUpdate != null ? timeago.format(lastUpdate) : '';

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            onTap: () {
              Navigator.pushNamed(
                context,
                '/scanners/${name.toLowerCase().replaceAll(' ', '-')}',
                arguments: {'category': category},
              );
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              // Fixed height not strictly necessary, but helps 'sleekness'
              // removing height lets it expand if description is long
              decoration: BoxDecoration(
                // Very subtle tint of the accent color
                color: accentColor.withOpacity(isDark ? 0.05 : 0.03),
                borderRadius: BorderRadius.circular(10),
              ),
              child: IntrinsicHeight(
                // Ensures the left bar stretches to match content
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. The Colored Left Bar
                    Container(
                      width: 4,
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(10),
                          bottomLeft: Radius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // 2. The Main Content
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 15, // Slightly smaller for sleekness
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              description.isNotEmpty
                                  ? description
                                  : 'No description available',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.grey[500]
                                    : Colors.grey[600],
                                height: 1.2,
                              ),
                              maxLines: 1, // Force single line for sleek look
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            // Sleek metadata row
                            Row(
                              children: [
                                Icon(Icons.access_time,
                                    size: 12,
                                    color: accentColor.withOpacity(0.8)),
                                const SizedBox(width: 4),
                                Text(
                                  timeframe.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? Colors.grey[500]
                                        : Colors.grey[600],
                                  ),
                                ),
                                if (formattedTime.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    // '• $formattedTime • $timeAgo',
                                    '• $timeAgo',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? Colors.grey[500]
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 3. The Signal Count (Right Side)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            signalCount.toString(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: accentColor,
                            ),
                          ),
                          Text(
                            'Stocks',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: accentColor.withOpacity(0.8),
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

  // Updated Shimmer to match the new sleek layout
  Widget _buildShimmerList(bool isDark) {
    return CustomShimmer(
      isDark: isDark,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              height: 80, // Approximate height of new items
              decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900] : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  // Optional: add a subtle border to the shimmer so it's visible on white
                  border: Border.all(
                    color: isDark ? Colors.transparent : Colors.grey[200]!,
                  )),
              child: Row(
                children: [
                  // Fake Left Bar
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[300],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(10),
                        bottomLeft: Radius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ShimmerContainer(
                          width: 120,
                          height: 14,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 8),
                        ShimmerContainer(
                          width: 200,
                          height: 10,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 8),
                        ShimmerContainer(
                          width: 60,
                          height: 10,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Right side count
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ShimmerContainer(
                        width: 20,
                        height: 16,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 4),
                      ShimmerContainer(
                        width: 30,
                        height: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
