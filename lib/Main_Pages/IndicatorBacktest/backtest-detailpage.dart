// ─────────────────────────────────────────────────────────────────────────
// Friendly Backtest Detail Page (Redesigned)
// ─────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
// AlertsListPage below is what used to be a separate, mismatched Alerts
// CRUD system (its own API service + condition/schedule builder). It's
// now just a list of algos that have `is_alert_enabled = true`, backed by
// BacktestApiService -- see that file's comment for why.
import 'package:optionxi/Main_Pages/IndicatorBacktest/Alerts/alert-indicator-list.dart';
import 'package:optionxi/Main_Pages/IndicatorBacktest/indicator-backtest.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────
// THEME
// ─────────────────────────────────────────────
class _DT {
  static const accent = Color(0xFF5B7FFF);
  static const green = Color(0xFF00C896);
  static const red = Color(0xFFFF4D6D);
  static const amber = Color(0xFFFFAB00);

  static Color bg(bool d) =>
      d ? const Color(0xFF0B0D15) : const Color(0xFFF0F2F8);
  static Color surface(bool d) => d ? const Color(0xFF161927) : Colors.white;
  static Color surface2(bool d) =>
      d ? const Color(0xFF1E2235) : const Color(0xFFF7F8FF);
  static Color border(bool d) =>
      d ? const Color(0xFF252840) : const Color(0xFFE4E7F2);
  static Color text(bool d) =>
      d ? const Color(0xFFEEF0FF) : const Color(0xFF0F1124);
  static Color sub(bool d) =>
      d ? const Color(0xFF7880A0) : const Color(0xFF8890B0);
}

// ─────────────────────────────────────────────
// DATA MODELS & FETCHING
// ─────────────────────────────────────────────
class _Candle {
  final DateTime time;
  final double open, high, low, close;
  _Candle(this.time, this.open, this.high, this.low, this.close);
}

String _dayString(DateTime dt) => DateFormat('yyyy-MM-dd').format(dt);

void _snack(BuildContext context, String msg, {required bool ok}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Row(children: [
      Icon(ok ? Icons.check_circle_rounded : Icons.error_outline_rounded,
          color: ok ? _DT.green : _DT.red, size: 16),
      const SizedBox(width: 8),
      Expanded(
          child: Text(msg,
              style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFFEEF0FF),
                  fontWeight: FontWeight.w500))),
    ]),
    backgroundColor: const Color(0xFF252840),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    margin: const EdgeInsets.all(12),
    duration: const Duration(seconds: 3),
  ));
}

Future<List<_Candle>> _fetchCandles({
  required String algoSymbol,
  required DateTime start,
  required DateTime end,
}) async {
  final res = await Supabase.instance.client
      .from('nifty_ohlcv')
      .select()
      .eq('symbol', algoSymbol)
      .gte('ts', start.toUtc().toIso8601String())
      .lte('ts', end.toUtc().toIso8601String())
      .order('ts', ascending: true);

  return (res as List).map((m) {
    // Force UTC parsing in case Supabase drops the 'Z', then safely convert to local
    final tsStr = m['ts'] as String;
    final parsedTime = tsStr.endsWith('Z') || tsStr.contains('+')
        ? DateTime.parse(tsStr)
        : DateTime.parse('${tsStr}Z');

    return _Candle(
      parsedTime.toLocal(), // Let Dart handle the exact IST conversion
      (m['open'] as num).toDouble(),
      (m['high'] as num).toDouble(),
      (m['low'] as num).toDouble(),
      (m['close'] as num).toDouble(),
    );
  }).toList();
}

// ─────────────────────────────────────────────
// MAIN PAGE
// ─────────────────────────────────────────────
class SavedBacktestDetailPage extends StatefulWidget {
  final BacktestApiService api;
  final SavedBacktestModel algo;

  const SavedBacktestDetailPage(
      {super.key, required this.api, required this.algo});

  @override
  State<SavedBacktestDetailPage> createState() =>
      _SavedBacktestDetailPageState();
}

class _SavedBacktestDetailPageState extends State<SavedBacktestDetailPage> {
  String _plan = 'free';
  bool _planLoading = true;
  bool _chartLoading = true;
  String? _error;

  late SavedBacktestModel _algo = widget.algo;
  AlertLimitModel? _alertLimit;
  bool _alertBusy = false;

