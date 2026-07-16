import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
// import 'package:optionxi/Payments/subsctiption_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dart:math' as math;

// ─────────────────────────────────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────────────────────────────────

class IndexEntry {
  final int id;
  final String symbol;
  final String snapshotTime;
  final String? sentiment;
  final double? close;
  final double? high;
  final double? low;
  final String description;

  IndexEntry({
    required this.id,
    required this.symbol,
    required this.snapshotTime,
    this.sentiment,
    this.close,
    this.high,
    this.low,
    required this.description,
  });

  factory IndexEntry.fromMap(Map<String, dynamic> m) => IndexEntry(
        id: m['id'] as int,
        symbol: m['symbol'] as String,
        snapshotTime: m['snapshot_time'] as String,
        sentiment: m['sentiment'] as String?,
        close: (m['close'] as num?)?.toDouble(),
        high: (m['high'] as num?)?.toDouble(),
        low: (m['low'] as num?)?.toDouble(),
        description: m['description'] as String? ?? '',
      );

  bool get isUpBreakout => description.toLowerCase().contains('high');
}

class OhlcvEntry {
  final String ts;
  final double open;
  final double high;
  final double low;
  final double close;
  final String symbol;

  OhlcvEntry({
    required this.ts,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.symbol,
  });

  factory OhlcvEntry.fromMap(Map<String, dynamic> m) => OhlcvEntry(
        ts: m['ts'] as String,
        open: (m['open'] as num).toDouble(),
        high: (m['high'] as num).toDouble(),
        low: (m['low'] as num).toDouble(),
        close: (m['close'] as num).toDouble(),
        symbol: m['symbol'] as String? ?? 'NIFTY50',
      );
}

class GroupedIndex {
  final String symbol;
  final String mappedSymbol;
  final String sentiment;
  final String firstSeenIso;
  final double? startPrice;
  double? latestPrice;
  double? priceChange;
  final List<IndexEntry> picks;
  List<OhlcvEntry> ohlcvData;
  // First high/low breakout times
  String? firstHighIso;
  String? firstLowIso;

  GroupedIndex({
    required this.symbol,
    required this.mappedSymbol,
    required this.sentiment,
    required this.firstSeenIso,
    this.startPrice,
    this.latestPrice,
    this.priceChange,
    required this.picks,
    required this.ohlcvData,
    this.firstHighIso,
    this.firstLowIso,
  });
}

class ChartDataPoint {
  final DateTime timestamp;
  final double open;
  final double high;
  final double low;
  final double close;

  ChartDataPoint({
    required this.timestamp,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
  });
}

