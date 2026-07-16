import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:optionxi/Components/cust_floating_ai.dart';
import 'package:optionxi/Helpers/constants.dart';
import 'package:optionxi/VirtualTradeJournal/add_journal_page.dart';
import 'package:optionxi/VirtualTradeJournal/edit_journal_page.dart';
import 'package:optionxi/VirtualTradeJournal/journal_analytics_controller.dart';
import 'package:optionxi/VirtualTrading/VDataModel/v_tradehistory.dart';
import 'package:optionxi/Helpers/conversions.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

// ─────────────────────────────────────────────
//  Design Tokens
// ─────────────────────────────────────────────
class _T {
  static const profitSoft = Color(0xFF16A34A);
  static const profitBg = Color(0xFFF0FDF4);
  static const profitBgDark = Color(0xFF052E16);

  static const loss = Color(0xFFEF4444);
  static const lossSoft = Color(0xFFDC2626);
  static const lossBg = Color(0xFFFFF1F2);
  static const lossBgDark = Color(0xFF4C0519);

  static const amber = Color(0xFFF59E0B);
  static const amberBg = Color(0xFFFFFBEB);
  static const amberBgDark = Color(0xFF451A03);

  static const blue = Color(0xFF3B82F6);
  static const blueBg = Color(0xFFEFF6FF);
  static const blueBgDark = Color(0xFF172554);

  static const bgLight = Color(0xFFF5F7FA);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surface2Light = Color(0xFFF8FAFC);
  static const borderLight = Color(0xFFE8ECF0);
  static const textLight = Color(0xFF0F172A);
  static const text2Light = Color(0xFF64748B);
  static const text3Light = Color(0xFF94A3B8);

  static const bgDark = Color(0xFF080B12);
  static const surfaceDark = Color(0xFF111827);
  static const surface2Dark = Color(0xFF1A2030);
  static const borderDark = Color(0xFF1E2A3B);
  static const textDark = Color(0xFFF8FAFC);
  static const text2Dark = Color(0xFF94A3B8);
  static const text3Dark = Color(0xFF475569);

  static bool _dark(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark;

  static Color bg(BuildContext c) => _dark(c) ? bgDark : bgLight;
  static Color surface(BuildContext c) => _dark(c) ? surfaceDark : surfaceLight;
  static Color surface2(BuildContext c) =>
      _dark(c) ? surface2Dark : surface2Light;
  static Color border(BuildContext c) => _dark(c) ? borderDark : borderLight;
  static Color text(BuildContext c) => _dark(c) ? textDark : textLight;
  static Color text2(BuildContext c) => _dark(c) ? text2Dark : text2Light;
  static Color text3(BuildContext c) => _dark(c) ? text3Dark : text3Light;

  static Color profitBgCtx(BuildContext c) =>
      _dark(c) ? profitBgDark : profitBg;
  static Color lossBgCtx(BuildContext c) => _dark(c) ? lossBgDark : lossBg;
  static Color amberBgCtx(BuildContext c) => _dark(c) ? amberBgDark : amberBg;
  static Color blueBgCtx(BuildContext c) => _dark(c) ? blueBgDark : blueBg;
}

// ─────────────────────────────────────────────
//  Typography
// ─────────────────────────────────────────────
TextStyle _caption(BuildContext c, {double size = 11, Color? color}) =>
    GoogleFonts.inter(
        fontSize: size,
        fontWeight: FontWeight.w500,
        color: color ?? _T.text2(c),
        letterSpacing: 0.2);

TextStyle _body(BuildContext c,
        {double size = 13, FontWeight? weight, Color? color}) =>
    GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight ?? FontWeight.w400,
        color: color ?? _T.text(c));

TextStyle _heading(BuildContext c,
        {double size = 15, FontWeight? weight, Color? color}) =>
    GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight ?? FontWeight.w600,
        color: color ?? _T.text(c),
        letterSpacing: -0.2);

// ─────────────────────────────────────────────
//  Helpers
// ─────────────────────────────────────────────
String _sym(String s) {
  try {
    if (s.contains(':')) s = s.split(':')[1];
    if (s.contains('-')) s = s.split('-')[0];
    return s;
  } catch (_) {
    return s;
  }
}

// ─────────────────────────────────────────────
//  View Modes
// ─────────────────────────────────────────────
enum _ViewMode { calendar, weekly, chart, list }

// ─────────────────────────────────────────────
//  Journal Analytics Page  (self-contained)
// ─────────────────────────────────────────────
/// Navigate to this page from anywhere — it fetches its own data.
///
/// ```dart
/// Navigator.of(context).push(
///   MaterialPageRoute(builder: (_) => const JournalAnalyticsPage()),
/// );
/// // or with GetX:
/// Get.to(() => const JournalAnalyticsPage());
/// // or for another user's analytics:
/// Get.to(() => JournalAnalyticsPage(suid: entry.suid));
/// ```
class JournalAnalyticsPage extends StatefulWidget {
  /// Optional: pass a [suid] to view another user's analytics.
  /// Omit (or pass null) to use the currently signed-in user.
  final String? suid;

  const JournalAnalyticsPage({Key? key, this.suid}) : super(key: key);

  @override
  State<JournalAnalyticsPage> createState() => _JournalAnalyticsPageState();
}

