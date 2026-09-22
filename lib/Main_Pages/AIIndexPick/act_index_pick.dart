import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

// ═════════════════════════════════════════════════════════════════════════════
// MODELS (unchanged data contract with Supabase)
// ═════════════════════════════════════════════════════════════════════════════

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

  int get upCount => picks.where((p) => p.isUpBreakout).length;
  int get downCount => picks.length - upCount;

  double? get changePct => (priceChange != null && (startPrice ?? 0) != 0)
      ? priceChange! / startPrice! * 100
      : null;
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

enum TimeRangeFilter { all, firstHour, midMorning, preNoon, afternoon }

// ═════════════════════════════════════════════════════════════════════════════
// HELPERS
// ═════════════════════════════════════════════════════════════════════════════

String mapSymbol(String s) {
  if (s == 'NIFTY50') return 'NIFTY';
  if (s == 'NIFTYBANK') return 'BANKNIFTY';
  return s;
}

String friendlyName(String mapped) {
  switch (mapped) {
    case 'NIFTY':
      return 'Nifty 50';
    case 'BANKNIFTY':
      return 'Bank Nifty';
    default:
      return mapped;
  }
}

DateTime getTodayIST() =>
    DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));

String formatDateHeader(DateTime d) => DateFormat('dd MMM yyyy').format(d);

String formatTimeIST(String iso) {
  final d =
      DateTime.parse(iso).toUtc().add(const Duration(hours: 5, minutes: 30));
  return DateFormat('h:mm a').format(d);
}

DateTime getLocalIstTime(String iso) {
  final t =
      DateTime.parse(iso).toUtc().add(const Duration(hours: 5, minutes: 30));
  return DateTime(t.year, t.month, t.day, t.hour, t.minute);
}

final NumberFormat _priceFmt = NumberFormat('#,##0.00');
String fmtPrice(double? v) => v == null ? '—' : _priceFmt.format(v);

String sessionName(TimeRangeFilter f) {
  switch (f) {
    case TimeRangeFilter.all:
      return 'Full day';
    case TimeRangeFilter.firstHour:
      return 'Opening hour';
    case TimeRangeFilter.midMorning:
      return 'Mid-morning';
    case TimeRangeFilter.preNoon:
      return 'Around noon';
    case TimeRangeFilter.afternoon:
      return 'Afternoon';
  }
}

String timeRangeLabel(TimeRangeFilter f) {
  switch (f) {
    case TimeRangeFilter.all:
      return '9:15 – 3:30';
    case TimeRangeFilter.firstHour:
      return '9:15 – 10:15';
    case TimeRangeFilter.midMorning:
      return '10:15 – 11:30';
    case TimeRangeFilter.preNoon:
      return '11:30 – 12:30';
    case TimeRangeFilter.afternoon:
      return '12:30 – 3:30';
  }
}

String sessionHint(TimeRangeFilter f) {
  switch (f) {
    case TimeRangeFilter.all:
      return 'Showing the whole trading day, from opening bell to close.';
    case TimeRangeFilter.firstHour:
      return 'The first hour is usually the busiest. Prices often swing the most here.';
    case TimeRangeFilter.midMorning:
      return 'Things settle down a bit. Moves here often show which side is winning.';
    case TimeRangeFilter.preNoon:
      return 'Often the quietest stretch of the day, with smaller price moves.';
    case TimeRangeFilter.afternoon:
      return 'Activity usually picks up again as traders get ready for the close.';
  }
}

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

List<IndexEntry> picksInRange(
    GroupedIndex g, TimeRangeFilter f, DateTime date) {
  final b = timeRangeBounds(f);
  final xMin = DateTime(date.year, date.month, date.day, b.sh, b.sm);
  final xMax = DateTime(date.year, date.month, date.day, b.eh, b.em);
  return g.picks.where((pick) {
    final t = getLocalIstTime(pick.snapshotTime);
    return !t.isBefore(xMin) && !t.isAfter(xMax);
  }).toList();
}

OhlcvEntry? closestCandle(List<OhlcvEntry> data, DateTime t) {
  OhlcvEntry? best;
  var minDiff = 1 << 30;
  for (final o in data) {
    final d = getLocalIstTime(o.ts).difference(t).inMinutes.abs();
    if (d < minDiff) {
      minDiff = d;
      best = o;
    }
  }
  return best;
}