// Time range filter options
enum TimeRangeFilter {
  all,
  firstHour, // 9:15–10:15
  midMorning, // 10:15–11:30
  preNoon, // 11:30–12:30
  afternoon, // 12:30–15:30
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

String mapSymbol(String s) {
  if (s == 'NIFTY50') return 'NIFTY';
  if (s == 'NIFTYBANK') return 'BANKNIFTY';
  return s;
}

DateTime getTodayIST() {
  final now = DateTime.now().toUtc();
  return now.add(const Duration(hours: 5, minutes: 30));
}

String formatDateHeader(DateTime d) => DateFormat('dd MMM yyyy').format(d);

String formatTimeIST(String iso) {
  final d =
      DateTime.parse(iso).toUtc().add(const Duration(hours: 5, minutes: 30));
  return DateFormat('hh:mm a').format(d);
}

DateTime getLocalIstTime(String iso) {
  final utcTime = DateTime.parse(iso).toUtc();
  final istTime = utcTime.add(const Duration(hours: 5, minutes: 30));
  return DateTime(
      istTime.year, istTime.month, istTime.day, istTime.hour, istTime.minute);
}

Color dominantColor(List<IndexEntry> picks, {required bool isDark}) {
  final upCount = picks.where((p) => p.isUpBreakout).length;
  if (upCount >= picks.length / 2) {
    return isDark ? const Color(0xFF10b981) : const Color(0xFF059669);
  }
  return isDark ? const Color(0xFFef4444) : const Color(0xFFdc2626);
}

// Time range filter helpers
String timeRangeLabel(TimeRangeFilter f) {
  switch (f) {
    case TimeRangeFilter.all:
      return 'All Day';
    case TimeRangeFilter.firstHour:
      return '9:15–10:15';
    case TimeRangeFilter.midMorning:
      return '10:15–11:30';
    case TimeRangeFilter.preNoon:
      return '11:30–12:30';
    case TimeRangeFilter.afternoon:
      return '12:30–3:30';
  }
}

// Returns (startHour, startMin, endHour, endMin) in IST local
({int sh, int sm, int eh, int em}) timeRangeBounds(TimeRangeFilter f) {
  switch (f) {
    case TimeRangeFilter.all:
      return (sh: 9, sm: 15, eh: 15, em: 30);
    case TimeRangeFilter.firstHour:
      return (sh: 9, sm: 15, eh: 10, em: 15);
    case TimeRangeFilter.midMorning:
      return (sh: 10, sm: 15, eh: 11, em: 30);
    case TimeRangeFilter.preNoon:
      return (sh: 11, sm: 30, eh: 12, em: 30);
    case TimeRangeFilter.afternoon:
      return (sh: 12, sm: 30, eh: 15, em: 30);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Design Tokens
// ─────────────────────────────────────────────────────────────────────────────

class AppColors {
  // Dark palette
  static const darkBg = Color(0xFF080808);
  static const darkSurface = Color(0xFF101010);
  static const darkCard = Color(0xFF141414);
  static const darkBorder = Color(0xFF222222);
  static const darkSubBg = Color(0xFF0c0c0c);
  static const darkTextPrimary = Color(0xFFf0f0f0);
  static const darkTextSub = Color(0xFF888888);
  static const darkTextMuted = Color(0xFF444444);

  // Light palette
  static const lightBg = Color(0xFFf5f5f5);
  static const lightSurface = Color(0xFFffffff);
  static const lightCard = Color(0xFFffffff);
  static const lightBorder = Color(0xFFe8e8e8);
  static const lightSubBg = Color(0xFFfafafa);
  static const lightTextPrimary = Color(0xFF111111);
  static const lightTextSub = Color(0xFF666666);
  static const lightTextMuted = Color(0xFFbbbbbb);

  // Semantic
  static const bullDark = Color(0xFF00d68f);
  static const bullLight = Color(0xFF00a86b);
  static const bearDark = Color(0xFFff4757);
  static const bearLight = Color(0xFFe8283a);
  static const accent = Color(0xFFF59E0B);
}

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

class AIPickedIndexPage extends StatefulWidget {
  const AIPickedIndexPage({super.key});

  @override
  State<AIPickedIndexPage> createState() => _AIPickedIndexPageState();
}

class _AIPickedIndexPageState extends State<AIPickedIndexPage> {
  DateTime _selectedDate = getTodayIST();
  List<GroupedIndex> _groups = [];
  bool _loading = true;
  String? _error;
  TimeRangeFilter _timeFilter = TimeRangeFilter.all;

  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final y = _selectedDate.year;
      final m = _selectedDate.month;
      final d = _selectedDate.day;

      // Full market day fetch always (filter applied client-side for chart zoom)
      final start = DateTime.utc(y, m, d, 3, 45).toIso8601String();
      final end = DateTime.utc(y, m, d, 10, 0).toIso8601String();

      final picksRes = await _supabase
          .from('ai_picked_index')
          .select()
          .gte('snapshot_time', start)
          .lte('snapshot_time', end)
          .order('snapshot_time', ascending: true);

      final ohlcvRes = await _supabase
          .from('nifty_ohlcv')
          .select()
          .gte('ts', start)
          .lte('ts', end)
          .order('ts', ascending: true);

      final picks =
          (picksRes as List).map((e) => IndexEntry.fromMap(e)).toList();

      final rawOhlcv = ohlcvRes as List;
      final allOhlcv = rawOhlcv.map((e) => OhlcvEntry.fromMap(e)).toList();

      final groupedMap = <String, GroupedIndex>{};

      for (final pick in picks) {
        final mapped = mapSymbol(pick.symbol);
        if (!groupedMap.containsKey(mapped)) {
          groupedMap[mapped] = GroupedIndex(
            symbol: pick.symbol,
            mappedSymbol: mapped,
            sentiment: pick.sentiment ?? 'Neutral',
            firstSeenIso: pick.snapshotTime,
            startPrice: pick.close,
            picks: [],
            ohlcvData: [],
          );
        }
        groupedMap[mapped]!.picks.add(pick);
      }

      groupedMap.forEach((mappedSym, group) {
        group.ohlcvData =
            allOhlcv.where((o) => mapSymbol(o.symbol) == mappedSym).toList();

        if (group.ohlcvData.isNotEmpty) {
          group.latestPrice = group.ohlcvData.last.close;
          if (group.startPrice != null) {
            group.priceChange = group.latestPrice! - group.startPrice!;
          }
        }

        // Find first high and first low breakout times
        final highs = group.picks.where((p) => p.isUpBreakout).toList();
        final lows = group.picks.where((p) => !p.isUpBreakout).toList();
        if (highs.isNotEmpty) group.firstHighIso = highs.first.snapshotTime;
        if (lows.isNotEmpty) group.firstLowIso = lows.first.snapshotTime;
      });

      setState(() {
        _groups = groupedMap.values.toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  bool get _isToday =>
      formatDateHeader(_selectedDate) == formatDateHeader(getTodayIST());

  void _prevDay() {
    setState(
        () => _selectedDate = _selectedDate.subtract(const Duration(days: 1)));
    _fetchData();
  }

  void _nextDay() {
    if (_isToday) return;
    setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1)));
    _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? AppColors.darkBg : AppColors.lightBg;
    final surfaceColor =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final subBg = isDark ? AppColors.darkSubBg : AppColors.lightSubBg;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSub = isDark ? AppColors.darkTextSub : AppColors.lightTextSub;
    final textMuted =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Column(
            children: [
              // ── Top Navigation Bar ──
              _TopBar(
                isDark: isDark,
                selectedDate: _selectedDate,
                isToday: _isToday,
                onPrev: _prevDay,
                onNext: _nextDay,
                surfaceColor: surfaceColor,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSub: textSub,
                onAnalysePressed: () {
                  Get.toNamed('/backtest/nifty');
                },
              ),
              // ── Time Range Filter Bar ──
              _TimeFilterBar(
                isDark: isDark,
                selected: _timeFilter,
                onSelect: (f) => setState(() => _timeFilter = f),
                surfaceColor: surfaceColor,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSub: textSub,
              ),
              // ── Content ──
              Expanded(
                child: _loading
                    ? _ShimmerLoadingView(isDark: isDark)
                    : _error != null
                        ? _ErrorView(error: _error!, isDark: isDark)
                        : _groups.isEmpty
                            ? _EmptyView(
                                date: formatDateHeader(_selectedDate),
                                isDark: isDark,
                                textSub: textSub,
                                borderColor: borderColor,
                              )
                            : _GroupList(
                                groups: _groups,
                                isDark: isDark,
                                cardColor: cardColor,
                                borderColor: borderColor,
                                subBg: subBg,
                                textPrimary: textPrimary,
                                textSub: textSub,
                                textMuted: textMuted,
                                timeFilter: _timeFilter,
                                selectedDate: _selectedDate,
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top Bar
// ─────────────────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final bool isDark;
  final DateTime selectedDate;
  final bool isToday;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onAnalysePressed;
  final Color surfaceColor;
  final Color borderColor;
  final Color textPrimary;
  final Color textSub;

  const _TopBar({
    required this.isDark,
    required this.selectedDate,
    required this.isToday,
    required this.onPrev,
    required this.onNext,
    required this.onAnalysePressed,
    required this.surfaceColor,
    required this.borderColor,
    required this.textPrimary,
    required this.textSub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: surfaceColor,
      child: Column(
        children: [
          // Back + Title row
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 16, 4),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.maybePop(context),
                  icon: Icon(Icons.arrow_back_ios_new_rounded,
                      size: 17, color: textPrimary),
                  splashRadius: 20,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Index Breakouts',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                          fontFamily: 'monospace',
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Breakout momentum & probabilities',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark
                              ? const Color(0xFF52525B)
                              : const Color(0xFF71717A),
                          fontFamily: 'monospace',
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _HeaderIconBtn(
                  icon: Icons.assessment_outlined,
                  isDark: isDark,
                  borderColor: borderColor,
                  onTap: onAnalysePressed,
                ),
              ],
            ),
          ),

          // Date Navigator + Analyse button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: _DateNav(
                    isDark: isDark,
                    selectedDate: selectedDate,
                    isToday: isToday,
                    onPrev: onPrev,
                    onNext: onNext,
                    borderColor: borderColor,
                    textPrimary: textPrimary,
                  ),
                ),
              ],
            ),
          ),

          // Upgrade chip
          // GestureDetector(
          //   onTap: () => Navigator.push(
          //     context,
          //     MaterialPageRoute(builder: (_) => SubscriptionScreenModern()),
          //   ),
          //   child: Container(
          //     padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          //     decoration: BoxDecoration(
          //       color: AppColors.accent,
          //       borderRadius: BorderRadius.circular(10),
          //     ),
          //     child: Row(
          //       mainAxisSize: MainAxisSize.min,
          //       children: const [
          //         Icon(Icons.bolt_rounded, size: 13, color: Colors.black),
          //         SizedBox(width: 4),
          //         Text(
          //           'PRO',
          //           style: TextStyle(
          //             color: Colors.black,
          //             fontSize: 12,
          //             fontWeight: FontWeight.w800,
          //             fontFamily: 'monospace',
          //             letterSpacing: 0.5,
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}

class _HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final Color borderColor;
  final VoidCallback onTap;

  const _HeaderIconBtn({
    required this.icon,
    required this.isDark,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1a1a1a) : const Color(0xFFf2f2f2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Icon(
            icon,
            size: 20,
            color: isDark ? AppColors.darkTextSub : AppColors.lightTextSub,
          ),
        ),
      ),
    );
  }
}

