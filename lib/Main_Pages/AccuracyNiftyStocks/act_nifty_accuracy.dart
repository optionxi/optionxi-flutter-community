// =============================================================================
// Atlas × Nifty — DASHBOARD SCREENS (v3)
// -----------------------------------------------------------------------------
// Changes in this pass:
//   • Removed the Material checkmark on selected chips (Bull/Bear direction
//     toggle, entry mode, lookback, and the date strip) — selection is
//     already obvious from color/border, the check felt redundant.
//   • Settings sheet now exposes the entry TIME window (start/end) that was
//     already being applied in _refresh() but had no UI control.
//   • Days tab reworked: instead of one chart per signal, there's a single
//     whole-day candlestick chart with a marker for every alert, plus a
//     ListView of alert rows underneath. Tapping a row selects it — the
//     matching marker on the chart is highlighted and the chart's trackball
//     jumps to that point so you can see exactly when in the session the
//     alert fired.
//   • Added a DeepAnalysisBanner ("click here to visit the webview...") and
//     a ProUpgradeButton ("purchase Pro for realtime alerts", opens
//     WhatsApp) near the top of the Overview tab.
//   • RiskRewardBar tap → jump to Days tab with selected alert + entry-exit
//     range shaded on the candlestick chart.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:optionxi/Components/cust_upgrade_to_pro.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' as math;

import 'atlas_core.dart' hide TimeOfDay;
import 'atlas_theme.dart';

// =============================================================================
// APP SHELL
// =============================================================================

class NiftyDashboardShell extends StatefulWidget {
  const NiftyDashboardShell({super.key});
  @override
  State<NiftyDashboardShell> createState() => _NiftyDashboardShellState();
}

class _NiftyDashboardShellState extends State<NiftyDashboardShell> {
  int tab = 0;
  late final SupabaseService supabaseService;

  AtlasSettings settings = AtlasSettings();
  bool loading = false;
  String? error;

  List<AtlasSignal> signals = [];
  Map<String, List<Candle>> niftyStore = {};
  List<Outcome> outcomes = [];
  List<DailySummary> dailySummary = [];
  Map<String, List<Outcome>> exitDetailFrames = {};
  List<StrategyRow> exitSummary = [];

  String? jumpToDate;
  Outcome? jumpToOutcome; // NEW: for jumping to a specific alert

  @override
  void initState() {
    super.initState();
    initAtlasTimeago();
    SupabaseClient? client;
    try {
      client = Supabase.instance.client;
    } catch (_) {
      client = null;
    }
    supabaseService = SupabaseService(client);
    _refresh();
  }

  Future<void> _ensureNiftyCandles() async {
    final wantedDates = signals.map((s) => s.date).toSet();
    final missing = wantedDates.difference(niftyStore.keys.toSet());
    if (missing.isEmpty) return;

    final today =
        DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
    final todayDate = DateTime.utc(today.year, today.month, today.day);
    final startDate =
        todayDate.subtract(Duration(days: settings.lookbackDays - 1));

    final rows = await supabaseService.fetchOhlcvArchive(startDate, todayDate);
    final Map<String, List<Candle>> grouped = {};
    for (final c in rows) {
      grouped.putIfAbsent(fmtDate(c.ts), () => []).add(c);
    }
    grouped.forEach((d, list) {
      list.sort((a, b) => a.ts.compareTo(b.ts));
      niftyStore[d] = list;
    });
  }

  Future<void> _refresh({bool hardReset = false}) async {
    setState(() {
      loading = true;
      error = null;
      if (hardReset) niftyStore = {};
    });
    try {
      final raw = await supabaseService.fetchAtlasEntries(
          settings.lookbackDays, settings.minProbability);
      if (raw.isEmpty) {
        _resetComputed();
        return;
      }
      final useBreakout = settings.entryMode == 'Breakout entry (day H/L)';
      var sigs = AtlasEngine.buildSignals(raw,
          useBreakout ? false : settings.entryMode == 'First entry per day');
      sigs = AtlasEngine.filterByEntryTimeWindow(
          sigs, settings.entryStart, settings.entryEnd);
      if (sigs.isEmpty) {
        _resetComputed();
        return;
      }
      signals = sigs;
      await _ensureNiftyCandles();
      if (useBreakout) {
        signals = AtlasEngine.selectBreakoutSignals(signals, niftyStore);
      }
      final allOutcomes = AtlasEngine.computeOutcomes(
          signals, niftyStore, settings.exitWindowMinutes);
      outcomes = allOutcomes
          .where((o) => settings.directions.contains(o.signal.direction))
          .toList();
      dailySummary = AtlasEngine.computeDailySummary(outcomes);
      exitDetailFrames = {};
      final filteredSignals = signals
          .where((s) => settings.directions.contains(s.direction))
          .toList();
      exitSummary = AtlasEngine.buildExitStrategySummary(
          filteredSignals, niftyStore, exitDetailFrames);
    } catch (e) {
      error = e.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _resetComputed() {
    signals = [];
    outcomes = [];
    dailySummary = [];
    exitSummary = [];
    exitDetailFrames = {};
  }

  void _jumpToDay(String date) {
    setState(() {
      jumpToDate = date;
      jumpToOutcome = null;
      tab = 1;
    });
  }

  // NEW METHOD: jump to a specific signal/alert on the Days tab
  void _jumpToSignal(Outcome o) {
    setState(() {
      jumpToDate = o.signal.date;
      jumpToOutcome = o;
      tab = 1;
    });
  }

  void _openSettings() async {
    final draft = settings.copy();
    final applied = await showModalBottomSheet<AtlasSettings>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SettingsSheet(settings: draft),
    );
    if (applied != null) {
      setState(() => settings = applied);
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = atlasColors(context);
    final t = atlasText(context);
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [c.accent, c.accent2]),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.show_chart_rounded,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Text('Atlas', style: t.h1),
            Text(' × Nifty',
                style: t.h1
                    .copyWith(color: c.textFaint, fontWeight: FontWeight.w500)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: loading ? null : () => _refresh(),
          ),
          IconButton(
            tooltip: 'Filters',
            icon: Badge(
              isLabelVisible: settings.directions.length < 2,
              smallSize: 7,
              child: const Icon(Icons.tune_rounded),
            ),
            onPressed: _openSettings,
          ),
          const SizedBox(width: 4),
        ],
        bottom: loading
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2.5), child: AtlasLoadingBar())
            : null,
      ),
      body: SafeArea(
        top: false,
        child: error != null
            ? _ErrorView(error: error!, onRetry: () => _refresh())
            : (signals.isEmpty && !loading)
                ? AtlasEmptyState(
                    icon: Icons.filter_alt_off_rounded,
                    title: 'No signals found',
                    message:
                        'Try lowering the minimum probability or widening the lookback window.',
                    actionLabel: 'Open filters',
                    onAction: _openSettings,
                  )
                : IndexedStack(
                    index: tab,
                    children: [
                      OverviewScreen(
                        dailySummary: dailySummary,
                        outcomes: outcomes,
                        onJumpToDay: _jumpToDay,
                        onJumpToSignal: _jumpToSignal, // NEW
                      ),
                      DaysScreen(
                        outcomes: outcomes,
                        niftyStore: niftyStore,
                        jumpToDate: jumpToDate,
                        jumpToOutcome: jumpToOutcome, // NEW
                        onConsumedJump: () {
                          jumpToDate = null;
                          jumpToOutcome = null; // NEW: clear both
                        },
                      ),
                      StrategyScreen(
                        rows: exitSummary,
                        detailFrames: exitDetailFrames,
                      ),
                    ],
                  ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded),
              label: 'Overview'),
          NavigationDestination(
              icon: Icon(Icons.calendar_view_day_outlined),
              selectedIcon: Icon(Icons.calendar_view_day_rounded),
              label: 'Days'),
          NavigationDestination(
              icon: Icon(Icons.auto_graph_outlined),
              selectedIcon: Icon(Icons.auto_graph_rounded),
              label: 'Strategy'),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    final c = atlasColors(context);
    final t = atlasText(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Sp.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, color: c.bear, size: 36),
            const SizedBox(height: Sp.md),
            Text('Something went wrong', style: t.h2),
            const SizedBox(height: 6),
            Text(error, style: t.bodyMuted, textAlign: TextAlign.center),
            const SizedBox(height: Sp.lg),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// SETTINGS SHEET