  Map<String, List<_Candle>> _candlesByDay = {};
  Map<String, List<EntryModel>> _entriesByDay = {};
  List<String> _availableDays = [];
  int _selectedDayIndex = 0;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  bool get _isSubscribed => _plan == 'pro' || _plan == 'max';

  @override
  void initState() {
    super.initState();
    _loadPlan();
    _loadData();
  }

  Future<void> _loadPlan() async {
    try {
      final results = await Future.wait([
        widget.api.getUserPlan(),
        widget.api.getAlertLimit(),
      ]);
      if (mounted) {
        setState(() {
          _plan = results[0] as String;
          _alertLimit = results[1] as AlertLimitModel;
        });
      }
    } catch (_) {
      // If the limit fetch fails we just fall back to plan-only gating --
      // the enable call still enforces the real limit server-side.
    } finally {
      if (mounted) setState(() => _planLoading = false);
    }
  }

  Future<void> _toggleAlert() async {
    if (!_isSubscribed) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => AlertsListPage(api: widget.api)));
      return;
    }

    setState(() => _alertBusy = true);
    try {
      final updated = _algo.isAlertEnabled
          ? await widget.api.disableAlert(_algo.id)
          : await widget.api.enableAlert(_algo.id);
      if (!mounted) return;
      setState(() => _algo = updated);
      _snack(
        context,
        updated.isAlertEnabled
            ? 'You\'ll be notified when this setup shows up again.'
            : 'Notifications turned off for this algo.',
        ok: true,
      );
      // Refresh the used/remaining count shown in the limit chip.
      try {
        final limit = await widget.api.getAlertLimit();
        if (mounted) setState(() => _alertLimit = limit);
      } catch (_) {}
    } on BacktestApiException catch (e) {
      if (!mounted) return;
      final msg = e.message;
      final isLimitHit = msg.contains('limit');
      if (isLimitHit) {
        _showLimitDialog(msg);
      } else {
        _snack(context, msg, ok: false);
      }
    } catch (e) {
      if (mounted) _snack(context, e.toString(), ok: false);
    } finally {
      if (mounted) setState(() => _alertBusy = false);
    }
  }

  void _showLimitDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _DT.surface(_isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Alert limit reached',
            style: TextStyle(
                color: _DT.text(_isDark), fontWeight: FontWeight.w700)),
        content: Text(message,
            style: TextStyle(color: _DT.sub(_isDark), fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: _DT.sub(_isDark))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: _DT.accent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => AlertsListPage(api: widget.api)));
            },
            child: const Text('Manage alerts',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _loadData() async {
    try {
      final r = _algo;
      final end = r.lastRunAt ?? DateTime.now();
      final start = end.subtract(Duration(days: r.days));

      final candles =
          await _fetchCandles(algoSymbol: r.symbol, start: start, end: end);

      final groupedCandles = <String, List<_Candle>>{};
      for (var c in candles) {
        final d = _dayString(c.time);
        groupedCandles.putIfAbsent(d, () => []).add(c);
      }

      // Replace your groupedEntries loop with this:
      final groupedEntries = <String, List<EntryModel>>{};
      for (var e in r.entries) {
        final d = _dayString(e.time.toLocal()); // <-- Added .toLocal() here!
        groupedEntries.putIfAbsent(d, () => []).add(e);
      }
      // Only show days that actually have entries so it's not empty
      final sortedDays = groupedEntries.keys.toList()
        ..sort((a, b) => b.compareTo(a));

      if (mounted) {
        setState(() {
          _candlesByDay = groupedCandles;
          _entriesByDay = groupedEntries;
          _availableDays = sortedDays;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _chartLoading = false);
    }
  }

  void _showDetailsSheet() {
    final dark = _isDark;
    final r = _algo;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _DT.surface(dark),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Performance Details',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _DT.text(dark))),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              childAspectRatio: 1.5,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                _statTile(
                    'Matched', '${r.matchedBars ?? 0}', _DT.text(dark), dark),
                _statTile('Confirmed', '${r.confirmed ?? 0}', _DT.green, dark),
                _statTile('Failed', '${r.failed ?? 0}', _DT.red, dark),
                _statTile('Pending', '${r.pending ?? 0}', _DT.amber, dark),
                _statTile(
                    'Total bars', '${r.totalBars ?? 0}', _DT.sub(dark), dark),
                _statTile(
                    'Hit rate',
                    r.hitRate != null
                        ? '${r.hitRate!.toStringAsFixed(1)}%'
                        : '—',
                    _confidenceColor(r.hitRate),
                    dark),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _statTile(String label, String value, Color color, bool dark) =>
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: color.withOpacity(0.07),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.2))),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800, color: color)),
              Text(label, style: TextStyle(fontSize: 10, color: _DT.sub(dark))),
            ]),
      );

  Color _confidenceColor(double? hitRate) {
    if (hitRate == null) return _DT.amber;
    if (hitRate >= 60) return _DT.green;
    if (hitRate >= 40) return _DT.amber;
    return _DT.red;
  }

  @override
  Widget build(BuildContext context) {
    final dark = _isDark;

    return Scaffold(
      backgroundColor: _DT.bg(dark),
      appBar: AppBar(
        backgroundColor: _DT.surface(dark),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: _DT.accent, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_algo.name,
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: _DT.text(dark))),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: _TopSummaryCard(
                dark: dark,
                result: _algo,
                onTap: _showDetailsSheet,
              ),
            ),
            if (_chartLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              Expanded(
                  child: Center(
                      child: Text(_error!,
                          style: TextStyle(color: _DT.sub(dark)))))
            else if (_availableDays.isEmpty)
              Expanded(
                  child: Center(
                      child: Text("No entries found.",
                          style: TextStyle(color: _DT.sub(dark)))))
            else ...[
              // Day Navigator
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _availableDays.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (ctx, i) {
                    final d = _availableDays[i];
                    final isSel = i == _selectedDayIndex;
                    return ChoiceChip(
                      label:
                          Text(DateFormat('d MMM').format(DateTime.parse(d))),
                      selected: isSel,
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _selectedDayIndex = i),
                      selectedColor: _DT.accent.withOpacity(0.15),
                      backgroundColor: _DT.surface(dark),
                      labelStyle: TextStyle(
                        color: isSel ? _DT.accent : _DT.sub(dark),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      side: BorderSide(
                          color: isSel ? _DT.accent : _DT.border(dark)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    );
                  },
                ),
              ),

              // Daily Chart and Alerts below
              Expanded(
                child: _DailyChartAndAlerts(
                  dark: dark,
                  date: _availableDays[_selectedDayIndex],
                  candles:
                      _candlesByDay[_availableDays[_selectedDayIndex]] ?? [],
                  entries:
                      _entriesByDay[_availableDays[_selectedDayIndex]] ?? [],
                ),
              ),
            ]
          ],
        ),
      ),
      bottomNavigationBar: _planLoading ? null : _buildBottomButton(dark),
    );
  }

  // ───────────────────────────────────────────
  // BOTTOM NOTIFY BAR — redesigned for clarity
  // ───────────────────────────────────────────
  Widget _buildBottomButton(bool dark) {
    final on = _algo.isAlertEnabled;
    final limit = _alertLimit;

    // Plain-English status copy, no jargon.
    late final String title;
    late final String subtitle;
    late final IconData icon;
    late final Color iconColor;

    if (!_isSubscribed) {
      title = 'Get notified next time';
      subtitle = 'Unlock alerts with Pro or Max';
      icon = Icons.lock_outline_rounded;
      iconColor = _DT.sub(dark);
    } else if (on) {
      title = 'Notifications are on';
      subtitle = _algo.lastCheckedAt != null
          ? 'Last checked ${_timeAgoShort(_algo.lastCheckedAt!)}'
          : 'We\'ll ping you if this happens again';
      icon = Icons.notifications_active_rounded;
      iconColor = _DT.accent;
    } else {
      title = 'Turn on notifications';
      subtitle = limit != null
          ? '${limit.used} of ${limit.limit} alerts used'
          : 'Get pinged when this setup repeats';
      icon = Icons.notifications_none_rounded;
      iconColor = _DT.sub(dark);
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: _DT.surface(dark),
        border: Border(top: BorderSide(color: _DT.border(dark))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Whole card is one tap target — no more guessing whether
            // to tap the text or the switch.
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _alertBusy ? null : _toggleAlert,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Row(children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.14),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, size: 18, color: iconColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: _DT.text(dark)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  TextStyle(fontSize: 11, color: _DT.sub(dark)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _alertBusy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : (!_isSubscribed
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _DT.accent,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'Upgrade',
                                    style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white),
                                  ),
                                )
                              : Switch(
                                  value: on,
                                  activeColor: _DT.accent,
                                  onChanged: (_) => _toggleAlert(),
                                )),
                    ]),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              tooltip: 'View all alerts',
              style: IconButton.styleFrom(
                backgroundColor: _DT.surface2(dark),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: _DT.border(dark))),
                padding: const EdgeInsets.all(12),
              ),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => AlertsListPage(api: widget.api))),
              icon: Icon(Icons.notifications_active_rounded,
                  size: 20, color: _DT.sub(dark)),
            ),
          ],
        ),
      ),
    );
  }
}

