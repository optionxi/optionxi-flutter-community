import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  AI PICKED STOCKS — REDESIGN
//  Design direction: warm paper / editorial fintech. No gradients, no neon.
//  Solid ink, one calm green accent, terracotta for downside. Every number
//  is paired with a plain-English sentence, and every jargon term opens an
//  educational dialog box. Built for learning, not for hype.
// ═══════════════════════════════════════════════════════════════════════════

class Theme {
  final bool isDark;
  Theme(this.isDark);

  // ── Solid brand colors (no gradients anywhere in this file) ──
  static const ink = Color(0xFF181713);
  static const paper = Color(0xFFF7F6F2);
  static const green = Color(0xFF0E7A5F); // "going up / good"
  static const red = Color(0xFFC2432F); // "going down / bad"
  static const gold = Color(0xFF9A7B2D); // neutral highlight
  static const blue = Color(0xFF2B5CE6); // interactive accent

  Color get bg => isDark ? const Color(0xFF111110) : paper;
  Color get surface => isDark ? const Color(0xFF1B1B19) : Colors.white;
  Color get surfaceSunken =>
      isDark ? const Color(0xFF151514) : const Color(0xFFF0EEE8);
  Color get line => isDark ? const Color(0xFF2B2B28) : const Color(0xFFE6E3D9);
  Color get lineSoft =>
      isDark ? const Color(0xFF232320) : const Color(0xFFEFEDE5);

  Color get text => isDark ? const Color(0xFFF2F1EB) : ink;
  Color get muted => isDark ? const Color(0xFF9C998E) : const Color(0xFF6E6A5D);
  Color get faint => isDark ? const Color(0xFF5C594F) : const Color(0xFFADA99B);

  Color get up => green;
  Color get down => red;
}

// ─────────────────────────────────────────────────────────────────────────
//  EDUCATIONAL DIALOG BOX
//  One reusable dialog used for EVERY explanation on the screen.
//  Always: what it means → why it matters → a real-world style example.
// ─────────────────────────────────────────────────────────────────────────

class ExplainDialog extends StatelessWidget {
  final Theme t;
  final IconData icon;
  final String title;
  final String plain; // one sentence, zero jargon
  final String? detail; // optional deeper explanation
  final String? example; // optional "real example" box
  final Color? accent;

  const ExplainDialog({
    super.key,
    required this.t,
    required this.icon,
    required this.title,
    required this.plain,
    this.detail,
    this.example,
    this.accent,
  });

