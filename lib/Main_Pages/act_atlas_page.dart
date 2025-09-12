import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:optionxi/Dialogs/custom_atlas_detaildialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class AtlasOutput {
  final int id;
  final String createdAt;
  final int negativeIndicators;
  final String negativeIndicatorsList;
  final int neutralIndicators;
  final String neutralIndicatorsList;
  final int positiveIndicators;
  final String positiveIndicatorsList;
  final int totalCrossovers;
  final String totalCrossoversList;
  final int advancing;
  final int breakoutvalue;
  final int crossovers;
  final String date;
  final int declining;
  final bool entry;
  final String longterm;
  final bool lowbreakout;
  final double probability;
  final String shortterm;
  final String time;
  final int timeinmill;
  final String type;
  final bool upbreakout;

  AtlasOutput({
    required this.id,
    required this.createdAt,
    required this.negativeIndicators,
    required this.negativeIndicatorsList,
    required this.neutralIndicators,
    required this.neutralIndicatorsList,
    required this.positiveIndicators,
    required this.positiveIndicatorsList,
    required this.totalCrossovers,
    required this.totalCrossoversList,
    required this.advancing,
    required this.breakoutvalue,
    required this.crossovers,
    required this.date,
    required this.declining,
    required this.entry,
    required this.longterm,
    required this.lowbreakout,
    required this.probability,
    required this.shortterm,
    required this.time,
    required this.timeinmill,
    required this.type,
    required this.upbreakout,
  });

  factory AtlasOutput.fromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.parse(json['created_at']).toLocal();
    return AtlasOutput(
      id: json['id'] as int,
      // createdAt: json['created_at'] as String,
      createdAt: createdAt.toIso8601String(), // Store as ISO string
      // Convert numeric types with toInt()
      negativeIndicators: (json['Negative Indicators'] as num).toInt(),
      negativeIndicatorsList: json['Negative Indicators List'] as String,
      neutralIndicators: (json['Neutral Indicators'] as num).toInt(),
      neutralIndicatorsList: json['Neutral Indicators List'] as String,
      positiveIndicators: (json['Postive Indicators'] as num).toInt(),
      positiveIndicatorsList: json['Postive Indicators List'] as String,
      totalCrossovers: (json['Total Crossovers'] as num).toInt(),
      totalCrossoversList: json['Total Crossovers List'] as String,
      advancing: (json['advancing'] as num).toInt(),
      breakoutvalue: (json['breakoutvalue'] as num).toInt(),
      crossovers: (json['crossovers'] as num).toInt(),
      date: json['date'] as String,
      declining: (json['declining'] as num).toInt(),
      entry: json['entry'] as bool,
      longterm: json['longterm'] as String,
      lowbreakout: json['lowbreakout'] as bool,
      probability: (json['probability'] as num).toDouble(),
      shortterm: json['shortterm'] as String,
      time: json['time'] as String,
      timeinmill: (json['timeinmill'] as num).toInt(),
      type: json['type'] as String,
      upbreakout: json['upbreakout'] as bool,
    );
  }
}

// Database Service
class SupabaseService {
  final SupabaseClient _supabaseClient;
  RealtimeChannel? _channel;

  SupabaseService(this._supabaseClient);

  Future<Map<String, dynamic>> getAtlasOutputs({
    int page = 1,
    int pageSize = 10,
    DateTime? selectedDate,
    bool strongTrendOnly = false,
    bool above60pcnt = false,
  }) async {
    final from = (page - 1) * pageSize;
    final to = from + pageSize - 1;

    // Start building the query
    var query = _supabaseClient.from('atlas_output').select();

    // Apply date filter if selected
    if (selectedDate != null) {
      final startDate =
          DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      final endDate = startDate
          .add(const Duration(days: 1))
          .subtract(const Duration(milliseconds: 1));

      query = query
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());
    }

    // Apply strong trend filter if selected
    if (strongTrendOnly) {
      query = query.gt('probability', 50.0); // Use double value
    }

    // Apply strong trend filter if selected
    if (above60pcnt) {
      query = query.gt('probability', 60.0); // Use double value
    }

