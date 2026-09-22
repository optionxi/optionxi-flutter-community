import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

// ============================================================================
// PALETTE (kept visually consistent with MarketSentimentSection's _P)
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
  final Color accentIndigo;
  final Color bull;
  final Color bear;
  final Color chipBg;
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
    required this.accentIndigo,
    required this.bull,
    required this.bear,
    required this.chipBg,
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
        accentIndigo: Color(0xFF818CF8),
        bull: Color(0xFF34D399),
        bear: Color(0xFFF25F6B),
        chipBg: Color(0x14FFFFFF),
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
      accentIndigo: Color(0xFF6366F1),
      bull: Color(0xFF12A375),
      bear: Color(0xFFD8404C),
      chipBg: Color(0x0A1B1D24),
      sheetBg: Color(0xFFFFFFFF),
    );
  }
}

// ============================================================================
// CONFIG — adjust these to match your actual table / routes
// ============================================================================

const String _kPicksTable = 'ai_picked_stocks';
const int _kMaxLookbackDays = 7;
const int _kMaxItemsShown = 5;

// Trading window in IST, expressed as UTC bounds (9:30 AM – 3:15 PM IST)
const int _kWindowStartUtcHour = 4;
const int _kWindowStartUtcMinute = 00;
const int _kWindowEndUtcHour = 9;
const int _kWindowEndUtcMinute = 45;

// Routes — replace with your actual route names
const String _kRouteViewAll = '/ai-picked-stocks';
const String _kRouteAccuracy = '/backtest/ai-picks';
String _routeForStock(String symbol) => '/stocks/$symbol';

// ============================================================================
// HELPERS
// ============================================================================

DateTime _todayIST() {
  final now = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
  return DateTime(now.year, now.month, now.day);
}

bool _isWeekend(DateTime d) =>
    d.weekday == DateTime.saturday || d.weekday == DateTime.sunday;

DateTime _prevWeekday(DateTime d) {
  var x = d.subtract(const Duration(days: 1));
  while (_isWeekend(x)) {
    x = x.subtract(const Duration(days: 1));
  }
  return x;
}

bool _isSameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _cleanSymbol(String raw) =>
    raw.replaceAll(RegExp(r'^(NSE|BSE):'), '').replaceAll('-EQ', '');

String _dayLabel(DateTime date) {
  final today = _todayIST();
  if (_isSameDate(date, today)) return 'Today';
  return DateFormat('EEE, d MMM').format(date);
}

String _pickDateTimeLabel(DateTime t) {
  final today = _todayIST();
  final tDate = DateTime(t.year, t.month, t.day);
  final datePart =
      _isSameDate(tDate, today) ? 'Today' : DateFormat('d MMM').format(t);
  final timePart = DateFormat('h:mm a').format(t);
  return '$datePart, $timePart';
}

// ============================================================================
// MODELS
// ============================================================================

enum _Status { loading, hasPicks, noPicks, error }

class _RawEntry {
  final String symbol;
  final DateTime snapshotTime;
  final String? sentiment;
  final double? breakoutClose;
  final String? sector;

  _RawEntry({
    required this.symbol,
    required this.snapshotTime,
    this.sentiment,
    this.breakoutClose,
    this.sector,
  });

  factory _RawEntry.fromMap(Map<String, dynamic> m) => _RawEntry(
        symbol: m['symbol'] as String,
        snapshotTime: DateTime.parse(m['snapshot_time'] as String).toLocal(),
        sentiment: m['sentiment'] as String?,
        breakoutClose: (m['breakout_close'] as num?)?.toDouble(),
        sector: m['sector'] as String?,
      );
}

class _Pick {
  final String symbol;
  final String cleanSymbol;
  final String sentiment;
  final DateTime pickTime;
  final double startPrice;
  final double latestPrice;
  final double gainPcnt;
  final bool isSuccess;

  _Pick({
    required this.symbol,
    required this.cleanSymbol,
    required this.sentiment,
    required this.pickTime,
    required this.startPrice,
    required this.latestPrice,
    required this.gainPcnt,
    required this.isSuccess,
  });
}

// ============================================================================
// PUBLIC WIDGET
// ============================================================================