  static Future<void> show(BuildContext context, Theme t,
      {required IconData icon,
      required String title,
      required String plain,
      String? detail,
      String? example,
      Color? accent}) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (_) => ExplainDialog(
        t: t,
        icon: icon,
        title: title,
        plain: plain,
        detail: detail,
        example: example,
        accent: accent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = accent ?? Theme.blue;
    return Dialog(
      backgroundColor: t.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: a.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, size: 20, color: a),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: t.text,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: t.surfaceSunken,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close_rounded, size: 15, color: t.muted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // "In plain words" — the sentence a friend would say.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: a.withOpacity(0.07),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: a.withOpacity(0.18)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.format_quote_rounded, size: 15, color: a),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      plain,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.55,
                        fontWeight: FontWeight.w600,
                        color: t.text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (detail != null) ...[
              const SizedBox(height: 12),
              Text(
                detail!,
                style: TextStyle(fontSize: 12.5, height: 1.65, color: t.muted),
              ),
            ],
            if (example != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: t.surfaceSunken,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline_rounded,
                            size: 13, color: Theme.gold),
                        const SizedBox(width: 5),
                        Text('REAL EXAMPLE',
                            style: TextStyle(
                                fontSize: 9.5,
                                letterSpacing: 1,
                                fontWeight: FontWeight.w800,
                                color: Theme.gold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(example!,
                        style: TextStyle(
                            fontSize: 12, height: 1.6, color: t.muted)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: t.text,
                  foregroundColor: t.bg,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Got it',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Small tappable "?" that opens an ExplainDialog. Sits next to any label.
class HelpDot extends StatelessWidget {
  final Theme t;
  final IconData icon;
  final String title;
  final String plain;
  final String? detail;
  final String? example;
  final Color? accent;

  const HelpDot({
    super.key,
    required this.t,
    required this.icon,
    required this.title,
    required this.plain,
    this.detail,
    this.example,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => ExplainDialog.show(
        context,
        t,
        icon: icon,
        title: title,
        plain: plain,
        detail: detail,
        example: example,
        accent: accent,
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Icon(Icons.help_outline_rounded, size: 13, color: t.faint),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
//  GLOSSARY — full list of terms, one educational dialog per entry
// ─────────────────────────────────────────────────────────────────────────

class _GlossaryEntry {
  final IconData icon;
  final String term;
  final String plain;
  final String detail;
  final String example;
  final Color accent;
  const _GlossaryEntry(
      this.icon, this.term, this.plain, this.detail, this.example, this.accent);
}

List<_GlossaryEntry> _glossaryEntries() => [
      _GlossaryEntry(
        Icons.flag_outlined,
        'Flagged / Picked',
        'Our system spotted something unusual and added the stock to today\'s watchlist.',
        'During market hours the scanner looks for sudden jumps in price or trading volume. When a stock behaves unusually, it gets "flagged" so we can follow what happens next.',
        'A stock that normally trades quietly suddenly has 10× its usual buyers in 5 minutes. That catches the scanner\'s eye — like a smoke detector noticing smoke.',
        Theme.blue,
      ),
      _GlossaryEntry(
        Icons.north_east_rounded,
        'Bullish',
        'The system thinks this stock\'s price will go UP.',
        '"Bull" is market slang for optimism. A bullish view expects rising prices. The opposite of bearish.',
        'Like predicting rain so you carry an umbrella — the system expects sunshine for this stock\'s price.',
        Theme.green,
      ),
      _GlossaryEntry(
        Icons.south_east_rounded,
        'Bearish',
        'The system thinks this stock\'s price will go DOWN.',
        '"Bear" is market slang for pessimism. A bearish view expects falling prices.',
        'Like checking the weather and deciding to stay home because a storm is coming.',
        Theme.red,
      ),
      _GlossaryEntry(
        Icons.trending_up_rounded,
        'Gain since flagged',
        'How much the price has moved since we started watching it, in percent.',
        'We record the price at the exact moment a stock is flagged. Every update after that is compared against that starting price.',
        'Flagged at ₹100 → now ₹107 → the gain since flagged is +7%. Flagged at ₹100 → now ₹95 → it\'s −5%.',
        Theme.green,
      ),
      _GlossaryEntry(
        Icons.today_rounded,
        'Today\'s move %',
        'How much the stock\'s price has changed today alone — from yesterday\'s close to right now.',
        'This is the standard "today\'s return" number you see on any finance app. It has nothing to do with when the stock was flagged.',
        'Yesterday it closed at ₹200. Today it\'s at ₹206 → today\'s move is +3%.',
        Theme.gold,
      ),
      _GlossaryEntry(
        Icons.track_changes_rounded,
        'Prediction accuracy',
        'Out of all the picks, how often the price actually moved the way the system expected.',
        'If 10 stocks were flagged and 7 of them moved in the expected direction, accuracy is 70%. One day is a very small sample — treat this as a learning metric, not a guarantee.',
        'A weather forecaster who predicts rain correctly 7 out of 10 days has 70% accuracy. It doesn\'t mean tomorrow will definitely rain.',
        Theme.blue,
      ),
      _GlossaryEntry(
        Icons.check_circle_outline_rounded,
        'Success / Missed',
        'Success = price moved the expected way by market close. Missed = it didn\'t.',
        'At 3:30 PM IST the market closes and prices freeze. We then check each pick: did the price end higher than the flagged price (for bullish) or lower (for bearish)?',
        'Bullish pick flagged at ₹50, closed at ₹53 → Success. Bearish pick flagged at ₹50, closed at ₹51 → Missed.',
        Theme.green,
      ),
      _GlossaryEntry(
        Icons.domain_rounded,
        'Sector',
        'The industry the company works in — like Banking, IT, or Pharma.',
        'Stocks in the same sector often move together because they face the same news. Seeing 3 banking stocks flagged tells a different story than 3 pharma stocks.',
        'If the government announces new banking rules, most bank stocks react the same day.',
        Theme.gold,
      ),
      _GlossaryEntry(
        Icons.schedule_rounded,
        'Market hours',
        'The NSE (India\'s main stock exchange) is open 9:15 AM – 3:30 PM IST, Monday to Friday.',
        'Outside these hours prices stop updating. A pick made at 10 AM will show fresh prices until 3:30 PM, then freeze. On holidays and weekends the market is fully closed.',
        'Like a shop: you can only buy and sell while it\'s open. After closing time, the price tags stay the same until it reopens.',
        Theme.blue,
      ),
    ];

// ─────────────────────────────────────────────────────────────────────────
//  MODELS  (same data shape as your Supabase feed — do not change)
// ─────────────────────────────────────────────────────────────────────────

class StockEntry {
  final int id;
  final String symbol;
  final DateTime snapshotTime;
  final String? sentiment;
  final double? close;
  final double? breakoutClose;
  final double? pcnt;
  final int? screenerCount;
  final String? sector;

  StockEntry({
    required this.id,
    required this.symbol,
    required this.snapshotTime,
    this.sentiment,
    this.close,
    this.breakoutClose,
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
      breakoutClose: (map['breakout_close'] as num?)?.toDouble(),
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

// ─────────────────────────────────────────────────────────────────────────
//  HELPERS
// ─────────────────────────────────────────────────────────────────────────

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
  final yesterday = today.subtract(const Duration(days: 1));
  if (date.year == yesterday.year &&
      date.month == yesterday.month &&
      date.day == yesterday.day) {
    return 'Yesterday';
  }
  return DateFormat('EEE, d MMM').format(date);
}

String formatINR(double value) {
  return NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  ).format(value);
}

// ─────────────────────────────────────────────────────────────────────────
//  MAIN PAGE
// ─────────────────────────────────────────────────────────────────────────

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
      final start =
          DateTime.utc(date.year, date.month, date.day, 4, 00); // 9:30 AM IST
      final end =
          DateTime.utc(date.year, date.month, date.day, 9, 45); // 3:15 PM IST

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
    HapticFeedback.selectionClick();
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

      final startPrice = first.breakoutClose ?? first.close ?? 0;
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
    final isDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final t = Theme(isDark);

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: Theme.ink,
          backgroundColor: t.surface,
          onRefresh: () => _fetchEntries(_selectedDate),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(t)),
              if (_loading)
                const SliverToBoxAdapter(child: _LoadingSkeleton())
              else if (_error != null)
                SliverFillRemaining(
                    hasScrollBody: false,
                    child: _ErrorState(
                        t: t, onRetry: () => _fetchEntries(_selectedDate)))
              else
                _buildContentSlivers(t),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(Theme t) {
    final today = getTodayIST();
    final isToday = _selectedDate.isAtSameMomentAs(today);

    return Container(
      decoration: BoxDecoration(
        color: t.bg,
        border: Border(bottom: BorderSide(color: t.line, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: Icon(Icons.arrow_back_ios_new_rounded,
                      size: 17, color: t.text),
                  splashRadius: 20,
                ),
                const Spacer(),
                // Glossary
                GestureDetector(
                  onTap: () => _showGlossary(context, t),
                  child: Container(
                    height: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: t.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: t.line),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.menu_book_outlined,
                            size: 14, color: t.muted),
                        const SizedBox(width: 5),
                        Text('Glossary',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: t.muted)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Backtest
                GestureDetector(
                  onTap: () => Get.toNamed('/backtest/ai-picks'),
                  child: Container(
                    height: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: t.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: t.line),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.history_rounded, size: 14, color: t.muted),
                        const SizedBox(width: 5),
                        Text('Backtest',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: t.muted)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today\'s Watchlist',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                          color: t.text,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Stocks our system noticed acting unusually — follow along and learn how they behave.',
                        style: TextStyle(
                            fontSize: 12.5, height: 1.5, color: t.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // What is this page?
                GestureDetector(
                  onTap: () => ExplainDialog.show(
                    context,
                    t,
                    icon: Icons.school_outlined,
                    title: 'What is this page?',
                    plain:
                        'This is a learning tool. It shows which stocks a computer model found "interesting" today, and lets you watch what actually happens to them.',
                    detail:
                        'No model can predict the future. The value here is in watching: do flagged stocks really move the way the model expected? Over time you\'ll build an intuition for what these signals mean and how unreliable short-term prediction can be.',
                    example:
                        'It\'s like a science experiment: the model makes a prediction (hypothesis), the market runs the experiment, and you check the result at 3:30 PM.',
                    accent: Theme.blue,
                  ),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Theme.blue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.school_outlined,
                        size: 16, color: Theme.blue),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: _DateNavigator(
              t: t,
              date: _selectedDate,
              isToday: isToday,
              onPrev: () => _adjustDay(-1),
              onNext: isToday ? null : () => _adjustDay(1),
              onTapLabel: _pickDate,
            ),
          ),
        ],
      ),
    );
  }

  void _showGlossary(BuildContext context, Theme t) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: t.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
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
                      color: t.line,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text('Glossary',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: t.text)),
                const SizedBox(height: 4),
                Text(
                  'Tap any term to open a full explanation with a real example.',
                  style: TextStyle(fontSize: 12, color: t.muted),
                ),
                const SizedBox(height: 16),
                ..._glossaryEntries().map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () => ExplainDialog.show(
                          context,
                          t,
                          icon: e.icon,
                          title: e.term,
                          plain: e.plain,
                          detail: e.detail,
                          example: e.example,
                          accent: e.accent,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 13),
                          decoration: BoxDecoration(
                            color: t.surfaceSunken,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: t.lineSoft),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: e.accent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(e.icon, size: 15, color: e.accent),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(e.term,
                                        style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                            color: t.text)),
                                    const SizedBox(height: 1),
                                    Text(e.plain,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontSize: 11, color: t.muted)),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded,
                                  size: 16, color: t.faint),
                            ],
                          ),
                        ),
                      ),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Content ───────────────────────────────────────────────────────────────

