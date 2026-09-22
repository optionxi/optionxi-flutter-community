import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:optionxi/Main_Pages/MarketSentiments/act_market_sentiments.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:timeago/timeago.dart' as timeago;

const List<String> kSymbols = ['NIFTY', 'BANKNIFTY'];

String symbolLabel(String s) =>
    s == 'NIFTY' ? 'Nifty 50' : (s == 'BANKNIFTY' ? 'Bank Nifty' : s);

// ═════════════════════════════════════════════════════════════════════════════
// Models
// ═════════════════════════════════════════════════════════════════════════════
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

  bool get isBull => type == 'Bull' || upBreakout;
  Mood get mood => isBull ? SX.up : SX.down;
  int get total => posCount + neutCount + negCount;

  String get summary {
    if (total == 0) return mood.plain;
    final n = isBull ? posCount : negCount;
    return '$n of $total market gauges say ${mood.voteWord}.';
  }
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

// ═════════════════════════════════════════════════════════════════════════════
// Service
// ═════════════════════════════════════════════════════════════════════════════
class AtlasChartService {
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
    return (data as List)
        .map((e) => OhlcvBar.fromJson(e as Map<String, dynamic>))
        .toList();
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
    return (data as List)
        .map((e) => AtlasSignal.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

class _EP {
  final DateTime ts;
  final double price;
  final AtlasSignal signal;
  _EP({required this.ts, required this.price, required this.signal});
}

// ═════════════════════════════════════════════════════════════════════════════
// Page
// ═════════════════════════════════════════════════════════════════════════════
class MarketSentimentChartPage extends StatefulWidget {
  /// Day to open on (defaults to the latest market day).
  final DateTime? initialDate;

  /// true when opened from the list page (header button then goes back).
  final bool fromList;

  const MarketSentimentChartPage({
    super.key,
    this.initialDate,
    this.fromList = false,
  });

  @override
  State<MarketSentimentChartPage> createState() =>
      _MarketSentimentChartPageState();
}

class _MarketSentimentChartPageState extends State<MarketSentimentChartPage> {
  late DateTime _date;
  String _symbol = kSymbols.first;
  List<OhlcvBar> _ohlcv = [];
  List<AtlasSignal> _signals = [];
  bool _loading = false;
  String? _error;
  int _req = 0;

  bool _fresh = false;
  int _dir = 0; // 0 any, 1 up, 2 down
  double _minProb = SX.mediumProb;

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
    final d = widget.initialDate;
    _date = d != null ? DateTime(d.year, d.month, d.day) : _todayMarket();
    _track = TrackballBehavior(
      enable: true,
      activationMode: ActivationMode.singleTap,
      tooltipDisplayMode: TrackballDisplayMode.groupAllPoints,
    );
    _fetch();
  }

  // ── data ────────────────────────────────────────────────────────────────
  Future<void> _fetch() async {
    final req = ++_req;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final (o, s) = await (
        AtlasChartService.fetchOhlcv(_date, _symbol),
        AtlasChartService.fetchAtlas(_date),
      ).wait;
      if (!mounted || req != _req) return;
      setState(() {
        _ohlcv = o;
        _signals = s;
        _loading = false;
      });
    } catch (e) {
      debugPrint('chart fetch error: $e');
      if (!mounted || req != _req) return;
      setState(() {
        _error =
            'We couldn\'t load this day. Check your internet connection and try again.';
        _loading = false;
      });
    }
  }