// =============================================================================
enum _EntryPreset { fullSession, morning, afternoon, custom }

class SettingsSheet extends StatefulWidget {
  final AtlasSettings settings;
  const SettingsSheet({super.key, required this.settings});
  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  late AtlasSettings s = widget.settings;
  late _EntryPreset _preset = _presetFor(s.entryStart, s.entryEnd);

  static const _fullStart =
      TimeOfDayLite(MarketHours.openHour, MarketHours.openMinute);
  static const _fullEnd =
      TimeOfDayLite(MarketHours.closeHour, MarketHours.closeMinute);
  static const _morningStart =
      TimeOfDayLite(MarketHours.openHour, MarketHours.openMinute);
  static const _morningEnd = TimeOfDayLite(12, 0);
  static const _afternoonStart = TimeOfDayLite(12, 0);
  static const _afternoonEnd =
      TimeOfDayLite(MarketHours.closeHour, MarketHours.closeMinute);

  bool _sameLite(TimeOfDayLite a, TimeOfDayLite b) =>
      a.hour == b.hour && a.minute == b.minute;

  _EntryPreset _presetFor(TimeOfDayLite start, TimeOfDayLite end) {
    if (_sameLite(start, _fullStart) && _sameLite(end, _fullEnd)) {
      return _EntryPreset.fullSession;
    }
    if (_sameLite(start, _morningStart) && _sameLite(end, _morningEnd)) {
      return _EntryPreset.morning;
    }
    if (_sameLite(start, _afternoonStart) && _sameLite(end, _afternoonEnd)) {
      return _EntryPreset.afternoon;
    }
    return _EntryPreset.custom;
  }

  void _applyPreset(_EntryPreset p) {
    setState(() {
      _preset = p;
      switch (p) {
        case _EntryPreset.fullSession:
          s.entryStart = _fullStart;
          s.entryEnd = _fullEnd;
          break;
        case _EntryPreset.morning:
          s.entryStart = _morningStart;
          s.entryEnd = _morningEnd;
          break;
        case _EntryPreset.afternoon:
          s.entryStart = _afternoonStart;
          s.entryEnd = _afternoonEnd;
          break;
        case _EntryPreset.custom:
          break;
      }
    });
  }

  TimeOfDay _toFlutterTod(TimeOfDayLite raw) =>
      TimeOfDay(hour: raw.hour, minute: raw.minute);
  TimeOfDayLite _toLite(TimeOfDay t) => TimeOfDayLite(t.hour, t.minute);

  Future<void> _pickTime({required bool isStart}) async {
    final current = _toFlutterTod(isStart ? s.entryStart : s.entryEnd);
    final picked = await showTimePicker(context: context, initialTime: current);
    if (picked == null) return;
    setState(() {
      if (isStart) {
        s.entryStart = _toLite(picked);
      } else {
        s.entryEnd = _toLite(picked);
      }
      _preset = _EntryPreset.custom;
    });
  }