class _JournalAnalyticsPageState extends State<JournalAnalyticsPage>
    with TickerProviderStateMixin {
  late final JournalAnalyticsController _ctrl;

  _ViewMode _mode = _ViewMode.calendar;
  late DateTime _focusedMonth;
  DateTime? _selectedDay;
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.put(JournalAnalyticsController(suid: widget.suid));
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
    _selectedDay = DateTime(now.year, now.month, now.day); // ← add this line
    _weekStart = _startOfWeek(now);
    // Default view is calendar → initial fetch already covers 6M which
    // includes the current month. No extra call needed on init.
  }

  @override
  void dispose() {
    Get.delete<JournalAnalyticsController>();
    super.dispose();
  }

  DateTime _startOfWeek(DateTime d) =>
      d.subtract(Duration(days: d.weekday - 1));

  Map<String, List<JournalTradeHistory>> get _byDay {
    final map = <String, List<JournalTradeHistory>>{};
    for (final t in _ctrl.allTrades) {
      final key = DateFormat('yyyy-MM-dd').format(t.exitDate);
      map.putIfAbsent(key, () => []).add(t);
    }
    return map;
  }

  List<JournalTradeHistory> _tradesForDay(DateTime d) =>
      _byDay[DateFormat('yyyy-MM-dd').format(d)] ?? [];

  double _pnlForDay(DateTime d) =>
      _tradesForDay(d).fold(0.0, (s, t) => s + t.profitLoss);

  List<JournalTradeHistory> _tradesForMonth(DateTime m) => _ctrl.allTrades
      .where((t) => t.exitDate.year == m.year && t.exitDate.month == m.month)
      .toList();

  // ── Preset range bottom-sheet ─────────────────
  void _showPresetSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 36),
        decoration: BoxDecoration(
          color: _T.surface(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 32,
            height: 3,
            decoration: BoxDecoration(
              color: _T.border(context),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text('Select Period',
              style: _heading(context, size: 16, weight: FontWeight.w700)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: JournalAnalyticsController.presets.map((p) {
              final isActive = _ctrl.rangeLabel.value == p.label;
              return GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  // Apply preset and reset view navigation to today
                  _ctrl.applyPreset(p.days);
                  setState(() {
                    _focusedMonth =
                        DateTime(DateTime.now().year, DateTime.now().month);
                    _weekStart = _startOfWeek(DateTime.now());
                  });
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? _T.blue : _T.surface2(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: isActive ? _T.blue : _T.border(context)),
                  ),
                  child: Text(p.label,
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isActive ? Colors.white : _T.text2(context))),
                ),
              );
            }).toList(),
          ),
        ]),
      ),
    );
  }

  void _onEditTrade(JournalTradeHistory trade) {
    // Navigate to EditJournalPage and refresh when returning.
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => EditJournalPage(journal: trade),
        ))
        .then((_) => _ctrl.refresh());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bg(context),
      appBar: AppBar(
        backgroundColor: _T.bg(context),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: _T.text(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Journal Analytics',
            style: _heading(context, size: 17, weight: FontWeight.w700)),
        centerTitle: false,
        actions: [
          Obx(() => _ctrl.isRefreshing.value
              ? const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _T.blue,
                    ),
                  ),
                )
              : IconButton(
                  icon: Icon(Icons.refresh_rounded, color: _T.text(context)),
                  tooltip: 'Refresh',
                  onPressed: _ctrl.refresh,
                )),
        ],
      ),
      floatingActionButton: MagicalAIButton(
        onPressed: _gotoAddJournalPage,
        label: "Add Journal",
      ),
      body: Obx(() {
        // ── First-ever load: full-screen spinner ──
        if (_ctrl.isInitialLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        // ── Error with no existing data ────────────
        if (_ctrl.hasError.value && _ctrl.trades.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.error_outline_rounded,
                  size: 36, color: _T.text3(context)),
              const SizedBox(height: 12),
              Text('Failed to load trades', style: _body(context, size: 14)),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _ctrl.refresh,
                child: const Text('Retry'),
              ),
            ]),
          );
        }

        // ── Normal view (with optional slim refresh bar) ──
        return Column(
          children: [
            // Slim progress bar shown during filter/refresh re-fetches
            // so the existing content stays visible.
            if (_ctrl.isRefreshing.value)
              LinearProgressIndicator(
                minHeight: 2,
                color: _T.blue,
                backgroundColor: _T.border(context),
              ),
            Obx(() => _PeriodBanner(
                  label: _ctrl.rangeLabel.value,
                  isLoading: _ctrl.isRefreshing.value,
                  onTap: () => _showPresetSheet(context),
                )),
            _ViewToggle(
                mode: _mode,
                onChanged: (m) {
                  setState(() => _mode = m);
                  if (m == _ViewMode.calendar) {
                    _ctrl.applyMonth(_focusedMonth);
                  } else if (m == _ViewMode.weekly) {
                    _ctrl.applyWeek(_weekStart);
                  } else {
                    // Chart & List show all loaded data; clear view window filter.
                    _ctrl.clearViewFilter();
                  }
                }),
            Expanded(child: _content()),
          ],
        );
      }),
    );
  }

  Widget _content() {
    switch (_mode) {
      case _ViewMode.calendar:
        return _CalendarView(
          focusedMonth: _focusedMonth,
          selectedDay: _selectedDay,
          // Calendar always uses the full allTrades so all months render correctly.
          trades: _ctrl.allTrades.toList(),
          onDaySelected: (d) => setState(() {
            _selectedDay = d;
            _focusedMonth = DateTime(d.year, d.month);
          }),
          tradesForDay: _tradesForDay,
          pnlForDay: _pnlForDay,
          tradesForMonth: _tradesForMonth(_focusedMonth),
          onPrevMonth: () {
            final m = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
            setState(() => _focusedMonth = m);
            // applyMonth now only expands the window if the month is outside
            // the already-loaded range — no extra fetch otherwise.
            _ctrl.applyMonth(m);
          },
          onNextMonth: () {
            final m = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
            setState(() => _focusedMonth = m);
            _ctrl.applyMonth(m);
          },
          onJumpToMonth: (m) {
            setState(() {
              _focusedMonth = m;
              _selectedDay = null;
            });
            _ctrl.applyMonth(m);
          },
          onEditTrade: _onEditTrade,
        );
      case _ViewMode.weekly:
        return _WeeklyView(
          weekStart: _weekStart,
          tradesForDay: _tradesForDay,
          pnlForDay: _pnlForDay,
          onPrevWeek: () {
            final w = _weekStart.subtract(const Duration(days: 7));
            setState(() => _weekStart = w);
            // applyWeek now only fetches when we scroll beyond loaded range.
            _ctrl.applyWeek(w);
          },
          onNextWeek: () {
            final w = _weekStart.add(const Duration(days: 7));
            setState(() => _weekStart = w);
            _ctrl.applyWeek(w);
          },
          onEditTrade: _onEditTrade,
        );
      case _ViewMode.chart:
        // Chart view receives allTrades and handles time-window chips itself.
        // It calls ctrl.ensureChartDays() when a larger window is selected.
        return Obx(() => _ChartView(
              allTrades: _ctrl.allTrades.toList(),
              loadedDays: _ctrl.loadedDays.value,
              onNeedMoreData: (days) => _ctrl.ensureChartDays(days),
              onEditTrade: _onEditTrade,
            ));
      case _ViewMode.list:
        return _ListView(
            trades: _ctrl.allTrades.toList(), onEditTrade: _onEditTrade);
    }
  }

  void _gotoAddJournalPage() async {
    // Pass the tapped calendar date (if any) so entry & exit are pre-filled.
    final raw = _selectedDay ?? DateTime.now();
    final dateToPass = DateTime(raw.year, raw.month, raw.day, 9, 0, 0);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddJournalPage(initialDate: dateToPass),
      ),
    );

    _ctrl.refresh();
  }
}