  bool get _canGoForward {
    final t = DateTime.now();
    return _date.isBefore(DateTime(t.year, t.month, t.day));
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
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: SX.accent),
        ),
        child: child!,
      ),
    );
    if (p != null && mounted && p != _date) {
      setState(() => _date = DateTime(p.year, p.month, p.day));
      _fetch();
    }
  }

  String get _dateLabel {
    final t = DateTime.now();
    final today = DateTime(t.year, t.month, t.day);
    final diff = today.difference(_date).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormat('d MMM yyyy').format(_date);
  }

  // ── derived ─────────────────────────────────────────────────────────────
  List<AtlasSignal> get _filtered => _signals
      .where((s) =>
          (!_fresh || s.entry) &&
          (_dir == 0 || (_dir == 1) == s.isBull) &&
          s.probability >= _minProb)
      .toList();

  int get _upCount => _signals.where((s) => s.isBull).length;
  int get _downCount => _signals.length - _upCount;
  int get _freshCount => _signals.where((s) => s.entry).length;

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

  void _openSheet(AtlasSignal s) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _SignalSheet(signal: s),
      );

  void _toList() {
    if (widget.fromList) {
      Navigator.of(context).maybePop();
    } else {
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const MarketSentimentPage(fromChart: true)));
    }
  }

  // ── build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: context.sxBg,
        body: SafeArea(
          child: Column(children: [
            _header(context),
            Expanded(
              child: RefreshIndicator(
                color: SX.accent,
                onRefresh: _fetch,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: _slivers(context),
                ),
              ),
            ),
          ]),
        ),
      );

  List<Widget> _slivers(BuildContext context) {
    if (_loading) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator(color: SX.accent)),
        ),
      ];
    }
    if (_error != null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: SxMessage(
            icon: Icons.cloud_off_rounded,
            color: SX.bear,
            title: 'Can\'t reach the server',
            body: _error!,
            actionLabel: 'Try again',
            onAction: _fetch,
          ),
        ),
      ];
    }
    if (_ohlcv.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: SxMessage(
            icon: Icons.event_busy_rounded,
            title: 'No prices for ${DateFormat('d MMM yyyy').format(_date)}',
            body:
                'The market may have been closed (weekend or holiday). Try another day.',
            actionLabel: 'Go to the previous day',
            onAction: () => _shiftDate(-1),
          ),
        ),
      ];
    }

    final list = _filtered.reversed.toList();
    return [
      SliverToBoxAdapter(child: _summaryCard(context)),
      SliverToBoxAdapter(child: _filterCard(context)),
      SliverToBoxAdapter(child: _chartCard(context)),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
          child: Row(children: [
            Text('Signals (${list.length})',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: context.sxTextP)),
            const Spacer(),
            Text('Newest first',
                style: TextStyle(fontSize: 11.5, color: context.sxTextS)),
          ]),
        ),
      ),
      if (list.isEmpty)
        SliverToBoxAdapter(
          child: SxMessage(
            icon: Icons.filter_alt_off_rounded,
            title: 'No signals match',
            body:
                'Lower the minimum confidence or turn off a filter to see more.',
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) =>
                  _SignalTile(s: list[i], onTap: () => _openSheet(list[i])),
              childCount: list.length,
            ),
          ),
        ),
    ];
  }

  // ── header ──────────────────────────────────────────────────────────────
  Widget _header(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: context.sxBg,
          border: Border(bottom: BorderSide(color: context.sxBorder)),
        ),
        child: Column(children: [
          Row(children: [
            SxIconBtn(
              icon: Icons.arrow_back_ios_new_rounded,
              size: 15,
              onTap: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Market chart',
                        style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: context.sxTextP)),
                    const SizedBox(height: 2),
                    Text('Prices with Atlas signals on top',
                        style:
                            TextStyle(fontSize: 11.5, color: context.sxTextS)),
                  ]),
            ),
            SxIconBtn(
              icon: Icons.help_outline_rounded,
              tooltip: 'How to read this',
              onTap: () => showSentimentGuide(context),
            ),
            const SizedBox(width: 8),
            SxPillBtn(
                icon: Icons.view_list_rounded, label: 'List', onTap: _toList),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            // Symbol switch
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: context.sxSurface,
                borderRadius: BorderRadius.circular(SX.rMD),
                border: Border.all(color: context.sxBorder),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                for (final s in kSymbols)
                  GestureDetector(
                    onTap: () {
                      if (s == _symbol) return;
                      setState(() => _symbol = s);
                      _fetch();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: s == _symbol ? SX.accent : Colors.transparent,
                        borderRadius: BorderRadius.circular(SX.rSM),
                      ),
                      child: Text(symbolLabel(s),
                          style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: s == _symbol
                                  ? Colors.white
                                  : context.sxTextS)),
                    ),
                  ),
              ]),
            ),
            const Spacer(),
            // Day switch
            Container(
              height: 38,
              decoration: BoxDecoration(
                color: context.sxSurface,
                borderRadius: BorderRadius.circular(SX.rMD),
                border: Border.all(color: context.sxBorder),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                _NavBtn(
                    icon: Icons.chevron_left_rounded,
                    onTap: () => _shiftDate(-1)),
                GestureDetector(
                  onTap: _pickDate,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 13, color: context.sxTextS),
                      const SizedBox(width: 6),
                      Text(_dateLabel,
                          style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: context.sxTextP)),
                    ]),
                  ),
                ),
                _NavBtn(
                  icon: Icons.chevron_right_rounded,
                  onTap: _canGoForward ? () => _shiftDate(1) : null,
                ),
              ]),
            ),
          ]),
        ]),
      );

  // ── summary ─────────────────────────────────────────────────────────────
  Widget _summaryCard(BuildContext context) {
    final first = _ohlcv.first, last = _ohlcv.last;
    final change = last.close - first.open;
    final pct = first.open == 0 ? 0.0 : change / first.open * 100;
    final isUp = change >= 0;
    final col = isUp ? SX.bull : SX.bear;
    final hi = _ohlcv.map((b) => b.high).reduce((a, b) => a > b ? a : b);
    final lo = _ohlcv.map((b) => b.low).reduce((a, b) => a < b ? a : b);
    final nf = NumberFormat('#,##0.00');

    String sentence;
    if (_signals.isEmpty) {
      sentence = 'Atlas has not raised any signals for this day.';
    } else {
      final lean = _upCount > _downCount
          ? 'Most signals pointed up'
          : (_downCount > _upCount
              ? 'Most signals pointed down'
              : 'Signals were split evenly');
      sentence =
          '$lean. Atlas raised ${_signals.length} in total: $_upCount up, $_downCount down, $_freshCount of them fresh moves.';
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(context),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(symbolLabel(_symbol),
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: context.sxTextS)),
              const SizedBox(height: 2),
              Text(nf.format(last.close),
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                      color: context.sxTextP)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: col.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(SX.rSM),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(
                  isUp
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 14,
                  color: col),
              const SizedBox(width: 4),
              Text(
                  '${change.abs().toStringAsFixed(1)} (${pct.abs().toStringAsFixed(2)}%)',
                  style: TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w700, color: col)),
            ]),
          ),
        ]),
        const SizedBox(height: 4),
        Text(isUp ? 'Up since the open' : 'Down since the open',
            style: TextStyle(fontSize: 11.5, color: context.sxTextS)),
        const SizedBox(height: 14),
        Row(children: [
          _MiniStat(label: 'Open', value: nf.format(first.open)),
          _MiniStat(label: 'Highest', value: nf.format(hi)),
          _MiniStat(label: 'Lowest', value: nf.format(lo)),
        ]),
        Divider(height: 24, color: context.sxBorder),
        Text(sentence,
            style:
                TextStyle(fontSize: 13, height: 1.4, color: context.sxTextP)),
      ]),
    );
  }

  // ── filters ─────────────────────────────────────────────────────────────
  Widget _filterCard(BuildContext context) {
    final active = SX.probColor(_minProb);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: _cardDeco(context),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Choose what to show',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: context.sxTextP)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _CountPill(
            label: 'All',
            count: _signals.length,
            color: SX.accent,
            active: !_fresh && _dir == 0,
            onTap: () => setState(() {
              _fresh = false;
              _dir = 0;
            }),
          ),
          _CountPill(
            label: 'Fresh moves',
            count: _freshCount,
            color: SX.accent,
            icon: Icons.flag_rounded,
            active: _fresh,
            onTap: () => setState(() => _fresh = !_fresh),
          ),
          _CountPill(
            label: 'Going up',
            count: _upCount,
            color: SX.bull,
            icon: Icons.trending_up_rounded,
            active: _dir == 1,
            onTap: () => setState(() => _dir = _dir == 1 ? 0 : 1),
          ),
          _CountPill(
            label: 'Going down',
            count: _downCount,
            color: SX.bear,
            icon: Icons.trending_down_rounded,
            active: _dir == 2,
            onTap: () => setState(() => _dir = _dir == 2 ? 0 : 2),
          ),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Text('Minimum confidence',
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: context.sxTextP)),
          const Spacer(),
          Text('${_minProb.round()}%',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800, color: active)),
        ]),
        Text('Hides signals the engine is less sure about.',
            style: TextStyle(fontSize: 11.5, color: context.sxTextS)),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: active,
            thumbColor: active,
            inactiveTrackColor: context.isDark
                ? const Color(0xFF2A2F3D)
                : const Color(0xFFE5E7EB),
            overlayColor: active.withValues(alpha: 0.15),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
          ),
          child: Slider(
            value: _minProb,
            min: 0,
            max: 100,
            divisions: 20,
            onChanged: (v) => setState(() => _minProb = v),
          ),
        ),
      ]),
    );
  }

  // ── chart ───────────────────────────────────────────────────────────────
  Widget _chartCard(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.fromLTRB(8, 14, 8, 10),
        decoration: _cardDeco(context),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(children: [
              Text('Price chart',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: context.sxTextP)),
              const Spacer(),
              Text('Tap a marker for details',
                  style: TextStyle(fontSize: 11, color: context.sxTextS)),
            ]),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Wrap(spacing: 14, runSpacing: 4, children: [
              _LegendItem('▲', SX.bull, 'Fresh up move'),
              _LegendItem('▼', SX.bear, 'Fresh down move'),
              _LegendItem('◆', SX.bull, 'Up signal'),
              _LegendItem('■', SX.bear, 'Down signal'),
            ]),
          ),
          const SizedBox(height: 4),
          SizedBox(height: 340, child: _chart(context)),
        ]),
      );

  ScatterSeries<_EP, DateTime> _marker(
    List<_EP> pts, {
    required Color Function(_EP) color,
    required DataMarkerType shape,
    required double size,
    required String name,
  }) =>
      ScatterSeries<_EP, DateTime>(
        dataSource: pts,
        xValueMapper: (p, _) => p.ts,
        yValueMapper: (p, _) => p.price,
        pointColorMapper: (p, _) => color(p),
        markerSettings: MarkerSettings(
          isVisible: true,
          height: size,
          width: size,
          shape: shape,
          borderWidth: 1.5,
          borderColor: Colors.white,
        ),
        animationDuration: 400,
        name: name,
        enableTooltip: false,
        onPointTap: (args) {
          final i = args.pointIndex;
          if (i != null && i < pts.length) _openSheet(pts[i].signal);
        },
      );

  Widget _chart(BuildContext context) {
    final bigUp = <_EP>[],
        bigDown = <_EP>[],
        smallUp = <_EP>[],
        smallDown = <_EP>[];

    for (final s in _filtered) {
      final b = _barFor(s);
      if (b == null) continue;
      final range = (b.high - b.low).abs();
      final off = range > 0
          ? range * (s.entry ? 0.18 : 0.07)
          : b.close * (s.entry ? 0.001 : 0.0005);
      if (s.isBull) {
        final p = _EP(ts: b.ts, price: b.high + off, signal: s);
        (s.entry ? bigUp : smallUp).add(p);
      } else {
        final p = _EP(ts: b.ts, price: b.low - off, signal: s);
        (s.entry ? bigDown : smallDown).add(p);
      }
    }

    final grid = context.sxTextS.withValues(alpha: 0.18);
    final label = context.sxTextS;

    return SfCartesianChart(
      backgroundColor: Colors.transparent,
      plotAreaBorderWidth: 0,
      trackballBehavior: _track,
      legend: const Legend(isVisible: false),
      tooltipBehavior: TooltipBehavior(enable: false),
      primaryXAxis: DateTimeAxis(
        intervalType: DateTimeIntervalType.minutes,
        interval: 60,
        dateFormat: DateFormat('h:mm a'),
        axisLine: AxisLine(width: 0.5, color: grid),
        majorGridLines: MajorGridLines(width: 0.3, color: grid),
        minorGridLines: const MinorGridLines(width: 0),
        labelStyle: TextStyle(fontSize: 10, color: label),
        edgeLabelPlacement: EdgeLabelPlacement.shift,
      ),
      primaryYAxis: NumericAxis(
        numberFormat: NumberFormat('#,###'),
        axisLine: const AxisLine(width: 0),
        majorGridLines: MajorGridLines(width: 0.3, color: grid),
        labelStyle: TextStyle(fontSize: 10, color: label),
        opposedPosition: true,
      ),
      series: <CartesianSeries>[
        CandleSeries<OhlcvBar, DateTime>(
          dataSource: _ohlcv,
          xValueMapper: (b, _) => b.ts,
          openValueMapper: (b, _) => b.open,
          highValueMapper: (b, _) => b.high,
          lowValueMapper: (b, _) => b.low,
          closeValueMapper: (b, _) => b.close,
          bullColor: SX.bull,
          bearColor: SX.bear,
          enableSolidCandles: true,
          animationDuration: 350,
          name: 'Price',
        ),
        if (smallUp.isNotEmpty)
          _marker(smallUp,
              color: (_) => SX.bull,
              shape: DataMarkerType.diamond,
              size: 9,
              name: 'Up signal'),
        if (smallDown.isNotEmpty)
          _marker(smallDown,
              color: (_) => SX.bear,
              shape: DataMarkerType.rectangle,
              size: 8,
              name: 'Down signal'),
        if (bigUp.isNotEmpty)
          _marker(bigUp,
              color: (p) => p.signal.probability >= SX.strongProb
                  ? const Color(0xFF1D4ED8)
                  : SX.bull,
              shape: DataMarkerType.triangle,
              size: 16,
              name: 'Fresh up move'),
        if (bigDown.isNotEmpty)
          _marker(bigDown,
              color: (p) => p.signal.probability >= SX.strongProb
                  ? const Color(0xFFBE123C)
                  : SX.bear,
              shape: DataMarkerType.invertedTriangle,
              size: 16,
              name: 'Fresh down move'),
      ],
    );
  }

  BoxDecoration _cardDeco(BuildContext context) => BoxDecoration(
        color: context.sxSurface,
        borderRadius: BorderRadius.circular(SX.rLG),
        border: Border.all(color: context.sxBorder),
        boxShadow: context.isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      );
}

