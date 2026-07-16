import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:optionxi/Components/cust_market_trend_loader.dart';
import 'package:optionxi/Helpers/constants.dart';
import 'package:optionxi/Main_Pages/StockPages/act_alert_stocks.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class LiveScannerWidget extends StatefulWidget {
  const LiveScannerWidget({Key? key}) : super(key: key);

  @override
  State<LiveScannerWidget> createState() => _LiveScannerWidgetState();
}

class _LiveScannerWidgetState extends State<LiveScannerWidget> {
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _scannerData = [];
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
      final results = await _supabase
          .from('live_scanner')
          .select()
          .order('created_at', ascending: false)
          .limit(5);

      setState(() {
        _scannerData = List<Map<String, dynamic>>.from(results);
        _isLoading = false;
      });
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
      mainAxisSize: MainAxisSize.min,
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
                      'Live Scanner',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                                color: colorScheme.onBackground,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Real-time market alerts',
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
                onPressed: _gotoScanner,
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  backgroundColor: isDark ? Colors.grey[800] : Colors.grey[100],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View All',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _isLoading
            ? _buildShimmerList(isDark)
            : _error != null
                ? _buildErrorState()
                : _buildScannerList(isDark, colorScheme),
      ],
    );
  }

  Widget _buildShimmerList(bool isDark) {
    return CustomShimmer(
      isDark: isDark,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                        width: 100,
                        height: 16,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 6),
                      ShimmerContainer(
                        width: double.infinity,
                        height: 14,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 4),
                      ShimmerContainer(
                        width: 150,
                        height: 12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
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
              'Failed to load data',
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

  Widget _buildScannerList(bool isDark, ColorScheme colorScheme) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _scannerData.length,
      itemBuilder: (context, index) {
        final item = _scannerData[index];
        final symbol = item['symbol'] ?? '';
        final description = item['description'] ?? '';
        final sentiment = item['sentiment'] ?? 'neutral';
        final close = (item['close'] ?? 0).toDouble();
        final pcnt = (item['pcnt'] ?? 0).toDouble();

        final createdAt = item['created_at'] != null
            ? DateTime.parse(item['created_at']).toLocal()
            : null;

        final formattedTime =
            createdAt != null ? DateFormat('HH:mm').format(createdAt) : '';

        final timeAgo = createdAt != null ? timeago.format(createdAt) : '';

        final sentimentColor = _getSentimentColor(sentiment, isDark);
        final isPositive = pcnt >= 0;
        final changeColor = isPositive ? Colors.green : Colors.red;

        return InkWell(
          onTap: () {
            // Navigate to stock detail
            Get.toNamed('/stocks/${"NSE:" + symbol.toUpperCase() + "-EQ"}');
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                      Row(
                        children: [
                          Text(
                            symbol,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onBackground,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: sentimentColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              sentiment.toUpperCase(),
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                                color: sentimentColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: isDark ? Colors.grey[500] : Colors.grey[500],
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '$formattedTime • $timeAgo',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  isDark ? Colors.grey[500] : Colors.grey[500],
                            ),
                          ),
                        ],
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
                        Icon(
                          isPositive
                              ? Icons.arrow_drop_up
                              : Icons.arrow_drop_down,
                          color: changeColor,
                          size: 20,
                        ),
                        Text(
                          '${pcnt.abs().toStringAsFixed(2)}%',
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

  Color _getSentimentColor(String sentiment, bool isDark) {
    switch (sentiment.toLowerCase()) {
      case 'bullish':
        return Colors.green;
      case 'bearish':
        return Colors.red;
      case 'neutral':
      default:
        return isDark ? Colors.grey[400]! : Colors.grey[600]!;
    }
  }

  void _gotoScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StockAlertsPage(null),
      ),
    );
  }
}