String _timeAgoShort(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inDays > 0) return '${diff.inDays}d ago';
  if (diff.inHours > 0) return '${diff.inHours}h ago';
  if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
  return 'just now';
}

// ─────────────────────────────────────────────
// TOP SUMMARY (TAPPABLE)
// ─────────────────────────────────────────────
class _TopSummaryCard extends StatelessWidget {
  final bool dark;
  final SavedBacktestModel result;
  final VoidCallback onTap;

  const _TopSummaryCard(
      {required this.dark, required this.result, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hitRate = result.hitRate;
    Color confColor = _DT.amber;
    String confLabel = 'Mixed track record';

    if (hitRate != null) {
      if (hitRate >= 60) {
        confColor = _DT.green;
        confLabel = 'Strong track record';
      } else if (hitRate < 40) {
        confColor = _DT.red;
        confLabel = 'Weak track record';
      }
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _DT.surface(dark),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _DT.border(dark)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: confColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: confColor.withOpacity(0.3))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.thumb_up_rounded, size: 13, color: confColor),
                const SizedBox(width: 6),
                Text(confLabel,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: confColor)),
              ]),
            ),
            const Spacer(),
            if (hitRate != null)
              Text('${hitRate.toStringAsFixed(0)}% worked out',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _DT.sub(dark))),
          ]),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// DAILY CHART & ALERTS VIEW
