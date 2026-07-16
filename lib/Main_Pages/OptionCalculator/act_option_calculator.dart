import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:optionxi/Helpers/analytics_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────
//  DESIGN TOKENS
// ─────────────────────────────────────────────
class _T {
  static const dBg = Color(0xFF07090E);
  static const dSurface = Color(0xFF0C0F17);
  static const dCard = Color(0xFF111520);
  static const dBorder = Color(0xFF1C2436);
  static const dAccent = Color(0xFF4E9EFF);
  static const dGreen = Color(0xFF00D68F);
  static const dRed = Color(0xFFFF4D6A);
  static const dAmber = Color(0xFFFFAB40);
  static const dViolet = Color(0xFF9B7FFF);
  static const dText = Color(0xFFECF0FC);
  static const dSub = Color(0xFF6B7A94);
  static const dMuted = Color(0xFF313D52);
  static const dDivider = Color(0xFF131926);
  static const dChip = Color(0xFF0F1420);
  static const dTrack = Color(0xFF192030);

  static const lBg = Color(0xFFF3F6FB);
  static const lSurface = Color(0xFFFFFFFF);
  static const lCard = Color(0xFFFFFFFF);
  static const lBorder = Color(0xFFDDE6F4);
  static const lAccent = Color(0xFF1A6FE8);
  static const lGreen = Color(0xFF009E6A);
  static const lRed = Color(0xFFDC3355);
  static const lAmber = Color(0xFFD97706);
  static const lViolet = Color(0xFF6E44E8);
  static const lText = Color(0xFF0B1526);
  static const lSub = Color(0xFF4A5E7A);
  static const lMuted = Color(0xFF9EB2CC);
  static const lDivider = Color(0xFFEAEFF8);
  static const lChip = Color(0xFFF0F4FC);
  static const lTrack = Color(0xFFDDE6F4);
}

// ─────────────────────────────────────────────
//  ENUMS
// ─────────────────────────────────────────────
enum _Universe { all, indexOnly, stocksOnly, specific }

extension _UExt on _Universe {
  String get label => const ['All', 'Index', 'Stocks', 'Pick'][index];
  IconData get icon => const [
        Icons.grid_view_rounded,
        Icons.bar_chart_rounded,
        Icons.business_rounded,
        Icons.search_rounded,
      ][index];
}

enum _Sort {
  budgetNearest, // default – closest to budget
  budgetAsc,
  budgetDesc,
  ltpAsc,
  ltpDesc,
  ivAsc,
  ivDesc,
  popDesc,
  strikeAsc,
}

extension _SExt on _Sort {
  String get label => const [
        'Nearest Budget',
        'Budget ↑',
        'Budget ↓',
        'LTP ↑',
        'LTP ↓',
        'IV ↑',
        'IV ↓',
        'PoP Best',
        'Strike ↑',
      ][index];
}

const _kIndices = [
  'NIFTY',
  'BANKNIFTY',
  'FINNIFTY',
  'MIDCPNIFTY',
  'SENSEX',
  'NIFTYNXT50',
  'MIDSELECT',
  'NIFTY MID SELECT',
  'BANKEX'
];
const double _bMin = 500, _bMax = 500000, _sMin = 0, _sMax = 50;
const int _pageSize = 15;

// ─────────────────────────────────────────────
//  MODEL
// ─────────────────────────────────────────────
class _Opt {
  final String symbol, type, strikeLevel, underlyingKey;
  final DateTime expiry;
  final double strike, spot, ltp, iv, delta, gamma, theta, vega, pop;
  final bool isAtm, isItm, isOtm;
  final double volume, oi, oiChange, bid, ask;
  final int lotSize, strikesFromAtm;

  const _Opt({
    required this.symbol,
    required this.type,
    required this.strikeLevel,
    required this.underlyingKey,
    required this.expiry,
    required this.strike,
    required this.spot,
    required this.ltp,
    required this.iv,
    required this.delta,
    required this.gamma,
    required this.theta,
    required this.vega,
    required this.pop,
    required this.isAtm,
    required this.isItm,
    required this.isOtm,
    required this.volume,
    required this.oi,
    required this.oiChange,
    required this.bid,
    required this.ask,
    required this.lotSize,
    required this.strikesFromAtm,
  });

  factory _Opt.fromMap(Map<String, dynamic> m) => _Opt(
        symbol: m['underlying_symbol'] ?? '',
        type: (m['option_type'] as String?)?.trim() ?? '',
        strikeLevel: (m['strike_level'] as String?)?.trim() ?? '',
        underlyingKey: m['underlying_key'] ?? '',
        expiry: DateTime.tryParse(m['expiry_date'] ?? '') ?? DateTime.now(),
        strike: (m['strike_price'] as num?)?.toDouble() ?? 0,
        spot: (m['spot_price'] as num?)?.toDouble() ?? 0,
        ltp: (m['ltp'] as num?)?.toDouble() ?? 0,
        iv: (m['iv'] as num?)?.toDouble() ?? 0,
        delta: (m['delta'] as num?)?.toDouble() ?? 0,
        gamma: (m['gamma'] as num?)?.toDouble() ?? 0,
        theta: (m['theta'] as num?)?.toDouble() ?? 0,
        vega: (m['vega'] as num?)?.toDouble() ?? 0,
        pop: (m['pop'] as num?)?.toDouble() ?? 0,
        isAtm: m['is_atm'] ?? false,
        isItm: m['is_itm'] ?? false,
        isOtm: m['is_otm'] ?? false,
        volume: (m['volume'] as num?)?.toDouble() ?? 0,
        oi: (m['oi'] as num?)?.toDouble() ?? 0,
        oiChange: (m['oi_change'] as num?)?.toDouble() ?? 0,
        bid: (m['bid_price'] as num?)?.toDouble() ?? 0,
        ask: (m['ask_price'] as num?)?.toDouble() ?? 0,
        lotSize: (m['lot_size'] as int?) ?? 1,
        strikesFromAtm: (m['strikes_from_atm'] as int?) ?? 0,
      );

  double get lotCost => ltp * lotSize;
  double get breakeven => type == 'CE' ? strike + ltp : strike - ltp;
  bool get isIndex =>
      _kIndices.contains(symbol) || underlyingKey.startsWith('NSE_INDEX');
}

// ─────────────────────────────────────────────
//  PAGE
// ─────────────────────────────────────────────
class OptionCalculatorPage extends StatefulWidget {
  const OptionCalculatorPage({super.key});
  @override
  State<OptionCalculatorPage> createState() => _PS();
}