// ─────────────────────────────────────────────
//  Filter days chip (AppBar action)
// ─────────────────────────────────────────────
// ─────────────────────────────────────────────
//  Period Banner  (replaces AppBar chip)
// ─────────────────────────────────────────────
class _PeriodBanner extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onTap;
  const _PeriodBanner(
      {required this.label, required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 6, 16, 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _T.surface(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _T.border(context)),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _T.blue.withOpacity(0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                const Icon(Icons.date_range_rounded, size: 15, color: _T.blue),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Viewing period',
                style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: _T.text2(context),
                    letterSpacing: 0.2)),
            const SizedBox(height: 1),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _T.text(context))),
          ]),
          const Spacer(),
          if (isLoading)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: _T.blue),
            )
          else ...[
            Text('Change',
                style: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.w600, color: _T.blue)),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded,
                size: 16, color: _T.blue),
          ],
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  View Toggle
// ─────────────────────────────────────────────
class _ViewToggle extends StatelessWidget {
  final _ViewMode mode;
  final ValueChanged<_ViewMode> onChanged;
  const _ViewToggle({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        icon: Icons.calendar_month_rounded,
        label: 'Month',
        m: _ViewMode.calendar
      ),
      (icon: Icons.view_week_rounded, label: 'Week', m: _ViewMode.weekly),
      (icon: Icons.show_chart_rounded, label: 'Chart', m: _ViewMode.chart),
      (icon: Icons.list_alt_rounded, label: 'List', m: _ViewMode.list),
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _T.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _T.border(context), width: 1),
      ),
      child: Row(
        children: items
            .map((item) => Expanded(
                  child: GestureDetector(
                    onTap: () => onChanged(item.m),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: mode == item.m ? _T.blue : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(item.icon,
                              size: 16,
                              color: mode == item.m
                                  ? Colors.white
                                  : _T.text2(context)),
                          const SizedBox(height: 3),
                          Text(item.label,
                              style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: mode == item.m
                                      ? Colors.white
                                      : _T.text2(context))),
                        ],
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  CALENDAR VIEW
// ─────────────────────────────────────────────
class _CalendarView extends StatelessWidget {
  final DateTime focusedMonth;
  final DateTime? selectedDay;
  final List<JournalTradeHistory> trades;
  final ValueChanged<DateTime> onDaySelected;
  final List<JournalTradeHistory> Function(DateTime) tradesForDay;
  final double Function(DateTime) pnlForDay;
  final List<JournalTradeHistory> tradesForMonth;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime>? onJumpToMonth;
  final void Function(JournalTradeHistory)? onEditTrade;

  const _CalendarView({
    required this.focusedMonth,
    required this.selectedDay,
    required this.trades,
    required this.onDaySelected,
    required this.tradesForDay,
    required this.pnlForDay,
    required this.tradesForMonth,
    required this.onPrevMonth,
    required this.onNextMonth,
    this.onJumpToMonth,
    this.onEditTrade,
  });

  @override
  Widget build(BuildContext context) {
    final monthPnl = tradesForMonth.fold(0.0, (s, t) => s + t.profitLoss);
    final monthWins = tradesForMonth.where((t) => t.profitLoss > 0).length;
    final monthLosses = tradesForMonth.where((t) => t.profitLoss < 0).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SixMonthHeatmap(
            trades: trades,
            focusedMonth: focusedMonth,
            pnlForDay: pnlForDay,
            tradesForDay: tradesForDay,
            onDaySelected: onDaySelected,
            onJumpToMonth: onJumpToMonth,
          ),
          const SizedBox(height: 14),
          _MonthHeader(
            month: focusedMonth,
            pnl: monthPnl,
            wins: monthWins,
            losses: monthLosses,
            onPrev: onPrevMonth,
            onNext: onNextMonth,
          ),
          const SizedBox(height: 14),
          _CalendarGrid(
            focusedMonth: focusedMonth,
            selectedDay: selectedDay,
            tradesForDay: tradesForDay,
            pnlForDay: pnlForDay,
            onDaySelected: onDaySelected,
          ),
          if (selectedDay != null) ...[
            const SizedBox(height: 20),
            _SelectedDayPanel(
              day: selectedDay!,
              trades: tradesForDay(selectedDay!),
              onEditTrade: onEditTrade,
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  6-MONTH HEATMAP
// ─────────────────────────────────────────────
class _SixMonthHeatmap extends StatelessWidget {
  final List<JournalTradeHistory> trades;
  final DateTime focusedMonth;
  final double Function(DateTime) pnlForDay;
  final List<JournalTradeHistory> Function(DateTime) tradesForDay;
  final ValueChanged<DateTime> onDaySelected;
  final ValueChanged<DateTime>? onJumpToMonth;

  const _SixMonthHeatmap({
    required this.trades,
    required this.focusedMonth,
    required this.pnlForDay,
    required this.tradesForDay,
    required this.onDaySelected,
    this.onJumpToMonth,
  });

  List<DateTime> _buildDays() {
    final today = DateTime.now();
    // Span from earliest trade date (or 6 months ago, whichever is earlier).
    DateTime earliest = DateTime(today.year, today.month - 5, 1);
    if (trades.isNotEmpty) {
      final minDate =
          trades.map((t) => t.exitDate).reduce((a, b) => a.isBefore(b) ? a : b);
      final monthStart = DateTime(minDate.year, minDate.month, 1);
      if (monthStart.isBefore(earliest)) earliest = monthStart;
    }
    final end = DateTime(today.year, today.month + 1, 0);
    final days = <DateTime>[];
    for (var d = earliest;
        !d.isAfter(end);
        d = d.add(const Duration(days: 1))) {
      days.add(d);
    }
    return days;
  }

  /// Returns all distinct months covered by [_buildDays].
  List<DateTime> _buildMonths(List<DateTime> days) {
    final seen = <String>{};
    final months = <DateTime>[];
    for (final d in days) {
      final key = '${d.year}-${d.month}';
      if (seen.add(key)) months.add(DateTime(d.year, d.month));
    }
    return months;
  }

  double _maxAbsPnl(List<DateTime> days) {
    double mx = 0;
    for (final d in days) {
      final v = pnlForDay(d).abs();
      if (v > mx) mx = v;
    }
    return mx;
  }

  Color _cellColor(double pnl, double maxPnl, bool isDark) {
    if (pnl == 0) {
      return isDark ? const Color(0xFF1E2A3B) : const Color(0xFFEEF2F7);
    }
    final intensity = maxPnl > 0 ? (pnl.abs() / maxPnl).clamp(0.15, 1.0) : 0.15;
    return pnl > 0
        ? Color.lerp(
            const Color(0xFF86EFAC), const Color(0xFF16A34A), intensity)!
        : Color.lerp(
            const Color(0xFFFCA5A5), const Color(0xFFDC2626), intensity)!;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _T._dark(context);
    final days = _buildDays();
    final maxPnl = _maxAbsPnl(days);

    final firstDay = days.first;
    final leadingPad = firstDay.weekday - 1;
    final padded = [
      ...List<DateTime?>.filled(leadingPad, null),
      ...days.map<DateTime?>((d) => d),
    ];
    final colCount = (padded.length / 7).ceil();

    final monthLabels = <int, String>{};
    for (int col = 0; col < colCount; col++) {
      for (int row = 0; row < 7; row++) {
        final idx = col * 7 + row;
        if (idx < padded.length && padded[idx] != null) {
          final d = padded[idx]!;
          if (d.day <= 7) monthLabels[col] = DateFormat('MMM').format(d);
          break;
        }
      }
    }

    const cellSize = 11.0;
    const cellGap = 3.0;
    const rowCount = 7;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _T.surface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _T.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('6-Month Activity',
                  style: _heading(context, size: 13, weight: FontWeight.w700)),
              const Spacer(),
              _HeatLegend(
                  color: isDark
                      ? const Color(0xFF1E2A3B)
                      : const Color(0xFFEEF2F7),
                  label: ''),
              const SizedBox(width: 2),
              _HeatLegend(color: const Color(0xFF86EFAC), label: ''),
              const SizedBox(width: 2),
              _HeatLegend(color: const Color(0xFF16A34A), label: 'P'),
              const SizedBox(width: 6),
              _HeatLegend(color: const Color(0xFFFCA5A5), label: ''),
              const SizedBox(width: 2),
              _HeatLegend(color: const Color(0xFFDC2626), label: 'L'),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 14,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: SizedBox(
                width: colCount * (cellSize + cellGap),
                child: Stack(
                  children: monthLabels.entries
                      .map((e) => Positioned(
                            left: e.key * (cellSize + cellGap),
                            child: Text(e.value,
                                style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: _T.text3(context),
                                    letterSpacing: 0.3)),
                          ))
                      .toList(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(
                  colCount,
                  (col) => Padding(
                        padding: EdgeInsets.only(
                            right: col < colCount - 1 ? cellGap : 0),
                        child: Column(
                          children: List.generate(rowCount, (row) {
                            final idx = col * rowCount + row;
                            if (idx >= padded.length || padded[idx] == null) {
                              return SizedBox(
                                  width: cellSize,
                                  height: cellSize +
                                      (row < rowCount - 1 ? cellGap : 0));
                            }
                            final day = padded[idx]!;
                            final pnl = pnlForDay(day);
                            final color = _cellColor(pnl, maxPnl, isDark);
                            final isToday = DateFormat('yyyy-MM-dd')
                                    .format(day) ==
                                DateFormat('yyyy-MM-dd').format(DateTime.now());
                            final isFocused = day.year == focusedMonth.year &&
                                day.month == focusedMonth.month;

                            return GestureDetector(
                              onTap: () => onDaySelected(day),
                              child: Container(
                                width: cellSize,
                                height: cellSize,
                                margin: EdgeInsets.only(
                                    bottom: row < rowCount - 1 ? cellGap : 0),
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(2.5),
                                  border: isToday
                                      ? Border.all(color: _T.blue, width: 1.5)
                                      : isFocused && pnl == 0
                                          ? Border.all(
                                              color: _T
                                                  .border(context)
                                                  .withOpacity(0.8))
                                          : null,
                                ),
                              ),
                            );
                          }),
                        ),
                      )),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 28,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _buildMonths(days).length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, i) {
                final month = _buildMonths(days)[i];
                final mTrades = trades
                    .where((t) =>
                        t.exitDate.year == month.year &&
                        t.exitDate.month == month.month)
                    .toList();
                final mPnl = mTrades.fold(0.0, (s, t) => s + t.profitLoss);
                final isPos = mPnl >= 0;
                final isFocus = month.year == focusedMonth.year &&
                    month.month == focusedMonth.month;

                return GestureDetector(
                  onTap: () => onJumpToMonth?.call(month),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: isFocus
                          ? _T.blue
                          : isPos && mTrades.isNotEmpty
                              ? _T.profitBgCtx(context)
                              : !isPos && mTrades.isNotEmpty
                                  ? _T.lossBgCtx(context)
                                  : _T.surface2(context),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                          color: isFocus ? _T.blue : _T.border(context),
                          width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(DateFormat('MMM yy').format(month),
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isFocus
                                    ? Colors.white
                                    : mTrades.isEmpty
                                        ? _T.text3(context)
                                        : isPos
                                            ? _T.profitSoft
                                            : _T.lossSoft)),
                        if (mTrades.isNotEmpty) ...[
                          const SizedBox(width: 5),
                          Text(
                            '${isPos ? '+' : '-'}₹${convertToKMB(mPnl.abs().toStringAsFixed(0))}',
                            style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isFocus
                                    ? Colors.white.withOpacity(0.85)
                                    : isPos
                                        ? _T.profitSoft
                                        : _T.lossSoft),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HeatLegend extends StatelessWidget {
  final Color color;
  final String label;
  const _HeatLegend({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2))),
        if (label.isNotEmpty) ...[
          const SizedBox(width: 3),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: _T.text3(context))),
        ],
      ]);
}

// ─────────────────────────────────────────────
//  Month Header
// ─────────────────────────────────────────────
class _MonthHeader extends StatelessWidget {
  final DateTime month;
  final double pnl;
  final int wins, losses;
  final VoidCallback onPrev, onNext;

  const _MonthHeader({
    required this.month,
    required this.pnl,
    required this.wins,
    required this.losses,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final isPos = pnl >= 0;
    final color = isPos ? _T.profitSoft : _T.lossSoft;
    final total = wins + losses;
    final wr = total > 0 ? (wins / total * 100) : 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _T.surface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _T.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _NavArrow(icon: Icons.chevron_left_rounded, onTap: onPrev),
              const SizedBox(width: 10),
              Expanded(
                child: Text(DateFormat('MMMM yyyy').format(month),
                    style:
                        _heading(context, size: 17, weight: FontWeight.w800)),
              ),
              _NavArrow(icon: Icons.chevron_right_rounded, onTap: onNext),
            ],
          ),
          const SizedBox(height: 14),
          Row(children: [
            _MiniStat(
              label: 'Month P&L',
              value:
                  '${isPos ? '+' : ''}₹${convertToKMB(pnl.toStringAsFixed(2))}',
              color: color,
              bg: isPos ? _T.profitBgCtx(context) : _T.lossBgCtx(context),
            ),
            const SizedBox(width: 8),
            _MiniStat(
                label: 'Trades',
                value: '$total',
                color: _T.blue,
                bg: _T.blueBgCtx(context)),
            const SizedBox(width: 8),
            _MiniStat(
              label: 'Win Rate',
              value: '${wr.toStringAsFixed(0)}%',
              color: _T.profitSoft,
              bg: _T.profitBgCtx(context),
            ),
          ]),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final Color color, bg;
  const _MiniStat(
      {required this.label,
      required this.value,
      required this.color,
      required this.bg});
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          decoration:
              BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: _caption(context, size: 10, color: color)),
            const SizedBox(height: 3),
            Text(value,
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w800, color: color)),
          ]),
        ),
      );
}

