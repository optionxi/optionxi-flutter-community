import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================================
// PALETTE
// ============================================================================

class _P {
  final Color cardTop;
  final Color cardBottom;
  final Color border;
  final Color shadow;
  final Color titleText;
  final Color subText;
  final Color mutedText;
  final Color accentGold;
  final Color bull;
  final Color bear;
  final Color neutral;
  final Color chipBg;
  final Color glassBg;
  final Color sheetBg;

  const _P({
    required this.cardTop,
    required this.cardBottom,
    required this.border,
    required this.shadow,
    required this.titleText,
    required this.subText,
    required this.mutedText,
    required this.accentGold,
    required this.bull,
    required this.bear,
    required this.neutral,
    required this.chipBg,
    required this.glassBg,
    required this.sheetBg,
  });

  factory _P.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return const _P(
        cardTop: Color(0xFF171A24),
        cardBottom: Color(0xFF0E1016),
        border: Color(0x33F5C451),
        shadow: Color(0x66000000),
        titleText: Color(0xFFF5F6FA),
        subText: Color(0xFFAEB4C2),
        mutedText: Color(0xFF7B8194),
        accentGold: Color(0xFFF5C451),
        bull: Color(0xFF34D399),
        bear: Color(0xFFF25F6B),
        neutral: Color(0xFF7B8194),
        chipBg: Color(0x14FFFFFF),
        glassBg: Color(0x0FFFFFFF),
        sheetBg: Color(0xFF13151D),
      );
    }
    return const _P(
      cardTop: Color(0xFFFFFFFF),
      cardBottom: Color(0xFFF6F3EC),
      border: Color(0x33C7962C),
      shadow: Color(0x1A1A1A2E),
      titleText: Color(0xFF1B1D24),
      subText: Color(0xFF565B6B),
      mutedText: Color(0xFF8A8FA0),
      accentGold: Color(0xFFB8862F),
      bull: Color(0xFF12A375),
      bear: Color(0xFFD8404C),
      neutral: Color(0xFF8A8FA0),
      chipBg: Color(0x0A1B1D24),
      glassBg: Color(0x061B1D24),
      sheetBg: Color(0xFFFFFFFF),
    );
  }
}

// ============================================================================
// CONFIG
// ============================================================================

const String _kCandleTable = 'nifty_ohlcv';
const String _kCandleSymbolCol = 'symbol';
const String _kCandleSymbol = 'NIFTY';
const String _kCandleTimeCol = 'ts';
const String _kCandleOpenCol = 'open';
const String _kCandleCloseCol = 'close';
const String _kCandleLowCol = 'low';
const String _kCandleHighCol = 'high';

const double _kMinEntryProbability = 72.0;

const int _kSignalWindowStartHour = 9;
const int _kSignalWindowStartMinute = 20;
const int _kSignalWindowEndHour = 15;
const int _kSignalWindowEndMinute = 20;

const int _kVerifyWindowMinutes = 15;
const int _kMaxLookbackDays = 7;

// ============================================================================
// STATE MODEL
// ============================================================================

enum _Status { loading, hasSignal, noSignal, error }

enum _MarketPhase { beforeOpen, open, afterClose, weekend }

enum _VerifyResult { correct, incorrect, pending, unavailable }

enum _Trend { up, down, flat }

class _QualifyingSignal {
  final DateTime ts;
  final double probability;
  final bool isBull;
  const _QualifyingSignal({
    required this.ts,
    required this.probability,
    required this.isBull,
  });
}

// ============================================================================
// DATE HELPERS
// ============================================================================

DateTime _stripTime(DateTime d) => DateTime(d.year, d.month, d.day);

bool _isWeekendDate(DateTime d) =>
    d.weekday == DateTime.saturday || d.weekday == DateTime.sunday;

DateTime _latestWeekdayOnOrBefore(DateTime d) {
  var x = _stripTime(d);
  while (_isWeekendDate(x)) {
    x = x.subtract(const Duration(days: 1));
  }
  return x;
}

DateTime _prevWeekday(DateTime d) {
  var x = d.subtract(const Duration(days: 1));
  while (_isWeekendDate(x)) {
    x = x.subtract(const Duration(days: 1));
  }
  return x;
}

bool _isSameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

