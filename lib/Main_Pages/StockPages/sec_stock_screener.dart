import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Updated Screener Model to align with TypeScript interface
class Screener {
  final String id;
  final String name;
  final String timeframe;
  final int signalCount;
  final DateTime? lastUpdate;
  final String? description;
  final List<String> criteria;
  final String category; // 'bullish' | 'bearish'

  Screener({
    required this.id,
    required this.name,
    required this.timeframe,
    required this.signalCount,
    this.lastUpdate,
    this.description,
    required this.criteria,
    required this.category,
  });

  factory Screener.fromJson(Map<String, dynamic> json) {
    return Screener(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      timeframe: json['timeframe'] ?? 'daily',
      signalCount: json['signal_count'] ?? 0,
      lastUpdate: json['last_update'] != null
          ? DateTime.parse(json['last_update'])
          : null,
      description: json['description'],
      criteria:
          json['criteria'] != null ? List<String>.from(json['criteria']) : [],
      category: json['category'] ?? 'bullish',
    );
  }

  // Helper method to get time ago string
  String get timeAgo {
    if (lastUpdate == null) return 'Unknown';

    final now = DateTime.now();
    final difference = now.difference(lastUpdate!);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  // Helper method to determine if data is fresh (less than 24 hours old)
  bool get isFresh {
    if (lastUpdate == null) return false;
    final now = DateTime.now();
    final difference = now.difference(lastUpdate!);
    return difference.inHours < 24;
  }
}

// Custom painter for dotted circle border
class DottedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  DottedCirclePainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    const dashLength = 8.0;
    const gapLength = 6.0;
    final circumference = 2 * 3.14159 * (size.width - strokeWidth) / 2;
    final dashCount = (circumference / (dashLength + gapLength)).floor();

    for (int i = 0; i < dashCount; i++) {
      final startAngle =
          (i * (dashLength + gapLength) / (size.width - strokeWidth) / 2);
      final endAngle =
          startAngle + (dashLength / (size.width - strokeWidth) / 2);

      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(size.width / 2, size.height / 2),
          radius: (size.width - strokeWidth) / 2,
        ),
        startAngle,
        endAngle - startAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Shimmer loader for Screener items
class ScreenerShimmerLoader extends StatefulWidget {
  const ScreenerShimmerLoader({Key? key}) : super(key: key);

  @override
  State<ScreenerShimmerLoader> createState() => _ScreenerShimmerLoaderState();
}

class _ScreenerShimmerLoaderState extends State<ScreenerShimmerLoader>
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
    return ListView.builder(
      itemCount: 6,
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return _buildShimmerItem(context);
          },
        );
      },
    );
  }

  Widget _buildShimmerItem(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getBorderColor(context).withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Indicator bar
            _buildShimmerContainer(
              height: 40,
              width: 4,
              borderRadius: BorderRadius.circular(2),
              isDark: isDark,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildShimmerContainer(
                        height: 18,
                        width: 120,
                        borderRadius: BorderRadius.circular(4),
                        isDark: isDark,
                      ),
                      _buildShimmerContainer(
                        height: 24,
                        width: 40,
                        borderRadius: BorderRadius.circular(8),
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Description
                  _buildShimmerContainer(
                    height: 14,
                    width: double.infinity,
                    borderRadius: BorderRadius.circular(4),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                  // Bottom row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _buildShimmerContainer(
                            height: 14,
                            width: 14,
                            borderRadius: BorderRadius.circular(7),
                            isDark: isDark,
                          ),
                          const SizedBox(width: 4),
                          _buildShimmerContainer(
                            height: 14,
                            width: 60,
                            borderRadius: BorderRadius.circular(4),
                            isDark: isDark,
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _buildShimmerContainer(
                            height: 14,
                            width: 80,
                            borderRadius: BorderRadius.circular(4),
                            isDark: isDark,
                          ),
                          const SizedBox(width: 8),
                          _buildShimmerContainer(
                            height: 20,
                            width: 20,
                            borderRadius: BorderRadius.circular(10),
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerContainer({
    required double height,
    required double width,
    required BorderRadius borderRadius,
    required bool isDark,
    EdgeInsetsGeometry? margin,
  }) {
    return Container(
      height: height,
      width: width,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
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
          stops: const [0.0, 0.5, 1.0],
          begin: Alignment(-1.0 + _animation.value, 0.0),
          end: Alignment(-0.5 + _animation.value, 0.0),
        ),
      ),
    );
  }

  Color _getCardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2C2C2C)
        : Colors.white;
  }

  Color _getBorderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF404040)
        : const Color(0xFFE0E0E0);
  }
}

class StockScannersWidget extends StatefulWidget {
  final String stockName;

  const StockScannersWidget({
    Key? key,
    required this.stockName,
  }) : super(key: key);

