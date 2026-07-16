import 'package:flutter/material.dart';
import 'package:optionxi/Components/cust_market_trend_loader.dart';
import 'package:optionxi/Dialogs/custom_atlas_detaildialog.dart';
import 'package:optionxi/Main_Pages/MarketSentiments/act_market_sentiments.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class AtlasOutputWidget extends StatefulWidget {
  const AtlasOutputWidget({Key? key}) : super(key: key);

  @override
  State<AtlasOutputWidget> createState() => _AtlasOutputWidgetState();
}

class _AtlasOutputWidgetState extends State<AtlasOutputWidget> {
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _atlasData = [];
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
          .from('atlas_output')
          .select()
          .order('timeinmill', ascending: false)
          .limit(5);

      setState(() {
        _atlasData = List<Map<String, dynamic>>.from(results);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _gotoScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MarketSentimentPage(),
      ),
    );
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
                      'Market Sentiment',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                                color: colorScheme.onBackground,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Latest market trend signals',
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
                : _buildAtlasList(isDark, colorScheme),
      ],
    );
  }

  Widget _buildShimmerList(bool isDark) {
    return CustomShimmer(
      isDark: isDark,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                ShimmerContainer(
                  width: 4,
                  height: 75,
                  borderRadius: BorderRadius.circular(2),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerContainer(
                        width: 140,
                        height: 16,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 8),
                      ShimmerContainer(
                        width: 90,
                        height: 13,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ShimmerContainer(
                      width: 60,
                      height: 16,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ShimmerContainer(
                          width: 32,
                          height: 32,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        const SizedBox(width: 5),
                        ShimmerContainer(
                          width: 32,
                          height: 32,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        const SizedBox(width: 5),
                        ShimmerContainer(
                          width: 32,
                          height: 32,
                          borderRadius: BorderRadius.circular(6),
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

  Widget _buildAtlasList(bool isDark, ColorScheme colorScheme) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _atlasData.length,
      itemBuilder: (context, index) {
        final item = _atlasData[index];
        final time = item['time'] ?? '';
        final createdAt = item['created_at'] != null
            ? DateTime.parse(item['created_at']).toLocal().toIso8601String()
            : '';
        final type = item['type'] ?? '';
        final probability = (item['probability'] ?? 0).toDouble();
        final positive = (item['Postive Indicators'] ?? 0).toInt();
        final neutral = (item['Neutral Indicators'] ?? 0).toInt();
        final negative = (item['Negative Indicators'] ?? 0).toInt();

        final borderColor = _getTypeColor(type);
        final timeAgo = timeago.format(DateTime.parse(createdAt));

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            onTap: () {
              // Handle tap if needed
              final atlasdata = AtlasOutput.fromJson(item);
              _showDetailDialog(atlasdata);
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              decoration: BoxDecoration(
                color: borderColor.withOpacity(0.03),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 75,
                    decoration: BoxDecoration(
                      color: borderColor,
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
                      children: [
                        Row(
                          children: [
                            Text(
                              type.toUpperCase(),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: borderColor,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${probability.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 12,
                              color:
                                  isDark ? Colors.grey[500] : Colors.grey[500],
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '$time • $timeAgo',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.grey[500]
                                    : Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Row(
                    children: [
                      _buildMiniIndicator(
                        positive,
                        Colors.green,
                        Icons.arrow_upward,
                        isDark,
                      ),
                      const SizedBox(width: 5),
                      _buildMiniIndicator(
                        neutral,
                        isDark ? Colors.grey[500]! : Colors.grey[600]!,
                        Icons.remove,
                        isDark,
                      ),
                      const SizedBox(width: 5),
                      _buildMiniIndicator(
                        negative,
                        Colors.red,
                        Icons.arrow_downward,
                        isDark,
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniIndicator(
    int count,
    Color color,
    IconData icon,
    bool isDark,
  ) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 11,
            color: color,
          ),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'bull':
        return Colors.green;
      case 'bear':
        return Colors.red;
      case 'neutral':
      default:
        return Colors.orange;
    }
  }

  void _showDetailDialog(AtlasOutput output) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AtlasDetailDialog(output: output),
    );
  }
}
