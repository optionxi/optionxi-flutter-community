import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Initialize Supabase client
final supabase = Supabase.instance.client;

// Data Models
class BollingerBreakoutModel {
  final int id;
  final String createdAt;
  final String description;
  final String time;
  final String sentiment;
  final String? whichmode;

  BollingerBreakoutModel({
    required this.id,
    required this.createdAt,
    required this.description,
    required this.time,
    required this.sentiment,
    this.whichmode,
  });

  factory BollingerBreakoutModel.fromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.parse(json['created_at']).toLocal();

    return BollingerBreakoutModel(
      id: json['id'],
      createdAt: createdAt.toIso8601String(), // Store as ISO string
      description: json['description'],
      time: json['time'],
      sentiment: json['sentiment'],
      whichmode: json['whichmode'],
    );
  }
}

class BollingerResponse {
  final List<BollingerBreakoutModel> data;
  final int count;
  final int page;
  final int pageSize;

  BollingerResponse({
    required this.data,
    required this.count,
    required this.page,
    required this.pageSize,
  });
}

class BollingerService {
  static final supabase = Supabase.instance.client;

  static Future<BollingerResponse> getBollingerBreakouts({
    int page = 1,
    int pageSize = 30,
    String? startDate,
    String? endDate,
    bool filterByEntry = false,
  }) async {
    final from = (page - 1) * pageSize;
    final to = from + pageSize - 1;

    // Create the base query
    var query = supabase.from('bollinger_breakouts').select();

    // Apply filters
    if (startDate != null) {
      query = query.gte('created_at', startDate);
    }
    if (endDate != null) {
      query = query.lte('created_at', endDate);
    }
    if (filterByEntry) {
      query = query.eq('whichmode', 'checkfirst');
    }

    // First, get count of total records that match the filter
    final countResponse = await query;
    final count = countResponse.length;

    // Then execute query with pagination
    final response =
        await query.order('created_at', ascending: false).range(from, to);

    // Parse data
    final List<BollingerBreakoutModel> data = [];
    for (final item in response) {
      data.add(BollingerBreakoutModel.fromJson(item));
    }

    return BollingerResponse(
      data: data,
      count: count,
      page: page,
      pageSize: pageSize,
    );
  }

  static Future<BollingerResponse> getFilteredBollingerBreakouts({
    required String sentiment,
    int page = 1,
    int pageSize = 30,
    bool filterByEntry = false,
  }) async {
    final from = (page - 1) * pageSize;
    final to = from + pageSize - 1;

    // Create the base query with sentiment filter
    var query = supabase
        .from('bollinger_breakouts')
        .select()
        .eq('sentiment', sentiment);

    // Apply entry filter if needed
    if (filterByEntry) {
      query = query.eq('whichmode', 'checkfirst');
    }

    // First, get count of total records that match the filter
    final countResponse = await query;
    final count = countResponse.length;

    // Then execute query with pagination
    final response =
        await query.order('created_at', ascending: false).range(from, to);

    // Parse data
    final List<BollingerBreakoutModel> data = [];
    for (final item in response) {
      data.add(BollingerBreakoutModel.fromJson(item));
    }

    return BollingerResponse(
      data: data,
      count: count,
      page: page,
      pageSize: pageSize,
    );
  }

  static Stream<BollingerBreakoutModel> subscribeToBollingerBreakouts() {
    final controller = StreamController<BollingerBreakoutModel>.broadcast();

    final channel = supabase.channel('bollinger_breakouts_changes');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'bollinger_breakouts',
      callback: (payload) {
        if (payload.newRecord.isNotEmpty) {
          try {
            final newBreakout = BollingerBreakoutModel.fromJson(
              Map<String, dynamic>.from(payload.newRecord),
            );
            controller.add(newBreakout);
          } catch (e) {
            debugPrint('Error parsing breakout: $e');
          }
        }
      },
    );

    channel.subscribe();

    // Return a stream that cleans up the subscription when it's closed
    controller.onCancel = () {
      channel.unsubscribe();
    };

    return controller.stream;
  }
}

class BollingerBreakoutsPage extends StatefulWidget {
  const BollingerBreakoutsPage({Key? key}) : super(key: key);

  @override
  State<BollingerBreakoutsPage> createState() => _BollingerBreakoutsPageState();
}

