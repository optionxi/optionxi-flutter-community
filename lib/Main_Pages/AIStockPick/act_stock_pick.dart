import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

Widget _emptyStateBtn({
  required IconData icon,
  required String label,
  required bool isDark,
  required Color borderColor,
  required Color textSecondary,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : const Color(0xFFF4F4F5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: textSecondary),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
                color: textSecondary,
              )),
        ],
      ),
    ),
  );
}

class _BarChartEmptyPainter extends CustomPainter {
  final bool isDark;
  _BarChartEmptyPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final barColor = isDark ? const Color(0xFF3F3F46) : const Color(0xFFD4D4D8);
    final paint = Paint()..color = barColor;

    final bars = [
      [20.0, 44.0, 6.0, 12.0],
      [30.0, 36.0, 6.0, 20.0],
      [40.0, 40.0, 6.0, 16.0],
      [50.0, 32.0, 6.0, 24.0],
    ];
    for (final b in bars) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(b[0], b[1], b[2], b[3]),
          const Radius.circular(2),
        ),
        paint,
      );
    }

    final dashPaint = Paint()
      ..color = barColor.withOpacity(0.5)
      ..strokeWidth = 1;
    double x = 14;
    while (x < 58) {
      canvas.drawLine(Offset(x, 28), Offset(x + 3, 28), dashPaint);
      x += 6;
    }

    final circlePaint = Paint()
      ..color = isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(const Offset(53, 22), 8, circlePaint);
    final crossPaint = Paint()
      ..color = isDark ? const Color(0xFF71717A) : const Color(0xFF71717A)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(50, 22), const Offset(56, 22), crossPaint);
    canvas.drawLine(const Offset(53, 19), const Offset(53, 25), crossPaint);
  }

  @override
  bool shouldRepaint(_BarChartEmptyPainter old) => old.isDark != isDark;
}
// ── Models ────────────────────────────────────────────────────────────────────

class StockEntry {
  final int id;
  final String symbol;
  final DateTime snapshotTime;
  final String? sentiment;
  final double? close;
  final double? pcnt;
  final int? screenerCount;
  final String? sector;

  StockEntry({
    required this.id,
    required this.symbol,
    required this.snapshotTime,
    this.sentiment,
    this.close,
    this.pcnt,
    this.screenerCount,
    this.sector,
  });

  factory StockEntry.fromMap(Map<String, dynamic> map) {
    return StockEntry(
      id: map['id'] as int,
      symbol: map['symbol'] as String,
      snapshotTime: DateTime.parse(map['snapshot_time'] as String).toLocal(),
      sentiment: map['sentiment'] as String?,
      close: (map['close'] as num?)?.toDouble(),
      pcnt: (map['pcnt'] as num?)?.toDouble(),
      screenerCount: map['screener_count'] as int?,
      sector: map['sector'] as String?,
    );
  }
}

class ChartPoint {
  final String time;
  final double close;
  final double dayPcnt;
  final double pcntSinceFirst;

  ChartPoint({
    required this.time,
    required this.close,
    required this.dayPcnt,
    required this.pcntSinceFirst,
  });
}

class GroupedStock {
  final String symbol;
  final String cleanSymbol;
  final String sector;
  final String sentiment;
  final DateTime firstSeenTime;
  final double startPrice;
  final double latestPrice;
  final double latestDayPcnt;
  final double netGain;
  final double netGainPcnt;
  final bool isSuccess;
  final List<ChartPoint> history;

  GroupedStock({
    required this.symbol,
    required this.cleanSymbol,
    required this.sector,
    required this.sentiment,
    required this.firstSeenTime,
    required this.startPrice,
    required this.latestPrice,
    required this.latestDayPcnt,
    required this.netGain,
    required this.netGainPcnt,
    required this.isSuccess,
    required this.history,
  });
}

class TimeGroup {
  final String time;
  final List<GroupedStock> stocks;
  TimeGroup(this.time, this.stocks);
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String extractSymbol(String raw) {
  return raw.replaceAll(RegExp(r'^(NSE|BSE):'), '').replaceAll('-EQ', '');
}

DateTime getTodayIST() {
  final now = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
  return DateTime(now.year, now.month, now.day);
}

String formatIST(DateTime utc) {
  final ist = utc.toUtc().add(const Duration(hours: 5, minutes: 30));
  final h = ist.hour > 12 ? ist.hour - 12 : (ist.hour == 0 ? 12 : ist.hour);
  final period = ist.hour >= 12 ? 'PM' : 'AM';
  final m = ist.minute.toString().padLeft(2, '0');
  return '$h:$m $period';
}

String formatDateHeader(DateTime date) {
  final today = getTodayIST();
  if (date.year == today.year &&
      date.month == today.month &&
      date.day == today.day) {
    return 'Today';
  }
  return DateFormat('EEE, d MMM yyyy').format(date);
}

String formatINR(double value) {
  final formatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );
  return formatter.format(value);
}

// ── Main Page ─────────────────────────────────────────────────────────────────