// ═════════════════════════════════════════════════════════════════════════════
// Small widgets
// ═════════════════════════════════════════════════════════════════════════════
class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _NavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 34,
          height: 38,
          child: Icon(icon,
              size: 20,
              color: onTap != null
                  ? context.sxTextP
                  : context.sxTextS.withValues(alpha: 0.35)),
        ),
      );
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 11.5, color: context.sxTextS)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: context.sxTextP)),
        ]),
      );
}

class _CountPill extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData? icon;
  final bool active;
  final VoidCallback onTap;
  const _CountPill({
    required this.label,
    required this.count,
    required this.color,
    required this.active,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: active ? color.withValues(alpha: 0.13) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color:
                    active ? color.withValues(alpha: 0.5) : context.sxBorder),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: active ? color : context.sxTextS),
              const SizedBox(width: 5),
            ],
            Text(label,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active ? color : context.sxTextP)),
            const SizedBox(width: 6),
            Text('$count',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: active ? color : context.sxTextS)),
          ]),
        ),
      );
}

class _LegendItem extends StatelessWidget {
  final String glyph, text;
  final Color color;
  const _LegendItem(this.glyph, this.color, this.text);

  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Text(glyph, style: TextStyle(fontSize: 11, color: color)),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 11, color: context.sxTextS)),
      ]);
}