  @override
  State<StockScannersWidget> createState() => _StockScannersWidgetState();
}

class _StockScannersWidgetState extends State<StockScannersWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Screener> bullishScreeners = [];
  List<Screener> bearishScreeners = [];
  bool isLoading = false;
  String? error;
  Set<String> expandedScreeners = {}; // Track which screener cards are expanded

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.stockName.isNotEmpty) {
      _loadScreenersForStock();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<List<Screener>> _fetchScreenersForStock(
      String category, String stockSymbol) async {
    final cleanedSymbol = stockSymbol.trim().toUpperCase();

    try {
      // Find screener IDs where the stock symbol appears
      final resultsResponse = await Supabase.instance.client
          .from('screener_results')
          .select('screener_id')
          .or('stckname.ilike.%:$cleanedSymbol-%,'
              'stckname.ilike.%:$cleanedSymbol%,'
              'stckname.eq.$cleanedSymbol')
          .order('scan_date', ascending: false);

      if (resultsResponse.isEmpty) {
        return [];
      }

      // Extract unique screener IDs
      final screenerIds =
          resultsResponse.map((item) => item['screener_id']).toSet().toList();

      // Fetch screener details with updated fields
      final screenersResponse = await Supabase.instance.client
          .from('screener_names')
          .select(
              'id, name, timeframe, signal_count, last_update, description, criteria, category')
          .eq('category', category)
          .inFilter('id', screenerIds)
          .order('timeframe', ascending: true)
          .order('last_update', ascending: false);

      return screenersResponse.map((data) => Screener.fromJson(data)).toList();
    } catch (e) {
      throw Exception('Failed to fetch screeners: $e');
    }
  }

  Future<void> _loadScreenersForStock() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final results = await Future.wait([
        _fetchScreenersForStock('bullish', widget.stockName),
        _fetchScreenersForStock('bearish', widget.stockName),
      ]);

      setState(() {
        bullishScreeners = results[0];
        bearishScreeners = results[1];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Map<String, List<Screener>> _groupScreenersByTimeframe(
      List<Screener> screeners) {
    final Map<String, List<Screener>> grouped = {};
    for (final screener in screeners) {
      final timeframe = screener.timeframe;
      if (!grouped.containsKey(timeframe)) {
        grouped[timeframe] = [];
      }
      grouped[timeframe]!.add(screener);
    }
    return grouped;
  }

  IconData _getTimeframeIcon(String timeframe) {
    switch (timeframe.toLowerCase()) {
      case 'daily':
        return Icons.access_time;
      case 'weekly':
        return Icons.calendar_view_week;
      case 'monthly':
        return Icons.calendar_month;
      default:
        return Icons.schedule;
    }
  }

  // Get theme-aware colors
  Color _getBullishColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF4CAF50)
        : const Color(0xFF2E7D32);
  }

  Color _getBearishColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFF44336)
        : const Color(0xFFC62828);
  }

  Color _getCardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2C2C2C)
        : Colors.white;
  }

  Color _getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1E1E1E)
        : const Color(0xFFF5F5F5);
  }

  Color _getBorderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF404040)
        : const Color(0xFFE0E0E0);
  }

  Color _getSubtleTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white70
        : Colors.black54;
  }

  Widget _buildTimeframeGroup(
    List<Screener>? screeners,
    String timeframe,
    bool isBullish,
  ) {
    if (screeners == null || screeners.isEmpty) {
      return const SizedBox.shrink();
    }

    final categoryColor =
        isBullish ? _getBullishColor(context) : _getBearishColor(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getBorderColor(context).withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getCardColor(context),
                border: Border(
                  bottom: BorderSide(
                    color: _getBorderColor(context).withOpacity(0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getTimeframeIcon(timeframe),
                    size: 20,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${timeframe[0].toUpperCase()}${timeframe.substring(1)} Screeners',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${screeners.length}',
                      style: TextStyle(
                        color: categoryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Container(
              color: _getCardColor(context),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: screeners.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final screener = screeners[index];
                  return _buildScreenerCard(screener, isBullish);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScreenerCard(Screener screener, bool isBullish) {
    final categoryColor =
        isBullish ? _getBullishColor(context) : _getBearishColor(context);
    final isExpanded = expandedScreeners.contains(screener.id);

    return Container(
      decoration: BoxDecoration(
        color: _getBackgroundColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: categoryColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          // Main card content - always visible
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  expandedScreeners.remove(screener.id);
                } else {
                  expandedScreeners.add(screener.id);
                }
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Indicator
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: categoryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                screener.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Signal Count Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${screener.signalCount}',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (screener.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            screener.description!,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: _getSubtleTextColor(context),
                                    ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 8),
                        // Last Update and Freshness Indicator
                        Row(
                          children: [
                            Icon(
                              screener.isFresh ? Icons.update : Icons.schedule,
                              size: 14,
                              color: screener.isFresh
                                  ? _getBullishColor(context)
                                  : _getSubtleTextColor(context),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              screener.timeAgo,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: screener.isFresh
                                        ? _getBullishColor(context)
                                        : _getSubtleTextColor(context),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                            if (screener.isFresh) ...[
                              const SizedBox(width: 8),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: _getBullishColor(context),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                            const Spacer(),
                            // Show criteria count and expand/collapse indicator
                            if (screener.criteria.isNotEmpty) ...[
                              Text(
                                '${screener.criteria.length} criteria',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: _getSubtleTextColor(context),
                                      fontSize: 11,
                                    ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            AnimatedRotation(
                              turns: isExpanded ? 0.5 : 0,
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                Icons.keyboard_arrow_down,
                                size: 20,
                                color: _getSubtleTextColor(context),
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
          // Expandable Criteria Section
          if (isExpanded && screener.criteria.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(
                    color: _getBorderColor(context).withOpacity(0.3),
                    height: 1,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Screening Criteria:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: categoryColor,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ...screener.criteria.map(
                    (criteria) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 4,
                            height: 4,
                            margin: const EdgeInsets.only(top: 6, right: 8),
                            decoration: BoxDecoration(
                              color: categoryColor.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              criteria,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: ScreenerShimmerLoader(),
    );
  }

  Widget _buildNoScreenersMessage(bool isBullish) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            // Professional SVG-like illustration
            Container(
              width: 120,
              height: 120,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _getBorderColor(context).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background circle
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _getSubtleTextColor(context).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                  // Chart icon with trend
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.assessment_outlined,
                        size: 32,
                        color: _getSubtleTextColor(context).withOpacity(0.6),
                      ),
                      const SizedBox(height: 4),
                      Icon(
                        isBullish ? Icons.trending_up : Icons.trending_down,
                        size: 20,
                        color: (isBullish
                                ? _getBullishColor(context)
                                : _getBearishColor(context))
                            .withOpacity(0.5),
                      ),
                    ],
                  ),
                  // Dotted border effect
                  Positioned.fill(
                    child: CustomPaint(
                      painter: DottedCirclePainter(
                        color: _getBorderColor(context).withOpacity(0.3),
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No ${isBullish ? 'Bullish' : 'Bearish'} Signals Found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              '${widget.stockName} doesn\'t currently appear in any ${isBullish ? 'bullish' : 'bearish'} screeners.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _getSubtleTextColor(context),
                    height: 1.5,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'This could indicate neutral market sentiment or that the stock doesn\'t meet current screening criteria.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _getSubtleTextColor(context).withOpacity(0.8),
                    height: 1.4,
                    fontStyle: FontStyle.italic,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: _getBearishColor(context).withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'Error: $error',
              style: TextStyle(
                color: _getBearishColor(context).withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(bool isBullish) {
    if (isLoading) {
      return _buildSkeletonLoader();
    }

    if (error != null) {
      return _buildErrorMessage();
    }

    final screeners = isBullish ? bullishScreeners : bearishScreeners;

    if (screeners.isEmpty) {
      return _buildNoScreenersMessage(isBullish);
    }

    final groupedScreeners = _groupScreenersByTimeframe(screeners);

    return Column(
      children: [
        _buildTimeframeGroup(groupedScreeners['daily'], 'daily', isBullish),
        _buildTimeframeGroup(groupedScreeners['weekly'], 'weekly', isBullish),
        _buildTimeframeGroup(groupedScreeners['monthly'], 'monthly', isBullish),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Tab Bar
        Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getBorderColor(context).withOpacity(0.3),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
            unselectedLabelColor: _getSubtleTextColor(context),
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.trending_up,
                      size: 18,
                      color: _getBullishColor(context),
                    ),
                    const SizedBox(width: 8),
                    const Text('Bullish'),
                    const SizedBox(width: 8),
                    // Bullish count badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getBullishColor(context).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        bullishScreeners.length.toString(),
                        style: TextStyle(
                          color: _getBullishColor(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.trending_down,
                      size: 18,
                      color: _getBearishColor(context),
                    ),
                    const SizedBox(width: 8),
                    const Text('Bearish'),
                    const SizedBox(width: 8),
                    // Bearish count badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getBearishColor(context).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        bearishScreeners.length.toString(),
                        style: TextStyle(
                          color: _getBearishColor(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Tab Content - Now wraps content instead of fixed height
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: AnimatedBuilder(
            animation: _tabController,
            builder: (context, child) {
              return _buildTabContent(_tabController.index == 0);
            },
          ),
        ),
      ],
    );
  }
}