class AIPickedStocksPage extends StatefulWidget {
  const AIPickedStocksPage({super.key});

  @override
  State<AIPickedStocksPage> createState() => _AIPickedStocksPageState();
}

class _AIPickedStocksPageState extends State<AIPickedStocksPage> {
  final _supabase = Supabase.instance.client;

  DateTime _selectedDate = getTodayIST();
  List<StockEntry> _entries = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchEntries(_selectedDate);
  }

  Future<void> _fetchEntries(DateTime date) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Create UTC bounds for the chosen IST day
      final start = DateTime.utc(
          date.year, date.month, date.day, 3, 55); // 9:25 AM IST = 3:55 UTC
      final end = DateTime.utc(
          date.year, date.month, date.day, 10, 5); // 3:35 PM IST = 10:05 UTC

      final response = await _supabase
          .from('ai_picked_stocks')
          .select('*')
          .gte('snapshot_time', start)
          .lte('snapshot_time', end)
          .order('snapshot_time', ascending: false);

      final entries = (response as List)
          .map((e) => StockEntry.fromMap(e as Map<String, dynamic>))
          .toList();

      setState(() {
        _entries = entries;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _entries = [];
        _loading = false;
      });
    }
  }

  void _adjustDay(int days) {
    final newDate = _selectedDate.add(Duration(days: days));
    final today = getTodayIST();
    if (newDate.isAfter(today)) return;
    setState(() => _selectedDate = newDate);
    _fetchEntries(newDate);
  }

  Future<void> _pickDate() async {
    final today = getTodayIST();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024, 1, 1),
      lastDate: today,
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _fetchEntries(picked);
    }
  }

  bool get _isMarketClosed {
    final today = getTodayIST();
    if (_selectedDate.compareTo(today) < 0) return true;
    if (_selectedDate == today) {
      final now =
          DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
      return now.hour > 15 || (now.hour == 15 && now.minute >= 30);
    }
    return false;
  }

  List<TimeGroup> get _groupedTimeline {
    if (_entries.isEmpty) return [];

    final symbolMap = <String, List<StockEntry>>{};
    for (final e in _entries) {
      symbolMap.putIfAbsent(e.symbol, () => []).add(e);
    }

    final uniqueStocks = symbolMap.values.map((entries) {
      entries.sort((a, b) => a.snapshotTime.compareTo(b.snapshotTime));
      final first = entries.first;
      final last = entries.last;

      final startPrice = first.close ?? 0;
      final latestPrice = last.close ?? 0;
      final netGain = latestPrice - startPrice;
      final netGainPcnt = startPrice > 0 ? (netGain / startPrice) * 100 : 0.0;
      final sentiment = first.sentiment ?? 'BULLISH';
      final isSuccess =
          sentiment.toUpperCase() == 'BEARISH' ? netGain <= 0 : netGain > 0;

      final history = entries.map((e) {
        final c = e.close ?? 0.0;
        final diff = c - startPrice;
        final pcntSinceFirst = startPrice > 0 ? (diff / startPrice) * 100 : 0.0;
        return ChartPoint(
          time: formatIST(e.snapshotTime),
          close: c,
          dayPcnt: e.pcnt ?? 0,
          pcntSinceFirst: pcntSinceFirst,
        );
      }).toList();

      return GroupedStock(
        symbol: first.symbol,
        cleanSymbol: extractSymbol(first.symbol),
        sector: first.sector ?? 'General',
        sentiment: sentiment,
        firstSeenTime: first.snapshotTime,
        startPrice: startPrice,
        latestPrice: latestPrice,
        latestDayPcnt: last.pcnt ?? 0,
        netGain: netGain,
        netGainPcnt: netGainPcnt.toDouble(),
        isSuccess: isSuccess,
        history: history,
      );
    }).toList();

    final timeGroupMap = <String, List<GroupedStock>>{};
    for (final stock in uniqueStocks) {
      final key = formatIST(stock.firstSeenTime);
      timeGroupMap.putIfAbsent(key, () => []).add(stock);
    }

    final sorted = timeGroupMap.entries.toList()
      ..sort((a, b) =>
          b.value[0].firstSeenTime.compareTo(a.value[0].firstSeenTime));

    return sorted.map((e) {
      final stocks = e.value
        ..sort((a, b) => b.latestDayPcnt.compareTo(a.latestDayPcnt));
      return TimeGroup(e.key, stocks);
    }).toList();
  }

  Map<String, dynamic>? get _analytics {
    final groups = _groupedTimeline;
    if (groups.isEmpty) return null;

    int total = 0;
    double sumGain = 0;
    int success = 0;

    for (final g in groups) {
      for (final s in g.stocks) {
        total++;
        sumGain += s.netGainPcnt;
        if (s.isSuccess) success++;
      }
    }

    return {
      'totalStocks': total,
      'avgGrabbed': total > 0 ? sumGain / total : 0.0,
      'accuracyRate': total > 0 ? (success / total) * 100 : 0.0,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F5);
    final cardBg = isDark ? const Color(0xFF111113) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7);
    final textPrimary =
        isDark ? const Color(0xFFF4F4F5) : const Color(0xFF18181B);
    final textSecondary =
        isDark ? const Color(0xFF71717A) : const Color(0xFF71717A);

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            _buildHeader(
                isDark, cardBg, borderColor, textPrimary, textSecondary),

            // ── Content ──────────────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? buildSkeletonStockPick(isDark, cardBg, borderColor)
                  : _error != null
                      ? _buildError(isDark, cardBg, borderColor, textPrimary,
                          textSecondary)
                      : _buildContent(isDark, cardBg, borderColor, textPrimary,
                          textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(bool isDark, Color cardBg, Color borderColor,
      Color textPrimary, Color textSecondary) {
    final today = getTodayIST();
    final isToday = _selectedDate.isAtSameMomentAs(today);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      child: Column(
        children: [
          // Back + Title + History row
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 12, 4),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: isDark
                        ? const Color(0xFFA1A1AA)
                        : const Color(0xFF52525B),
                  ),
                  splashRadius: 20,
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stock Breakouts',
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
                // History / Analysis button
                _headerActionBtn(
                  icon: Icons.assessment_outlined,
                  isDark: isDark,
                  onTap: () {
                    Get.toNamed('/backtest/ai-picks');
                  },
                ),
              ],
            ),
          ),

          // Date Navigator
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF18181B) : const Color(0xFFF4F4F5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  _navArrowBtn(
                    icon: Icons.chevron_left_rounded,
                    onTap: () => _adjustDay(-1),
                    isDark: isDark,
                    disabled: false,
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        color: Colors.transparent,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              formatDateHeader(_selectedDate),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'monospace',
                                color: isDark
                                    ? const Color(0xFFF4F4F5)
                                    : const Color(0xFF18181B),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 13,
                              color: isDark
                                  ? const Color(0xFF71717A)
                                  : const Color(0xFF71717A),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _navArrowBtn(
                    icon: Icons.chevron_right_rounded,
                    onTap: isToday ? null : () => _adjustDay(1),
                    isDark: isDark,
                    disabled: isToday,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerActionBtn({
    required IconData icon,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        margin: const EdgeInsets.only(left: 4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF18181B) : const Color(0xFFF4F4F5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF52525B),
        ),
      ),
    );
  }

  Widget _navArrowBtn({
    required IconData icon,
    required VoidCallback? onTap,
    required bool isDark,
    required bool disabled,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        color: Colors.transparent,
        child: Icon(
          icon,
          size: 20,
          color: disabled
              ? (isDark ? const Color(0xFF3F3F46) : const Color(0xFFD4D4D8))
              : (isDark ? const Color(0xFFA1A1AA) : const Color(0xFF52525B)),
        ),
      ),
    );
  }
  // ── Skeleton ───────────────────────────────────────────────────────────────

  // ── Error ──────────────────────────────────────────────────────────────────

  Widget _buildError(bool isDark, Color cardBg, Color borderColor,
      Color textPrimary, Color textSecondary) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  color: Color(0xFFEF4444), size: 26),
            ),
            const SizedBox(height: 16),
            Text('Failed to load picks',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                  fontFamily: 'monospace',
                )),
            const SizedBox(height: 8),
            Text(_error ?? '',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                  fontFamily: 'monospace',
                )),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => _fetchEntries(_selectedDate),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFF6366F1).withOpacity(0.3)),
                ),
                child: const Text('Retry',
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6366F1),
                    )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Content ────────────────────────────────────────────────────────────────

  Widget _buildContent(bool isDark, Color cardBg, Color borderColor,
      Color textPrimary, Color textSecondary) {
    final analytics = _analytics;
    final groups = _groupedTimeline;

    if (groups.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF18181B)
                      : const Color(0xFFF4F4F5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child:
                    CustomPaint(painter: _BarChartEmptyPainter(isDark: isDark)),
              ),
              const SizedBox(height: 24),
              Text(
                'No picks this session',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                  color: textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'The AI scanned the market but found no breakout candidates worth flagging today.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: textSecondary,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _emptyStateBtn(
                    icon: Icons.calendar_today_rounded,
                    label: 'Go to today',
                    isDark: isDark,
                    borderColor: borderColor,
                    textSecondary: textSecondary,
                    onTap: () {
                      setState(() => _selectedDate = getTodayIST());
                      _fetchEntries(getTodayIST());
                    },
                  ),
                  const SizedBox(width: 10),
                  _emptyStateBtn(
                    icon: Icons.refresh_rounded,
                    label: 'Retry',
                    isDark: isDark,
                    borderColor: borderColor,
                    textSecondary: textSecondary,
                    onTap: () => _fetchEntries(_selectedDate),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                'Markets are only scanned on weekdays\nbetween 9:25 AM – 3:30 PM IST',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontFamily: 'monospace',
                  color: isDark
                      ? const Color(0xFF3F3F46)
                      : const Color(0xFFD4D4D8),
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Analytics grid
        if (analytics != null) ...[
          _buildAnalyticsGrid(analytics, isDark, cardBg, borderColor,
              textPrimary, textSecondary),
          const SizedBox(height: 20),
        ],

        // Timeline
        ...groups.asMap().entries.map((entry) {
          final idx = entry.key;
          final group = entry.value;
          return _buildTimeGroup(group, idx, isDark, cardBg, borderColor,
              textPrimary, textSecondary);
        }),

        // Disclaimer
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'Disclaimer: AI-picked stocks are for informational and educational purposes only. They do not constitute financial or investment advice. Always conduct your own research before making investment decisions.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 9,
                color: textSecondary,
                fontFamily: 'monospace',
                height: 1.6),
          ),
        ),
      ],
    );
  }

  // ── Analytics Grid ─────────────────────────────────────────────────────────

  Widget _buildAnalyticsGrid(Map<String, dynamic> a, bool isDark, Color cardBg,
      Color borderColor, Color textPrimary, Color textSecondary) {
    final avg = (a['avgGrabbed'] as double);
    final acc = (a['accuracyRate'] as double);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: _analyticsCard(
              label: 'Total Picks',
              value: '${a['totalStocks']}',
              valueColor: textPrimary,
              isDark: isDark,
              cardBg: cardBg,
              borderColor: borderColor,
              textSecondary: textSecondary,
            )),
            const SizedBox(width: 10),
            Expanded(
                child: _analyticsCard(
              label: 'Avg Gain Grabbed',
              value: '${avg >= 0 ? '+' : ''}${avg.toStringAsFixed(2)}%',
              valueColor:
                  avg >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              isDark: isDark,
              cardBg: cardBg,
              borderColor: borderColor,
              textSecondary: textSecondary,
            )),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: _analyticsCard(
              label: 'Accuracy Rate',
              value: '${acc.toStringAsFixed(1)}%',
              valueColor:
                  acc >= 50 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              isDark: isDark,
              cardBg: cardBg,
              borderColor: borderColor,
              textSecondary: textSecondary,
            )),
            const SizedBox(width: 10),
            Expanded(
                child: _marketStatusCard(
                    isDark, cardBg, borderColor, textSecondary)),
          ],
        ),
      ],
    );
  }

  Widget _analyticsCard({
    required String label,
    required String value,
    required Color valueColor,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required Color textSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: TextStyle(
                fontSize: 9,
                letterSpacing: 1.2,
                color: textSecondary,
                fontFamily: 'monospace',
              )),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: valueColor,
                fontFamily: 'monospace',
              )),
        ],
      ),
    );
  }

  Widget _marketStatusCard(
      bool isDark, Color cardBg, Color borderColor, Color textSecondary) {
    final closed = _isMarketClosed;
    final dotColor = closed ? const Color(0xFF71717A) : const Color(0xFF10B981);
    final textColor = closed
        ? (isDark ? const Color(0xFFA1A1AA) : const Color(0xFF52525B))
        : const Color(0xFF10B981);
    final bgColor = closed
        ? (isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5))
        : const Color(0xFF10B981).withOpacity(0.1);
    final borderC = closed
        ? (isDark ? const Color(0xFF3F3F46) : const Color(0xFFD4D4D8))
        : const Color(0xFF10B981).withOpacity(0.3);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('MARKET STATUS',
              style: TextStyle(
                fontSize: 9,
                letterSpacing: 1.2,
                color: textSecondary,
                fontFamily: 'monospace',
              )),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: borderC),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration:
                      BoxDecoration(color: dotColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(
                  closed ? 'CLOSED' : 'LIVE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    fontFamily: 'monospace',
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Timeline Group ─────────────────────────────────────────────────────────

  Widget _buildTimeGroup(TimeGroup group, int idx, bool isDark, Color cardBg,
      Color borderColor, Color textPrimary, Color textSecondary) {
    final isFirst = idx == 0;
    final timelineLineColor =
        isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: IntrinsicHeight(
        // ← wrap with IntrinsicHeight
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline indicator
            Column(
              children: [
                const SizedBox(height: 2),
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0A0A0A)
                        : const Color(0xFFF5F5F5),
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: const Color(0xFF6366F1), width: 2),
                  ),
                  child: isFirst && !_isMarketClosed
                      ? Center(
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                                color: Color(0xFF6366F1),
                                shape: BoxShape.circle),
                          ),
                        )
                      : null,
                ),
                Expanded(
                  // ← Expanded, not fixed infinity
                  child: Container(
                    width: 1,
                    color: timelineLineColor,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF18181B)
                              : const Color(0xFFF4F4F5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderColor),
                        ),
                        child: Text(group.time,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'monospace',
                              color: textPrimary,
                            )),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${group.stocks.length} pick${group.stocks.length != 1 ? 's' : ''}',
                        style: TextStyle(
                            fontSize: 11,
                            color: textSecondary,
                            fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Stock cards
                  ...group.stocks.map((stock) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildStockCard(stock, isDark, cardBg,
                            borderColor, textPrimary, textSecondary),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  // ── Stock Card ─────────────────────────────────────────────────────────────

  Widget _buildStockCard(GroupedStock stock, bool isDark, Color cardBg,
      Color borderColor, Color textPrimary, Color textSecondary) {
    final gainColor =
        stock.netGain >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed(
          '/stocks/${stock.symbol}',
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top info
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Symbol row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(stock.cleanSymbol,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'monospace',
                                  color: textPrimary,
                                  letterSpacing: -0.3,
                                )),
                            const SizedBox(height: 2),
                            Text(stock.sector.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 9,
                                  letterSpacing: 1.2,
                                  color: textSecondary,
                                  fontFamily: 'monospace',
                                )),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          _sentimentBadge(stock.sentiment),
                          if (_isMarketClosed) ...[
                            const SizedBox(width: 6),
                            _outcomeChip(stock.isSuccess),
                          ],
                        ],
                      ),
                    ],
                  ),

                  // After-pick badge
                  if (stock.history.length > 1) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: gainColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${stock.netGainPcnt >= 0 ? '▲' : '▼'} ${stock.netGainPcnt.abs().toStringAsFixed(2)}% AFTER PICK',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'monospace',
                          color: gainColor,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Price row
                  Row(
                    children: [
                      Expanded(
                          child: _priceCell(
                        label: 'Pick Price',
                        value: formatINR(stock.startPrice),
                        valueColor: textPrimary,
                        textSecondary: textSecondary,
                      )),
                      Expanded(
                          child: _priceCell(
                        label: 'Current',
                        value: formatINR(stock.latestPrice),
                        valueColor: textPrimary,
                        textSecondary: textSecondary,
                        badge:
                            '${stock.latestDayPcnt >= 0 ? '▲' : '▼'} ${stock.latestDayPcnt.abs().toStringAsFixed(2)}%',
                        badgeColor: stock.latestDayPcnt >= 0
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                      )),
                    ],
                  ),
                ],
              ),
            ),

            // Chart
            _buildChart(stock, isDark, borderColor),
          ],
        ),
      ),
    );
  }

  Widget _priceCell({
    required String label,
    required String value,
    required Color valueColor,
    required Color textSecondary,
    String? badge,
    Color? badgeColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              letterSpacing: 1.2,
              color: textSecondary,
              fontFamily: 'monospace',
            )),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace',
                  color: valueColor,
                )),
            if (badge != null && badgeColor != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(badge,
                    style: TextStyle(
                      fontSize: 9,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w700,
                      color: badgeColor,
                    )),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildChart(GroupedStock stock, bool isDark, Color borderColor) {
    final lineColor =
        stock.netGain >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final chartBg = isDark ? const Color(0xFF0A0A0C) : const Color(0xFFFAFAFA);

    if (stock.history.length <= 1) {
      return Container(
        height: 120,
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        decoration: BoxDecoration(
          color: chartBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, style: BorderStyle.solid),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _isMarketClosed
                      ? (stock.isSuccess
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444))
                      : const Color(0xFF6366F1),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _isMarketClosed
                    ? (stock.isSuccess
                        ? 'Prediction Success'
                        : 'Prediction Failed')
                    : 'Tracking Started',
                style: TextStyle(
                  fontSize: 10,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFF71717A)
                      : const Color(0xFF71717A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _isMarketClosed
                    ? 'Market closed before more data could be charted.'
                    : 'Awaiting more data points',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  fontFamily: 'monospace',
                  color: isDark
                      ? const Color(0xFF52525B)
                      : const Color(0xFFA1A1AA),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final gridColor =
        isDark ? const Color(0xFF1C1C1F) : const Color(0xFFE4E4E7);
    final labelColor = const Color(0xFF71717A);

    return SizedBox(
      height: 160,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 14, 14),
        child: SfCartesianChart(
          backgroundColor: chartBg,
          plotAreaBorderWidth: 0,
          margin: const EdgeInsets.fromLTRB(14, 8, 0, 0),
          primaryXAxis: CategoryAxis(
            labelStyle: TextStyle(
                fontSize: 9, color: labelColor, fontFamily: 'monospace'),
            axisLine: AxisLine(color: gridColor),
            majorGridLines: MajorGridLines(width: 0),
            majorTickLines: const MajorTickLines(size: 0),
            labelPlacement: LabelPlacement.onTicks,
            desiredIntervals: 4,
            edgeLabelPlacement: EdgeLabelPlacement.shift,
          ),
          primaryYAxis: NumericAxis(
            labelStyle: TextStyle(
                fontSize: 9, color: labelColor, fontFamily: 'monospace'),
            axisLine: AxisLine(color: gridColor),
            majorGridLines: MajorGridLines(
                width: 1, color: gridColor, dashArray: const [3, 3]),
            majorTickLines: const MajorTickLines(size: 0),
            numberFormat: NumberFormat.currency(
                locale: 'en_IN', symbol: '₹', decimalDigits: 0),
            desiredIntervals: 3,
          ),
          tooltipBehavior: TooltipBehavior(
            enable: true,
            color: isDark ? const Color(0xFF27272A) : Colors.white,
            textStyle: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: isDark ? Colors.white : Colors.black87),
            builder: (data, point, series, pointIndex, seriesIndex) {
              final d = data as ChartPoint;
              final dayC = d.dayPcnt >= 0
                  ? const Color(0xFF10B981)
                  : const Color(0xFFEF4444);
              final sinceC = d.pcntSinceFirst >= 0
                  ? const Color(0xFF10B981)
                  : const Color(0xFFEF4444);
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF18181B) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: isDark
                          ? const Color(0xFF3F3F46)
                          : const Color(0xFFE4E4E7)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.15), blurRadius: 8)
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(d.time,
                        style: TextStyle(
                            fontSize: 10,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w700,
                            color: labelColor)),
                    const SizedBox(height: 6),
                    Text(formatINR(d.close),
                        style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87)),
                    const SizedBox(height: 2),
                    Text(
                      '${d.dayPcnt >= 0 ? '+' : ''}${d.dayPcnt.toStringAsFixed(2)}% day',
                      style: TextStyle(
                          fontSize: 10, fontFamily: 'monospace', color: dayC),
                    ),
                    Text(
                      '${d.pcntSinceFirst >= 0 ? '+' : ''}${d.pcntSinceFirst.toStringAsFixed(2)}% since pick',
                      style: TextStyle(
                          fontSize: 10,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w700,
                          color: sinceC),
                    ),
                  ],
                ),
              );
            },
          ),
          series: <CartesianSeries>[
            AreaSeries<ChartPoint, String>(
              dataSource: stock.history,
              xValueMapper: (d, _) => d.time,
              yValueMapper: (d, _) => d.close,
              color: lineColor.withOpacity(0.15),
              borderColor: lineColor,
              borderWidth: 2,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  lineColor.withOpacity(0.25),
                  lineColor.withOpacity(0.0)
                ],
              ),
              animationDuration: 0,
              markerSettings: MarkerSettings(
                isVisible: false,
                color: lineColor,
                borderColor: Colors.white,
                borderWidth: 2,
                height: 6,
                width: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Badges ─────────────────────────────────────────────────────────────────

  Widget _sentimentBadge(String sentiment) {
    final s = sentiment.toUpperCase();
    Color bg, text, border;
    if (s == 'BULLISH') {
      bg = const Color(0xFF6366F1).withOpacity(0.1);
      text = const Color(0xFF6366F1);
      border = const Color(0xFF6366F1).withOpacity(0.3);
    } else if (s == 'BEARISH') {
      bg = const Color(0xFFF97316).withOpacity(0.1);
      text = const Color(0xFFF97316);
      border = const Color(0xFFF97316).withOpacity(0.3);
    } else {
      bg = const Color(0xFF71717A).withOpacity(0.1);
      text = const Color(0xFF71717A);
      border = const Color(0xFF71717A).withOpacity(0.3);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: border)),
      child: Text(s,
          style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              color: text,
              fontFamily: 'monospace')),
    );
  }

  Widget _outcomeChip(bool success) {
    final color = success ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        success ? 'SUCCESS' : 'FAILED',
        style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
            color: color,
            fontFamily: 'monospace'),
      ),
    );
  }
}

