import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:meilisearch/meilisearch.dart' as meili;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:optionxi/Components/cust_alert_item.dart';
import 'package:optionxi/DataModels/sample_stock_symbols.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────
// DESIGN TOKENS
// ─────────────────────────────────────────────────────────────

class AppTokens {
  static const double radiusXs = 6;
  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 18;
  static const double radiusPill = 100;

  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 12;
  static const double spacingLg = 16;
  static const double spacingXl = 20;
  static const double spacingXxl = 24;

  static const Color bullish = Color(0xFF10B981);
  static const Color bullishDim = Color(0x1A10B981);
  static const Color bullishBorder = Color(0x3310B981);

  static const Color bearish = Color(0xFFF43F5E);
  static const Color bearishDim = Color(0x1AF43F5E);
  static const Color bearishBorder = Color(0x33F43F5E);

  static const Color neutral = Color(0xFF6366F1);
  static const Color neutralDim = Color(0x1A6366F1);
  static const Color neutralBorder = Color(0x336366F1);
}

class AppColors {
  static const Color darkBg = Color(0xFF080A0F);
  static const Color darkSurface = Color(0xFF0F1218);
  static const Color darkSurface2 = Color(0xFF161B25);
  static const Color darkSurface3 = Color(0xFF1C2230);
  static const Color darkBorder = Color(0x14FFFFFF);
  static const Color darkBorderStrong = Color(0x22FFFFFF);
  static const Color darkTextPrimary = Color(0xFFEDF0F7);
  static const Color darkTextSecondary = Color(0xFF8892A4);
  static const Color darkTextMuted = Color(0xFF3F4A5C);

  static const Color lightBg = Color(0xFFF0F2F7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurface2 = Color(0xFFEBEEF5);
  static const Color lightSurface3 = Color(0xFFE0E5EF);
  static const Color lightBorder = Color(0x0F000000);
  static const Color lightBorderStrong = Color(0x1A000000);
  static const Color lightTextPrimary = Color(0xFF0D1117);
  static const Color lightTextSecondary = Color(0xFF5A6478);
  static const Color lightTextMuted = Color(0xFFADB5C7);
}

// ─────────────────────────────────────────────────────────────
// THEME EXTENSION
// ─────────────────────────────────────────────────────────────

class AppThemeData extends ThemeExtension<AppThemeData> {
  final Color bg;
  final Color surface;
  final Color surface2;
  final Color surface3;
  final Color border;
  final Color borderStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  const AppThemeData({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.surface3,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
  });

  static const dark = AppThemeData(
    bg: AppColors.darkBg,
    surface: AppColors.darkSurface,
    surface2: AppColors.darkSurface2,
    surface3: AppColors.darkSurface3,
    border: AppColors.darkBorder,
    borderStrong: AppColors.darkBorderStrong,
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
    textMuted: AppColors.darkTextMuted,
  );

  static const light = AppThemeData(
    bg: AppColors.lightBg,
    surface: AppColors.lightSurface,
    surface2: AppColors.lightSurface2,
    surface3: AppColors.lightSurface3,
    border: AppColors.lightBorder,
    borderStrong: AppColors.lightBorderStrong,
    textPrimary: AppColors.lightTextPrimary,
    textSecondary: AppColors.lightTextSecondary,
    textMuted: AppColors.lightTextMuted,
  );

  @override
  AppThemeData copyWith({
    Color? bg,
    Color? surface,
    Color? surface2,
    Color? surface3,
    Color? border,
    Color? borderStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
  }) =>
      AppThemeData(
        bg: bg ?? this.bg,
        surface: surface ?? this.surface,
        surface2: surface2 ?? this.surface2,
        surface3: surface3 ?? this.surface3,
        border: border ?? this.border,
        borderStrong: borderStrong ?? this.borderStrong,
        textPrimary: textPrimary ?? this.textPrimary,
        textSecondary: textSecondary ?? this.textSecondary,
        textMuted: textMuted ?? this.textMuted,
      );