/// Compact, fixed-height home-screen card summarizing the latest AI stock
/// picks (today's, or the most recent trading day with picks). Mirrors the
/// visual language of MarketSentimentSection: same states, same card shell,
/// same gold/dark palette.
class MarketSentimentSection_Stocks extends StatefulWidget {
  final EdgeInsetsGeometry margin;

  const MarketSentimentSection_Stocks({
    super.key,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  @override
  State<MarketSentimentSection_Stocks> createState() =>
      _MarketSentimentSection_StocksState();
}

class _MarketSentimentSection_StocksState
    extends State<MarketSentimentSection_Stocks> {
  _Status _status = _Status.loading;
  List<_Pick> _picks = [];
  DateTime? _pickDate;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refresh();
    // Light polling while the market's open; harmless the rest of the time.
    _refreshTimer =
        Timer.periodic(const Duration(minutes: 2), (_) => _refresh());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  bool get _isMarketClosedForDate {
    final date = _pickDate;
    if (date == null) return true;
    final today = _todayIST();
    if (date.isBefore(today)) return true;
    final now =
        DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
    return now.hour > 15 || (now.hour == 15 && now.minute >= 30);
  }

  bool get _isLive {
    final date = _pickDate;
    if (date == null) return false;
    if (!_isSameDate(date, _todayIST())) return false;
    final now =
        DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
    final afterOpen = now.hour > 9 || (now.hour == 9 && now.minute >= 15);
    final beforeClose = now.hour < 15 || (now.hour == 15 && now.minute < 30);
    return afterOpen && beforeClose && !_isWeekend(now);
  }

  Future<List<_Pick>> _fetchForDate(DateTime date) async {
    final start = DateTime.utc(date.year, date.month, date.day,
        _kWindowStartUtcHour, _kWindowStartUtcMinute);
    final end = DateTime.utc(date.year, date.month, date.day,
        _kWindowEndUtcHour, _kWindowEndUtcMinute);

    final rows = await Supabase.instance.client
        .from(_kPicksTable)
        .select('symbol,snapshot_time,sentiment,breakout_close,sector')
        .gte('snapshot_time', start.toIso8601String())
        .lte('snapshot_time', end.toIso8601String())
        .order('snapshot_time', ascending: true);

    final entries = (rows as List)
        .map((e) => _RawEntry.fromMap(e as Map<String, dynamic>))
        .toList();

    if (entries.isEmpty) return [];

    final bySymbol = <String, List<_RawEntry>>{};
    for (final e in entries) {
      bySymbol.putIfAbsent(e.symbol, () => []).add(e);
    }

    final picks = bySymbol.values.map((list) {
      list.sort((a, b) => a.snapshotTime.compareTo(b.snapshotTime));
      final first = list.first;
      final last = list.last;
      final startPrice = first.breakoutClose ?? 0;
      final latestPrice = last.breakoutClose ?? 0;
      final gain = startPrice > 0
          ? ((latestPrice - startPrice) / startPrice) * 100
          : 0.0;
      final sentiment = (first.sentiment ?? 'BULLISH').toUpperCase();
      final isSuccess = sentiment == 'BEARISH' ? gain <= 0 : gain > 0;

      return _Pick(
        symbol: first.symbol,
        cleanSymbol: _cleanSymbol(first.symbol),
        sentiment: sentiment,
        pickTime: first.snapshotTime,
        startPrice: startPrice,
        latestPrice: latestPrice,
        gainPcnt: gain,
        isSuccess: isSuccess,
      );
    }).toList();

    picks.sort((a, b) => b.gainPcnt.compareTo(a.gainPcnt));
    return picks;
  }

  Future<void> _refresh() async {
    if (mounted) setState(() => _status = _Status.loading);
    try {
      DateTime date = _todayIST();
      List<_Pick> found = await _fetchForDate(date);

      int guard = 0;
      while (found.isEmpty && guard < _kMaxLookbackDays) {
        date = _prevWeekday(date);
        found = await _fetchForDate(date);
        guard++;
      }

      _pickDate = date;
      _picks = found;

      if (mounted) {
        setState(
            () => _status = found.isEmpty ? _Status.noPicks : _Status.hasPicks);
      }
    } catch (_) {
      if (mounted) setState(() => _status = _Status.error);
    }
  }

  void _openStockDetail(_Pick pick) {
    Get.toNamed(
      _routeForStock(pick.symbol),
      arguments: {'date': DateFormat('yyyy-MM-dd').format(pick.pickTime)},
    );
  }

  void _openViewAll(DateTime date) {
    Get.toNamed(
      _kRouteViewAll,
      arguments: {'date': DateFormat('yyyy-MM-dd').format(date)},
    );
  }

  void _openAccuracy(DateTime date) {
    Get.toNamed(
      _kRouteAccuracy,
      arguments: {'date': DateFormat('yyyy-MM-dd').format(date)},
    );
  }

  void _openDetails() {
    final date = _pickDate ?? _todayIST();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PicksListSheet(
        p: _P.of(context),
        picks: _picks,
        dayLabel: _dayLabel(date),
        pickDate: date,
        isClosed: _isMarketClosedForDate,
        onTapPick: (pick) {
          Navigator.pop(context);
          _openStockDetail(pick);
        },
        onViewAll: (d) {
          Navigator.pop(context);
          _openViewAll(d);
        },
        onAccuracy: (d) {
          Navigator.pop(context);
          _openAccuracy(d);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = _P.of(context);
    final canOpenDetails =
        _status == _Status.hasPicks || _status == _Status.noPicks;

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
                  color: p.shadow, blurRadius: 24, offset: const Offset(0, 10)),
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
      case _Status.noPicks:
        return _NoPicksBody(
          key: const ValueKey('noPicks'),
          p: p,
          onViewAll: () => _openViewAll(_pickDate ?? _todayIST()),
          onAccuracy: () => _openAccuracy(_pickDate ?? _todayIST()),
        );
      case _Status.hasPicks:
        return _HasPicksBody(
          key: const ValueKey('hasPicks'),
          p: p,
          picks: _picks.take(_kMaxItemsShown).toList(),
          totalCount: _picks.length,
          dayLabel: _dayLabel(_pickDate!),
          isLive: _isLive,
          isClosed: _isMarketClosedForDate,
          onViewAll: () => _openViewAll(_pickDate!),
          onAccuracy: () => _openAccuracy(_pickDate!),
        );
    }
  }
}

// ============================================================================
// HEADER (shared shape with MarketSentimentSection's _Header)
// ============================================================================

class _Header extends StatelessWidget {
  final _P p;
  final bool live;
  final String? tag;
  const _Header({required this.p, required this.live, this.tag});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration:
              BoxDecoration(color: p.accentIndigo, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          'Stock Picks',
          style: TextStyle(
            color: const Color(0xFF8B96A5),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
        const Spacer(),
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
                color: p.chipBg, borderRadius: BorderRadius.circular(6)),
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

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200))
    ..repeat(reverse: true);

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
// ACTION BUTTONS ROW (View All / Accuracy)
// ============================================================================

class _ActionButtonsRow extends StatelessWidget {
  final _P p;
  final VoidCallback onViewAll;
  final VoidCallback onAccuracy;
  const _ActionButtonsRow({
    required this.p,
    required this.onViewAll,
    required this.onAccuracy,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            p: p,
            icon: Icons.grid_view_rounded,
            label: 'View all',
            filled: true,
            onTap: onViewAll,
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
              Text(label,
                  style: TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w800, color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// PICK LIST ROW — single "activity" line item, stacked one below another
// ============================================================================

class _PickListRow extends StatelessWidget {
  final _P p;
  final _Pick pick;
  final bool showOutcome;
  final bool isLast;
  final VoidCallback? onTap; // now nullable
  const _PickListRow({
    required this.p,
    required this.pick,
    required this.showOutcome,
    required this.isLast,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final gainColor = pick.gainPcnt >= 0 ? p.bull : p.bear;
    final bullish = pick.sentiment == 'BULLISH';

    final content = Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: p.border, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: (bullish ? p.bull : p.bear).withOpacity(0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: Icon(
              bullish ? Icons.trending_up_rounded : Icons.trending_down_rounded,
              size: 16,
              color: bullish ? p.bull : p.bear,
            ),
          ),
          // Container(
          //   width: 32,
          //   height: 32,
          //   decoration: BoxDecoration(
          //     color: (bullish ? p.bull : p.bear).withOpacity(0.12),
          //     borderRadius: BorderRadius.circular(9),
          //   ),
          //   child: ClipRRect(
          //     borderRadius: BorderRadius.circular(9),
          //     child: CachedNetworkImage(
          //       imageUrl: '${Constants.OptionXiS3Loc}${pick.cleanSymbol}.png',
          //       fit: BoxFit.cover,
          //       placeholder: (context, url) => Image.asset(
          //         'assets/images/stockdefault.png',
          //         fit: BoxFit.cover,
          //       ),
          //       errorWidget: (context, url, error) => Image.asset(
          //         'assets/images/stockdefault.png',
          //         fit: BoxFit.cover,
          //       ),
          //     ),
          //   ),
          // ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  pick.cleanSymbol,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: p.titleText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_pickDateTimeLabel(pick.pickTime)} · ${timeago.format(pick.pickTime)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: p.mutedText),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${pick.gainPcnt >= 0 ? '+' : ''}${pick.gainPcnt.toStringAsFixed(2)}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: gainColor,
                ),
              ),
              if (showOutcome) ...[
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      pick.isSuccess
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      size: 11,
                      color: pick.isSuccess ? p.bull : p.bear,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      pick.isSuccess ? 'Right' : 'Wrong',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: pick.isSuccess ? p.bull : p.bear,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );

    if (onTap == null) return content;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: content,
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
      vsync: this, duration: const Duration(milliseconds: 1100))
    ..repeat(reverse: true);

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
          color: widget.p.chipBg, borderRadius: BorderRadius.circular(radius)),
    );
  }

  Widget _row({required bool isLast}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: widget.p.border, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: widget.p.chipBg,
              borderRadius: BorderRadius.circular(9),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _bar(64, 12),
                const SizedBox(height: 6),
                _bar(88, 9),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _bar(40, 12),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.45, end: 0.9).animate(_c),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [_bar(90, 12), const Spacer(), _bar(40, 12)]),
          const SizedBox(height: 6),
          _bar(140, 11),
          const SizedBox(height: 6),
          _row(isLast: false),
          _row(isLast: false),
          _row(isLast: true),
          const SizedBox(height: 6),
          _bar(double.infinity, 34, radius: 10),
        ],
      ),
    );
  }
}