bool _withinSignalWindow(DateTime local) {
  final start = DateTime(local.year, local.month, local.day,
      _kSignalWindowStartHour, _kSignalWindowStartMinute);
  final end = DateTime(local.year, local.month, local.day,
      _kSignalWindowEndHour, _kSignalWindowEndMinute);
  return !local.isBefore(start) && !local.isAfter(end);
}

// ============================================================================
// PUBLIC WIDGET
// ============================================================================

class MarketSentimentSection extends StatefulWidget {
  final EdgeInsetsGeometry margin;

  const MarketSentimentSection({
    super.key,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  @override
  State<MarketSentimentSection> createState() => _MarketSentimentSectionState();
}

class _MarketSentimentSectionState extends State<MarketSentimentSection> {
  _Status _status = _Status.loading;
  _QualifyingSignal? _signal;
  bool _signalIsToday = true;
  DateTime? _signalDate;
  _VerifyResult? _verify;
  _Trend? _trend;
  Timer? _minuteTimer;

  @override
  void initState() {
    super.initState();
    _refresh();
    _minuteTimer =
        Timer.periodic(const Duration(minutes: 1), (_) => _refresh());
  }

  @override
  void dispose() {
    _minuteTimer?.cancel();
    super.dispose();
  }

  _MarketPhase get _phase {
    final n = DateTime.now();
    if (_isWeekendDate(n)) return _MarketPhase.weekend;
    final open = DateTime(n.year, n.month, n.day, 9, 15);
    final close = DateTime(n.year, n.month, n.day, 15, 30);
    if (n.isBefore(open)) return _MarketPhase.beforeOpen;
    if (n.isAfter(close)) return _MarketPhase.afterClose;
    return _MarketPhase.open;
  }

  bool get _isLive => _phase == _MarketPhase.open;
  bool get _isMarketClosedNow =>
      _phase == _MarketPhase.afterClose || _phase == _MarketPhase.weekend;
  bool get _isWeekend => _phase == _MarketPhase.weekend;

  /// Fetch first entry signal using explicit UTC boundaries.
  Future<_QualifyingSignal?> _fetchFirstQualifyingSignal(DateTime date) async {
    final startUtc = DateTime.utc(date.year, date.month, date.day, 0, 0, 0)
        .subtract(const Duration(hours: 5, minutes: 30));
    final endUtc = DateTime.utc(date.year, date.month, date.day, 23, 59, 59)
        .subtract(const Duration(hours: 5, minutes: 30));

    final rows = await Supabase.instance.client
        .from('atlas_output')
        .select('created_at,probability,upbreakout,type')
        .eq('entry', true)
        .gte('probability', _kMinEntryProbability)
        .gte('created_at', startUtc.toIso8601String())
        .lte('created_at', endUtc.toIso8601String())
        .order('created_at', ascending: true);

    for (final row in (rows as List)) {
      final m = row as Map<String, dynamic>;
      final ts = DateTime.parse(m['created_at'] as String).toLocal();
      if (!_withinSignalWindow(ts)) continue;
      final isBull = (m['type'] == 'Bull') || (m['upbreakout'] == true);
      return _QualifyingSignal(
        ts: ts,
        probability: (m['probability'] as num).toDouble(),
        isBull: isBull,
      );
    }
    return null;
  }

  /// Verifies 5-minute candles using UTC-formatted queries.
  Future<_VerifyResult> _verifySignal(DateTime signalTs, bool isBull) async {
    final utcSignalTs = signalTs.toUtc();
    final windowEndUtc =
        utcSignalTs.add(const Duration(minutes: _kVerifyWindowMinutes));
    final searchStartUtc = utcSignalTs.subtract(const Duration(minutes: 5));
    final now = DateTime.now();

    try {
      final rows = await Supabase.instance.client
          .from(_kCandleTable)
          .select(
              '$_kCandleTimeCol,$_kCandleOpenCol,$_kCandleCloseCol,$_kCandleLowCol,$_kCandleHighCol')
          .eq(_kCandleSymbolCol, _kCandleSymbol)
          .gte(_kCandleTimeCol, searchStartUtc.toIso8601String())
          .lte(_kCandleTimeCol, windowEndUtc.toIso8601String())
          .order(_kCandleTimeCol, ascending: true);

      final list = rows as List;
      if (list.isEmpty) {
        if (now.isBefore(
            signalTs.add(const Duration(minutes: _kVerifyWindowMinutes)))) {
          return _VerifyResult.pending;
        }
        return _VerifyResult.unavailable;
      }

      final startPrice = (list.first[_kCandleOpenCol] as num).toDouble();

      for (final row in list) {
        final m = row as Map<String, dynamic>;
        final open = (m[_kCandleOpenCol] as num).toDouble();
        final close = (m[_kCandleCloseCol] as num).toDouble();
        final low = (m[_kCandleLowCol] as num?)?.toDouble() ?? close;
        final high = (m[_kCandleHighCol] as num?)?.toDouble() ?? close;

        if (isBull) {
          if (close > startPrice || close > open || high > startPrice) {
            return _VerifyResult.correct;
          }
        } else {
          // Bearish logic: Price moved down relative to entry/open
          if (close < startPrice || close < open || low < startPrice) {
            return _VerifyResult.correct;
          }
        }
      }

      if (now.isBefore(
          signalTs.add(const Duration(minutes: _kVerifyWindowMinutes)))) {
        return _VerifyResult.pending;
      }
      return _VerifyResult.incorrect;
    } catch (_) {
      return _VerifyResult.unavailable;
    }
  }

  Future<_Trend?> _fetchTrend() async {
    try {
      final ds = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final client = Supabase.instance.client;

      final openRows = await client
          .from(_kCandleTable)
          .select(_kCandleOpenCol)
          .eq(_kCandleSymbolCol, _kCandleSymbol)
          .gte(_kCandleTimeCol, '${ds}T00:00:00')
          .order(_kCandleTimeCol, ascending: true)
          .limit(1);

      final latestRows = await client
          .from(_kCandleTable)
          .select(_kCandleCloseCol)
          .eq(_kCandleSymbolCol, _kCandleSymbol)
          .gte(_kCandleTimeCol, '${ds}T00:00:00')
          .order(_kCandleTimeCol, ascending: false)
          .limit(1);

      if ((openRows as List).isEmpty || (latestRows as List).isEmpty) {
        return null;
      }

      final dayOpen =
          ((openRows.first as Map)[_kCandleOpenCol] as num).toDouble();
      final latestClose =
          ((latestRows.first as Map)[_kCandleCloseCol] as num).toDouble();

      if (latestClose > dayOpen) return _Trend.up;
      if (latestClose < dayOpen) return _Trend.down;
      return _Trend.flat;
    } catch (_) {
      return null;
    }
  }

  Future<void> _refresh() async {
    if (mounted) setState(() => _status = _Status.loading);

    try {
      DateTime day = _latestWeekdayOnOrBefore(DateTime.now());
      bool isToday = _isSameDate(day, DateTime.now());
      _QualifyingSignal? found = await _fetchFirstQualifyingSignal(day);

      int guard = 0;
      while (found == null && guard < _kMaxLookbackDays) {
        day = _prevWeekday(day);
        isToday = false;
        found = await _fetchFirstQualifyingSignal(day);
        guard++;
      }

      if (found == null) {
        _signal = null;
        _verify = null;
        _trend = null;
        if (mounted) setState(() => _status = _Status.noSignal);
        return;
      }

      _signal = found;
      _signalIsToday = isToday;
      _signalDate = day;
      _verify = await _verifySignal(found.ts, found.isBull);
      _trend = _isLive ? await _fetchTrend() : null;

      if (mounted) setState(() => _status = _Status.hasSignal);
    } catch (_) {
      if (mounted) setState(() => _status = _Status.error);
    }
  }

  void _openChart() => Get.toNamed('/market-sentiments-chart');
  void _openAccuracy() => Get.toNamed('/backtest/nifty');

  /// Clean Standard Bottom Sheet Fix
  void _openDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetailSheet(
        signal: _signal,
        verify: _verify,
        signalIsToday: _signalIsToday,
        signalDate: _signalDate,
        isMarketClosedNow: _isMarketClosedNow,
        isWeekend: _isWeekend,
        onViewChart: () {
          Navigator.pop(context);
          _openChart();
        },
        onViewAccuracy: () {
          Navigator.pop(context);
          _openAccuracy();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = _P.of(context);
    final canOpenDetails =
        _status == _Status.hasSignal || _status == _Status.noSignal;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: canOpenDetails ? _openDetails : null,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: p.border, width: 1),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [p.cardTop, p.cardBottom],
            ),
            boxShadow: [
              BoxShadow(
                color: p.shadow,
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _buildBody(p),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(_P p) {
    switch (_status) {
      case _Status.loading:
        return _SkeletonBody(key: const ValueKey('loading'), p: p);
      case _Status.error:
        return _ErrorBody(
            key: const ValueKey('error'), p: p, onRetry: _refresh);
      case _Status.noSignal:
        return _NoSignalBody(
          key: const ValueKey('noSignal'),
          p: p,
          isClosed: _isMarketClosedNow,
          isLive: _isLive,
          onChart: _openChart,
          onAccuracy: _openAccuracy,
        );
      case _Status.hasSignal:
        return _HasSignalBody(
          key: const ValueKey('hasSignal'),
          p: p,
          signal: _signal!,
          verify: _verify,
          signalIsToday: _signalIsToday,
          signalDate: _signalDate!,
          isClosed: _isMarketClosedNow,
          isWeekend: _isWeekend,
          isLive: _isLive,
          trend: _trend,
          onChart: _openChart,
          onAccuracy: _openAccuracy,
        );
    }
  }
}

// ============================================================================
// HEADER
// ============================================================================

class _Header extends StatelessWidget {
  final _P p;
  final bool live;
  final String? tag;
  final _Trend? trend;
  const _Header({required this.p, required this.live, this.tag, this.trend});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Container(
        //   width: 34,
        //   height: 34,
        //   decoration: BoxDecoration(
        //     borderRadius: BorderRadius.circular(10),
        //     gradient: LinearGradient(
        //       begin: Alignment.topLeft,
        //       end: Alignment.bottomRight,
        //       colors: [
        //         p.accentGold.withOpacity(0.9),
        //         p.accentGold.withOpacity(0.55)
        //       ],
        //     ),
        //   ),
        //   child: const Icon(Icons.auto_graph_rounded,
        //       size: 18, color: Colors.black),
        // ),
        // const SizedBox(width: 10),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Color(0xFFF5C544),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Market Sentiments',
          style: TextStyle(
            color: Color(0xFF8B96A5),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
        const Spacer(),
        if (trend != null && trend != _Trend.flat) ...[
          _TrendChip(p: p, trend: trend!),
          const SizedBox(width: 6),
        ],
        if (live) ...[
          _PulsingDot(color: p.bull),
          const SizedBox(width: 5),
          Text('LIVE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: p.bull,
              )),
        ] else if (tag != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: p.chipBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              tag!,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: p.mutedText,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _TrendChip extends StatelessWidget {
  final _P p;
  final _Trend trend;
  const _TrendChip({required this.p, required this.trend});

  @override
  Widget build(BuildContext context) {
    final up = trend == _Trend.up;
    final color = up ? p.bull : p.bear;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(up ? Icons.north_east_rounded : Icons.south_east_rounded,
              size: 10, color: color),
          const SizedBox(width: 2),
          Text(
            up ? 'Trending up' : 'Trending down',
            style: TextStyle(
                fontSize: 9, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.35, end: 1.0).animate(_c),
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color),
      ),
    );
  }
}

// ============================================================================
// VERIFICATION CHIP
// ============================================================================

class _VerifyChip extends StatelessWidget {
  final _P p;
  final _VerifyResult result;
  const _VerifyChip({
    required this.p,
    required this.result,
  });

  ({IconData icon, String label, Color color}) get _meta {
    switch (result) {
      case _VerifyResult.correct:
        return (
          icon: Icons.check_circle_rounded,
          label: 'Played out right',
          color: p.bull,
        );
      case _VerifyResult.incorrect:
        return (
          icon: Icons.cancel_rounded,
          label: "Didn't play out",
          color: p.bear,
        );
      case _VerifyResult.pending:
        return (
          icon: Icons.hourglass_top_rounded,
          label: 'Still checking',
          color: p.accentGold,
        );
      case _VerifyResult.unavailable:
        return (
          icon: Icons.help_outline_rounded,
          label: 'Not verified',
          color: p.mutedText,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = _meta;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: m.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: m.color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(m.icon, size: 13, color: m.color),
          const SizedBox(width: 5),
          Text(
            m.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: m.color,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SKELETON BODY
// ============================================================================

class _SkeletonBody extends StatefulWidget {
  final _P p;
  const _SkeletonBody({super.key, required this.p});

  @override
  State<_SkeletonBody> createState() => _SkeletonBodyState();
}

class _SkeletonBodyState extends State<_SkeletonBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _bar(double width, double height, {double radius = 6}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: widget.p.chipBg,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.45, end: 0.9).animate(_c),
      child: SizedBox(
        height: 118,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: widget.p.chipBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 10),
                _bar(140, 16),
              ],
            ),
            _bar(220, 12),
            _bar(double.infinity, 34, radius: 10),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// ACTION BUTTONS ROW
// ============================================================================

class _ActionButtonsRow extends StatelessWidget {
  final _P p;
  final VoidCallback onChart;
  final VoidCallback onAccuracy;
  const _ActionButtonsRow(
      {required this.p, required this.onChart, required this.onAccuracy});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            p: p,
            icon: Icons.candlestick_chart_rounded,
            label: 'View chart',
            filled: true,
            onTap: onChart,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionButton(
            p: p,
            icon: Icons.insights_rounded,
            label: 'Accuracy',
            filled: false,
            onTap: onAccuracy,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final _P p;
  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;
  const _ActionButton({
    required this.p,
    required this.icon,
    required this.label,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = filled ? p.accentGold : Colors.transparent;
    final fg = filled ? Colors.black : p.accentGold;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: filled
                ? null
                : Border.all(color: p.accentGold.withOpacity(0.45)),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w800, color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// NO SIGNAL BODY
// ============================================================================

class _NoSignalBody extends StatelessWidget {
  final _P p;
  final bool isClosed;
  final bool isLive;
  final VoidCallback onChart;
  final VoidCallback onAccuracy;
  const _NoSignalBody({
    super.key,
    required this.p,
    required this.isClosed,
    required this.isLive,
    required this.onChart,
    required this.onAccuracy,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Header(p: p, live: isLive, tag: isClosed ? 'CLOSED' : null),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.visibility_outlined, size: 18, color: p.mutedText),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'No strong signal recently',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: p.subText,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Nothing has crossed the ${_kMinEntryProbability.toInt()}% confidence bar in the last few trading days.',
          style: TextStyle(fontSize: 12, color: p.mutedText),
        ),
        const SizedBox(height: 12),
        _ActionButtonsRow(p: p, onChart: onChart, onAccuracy: onAccuracy),
      ],
    );
  }
}

// ============================================================================
// HAS SIGNAL BODY
// ============================================================================

class _HasSignalBody extends StatelessWidget {
  final _P p;
  final _QualifyingSignal signal;
  final _VerifyResult? verify;
  final bool signalIsToday;
  final DateTime signalDate;
  final bool isClosed;
  final bool isWeekend;
  final bool isLive;
  final _Trend? trend;
  final VoidCallback onChart;
  final VoidCallback onAccuracy;

  const _HasSignalBody({
    super.key,
    required this.p,
    required this.signal,
    required this.verify,
    required this.signalIsToday,
    required this.signalDate,
    required this.isClosed,
    required this.isWeekend,
    required this.isLive,
    required this.trend,
    required this.onChart,
    required this.onAccuracy,
  });

  @override
  Widget build(BuildContext context) {
    final dirColor = signal.isBull ? p.bull : p.bear;
    final dayLabel =
        signalIsToday ? 'Today' : DateFormat('EEE, d MMM').format(signalDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Header(
          p: p,
          live: isLive,
          tag: isWeekend ? 'WEEKEND' : (isClosed ? 'CLOSED' : null),
          trend: trend,
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: dirColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                signal.isBull
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                size: 18,
                color: dirColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${signal.isBull ? "Bull" : "Bear"} entry · ${signal.probability.toStringAsFixed(0)}% confidence',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: p.titleText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$dayLabel · ${DateFormat('h:mm a').format(signal.ts)}',
                    style: TextStyle(fontSize: 12, color: p.mutedText),
                  ),
                ],
              ),
            ),
            // Simplified verification indicator — just ✓ or ✗
            if (verify == _VerifyResult.correct)
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 2),
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 20,
                  color: p.bull,
                ),
              )
            else if (verify == _VerifyResult.incorrect)
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 2),
                child: Icon(
                  Icons.cancel_rounded,
                  size: 20,
                  color: p.bear,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        // Disclaimer
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: p.accentGold.withOpacity(0.06),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: p.accentGold.withOpacity(0.15)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: p.accentGold.withOpacity(0.7),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'This is a statistically derived signal, not investment advice. '
                  'Markets can be unpredictable — always do your own research before trading.',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.4,
                    color: p.mutedText,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _ActionButtonsRow(p: p, onChart: onChart, onAccuracy: onAccuracy),
      ],
    );
  }
}

// ============================================================================
// ERROR BODY
// ============================================================================

class _ErrorBody extends StatelessWidget {
  final _P p;
  final VoidCallback onRetry;
  const _ErrorBody({super.key, required this.p, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Header(p: p, live: false),
        const SizedBox(height: 12),
        Text(
          "Couldn't load signal data",
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700, color: p.subText),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onRetry,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.refresh_rounded, size: 14, color: p.accentGold),
              const SizedBox(width: 4),
              Text('Retry',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: p.accentGold)),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// MODAL BOTTOM SHEET — FIXES DIALOG SCROLL ISSUE
// ============================================================================

class _DetailSheet extends StatelessWidget {
  final _QualifyingSignal? signal;
  final _VerifyResult? verify;
  final bool signalIsToday;
  final DateTime? signalDate;
  final bool isMarketClosedNow;
  final bool isWeekend;
  final VoidCallback onViewChart;
  final VoidCallback onViewAccuracy;

  const _DetailSheet({
    required this.signal,
    required this.verify,
    required this.signalIsToday,
    required this.signalDate,
    required this.isMarketClosedNow,
    required this.isWeekend,
    required this.onViewChart,
    required this.onViewAccuracy,
  });

  String _verifyExplanation(_VerifyResult r, bool isBull) {
    final dir = isBull ? 'up' : 'down';
    switch (r) {
      case _VerifyResult.correct:
        return 'Within 15 minutes of this signal, price actually moved $dir as predicted.';
      case _VerifyResult.incorrect:
        return "Price hadn't moved $dir within 15 minutes, so this call is marked as missed.";
      case _VerifyResult.pending:
        return "We'll know within 15 minutes of the signal whether price moved $dir as expected.";
      case _VerifyResult.unavailable:
        return "We couldn't check the price data for this signal right now.";
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _P.of(context);
    final has = signal != null;
    final dayLabel = has
        ? (signalIsToday
            ? 'Today'
            : DateFormat('EEE, d MMM').format(signalDate!))
        : '';

    return Container(
      decoration: BoxDecoration(
        color: p.sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: p.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                has ? 'Signal Details' : 'No Recent Signal',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: p.titleText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Market sentiment verification',
                style: TextStyle(fontSize: 12, color: p.mutedText),
              ),
              const SizedBox(height: 14),
              if (isMarketClosedNow) ...[
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: p.chipBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                          isWeekend
                              ? Icons.weekend_rounded
                              : Icons.nightlight_round,
                          size: 16,
                          color: p.mutedText),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isWeekend
                              ? 'Markets are closed for the weekend.'
                              : 'Market is closed for the day.',
                          style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: p.subText),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (has) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: p.chipBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        signal!.isBull
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        color: signal!.isBull ? p.bull : p.bear,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Predicted price would go ${signal!.isBull ? "UP" : "DOWN"}',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: p.titleText,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$dayLabel · ${DateFormat('h:mm a').format(signal!.ts)} · ${signal!.probability.toStringAsFixed(0)}% confident',
                              style:
                                  TextStyle(fontSize: 11, color: p.mutedText),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                if (verify != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: p.chipBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Was it right?',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: p.titleText,
                              ),
                            ),
                            const Spacer(),
                            _VerifyChip(p: p, result: verify!),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _verifyExplanation(verify!, signal!.isBull),
                          style: TextStyle(
                              fontSize: 12, height: 1.4, color: p.subText),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: p.chipBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "Nothing has cleared the ${_kMinEntryProbability.toInt()}% confidence bar in the last few trading days.",
                    style: TextStyle(
                        fontSize: 12.5, height: 1.4, color: p.subText),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Icon(Icons.bolt_rounded, size: 15, color: p.accentGold),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${_kMinEntryProbability.toInt()}%+ confidence is flagged as a signal',
                      style: TextStyle(fontSize: 12, color: p.subText),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      p: p,
                      icon: Icons.candlestick_chart_rounded,
                      label: 'View chart',
                      filled: true,
                      onTap: onViewChart,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionButton(
                      p: p,
                      icon: Icons.insights_rounded,
                      label: 'Accuracy',
                      filled: false,
                      onTap: onViewAccuracy,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Disclaimer
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: p.accentGold.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: p.accentGold.withOpacity(0.15)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: p.accentGold.withOpacity(0.7),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'This is a statistically derived signal, not investment advice. '
                        'Markets can be unpredictable — always do your own research before trading.',
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.4,
                          color: p.mutedText,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
