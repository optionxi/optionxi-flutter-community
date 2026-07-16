import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:optionxi/Main_Pages/MarketSentiments/act_market_sentiments.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:timeago/timeago.dart' as timeago;

const List<String> kSymbols = ['NIFTY', 'BANKNIFTY'];

// ─────────────────────────────────────────────
// DESIGN TOKENS (shared with AtlasOutputPage)
// ─────────────────────────────────────────────
class _T {
  static const double rXS = 6.0;
  static const double rSM = 10.0;
  static const double rMD = 14.0;

  static const Color lBg = Color(0xFFF4F5F9);
  static const Color lSurface = Color(0xFFFFFFFF);
  static const Color lBorder = Color(0xFFE2E5EE);
  static const Color lTextP = Color(0xFF111827);
  static const Color lTextS = Color(0xFF6B7280);

  static const Color dBg = Color(0xFF0D0F14);
  static const Color dSurface = Color(0xFF151820);
  static const Color dBorder = Color(0xFF252B3A);
  static const Color dTextP = Color(0xFFEDF0F7);
  static const Color dTextS = Color(0xFF828A9B);

  static const Color accent = Color(0xFF6366F1);
  static const Color accentDim = Color(0x1A6366F1);

  static const Color bull = Color(0xFF3B82F6);
  static const Color bullDim = Color(0x153B82F6);
  static const Color bullDimL = Color(0xFFEFF4FF);

  static const Color bear = Color(0xFFF43F5E);
  static const Color bearDim = Color(0x15F43F5E);
  static const Color bearDimL = Color(0xFFFFF0F3);

  static const Color neutral = Color(0xFF14B8A6);

  static const Color strong = Color(0xFFF59E0B);

  static const Color probHigh = Color(0xFF10B981);
  static const Color probMid = Color(0xFFEAB308);
  static const Color probLow = Color(0xFFF43F5E);

  static Color probColor(double p) {
    if (p >= 65) return probHigh;
    if (p >= 50) return probMid;
    return probLow;
  }
}

// ─────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────
class OhlcvBar {
  final DateTime ts;
  final double open, high, low, close;
  final int volume;
  OhlcvBar({
    required this.ts,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });
  factory OhlcvBar.fromJson(Map<String, dynamic> j) => OhlcvBar(
        ts: DateTime.parse(j['ts']).toLocal(),
        open: (j['open'] as num).toDouble(),
        high: (j['high'] as num).toDouble(),
        low: (j['low'] as num).toDouble(),
        close: (j['close'] as num).toDouble(),
        volume: (j['volume'] as num).toInt(),
      );
}

class AtlasSignal {
  final int id;
  final DateTime ts;
  final double probability;
  final bool entry, upBreakout, lowBreakout;
  final String longTerm, shortTerm, type;
  final int negCount, neutCount, posCount;
  final List<dynamic> negList, neutList, posList, crossList;
  final int advancing, declining;
  final double breakoutValue;
  final int crossovers;

  AtlasSignal({
    required this.id,
    required this.ts,
    required this.probability,
    required this.entry,
    required this.upBreakout,
    required this.lowBreakout,
    required this.longTerm,
    required this.shortTerm,
    required this.type,
    required this.negCount,
    required this.neutCount,
    required this.posCount,
    required this.negList,
    required this.neutList,
    required this.posList,
    required this.crossList,
    required this.advancing,
    required this.declining,
    required this.breakoutValue,
    required this.crossovers,
  });

  factory AtlasSignal.fromJson(Map<String, dynamic> j) {
    final dt = DateTime.parse(j['created_at'] as String).toLocal();
    return AtlasSignal(
      id: j['id'] as int,
      ts: dt,
      probability: (j['probability'] as num).toDouble(),
      entry: j['entry'] as bool,
      upBreakout: j['upbreakout'] as bool,
      lowBreakout: j['lowbreakout'] as bool,
      longTerm: j['longterm'] as String,
      shortTerm: j['shortterm'] as String,
      type: j['type'] as String,
      negCount: (j['Negative Indicators'] as num).toInt(),
      neutCount: (j['Neutral Indicators'] as num).toInt(),
      posCount: (j['Postive Indicators'] as num).toInt(),
      negList: _parseList(j['Negative Indicators List']),
      neutList: _parseList(j['Neutral Indicators List']),
      posList: _parseList(j['Postive Indicators List']),
      crossList: _parseList(j['Total Crossovers List']),
      advancing: (j['advancing'] as num).toInt(),
      declining: (j['declining'] as num).toInt(),
      breakoutValue: (j['breakoutvalue'] as num).toDouble(),
      crossovers: (j['crossovers'] as num).toInt(),
    );
  }

  bool get isStrong => probability >= 50.0;
  bool get isBull => type == 'Bull' || upBreakout;
  Color get dirColor => isBull ? _T.bull : _T.bear;
  Color get dirDimDark => isBull ? _T.bullDim : _T.bearDim;
  Color get dirDimLight => isBull ? _T.bullDimL : _T.bearDimL;
  IconData get dirIcon =>
      isBull ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;
  String get dirLabel => isBull ? 'Bull' : 'Bear';
}