// ═════════════════════════════════════════════════════════════════════════════
// Signal tile (list under the chart)
// ═════════════════════════════════════════════════════════════════════════════
class _SignalTile extends StatelessWidget {
  final AtlasSignal s;
  final VoidCallback onTap;
  const _SignalTile({required this.s, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    final m = s.mood;
    final pc = SX.probColor(s.probability);
    return SxTapScale(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.sxSurface,
          borderRadius: BorderRadius.circular(SX.rLG - 2),
          border: Border.all(color: context.sxBorder),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: m.dim(dark),
                borderRadius: BorderRadius.circular(SX.rMD - 2),
              ),
              child: Icon(m.icon, size: 20, color: m.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.headline,
                        style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: context.sxTextP)),
                    const SizedBox(height: 2),
                    Text(
                        '${DateFormat('h:mm a').format(s.ts)}, ${timeago.format(s.ts)}',
                        style:
                            TextStyle(fontSize: 11.5, color: context.sxTextS)),
                  ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${s.probability.toStringAsFixed(0)}%',
                  style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800, color: pc)),
              Text(SX.confidence(s.probability),
                  style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w600, color: pc)),
            ]),
          ]),
          const SizedBox(height: 10),
          Text(s.summary,
              style: TextStyle(fontSize: 12.5, color: context.sxTextP)),
          const SizedBox(height: 8),
          SxVoteBar(
              pos: s.posCount, neut: s.neutCount, neg: s.negCount, height: 5),
          if (s.entry) ...[
            const SizedBox(height: 8),
            const SxChip(
                label: 'Fresh move',
                icon: Icons.flag_rounded,
                color: SX.accent),
          ],
        ]),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Detail sheet, written in plain English