TextStyle _ts(Color c, double size,
        {FontWeight w = FontWeight.w500, double? ls, double? h}) =>
    TextStyle(
      color: c,
      fontSize: size,
      fontWeight: w,
      letterSpacing: ls,
      height: h,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

// ── Market mood: a plain-language summary of highs vs lows ──────────────────

enum MoodKind { buyers, sellers, mixed }

class MoodInfo {
  final MoodKind kind;
  final String label;
  final String line;
  final IconData icon;
  const MoodInfo(this.kind, this.label, this.line, this.icon);
}

MoodInfo moodFor(GroupedIndex g) {
  final total = g.picks.length;
  final ratio = total == 0 ? 0.5 : g.upCount / total;
  if (ratio >= 0.65) {
    return const MoodInfo(
      MoodKind.buyers,
      'Buyers are in control',
      'Most alerts were new highs, so more people wanted to buy than sell.',
      Icons.north_east_rounded,
    );
  }
  if (ratio <= 0.35) {
    return const MoodInfo(
      MoodKind.sellers,
      'Sellers are in control',
      'Most alerts were new lows, so more people wanted to sell than buy.',
      Icons.south_east_rounded,
    );
  }
  return const MoodInfo(
    MoodKind.mixed,
    'Buyers and sellers are split',
    'Both new highs and new lows showed up, so the market is undecided.',
    Icons.swap_vert_rounded,
  );
}

Color moodColor(MoodKind k, Pal p) {
  switch (k) {
    case MoodKind.buyers:
      return p.bull;
    case MoodKind.sellers:
      return p.bear;
    case MoodKind.mixed:
      return p.amber;
  }
}

String heroHeadline(List<GroupedIndex> gs) {
  final moods = gs.map(moodFor).toList();
  final names = gs.map((g) => friendlyName(g.mappedSymbol)).toList();
  String phrase(int i) {
    switch (moods[i].kind) {
      case MoodKind.buyers:
        return 'buyers are in control of ${names[i]}';
      case MoodKind.sellers:
        return 'sellers are in control of ${names[i]}';
      case MoodKind.mixed:
        return '${names[i]} is undecided';
    }
  }

  if (gs.length == 1) return _cap(phrase(0));
  final allSame = moods.every((m) => m.kind == moods.first.kind);
  if (allSame) {
    final joined = names.join(' and ');
    switch (moods.first.kind) {
      case MoodKind.buyers:
        return 'Buyers are in control of $joined';
      case MoodKind.sellers:
        return 'Sellers are in control of $joined';
      case MoodKind.mixed:
        return '$joined are both undecided';
    }
  }
  return _cap(List.generate(gs.length, phrase).join(', while '));
}

// ═════════════════════════════════════════════════════════════════════════════
// DESIGN TOKENS — flat surfaces, navy ink, marigold highlight
// ═════════════════════════════════════════════════════════════════════════════

class Pal {
  final bool dark;
  final Color bg, card, line, chip;
  final Color ink, sub, muted;
  final Color bull, bear, amber;
  final Color accent, onAccent;
  final Color hero, onHero, onHeroSub;

  const Pal({
    required this.dark,
    required this.bg,
    required this.card,
    required this.line,
    required this.chip,
    required this.ink,
    required this.sub,
    required this.muted,
    required this.bull,
    required this.bear,
    required this.amber,
    required this.accent,
    required this.onAccent,
    required this.hero,
    required this.onHero,
    required this.onHeroSub,
  });

  static const light = Pal(
    dark: false,
    bg: Color(0xFFF1F4F8),
    card: Color(0xFFFFFFFF),
    line: Color(0xFFE1E6EE),
    chip: Color(0xFFEDF1F6),
    ink: Color(0xFF0E1A2B),
    sub: Color(0xFF5B6778),
    muted: Color(0xFF9AA5B5),
    bull: Color(0xFF0E9F6E),
    bear: Color(0xFFD9363E),
    amber: Color(0xFFB7791F),
    accent: Color(0xFFFFB020),
    onAccent: Color(0xFF0E1A2B),
    hero: Color(0xFF0E1A2B),
    onHero: Color(0xFFF4F7FB),
    onHeroSub: Color(0xFF9FB0C6),
  );

  static const darkPal = Pal(
    dark: true,
    bg: Color(0xFF0A121C),
    card: Color(0xFF111C2B),
    line: Color(0xFF1F2E44),
    chip: Color(0xFF172538),
    ink: Color(0xFFE8EEF6),
    sub: Color(0xFF92A1B5),
    muted: Color(0xFF5A6A80),
    bull: Color(0xFF3ED598),
    bear: Color(0xFFFF6B6F),
    amber: Color(0xFFFFC24B),
    accent: Color(0xFFFFB020),
    onAccent: Color(0xFF0E1A2B),
    hero: Color(0xFF16263B),
    onHero: Color(0xFFF4F7FB),
    onHeroSub: Color(0xFF9FB0C6),
  );

  static Pal of(bool dark) => dark ? darkPal : light;
}

// ═════════════════════════════════════════════════════════════════════════════
// EDUCATION CONTENT — plain-language explanations shown in dialogs
// ═════════════════════════════════════════════════════════════════════════════

class InfoTopic {
  final IconData icon;
  final String title;
  final String simple;
  final List<String> more;
  final String? example;
  final String? tip;

  const InfoTopic({
    required this.icon,
    required this.title,
    required this.simple,
    this.more = const [],
    this.example,
    this.tip,
  });
}

class Topics {
  static const breakout = InfoTopic(
    icon: Icons.trending_up_rounded,
    title: 'What is a breakout?',
    simple:
        'A breakout is when a price moves past the highest or lowest point it has reached so far today.',
    more: [
      'Picture the day\'s highest price as a ceiling and its lowest price as a floor. While the price stays between them, nothing unusual is happening. When it pushes through the ceiling or drops through the floor, that is a breakout.',
      'Traders watch breakouts because they can mean a new wave of buying or selling has started. Our AI scans the market and posts an alert whenever one happens.',
    ],
    example:
        'Say Nifty has moved between 24,800 and 24,950 all morning. At 10:42 it touches 24,955. That is a new high for the day, so an upside breakout alert appears.',
    tip: 'An alert means "pay attention", not "the price will keep going".',
  );

  static const newHigh = InfoTopic(
    icon: Icons.arrow_upward_rounded,
    title: 'New highs',
    simple:
        'This counts how many times the price climbed above its highest level of the day.',
    more: [
      'Each new high means buyers were willing to pay more than anyone had paid earlier that day.',
      'A few new highs in a row usually show steady buying. One lone high that quickly falls back can be a false alarm.',
    ],
    tip: 'More new highs than new lows usually means buyers are stronger.',
  );

  static const newLow = InfoTopic(
    icon: Icons.arrow_downward_rounded,
    title: 'New lows',
    simple:
        'This counts how many times the price dropped below its lowest level of the day.',
    more: [
      'Each new low means sellers accepted a lower price than anyone had earlier that day.',
      'Several new lows close together often show that selling pressure is building.',
    ],
    tip: 'More new lows than new highs usually means sellers are stronger.',
  );

  static const firstAlert = InfoTopic(
    icon: Icons.schedule_rounded,
    title: 'First alert',
    simple:
        'The time of the very first breakout alert for this index on the selected day.',
    more: [
      'Early alerts can show which way the day started. The price shown next to the index is measured from this first alert, so you can see how far it has moved since.',
    ],
  );

  static const mood = InfoTopic(
    icon: Icons.balance_rounded,
    title: 'Market mood',
    simple:
        'A quick summary we work out for you by comparing how many new highs and new lows appeared.',
    more: [
      'Mostly highs: "Buyers are in control".',
      'Mostly lows: "Sellers are in control".',
      'A fairly even mix: "Buyers and sellers are split", meaning the market can\'t decide yet.',
      'The mood only describes what already happened today. It does not predict what comes next.',
    ],
    tip:
        'Think of it as a tug of war. The mood tells you who is pulling harder right now.',
  );

  static const indices = InfoTopic(
    icon: Icons.stacked_bar_chart_rounded,
    title: 'What are Nifty 50 and Bank Nifty?',
    simple:
        'They are scoreboards that track how a group of big companies is doing, instead of just one company.',
    more: [
      'Nifty 50 follows 50 of the largest companies listed on India\'s National Stock Exchange. It is the most common way to describe how "the market" is doing.',
      'Bank Nifty follows the biggest banking companies. It tends to move faster and more sharply than Nifty 50.',
      'When the index goes up, most of the companies inside it are generally rising too.',
    ],
  );

  static const candles = InfoTopic(
    icon: Icons.candlestick_chart_rounded,
    title: 'How to read the chart',
    simple:
        'Each little bar (a candle) shows what the price did during one short slice of time.',
    more: [
      'Green candle: the price finished higher than it started in that slice.',
      'Red candle: the price finished lower than it started.',
      'The thick part is where the price opened and closed. The thin lines above and below show the highest and lowest points it touched.',
      'Vertical lines mark alerts. The solid line is the first alert. Dashed lines are later ones. The small triangles point to the first new high and first new low.',
      'Tap the chart to see exact numbers for any candle.',
    ],
    tip: 'Tap and hold on a candle to see Open, High, Low and Close.',
  );

  static const session = InfoTopic(
    icon: Icons.access_time_rounded,
    title: 'Trading sessions',
    simple:
        'The market is open from 9:15 AM to 3:30 PM (India time). Sessions let you zoom into one part of that day.',
    more: [
      'The opening hour is usually the busiest and most unpredictable.',
      'Around noon things often go quiet.',
      'The last couple of hours can get busy again as traders close out their positions.',
      'Choosing a session only changes what you see on this screen. Nothing is lost.',
    ],
  );

  static const accuracy = InfoTopic(
    icon: Icons.insights_rounded,
    title: 'Past accuracy',
    simple:
        'Opens a report that looks back at earlier alerts and checks what the price did afterwards.',
    more: [
      'This is called a back-test. It helps you judge how reliable alerts have been, instead of trusting them blindly.',
      'Past results never guarantee future results, but they are a good reality check.',
    ],
  );

  static const disclaimer = InfoTopic(
    icon: Icons.school_rounded,
    title: 'Learning tool, not advice',
    simple:
        'Everything on this page is meant to help you understand the market. It is not a recommendation to buy or sell anything.',
    more: [
      'Breakouts can fail. Prices sometimes poke through a high or low and then turn back. Traders call this a "false breakout".',
      'Before making any financial decision, do your own research and consider speaking with a licensed advisor.',
    ],
    tip: 'Never risk money you can\'t afford to lose.',
  );

  static const all = <InfoTopic>[
    breakout,
    newHigh,
    newLow,
    mood,
    firstAlert,
    indices,
    candles,
    session,
    accuracy,
    disclaimer,
  ];
}

// Shown once per app run.
bool _welcomeShown = false;

Future<void> showInfoDialog(BuildContext context, InfoTopic t, Pal p,
    {bool glossaryLink = true}) {
  return showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: p.card,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: p.line),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: p.accent.withOpacity(p.dark ? 0.16 : 0.22),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(t.icon,
                        size: 22, color: p.dark ? p.accent : p.ink),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(t.title,
                        style: _ts(p.ink, 19,
                            w: FontWeight.w800, ls: -0.3, h: 1.2)),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: p.chip,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('In simple words',
                        style: _ts(p.sub, 12, w: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(t.simple,
                        style: _ts(p.ink, 15, w: FontWeight.w600, h: 1.45)),
                  ],
                ),
              ),
              for (final para in t.more) ...[
                const SizedBox(height: 14),
                Text(para, style: _ts(p.sub, 14, h: 1.55)),
              ],
              if (t.example != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: p.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(Icons.lightbulb_outline_rounded,
                            size: 16, color: p.amber),
                        const SizedBox(width: 6),
                        Text('Example (illustrative numbers)',
                            style: _ts(p.ink, 12.5, w: FontWeight.w700)),
                      ]),
                      const SizedBox(height: 8),
                      Text(t.example!, style: _ts(p.sub, 13.5, h: 1.5)),
                    ],
                  ),
                ),
              ],
              if (t.tip != null) ...[
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.tips_and_updates_outlined,
                        size: 16, color: p.sub),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(t.tip!,
                          style: _ts(p.ink, 13, w: FontWeight.w600, h: 1.45)),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: p.accent,
                    foregroundColor: p.onAccent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text('Got it',
                      style: _ts(p.onAccent, 15, w: FontWeight.w800)),
                ),
              ),
              if (glossaryLink)
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      showGlossary(context, p);
                    },
                    child: Text('Browse all terms',
                        style: _ts(p.sub, 13, w: FontWeight.w600)),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> showGlossary(BuildContext context, Pal p) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scroll) => Container(
        decoration: BoxDecoration(
          color: p.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: p.line,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Learn the basics',
                style: _ts(p.ink, 24, w: FontWeight.w800, ls: -0.5)),
            const SizedBox(height: 6),
            Text(
              'New to this? Tap any topic for a plain-language explanation.',
              style: _ts(p.sub, 14, h: 1.45),
            ),
            const SizedBox(height: 20),
            for (final t in Topics.all)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: p.card,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => showInfoDialog(ctx, t, p, glossaryLink: false),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: p.line),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: p.chip,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(t.icon, size: 20, color: p.ink),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t.title,
                                    style:
                                        _ts(p.ink, 14.5, w: FontWeight.w700)),
                                const SizedBox(height: 2),
                                Text(t.simple,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: _ts(p.sub, 12.5, h: 1.4)),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: p.muted),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