class _PS extends State<OptionCalculatorPage> {
  // ── theme ─────────────────────────────────
  bool get dk => Theme.of(context).brightness == Brightness.dark;
  Color get bg => dk ? _T.dBg : _T.lBg;
  Color get surface => dk ? _T.dSurface : _T.lSurface;
  Color get card => dk ? _T.dCard : _T.lCard;
  Color get brd => dk ? _T.dBorder : _T.lBorder;
  Color get accent => dk ? _T.dAccent : _T.lAccent;
  Color get green => dk ? _T.dGreen : _T.lGreen;
  Color get red => dk ? _T.dRed : _T.lRed;
  Color get amber => dk ? _T.dAmber : _T.lAmber;
  Color get violet => dk ? _T.dViolet : _T.lViolet;
  Color get txt => dk ? _T.dText : _T.lText;
  Color get sub => dk ? _T.dSub : _T.lSub;
  Color get muted => dk ? _T.dMuted : _T.lMuted;
  Color get divider => dk ? _T.dDivider : _T.lDivider;
  Color get chipC => dk ? _T.dChip : _T.lChip;
  Color get trackC => dk ? _T.dTrack : _T.lTrack;

  // ── supabase ──────────────────────────────
  final _db = Supabase.instance.client;

  // ── filter state ──────────────────────────
  _Universe _universe = _Universe.all;
  String _specSym = '';
  String _optType = 'ALL';
  String _level = 'ALL';
  _Sort _sortBy = _Sort.budgetNearest; // default: nearest to budget
  double _budget = 30000;
  double _sRange = 20; // default strike range = 20

  // ── search ────────────────────────────────
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  // ── data ──────────────────────────────────
  List<_Opt> _rows = [];
  int _totalCount = 0;
  bool _loading = false;
  bool _countLoading = false;
  String? _error;

  // ── pagination ────────────────────────────
  int _page = 0;
  int get _pages => (_totalCount / _pageSize).ceil().clamp(1, 9999);