  Widget _buildContentSlivers(Theme t) {
    final analytics = _analytics;
    final groups = _groupedTimeline;

    if (groups.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _EmptyState(
          t: t,
          onGoToday: () {
            setState(() => _selectedDate = getTodayIST());
            _fetchEntries(getTodayIST());
          },
          onRetry: () => _fetchEntries(_selectedDate),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildListDelegate([
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
          child: Column(
            children: [
              if (analytics != null) ...[
                _Scoreboard(
                    t: t,
                    analytics: analytics,
                    isMarketClosed: _isMarketClosed),
                const SizedBox(height: 26),
              ],
              // Section label
              Row(
                children: [
                  Text('PICKS TIMELINE',
                      style: TextStyle(
                          fontSize: 10.5,
                          letterSpacing: 1.4,
                          fontWeight: FontWeight.w800,
                          color: t.faint)),
                  const SizedBox(width: 8),
                  HelpDot(
                    t: t,
                    icon: Icons.timeline_rounded,
                    title: 'How to read the timeline',
                    plain:
                        'Stocks are grouped by the exact time our system first noticed them, newest first.',
                    detail:
                        'A stock flagged at 10:15 AM appears under "10:15 AM". Under it you\'ll see how its price moved from that moment onward. Earlier picks have had more time to prove (or disprove) the prediction.',
                    example:
                        'A stock flagged at 9:30 AM has nearly a full day of price data. One flagged at 3:00 PM only has 30 minutes — it\'s too early to judge it.',
                    accent: Theme.blue,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ...groups.asMap().entries.map((entry) {
                return _TimeGroupSection(
                  t: t,
                  group: entry.value,
                  isMarketClosed: _isMarketClosed,
                  onOpenStock: (symbol) =>
                      Navigator.of(context).pushNamed('/stocks/$symbol'),
                );
              }),
              const SizedBox(height: 6),
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.gold.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Theme.gold.withOpacity(0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.school_outlined, size: 16, color: Theme.gold),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Learning tool only. These picks come from a computer model and are NOT financial advice. Markets are unpredictable — never invest money you can\'t afford to lose.',
                          style: TextStyle(
                              fontSize: 11, height: 1.6, color: t.muted),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
//  DATE NAVIGATOR
// ─────────────────────────────────────────────────────────────────────────

class _DateNavigator extends StatelessWidget {
  final Theme t;
  final DateTime date;
  final bool isToday;
  final VoidCallback onPrev;
  final VoidCallback? onNext;
  final VoidCallback onTapLabel;

  const _DateNavigator({
    required this.t,
    required this.date,
    required this.isToday,
    required this.onPrev,
    required this.onNext,
    required this.onTapLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.line),
      ),
      child: Row(
        children: [
          _arrow(Icons.chevron_left_rounded, onPrev),
          Expanded(
            child: GestureDetector(
              onTap: onTapLabel,
              child: Container(
                color: Colors.transparent,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isToday && !_marketClosedNow)
                      Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.only(right: 7),
                        decoration: const BoxDecoration(
                            color: Theme.green, shape: BoxShape.circle),
                      ),
                    Text(
                      formatDateHeader(date),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                        color: t.text,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.expand_more_rounded, size: 16, color: t.faint),
                  ],
                ),
              ),
            ),
          ),
          _arrow(Icons.chevron_right_rounded, onNext, disabled: onNext == null),
        ],
      ),
    );
  }

  bool get _marketClosedNow {
    final now =
        DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
    return now.hour > 15 || (now.hour == 15 && now.minute >= 30);
  }

  Widget _arrow(IconData icon, VoidCallback? onTap, {bool disabled = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        color: Colors.transparent,
        child: Icon(icon, size: 20, color: disabled ? t.faint : t.muted),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
//  SCOREBOARD — the day's headline numbers, each explained
// ─────────────────────────────────────────────────────────────────────────

class _Scoreboard extends StatelessWidget {
  final Theme t;
  final Map<String, dynamic> analytics;
  final bool isMarketClosed;

  const _Scoreboard(
      {required this.t, required this.analytics, required this.isMarketClosed});

  @override
  Widget build(BuildContext context) {
    final avg = analytics['avgGrabbed'] as double;
    final acc = analytics['accuracyRate'] as double;
    final total = analytics['totalStocks'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: t.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('DAY SCOREBOARD',
                  style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w800,
                      color: t.faint)),
              const Spacer(),
              _MarketDot(t: t, isMarketClosed: isMarketClosed),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ScoreCell(
                  t: t,
                  value: '$total',
                  label: 'stocks flagged',
                  sub: total == 0
                      ? 'Nothing caught the eye today'
                      : 'the system found $total unusual stock${total == 1 ? '' : 's'}',
                  helpIcon: Icons.flag_outlined,
                  helpTitle: 'Stocks flagged',
                  helpPlain:
                      'The number of stocks the system decided to watch today.',
                  helpDetail:
                      'More flags usually mean a more volatile or news-heavy day. Zero flags means the market was quiet by the model\'s standards — which is also useful information.',
                  helpExample:
                      'A normal day might flag 5–15 stocks. A day with big news (budget, election, rate change) can flag 40+.',
                ),
              ),
              Container(width: 1, height: 54, color: t.lineSoft),
              Expanded(
                child: _ScoreCell(
                  t: t,
                  value: '${avg >= 0 ? '+' : ''}${avg.toStringAsFixed(2)}%',
                  label: 'average move',
                  valueColor: avg >= 0 ? t.up : t.down,
                  sub: avg >= 0
                      ? 'on average, picks moved UP this much'
                      : 'on average, picks moved DOWN this much',
                  helpIcon: Icons.trending_up_rounded,
                  helpTitle: 'Average move',
                  helpPlain:
                      'If you had followed every pick equally, this is roughly how your day would have gone, in percent.',
                  helpDetail:
                      'It\'s a simple average across all flagged stocks of the "gain since flagged" number. One huge winner can pull it up; one big loser can pull it down.',
                  helpExample:
                      'Three picks: +2%, −1%, +4%. Average = (2 − 1 + 4) / 3 = +1.67%.',
                  helpAccent: avg >= 0 ? t.up : t.down,
                ),
              ),
              Container(width: 1, height: 54, color: t.lineSoft),
              Expanded(
                child: _ScoreCell(
                  t: t,
                  value: '${acc.toStringAsFixed(0)}%',
                  label: 'direction right',
                  valueColor: acc >= 50 ? t.up : t.down,
                  sub: acc >= 50
                      ? 'more picks went the expected way'
                      : 'more picks went the wrong way',
                  helpIcon: Icons.track_changes_rounded,
                  helpTitle: 'Prediction accuracy',
                  helpPlain:
                      'Out of all today\'s picks, the percent that moved in the direction the system expected.',
                  helpDetail:
                      'Bullish picks count as correct if the price went up; bearish picks count as correct if the price went down. A small sample (like one day) says very little — patterns only emerge over weeks.',
                  helpExample:
                      '10 picks today: 7 went the expected direction → 70% accuracy. Tomorrow might be 40%. That\'s normal.',
                  helpAccent: acc >= 50 ? t.up : t.down,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MarketDot extends StatelessWidget {
  final Theme t;
  final bool isMarketClosed;
  const _MarketDot({required this.t, required this.isMarketClosed});

  @override
  Widget build(BuildContext context) {
    final live = !isMarketClosed;
    final color = live ? t.up : t.faint;
    return GestureDetector(
      onTap: () => ExplainDialog.show(
        context,
        t,
        icon: Icons.schedule_rounded,
        title: 'Market status',
        plain: live
            ? 'The market is open right now, so prices are updating live.'
            : 'The market is closed, so all prices are frozen at their last values.',
        detail:
            'NSE (India\'s National Stock Exchange) trades 9:15 AM – 3:30 PM IST, Monday to Friday. On this page, "Success" and "Missed" outcomes are judged at the 3:30 PM close.',
        example: live
            ? 'A price shown as ₹102.40 may be ₹102.60 two minutes from now.'
            : 'A price shown as ₹102.40 after 3:30 PM will stay ₹102.40 until the market reopens tomorrow.',
        accent: color,
      ),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(live ? 'LIVE' : 'CLOSED',
              style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w800,
                  color: color)),
        ],
      ),
    );
  }
}

class _ScoreCell extends StatelessWidget {
  final Theme t;
  final String value;
  final String label;
  final String sub;
  final Color? valueColor;
  final IconData helpIcon;
  final String helpTitle;
  final String helpPlain;
  final String helpDetail;
  final String helpExample;
  final Color? helpAccent;

  const _ScoreCell({
    required this.t,
    required this.value,
    required this.label,
    required this.sub,
    required this.helpIcon,
    required this.helpTitle,
    required this.helpPlain,
    required this.helpDetail,
    required this.helpExample,
    this.valueColor,
    this.helpAccent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'monospace',
                    letterSpacing: -0.5,
                    color: valueColor ?? t.text,
                  ),
                ),
              ),
              HelpDot(
                t: t,
                icon: helpIcon,
                title: helpTitle,
                plain: helpPlain,
                detail: helpDetail,
                example: helpExample,
                accent: helpAccent,
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(label.toUpperCase(),
              style: TextStyle(
                  fontSize: 8.5,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                  color: t.faint)),
          const SizedBox(height: 4),
          Text(sub,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 9.5, height: 1.4, color: t.muted)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
//  TIMELINE
// ─────────────────────────────────────────────────────────────────────────

class _TimeGroupSection extends StatelessWidget {
  final Theme t;
  final TimeGroup group;
  final bool isMarketClosed;
  final void Function(String symbol) onOpenStock;

  const _TimeGroupSection({
    required this.t,
    required this.group,
    required this.isMarketClosed,
    required this.onOpenStock,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline rail
            Column(
              children: [
                const SizedBox(height: 3),
                Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: t.up,
                    shape: BoxShape.circle,
                    border: Border.all(color: t.bg, width: 2.5),
                  ),
                ),
                Expanded(child: Container(width: 1.5, color: t.lineSoft)),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Text('Flagged at ${group.time}',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'monospace',
                                color: t.text)),
                        const SizedBox(width: 8),
                        Text('· ${group.stocks.length}',
                            style: TextStyle(fontSize: 12, color: t.faint)),
                      ],
                    ),
                  ),
                  ...group.stocks.map((stock) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _StockCard(
                            t: t,
                            stock: stock,
                            isMarketClosed: isMarketClosed,
                            onTap: () => onOpenStock(stock.symbol)),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
//  STOCK CARD — redesigned around one plain-English story
// ─────────────────────────────────────────────────────────────────────────

class _StockCard extends StatelessWidget {
  final Theme t;
  final GroupedStock stock;
  final bool isMarketClosed;
  final VoidCallback onTap;

  const _StockCard(
      {required this.t,
      required this.stock,
      required this.isMarketClosed,
      required this.onTap});

  // The single sentence that tells the whole story of this card.
  String get _story {
    final isBullish = stock.sentiment.toUpperCase() != 'BEARISH';
    final pct = stock.netGainPcnt.abs().toStringAsFixed(2);
    final dir = stock.netGainPcnt >= 0 ? 'up' : 'down';

    if (stock.history.length <= 1) {
      return isBullish
          ? 'Just flagged — the system expects the price to rise. Too early to say if it\'s right.'
          : 'Just flagged — the system expects the price to fall. Too early to say if it\'s right.';
    }
    if (isMarketClosed) {
      final verdict =
          stock.isSuccess ? 'the system was right.' : 'the system was wrong.';
      return isBullish
          ? 'Expected to go up. At the closing bell it was $dir $pct% — $verdict'
          : 'Expected to go down. At the closing bell it was $dir $pct% — $verdict';
    }
    return isBullish
        ? 'Expected to go up. So far the price has moved $dir $pct%.'
        : 'Expected to go down. So far the price has moved $dir $pct%.';
  }

  @override
  Widget build(BuildContext context) {
    final isBullish = stock.sentiment.toUpperCase() != 'BEARISH';
    final gainColor = stock.netGainPcnt >= 0 ? t.up : t.down;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: t.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Row 1: identity + badges ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo-ish square with initials
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: t.surfaceSunken,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          stock.cleanSymbol.length >= 2
                              ? stock.cleanSymbol.substring(0, 2)
                              : stock.cleanSymbol,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'monospace',
                              color: t.muted),
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(stock.cleanSymbol,
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'monospace',
                                    letterSpacing: -0.3,
                                    color: t.text)),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(stock.sector,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: 11, color: t.muted)),
                                ),
                                const SizedBox(width: 4),
                                // Sector explainer
                                HelpDot(
                                  t: t,
                                  icon: Icons.domain_rounded,
                                  title: 'Sector: ${stock.sector}',
                                  plain:
                                      'This company operates in the ${stock.sector} industry.',
                                  detail:
                                      'Companies in the same sector tend to react to the same news. Watching which sectors get flagged most often tells you where the market\'s attention is going.',
                                  example:
                                      'If four out of five flagged stocks are banks, something sector-wide (like an RBI announcement) is probably moving the whole group.',
                                  accent: Theme.gold,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isMarketClosed)
                        _OutcomeChip(t: t, success: stock.isSuccess),
                      if (isMarketClosed) const SizedBox(width: 6),
                      _DirectionBadge(t: t, isBullish: isBullish),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ── The plain-English story — the heart of the card ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: gainColor.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: gainColor.withOpacity(0.15)),
                    ),
                    child: Text(
                      _story,
                      style: TextStyle(
                          fontSize: 12.5,
                          height: 1.55,
                          fontWeight: FontWeight.w600,
                          color: t.text),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── The three numbers, each with a "?" explainer ──
                  Row(
                    children: [
                      Expanded(
                        child: _Metric(
                          t: t,
                          label: 'Flagged at',
                          value: formatINR(stock.startPrice),
                          helpPlain:
                              'The price of this stock at the exact minute our system flagged it. Every move is measured from this starting point.',
                          helpExample:
                              'Flagged at ₹100. If it later trades at ₹110, that\'s a +10% move since flagged.',
                        ),
                      ),
                      Expanded(
                        child: _Metric(
                          t: t,
                          label: 'Price now',
                          value: formatINR(stock.latestPrice),
                          helpPlain:
                              'The most recent price we have for this stock.',
                          helpDetail: isMarketClosed
                              ? 'The market has closed, so this is the final closing price.'
                              : 'The market is open, so this keeps updating during trading hours.',
                        ),
                      ),
                      Expanded(
                        child: _Metric(
                          t: t,
                          label: 'Since flagged',
                          value:
                              '${stock.netGainPcnt >= 0 ? '+' : ''}${stock.netGainPcnt.toStringAsFixed(2)}%',
                          valueColor: stock.netGainPcnt >= 0 ? t.up : t.down,
                          helpPlain:
                              'The total percent change from the flagged price to the current price.',
                          helpDetail:
                              'Positive (green) means the price is higher than when it was flagged. Negative (red) means it\'s lower. For bearish picks, a red number is actually what the system wanted.',
                          helpExample:
                              'Flagged at ₹200, now ₹210 → +5.00%. This single number summarizes the entire pick so far.',
                          helpAccent: stock.netGainPcnt >= 0 ? t.up : t.down,
                        ),
                      ),
                    ],
                  ),

                  // Today's move — small supporting line
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      children: [
                        Icon(
                            stock.latestDayPcnt >= 0
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            size: 11,
                            color: stock.latestDayPcnt >= 0 ? t.up : t.down),
                        const SizedBox(width: 4),
                        Text(
                          '${stock.latestDayPcnt >= 0 ? '+' : ''}${stock.latestDayPcnt.toStringAsFixed(2)}% today',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'monospace',
                              color: stock.latestDayPcnt >= 0 ? t.up : t.down),
                        ),
                        const SizedBox(width: 4),
                        HelpDot(
                          t: t,
                          icon: Icons.today_rounded,
                          title: 'Today\'s move',
                          plain:
                              'How much this stock has moved today overall — from yesterday\'s closing price.',
                          detail:
                              'This is independent of the flag. A stock can be down today overall (+) yet still up since it was flagged, if the flag happened near the day\'s low.',
                          example:
                              'Stock closed yesterday at ₹500, flagged today at ₹490 (bearish), now at ₹495. Today: −1.0%. Since flagged: +1.02%.',
                          accent: Theme.gold,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Chart
            _StockChart(t: t, stock: stock, isMarketClosed: isMarketClosed),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final Theme t;
  final String label;
  final String value;
  final Color? valueColor;
  final String helpPlain;
  final String? helpDetail;
  final String? helpExample;
  final Color? helpAccent;

  const _Metric({
    required this.t,
    required this.label,
    required this.value,
    required this.helpPlain,
    this.helpDetail,
    this.helpExample,
    this.valueColor,
    this.helpAccent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: t.faint)),
            ),
            HelpDot(
              t: t,
              icon: Icons.info_outline_rounded,
              title: label,
              plain: helpPlain,
              detail: helpDetail,
              example: helpExample,
              accent: helpAccent,
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(value,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                fontFamily: 'monospace',
                letterSpacing: -0.3,
                color: valueColor ?? t.text)),
      ],
    );
  }
}

class _DirectionBadge extends StatelessWidget {
  final Theme t;
  final bool isBullish;
  const _DirectionBadge({required this.t, required this.isBullish});

  @override
  Widget build(BuildContext context) {
    final color = isBullish ? t.up : t.down;
    return GestureDetector(
      onTap: () => ExplainDialog.show(
        context,
        t,
        icon: isBullish ? Icons.north_east_rounded : Icons.south_east_rounded,
        title: isBullish ? 'Bullish — expects UP' : 'Bearish — expects DOWN',
        plain: isBullish
            ? 'The model predicts this stock\'s price will rise.'
            : 'The model predicts this stock\'s price will fall.',
        detail:
            'This is a prediction made at flag time, based on patterns the model saw in price and volume. Predictions are frequently wrong — especially short-term ones — which is exactly why this page exists: so you can watch and judge for yourself.',
        example: isBullish
            ? 'Like a hunch that "this team will win" before the match starts. The final whistle (3:30 PM close) reveals the result.'
            : 'Like betting the underdog: less common, but sometimes the smart side when a stock has run up too far, too fast.',
        accent: color,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
                isBullish
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: 11,
                color: color),
            const SizedBox(width: 3),
            Text(isBullish ? 'UP' : 'DOWN',
                style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: color,
                    fontFamily: 'monospace')),
          ],
        ),
      ),
    );
  }
}