List<dynamic> _parseList(dynamic value) {
  if (value == null) return [];
  if (value is List) return value;
  if (value is String) {
    final s = value.trim();
    if (s.isEmpty || s == '{}' || s == '[]') return [];
    if (s.startsWith('[')) {
      try {
        final decoded = jsonDecode(s);
        if (decoded is List) return decoded;
      } catch (_) {}
    }
    final keyRegex = RegExp(r"'([^']+)'\s*:");
    final matches = keyRegex.allMatches(s);
    if (matches.isNotEmpty) return matches.map((m) => m.group(1)!).toList();
    return s
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
  return [];
}

// ─────────────────────────────────────────────
// SERVICE
// ─────────────────────────────────────────────
class SupabaseService {
  static final _db = Supabase.instance.client;
  static String _ds(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  static Future<List<OhlcvBar>> fetchOhlcv(DateTime date, String symbol) async {
    final ds = _ds(date);
    final next = _ds(date.add(const Duration(days: 1)));
    final data = await _db
        .from('nifty_ohlcv')
        .select('ts,open,high,low,close,volume')
        .eq('symbol', symbol)
        .gte('ts', '${ds}T00:00:00')
        .lt('ts', '${next}T00:00:00')
        .order('ts');
    return (data as List).map((e) => OhlcvBar.fromJson(e)).toList();
  }

  static Future<List<AtlasSignal>> fetchAtlas(DateTime date) async {
    final ds = _ds(date);
    final next = _ds(date.add(const Duration(days: 1)));
    final data = await _db
        .from('atlas_output')
        .select()
        .gte('created_at', '${ds}T00:00:00+00:00')
        .lt('created_at', '${next}T00:00:00+00:00')
        .order('timeinmill');
    return (data as List).map((e) => AtlasSignal.fromJson(e)).toList();
  }
}

// ─────────────────────────────────────────────
// SCATTER HELPERS
// ─────────────────────────────────────────────
class _EP {
  final DateTime ts;
  final double price;
  final AtlasSignal signal;
  final bool up;
  _EP({
    required this.ts,
    required this.price,
    required this.signal,
    required this.up,
  });
}

// ─────────────────────────────────────────────
// PAGE
// ─────────────────────────────────────────────
class MarketSentimentChartPage extends StatefulWidget {
  const MarketSentimentChartPage({super.key});
  @override
  State<MarketSentimentChartPage> createState() =>
      _MarketSentimentChartPageState();
}

class _MarketSentimentChartPageState extends State<MarketSentimentChartPage> {
  DateTime _date = _todayMarket();
  String _symbol = kSymbols.first;
  List<OhlcvBar> _ohlcv = [];
  List<AtlasSignal> _signals = [];
  bool _loading = false;
  String? _error;

  bool _filterEntry = false;
  bool _filterUp = false;
  bool _filterDown = false;
  bool _filterStrong = false;

  /// Minimum probability threshold for signal filtering (0–100)
  double _minProb = 60.0;

  late final ZoomPanBehavior _zoom;
  late final TrackballBehavior _track;

  static DateTime _todayMarket() {
    final n = DateTime.now().toLocal();
    if (n.hour < 9 || (n.hour == 9 && n.minute < 15)) {
      return DateTime(n.year, n.month, n.day - 1);
    }
    return DateTime(n.year, n.month, n.day);
  }

  @override
  void initState() {
    super.initState();
    _zoom = ZoomPanBehavior(
      enablePinching: true,
      enableDoubleTapZooming: true,
      enableSelectionZooming: true,
      enablePanning: true,
      zoomMode: ZoomMode.x,
    );
    _track = TrackballBehavior(
      enable: true,
      activationMode: ActivationMode.singleTap,
      tooltipDisplayMode: TrackballDisplayMode.groupAllPoints,
    );
    _fetch();
  }

  void _gotoLogs() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MarketSentimentPage(),
      ),
    );
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await Future.wait([
        SupabaseService.fetchOhlcv(_date, _symbol),
        SupabaseService.fetchAtlas(_date),
      ]);
      setState(() {
        _ohlcv = r[0] as List<OhlcvBar>;
        _signals = r[1] as List<AtlasSignal>;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _shiftDate(int d) {
    final n = _date.add(Duration(days: d));
    if (n.isAfter(DateTime.now())) return;
    setState(() => _date = n);
    _fetch();
  }

  Future<void> _pickDate() async {
    final p = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );
    if (p != null && p != _date) {
      setState(() => _date = p);
      _fetch();
    }
  }

  List<AtlasSignal> get _filtered {
    var list = _signals;
    if (_filterEntry) list = list.where((s) => s.entry).toList();
    if (_filterUp) list = list.where((s) => s.upBreakout).toList();
    if (_filterDown) list = list.where((s) => s.lowBreakout).toList();
    if (_filterStrong) list = list.where((s) => s.isStrong).toList();
    // Apply minimum probability threshold
    if (_minProb > 0) {
      list = list.where((s) => s.probability >= _minProb).toList();
    }
    return list;
  }

  OhlcvBar? _barFor(AtlasSignal s) {
    if (_ohlcv.isEmpty) return null;
    OhlcvBar? best;
    var bd = const Duration(days: 999);
    for (final b in _ohlcv) {
      final d = b.ts.difference(s.ts).abs();
      if (d < bd) {
        bd = d;
        best = b;
      }
    }
    return best;
  }

  int get _totalCount => _signals.length;
  int get _entryCount => _signals.where((s) => s.entry).length;
  int get _upCount => _signals.where((s) => s.upBreakout).length;
  int get _downCount => _signals.where((s) => s.lowBreakout).length;
  int get _strongCount => _signals.where((s) => s.isStrong).length;
  double get _avgProb => _signals.isEmpty
      ? 0.0
      : _signals.map((s) => s.probability).reduce((a, b) => a + b) /
          _signals.length;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: isDark ? _T.dBg : _T.lBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(isDark, cs),
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              Expanded(child: _ErrWidget(msg: _error!, onRetry: _fetch))
            else if (_ohlcv.isEmpty)
              Expanded(child: _EmptyWidget(date: _date))
            else ...[
              _buildFilterStrip(isDark, cs),
              // ── Probability snackbar ──
              _buildProbSnackbar(isDark, cs),
              // Chart
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
                  child: _buildChart(isDark, cs),
                ),
              ),
              // Bottom panel: scrollable signal cards
              _SignalCardList(
                key: const ValueKey('card-list'),
                signals: _filtered,
                isDark: isDark,
                onTap: (s) => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => _AtlasDetailSheet(signal: s, isDark: isDark),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── HEADER ──────────────────────────────────────────────────────────────
  Widget _buildHeader(bool isDark, ColorScheme cs) {
    final surface = isDark ? _T.dSurface : cs.surfaceContainerHighest;
    final border = isDark ? _T.dBorder : cs.outlineVariant;
    final textP = isDark ? _T.dTextP : _T.lTextP;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _IBtn(
              onTap: () => Navigator.of(context).maybePop(),
              isDark: isDark,
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  size: 15, color: cs.onSurface),
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Market Sentiment',
                  style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      letterSpacing: 2.5,
                      color: textP)),
              Text('Live Market Chart',
                  style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurface.withOpacity(0.45),
                      letterSpacing: 0.3)),
            ]),
            const Spacer(),
            // _IBtn(
            //   onTap: _fetch,
            //   isDark: isDark,
            //   child: Icon(Icons.refresh_rounded,
            //       size: 18, color: cs.onSurface.withOpacity(0.5)),
            // ),
            // SizedBox(width: 16),
            _IBtn(
              onTap: _gotoLogs,
              isDark: isDark,
              child: Icon(Icons.analytics_outlined,
                  size: 18, color: cs.onSurface.withOpacity(0.5)),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _symbol,
                  isDense: true,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: cs.primary),
                  dropdownColor: cs.surface,
                  icon: Icon(Icons.keyboard_arrow_down_rounded,
                      size: 16, color: cs.primary),
                  items: kSymbols
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _symbol = v);
                      _fetch();
                    }
                  },
                ),
              ),
            ),
            const Spacer(),
            _NavBtn(
                icon: Icons.chevron_left_rounded,
                onTap: () => _shiftDate(-1),
                isDark: isDark),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.calendar_today_rounded,
                      size: 12, color: cs.primary),
                  const SizedBox(width: 6),
                  Text(DateFormat('d MMM yyyy').format(_date),
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: cs.primary)),
                ]),
              ),
            ),
            const SizedBox(width: 6),
            _NavBtn(
              icon: Icons.chevron_right_rounded,
              onTap: _date.isBefore(
                      DateTime.now().subtract(const Duration(days: 1)))
                  ? () => _shiftDate(1)
                  : null,
              isDark: isDark,
            ),
          ]),
        ],
      ),
    );
  }

  // ── FILTER STRIP ─────────────────────────────────────────────────────────
  Widget _buildFilterStrip(bool isDark, ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      decoration: BoxDecoration(
        color: isDark ? _T.dSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? _T.dBorder : _T.lBorder),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StatChip(
              label: 'All',
              value: '$_totalCount',
              color: isDark ? _T.dTextP : _T.lTextP,
              active:
                  !_filterEntry && !_filterUp && !_filterDown && !_filterStrong,
              isDark: isDark,
              onTap: () => setState(() {
                _filterEntry = false;
                _filterUp = false;
                _filterDown = false;
                _filterStrong = false;
              }),
            ),
            _SDivider(isDark: isDark),
            _StatChip(
              label: 'Entry',
              value: '$_entryCount',
              color: _T.accent,
              active: _filterEntry,
              isDark: isDark,
              icon: Icons.flag_rounded,
              onTap: () => setState(() => _filterEntry = !_filterEntry),
            ),
            _SDivider(isDark: isDark),
            _StatChip(
              label: '▲ Up',
              value: '$_upCount',
              color: _T.bull,
              active: _filterUp,
              isDark: isDark,
              onTap: () => setState(() {
                _filterUp = !_filterUp;
                if (_filterUp) _filterDown = false;
              }),
            ),
            _SDivider(isDark: isDark),
            _StatChip(
              label: '▼ Down',
              value: '$_downCount',
              color: _T.bear,
              active: _filterDown,
              isDark: isDark,
              onTap: () => setState(() {
                _filterDown = !_filterDown;
                if (_filterDown) _filterUp = false;
              }),
            ),
            _SDivider(isDark: isDark),
            _StatChip(
              label: 'Strong',
              value: '$_strongCount',
              color: _T.strong,
              active: _filterStrong,
              isDark: isDark,
              icon: Icons.bolt_rounded,
              onTap: () => setState(() => _filterStrong = !_filterStrong),
            ),
          ],
        ),
      ),
    );
  }

  // ── PROBABILITY SNACKBAR ─────────────────────────────────────────────────
  Widget _buildProbSnackbar(bool isDark, ColorScheme cs) {
    final surface = isDark ? _T.dSurface : Colors.white;
    final border = isDark ? _T.dBorder : _T.lBorder;
    final textS = isDark ? _T.dTextS : _T.lTextS;
    final probColor = _T.probColor(_minProb > 0 ? _minProb : _avgProb);
    final activeColor = _T.probColor(_minProb);
    final isFiltering = _minProb > 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFiltering ? activeColor.withOpacity(0.4) : border,
          width: isFiltering ? 1.2 : 1.0,
        ),
      ),
      child: Row(
        children: [
          // ── Left label ──
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Prob ≥',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: textS,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 1),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 150),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'monospace',
                  color: isFiltering ? activeColor : textS,
                ),
                child: Text('${_minProb.toInt()}%'),
              ),
            ],
          ),
          const SizedBox(width: 10),

          // ── Slider ──
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: activeColor,
                inactiveTrackColor:
                    isDark ? const Color(0xFF2A2F3D) : const Color(0xFFE5E7EB),
                thumbColor: isFiltering ? activeColor : probColor,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 7.0),
                overlayShape:
                    const RoundSliderOverlayShape(overlayRadius: 14.0),
                overlayColor: activeColor.withOpacity(0.15),
                trackHeight: 3.5,
                // Tick marks at 0, 25, 50, 75, 100
                tickMarkShape:
                    const RoundSliderTickMarkShape(tickMarkRadius: 2),
                activeTickMarkColor: activeColor.withOpacity(0.6),
                inactiveTickMarkColor:
                    isDark ? const Color(0xFF3A4055) : const Color(0xFFD1D5DB),
              ),
              child: Slider(
                value: _minProb,
                min: 0,
                max: 100,
                divisions: 20, // steps of 5
                onChanged: (v) => setState(() => _minProb = v),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── CHART ─────────────────────────────────────────────────────────────────
  Widget _buildChart(bool isDark, ColorScheme cs) {
    final displayed = _filtered;

    // UP entry — triangles ABOVE high
    final upEntryPts = <_EP>[];
    // DOWN entry — inverted triangles BELOW low
    final downEntryPts = <_EP>[];
    for (final s in displayed.where((s) => s.entry)) {
      final b = _barFor(s);
      if (b == null) continue;
      final range = (b.high - b.low).abs();
      final offset = range > 0 ? range * 0.18 : b.close * 0.001;
      if (s.upBreakout) {
        upEntryPts
            .add(_EP(ts: b.ts, price: b.high + offset, signal: s, up: true));
      } else {
        downEntryPts
            .add(_EP(ts: b.ts, price: b.low - offset, signal: s, up: false));
      }
    }

    // Non-entry up small diamonds (blue)
    final nonEntryUpPts = <_EP>[];
    // Non-entry down small squares (red)
    final nonEntryDownPts = <_EP>[];
    for (final s in displayed.where((s) => !s.entry)) {
      final b = _barFor(s);
      if (b == null) continue;
      final range = (b.high - b.low).abs();
      final offset = range > 0 ? range * 0.07 : b.close * 0.0005;
      if (s.upBreakout) {
        nonEntryUpPts
            .add(_EP(ts: b.ts, price: b.high + offset, signal: s, up: true));
      } else {
        nonEntryDownPts
            .add(_EP(ts: b.ts, price: b.low - offset, signal: s, up: false));
      }
    }

    final gridColor = cs.outline.withOpacity(0.10);
    final labelColor = cs.onSurface.withOpacity(0.45);

    return SfCartesianChart(
      backgroundColor: Colors.transparent,
      plotAreaBorderWidth: 0,
      zoomPanBehavior: _zoom,
      trackballBehavior: _track,
      axes: const <ChartAxis>[],
      primaryXAxis: DateTimeAxis(
        intervalType: DateTimeIntervalType.minutes,
        interval: 60,
        dateFormat: DateFormat('HH:mm'),
        axisLine: AxisLine(width: 0.5, color: cs.outline.withOpacity(0.2)),
        majorGridLines: MajorGridLines(width: 0.3, color: gridColor),
        minorGridLines: const MinorGridLines(width: 0),
        labelStyle: TextStyle(fontSize: 10, color: labelColor),
        edgeLabelPlacement: EdgeLabelPlacement.shift,
      ),
      primaryYAxis: NumericAxis(
        numberFormat: NumberFormat('#,###'),
        axisLine: const AxisLine(width: 0),
        majorGridLines: MajorGridLines(width: 0.3, color: gridColor),
        labelStyle: TextStyle(fontSize: 10, color: labelColor),
        opposedPosition: true,
      ),
      series: <CartesianSeries>[
        // Candlestick
        CandleSeries<OhlcvBar, DateTime>(
          dataSource: _ohlcv,
          xValueMapper: (b, _) => b.ts,
          openValueMapper: (b, _) => b.open,
          highValueMapper: (b, _) => b.high,
          lowValueMapper: (b, _) => b.low,
          closeValueMapper: (b, _) => b.close,
          bullColor: _T.bull,
          bearColor: _T.bear,
          enableSolidCandles: true,
          animationDuration: 350,
          name: 'Price',
          legendIconType: LegendIconType.horizontalLine,
        ),

        // Non-entry UP — small blue diamonds above high
        if (!_filterDown && nonEntryUpPts.isNotEmpty)
          ScatterSeries<_EP, DateTime>(
            dataSource: nonEntryUpPts,
            xValueMapper: (p, _) => p.ts,
            yValueMapper: (p, _) => p.price,
            pointColorMapper: (_, __) => const Color(0xFF3B82F6),
            markerSettings: const MarkerSettings(
              height: 9,
              width: 9,
              shape: DataMarkerType.diamond,
              borderWidth: 1,
              borderColor: Colors.white,
            ),
            animationDuration: 300,
            opacity: 1.0,
            name: '◆ Up Signal',
            enableTooltip: false,
            legendIconType: LegendIconType.diamond,
          ),

        // Non-entry DOWN — small red squares below low
        if (!_filterUp && nonEntryDownPts.isNotEmpty)
          ScatterSeries<_EP, DateTime>(
            dataSource: nonEntryDownPts,
            xValueMapper: (p, _) => p.ts,
            yValueMapper: (p, _) => p.price,
            pointColorMapper: (_, __) => const Color(0xFFF43F5E),
            markerSettings: const MarkerSettings(
              height: 9,
              width: 9,
              shape: DataMarkerType.rectangle,
              borderWidth: 1,
              borderColor: Colors.white,
            ),
            animationDuration: 300,
            name: '■ Down Signal',
            enableTooltip: false,
            legendIconType: LegendIconType.rectangle,
          ),

        // UP entry — large green triangles ▲ above high
        if (!_filterDown && upEntryPts.isNotEmpty)
          ScatterSeries<_EP, DateTime>(
            dataSource: upEntryPts,
            xValueMapper: (p, _) => p.ts,
            yValueMapper: (p, _) => p.price,
            pointColorMapper: (p, _) => p.signal.isStrong
                ? const Color(0xFF1D4ED8)
                : const Color(0xFF3B82F6),
            markerSettings: const MarkerSettings(
              isVisible: true,
              height: 16,
              width: 16,
              shape: DataMarkerType.triangle,
              borderWidth: 1.5,
              borderColor: Colors.white,
            ),
            animationDuration: 500,
            name: '▲ Bull Entry',
            onPointTap: (args) {
              if (args.pointIndex != null &&
                  args.pointIndex! < upEntryPts.length) {
                final s = upEntryPts[args.pointIndex!].signal;
                final dark = Theme.of(context).brightness == Brightness.dark;
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => _AtlasDetailSheet(signal: s, isDark: dark),
                );
              }
            },
          ),

        // DOWN entry — large red inverted triangles ▼ below low
        if (!_filterUp && downEntryPts.isNotEmpty)
          ScatterSeries<_EP, DateTime>(
            dataSource: downEntryPts,
            xValueMapper: (p, _) => p.ts,
            yValueMapper: (p, _) => p.price,
            pointColorMapper: (p, _) => p.signal.isStrong
                ? const Color(0xFFBE123C)
                : const Color(0xFFF43F5E),
            markerSettings: const MarkerSettings(
              height: 16,
              width: 16,
              shape: DataMarkerType.invertedTriangle,
              borderWidth: 1.5,
              borderColor: Colors.white,
            ),
            animationDuration: 500,
            name: '▼ Bear Entry',
            onPointTap: (args) {
              if (args.pointIndex != null &&
                  args.pointIndex! < downEntryPts.length) {
                final s = downEntryPts[args.pointIndex!].signal;
                final dark = Theme.of(context).brightness == Brightness.dark;
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => _AtlasDetailSheet(signal: s, isDark: dark),
                );
              }
            },
          ),
      ],
      legend: Legend(
        isVisible: true,
        position: LegendPosition.top,
        textStyle:
            TextStyle(fontSize: 10, color: cs.onSurface.withOpacity(0.55)),
        iconHeight: 10,
        iconWidth: 10,
        overflowMode: LegendItemOverflowMode.wrap,
        padding: 4,
      ),
      tooltipBehavior: TooltipBehavior(enable: false),
    );
  }
}