  String _fmtTod(TimeOfDayLite raw) {
    final h = raw.hour % 12 == 0 ? 12 : raw.hour % 12;
    final m = raw.minute.toString().padLeft(2, '0');
    final period = raw.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    final c = atlasColors(context);
    final t = atlasText(context);
    final maxH = MediaQuery.of(context).size.height * 0.88;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: Container(
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                          color: c.border,
                          borderRadius: BorderRadius.circular(2))),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(Sp.lg, Sp.md, Sp.lg, 0),
                    child: Row(children: [
                      Icon(Icons.tune_rounded, size: 18, color: c.accent),
                      const SizedBox(width: 8),
                      Expanded(child: Text('Filters', style: t.h1)),
                      TextButton.icon(
                        onPressed: () =>
                            Navigator.pop(context, AtlasSettings()),
                        icon: const Icon(Icons.restart_alt_rounded, size: 16),
                        label: const Text('Reset'),
                      ),
                    ]),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(Sp.lg, Sp.sm, Sp.lg, Sp.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label(context, Icons.calendar_today_rounded,
                            'Lookback window'),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: kLookbackOptions
                              .map((d) => AtlasChipToggle(
                                    label: '${d}d',
                                    selected: s.lookbackDays == d,
                                    activeColor: c.accent,
                                    onChanged: (_) =>
                                        setState(() => s.lookbackDays = d),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: Sp.lg),
                        _label(context, Icons.bolt_rounded,
                            'Min. probability — ${s.minProbability.toStringAsFixed(0)}%'),
                        Slider(
                          value: s.minProbability,
                          min: kProbMin,
                          max: kProbMax,
                          divisions: (kProbMax - kProbMin).toInt(),
                          label: '${s.minProbability.toStringAsFixed(0)}%',
                          onChanged: (v) =>
                              setState(() => s.minProbability = v),
                        ),
                        const SizedBox(height: Sp.md),
                        _label(context, Icons.login_rounded, 'Entry selection'),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: kEntryModes
                              .map((m) => AtlasChipToggle(
                                    label: m,
                                    selected: s.entryMode == m,
                                    activeColor: c.accent,
                                    onChanged: (_) =>
                                        setState(() => s.entryMode = m),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: Sp.lg),
                        _label(context, Icons.access_time_rounded,
                            'Entry time window'),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            AtlasChipToggle(
                              label: 'Full session',
                              selected: _preset == _EntryPreset.fullSession,
                              activeColor: c.accent,
                              onChanged: (_) =>
                                  _applyPreset(_EntryPreset.fullSession),
                            ),
                            AtlasChipToggle(
                              label: 'Morning',
                              selected: _preset == _EntryPreset.morning,
                              activeColor: c.accent,
                              onChanged: (_) =>
                                  _applyPreset(_EntryPreset.morning),
                            ),
                            AtlasChipToggle(
                              label: 'Afternoon',
                              selected: _preset == _EntryPreset.afternoon,
                              activeColor: c.accent,
                              onChanged: (_) =>
                                  _applyPreset(_EntryPreset.afternoon),
                            ),
                            AtlasChipToggle(
                              label: 'Custom',
                              selected: _preset == _EntryPreset.custom,
                              activeColor: c.accent,
                              onChanged: (_) =>
                                  _applyPreset(_EntryPreset.custom),
                            ),
                          ],
                        ),
                        const SizedBox(height: Sp.sm),
                        if (_preset == _EntryPreset.custom)
                          Row(children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _pickTime(isStart: true),
                                icon: const Icon(Icons.schedule_rounded,
                                    size: 15),
                                label: Text('From ${_fmtTod(s.entryStart)}'),
                              ),
                            ),
                            const SizedBox(width: Sp.sm),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _pickTime(isStart: false),
                                icon: const Icon(Icons.schedule_rounded,
                                    size: 15),
                                label: Text('To ${_fmtTod(s.entryEnd)}'),
                              ),
                            ),
                          ])
                        else
                          Text(
                              '${_fmtTod(s.entryStart)} – ${_fmtTod(s.entryEnd)} IST',
                              style: t.bodyMuted),
                        const SizedBox(height: Sp.lg),
                        _label(context, Icons.timer_outlined,
                            'Exit window — ${s.exitWindowMinutes >= 375 ? 'End of day' : formatMinutes(s.exitWindowMinutes.toDouble())}'),
                        Slider(
                          value: s.exitWindowMinutes.toDouble(),
                          min: kExitMin.toDouble(),
                          max: kExitMax.toDouble(),
                          divisions: (kExitMax - kExitMin) ~/ 5,
                          onChanged: (v) => setState(
                              () => s.exitWindowMinutes = (v ~/ 5) * 5),
                        ),
                        const SizedBox(height: Sp.md),
                        _label(context, Icons.swap_vert_rounded, 'Direction'),
                        Row(children: [
                          AtlasChipToggle(
                            label: 'Bull',
                            icon: Icons.arrow_upward_rounded,
                            selected: s.directions.contains('Bull'),
                            activeColor: c.bull,
                            onChanged: (v) => setState(() => v
                                ? s.directions.add('Bull')
                                : s.directions.remove('Bull')),
                          ),
                          const SizedBox(width: 8),
                          AtlasChipToggle(
                            label: 'Bear',
                            icon: Icons.arrow_downward_rounded,
                            selected: s.directions.contains('Bear'),
                            activeColor: c.bear,
                            onChanged: (v) => setState(() => v
                                ? s.directions.add('Bear')
                                : s.directions.remove('Bear')),
                          ),
                        ]),
                        const SizedBox(height: Sp.lg),
                        FilledButton.icon(
                          onPressed: () => Navigator.pop(context, s),
                          style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(48)),
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: const Text('Apply filters'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(BuildContext context, IconData icon, String text) {
    final t = atlasText(context);
    final c = atlasColors(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Sp.sm),
      child: Row(children: [
        Icon(icon, size: 13, color: c.textFaint),
        const SizedBox(width: 5),
        Text(text, style: t.caption),
      ]),
    );
  }
}

// =============================================================================
// OVERVIEW SCREEN
// =============================================================================
class OverviewScreen extends StatelessWidget {
  final List<DailySummary> dailySummary;
  final List<Outcome> outcomes;
  final void Function(String date) onJumpToDay;
  final void Function(Outcome) onJumpToSignal; // NEW
  const OverviewScreen({
    super.key,
    required this.dailySummary,
    required this.outcomes,
    required this.onJumpToDay,
    required this.onJumpToSignal, // NEW
  });

