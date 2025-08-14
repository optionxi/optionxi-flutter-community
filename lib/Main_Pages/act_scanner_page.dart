import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

// Models
class Screener {
  final String id;
  final String name;
  final String timeframe;
  final int signalCount;
  final String lastUpdate;
  final String description;
  final List<String> criteria;
  final String category;

  Screener({
    required this.id,
    required this.name,
    required this.timeframe,
    required this.signalCount,
    required this.lastUpdate,
    required this.description,
    required this.criteria,
    required this.category,
  });

  factory Screener.fromJson(Map<String, dynamic> json) {
    return Screener(
      id: json['id'],
      name: json['name'],
      timeframe: json['timeframe'],
      signalCount: json['signal_count'],
      lastUpdate: json['last_update'],
      description: json['description'],
      criteria: List<String>.from(json['criteria']),
      category: json['category'],
    );
  }
}

// Service for Supabase
class ScreenerService {
  final SupabaseClient _supabase;

  ScreenerService(this._supabase);

  Future<List<Screener>> fetchScreeners(String category) async {
    final response = await _supabase
        .from('screener_names')
        .select()
        .eq('category', category)
        .order('timeframe', ascending: true)
        .order('created_at', ascending: false);

    if (response.isNotEmpty) {
      return response.map((json) => Screener.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load screeners');
    }
  }
}

// Custom Icons
class CustomIcons {
  static const IconData trendingUp = Icons.trending_up;
  static const IconData arrowDownCircle = Icons.arrow_downward;
  static const IconData clock = Icons.access_time;
  static const IconData calendar = Icons.calendar_today;
  static const IconData calendarDays = Icons.date_range;
  static const IconData info = Icons.info_outline;
}

// TimeframeIcon Widget
class TimeframeIcon extends StatelessWidget {
  final String timeframe;

  const TimeframeIcon({Key? key, required this.timeframe}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final iconColor = Theme.of(context).textTheme.bodyMedium?.color;

    switch (timeframe) {
      case 'daily':
        return Icon(CustomIcons.clock, size: 20, color: iconColor);
      case 'weekly':
        return Icon(CustomIcons.calendar, size: 20, color: iconColor);
      case 'monthly':
        return Icon(CustomIcons.calendarDays, size: 20, color: iconColor);
      default:
        return const SizedBox.shrink();
    }
  }
}

// ScannerCard Widget
class ScannerCard extends StatefulWidget {
  final Screener screener;
  final String type;
  final bool defaultExpanded;
  final String category;

  const ScannerCard({
    Key? key,
    required this.screener,
    required this.type,
    this.defaultExpanded = false,
    required this.category,
  }) : super(key: key);

  @override
  _ScannerCardState createState() => _ScannerCardState();
}

class _ScannerCardState extends State<ScannerCard> {
  late bool isExpanded;

  @override
  void initState() {
    super.initState();
    isExpanded = widget.defaultExpanded;
  }

  @override
  void didUpdateWidget(ScannerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.defaultExpanded != widget.defaultExpanded) {
      setState(() {
        isExpanded = widget.defaultExpanded;
      });
    }
  }

