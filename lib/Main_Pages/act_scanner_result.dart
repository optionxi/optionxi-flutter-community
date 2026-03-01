import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:optionxi/Components/custom_loading_screener_result.dart';
import 'package:optionxi/Helpers/constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Screener {
  final String id;
  final String name;
  final String category;
  final String timeframe;
  final DateTime createdAt;

  Screener({
    required this.id,
    required this.name,
    required this.category,
    required this.timeframe,
    required this.createdAt,
  });

  factory Screener.fromJson(Map<String, dynamic> json) {
    return Screener(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      timeframe: json['timeframe'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class DataStockModel {
  final String stckname;
  final double close;
  final double pclose;
  final double high;
  final double low;
  final double open;
  final double pcnt;
  final String sec;
  final int vol;

  DataStockModel({
    required this.stckname,
    required this.close,
    required this.pclose,
    required this.high,
    required this.low,
    required this.open,
    required this.pcnt,
    required this.sec,
    required this.vol,
  });

  factory DataStockModel.fromJson(Map<String, dynamic> json) {
    return DataStockModel(
      stckname: json['stckname'] ?? '',
      close: (json['close'] ?? 0).toDouble(),
      pclose: (json['close'] ?? 0) / (1 + (json['pcnt'] ?? 0) / 100),
      high: (json['high'] ?? 0).toDouble(),
      low: (json['low'] ?? 0).toDouble(),
      open: (json['open'] ?? 0).toDouble(),
      pcnt: (json['pcnt'] ?? 0).toDouble(),
      sec: json['sec'] ?? '',
      vol: (json['vol'] ?? 0),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Design tokens
// ─────────────────────────────────────────────────────────────────────────────
class _AppColors {
  // Bullish palette
  static const bullishPrimary = Color(0xFF00C896);
  static const bullishLight = Color(0xFFE6FAF5);

  // Bearish palette
  static const bearishPrimary = Color(0xFFFF4D6D);
  static const bearishLight = Color(0xFFFFEBEE);

  // Neutrals
  static const surface = Color(0xFFF8F9FB);
  static const surfaceDark = Color(0xFF0F1117);
  static const cardLight = Color(0xFFFFFFFF);
  static const cardDark = Color(0xFF1A1D27);
  static const borderLight = Color(0xFFE8ECF0);
  static const borderDark = Color(0xFF272B3A);
  static const textPrimaryLight = Color(0xFF0D1117);
  static const textPrimaryDark = Color(0xFFF0F2F5);
  static const textSecondaryLight = Color(0xFF6B7280);
  static const textSecondaryDark = Color(0xFF8B92A5);
}

// ─────────────────────────────────────────────────────────────────────────────
// Main Page
// ─────────────────────────────────────────────────────────────────────────────
class ScannerDetailPage extends StatefulWidget {
  final String scanName;
  final String? category;

  const ScannerDetailPage({
    Key? key,
    required this.scanName,
    this.category,
  }) : super(key: key);

  @override
  State<ScannerDetailPage> createState() => _ScannerDetailPageState();
}

class _ScannerDetailPageState extends State<ScannerDetailPage>
    with SingleTickerProviderStateMixin {
  final SupabaseClient _supabase = Supabase.instance.client;
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _chipScrollController = ScrollController();

  String _selectedCategory = 'bullish';
  List<Screener> _screeners = [];
  String _selectedScreenerId = '';
  bool _isLoadingScreeners = true;

  List<DataStockModel> _stocks = [];
  bool _isLoadingStocks = true;
  String _search = '';
  int _currentPage = 1;
  int _totalStocks = 0;
  final int _pageSize = 20;
  String _sortOrder = 'desc';

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.category ?? 'bullish';
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: _selectedCategory == 'bullish' ? 0 : 1,
    );
    _loadScreeners();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _chipScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadScreeners() async {
    if (!mounted) return;
    setState(() => _isLoadingScreeners = true);

    try {
      final response = await _supabase
          .from('screener_names')
          .select()
          .eq('category', _selectedCategory)
          .order('timeframe', ascending: true)
          .order('created_at', ascending: false);

      final fetchedScreeners =
          (response as List).map((item) => Screener.fromJson(item)).toList();

      if (mounted) {
        setState(() {
          _screeners = fetchedScreeners;
          final match = fetchedScreeners.firstWhere(
            (s) => s.name.toLowerCase().replaceAll(' ', '-') == widget.scanName,
            orElse: () => fetchedScreeners.isNotEmpty
                ? fetchedScreeners.first
                : Screener(
                    id: '',
                    name: '',
                    category: '',
                    timeframe: '',
                    createdAt: DateTime.now()),
          );
          _selectedScreenerId =
              match.id.isNotEmpty && fetchedScreeners.isNotEmpty
                  ? match.id
                  : fetchedScreeners.isNotEmpty
                      ? fetchedScreeners.first.id
                      : '';
        });
      }
    } catch (e) {
      debugPrint('Error fetching screeners: $e');
      if (mounted) setState(() => _screeners = []);
    } finally {
      if (mounted) setState(() => _isLoadingScreeners = false);
      if (_selectedScreenerId.isNotEmpty && mounted) _loadScreenerResults();
    }
  }

  Future<void> _loadScreenerResults() async {
    if (_selectedScreenerId.isEmpty || !mounted) return;
    if (mounted) setState(() => _isLoadingStocks = true);

    try {
      final countQuery = _supabase
          .from('screener_results')
          .select()
          .eq('screener_id', _selectedScreenerId);

      final countWithSearch = _search.trim().isNotEmpty
          ? countQuery.ilike('stckname', '%${_search.trim().toUpperCase()}%')
          : countQuery;

      final countResponse = await countWithSearch;
      if (!mounted) return;
      final totalCount = (countResponse as List).length;

      final dataQuery = _supabase
          .from('screener_results')
          .select()
          .eq('screener_id', _selectedScreenerId);

      final dataWithSearch = _search.trim().isNotEmpty
          ? dataQuery.ilike('stckname', '%${_search.trim().toUpperCase()}%')
          : dataQuery;

      final startIndex = (_currentPage - 1) * _pageSize;
      final response = await dataWithSearch
          .order('pcnt', ascending: _sortOrder == 'asc')
          .range(startIndex, startIndex + _pageSize - 1);

      if (!mounted) return;
      final transformed = (response as List)
          .map((item) => DataStockModel.fromJson(item))
          .toList();

      if (mounted) {
        setState(() {
          _stocks = transformed;
          _totalStocks = totalCount;
        });
      }
    } catch (e) {
      debugPrint('Error fetching results: $e');
      if (mounted)
        setState(() {
          _stocks = [];
          _totalStocks = 0;
        });
    } finally {
      if (mounted) setState(() => _isLoadingStocks = false);
    }
  }

  void _handleCategoryChange(String value) {
    if (!mounted) return;
    setState(() {
      _selectedCategory = value;
      _currentPage = 1;
      _search = '';
      _searchController.clear();
    });
    _loadScreeners();
  }

  void _handleScreenerChange(Screener screener) {
    if (!mounted) return;
    setState(() {
      _selectedScreenerId = screener.id;
      _currentPage = 1;
    });
    _loadScreenerResults();
  }

  void _handleSearch(String value) {
    setState(() {
      _search = value;
      _currentPage = 1;
    });
    _loadScreenerResults();
  }

  void _handlePageChange(int newPage) {
    setState(() => _currentPage = newPage);
    _loadScreenerResults();
  }

  void _handleSortToggle() {
    setState(() {
      _sortOrder = _sortOrder == 'desc' ? 'asc' : 'desc';
      _currentPage = 1;
    });
    _loadScreenerResults();
  }

  void _showStockDetails(DataStockModel stock) {
    Get.toNamed('/stocks/${stock.stckname.toUpperCase()}');
  }

  bool get _isBullish => _selectedCategory == 'bullish';

  Color get _accentColor =>
      _isBullish ? _AppColors.bullishPrimary : _AppColors.bearishPrimary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final totalPages = (_totalStocks / _pageSize).ceil();
    final filteredScreeners =
        _screeners.where((s) => s.category == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: isDark ? _AppColors.surfaceDark : _AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark),
            _buildTabBar(isDark),
            _buildScreenerChips(filteredScreeners, isDark),
            _buildSearchBar(isDark),
            _buildResultsHeader(isDark),
            Expanded(
              child: _isLoadingStocks
                  ? const Center(child: StockListSkeleton())
                  : _stocks.isEmpty
                      ? _buildEmptyState(isDark)
                      : _buildStockList(isDark),
            ),
            if (!_isLoadingStocks && _stocks.isNotEmpty && totalPages > 1)
              _buildPagination(totalPages, isDark),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: isDark
                  ? _AppColors.textPrimaryDark
                  : _AppColors.textPrimaryLight,
            ),
            onPressed: () => Get.back(),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              'Stock Screeners',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: isDark
                    ? _AppColors.textPrimaryDark
                    : _AppColors.textPrimaryLight,
              ),
            ),
          ),
          // Live badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _accentColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'LIVE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: _accentColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab Bar ────────────────────────────────────────────────────────────────
  Widget _buildTabBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? _AppColors.cardDark : _AppColors.borderLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        onTap: (i) => _handleCategoryChange(i == 0 ? 'bullish' : 'bearish'),
        indicator: BoxDecoration(
          color: _accentColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: _accentColor.withOpacity(0.35),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelPadding: EdgeInsets.zero,
        tabs: [
          _buildTab('Bullish', Icons.trending_up_rounded, 0),
          _buildTab('Bearish', Icons.trending_down_rounded, 1),
        ],
      ),
    );
  }

  Widget _buildTab(String label, IconData icon, int index) {
    final isSelected = _tabController.index == index;
    // We re-render on tab change via setState so color reacts
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected
                ? Colors.white
                : (Theme.of(context).brightness == Brightness.dark
                    ? _AppColors.textSecondaryDark
                    : _AppColors.textSecondaryLight),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? Colors.white
                  : (Theme.of(context).brightness == Brightness.dark
                      ? _AppColors.textSecondaryDark
                      : _AppColors.textSecondaryLight),
            ),
          ),
        ],
      ),
    );
  }

  // ── Screener Chips ─────────────────────────────────────────────────────────
  Widget _buildScreenerChips(List<Screener> screeners, bool isDark) {
    return Container(
      height: 52,
      margin: const EdgeInsets.only(top: 12),
      child: _isLoadingScreeners
          ? Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _accentColor,
                ),
              ),
            )
          : screeners.isEmpty
              ? const SizedBox.shrink()
              : ListView.separated(
                  controller: _chipScrollController,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: screeners.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final screener = screeners[index];
                    final isSelected = _selectedScreenerId == screener.id;
                    return _buildScreenerChip(screener, isSelected, isDark);
                  },
                ),
    );
  }

  Widget _buildScreenerChip(Screener screener, bool isSelected, bool isDark) {
    final timeframeIcon = screener.timeframe == 'daily'
        ? Icons.calendar_today_rounded
        : screener.timeframe == 'weekly'
            ? Icons.calendar_month_rounded
            : null;

    return GestureDetector(
      onTap: () => _handleScreenerChange(screener),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? _accentColor
              : isDark
                  ? _AppColors.cardDark
                  : _AppColors.cardLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? _accentColor
                : isDark
                    ? _AppColors.borderDark
                    : _AppColors.borderLight,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _accentColor.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              screener.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : isDark
                        ? _AppColors.textSecondaryDark
                        : _AppColors.textSecondaryLight,
              ),
            ),
            if (timeframeIcon != null) ...[
              const SizedBox(width: 5),
              Icon(
                timeframeIcon,
                size: 13,
                color: isSelected
                    ? Colors.white.withOpacity(0.8)
                    : isDark
                        ? _AppColors.textSecondaryDark
                        : _AppColors.textSecondaryLight,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Search Bar ─────────────────────────────────────────────────────────────
  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: isDark ? _AppColors.cardDark : _AppColors.cardLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      isDark ? _AppColors.borderDark : _AppColors.borderLight,
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _handleSearch,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? _AppColors.textPrimaryDark
                      : _AppColors.textPrimaryLight,
                ),
                decoration: InputDecoration(
                  hintText: 'Search by symbol…',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? _AppColors.textSecondaryDark
                        : _AppColors.textSecondaryLight,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: isDark
                        ? _AppColors.textSecondaryDark
                        : _AppColors.textSecondaryLight,
                  ),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: isDark
                                ? _AppColors.textSecondaryDark
                                : _AppColors.textSecondaryLight,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            _handleSearch('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Sort button
          GestureDetector(
            onTap: _handleSortToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _sortOrder == 'desc'
                    ? _accentColor.withOpacity(0.12)
                    : isDark
                        ? _AppColors.cardDark
                        : _AppColors.cardLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _sortOrder == 'desc'
                      ? _accentColor.withOpacity(0.4)
                      : isDark
                          ? _AppColors.borderDark
                          : _AppColors.borderLight,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    _sortOrder == 'desc'
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded,
                    size: 20,
                    color: _sortOrder == 'desc'
                        ? _accentColor
                        : isDark
                            ? _AppColors.textSecondaryDark
                            : _AppColors.textSecondaryLight,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Results Header ─────────────────────────────────────────────────────────
  Widget _buildResultsHeader(bool isDark) {
    if (_isLoadingStocks) return const SizedBox(height: 12);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          Text(
            '$_totalStocks Results',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? _AppColors.textSecondaryDark
                  : _AppColors.textSecondaryLight,
            ),
          ),
          const Spacer(),
          Text(
            'Sorted by % ${_sortOrder == 'desc' ? '↓' : '↑'}',
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? _AppColors.textSecondaryDark
                  : _AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty State ────────────────────────────────────────────────────────────
  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: isDark ? _AppColors.cardDark : _AppColors.borderLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 36,
              color: isDark
                  ? _AppColors.textSecondaryDark
                  : _AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No stocks found',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? _AppColors.textPrimaryDark
                  : _AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try adjusting your filters or search term',
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? _AppColors.textSecondaryDark
                  : _AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  // ── Stock List ─────────────────────────────────────────────────────────────
  Widget _buildStockList(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      itemCount: _stocks.length,
      itemBuilder: (context, index) => _buildStockCard(_stocks[index], isDark),
    );
  }

  Widget _buildStockCard(DataStockModel stock, bool isDark) {
    final parts = stock.stckname.split(':');
    final stockSymbol =
        parts.length > 1 ? parts[1].split('-')[0] : stock.stckname;
    final exchange = parts[0];
    final isPositive = stock.pcnt >= 0;

    final gainColor =
        isPositive ? _AppColors.bullishPrimary : _AppColors.bearishPrimary;
    final gainBg = isPositive
        ? (isDark
            ? _AppColors.bullishPrimary.withOpacity(0.12)
            : _AppColors.bullishLight)
        : (isDark
            ? _AppColors.bearishPrimary.withOpacity(0.12)
            : _AppColors.bearishLight);

    final priceChange = stock.close - stock.pclose;

    return GestureDetector(
      onTap: () => _showStockDetails(stock),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isDark ? _AppColors.cardDark : _AppColors.cardLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? _AppColors.borderDark : _AppColors.borderLight,
          ),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Stock logo
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isDark ? _AppColors.borderDark : _AppColors.surface,
                ),
                clipBehavior: Clip.antiAlias,
                child: CachedNetworkImage(
                  imageUrl: Constants.OptionXiS3Loc + stockSymbol + ".png",
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Center(
                    child: Text(
                      stockSymbol.isNotEmpty ? stockSymbol[0] : 'S',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _accentColor,
                      ),
                    ),
                  ),
                  errorWidget: (_, __, ___) => ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/stockdefault.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Symbol + exchange
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stockSymbol,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                        color: isDark
                            ? _AppColors.textPrimaryDark
                            : _AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      exchange,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? _AppColors.textSecondaryDark
                            : _AppColors.textSecondaryLight,
                      ),
                    ),
                    // Sector tag
                    if (stock.sec.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark
                              ? _AppColors.borderDark
                              : _AppColors.surface,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          stock.sec,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? _AppColors.textSecondaryDark
                                : _AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Price + badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${stock.close.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? _AppColors.textPrimaryDark
                          : _AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${isPositive ? '+' : ''}${priceChange.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? _AppColors.textSecondaryDark
                          : _AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: gainBg,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPositive
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          size: 12,
                          color: gainColor,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${stock.pcnt.abs().toStringAsFixed(2)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: gainColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Pagination ─────────────────────────────────────────────────────────────
  Widget _buildPagination(int totalPages, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildPageButton(
            icon: Icons.chevron_left_rounded,
            enabled: _currentPage > 1,
            onTap: () => _handlePageChange(_currentPage - 1),
            isDark: isDark,
          ),
          const SizedBox(width: 12),
          // Page pills
          ..._buildPageNumbers(totalPages, isDark),
          const SizedBox(width: 12),
          _buildPageButton(
            icon: Icons.chevron_right_rounded,
            enabled: _currentPage < totalPages,
            onTap: () => _handlePageChange(_currentPage + 1),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPageNumbers(int totalPages, bool isDark) {
    final pages = <Widget>[];
    final showPages = <int>[];

    if (totalPages <= 5) {
      for (var i = 1; i <= totalPages; i++) showPages.add(i);
    } else {
      showPages.add(1);
      if (_currentPage > 3) showPages.add(-1); // ellipsis
      for (var i = (_currentPage - 1).clamp(2, totalPages - 1);
          i <= (_currentPage + 1).clamp(2, totalPages - 1);
          i++) {
        showPages.add(i);
      }
      if (_currentPage < totalPages - 2) showPages.add(-1);
      showPages.add(totalPages);
    }

    for (final p in showPages) {
      if (p == -1) {
        pages.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text('…',
              style: TextStyle(
                  color: isDark
                      ? _AppColors.textSecondaryDark
                      : _AppColors.textSecondaryLight)),
        ));
      } else {
        final isCurrent = p == _currentPage;
        pages.add(GestureDetector(
          onTap: () => _handlePageChange(p),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 36,
            height: 36,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: isCurrent
                  ? _accentColor
                  : isDark
                      ? _AppColors.cardDark
                      : _AppColors.cardLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isCurrent
                    ? _accentColor
                    : isDark
                        ? _AppColors.borderDark
                        : _AppColors.borderLight,
              ),
            ),
            child: Center(
              child: Text(
                '$p',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isCurrent
                      ? Colors.white
                      : isDark
                          ? _AppColors.textSecondaryDark
                          : _AppColors.textSecondaryLight,
                ),
              ),
            ),
          ),
        ));
      }
    }
    return pages;
  }

  Widget _buildPageButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled
              ? isDark
                  ? _AppColors.cardDark
                  : _AppColors.cardLight
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled
                ? isDark
                    ? _AppColors.borderDark
                    : _AppColors.borderLight
                : Colors.transparent,
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled
              ? isDark
                  ? _AppColors.textPrimaryDark
                  : _AppColors.textPrimaryLight
              : (isDark
                  ? _AppColors.textSecondaryDark
                  : _AppColors.textSecondaryLight),
        ),
      ),
    );
  }
}
