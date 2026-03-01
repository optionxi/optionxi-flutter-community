import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:meilisearch/meilisearch.dart' as meili;
import 'package:optionxi/DataModels/dm_watchlist_stock.dart';
import 'package:optionxi/DB_Services/database_read.dart';
import 'package:optionxi/DB_Services/database_write.dart';
import 'package:optionxi/Helpers/constants.dart';
import 'package:optionxi/Main_Pages/act_set_alert.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────
//  Theme tokens — adaptive dark / light
// ─────────────────────────────────────────────────────────────
class _T {
  static Color surface(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? const Color(0xFF0F1117)
          : const Color(0xFFF5F6FA);

  static Color card(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? const Color(0xFF181C27)
          : Colors.white;

  static Color cardAlt(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? const Color(0xFF1E2333)
          : const Color(0xFFF0F2F8);

  static Color border(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? const Color(0xFF252B3D)
          : const Color(0xFFE4E7F0);

  static Color textPrimary(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? const Color(0xFFF0F2FF)
          : const Color(0xFF141622);

  static Color textSecondary(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? const Color(0xFF7B85A3)
          : const Color(0xFF6B7490);

  static Color textMuted(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? const Color(0xFF3D4460)
          : const Color(0xFFB0B7CC);

  static const accent = Color(0xFF3B72F6);
  static const bull = Color(0xFF00C896);
  static const bear = Color(0xFFEF4565);

  static Color bullBg(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? const Color(0x1400C896)
          : const Color(0xFFE6FBF5);

  static Color bearBg(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark
          ? const Color(0x14EF4565)
          : const Color(0xFFFEECEF);
}

// ─────────────────────────────────────────────────────────────
//  Combined Stock Search Page
// ─────────────────────────────────────────────────────────────
class AllSearchPageMeili extends StatefulWidget {
  const AllSearchPageMeili({Key? key}) : super(key: key);

  @override
  State<AllSearchPageMeili> createState() => _AllSearchPageMeiliState();
}

class _AllSearchPageMeiliState extends State<AllSearchPageMeili>
    with SingleTickerProviderStateMixin {
  // Services
  late meili.MeiliSearchClient _client;
  final DatabaseReadService _dbReadService = DatabaseReadService();
  final DatabaseWriteService _dbWriteService = DatabaseWriteService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Controllers
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  late AnimationController _shimmerController;

  // State
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _trendingStocks = [];
  List<String> _recentSearches = [];
  Set<String> _favoriteStocks = {};

  bool _isLoading = false;
  bool _isLoadingTrending = false;
  bool _isFocused = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _searchFocus.addListener(() {
      setState(() => _isFocused = _searchFocus.hasFocus);
    });

    _initMeili();
    _loadRecent();
    _loadFavorites();
    _loadTrending();
  }

  void _initMeili() {
    _client = meili.MeiliSearchClient(
      dotenv.env['MELIESEARCH_URL']!,
      dotenv.env['MELIE_API_KEY']!,
    );
  }

  // ── Data Loading ──────────────────────────────
  Future<void> _loadRecent() async {
    final prefs = await SharedPreferences.getInstance();
    setState(
        () => _recentSearches = prefs.getStringList('recent_searches') ?? []);
  }

  Future<void> _saveRecent(String symbol) async {
    if (symbol.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('recent_searches') ?? [];
    list.remove(symbol);
    list.insert(0, symbol);
    final trimmed = list.take(6).toList();
    await prefs.setStringList('recent_searches', trimmed);
    setState(() => _recentSearches = trimmed);
  }

  Future<void> _removeRecent(String symbol) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('recent_searches') ?? [];
    list.remove(symbol);
    await prefs.setStringList('recent_searches', list);
    setState(() => _recentSearches = list);
  }

  Future<void> _clearRecent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recent_searches');
    setState(() => _recentSearches = []);
  }

  Future<void> _loadFavorites() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final favs = await _dbReadService.getFavoriteStocks(user.uid);
      setState(() => _favoriteStocks = favs.map((s) => s.stockName).toSet());
    } catch (_) {}
  }

  Future<void> _loadTrending() async {
    setState(() => _isLoadingTrending = true);
    try {
      final res = await _client.index('stocks').search(
            '',
            meili.SearchQuery(
              hitsPerPage: 15,
              sort: ['percent_change:desc'],
              filter:
                  'percent_change > 0 AND type = "stock" AND volume > 1000000',
            ),
          );
      setState(() {
        _trendingStocks = res.hits.cast<Map<String, dynamic>>();
        _isLoadingTrending = false;
      });
    } catch (_) {
      setState(() => _isLoadingTrending = false);
    }
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _error = null;
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await _client.index('stocks').search(
          query,
          meili.SearchQuery(
            filter: 'type = "stock"',
          ));
      final hits = res.hits.cast<Map<String, dynamic>>();

      // Client-side relevance sort
      final q = query.toLowerCase();
      hits.sort((a, b) {
        final aName = _sym(a).toLowerCase();
        final bName = _sym(b).toLowerCase();
        if (aName == q && bName != q) return -1;
        if (bName == q && aName != q) return 1;
        if (aName.startsWith(q) && !bName.startsWith(q)) return -1;
        if (bName.startsWith(q) && !aName.startsWith(q)) return 1;
        return 0;
      });

      setState(() {
        _searchResults = hits;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Search failed. Check your connection.';
        _isLoading = false;
        _searchResults = [];
      });
    }
  }

  // ── Watchlist ─────────────────────────────────
  bool _isFav(Map<String, dynamic> stock) =>
      _favoriteStocks.contains(stock['symbol'] ?? '');

  Future<void> _toggleFav(Map<String, dynamic> stock) async {
    final user = _auth.currentUser;
    if (user == null) {
      _snack('Sign in to manage your watchlist', isError: true);
      return;
    }
    final symbol = stock['symbol'] ?? '';
    final fullName = stock['name'] ?? '';
    final added = !_favoriteStocks.contains(symbol);

    setState(() {
      if (added) {
        _favoriteStocks.add(symbol);
      } else {
        _favoriteStocks.remove(symbol);
      }
    });

    _snack(added ? 'Added to watchlist' : 'Removed from watchlist');

    try {
      final dm = dm_stock(stockName: symbol, fullStockName: fullName);
      await _dbWriteService.toggleFavorite(user.uid, dm);
    } catch (_) {
      // Rollback
      setState(() {
        if (added) {
          _favoriteStocks.remove(symbol);
        } else {
          _favoriteStocks.add(symbol);
        }
      });
      _snack('Something went wrong. Please try again.', isError: true);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    final ctx = context;
    ScaffoldMessenger.of(ctx).clearSnackBars();
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: isError ? _T.bear : const Color(0xFF1A1F2E),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(milliseconds: 1800),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────
  String _sym(Map<String, dynamic> stock) => (stock['symbol'] ?? '')
      .toString()
      .replaceAll('NSE:', '')
      .replaceAll('-EQ', '')
      .replaceAll('-BE', '')
      .replaceAll('-BZ', '')
      .trim();

  String _formatVol(dynamic volume) {
    if (volume == null) return '–';
    final num v = volume is num ? volume : 0;
    if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(1)}Cr';
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  //  Build
  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Theme.of(context).brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _T.surface(context),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchBar(),
              const SizedBox(height: 8),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _T.card(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _T.border(context)),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 15,
                color: _T.textPrimary(context),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Market Search',
            style: TextStyle(
              color: _T.textPrimary(context),
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          const Spacer(),
          _LivePill(),
        ],
      ),
    );
  }

  // ── Search Bar ────────────────────────────────
  Widget _buildSearchBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      decoration: BoxDecoration(
        color: _T.card(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isFocused ? _T.accent.withOpacity(0.5) : _T.border(context),
          width: 1.5,
        ),
        boxShadow: _isFocused
            ? [BoxShadow(color: _T.accent.withOpacity(0.1), blurRadius: 16)]
            : [],
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocus,
        style: TextStyle(
          color: _T.textPrimary(context),
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'Search stocks like HDFC, RELIANCE',
          hintStyle: TextStyle(color: _T.textMuted(context), fontSize: 14),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 14, right: 10),
            child: Icon(
              Icons.search_rounded,
              color: _isFocused ? _T.accent : _T.textSecondary(context),
              size: 20,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 46),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded,
                      size: 17, color: _T.textSecondary(context)),
                  onPressed: () {
                    _searchController.clear();
                    _search('');
                    setState(() {});
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 0, vertical: 14),
        ),
        onChanged: (v) {
          setState(() {});
          _search(v);
        },
      ),
    );
  }

  // ── Body Router ───────────────────────────────
  Widget _buildBody() {
    if (_isLoading) return _buildShimmer();
    if (_error != null) return _buildError();
    if (_searchController.text.isNotEmpty) return _buildResults(_searchResults);
    return _buildHome();
  }

  // ── Shimmer ───────────────────────────────────
  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      itemCount: 7,
      itemBuilder: (_, i) => _ShimmerTile(
        controller: _shimmerController,
        ctx: context,
      ),
    );
  }

  // ── Error ─────────────────────────────────────
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded,
                color: _T.textMuted(context), size: 38),
            const SizedBox(height: 14),
            Text(
              'Connection error',
              style: TextStyle(
                color: _T.textPrimary(context),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _error!,
              style: TextStyle(color: _T.textSecondary(context), fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => _search(_searchController.text),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: _T.accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Search Results ────────────────────────────
  Widget _buildResults(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                color: _T.textMuted(context), size: 38),
            const SizedBox(height: 12),
            Text(
              'No results found',
              style: TextStyle(
                color: _T.textPrimary(context),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try a different symbol or name',
              style: TextStyle(color: _T.textSecondary(context), fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: items.length,
      itemBuilder: (_, i) => _buildTile(items[i]),
    );
  }

  // ── Home Feed ─────────────────────────────────
  Widget _buildHome() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Recent searches
        if (_recentSearches.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _SectionLabel(
              label: 'Recent',
              trailing: GestureDetector(
                onTap: _clearRecent,
                child: Text(
                  'Clear',
                  style: TextStyle(
                    color: _T.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(child: _buildRecentChips()),
        ],

        // Trending
        SliverToBoxAdapter(
          child: _SectionLabel(
            label: 'Trending',
            topPad: _recentSearches.isNotEmpty ? 24 : 16,
          ),
        ),

        if (_isLoadingTrending)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _ShimmerTile(
                controller: _shimmerController,
                ctx: context,
              ),
              childCount: 6,
            ),
          )
        else if (_trendingStocks.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'No trending stocks right now',
                  style: TextStyle(color: _T.textMuted(context), fontSize: 13),
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _buildTile(_trendingStocks[i]),
                childCount: _trendingStocks.length,
              ),
            ),
          ),
      ],
    );
  }

  // ── Recent Chips ──────────────────────────────
  Widget _buildRecentChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _recentSearches.map((s) {
          return GestureDetector(
            onTap: () {
              _searchController.text = s;
              setState(() {});
              _search(s);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: _T.card(context),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _T.border(context)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history_rounded,
                      size: 13, color: _T.textMuted(context)),
                  const SizedBox(width: 6),
                  Text(
                    s,
                    style: TextStyle(
                      color: _T.textSecondary(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => _removeRecent(s),
                    child: Icon(Icons.close_rounded,
                        size: 12, color: _T.textMuted(context)),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Stock Tile ────────────────────────────────
  Widget _buildTile(Map<String, dynamic> stock) {
    final name = _sym(stock);
    final ltp = stock['ltp']?.toDouble() ?? 0.0;
    final pct = stock['percent_change']?.toDouble() ?? 0.0;
    final vol = stock['volume'] ?? 0;
    final isPos = pct >= 0;
    final color = isPos ? _T.bull : _T.bear;
    final fav = _isFav(stock);

    return GestureDetector(
      onTap: () {
        _saveRecent(name);
        _showStockSheet(stock);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _T.card(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _T.border(context)),
        ),
        child: Row(
          children: [
            // Logo
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _T.cardAlt(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _T.border(context)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: CachedNetworkImage(
                  imageUrl: '${Constants.OptionXiS3Loc}$name.png',
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Center(
                    child: Text(
                      name.isNotEmpty ? name[0] : '?',
                      style: TextStyle(
                        color: _T.accent,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Center(
                    child: Text(
                      name.isNotEmpty ? name[0] : '?',
                      style: TextStyle(
                        color: _T.accent,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Name + vol
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: _T.textPrimary(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Vol ${_formatVol(vol)}',
                    style: TextStyle(
                      color: _T.textMuted(context),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            // Price + change
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${ltp.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: _T.textPrimary(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isPos ? _T.bullBg(context) : _T.bearBg(context),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    '${isPos ? '+' : ''}${pct.toStringAsFixed(2)}%',
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 10),

            // Watchlist toggle
            GestureDetector(
              onTap: () => _toggleFav(stock),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Icon(
                  fav ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  size: 20,
                  color: fav ? _T.accent : _T.textMuted(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Stock Detail Bottom Sheet
  // ─────────────────────────────────────────────────────────────
  void _showStockSheet(Map<String, dynamic> stock) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _StockSheet(
        stock: stock,
        displayName: _sym(stock),
        formatVolume: _formatVol,
        isFavorite: _isFav(stock),
        onToggleFav: () => _toggleFav(stock),
        onSetAlert: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SetAlertPage(
                stockName: stock['symbol'],
                segment: stock['type'],
              ),
            ),
          );
        },
      ),
    );
  }
}
// ─────────────────────────────────────────────────────────────
//  Stock Detail Sheet — Sweet Spot Redesign
//  LTP stays prominent · OHLC compacted · Volume inline
//  Dark & Light compatible · Modern Professional
// ─────────────────────────────────────────────────────────────

class _StockSheet extends StatefulWidget {
  final Map<String, dynamic> stock;
  final String displayName;
  final String Function(dynamic) formatVolume;
  final bool isFavorite;
  final VoidCallback onToggleFav;
  final VoidCallback onSetAlert;

  const _StockSheet({
    required this.stock,
    required this.displayName,
    required this.formatVolume,
    required this.isFavorite,
    required this.onToggleFav,
    required this.onSetAlert,
  });

  @override
  State<_StockSheet> createState() => _StockSheetState();
}

class _StockSheetState extends State<_StockSheet> {
  late bool _isFav;

  @override
  void initState() {
    super.initState();
    _isFav = widget.isFavorite;
  }

  @override
  Widget build(BuildContext context) {
    final pct = widget.stock['percent_change']?.toDouble() ?? 0.0;
    final isPos = pct >= 0;
    final ltp = widget.stock['ltp']?.toDouble() ?? 0.0;
    final color = isPos ? _T.bull : _T.bear;
    final bgColor = isPos ? _T.bullBg(context) : _T.bearBg(context);

    return Container(
      decoration: BoxDecoration(
        color: _T.card(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(
          top: BorderSide(color: _T.border(context)),
          left: BorderSide(color: _T.border(context)),
          right: BorderSide(color: _T.border(context)),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).padding.bottom + 12),
      child: Column(
        mainAxisSize: MainAxisSize.min, // ← key: shrink to content
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            width: 36,
            height: 3,
            decoration: BoxDecoration(
              color: _T.border(context),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // ── Header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _T.cardAlt(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _T.border(context)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: CachedNetworkImage(
                    imageUrl:
                        '${Constants.OptionXiS3Loc}${widget.displayName}.png',
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Center(
                        child: Text(
                            widget.displayName.isNotEmpty
                                ? widget.displayName[0]
                                : '?',
                            style: const TextStyle(
                                color: _T.accent,
                                fontSize: 20,
                                fontWeight: FontWeight.w800))),
                    errorWidget: (_, __, ___) => Center(
                        child: Text(
                            widget.displayName.isNotEmpty
                                ? widget.displayName[0]
                                : '?',
                            style: const TextStyle(
                                color: _T.accent,
                                fontSize: 20,
                                fontWeight: FontWeight.w800))),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.displayName,
                        style: TextStyle(
                            color: _T.textPrimary(context),
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5)),
                    const SizedBox(height: 2),
                    Text(widget.stock['symbol'] ?? '',
                        style: TextStyle(
                            color: _T.textMuted(context),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3)),
                  ],
                ),
              ),
              if (widget.stock['type'] != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                      color: _T.cardAlt(context),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _T.border(context))),
                  child: Text('${widget.stock['type']}'.toUpperCase(),
                      style: TextStyle(
                          color: _T.textSecondary(context),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8)),
                ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  setState(() => _isFav = !_isFav);
                  widget.onToggleFav();
                },
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                      _isFav
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      key: ValueKey(_isFav),
                      color: _isFav ? _T.accent : _T.textSecondary(context),
                      size: 22),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── LTP Card
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
                color: _T.cardAlt(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _T.border(context))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('LAST PRICE',
                              style: TextStyle(
                                  color: _T.textMuted(context),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2)),
                          const SizedBox(height: 4),
                          Text('₹${ltp.toStringAsFixed(2)}',
                              style: TextStyle(
                                  color: _T.textPrimary(context),
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1,
                                  height: 1)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        children: [
                          Icon(
                              isPos
                                  ? Icons.trending_up_rounded
                                  : Icons.trending_down_rounded,
                              color: color,
                              size: 16),
                          const SizedBox(width: 5),
                          Text('${isPos ? '+' : ''}${pct.toStringAsFixed(2)}%',
                              style: TextStyle(
                                  color: color,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                        'Prev ${widget.stock['prev_close']?.toStringAsFixed(2) ?? '–'}',
                        style: TextStyle(
                            color: _T.textMuted(context), fontSize: 11)),
                    Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 1,
                        height: 11,
                        color: _T.border(context)),
                    Icon(Icons.bar_chart_rounded,
                        size: 11, color: _T.textMuted(context)),
                    const SizedBox(width: 3),
                    Text('Vol ',
                        style: TextStyle(
                            color: _T.textMuted(context), fontSize: 11)),
                    Text(widget.formatVolume(widget.stock['volume'] ?? 0),
                        style: const TextStyle(
                            color: _T.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── OHLC Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
            decoration: BoxDecoration(
                color: _T.cardAlt(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _T.border(context))),
            child: Row(
              children: [
                _ohlcCell(context, 'OPEN',
                    '₹${widget.stock['open']?.toStringAsFixed(2) ?? '–'}'),
                _ohlcDivider(context),
                _ohlcCell(context, 'HIGH',
                    '₹${widget.stock['high']?.toStringAsFixed(2) ?? '–'}',
                    valueColor: _T.bull),
                _ohlcDivider(context),
                _ohlcCell(context, 'LOW',
                    '₹${widget.stock['low']?.toStringAsFixed(2) ?? '–'}',
                    valueColor: _T.bear),
                _ohlcDivider(context),
                _ohlcCell(context, 'PREV',
                    '₹${widget.stock['prev_close']?.toStringAsFixed(2) ?? '–'}'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── View Full Details
          GestureDetector(
            onTap: () {
              Get.toNamed(
                  '/stocks/${'NSE:' + widget.displayName.toUpperCase() + '-EQ'}');
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF3B72F6), Color(0xFF5B8EFF)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: _T.accent.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6))
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.candlestick_chart_rounded,
                      size: 17, color: Colors.white),
                  SizedBox(width: 8),
                  Text('View Full Details',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2)),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded,
                      size: 15, color: Colors.white70),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // ── Watchlist + Alert
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _isFav = !_isFav);
                    widget.onToggleFav();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                        color: _T.cardAlt(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _T.border(context))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                            _isFav
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            size: 17,
                            color:
                                _isFav ? _T.accent : _T.textSecondary(context)),
                        const SizedBox(width: 8),
                        Text(_isFav ? 'In Watchlist' : 'Add to Watchlist',
                            style: TextStyle(
                                color: _isFav
                                    ? _T.accent
                                    : _T.textSecondary(context),
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: widget.onSetAlert,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                        color: _T.cardAlt(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _T.border(context))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_outlined,
                            size: 17, color: _T.textSecondary(context)),
                        const SizedBox(width: 8),
                        Text('Set Alert',
                            style: TextStyle(
                                color: _T.textSecondary(context),
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Compact OHLC cell — centered label + value
  Widget _ohlcCell(BuildContext context, String label, String value,
      {Color? valueColor}) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: _T.textMuted(context),
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? _T.textPrimary(context),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Thin vertical separator between OHLC cells
  Widget _ohlcDivider(BuildContext context) => Container(
        width: 1,
        height: 26,
        color: _T.border(context),
      );
}

// ─────────────────────────────────────────────────────────────
//  Section Label (unchanged)
// ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  final Widget? trailing;
  final double topPad;

  const _SectionLabel({
    required this.label,
    this.trailing,
    this.topPad = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, topPad, 16, 10),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: _T.textSecondary(context),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Live Pill (unchanged)
// ─────────────────────────────────────────────────────────────
class _LivePill extends StatefulWidget {
  @override
  State<_LivePill> createState() => _LivePillState();
}

class _LivePillState extends State<_LivePill>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: _T.bullBg(context),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: _T.bull.withOpacity(0.25 + _c.value * 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: _T.bull.withOpacity(0.6 + _c.value * 0.4),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              'LIVE',
              style: TextStyle(
                color: _T.bull,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Shimmer Tile (unchanged)
// ─────────────────────────────────────────────────────────────
class _ShimmerTile extends StatelessWidget {
  final AnimationController controller;
  final BuildContext ctx;

  const _ShimmerTile({required this.controller, required this.ctx});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = (math.sin(controller.value * math.pi * 2) + 1) / 2;
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final base = isDark ? const Color(0xFF1E2333) : const Color(0xFFEEF0F6);
        final highlight =
            isDark ? const Color(0xFF262D42) : const Color(0xFFD8DCE8);
        final shade = Color.lerp(base, highlight, t)!;

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _T.card(ctx),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _T.border(ctx)),
          ),
          child: Row(
            children: [
              _box(shade, 40, 40, radius: 10),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _box(shade, 100, 12, radius: 4),
                    const SizedBox(height: 6),
                    _box(shade, 60, 9, radius: 4),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _box(shade, 64, 12, radius: 4),
                  const SizedBox(height: 6),
                  _box(shade, 44, 16, radius: 4),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _box(Color c, double w, double h, {double radius = 4}) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}