  void handleInfoClick() {
    setState(() {
      isExpanded = !isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final timeAgo = timeago.format(DateTime.parse(widget.screener.lastUpdate));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 20),
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.screener.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/scanners/${widget.screener.name.toLowerCase().replaceAll(' ', '-')}',
                            arguments: {'category': widget.category},
                          );
                        },
                        child: Chip(
                          label: Text('${widget.screener.signalCount} stocks'),
                          backgroundColor: widget.type == 'bullish'
                              ? Colors.green.withValues(alpha: 0.2)
                              : Colors.red.withValues(alpha: 0.2),
                          labelStyle: TextStyle(
                            color: widget.type == 'bullish'
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            CustomIcons.clock,
                            size: 16,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.screener.timeframe} • $timeAgo',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      isExpanded = !isExpanded;
                    });
                  },
                  icon: AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      size: 20,
                    ),
                  ),
                  tooltip: isExpanded ? 'Show less' : 'Show criteria',
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.surfaceVariant,
                    foregroundColor: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Modern View All Stocks Button
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/scanners/${widget.screener.name.toLowerCase().replaceAll(' ', '-')}',
                        arguments: {'category': widget.category},
                      );
                    },
                    icon: Icon(
                      Icons.trending_up,
                      size: 18,
                    ),
                    label: Text('View All Stocks'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      side: BorderSide(
                        color: widget.type == 'bullish'
                            ? Colors.green.withValues(alpha: 0.5)
                            : Colors.red.withValues(alpha: 0.5),
                      ),
                      foregroundColor: widget.type == 'bullish'
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
            if (isExpanded)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(top: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(color: colorScheme.outline),
                    const SizedBox(height: 8),
                    Text(
                      widget.screener.description,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Screening Criteria:',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...widget.screener.criteria
                              .map((criterion) => Padding(
                                    padding: const EdgeInsets.only(
                                        left: 16, bottom: 4, top: 4),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('• ',
                                            style: theme.textTheme.bodyMedium),
                                        Expanded(
                                          child: Text(
                                            criterion,
                                            style: theme.textTheme.bodyMedium,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Skeleton Loading Widget
class ScannerCardSkeleton extends StatelessWidget {
  const ScannerCardSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 20,
                        width: 150,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 30,
                        width: 100,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 16,
                        width: 180,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Main Screen
class StockScreenerPage extends StatefulWidget {
  const StockScreenerPage({Key? key}) : super(key: key);

  @override
  _StockScreenerPageState createState() => _StockScreenerPageState();
}

class _StockScreenerPageState extends State<StockScreenerPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String selectedCategory = 'bullish';
  bool loading = true;
  String? error;
  List<Screener> bullishScreeners = [];
  List<Screener> bearishScreeners = [];
  late AnimationController _controller;
  late Animation<double> _animation;

  late final ScreenerService _screenerService;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          selectedCategory = _tabController.index == 0 ? 'bullish' : 'bearish';
        });
      }
    });

    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    _controller.forward();

    // Initialize Supabase service
    final supabase = Supabase.instance.client;
    _screenerService = ScreenerService(supabase);

    // Load screeners
    loadScreeners();
  }

  Future<void> loadScreeners() async {
    try {
      if (mounted) {
        setState(() {
          loading = true;
          error = null;
        });
      }

      final bullishData = await _screenerService.fetchScreeners('bullish');
      final bearishData = await _screenerService.fetchScreeners('bearish');

      if (mounted) {
        setState(() {
          bullishScreeners = bullishData;
          bearishScreeners = bearishData;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          loading = false;
        });
      }
    }
  }

  Map<String, List<Screener>> groupScreenersByTimeframe(
      List<Screener> screeners) {
    final grouped = <String, List<Screener>>{};
    for (final screener in screeners) {
      if (!grouped.containsKey(screener.timeframe)) {
        grouped[screener.timeframe] = [];
      }
      grouped[screener.timeframe]!.add(screener);
    }
    return grouped;
  }

  Widget renderTimeframeGroup(
    List<Screener>? screeners,
    String timeframe,
    String type,
  ) {
    if (screeners == null || screeners.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    TimeframeIcon(timeframe: timeframe),
                    const SizedBox(width: 8),
                    Text(
                      '${timeframe.substring(0, 1).toUpperCase()}${timeframe.substring(1)} Screeners',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...screeners.map((screener) => ScannerCard(
                      screener: screener,
                      type: type,
                      category: selectedCategory,
                    )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final fontSize = isTablet ? 32.0 : 28.0;
    final descriptionSize = isTablet ? 18.0 : 16.0;
    final padding = isTablet ? 24.0 : 20.0;

    return FadeTransition(
      opacity: _animation,
      child: Container(
        padding: EdgeInsets.all(padding),
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
                  "Stock Screeners",
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              "Discover stocks that match specific technical criteria. These screeners help identify potential trading opportunities.",
              style: TextStyle(
                color: Theme.of(context).textTheme.titleSmall?.color,
                fontSize: descriptionSize,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bullishGrouped = groupScreenersByTimeframe(bullishScreeners);
    final bearishGrouped = groupScreenersByTimeframe(bearishScreeners);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: TabBar(
                          controller: _tabController,
                          tabs: [
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    CustomIcons.trendingUp,
                                    color: Colors.green,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Bullish',
                                    style: theme.textTheme.labelLarge,
                                  ),
                                ],
                              ),
                            ),
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    CustomIcons.arrowDownCircle,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Bearish',
                                    style: theme.textTheme.labelLarge,
                                  ),
                                ],
                              ),
                            ),
                          ],
                          indicatorSize: TabBarIndicatorSize.tab,
                          labelColor: theme.colorScheme.primary,
                          unselectedLabelColor:
                              theme.colorScheme.onSurfaceVariant,
                          indicator: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Bullish Tab
                          loading
                              ? ListView.builder(
                                  itemCount: 5,
                                  itemBuilder: (context, index) =>
                                      const ScannerCardSkeleton(),
                                )
                              : error != null
                                  ? Center(
                                      child: Text(
                                        'Error: $error',
                                        style: TextStyle(
                                            color: theme.colorScheme.error),
                                      ),
                                    )
                                  : SingleChildScrollView(
                                      child: Column(
                                        children: [
                                          renderTimeframeGroup(
                                              bullishGrouped['daily'],
                                              'daily',
                                              'bullish'),
                                          renderTimeframeGroup(
                                              bullishGrouped['weekly'],
                                              'weekly',
                                              'bullish'),
                                          renderTimeframeGroup(
                                              bullishGrouped['monthly'],
                                              'monthly',
                                              'bullish'),
                                        ],
                                      ),
                                    ),
                          // Bearish Tab
                          loading
                              ? ListView.builder(
                                  itemCount: 3,
                                  itemBuilder: (context, index) =>
                                      const ScannerCardSkeleton(),
                                )
                              : error != null
                                  ? Center(
                                      child: Text(
                                        'Error: $error',
                                        style: TextStyle(
                                            color: theme.colorScheme.error),
                                      ),
                                    )
                                  : SingleChildScrollView(
                                      child: Column(
                                        children: [
                                          renderTimeframeGroup(
                                              bearishGrouped['daily'],
                                              'daily',
                                              'bearish'),
                                          renderTimeframeGroup(
                                              bearishGrouped['weekly'],
                                              'weekly',
                                              'bearish'),
                                          renderTimeframeGroup(
                                              bearishGrouped['monthly'],
                                              'monthly',
                                              'bearish'),
                                        ],
                                      ),
                                    ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _controller.dispose();
    super.dispose();
  }
}