    // Order and paginate results
    final response =
        await query.order('created_at', ascending: false).range(from, to);

    List<AtlasOutput> outputs = [];
    for (var item in response) {
      outputs.add(AtlasOutput.fromJson(item));
    }

    // Get total count with the same filters
    var countQuery = _supabaseClient.from('atlas_output').select('id');

    // Apply the same filters to count query
    if (selectedDate != null) {
      final startDate =
          DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      final endDate = startDate
          .add(const Duration(days: 1))
          .subtract(const Duration(milliseconds: 1));

      countQuery = countQuery
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());
    }

    if (strongTrendOnly) {
      countQuery = countQuery.gt('probability', 50);
    }

    final countResponse = await countQuery;
    final count = countResponse.length;

    return {
      'data': outputs,
      'count': count,
      'page': page,
      'pageSize': pageSize,
    };
  }

  StreamSubscription<dynamic> subscribeToAtlasOutputs(
    void Function(AtlasOutput) callback, {
    bool strongTrendOnly = false,
    DateTime? selectedDate,
  }) {
    // Unsubscribe from any previous channel
    _channel?.unsubscribe();

    // Create a new channel
    final channel = _supabaseClient.channel('atlas_output_changes');

    // Create filter if needed
    PostgresChangeFilter? filter;
    if (strongTrendOnly) {
      filter = PostgresChangeFilter(
        type: PostgresChangeFilterType.gt,
        column: 'probability',
        value: 50.0, // Use double value
      );
    }

    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'atlas_output',
      filter: filter,
      callback: (payload) {
        // Extract the new record
        if (payload.newRecord.isNotEmpty) {
          final newOutput = AtlasOutput.fromJson(payload.newRecord);

          // Apply date filter in memory if needed
          if (selectedDate != null) {
            final outputDate = DateTime.parse(newOutput.createdAt);
            final startOfDay = DateTime(
                selectedDate.year, selectedDate.month, selectedDate.day);
            final endOfDay = startOfDay.add(const Duration(days: 1));

            if (outputDate.isAfter(startOfDay) &&
                outputDate.isBefore(endOfDay)) {
              callback(newOutput);
            }
          } else {
            callback(newOutput);
          }
        }
      },
    );

    // Subscribe to the channel
    channel.subscribe(
      (status, [error]) {
        if (status == RealtimeSubscribeStatus.subscribed) {
          print('Successfully subscribed to atlas_output changes!');
        } else if (error != null) {
          print('Error subscribing to atlas_output changes: $error');
        }
      },
    );

    _channel = channel;

    // Return a StreamSubscription that can be cancelled
    final controller = StreamController<dynamic>();

    // Listen to the stream and handle cancellation
    final subscription = controller.stream.listen((_) {
      // This is not actually used, but needed to return a StreamSubscription
    });

    // Create a wrapper subscription that handles unsubscribing from the channel
    final wrapper = _SubscriptionWrapper(
      subscription,
      onCancel: () {
        channel.unsubscribe();
        controller.close();
      },
    );

    return wrapper;
  }
}

// Custom wrapper class to handle onCancel
class _SubscriptionWrapper implements StreamSubscription<dynamic> {
  final StreamSubscription<dynamic> _subscription;
  final VoidCallback onCancel;

  _SubscriptionWrapper(this._subscription, {required this.onCancel});

  @override
  Future<void> cancel() {
    onCancel();
    return _subscription.cancel();
  }

  @override
  Future<E> asFuture<E>([E? futureValue]) =>
      _subscription.asFuture(futureValue);

  @override
  bool get isPaused => _subscription.isPaused;

  @override
  void onData(void Function(dynamic data)? handleData) {
    _subscription.onData(handleData);
  }

  @override
  void onDone(void Function()? handleDone) {
    _subscription.onDone(handleDone);
  }

  @override
  void onError(Function? handleError) {
    _subscription.onError(handleError);
  }

  @override
  void pause([Future<void>? resumeSignal]) {
    _subscription.pause(resumeSignal);
  }

  @override
  void resume() {
    _subscription.resume();
  }
}