// ─────────────────────────────────────────────
//  Calendar Grid
// ─────────────────────────────────────────────
class _CalendarGrid extends StatelessWidget {
  final DateTime focusedMonth;
  final DateTime? selectedDay;
  final List<JournalTradeHistory> Function(DateTime) tradesForDay;
  final double Function(DateTime) pnlForDay;
  final ValueChanged<DateTime> onDaySelected;

  const _CalendarGrid({
    required this.focusedMonth,
    required this.selectedDay,
    required this.tradesForDay,
    required this.pnlForDay,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final lastDay = DateTime(focusedMonth.year, focusedMonth.month + 1, 0);
    final startOffset = firstDay.weekday - 1;
    final rows = ((startOffset + lastDay.day) / 7).ceil();

    return Container(
      decoration: BoxDecoration(
        color: _T.surface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _T.border(context)),
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 14, 8, 8),
          child: Row(
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                .map((d) => Expanded(
                    child: Center(
                        child: Text(d,
                            style: _caption(context,
                                size: 11,
                                color: d == 'S'
                                    ? _T.loss.withOpacity(0.5)
                                    : _T.text2(context))))))
                .toList(),
          ),
        ),
        Divider(height: 1, color: _T.border(context)),
        ...List.generate(
            rows,
            (row) => Column(children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      children: List.generate(7, (col) {
                        final dayNum = row * 7 + col - startOffset + 1;
                        if (dayNum < 1 || dayNum > lastDay.day) {
                          return const Expanded(child: SizedBox());
                        }
                        final day = DateTime(
                            focusedMonth.year, focusedMonth.month, dayNum);
                        return Expanded(
                            child: _DayCell(
                          day: day,
                          isSelected: selectedDay != null &&
                              DateFormat('yyyy-MM-dd').format(selectedDay!) ==
                                  DateFormat('yyyy-MM-dd').format(day),
                          isToday:
                              DateFormat('yyyy-MM-dd').format(DateTime.now()) ==
                                  DateFormat('yyyy-MM-dd').format(day),
                          trades: tradesForDay(day),
                          pnl: pnlForDay(day),
                          onTap: () => onDaySelected(day),
                        ));
                      }),
                    ),
                  ),
                  if (row < rows - 1)
                    Divider(
                        height: 1, color: _T.border(context).withOpacity(0.4)),
                ])),
        const SizedBox(height: 8),
      ]),
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime day;
  final bool isSelected, isToday;
  final List<JournalTradeHistory> trades;
  final double pnl;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.isSelected,
    required this.isToday,
    required this.trades,
    required this.pnl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasTrades = trades.isNotEmpty;
    final isPos = pnl >= 0;
    Color? cellBg;
    Color? dotColor;

    if (isSelected) {
      cellBg = _T.blue;
    } else if (hasTrades) {
      cellBg = isPos
          ? _T.profitSoft.withOpacity(0.08)
          : _T.lossSoft.withOpacity(0.08);
      dotColor = isPos ? _T.profitSoft : _T.lossSoft;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(2),
        height: 52,
        decoration: BoxDecoration(
          color: cellBg,
          borderRadius: BorderRadius.circular(10),
          border: isToday && !isSelected
              ? Border.all(color: _T.blue, width: 1.5)
              : null,
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('${day.day}',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight:
                    isSelected || isToday ? FontWeight.w800 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : isToday
                        ? _T.blue
                        : _T.text(context),
              )),
          if (hasTrades) ...[
            const SizedBox(height: 3),
            isSelected
                ? Text('${trades.length}',
                    style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white))
                : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                            color: dotColor, shape: BoxShape.circle)),
                    if (trades.length > 1) ...[
                      const SizedBox(width: 2),
                      Text('+${trades.length - 1}',
                          style: GoogleFonts.inter(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: dotColor)),
                    ],
                  ]),
          ],
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Selected Day Panel
// ─────────────────────────────────────────────
class _SelectedDayPanel extends StatelessWidget {
  final DateTime day;
  final List<JournalTradeHistory> trades;
  final void Function(JournalTradeHistory)? onEditTrade;
  const _SelectedDayPanel(
      {required this.day, required this.trades, this.onEditTrade});

