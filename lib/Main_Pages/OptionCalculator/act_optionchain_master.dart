import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:optionxi/Helpers/analytics_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────
//  THEME TOKENS
// ─────────────────────────────────────────────
class _Dark {
  static const bg = Color(0xFF08090D);
  static const surface = Color(0xFF0F1117);
  static const card = Color(0xFF161B25);
  static const cardBorder = Color(0xFF222840);
  static const accent = Color(0xFF00D4FF);
  static const accentGreen = Color(0xFF00E699);
  static const accentRed = Color(0xFFFF4D6A);
  static const accentOrange = Color(0xFFFFAB40);
  static const text = Color(0xFFEEF2FF);
  static const textSub = Color(0xFF8892A4);
  static const textMuted = Color(0xFF3D4A60);
  static const divider = Color(0xFF1A2035);
  static const chipBg = Color(0xFF161C2C);
  static const rowOdd = Color(0xFF0F1117);
  static const rowEven = Color(0xFF0B0D13);
  static const rowAtm = Color(0xFF1A1400);
  static const rowAtmBorder = Color(0xFFFFAB40);
}

class _Light {
  static const bg = Color(0xFFF2F5FA);
  static const surface = Color(0xFFFFFFFF);
  static const card = Color(0xFFFFFFFF);
  static const cardBorder = Color(0xFFDDE3EF);
  static const accent = Color(0xFF0098CC);
  static const accentGreen = Color(0xFF00A86B);
  static const accentRed = Color(0xFFE63355);
  static const accentOrange = Color(0xFFE07B00);
  static const text = Color(0xFF0F172A);
  static const textSub = Color(0xFF4A5A7A);
  static const textMuted = Color(0xFF94A3B8);
  static const divider = Color(0xFFE4EAF4);
  static const chipBg = Color(0xFFEEF4FF);
  static const rowOdd = Color(0xFFFFFFFF);
  static const rowEven = Color(0xFFF8FAFD);
  static const rowAtm = Color(0xFFFFFAEB);
  static const rowAtmBorder = Color(0xFFE07B00);
}

// ─────────────────────────────────────────────
//  MODEL
// ─────────────────────────────────────────────
class _ChainRow {
  final String symbol;
  final String optionType;
  final DateTime expiry;
  final double strike;
  final double spot;
  final double ltp;
  final double volume;
  final double oi;
  final double oiChange;
  final double iv;
  final double delta;
  final double gamma;
  final double theta;
  final double vega;
  final double pop;
  final double bidPrice;
  final double askPrice;
  final bool isAtm;
  final bool isItm;
  final bool isOtm;
  final String strikeLevel;
  final int strikesFromAtm;
  final double pcr;
  final int lotSize;
  final DateTime? fetchedAt;

  _ChainRow({
    required this.symbol,
    required this.optionType,
    required this.expiry,
    required this.strike,
    required this.spot,
    required this.ltp,
    required this.volume,
    required this.oi,
    required this.oiChange,
    required this.iv,
    required this.delta,
    required this.gamma,
    required this.theta,
    required this.vega,
    required this.pop,
    required this.bidPrice,
    required this.askPrice,
    required this.isAtm,
    required this.isItm,
    required this.isOtm,
    required this.strikeLevel,
    required this.strikesFromAtm,
    required this.pcr,
    required this.lotSize,
    this.fetchedAt,
  });

  factory _ChainRow.fromMap(Map<String, dynamic> m) => _ChainRow(
        symbol: m['underlying_symbol'] ?? '',
        optionType: (m['option_type'] as String?)?.trim() ?? '',
        expiry: DateTime.tryParse(m['expiry_date'] ?? '') ?? DateTime.now(),
        strike: (m['strike_price'] as num?)?.toDouble() ?? 0,
        spot: (m['spot_price'] as num?)?.toDouble() ?? 0,
        ltp: (m['ltp'] as num?)?.toDouble() ?? 0,
        volume: (m['volume'] as num?)?.toDouble() ?? 0,
        oi: (m['oi'] as num?)?.toDouble() ?? 0,
        oiChange: (m['oi_change'] as num?)?.toDouble() ?? 0,
        iv: (m['iv'] as num?)?.toDouble() ?? 0,
        delta: (m['delta'] as num?)?.toDouble() ?? 0,
        gamma: (m['gamma'] as num?)?.toDouble() ?? 0,
        theta: (m['theta'] as num?)?.toDouble() ?? 0,
        vega: (m['vega'] as num?)?.toDouble() ?? 0,
        pop: (m['pop'] as num?)?.toDouble() ?? 0,
        bidPrice: (m['bid_price'] as num?)?.toDouble() ?? 0,
        askPrice: (m['ask_price'] as num?)?.toDouble() ?? 0,
        isAtm: m['is_atm'] ?? false,
        isItm: m['is_itm'] ?? false,
        isOtm: m['is_otm'] ?? false,
        strikeLevel: (m['strike_level'] as String?)?.trim() ?? '',
        strikesFromAtm: (m['strikes_from_atm'] as int?) ?? 0,
        pcr: (m['pcr'] as num?)?.toDouble() ?? 0,
        lotSize: (m['lot_size'] as int?) ?? 1,
        fetchedAt: m['fetched_at'] != null
            ? DateTime.tryParse(m['fetched_at'].toString())?.toLocal()
            : null,
      );

  double get lotCost => ltp * lotSize;
}

class _StrikePair {
  final double strike;
  final bool isAtm;
  final _ChainRow? call;
  final _ChainRow? put;
  _StrikePair({required this.strike, required this.isAtm, this.call, this.put});

  double get pcr => put?.pcr ?? call?.pcr ?? 0;
  int get lotSize => call?.lotSize ?? put?.lotSize ?? 1;
  double get callLotCost => (call?.ltp ?? 0) * lotSize;
  double get putLotCost => (put?.ltp ?? 0) * lotSize;
  DateTime? get updatedAt => call?.fetchedAt ?? put?.fetchedAt;
}

// ─────────────────────────────────────────────
//  PAGE
// ─────────────────────────────────────────────
class OptionChainPage extends StatefulWidget {
  const OptionChainPage({super.key});

  @override
  State<OptionChainPage> createState() => _OptionChainPageState();
}