// ============================================================================
// NO PICKS BODY
// ============================================================================

class _NoPicksBody extends StatelessWidget {
  final _P p;
  final VoidCallback onViewAll;
  final VoidCallback onAccuracy;
  const _NoPicksBody({
    super.key,
    required this.p,
    required this.onViewAll,
    required this.onAccuracy,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Header(p: p, live: false),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.search_off_rounded, size: 18, color: p.mutedText),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'No picks flagged recently',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: p.subText),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          "The AI scanned the market but hasn't flagged any breakout candidates in the last few trading days.",
          style: TextStyle(fontSize: 12, color: p.mutedText),
        ),
        const SizedBox(height: 12),
        _ActionButtonsRow(p: p, onViewAll: onViewAll, onAccuracy: onAccuracy),
      ],
    );
  }
}

// ============================================================================
// HAS PICKS BODY
// ============================================================================

class _HasPicksBody extends StatelessWidget {
  final _P p;
  final List<_Pick> picks;
  final int totalCount;
  final String dayLabel;
  final bool isLive;
  final bool isClosed;
  final VoidCallback onViewAll;
  final VoidCallback onAccuracy;

  const _HasPicksBody({
    super.key,
    required this.p,
    required this.picks,
    required this.totalCount,
    required this.dayLabel,
    required this.isLive,
    required this.isClosed,
    required this.onViewAll,
    required this.onAccuracy,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Header(
            p: p,
            live: isLive,
            tag: isLive ? null : (isClosed ? 'CLOSED' : null)),
        const SizedBox(height: 4),
        Text(
          '$dayLabel · $totalCount stock${totalCount == 1 ? '' : 's'} flagged',
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700, color: p.subText),
        ),
        const SizedBox(height: 6),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < picks.length; i++)
              _PickListRow(
                p: p,
                pick: picks[i],
                showOutcome: isClosed,
                isLast: i == picks.length - 1,
                // no onTap — whole card handles the tap now
              ),
          ],
        ),
        const SizedBox(height: 12),
        _ActionButtonsRow(p: p, onViewAll: onViewAll, onAccuracy: onAccuracy),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: p.accentGold.withOpacity(0.06),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: p.accentGold.withOpacity(0.15)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 13, color: p.accentGold.withOpacity(0.7)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'AI-picked stocks are for informational purposes only, not investment advice.',
                  style: TextStyle(
                      fontSize: 10.5, height: 1.3, color: p.mutedText),
                ),
              ),
            ],
          ),
        ),
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
          "Couldn't load stock picks",
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
// PICKS LIST SHEET (replaces old _PickDetailSheet)
// ============================================================================