class _BollingerBreakoutsPageState extends State<BollingerBreakoutsPage> {
  List<BollingerBreakoutModel> _data = [];
  bool _loading = true;
  String? _error;
  int _page = 1;
  int _totalCount = 0;
  DateTime? _selectedDate;
  String? _sentimentFilter;
  bool _filterByEntry = true;
  final int _pageSize = 10;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _setupSubscription();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _setupSubscription() {
    _subscription =
        BollingerService.subscribeToBollingerBreakouts().listen((newBreakout) {
      if (_page == 1) {
        setState(() {
          _data = [newBreakout, ..._data.take(_pageSize - 1).toList()];
          _totalCount = _totalCount + 1;
        });
      }
    });
  }

  Future<void> _fetchData() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      BollingerResponse result;

      if (_sentimentFilter != null) {
        result = await BollingerService.getFilteredBollingerBreakouts(
          sentiment: _sentimentFilter!,
          page: _page,
          pageSize: _pageSize,
          filterByEntry: _filterByEntry,
        );
      } else {
        final startOfDay = _selectedDate != null
            ? DateTime(_selectedDate!.year, _selectedDate!.month,
                    _selectedDate!.day)
                .toIso8601String()
            : null;
        final endOfDay = _selectedDate != null
            ? DateTime(_selectedDate!.year, _selectedDate!.month,
                    _selectedDate!.day, 23, 59, 59, 999)
                .toIso8601String()
            : null;

        result = await BollingerService.getBollingerBreakouts(
          page: _page,
          pageSize: _pageSize,
          startDate: startOfDay,
          endDate: endOfDay,
          filterByEntry: _filterByEntry,
        );
      }