class _OptionChainPageState extends State<OptionChainPage>
    with SingleTickerProviderStateMixin {
  // ── theme helpers ──────────────────────────
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bg => _isDark ? _Dark.bg : _Light.bg;
  Color get _surface => _isDark ? _Dark.surface : _Light.surface;
  Color get _card => _isDark ? _Dark.card : _Light.card;
  Color get _cardBorder => _isDark ? _Dark.cardBorder : _Light.cardBorder;
  Color get _accent => _isDark ? _Dark.accent : _Light.accent;
  Color get _green => _isDark ? _Dark.accentGreen : _Light.accentGreen;
  Color get _red => _isDark ? _Dark.accentRed : _Light.accentRed;
  Color get _orange => _isDark ? _Dark.accentOrange : _Light.accentOrange;
  Color get _text => _isDark ? _Dark.text : _Light.text;
  Color get _textSub => _isDark ? _Dark.textSub : _Light.textSub;
  Color get _textMuted => _isDark ? _Dark.textMuted : _Light.textMuted;
  Color get _divider => _isDark ? _Dark.divider : _Light.divider;
  Color get _chipBg => _isDark ? _Dark.chipBg : _Light.chipBg;

  // ── data ───────────────────────────────────
  final _db = Supabase.instance.client;
  String _symbol = 'NIFTY';
  String _selectedExpiry = '';
  List<String> _expiryList = [];
  bool _showGreeks = false;
  bool _loading = false;
  String? _error;
  List<_ChainRow> _rows = [];
  List<_StrikePair> _pairs = [];
  List<_StrikePair> _filteredPairs = [];
  double _spotPrice = 0;
  double _overallPcr = 0;

  // ── fetch config ────────────────────────────
  // How many strikes either side of ATM to fetch from the DB.
  // 50 means fetch ATM-50…ATM+50 strikes (i.e. 101 strikes max).
  static const int _strikesRadius = 50;

  // ── budget filter ───────────────────────────
  final _budgetCtrl = TextEditingController();
  double? _budgetAmount;
  bool _budgetActive = false;

  // ── search ─────────────────────────────────
  final _searchCtrl = TextEditingController();
  final _searchFocusNode = FocusNode(); // ADD THIS
  List<String> _searchResults = [];
  final List<String> _predefined = [
    'NIFTY',
    'BANKNIFTY',
    'FINNIFTY',
    'MIDCPNIFTY',
  ];

  // ── scroll controllers ─────────────────────
  final _vertScrollCtrl = ScrollController();
  final _stickyVertScrollCtrl = ScrollController();
  final _hScrollCtrl = ScrollController();
  final _hHeaderScrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _hScrollCtrl.addListener(() {
      if (_hHeaderScrollCtrl.hasClients &&
          _hHeaderScrollCtrl.offset != _hScrollCtrl.offset) {
        _hHeaderScrollCtrl.jumpTo(_hScrollCtrl.offset);
      }
    });
    _vertScrollCtrl.addListener(() {
      if (_stickyVertScrollCtrl.hasClients &&
          _stickyVertScrollCtrl.offset != _vertScrollCtrl.offset) {
        _stickyVertScrollCtrl.jumpTo(_vertScrollCtrl.offset);
      }
    });

    // ADD THIS: Listen to focus changes on the search bar
    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus && _searchCtrl.text.isEmpty) {
        setState(() => _searchResults = _predefined);
      } else if (!_searchFocusNode.hasFocus && _searchCtrl.text.isEmpty) {
        // Clear results if they tap away without typing anything
        setState(() => _searchResults = []);
      }
    });

    // Call our welcome setup dialog once the initial frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showWelcomeSetupDialog();
    });

    _fetchChain();
    AnalyticsHelper.logScreen('optionchain_master',
        screenClass: "OptionChainPage");
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocusNode.dispose(); // ADD THIS
    _budgetCtrl.dispose();
    _vertScrollCtrl.dispose();
    _stickyVertScrollCtrl.dispose();
    _hScrollCtrl.dispose();
    _hHeaderScrollCtrl.dispose();
    super.dispose();
  }

  // ── column config ──────────────────────────
  static const _ceColsGreeks = [
    ('PoP', 50.0),
    ('Θ', 56.0),
    ('Γ', 50.0),
    ('Δ', 52.0),
    ('IV%', 54.0),
    ('Vol', 62.0),
    ('OI', 66.0),
    ('LTP', 70.0),
  ];
  static const _ceColsBasic = [
    ('PoP', 50.0),
    ('IV%', 54.0),
    ('Vol', 62.0),
    ('OI', 66.0),
    ('LTP', 70.0),
  ];
  static const _peColsGreeks = [
    ('LTP', 70.0),
    ('OI', 66.0),
    ('Vol', 62.0),
    ('IV%', 54.0),
    ('Δ', 52.0),
    ('Γ', 50.0),
    ('Θ', 56.0),
    ('PoP', 50.0),
  ];
  static const _peColsBasic = [
    ('LTP', 70.0),
    ('OI', 66.0),
    ('Vol', 62.0),
    ('IV%', 54.0),
    ('PoP', 50.0),
  ];

  static const double _strikePinW = 82.0;
  static const double _rowH = 52.0;
  static const double _headerH = 28.0;

  List<(String, double)> get _ceCols =>
      _showGreeks ? _ceColsGreeks.toList() : _ceColsBasic.toList();
  List<(String, double)> get _peCols =>
      _showGreeks ? _peColsGreeks.toList() : _peColsBasic.toList();

  double _colsW(List<(String, double)> cols) =>
      cols.fold(0.0, (s, c) => s + c.$2);

  // ─────────────────────────────────────────────────────────────────────────
  //  FETCH — optimised: meta query first, then targeted strike-range fetch
  // ─────────────────────────────────────────────────────────────────────────

  /// Full fetch: called on symbol change or refresh.
  /// 1. Lightweight meta query → spot price + expiry list.
  /// 2. 2-row query → infer strike step (50 / 100 / 200 …).
  /// 3. Targeted fetch → only ±_strikesRadius strikes around ATM for the
  ///    selected expiry.
  Future<void> _fetchChain() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // ── Step 1: meta — spot + distinct expiry dates ────────────────
      // We fetch a small slice (200 rows) that covers all expiry dates
      // without pulling the full chain payload.
      final metaRes = await _db
          .from('option_chain')
          .select('spot_price, expiry_date')
          .eq('underlying_symbol', _symbol)
          .order('expiry_date', ascending: true)
          .limit(200);

      if ((metaRes as List).isEmpty) {
        setState(() {
          _rows = [];
          _pairs = [];
          _filteredPairs = [];
          _expiryList = [];
          _spotPrice = 0;
          _loading = false;
        });
        return;
      }

      final spot = (metaRes.first['spot_price'] as num?)?.toDouble() ?? 0;

      final expirySet = <String>{};
      for (final r in metaRes) {
        final d = DateTime.tryParse(r['expiry_date'] ?? '');
        if (d != null) expirySet.add(_fmtDate(d));
      }
      final expiries = expirySet.toList()..sort();

      if (_selectedExpiry.isEmpty || !expiries.contains(_selectedExpiry)) {
        _selectedExpiry = expiries.isNotEmpty ? expiries.first : '';
      }

      setState(() {
        _spotPrice = spot;
        _expiryList = expiries;
      });

      if (_selectedExpiry.isEmpty) {
        setState(() => _loading = false);
        return;
      }

      // ── Step 2: infer strike step from 2 rows ─────────────────────
      final stepRes = await _db
          .from('option_chain')
          .select('strike_price')
          .eq('underlying_symbol', _symbol)
          .eq('expiry_date', _expiryDateString(_selectedExpiry))
          .order('strike_price', ascending: true)
          .limit(2);

      double strikeStep = 50;
      if ((stepRes as List).length >= 2) {
        final s0 = (stepRes[0]['strike_price'] as num).toDouble();
        final s1 = (stepRes[1]['strike_price'] as num).toDouble();
        final diff = (s1 - s0).abs();
        if (diff > 0) strikeStep = diff;
      }

      // ── Step 3: targeted chain fetch ──────────────────────────────
      final rows = await _fetchStrikeRange(
        expiry: _selectedExpiry,
        spot: spot,
        strikeStep: strikeStep,
      );

      setState(() => _rows = rows);
      _buildPairs();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  /// Fetches only when the user taps a different expiry chip.
  /// Reuses the already-known spot price and infers strike step from
  /// currently loaded rows — no extra meta queries needed.
  Future<void> _fetchForExpiry(String expiry) async {
    setState(() {
      _selectedExpiry = expiry;
      _loading = true;
      _error = null;
    });
    try {
      final strikeStep = _inferStrikeStep();
      final rows = await _fetchStrikeRange(
        expiry: expiry,
        spot: _spotPrice,
        strikeStep: strikeStep,
      );
      setState(() => _rows = rows);
      _buildPairs();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  /// Core targeted query: fetches ATM ± (_strikesRadius * strikeStep) for
  /// the given expiry. Postgres filters strike_price server-side so only
  /// ~100 rows travel over the wire.
  Future<List<_ChainRow>> _fetchStrikeRange({
    required String expiry,
    required double spot,
    required double strikeStep,
  }) async {
    final atm = (spot / strikeStep).round() * strikeStep;
    final lo = atm - (_strikesRadius * strikeStep);
    final hi = atm + (_strikesRadius * strikeStep);

    final res = await _db
        .from('option_chain')
        .select()
        .eq('underlying_symbol', _symbol)
        .eq('expiry_date', _expiryDateString(expiry))
        .gte('strike_price', lo)
        .lte('strike_price', hi)
        .order('strike_price', ascending: true);

    return (res as List).map((e) => _ChainRow.fromMap(e)).toList();
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  /// Convert display format "24-Jul-2025" → "2025-07-24" for Supabase queries.
  String _expiryDateString(String display) {
    final parts = display.split('-');
    if (parts.length != 3) return display;
    const months = {
      'Jan': '01',
      'Feb': '02',
      'Mar': '03',
      'Apr': '04',
      'May': '05',
      'Jun': '06',
      'Jul': '07',
      'Aug': '08',
      'Sep': '09',
      'Oct': '10',
      'Nov': '11',
      'Dec': '12',
    };
    final mm = months[parts[1]] ?? '01';
    return '${parts[2]}-$mm-${parts[0].padLeft(2, '0')}';
  }

  /// Infer strike step from currently loaded rows — avoids an extra DB call
  /// when switching expiries.
  double _inferStrikeStep() {
    final strikes = _rows.map((r) => r.strike).toSet().toList()..sort();
    if (strikes.length >= 2) {
      final step = (strikes[1] - strikes[0]).abs();
      if (step > 0) return step;
    }
    return 50.0;
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  BUILD PAIRS (client-side grouping of already-fetched rows)
  // ─────────────────────────────────────────────────────────────────────────
  void _buildPairs() {
    // _rows already contains only the selected expiry's strike range —
    // no need to filter by expiry date here.
    final strikeSet = _rows.map((r) => r.strike).toSet().toList()..sort();

    double? atmStrike;
    if (_spotPrice > 0 && strikeSet.isNotEmpty) {
      atmStrike = strikeSet.reduce(
          (a, b) => (a - _spotPrice).abs() < (b - _spotPrice).abs() ? a : b);
    }

    final pairs = <_StrikePair>[];
    for (final s in strikeSet) {
      final calls = _rows.where((r) => r.strike == s && r.optionType == 'CE');
      final puts = _rows.where((r) => r.strike == s && r.optionType == 'PE');
      final isAtm = atmStrike != null && s == atmStrike;
      pairs.add(_StrikePair(
        strike: s,
        isAtm: isAtm,
        call: calls.isNotEmpty ? calls.first : null,
        put: puts.isNotEmpty ? puts.first : null,
      ));
    }

    double totalCallOI = 0, totalPutOI = 0;
    for (final p in pairs) {
      totalCallOI += p.call?.oi ?? 0;
      totalPutOI += p.put?.oi ?? 0;
    }
    final overallPcr = totalCallOI > 0 ? totalPutOI / totalCallOI : 0.0;

    setState(() {
      _pairs = pairs;
      _filteredPairs = pairs;
      _overallPcr = overallPcr;
    });

    _applyBudgetFilter();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToAtm());
  }

  void _applyBudgetFilter() {
    if (!_budgetActive || _budgetAmount == null || _budgetAmount! <= 0) {
      setState(() => _filteredPairs = _pairs);
      return;
    }
    final budget = _budgetAmount!;

    final callsSorted = _pairs
        .where((p) => p.call != null && p.callLotCost > 0)
        .toList()
      ..sort((a, b) => (a.callLotCost - budget)
          .abs()
          .compareTo((b.callLotCost - budget).abs()));
    final putsSorted = _pairs
        .where((p) => p.put != null && p.putLotCost > 0)
        .toList()
      ..sort((a, b) => (a.putLotCost - budget)
          .abs()
          .compareTo((b.putLotCost - budget).abs()));

    final top3Calls = callsSorted.take(3).map((p) => p.strike).toSet();
    final top3Puts = putsSorted.take(3).map((p) => p.strike).toSet();
    final relevantStrikes = {...top3Calls, ...top3Puts};

    setState(() {
      _filteredPairs =
          _pairs.where((p) => relevantStrikes.contains(p.strike)).toList();
    });
  }

  void _scrollToAtm() {
    final atmIdx = _filteredPairs.indexWhere((p) => p.isAtm);
    if (atmIdx < 0 || !_vertScrollCtrl.hasClients) return;
    final target = (atmIdx * _rowH) -
        (_vertScrollCtrl.position.viewportDimension / 2) +
        _rowH / 2;
    _vertScrollCtrl.animateTo(
      target.clamp(0.0, _vertScrollCtrl.position.maxScrollExtent),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  // ── formatting ──────────────────────────────
  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-${_month(d.month)}-${d.year}';
  String _month(int m) => const [
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

  String _fmtOI(double v) {
    if (v >= 1e7) return '${(v / 1e7).toStringAsFixed(1)}Cr';
    if (v >= 1e5) return '${(v / 1e5).toStringAsFixed(1)}L';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  String _fmtMoney(double v) {
    if (v >= 1e7) return '₹${(v / 1e7).toStringAsFixed(2)}Cr';
    if (v >= 1e5) return '₹${(v / 1e5).toStringAsFixed(2)}L';
    if (v >= 1e3) return '₹${(v / 1e3).toStringAsFixed(1)}K';
    return '₹${v.toStringAsFixed(0)}';
  }

  // ── search ──────────────────────────────────
  Future<void> _searchSymbols(String q) async {
    if (q.trim().isEmpty) {
      // CHANGED: Revert to predefined defaults instead of an empty array
      setState(() => _searchResults = _predefined);
      return;
    }
    try {
      final res = await _db
          .from('option_chain')
          .select('underlying_symbol')
          .ilike('underlying_symbol', '%$q%')
          .limit(20);
      final symbols = (res as List)
          .map((e) => e['underlying_symbol'] as String)
          .toSet()
          .toList();
      setState(() => _searchResults = symbols);
    } catch (_) {}
  }

  void _selectSymbol(String s) {
    setState(() {
      _symbol = s;
      _selectedExpiry = '';
      _searchCtrl.clear();
      _searchResults = [];
    });
    _fetchChain();
  }

  void _clearBudget() {
    setState(() {
      _budgetActive = false;
      _budgetAmount = null;
      _budgetCtrl.clear();
      _filteredPairs = _pairs;
    });
  }

  // ── cell value helpers ──────────────────────
  String _ceVal(String col, _ChainRow? r) {
    if (r == null) return '—';
    switch (col) {
      case 'LTP':
        return r.ltp.toStringAsFixed(2);
      case 'OI':
        return _fmtOI(r.oi);
      case 'Vol':
        return _fmtOI(r.volume);
      case 'IV%':
        return '${r.iv.toStringAsFixed(1)}%';
      case 'PoP':
        return '${r.pop.toStringAsFixed(0)}%';
      case 'Δ':
        return r.delta.toStringAsFixed(3);
      case 'Γ':
        return r.gamma.toStringAsFixed(4);
      case 'Θ':
        return r.theta.toStringAsFixed(2);
      default:
        return '—';
    }
  }

  String _peVal(String col, _ChainRow? r) {
    if (r == null) return '—';
    switch (col) {
      case 'LTP':
        return r.ltp.toStringAsFixed(2);
      case 'OI':
        return _fmtOI(r.oi);
      case 'Vol':
        return _fmtOI(r.volume);
      case 'IV%':
        return '${r.iv.toStringAsFixed(1)}%';
      case 'PoP':
        return '${r.pop.toStringAsFixed(0)}%';
      case 'Δ':
        return r.delta.abs().toStringAsFixed(3);
      case 'Γ':
        return r.gamma.toStringAsFixed(4);
      case 'Θ':
        return r.theta.toStringAsFixed(2);
      default:
        return '—';
    }
  }

  Color _ceColor(String col) {
    switch (col) {
      case 'LTP':
        return _green;
      case 'IV%':
        return _orange;
      case 'PoP':
        return _accent;
      case 'Δ':
        return _accent;
      case 'Θ':
        return _red.withOpacity(0.85);
      default:
        return _textSub;
    }
  }

  Color _peColor(String col) {
    switch (col) {
      case 'LTP':
        return _red;
      case 'IV%':
        return _orange;
      case 'PoP':
        return _accent;
      case 'Δ':
        return _accent;
      case 'Θ':
        return _red.withOpacity(0.85);
      default:
        return _textSub;
    }
  }

  Color _pcrColor(double pcr) {
    if (pcr > 1.2) return _green;
    if (pcr < 0.8) return _red;
    return _orange;
  }

  String _pcrSentiment(double pcr) {
    if (pcr > 1.5) return 'Very Bullish';
    if (pcr > 1.2) return 'Bullish';
    if (pcr > 0.8) return 'Neutral';
    if (pcr > 0.5) return 'Bearish';
    return 'Very Bearish';
  }

  // ── WELCOME SETUP DIALOG ───────────────────────────
  // ── WELCOME SETUP DIALOG ───────────────────────────
  void _showWelcomeSetupDialog() {
    String tempSymbol = _symbol;
    final tempBudgetCtrl = TextEditingController(text: _budgetCtrl.text);
    bool tempShowGreeks = _showGreeks;

    showModalBottomSheet(
      context: context,
      backgroundColor: _card,
      isScrollControlled: true,
      isDismissible: true, // Changed: Allows dismissing on outside click
      enableDrag: true, // Changed: Allows dragging down to dismiss
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(_).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome to Options!',
                    style: GoogleFonts.dmSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _text)),
                const SizedBox(height: 8),
                Text(
                    'Let\'s quickly set up your view. Choose the asset you want to track, and optionally set a budget to only see options you can afford.',
                    style: GoogleFonts.dmSans(
                        fontSize: 13, color: _textSub, height: 1.4)),
                const SizedBox(height: 24),
                Text('1. Select an Asset',
                    style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _text)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _predefined.map((s) {
                    final sel = s == tempSymbol;
                    return GestureDetector(
                      onTap: () => setSheetState(() => tempSymbol = s),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel ? _accent.withOpacity(0.12) : _bg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color:
                                  sel ? _accent.withOpacity(0.6) : _cardBorder),
                        ),
                        child: Text(s,
                            style: GoogleFonts.spaceMono(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: sel ? _accent : _textSub)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // NEW: Stock Search Redirect
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context); // Close dialog
                    _searchFocusNode.requestFocus(); // Focus main search bar
                  },
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded, color: _accent, size: 16),
                      const SizedBox(width: 8),
                      Text('Or search for a specific stock...',
                          style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _accent)),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                Text('2. Set Max Budget / Lot (Optional)',
                    style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _text)),
                const SizedBox(height: 8),
                TextField(
                  controller: tempBudgetCtrl,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.spaceMono(
                      fontSize: 16, color: _text, fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    hintText: 'e.g. 5000',
                    hintStyle:
                        GoogleFonts.spaceMono(fontSize: 14, color: _textMuted),
                    prefixText: '₹ ',
                    prefixStyle: GoogleFonts.spaceMono(
                        fontSize: 16,
                        color: _accent,
                        fontWeight: FontWeight.w700),
                    filled: true,
                    fillColor: _bg,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _cardBorder)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _accent, width: 1.5)),
                  ),
                ),
                const SizedBox(height: 24),

                // NEW: Greeks Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('3. Show Option Greeks (Δ, Γ, Θ, ν)',
                        style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _text)),
                    Switch(
                      value: tempShowGreeks,
                      onChanged: (val) =>
                          setSheetState(() => tempShowGreeks = val),
                      activeColor: _accent,
                      activeTrackColor: _accent.withOpacity(0.3),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);

                      // Apply symbol if changed
                      if (tempSymbol != _symbol) {
                        _selectSymbol(tempSymbol);
                      }

                      // Apply Greeks setting
                      if (tempShowGreeks != _showGreeks) {
                        setState(() => _showGreeks = tempShowGreeks);
                      }

                      // Apply budget
                      final val = double.tryParse(tempBudgetCtrl.text);
                      if (val != null && val > 0) {
                        setState(() {
                          _budgetAmount = val;
                          _budgetActive = true;
                          _budgetCtrl.text = tempBudgetCtrl.text;
                        });
                        _applyBudgetFilter();
                      } else {
                        _clearBudget();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    child: Text('Get Started',
                        style: GoogleFonts.dmSans(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── build ───────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSubBar(),
            _buildSpotBanner(),
            Expanded(
              child: _loading
                  ? _buildShimmer()
                  : _error != null
                      ? _buildError()
                      : _filteredPairs.isEmpty
                          ? _buildEmpty()
                          : _buildChainTable(),
            ),
          ],
        ),
      ),
    );
  }

  // ── HEADER ──────────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        border: Border(bottom: BorderSide(color: _divider, width: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 10, 0),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  height: 36,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: Icon(Icons.arrow_back_ios_new_rounded,
                        color: _textSub, size: 16),
                    padding: EdgeInsets.zero,
                    splashRadius: 18,
                  ),
                ),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('Option Chain',
                          style: GoogleFonts.dmSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: _text,
                              letterSpacing: -0.2)),
                      const SizedBox(width: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: _accent.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: _accent.withOpacity(0.25)),
                        ),
                        child: Text(_symbol,
                            style: GoogleFonts.spaceMono(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _accent)),
                      ),
                    ],
                  ),
                ),
                _iconToggleBtn(
                  label: 'Δ Greeks',
                  active: _showGreeks,
                  activeColor: _orange,
                  onTap: () => setState(() => _showGreeks = !_showGreeks),
                ),
                const SizedBox(width: 5),
                GestureDetector(
                  onTap: _fetchChain,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _chipBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _cardBorder),
                    ),
                    child: Icon(Icons.refresh_rounded,
                        color: _textMuted, size: 15),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: _buildSearchBar(),
          ),
          if (_searchResults.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: _buildSearchResults(),
            ),
          const SizedBox(height: 8),
          SizedBox(
            height: 30,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: _predefined.length,
              itemBuilder: (_, i) {
                final s = _predefined[i];
                final sel = s == _symbol;
                return GestureDetector(
                  onTap: () => _selectSymbol(s),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 7),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color:
                          sel ? _accent.withOpacity(0.12) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: sel ? _accent.withOpacity(0.4) : _cardBorder),
                    ),
                    child: Text(s,
                        style: GoogleFonts.spaceMono(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: sel ? _accent : _textSub)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _iconToggleBtn({
    required String label,
    required bool active,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          color: active ? activeColor.withOpacity(0.12) : _chipBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: active ? activeColor.withOpacity(0.4) : _cardBorder),
        ),
        child: Center(
          child: Text(label,
              style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: active ? activeColor : _textMuted)),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchCtrl,
            focusNode: _searchFocusNode, // ADD THIS
            style: GoogleFonts.dmSans(fontSize: 13, color: _text),
            decoration: InputDecoration(
              hintText: _budgetActive
                  ? 'Search symbol…'
                  : 'Search symbol  (e.g. RELIANCE, INFY)…',
              hintStyle: GoogleFonts.dmSans(fontSize: 12, color: _textMuted),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 10, right: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search_rounded, color: _textMuted, size: 16),
                    if (_budgetActive) ...[
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: _clearBudget,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: _accent.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(5),
                            border:
                                Border.all(color: _accent.withOpacity(0.35)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_fmtMoney(_budgetAmount ?? 0),
                                  style: GoogleFonts.spaceMono(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: _accent)),
                              const SizedBox(width: 4),
                              Icon(Icons.close_rounded,
                                  color: _accent, size: 11),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 0, minHeight: 0),
              // Update this specific block inside your TextField decoration
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        _searchCtrl.clear();
                        // CHANGED: Revert to defaults instead of clearing array
                        setState(() => _searchResults = _predefined);
                      },
                      child: Icon(Icons.close_rounded,
                          color: _textMuted, size: 16),
                    )
                  : null,
              filled: true,
              fillColor: _bg,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: _cardBorder)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: _cardBorder)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: _accent, width: 1.5)),
              isDense: true,
            ),
            onChanged: _searchSymbols,
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _showBudgetDialog,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: _budgetActive ? _accent.withOpacity(0.12) : _chipBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color:
                      _budgetActive ? _accent.withOpacity(0.4) : _cardBorder),
            ),
            child: Center(
              child: Text('₹ Budget',
                  style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: _budgetActive ? _accent : _textMuted)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    return Container(
      // 1. Add constraints to limit the maximum height of the dropdown
      constraints: const BoxConstraints(maxHeight: 250),
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      // 2. Wrap the Column in a SingleChildScrollView
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min, // 3. Keep it compact
          children: _searchResults.asMap().entries.map((entry) {
            final i = entry.key;
            final s = entry.value;
            return Column(
              children: [
                if (i > 0) Divider(height: 1, color: _divider),
                ListTile(
                  dense: true,
                  onTap: () => _selectSymbol(s),
                  leading: Icon(Icons.candlestick_chart_rounded,
                      color: _accent, size: 15),
                  title: Text(s,
                      style: GoogleFonts.spaceMono(
                          color: _text,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                  trailing: Icon(Icons.north_east_rounded,
                      size: 13, color: _textMuted),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── BUDGET DIALOG ───────────────────────────
  void _showBudgetDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(_).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 32,
                height: 3,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: _textMuted.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text('Budget Filter',
                style: GoogleFonts.dmSans(
                    fontSize: 16, fontWeight: FontWeight.w700, color: _text)),
            const SizedBox(height: 4),
            Text(
                'Enter your budget. We\'ll show the 3 closest CE & PE strikes by lot cost.',
                style: GoogleFonts.dmSans(fontSize: 12, color: _textSub)),
            const SizedBox(height: 16),
            TextField(
              controller: _budgetCtrl,
              keyboardType: TextInputType.number,
              style: GoogleFonts.spaceMono(
                  fontSize: 18, color: _text, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                hintText: 'e.g. 8000',
                hintStyle:
                    GoogleFonts.spaceMono(fontSize: 16, color: _textMuted),
                prefixText: '₹ ',
                prefixStyle: GoogleFonts.spaceMono(
                    fontSize: 18, color: _accent, fontWeight: FontWeight.w700),
                filled: true,
                fillColor: _bg,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _cardBorder)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _accent, width: 1.5)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _clearBudget();
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                        side: BorderSide(color: _cardBorder),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10))),
                    child: Text('Clear',
                        style: GoogleFonts.dmSans(color: _textSub)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final val = double.tryParse(_budgetCtrl.text);
                      setState(() {
                        _budgetAmount = val;
                        _budgetActive = val != null && val > 0;
                      });
                      _applyBudgetFilter();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10))),
                    child: Text('Apply',
                        style: GoogleFonts.dmSans(
                            color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── EXPIRY SUB BAR ──────────────────────────
  Widget _buildSubBar() {
    if (_expiryList.isEmpty) return const SizedBox.shrink();
    final pcrColor = _pcrColor(_overallPcr);
    final sentiment = _pcrSentiment(_overallPcr);
    final sentimentIcon = _overallPcr >= 1.2
        ? '▲'
        : _overallPcr <= 0.8
            ? '▼'
            : '●';

    return Container(
      color: _surface,
      height: 48,
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _expiryList.length,
              itemBuilder: (_, i) {
                final e = _expiryList[i];
                final sel = e == _selectedExpiry;
                return GestureDetector(
                  // ← uses _fetchForExpiry (targeted, not full refetch)
                  onTap: () => _fetchForExpiry(e),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    margin:
                        const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color:
                          sel ? _accent.withOpacity(0.14) : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: sel ? _accent.withOpacity(0.55) : _cardBorder,
                        width: sel ? 1.2 : 1.0,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        e,
                        style: GoogleFonts.spaceMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: sel ? _accent : _textSub,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_overallPcr > 0)
            Container(
              width: 1,
              height: 24,
              color: _cardBorder,
              margin: const EdgeInsets.only(right: 10),
            ),
          if (_overallPcr > 0)
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: pcrColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: pcrColor.withOpacity(0.30)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('PCR',
                      style: GoogleFonts.dmSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: _textSub,
                          letterSpacing: 0.8)),
                  const SizedBox(width: 6),
                  Text(
                    _overallPcr.toStringAsFixed(2),
                    style: GoogleFonts.spaceMono(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: pcrColor),
                  ),
                  const SizedBox(width: 5),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: pcrColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(sentimentIcon,
                            style: TextStyle(
                                fontSize: 7, color: pcrColor, height: 1)),
                        const SizedBox(width: 3),
                        Text(sentiment,
                            style: GoogleFonts.dmSans(
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                color: pcrColor,
                                letterSpacing: 0.3)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── SPOT BANNER ─────────────────────────────
  Widget _buildSpotBanner() {
    if (_spotPrice == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: _isDark ? const Color(0xFF0C1220) : const Color(0xFFEDF7FF),
        border: Border(
          top: BorderSide(color: _divider),
          bottom: BorderSide(color: _accent.withOpacity(0.18)),
        ),
      ),
      child: Row(
        children: [
          _dot(_accent),
          const SizedBox(width: 6),
          Text('Spot',
              style: GoogleFonts.dmSans(fontSize: 11, color: _textSub)),
          const SizedBox(width: 5),
          Text('₹${_spotPrice.toStringAsFixed(2)}',
              style: GoogleFonts.spaceMono(
                  fontSize: 13, fontWeight: FontWeight.w700, color: _accent)),
          const Spacer(),
          if (_budgetActive) ...[
            GestureDetector(
              onTap: _clearBudget,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _orange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _orange.withOpacity(0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_fmtMoney(_budgetAmount ?? 0),
                        style: GoogleFonts.spaceMono(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: _orange)),
                    const SizedBox(width: 4),
                    Icon(Icons.close_rounded, color: _orange, size: 10),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          GestureDetector(
            onTap: _scrollToAtm,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _orange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _orange.withOpacity(0.35)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.my_location_rounded, color: _orange, size: 10),
                  const SizedBox(width: 3),
                  Text('ATM',
                      style: GoogleFonts.spaceMono(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: _orange)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text('${_filteredPairs.length} strikes',
              style: GoogleFonts.dmSans(fontSize: 11, color: _textMuted)),
        ],
      ),
    );
  }

  Widget _dot(Color c) => Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
            color: c,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: c.withOpacity(0.5), blurRadius: 5)]),
      );

  // ── CHAIN TABLE ─────────────────────────────
  Widget _buildChainTable() {
    final ceCols = _ceCols;
    final peCols = _peCols;
    final ceW = _colsW(ceCols);
    final peW = _colsW(peCols);
    final totalW = ceW + _strikePinW + peW;

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewW = constraints.maxWidth;
        return Column(
          children: [
            // ── Header ────────────────────────
            SizedBox(
              height: _headerH,
              child: Stack(
                children: [
                  NotificationListener<ScrollNotification>(
                    onNotification: (n) => true,
                    child: SingleChildScrollView(
                      controller: _hHeaderScrollCtrl,
                      scrollDirection: Axis.horizontal,
                      physics: const NeverScrollableScrollPhysics(),
                      child: SizedBox(
                        width: totalW,
                        child: Row(
                          children: [
                            Container(
                              width: ceW,
                              color: _isDark
                                  ? const Color(0xFF001A0D).withOpacity(0.45)
                                  : const Color(0xFFEDFFF8).withOpacity(0.55),
                              child: Row(
                                children: ceCols
                                    .map((c) => SizedBox(
                                          width: c.$2,
                                          child: Center(
                                            child: Text(c.$1,
                                                style: GoogleFonts.spaceMono(
                                                    fontSize: 7.5,
                                                    fontWeight: FontWeight.w700,
                                                    color:
                                                        _green.withOpacity(0.7),
                                                    letterSpacing: 0.5)),
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ),
                            Container(
                              width: _strikePinW,
                              color: _isDark
                                  ? const Color(0xFF0D1018)
                                  : const Color(0xFFF1F5FB),
                            ),
                            Container(
                              width: peW,
                              color: _isDark
                                  ? const Color(0xFF1A0009).withOpacity(0.45)
                                  : const Color(0xFFFFF0F3).withOpacity(0.55),
                              child: Row(
                                children: peCols
                                    .map((c) => SizedBox(
                                          width: c.$2,
                                          child: Center(
                                            child: Text(c.$1,
                                                style: GoogleFonts.spaceMono(
                                                    fontSize: 7.5,
                                                    fontWeight: FontWeight.w700,
                                                    color:
                                                        _red.withOpacity(0.7),
                                                    letterSpacing: 0.5)),
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _hScrollCtrl,
                    builder: (_, __) {
                      final offset =
                          _hScrollCtrl.hasClients ? _hScrollCtrl.offset : 0.0;
                      final natural = ceW - offset;
                      final stickyLeft =
                          natural.clamp(0.0, viewW - _strikePinW);
                      return Positioned(
                        left: stickyLeft,
                        top: 0,
                        bottom: 0,
                        width: _strikePinW,
                        child: Container(
                          color: _isDark
                              ? const Color(0xFF0D1018)
                              : const Color(0xFFF1F5FB),
                          child: Center(
                            child: Text('STRIKE',
                                style: GoogleFonts.spaceMono(
                                    fontSize: 7.5,
                                    fontWeight: FontWeight.w700,
                                    color: _textMuted,
                                    letterSpacing: 0.6)),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            // ── Body ──────────────────────────
            Expanded(
              child: Stack(
                children: [
                  NotificationListener<ScrollNotification>(
                    onNotification: (n) {
                      if (n is ScrollUpdateNotification &&
                          n.metrics.axis == Axis.horizontal) {
                        setState(() => _hScrollCtrl.offset);
                        if (_hHeaderScrollCtrl.hasClients) {
                          _hHeaderScrollCtrl.jumpTo(_hScrollCtrl.offset);
                        }
                      }
                      return false;
                    },
                    child: SingleChildScrollView(
                      controller: _hScrollCtrl,
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: totalW,
                        child: ListView.builder(
                          controller: _vertScrollCtrl,
                          itemCount: _filteredPairs.length,
                          itemExtent: _rowH,
                          itemBuilder: (_, i) => _buildFullRow(
                              _filteredPairs[i], i, ceCols, peCols, totalW),
                        ),
                      ),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _hScrollCtrl,
                    builder: (_, __) {
                      final offset =
                          _hScrollCtrl.hasClients ? _hScrollCtrl.offset : 0.0;
                      final natural = ceW - offset;
                      final stickyLeft =
                          natural.clamp(0.0, viewW - _strikePinW);
                      return Positioned(
                        left: stickyLeft,
                        top: 0,
                        bottom: 0,
                        width: _strikePinW,
                        child: ListView.builder(
                          controller: _stickyVertScrollCtrl,
                          itemCount: _filteredPairs.length,
                          itemExtent: _rowH,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (_, i) =>
                              _buildStrikePinRow(_filteredPairs[i], i),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFullRow(
    _StrikePair pair,
    int index,
    List<(String, double)> ceCols,
    List<(String, double)> peCols,
    double totalW,
  ) {
    final bg = _rowBg(pair, index);
    final ceItmTint = (pair.call?.isItm ?? false)
        ? (_isDark
            ? const Color(0xFF001A0D).withOpacity(0.28)
            : const Color(0xFFEDFFF5).withOpacity(0.45))
        : Colors.transparent;
    final peItmTint = (pair.put?.isItm ?? false)
        ? (_isDark
            ? const Color(0xFF1A0009).withOpacity(0.28)
            : const Color(0xFFFFF0F3).withOpacity(0.45))
        : Colors.transparent;

    return GestureDetector(
      onTap: () => _showStrikeDetail(pair),
      child: Container(
        height: _rowH,
        width: totalW,
        decoration: BoxDecoration(
          color: bg,
          border: Border(
              bottom:
                  BorderSide(color: _divider.withOpacity(0.35), width: 0.5)),
        ),
        child: Row(
          children: [
            ...ceCols.map((c) {
              final val = _ceVal(c.$1, pair.call);
              final color = pair.call == null
                  ? _textMuted.withOpacity(0.3)
                  : _ceColor(c.$1);
              return Container(
                width: c.$2,
                color: ceItmTint,
                child: Center(
                  child: Text(val,
                      style: GoogleFonts.spaceMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: color),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              );
            }),
            SizedBox(width: _strikePinW),
            ...peCols.map((c) {
              final val = _peVal(c.$1, pair.put);
              final color = pair.put == null
                  ? _textMuted.withOpacity(0.3)
                  : _peColor(c.$1);
              return Container(
                width: c.$2,
                color: peItmTint,
                child: Center(
                  child: Text(val,
                      style: GoogleFonts.spaceMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: color),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStrikePinRow(_StrikePair pair, int index) {
    final atmColor = _isDark ? _Dark.rowAtmBorder : _Light.rowAtmBorder;
    final pcr = pair.pcr;
    final hasPcr = pcr > 0;
    Color pcrC = _pcrColor(pcr);

    return GestureDetector(
      onTap: () => _showStrikeDetail(pair),
      child: Stack(
        children: [
          Container(
            height: _rowH,
            width: _strikePinW,
            decoration: BoxDecoration(
              color: pair.isAtm
                  ? (_isDark
                      ? const Color(0xFF1E1500)
                      : const Color(0xFFFFF8E0))
                  : (_isDark
                      ? const Color(0xFF0D1018)
                      : const Color(0xFFF1F5FB)),
              border: Border(
                left: BorderSide(color: _divider.withOpacity(0.5), width: 0.5),
                right: BorderSide(color: _divider.withOpacity(0.5), width: 0.5),
                bottom:
                    BorderSide(color: _divider.withOpacity(0.35), width: 0.5),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  pair.strike.toStringAsFixed(0),
                  style: GoogleFonts.spaceMono(
                    fontSize: pair.isAtm ? 11.5 : 10.5,
                    fontWeight: pair.isAtm ? FontWeight.w800 : FontWeight.w600,
                    color: pair.isAtm ? _orange : _text,
                  ),
                ),
                if (pair.isAtm)
                  Text('ATM',
                      style: GoogleFonts.spaceMono(
                          fontSize: 6.5,
                          fontWeight: FontWeight.w800,
                          color: _orange.withOpacity(0.8),
                          letterSpacing: 0.5))
                else
                  const SizedBox(height: 1),
                if (hasPcr)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: pcrC.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      'PCR ${pcr.toStringAsFixed(2)}',
                      style: GoogleFonts.spaceMono(
                          fontSize: 6.5,
                          fontWeight: FontWeight.w700,
                          color: pcrC),
                    ),
                  ),
              ],
            ),
          ),
          if (pair.isAtm)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 2.5, color: atmColor),
            ),
        ],
      ),
    );
  }

  Color _rowBg(_StrikePair pair, int index) {
    if (pair.isAtm) return _isDark ? _Dark.rowAtm : _Light.rowAtm;
    return index.isEven
        ? (_isDark ? _Dark.rowEven : _Light.rowEven)
        : (_isDark ? _Dark.rowOdd : _Light.rowOdd);
  }

  // ── DETAIL SHEET ────────────────────────────
  void _showStrikeDetail(_StrikePair pair) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scroll) => _StrikeDetailSheet(
          pair: pair,
          isDark: _isDark,
          scroll: scroll,
        ),
      ),
    );
  }

  // ── SHIMMER / ERROR / EMPTY ─────────────────
  Widget _buildShimmer() {
    return ListView.builder(
      itemCount: 14,
      itemExtent: _rowH,
      itemBuilder: (_, i) => _ChainRowShimmer(isDark: _isDark),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, color: _red, size: 44),
          const SizedBox(height: 12),
          Text('Failed to fetch chain',
              style: GoogleFonts.dmSans(color: _text, fontSize: 14)),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(_error ?? '',
                style: GoogleFonts.dmSans(color: _textSub, fontSize: 11),
                textAlign: TextAlign.center),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _fetchChain,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(backgroundColor: _accent),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.table_chart_outlined, color: _textMuted, size: 44),
          const SizedBox(height: 12),
          Text('No data available',
              style: GoogleFonts.dmSans(
                  color: _textSub, fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text('Try another symbol or expiry',
              style: GoogleFonts.dmSans(color: _textMuted, fontSize: 12)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  STRIKE DETAIL SHEET
// ─────────────────────────────────────────────
class _StrikeDetailSheet extends StatelessWidget {
  final _StrikePair pair;
  final bool isDark;
  final ScrollController scroll;

  const _StrikeDetailSheet(
      {required this.pair, required this.isDark, required this.scroll});

  Color get _text => isDark ? _Dark.text : _Light.text;
  Color get _textSub => isDark ? _Dark.textSub : _Light.textSub;
  Color get _textMuted => isDark ? _Dark.textMuted : _Light.textMuted;
  Color get _green => isDark ? _Dark.accentGreen : _Light.accentGreen;
  Color get _red => isDark ? _Dark.accentRed : _Light.accentRed;
  Color get _accent => isDark ? _Dark.accent : _Light.accent;
  Color get _orange => isDark ? _Dark.accentOrange : _Light.accentOrange;
  Color get _divider => isDark ? _Dark.divider : _Light.divider;
  Color get _card => isDark ? _Dark.card : _Light.card;

  String _fmt(double v) {
    if (v >= 1e7) return '${(v / 1e7).toStringAsFixed(2)}Cr';
    if (v >= 1e5) return '${(v / 1e5).toStringAsFixed(2)}L';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  String _fmtMoney(double v) {
    if (v >= 1e5) return '₹${(v / 1e5).toStringAsFixed(2)}L';
    if (v >= 1e3) return '₹${(v / 1e3).toStringAsFixed(1)}K';
    return '₹${v.toStringAsFixed(0)}';
  }

  Color _pcrColor(double pcr) {
    if (pcr > 1.2) return _green;
    if (pcr < 0.8) return _red;
    return _orange;
  }

  String _fmtTimestamp(DateTime? dt) {
    if (dt == null) return '—';
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final mon = [
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
    ][dt.month - 1];
    return '$h:$min:$s  $day $mon ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final lotSize = pair.lotSize;
    final callLotCost = pair.callLotCost;
    final putLotCost = pair.putLotCost;
    final pcr = pair.pcr;

    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SingleChildScrollView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 34,
                height: 3.5,
                margin: const EdgeInsets.only(bottom: 16, top: 10),
                decoration: BoxDecoration(
                    color: _textMuted.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _accent.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(6),
                              border:
                                  Border.all(color: _accent.withOpacity(0.28)),
                            ),
                            child: Text(
                              pair.call?.symbol ?? pair.put?.symbol ?? '—',
                              style: GoogleFonts.spaceMono(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _accent),
                            ),
                          ),
                          const Spacer(),
                          if (pair.call != null || pair.put != null)
                            _badge(
                              'Spot  ₹${(pair.call?.spot ?? pair.put?.spot ?? 0).toStringAsFixed(2)}',
                              _accent,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            pair.strike.toStringAsFixed(0),
                            style: GoogleFonts.dmSans(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: _text),
                          ),
                          if (pair.isAtm) ...[
                            const SizedBox(width: 8),
                            _badge('ATM', _orange),
                          ],
                          const Spacer(),
                          if (pair.updatedAt != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.update_rounded,
                                    size: 10, color: _textMuted),
                                const SizedBox(width: 3),
                                Text(
                                  _fmtTimestamp(pair.updatedAt),
                                  style: GoogleFonts.spaceMono(
                                    fontSize: 9,
                                    color: _textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
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
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _accent.withOpacity(0.18)),
              ),
              child: Row(
                children: [
                  Icon(Icons.inventory_2_outlined, color: _accent, size: 14),
                  const SizedBox(width: 6),
                  Text('Lot Size: ',
                      style: GoogleFonts.dmSans(fontSize: 11, color: _textSub)),
                  Text('$lotSize',
                      style: GoogleFonts.spaceMono(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _accent)),
                  const SizedBox(width: 14),
                  Container(width: 1, height: 14, color: _divider),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CE 1 lot',
                          style: GoogleFonts.dmSans(
                              fontSize: 9, color: _textMuted)),
                      Text(callLotCost > 0 ? _fmtMoney(callLotCost) : '—',
                          style: GoogleFonts.spaceMono(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _green)),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Container(width: 1, height: 14, color: _divider),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PE 1 lot',
                          style: GoogleFonts.dmSans(
                              fontSize: 9, color: _textMuted)),
                      Text(putLotCost > 0 ? _fmtMoney(putLotCost) : '—',
                          style: GoogleFonts.spaceMono(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _red)),
                    ],
                  ),
                ],
              ),
            ),
            if (pcr > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: _pcrColor(pcr).withOpacity(0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _pcrColor(pcr).withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Text('Strike PCR',
                        style:
                            GoogleFonts.dmSans(fontSize: 11, color: _textSub)),
                    const SizedBox(width: 8),
                    Text(pcr.toStringAsFixed(2),
                        style: GoogleFonts.spaceMono(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: _pcrColor(pcr))),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: _pcrColor(pcr).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        pcr > 1.5
                            ? 'Very Bullish'
                            : pcr > 1.2
                                ? 'Bullish'
                                : pcr > 0.8
                                    ? 'Neutral'
                                    : pcr > 0.5
                                        ? 'Bearish'
                                        : 'Very Bearish',
                        style: GoogleFonts.dmSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _pcrColor(pcr)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                _sectionLabel('CALL', _green),
                const Spacer(),
                _sectionLabel('PUT', _red),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                    child: _optionCard(pair.call, _green,
                        isCall: true, lotSize: lotSize)),
                const SizedBox(width: 10),
                Expanded(
                    child: _optionCard(pair.put, _red,
                        isCall: false, lotSize: lotSize)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: c.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.withOpacity(0.4)),
      ),
      child: Text(label,
          style: GoogleFonts.spaceMono(
              fontSize: 10, fontWeight: FontWeight.w700, color: c)),
    );
  }

  Widget _sectionLabel(String label, Color c) {
    return Row(
      children: [
        Container(
            width: 3,
            height: 12,
            color: c,
            margin: const EdgeInsets.only(right: 6)),
        Text(label,
            style: GoogleFonts.dmSans(
                fontSize: 11, fontWeight: FontWeight.w700, color: c)),
      ],
    );
  }

  Widget _optionCard(_ChainRow? r, Color c,
      {required bool isCall, required int lotSize}) {
    if (r == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.02)
              : Colors.black.withOpacity(0.02),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _divider),
        ),
        height: 200,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.block_rounded, color: _textMuted, size: 24),
              const SizedBox(height: 8),
              Text('No data',
                  style: GoogleFonts.dmSans(color: _textMuted, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    final lotCost = r.ltp * lotSize;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(r.ltp.toStringAsFixed(2),
              style: GoogleFonts.spaceMono(
                  fontSize: 18, fontWeight: FontWeight.w800, color: c)),
          Text('LTP',
              style: GoogleFonts.dmSans(fontSize: 10, color: _textMuted)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: c.withOpacity(0.10),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              '${_fmtMoney(lotCost)} / lot',
              style: GoogleFonts.spaceMono(
                  fontSize: 9, fontWeight: FontWeight.w700, color: c),
            ),
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: _divider),
          const SizedBox(height: 10),
          _row('IV', '${r.iv.toStringAsFixed(2)}%', _orange),
          _row('OI', _fmt(r.oi), _textSub),
          _row('Chg OI', _fmt(r.oiChange), r.oiChange >= 0 ? _green : _red),
          _row('Volume', _fmt(r.volume), _textSub),
          _row('Bid', r.bidPrice.toStringAsFixed(2), _textSub),
          _row('Ask', r.askPrice.toStringAsFixed(2), _textSub),
          const SizedBox(height: 10),
          Divider(height: 1, color: _divider),
          const SizedBox(height: 8),
          Text('Greeks',
              style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _textMuted,
                  letterSpacing: 0.4)),
          const SizedBox(height: 8),
          _row(
              'Δ Delta',
              isCall
                  ? r.delta.toStringAsFixed(4)
                  : r.delta.abs().toStringAsFixed(4),
              _accent),
          _row('Γ Gamma', r.gamma.toStringAsFixed(5), _textSub),
          _row('Θ Theta', r.theta.toStringAsFixed(4), _red),
          _row('ν Vega', r.vega.toStringAsFixed(4), _textSub),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('PoP',
                  style: GoogleFonts.dmSans(fontSize: 11, color: _textMuted)),
              Text('${r.pop.toStringAsFixed(1)}%',
                  style: GoogleFonts.spaceMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: r.pop > 50 ? _green : _red)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: r.pop.clamp(0, 100) / 100,
              minHeight: 4,
              backgroundColor: _divider,
              valueColor: AlwaysStoppedAnimation(r.pop > 50 ? _green : _red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String val, Color vc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.dmSans(fontSize: 11, color: _textMuted)),
          Text(val,
              style: GoogleFonts.spaceMono(
                  fontSize: 11, fontWeight: FontWeight.w600, color: vc)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SHIMMER ROW
// ─────────────────────────────────────────────
class _ChainRowShimmer extends StatefulWidget {
  final bool isDark;
  const _ChainRowShimmer({required this.isDark});

  @override
  State<_ChainRowShimmer> createState() => _ChainRowShimmerState();
}

class _ChainRowShimmerState extends State<_ChainRowShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1300))
      ..repeat();
    _anim = Tween<double>(begin: -1.5, end: 1.5)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base =
        widget.isDark ? const Color(0xFF161B25) : const Color(0xFFEFF3FA);
    final hl =
        widget.isDark ? const Color(0xFF202840) : const Color(0xFFF8FAFE);
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        height: 46,
        margin: const EdgeInsets.symmetric(vertical: 0.5),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(_anim.value - 1, 0),
            end: Alignment(_anim.value + 1, 0),
            colors: [base, hl, base],
          ),
        ),
      ),
    );
  }
}