class _PicksListSheet extends StatelessWidget {
  final _P p;
  final List<_Pick> picks;
  final String dayLabel;
  final DateTime pickDate;
  final bool isClosed;
  final void Function(_Pick pick) onTapPick;
  final void Function(DateTime date) onViewAll;
  final void Function(DateTime date) onAccuracy;

  const _PicksListSheet({
    required this.p,
    required this.picks,
    required this.dayLabel,
    required this.pickDate,
    required this.isClosed,
    required this.onTapPick,
    required this.onViewAll,
    required this.onAccuracy,
  });

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final maxSheetH = screenH * 0.92; // cap
    final bottomInset = MediaQuery.of(context).padding.bottom +
        MediaQuery.of(context).viewInsets.bottom;

    // Align + transparent modal route lets this hug its content instead
    // of stretching a colored box to fill the whole screen.
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxSheetH),
      child: Container(
        decoration: BoxDecoration(
          color: p.sheetBg,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(28), // rounder corners
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min, // <- key: hug content
            children: [
              // Fixed, non-scrolling header (unchanged)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
                child: Column(
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: p.accentIndigo.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.auto_graph_rounded,
                              color: p.accentIndigo, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Stock Picks',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: p.titleText,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                picks.isEmpty
                                    ? dayLabel
                                    : '$dayLabel · ${picks.length} stock${picks.length == 1 ? '' : 's'} flagged',
                                style:
                                    TextStyle(fontSize: 12, color: p.mutedText),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: p.border),

              // Content: sizes to fit, scrolls only if it exceeds maxSheetH
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 14,
                    bottom: bottomInset, // trimmed, was + 24
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // How it works
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: p.chipBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'HOW THIS WORKS',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: p.mutedText,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _ExplainLine(
                              p: p,
                              icon: Icons.radar_rounded,
                              text:
                                  'A few of our market scanners flag stocks independently — when they overlap on the same stock, it gets picked.',
                            ),
                            _ExplainLine(
                              p: p,
                              icon: Icons.trending_up_rounded,
                              text:
                                  'Stocks breaking above recent highs (bullish) or below recent lows (bearish) are tracked in real time.',
                            ),
                            _ExplainLine(
                              p: p,
                              icon: Icons.update_rounded,
                              text:
                                  'Runs on live 5-minute price data while the market is open, so picks can move as the day goes on.',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      if (picks.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            "The AI scanned the market but hasn't flagged any breakout candidates in the last few trading days.",
                            style: TextStyle(
                                fontSize: 12.5, height: 1.4, color: p.subText),
                          ),
                        )
                      else
                        for (int i = 0; i < picks.length; i++)
                          _PickListRow(
                            p: p,
                            pick: picks[i],
                            showOutcome: isClosed,
                            isLast: i == picks.length - 1,
                            onTap: () => onTapPick(picks[i]),
                          ),

                      const SizedBox(height: 14),
                      _ActionButtonsRow(
                        p: p,
                        onViewAll: () => onViewAll(pickDate),
                        onAccuracy: () => onAccuracy(pickDate),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: p.accentGold.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: p.accentGold.withOpacity(0.15)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline_rounded,
                                size: 13, color: p.accentGold.withOpacity(0.7)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'AI-picked stocks are for informational purposes only, not investment advice.',
                                style: TextStyle(
                                    fontSize: 10.5,
                                    height: 1.3,
                                    color: p.mutedText),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExplainLine extends StatelessWidget {
  final _P p;
  final IconData icon;
  final String text;
  const _ExplainLine({required this.p, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: p.mutedText),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12.5, height: 1.4, color: p.subText),
            ),
          ),
        ],
      ),
    );
  }
}