// ── Shimmer box with wave animation ───────────────────────────────────────
class _ShimmerBox extends StatefulWidget {
  final double height;
  final double radius;
  final Color? bg;
  final Color? border;
  final bool isDark;

  const _ShimmerBox({
    required this.height,
    required this.radius,
    this.bg,
    this.border,
    required this.isDark,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _anim = Tween<double>(begin: -1.5, end: 1.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.bg ??
        (widget.isDark ? const Color(0xFF1C1C1F) : const Color(0xFFE4E4E7));
    final shine =
        widget.isDark ? const Color(0xFF2A2A2F) : const Color(0xFFF0F0F2);

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          border:
              widget.border != null ? Border.all(color: widget.border!) : null,
          gradient: LinearGradient(
            begin: Alignment(_anim.value - 1, 0),
            end: Alignment(_anim.value + 1, 0),
            colors: [base, shine, base],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }
}

// ── Pulsing dot ────────────────────────────────────────────────────────────

class _PulsingDot extends StatefulWidget {
  final Duration delay;
  final Color color;

  const _PulsingDot({
    required this.delay,
    this.color = const Color(0xFF6366F1),
  });

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
    _anim = Tween<double>(begin: 1.0, end: 0.3).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
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
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Container(
          width: 6,
          height: 6,
          decoration:
              BoxDecoration(color: widget.color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

// ── Animated chart line ────────────────────────────────────────────────────

class _AnimatedChartLine extends StatefulWidget {
  const _AnimatedChartLine();

  @override
  State<_AnimatedChartLine> createState() => _AnimatedChartLineState();
}

class _AnimatedChartLineState extends State<_AnimatedChartLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();
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
      builder: (_, __) => CustomPaint(
        painter: _ChartLinePainter(progress: _anim.value),
      ),
    );
  }
}

class _ChartLinePainter extends CustomPainter {
  final double progress;
  _ChartLinePainter({required this.progress});

  static const _points = [
    Offset(0.0, 0.75),
    Offset(0.12, 0.62),
    Offset(0.25, 0.50),
    Offset(0.38, 0.42),
    Offset(0.52, 0.33),
    Offset(0.65, 0.38),
    Offset(0.78, 0.25),
    Offset(0.90, 0.28),
    Offset(1.0, 0.20),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // Grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFF1C1C1F)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    final dashPath = Path();
    for (final frac in [0.33, 0.66]) {
      dashPath.moveTo(0, size.height * frac);
      dashPath.lineTo(size.width, size.height * frac);
    }
    canvas.drawPath(dashPath, gridPaint);

    final pts = _points
        .map((p) => Offset(p.dx * size.width, p.dy * size.height))
        .toList();

    // Draw only up to `progress` fraction of the path
    final totalPts = pts.length;
    final drawCount = (totalPts * progress).clamp(1.0, totalPts.toDouble());
    final fullIdx = drawCount.floor();
    final partial = drawCount - fullIdx;

    final drawPts = [
      ...pts.take(fullIdx),
      if (fullIdx < totalPts - 1)
        Offset.lerp(pts[fullIdx], pts[fullIdx + 1], partial)!,
    ];

    // Area fill
    if (drawPts.length > 1) {
      final fillPath = Path()..moveTo(drawPts.first.dx, drawPts.first.dy);
      for (final pt in drawPts.skip(1)) {
        fillPath.lineTo(pt.dx, pt.dy);
      }
      fillPath.lineTo(drawPts.last.dx, size.height);
      fillPath.lineTo(drawPts.first.dx, size.height);
      fillPath.close();

      canvas.drawPath(
        fillPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF6366F1).withOpacity(0.25 * progress),
              const Color(0xFF6366F1).withOpacity(0),
            ],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
      );
    }

    // Line
    if (drawPts.length > 1) {
      final linePath = Path()..moveTo(drawPts.first.dx, drawPts.first.dy);
      for (final pt in drawPts.skip(1)) {
        linePath.lineTo(pt.dx, pt.dy);
      }
      canvas.drawPath(
        linePath,
        Paint()
          ..color = const Color(0xFF6366F1).withOpacity(0.5)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(_ChartLinePainter old) => old.progress != progress;
}

// ── Animated ticker ────────────────────────────────────────────────────────

class _AnimatedTicker extends StatefulWidget {
  final bool isDark;
  final Color dotG;
  final Color dotR;

  const _AnimatedTicker(
      {required this.isDark, required this.dotG, required this.dotR});

  @override
  State<_AnimatedTicker> createState() => _AnimatedTickerState();
}

class _AnimatedTickerState extends State<_AnimatedTicker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shimBase =
        widget.isDark ? const Color(0xFF1C1C1F) : const Color(0xFFE4E4E7);
    final items = List.generate(8, (i) {
      final isGreen = i.isEven;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: isGreen ? widget.dotG : widget.dotR,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Container(
              width: 44,
              height: 10,
              decoration: BoxDecoration(
                color: shimBase,
                borderRadius: BorderRadius.circular(3),
              )),
          const SizedBox(width: 6),
          Container(
              width: 32,
              height: 9,
              decoration: BoxDecoration(
                color: shimBase,
                borderRadius: BorderRadius.circular(3),
              )),
          const SizedBox(width: 20),
        ],
      );
    });

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return ClipRect(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Transform.translate(
              offset: Offset(-_ctrl.value * 300, 0),
              child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [...items, ...items]),
            ),
          ),
        );
      },
    );
  }
}