// ─────────────────────────────────────────────
// SIGNAL CARD LIST (bottom panel)
// ─────────────────────────────────────────────
class _SignalCardList extends StatelessWidget {
  final List<AtlasSignal> signals;
  final bool isDark;
  final ValueChanged<AtlasSignal> onTap;

  const _SignalCardList({
    super.key,
    required this.signals,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textS = isDark ? _T.dTextS : _T.lTextS;

    if (signals.isEmpty) {
      return Container(
        height: 72,
        alignment: Alignment.center,
        color: (isDark ? _T.dSurface : _T.lSurface).withOpacity(0.4),
        child: Text('No signals for current filter',
            style: TextStyle(fontSize: 12, color: textS)),
      );
    }

    return Container(
      height: 145,
      color: isDark ? _T.dBg.withOpacity(0.85) : _T.lBg.withOpacity(0.85),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
            child: Row(children: [
              Text('${signals.length} Signals',
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600, color: textS)),
              const Spacer(),
              Text('Tap to view details',
                  style: TextStyle(fontSize: 10, color: textS)),
            ]),
          ),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              itemCount: signals.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => _MiniSignalCard(
                signal: signals[i],
                isDark: isDark,
                onTap: () => onTap(signals[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mini card ────────────────────────────────────────────────────────────────
class _MiniSignalCard extends StatelessWidget {
  final AtlasSignal signal;
  final bool isDark;
  final VoidCallback onTap;

  const _MiniSignalCard({
    required this.signal,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = signal;
    final surface = isDark ? _T.dSurface : _T.lSurface;
    final border = isDark ? _T.dBorder : _T.lBorder;
    final textS = isDark ? _T.dTextS : _T.lTextS;
    final dim = isDark ? s.dirDimDark : s.dirDimLight;
    final pc = _T.probColor(s.probability);
    final total = s.posCount + s.neutCount + s.negCount;

    return _TapScale(
      onTap: onTap,
      child: Container(
        width: 210,
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(_T.rMD),
          border: Border.all(color: border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Accent strip
            Container(
              height: 3,
              decoration: BoxDecoration(
                color: s.dirColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(_T.rMD),
                  topRight: Radius.circular(_T.rMD),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: direction badge + prob badge
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 4),
                      decoration: BoxDecoration(
                        color: dim,
                        borderRadius: BorderRadius.circular(_T.rSM),
                        border: Border.all(color: s.dirColor.withOpacity(0.3)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(s.dirIcon, size: 10, color: s.dirColor),
                        const SizedBox(width: 3),
                        Text(s.dirLabel.toUpperCase(),
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: s.dirColor,
                                letterSpacing: 0.8)),
                      ]),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: pc.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(_T.rXS),
                        border: Border.all(color: pc.withOpacity(0.28)),
                      ),
                      child: Text('${s.probability.toStringAsFixed(1)}%',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: pc)),
                    ),
                  ]),
                  const SizedBox(height: 7),
                  // Inline indicator bar
                  if (total > 0) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: SizedBox(
                        height: 4,
                        child: Row(children: [
                          if (s.posCount > 0)
                            Expanded(
                                flex: s.posCount,
                                child: Container(color: _T.bull)),
                          if (s.neutCount > 0)
                            Expanded(
                                flex: s.neutCount,
                                child: Container(color: _T.neutral)),
                          if (s.negCount > 0)
                            Expanded(
                                flex: s.negCount,
                                child: Container(color: _T.bear)),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Counts row — same style as dialog _IndLabel
                    Row(children: [
                      _IndLabel(color: _T.bull, label: '+${s.posCount}'),
                      const SizedBox(width: 8),
                      _IndLabel(color: _T.neutral, label: '~${s.neutCount}'),
                      const SizedBox(width: 8),
                      _IndLabel(color: _T.bear, label: '-${s.negCount}'),
                    ]),
                    const SizedBox(height: 6),
                  ],
                  // Row 3: time + timeago + badges
                  Row(children: [
                    Icon(Icons.schedule_rounded, size: 10, color: textS),
                    const SizedBox(width: 3),
                    Text(DateFormat('HH:mm').format(s.ts),
                        style: TextStyle(
                            fontSize: 10,
                            color: textS,
                            fontFamily: 'monospace')),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(timeago.format(s.ts),
                          style: TextStyle(
                              fontSize: 9, color: textS.withOpacity(0.6)),
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (s.entry)
                      _MiniChip(
                          label: 'Entry',
                          color: _T.accent,
                          icon: Icons.flag_rounded),
                    if (s.isStrong) ...[
                      const SizedBox(width: 4),
                      _MiniChip(
                          label: 'Strong',
                          color: _T.strong,
                          icon: Icons.bolt_rounded),
                    ],
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _MiniChip(
      {required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(_T.rXS),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 8, color: color),
        const SizedBox(width: 2),
        Text(label,
            style: TextStyle(
                fontSize: 8, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────
// DETAIL SHEET
// ─────────────────────────────────────────────
class _AtlasDetailSheet extends StatelessWidget {
  final AtlasSignal signal;
  final bool isDark;
  const _AtlasDetailSheet({required this.signal, required this.isDark});

  _AtlasOutputCompat _toOutput() {
    final s = signal;
    return _AtlasOutputCompat(
      id: s.id,
      createdAt: s.ts.toIso8601String(),
      negativeIndicators: s.negCount,
      negativeIndicatorsList: s.negList.join(', '),
      neutralIndicators: s.neutCount,
      neutralIndicatorsList: s.neutList.join(', '),
      positiveIndicators: s.posCount,
      positiveIndicatorsList: s.posList.join(', '),
      crossovers: s.crossovers,
      advancing: s.advancing,
      declining: s.declining,
      breakoutvalue: s.breakoutValue.toInt(),
      entry: s.entry,
      longterm: s.longTerm,
      shortterm: s.shortTerm,
      lowbreakout: s.lowBreakout,
      upbreakout: s.upBreakout,
      probability: s.probability,
      type: s.type,
      time: DateFormat('HH:mm').format(s.ts),
    );
  }

  @override
  Widget build(BuildContext context) {
    final out = _toOutput();
    return _InlineDetail(output: out, isDark: isDark);
  }
}

/// Standalone detail panel rendered inline.
class _InlineDetail extends StatelessWidget {
  final _AtlasOutputCompat output;
  final bool isDark;
  const _InlineDetail({required this.output, required this.isDark});

  Color _probColor(double p) {
    if (p >= 65) return _T.probHigh;
    if (p >= 50) return _T.probMid;
    return _T.probLow;
  }

  @override
  Widget build(BuildContext context) {
    final o = output;
    final surface = isDark ? _T.dSurface : _T.lSurface;
    final textS = isDark ? _T.dTextS : _T.lTextS;
    final isBull = o.type == 'Bull' || o.upbreakout;
    final dirColor = isBull ? _T.bull : _T.bear;
    final dim = isDark
        ? (isBull ? _T.bullDim : _T.bearDim)
        : (isBull ? _T.bullDimL : _T.bearDimL);
    final dirIcon =
        isBull ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;
    final pc = _probColor(o.probability);
    final total =
        o.positiveIndicators + o.negativeIndicators + o.neutralIndicators;
    final ts = DateTime.parse(o.createdAt);

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
            top: BorderSide(color: dirColor.withOpacity(0.6), width: 2.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ──
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 10),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? _T.dBorder : _T.lBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Header: prob pill + dir badge + time ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Large probability pill on the left
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: pc.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: pc.withOpacity(0.4)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${o.probability.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: pc,
                          fontSize: 18,
                          fontFamily: 'monospace',
                          height: 1.1,
                        ),
                      ),
                      Text(
                        'PROB',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          color: pc.withOpacity(0.7),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Direction + time stack
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Direction badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: dim,
                          borderRadius: BorderRadius.circular(_T.rSM),
                          border: Border.all(color: dirColor.withOpacity(0.3)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(dirIcon, size: 11, color: dirColor),
                          const SizedBox(width: 4),
                          Text(isBull ? 'BULL' : 'BEAR',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: dirColor,
                                  letterSpacing: 0.8)),
                        ]),
                      ),
                    ],
                  ),
                ),
                // Status badge column on right
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (o.probability >= 50)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: _T.strong.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(_T.rXS),
                          border: Border.all(color: _T.strong.withOpacity(0.3)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.bolt_rounded, size: 9, color: _T.strong),
                          const SizedBox(width: 3),
                          Text('STRONG',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: _T.strong)),
                        ]),
                      ),
                    if (o.probability >= 50 && o.entry)
                      const SizedBox(height: 5),
                    if (o.entry)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: _T.accentDim,
                          borderRadius: BorderRadius.circular(_T.rXS),
                          border: Border.all(color: _T.accent.withOpacity(0.3)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.flag_rounded, size: 9, color: _T.accent),
                          const SizedBox(width: 3),
                          Text('ENTRY',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: _T.accent)),
                        ]),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // ── Row 1 chips: Pos / Neg / Neut / Cross / Brkout ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: Row(children: [
              _DC('▲ Pos', '${o.positiveIndicators}', _T.bull),
              _DC('▼ Neg', '${o.negativeIndicators}', _T.bear),
              _DC('= Neut', '${o.neutralIndicators}', _T.neutral),
              _DC('Cross', '${o.crossovers}', const Color(0xFFAB47BC)),
              _DC('Brkout', '${o.breakoutvalue}', const Color(0xFF42A5F5)),
              _DC('Adv', '${o.advancing}', _T.bull),
              _DC('Dec', '${o.declining}', _T.bear),
              const SizedBox(width: 6),
              // Long Term styled badge
              _TermBadge(
                label: 'Long Term',
                value: o.longterm.toUpperCase(),
                color: o.longterm.toLowerCase().contains('bull')
                    ? _T.bull
                    : o.longterm.toLowerCase().contains('bear')
                        ? _T.bear
                        : _T.neutral,
              ),
              const SizedBox(width: 6),
              // Short Term styled badge
              _TermBadge(
                label: 'Short Term',
                value: o.shortterm.toUpperCase(),
                color: o.shortterm.toLowerCase().contains('bull')
                    ? _T.bull
                    : o.shortterm.toLowerCase().contains('bear')
                        ? _T.bear
                        : _T.neutral,
              ),
            ]),
          ),

          // ── Indicator bar ──
          if (total > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: SizedBox(
                  height: 5,
                  child: Row(children: [
                    if (o.positiveIndicators > 0)
                      Expanded(
                          flex: o.positiveIndicators,
                          child: Container(color: _T.bull)),
                    if (o.neutralIndicators > 0)
                      Expanded(
                          flex: o.neutralIndicators,
                          child: Container(color: _T.neutral)),
                    if (o.negativeIndicators > 0)
                      Expanded(
                          flex: o.negativeIndicators,
                          child: Container(color: _T.bear)),
                  ]),
                ),
              ),
            ),

          // ── Indicator label row + time/timeago ──
          if (total > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
              child: Row(children: [
                _IndLabel(color: _T.bull, label: '+${o.positiveIndicators}'),
                const SizedBox(width: 8),
                _IndLabel(color: _T.neutral, label: '~${o.neutralIndicators}'),
                const SizedBox(width: 8),
                _IndLabel(color: _T.bear, label: '-${o.negativeIndicators}'),
                const SizedBox(width: 10),
                Container(
                    width: 1,
                    height: 10,
                    color: isDark ? _T.dBorder : _T.lBorder),
                const SizedBox(width: 10),
                Icon(Icons.schedule_rounded, size: 9, color: textS),
                const SizedBox(width: 3),
                Text(
                  DateFormat('HH:mm · d MMM').format(ts),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: textS,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  '· ${timeago.format(ts)}',
                  style: TextStyle(fontSize: 9, color: textS.withOpacity(0.6)),
                ),
              ]),
            ),

          // ── Positive + Negative indicator tiles stacked full-width ──
          if (o.positiveIndicatorsList.isNotEmpty ||
              o.negativeIndicatorsList.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (o.positiveIndicatorsList.isNotEmpty)
                    _IndTile(
                        label: 'Positive',
                        items: o.positiveIndicatorsList
                            .split(',')
                            .map((e) => e.trim())
                            .toList(),
                        color: _T.bull),
                  if (o.positiveIndicatorsList.isNotEmpty &&
                      o.negativeIndicatorsList.isNotEmpty)
                    const SizedBox(height: 8),
                  if (o.negativeIndicatorsList.isNotEmpty)
                    _IndTile(
                        label: 'Negative',
                        items: o.negativeIndicatorsList
                            .split(',')
                            .map((e) => e.trim())
                            .toList(),
                        color: _T.bear),
                ],
              ),
            )
          else
            const SizedBox(height: 12),
        ],
      ),
    );
  }
}