// ─────────────────────────────────────────────
class _DailyChartAndAlerts extends StatefulWidget {
  final bool dark;
  final String date;
  final List<_Candle> candles;
  final List<EntryModel> entries;

  const _DailyChartAndAlerts({
    required this.dark,
    required this.date,
    required this.candles,
    required this.entries,
  });

  @override
  State<_DailyChartAndAlerts> createState() => _DailyChartAndAlertsState();
}

class _DailyChartAndAlertsState extends State<_DailyChartAndAlerts> {
  int? _selectedAlertIndex;

  late final TrackballBehavior _trackball = TrackballBehavior(
    enable: true,
    activationMode: ActivationMode.singleTap,
    lineType: TrackballLineType.vertical,
    // Use groupAllPoints to show OHLC data cleanly in one popup
    tooltipDisplayMode: TrackballDisplayMode.groupAllPoints,
  );

  void _selectAlert(int index) {
    setState(() => _selectedAlertIndex = index);
    final dt = widget.entries[index].time;
    // Find nearest candle
    if (widget.candles.isNotEmpty) {
      int bestIdx = 0;
      int minDiff =
          (widget.candles[0].time.difference(dt)).inMilliseconds.abs();
      for (int i = 1; i < widget.candles.length; i++) {
        int diff = (widget.candles[i].time.difference(dt)).inMilliseconds.abs();
        if (diff < minDiff) {
          minDiff = diff;
          bestIdx = i;
        }
      }
      _trackball.showByIndex(bestIdx);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.dark;
    final cBull = const Color(0xFF00C896);
    final cBear = const Color(0xFFFF4D6D);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _DT.surface(dark),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _DT.border(dark)),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.candlestick_chart_rounded,
                  size: 15, color: _DT.accent),
              const SizedBox(width: 7),
              Text('NIFTY price chart',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: _DT.text(dark))),
              const Spacer(),
              Text(DateFormat('d MMM yyyy').format(DateTime.parse(widget.date)),
                  style: TextStyle(fontSize: 10, color: _DT.sub(dark))),
            ]),
            const SizedBox(height: 4),
            Text(
                'Dots show exactly where this setup fired. Tap an alert below to view.',
                style: TextStyle(fontSize: 11, color: _DT.sub(dark))),
            const SizedBox(height: 10),
            SizedBox(
              height: 240,
              child: SfCartesianChart(
                margin: EdgeInsets.zero,
                plotAreaBorderWidth: 0,
                trackballBehavior: _trackball,
                zoomPanBehavior:
                    ZoomPanBehavior(enablePanning: true, zoomMode: ZoomMode.x),
                primaryXAxis: DateTimeAxis(
                  majorGridLines: const MajorGridLines(width: 0),
                  labelStyle: TextStyle(color: _DT.sub(dark), fontSize: 9),
                  dateFormat: DateFormat('h:mm a'),
                  // Add these 4 lines to show the time bubble at the bottom:
                  interactiveTooltip: const InteractiveTooltip(
                    enable: true,
                    format: 'h:mm a',
                  ),
                ),
                primaryYAxis: NumericAxis(
                  majorGridLines: MajorGridLines(
                      color: _DT.border(dark), dashArray: const [4, 4]),
                  labelStyle: TextStyle(color: _DT.sub(dark), fontSize: 9),
                ),
                series: <CartesianSeries>[
                  CandleSeries<_Candle, DateTime>(
                    dataSource: widget.candles,
                    xValueMapper: (c, _) => c.time,
                    lowValueMapper: (c, _) => c.low,
                    highValueMapper: (c, _) => c.high,
                    openValueMapper: (c, _) => c.open,
                    closeValueMapper: (c, _) => c.close,
                    bullColor: cBull,
                    bearColor: cBear,
                    enableSolidCandles: true,
                  ),
                ],
                annotations: List.generate(
                  widget.entries.length,
                  (i) => _buildAnnotation(i, widget.entries[i], cBull, cBear),
                ).whereType<CartesianChartAnnotation>().toList(),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        Text('Alerts Today',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _DT.text(dark))),
        const SizedBox(height: 10),
        for (int i = 0; i < widget.entries.length; i++)
          _AlertTile(
            dark: dark,
            entry: widget.entries[i],
            isSelected: _selectedAlertIndex == i,
            onTap: () => _selectAlert(i),
          ),
      ],
    );
  }

  CartesianChartAnnotation? _buildAnnotation(
      int index, EntryModel entry, Color bull, Color bear) {
    if (widget.candles.isEmpty) return null;
    final isSel = _selectedAlertIndex == index;
    final outColor = entry.outcome == 'Confirmed'
        ? bull
        : (entry.outcome == 'Failed' ? bear : _DT.amber);

    return CartesianChartAnnotation(
      widget: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: isSel ? 16 : 8,
        height: isSel ? 16 : 8,
        decoration: BoxDecoration(
          color: outColor,
          shape: BoxShape.circle,
          border: isSel ? Border.all(color: Colors.white, width: 2) : null,
          boxShadow: isSel
              ? [BoxShadow(color: outColor.withOpacity(0.5), blurRadius: 6)]
              : null,
        ),
      ),
      coordinateUnit: CoordinateUnit.point,
      x: entry.time,
      y: entry.close,
    );
  }
}

class _AlertTile extends StatelessWidget {
  final bool dark;
  final EntryModel entry;
  final bool isSelected;
  final VoidCallback onTap;

  const _AlertTile(
      {required this.dark,
      required this.entry,
      required this.isSelected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cBull = const Color(0xFF00C896);
    final cBear = const Color(0xFFFF4D6D);
    final outColor = entry.outcome == 'Confirmed'
        ? cBull
        : (entry.outcome == 'Failed' ? cBear : _DT.amber);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected ? _DT.accent.withOpacity(0.1) : _DT.surface(dark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isSelected ? _DT.accent : _DT.border(dark)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(Icons.my_location_rounded,
            size: 20, color: isSelected ? _DT.accent : _DT.sub(dark)),
        // Change this line in _AlertTile:
        title: Text(DateFormat('hh:mm a').format(entry.time.toLocal()),
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _DT.text(dark))),
        subtitle: Text('Price: ${entry.close.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 12, color: _DT.sub(dark))),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
              color: outColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12)),
          child: Text(entry.outcome,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: outColor)),
        ),
      ),
    );
  }
}