  @override
  Widget build(BuildContext context) {
    final c = atlasColors(context);
    final total = outcomes.length;
    final succ = outcomes.where((o) => o.success).length;
    final acc = total == 0 ? 0.0 : succ / total * 100;
    final bull = outcomes.where((o) => o.signal.direction == 'Bull').toList();
    final bear = outcomes.where((o) => o.signal.direction == 'Bear').toList();
    final bullAcc = bull.isEmpty
        ? null
        : bull.where((o) => o.success).length / bull.length * 100;
    final bearAcc = bear.isEmpty
        ? null
        : bear.where((o) => o.success).length / bear.length * 100;
    final avgPeak = total == 0
        ? 0.0
        : outcomes.map((o) => o.timeToPeakMin).reduce((a, b) => a + b) / total;
    final avgFavorable = total == 0
        ? 0.0
        : outcomes.map((o) => o.maxProfitPcnt).reduce((a, b) => a + b) / total;
    final avgAdverse = total == 0
        ? 0.0
        : outcomes.map((o) => o.maxLossPcnt).reduce((a, b) => a + b) / total;

    return ListView(
      padding: const EdgeInsets.fromLTRB(Sp.lg, Sp.md, Sp.lg, Sp.xxl),
      children: [
        HeroStat(
          label: 'Overall accuracy',
          value: '${acc.toStringAsFixed(1)}%',
          valueColor: c.accuracyColor(acc),
          ringValue: acc,
          sublabel:
              '$succ of $total signals hit · avg peak in ${formatMinutes(avgPeak)}',
        ),
        const SizedBox(height: Sp.md),
        AtlasCard(
          child: Row(
            children: [
              RiskRewardBar(
                  rewardPcnt: avgFavorable, riskPcnt: avgAdverse, height: 48),
              const SizedBox(width: Sp.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Avg reward vs. risk', style: atlasText(context).body),
                    const SizedBox(height: 2),
                    Text(
                      'How far price typically moved in your favor vs. against you before exit.',
                      style: atlasText(context).bodyMuted,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        StatChipRow(chips: [
          StatChip(
              label: 'Bull acc.',
              icon: Icons.arrow_upward_rounded,
              value: bullAcc != null ? '${bullAcc.toStringAsFixed(0)}%' : '—',
              valueColor: c.bull),
          StatChip(
              label: 'Bear acc.',
              icon: Icons.arrow_downward_rounded,
              value: bearAcc != null ? '${bearAcc.toStringAsFixed(0)}%' : '—',
              valueColor: c.bear),
          StatChip(
              label: 'Signals',
              icon: Icons.query_stats_rounded,
              value: '$total'),
        ]),
        AtlasSectionHeader(
          title: 'Daily accuracy',
          icon: Icons.show_chart_rounded,
          infoTitle: 'What this shows',
          infoBuilder: (ctx) => _AccuracyInfoBody(daily: dailySummary),
        ),
        if (dailySummary.isEmpty)
          const AtlasEmptyState(
              icon: Icons.timeline_rounded,
              title: 'No trend yet',
              message: 'Not enough days to chart yet.')
        else
          AccuracyTrendChart(daily: dailySummary),
        AtlasSectionHeader(
            title: 'Daily breakdown',
            icon: Icons.calendar_month_rounded,
            trailingText: '${dailySummary.length} days'),
        if (dailySummary.isEmpty)
          const AtlasEmptyState(
              icon: Icons.event_busy_rounded,
              title: 'Nothing here yet',
              message: 'Daily results will appear once signals resolve.')
        else
          ...([...dailySummary]..sort((a, b) => b.date.compareTo(a.date)))
              .take(10)
              .map((d) =>
                  DailySummaryCard(day: d, onTap: () => onJumpToDay(d.date))),
        if (dailySummary.length > 10)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: TextButton.icon(
              onPressed: () => showAtlasSheet(context,
                  title: 'All days',
                  icon: Icons.calendar_month_rounded, builder: (ctx) {
                final sortedDays = [...dailySummary]
                  ..sort((a, b) => b.date.compareTo(a.date));

                return Column(
                  children: sortedDays
                      .map((d) => DailySummaryCard(
                          day: d,
                          onTap: () {
                            Navigator.pop(ctx);
                            onJumpToDay(d.date);
                          }))
                      .toList(),
                );
              }),
              icon: const Icon(Icons.expand_more_rounded, size: 18),
              label: Text('View all ${dailySummary.length} days'),
            ),
          ),
        AtlasSectionHeader(
          title: 'Signal log',
          icon: Icons.receipt_long_rounded,
          trailingText: '$total total',
          infoTitle: 'Signal log',
          infoBuilder: (ctx) => _SignalLogFull(
              outcomes: outcomes, onSelectDay: onJumpToSignal), // UPDATED
        ),
        if (outcomes.isEmpty)
          const AtlasEmptyState(
              icon: Icons.inbox_rounded,
              title: 'No signals',
              message: 'Nothing to show under current filters.')
        else ...[
          ...outcomes.take(6).map((o) =>
              SignalCard(outcome: o, onSelectDay: onJumpToSignal)), // UPDATED
          const SizedBox(height: Sp.sm),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => showAtlasSheet(context,
                    title: 'Signal log ($total)',
                    icon: Icons.receipt_long_rounded,
                    builder: (ctx) => _SignalLogFull(
                        outcomes: outcomes,
                        onSelectDay: onJumpToSignal)), // UPDATED
                icon: const Icon(Icons.list_alt_rounded, size: 17),
                label: const Text('View all'),
              ),
            ),
            const SizedBox(width: Sp.sm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showCsvSheet(context, outcomes),
                icon: const Icon(Icons.download_rounded, size: 17),
                label: const Text('Export CSV'),
              ),
            ),
          ]),
        ],
        const SizedBox(height: Sp.lg),
        const ProUpgradeButton(),
      ],
    );
  }

  void _showCsvSheet(BuildContext context, List<Outcome> rows) {
    final csv = outcomesToCsv(rows);
    showAtlasSheet(
      context,
      title: 'Export CSV',
      icon: Icons.download_rounded,
      builder: (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(Sp.md),
            decoration: BoxDecoration(
              color: atlasColors(ctx).surfaceAlt,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SelectableText(csv,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
          ),
          const SizedBox(height: Sp.md),
          FilledButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: csv));
              ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')));
            },
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Copy to clipboard'),
          ),
        ],
      ),
    );
  }
}

class _AccuracyInfoBody extends StatelessWidget {
  final List<DailySummary> daily;
  const _AccuracyInfoBody({required this.daily});
  @override
  Widget build(BuildContext context) {
    final t = atlasText(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Each point is the % of signals that day whose direction was confirmed by price '
          'before the exit window closed. Tap a day in the list below for details.',
          style: t.bodyMuted,
        ),
      ],
    );
  }
}