  @override
  AppThemeData lerp(ThemeExtension<AppThemeData>? other, double t) {
    if (other is! AppThemeData) return this;
    return AppThemeData(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      surface3: Color.lerp(surface3, other.surface3, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ALERT MODEL
// ─────────────────────────────────────────────────────────────

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

  factory AlertModel.fromJson(Map<String, dynamic> json) => AlertModel(
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

  bool get isBullish => sentiment?.toLowerCase() == 'bullish';
  bool get isBearish => sentiment?.toLowerCase() == 'bearish';
}

// ─────────────────────────────────────────────────────────────
// CONSTANTS
// ─────────────────────────────────────────────────────────────

const int pageSize = 20;

enum SentimentFilter { all, bullish, bearish }

// ─────────────────────────────────────────────────────────────
// MAIN PAGE
// ─────────────────────────────────────────────────────────────

class StockAlertsPage extends StatefulWidget {
  final String? stockname;
  const StockAlertsPage(this.stockname, {Key? key}) : super(key: key);

  @override
  _StockAlertsPageState createState() => _StockAlertsPageState();
}

class _StockAlertsPageState extends State<StockAlertsPage>
    with TickerProviderStateMixin {
  // ── Supabase ──
  final supabase = Supabase.instance.client;

  // ── Meilisearch ──
  late meili.MeiliSearchClient _meili;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearchOpen = false; // dropdown visible?
  bool _isSearchLoading = false;
  Timer? _debounce;

  // ── Scroll / animation ──
  final ScrollController _scrollController = ScrollController();
  late AnimationController _shimmerController;

  // ── Alerts state ──
  List<AlertModel> _alerts = [];
  bool _isLoading = true;
  String? _error;
  int _currentPage = 1;
  int _totalCount = 0;

  // ── Filters ──
  String _selectedStock = 'all';
  DateTime? _selectedDate;
  SentimentFilter _currentFilter = SentimentFilter.all;
  String _displayStockName = '';

  // ── Realtime ──
  RealtimeChannel? _channel;

  // ─────────────────────────────────────────────
  // LIFECYCLE
  // ─────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _meili = meili.MeiliSearchClient(
      dotenv.env['MELIESEARCH_URL']!,
      dotenv.env['MELIE_API_KEY']!,
    );

    // Open dropdown when field gains focus
    _searchFocus.addListener(() {
      if (_searchFocus.hasFocus && !_isSearchOpen) {
        setState(() => _isSearchOpen = true);
        _runSearch(''); // show initial results
      }
    });

    if (widget.stockname != null &&
        widget.stockname!.isNotEmpty &&
        widget.stockname != 'all') {
      _selectedStock = widget.stockname!;
      _displayStockName = totalStocks.containsKey(widget.stockname)
          ? (totalStocks[widget.stockname]?['full_stock_name'] ??
              widget.stockname!)
          : widget.stockname!;
    }

    _fetchAlerts();
    _subscribeToAlerts();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _shimmerController.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    _scrollController.dispose();
    _channel?.unsubscribe();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // MEILISEARCH — inline search
  // ─────────────────────────────────────────────

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce =
        Timer(const Duration(milliseconds: 250), () => _runSearch(query));
  }

  Future<void> _runSearch(String query) async {
    if (!mounted) return;
    setState(() => _isSearchLoading = true);
    try {
      final res = await _meili.index('stocks').search(
            query,
            meili.SearchQuery(
              hitsPerPage: query.isEmpty ? 20 : 35,
              filter: 'type = "stock"',
            ),
          );
      var hits = res.hits.cast<Map<String, dynamic>>();

      // Sort: exact symbol → prefix → rest
      if (query.isNotEmpty) {
        final q = query.toLowerCase();
        hits.sort((a, b) {
          final aS = _cleanSym(a['symbol']).toLowerCase();
          final bS = _cleanSym(b['symbol']).toLowerCase();
          if (aS == q && bS != q) return -1;
          if (bS == q && aS != q) return 1;
          if (aS.startsWith(q) && !bS.startsWith(q)) return -1;
          if (bS.startsWith(q) && !aS.startsWith(q)) return 1;
          return 0;
        });
      }

      if (mounted) {
        setState(() {
          _searchResults = hits;
          _isSearchLoading = false;
        });
      }
    } catch (_) {
      if (mounted)
        setState(() {
          _searchResults = [];
          _isSearchLoading = false;
        });
    }
  }

  /// Clean NSE: prefix and exchange suffixes from symbol
  String _cleanSym(dynamic raw) => (raw ?? '')
      .toString()
      .replaceAll('NSE:', '')
      .replaceAll('-EQ', '')
      .replaceAll('-BE', '')
      .replaceAll('-BZ', '')
      .trim();

  /// Called when user taps a result row
  void _selectStock(Map<String, dynamic> stock) {
    HapticFeedback.selectionClick();
    final sym = _cleanSym(stock['symbol']);
    final name = (stock['name'] ?? sym).toString();
    _searchFocus.unfocus();
    _searchController.clear();
    setState(() {
      _selectedStock = sym;
      _displayStockName = name;
      _isSearchOpen = false;
      _searchResults = [];
      _currentPage = 1;
    });
    _fetchAlerts();
    _subscribeToAlerts();
  }

  /// Close search dropdown without selecting
  void _closeSearch() {
    _searchFocus.unfocus();
    _searchController.clear();
    setState(() {
      _isSearchOpen = false;
      _searchResults = [];
    });
  }

  // ─────────────────────────────────────────────
  // SUPABASE DATA
  // ─────────────────────────────────────────────

  PostgrestFilterBuilder<PostgrestList> _applyFilters(
      PostgrestFilterBuilder<PostgrestList> q) {
    if (_currentFilter == SentimentFilter.bullish)
      q = q.eq('sentiment', 'bullish');
    if (_currentFilter == SentimentFilter.bearish)
      q = q.eq('sentiment', 'bearish');
    if (_selectedStock != 'all') q = q.eq('symbol', _selectedStock);
    if (_selectedDate != null) {
      final s = DateTime(
          _selectedDate!.year, _selectedDate!.month, _selectedDate!.day);
      final e = s
          .add(const Duration(days: 1))
          .subtract(const Duration(milliseconds: 1));
      q = q
          .gte('created_at', s.toIso8601String())
          .lte('created_at', e.toIso8601String());
    }
    return q;
  }

  Future<void> _fetchAlerts() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final from = (_currentPage - 1) * pageSize;
      final to = from + pageSize - 1;
      var q = supabase.from('live_scanner').select();
      q = _applyFilters(q);
      final response =
          await q.order('created_at', ascending: false).range(from, to);
      var cq = supabase.from('live_scanner').select('id');
      cq = _applyFilters(cq);
      final count = (await cq).length;
      final data =
          (response as List).map((e) => AlertModel.fromJson(e)).toList();
      if (mounted)
        setState(() {
          _alerts = data;
          _totalCount = count;
          _isLoading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
    }
  }

  void _subscribeToAlerts() {
    _channel?.unsubscribe();
    final ch = supabase.channel('live_scanner_v3');
    PostgresChangeFilter? filter;
    if (_selectedStock != 'all') {
      filter = PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'symbol',
          value: _selectedStock);
    } else if (_currentFilter != SentimentFilter.all) {
      filter = PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'sentiment',
        value:
            _currentFilter == SentimentFilter.bullish ? 'bullish' : 'bearish',
      );
    }
    ch
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'live_scanner',
          filter: filter,
          callback: (_) {
            if (mounted) _fetchAlerts();
          },
        )
        .subscribe();
    _channel = ch;
  }