// ═════════════════════════════════════════════════════════════════════════════
class _SignalSheet extends StatelessWidget {
  final AtlasSignal signal;
  const _SignalSheet({required this.signal});

  String _story() {
    final s = signal;
    final time = DateFormat('h:mm a').format(s.ts);
    final side = s.isBull ? 'up' : 'down';
    final agree = s.isBull ? s.posCount : s.negCount;
    final b = StringBuffer(
        'At $time, $agree of ${s.total} market gauges pointed $side, so Atlas leaned $side. ');
    b.write('It was ${s.probability.round()}% sure. ');
    if (s.entry) {
      b.write(
          'This was the first signal after a change in direction, so a new move may have been starting. ');
    }
    if (s.upBreakout) b.write('Price also pushed above its recent high. ');
    if (s.lowBreakout) b.write('Price also pushed below its recent low. ');
    return b.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    final s = signal;
    final m = s.mood;
    final pc = SX.probColor(s.probability);
    final h = MediaQuery.of(context).size.height;

    Widget group(String title, List<dynamic> items, Color c) => items.isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(top: 14),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w700, color: c)),
              const SizedBox(height: 6),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final it in items) SxChip(label: '$it', color: c),
              ]),
            ]),
          );

    return Container(
      constraints: BoxConstraints(maxHeight: h * 0.9),
      decoration: BoxDecoration(
        color: context.sxSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        border: Border(top: BorderSide(color: m.color, width: 3)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: context.sxBorder,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Row(children: [
              SxRing(value: s.probability, size: 72, color: pc),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(m.icon, size: 22, color: m.color),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(m.headline,
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.4,
                                  color: context.sxTextP)),
                        ),
                      ]),
                      const SizedBox(height: 4),
                      Text(
                          '${SX.confidence(s.probability)}, ${DateFormat('h:mm a, d MMM').format(s.ts)}',
                          style:
                              TextStyle(fontSize: 12, color: context.sxTextS)),
                    ]),
              ),
            ]),
            const SizedBox(height: 14),
            Wrap(spacing: 6, runSpacing: 6, children: [
              if (s.entry)
                const SxChip(
                    label: 'Fresh move',
                    icon: Icons.flag_rounded,
                    color: SX.accent),
              if (s.upBreakout)
                const SxChip(
                    label: 'Broke above recent high',
                    icon: Icons.north_rounded,
                    color: SX.bull),
              if (s.lowBreakout)
                const SxChip(
                    label: 'Broke below recent low',
                    icon: Icons.south_rounded,
                    color: SX.bear),
            ]),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: m.dim(context.isDark),
                borderRadius: BorderRadius.circular(SX.rMD),
              ),
              child: Text(_story(),
                  style: TextStyle(
                      fontSize: 13.5, height: 1.45, color: context.sxTextP)),
            ),
            const SizedBox(height: 18),
            Text('How the market gauges voted',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: context.sxTextP)),
            const SizedBox(height: 10),
            SxVoteBar(
                pos: s.posCount, neut: s.neutCount, neg: s.negCount, height: 8),
            const SizedBox(height: 8),
            SxVoteLegend(pos: s.posCount, neut: s.neutCount, neg: s.negCount),
            const SizedBox(height: 18),
            Row(children: [
              _Tile(
                  label: 'Short-term trend',
                  value: SX.trendWord(s.shortTerm),
                  color: SX.trendColor(s.shortTerm)),
              const SizedBox(width: 10),
              _Tile(
                  label: 'Long-term trend',
                  value: SX.trendWord(s.longTerm),
                  color: SX.trendColor(s.longTerm)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              _Tile(
                  label: 'Stocks rising',
                  value: '${s.advancing}',
                  color: SX.bull),
              const SizedBox(width: 10),
              _Tile(
                  label: 'Stocks falling',
                  value: '${s.declining}',
                  color: SX.bear),
            ]),
            group('Gauges pointing up', s.posList, SX.bull),
            group('Gauges pointing down', s.negList, SX.bear),
            group('Gauges unsure', s.neutList, SX.neutral),
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: () => showSentimentGuide(context),
              icon: const Icon(Icons.help_outline_rounded, size: 16),
              label: const Text('What do these terms mean?'),
              style: TextButton.styleFrom(foregroundColor: SX.accent),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final String label, value;
  final Color color;
  const _Tile({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(SX.rMD - 2),
            border: Border.all(color: color.withValues(alpha: 0.22)),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value,
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(fontSize: 11.5, color: context.sxTextS)),
          ]),
        ),
      );
}