class _SignalLogFull extends StatelessWidget {
  final List<Outcome> outcomes;
  final void Function(Outcome) onSelectDay; // NEW
  const _SignalLogFull(
      {required this.outcomes, required this.onSelectDay}); // UPDATED
  @override
  Widget build(BuildContext context) {
    return Column(
        children: outcomes
            .map((o) => SignalCard(outcome: o, onSelectDay: onSelectDay))
            .toList()); // UPDATED
  }
}

class AccuracyTrendChart extends StatelessWidget {
  final List<DailySummary> daily;
  const AccuracyTrendChart({super.key, required this.daily});

  @override
  Widget build(BuildContext context) {
    final c = atlasColors(context);
    final t = atlasText(context);
    final sorted = [...daily]..sort((a, b) => a.date.compareTo(b.date));

    final rrMax = sorted.isEmpty
        ? 1.0
        : sorted
                .map((d) =>
                    [d.avgMaxProfit.abs(), d.avgMaxLoss.abs()].reduce(math.max))
                .reduce(math.max) *
            1.25;

    return AtlasCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            // _legendDot(c.accent, 'Accuracy', t),
            const SizedBox(width: 14),
            _legendDot(c.bull, 'Avg reward', t),
            const SizedBox(width: 14),
            _legendDot(c.bear, 'Avg risk', t),
          ]),
          const SizedBox(height: Sp.sm),
          SizedBox(
            height: 140,
            child: SfCartesianChart(
              margin: EdgeInsets.zero,
              plotAreaBorderWidth: 0,
              primaryXAxis: CategoryAxis(
                isVisible: true,
                majorGridLines: const MajorGridLines(width: 0),
                axisLine: const AxisLine(width: 0),
                labelStyle: TextStyle(color: c.textFaint, fontSize: 9),
                majorTickLines: const MajorTickLines(size: 0),
                interval: (sorted.length / 5).clamp(1, 999).toDouble(),
              ),
              primaryYAxis: NumericAxis(
                minimum: 0,
                maximum: 120,
                isVisible: false,
                majorGridLines:
                    MajorGridLines(color: c.border, dashArray: const [3, 4]),
              ),
              axes: <ChartAxis>[
                NumericAxis(
                    name: 'rr',
                    minimum: -rrMax,
                    maximum: rrMax,
                    isVisible: false),
                // NEW — a second, invisible x-axis with the same categories,
                // used only by the bear series so it doesn't cluster with bull.
                CategoryAxis(
                  name: 'xBear',
                  isVisible: false,
                  majorGridLines: const MajorGridLines(width: 0),
                  axisLine: const AxisLine(width: 0),
                  majorTickLines: const MajorTickLines(size: 0),
                ),
              ],
              series: <CartesianSeries>[
                ColumnSeries<DailySummary, String>(
                  dataSource: sorted,
                  xValueMapper: (d, _) => fmtDateShort(DateTime.parse(d.date)),
                  yValueMapper: (d, _) => d.avgMaxProfit,
                  yAxisName: 'rr',
                  color: c.bull,
                  width: 0.5,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(3)),
                ),
                ColumnSeries<DailySummary, String>(
                  dataSource: sorted,
                  xValueMapper: (d, _) => fmtDateShort(DateTime.parse(d.date)),
                  yValueMapper: (d, _) => d.avgMaxLoss,
                  yAxisName: 'rr',
                  xAxisName: 'xBear', // NEW — different x-axis, same categories
                  color: c.bear,
                  width: 0.5,
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(3)),
                ),
                SplineAreaSeries<DailySummary, String>(
                  dataSource: sorted,
                  xValueMapper: (d, _) => fmtDateShort(DateTime.parse(d.date)),
                  yValueMapper: (d, _) => d.accuracy,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      c.accent.withOpacity(0.32),
                      c.accent.withOpacity(0.02)
                    ],
                  ),
                  color: c.bear.withOpacity(0.35),
                  borderColor: c.accent,
                  borderWidth: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label, AtlasText t) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(label, style: t.caption),
        ],
      );
}

class DailySummaryCard extends StatelessWidget {
  final DailySummary day;
  final VoidCallback onTap;
  const DailySummaryCard({super.key, required this.day, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = atlasColors(context);
    final t = atlasText(context);
    final date = DateTime.parse(day.date);
    return AtlasCard(
      padding: const EdgeInsets.symmetric(horizontal: Sp.lg, vertical: Sp.md),
      onTap: onTap,
      child: Row(
        children: [
          AccuracyRing(value: day.accuracy, size: 44),
          const SizedBox(width: Sp.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fmtDateShort(date), style: t.body),
                const SizedBox(height: 2),
                Row(children: [
                  Icon(Icons.query_stats_rounded, size: 12, color: c.textFaint),
                  const SizedBox(width: 3),
                  Text('${day.signals} signals · ${day.success} hit',
                      style: t.bodyMuted),
                ]),
                const SizedBox(height: 2),
                TimeAgoChip(date, exactLabel: fmtDateShort(date)),
              ],
            ),
          ),
          Text(
            '${day.avgNetGain >= 0 ? '+' : ''}${day.avgNetGain.toStringAsFixed(2)}%',
            style: t.numberMd.copyWith(color: c.pnl(day.avgNetGain)),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, color: c.textFaint, size: 18),
        ],
      ),
    );
  }
}

/// Compact signal row — tap to expand for entry/exit/peak detail.
/// NEW: tapping the RiskRewardBar now jumps to the Days tab with this alert selected.
class SignalCard extends StatelessWidget {
  final Outcome outcome;
  final void Function(Outcome)? onSelectDay; // NEW
  const SignalCard(
      {super.key, required this.outcome, this.onSelectDay}); // UPDATED