class _OutcomeChip extends StatelessWidget {
  final Theme t;
  final bool success;
  const _OutcomeChip({required this.t, required this.success});

  @override
  Widget build(BuildContext context) {
    final color = success ? t.up : t.down;
    return GestureDetector(
      onTap: () => ExplainDialog.show(
        context,
        t,
        icon: success
            ? Icons.check_circle_outline_rounded
            : Icons.cancel_outlined,
        title: success ? 'Result: Correct' : 'Result: Wrong',
        plain: success
            ? 'By the 3:30 PM market close, the price had moved the direction the model predicted.'
            : 'By the 3:30 PM market close, the price had moved the opposite of what the model predicted.',
        detail:
            'This verdict is only final for past days. For today\'s picks it appears after the market closes. Being wrong is normal and expected — even great models are wrong often.',
        example: success
            ? 'Predicted UP, flagged at ₹100, closed at ₹104 → correct prediction. The model earned a point.'
            : 'Predicted UP, flagged at ₹100, closed at ₹97 → wrong prediction. These happen to every model, regularly.',
        accent: color,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(success ? Icons.check_rounded : Icons.close_rounded,
                size: 12, color: color),
            const SizedBox(width: 3),
            Text(success ? 'RIGHT' : 'WRONG',
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: color,
                    fontFamily: 'monospace')),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
//  CHART — clean line chart, no gradient fill
// ─────────────────────────────────────────────────────────────────────────

class _StockChart extends StatelessWidget {
  final Theme t;
  final GroupedStock stock;
  final bool isMarketClosed;

  const _StockChart(
      {required this.t, required this.stock, required this.isMarketClosed});

  @override
  Widget build(BuildContext context) {
    final lineColor = stock.netGainPcnt >= 0 ? t.up : t.down;

    if (stock.history.length <= 1) {
      return Container(
        height: 110,
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        decoration: BoxDecoration(
          color: t.surfaceSunken,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isMarketClosed
                    ? (stock.isSuccess
                        ? Icons.check_circle_outline_rounded
                        : Icons.cancel_outlined)
                    : Icons.hourglass_top_rounded,
                size: 17,
                color: isMarketClosed
                    ? (stock.isSuccess ? t.up : t.down)
                    : t.muted,
              ),
              const SizedBox(height: 6),
              Text(
                isMarketClosed
                    ? (stock.isSuccess
                        ? 'Closed higher than the flagged price'
                        : 'Closed lower than the flagged price')
                    : 'Flagged moments ago — chart appears with the next update',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600, color: t.muted),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 150,
      margin: const EdgeInsets.fromLTRB(14, 2, 14, 14),
      decoration: BoxDecoration(
        color: t.surfaceSunken,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SfCartesianChart(
          backgroundColor: Colors.transparent,
          plotAreaBorderWidth: 0,
          margin: const EdgeInsets.fromLTRB(10, 10, 12, 6),
          primaryXAxis: CategoryAxis(
            labelStyle: TextStyle(
                fontSize: 8.5, color: t.faint, fontFamily: 'monospace'),
            axisLine: AxisLine(color: t.lineSoft),
            majorGridLines: const MajorGridLines(width: 0),
            majorTickLines: const MajorTickLines(size: 0),
            labelPlacement: LabelPlacement.onTicks,
            desiredIntervals: 3,
            edgeLabelPlacement: EdgeLabelPlacement.shift,
          ),
          primaryYAxis: NumericAxis(
            labelStyle: TextStyle(
                fontSize: 8.5, color: t.faint, fontFamily: 'monospace'),
            axisLine: AxisLine(color: t.lineSoft),
            majorGridLines: MajorGridLines(
                width: 1, color: t.lineSoft, dashArray: const [3, 4]),
            majorTickLines: const MajorTickLines(size: 0),
            numberFormat: NumberFormat.currency(
                locale: 'en_IN', symbol: '₹', decimalDigits: 0),
            desiredIntervals: 3,
          ),
          tooltipBehavior: TooltipBehavior(
            enable: true,
            color: t.surface,
            builder: (data, point, series, pointIndex, seriesIndex) {
              final d = data as ChartPoint;
              final dayC = d.dayPcnt >= 0 ? t.up : t.down;
              final sinceC = d.pcntSinceFirst >= 0 ? t.up : t.down;
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: t.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: t.line),
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
                            color: t.faint)),
                    const SizedBox(height: 5),
                    Text(formatINR(d.close),
                        style: TextStyle(
                            fontSize: 11.5,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w700,
                            color: t.text)),
                    Text(
                        '${d.dayPcnt >= 0 ? '+' : ''}${d.dayPcnt.toStringAsFixed(2)}% today',
                        style: TextStyle(
                            fontSize: 10,
                            fontFamily: 'monospace',
                            color: dayC)),
                    Text(
                        '${d.pcntSinceFirst >= 0 ? '+' : ''}${d.pcntSinceFirst.toStringAsFixed(2)}% since flagged',
                        style: TextStyle(
                            fontSize: 10,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w700,
                            color: sinceC)),
                  ],
                ),
              );
            },
          ),
          series: <CartesianSeries>[
            LineSeries<ChartPoint, String>(
              dataSource: stock.history,
              xValueMapper: (d, _) => d.time,
              yValueMapper: (d, _) => d.close,
              color: lineColor,
              width: 2.2,
              animationDuration: 400,
              markerSettings: MarkerSettings(
                isVisible: true,
                height: 4,
                width: 4,
                color: lineColor,
                borderColor: t.surface,
                borderWidth: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
//  EMPTY / ERROR / LOADING
// ─────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final Theme t;
  final VoidCallback onGoToday;
  final VoidCallback onRetry;
  const _EmptyState(
      {required this.t, required this.onGoToday, required this.onRetry});

  @override
  Widget build(BuildContext context) {
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
                  color: t.surfaceSunken,
                  borderRadius: BorderRadius.circular(20)),
              child: Icon(Icons.visibility_outlined, size: 28, color: t.faint),
            ),
            const SizedBox(height: 20),
            Text('Nothing flagged for this day',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: t.text)),
            const SizedBox(height: 8),
            Text(
              "The system scans during market hours (9:15 AM – 3:30 PM IST, Mon–Fri) and only flags stocks behaving unusually. A quiet day with no flags is normal.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: t.muted, height: 1.7),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _pillButton(
                    icon: Icons.calendar_today_rounded,
                    label: 'Go to today',
                    onTap: onGoToday),
                const SizedBox(width: 10),
                _pillButton(
                    icon: Icons.refresh_rounded,
                    label: 'Refresh',
                    onTap: onRetry),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pillButton(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: t.line)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: t.muted),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: t.muted)),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final Theme t;
  final VoidCallback onRetry;
  const _ErrorState({required this.t, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                  color: t.down.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(Icons.wifi_off_rounded, color: t.down, size: 24),
            ),
            const SizedBox(height: 16),
            Text('Couldn\'t load picks',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800, color: t.text)),
            const SizedBox(height: 8),
            Text('Check your internet connection and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: t.muted)),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                decoration: BoxDecoration(
                    color: t.text, borderRadius: BorderRadius.circular(13)),
                child: Text('Try again',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: t.bg)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ...List.generate(
                  3,
                  (i) => Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child:
                          _PulsingDot(delay: Duration(milliseconds: i * 200)))),
              const SizedBox(width: 6),
              Text('SCANNING THE MARKET…',
                  style: TextStyle(
                      fontSize: 10, letterSpacing: 1.2, color: _kSkeletonText)),
            ],
          ),
          const SizedBox(height: 16),
          _SkeletonBox(height: 96, radius: 20),
          const SizedBox(height: 24),
          _SkeletonBox(height: 260, radius: 18),
          const SizedBox(height: 12),
          _SkeletonBox(height: 260, radius: 18),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatefulWidget {
  final double height;
  final double radius;
  const _SkeletonBox({required this.height, this.radius = 12});

  @override
  State<_SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<_SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();
    _anim = Tween<double>(begin: -1.4, end: 1.4)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final base = isDark ? const Color(0xFF1B1B19) : const Color(0xFFEDEBE3);
    final shine = isDark ? const Color(0xFF232320) : const Color(0xFFF6F5F0);
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
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

// Faint text color for widgets that don't receive a Theme.
const Color _kSkeletonText = Color(0xFFADA99B);

class _PulsingDot extends StatefulWidget {
  final Duration delay;
  const _PulsingDot({required this.delay});

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
        vsync: this, duration: const Duration(milliseconds: 1000));
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
    _anim = Tween<double>(begin: 1.0, end: 0.25)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
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
            decoration: const BoxDecoration(
                color: Theme.green, shape: BoxShape.circle)),
      ),
    );
  }
}