Future<void> showWelcomeDialog(BuildContext context, Pal p) {
  Widget row(IconData icon, String title, String body) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: p.chip,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 19, color: p.ink),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: _ts(p.ink, 14.5, w: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(body, style: _ts(p.sub, 13, h: 1.45)),
                ],
              ),
            ),
          ],
        ),
      );

  return showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: p.card,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: p.line),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome. Here\'s the 30-second version.',
                style: _ts(p.ink, 21, w: FontWeight.w800, ls: -0.4, h: 1.25)),
            const SizedBox(height: 8),
            Text(
              'This page shows the moments when the market moved past its own high or low of the day.',
              style: _ts(p.sub, 14, h: 1.5),
            ),
            const SizedBox(height: 22),
            row(Icons.trending_up_rounded, 'A breakout is a signal to notice',
                'It happens when a price goes above its high or below its low for the day.'),
            row(Icons.balance_rounded, 'Each card tells you who is winning',
                'Buyers, sellers, or neither, plus a chart of what happened.'),
            row(Icons.info_outline_rounded, 'Tap any info icon',
                'You\'ll get a short explanation in everyday language.'),
            row(Icons.school_rounded, 'For learning, not advice',
                'Nothing here tells you to buy or sell.'),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: p.accent,
                  foregroundColor: p.onAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('Start exploring',
                    style: _ts(p.onAccent, 15, w: FontWeight.w800)),
              ),
            ),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  showGlossary(context, p);
                },
                child: Text('Learn the terms first',
                    style: _ts(p.sub, 13, w: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// PAGE
// ═════════════════════════════════════════════════════════════════════════════

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _welcomeShown) return;
      _welcomeShown = true;
      final isDark = Theme.of(context).brightness == Brightness.dark;
      showWelcomeDialog(context, Pal.of(isDark));
    });
  }

  Future<void> _fetchData({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final y = _selectedDate.year;
      final m = _selectedDate.month;
      final d = _selectedDate.day;

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
      final allOhlcv =
          (ohlcvRes as List).map((e) => OhlcvEntry.fromMap(e)).toList();

      final groupedMap = <String, GroupedIndex>{};

      for (final pick in picks) {
        final mapped = mapSymbol(pick.symbol);
        groupedMap.putIfAbsent(
          mapped,
          () => GroupedIndex(
            symbol: pick.symbol,
            mappedSymbol: mapped,
            sentiment: pick.sentiment ?? 'Neutral',
            firstSeenIso: pick.snapshotTime,
            startPrice: pick.close,
            picks: [],
            ohlcvData: [],
          ),
        );
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

        final highs = group.picks.where((p) => p.isUpBreakout).toList();
        final lows = group.picks.where((p) => !p.isUpBreakout).toList();
        if (highs.isNotEmpty) group.firstHighIso = highs.first.snapshotTime;
        if (lows.isNotEmpty) group.firstLowIso = lows.first.snapshotTime;
      });

      const order = ['NIFTY', 'BANKNIFTY'];
      final list = groupedMap.values.toList()
        ..sort((a, b) {
          final ia = order.indexOf(a.mappedSymbol);
          final ib = order.indexOf(b.mappedSymbol);
          return (ia < 0 ? 99 : ia).compareTo(ib < 0 ? 99 : ib);
        });

      if (!mounted) return;
      setState(() {
        _groups = list;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
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

  Future<void> _pickDate() async {
    final today = getTodayIST();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023, 1, 1),
      lastDate: DateTime(today.year, today.month, today.day),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final p = Pal.of(isDark);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: p.bg,
        body: SafeArea(
          child: Column(
            children: [
              _Header(
                p: p,
                onHelp: () => showGlossary(context, p),
                onAccuracy: () => Get.toNamed('/backtest/nifty'),
                onAccuracyInfo: () =>
                    showInfoDialog(context, Topics.accuracy, p),
              ),
              _DateBar(
                p: p,
                date: _selectedDate,
                isToday: _isToday,
                onPrev: _prevDay,
                onNext: _nextDay,
                onPick: _pickDate,
              ),
              Expanded(child: _body(p)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(Pal p) {
    if (_loading) return _SkeletonView(p: p);
    if (_error != null) {
      return _ErrorView(p: p, error: _error!, onRetry: _fetchData);
    }

    return RefreshIndicator(
      color: p.onAccent,
      backgroundColor: p.accent,
      onRefresh: () => _fetchData(silent: true),
      child: _groups.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _EmptyView(
                  p: p,
                  date: _selectedDate,
                  isToday: _isToday,
                  onPrev: _prevDay,
                ),
              ],
            )
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              children: [
                _HeroSummary(p: p, groups: _groups, isToday: _isToday),
                const SizedBox(height: 20),
                _SessionBar(
                  p: p,
                  selected: _timeFilter,
                  onSelect: (f) => setState(() => _timeFilter = f),
                ),
                const SizedBox(height: 16),
                for (final g in _groups)
                  _IndexCard(
                    key: ValueKey('${g.mappedSymbol}-${_selectedDate.day}'),
                    p: p,
                    group: g,
                    timeFilter: _timeFilter,
                    selectedDate: _selectedDate,
                  ),
                _DisclaimerCard(p: p),
              ],
            ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// HEADER + DATE BAR
// ═════════════════════════════════════════════════════════════════════════════
class _Header extends StatelessWidget {
  final Pal p;
  final VoidCallback onHelp;
  final VoidCallback onAccuracy;
  final VoidCallback onAccuracyInfo;

  const _Header({
    required this.p,
    required this.onHelp,
    required this.onAccuracy,
    required this.onAccuracyInfo,
  });

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(canPop ? 4 : 20, 8, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: back button + title
          Row(
            children: [
              if (canPop)
                IconButton(
                  onPressed: () => Navigator.maybePop(context),
                  icon: Icon(Icons.arrow_back_ios_new_rounded,
                      size: 18, color: p.ink),
                ),
              Expanded(
                child: Text('Index breakouts',
                    style: _ts(p.ink, 22, w: FontWeight.w800, ls: -0.6)),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Learn the basics',
                onPressed: onHelp,
                icon: Icon(Icons.help_outline_rounded, size: 24, color: p.ink),
              ),
            ],
          ),
          // Row 2: subtitle + accuracy chip + help button
          Row(
            children: [
              const SizedBox(width: 28),
              Expanded(
                child: Text('When the market breaks its high or low',
                    style: _ts(p.sub, 12.5)),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onAccuracy,
                onLongPress: onAccuracyInfo,
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: p.card,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: p.line),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.insights_rounded, size: 16, color: p.ink),
                      const SizedBox(width: 6),
                      Text('Past accuracy',
                          style: _ts(p.ink, 12.5, w: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // IconButton(
              //   tooltip: 'Learn the basics',
              //   onPressed: onHelp,
              //   icon: Icon(Icons.help_outline_rounded, size: 24, color: p.ink),
              // ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DateBar extends StatelessWidget {
  final Pal p;
  final DateTime date;
  final bool isToday;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onPick;

  const _DateBar({
    required this.p,
    required this.date,
    required this.isToday,
    required this.onPrev,
    required this.onNext,
    required this.onPick,
  });

  Widget _btn(IconData icon, VoidCallback? onTap) => Opacity(
        opacity: onTap == null ? 0.3 : 1,
        child: Material(
          color: p.card,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: p.line),
              ),
              child: Icon(icon, size: 22, color: p.ink),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          _btn(Icons.chevron_left_rounded, onPrev),
          Expanded(
            child: GestureDetector(
              onTap: onPick,
              child: Container(
                height: 44,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: p.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: p.line),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 15, color: p.sub),
                    const SizedBox(width: 8),
                    Text(DateFormat('EEE, d MMM yyyy').format(date),
                        style: _ts(p.ink, 14, w: FontWeight.w700)),
                    if (isToday) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: p.accent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text('Today',
                            style: _ts(p.onAccent, 11, w: FontWeight.w800)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          _btn(Icons.chevron_right_rounded, isToday ? null : onNext),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// HERO SUMMARY — one sentence that answers "what's going on?"
// ═════════════════════════════════════════════════════════════════════════════

class _HeroSummary extends StatelessWidget {
  final Pal p;
  final List<GroupedIndex> groups;
  final bool isToday;

  const _HeroSummary(
      {required this.p, required this.groups, required this.isToday});

  @override
  Widget build(BuildContext context) {
    final total = groups.fold<int>(0, (s, g) => s + g.picks.length);
    final highs = groups.fold<int>(0, (s, g) => s + g.upCount);
    final lows = total - highs;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
      decoration: BoxDecoration(
        color: p.hero,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isToday ? 'The short version for today' : 'The short version',
              style: _ts(p.onHeroSub, 13, w: FontWeight.w600)),
          const SizedBox(height: 10),
          Text(
            heroHeadline(groups),
            style: _ts(p.onHero, 26, w: FontWeight.w800, ls: -0.8, h: 1.18),
          ),
          const SizedBox(height: 14),
          Text(
            '$total breakout ${total == 1 ? 'alert' : 'alerts'} so far: '
            '$highs new ${highs == 1 ? 'high' : 'highs'} and '
            '$lows new ${lows == 1 ? 'low' : 'lows'}.',
            style: _ts(p.onHeroSub, 14, h: 1.45),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => showInfoDialog(context, Topics.breakout, p),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: p.accent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.help_outline_rounded, size: 16, color: p.onAccent),
                  const SizedBox(width: 6),
                  Text('What is a breakout?',
                      style: _ts(p.onAccent, 13, w: FontWeight.w800)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SESSION FILTER
// ═════════════════════════════════════════════════════════════════════════════

class _SessionBar extends StatelessWidget {
  final Pal p;
  final TimeRangeFilter selected;
  final ValueChanged<TimeRangeFilter> onSelect;

  const _SessionBar(
      {required this.p, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Zoom into part of the day',
                style: _ts(p.ink, 15, w: FontWeight.w800)),
            _InfoDot(p: p, topic: Topics.session),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 54,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final f in TimeRangeFilter.values)
                _SessionChip(
                  p: p,
                  filter: f,
                  active: f == selected,
                  onTap: () => onSelect(f),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            sessionHint(selected),
            key: ValueKey(selected),
            style: _ts(p.sub, 12.5, h: 1.45),
          ),
        ),
      ],
    );
  }
}

class _SessionChip extends StatelessWidget {
  final Pal p;
  final TimeRangeFilter filter;
  final bool active;
  final VoidCallback onTap;

  const _SessionChip({
    required this.p,
    required this.filter,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = active ? p.onAccent : p.ink;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? p.accent : p.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: active ? p.accent : p.line),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(sessionName(filter), style: _ts(fg, 13, w: FontWeight.w800)),
            const SizedBox(height: 1),
            Text(timeRangeLabel(filter),
                style: _ts(active ? p.onAccent.withOpacity(0.75) : p.sub, 11)),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// INDEX CARD
// ═════════════════════════════════════════════════════════════════════════════

class _IndexCard extends StatefulWidget {
  final Pal p;
  final GroupedIndex group;
  final TimeRangeFilter timeFilter;
  final DateTime selectedDate;

  const _IndexCard({
    super.key,
    required this.p,
    required this.group,
    required this.timeFilter,
    required this.selectedDate,
  });

  @override
  State<_IndexCard> createState() => _IndexCardState();
}

class _IndexCardState extends State<_IndexCard> {
  bool _showAll = false;
  static const _previewCount = 4;

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final g = widget.group;
    final mood = moodFor(g);
    final mColor = moodColor(mood.kind, p);
    final positive = (g.priceChange ?? 0) >= 0;
    final changeColor = positive ? p.bull : p.bear;
    final pct = g.changePct;

    final sessionPicks =
        picksInRange(g, widget.timeFilter, widget.selectedDate);
    final visiblePicks =
        _showAll ? sessionPicks : sessionPicks.take(_previewCount).toList();
    final firstHighId = g.picks.where((x) => x.isUpBreakout).firstOrNull?.id;
    final firstLowId = g.picks.where((x) => !x.isUpBreakout).firstOrNull?.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: p.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title + price ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(friendlyName(g.mappedSymbol),
                                overflow: TextOverflow.ellipsis,
                                style: _ts(p.ink, 24,
                                    w: FontWeight.w800, ls: -0.6)),
                          ),
                          _InfoDot(p: p, topic: Topics.indices),
                        ],
                      ),
                      Text(g.mappedSymbol, style: _ts(p.sub, 12.5)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(fmtPrice(g.latestPrice),
                        style: _ts(p.ink, 22, w: FontWeight.w800, ls: -0.4)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: changeColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                              positive
                                  ? Icons.arrow_drop_up_rounded
                                  : Icons.arrow_drop_down_rounded,
                              size: 20,
                              color: changeColor),
                          Text(
                            g.priceChange == null
                                ? '—'
                                : '${positive ? '+' : ''}${g.priceChange!.toStringAsFixed(2)}'
                                    '${pct != null ? ' (${pct.toStringAsFixed(2)}%)' : ''}',
                            style: _ts(changeColor, 12.5, w: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('since first alert', style: _ts(p.muted, 11)),
                  ],
                ),
              ],
            ),
          ),

          // ── Mood banner ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Material(
              color: mColor.withOpacity(p.dark ? 0.14 : 0.09),
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => showInfoDialog(context, Topics.mood, p),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: mColor.withOpacity(0.18),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(mood.icon, size: 20, color: mColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(mood.label,
                                style: _ts(p.ink, 15, w: FontWeight.w800)),
                            const SizedBox(height: 2),
                            Text(mood.line, style: _ts(p.sub, 12.5, h: 1.4)),
                          ],
                        ),
                      ),
                      Icon(Icons.info_outline_rounded, size: 18, color: p.sub),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Stat tiles ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: _StatTile(
                    p: p,
                    icon: Icons.arrow_upward_rounded,
                    color: p.bull,
                    label: 'New highs',
                    value: '${g.upCount}',
                    caption: 'price went up past its high',
                    topic: Topics.newHigh,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatTile(
                    p: p,
                    icon: Icons.arrow_downward_rounded,
                    color: p.bear,
                    label: 'New lows',
                    value: '${g.downCount}',
                    caption: 'price went down past its low',
                    topic: Topics.newLow,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatTile(
                    p: p,
                    icon: Icons.schedule_rounded,
                    color: p.sub,
                    label: 'First alert',
                    value: formatTimeIST(g.firstSeenIso),
                    caption: 'first signal of the day',
                    topic: Topics.firstAlert,
                  ),
                ),
              ],
            ),
          ),

          // ── Chart ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 12, 0),
            child: Row(
              children: [
                Text('Price chart', style: _ts(p.ink, 15, w: FontWeight.w800)),
                _InfoDot(p: p, topic: Topics.candles),
                const Spacer(),
                Text(sessionName(widget.timeFilter),
                    style: _ts(p.sub, 12, w: FontWeight.w600)),
                const SizedBox(width: 8),
              ],
            ),
          ),
          Container(
            height: 270,
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            decoration: BoxDecoration(
              color: p.dark ? p.bg.withOpacity(0.5) : p.bg.withOpacity(0.55),
              borderRadius: BorderRadius.circular(18),
            ),
            child: g.ohlcvData.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.candlestick_chart_outlined,
                            size: 30, color: p.muted),
                        const SizedBox(height: 8),
                        Text('No price data for this day',
                            style: _ts(p.sub, 12.5)),
                      ],
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: _ChartArea(
                      p: p,
                      group: g,
                      mood: mColor,
                      timeFilter: widget.timeFilter,
                      selectedDate: widget.selectedDate,
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _LegendItem(
                  p: p,
                  leading: Icon(Icons.arrow_drop_up_rounded,
                      size: 20, color: p.bull),
                  text: 'First new high',
                ),
                _LegendItem(
                  p: p,
                  leading: Icon(Icons.arrow_drop_down_rounded,
                      size: 20, color: p.bear),
                  text: 'First new low',
                ),
                _LegendItem(
                  p: p,
                  leading: Container(width: 16, height: 2, color: p.sub),
                  text: 'First alert line',
                ),
                _LegendItem(
                  p: p,
                  leading: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 5, height: 2, color: p.sub),
                    const SizedBox(width: 3),
                    Container(width: 5, height: 2, color: p.sub),
                  ]),
                  text: 'Later alerts',
                ),
              ],
            ),
          ),

          // ── Timeline ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Row(
              children: [
                Text('Alerts in this session',
                    style: _ts(p.ink, 15, w: FontWeight.w800)),
                const Spacer(),
                Text(
                  '${sessionPicks.length} of ${g.picks.length}',
                  style: _ts(p.sub, 12.5, w: FontWeight.w600),
                ),
              ],
            ),
          ),
          if (sessionPicks.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Text(
                'No breakouts happened during this part of the day. Try another session above.',
                style: _ts(p.sub, 13, h: 1.5),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                children: [
                  for (var i = 0; i < visiblePicks.length; i++)
                    _AlertRow(
                      p: p,
                      pick: visiblePicks[i],
                      isFirst: visiblePicks[i].id == firstHighId ||
                          visiblePicks[i].id == firstLowId,
                      showDivider: i != visiblePicks.length - 1,
                    ),
                ],
              ),
            ),
          if (sessionPicks.length > _previewCount)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
              child: TextButton(
                onPressed: () => setState(() => _showAll = !_showAll),
                child: Text(
                  _showAll
                      ? 'Show fewer'
                      : 'Show ${sessionPicks.length - _previewCount} more',
                  style: _ts(p.ink, 13, w: FontWeight.w700),
                ),
              ),
            ),

          // ── Plain-language takeaway ──
          const SizedBox(height: 8),
          Divider(height: 1, color: p.line),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 20),
              childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
              iconColor: p.ink,
              collapsedIconColor: p.sub,
              shape: const Border(),
              collapsedShape: const Border(),
              title: Row(
                children: [
                  Icon(Icons.lightbulb_outline_rounded,
                      size: 18, color: p.amber),
                  const SizedBox(width: 8),
                  Text('What does this mean for me?',
                      style: _ts(p.ink, 14, w: FontWeight.w700)),
                ],
              ),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(_takeaway(mood.kind),
                      style: _ts(p.sub, 13.5, h: 1.55)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _takeaway(MoodKind k) {
    switch (k) {
      case MoodKind.buyers:
        return 'The price kept setting fresh highs, which usually means buyers were more eager than sellers. That can be a sign of strength, but breakouts do fail sometimes. A useful habit is to check whether the price stays above the level it just broke. If it slips straight back, the move may have been a false alarm.';
      case MoodKind.sellers:
        return 'The price kept falling to fresh lows, which usually means sellers were more eager than buyers. That can signal weakness, but prices can also bounce back quickly. Notice whether the price stays under the level it just broke, or recovers.';
      case MoodKind.mixed:
        return 'The price broke both its high and its low today. That usually means the market is unsure and swinging back and forth. Mixed signals are a reminder that a single alert doesn\'t tell the whole story.';
    }
  }
}