Widget buildSkeletonStockPick(bool isDark, Color cardBg, Color borderColor) {
  return ListView(
    padding: const EdgeInsets.all(16),
    children: [
      // "Scanning..." label
      _buildScanningLabel(isDark),
      const SizedBox(height: 14),

      // Analytics grid
      Row(children: [
        Expanded(child: _skeletonCard(isDark, cardBg, borderColor, height: 72)),
        const SizedBox(width: 10),
        Expanded(child: _skeletonCard(isDark, cardBg, borderColor, height: 72)),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _skeletonCard(isDark, cardBg, borderColor, height: 72)),
        const SizedBox(width: 10),
        Expanded(child: _skeletonCard(isDark, cardBg, borderColor, height: 72)),
      ]),
      const SizedBox(height: 24),

      // Timeline skeleton cards
      _buildTimelineSkeletonGroup(isDark, cardBg, borderColor, isFirst: true),
      const SizedBox(height: 20),
      _buildTimelineSkeletonGroup(isDark, cardBg, borderColor, isFirst: false),
      const SizedBox(height: 20),
      _buildTimelineSkeletonGroup(isDark, cardBg, borderColor, isFirst: false),
    ],
  );
}

Widget _buildScanningLabel(bool isDark) {
  return Row(
    children: [
      ...List.generate(
          3,
          (i) => Padding(
                padding: const EdgeInsets.only(right: 4),
                child: _PulsingDot(delay: Duration(milliseconds: i * 200)),
              )),
      const SizedBox(width: 4),
      Text(
        'SCANNING BREAKOUTS',
        style: TextStyle(
          fontSize: 10,
          letterSpacing: 1.4,
          fontFamily: 'monospace',
          color: isDark ? const Color(0xFF52525B) : const Color(0xFF71717A),
        ),
      ),
    ],
  );
}