class AtlasOutputPage extends StatefulWidget {
  const AtlasOutputPage({Key? key}) : super(key: key);

  @override
  _AtlasOutputPageState createState() => _AtlasOutputPageState();
}

class _AtlasOutputPageState extends State<AtlasOutputPage>
    with SingleTickerProviderStateMixin {
  final SupabaseService _supabaseService =
      SupabaseService(Supabase.instance.client);
  List<AtlasOutput> _outputs = [];
  bool _isLoading = true;
  String? _error;
  int _page = 1;
  int _totalPages = 1;
  DateTime? _selectedDate;
  bool _strongTrendOnly = true;
  bool _above60pcnt = true;
  TabController? _tabController;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchOutputs();
    _setupSubscription();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _subscription?.cancel();
    super.dispose();
  }

  void _setupSubscription() {
    _subscription = _supabaseService.subscribeToAtlasOutputs((newOutput) {
      // Only add new output if it matches all current filters
      if ((_selectedDate == null ||
              (DateTime.parse(newOutput.createdAt).day == _selectedDate!.day &&
                  DateTime.parse(newOutput.createdAt).month ==
                      _selectedDate!.month &&
                  DateTime.parse(newOutput.createdAt).year ==
                      _selectedDate!.year)) &&
          (!_strongTrendOnly || newOutput.probability > 50)) {
        setState(() {
          _outputs = [newOutput, ..._outputs].take(10).toList();
        });
      }
    });
  }

  Future<void> _fetchOutputs() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }

      final result = await _supabaseService.getAtlasOutputs(
        page: _page,
        pageSize: 10,
        selectedDate: _selectedDate,
        strongTrendOnly: _strongTrendOnly,
        above60pcnt: _above60pcnt,
      );
      if (mounted) {
        setState(() {
          _outputs = result['data'];
          _totalPages = (result['count'] / 10).ceil();
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

  void _handleStrongTrendToggle(bool value) {
    if (mounted) {
      setState(() {
        _strongTrendOnly = value;
        _page = 1;
      });
    }

    _fetchOutputs();
  }

  void _handleAbove60Toggle(bool value) {
    if (mounted) {
      setState(() {
        _above60pcnt = value;
        _page = 1;
      });
    }

    _fetchOutputs();
  }

  void _handlePreviousPage() {
    if (_page > 1) {
      setState(() {
        _page--;
      });
      _fetchOutputs();
    }
  }

  void _handleNextPage() {
    if (_page < _totalPages) {
      setState(() {
        _page++;
      });
      _fetchOutputs();
    }
  }

  void _handleResetFilters() {
    setState(() {
      _selectedDate = null;
      _strongTrendOnly = false;
      _above60pcnt = false;
      _page = 1;
      _tabController?.index = 0;
    });
    _fetchOutputs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Market Sentiments'),
        elevation: 0,
      ),
      body: _isLoading
          ? _buildLoadingSkeleton()
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filters Section - Show actual content
          _buildFiltersSection(),

          SizedBox(height: 16),

          // Tabs Section with skeleton ListView
          Expanded(
            child: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  tabs: [
                    Tab(text: 'All Signals'),
                    Tab(text: 'Bullish'),
                    Tab(text: 'Bearish'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSkeletonListView(),
                      _buildSkeletonListView(),
                      _buildSkeletonListView(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Pagination Section - Show actual content
          _buildPaginationSection(),
        ],
      ),
    );
  }

  Widget _buildSkeletonListView() {
    return ListView.separated(
      itemCount: 6,
      separatorBuilder: (context, index) => SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildSkeletonCard();
      },
    );
  }

  Widget _buildSkeletonCard() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      color: isDark ? theme.cardColor : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark
              ? Colors.grey[700]!.withValues(alpha: 0.3)
              : Colors.grey[200]!.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                _buildShimmer(24, 24, isCircle: true),
                SizedBox(width: 12),
                _buildShimmer(100, 18),
                Spacer(),
                _buildShimmer(20, 20, isCircle: true),
              ],
            ),

            SizedBox(height: 16),

            // Title
            _buildShimmer(double.infinity, 20),

            SizedBox(height: 12),

            // Subtitle
            _buildShimmer(MediaQuery.of(context).size.width * 0.6, 16),

            SizedBox(height: 20),

            // Stats row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildShimmer(60, 14),
                      SizedBox(height: 6),
                      _buildShimmer(40, 24),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildShimmer(60, 14),
                      SizedBox(height: 6),
                      _buildShimmer(40, 24),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildShimmer(60, 14),
                      SizedBox(height: 6),
                      _buildShimmer(40, 24),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            // Progress bar
            _buildShimmer(double.infinity, 6),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer(double width, double height, {bool isCircle = false}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 1200),
      tween: Tween(begin: 0.3, end: 1.0),
      builder: (context, opacity, child) {
        return AnimatedOpacity(
          opacity: opacity,
          duration: Duration(milliseconds: 800),
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: _getShimmerColor(isDark, opacity),
              borderRadius: isCircle
                  ? BorderRadius.circular(height / 2)
                  : BorderRadius.circular(8),
            ),
          ),
        );
      },
    );
  }

  Color _getShimmerColor(bool isDark, double opacity) {
    if (isDark) {
      // Dark theme: Use lighter greys that adapt to opacity
      final baseColor = Colors.grey[700]!;
      final highlightColor = Colors.grey[600]!;
      return Color.lerp(baseColor, highlightColor, opacity)!
          .withValues(alpha: 0.4);
    } else {
      // Light theme: Use darker greys that adapt to opacity
      final baseColor = Colors.grey[300]!;
      final highlightColor = Colors.grey[200]!;
      return Color.lerp(baseColor, highlightColor, opacity)!
          .withValues(alpha: 0.8);
    }
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red),
          SizedBox(height: 16),
          Text('Error: $_error'),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchOutputs,
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filters Section
          _buildFiltersSection(),

          SizedBox(height: 16),

          // Tabs Section
          _buildTabsSection(),

          // Pagination Section
          _buildPaginationSection(),
        ],
      ),
    );
  }

  Widget _buildTabsSection() {
    return Expanded(
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: 'All Signals'),
              Tab(text: 'Bullish'),
              Tab(text: 'Bearish'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSignalsList('All'),
                _buildSignalsList('Bull'),
                _buildSignalsList('Bear'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignalsList(String tabType) {
    final filteredOutputs = _outputs.where((output) {
      return tabType == 'All' || output.type == tabType;
    }).toList();

    if (filteredOutputs.isEmpty) {
      return _buildEmptyState(tabType);
    }

    return ListView.builder(
      itemCount: filteredOutputs.length,
      itemBuilder: (context, index) {
        return _buildSignalCard(filteredOutputs[index], index);
      },
    );
  }

  Widget _buildEmptyState(String tabType) {
    String message = 'No ${tabType.toLowerCase()} signals found';
    if (_selectedDate != null) {
      message += ' for ${DateFormat('MMMM d, yyyy').format(_selectedDate!)}';
    }
    if (_strongTrendOnly) {
      message += ' with strong trend';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(message),
          SizedBox(height: 16),
          if (_selectedDate != null || _strongTrendOnly || tabType != 'All')
            ElevatedButton(
              onPressed: _handleResetFilters,
              child: Text('Reset Filters'),
            ),
        ],
      ),
    );
  }

  Widget _buildSignalCard(AtlasOutput output, int index) {
    final totalIndicators = output.positiveIndicators +
        output.negativeIndicators +
        output.neutralIndicators;

    // final styles = _getSentimentStyles(output.type);

    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            // color: styles.borderColor,
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: () => _showDetailDialog(output),
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            _getSignalIcon(output.type),
                            SizedBox(width: 8),
                            Text(
                              '${output.type} Signal',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(Icons.info),
                          onPressed: () => _showDetailDialog(output),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Icon(Icons.access_time,
                                size: 16, color: Colors.grey),
                            SizedBox(width: 4),
                            Text(
                              DateFormat('MMM d y h:mm a')
                                  .format(DateTime.parse(output.createdAt)),
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                            SizedBox(width: 8),
                          ],
                        ),
                        Text(
                          timeago.format(DateTime.parse(output.createdAt)),
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Card Content
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Signal Probability
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Signal Probability',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            // color: styles.badgeColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${output.probability}%',
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 16),

                    // Short Term and Long Term
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Text(
                                'Short Term:',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              SizedBox(width: 8),
                              _getSignalIcon(output.shortterm),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              Text(
                                'Long Term:',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              SizedBox(width: 8),
                              _getSignalIcon(output.longterm),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 16),

                    // Breakouts if any
                    if (output.upbreakout || output.lowbreakout)
                      Wrap(
                        spacing: 8,
                        children: [
                          if (output.upbreakout)
                            Chip(
                              backgroundColor: Colors.green,
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.trending_up,
                                      color: Colors.white, size: 16),
                                  SizedBox(width: 4),
                                  Text('Up Breakout',
                                      style: TextStyle(color: Colors.white)),
                                ],
                              ),
                            ),
                          if (output.lowbreakout)
                            Chip(
                              backgroundColor: Colors.red,
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.trending_down,
                                      color: Colors.white, size: 16),
                                  SizedBox(width: 4),
                                  Text('Low Breakout',
                                      style: TextStyle(color: Colors.white)),
                                ],
                              ),
                            ),
                        ],
                      ),

                    SizedBox(height: 16),

                    // Indicators Distribution
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Indicators Distribution'),
                            Text('$totalIndicators Total'),
                          ],
                        ),
                        SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            height: 8,
                            child: Row(
                              children: [
                                Expanded(
                                  flex: output.positiveIndicators,
                                  child: Container(color: Colors.green),
                                ),
                                Expanded(
                                  flex: output.neutralIndicators,
                                  child: Container(color: Colors.amber),
                                ),
                                Expanded(
                                  flex: output.negativeIndicators,
                                  child: Container(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Positive: ${output.positiveIndicators}',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                            Text('Neutral: ${output.neutralIndicators}',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                            Text('Negative: ${output.negativeIndicators}',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey)),
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
      ),
    );
  }

  Widget _getSignalIcon(String type) {
    switch (type) {
      case 'Bull':
        return Icon(Icons.trending_up, color: Colors.green);
      case 'Bear':
        return Icon(Icons.trending_down, color: Colors.red);
      default:
        return Icon(Icons.remove, color: Colors.grey);
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

  Widget _buildFiltersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null && picked != _selectedDate) {
                    setState(() {
                      _selectedDate = picked;
                      _page = 1;
                    });
                    _fetchOutputs();
                  }
                },
                child: Text(
                  _selectedDate != null
                      ? DateFormat('MMMM d, yyyy').format(_selectedDate!)
                      : 'Select Date',
                ),
              ),
            ),
            if (_selectedDate != null)
              IconButton(
                icon: Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    _selectedDate = null;
                    _page = 1;
                  });
                  _fetchOutputs();
                },
              ),
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Switch(
              value: _strongTrendOnly,
              onChanged: _handleStrongTrendToggle,
            ),
            SizedBox(width: 8),
            Text('Show Strong Trend Only'),
            Spacer(),
            if (_selectedDate != null || _strongTrendOnly)
              TextButton(
                onPressed: _handleResetFilters,
                child: Text('Clear Filters'),
              ),
          ],
        ),
        Row(
          children: [
            Switch(
              value: _above60pcnt,
              onChanged: _handleAbove60Toggle,
            ),
            SizedBox(width: 8),
            Text('Show 60% probability and Above'),
            Spacer(),
          ],
        ),
      ],
    );
  }

  Widget _buildPaginationSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            onPressed: _page > 1 ? _handlePreviousPage : null,
            child: Text('Previous'),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(100, 36),
            ),
          ),
          Text('Page $_page of $_totalPages'),
          ElevatedButton(
            onPressed: _page < _totalPages ? _handleNextPage : null,
            child: Text('Next'),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(100, 36),
            ),
          ),
        ],
      ),
    );
  }
}