  // ─────────────────────────────────────────────
  // FILTER HANDLERS
  // ─────────────────────────────────────────────

  void _handleFilterChange(SentimentFilter f) {
    HapticFeedback.selectionClick();
    setState(() {
      _currentFilter = f;
      _currentPage = 1;
    });
    _fetchAlerts();
    _subscribeToAlerts();
  }

  void _handleClearStock() {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedStock = 'all';
      _displayStockName = '';
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
    HapticFeedback.selectionClick();
    setState(() {
      _currentPage = page;
    });
    _scrollController.animateTo(0,
        duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
    _fetchAlerts();
  }

  // ─────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────

  AppThemeData get _t =>
      Theme.of(context).extension<AppThemeData>() ??
      (Theme.of(context).brightness == Brightness.dark
          ? AppThemeData.dark
          : AppThemeData.light);

  /// Height for the FlexibleSpaceBar background area
  double _getFiltersHeight() {
    double h = 48 + AppTokens.spacingSm; // search field
    if (_selectedStock != 'all' && _displayStockName.isNotEmpty) {
      h += 36 + AppTokens.spacingSm; // active stock chip
    }
    h += 44; // date row
    return h;
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    const sentBarH = 60.0;

    return Scaffold(
      backgroundColor: _t.bg,
      // Stack so the dropdown can float above the list
      body: Stack(
        children: [
          // ── Main scrollable content ──
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                backgroundColor: _t.bg,
                surfaceTintColor: Colors.transparent,
                shadowColor: Colors.transparent,
                pinned: true,
                expandedHeight:
                    kToolbarHeight + _getFiltersHeight() + sentBarH + 8,
                automaticallyImplyLeading: false,
                titleSpacing: 0,
                title: _buildAppBarTitle(),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    color: _t.bg,
                    padding: EdgeInsets.only(
                      top: kToolbarHeight + top,
                      bottom: sentBarH + 8,
                      left: AppTokens.spacingLg,
                      right: AppTokens.spacingLg,
                    ),
                    child: _buildFilters(),
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(sentBarH),
                  child: _buildSentimentBar(),
                ),
              ),
              ..._buildBodySlivers(),
            ],
          ),

          // ── Search dropdown overlay ──
          if (_isSearchOpen) _buildSearchOverlay(top),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // APP BAR TITLE ROW
  // ─────────────────────────────────────────────

  Widget _buildAppBarTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.spacingLg),
      child: Row(
        children: [
          _TapTarget(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _t.surface,
                borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                border: Border.all(color: _t.border),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  size: 15, color: _t.textSecondary),
            ),
          ),
          const SizedBox(width: AppTokens.spacingMd),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    _selectedStock == 'all'
                        ? 'Stock Alerts'
                        : _displayStockName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _t.textPrimary,
                      letterSpacing: -0.4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: AppTokens.spacingSm),
                _LiveBadge(),
              ],
            ),
          ),
          if (!_isLoading && _totalCount > 0) ...[
            const SizedBox(width: AppTokens.spacingSm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _t.surface2,
                borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                border: Border.all(color: _t.border),
              ),
              child: Text(
                '$_totalCount',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _t.textSecondary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // FILTER SECTION
  // ─────────────────────────────────────────────

  Widget _buildFilters() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search field — always visible, drives the dropdown
        _InlineSearchField(
          controller: _searchController,
          focusNode: _searchFocus,
          themeData: _t,
          isActive: _isSearchOpen,
          onChanged: _onSearchChanged,
          onClear: _closeSearch,
        ),

        // Active-stock chip shown when a stock is selected
        if (_selectedStock != 'all' && _displayStockName.isNotEmpty) ...[
          const SizedBox(height: AppTokens.spacingSm),
          _StockChip(
            symbol: _selectedStock,
            label: _displayStockName,
            onDelete: _handleClearStock,
            themeData: _t,
          ),
        ],

        const SizedBox(height: AppTokens.spacingSm),

        // Date filter
        _DateRow(
          selectedDate: _selectedDate,
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
              builder: (ctx, child) => Theme(
                data: Theme.of(ctx).copyWith(
                  colorScheme: Theme.of(ctx).colorScheme.copyWith(
                        primary: AppTokens.neutral,
                        onPrimary: Colors.white,
                      ),
                ),
                child: child!,
              ),
            );
            if (picked != null) _handleDateChange(picked);
          },
          onClear: () => _handleDateChange(null),
          themeData: _t,
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // SENTIMENT BAR
  // ─────────────────────────────────────────────

  Widget _buildSentimentBar() {
    return Container(
      height: 60,
      color: _t.bg,
      padding: const EdgeInsets.fromLTRB(
          AppTokens.spacingLg, 0, AppTokens.spacingLg, AppTokens.spacingMd),
      child: Row(
        children: [
          _SentimentChip(
            label: 'All',
            isSelected: _currentFilter == SentimentFilter.all,
            activeColor: AppTokens.neutral,
            activeDim: AppTokens.neutralDim,
            activeBorder: AppTokens.neutralBorder,
            themeData: _t,
            onTap: () => _handleFilterChange(SentimentFilter.all),
          ),
          const SizedBox(width: AppTokens.spacingSm),
          _SentimentChip(
            label: '▲ Bullish',
            isSelected: _currentFilter == SentimentFilter.bullish,
            activeColor: AppTokens.bullish,
            activeDim: AppTokens.bullishDim,
            activeBorder: AppTokens.bullishBorder,
            themeData: _t,
            onTap: () => _handleFilterChange(SentimentFilter.bullish),
          ),
          const SizedBox(width: AppTokens.spacingSm),
          _SentimentChip(
            label: '▼ Bearish',
            isSelected: _currentFilter == SentimentFilter.bearish,
            activeColor: AppTokens.bearish,
            activeDim: AppTokens.bearishDim,
            activeBorder: AppTokens.bearishBorder,
            themeData: _t,
            onTap: () => _handleFilterChange(SentimentFilter.bearish),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // SEARCH DROPDOWN OVERLAY
  // Floats over the list, anchored just below the search field.
  // ─────────────────────────────────────────────

  Widget _buildSearchOverlay(double statusBarTop) {
    final mediaQuery = MediaQuery.of(context);
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final screenHeight = mediaQuery.size.height;

    // Position = status bar + app bar row height + search field top margin + field height
    final overlayTop = statusBarTop + kToolbarHeight + 58.0;

    // Available height between overlay top and above the keyboard (with some padding)
    final availableHeight = screenHeight - overlayTop - keyboardHeight - 16.0;

    // Clamp: at least 200px visible, at most 55% of screen
    final dropdownMaxHeight = availableHeight.clamp(200.0, screenHeight * 0.55);

    return Positioned(
      top: overlayTop,
      left: AppTokens.spacingLg,
      right: AppTokens.spacingLg,
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The dropdown card — constrained to computed height
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: dropdownMaxHeight),
              child: Container(
                decoration: BoxDecoration(
                  color: _t.surface,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(AppTokens.radiusMd),
                    bottomRight: Radius.circular(AppTokens.radiusMd),
                  ),
                  border:
                      Border.all(color: AppTokens.neutral.withOpacity(0.28)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.20),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(AppTokens.radiusMd),
                    bottomRight: Radius.circular(AppTokens.radiusMd),
                  ),
                  child: _buildDropdownContent(),
                ),
              ),
            ),

            // Backdrop to catch taps and dismiss — only fills remaining space above keyboard
            SizedBox(
              height: (screenHeight -
                      overlayTop -
                      dropdownMaxHeight -
                      keyboardHeight -
                      16.0)
                  .clamp(0.0, double.infinity),
              child: GestureDetector(
                onTap: _closeSearch,
                behavior: HitTestBehavior.opaque,
                child: Container(color: Colors.transparent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownContent() {
    // Loading spinner
    if (_isSearchLoading) {
      return SizedBox(
        height: 160,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppTokens.neutral,
            ),
          ),
        ),
      );
    }

    // Empty / hint state
    if (_searchResults.isEmpty) {
      return SizedBox(
        height: 130,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.manage_search_rounded, size: 30, color: _t.textMuted),
              const SizedBox(height: 8),
              Text(
                _searchController.text.isEmpty
                    ? 'Type a stock name or symbol'
                    : 'No stocks matched',
                style: TextStyle(fontSize: 13, color: _t.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    // Result list
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.spacingXs),
      itemCount: _searchResults.length,
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (_, i) => _buildResultRow(_searchResults[i]),
    );
  }

  Widget _buildResultRow(Map<String, dynamic> stock) {
    final sym = _cleanSym(stock['symbol']);
    final name = (stock['name'] ?? sym).toString();
    final pct = (stock['percent_change'] as num?)?.toDouble();
    final isPos = (pct ?? 0) >= 0;
    final isSelected = sym == _selectedStock;

    return _TapTarget(
      onTap: () => _selectStock(stock),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.spacingLg, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected ? AppTokens.neutralDim : Colors.transparent,
          border: Border(bottom: BorderSide(color: _t.border, width: 0.5)),
        ),
        child: Row(
          children: [
            // Symbol badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              constraints: const BoxConstraints(minWidth: 52),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTokens.neutral.withOpacity(0.12)
                    : _t.surface2,
                borderRadius: BorderRadius.circular(AppTokens.radiusXs),
                border: Border.all(
                    color: isSelected ? AppTokens.neutralBorder : _t.border),
              ),
              child: Text(
                sym,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: isSelected ? AppTokens.neutral : _t.textSecondary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(width: AppTokens.spacingMd),

            // Full name
            Expanded(
              child: Text(
                name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _t.textPrimary,
                ),
              ),
            ),

            // % change badge (if available from Meilisearch)
            if (pct != null) ...[
              const SizedBox(width: AppTokens.spacingMd),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isPos ? AppTokens.bullishDim : AppTokens.bearishDim,
                  borderRadius: BorderRadius.circular(AppTokens.radiusXs),
                ),
                child: Text(
                  '${isPos ? '+' : ''}${pct.toStringAsFixed(2)}%',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isPos ? AppTokens.bullish : AppTokens.bearish,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],

            const SizedBox(width: AppTokens.spacingSm),
            Icon(
              isSelected
                  ? Icons.check_circle_rounded
                  : Icons.chevron_right_rounded,
              size: 16,
              color: isSelected ? AppTokens.neutral : _t.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BODY SLIVERS
  // ─────────────────────────────────────────────

  List<Widget> _buildBodySlivers() {
    if (_isLoading) {
      return [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
              AppTokens.spacingLg, AppTokens.spacingMd, AppTokens.spacingLg, 0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) =>
                  _SkeletonCard(animation: _shimmerController, themeData: _t),
              childCount: 6,
            ),
          ),
        ),
      ];
    }
    if (_error != null) {
      return [
        SliverFillRemaining(child: _ErrorPanel(message: _error!, themeData: _t))
      ];
    }
    if (_alerts.isEmpty) {
      return [
        SliverFillRemaining(
            hasScrollBody: false, child: _EmptyState(themeData: _t))
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
            AppTokens.spacingLg, AppTokens.spacingMd, AppTokens.spacingLg, 0),
        sliver: SliverList.builder(
          itemCount: _alerts.length,
          itemBuilder: (_, i) {
            final prevAlert = (i + 1 < _alerts.length) ? _alerts[i + 1] : null;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppTokens.spacingMd),
              child: AlertItem(
                alert: _alerts[i],
                prevAlert: _selectedStock == 'all' ? null : prevAlert,
                index: i,
              ),
            );
          },
        ),
      ),
      SliverToBoxAdapter(
        child: _PaginationBar(
          currentPage: _currentPage,
          totalCount: _totalCount,
          pageSize: pageSize,
          isLoading: _isLoading,
          onPageChange: _handlePageChange,
          themeData: _t,
        ),
      ),
    ];
  }
}