/// Styled Long Term / Short Term badge
class _TermBadge extends StatelessWidget {
  final String label, value;
  final Color color;
  const _TermBadge(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(_T.rSM),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: color,
                  fontFamily: 'monospace')),
          const SizedBox(height: 1),
          Text(label,
              style: const TextStyle(fontSize: 8.5, color: Colors.grey)),
        ]),
      );
}

/// Lightweight data holder
class _AtlasOutputCompat {
  final int id;
  final String createdAt;
  final int negativeIndicators;
  final String negativeIndicatorsList;
  final int neutralIndicators;
  final String neutralIndicatorsList;
  final int positiveIndicators;
  final String positiveIndicatorsList;
  final int crossovers, advancing, declining, breakoutvalue;
  final bool entry, lowbreakout, upbreakout;
  final double probability;
  final String longterm, shortterm, type, time;

  const _AtlasOutputCompat({
    required this.id,
    required this.createdAt,
    required this.negativeIndicators,
    required this.negativeIndicatorsList,
    required this.neutralIndicators,
    required this.neutralIndicatorsList,
    required this.positiveIndicators,
    required this.positiveIndicatorsList,
    required this.crossovers,
    required this.advancing,
    required this.declining,
    required this.breakoutvalue,
    required this.entry,
    required this.longterm,
    required this.lowbreakout,
    required this.upbreakout,
    required this.probability,
    required this.shortterm,
    required this.type,
    required this.time,
  });
}