  @override
  Widget build(BuildContext context) {
    if (trades.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _T.surface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _T.border(context)),
        ),
        child: Center(
            child: Column(children: [
          Icon(Icons.event_available_rounded,
              size: 28, color: _T.text3(context)),
          const SizedBox(height: 8),
          Text('No trades on ${DateFormat('d MMM').format(day)}',
              style: _caption(context, size: 13)),
        ])),
      );
    }

    final dayPnl = trades.fold(0.0, (s, t) => s + t.profitLoss);
    final isPos = dayPnl >= 0;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
            child: Text(DateFormat('EEEE, d MMMM').format(day),
                style: _heading(context, size: 14, weight: FontWeight.w700))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: isPos ? _T.profitBgCtx(context) : _T.lossBgCtx(context),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${isPos ? '+' : ''}₹${convertToKMB(dayPnl.toStringAsFixed(2))}',
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isPos ? _T.profitSoft : _T.lossSoft),
          ),
        ),
      ]),
      const SizedBox(height: 10),
      ...trades
          .map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _TradeCard(trade: t, onEdit: onEditTrade),
              ))
          .toList(),
    ]);
  }
}

// ─────────────────────────────────────────────
//  Rich Trade Card
// ─────────────────────────────────────────────
class _TradeCard extends StatelessWidget {
  final JournalTradeHistory trade;
  final void Function(JournalTradeHistory)? onEdit;
  const _TradeCard({required this.trade, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final isPos = trade.profitLoss >= 0;
    final color = isPos ? _T.profitSoft : _T.lossSoft;
    final invested = trade.entryPrice * trade.quantity;
    final pct = invested > 0 ? (trade.profitLoss / invested * 100) : 0.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _T.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _T.border(context)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(_T._dark(context) ? 0.15 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Row 1: icon + name + edit button + P&L ──
        Row(children: [
          // Container(
          //   width: 38,
          //   height: 38,
          //   decoration: BoxDecoration(
          //     color: isPos ? _T.profitBgCtx(context) : _T.lossBgCtx(context),
          //     borderRadius: BorderRadius.circular(10),
          //   ),
          //   child: Icon(
          //     isPos ? Icons.trending_up_rounded : Icons.trending_down_rounded,
          //     size: 18,
          //     color: color,
          //   ),
          // ),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.2), width: 1.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: '${Constants.OptionXiS3Loc}${_sym(trade.symbol)}.png',
                fit: BoxFit.cover,
                placeholder: (_, __) => _LogoFallback(),
                errorWidget: (_, __, ___) => _LogoFallback(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(_sym(trade.symbol),
                    style: _body(context, size: 14, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Row(children: [
                  _Badge(
                    label: trade.isShortSell ? 'SHORT' : 'LONG',
                    color: trade.isShortSell ? _T.amber : _T.profitSoft,
                    bg: trade.isShortSell
                        ? _T.amberBgCtx(context)
                        : _T.profitBgCtx(context),
                  ),
                  const SizedBox(width: 5),
                  if (trade.segment.isNotEmpty && trade.segment != 'N/A')
                    _Badge(
                        label: trade.segment,
                        color: _T.blue,
                        bg: _T.blueBgCtx(context)),
                ]),
              ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            // ── Edit button ──
            if (onEdit != null)
              GestureDetector(
                onTap: () => onEdit!(trade),
                child: Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: _T.blueBgCtx(context),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: _T.blue.withOpacity(0.2)),
                  ),
                  child: Icon(Icons.edit_rounded, size: 13, color: _T.blue),
                ),
              ),
            Text(
              '${isPos ? '+' : ''}₹${convertToKMB(trade.profitLoss.abs().toStringAsFixed(2))}',
              style: GoogleFonts.inter(
                  fontSize: 15, fontWeight: FontWeight.w800, color: color),
            ),
            const SizedBox(height: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(5)),
              child: Text('${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(2)}%',
                  style: GoogleFonts.inter(
                      fontSize: 10, fontWeight: FontWeight.w700, color: color)),
            ),
          ]),
        ]),
        const SizedBox(height: 10),

        // ── Row 2: entry → exit price strip ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: _T.surface2(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _T.border(context)),
          ),
          child: Row(children: [
            _PriceLabel(
                label: 'Entry',
                value: '₹${trade.entryPrice.toStringAsFixed(2)}',
                color: _T.profitSoft),
            Icon(Icons.arrow_forward_rounded,
                size: 12, color: _T.text3(context)),
            _PriceLabel(
                label: 'Exit',
                value: '₹${trade.exitPrice.toStringAsFixed(2)}',
                color: color),
            const Spacer(),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${trade.quantity} qty', style: _caption(context, size: 10)),
              const SizedBox(height: 1),
              Text(trade.timeframe.isNotEmpty ? trade.timeframe : '–',
                  style: _caption(context, size: 10, color: _T.blue)),
            ]),
          ]),
        ),
        const SizedBox(height: 8),

        // ── Row 3: dates + timeago ──
        Row(children: [
          Icon(Icons.login_rounded, size: 11, color: _T.text3(context)),
          const SizedBox(width: 4),
          Text(DateFormat('d MMM yy, HH:mm').format(trade.entryDate),
              style: _caption(context, size: 10)),
          const SizedBox(width: 10),
          Icon(Icons.logout_rounded, size: 11, color: _T.text3(context)),
          const SizedBox(width: 4),
          Text(DateFormat('d MMM yy, HH:mm').format(trade.exitDate),
              style: _caption(context, size: 10)),
          const Spacer(),
          Icon(Icons.access_time_rounded, size: 11, color: _T.text3(context)),
          const SizedBox(width: 3),
          Text(timeago.format(trade.exitDate),
              style: _caption(context, size: 10)),
        ]),

        // ── Optional: SL/Target if set ──
        if ((trade.stopLossPrice != null && trade.stopLossPrice! > 0) ||
            (trade.targetPrice != null && trade.targetPrice! > 0)) ...[
          const SizedBox(height: 8),
          Row(children: [
            if (trade.stopLossPrice != null && trade.stopLossPrice! > 0) ...[
              Icon(Icons.shield_outlined, size: 11, color: _T.loss),
              const SizedBox(width: 3),
              Text('SL ₹${trade.stopLossPrice!.toStringAsFixed(2)}',
                  style: _caption(context, size: 10, color: _T.loss)),
              const SizedBox(width: 12),
            ],
            if (trade.targetPrice != null && trade.targetPrice! > 0) ...[
              Icon(Icons.flag_outlined, size: 11, color: _T.profitSoft),
              const SizedBox(width: 3),
              Text('TGT ₹${trade.targetPrice!.toStringAsFixed(2)}',
                  style: _caption(context, size: 10, color: _T.profitSoft)),
            ],
          ]),
        ],

        // ── Reason / analysis ──
        if (trade.reason != null && trade.reason!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _T.blueBgCtx(context),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: _T.blue.withOpacity(0.12)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.psychology_outlined, size: 13, color: _T.blue),
              const SizedBox(width: 6),
              Expanded(
                  child: Text(trade.reason!,
                      style: _body(context, size: 12).copyWith(height: 1.5))),
            ]),
          ),
        ],
      ]),
    );
  }
}