// ─────────────────────────────────────────────────────────────
// INLINE SEARCH FIELD
// ─────────────────────────────────────────────────────────────

class _InlineSearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final AppThemeData themeData;
  final bool isActive;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _InlineSearchField({
    required this.controller,
    required this.focusNode,
    required this.themeData,
    required this.isActive,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final t = themeData;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 48,
      decoration: BoxDecoration(
        color: t.surface,
        // Open state: only top radius so it connects to the dropdown below
        borderRadius: isActive
            ? const BorderRadius.only(
                topLeft: Radius.circular(AppTokens.radiusMd),
                topRight: Radius.circular(AppTokens.radiusMd),
              )
            : BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(
          color: isActive ? AppTokens.neutral.withOpacity(0.45) : t.border,
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppTokens.neutral.withOpacity(0.07),
                  blurRadius: 10,
                )
              ]
            : [],
      ),
      child: Row(
        children: [
          const SizedBox(width: AppTokens.spacingLg),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Icon(
              Icons.search_rounded,
              key: ValueKey(isActive),
              size: 18,
              color: isActive ? AppTokens.neutral : t.textMuted,
            ),
          ),
          const SizedBox(width: AppTokens.spacingMd),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: t.textPrimary,
              ),
              decoration: InputDecoration(
                hintText:
                    isActive ? 'Type symbol or name…' : 'Filter by stock…',
                hintStyle: TextStyle(
                    fontSize: 13,
                    color: t.textMuted,
                    fontWeight: FontWeight.w400),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              textInputAction: TextInputAction.search,
              onChanged: onChanged,
            ),
          ),
          if (isActive)
            GestureDetector(
              onTap: onClear,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppTokens.spacingMd),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration:
                      BoxDecoration(color: t.surface3, shape: BoxShape.circle),
                  child: Icon(Icons.close_rounded,
                      size: 12, color: t.textSecondary),
                ),
              ),
            )
          else
            const SizedBox(width: AppTokens.spacingMd),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ACTIVE STOCK CHIP