class _DateNav extends StatelessWidget {
  final bool isDark;
  final DateTime selectedDate;
  final bool isToday;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final Color borderColor;
  final Color textPrimary;

  const _DateNav({
    required this.isDark,
    required this.selectedDate,
    required this.isToday,
    required this.onPrev,
    required this.onNext,
    required this.borderColor,
    required this.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1a1a1a) : const Color(0xFFf2f2f2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          _NavIconBtn(
            icon: Icons.chevron_left_rounded,
            onTap: onPrev,
            isDark: isDark,
          ),
          Expanded(
            child: Center(
              child: Text(
                formatDateHeader(selectedDate),
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
          _NavIconBtn(
            icon: Icons.chevron_right_rounded,
            onTap: isToday ? null : onNext,
            isDark: isDark,
            disabled: isToday,
          ),
        ],
      ),
    );
  }
}

class _NavIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isDark;
  final bool disabled;

  const _NavIconBtn({
    required this.icon,
    required this.onTap,
    required this.isDark,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Opacity(
        opacity: disabled ? 0.25 : 1,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 18,
            color: isDark ? AppColors.darkTextSub : AppColors.lightTextSub,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Time Filter Bar
// ─────────────────────────────────────────────────────────────────────────────

class _TimeFilterBar extends StatelessWidget {
  final bool isDark;
  final TimeRangeFilter selected;
  final ValueChanged<TimeRangeFilter> onSelect;
  final Color surfaceColor;
  final Color borderColor;
  final Color textPrimary;
  final Color textSub;

  const _TimeFilterBar({
    required this.isDark,
    required this.selected,
    required this.onSelect,
    required this.surfaceColor,
    required this.borderColor,
    required this.textPrimary,
    required this.textSub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: surfaceColor,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label row
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 11,
                color: textSub,
              ),
              const SizedBox(width: 5),
              Text(
                'ZOOM TO SESSION',
                style: TextStyle(
                  color: textSub,
                  fontSize: 10,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Filter chips
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: TimeRangeFilter.values.map((f) {
                final isActive = selected == f;
                return _FilterChip(
                  label: timeRangeLabel(f),
                  isActive: isActive,
                  isDark: isDark,
                  onTap: () => onSelect(f),
                  borderColor: borderColor,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;
  final Color borderColor;

  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.isDark,
    required this.onTap,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.accent
              : (isDark ? const Color(0xFF1a1a1a) : const Color(0xFFf0f0f0)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? AppColors.accent : borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive
                ? Colors.black
                : (isDark ? AppColors.darkTextSub : AppColors.lightTextSub),
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
            fontFamily: 'monospace',
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Group List
// ─────────────────────────────────────────────────────────────────────────────

class _GroupList extends StatelessWidget {
  final List<GroupedIndex> groups;
  final bool isDark;
  final Color cardColor;
  final Color borderColor;
  final Color subBg;
  final Color textPrimary;
  final Color textSub;
  final Color textMuted;
  final TimeRangeFilter timeFilter;
  final DateTime selectedDate;

  const _GroupList({
    required this.groups,
    required this.isDark,
    required this.cardColor,
    required this.borderColor,
    required this.subBg,
    required this.textPrimary,
    required this.textSub,
    required this.textMuted,
    required this.timeFilter,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: groups.length + 1,
      itemBuilder: (ctx, i) {
        if (i == groups.length) {
          return _Disclaimer(textMuted: textMuted);
        }
        return _IndexCard(
          group: groups[i],
          isDark: isDark,
          cardColor: cardColor,
          borderColor: borderColor,
          subBg: subBg,
          textPrimary: textPrimary,
          textSub: textSub,
          timeFilter: timeFilter,
          selectedDate: selectedDate,
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Index Card
// ─────────────────────────────────────────────────────────────────────────────

class _IndexCard extends StatefulWidget {
  final GroupedIndex group;
  final bool isDark;
  final Color cardColor;
  final Color borderColor;
  final Color subBg;
  final Color textPrimary;
  final Color textSub;
  final TimeRangeFilter timeFilter;
  final DateTime selectedDate;

  const _IndexCard({
    required this.group,
    required this.isDark,
    required this.cardColor,
    required this.borderColor,
    required this.subBg,
    required this.textPrimary,
    required this.textSub,
    required this.timeFilter,
    required this.selectedDate,
  });

  @override
  State<_IndexCard> createState() => _IndexCardState();
}

class _IndexCardState extends State<_IndexCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.group;
    final isDark = widget.isDark;
    final themeColor = dominantColor(g.picks, isDark: isDark);
    final upCount = g.picks.where((p) => p.isUpBreakout).length;
    final downCount = g.picks.length - upCount;
    final isPositive = (g.priceChange ?? 0) >= 0;

    final bullColor = isDark ? AppColors.bullDark : AppColors.bullLight;
    final bearColor = isDark ? AppColors.bearDark : AppColors.bearLight;
    final changeColor = isPositive ? bullColor : bearColor;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: widget.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: widget.borderColor),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    )
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Card Header ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Symbol + badges
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              g.mappedSymbol,
                              style: TextStyle(
                                color: widget.textPrimary,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.8,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                if (upCount > 0)
                                  _SignalBadge(
                                    label: '↑ $upCount',
                                    sublabel: 'Highs',
                                    color: bullColor,
                                    isDark: isDark,
                                  ),
                                if (downCount > 0)
                                  _SignalBadge(
                                    label: '↓ $downCount',
                                    sublabel: 'Lows',
                                    color: bearColor,
                                    isDark: isDark,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Price + change
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            g.latestPrice?.toStringAsFixed(2) ?? '—',
                            style: TextStyle(
                              color: widget.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'monospace',
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: changeColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              g.priceChange != null
                                  ? '${isPositive ? '+' : ''}${g.priceChange!.toStringAsFixed(2)}'
                                  : '—',
                              style: TextStyle(
                                color: changeColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── First Breakout Info Row ──
                _BreakoutInfoRow(
                  group: g,
                  isDark: isDark,
                  subBg: widget.subBg,
                  borderColor: widget.borderColor,
                  textSub: widget.textSub,
                  bullColor: bullColor,
                  bearColor: bearColor,
                ),

                // ── Chart ──
                Container(
                  height: 280,
                  color: widget.subBg,
                  child: g.ohlcvData.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.bar_chart_rounded,
                                  size: 32, color: widget.textSub),
                              const SizedBox(height: 8),
                              Text(
                                'No OHLCV data',
                                style: TextStyle(
                                  color: widget.textSub,
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        )
                      : _ChartArea(
                          group: g,
                          themeColor: themeColor,
                          isDark: isDark,
                          borderColor: widget.borderColor,
                          timeFilter: widget.timeFilter,
                          selectedDate: widget.selectedDate,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Breakout Info Row
// ─────────────────────────────────────────────────────────────────────────────

class _BreakoutInfoRow extends StatelessWidget {
  final GroupedIndex group;
  final bool isDark;
  final Color subBg;
  final Color borderColor;
  final Color textSub;
  final Color bullColor;
  final Color bearColor;

  const _BreakoutInfoRow({
    required this.group,
    required this.isDark,
    required this.subBg,
    required this.borderColor,
    required this.textSub,
    required this.bullColor,
    required this.bearColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasHigh = group.firstHighIso != null;
    final hasLow = group.firstLowIso != null;

    return Container(
      decoration: BoxDecoration(
        color: subBg,
        border: Border(
          top: BorderSide(color: borderColor),
          bottom: BorderSide(color: borderColor),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          if (hasHigh) ...[
            _BreakoutChip(
              icon: Icons.arrow_upward_rounded,
              label: '1ST HIGH',
              time: formatTimeIST(group.firstHighIso!),
              color: bullColor,
              isDark: isDark,
            ),
            if (hasLow) const SizedBox(width: 12),
          ],
          if (hasLow)
            _BreakoutChip(
              icon: Icons.arrow_downward_rounded,
              label: '1ST LOW',
              time: formatTimeIST(group.firstLowIso!),
              color: bearColor,
              isDark: isDark,
            ),
          if (!hasHigh && !hasLow)
            Row(
              children: [
                Icon(Icons.access_time_rounded, size: 13, color: textSub),
                const SizedBox(width: 6),
                Text(
                  '1ST BROKE: ${formatTimeIST(group.firstSeenIso)}',
                  style: TextStyle(
                    color: textSub,
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _BreakoutChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String time;
  final Color color;
  final bool isDark;

  const _BreakoutChip({
    required this.icon,
    required this.label,
    required this.time,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color.withOpacity(0.7),
                  fontSize: 9,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              Text(
                time,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chart Area — Improved Candlestick with Clean Annotations
// ─────────────────────────────────────────────────────────────────────────────

class _ChartArea extends StatelessWidget {
  final GroupedIndex group;
  final Color themeColor;
  final bool isDark;
  final Color borderColor;
  final TimeRangeFilter timeFilter;
  final DateTime selectedDate;

  const _ChartArea({
    required this.group,
    required this.themeColor,
    required this.isDark,
    required this.borderColor,
    required this.timeFilter,
    required this.selectedDate,
  });

  List<ChartDataPoint> _buildChartData() {
    return group.ohlcvData.map((ohlcv) {
      final timestamp = getLocalIstTime(ohlcv.ts);
      return ChartDataPoint(
        timestamp: timestamp,
        open: ohlcv.open,
        high: ohlcv.high,
        low: ohlcv.low,
        close: ohlcv.close,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final chartData = _buildChartData();
    final gridColor =
        isDark ? const Color(0xFF1e1e1e) : const Color(0xFFeeeeee);
    final bullColor = isDark ? AppColors.bullDark : AppColors.bullLight;
    final bearColor = isDark ? AppColors.bearDark : AppColors.bearLight;

    final y = selectedDate.year;
    final mo = selectedDate.month;
    final da = selectedDate.day;

    // Apply time filter for X-axis zoom
    final bounds = timeRangeBounds(timeFilter);
    final xMin = DateTime(y, mo, da, bounds.sh, bounds.sm);
    final xMax = DateTime(y, mo, da, bounds.eh, bounds.em);

    // Build annotation lines only for picks within visible range
    final visiblePicks = group.picks.where((pick) {
      final t = getLocalIstTime(pick.snapshotTime);
      return !t.isBefore(xMin) && !t.isAfter(xMax);
    }).toList();

    // For clean annotations: only show first high and first low as lines
    // Mark all others as subtle dots via series
    IndexEntry? firstHigh;
    IndexEntry? firstLow;
    for (final p in visiblePicks) {
      if (p.isUpBreakout && firstHigh == null) firstHigh = p;
      if (!p.isUpBreakout && firstLow == null) firstLow = p;
    }

    final plotBands = <PlotBand>[];

    // Add clean vertical plot bands (no labels — labels are in the chip row above)
    for (final pick in visiblePicks) {
      final t = getLocalIstTime(pick.snapshotTime);
      final isUp = pick.isUpBreakout;
      final color = isUp ? bullColor : bearColor;
      final isFirst = (isUp && firstHigh?.id == pick.id) ||
          (!isUp && firstLow?.id == pick.id);

      plotBands.add(PlotBand(
        isVisible: true,
        start: t,
        end: t,
        borderWidth: isFirst ? 2.0 : 1.0,
        borderColor: isFirst ? color : color.withOpacity(0.4),
        dashArray: isFirst ? [] : const <double>[3, 4],
        // No text labels on chart — cleaner look
      ));
    }

    // Annotation data for first-break markers (rendered as scatter overlay)
    final List<ChartDataPoint> highAnnotations = [];
    final List<ChartDataPoint> lowAnnotations = [];

    if (firstHigh != null) {
      final t = getLocalIstTime(firstHigh.snapshotTime);
      // Find closest OHLCV candle for price
      OhlcvEntry? closest;
      int minDiff = 999999;
      for (final o in group.ohlcvData) {
        final ot = getLocalIstTime(o.ts);
        final diff = (ot.difference(t).inMinutes).abs();
        if (diff < minDiff) {
          minDiff = diff;
          closest = o;
        }
      }
      if (closest != null) {
        highAnnotations.add(ChartDataPoint(
          timestamp: t,
          open: closest.open,
          high: closest.high + (closest.high * 0.001),
          low: closest.low,
          close: closest.close,
        ));
      }
    }

    if (firstLow != null) {
      final t = getLocalIstTime(firstLow.snapshotTime);
      OhlcvEntry? closest;
      int minDiff = 999999;
      for (final o in group.ohlcvData) {
        final ot = getLocalIstTime(o.ts);
        final diff = (ot.difference(t).inMinutes).abs();
        if (diff < minDiff) {
          minDiff = diff;
          closest = o;
        }
      }
      if (closest != null) {
        lowAnnotations.add(ChartDataPoint(
          timestamp: t,
          open: closest.open,
          high: closest.high,
          low: closest.low - (closest.low * 0.001),
          close: closest.close,
        ));
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 8, 8),
      child: SfCartesianChart(
        backgroundColor: Colors.transparent,
        plotAreaBorderWidth: 0,
        margin: EdgeInsets.zero,
        crosshairBehavior: CrosshairBehavior(
          enable: true,
          lineColor: themeColor.withOpacity(0.4),
          lineWidth: 1,
          lineDashArray: const [4, 4],
          shouldAlwaysShow: false,
          activationMode: ActivationMode.singleTap,
        ),
        zoomPanBehavior: ZoomPanBehavior(
          enablePanning: true,
          enablePinching: true,
          zoomMode: ZoomMode.x,
          enableDoubleTapZooming: true,
        ),
        trackballBehavior: TrackballBehavior(
          enable: true,
          activationMode: ActivationMode.singleTap,
          tooltipSettings: InteractiveTooltip(
            enable: true,
            color: isDark ? const Color(0xFF1c1c1c) : Colors.white,
            borderColor: themeColor.withOpacity(0.4),
            borderWidth: 1,
            format:
                'point.x\nO: point.open  H: point.high\nL: point.low  C: point.close',
            textStyle: TextStyle(
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
              fontFamily: 'monospace',
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          markerSettings: TrackballMarkerSettings(
            markerVisibility: TrackballVisibilityMode.visible,
            color: themeColor,
            borderColor: themeColor,
            borderWidth: 2,
            height: 7,
            width: 7,
          ),
          lineColor: themeColor.withOpacity(0.25),
          lineWidth: 1,
          lineDashArray: const [4, 4],
        ),
        primaryXAxis: DateTimeAxis(
          isVisible: true,
          minimum: xMin,
          maximum: xMax,
          majorGridLines: MajorGridLines(
              color: gridColor, width: 1, dashArray: const [2, 4]),
          minorGridLines: const MinorGridLines(width: 0),
          axisLine: const AxisLine(width: 0),
          majorTickLines: const MajorTickLines(size: 0),
          labelStyle: TextStyle(
            color: isDark ? const Color(0xFF555555) : const Color(0xFFaaaaaa),
            fontSize: 10,
            fontFamily: 'monospace',
          ),
          dateFormat: DateFormat('h:mm'),
          intervalType: DateTimeIntervalType.minutes,
          interval: _xInterval(timeFilter),
          edgeLabelPlacement: EdgeLabelPlacement.shift,
          plotBands: plotBands,
        ),
        primaryYAxis: NumericAxis(
          isVisible: true,
          opposedPosition: true,
          majorGridLines: MajorGridLines(
              color: gridColor, width: 0.5, dashArray: const [2, 4]),
          minorGridLines: const MinorGridLines(width: 0),
          axisLine: const AxisLine(width: 0),
          majorTickLines: const MajorTickLines(size: 0),
          labelStyle: TextStyle(
            color: isDark ? const Color(0xFF555555) : const Color(0xFFaaaaaa),
            fontSize: 10,
            fontFamily: 'monospace',
          ),
          numberFormat: NumberFormat.compact(),
        ),
        series: <CartesianSeries>[
          // ── Candlestick ──
          CandleSeries<ChartDataPoint, DateTime>(
            dataSource: chartData,
            xValueMapper: (d, _) => d.timestamp,
            lowValueMapper: (d, _) => d.low,
            highValueMapper: (d, _) => d.high,
            openValueMapper: (d, _) => d.open,
            closeValueMapper: (d, _) => d.close,
            bullColor: bullColor,
            bearColor: bearColor,
            enableSolidCandles: true,
            animationDuration: 800,
            enableTooltip: true,
            spacing: 0.15,
            width: 0.65,
          ),
          // ── First High Marker ──
          if (highAnnotations.isNotEmpty)
            ScatterSeries<ChartDataPoint, DateTime>(
              dataSource: highAnnotations,
              xValueMapper: (d, _) => d.timestamp,
              yValueMapper: (d, _) => d.high,
              color: bullColor,
              markerSettings: const MarkerSettings(
                isVisible: true,
                shape: DataMarkerType.triangle,
                height: 10,
                width: 10,
              ),
              enableTooltip: false,
              animationDuration: 1000,
            ),
          // ── First Low Marker ──
          if (lowAnnotations.isNotEmpty)
            ScatterSeries<ChartDataPoint, DateTime>(
              dataSource: lowAnnotations,
              xValueMapper: (d, _) => d.timestamp,
              yValueMapper: (d, _) => d.low,
              color: bearColor,
              markerSettings: const MarkerSettings(
                isVisible: true,
                shape: DataMarkerType.invertedTriangle,
                height: 10,
                width: 10,
              ),
              enableTooltip: false,
              animationDuration: 1000,
            ),
        ],
      ),
    );
  }

  double _xInterval(TimeRangeFilter f) {
    switch (f) {
      case TimeRangeFilter.firstHour:
        return 15;
      case TimeRangeFilter.midMorning:
      case TimeRangeFilter.preNoon:
        return 15;
      case TimeRangeFilter.afternoon:
        return 30;
      case TimeRangeFilter.all:
        return 60;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shimmer Loading (no plugin)
// ─────────────────────────────────────────────────────────────────────────────

class _ShimmerLoadingView extends StatefulWidget {
  final bool isDark;
  const _ShimmerLoadingView({required this.isDark});

  @override
  State<_ShimmerLoadingView> createState() => _ShimmerLoadingViewState();
}

class _ShimmerLoadingViewState extends State<_ShimmerLoadingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
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
      builder: (ctx, _) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 2,
          itemBuilder: (_, i) => _ShimmerCard(
            isDark: widget.isDark,
            progress: _anim.value,
          ),
        );
      },
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  final bool isDark;
  final double progress;

  const _ShimmerCard({required this.isDark, required this.progress});

  @override
  Widget build(BuildContext context) {
    final baseColor =
        isDark ? const Color(0xFF181818) : const Color(0xFFe8e8e8);
    final shineColor =
        isDark ? const Color(0xFF272727) : const Color(0xFFf5f5f5);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141414) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF222222) : const Color(0xFFe8e8e8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Symbol skeleton
                _ShimmerBox(
                  width: 140,
                  height: 28,
                  base: baseColor,
                  shine: shineColor,
                  progress: progress,
                  radius: 6,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _ShimmerBox(
                      width: 72,
                      height: 22,
                      base: baseColor,
                      shine: shineColor,
                      progress: progress,
                      radius: 6,
                    ),
                    const SizedBox(width: 8),
                    _ShimmerBox(
                      width: 72,
                      height: 22,
                      base: baseColor,
                      shine: shineColor,
                      progress: progress,
                      radius: 6,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Breakout info row skeleton
          Container(
            color: isDark ? const Color(0xFF0c0c0c) : const Color(0xFFfafafa),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                _ShimmerBox(
                  width: 100,
                  height: 38,
                  base: baseColor,
                  shine: shineColor,
                  progress: progress,
                  radius: 8,
                ),
                const SizedBox(width: 10),
                _ShimmerBox(
                  width: 100,
                  height: 38,
                  base: baseColor,
                  shine: shineColor,
                  progress: progress,
                  radius: 8,
                ),
              ],
            ),
          ),
          // Chart skeleton with fake candle bars
          Container(
            height: 240,
            color: isDark ? const Color(0xFF0c0c0c) : const Color(0xFFfafafa),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: _FakeCandleChart(
              isDark: isDark,
              progress: progress,
              base: baseColor,
              shine: shineColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _FakeCandleChart extends StatelessWidget {
  final bool isDark;
  final double progress;
  final Color base;
  final Color shine;

  const _FakeCandleChart({
    required this.isDark,
    required this.progress,
    required this.base,
    required this.shine,
  });

  @override
  Widget build(BuildContext context) {
    final rng = math.Random(42);
    final candles = List.generate(22, (i) {
      final h = 0.3 + rng.nextDouble() * 0.6;
      final offset = rng.nextDouble() * (1 - h);
      return (height: h, offset: offset);
    });

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: candles.map((c) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      heightFactor: c.height,
                      child: _ShimmerBox(
                        width: double.infinity,
                        height: double.infinity,
                        base: base,
                        shine: shine,
                        progress: progress,
                        radius: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final Color base;
  final Color shine;
  final double progress;
  final double radius;

  const _ShimmerBox({
    required this.width,
    required this.height,
    required this.base,
    required this.shine,
    required this.progress,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width == double.infinity ? null : width,
      height: height == double.infinity ? null : height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment(-1.5 + progress * 3, 0),
          end: Alignment(-0.5 + progress * 3, 0),
          colors: [base, shine, base],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Signal Badge
// ─────────────────────────────────────────────────────────────────────────────

class _SignalBadge extends StatelessWidget {
  final String label;
  final String sublabel;
  final Color color;
  final bool isDark;

  const _SignalBadge({
    required this.label,
    required this.sublabel,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            sublabel,
            style: TextStyle(
              color: color.withOpacity(0.7),
              fontSize: 11,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error + Empty + Disclaimer
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String error;
  final bool isDark;
  const _ErrorView({required this.error, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bearDark.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.bearDark.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: AppColors.bearDark, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  error,
                  style: const TextStyle(
                    color: AppColors.bearDark,
                    fontSize: 12,
                    fontFamily: 'monospace',
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

class _EmptyView extends StatelessWidget {
  final String date;
  final bool isDark;
  final Color textSub;
  final Color borderColor;
  const _EmptyView({
    required this.date,
    required this.isDark,
    required this.textSub,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(20),
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1a1a1a)
                      : const Color(0xFFf0f0f0),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: Icon(
                  Icons.bar_chart_rounded,
                  size: 28,
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'NO BREAKOUTS',
                style: TextStyle(
                  color: textSub,
                  fontSize: 11,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                date,
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                  fontSize: 18,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'No index breakouts were detected\nby AI on this trading session.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textSub,
                  fontSize: 12,
                  fontFamily: 'monospace',
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 24),
              Container(height: 1, color: borderColor),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.access_time_rounded,
                      size: 12,
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted),
                  const SizedBox(width: 6),
                  Text(
                    'MARKET HOURS  9:15 AM – 3:30 PM IST',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted,
                      fontSize: 10,
                      fontFamily: 'monospace',
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Disclaimer extends StatelessWidget {
  final Color textMuted;
  const _Disclaimer({required this.textMuted});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(
        'DISCLAIMER: The AI breakout indices and related data are for informational '
        'and educational purposes only. They do not constitute financial, investment, '
        'or trading advice. Always conduct your own research.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: textMuted,
          fontSize: 10,
          fontFamily: 'monospace',
          height: 1.7,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