  @override
  Widget build(BuildContext context) {
    final c = atlasColors(context);
    final t = atlasText(context);
    final o = outcome;
    return ExpandableCard(
      header: Row(
        children: [
          DirectionPill(o.signal.direction, compact: true),
          const SizedBox(width: Sp.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${fmtDateShort(o.signal.dt)} · ${o.signal.entryTimeIst}',
                    style: t.body),
                Row(children: [
                  Icon(Icons.bolt_rounded, size: 11, color: c.textFaint),
                  const SizedBox(width: 2),
                  Text('${o.signal.probability.toStringAsFixed(0)}%',
                      style: t.caption),
                  const SizedBox(width: 8),
                  TimeAgoChip(o.signal.dt),
                ]),
              ],
            ),
          ),
          Icon(
              o.success
                  ? Icons.check_circle_rounded
                  : Icons.remove_circle_outline_rounded,
              color: o.success ? c.bull : c.textFaint,
              size: 16),
          const SizedBox(width: 6),
          Text(
              '${o.netGainPcnt >= 0 ? '+' : ''}${o.netGainPcnt.toStringAsFixed(2)}%',
              style: t.numberMd.copyWith(color: c.pnl(o.netGainPcnt))),
        ],
      ),
      details: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // NEW: wrap RiskRewardBar in InkWell to make it tappable
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onSelectDay != null ? () => onSelectDay!(o) : null,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: RiskRewardBar(
                  rewardPcnt: o.maxProfitPcnt, riskPcnt: o.maxLossPcnt.abs()),
            ),
          ),
          const SizedBox(width: Sp.lg),
          Expanded(
            child: Column(
              children: [
                KvRow('Entry price', o.startPrice.toStringAsFixed(2),
                    icon: Icons.login_rounded),
                KvRow('Exit price', o.exitPrice.toStringAsFixed(2),
                    icon: Icons.logout_rounded),
                KvRow('Time to peak', formatMinutes(o.timeToPeakMin),
                    icon: Icons.timer_outlined),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// DAYS SCREEN
// =============================================================================
class DaysScreen extends StatefulWidget {
  final List<Outcome> outcomes;
  final Map<String, List<Candle>> niftyStore;
  final String? jumpToDate;
  final Outcome? jumpToOutcome; // NEW
  final VoidCallback onConsumedJump;
  const DaysScreen({
    super.key,
    required this.outcomes,
    required this.niftyStore,
    required this.jumpToDate,
    this.jumpToOutcome, // NEW
    required this.onConsumedJump,
  });

  @override
  State<DaysScreen> createState() => _DaysScreenState();
}

class _DaysScreenState extends State<DaysScreen> {
  int page = 0;

  List<String> get _dates {
    final s = widget.outcomes.map((o) => o.signal.date).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    return s;
  }

  @override
  void didUpdateWidget(covariant DaysScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.jumpToDate != null) {
      final idx = _dates.indexOf(widget.jumpToDate!);
      if (idx >= 0) setState(() => page = idx);
      widget.onConsumedJump();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = atlasColors(context);
    final dates = _dates;
    if (dates.isEmpty) {
      return const AtlasEmptyState(
          icon: Icons.event_busy_rounded,
          title: 'No days yet',
          message: 'Signals will appear here once they resolve.');
    }
    if (page >= dates.length) page = 0;
    final currentDate = dates[page];
    final daySignals = widget.outcomes
        .where((o) => o.signal.date == currentDate)
        .toList()
      ..sort((a, b) => a.signal.dt.compareTo(b.signal.dt));
    final dayCandles = widget.niftyStore[currentDate] ?? [];

    return Column(
      children: [
        SizedBox(
          height: 52,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: Sp.lg, vertical: Sp.sm),
            itemCount: dates.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (ctx, i) {
              final d = dates[i];
              final selected = i == page;
              return ChoiceChip(
                avatar: Icon(Icons.calendar_today_rounded,
                    size: 13, color: selected ? c.accent : c.textFaint),
                label: Text(fmtDateShort(DateTime.parse(d))),
                selected: selected,
                showCheckmark: false,
                onSelected: (_) => setState(() => page = i),
                selectedColor: c.accentSoft(),
                backgroundColor: c.surfaceAlt,
                labelStyle: TextStyle(
                  color: selected ? c.accent : c.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
                side: BorderSide(color: selected ? c.accent : c.border),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              );
            },
          ),
        ),
        Expanded(
          child: DayDetailView(
            key: ValueKey(currentDate),
            date: currentDate,
            daySignals: daySignals,
            dayCandles: dayCandles,
            initialOutcome: widget.jumpToOutcome, // NEW
          ),
        ),
      ],
    );
  }
}

/// Combined whole-day chart + tappable alert list for a single trading day.
/// NEW: supports initialOutcome to highlight a specific alert on load, and
/// draws a shaded PlotBand between the alert's entry and exit times.
class DayDetailView extends StatefulWidget {
  final String date;
  final List<Outcome> daySignals;
  final List<Candle> dayCandles;
  final Outcome? initialOutcome; // NEW
  const DayDetailView({
    super.key,
    required this.date,
    required this.daySignals,
    required this.dayCandles,
    this.initialOutcome, // NEW
  });

  @override
  State<DayDetailView> createState() => _DayDetailViewState();
}

class _DayDetailViewState extends State<DayDetailView> {
  int? selected;
  late final TrackballBehavior _trackball = TrackballBehavior(
    enable: true,
    activationMode: ActivationMode.singleTap,
    tooltipSettings: const InteractiveTooltip(enable: true),
    lineType: TrackballLineType.vertical,
  );

  @override
  void initState() {
    super.initState();
    // NEW: if an initialOutcome was provided, select it and jump the trackball
    if (widget.initialOutcome != null) {
      final idx = widget.daySignals.indexWhere((o) =>
          o.signal.timeinmill == widget.initialOutcome!.signal.timeinmill);
      if (idx >= 0) {
        selected = idx;
        WidgetsBinding.instance.addPostFrameCallback((_) => _selectAlert(idx));
      }
    }
  }

  void _selectAlert(int index) {
    setState(() => selected = index);
    if (index >= 0 && index < widget.daySignals.length) {
      final dt = widget.daySignals[index].signal.dt;
      final idx = AtlasEngine.nearestIndex(widget.dayCandles, dt);
      if (idx != null) {
        _trackball.showByIndex(idx);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = atlasColors(context);
    final t = atlasText(context);

    if (widget.daySignals.isEmpty) {
      return const AtlasEmptyState(
          icon: Icons.event_note_rounded,
          title: 'No signals this day',
          message: 'Pick another date above.');
    }
    if (widget.dayCandles.isEmpty) {
      return AtlasEmptyState(
        icon: Icons.candlestick_chart_outlined,
        title: 'No candle data',
        message: 'No candle data for ${widget.date}.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(Sp.lg, Sp.sm, Sp.lg, Sp.xxl),
      children: [
        AtlasCard(
          padding: const EdgeInsets.all(Sp.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.calendar_today_rounded, size: 14, color: c.accent),
                const SizedBox(width: 6),
                Text(fmtDateShort(DateTime.parse(widget.date)), style: t.h2),
                const Spacer(),
                Icon(Icons.notifications_active_rounded,
                    size: 13, color: c.textFaint),
                const SizedBox(width: 3),
                Text('${widget.daySignals.length} alerts', style: t.bodyMuted),
              ]),
              const SizedBox(height: Sp.sm),
              SizedBox(
                height: 220,
                child: SfCartesianChart(
                  margin: EdgeInsets.zero,
                  plotAreaBorderWidth: 0,
                  trackballBehavior: _trackball,
                  primaryXAxis: DateTimeAxis(
                    majorGridLines: const MajorGridLines(width: 0),
                    labelStyle: TextStyle(color: c.textFaint, fontSize: 9),
                    edgeLabelPlacement: EdgeLabelPlacement.shift,
                    // NEW: shade the entry→exit range when an alert is selected
                    plotBands: selected != null
                        ? [
                            PlotBand(
                              start: widget.daySignals[selected!].signal.dt,
                              end: widget.daySignals[selected!].windowEndDt,
                              color: c.accent.withOpacity(0.08),
                              borderWidth: 0,
                            ),
                          ]
                        : const [],
                  ),
                  primaryYAxis: NumericAxis(
                    majorGridLines: MajorGridLines(
                        color: c.border, dashArray: const [3, 4]),
                    labelStyle: TextStyle(color: c.textFaint, fontSize: 9),
                    numberFormat: NumberFormat.decimalPattern(),
                  ),
                  series: <CartesianSeries>[
                    CandleSeries<Candle, DateTime>(
                      dataSource: widget.dayCandles,
                      xValueMapper: (candle, _) => candle.ts,
                      highValueMapper: (candle, _) => candle.high,
                      lowValueMapper: (candle, _) => candle.low,
                      openValueMapper: (candle, _) => candle.open,
                      closeValueMapper: (candle, _) => candle.close,
                      bearColor: c.bear,
                      bullColor: c.bull,
                      enableTooltip: true,
                    ),
                  ],
                  annotations: <CartesianChartAnnotation>[
                    for (int i = 0; i < widget.daySignals.length; i++)
                      if (_annotationFor(i) != null) _annotationFor(i)!,
                  ],
                ),
              ),
            ],
          ),
        ),
        AtlasSectionHeader(
          title: 'Alerts today',
          icon: Icons.notifications_active_rounded,
          trailingText: '${widget.daySignals.length}',
        ),
        for (int i = 0; i < widget.daySignals.length; i++)
          AlertListTile(
            outcome: widget.daySignals[i],
            isSelected: selected == i,
            onTap: () => _selectAlert(i),
          ),
        const ProUpgradeButton(),
      ],
    );
  }

  CartesianChartAnnotation? _annotationFor(int i) {
    final o = widget.daySignals[i];
    final idx = AtlasEngine.nearestIndex(widget.dayCandles, o.signal.dt);
    if (idx == null || idx >= widget.dayCandles.length) return null;
    final c = atlasColors(context);
    final isSel = selected == i;
    final color = o.signal.direction == 'Bull' ? c.bull : c.bear;
    return CartesianChartAnnotation(
      widget: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: isSel ? 16 : 9,
        height: isSel ? 16 : 9,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: isSel ? 2.5 : 1.5),
          boxShadow: isSel
              ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 8)]
              : null,
        ),
      ),
      coordinateUnit: CoordinateUnit.point,
      x: widget.dayCandles[idx].ts,
      y: widget.dayCandles[idx].high,
    );
  }
}