  @override
  void initState() {
    super.initState();
    _fetchPage();
    AnalyticsHelper.logScreen('optionchain_budget',
        screenClass: "OptionCalculatorPage");
    // Show budget sheet after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showBudgetSheet();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── SHARED FILTER LOGIC ───────────────────
  // Applies all active filters to any already-started query builder.
  // `q` must be a PostgrestFilterBuilder — typed as dynamic so we can
  // reuse the same logic for both the data query and the count query
  // without duplicating filter code.
  dynamic _applyFilters(dynamic q) {
    // ltp > 0
    q = q.gt('ltp', 0);

    // Universe
    switch (_universe) {
      case _Universe.indexOnly:
        q = q.like('underlying_key', 'NSE_INDEX%');
      case _Universe.stocksOnly:
        q = q.not('underlying_key', 'like', 'NSE_INDEX%');
      case _Universe.specific:
        if (_specSym.isNotEmpty) q = q.eq('underlying_symbol', _specSym);
      case _Universe.all:
        break;
    }

    // Symbol search
    if (_searchQuery.trim().isNotEmpty) {
      q = q.ilike('underlying_symbol', '%${_searchQuery.trim()}%');
    }

    // Option type
    if (_optType != 'ALL') q = q.eq('option_type', _optType);

    // Strike level
    if (_level == 'ATM') q = q.eq('is_atm', true);
    if (_level == 'ITM') q = q.eq('is_itm', true);
    if (_level == 'OTM') q = q.eq('is_otm', true);

    // Strike range (strikes_from_atm).
    // Budget (lot_cost = ltp × lot_size) is a computed value — filtered
    // client-side after fetch since Supabase can't filter on expressions
    // without an RPC/generated column.
    final range = _sRange.round();
    q = q.lte('strikes_from_atm', range).gte('strikes_from_atm', -range);

    return q;
  }

  // ── FETCH PAGE ────────────────────────────
  Future<void> _fetchPage({bool resetPage = false}) async {
    if (resetPage && mounted) setState(() => _page = 0);
    if (mounted)
      setState(() {
        _loading = true;
        _error = null;
      });

    try {
      final offset = _page * _pageSize;

      List<Map<String, dynamic>> res;

      if (_sortBy == _Sort.budgetNearest) {
        // ✅ Full server-side: ORDER BY ABS(total_margin - budget)
        res = List<Map<String, dynamic>>.from(
          await _db.rpc('get_options_by_budget', params: {
            'p_budget': _budget,
            'p_universe': switch (_universe) {
              _Universe.indexOnly => 'index',
              _Universe.stocksOnly => 'stocks',
              _Universe.specific => 'specific',
              _Universe.all => 'all',
            },
            'p_symbol': _specSym,
            'p_option_type': _optType,
            'p_level': _level,
            'p_strikes_range': _sRange.round(),
            'p_search': _searchQuery.trim(),
            'p_limit': _pageSize,
            'p_offset': offset,
          }) as List,
        );
      } else {
        // Other sorts — use existing filter builder + total_margin budget filter
        final (col, asc) = _sortColumn();
        dynamic q = _applyFilters(
          _db.from('option_chain').select(
                'underlying_symbol,underlying_key,option_type,expiry_date,strike_price,spot_price,'
                'ltp,iv,delta,gamma,theta,vega,pop,strike_level,is_atm,is_itm,is_otm,'
                'volume,oi,oi_change,bid_price,ask_price,lot_size,strikes_from_atm,total_margin',
              ),
        )
            .gt('total_margin', 0)
            .lte('total_margin', _budget); // ✅ server-side budget filter

        if (col != null) q = q.order(col, ascending: asc);
        q = q.range(offset, offset + _pageSize - 1);
        res = List<Map<String, dynamic>>.from(await q as List);
      }

      if (mounted) setState(() => _rows = res.map(_Opt.fromMap).toList());
      _fetchCount();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fetchCount() async {
    if (!mounted) return;
    setState(() => _countLoading = true);
    try {
      final response = await _applyFilters(
        _db.from('option_chain').select('*'),
      )
          .gt('total_margin', 0)
          .lte('total_margin', _budget) // ✅ uses real column
          .count();
      if (mounted) setState(() => _totalCount = response.count);
    } catch (_) {
      if (mounted) setState(() => _totalCount = 0);
    } finally {
      if (mounted) setState(() => _countLoading = false);
    }
  }

  // Returns (columnName, ascending) for server-side ordering.
  // budgetNearest is handled client-side; return ltp asc as a proxy.
  (String?, bool) _sortColumn() => switch (_sortBy) {
        _Sort.budgetNearest => ('ltp', true), // proxy; client reorders
        _Sort.budgetAsc => ('ltp', true),
        _Sort.budgetDesc => ('ltp', false),
        _Sort.ltpAsc => ('ltp', true),
        _Sort.ltpDesc => ('ltp', false),
        _Sort.ivAsc => ('iv', true),
        _Sort.ivDesc => ('iv', false),
        _Sort.popDesc => ('pop', false),
        _Sort.strikeAsc => ('strike_price', true),
      };

  // Re-fetch from page 0 whenever a filter changes
  void _apply() => _fetchPage(resetPage: true);

  // ── FORMAT ────────────────────────────────
  String _fD(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-${_mn(d.month)}-${d.year}';
  String _fDs(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} ${_mn(d.month)}\'${d.year.toString().substring(2)}';
  String _mn(int m) => const [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ][m - 1];
  String _fB(double v) {
    if (v >= 100000)
      return '₹${(v / 100000).toStringAsFixed(v % 100000 == 0 ? 0 : 1)}L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(0)}K';
    return '₹${v.toStringAsFixed(0)}';
  }

  String _fOI(double v) {
    if (v >= 1e7) return '${(v / 1e7).toStringAsFixed(1)}Cr';
    if (v >= 1e5) return '${(v / 1e5).toStringAsFixed(1)}L';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  // ── BUILD ─────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          _buildHeader(),
          _buildFilterStrip(),
          _buildSearchBar(), // full-width search below filter strip
          Expanded(child: _buildBody()),
          if (_pages > 1) _buildPagination(),
        ],
      ),
    );
  }

  // ── HEADER ────────────────────────────────
  Widget _buildHeader() {
    final uLabel = _universe == _Universe.specific && _specSym.isNotEmpty
        ? _specSym
        : _universe.label;
    return Container(
      decoration: BoxDecoration(
        color: surface,
        border: Border(bottom: BorderSide(color: divider, width: 0.8)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 14, 10),
          child: Row(
            children: [
              _Tap(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  height: 36,
                  width: 36,
                  decoration: BoxDecoration(
                    color: chipC,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: brd),
                  ),
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                      size: 14, color: sub),
                ),
              ),
              Container(
                  width: 1,
                  height: 22,
                  color: divider,
                  margin: const EdgeInsets.symmetric(horizontal: 10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(children: [
                      Text('FNO Budget',
                          style: GoogleFonts.dmSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: txt,
                              letterSpacing: -0.4)),
                      const SizedBox(width: 7),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: green,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: green.withOpacity(0.55), blurRadius: 6)
                          ],
                        ),
                      ),
                    ]),
                    Text(
                        _countLoading
                            ? '— results · ${_fB(_budget)}'
                            : '$_totalCount results · ${_fB(_budget)}',
                        style: GoogleFonts.dmSans(fontSize: 11, color: sub)),
                  ],
                ),
              ),
              // Universe badge
              _Tap(
                onTap: _showUniverseSheet,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: accent.withOpacity(0.35)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_universe.icon, size: 13, color: accent),
                    const SizedBox(width: 5),
                    Text(uLabel,
                        style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: accent)),
                    const SizedBox(width: 3),
                    Icon(Icons.unfold_more_rounded, size: 13, color: accent),
                  ]),
                ),
              ),
              const SizedBox(width: 8),
              _Tap(
                onTap: () => _fetchPage(resetPage: true),
                child: Container(
                  height: 34,
                  width: 34,
                  decoration: BoxDecoration(
                    color: chipC,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: brd),
                  ),
                  child: Icon(Icons.refresh_rounded, size: 16, color: sub),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── FILTER STRIP ──────────────────────────
  Widget _buildFilterStrip() {
    return Container(
      color: surface,
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        children: [
          _FilterChip(
              label: _optType == 'ALL' ? 'CE/PE' : _optType,
              active: _optType != 'ALL',
              color: _optType == 'CE'
                  ? green
                  : _optType == 'PE'
                      ? red
                      : accent,
              chipC: chipC,
              brd: brd,
              sub: sub,
              onTap: _showTypeSheet),
          const SizedBox(width: 7),
          _FilterChip(
              label: _level == 'ALL' ? 'Level' : _level,
              active: _level != 'ALL',
              color: _level == 'ATM'
                  ? amber
                  : _level == 'ITM'
                      ? green
                      : red,
              chipC: chipC,
              brd: brd,
              sub: sub,
              onTap: _showLevelSheet),
          const SizedBox(width: 7),
          _FilterChip(
              label: _fB(_budget),
              icon: Icons.account_balance_wallet_rounded,
              active: true,
              color: green,
              chipC: chipC,
              brd: brd,
              sub: sub,
              onTap: _showBudgetSheet),
          const SizedBox(width: 7),
          _FilterChip(
              label: _sRange == 0 ? 'ATM only' : '±${_sRange.round()} strikes',
              icon: Icons.layers_rounded,
              active: true,
              color: accent,
              chipC: chipC,
              brd: brd,
              sub: sub,
              onTap: _showStrikeSheet),
          const SizedBox(width: 7),
          _FilterChip(
              label: _sortBy.label,
              icon: Icons.swap_vert_rounded,
              // Only show as "active" (colored) when non-default sort selected
              active: _sortBy != _Sort.budgetNearest,
              color: violet,
              chipC: chipC,
              brd: brd,
              sub: sub,
              onTap: _showSortSheet),
        ],
      ),
    );
  }

  // ── FULL-WIDTH SEARCH BAR ─────────────────
  Widget _buildSearchBar() {
    return Container(
      color: surface,
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: chipC,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: brd),
        ),
        child: Row(children: [
          const SizedBox(width: 12),
          Icon(Icons.search_rounded, size: 16, color: sub),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              style: GoogleFonts.dmSans(fontSize: 13, color: txt),
              decoration: InputDecoration(
                hintText: 'Search symbol…',
                hintStyle: GoogleFonts.dmSans(fontSize: 13, color: muted),
                border: InputBorder.none,
                isDense: true,
              ),
              onChanged: (v) {
                setState(() => _searchQuery = v);
                _apply();
              },
            ),
          ),
          if (_searchQuery.isNotEmpty)
            _Tap(
              onTap: () {
                _searchCtrl.clear();
                setState(() => _searchQuery = '');
                _apply();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.close_rounded, size: 15, color: sub),
              ),
            )
          else
            const SizedBox(width: 10),
        ]),
      ),
    );
  }

  // ── BODY ──────────────────────────────────
  Widget _buildBody() {
    if (_loading && _rows.isEmpty) return _buildShimmer();
    if (_error != null) return _buildError();
    if (_rows.isEmpty) return _buildEmpty();
    return Stack(children: [
      ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
        itemCount: _rows.length,
        itemBuilder: (_, i) => _RowTile(
          opt: _rows[i],
          dk: dk,
          card: card,
          brd: brd,
          green: green,
          red: red,
          amber: amber,
          txt: txt,
          sub: sub,
          muted: muted,
          fDs: _fDs,
          fOI: _fOI,
          fB: _fB,
          onTap: () {
            HapticFeedback.lightImpact();
            _showDetail(_rows[i]);
          },
        ),
      ),
      // Subtle loading overlay while fetching next page
      if (_loading)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: LinearProgressIndicator(
            minHeight: 2,
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation(accent),
          ),
        ),
    ]);
  }

  // ── SHIMMER / ERROR / EMPTY ───────────────
  Widget _buildShimmer() => ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
        itemCount: 12,
        itemBuilder: (_, i) => _ShimmerTile(dk: dk),
      );

  Widget _buildError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                  color: red.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(Icons.cloud_off_rounded, color: red, size: 24),
            ),
            const SizedBox(height: 16),
            Text('Unable to load',
                style: GoogleFonts.dmSans(
                    color: txt, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(_error ?? '',
                style: GoogleFonts.dmSans(color: sub, fontSize: 12),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            _PillBtn(
                label: 'Retry',
                color: accent,
                onTap: () => _fetchPage(resetPage: true)),
          ]),
        ),
      );

  Widget _buildEmpty() => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.search_off_rounded, color: muted, size: 48),
            const SizedBox(height: 16),
            Text('No matches found',
                style: GoogleFonts.dmSans(
                    color: txt, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('Raise budget or expand strike range.',
                style: GoogleFonts.dmSans(color: sub, fontSize: 13),
                textAlign: TextAlign.center),
          ]),
        ),
      );

  // ── PAGINATION ────────────────────────────
  Widget _buildPagination() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: surface,
        border: Border(top: BorderSide(color: divider, width: 0.8)),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        _Tap(
          onTap: _page > 0
              ? () {
                  setState(() => _page--);
                  _fetchPage();
                }
              : null,
          child: SizedBox(
              height: 52,
              width: 56,
              child: Icon(Icons.chevron_left_rounded,
                  color: _page > 0 ? accent : muted, size: 22)),
        ),
        // Page counter text instead of dots — works for any page count
        RichText(
          text: TextSpan(children: [
            TextSpan(
                text: '${_page + 1}',
                style: GoogleFonts.spaceMono(
                    fontSize: 14, fontWeight: FontWeight.w800, color: accent)),
            TextSpan(
                text: '  /  ',
                style: GoogleFonts.spaceMono(fontSize: 12, color: muted)),
            TextSpan(
                text: _countLoading ? '…' : '$_pages',
                style: GoogleFonts.spaceMono(
                    fontSize: 14, fontWeight: FontWeight.w600, color: sub)),
          ]),
        ),
        _Tap(
          onTap: _page < _pages - 1
              ? () {
                  setState(() => _page++);
                  _fetchPage();
                }
              : null,
          child: SizedBox(
              height: 52,
              width: 56,
              child: Icon(Icons.chevron_right_rounded,
                  color: _page < _pages - 1 ? accent : muted, size: 22)),
        ),
      ]),
    );
  }

  // ── DETAIL SHEET ──────────────────────────
  void _showDetail(_Opt o) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DetailSheet(
          o: o,
          dk: dk,
          surface: surface,
          card: card,
          brd: brd,
          divider: divider,
          chipC: chipC,
          accent: accent,
          green: green,
          red: red,
          amber: amber,
          violet: violet,
          txt: txt,
          sub: sub,
          muted: muted,
          fD: _fD,
          fOI: _fOI,
          fB: _fB),
    );
  }

  // ── FILTER SHEETS ─────────────────────────
  void _showTypeSheet() => showDialog(
        context: context,
        builder: (_) => _PickDialog(
            title: 'Option Type',
            opts: const ['ALL', 'CE', 'PE'],
            sel: _optType,
            color: accent,
            surface: surface,
            card: card,
            brd: brd,
            txt: txt,
            sub: sub,
            muted: muted,
            divider: divider,
            onSelect: (v) {
              setState(() => _optType = v);
              _apply();
              Navigator.pop(context);
            }),
      );

  void _showLevelSheet() => showDialog(
        context: context,
        builder: (_) => _PickDialog(
            title: 'Strike Level',
            opts: const ['ALL', 'ATM', 'ITM', 'OTM'],
            sel: _level,
            color: amber,
            surface: surface,
            card: card,
            brd: brd,
            txt: txt,
            sub: sub,
            muted: muted,
            divider: divider,
            onSelect: (v) {
              setState(() => _level = v);
              _apply();
              Navigator.pop(context);
            }),
      );

  void _showBudgetSheet() => showModalBottomSheet(
        context: context,
        backgroundColor: surface,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (_) => _BudgetSheet(
            init: _budget,
            green: green,
            chipC: chipC,
            brd: brd,
            sub: sub,
            bg: bg,
            trackC: trackC,
            txt: txt,
            muted: muted,
            divider: divider,
            fB: _fB,
            onApply: (v) {
              setState(() => _budget = v);
              _apply();
            }),
      );

  void _showStrikeSheet() => showModalBottomSheet(
        context: context,
        backgroundColor: surface,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (_) => _StrikeSheet(
            init: _sRange,
            accent: accent,
            chipC: chipC,
            brd: brd,
            sub: sub,
            trackC: trackC,
            txt: txt,
            muted: muted,
            divider: divider,
            onApply: (v) {
              setState(() => _sRange = v);
              _apply();
            }),
      );

  void _showSortSheet() => showDialog(
        context: context,
        builder: (_) => _SortDialog(
            sel: _sortBy,
            surface: surface,
            card: card,
            violet: violet,
            chipC: chipC,
            brd: brd,
            txt: txt,
            sub: sub,
            muted: muted,
            divider: divider,
            onSelect: (v) {
              setState(() => _sortBy = v);
              _apply();
              Navigator.pop(context);
            }),
      );

  void _showUniverseSheet() => showModalBottomSheet(
        context: context,
        backgroundColor: surface,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (_) => _UniverseSheet(
            db: _db,
            initUni: _universe,
            initSpec: _specSym,
            accent: accent,
            chipC: chipC,
            brd: brd,
            bg: bg,
            divider: divider,
            txt: txt,
            sub: sub,
            muted: muted,
            onApply: (uni, spec) {
              setState(() {
                _universe = uni;
                _specSym = spec;
              });
              _apply();
            }),
      );
}

