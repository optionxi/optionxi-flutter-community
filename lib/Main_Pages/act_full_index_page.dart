import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:optionxi/Main_Pages/act_set_alert.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ---------------------------------------------------------------------------
// Data model for a single index row
// ---------------------------------------------------------------------------
class IndexModel {
  final String symbol;
  final double ltp;
  final double pcnt;
  final double change;
  final double low;
  final double high;
  final double previousClose;
  final double open;

  const IndexModel({
    required this.symbol,
    required this.ltp,
    required this.pcnt,
    required this.change,
    required this.low,
    required this.high,
    required this.previousClose,
    required this.open,
  });

  factory IndexModel.fromJson(Map<String, dynamic> json) {
    final ltp = (json['ltp'] as num?)?.toDouble() ?? 0;
    final pc = (json['pc'] as num?)?.toDouble() ?? ltp;
    return IndexModel(
      symbol: json['symbol'] as String? ?? '',
      ltp: ltp,
      pcnt: (json['pcnt'] as num?)?.toDouble() ?? 0,
      change: ltp - pc,
      low: (json['l'] as num?)?.toDouble() ?? ltp,
      high: (json['h'] as num?)?.toDouble() ?? ltp,
      previousClose: pc,
      open: (json['o'] as num?)?.toDouble() ?? ltp,
    );
  }

  IndexModel copyWith({
    double? ltp,
    double? pcnt,
    double? low,
    double? high,
    double? open,
  }) {
    final newLtp = ltp ?? this.ltp;
    final newPc = previousClose;
    return IndexModel(
      symbol: symbol,
      ltp: newLtp,
      pcnt: pcnt ?? this.pcnt,
      change: newLtp - newPc,
      low: low ?? this.low,
      high: high ?? this.high,
      previousClose: newPc,
      open: open ?? this.open,
    );
  }
}

// ---------------------------------------------------------------------------
// Display name helpers
// ---------------------------------------------------------------------------
String _displayName(String symbol) {
  const map = {
    'NIFTY50': 'NIFTY 50',
    'NIFTYBANK': 'BANK NIFTY',
    'INDIAVIX': 'INDIA VIX',
    'NIFTYIT': 'NIFTY IT',
    'NIFTYMIDCAP50': 'MIDCAP 50',
    'NIFTYNEXT50': 'NIFTY NEXT 50',
    'NIFTYFINSERVICE': 'FIN SERVICE',
    'NIFTYAUTO': 'NIFTY AUTO',
    'NIFTYPHARMA': 'NIFTY PHARMA',
    'NIFTYFMCG': 'NIFTY FMCG',
    'NIFTYMETAL': 'NIFTY METAL',
    'NIFTYREALTY': 'NIFTY REALTY',
    'NIFTYINFRA': 'NIFTY INFRA',
    'NIFTYMEDIA': 'NIFTY MEDIA',
  };
  return map[symbol] ?? symbol;
}

String _sectorLabel(String symbol) {
  const map = {
    'NIFTY50': 'Broad Market',
    'NIFTYBANK': 'Banking',
    'INDIAVIX': 'Volatility',
    'NIFTYIT': 'Technology',
    'NIFTYMIDCAP50': 'Mid Cap',
    'NIFTYNEXT50': 'Broad Market',
    'NIFTYFINSERVICE': 'Finance',
    'NIFTYAUTO': 'Automobile',
    'NIFTYPHARMA': 'Pharma',
    'NIFTYFMCG': 'FMCG',
    'NIFTYMETAL': 'Metal',
    'NIFTYREALTY': 'Realty',
    'NIFTYINFRA': 'Infrastructure',
    'NIFTYMEDIA': 'Media',
  };
  return map[symbol] ?? 'Index';
}

// ---------------------------------------------------------------------------
// Full Indices Page
// ---------------------------------------------------------------------------
class FullIndicesPage extends StatefulWidget {
  const FullIndicesPage({super.key});

  @override
  State<FullIndicesPage> createState() => _FullIndicesPageState();
}