// ─────────────────────────────────────────────
// SHARED ATOMS
// ─────────────────────────────────────────────
class _DC extends StatelessWidget {
  final String label, value;
  final Color color;
  const _DC(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: color,
                  fontFamily: 'monospace')),
          Text(label,
              style: const TextStyle(fontSize: 8.5, color: Colors.grey)),
        ]),
      );
}

class _IndTile extends StatelessWidget {
  final String label;
  final List<dynamic> items;
  final Color color;
  const _IndTile(
      {required this.label, required this.items, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 2,
            children: items
                .take(6)
                .map((item) => Text('· $item',
                    style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.65))))
                .toList(),
          ),
        ]),
      );
}

class _IndLabel extends StatelessWidget {
  final Color color;
  final String label;
  const _IndLabel({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(
                fontSize: 9, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// HEADER BUTTONS
// ─────────────────────────────────────────────
class _IBtn extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool isDark;
  const _IBtn({required this.child, required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: isDark ? _T.dSurface : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: cs.outlineVariant),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isDark;
  const _NavBtn(
      {required this.icon, required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 34,
        decoration: BoxDecoration(
          color: isDark ? _T.dSurface : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: cs.outlineVariant),
        ),
        alignment: Alignment.center,
        child: Icon(icon,
            size: 18,
            color: onTap != null
                ? cs.onSurface.withOpacity(0.7)
                : cs.onSurface.withOpacity(0.2)),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// FILTER CHIP (stat strip)
// ─────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label, value;
  final Color color;
  final bool active;
  final bool isDark;
  final IconData? icon;
  final VoidCallback onTap;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.active,
    required this.isDark,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active
                ? color.withOpacity(isDark ? 0.18 : 0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (icon != null) ...[
                Icon(icon,
                    size: 9, color: active ? color : color.withOpacity(0.45)),
                const SizedBox(width: 2),
              ],
              Text(value,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: active ? color : color.withOpacity(0.5),
                  )),
            ]),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  color: active
                      ? color.withOpacity(0.8)
                      : (isDark
                          ? const Color(0xFF828A9B)
                          : const Color(0xFF9CA3AF)),
                )),
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: active ? 18 : 0,
              height: 2.5,
              decoration: BoxDecoration(
                color: active ? color : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _SDivider extends StatelessWidget {
  final bool isDark;
  const _SDivider({required this.isDark});
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        color: isDark ? _T.dBorder : _T.lBorder,
      );
}

// ─────────────────────────────────────────────
// TAP SCALE
// ─────────────────────────────────────────────
class _TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _TapScale({required this.child, required this.onTap});
  @override
  State<_TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<_TapScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 90));
    _scale = Tween<double>(begin: 1.0, end: 0.95)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

// ─────────────────────────────────────────────
// ERROR / EMPTY
// ─────────────────────────────────────────────
class _ErrWidget extends StatelessWidget {
  final String msg;
  final VoidCallback onRetry;
  const _ErrWidget({required this.msg, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: _T.bear),
            const SizedBox(height: 12),
            Text(msg,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 16),
            FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Retry')),
          ]),
        ),
      );
}

class _EmptyWidget extends StatelessWidget {
  final DateTime date;
  const _EmptyWidget({required this.date});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.bar_chart_rounded,
              size: 56,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.15)),
          const SizedBox(height: 12),
          Text('No data for ${DateFormat('dd MMM yyyy').format(date)}',
              style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.4))),
        ]),
      );
}