// ─────────────────────────────────────────────
//  ROW TILE (with POP - Full Width)
// ─────────────────────────────────────────────
class _RowTile extends StatelessWidget {
  final _Opt opt;
  final bool dk;
  final Color card, brd, green, red, amber, txt, sub, muted;
  final String Function(DateTime) fDs;
  final String Function(double) fOI, fB;
  final VoidCallback onTap;

  const _RowTile({
    required this.opt,
    required this.dk,
    required this.card,
    required this.brd,
    required this.green,
    required this.red,
    required this.amber,
    required this.txt,
    required this.sub,
    required this.muted,
    required this.fDs,
    required this.fOI,
    required this.fB,
    required this.onTap,
  });

  Color _getPopColor(double pop) {
    if (pop >= 70) return green;
    if (pop >= 50) return amber;
    return red;
  }

  @override
  Widget build(BuildContext context) {
    final o = opt;
    final tc = o.type == 'CE' ? green : red;
    final popColor = _getPopColor(o.pop);

    return _Tap(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 7),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: brd),
        ),
        child: Column(
          children: [
            // Main row content
            Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: tc.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: tc.withOpacity(0.3)),
                ),
                child: Center(
                    child: Text(o.type,
                        style: GoogleFonts.spaceMono(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: tc))),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    RichText(
                        text: TextSpan(children: [
                      TextSpan(
                          text: '${o.symbol} ',
                          style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: txt)),
                      TextSpan(
                          text: o.strike.toStringAsFixed(0),
                          style: GoogleFonts.spaceMono(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: txt)),
                      TextSpan(
                          text: ' ${o.type}',
                          style: GoogleFonts.spaceMono(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: tc)),
                    ])),
                    const SizedBox(height: 3),
                    Row(children: [
                      Text(fDs(o.expiry),
                          style: GoogleFonts.spaceMono(
                              fontSize: 10, color: muted)),
                      if (o.isAtm) ...[
                        const SizedBox(width: 6),
                        _Tag('ATM', amber)
                      ],
                      if (o.isItm) ...[
                        const SizedBox(width: 6),
                        _Tag('ITM', green)
                      ],
                      const SizedBox(width: 6),
                      Text('IV ${o.iv.toStringAsFixed(1)}%',
                          style: GoogleFonts.spaceMono(
                              fontSize: 10, color: muted)),
                    ]),
                  ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('₹',
                          style: GoogleFonts.dmSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: tc)),
                      Text(o.ltp.toStringAsFixed(2),
                          style: GoogleFonts.spaceMono(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: tc)),
                    ]),
                const SizedBox(height: 3),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                      color: green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(5)),
                  child: Text('${fB(o.lotCost)} / lot',
                      style: GoogleFonts.spaceMono(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: green)),
                ),
              ]),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, size: 15, color: muted),
            ]),

            // POP Progress Bar Section - FULL WIDTH
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Probability of Profit',
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: muted,
                      ),
                    ),
                    Text(
                      '${o.pop.toStringAsFixed(1)}%',
                      style: GoogleFonts.spaceMono(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: popColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: o.pop / 100,
                    backgroundColor: popColor.withOpacity(0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(popColor),
                    minHeight: 6,
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

// ─────────────────────────────────────────────
//  DETAIL BOTTOM SHEET
// ─────────────────────────────────────────────
class _DetailSheet extends StatelessWidget {
  final _Opt o;
  final bool dk;
  final Color surface, card, brd, divider, chipC;
  final Color accent, green, red, amber, violet, txt, sub, muted;
  final String Function(DateTime) fD;
  final String Function(double) fOI, fB;

  const _DetailSheet({
    required this.o,
    required this.dk,
    required this.surface,
    required this.card,
    required this.brd,
    required this.divider,
    required this.chipC,
    required this.accent,
    required this.green,
    required this.red,
    required this.amber,
    required this.violet,
    required this.txt,
    required this.sub,
    required this.muted,
    required this.fD,
    required this.fOI,
    required this.fB,
  });

  @override
  Widget build(BuildContext context) {
    final tc = o.type == 'CE' ? green : red;
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, sc) => Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                  color: muted.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: tc.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: tc.withOpacity(0.35)),
                ),
                child: Center(
                    child: Text(o.type,
                        style: GoogleFonts.spaceMono(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: tc))),
              ),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    RichText(
                        text: TextSpan(children: [
                      TextSpan(
                          text: '${o.symbol} ',
                          style: GoogleFonts.dmSans(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: txt)),
                      TextSpan(
                          text: o.strike.toStringAsFixed(0),
                          style: GoogleFonts.spaceMono(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: txt)),
                      TextSpan(
                          text: ' ${o.type}',
                          style: GoogleFonts.spaceMono(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: tc)),
                    ])),
                    const SizedBox(height: 5),
                    Wrap(spacing: 6, children: [
                      Text(fD(o.expiry),
                          style: GoogleFonts.spaceMono(
                              fontSize: 11, color: muted)),
                      if (o.isAtm) _Tag('ATM', amber),
                      if (o.isItm) _Tag('ITM', green),
                      if (o.isOtm) _Tag('OTM', red),
                    ]),
                  ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('₹',
                          style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: tc)),
                      Text(o.ltp.toStringAsFixed(2),
                          style: GoogleFonts.spaceMono(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: tc)),
                    ]),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6)),
                  child: Text('${fB(o.lotCost)} / lot',
                      style: GoogleFonts.spaceMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: green)),
                ),
              ]),
            ]),
          ),
          Divider(height: 1, color: divider),
          Expanded(
              child: ListView(
                  controller: sc,
                  padding: const EdgeInsets.all(20),
                  children: [
                _SecLabel('Options Greeks', accent, sub),
                const SizedBox(height: 10),
                Row(children: [
                  _GreekBox('Δ Delta', o.delta.toStringAsFixed(4), accent,
                      chipC, brd, sub, muted),
                  const SizedBox(width: 8),
                  _GreekBox('Γ Gamma', o.gamma.toStringAsFixed(5), sub, chipC,
                      brd, sub, muted),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  _GreekBox('Θ Theta', o.theta.toStringAsFixed(4), red, chipC,
                      brd, sub, muted),
                  const SizedBox(width: 8),
                  _GreekBox('ν Vega', o.vega.toStringAsFixed(4), violet, chipC,
                      brd, sub, muted),
                ]),
                const SizedBox(height: 20),
                _SecLabel('Key Metrics', accent, sub),
                const SizedBox(height: 10),
                _MetricGrid2([
                  _M('IV', '${o.iv.toStringAsFixed(2)}%', amber),
                  _M('Spot', '₹${o.spot.toStringAsFixed(2)}', txt),
                  _M('Breakeven', o.breakeven.toStringAsFixed(0), accent),
                  _M('Lot Size', '${o.lotSize}', txt),
                  _M('OI', fOI(o.oi), sub),
                  _M('Volume', fOI(o.volume), sub),
                  _M('OI Chg', fOI(o.oiChange), o.oiChange >= 0 ? green : red),
                  _M(
                      'Bid/Ask',
                      '${o.bid.toStringAsFixed(1)} / ${o.ask.toStringAsFixed(1)}',
                      sub),
                ], chipC, brd, txt, sub, muted),
                const SizedBox(height: 20),
                _SecLabel('Probability of Profit', accent, sub),
                const SizedBox(height: 10),
                _PopBar2(o.pop, green, red, chipC, brd, sub, muted, divider),
              ])),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  BUDGET SHEET