class _FullIndicesPageState extends State<FullIndicesPage>
    with TickerProviderStateMixin {
  List<IndexModel> _indices = [];
  bool _loading = true;
  String? _error;
  RealtimeChannel? _channel;

  // Flash animation tracking
  final Map<String, AnimationController> _flashControllers = {};
  final Map<String, bool> _flashDirections = {};
  Map<String, double> _prevLtps = {};

  // Sort & filter
  String _sortBy = 'symbol';
  bool _sortAsc = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _fetchAll();
    _setupRealtime();
  }

  @override
  void dispose() {
    for (final c in _flashControllers.values) {
      c.dispose();
    }
    _channel?.unsubscribe();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Data layer
  // ---------------------------------------------------------------------------
  Future<void> _fetchAll() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });
      final data = await Supabase.instance.client
          .from('live_nifty_indices')
          .select('symbol, ltp, pcnt, l, h, pc, o');

      if (!mounted) return;
      final list = (data as List).map((e) => IndexModel.fromJson(e)).toList();
      for (final m in list) {
        _prevLtps[m.symbol] = m.ltp;
      }
      setState(() {
        _indices = list;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Failed to load indices.\nPull down to retry.';
        });
      }
    }
  }

  void _setupRealtime() {
    _channel = Supabase.instance.client
        .channel('full_indices_updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'live_nifty_indices',
          callback: (payload) => _onRealtimeUpdate(payload),
        )
        .subscribe();
  }

  void _onRealtimeUpdate(PostgresChangePayload payload) {
    if (!mounted) return;
    final newRow = payload.newRecord;
    if (newRow.isEmpty) return;
    final symbol = newRow['symbol'] as String?;
    if (symbol == null) return;

    final updated = IndexModel.fromJson(newRow);
    final oldLtp = _prevLtps[symbol];

    setState(() {
      final idx = _indices.indexWhere((m) => m.symbol == symbol);
      if (idx >= 0) {
        _indices[idx] = updated;
      } else {
        _indices.add(updated);
      }
    });

    if (oldLtp != null && updated.ltp != oldLtp) {
      _triggerFlash(symbol, updated.ltp > oldLtp);
    }
    _prevLtps[symbol] = updated.ltp;
  }

  void _triggerFlash(String symbol, bool isUp) {
    _flashControllers[symbol]?.dispose();
    final ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _flashControllers[symbol] = ctrl;
    _flashDirections[symbol] = isUp;
    ctrl.forward().then((_) {
      if (mounted) setState(() {});
    });
    setState(() {});
  }

  // ---------------------------------------------------------------------------
  // Sorted + filtered list
  // ---------------------------------------------------------------------------
  List<IndexModel> get _displayList {
    var list = List<IndexModel>.from(_indices);

    if (_filter == 'gainers') {
      list = list.where((m) => m.pcnt >= 0).toList();
    } else if (_filter == 'losers') {
      list = list.where((m) => m.pcnt < 0).toList();
    }

    list.sort((a, b) {
      int cmp;
      switch (_sortBy) {
        case 'ltp':
          cmp = a.ltp.compareTo(b.ltp);
          break;
        case 'pcnt':
          cmp = a.pcnt.compareTo(b.pcnt);
          break;
        default:
          cmp = a.symbol.compareTo(b.symbol);
      }
      return _sortAsc ? cmp : -cmp;
    });

    return list;
  }

  void _toggleSort(String col) {
    setState(() {
      if (_sortBy == col) {
        _sortAsc = !_sortAsc;
      } else {
        _sortBy = col;
        _sortAsc = col == 'symbol';
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Theme helpers
  // ---------------------------------------------------------------------------
  static const Color _upColorDark = Color(0xFF00C896);
  static const Color _upColorLight = Color(0xFF00897B);
  static const Color _downColorDark = Color(0xFFFF4D6A);
  static const Color _downColorLight = Color(0xFFD32F2F);

  Color get _upColor => _isDark ? _upColorDark : _upColorLight;
  Color get _downColor => _isDark ? _downColorDark : _downColorLight;

  Color get _bgColor =>
      _isDark ? const Color(0xFF07090F) : const Color(0xFFF2F4F8);
  Color get _cardColor => _isDark ? const Color(0xFF0D1017) : Colors.white;
  Color get _borderColor =>
      _isDark ? const Color(0xFF161B26) : const Color(0xFFDFE4ED);
  Color get _labelColor =>
      _isDark ? const Color(0xFF3D4560) : const Color(0xFF9CA5B8);
  Color get _valueColor =>
      _isDark ? const Color(0xFFE8EBF3) : const Color(0xFF111827);
  Color get _subColor =>
      _isDark ? const Color(0xFF525D78) : const Color(0xFFB0B8CC);
  Color get _accentTeal =>
      _isDark ? const Color(0xFF00C896) : const Color(0xFF00897B);
  Color get _headerBg =>
      _isDark ? const Color(0xFF0D1017) : const Color(0xFFEAEDF4);
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _bgColor,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildAppBar(),
              _buildSummaryBar(),
              _buildFilterChips(),
              _buildColumnHeaders(),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  // ── App bar ────────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Row(
        children: [
          _IconBtn(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.pop(context),
            cardColor: _cardColor,
            borderColor: _borderColor,
            iconColor: _labelColor,
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Market Indices',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: _valueColor,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 1),
              Row(
                children: [
                  _PulseDot(color: _accentTeal),
                  const SizedBox(width: 5),
                  Text(
                    'LIVE · NSE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _accentTeal,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          _IconBtn(
            icon: Icons.refresh_rounded,
            onTap: _fetchAll,
            cardColor: _cardColor,
            borderColor: _borderColor,
            iconColor: _labelColor,
          ),
        ],
      ),
    );
  }

  // ── Summary bar ────────────────────────────────────────────────────────────
  Widget _buildSummaryBar() {
    if (_indices.isEmpty) return const SizedBox.shrink();
    final gainers = _indices.where((m) => m.pcnt >= 0).length;
    final losers = _indices.length - gainers;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Row(
        children: [
          _SummaryPill(label: 'Gainers', value: '$gainers', color: _upColor),
          const SizedBox(width: 8),
          _SummaryPill(label: 'Losers', value: '$losers', color: _downColor),
          const SizedBox(width: 8),
          _SummaryPill(
              label: 'Total', value: '${_indices.length}', color: _accentTeal),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: [
          _FilterTab(
              label: 'All',
              active: _filter == 'all',
              activeColor: _accentTeal,
              isDark: _isDark,
              onTap: () => setState(() => _filter = 'all')),
          const SizedBox(width: 6),
          _FilterTab(
              label: '▲ Gainers',
              active: _filter == 'gainers',
              activeColor: _upColor,
              isDark: _isDark,
              onTap: () => setState(() => _filter = 'gainers')),
          const SizedBox(width: 6),
          _FilterTab(
              label: '▼ Losers',
              active: _filter == 'losers',
              activeColor: _downColor,
              isDark: _isDark,
              onTap: () => setState(() => _filter = 'losers')),
        ],
      ),
    );
  }

  // ── Column headers ─────────────────────────────────────────────────────────
  Widget _buildColumnHeaders() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _headerBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          // Left accent bar spacer
          const SizedBox(width: 4),
          Expanded(
            flex: 5,
            child: _SortHeader(
              label: 'INDEX',
              col: 'symbol',
              current: _sortBy,
              asc: _sortAsc,
              onTap: _toggleSort,
              color: _labelColor,
            ),
          ),
          Expanded(
            flex: 4,
            child: _SortHeader(
              label: 'LTP',
              col: 'ltp',
              current: _sortBy,
              asc: _sortAsc,
              onTap: _toggleSort,
              color: _labelColor,
              align: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 4,
            child: _SortHeader(
              label: 'CHG / %',
              col: 'pcnt',
              current: _sortBy,
              asc: _sortAsc,
              onTap: _toggleSort,
              color: _labelColor,
              align: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────
  Widget _buildBody() {
    if (_loading) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemCount: 8,
        itemBuilder: (_, __) => _ShimmerRow(isDark: _isDark),
      );
    }

    if (_error != null) {
      return RefreshIndicator(
        onRefresh: _fetchAll,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: 300,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off_rounded, size: 42, color: _labelColor),
                  const SizedBox(height: 14),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13, color: _labelColor, height: 1.5),
                  ),
                  const SizedBox(height: 18),
                  GestureDetector(
                    onTap: _fetchAll,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 10),
                      decoration: BoxDecoration(
                        color: _accentTeal.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: _accentTeal.withOpacity(0.35)),
                      ),
                      child: Text(
                        'Retry',
                        style: TextStyle(
                          color: _accentTeal,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final list = _displayList;
    if (list.isEmpty) {
      return Center(
        child: Text('No indices found', style: TextStyle(color: _labelColor)),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchAll,
      color: _accentTeal,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        itemCount: list.length,
        itemBuilder: (context, i) {
          final m = list[i];
          final flashCtrl = _flashControllers[m.symbol];
          final isUp = _flashDirections[m.symbol] ?? true;
          return _IndexRow(
            model: m,
            isDark: _isDark,
            upColor: _upColor,
            downColor: _downColor,
            cardColor: _cardColor,
            borderColor: _borderColor,
            labelColor: _labelColor,
            valueColor: _valueColor,
            subColor: _subColor,
            flashController: flashCtrl,
            flashIsUp: isUp,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    SetAlertPage(stockName: m.symbol, segment: "index"),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Individual index row card  —  LEFT ACCENT BAR  +  RIGHT CHANGE INFO
// ---------------------------------------------------------------------------
class _IndexRow extends StatelessWidget {
  final IndexModel model;
  final bool isDark;
  final Color upColor,
      downColor,
      cardColor,
      borderColor,
      labelColor,
      valueColor,
      subColor;
  final AnimationController? flashController;
  final bool flashIsUp;
  final VoidCallback onTap;

  const _IndexRow({
    required this.model,
    required this.isDark,
    required this.upColor,
    required this.downColor,
    required this.cardColor,
    required this.borderColor,
    required this.labelColor,
    required this.valueColor,
    required this.subColor,
    required this.flashController,
    required this.flashIsUp,
    required this.onTap,
  });

  bool get _isPositive => model.pcnt >= 0;
  Color get _accentColor => _isPositive ? upColor : downColor;

  double get _progress {
    final range = model.high - model.low;
    if (range <= 0) return 0.5;
    return ((model.ltp - model.low) / range).clamp(0.0, 1.0);
  }

  String _fmtLtp(double v) =>
      v >= 10000 ? v.toStringAsFixed(1) : v.toStringAsFixed(2);

  String _fmtChg(double v) {
    final sign = v >= 0 ? '+' : '';
    return '$sign${v.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final flashOverlay =
        flashIsUp ? const Color(0xFF00C896) : const Color(0xFFFF4D6A);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AnimatedBuilder(
        animation: flashController ?? kAlwaysCompleteAnimation,
        builder: (context, _) {
          final opacity =
              (flashController != null && flashController!.isAnimating)
                  ? (1 - flashController!.value) * 0.10
                  : 0.0;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                decoration: BoxDecoration(
                  color: opacity > 0
                      ? Color.lerp(cardColor, flashOverlay, opacity)
                      : cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.20 : 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // ── MAIN CONTENT ───────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 14, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(width: 10),

                              // Name + sector
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _displayName(model.symbol),
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: valueColor,
                                        letterSpacing: -0.1,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _sectorLabel(model.symbol),
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: subColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 8),

                              // ── RIGHT: LTP + CHG + % ─────────────────────
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _fmtLtp(model.ltp),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: valueColor,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  _ChangePill(
                                    chgStr: _fmtChg(model.change),
                                    pctStr:
                                        '${_isPositive ? '+' : ''}${model.pcnt.toStringAsFixed(2)}%',
                                    accentColor: _accentColor,
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // ── Day Range Bar ──────────────────────────────
                          _DayRangeBar(
                            low: model.low,
                            high: model.high,
                            progress: _progress,
                            accentColor: _accentColor,
                            labelColor: labelColor,
                            trackColor: isDark
                                ? const Color(0xFF161B26)
                                : const Color(0xFFE4E8F0),
                          ),
                        ],
                      ),
                    ),

                    // ── LEFT ACCENT BAR (overlaid via Positioned) ──────────
                    Positioned(
                      left: 0,
                      top: 20,
                      bottom: 20,
                      child: Container(
                        width: 4,
                        decoration: BoxDecoration(
                          color: _accentColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(14),
                            bottomLeft: Radius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Change pill  —  shows "▲ +123.45  +0.56%"  or  "▼ −123.45  −0.56%"
// ---------------------------------------------------------------------------
class _ChangePill extends StatelessWidget {
  final String chgStr;
  final String pctStr;
  final Color accentColor;

  const _ChangePill({
    required this.chgStr,
    required this.pctStr,
    required this.accentColor,
  });

  bool get _isPositive => chgStr.startsWith('+');

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.10),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isPositive
                ? Icons.arrow_drop_up_rounded
                : Icons.arrow_drop_down_rounded,
            size: 14,
            color: accentColor,
          ),
          Text(
            chgStr,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: accentColor,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            width: 1,
            height: 10,
            color: accentColor.withOpacity(0.25),
          ),
          const SizedBox(width: 4),
          Text(
            pctStr,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Day range bar
// ---------------------------------------------------------------------------
class _DayRangeBar extends StatelessWidget {
  final double low, high, progress;
  final Color accentColor, labelColor, trackColor;

  const _DayRangeBar({
    required this.low,
    required this.high,
    required this.progress,
    required this.accentColor,
    required this.labelColor,
    required this.trackColor,
  });

  String _compact(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(builder: (context, constraints) {
          final barW = constraints.maxWidth;
          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 4,
                  child: Stack(children: [
                    Container(color: trackColor),
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              accentColor.withOpacity(0.35),
                              accentColor
                            ],
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
              Positioned(
                left: (barW * progress - 3).clamp(0.0, barW - 6),
                top: -1,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.55),
                        blurRadius: 5,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('L: ${_compact(low)}',
                style: TextStyle(fontSize: 9, color: labelColor)),
            Text('Day Range', style: TextStyle(fontSize: 9, color: labelColor)),
            Text('H: ${_compact(high)}',
                style: TextStyle(fontSize: 9, color: labelColor)),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Summary pill
// ---------------------------------------------------------------------------
class _SummaryPill extends StatelessWidget {
  final String label, value;
  final Color color;

  const _SummaryPill(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: color.withOpacity(0.65),
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter tab
// ---------------------------------------------------------------------------
class _FilterTab extends StatelessWidget {
  final String label;
  final bool active;
  final Color activeColor;
  final bool isDark;
  final VoidCallback onTap;

  const _FilterTab({
    required this.label,
    required this.active,
    required this.activeColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF0D1017) : Colors.white;
    final border = isDark ? const Color(0xFF161B26) : const Color(0xFFDFE4ED);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: active ? activeColor.withOpacity(0.12) : bg,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: active ? activeColor.withOpacity(0.45) : border,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active
                  ? activeColor
                  : (isDark
                      ? const Color(0xFF4A5168)
                      : const Color(0xFF9CA5B8)),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sortable column header
// ---------------------------------------------------------------------------
class _SortHeader extends StatelessWidget {
  final String label, col, current;
  final bool asc;
  final void Function(String) onTap;
  final Color color;
  final TextAlign align;

  const _SortHeader({
    required this.label,
    required this.col,
    required this.current,
    required this.asc,
    required this.onTap,
    required this.color,
    this.align = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    final active = current == col;
    return GestureDetector(
      onTap: () => onTap(col),
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisAlignment: align == TextAlign.right
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: active ? color.withOpacity(0.9) : color,
              letterSpacing: 0.6,
            ),
          ),
          if (active) ...[
            const SizedBox(width: 2),
            Icon(
              asc ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              size: 10,
              color: color,
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Icon button helper
// ---------------------------------------------------------------------------
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color cardColor, borderColor, iconColor;

  const _IconBtn({
    required this.icon,
    required this.onTap,
    required this.cardColor,
    required this.borderColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: borderColor),
        ),
        child: Icon(icon, size: 16, color: iconColor),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shimmer row
// ---------------------------------------------------------------------------
class _ShimmerRow extends StatefulWidget {
  final bool isDark;
  const _ShimmerRow({required this.isDark});

  @override
  State<_ShimmerRow> createState() => _ShimmerRowState();
}

class _ShimmerRowState extends State<_ShimmerRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1300));
    _anim = Tween(begin: -1.5, end: 2.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _ctrl.repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => Container(
          height: 98,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment(_anim.value - 1, 0),
              end: Alignment(_anim.value, 0),
              colors: widget.isDark
                  ? [
                      const Color(0xFF0D1017),
                      const Color(0xFF161B26),
                      const Color(0xFF0D1017),
                    ]
                  : [Colors.white, const Color(0xFFE8ECF3), Colors.white],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pulsing live dot
// ---------------------------------------------------------------------------
class _PulseDot extends StatefulWidget {
  final Color color;
  const _PulseDot({required this.color});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100));
    _anim = Tween(begin: 0.3, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: widget.color.withOpacity(_anim.value),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(_anim.value * 0.45),
              blurRadius: 5,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}