// ── Timeline skeleton group ────────────────────────────────────────────────

Widget _buildTimelineSkeletonGroup(bool isDark, Color cardBg, Color borderColor,
    {required bool isFirst}) {
  final lineColor = isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7);
  final accentBorder = const Color(0xFF6366F1).withOpacity(0.3);

  return IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(children: [
          const SizedBox(height: 2),
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F5),
              border: Border.all(
                color: isFirst ? accentBorder : lineColor,
                width: 2,
              ),
            ),
            child: isFirst
                ? Center(
                    child: _PulsingDot(
                    delay: Duration.zero,
                    color: const Color(0xFF6366F1),
                  ))
                : null,
          ),
          Expanded(child: Container(width: 1, color: lineColor)),
        ]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                _shimmerBox(isDark,
                    width: 90,
                    height: 30,
                    radius: 8,
                    bg: isDark
                        ? const Color(0xFF18181B)
                        : const Color(0xFFF4F4F5),
                    border: borderColor),
                const SizedBox(width: 8),
                _shimmerBox(isDark, width: 48, height: 10),
              ]),
              const SizedBox(height: 10),
              _buildStockCardSkeleton(isDark, cardBg, borderColor,
                  showGain: isFirst),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildStockCardSkeleton(bool isDark, Color cardBg, Color borderColor,
    {bool showGain = false}) {
  return Container(
    decoration: BoxDecoration(
      color: cardBg,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: borderColor),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _shimmerBox(isDark, width: 80, height: 18),
                        const SizedBox(height: 5),
                        _shimmerBox(isDark, width: 55, height: 8),
                      ],
                    ),
                  ),
                  _shimmerBox(isDark,
                      width: 60,
                      height: 22,
                      radius: 5,
                      bg: isDark
                          ? const Color(0xFF18181B)
                          : const Color(0xFFF4F4F5),
                      border: borderColor),
                ],
              ),
              if (showGain) ...[
                const SizedBox(height: 10),
                _shimmerBox(isDark,
                    width: 140,
                    height: 26,
                    radius: 6,
                    bg: const Color(0xFF10B981).withOpacity(0.08)),
              ],
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _shimmerBox(isDark,
                        width: double.infinity, height: 8, widthFraction: 0.5),
                    const SizedBox(height: 6),
                    _shimmerBox(isDark,
                        width: double.infinity, height: 14, widthFraction: 0.8),
                  ],
                )),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _shimmerBox(isDark,
                        width: double.infinity, height: 8, widthFraction: 0.5),
                    const SizedBox(height: 6),
                    _shimmerBox(isDark,
                        width: double.infinity, height: 14, widthFraction: 0.8),
                  ],
                )),
              ]),
            ],
          ),
        ),
        _buildChartSkeleton(isDark),
      ],
    ),
  );
}