// ─────────────────────────────────────────────
class _BudgetSheet extends StatefulWidget {
  final double init;
  final Color green, chipC, brd, sub, bg, trackC, txt, muted, divider;
  final String Function(double) fB;
  final ValueChanged<double> onApply;

  const _BudgetSheet({
    required this.init,
    required this.green,
    required this.chipC,
    required this.brd,
    required this.sub,
    required this.bg,
    required this.trackC,
    required this.txt,
    required this.muted,
    required this.divider,
    required this.fB,
    required this.onApply,
  });

  @override
  State<_BudgetSheet> createState() => _BudgetSheetState();
}

class _BudgetSheetState extends State<_BudgetSheet> {
  late double _v;
  @override
  void initState() {
    super.initState();
    _v = widget.init;
  }

  @override
  Widget build(BuildContext context) {
    final presets = <double>[5000, 15000, 30000, 50000, 100000];
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Handle(widget.muted),
            Row(children: [
              Icon(Icons.account_balance_wallet_rounded,
                  color: widget.green, size: 18),
              const SizedBox(width: 8),
              Text('Max Budget',
                  style: GoogleFonts.dmSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: widget.txt)),
              const Spacer(),
              Text(widget.fB(_v),
                  style: GoogleFonts.spaceMono(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: widget.green)),
            ]),
            const SizedBox(height: 5),
            Text('Show options where 1 lot cost ≤ budget',
                style: GoogleFonts.dmSans(fontSize: 13, color: widget.sub)),
            const SizedBox(height: 22),
            _Slider2(
                v: _v,
                min: _bMin,
                max: _bMax,
                color: widget.green,
                track: widget.trackC,
                onChange: (v) => setState(() => _v = v)),
            const SizedBox(height: 12),
            Row(
                children: presets.map((p) {
              final active = (_v - p).abs() < 500;
              return Expanded(
                  child: _Tap(
                onTap: () => setState(() => _v = p),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color:
                        active ? widget.green.withOpacity(0.14) : widget.chipC,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                        color: active
                            ? widget.green.withOpacity(0.4)
                            : widget.brd),
                  ),
                  child: Center(
                      child: Text(widget.fB(p),
                          style: GoogleFonts.spaceMono(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: active ? widget.green : widget.sub))),
                ),
              ));
            }).toList()),
            const SizedBox(height: 20),
            _PillBtn(
                label: 'Apply',
                color: widget.green,
                onTap: () {
                  widget.onApply(_v);
                  Navigator.pop(context);
                }),
          ]),
    );
  }
}