class _LogoFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        color: _T.surface2(context),
        child: Icon(Icons.candlestick_chart_rounded,
            size: 18, color: _T.text3(context)),
      );
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color, bg;
  const _Badge({required this.label, required this.color, required this.bg});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(5)),
        child: Text(label,
            style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.3)),
      );
}

class _PriceLabel extends StatelessWidget {
  final String label, value;
  final Color color;
  const _PriceLabel(
      {required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: _caption(context, size: 9, color: color)),
          const SizedBox(height: 1),
          Text(value, style: _body(context, size: 12, weight: FontWeight.w700)),
        ]),
      );
}

// ─────────────────────────────────────────────
//  WEEKLY VIEW
// ─────────────────────────────────────────────
class _WeeklyView extends StatelessWidget {
  final DateTime weekStart;
  final List<JournalTradeHistory> Function(DateTime) tradesForDay;
  final double Function(DateTime) pnlForDay;
  final VoidCallback onPrevWeek, onNextWeek;
  final void Function(JournalTradeHistory)? onEditTrade;

  const _WeeklyView({
    required this.weekStart,
    required this.tradesForDay,
    required this.pnlForDay,
    required this.onPrevWeek,
    required this.onNextWeek,
    this.onEditTrade,
  });

  @override
  Widget build(BuildContext context) {
    final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));
    final weekTrades = days.expand((d) => tradesForDay(d)).toList();
    final weekPnl = weekTrades.fold(0.0, (s, t) => s + t.profitLoss);
    final isPos = weekPnl >= 0;
    final maxPnl =
        days.map((d) => pnlForDay(d).abs()).fold(0.0, (a, b) => a > b ? a : b);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _T.surface(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _T.border(context)),
          ),
          child: Column(children: [
            Row(children: [
              _NavArrow(icon: Icons.chevron_left_rounded, onTap: onPrevWeek),
              const SizedBox(width: 10),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(
                      '${DateFormat('d MMM').format(weekStart)} – ${DateFormat('d MMM yyyy').format(weekStart.add(const Duration(days: 6)))}',
                      style:
                          _heading(context, size: 15, weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                        '${weekTrades.length} trade${weekTrades.length == 1 ? '' : 's'} this week',
                        style: _caption(context)),
                  ])),
              _NavArrow(icon: Icons.chevron_right_rounded, onTap: onNextWeek),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                  child: _WeekStat(
                      label: 'Week P&L',
                      value:
                          '${isPos ? '+' : ''}₹${convertToKMB(weekPnl.toStringAsFixed(2))}',
                      color: isPos ? _T.profitSoft : _T.lossSoft,
                      bg: isPos
                          ? _T.profitBgCtx(context)
                          : _T.lossBgCtx(context))),
              const SizedBox(width: 8),
              Expanded(
                  child: _WeekStat(
                      label: 'Wins',
                      value:
                          '${weekTrades.where((t) => t.profitLoss > 0).length}',
                      color: _T.profitSoft,
                      bg: _T.profitBgCtx(context))),
              const SizedBox(width: 8),
              Expanded(
                  child: _WeekStat(
                      label: 'Losses',
                      value:
                          '${weekTrades.where((t) => t.profitLoss < 0).length}',
                      color: _T.lossSoft,
                      bg: _T.lossBgCtx(context))),
            ]),
          ]),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _T.surface(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _T.border(context)),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Daily P&L',
                style: _heading(context, size: 13, weight: FontWeight.w600)),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: days
                    .map((d) => Expanded(
                            child: _DayBar(
                          day: d,
                          pnl: pnlForDay(d),
                          maxPnl: maxPnl,
                          trades: tradesForDay(d),
                        )))
                    .toList(),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        ...days.map((d) {
          final dayTrades = tradesForDay(d);
          if (dayTrades.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _WeekDaySection(
                day: d, trades: dayTrades, onEditTrade: onEditTrade),
          );
        }).toList(),
      ]),
    );
  }
}

class _WeekStat extends StatelessWidget {
  final String label, value;
  final Color color, bg;
  const _WeekStat(
      {required this.label,
      required this.value,
      required this.color,
      required this.bg});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: _caption(context, size: 10, color: color)),
          const SizedBox(height: 3),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w800, color: color)),
        ]),
      );
}

class _DayBar extends StatelessWidget {
  final DateTime day;
  final double pnl, maxPnl;
  final List<JournalTradeHistory> trades;

  const _DayBar(
      {required this.day,
      required this.pnl,
      required this.maxPnl,
      required this.trades});

  @override
  Widget build(BuildContext context) {
    final isPos = pnl >= 0;
    final color = trades.isEmpty
        ? _T.border(context)
        : isPos
            ? _T.profitSoft
            : _T.lossSoft;
    final fraction = maxPnl > 0 ? (pnl.abs() / maxPnl) : 0.0;
    final isToday = DateFormat('yyyy-MM-dd').format(day) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Column(mainAxisAlignment: MainAxisAlignment.end, children: [
      if (trades.isNotEmpty)
        Text(
          '${isPos ? '+' : '-'}₹${convertToKMB(pnl.abs().toStringAsFixed(0))}',
          style: GoogleFonts.inter(
              fontSize: 8, fontWeight: FontWeight.w700, color: color),
          textAlign: TextAlign.center,
        )
      else
        const SizedBox(height: 12),
      const SizedBox(height: 3),
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        height: trades.isEmpty ? 3 : (55 * fraction).clamp(4.0, 55.0),
        decoration:
            BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
      ),
      const SizedBox(height: 5),
      Text(
        DateFormat('E').format(day).substring(0, 2),
        style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
            color: isToday ? _T.blue : _T.text2(context)),
      ),
      Text(
        '${day.day}',
        style: GoogleFonts.inter(
            fontSize: 9, fontWeight: FontWeight.w500, color: _T.text3(context)),
      ),
    ]);
  }
}

class _WeekDaySection extends StatelessWidget {
  final DateTime day;
  final List<JournalTradeHistory> trades;
  final void Function(JournalTradeHistory)? onEditTrade;
  const _WeekDaySection(
      {required this.day, required this.trades, this.onEditTrade});

  @override
  Widget build(BuildContext context) {
    final pnl = trades.fold(0.0, (s, t) => s + t.profitLoss);
    final isPos = pnl >= 0;

    return Container(
      decoration: BoxDecoration(
        color: _T.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _T.border(context)),
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          child: Row(children: [
            Expanded(
                child: Text(DateFormat('EEEE, d MMM').format(day),
                    style: _body(context, size: 13, weight: FontWeight.w700))),
            Text(
              '${isPos ? '+' : ''}₹${convertToKMB(pnl.toStringAsFixed(2))}',
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isPos ? _T.profitSoft : _T.lossSoft),
            ),
          ]),
        ),
        Divider(height: 1, color: _T.border(context)),
        ...trades
            .map((t) => Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                  child: _TradeCard(trade: t, onEdit: onEditTrade),
                ))
            .toList(),
        const SizedBox(height: 10),
      ]),
    );
  }
}

// ─────────────────────────────────────────────
//  CHART VIEW
// ─────────────────────────────────────────────
class _ChartView extends StatefulWidget {
  final List<JournalTradeHistory> allTrades;

  /// How many days have already been fetched by the controller.
  final int loadedDays;

  /// Called when the selected window exceeds [loadedDays].
  final void Function(int days) onNeedMoreData;
  final void Function(JournalTradeHistory)? onEditTrade;
  const _ChartView({
    required this.allTrades,
    required this.loadedDays,
    required this.onNeedMoreData,
    this.onEditTrade,
  });

  @override
  State<_ChartView> createState() => _ChartViewState();
}

class _ChartViewState extends State<_ChartView> {
  // Default to the controller's initial window (6M = 180 days).
  int _days = 180;