Widget _buildChartSkeleton(bool isDark) {
  final bg = isDark ? const Color(0xFF0A0A0C) : const Color(0xFFFAFAFA);
  return Container(
    height: 140,
    decoration: BoxDecoration(
      color: bg,
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(16),
        bottomRight: Radius.circular(16),
      ),
    ),
    child: const _AnimatedChartLine(),
  );
}

// ── Shimmer helper ─────────────────────────────────────────────────────────

Widget _shimmerBox(
  bool isDark, {
  double? width,
  required double height,
  double radius = 6,
  Color? bg,
  Color? border,
  double? widthFraction,
}) {
  Widget box = _ShimmerBox(
    height: height,
    radius: radius,
    bg: bg,
    border: border,
    isDark: isDark,
  );
  if (widthFraction != null) {
    box = FractionallySizedBox(widthFactor: widthFraction, child: box);
  } else if (width != null && width != double.infinity) {
    box = SizedBox(width: width, child: box);
  }
  return box;
}

Widget _skeletonCard(bool isDark, Color cardBg, Color borderColor,
    {required double height}) {
  return Container(
    height: height,
    decoration: BoxDecoration(
      color: cardBg,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: borderColor),
    ),
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _shimmerBox(isDark, width: 70, height: 8),
        const SizedBox(height: 10),
        _shimmerBox(isDark, width: 50, height: 22),
      ],
    ),
  );
}