// ─────────────────────────────────────────────
//  STRIKE SHEET  (max 50, default 20)
// ─────────────────────────────────────────────
class _StrikeSheet extends StatefulWidget {
  final double init;
  final Color accent, chipC, brd, sub, trackC, txt, muted, divider;
  final ValueChanged<double> onApply;

  const _StrikeSheet({
    required this.init,
    required this.accent,
    required this.chipC,
    required this.brd,
    required this.sub,
    required this.trackC,
    required this.txt,
    required this.muted,
    required this.divider,
    required this.onApply,
  });

  @override
  State<_StrikeSheet> createState() => _StrikeSheetState();
}

class _StrikeSheetState extends State<_StrikeSheet> {
  late double _v;
  @override
  void initState() {
    super.initState();
    _v = widget.init;
  }

  @override
  Widget build(BuildContext context) {
    final label = _v == 0 ? 'ATM only' : '±${_v.round()} strikes';
    // presets updated to reflect new 0-50 range
    final presets = <double>[0, 5, 10, 20, 50];
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Handle(widget.muted),
            Row(children: [
              Icon(Icons.layers_rounded, color: widget.accent, size: 18),
              const SizedBox(width: 8),
              Text('Strike Range',
                  style: GoogleFonts.dmSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: widget.txt)),
              const Spacer(),
              Text(label,
                  style: GoogleFonts.spaceMono(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: widget.accent)),
            ]),
            const SizedBox(height: 5),
            Text('Strikes shown from ATM (0 = ATM only)',
                style: GoogleFonts.dmSans(fontSize: 13, color: widget.sub)),
            const SizedBox(height: 22),
            _Slider2(
                v: _v,
                min: _sMin,
                max: _sMax, // now 50
                color: widget.accent,
                track: widget.trackC,
                divisions: 50, // one tick per strike
                onChange: (v) => setState(() => _v = v)),
            const SizedBox(height: 12),
            Row(
                children: presets.map((p) {
              final active = (_v - p).abs() < 0.5;
              return Expanded(
                  child: _Tap(
                onTap: () => setState(() => _v = p),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color:
                        active ? widget.accent.withOpacity(0.14) : widget.chipC,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                        color: active
                            ? widget.accent.withOpacity(0.4)
                            : widget.brd),
                  ),
                  child: Center(
                      child: Text(p == 0 ? 'ATM' : '±${p.toInt()}',
                          style: GoogleFonts.spaceMono(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: active ? widget.accent : widget.sub))),
                ),
              ));
            }).toList()),
            const SizedBox(height: 20),
            _PillBtn(
                label: 'Apply',
                color: widget.accent,
                onTap: () {
                  widget.onApply(_v);
                  Navigator.pop(context);
                }),
          ]),
    );
  }
}

// ─────────────────────────────────────────────
//  SORT DIALOG
// ─────────────────────────────────────────────
class _SortDialog extends StatelessWidget {
  final _Sort sel;
  final Color surface, card, violet, chipC, brd, txt, sub, muted, divider;
  final ValueChanged<_Sort> onSelect;

  const _SortDialog({
    required this.sel,
    required this.surface,
    required this.card,
    required this.violet,
    required this.chipC,
    required this.brd,
    required this.txt,
    required this.sub,
    required this.muted,
    required this.divider,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.72),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: brd),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
              child: Row(children: [
                Text('Sort By',
                    style: GoogleFonts.dmSans(
                        fontSize: 17, fontWeight: FontWeight.w800, color: txt)),
                const Spacer(),
                _Tap(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                        color: muted.withOpacity(0.15), shape: BoxShape.circle),
                    child: Icon(Icons.close_rounded, size: 14, color: sub),
                  ),
                ),
              ]),
            ),
            Divider(height: 1, color: divider),
            // Options list
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: _Sort.values.asMap().entries.map((e) {
                    final sv = e.value;
                    final active = sv == sel;
                    return _Tap(
                      onTap: () => onSelect(sv),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 130),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 3),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 13),
                        decoration: BoxDecoration(
                          color: active ? violet.withOpacity(0.1) : chipC,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: active ? violet.withOpacity(0.45) : brd,
                              width: active ? 1.5 : 1),
                        ),
                        child: Row(children: [
                          Text(sv.label,
                              style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  fontWeight: active
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: active ? violet : txt)),
                          const Spacer(),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 130),
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: active ? violet : Colors.transparent,
                              border: Border.all(
                                  color:
                                      active ? violet : muted.withOpacity(0.4),
                                  width: active ? 0 : 1.5),
                            ),
                            child: active
                                ? Icon(Icons.check_rounded,
                                    size: 13, color: Colors.white)
                                : null,
                          ),
                        ]),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  UNIVERSE SHEET