  static const _opts = [
    (label: '7D', days: 7),
    (label: '1M', days: 30),
    (label: '3M', days: 90),
    (label: '6M', days: 180),
    (label: '1Y', days: 365),
    (label: 'All', days: 3650),
  ];

  /// Whether the controller still needs to fetch data for the selected window.
  bool get _awaitingData => _days > widget.loadedDays;

  List<JournalTradeHistory> get _filtered {
    if (_days >= 3650) return widget.allTrades;
    final cutoff = DateTime.now().subtract(Duration(days: _days));
    return widget.allTrades.where((t) => t.exitDate.isAfter(cutoff)).toList();
  }

  void _selectDays(int days) {
    setState(() => _days = days);
    if (days > widget.loadedDays) {
      // Ask the controller to expand its fetch window.
      widget.onNeedMoreData(days);
    }
  }

  @override
  Widget build(BuildContext context) {
    final trades = _filtered;
    final sorted = [...trades]
      ..sort((a, b) => a.exitDate.compareTo(b.exitDate));

    double cum = 0;
    final points = sorted.map((t) {
      cum += t.profitLoss;
      return _ChartPoint(date: t.exitDate, cumPnl: cum, pnl: t.profitLoss);
    }).toList();

    final totalPnl = trades.fold(0.0, (s, t) => s + t.profitLoss);
    final wins = trades.where((t) => t.profitLoss > 0).length;
    final losses = trades.where((t) => t.profitLoss < 0).length;
    final wr = trades.isNotEmpty ? (wins / trades.length * 100) : 0.0;
    final avgWin = wins > 0
        ? trades
                .where((t) => t.profitLoss > 0)
                .fold(0.0, (s, t) => s + t.profitLoss) /
            wins
        : 0.0;
    final avgLoss = losses > 0
        ? trades
                .where((t) => t.profitLoss < 0)
                .fold(0.0, (s, t) => s + t.profitLoss.abs()) /
            losses
        : 0.0;
    final bestDay = trades.isEmpty
        ? null
        : trades.reduce((a, b) => a.profitLoss > b.profitLoss ? a : b);
    final worstDay = trades.isEmpty
        ? null
        : trades.reduce((a, b) => a.profitLoss < b.profitLoss ? a : b);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _T.surface(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _T.border(context)),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Cumulative P&L', style: _caption(context, size: 11)),
                const SizedBox(height: 4),
                Text(
                  '${totalPnl >= 0 ? '+' : ''}₹${convertToKMB(totalPnl.toStringAsFixed(2))}',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: totalPnl >= 0 ? _T.profitSoft : _T.lossSoft,
                  ),
                ),
              ]),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _T.surface2(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _T.border(context)),
                ),
                child: Text(
                  '${trades.length} trade${trades.length == 1 ? '' : 's'}',
                  style: _caption(context, size: 11),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Row(
                children: _opts.map((o) {
              final active = _days == o.days;
              final needsFetch = active && _awaitingData;
              return Expanded(
                child: GestureDetector(
                  onTap: () => _selectDays(o.days),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    margin: const EdgeInsets.only(right: 5),
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: active ? _T.blue : _T.surface2(context),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: active ? _T.blue : _T.border(context),
                          width: 1),
                    ),
                    child: needsFetch
                        ? const Center(
                            child: SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.8,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : Text(o.label,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight:
                                    active ? FontWeight.w700 : FontWeight.w500,
                                color:
                                    active ? Colors.white : _T.text2(context))),
                  ),
                ),
              );
            }).toList()),
            const SizedBox(height: 14),
            points.isEmpty
                ? SizedBox(
                    height: 100,
                    child: Center(
                        child: _awaitingData
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.5, color: _T.blue),
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Fetching more data…',
                                      style: _caption(context)),
                                ],
                              )
                            : Text('No trades in this period',
                                style: _caption(context))))
                : _Sparkline(points: points),
            if (points.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(DateFormat('d MMM yy').format(points.first.date),
                    style: _caption(context, size: 10)),
                Text(DateFormat('d MMM yy').format(points.last.date),
                    style: _caption(context, size: 10)),
              ]),
            ],
            if (_awaitingData && points.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: _T.blueBgCtx(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _T.blue.withOpacity(0.2)),
                ),
                child: Row(children: [
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _T.blue),
                  ),
                  const SizedBox(width: 8),
                  Text('Loading more history…',
                      style: _caption(context, size: 11, color: _T.blue)),
                ]),
              ),
            ],
          ]),
        ),
        const SizedBox(height: 14),
        _StatsGrid(
            wins: wins,
            losses: losses,
            winRate: wr,
            avgWin: avgWin,
            avgLoss: avgLoss,
            totalTrades: trades.length),
        const SizedBox(height: 14),
        if (bestDay != null && worstDay != null) ...[
          Row(children: [
            Expanded(
                child: _HighlightTile(
              label: '🏆 Best Trade',
              trade: bestDay,
              color: _T.profitSoft,
              bg: _T.profitBgCtx(context),
            )),
            const SizedBox(width: 10),
            Expanded(
                child: _HighlightTile(
              label: '💥 Worst Trade',
              trade: worstDay,
              color: _T.lossSoft,
              bg: _T.lossBgCtx(context),
            )),
          ]),
          const SizedBox(height: 14),
        ],
        Text('Top Trades',
            style: _heading(context, size: 14, weight: FontWeight.w700)),
        const SizedBox(height: 10),
        ...([
          ...trades
        ]..sort((a, b) => b.profitLoss.abs().compareTo(a.profitLoss.abs())))
            .take(10)
            .map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _TradeCard(trade: t, onEdit: widget.onEditTrade),
                ))
            .toList(),
      ]),
    );
  }
}

class _HighlightTile extends StatelessWidget {
  final String label;
  final JournalTradeHistory trade;
  final Color color, bg;
  const _HighlightTile(
      {required this.label,
      required this.trade,
      required this.color,
      required this.bg});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 10, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 6),
          Text(_sym(trade.symbol),
              style: _body(context, size: 13, weight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(
            '${trade.profitLoss >= 0 ? '+' : ''}₹${convertToKMB(trade.profitLoss.abs().toStringAsFixed(2))}',
            style: GoogleFonts.inter(
                fontSize: 16, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 3),
          Text(DateFormat('d MMM yy').format(trade.exitDate),
              style: _caption(context, size: 10)),
        ]),
      );
}

class _ChartPoint {
  final DateTime date;
  final double cumPnl, pnl;
  const _ChartPoint(
      {required this.date, required this.cumPnl, required this.pnl});
}

class _Sparkline extends StatelessWidget {
  final List<_ChartPoint> points;
  const _Sparkline({required this.points});

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 110,
        child: CustomPaint(
          painter: _SparklinePainter(
            points: points,
            lineColor: points.last.cumPnl >= 0 ? _T.profitSoft : _T.lossSoft,
            fillColor: points.last.cumPnl >= 0
                ? _T.profitSoft.withOpacity(0.08)
                : _T.lossSoft.withOpacity(0.08),
            borderColor: _T.border(context),
          ),
          size: const Size(double.infinity, 130),
        ),
      );
}

class _SparklinePainter extends CustomPainter {
  final List<_ChartPoint> points;
  final Color lineColor, fillColor, borderColor;