class _StatTile extends StatelessWidget {
  final Pal p;
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String caption;
  final InfoTopic topic;

  const _StatTile({
    required this.p,
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.caption,
    required this.topic,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: p.chip,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => showInfoDialog(context, topic, p),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 14, color: color),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(label,
                        overflow: TextOverflow.ellipsis,
                        style: _ts(p.sub, 11.5, w: FontWeight.w700)),
                  ),
                  Icon(Icons.info_outline_rounded, size: 13, color: p.muted),
                ],
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value,
                    style: _ts(p.ink, 20, w: FontWeight.w800, ls: -0.4)),
              ),
              const SizedBox(height: 2),
              Text(caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _ts(p.muted, 10.5, h: 1.3)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Pal p;
  final Widget leading;
  final String text;

  const _LegendItem(
      {required this.p, required this.leading, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        leading,
        const SizedBox(width: 5),
        Text(text, style: _ts(p.sub, 11.5)),
      ],
    );
  }
}

class _AlertRow extends StatelessWidget {
  final Pal p;
  final IndexEntry pick;
  final bool isFirst;
  final bool showDivider;

  const _AlertRow({
    required this.p,
    required this.pick,
    required this.isFirst,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final up = pick.isUpBreakout;
    final color = up ? p.bull : p.bear;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: showDivider ? Border(bottom: BorderSide(color: p.line)) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              size: 17,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  up
                      ? 'Went above the day\'s high'
                      : 'Fell below the day\'s low',
                  style: _ts(p.ink, 13.5, w: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  'at ${formatTimeIST(pick.snapshotTime)}'
                  '${pick.close != null ? ', price ${fmtPrice(pick.close)}' : ''}',
                  style: _ts(p.sub, 12),
                ),
              ],
            ),
          ),
          if (isFirst)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                border: Border.all(color: p.line),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text('First of the day',
                  style: _ts(p.sub, 10.5, w: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}

class _InfoDot extends StatelessWidget {
  final Pal p;
  final InfoTopic topic;

  const _InfoDot({required this.p, required this.topic});

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      radius: 18,
      onTap: () => showInfoDialog(context, topic, p),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(Icons.info_outline_rounded, size: 17, color: p.sub),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// CHART
// ═════════════════════════════════════════════════════════════════════════════

class _ChartArea extends StatelessWidget {
  final Pal p;
  final GroupedIndex group;
  final Color mood;
  final TimeRangeFilter timeFilter;
  final DateTime selectedDate;

  const _ChartArea({
    required this.p,
    required this.group,
    required this.mood,
    required this.timeFilter,
    required this.selectedDate,
  });

  double _xInterval(TimeRangeFilter f) {
    switch (f) {
      case TimeRangeFilter.firstHour:
      case TimeRangeFilter.midMorning:
      case TimeRangeFilter.preNoon:
        return 15;
      case TimeRangeFilter.afternoon:
        return 30;
      case TimeRangeFilter.all:
        return 60;
    }
  }

  @override
  Widget build(BuildContext context) {
    final chartData = group.ohlcvData
        .map((o) => ChartDataPoint(
              timestamp: getLocalIstTime(o.ts),
              open: o.open,
              high: o.high,
              low: o.low,
              close: o.close,
            ))
        .toList();

    final b = timeRangeBounds(timeFilter);
    final y = selectedDate.year;
    final mo = selectedDate.month;
    final da = selectedDate.day;
    final xMin = DateTime(y, mo, da, b.sh, b.sm);
    final xMax = DateTime(y, mo, da, b.eh, b.em);

    final inRange = chartData
        .where((c) => !c.timestamp.isBefore(xMin) && !c.timestamp.isAfter(xMax))
        .length;
    if (inRange == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'There is no price data for this part of the day yet.',
            textAlign: TextAlign.center,
            style: _ts(p.sub, 12.5, h: 1.5),
          ),
        ),
      );
    }

    final gridColor = p.line.withOpacity(0.8);
    final visiblePicks = picksInRange(group, timeFilter, selectedDate);

    IndexEntry? firstHigh;
    IndexEntry? firstLow;
    for (final pk in visiblePicks) {
      if (pk.isUpBreakout && firstHigh == null) firstHigh = pk;
      if (!pk.isUpBreakout && firstLow == null) firstLow = pk;
    }

    final plotBands = <PlotBand>[];
    for (final pk in visiblePicks) {
      final t = getLocalIstTime(pk.snapshotTime);
      final isUp = pk.isUpBreakout;
      final c = isUp ? p.bull : p.bear;
      final first =
          (isUp && firstHigh?.id == pk.id) || (!isUp && firstLow?.id == pk.id);
      plotBands.add(PlotBand(
        isVisible: true,
        start: t,
        end: t,
        borderWidth: first ? 1.8 : 1.0,
        borderColor: first ? c : c.withOpacity(0.4),
        dashArray: first ? const <double>[] : const <double>[3, 4],
      ));
    }

    final highMarks = <ChartDataPoint>[];
    final lowMarks = <ChartDataPoint>[];
    if (firstHigh != null) {
      final t = getLocalIstTime(firstHigh.snapshotTime);
      final c = closestCandle(group.ohlcvData, t);
      if (c != null) {
        highMarks.add(ChartDataPoint(
          timestamp: t,
          open: c.open,
          high: c.high + c.high * 0.0008,
          low: c.low,
          close: c.close,
        ));
      }
    }
    if (firstLow != null) {
      final t = getLocalIstTime(firstLow.snapshotTime);
      final c = closestCandle(group.ohlcvData, t);
      if (c != null) {
        lowMarks.add(ChartDataPoint(
          timestamp: t,
          open: c.open,
          high: c.high,
          low: c.low - c.low * 0.0008,
          close: c.close,
        ));
      }
    }

    final axisLabel = _ts(p.muted, 10.5);

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 14, 10, 8),
      child: SfCartesianChart(
        backgroundColor: Colors.transparent,
        plotAreaBorderWidth: 0,
        margin: EdgeInsets.zero,
        trackballBehavior: TrackballBehavior(
          enable: true,
          activationMode: ActivationMode.singleTap,
          tooltipSettings: InteractiveTooltip(
            enable: true,
            color: p.card,
            borderColor: p.line,
            borderWidth: 1,
            format:
                'point.x\nO: point.open  H: point.high\nL: point.low  C: point.close',
            textStyle: _ts(p.ink, 11.5, w: FontWeight.w600),
          ),
          markerSettings: TrackballMarkerSettings(
            markerVisibility: TrackballVisibilityMode.visible,
            color: p.ink,
            borderColor: p.ink,
            borderWidth: 2,
            height: 6,
            width: 6,
          ),
          lineColor: p.muted,
          lineWidth: 1,
          lineDashArray: const [4, 4],
        ),
        primaryXAxis: DateTimeAxis(
          minimum: xMin,
          maximum: xMax,
          majorGridLines: MajorGridLines(
              color: gridColor, width: 1, dashArray: const [2, 4]),
          minorGridLines: const MinorGridLines(width: 0),
          axisLine: const AxisLine(width: 0),
          majorTickLines: const MajorTickLines(size: 0),
          labelStyle: axisLabel,
          dateFormat: DateFormat('h:mm'),
          intervalType: DateTimeIntervalType.minutes,
          interval: _xInterval(timeFilter),
          edgeLabelPlacement: EdgeLabelPlacement.shift,
          plotBands: plotBands,
        ),
        primaryYAxis: NumericAxis(
          opposedPosition: true,
          majorGridLines: MajorGridLines(
              color: gridColor, width: 0.6, dashArray: const [2, 4]),
          minorGridLines: const MinorGridLines(width: 0),
          axisLine: const AxisLine(width: 0),
          majorTickLines: const MajorTickLines(size: 0),
          labelStyle: axisLabel,
          numberFormat: NumberFormat('#,##0'),
        ),
        series: <CartesianSeries>[
          CandleSeries<ChartDataPoint, DateTime>(
            dataSource: chartData,
            xValueMapper: (d, _) => d.timestamp,
            lowValueMapper: (d, _) => d.low,
            highValueMapper: (d, _) => d.high,
            openValueMapper: (d, _) => d.open,
            closeValueMapper: (d, _) => d.close,
            bullColor: p.bull,
            bearColor: p.bear,
            enableSolidCandles: true,
            animationDuration: 600,
            enableTooltip: true,
            spacing: 0.15,
            width: 0.65,
          ),
          if (highMarks.isNotEmpty)
            ScatterSeries<ChartDataPoint, DateTime>(
              dataSource: highMarks,
              xValueMapper: (d, _) => d.timestamp,
              yValueMapper: (d, _) => d.high,
              color: p.bull,
              markerSettings: const MarkerSettings(
                isVisible: true,
                shape: DataMarkerType.triangle,
                height: 10,
                width: 10,
              ),
              enableTooltip: false,
            ),
          if (lowMarks.isNotEmpty)
            ScatterSeries<ChartDataPoint, DateTime>(
              dataSource: lowMarks,
              xValueMapper: (d, _) => d.timestamp,
              yValueMapper: (d, _) => d.low,
              color: p.bear,
              markerSettings: const MarkerSettings(
                isVisible: true,
                shape: DataMarkerType.invertedTriangle,
                height: 10,
                width: 10,
              ),
              enableTooltip: false,
            ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// LOADING / ERROR / EMPTY / DISCLAIMER
// ═════════════════════════════════════════════════════════════════════════════

class _SkeletonView extends StatefulWidget {
  final Pal p;
  const _SkeletonView({required this.p});

  @override
  State<_SkeletonView> createState() => _SkeletonViewState();
}

class _SkeletonViewState extends State<_SkeletonView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _block(double h, {double? w, double r = 16}) => Container(
        height: h,
        width: w,
        decoration: BoxDecoration(
          color: widget.p.line,
          borderRadius: BorderRadius.circular(r),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Opacity(
        opacity: 0.45 + 0.55 * _c.value,
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          children: [
            _block(170, r: 28),
            const SizedBox(height: 20),
            _block(18, w: 180, r: 8),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _block(50, r: 12)),
                const SizedBox(width: 8),
                Expanded(child: _block(50, r: 12)),
                const SizedBox(width: 8),
                Expanded(child: _block(50, r: 12)),
              ],
            ),
            const SizedBox(height: 20),
            _block(320, r: 24),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final Pal p;
  final String error;
  final VoidCallback onRetry;

  const _ErrorView(
      {required this.p, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: p.line),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, size: 32, color: p.bear),
              const SizedBox(height: 14),
              Text('Couldn\'t load breakouts',
                  style: _ts(p.ink, 18, w: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(
                'Check your internet connection and try again.',
                textAlign: TextAlign.center,
                style: _ts(p.sub, 13.5, h: 1.5),
              ),
              const SizedBox(height: 18),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: p.accent,
                  foregroundColor: p.onAccent,
                  minimumSize: const Size(140, 46),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: onRetry,
                child: Text('Try again',
                    style: _ts(p.onAccent, 14, w: FontWeight.w800)),
              ),
              const SizedBox(height: 14),
              Text(error,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: _ts(p.muted, 10.5, h: 1.4)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final Pal p;
  final DateTime date;
  final bool isToday;
  final VoidCallback onPrev;

  const _EmptyView({
    required this.p,
    required this.date,
    required this.isToday,
    required this.onPrev,
  });

  @override
  Widget build(BuildContext context) {
    final weekend = date.weekday >= 6;
    final title = weekend
        ? 'The market is closed on weekends'
        : isToday
            ? 'No breakouts yet today'
            : 'No breakouts on this day';
    final body = weekend
        ? 'Indian markets trade Monday to Friday, 9:15 AM to 3:30 PM. Pick a weekday to see alerts.'
        : isToday
            ? 'Nothing has moved past its high or low of the day so far. Alerts show up here as soon as they happen. Pull down to refresh.'
            : 'The AI didn\'t flag any breakouts on this day. It may also have been a market holiday.';

    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: p.line),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: p.chip,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.hourglass_empty_rounded, size: 28, color: p.sub),
          ),
          const SizedBox(height: 20),
          Text(title,
              textAlign: TextAlign.center,
              style: _ts(p.ink, 19, w: FontWeight.w800, ls: -0.3)),
          const SizedBox(height: 8),
          Text(body,
              textAlign: TextAlign.center, style: _ts(p.sub, 13.5, h: 1.55)),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: p.accent,
                foregroundColor: p.onAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: onPrev,
              child: Text('Go to the previous day',
                  style: _ts(p.onAccent, 14, w: FontWeight.w800)),
            ),
          ),
          TextButton(
            onPressed: () => showInfoDialog(context, Topics.breakout, p),
            child: Text('What is a breakout?',
                style: _ts(p.sub, 13, w: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _DisclaimerCard extends StatelessWidget {
  final Pal p;
  const _DisclaimerCard({required this.p});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => showInfoDialog(context, Topics.disclaimer, p),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: p.line),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.school_outlined, size: 20, color: p.sub),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('For learning, not advice',
                      style: _ts(p.ink, 13.5, w: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(
                    'These alerts help you understand market moves. They are not recommendations to buy or sell, and breakouts can fail. Always do your own research.',
                    style: _ts(p.sub, 12, h: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