// ─────────────────────────────────────────────
class _UniverseSheet extends StatefulWidget {
  final SupabaseClient db;
  final _Universe initUni;
  final String initSpec;
  final Color accent, chipC, brd, bg, divider, txt, sub, muted;
  final void Function(_Universe, String) onApply;

  const _UniverseSheet({
    required this.db,
    required this.initUni,
    required this.initSpec,
    required this.accent,
    required this.chipC,
    required this.brd,
    required this.bg,
    required this.divider,
    required this.txt,
    required this.sub,
    required this.muted,
    required this.onApply,
  });

  @override
  State<_UniverseSheet> createState() => _UniverseSheetState();
}

class _UniverseSheetState extends State<_UniverseSheet> {
  late _Universe _uni;
  late String _spec;
  final _ctrl = TextEditingController();
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _uni = widget.initUni;
    _spec = widget.initSpec;
    _ctrl.text = _spec;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    try {
      final res = await widget.db
          .from('option_chain')
          .select('underlying_symbol')
          .ilike('underlying_symbol', '%$q%')
          .limit(20);
      setState(() => _suggestions = (res as List)
          .map((e) => e['underlying_symbol'] as String)
          .toSet()
          .toList());
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.78),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Handle(w.sub),
              Text('Universe',
                  style: GoogleFonts.dmSans(
                      fontSize: 18, fontWeight: FontWeight.w800, color: w.txt)),
              const SizedBox(height: 4),
              Text('Which instruments to scan',
                  style: GoogleFonts.dmSans(fontSize: 13, color: w.sub)),
              const SizedBox(height: 16),
              Row(
                  children: _Universe.values.map((u) {
                final active = _uni == u;
                final isLast = u == _Universe.specific;
                return Expanded(
                    child: _Tap(
                  onTap: () => setState(() {
                    _uni = u;
                    if (u != _Universe.specific) _suggestions = [];
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: EdgeInsets.only(right: isLast ? 0 : 8),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: active ? w.accent.withOpacity(0.14) : w.chipC,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: active ? w.accent.withOpacity(0.5) : w.brd,
                          width: active ? 1.5 : 1),
                    ),
                    child: Column(children: [
                      Icon(u.icon, size: 18, color: active ? w.accent : w.sub),
                      const SizedBox(height: 5),
                      Text(u.label,
                          style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: active ? w.accent : w.sub)),
                    ]),
                  ),
                ));
              }).toList()),
              if (_uni == _Universe.specific) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _ctrl,
                  style: GoogleFonts.dmSans(fontSize: 14, color: w.txt),
                  decoration: InputDecoration(
                    hintText: 'e.g. RELIANCE, TCS, HDFC…',
                    hintStyle: GoogleFonts.dmSans(fontSize: 13, color: w.muted),
                    prefixIcon:
                        Icon(Icons.search_rounded, color: w.muted, size: 18),
                    filled: true,
                    fillColor: w.bg,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: w.brd)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: w.accent, width: 1.5)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: w.brd)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: _search,
                ),
                if (_suggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                        color: w.chipC,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: w.brd)),
                    child: Column(
                        children: _suggestions
                            .take(6)
                            .toList()
                            .asMap()
                            .entries
                            .map((e) {
                      final sym = e.value;
                      return Column(children: [
                        if (e.key > 0) Divider(height: 1, color: w.divider),
                        ListTile(
                          dense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 14),
                          onTap: () => setState(() {
                            _spec = sym;
                            _ctrl.text = sym;
                            _suggestions = [];
                          }),
                          leading: Icon(Icons.candlestick_chart_rounded,
                              color: w.accent, size: 15),
                          title: Text(sym,
                              style: GoogleFonts.spaceMono(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: w.txt)),
                          trailing: sym == _spec
                              ? Icon(Icons.check_rounded,
                                  color: w.accent, size: 16)
                              : null,
                        ),
                      ]);
                    }).toList()),
                  ),
              ],
              const SizedBox(height: 20),
              _PillBtn(
                  label: 'Apply',
                  color: w.accent,
                  onTap: () {
                    widget.onApply(
                        _uni, _uni == _Universe.specific ? _spec : '');
                    Navigator.pop(context);
                  }),
            ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  PICK DIALOG  (Type / Level)
// ─────────────────────────────────────────────
class _PickDialog extends StatelessWidget {
  final String title, sel;
  final List<String> opts;
  final Color color, surface, card, brd, txt, sub, muted, divider;
  final ValueChanged<String> onSelect;

  const _PickDialog({
    required this.title,
    required this.opts,
    required this.sel,
    required this.color,
    required this.surface,
    required this.card,
    required this.brd,
    required this.txt,
    required this.sub,
    required this.muted,
    required this.divider,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: brd),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
              child: Row(children: [
                Text(title,
                    style: GoogleFonts.dmSans(
                        fontSize: 17, fontWeight: FontWeight.w800, color: txt)),
                const Spacer(),
                _Tap(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                        color: muted.withOpacity(0.15), shape: BoxShape.circle),
                    child: Icon(Icons.close_rounded, size: 14, color: sub),
                  ),
                ),
              ]),
            ),
            Divider(height: 1, color: divider),
            // Options
            ...opts.asMap().entries.map((e) {
              final i = e.key;
              final o = e.value;
              final s = o == sel;
              return Column(children: [
                if (i > 0) Divider(height: 1, color: divider),
                _Tap(
                  onTap: () => onSelect(o),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 130),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 15),
                    color: s ? color.withOpacity(0.07) : Colors.transparent,
                    child: Row(children: [
                      Text(o,
                          style: GoogleFonts.dmSans(
                              fontSize: 15,
                              fontWeight: s ? FontWeight.w700 : FontWeight.w500,
                              color: s ? color : txt)),
                      const Spacer(),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 130),
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: s ? color : Colors.transparent,
                          border: Border.all(
                              color: s ? color : muted.withOpacity(0.4),
                              width: s ? 0 : 1.5),
                        ),
                        child: s
                            ? Icon(Icons.check_rounded,
                                size: 13, color: Colors.white)
                            : null,
                      ),
                    ]),
                  ),
                ),
              ]);
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SMALL SHARED WIDGETS
// ─────────────────────────────────────────────
class _Tag extends StatelessWidget {
  final String t;
  final Color c;
  const _Tag(this.t, this.c);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(
            color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
        child: Text(t,
            style: GoogleFonts.spaceMono(
                fontSize: 8, fontWeight: FontWeight.w800, color: c)),
      );
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final Color color, chipC, brd, sub;
  final IconData? icon;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label,
      required this.active,
      required this.color,
      required this.chipC,
      required this.brd,
      required this.sub,
      this.icon,
      required this.onTap});

  @override
  Widget build(BuildContext context) => _Tap(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: active ? color.withOpacity(0.12) : chipC,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: active ? color.withOpacity(0.45) : brd, width: 1.2),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: active ? color : sub),
              const SizedBox(width: 5)
            ],
            Text(label,
                style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: active ? color : sub)),
            const SizedBox(width: 3),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 13, color: active ? color : sub.withOpacity(0.6)),
          ]),
        ),
      );
}