      if (mounted) {
        setState(() {
          _data = result.data;
          _totalCount = result.count;
          _loading = false;
        });
      }
    } catch (err) {
      if (mounted) {
        setState(() {
          _error = 'Failed to fetch data';
          _loading = false;
        });
        debugPrint(err.toString());
      }
    }
  }

  int get _totalPages => (_totalCount / _pageSize).ceil();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bollinger Breakouts'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filters section
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Date filter
                _buildDateFilter(),

                // Sentiment filters
                _buildSentimentButton(
                  label: 'Bullish',
                  value: 'bullish',
                  color: Colors.green,
                ),
                _buildSentimentButton(
                  label: 'Bearish',
                  value: 'bearish',
                  color: Colors.red,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Clear filters and entry toggle row
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedDate = null;
                          _sentimentFilter = null;
                          _filterByEntry = true;
                          _page = 1;
                        });
                        _fetchData();
                      },
                      icon: const Icon(Icons.clear, size: 18),
                      label: const Text('Clear Filters'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.surface,
                        foregroundColor: theme.colorScheme.onSurface,
                      )),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  // decoration: BoxDecoration(
                  //   borderRadius: BorderRadius.circular(8),
                  //   color: theme.colorScheme.surface,
                  // ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Show first entries',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: _filterByEntry,
                        onChanged: (value) {
                          setState(() {
                            _filterByEntry = value;
                            _page = 1;
                          });
                          _fetchData();
                        },
                        activeColor: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Content section
            Expanded(
              child: _buildContent(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateFilter() {
    final theme = Theme.of(context);
    final dateText = _selectedDate != null
        ? DateFormat('MMM d, yyyy').format(_selectedDate!)
        : 'Select Date';

    return OutlinedButton.icon(
      onPressed: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 30)),
          builder: (BuildContext context, Widget? child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: theme.colorScheme.primary,
                  onPrimary: theme.colorScheme.onPrimary,
                  surface: theme.colorScheme.surface,
                  onSurface: theme.colorScheme.onSurface,
                ),
                dialogBackgroundColor: theme.colorScheme.background,
              ),
              child: child!,
            );
          },
        );

        if (picked != null && picked != _selectedDate) {
          setState(() {
            _selectedDate = picked;
            _page = 1;
          });
          _fetchData();
        }
      },
      icon: const Icon(Icons.calendar_today, size: 16),
      label: Text(dateText),
      style: OutlinedButton.styleFrom(
        foregroundColor: theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildSentimentButton({
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final isSelected = _sentimentFilter == value;

    return ElevatedButton(
      onPressed: () {
        setState(() {
          _sentimentFilter = _sentimentFilter == value ? null : value;
          _page = 1;
        });
        _fetchData();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color : theme.colorScheme.surface,
        foregroundColor: isSelected ? Colors.white : color,
      ),
      child: Text(label),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_error != null) {
      return _buildErrorState(theme);
    }

    if (_loading) {
      return _buildLoadingSkeleton(theme);
    }

    if (_data.isEmpty) {
      return _buildEmptyState(theme);
    }

    return Column(
      children: [
        // List of cards
        Expanded(
          child: ListView.builder(
            itemCount: _data.length,
            itemBuilder: (context, index) {
              final item = _data[index];

              return Animate(
                effects: [
                  FadeEffect(
                    delay: Duration(milliseconds: index * 100),
                    duration: const Duration(milliseconds: 300),
                  ),
                  SlideEffect(
                    delay: Duration(milliseconds: index * 100),
                    duration: const Duration(milliseconds: 300),
                    begin: const Offset(0.2, 0),
                    end: const Offset(0, 0),
                  ),
                ],
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildBreakoutCard(item, theme),
                ),
              );
            },
          ),
        ),

        // Pagination
        _buildPagination(theme),
      ],
    );
  }

  Widget _buildBreakoutCard(BollingerBreakoutModel item, ThemeData theme) {
    final createdAt = DateTime.parse(item.createdAt).toLocal();
    ;
    final formattedDate = DateFormat('MMM d, yyyy h:mm a').format(createdAt);
    final timeAgo = _getTimeAgo(createdAt);

    final sentimentColor =
        item.sentiment == 'bullish' ? Colors.green : Colors.red;

    final hasBreakoutText =
        item.description.toLowerCase().contains('first breakout');
    final numberValue = _extractNumberAfterColon(item.description);

    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      color: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "NIFTY50 IN " + item.sentiment.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: sentimentColor,
                      ),
                    ),
                    Text(
                      formattedDate,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                Text(
                  timeAgo,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Content
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.description.split(':')[0],
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                if (numberValue != null)
                  Text(
                    numberValue,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                if (hasBreakoutText)
                  Icon(
                    item.sentiment == 'bullish'
                        ? Icons.trending_up
                        : Icons.trending_down,
                    color: sentimentColor,
                    size: 20,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String? _extractNumberAfterColon(String text) {
    final match = RegExp(r':\s*(\d+)').firstMatch(text);
    return match != null ? match.group(1) : null;
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

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

  Widget _buildLoadingSkeleton(ThemeData theme) {
    final baseColor = theme.brightness == Brightness.dark
        ? Colors.grey[800]!
        : Colors.grey[300]!;
    final highlightColor = theme.brightness == Brightness.dark
        ? Colors.grey[700]!
        : Colors.grey[200]!;

    return ListView.builder(
      itemCount: 6,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            color: theme.cardColor,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 80,
                            height: 16,
                            color: baseColor,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 120,
                            height: 12,
                            color: highlightColor,
                          ),
                        ],
                      ),
                      Container(
                        width: 60,
                        height: 12,
                        color: highlightColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    height: 60,
                    color: highlightColor,
                  ),
                ],
              ),
            ),
          ),
        )
            .animate(
              onPlay: (controller) => controller.repeat(),
            )
            .shimmer(
              duration: 1000.ms,
              delay: (index * 100).ms,
              color: theme.brightness == Brightness.dark
                  ? Colors.grey[600]!
                  : Colors.grey[100]!,
            );
      },
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Failed to load Bollinger Breakouts',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _fetchData,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(16),
              child: Icon(
                Icons.search_off,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No signals found for the selected filters',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedDate = null;
                  _sentimentFilter = null;
                  _filterByEntry = false;
                  _page = 1;
                });
                _fetchData();
              },
              child: const Text('Reset filters'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            onPressed: _page <= 1
                ? null
                : () {
                    setState(() {
                      _page--;
                    });
                    _fetchData();
                  },
            child: const Text('Previous'),
          ),
          Text(
            'Page $_page of $_totalPages',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          ElevatedButton(
            onPressed: _page >= _totalPages
                ? null
                : () {
                    setState(() {
                      _page++;
                    });
                    _fetchData();
                  },
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }
}