  _SparklinePainter({
    required this.points,
    required this.lineColor,
    required this.fillColor,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final minVal = points.map((p) => p.cumPnl).reduce((a, b) => a < b ? a : b);
    final maxVal = points.map((p) => p.cumPnl).reduce((a, b) => a > b ? a : b);
    final range = (maxVal - minVal).abs();

    double toX(int i) => points.length == 1
        ? size.width / 2
        : i / (points.length - 1) * size.width;
    double toY(double v) => range == 0
        ? size.height / 2
        : size.height -
            ((v - minVal) / range * size.height * 0.82 + size.height * 0.09);

    final path = Path()..moveTo(toX(0), toY(points[0].cumPnl));
    for (int i = 1; i < points.length; i++) {
      if (points.length < 4) {
        path.lineTo(toX(i), toY(points[i].cumPnl));
      } else {
        final x0 = toX(i - 1);
        final y0 = toY(points[i - 1].cumPnl);
        final x1 = toX(i);
        final y1 = toY(points[i].cumPnl);
        path.cubicTo(
            x0 + (x1 - x0) * 0.5, y0, x0 + (x1 - x0) * 0.5, y1, x1, y1);
      }
    }

    final fill = Path.from(path)
      ..lineTo(toX(points.length - 1), size.height)
      ..lineTo(toX(0), size.height)
      ..close();
    canvas.drawPath(fill, Paint()..color = fillColor);

    if (minVal < 0 && maxVal > 0) {
      final zy = toY(0);
      canvas.drawLine(
          Offset(0, zy),
          Offset(size.width, zy),
          Paint()
            ..color = borderColor
            ..strokeWidth = 1
            ..style = PaintingStyle.stroke);
    }

    canvas.drawPath(
        path,
        Paint()
          ..color = lineColor
          ..strokeWidth = 2.2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round);

    canvas.drawCircle(Offset(toX(points.length - 1), toY(points.last.cumPnl)),
        4.5, Paint()..color = lineColor);
    canvas.drawCircle(Offset(toX(points.length - 1), toY(points.last.cumPnl)),
        2.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_SparklinePainter o) =>
      o.points != points || o.lineColor != lineColor;
}

class _StatsGrid extends StatelessWidget {
  final int wins, losses, totalTrades;
  final double winRate, avgWin, avgLoss;
  const _StatsGrid(
      {required this.wins,
      required this.losses,
      required this.totalTrades,
      required this.winRate,
      required this.avgWin,
      required this.avgLoss});

  @override
  Widget build(BuildContext context) => Column(children: [
        Row(children: [
          Expanded(
              child: _StatBox(
                  label: 'Win Rate',
                  value: '${winRate.toStringAsFixed(1)}%',
                  color: _T.profitSoft)),
          const SizedBox(width: 10),
          Expanded(
              child: _StatBox(
                  label: 'Total Trades',
                  value: '$totalTrades',
                  color: _T.blue)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: _StatBox(
                  label: 'Avg Win',
                  value: '₹${convertToKMB(avgWin.toStringAsFixed(0))}',
                  color: _T.profitSoft)),
          const SizedBox(width: 10),
          Expanded(
              child: _StatBox(
                  label: 'Avg Loss',
                  value: '₹${convertToKMB(avgLoss.toStringAsFixed(0))}',
                  color: _T.lossSoft)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: _StatBox(
                  label: 'Wins', value: '$wins', color: _T.profitSoft)),
          const SizedBox(width: 10),
          Expanded(
              child: _StatBox(
                  label: 'Losses', value: '$losses', color: _T.lossSoft)),
        ]),
      ]);
}

class _StatBox extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatBox(
      {required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _T.surface(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _T.border(context)),
        ),
        child: Row(children: [
          Container(
              width: 3,
              height: 30,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: _caption(context, size: 11)),
            const SizedBox(height: 3),
            Text(value,
                style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.w800, color: color)),
          ]),
        ]),
      );
}

// ─────────────────────────────────────────────
//  LIST VIEW
// ─────────────────────────────────────────────
class _ListView extends StatefulWidget {
  final List<JournalTradeHistory> trades;
  final void Function(JournalTradeHistory)? onEditTrade;
  const _ListView({required this.trades, this.onEditTrade});

  @override
  State<_ListView> createState() => _ListViewState();
}

class _ListViewState extends State<_ListView> {
  String _sort = 'Date';
  // FIX: single enum-like string — Wins and Losses are mutually exclusive
  String _filter = 'All'; // 'All' | 'Wins' | 'Losses'

  List<JournalTradeHistory> get _filtered {
    var list = [...widget.trades];
    if (_filter == 'Wins') list = list.where((t) => t.profitLoss > 0).toList();
    if (_filter == 'Losses') {
      list = list.where((t) => t.profitLoss < 0).toList();
    }
    switch (_sort) {
      case 'P&L':
        list.sort((a, b) => b.profitLoss.compareTo(a.profitLoss));
        break;
      case 'Symbol':
        list.sort((a, b) => a.symbol.compareTo(b.symbol));
        break;
      default:
        list.sort((a, b) => b.exitDate.compareTo(a.exitDate));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final trades = _filtered;
    final totalPnl = trades.fold(0.0, (s, t) => s + t.profitLoss);
    final isPos = totalPnl >= 0;

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Row(children: [
          _FilterChip(
              label: 'Sort: $_sort',
              icon: Icons.sort_rounded,
              onTap: _showSortSheet),
          const SizedBox(width: 8),
          // FIX: tapping the active chip toggles it off (back to 'All')
          //      tapping the inactive chip activates it and deactivates the other
          _FilterChip(
              label: 'Wins',
              icon: Icons.thumb_up_outlined,
              active: _filter == 'Wins',
              activeColor: _T.profitSoft,
              onTap: () =>
                  setState(() => _filter = _filter == 'Wins' ? 'All' : 'Wins')),
          const SizedBox(width: 8),
          _FilterChip(
              label: 'Losses',
              icon: Icons.thumb_down_outlined,
              active: _filter == 'Losses',
              activeColor: _T.lossSoft,
              onTap: () => setState(
                  () => _filter = _filter == 'Losses' ? 'All' : 'Losses')),
          const Spacer(),
          Text('${trades.length}', style: _caption(context, size: 11)),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _T.surface(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _T.border(context)),
          ),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Filtered P&L',
                style: _body(context, size: 13, weight: FontWeight.w600)),
            Text(
              '${isPos ? '+' : ''}₹${convertToKMB(totalPnl.toStringAsFixed(2))}',
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isPos ? _T.profitSoft : _T.lossSoft),
            ),
          ]),
        ),
      ),
      Expanded(
        child: trades.isEmpty
            ? Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.inbox_outlined, size: 32, color: _T.text3(context)),
                const SizedBox(height: 10),
                Text('No trades match filters',
                    style: _caption(context, size: 13)),
              ]))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                itemCount: trades.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child:
                      _TradeCard(trade: trades[i], onEdit: widget.onEditTrade),
                ),
              ),
      ),
    ]);
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _T.surface(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Sort by',
              style: _heading(context, size: 16, weight: FontWeight.w700)),
          const SizedBox(height: 16),
          ...['Date', 'P&L', 'Symbol'].map((s) => ListTile(
                title: Text(s, style: _body(context, size: 14)),
                leading: Icon(
                  _sort == s
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: _sort == s ? _T.blue : _T.text3(context),
                  size: 20,
                ),
                onTap: () {
                  setState(() => _sort = s);
                  Navigator.pop(context);
                },
              )),
        ]),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final Color? activeColor;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label,
      required this.icon,
      required this.onTap,
      this.active = false,
      this.activeColor});

  @override
  Widget build(BuildContext context) {
    final color = active ? (activeColor ?? _T.blue) : _T.text2(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.1) : _T.surface(context),
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: active ? color : _T.border(context), width: 1),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: color)),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Nav Arrow (reusable)
// ─────────────────────────────────────────────
class _NavArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavArrow({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _T.surface2(context),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _T.border(context)),
          ),
          child: Icon(icon, size: 18, color: _T.text2(context)),
        ),
      );
}