/// One tappable row for an alert in the "Alerts today" list.
class AlertListTile extends StatelessWidget {
  final Outcome outcome;
  final bool isSelected;
  final VoidCallback onTap;
  const AlertListTile({
    super.key,
    required this.outcome,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = atlasColors(context);
    final t = atlasText(context);
    final o = outcome;
    return Container(
      margin: const EdgeInsets.only(bottom: Sp.sm),
      decoration: BoxDecoration(
        color: isSelected ? c.accentSoft() : c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isSelected ? c.accent : c.border),
        boxShadow: isSelected ? null : c.cardShadow(),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.sm),
            child: Row(
              children: [
                Icon(Icons.my_location_rounded,
                    size: 15, color: isSelected ? c.accent : c.textFaint),
                const SizedBox(width: Sp.sm),
                DirectionPill(o.signal.direction, compact: true),
                const SizedBox(width: Sp.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(o.signal.entryTimeIst, style: t.body),
                      Row(children: [
                        Icon(Icons.bolt_rounded, size: 11, color: c.textFaint),
                        const SizedBox(width: 2),
                        Text('${o.signal.probability.toStringAsFixed(0)}%',
                            style: t.caption),
                        const SizedBox(width: 8),
                        TimeAgoChip(o.signal.dt),
                      ]),
                    ],
                  ),
                ),
                Icon(
                    o.success
                        ? Icons.check_circle_rounded
                        : Icons.remove_circle_outline_rounded,
                    color: o.success ? c.bull : c.textFaint,
                    size: 16),
                const SizedBox(width: 6),
                Text(
                    '${o.netGainPcnt >= 0 ? '+' : ''}${o.netGainPcnt.toStringAsFixed(2)}%',
                    style: t.numberSm.copyWith(color: c.pnl(o.netGainPcnt))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// STRATEGY SCREEN
// =============================================================================
class StrategyScreen extends StatelessWidget {
  final List<StrategyRow> rows;
  final Map<String, List<Outcome>> detailFrames;
  const StrategyScreen(
      {super.key, required this.rows, required this.detailFrames});

  @override
  Widget build(BuildContext context) {
    final c = atlasColors(context);
    final valid = rows.where((r) => r.riskAdjScore != null).toList()
      ..sort((a, b) => b.riskAdjScore!.compareTo(a.riskAdjScore!));

    if (rows.isEmpty || valid.isEmpty) {
      return const AtlasEmptyState(
        icon: Icons.science_outlined,
        title: 'Not enough data',
        message: 'Widen the lookback window to compare exit strategies.',
      );
    }
    final best = valid.first;

    return ListView(
      padding: const EdgeInsets.fromLTRB(Sp.lg, Sp.md, Sp.lg, Sp.xxl),
      children: [
        HeroStat(
          icon: Icons.emoji_events_rounded,
          label: 'Best risk-adjusted exit',
          value: best.strategy,
          ringValue: best.winRate,
          sublabel: 'gain/risk ${best.riskAdjScore!.toStringAsFixed(2)} · '
              '${best.winRate!.toStringAsFixed(0)}% win rate · held ~${formatMinutes(best.avgHoldMin)}',
        ),
        const SizedBox(height: Sp.md),
        StatChipRow(chips: [
          StatChip(
              label: 'Avg captured',
              icon: Icons.arrow_upward_rounded,
              value:
                  '${best.avgGainPcnt! >= 0 ? '+' : ''}${best.avgGainPcnt!.toStringAsFixed(2)}%',
              valueColor: c.bull),
          StatChip(
              label: 'Avg risk',
              icon: Icons.arrow_downward_rounded,
              value: '${best.avgRiskPcnt!.toStringAsFixed(2)}%',
              valueColor: c.bear),
          StatChip(
              label: 'Signals',
              icon: Icons.query_stats_rounded,
              value: '${best.signals}'),
        ]),
        AtlasSectionHeader(
          title: 'Compare strategies',
          icon: Icons.auto_graph_rounded,
          infoTitle: 'How strategies are compared',
          infoBuilder: (ctx) => Text(
            'Fixed-time exits close the trade after a set number of minutes. '
            'The structure stop exits if price breaks the recent 3-candle range. '
            'Breakout entry only takes signals confirmed by a break of the day\'s '
            'prior high/low. Gain/Risk is average % captured divided by average % '
            'adverse move — higher is better.',
            style: atlasText(ctx).bodyMuted,
          ),
        ),
        StrategyRankChart(rows: valid),
        const SizedBox(height: Sp.sm),
        ...valid.map((r) => StrategyCard(
              row: r,
              isBest: r.strategy == best.strategy,
              detail: detailFrames[r.strategy] ?? [],
            )),
        const ProUpgradeButton(),
      ],
    );
  }
}

class StrategyRankChart extends StatelessWidget {
  final List<StrategyRow> rows;
  const StrategyRankChart({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    final c = atlasColors(context);
    final top = rows.take(6).toList();
    return AtlasCard(
      child: SizedBox(
        height: 160,
        child: SfCartesianChart(
          margin: EdgeInsets.zero,
          plotAreaBorderWidth: 0,
          primaryXAxis: CategoryAxis(
            majorGridLines: const MajorGridLines(width: 0),
            labelStyle: TextStyle(color: c.textFaint, fontSize: 8),
            labelIntersectAction: AxisLabelIntersectAction.rotate45,
          ),
          primaryYAxis: NumericAxis(
            isVisible: false,
            majorGridLines:
                MajorGridLines(color: c.border, dashArray: const [3, 4]),
          ),
          series: <CartesianSeries>[
            ColumnSeries<StrategyRow, String>(
              dataSource: top,
              xValueMapper: (r, _) => r.strategy,
              yValueMapper: (r, _) => r.riskAdjScore,
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [c.accent.withOpacity(0.55), c.accent],
              ),
              borderRadius: BorderRadius.circular(6),
            ),
          ],
        ),
      ),
    );
  }
}

class StrategyCard extends StatelessWidget {
  final StrategyRow row;
  final bool isBest;
  final List<Outcome> detail;
  const StrategyCard(
      {super.key,
      required this.row,
      required this.isBest,
      required this.detail});

  @override
  Widget build(BuildContext context) {
    final c = atlasColors(context);
    final t = atlasText(context);
    final r = row;
    return ExpandableCard(
      header: Row(
        children: [
          if (isBest)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Icon(Icons.emoji_events_rounded, size: 15, color: c.warn),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.strategy, style: t.body),
                Row(children: [
                  Icon(Icons.query_stats_rounded, size: 11, color: c.textFaint),
                  const SizedBox(width: 3),
                  Text('${r.signals} signals', style: t.caption),
                ]),
              ],
            ),
          ),
          if (r.winRate != null)
            Padding(
              padding: const EdgeInsets.only(right: Sp.sm),
              child: Text('${r.winRate!.toStringAsFixed(0)}%',
                  style: t.numberSm
                      .copyWith(color: r.winRate! >= 50 ? c.bull : c.bear)),
            ),
          Text(
              r.riskAdjScore != null ? r.riskAdjScore!.toStringAsFixed(2) : '—',
              style: t.numberMd.copyWith(color: c.accent)),
        ],
      ),
      details: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (r.avgGainPcnt != null && r.avgRiskPcnt != null) ...[
            RiskRewardBar(
                rewardPcnt: r.avgGainPcnt!, riskPcnt: r.avgRiskPcnt!.abs()),
            const SizedBox(width: Sp.lg),
          ],
          Expanded(
            child: Column(
              children: [
                KvRow(
                    'Avg gain',
                    r.avgGainPcnt != null
                        ? '${r.avgGainPcnt! >= 0 ? '+' : ''}${r.avgGainPcnt!.toStringAsFixed(2)}%'
                        : '—',
                    icon: Icons.arrow_upward_rounded,
                    valueColor: c.pnl(r.avgGainPcnt ?? 0)),
                KvRow(
                    'Avg risk',
                    r.avgRiskPcnt != null
                        ? '${r.avgRiskPcnt!.toStringAsFixed(2)}%'
                        : '—',
                    icon: Icons.arrow_downward_rounded,
                    valueColor: c.bear),
                KvRow('Avg hold',
                    r.avgHoldMin != null ? formatMinutes(r.avgHoldMin) : '—',
                    icon: Icons.timer_outlined),
                if (detail.isNotEmpty) ...[
                  const SizedBox(height: Sp.sm),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => showAtlasSheet(context,
                          title: '${r.strategy} — signals',
                          icon: Icons.receipt_long_rounded,
                          builder: (ctx) => Column(
                                children: detail
                                    .map((o) => SignalCard(outcome: o))
                                    .toList(),
                              )),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 15),
                      label: Text('View ${detail.length} signals'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