// ─────────────────────────────────────────────────────────────

class _StockChip extends StatelessWidget {
  final String symbol;
  final String label;
  final VoidCallback onDelete;
  final AppThemeData themeData;

  const _StockChip({
    required this.symbol,
    required this.label,
    required this.onDelete,
    required this.themeData,
  });

  @override
  Widget build(BuildContext context) {
    final t = themeData;
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.spacingMd),
      decoration: BoxDecoration(
        color: AppTokens.neutralDim,
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
        border: Border.all(color: AppTokens.neutralBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTokens.neutral.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppTokens.radiusXs),
            ),
            child: Text(
              symbol,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppTokens.neutral,
                letterSpacing: 0.5,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: AppTokens.spacingSm),
          Flexible(
            child: Text(label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: t.textPrimary)),
          ),
          const SizedBox(width: AppTokens.spacingSm),
          GestureDetector(
            onTap: onDelete,
            child: Container(
              width: 18,
              height: 18,
              decoration:
                  BoxDecoration(color: t.surface3, shape: BoxShape.circle),
              child:
                  Icon(Icons.close_rounded, size: 11, color: t.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// DATE ROW
// ─────────────────────────────────────────────────────────────

class _DateRow extends StatelessWidget {
  final DateTime? selectedDate;
  final VoidCallback onTap;
  final VoidCallback onClear;
  final AppThemeData themeData;

  const _DateRow({
    required this.selectedDate,
    required this.onTap,
    required this.onClear,
    required this.themeData,
  });

  @override
  Widget build(BuildContext context) {
    final t = themeData;
    final has = selectedDate != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.spacingLg),
        decoration: BoxDecoration(
          color: has ? AppTokens.neutralDim : t.surface,
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          border: Border.all(color: has ? AppTokens.neutralBorder : t.border),
        ),
        child: Row(children: [
          Icon(Icons.calendar_today_rounded,
              size: 15, color: has ? AppTokens.neutral : t.textMuted),
          const SizedBox(width: AppTokens.spacingMd),
          Expanded(
            child: Text(
              has
                  ? DateFormat('EEE, MMM d, yyyy').format(selectedDate!)
                  : 'Filter by date',
              style: TextStyle(
                fontSize: 13,
                fontWeight: has ? FontWeight.w500 : FontWeight.w400,
                color: has ? AppTokens.neutral : t.textMuted,
              ),
            ),
          ),
          if (has)
            GestureDetector(
              onTap: onClear,
              child:
                  Icon(Icons.close_rounded, size: 16, color: t.textSecondary),
            )
          else
            Icon(Icons.chevron_right_rounded, size: 16, color: t.textMuted),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SENTIMENT CHIP
// ─────────────────────────────────────────────────────────────

class _SentimentChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color activeColor;
  final Color activeDim;
  final Color activeBorder;
  final AppThemeData themeData;
  final VoidCallback onTap;

  const _SentimentChip({
    required this.label,
    required this.isSelected,
    required this.activeColor,
    required this.activeDim,
    required this.activeBorder,
    required this.themeData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = themeData;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 36,
          decoration: BoxDecoration(
            color: isSelected ? activeDim : t.surface,
            borderRadius: BorderRadius.circular(AppTokens.radiusSm),
            border: Border.all(
                color: isSelected ? activeBorder : t.border,
                width: isSelected ? 1.5 : 1),
          ),
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? activeColor : t.textSecondary,
              ),
              child: Text(label),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TAP TARGET (scale-press)
// ─────────────────────────────────────────────────────────────

class _TapTarget extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _TapTarget({required this.child, required this.onTap});

  @override
  State<_TapTarget> createState() => _TapTargetState();
}

class _TapTargetState extends State<_TapTarget> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 110),
        child: widget.child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// LIVE BADGE
// ─────────────────────────────────────────────────────────────

class _LiveBadge extends StatefulWidget {
  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _a = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppTokens.bullishDim,
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
        border: Border.all(color: AppTokens.bullishBorder),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        AnimatedBuilder(
          animation: _a,
          builder: (_, __) => Opacity(
            opacity: _a.value,
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                  color: AppTokens.bullish, shape: BoxShape.circle),
            ),
          ),
        ),
        const SizedBox(width: 4),
        const Text('LIVE',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppTokens.bullish,
              letterSpacing: 0.8,
            )),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SKELETON CARD
// ─────────────────────────────────────────────────────────────

class _SkeletonCard extends StatelessWidget {
  final AnimationController animation;
  final AppThemeData themeData;
  const _SkeletonCard({required this.animation, required this.themeData});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        final v = (animation.value * 2 - 1).abs();
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final base = isDark ? const Color(0xFF1A1F2B) : const Color(0xFFE8ECF5);
        final hi = isDark ? const Color(0xFF242A38) : const Color(0xFFF5F7FD);
        final c = Color.lerp(base, hi, v)!;

        Widget bone(double h, double? w, {double r = 6}) => Container(
              height: h,
              width: w,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                  color: c, borderRadius: BorderRadius.circular(r)),
            );

        return Container(
          margin: const EdgeInsets.only(bottom: AppTokens.spacingMd),
          padding: const EdgeInsets.all(AppTokens.spacingLg),
          decoration: BoxDecoration(
            color: themeData.surface,
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            border: Border.all(color: themeData.border),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              bone(14, 60, r: AppTokens.radiusPill),
              const Spacer(),
              bone(14, 40, r: AppTokens.radiusPill),
            ]),
            const SizedBox(height: 4),
            bone(18, double.infinity),
            bone(14, 220),
            const SizedBox(height: 4),
            Row(children: [
              bone(10, 80),
              const SizedBox(width: 8),
              bone(10, 60),
              const SizedBox(width: 8),
              bone(10, 70),
            ]),
          ]),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ERROR PANEL
// ─────────────────────────────────────────────────────────────

class _ErrorPanel extends StatelessWidget {
  final String message;
  final AppThemeData themeData;
  const _ErrorPanel({required this.message, required this.themeData});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacingXxl),
        child: Container(
          padding: const EdgeInsets.all(AppTokens.spacingXl),
          decoration: BoxDecoration(
            color: AppTokens.bearishDim,
            borderRadius: BorderRadius.circular(AppTokens.radiusLg),
            border: Border.all(color: AppTokens.bearishBorder),
          ),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Icon(Icons.error_outline_rounded,
                      color: AppTokens.bearish, size: 20),
                  SizedBox(width: AppTokens.spacingSm),
                  Text('Connection Error',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppTokens.bearish)),
                ]),
                const SizedBox(height: AppTokens.spacingSm),
                Text(message,
                    style: TextStyle(
                        fontSize: 13, color: themeData.textSecondary)),
              ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final AppThemeData themeData;
  const _EmptyState({required this.themeData});

  @override
  Widget build(BuildContext context) {
    final t = themeData;
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: t.surface2,
            shape: BoxShape.circle,
            border: Border.all(color: t.border),
          ),
          child: Icon(Icons.radar_rounded, size: 32, color: t.textMuted),
        ),
        const SizedBox(height: AppTokens.spacingLg),
        Text('No signals found',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: t.textPrimary,
                letterSpacing: -0.3)),
        const SizedBox(height: AppTokens.spacingSm),
        Text(
          'Adjust your filters or\ncheck back during market hours.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: t.textSecondary, height: 1.5),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PAGINATION BAR
// ─────────────────────────────────────────────────────────────

class _PaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalCount;
  final int pageSize;
  final bool isLoading;
  final ValueChanged<int> onPageChange;
  final AppThemeData themeData;

  const _PaginationBar({
    required this.currentPage,
    required this.totalCount,
    required this.pageSize,
    required this.isLoading,
    required this.onPageChange,
    required this.themeData,
  });

  @override
  Widget build(BuildContext context) {
    final t = themeData;
    final totalPages = (totalCount / pageSize).ceil().clamp(1, 9999);
    final canPrev = currentPage > 1 && !isLoading;
    final canNext = currentPage < totalPages && !isLoading;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTokens.spacingLg,
          AppTokens.spacingMd, AppTokens.spacingLg, AppTokens.spacingXxl),
      child: Row(children: [
        _PageBtn(
            icon: Icons.chevron_left_rounded,
            enabled: canPrev,
            onTap: () => onPageChange(currentPage - 1),
            t: t),
        const Spacer(),
        Column(children: [
          Text('Page $currentPage of $totalPages',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: t.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()])),
          const SizedBox(height: 2),
          Text('$totalCount total signals',
              style: TextStyle(fontSize: 11, color: t.textMuted)),
        ]),
        const Spacer(),
        _PageBtn(
            icon: Icons.chevron_right_rounded,
            enabled: canNext,
            onTap: () => onPageChange(currentPage + 1),
            t: t),
      ]),
    );
  }
}

class _PageBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  final AppThemeData t;
  const _PageBtn(
      {required this.icon,
      required this.enabled,
      required this.onTap,
      required this.t});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.35,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(AppTokens.radiusSm),
            border: Border.all(color: t.border),
          ),
          child: Icon(icon, size: 20, color: t.textSecondary),
        ),
      ),
    );
  }
}
