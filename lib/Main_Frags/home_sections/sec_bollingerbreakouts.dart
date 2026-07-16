import 'package:flutter/material.dart';
import 'package:optionxi/Main_Pages/BollingerBreakouts/act_breakout_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:optionxi/Components/cust_market_trend_loader.dart';

class BollingerBreakoutsScreen extends StatefulWidget {
  const BollingerBreakoutsScreen({Key? key}) : super(key: key);

  @override
  State<BollingerBreakoutsScreen> createState() =>
      _BollingerBreakoutsScreenState();
}

class _BollingerBreakoutsScreenState extends State<BollingerBreakoutsScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _alerts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _supabase
          .from('bollinger_breakouts')
          .select()
          .order('created_at', ascending: false)
          .limit(5);

      if (mounted) {
        setState(() {
          _alerts = List<Map<String, dynamic>>.from(response);
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

  String _formatTimeAgo(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final date = DateTime.parse(timestamp).toLocal();
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    // NOTE: We return a Column (MainAxisSize.min) instead of Scaffold/Expanded
    // so this fits safely inside your parent SingleChildScrollView.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // Important for nesting
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
                      'Bollinger Breakouts',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                                color: colorScheme.onBackground,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Live market volatility alerts',
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

              /// ---- VIEW ALL BUTTON ----
              TextButton(
                onPressed:
                    _gotoBollinerPage, // Allow parent to control callback
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
        if (_isLoading)
          _buildShimmerList(isDark)
        else if (_error != null)
          _buildErrorState()
        else if (_alerts.isEmpty)
          _buildEmptyState(isDark)
        else
          ListView.builder(
            // These two lines are CRITICAL for working inside SingleChildScrollView
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),

            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: _alerts.length,
            itemBuilder: (context, index) {
              return _buildAlertCard(_alerts[index], isDark, colorScheme);
            },
          ),
      ],
    );
  }

  Widget _buildAlertCard(
      Map<String, dynamic> alert, bool isDark, ColorScheme colorScheme) {
    final description = alert['description'] ?? 'No description';
    final sentiment = (alert['sentiment'] ?? '').toString().toLowerCase();
    final mode = alert['whichmode'] ?? '';
    final createdAt = alert['created_at'];

    final bool isBullish =
        sentiment.contains('bull') || sentiment.contains('buy');
    final Color accentColor =
        isBullish ? const Color(0xFF00C853) : const Color(0xFFFF3D00);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: accentColor.withOpacity(isDark ? 0.05 : 0.03),
          borderRadius: BorderRadius.circular(10),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (mode.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: accentColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                mode.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: accentColor,
                                ),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 12,
                                  color: isDark
                                      ? Colors.grey[500]
                                      : Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatTimeAgo(createdAt),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? Colors.grey[500]
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: Text(
                          description,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart,
                size: 64, color: isDark ? Colors.grey[800] : Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No recent breakouts',
                style: TextStyle(
                    color: isDark ? Colors.grey[500] : Colors.grey[600])),
          ],
        ),
      ),
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
            Icon(Icons.error_outline,
                size: 64, color: isDark ? Colors.grey[400] : Colors.grey[500]),
            const SizedBox(height: 16),
            Text('Failed to load alerts',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(_error ?? 'Unknown error',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 24),
            ElevatedButton.icon(
                onPressed: _fetchData,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerList(bool isDark) {
    return CustomShimmer(
      isDark: isDark,
      child: ListView.builder(
        // Same constraints for Shimmer
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
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
                        Row(
                          children: [
                            ShimmerContainer(
                                width: 50,
                                height: 10,
                                borderRadius: BorderRadius.circular(2)),
                            const Spacer(),
                            ShimmerContainer(
                                width: 40,
                                height: 10,
                                borderRadius: BorderRadius.circular(2)),
                            const SizedBox(width: 16),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ShimmerContainer(
                            width: double.infinity,
                            height: 12,
                            borderRadius: BorderRadius.circular(4)),
                      ],
                    ),
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

  void _gotoBollinerPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BollingerBreakoutsPage(),
      ),
    );
  }
}