class _PillBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _PillBtn(
      {required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => _Tap(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(13)),
          child: Center(
              child: Text(label,
                  style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white))),
        ),
      );
}

class _Handle extends StatelessWidget {
  final Color c;
  const _Handle(this.c);
  @override
  Widget build(BuildContext context) => Center(
        child: Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
                color: c.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2))),
      );
}

class _Slider2 extends StatelessWidget {
  final double v, min, max;
  final int? divisions;
  final Color color, track;
  final ValueChanged<double> onChange;
  const _Slider2(
      {required this.v,
      required this.min,
      required this.max,
      required this.color,
      required this.track,
      this.divisions,
      required this.onChange});
  @override
  Widget build(BuildContext context) => SliderTheme(
        data: SliderThemeData(
          trackHeight: 4,
          activeTrackColor: color,
          inactiveTrackColor: track,
          thumbColor: color,
          overlayColor: color.withOpacity(0.15),
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
          showValueIndicator: ShowValueIndicator.never,
        ),
        child: Slider(
            value: v.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChange),
      );
}

class _SecLabel extends StatelessWidget {
  final String t;
  final Color accent, sub;
  const _SecLabel(this.t, this.accent, this.sub);
  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
            width: 3,
            height: 14,
            color: accent,
            margin: const EdgeInsets.only(right: 8)),
        Text(t,
            style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: sub,
                letterSpacing: 0.5)),
      ]);
}

class _GreekBox extends StatelessWidget {
  final String l, v;
  final Color color, chipC, brd, sub, muted;
  const _GreekBox(
      this.l, this.v, this.color, this.chipC, this.brd, this.sub, this.muted);
  @override
  Widget build(BuildContext context) => Expanded(
          child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
            color: color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: color.withOpacity(0.2))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l, style: GoogleFonts.dmSans(fontSize: 11, color: muted)),
          const SizedBox(height: 4),
          Text(v,
              style: GoogleFonts.spaceMono(
                  fontSize: 14, fontWeight: FontWeight.w700, color: color)),
        ]),
      ));
}

class _M {
  final String l, v;
  final Color c;
  const _M(this.l, this.v, this.c);
}

class _MetricGrid2 extends StatelessWidget {
  final List<_M> items;
  final Color chipC, brd, txt, sub, muted;
  const _MetricGrid2(
      this.items, this.chipC, this.brd, this.txt, this.sub, this.muted);

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (int i = 0; i < items.length; i += 2) {
      final a = items[i];
      final b = i + 1 < items.length ? items[i + 1] : null;
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Expanded(child: _cell(a)),
          if (b != null) ...[
            const SizedBox(width: 8),
            Expanded(child: _cell(b))
          ],
        ]),
      ));
    }
    return Column(children: rows);
  }

  Widget _cell(_M m) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
            color: chipC,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: brd)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(m.l, style: GoogleFonts.dmSans(fontSize: 10, color: muted)),
          const SizedBox(height: 3),
          Text(m.v,
              style: GoogleFonts.spaceMono(
                  fontSize: 13, fontWeight: FontWeight.w700, color: m.c)),
        ]),
      );
}

class _PopBar2 extends StatelessWidget {
  final double pop;
  final Color green, red, chipC, brd, sub, muted, divider;
  const _PopBar2(this.pop, this.green, this.red, this.chipC, this.brd, this.sub,
      this.muted, this.divider);

  @override
  Widget build(BuildContext context) {
    final c = pop > 50 ? green : red;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: chipC,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: brd)),
      child: Column(children: [
        Row(children: [
          Text('${pop.toStringAsFixed(1)}%',
              style: GoogleFonts.spaceMono(
                  fontSize: 24, fontWeight: FontWeight.w800, color: c)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: c.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8)),
            child: Text(pop > 50 ? 'Favourable' : 'Unfavourable',
                style: GoogleFonts.dmSans(
                    fontSize: 12, fontWeight: FontWeight.w700, color: c)),
          ),
        ]),
        const SizedBox(height: 12),
        ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
                value: pop.clamp(0.0, 100.0) / 100.0,
                minHeight: 8,
                backgroundColor: divider,
                valueColor: AlwaysStoppedAnimation(c))),
      ]),
    );
  }
}

// Tap scale (spring press)
class _Tap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _Tap({required this.child, this.onTap});
  @override
  State<_Tap> createState() => _TapState();
}

class _TapState extends State<_Tap> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _s;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 85));
    _s = Tween<double>(begin: 1.0, end: 0.94)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: widget.onTap != null ? (_) => _c.forward() : null,
        onTapUp: widget.onTap != null
            ? (_) {
                _c.reverse();
                widget.onTap!();
              }
            : null,
        onTapCancel: () => _c.reverse(),
        child: ScaleTransition(scale: _s, child: widget.child),
      );
}

// Shimmer
class _ShimmerTile extends StatefulWidget {
  final bool dk;
  const _ShimmerTile({required this.dk});
  @override
  State<_ShimmerTile> createState() => _ShimmerTileState();
}

class _ShimmerTileState extends State<_ShimmerTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();
    _a = Tween<double>(begin: -1.5, end: 1.5)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.dk ? const Color(0xFF111520) : const Color(0xFFECF2FA);
    final hi = widget.dk ? const Color(0xFF1C2538) : const Color(0xFFF5F9FF);
    return AnimatedBuilder(
      animation: _a,
      builder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 7),
        height: 66,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            gradient: LinearGradient(
                begin: Alignment(_a.value - 1, 0),
                end: Alignment(_a.value + 1, 0),
                colors: [base, hi, base])),
      ),
    );
  }
}
