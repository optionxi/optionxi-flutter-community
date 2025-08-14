import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:optionxi/Components/cust_alert_item.dart';
import 'package:optionxi/Components/custom_searchbar.dart';
import 'package:optionxi/DataModels/sample_stock_symbols.dart';
import 'package:optionxi/Main_Pages/act_search_stocks_alerts.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class AlertModel {
  final int id;
  final String date;
  final String description;
  final String? symbol;
  final String? sentiment;
  final double? close;
  final double? prevClose;
  final double? pcnt;
  final double? high;
  final double? low;
  final double? week52High;
  final double? week52Low;
  final double? prevDayLow;
  final double? prevDayHigh;
  final double? volume;
  final double? sma5Volume;
  final double? open;
  final String createdAt;
  final String updatedAt;

  AlertModel({
    required this.id,
    required this.date,
    required this.description,
    this.symbol,
    this.sentiment,
    this.close,
    this.prevClose,
    this.pcnt,
    this.high,
    this.low,
    this.week52High,
    this.week52Low,
    this.prevDayLow,
    this.prevDayHigh,
    this.volume,
    this.sma5Volume,
    this.open,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'] ?? 0,
      date: json['date'] ?? '',
      description: json['description'] ?? '',
      symbol: json['symbol'],
      sentiment: json['sentiment'],
      close: (json['close'] as num?)?.toDouble(),
      prevClose: (json['prev_close'] as num?)?.toDouble(),
      pcnt: (json['pcnt'] as num?)?.toDouble(),
      high: (json['high'] as num?)?.toDouble(),
      low: (json['low'] as num?)?.toDouble(),
      week52High: (json['52_week_high'] as num?)?.toDouble(),
      week52Low: (json['52_week_low'] as num?)?.toDouble(),
      prevDayLow: (json['prev_day_low'] as num?)?.toDouble(),
      prevDayHigh: (json['prev_day_high'] as num?)?.toDouble(),
      volume: (json['volume'] as num?)?.toDouble(),
      sma5Volume: (json['sma_5_volume'] as num?)?.toDouble(),
      open: (json['open'] as num?)?.toDouble(),
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}

// Constants
const int pageSize = 20;

enum SentimentFilter { all, bullish, bearish }

class StockAlertsPage extends StatefulWidget {
  final String? stockname;
  const StockAlertsPage(this.stockname, {Key? key}) : super(key: key);

  @override
  _StockAlertsPageState createState() => _StockAlertsPageState();
}

class _StockAlertsPageState extends State<StockAlertsPage> {
  // Supabase client
  final supabase = Supabase.instance.client;

  // Controllers
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // State variables
  List<AlertModel> _alerts = [];
  bool _isLoading = true;
  String? _error;
  int _currentPage = 1;
  int _totalCount = 0;
  String _selectedStock = 'all';
  DateTime? _selectedDate;
  SentimentFilter _currentFilter = SentimentFilter.all;
  bool _isSearchFocused = false;
  String _displayStockName = '';
  String _searchQuery = '';
  RealtimeChannel? _channel;
  @override
  void initState() {
    super.initState();
    // Initialize with the stock passed in constructor if any
    if (widget.stockname != null &&
        widget.stockname!.isNotEmpty &&
        widget.stockname != "all") {
      _selectedStock = widget.stockname!;

      // Find the display name for the selected stock
      if (totalStocks.containsKey(widget.stockname)) {
        setState(() {
          _displayStockName = totalStocks[widget.stockname]
                  ?['full_stock_name'] ??
              widget.stockname!;
        });
      } else {
        setState(() {
          _displayStockName = widget.stockname!;
        });
      }
    } else {
      // If stockname is null or empty or "all", show all stocks
      _selectedStock = 'all';
      _displayStockName = '';
    }

    _fetchAlerts();
    _subscribeToAlerts();

    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
        if (_isSearchFocused && _searchQuery.isEmpty) {
          _searchQuery = '';
        }
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _channel?.unsubscribe().then((_) {
      _channel = null;
    });
    super.dispose();
  }

// Helper method to apply filters to a query
  PostgrestFilterBuilder<PostgrestList> _applyFilters(
      PostgrestFilterBuilder<PostgrestList> query) {
    // Apply sentiment filter
    if (_currentFilter == SentimentFilter.bullish) {
      query = query.eq('sentiment', 'bullish');
    } else if (_currentFilter == SentimentFilter.bearish) {
      query = query.eq('sentiment', 'bearish');
    }

    // Apply stock filter
    if (_selectedStock != 'all') {
      query = query.eq('symbol', _selectedStock);
    }

    // Apply date filter
    if (_selectedDate != null) {
      final startDate = DateTime(
          _selectedDate!.year, _selectedDate!.month, _selectedDate!.day);
      final endDate = startDate
          .add(const Duration(days: 1))
          .subtract(const Duration(milliseconds: 1));

      query = query
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());
    }

    return query;
  }

  Future<void> _fetchAlerts() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final from = (_currentPage - 1) * pageSize;
      final to = from + pageSize - 1;

      // Start building the query
      var query = supabase.from('live_scanner').select();
      query = _applyFilters(query);
      final response =
          await query.order('created_at', ascending: false).range(from, to);

      // Get total count with the same filters applied
      var countQuery = supabase.from('live_scanner').select('id');
      countQuery = _applyFilters(countQuery);
      final countResponse = await countQuery;
      final count = countResponse.length;

      final data =
          (response as List).map((item) => AlertModel.fromJson(item)).toList();

      if (mounted) {
        setState(() {
          _alerts = data;
          _totalCount = count;
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

  void _subscribeToAlerts() {
    _channel?.unsubscribe();

    final channel = supabase.channel('live_scanner_changes_filtered');

    PostgresChangeFilter? activeSubscriptionFilter;
    if (_selectedStock != 'all') {
      activeSubscriptionFilter = PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'symbol',
        value: _selectedStock,
      );
    } else if (_currentFilter != SentimentFilter.all) {
      activeSubscriptionFilter = PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'sentiment',
        value:
            _currentFilter == SentimentFilter.bullish ? 'bullish' : 'bearish',
      );
    }

    channel
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'live_scanner',
      filter: activeSubscriptionFilter,
      callback: (payload) {
        if (mounted) {
          _fetchAlerts();
        }
      },
    )
        .subscribe(
      (status, [error]) {
        if (status == RealtimeSubscribeStatus.subscribed) {
          print('Successfully subscribed to filtered channel!');
        } else if (error != null) {
          print('Error subscribing to channel: $error');
        }
      },
    );

    _channel = channel;
  }

  void _handleFilterChange(SentimentFilter filter) {
    setState(() {
      _currentFilter = filter;
      _currentPage = 1;
    });
    _fetchAlerts();
    _subscribeToAlerts();
  }

  void _handleClearStock() {
    setState(() {
      _selectedStock = 'all';
      _displayStockName = '';
      _searchQuery = '';
      _currentPage = 1;
    });
    _fetchAlerts();
    _subscribeToAlerts();
  }

  void _handleDateChange(DateTime? date) {
    setState(() {
      _selectedDate = date;
      _currentPage = 1;
    });
    _fetchAlerts();
    _subscribeToAlerts();
  }

  void _handlePageChange(int page) {
    setState(() {
      _currentPage = page;
    });
    _fetchAlerts();
  }

  Widget _buildSearchBar() {
    return const ModernSearchBar();
  }

  Widget _buildPagination() {
    final int totalPages = (_totalCount / pageSize).ceil();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            onPressed: _currentPage > 1 && !_isLoading
                ? () => _handlePageChange(_currentPage - 1)
                : null,
            child: const Text('Previous'),
          ),
          Text(
            'Page $_currentPage of ${totalPages > 0 ? totalPages : 1}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          ElevatedButton(
            onPressed: _currentPage < totalPages && !_isLoading
                ? () => _handlePageChange(_currentPage + 1)
                : null,
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.search_off,
          size: 64,
          color: Theme.of(context).disabledColor,
        ),
        const SizedBox(height: 16),
        const Text('No alerts found',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          'Try again sometime later or adjust your filters',
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
        ),
      ],
    );
  }

  Widget _buildSkeletonItem() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          _buildShimmer(48, 48, 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: _buildShimmer(20, null, 4)),
                  const SizedBox(width: 12),
                  _buildShimmer(24, 60, 12),
                ]),
                const SizedBox(height: 12),
                _buildShimmer(14, null, 4),
                const SizedBox(height: 6),
                _buildShimmer(14, 200, 4),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildShimmer(12, 80, 4),
                    _buildShimmer(12, 50, 4)
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer(double height, double? width, double radius) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]?.withOpacity(0.3)
            : Colors.grey[300]?.withOpacity(0.5),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error.withOpacity(0.1),
        border: Border.all(color: Theme.of(context).colorScheme.error),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Error',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Theme.of(context).colorScheme.error)),
          const SizedBox(height: 8),
          Text(_error!,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer)),
        ],
      ),
    );
  }

  double _getFiltersHeight() {
    double height = 0;
    if (_selectedStock == 'all') {
      height += 70; // Search bar
    } else if (_displayStockName.isNotEmpty) {
      height += 50; // Stock chip
    }
    height += 70; // Date picker
    return height;
  }

  Widget _buildCollapsibleFilters() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_selectedStock == 'all')
          GestureDetector(
            onTap: () async {
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const StockSearchPageAlerts()));
            },
            child: AbsorbPointer(
                child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: _buildSearchBar())),
          )
        else if (_displayStockName.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Wrap(spacing: 8, runSpacing: 8, children: [
              Chip(
                label: Text(_displayStockName),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: _handleClearStock,
                backgroundColor:
                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                side: BorderSide(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.5)),
                labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold),
              )
            ]),
          ),
        InkWell(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now());
            if (picked != null && picked != _selectedDate) {
              _handleDateChange(picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const Icon(Icons.calendar_today, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                    _selectedDate == null
                        ? 'Pick a date'
                        : DateFormat('MMMM d, yyyy').format(_selectedDate!),
                    style: const TextStyle(fontSize: 16)),
              ),
              if (_selectedDate != null)
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => _handleDateChange(null),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints()),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildSentimentFilters() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 12.0),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Row(children: [
        Expanded(
          child: ElevatedButton(
              onPressed: () => _handleFilterChange(SentimentFilter.all),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _currentFilter == SentimentFilter.all
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).cardColor,
                  foregroundColor: _currentFilter == SentimentFilter.all
                      ? Colors.white
                      : Theme.of(context).textTheme.bodyLarge?.color,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                          color: Theme.of(context).dividerColor, width: 1)),
                  padding: const EdgeInsets.symmetric(vertical: 12)),
              child: const Text('All')),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
              onPressed: () => _handleFilterChange(SentimentFilter.bullish),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _currentFilter == SentimentFilter.bullish
                      ? Colors.green[600]
                      : Theme.of(context).cardColor,
                  foregroundColor: _currentFilter == SentimentFilter.bullish
                      ? Colors.white
                      : Colors.green[700],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                          color: Theme.of(context).dividerColor, width: 1)),
                  padding: const EdgeInsets.symmetric(vertical: 12)),
              child: const Text('Bullish')),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
              onPressed: () => _handleFilterChange(SentimentFilter.bearish),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _currentFilter == SentimentFilter.bearish
                      ? Colors.red[600]
                      : Theme.of(context).cardColor,
                  foregroundColor: _currentFilter == SentimentFilter.bearish
                      ? Colors.white
                      : Colors.red[700],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                          color: Theme.of(context).dividerColor, width: 1)),
                  padding: const EdgeInsets.symmetric(vertical: 12)),
              child: const Text('Bearish')),
        ),
      ]),
    );
  }

  List<Widget> _buildBodySlivers() {
    if (_isLoading) {
      return [
        SliverList(
            delegate: SliverChildBuilderDelegate(
                (context, index) => _buildSkeletonItem(),
                childCount: 5))
      ];
    }
    if (_error != null) {
      return [SliverFillRemaining(child: _buildErrorWidget())];
    }
    if (_alerts.isEmpty) {
      return [
        SliverFillRemaining(hasScrollBody: false, child: _buildEmptyState())
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        sliver: SliverList.builder(
            itemCount: _alerts.length,
            itemBuilder: (context, index) {
              final prevAlert =
                  (index + 1 < _alerts.length) ? _alerts[index + 1] : null;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AlertItem(
                    alert: _alerts[index],
                    prevAlert: _selectedStock == "all" ? null : prevAlert,
                    index: index),
              );
            }),
      ),
      SliverToBoxAdapter(child: _buildPagination()),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    const double sentimentFilterHeight = 64;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            surfaceTintColor: Theme.of(context).scaffoldBackgroundColor,
            pinned: true,
            expandedHeight: kToolbarHeight +
                topPadding +
                _getFiltersHeight() +
                sentimentFilterHeight,
            leading: Center(
              child: InkWell(
                onTap: () => Navigator.pop(context),
                child: Container(
                  margin: const EdgeInsets.only(left: 12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Icon(Icons.navigate_before,
                      color: Theme.of(context).textTheme.titleSmall?.color),
                ),
              ),
            ),
            title: const Text('Stock Alerts'),
            flexibleSpace: FlexibleSpaceBar(
              background: Padding(
                padding: EdgeInsets.only(
                  top: kToolbarHeight + topPadding,
                  bottom: sentimentFilterHeight, // Space for the pinned filters
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: _buildCollapsibleFilters(),
                    ),
                  ],
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(sentimentFilterHeight),
              child: _buildSentimentFilters(),
            ),
          ),
          ..._buildBodySlivers(),
        ],
      ),
    );
  }
}
