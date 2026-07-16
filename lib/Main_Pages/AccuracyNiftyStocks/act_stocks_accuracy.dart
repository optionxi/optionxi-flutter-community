// =============================================================================
// Atlas × AI Picks — MULTI-STOCK PORTFOLIO DASHBOARD
// -----------------------------------------------------------------------------
// Flutter counterpart of the "AI Picked Stocks" Streamlit backtester. Reuses
// the existing design system (atlas_theme.dart) and the Candle / TimeOfDayLite
// / formatMinutes / Sp primitives from atlas_core.dart so this drops into the
// same app without duplicating that plumbing. Everything else — the models,
// Supabase reads, the outcome engine, and the four screens — is new, because
// this deals with *many* symbols/sectors per day instead of a single index.
//
// Tables expected in Supabase (mirrors the Python job):
//   ai_picked_stocks         — one row per AI pick (symbol, sector, sentiment,
//                               snapshot_time)
//   stock_candles_5m         — 5-min OHLCV candles per (ticker, trading_day),
//                               backfilled by a separate `fetch_candles` job
//   stock_candles_fetch_log  — (ticker, trading_day, has_data) — used to hop
//                               forward to "the next trading day with data"
//                               when carrying a window/hold into future days
//
// SUCCESS LOGIC (unchanged from the Streamlit app — keep this in sync):
//   A pick is "successful" if price EVER traded in the predicted direction at
//   any point during the window (BULLISH → window high > entry, BEARISH →
//   window low < entry) — not just whether the window's final close is
//   favorable. Carrying the window into more days only extends how far that
//   "ever" check looks; it never changes how a single day is judged.
// =============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:optionxi/Components/cust_upgrade_to_pro.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'atlas_core.dart' show Candle, TimeOfDayLite, formatMinutes, MarketHours;
import 'atlas_theme.dart';

// =============================================================================
// CONFIG
// =============================================================================
const String kPicksTable = 'ai_picked_stocks';
const String kCandlesTable = 'stock_candles_5m';
const String kFetchLogTable = 'stock_candles_fetch_log';

const Duration kIstOffset = Duration(hours: 5, minutes: 30);
const int kMaxCarryDays = 5;

const List<int> kMinuteWindows = [15, 30, 45, 60, 90, 120];
const Map<String, int> kDayWindows = {
  '1 Day': 1,
  '2 Days': 2,
  '3 Days': 3,
  '5 Days': 5,
};
const List<int> kLookbackOptions = [1, 2, 3, 5, 7, 10, 14, 21, 30, 60, 90, 180];
const int kDefaultLookback = 5;

const int kExitWindowMin = 5, kExitWindowMax = 375, kExitWindowDefault = 60;
const List<int> kFixedExitMinutes = [5, 10, 15, 20, 25, 30, 45, 60];
const int kStructureStopCandles = 3;

// -----------------------------------------------------------------------------
// TIME HELPERS — all timestamps are kept as "IST wall-clock" DateTimes (i.e.
// tagged UTC internally purely so DateTime doesn't apply local-tz math, same
// trick atlas_core.dart uses for the Nifty candles).
// -----------------------------------------------------------------------------
DateTime _toIstWall(String isoUtc) {
  final utc = DateTime.parse(isoUtc).toUtc();
  final ist = utc.add(kIstOffset);
  return DateTime.utc(
      ist.year, ist.month, ist.day, ist.hour, ist.minute, ist.second);
}

String fmtDay(DateTime dt) => DateFormat('yyyy-MM-dd').format(dt);
String fmtDayShort(DateTime dt) => DateFormat('d MMM').format(dt);
String fmtHm(DateTime dt) => DateFormat('HH:mm').format(dt);

DateTime _parseDay(String day) {
  final p = day.split('-').map(int.parse).toList();
  return DateTime.utc(p[0], p[1], p[2]);
}

DateTime sessionOpenDt(String day) {
  final d = _parseDay(day);
  return DateTime.utc(
      d.year, d.month, d.day, MarketHours.openHour, MarketHours.openMinute);
}

DateTime sessionCloseDt(String day) {
  final d = _parseDay(day);
  // Streamlit reference uses a slightly later session-close (15:30) than the
  // Nifty index's own 15:15 candle close, to allow the final 5-min candle to
  // fully print. Kept as its own constant so it's easy to retune.
  return DateTime.utc(d.year, d.month, d.day, 15, 30);
}

bool isMarketHours(DateTime dt) {
  final m = dt.hour * 60 + dt.minute;
  return m >= (MarketHours.openHour * 60 + MarketHours.openMinute - 5) &&
      m <= (MarketHours.closeHour * 60 + MarketHours.closeMinute + 5);
}

String extractSymbol(String raw) {
  var s = raw;
  if (s.startsWith('NSE:') || s.startsWith('BSE:')) s = s.substring(4);
  if (s.endsWith('-EQ')) s = s.substring(0, s.length - 3);
  return s;
}

String toTicker(String raw) {
  final suffix = raw.startsWith('BSE:') ? '.BO' : '.NS';
  return extractSymbol(raw) + suffix;
}

// -----------------------------------------------------------------------------
// PREDICTION WINDOW — one small sum type instead of a loose dynamic, so the
// engine can switch on `.kind` instead of juggling ints/strings.
// -----------------------------------------------------------------------------
enum _WKind { minutes, fullDay, days }

class PredictionWindow {
  final _WKind kind;
  final int value; // minutes, or day count — ignored for fullDay
  const PredictionWindow._(this.kind, this.value);
  const PredictionWindow.minutes(int m) : this._(_WKind.minutes, m);
  const PredictionWindow.days(int n) : this._(_WKind.days, n);
  static const fullDay = PredictionWindow._(_WKind.fullDay, 0);

  bool get isMinutes => kind == _WKind.minutes;
  bool get isFullDay => kind == _WKind.fullDay;
  bool get isDays => kind == _WKind.days;

  String get label {
    if (isFullDay) return 'Till market close';
    if (isDays) return value == 1 ? '1 Day' : '$value Days';
    return '$value min';
  }

  @override
  bool operator ==(Object other) =>
      other is PredictionWindow && other.kind == kind && other.value == value;
  @override
  int get hashCode => Object.hash(kind, value);
}

// =============================================================================
// MODELS
// =============================================================================
class StockPick {
  final String date; // yyyy-MM-dd, IST
  final String rawSymbol;
  final String symbol;
  final String ticker;
  final String sector;
  final String sentiment; // BULLISH | BEARISH
  final DateTime pickDt; // IST wall-clock
  final String pickTimeIst;

  StockPick({
    required this.date,
    required this.rawSymbol,
    required this.symbol,
    required this.ticker,
    required this.sector,
    required this.sentiment,
    required this.pickDt,
    required this.pickTimeIst,
  });

  String get storeKey => '$ticker|$date';
}

class StockOutcome {
  final StockPick pick;
  final double startPrice, exitPrice, maxPrice, minPrice;
  final double netGainPcnt, maxProfitPcnt, maxLossPcnt;
  final bool success;
  final DateTime? hitTime;
  final double? hitPrice;
  final DateTime peakTime;
  final double timeToPeakMin;
  final double prePeakRiskPcnt;
  final DateTime windowEndDt;
  final bool carriedOver;
  final List<String> carryDays;

  // Present only on structure-stop / fixed-exit-lab rows.
  final double? stopLevel;
  final bool? stoppedOut;
  final double? holdMinutes;

  StockOutcome({
    required this.pick,
    required this.startPrice,
    required this.exitPrice,
    required this.maxPrice,
    required this.minPrice,
    required this.netGainPcnt,
    required this.maxProfitPcnt,
    required this.maxLossPcnt,
    required this.success,
    this.hitTime,
    this.hitPrice,
    required this.peakTime,
    required this.timeToPeakMin,
    required this.prePeakRiskPcnt,
    required this.windowEndDt,
    this.carriedOver = false,
    this.carryDays = const [],
    this.stopLevel,
    this.stoppedOut,
    this.holdMinutes,
  });
}

class StockDailySummary {
  final String date;
  final int picks;
  final int success;
  final double avgNetGain,
      avgMaxProfit,
      avgMaxLoss,
      avgTimeToPeak,
      avgRiskBeforePeak;
  double get accuracy => picks == 0 ? 0 : success / picks * 100;
  StockDailySummary({
    required this.date,
    required this.picks,
    required this.success,
    required this.avgNetGain,
    required this.avgMaxProfit,
    required this.avgMaxLoss,
    required this.avgTimeToPeak,
    required this.avgRiskBeforePeak,
  });
}

class StockStrategyRow {
  final String strategy;
  final int picks;
  final double? winRate, avgGainPcnt, avgRiskPcnt, avgHoldMin, riskAdjScore;
  StockStrategyRow({
    required this.strategy,
    required this.picks,
    this.winRate,
    this.avgGainPcnt,
    this.avgRiskPcnt,
    this.avgHoldMin,
    this.riskAdjScore,
  });
}

class HoldingPoint {
  final int dayOffset;
  final double avgMaxProfit, avgMaxLoss;
  final int n;
  HoldingPoint(this.dayOffset, this.avgMaxProfit, this.avgMaxLoss, this.n);
}

// -----------------------------------------------------------------------------
// SETTINGS — one bag of state, mirrors AtlasSettings from atlas_core.dart.
// -----------------------------------------------------------------------------
class StockSettings {
  int lookbackDays;
  TimeOfDayLite entryStart;
  TimeOfDayLite entryEnd;
  bool carryEnabled;
  PredictionWindow window;
  Set<String> sentiments;
  Set<String> sectors; // empty == "all sectors currently known"

  StockSettings({
    this.lookbackDays = kDefaultLookback,
    TimeOfDayLite? entryStart,
    TimeOfDayLite? entryEnd,
    this.carryEnabled = false,
    this.window = const PredictionWindow.minutes(15),
    Set<String>? sentiments,
    Set<String>? sectors,
  })  : entryStart = entryStart ??
            const TimeOfDayLite(MarketHours.openHour, MarketHours.openMinute),
        entryEnd = entryEnd ??
            const TimeOfDayLite(MarketHours.closeHour, MarketHours.closeMinute),
        sentiments = sentiments ?? {'BULLISH', 'BEARISH'},
        sectors = sectors ?? {};

  StockSettings copy() => StockSettings(
        lookbackDays: lookbackDays,
        entryStart: entryStart,
        entryEnd: entryEnd,
        carryEnabled: carryEnabled,
        window: window,
        sentiments: {...sentiments},
        sectors: {...sectors},
      );
}

// =============================================================================
// SUPABASE SERVICE
// =============================================================================
class StockSupabaseService {
  final SupabaseClient? client;
  StockSupabaseService(this.client);

  Future<List<Map<String, dynamic>>> fetchLastNDays(int days) async {
    if (client == null) return [];
    final nowIst = DateTime.now().toUtc().add(kIstOffset);
    final todayIst = DateTime.utc(nowIst.year, nowIst.month, nowIst.day);
    final startDay = todayIst.subtract(Duration(days: days - 1));
    try {
      final resp = await client!
          .from(kPicksTable)
          .select('*')
          .gte('snapshot_time', '${fmtDay(startDay)}T00:00:00+05:30')
          .lte('snapshot_time', '${fmtDay(todayIst)}T23:59:59+05:30')
          .order('snapshot_time', ascending: true);
      return List<Map<String, dynamic>>.from(resp as List);
    } catch (_) {
      return [];
    }
  }

  Future<List<Candle>?> fetchIntraday5m(String ticker, String day) async {
    if (client == null) return null;
    try {
      final resp = await client!
          .from(kCandlesTable)
          .select('candle_time,open,high,low,close,volume')
          .eq('ticker', ticker)
          .eq('trading_day', day)
          .order('candle_time', ascending: true);
      final rows = List<Map<String, dynamic>>.from(resp as List);
      if (rows.isEmpty) return null;
      return rows
          .map((r) => Candle(
                _toIstWall(r['candle_time'] as String),
                (r['open'] as num).toDouble(),
                (r['high'] as num).toDouble(),
                (r['low'] as num).toDouble(),
                (r['close'] as num).toDouble(),
                (r['volume'] as num?)?.toDouble() ?? 0,
              ))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<String?> findNextTradingDay(String ticker, String day) async {
    if (client == null) return null;
    try {
      final resp = await client!
          .from(kFetchLogTable)
          .select('trading_day')
          .eq('ticker', ticker)
          .eq('has_data', true)
          .gt('trading_day', day)
          .order('trading_day', ascending: true)
          .limit(1);
      final rows = List<Map<String, dynamic>>.from(resp as List);
      if (rows.isEmpty) return null;
      return rows.first['trading_day'] as String;
    } catch (_) {
      return null;
    }
  }

  Future<List<String>> findCarryChain(String ticker, String startDay,
      {int n = kMaxCarryDays}) async {
    final chain = <String>[];
    var current = startDay;
    for (var i = 0; i < n; i++) {
      final next = await findNextTradingDay(ticker, current);
      if (next == null) break;
      chain.add(next);
      current = next;
    }
    return chain;
  }
}

// =============================================================================
// ENGINE
// =============================================================================
class StockEngine {
  /// Groups raw rows by (day, symbol) and keeps only the first (earliest)
  /// pick per group, restricted to market hours. Returns (picks, skippedRows).
  static (List<StockPick>, int) buildFirstPicks(
      List<Map<String, dynamic>> raw) {
    final rows = raw.where((r) {
      final ts = r['snapshot_time'];
      if (ts == null) return false;
      return isMarketHours(_toIstWall(ts as String));
    }).toList();

    final Map<String, List<Map<String, dynamic>>> groups = {};
    for (final r in rows) {
      final dt = _toIstWall(r['snapshot_time'] as String);
      final key = '${fmtDay(dt)}|${r['symbol']}';
      groups.putIfAbsent(key, () => []).add(r);
    }

    final picks = <StockPick>[];
    groups.forEach((_, entries) {
      entries.sort((a, b) => (a['snapshot_time'] as String)
          .compareTo(b['snapshot_time'] as String));
      final first = entries.first;
      final dt = _toIstWall(first['snapshot_time'] as String);
      final rawSymbol = first['symbol'] as String;
      picks.add(StockPick(
        date: fmtDay(dt),
        rawSymbol: rawSymbol,
        symbol: extractSymbol(rawSymbol),
        ticker: toTicker(rawSymbol),
        sector: (first['sector'] as String?) ?? 'General',
        sentiment: ((first['sentiment'] as String?) ?? 'BULLISH').toUpperCase(),
        pickDt: dt,
        pickTimeIst: fmtHm(dt),
      ));
    });
    picks.sort((a, b) {
      final byDate = a.date.compareTo(b.date);
      return byDate != 0 ? byDate : a.pickTimeIst.compareTo(b.pickTimeIst);
    });
    return (picks, raw.length - rows.length);
  }

  static List<StockPick> filterByEntryTimeWindow(
      List<StockPick> picks, TimeOfDayLite start, TimeOfDayLite end) {
    final s0 = start.minutesOfDay, s1 = end.minutesOfDay;
    return picks.where((p) {
      final m = p.pickDt.hour * 60 + p.pickDt.minute;
      return m >= s0 && m <= s1;
    }).toList();
  }

  static List<Candle> _mergeSorted(List<List<Candle>?> parts) {
    final all = <Candle>[];
    for (final p in parts) {
      if (p != null) all.addAll(p);
    }
    all.sort((a, b) => a.ts.compareTo(b.ts));
    return all;
  }

  /// Core outcome computation — mirrors `compute_outcomes` in the Streamlit
  /// app, including multi-day carry-over and the "ever touched" success rule.
  static List<StockOutcome> computeOutcomes(
    List<StockPick> picks,
    Map<String, List<Candle>?> store,
    Map<String, List<String>> chainMap,
    PredictionWindow window,
    bool carryEnabled,
  ) {
    final out = <StockOutcome>[];
    for (final pick in picks) {
      final key = pick.storeKey;
      final dfToday = store[key];
      if (dfToday == null || dfToday.isEmpty) continue;

      final pickDt = pick.pickDt;
      final todayClose = sessionCloseDt(pick.date);
      var combined = dfToday;
      var carried = false;
      var carryDays = <String>[];

      final chain =
          carryEnabled ? (chainMap[key] ?? const <String>[]) : const <String>[];
      DateTime windowEnd;

      if (window.isFullDay) {
        windowEnd = todayClose;
      } else if (window.isDays) {
        final useChain = chain.take(window.value).toList();
        if (useChain.isNotEmpty) {
          combined = _mergeSorted(
              [dfToday, ...useChain.map((d) => store['${pick.ticker}|$d'])]);
          windowEnd = sessionCloseDt(useChain.last);
          carried = true;
          carryDays = useChain;
        } else {
          windowEnd = todayClose; // no carry data fetched yet — fall back
        }
      } else {
        final naiveEnd = pickDt.add(Duration(minutes: window.value));
        if (!naiveEnd.isAfter(todayClose) || !carryEnabled || chain.isEmpty) {
          windowEnd = naiveEnd.isBefore(todayClose) ? naiveEnd : todayClose;
        } else {
          final nextDay = chain.first;
          final nextDf = store['${pick.ticker}|$nextDay'];
          if (nextDf != null && nextDf.isNotEmpty) {
            final overflow = naiveEnd.difference(todayClose);
            final nextOpen = sessionOpenDt(nextDay);
            final candidate = nextOpen.add(overflow);
            final nextClose = sessionCloseDt(nextDay);
            windowEnd = candidate.isBefore(nextClose) ? candidate : nextClose;
            combined = _mergeSorted([dfToday, nextDf]);
            carried = true;
            carryDays = [nextDay];
          } else {
            windowEnd = todayClose;
          }
        }
      }

      final w = combined
          .where((c) => !c.ts.isBefore(pickDt) && !c.ts.isAfter(windowEnd))
          .toList();
      if (w.isEmpty) continue;

      final startPrice = w.first.open;
      final exitPrice = w.last.close;
      final maxPrice = w.map((c) => c.high).reduce(math.max);
      final minPrice = w.map((c) => c.low).reduce(math.min);
      final bearish = pick.sentiment == 'BEARISH';

      double pct(double v) =>
          startPrice == 0 ? 0 : (v - startPrice) / startPrice * 100;
      final netGain = bearish ? -pct(exitPrice) : pct(exitPrice);
      final maxProfit = bearish ? -pct(minPrice) : pct(maxPrice);
      final maxLoss = bearish ? -pct(maxPrice) : pct(minPrice);

      // Success = direction ever reached post-entry (entry candle excluded —
      // its own high/low wicking past its open is just candle noise).
      final postEntry = w.length > 1 ? w.sublist(1) : const <Candle>[];
      var success = false;
      DateTime? hitTime;
      double? hitPrice;
      for (final c in postEntry) {
        if (bearish && c.low < startPrice) {
          success = true;
          hitTime = c.ts;
          hitPrice = c.low;
          break;
        }
        if (!bearish && c.high > startPrice) {
          success = true;
          hitTime = c.ts;
          hitPrice = c.high;
          break;
        }
      }

      final peakCandle = bearish
          ? w.reduce((a, b) => a.low <= b.low ? a : b)
          : w.reduce((a, b) => a.high >= b.high ? a : b);
      final prePeak = w.where((c) => !c.ts.isAfter(peakCandle.ts)).toList();
      final prePeakExtreme = prePeak.isEmpty
          ? startPrice
          : (bearish
              ? prePeak.map((c) => c.high).reduce(math.max)
              : prePeak.map((c) => c.low).reduce(math.min));
      final timeToPeakMin = peakCandle.ts.difference(pickDt).inSeconds / 60.0;
      final prePeakRisk = pct(prePeakExtreme) * (bearish ? -1 : 1);

      out.add(StockOutcome(
        pick: pick,
        startPrice: startPrice,
        exitPrice: exitPrice,
        maxPrice: maxPrice,
        minPrice: minPrice,
        netGainPcnt: netGain,
        maxProfitPcnt: maxProfit,
        maxLossPcnt: maxLoss,
        success: success,
        hitTime: hitTime,
        hitPrice: hitPrice,
        peakTime: peakCandle.ts,
        timeToPeakMin: timeToPeakMin,
        prePeakRiskPcnt: prePeakRisk,
        windowEndDt: windowEnd,
        carriedOver: carried,
        carryDays: carryDays,
      ));
    }
    out.sort((a, b) => b.pick.date.compareTo(a.pick.date));
    return out;
  }

  static List<StockDailySummary> computeDailySummary(
      List<StockOutcome> outcomes) {
    final Map<String, List<StockOutcome>> byDay = {};
    for (final o in outcomes) {
      byDay.putIfAbsent(o.pick.date, () => []).add(o);
    }
    double avg(Iterable<double> xs) {
      final l = xs.toList();
      return l.isEmpty ? 0 : l.reduce((a, b) => a + b) / l.length;
    }

    final list = byDay.entries.map((e) {
      final os = e.value;
      return StockDailySummary(
        date: e.key,
        picks: os.length,
        success: os.where((o) => o.success).length,
        avgNetGain: avg(os.map((o) => o.netGainPcnt)),
        avgMaxProfit: avg(os.map((o) => o.maxProfitPcnt)),
        avgMaxLoss: avg(os.map((o) => o.maxLossPcnt)),
        avgTimeToPeak: avg(os.map((o) => o.timeToPeakMin)),
        avgRiskBeforePeak: avg(os.map((o) => o.prePeakRiskPcnt.abs())),
      );
    }).toList();
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  /// For each additional trading day held from entry (0..maxDays), the
  /// average best-case / worst-case swing across all picks — independent of
  /// whichever window is currently selected. Only meaningful once carry-over
  /// candles have been fetched.
  static List<HoldingPoint> computeHoldingCurve(
    List<StockPick> picks,
    Map<String, List<Candle>?> store,
    Map<String, List<String>> chainMap, {
    int maxDays = kMaxCarryDays,
  }) {
    final rows = <HoldingPoint>[];
    for (var offset = 0; offset <= maxDays; offset++) {
      final profits = <double>[], losses = <double>[];
      for (final pick in picks) {
        final key = pick.storeKey;
        final dfToday = store[key];
        if (dfToday == null || dfToday.isEmpty) continue;
        final chain = chainMap[key] ?? const <String>[];
        final useChain = chain.take(offset).toList();
        if (offset > 0 && useChain.length < offset) continue;
        final combined = _mergeSorted(
            [dfToday, ...useChain.map((d) => store['${pick.ticker}|$d'])]);
        final endDt = useChain.isNotEmpty
            ? sessionCloseDt(useChain.last)
            : sessionCloseDt(pick.date);
        final w = combined
            .where((c) => !c.ts.isBefore(pick.pickDt) && !c.ts.isAfter(endDt))
            .toList();
        if (w.isEmpty) continue;
        final start = w.first.open;
        if (start == 0) continue;
        profits
            .add((w.map((c) => c.high).reduce(math.max) - start) / start * 100);
        losses
            .add((w.map((c) => c.low).reduce(math.min) - start) / start * 100);
      }
      if (profits.isNotEmpty) {
        rows.add(HoldingPoint(
          offset,
          profits.reduce((a, b) => a + b) / profits.length,
          losses.reduce((a, b) => a + b) / losses.length,
          profits.length,
        ));
      }
    }
    return rows;
  }

  /// Holds each pick until price breaks the high (BEARISH) / low (BULLISH)
  /// of the `nCandles` immediately before entry, else exits at day close.
  /// Same-day candles only — no carry-over.
  static List<StockOutcome> computeStructureStopOutcomes(
    List<StockPick> picks,
    Map<String, List<Candle>?> store, {
    int nCandles = kStructureStopCandles,
  }) {
    final out = <StockOutcome>[];
    for (final pick in picks) {
      final candles = store[pick.storeKey];
      if (candles == null || candles.isEmpty) continue;
      final entryDt = pick.pickDt;
      final closeDt = sessionCloseDt(pick.date);

      var entryIdx = 0;
      var bestDiff = candles[0].ts.difference(entryDt).abs();
      for (var i = 1; i < candles.length; i++) {
        final diff = candles[i].ts.difference(entryDt).abs();
        if (diff < bestDiff) {
          bestDiff = diff;
          entryIdx = i;
        }
      }
      if (entryIdx < nCandles) continue;

      final prev = candles.sublist(entryIdx - nCandles, entryIdx);
      final bearish = pick.sentiment == 'BEARISH';
      final stopLevel = bearish
          ? prev.map((c) => c.high).reduce(math.max)
          : prev.map((c) => c.low).reduce(math.min);

      final w = candles
          .where((c) => !c.ts.isBefore(entryDt) && !c.ts.isAfter(closeDt))
          .toList();
      if (w.isEmpty) continue;
      final startPrice = w.first.open;

      var stoppedOut = false;
      double exitPrice = w.last.close;
      DateTime exitTime = w.last.ts;
      for (final c in w) {
        if (bearish && c.high >= stopLevel) {
          exitPrice = stopLevel;
          exitTime = c.ts;
          stoppedOut = true;
          break;
        }
        if (!bearish && c.low <= stopLevel) {
          exitPrice = stopLevel;
          exitTime = c.ts;
          stoppedOut = true;
          break;
        }
      }

      final maxPrice = w.map((c) => c.high).reduce(math.max);
      final minPrice = w.map((c) => c.low).reduce(math.min);
      double pct(double v) =>
          startPrice == 0 ? 0 : (v - startPrice) / startPrice * 100;
      final netGain = bearish ? -pct(exitPrice) : pct(exitPrice);
      final maxProfit = bearish ? -pct(minPrice) : pct(maxPrice);
      final maxLoss = bearish ? -pct(maxPrice) : pct(minPrice);
      final holdMin = exitTime.difference(entryDt).inSeconds / 60.0;

      out.add(StockOutcome(
        pick: pick,
        startPrice: startPrice,
        exitPrice: exitPrice,
        maxPrice: maxPrice,
        minPrice: minPrice,
        netGainPcnt: netGain,
        maxProfitPcnt: maxProfit,
        maxLossPcnt: maxLoss,
        success: netGain > 0,
        peakTime: exitTime,
        timeToPeakMin: holdMin,
        prePeakRiskPcnt: maxLoss,
        windowEndDt: exitTime,
        stopLevel: stopLevel,
        stoppedOut: stoppedOut,
        holdMinutes: holdMin,
      ));
    }
    out.sort((a, b) => b.pick.date.compareTo(a.pick.date));
    return out;
  }

  static (List<StockStrategyRow>, Map<String, List<StockOutcome>>)
      buildExitStrategySummary(
    List<StockPick> picks,
    Map<String, List<Candle>?> store,
  ) {
    final rows = <StockStrategyRow>[];
    final detail = <String, List<StockOutcome>>{};
    double? avgOf(Iterable<double> xs) {
      final l = xs.toList();
      return l.isEmpty ? null : l.reduce((a, b) => a + b) / l.length;
    }

    for (final m in kFixedExitMinutes) {
      final label = 'Exit @ ${m}min';
      final df = computeOutcomes(
          picks, store, const {}, PredictionWindow.minutes(m), false);
      detail[label] = df;
      if (df.isEmpty) {
        rows.add(StockStrategyRow(
            strategy: label, picks: 0, avgHoldMin: m.toDouble()));
      } else {
        rows.add(StockStrategyRow(
          strategy: label,
          picks: df.length,
          winRate: df.where((o) => o.netGainPcnt > 0).length / df.length * 100,
          avgGainPcnt: avgOf(df.map((o) => o.netGainPcnt)),
          avgRiskPcnt: avgOf(df.map((o) => o.maxLossPcnt)),
          avgHoldMin: m.toDouble(),
        ));
      }
    }

    final structLabel = 'Structure Stop (${kStructureStopCandles}c)';
    final structDf = computeStructureStopOutcomes(picks, store);
    detail[structLabel] = structDf;
    if (structDf.isEmpty) {
      rows.add(StockStrategyRow(strategy: structLabel, picks: 0));
    } else {
      rows.add(StockStrategyRow(
        strategy: structLabel,
        picks: structDf.length,
        winRate: structDf.where((o) => o.netGainPcnt > 0).length /
            structDf.length *
            100,
        avgGainPcnt: avgOf(structDf.map((o) => o.netGainPcnt)),
        avgRiskPcnt: avgOf(structDf.map((o) => o.maxLossPcnt)),
        avgHoldMin: avgOf(structDf.map((o) => o.holdMinutes ?? 0)),
      ));
    }

    final scored = rows.map((r) {
      if (r.avgGainPcnt != null &&
          r.avgRiskPcnt != null &&
          r.avgRiskPcnt != 0) {
        return StockStrategyRow(
          strategy: r.strategy,
          picks: r.picks,
          winRate: r.winRate,
          avgGainPcnt: r.avgGainPcnt,
          avgRiskPcnt: r.avgRiskPcnt,
          avgHoldMin: r.avgHoldMin,
          riskAdjScore: r.avgGainPcnt! / r.avgRiskPcnt!.abs(),
        );
      }
      return r;
    }).toList();
    return (scored, detail);
  }
}

// =============================================================================
// APP SHELL
// =============================================================================
class StockDashboardShell extends StatefulWidget {
  const StockDashboardShell({super.key});
  @override
  State<StockDashboardShell> createState() => _StockDashboardShellState();
}

class _StockDashboardShellState extends State<StockDashboardShell> {
  int tab = 0;
  late final StockSupabaseService service;

  StockSettings settings = StockSettings();
  bool loading = false;
  String? error;

  List<StockPick> allPicks = [];
  List<StockPick> filteredPicks = [];
  final Map<String, List<Candle>?> candleStore = {};
  final Map<String, List<String>> chainMap = {};
  final Set<String> noDataPairs = {};

  List<StockOutcome> outcomes = [];
  List<StockDailySummary> dailySummary = [];
  List<HoldingPoint> holdingCurve = [];
  List<StockStrategyRow> exitSummary = [];
  Map<String, List<StockOutcome>> exitDetail = {};

  int skippedRows = 0;
  String? jumpToDate;

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
    service = StockSupabaseService(client);
    _refresh(hardReset: true);
  }

  Future<void> _ensureSameDayCandles(List<StockPick> picks) async {
    final missing =
        picks.where((p) => !candleStore.containsKey(p.storeKey)).toList();
    for (final p in missing) {
      final df = await service.fetchIntraday5m(p.ticker, p.date);
      candleStore[p.storeKey] = df;
      if (df == null) noDataPairs.add('${p.symbol} — ${p.date}');
    }
  }

  Future<void> _ensureCarryOverCandles(List<StockPick> picks) async {
    final missing =
        picks.where((p) => !chainMap.containsKey(p.storeKey)).toList();
    for (final p in missing) {
      final chain = await service.findCarryChain(p.ticker, p.date);
      chainMap[p.storeKey] = chain;
      for (final d in chain) {
        final key = '${p.ticker}|$d';
        if (!candleStore.containsKey(key)) {
          final df = await service.fetchIntraday5m(p.ticker, d);
          candleStore[key] = df;
          if (df == null) noDataPairs.add('${p.symbol} — $d');
        }
      }
    }
  }

  Future<void> _refresh({bool hardReset = false}) async {
    setState(() {
      loading = true;
      error = null;
      if (hardReset) {
        candleStore.clear();
        chainMap.clear();
        noDataPairs.clear();
      }
    });
    try {
      final raw = await service.fetchLastNDays(settings.lookbackDays);
      final (picks, skipped) = StockEngine.buildFirstPicks(raw);
      skippedRows = skipped;
      allPicks = picks;
      var filtered = StockEngine.filterByEntryTimeWindow(
          picks, settings.entryStart, settings.entryEnd);
      if (filtered.isEmpty) {
        _resetComputed();
        return;
      }
      filteredPicks = filtered;
      await _ensureSameDayCandles(filtered);
      if (settings.carryEnabled) {
        await _ensureCarryOverCandles(filtered);
      }
      var allOutcomes = StockEngine.computeOutcomes(filtered, candleStore,
          chainMap, settings.window, settings.carryEnabled);
      allOutcomes = allOutcomes
          .where((o) =>
              settings.sentiments.contains(o.pick.sentiment) &&
              (settings.sectors.isEmpty ||
                  settings.sectors.contains(o.pick.sector)))
          .toList();
      outcomes = allOutcomes;
      dailySummary = StockEngine.computeDailySummary(outcomes);
      if (settings.carryEnabled) {
        holdingCurve =
            StockEngine.computeHoldingCurve(filtered, candleStore, chainMap);
      } else {
        holdingCurve = [];
      }
      final (rows, detail) =
          StockEngine.buildExitStrategySummary(filtered, candleStore);
      exitSummary = rows;
      exitDetail = detail;
    } catch (e) {
      error = e.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _resetComputed() {
    filteredPicks = [];
    outcomes = [];
    dailySummary = [];
    holdingCurve = [];
    exitSummary = [];
    exitDetail = {};
  }

  Set<String> get knownSectors => allPicks.map((p) => p.sector).toSet();

  void _jumpToDay(String date) {
    setState(() {
      jumpToDate = date;
      tab = 1;
    });
  }

  void _openSettings() async {
    final draft = settings.copy();
    final applied = await showModalBottomSheet<StockSettings>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) =>
          StockSettingsSheet(settings: draft, knownSectors: knownSectors),
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
              child: const Icon(Icons.candlestick_chart_rounded,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Text('AI Picks', style: t.h1),
            Text(' Portfolio',
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
              isLabelVisible:
                  settings.sentiments.length < 2 || settings.sectors.isNotEmpty,
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
            ? StockErrorView(error: error!, onRetry: () => _refresh())
            : (outcomes.isEmpty && !loading)
                ? AtlasEmptyState(
                    icon: Icons.filter_alt_off_rounded,
                    title: 'No picks found',
                    message: noDataPairs.isNotEmpty
                        ? 'No candle data yet for the current picks — run the candle backfill job.'
                        : 'Try widening the lookback window or the entry-time filter.',
                    actionLabel: 'Open filters',
                    onAction: _openSettings,
                  )
                : IndexedStack(
                    index: tab,
                    children: [
                      StockOverviewScreen(
                        dailySummary: dailySummary,
                        outcomes: outcomes,
                        holdingCurve: holdingCurve,
                        carryEnabled: settings.carryEnabled,
                        window: settings.window,
                        lookbackDays: settings.lookbackDays,
                        skippedRows: skippedRows,
                        noDataPairs: noDataPairs,
                        onJumpToDay: _jumpToDay,
                      ),
                      StockDateWiseScreen(
                        outcomes: outcomes,
                        candleStore: candleStore,
                        chainMap: chainMap,
                        carryEnabled: settings.carryEnabled,
                        window: settings.window,
                        jumpToDate: jumpToDate,
                        onConsumedJump: () => jumpToDate = null,
                      ),
                      StockChartScreen(
                        outcomes: outcomes,
                        candleStore: candleStore,
                        chainMap: chainMap,
                        carryEnabled: settings.carryEnabled,
                        window: settings.window,
                      ),
                      StockExitStrategyScreen(
                          rows: exitSummary, detailFrames: exitDetail),
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
              label: 'Date-wise'),
          NavigationDestination(
              icon: Icon(Icons.show_chart_rounded),
              selectedIcon: Icon(Icons.show_chart_rounded),
              label: 'Stock Chart'),
          NavigationDestination(
              icon: Icon(Icons.auto_graph_outlined),
              selectedIcon: Icon(Icons.auto_graph_rounded),
              label: 'Exit Lab'),
        ],
      ),
    );
  }
}

class StockErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const StockErrorView({super.key, required this.error, required this.onRetry});
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

class StockSettingsSheet extends StatefulWidget {
  final StockSettings settings;
  final Set<String> knownSectors;
  const StockSettingsSheet(
      {super.key, required this.settings, required this.knownSectors});
  @override
  State<StockSettingsSheet> createState() => _StockSettingsSheetState();
}

class _StockSettingsSheetState extends State<StockSettingsSheet> {
  late StockSettings s = widget.settings;
  late _EntryPreset _preset = _presetFor(s.entryStart, s.entryEnd);
  bool _customExit = false;

  static const _fullStart =
      TimeOfDayLite(MarketHours.openHour, MarketHours.openMinute);
  static const _fullEnd =
      TimeOfDayLite(MarketHours.closeHour, MarketHours.closeMinute);
  static const _morningEnd = TimeOfDayLite(12, 0);
  static const _afternoonStart = TimeOfDayLite(12, 0);

  bool _same(TimeOfDayLite a, TimeOfDayLite b) =>
      a.hour == b.hour && a.minute == b.minute;

  _EntryPreset _presetFor(TimeOfDayLite start, TimeOfDayLite end) {
    if (_same(start, _fullStart) && _same(end, _fullEnd))
      return _EntryPreset.fullSession;
    if (_same(start, _fullStart) && _same(end, _morningEnd))
      return _EntryPreset.morning;
    if (_same(start, _afternoonStart) && _same(end, _fullEnd))
      return _EntryPreset.afternoon;
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
          s.entryStart = _fullStart;
          s.entryEnd = _morningEnd;
          break;
        case _EntryPreset.afternoon:
          s.entryStart = _afternoonStart;
          s.entryEnd = _fullEnd;
          break;
        case _EntryPreset.custom:
          break;
      }
    });
  }

  Future<void> _pickTime({required bool isStart}) async {
    final cur = isStart ? s.entryStart : s.entryEnd;
    final picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: cur.hour, minute: cur.minute));
    if (picked == null) return;
    setState(() {
      final lite = TimeOfDayLite(picked.hour, picked.minute);
      if (isStart) {
        s.entryStart = lite;
      } else {
        s.entryEnd = lite;
      }
      _preset = _EntryPreset.custom;
    });
  }

  String _fmtTod(TimeOfDayLite raw) {
    final h = raw.hour % 12 == 0 ? 12 : raw.hour % 12;
    final m = raw.minute.toString().padLeft(2, '0');
    return '$h:$m ${raw.hour < 12 ? 'AM' : 'PM'}';
  }

  List<PredictionWindow> get _windowOptions => [
        ...kMinuteWindows.map((m) => PredictionWindow.minutes(m)),
        PredictionWindow.fullDay,
        if (s.carryEnabled)
          ...kDayWindows.values.map((n) => PredictionWindow.days(n)),
      ];

  @override
  Widget build(BuildContext context) {
    final c = atlasColors(context);
    final t = atlasText(context);
    final maxH = MediaQuery.of(context).size.height * 0.88;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    if (!_windowOptions.contains(s.window)) {
      s.window = const PredictionWindow.minutes(15);
    }

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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                        color: c.border,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(Sp.lg, Sp.md, Sp.sm, Sp.sm),
                  child: Row(
                    children: [
                      Icon(Icons.tune_rounded, size: 18, color: c.accent),
                      const SizedBox(width: 8),
                      Expanded(child: Text('Filters', style: t.h1)),
                      IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: Sp.xl),
                    child: Padding(
                      padding:
                          const EdgeInsets.fromLTRB(Sp.lg, 0, Sp.lg, Sp.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label(context, Icons.history_rounded,
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
                          Row(children: [
                            Expanded(
                              child: _label(context, Icons.fast_forward_rounded,
                                  'Carry over to next trading day(s)'),
                            ),
                            Switch(
                              value: s.carryEnabled,
                              onChanged: (v) =>
                                  setState(() => s.carryEnabled = v),
                              activeColor: c.accent,
                            ),
                          ]),
                          const SizedBox(height: Sp.sm),
                          _label(context, Icons.timer_outlined,
                              'Prediction window — ${s.window.label}'),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _windowOptions
                                .map((w) => AtlasChipToggle(
                                      label: w.label,
                                      selected: s.window == w,
                                      activeColor: c.accent,
                                      onChanged: (_) => setState(() {
                                        s.window = w;
                                        _customExit = false;
                                      }),
                                    ))
                                .toList(),
                          ),
                          const SizedBox(height: Sp.sm),
                          Row(children: [
                            Expanded(
                              child: _label(context, Icons.linear_scale_rounded,
                                  'Use exact-minute slider'),
                            ),
                            Switch(
                              value: _customExit,
                              onChanged: (v) => setState(() {
                                _customExit = v;
                                if (v)
                                  s.window = PredictionWindow.minutes(
                                      kExitWindowDefault);
                              }),
                              activeColor: c.accent,
                            ),
                          ]),
                          if (_customExit)
                            Slider(
                              value: (s.window.isMinutes
                                      ? s.window.value
                                      : kExitWindowDefault)
                                  .toDouble(),
                              min: kExitWindowMin.toDouble(),
                              max: kExitWindowMax.toDouble(),
                              divisions: (kExitWindowMax - kExitWindowMin) ~/ 5,
                              label:
                                  '${s.window.isMinutes ? s.window.value : kExitWindowDefault} min',
                              onChanged: (v) => setState(() => s.window =
                                  PredictionWindow.minutes((v ~/ 5) * 5)),
                            ),
                          const SizedBox(height: Sp.lg),
                          _label(context, Icons.swap_vert_rounded, 'Sentiment'),
                          Row(children: [
                            AtlasChipToggle(
                              label: 'Bullish',
                              icon: Icons.arrow_upward_rounded,
                              selected: s.sentiments.contains('BULLISH'),
                              activeColor: c.bull,
                              onChanged: (v) => setState(() => v
                                  ? s.sentiments.add('BULLISH')
                                  : s.sentiments.remove('BULLISH')),
                            ),
                            const SizedBox(width: 8),
                            AtlasChipToggle(
                              label: 'Bearish',
                              icon: Icons.arrow_downward_rounded,
                              selected: s.sentiments.contains('BEARISH'),
                              activeColor: c.bear,
                              onChanged: (v) => setState(() => v
                                  ? s.sentiments.add('BEARISH')
                                  : s.sentiments.remove('BEARISH')),
                            ),
                          ]),
                          if (widget.knownSectors.isNotEmpty) ...[
                            const SizedBox(height: Sp.lg),
                            _label(context, Icons.category_outlined, 'Sector'),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: widget.knownSectors
                                  .map((sec) => AtlasChipToggle(
                                        label: sec,
                                        selected: s.sectors.isEmpty ||
                                            s.sectors.contains(sec),
                                        activeColor: c.accent,
                                        onChanged: (v) => setState(() {
                                          if (s.sectors.isEmpty) {
                                            s.sectors = {...widget.knownSectors}
                                              ..remove(sec);
                                          } else if (v) {
                                            s.sectors.add(sec);
                                          } else {
                                            s.sectors.remove(sec);
                                          }
                                          if (s.sectors.length ==
                                              widget.knownSectors.length) {
                                            s.sectors = {};
                                          }
                                        }),
                                      ))
                                  .toList(),
                            ),
                          ],
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
                  ),
                ),
              ],
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
class StockOverviewScreen extends StatelessWidget {
  final List<StockDailySummary> dailySummary;
  final List<StockOutcome> outcomes;
  final List<HoldingPoint> holdingCurve;
  final bool carryEnabled;
  final PredictionWindow window;
  final int lookbackDays;
  final int skippedRows;
  final Set<String> noDataPairs;
  final void Function(String date) onJumpToDay;
  const StockOverviewScreen({
    super.key,
    required this.dailySummary,
    required this.outcomes,
    required this.holdingCurve,
    required this.carryEnabled,
    required this.window,
    required this.lookbackDays,
    required this.skippedRows,
    required this.noDataPairs,
    required this.onJumpToDay,
  });

  @override
  Widget build(BuildContext context) {
    final c = atlasColors(context);
    final t = atlasText(context);
    final total = outcomes.length;
    final succ = outcomes.where((o) => o.success).length;
    final acc = total == 0 ? 0.0 : succ / total * 100;
    final avgMaxProfit = total == 0
        ? 0.0
        : outcomes.map((o) => o.maxProfitPcnt).reduce((a, b) => a + b) / total;
    final avgMaxLoss = total == 0
        ? 0.0
        : outcomes.map((o) => o.maxLossPcnt).reduce((a, b) => a + b) / total;
    final avgTimeToPeak = total == 0
        ? 0.0
        : outcomes.map((o) => o.timeToPeakMin).reduce((a, b) => a + b) / total;
    final successful = outcomes.where((o) => o.success).toList();
    final avgRiskBeforePeak = successful.isEmpty
        ? null
        : successful
                .map((o) => o.prePeakRiskPcnt.abs())
                .reduce((a, b) => a + b) /
            successful.length;
    final carriedCount = outcomes.where((o) => o.carriedOver).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(Sp.lg, Sp.md, Sp.lg, Sp.xxl),
      children: [
        HeroStat(
          label: 'Success rate',
          value: '${acc.toStringAsFixed(1)}%',
          valueColor: c.accuracyColor(acc),
          ringValue: acc,
          sublabel:
              '$succ of $total picks hit · ${window.label} window · last $lookbackDays'
              'd${carryEnabled ? ' · $carriedCount carried over' : ''}',
        ),
        if (skippedRows > 0 || noDataPairs.isNotEmpty) ...[
          const SizedBox(height: Sp.sm),
          Text(
            '${skippedRows > 0 ? '$skippedRows rows skipped outside market hours' : ''}'
            '${skippedRows > 0 && noDataPairs.isNotEmpty ? ' · ' : ''}'
            '${noDataPairs.isNotEmpty ? '${noDataPairs.length} symbol-day pairs missing candle data' : ''}',
            style: t.caption,
          ),
        ],
        const SizedBox(height: Sp.md),
        AtlasCard(
          child: Row(
            children: [
              RiskRewardBar(
                  rewardPcnt: avgMaxProfit, riskPcnt: avgMaxLoss, height: 48),
              const SizedBox(width: Sp.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Avg max profit vs. max loss', style: t.body),
                    const SizedBox(height: 2),
                    Text(
                      'Avg time to peak ${formatMinutes(avgTimeToPeak)}'
                      '${avgRiskBeforePeak != null ? ' · avg risk before peak ${avgRiskBeforePeak.toStringAsFixed(2)}%' : ''}',
                      style: t.bodyMuted,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        AtlasSectionHeader(
          title: 'Daily performance',
          icon: Icons.bar_chart_rounded,
          infoTitle: 'How this is read',
          infoBuilder: (ctx) => Text(
            'For every day, the bar shows the average max profit reached (up, green) '
            'against the average risk endured before the peak (down, amber). The line '
            'traces the day\'s success rate. Tap a day to jump to Date-wise.',
            style: atlasText(ctx).bodyMuted,
          ),
        ),
        DailyPerformanceChart(daily: dailySummary, onTapDay: onJumpToDay),
        const SizedBox(height: Sp.sm),
        ...dailySummary.reversed.take(10).map(
            (d) => DailySummaryCard(day: d, onTap: () => onJumpToDay(d.date))),
        AtlasSectionHeader(
          title: 'Profit/loss potential vs. holding period',
          icon: Icons.timeline_rounded,
        ),
        if (!carryEnabled)
          const AtlasEmptyState(
            icon: Icons.fast_forward_rounded,
            title: 'Carry-over is off',
            message:
                'Turn on "Carry over to next trading day(s)" in Filters to see profit/loss '
                'potential across longer holding periods.',
          )
        else if (holdingCurve.isEmpty)
          const AtlasEmptyState(
            icon: Icons.hourglass_empty_rounded,
            title: 'Not enough data yet',
            message:
                'Carried-over candle data hasn\'t been fetched for enough picks yet.',
          )
        else
          HoldingCurveChart(points: holdingCurve),
        const SizedBox(height: Sp.md),
        const ProUpgradeButton(),
      ],
    );
  }
}

class DailyPerformanceChart extends StatelessWidget {
  final List<StockDailySummary> daily;
  final void Function(String date) onTapDay;
  const DailyPerformanceChart(
      {super.key, required this.daily, required this.onTapDay});

  @override
  Widget build(BuildContext context) {
    final c = atlasColors(context);
    final t = atlasText(context);
    if (daily.isEmpty) {
      return AtlasEmptyState(
        icon: Icons.query_stats_rounded,
        title: 'No days yet',
        message: 'Picks will appear here once they resolve.',
      );
    }
    return AtlasCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _legendDot(c.bull, 'Avg max profit', t),
            const SizedBox(width: 14),
            _legendDot(c.warn, 'Avg risk before peak', t),
            const SizedBox(width: 14),
            _legendDot(c.accent, 'Success %', t),
          ]),
          const SizedBox(height: Sp.sm),
          SizedBox(
            height: 220,
            child: SfCartesianChart(
              margin: EdgeInsets.zero,
              plotAreaBorderWidth: 0,
              enableSideBySideSeriesPlacement:
                  false, // <-- key change, overlaps series instead of clustering
              primaryXAxis: CategoryAxis(
                majorGridLines: const MajorGridLines(width: 0),
                labelStyle: TextStyle(color: c.textFaint, fontSize: 8),
                labelIntersectAction: AxisLabelIntersectAction.rotate45,
              ),
              primaryYAxis: NumericAxis(
                title: AxisTitle(
                    text: '% from entry',
                    textStyle: TextStyle(color: c.textFaint, fontSize: 9)),
                majorGridLines:
                    MajorGridLines(color: c.border, dashArray: const [3, 4]),
              ),
              axes: <ChartAxis>[
                NumericAxis(
                    name: 'acc', minimum: 0, maximum: 100, isVisible: false),
              ],
              series: <CartesianSeries>[
                ColumnSeries<StockDailySummary, String>(
                  dataSource: daily,
                  xValueMapper: (d, _) => fmtDayShort(_parseDay(d.date)),
                  yValueMapper: (d, _) => d.avgMaxProfit,
                  color: c.bull,
                  width: 0.6, // same width on both -> they line up exactly
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(3)),
                  onPointTap: (args) => onTapDay(daily[args.pointIndex!].date),
                ),
                ColumnSeries<StockDailySummary, String>(
                  dataSource: daily,
                  xValueMapper: (d, _) => fmtDayShort(_parseDay(d.date)),
                  yValueMapper: (d, _) => -d.avgRiskBeforePeak,
                  color: c.warn,
                  width: 0.6,
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(3)),
                  onPointTap: (args) => onTapDay(daily[args.pointIndex!].date),
                ),
                SplineSeries<StockDailySummary, String>(
                  dataSource: daily,
                  xValueMapper: (d, _) => fmtDayShort(_parseDay(d.date)),
                  yValueMapper: (d, _) => d.accuracy,
                  yAxisName: 'acc',
                  color: c.accent,
                  width: 2,
                  markerSettings: const MarkerSettings(
                      isVisible: true, height: 5, width: 5),
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

class HoldingCurveChart extends StatelessWidget {
  final List<HoldingPoint> points;
  const HoldingCurveChart({super.key, required this.points});
  @override
  Widget build(BuildContext context) {
    final c = atlasColors(context);
    return AtlasCard(
      child: SizedBox(
        height: 200,
        child: SfCartesianChart(
          margin: EdgeInsets.zero,
          plotAreaBorderWidth: 0,
          primaryXAxis: CategoryAxis(
            majorGridLines: const MajorGridLines(width: 0),
            labelStyle: TextStyle(color: c.textFaint, fontSize: 9),
          ),
          primaryYAxis: NumericAxis(
            majorGridLines:
                MajorGridLines(color: c.border, dashArray: const [3, 4]),
          ),
          legend: Legend(isVisible: true, position: LegendPosition.top),
          series: <CartesianSeries>[
            LineSeries<HoldingPoint, String>(
              name: 'Avg max profit %',
              dataSource: points,
              xValueMapper: (p, _) => 'D+${p.dayOffset}',
              yValueMapper: (p, _) => p.avgMaxProfit,
              color: c.bull,
              width: 3,
              markerSettings: const MarkerSettings(isVisible: true),
            ),
            LineSeries<HoldingPoint, String>(
              name: 'Avg max loss %',
              dataSource: points,
              xValueMapper: (p, _) => 'D+${p.dayOffset}',
              yValueMapper: (p, _) => p.avgMaxLoss,
              color: c.bear,
              width: 3,
              markerSettings: const MarkerSettings(isVisible: true),
            ),
          ],
        ),
      ),
    );
  }
}

class DailySummaryCard extends StatelessWidget {
  final StockDailySummary day;
  final VoidCallback onTap;
  const DailySummaryCard({super.key, required this.day, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final c = atlasColors(context);
    final t = atlasText(context);
    final date = _parseDay(day.date);
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
                Text(fmtDayShort(date), style: t.body),
                const SizedBox(height: 2),
                Row(children: [
                  Icon(Icons.query_stats_rounded, size: 12, color: c.textFaint),
                  const SizedBox(width: 3),
                  Text('${day.picks} picks · ${day.success} hit',
                      style: t.bodyMuted),
                ]),
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

// =============================================================================
// DATE-WISE SCREEN
// =============================================================================
class StockDateWiseScreen extends StatefulWidget {
  final List<StockOutcome> outcomes;
  final Map<String, List<Candle>?> candleStore;
  final Map<String, List<String>> chainMap;
  final bool carryEnabled;
  final PredictionWindow window;
  final String? jumpToDate;
  final VoidCallback onConsumedJump;
  const StockDateWiseScreen({
    super.key,
    required this.outcomes,
    required this.candleStore,
    required this.chainMap,
    required this.carryEnabled,
    required this.window,
    required this.jumpToDate,
    required this.onConsumedJump,
  });
  @override
  State<StockDateWiseScreen> createState() => _StockDateWiseScreenState();
}

class _StockDateWiseScreenState extends State<StockDateWiseScreen> {
  int page = 0;

  List<String> get _dates {
    final s = widget.outcomes.map((o) => o.pick.date).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    return s;
  }

  @override
  void didUpdateWidget(covariant StockDateWiseScreen old) {
    super.didUpdateWidget(old);
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
          message: 'Picks will appear here once they resolve.');
    }
    if (page >= dates.length) page = 0;
    final currentDate = dates[page];
    final dayOutcomes = widget.outcomes
        .where((o) => o.pick.date == currentDate)
        .toList()
      ..sort((a, b) => a.pick.pickTimeIst.compareTo(b.pick.pickTimeIst));
    final dayAcc = dayOutcomes.isEmpty
        ? 0.0
        : dayOutcomes.where((o) => o.success).length / dayOutcomes.length * 100;

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
                label: Text(fmtDayShort(_parseDay(d))),
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
          child: ListView(
            key: ValueKey(currentDate),
            padding: const EdgeInsets.fromLTRB(Sp.lg, 0, Sp.lg, Sp.xxl),
            children: [
              AtlasSectionHeader(
                title:
                    '$currentDate — ${dayOutcomes.length} picks — ${dayAcc.toStringAsFixed(0)}% success',
                icon: Icons.event_note_rounded,
              ),
              ...dayOutcomes.map((o) => StockPickCard(
                    outcome: o,
                    candleStore: widget.candleStore,
                    chainMap: widget.chainMap,
                    carryEnabled: widget.carryEnabled,
                    window: widget.window,
                  )),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// STOCK CHART SCREEN — search a symbol, see every pick for it
// =============================================================================
class StockChartScreen extends StatefulWidget {
  final List<StockOutcome> outcomes;
  final Map<String, List<Candle>?> candleStore;
  final Map<String, List<String>> chainMap;
  final bool carryEnabled;
  final PredictionWindow window;
  const StockChartScreen({
    super.key,
    required this.outcomes,
    required this.candleStore,
    required this.chainMap,
    required this.carryEnabled,
    required this.window,
  });
  @override
  State<StockChartScreen> createState() => _StockChartScreenState();
}

class _StockChartScreenState extends State<StockChartScreen> {
  String? selectedSymbol;

  @override
  Widget build(BuildContext context) {
    final c = atlasColors(context);
    final symbols = widget.outcomes.map((o) => o.pick.symbol).toSet().toList()
      ..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Sp.lg, Sp.md, Sp.lg, Sp.sm),
          child: DropdownMenu<String>(
            width: MediaQuery.of(context).size.width - Sp.lg * 2,
            hintText: 'Search / select a symbol…',
            leadingIcon: Icon(Icons.search_rounded, color: c.textFaint),
            enableFilter: true, // <-- ADD: type-to-filter
            enableSearch:
                true, // <-- keep search on (default true, explicit for clarity)
            requestFocusOnTap:
                true, // <-- ADD: tapping opens keyboard + list immediately
            filterCallback: (entries, filter) {
              // <-- ADD: case-insensitive substring match
              if (filter.isEmpty) return entries;
              final q = filter.toUpperCase();
              return entries
                  .where((e) => e.label.toUpperCase().contains(q))
                  .toList();
            },
            menuHeight:
                320, // <-- ADD: caps the suggestion list so it scrolls instead of pushing content
            initialSelection: selectedSymbol,
            onSelected: (v) => setState(() => selectedSymbol = v),
            dropdownMenuEntries: symbols
                .map((s) => DropdownMenuEntry(value: s, label: s))
                .toList(),
          ),
        ),
        Expanded(
          child: selectedSymbol == null
              ? const AtlasEmptyState(
                  icon: Icons.manage_search_rounded,
                  title: 'Search a symbol',
                  message:
                      'Pick a stock above to see every 5-min chart it was called on.',
                )
              : Builder(builder: (ctx) {
                  final rows = widget.outcomes
                      .where((o) => o.pick.symbol == selectedSymbol)
                      .toList()
                    ..sort((a, b) => b.pick.date.compareTo(a.pick.date));
                  if (rows.isEmpty) {
                    return const AtlasEmptyState(
                      icon: Icons.inbox_rounded,
                      title: 'No picks',
                      message:
                          'No picks for this symbol under the current filters.',
                    );
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(Sp.lg, 0, Sp.lg, Sp.xxl),
                    children: [
                      AtlasSectionHeader(
                        title:
                            '$selectedSymbol — ${rows.length} pick${rows.length != 1 ? 's' : ''}',
                        icon: Icons.candlestick_chart_rounded,
                      ),
                      ...rows.map((o) => StockPickCard(
                            outcome: o,
                            candleStore: widget.candleStore,
                            chainMap: widget.chainMap,
                            carryEnabled: widget.carryEnabled,
                            window: widget.window,
                          )),
                    ],
                  );
                }),
        ),
      ],
    );
  }
}

// =============================================================================
// PICK CARD + STITCHED CANDLESTICK CHART
// =============================================================================
class StockPickCard extends StatelessWidget {
  final StockOutcome outcome;
  final Map<String, List<Candle>?> candleStore;
  final Map<String, List<String>> chainMap;
  final bool carryEnabled;
  final PredictionWindow window;
  const StockPickCard({
    super.key,
    required this.outcome,
    required this.candleStore,
    required this.chainMap,
    required this.carryEnabled,
    required this.window,
  });

  @override
  Widget build(BuildContext context) {
    final c = atlasColors(context);
    final t = atlasText(context);
    final o = outcome;
    final bullish = o.pick.sentiment == 'BULLISH';
    return ExpandableCard(
      header: Row(
        children: [
          DirectionPill(bullish ? 'Bull' : 'Bear', compact: true),
          const SizedBox(width: Sp.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${o.pick.symbol} · ${o.pick.pickTimeIst} IST',
                    style: t.body),
                Row(children: [
                  Icon(Icons.category_outlined, size: 11, color: c.textFaint),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      o.pick.sector,
                      style: t.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
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
      details: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RiskRewardBar(
                  rewardPcnt: o.maxProfitPcnt, riskPcnt: o.maxLossPcnt.abs()),
              const SizedBox(width: Sp.lg),
              Expanded(
                child: Column(
                  children: [
                    KvRow('Entry price', '₹${o.startPrice.toStringAsFixed(2)}',
                        icon: Icons.login_rounded),
                    KvRow('Price @ ${window.label}',
                        '₹${o.exitPrice.toStringAsFixed(2)}',
                        icon: Icons.logout_rounded),
                    KvRow('Time to peak', formatMinutes(o.timeToPeakMin),
                        icon: Icons.timer_outlined),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Sp.md),
          StockPickChart(
              outcome: o,
              candleStore: candleStore,
              chainMap: chainMap,
              carryEnabled: carryEnabled,
              window: window),
        ],
      ),
    );
  }
}

/// Stitched, gap-free candlestick chart for one pick — entry, window-end, and
/// the first moment the call was proven right (★) are all marked, plus an EOD
/// diamond for every day shown. Mirrors `render_pick_chart` in the Streamlit
/// reference, minus the "extra lookahead days" slider (kept to what the
/// current window/carry settings already fetched, to avoid surprise reads).
class StockPickChart extends StatelessWidget {
  final StockOutcome outcome;
  final Map<String, List<Candle>?> candleStore;
  final Map<String, List<String>> chainMap;
  final bool carryEnabled;
  final PredictionWindow window;
  const StockPickChart({
    super.key,
    required this.outcome,
    required this.candleStore,
    required this.chainMap,
    required this.carryEnabled,
    required this.window,
  });

  @override
  Widget build(BuildContext context) {
    final c = atlasColors(context);
    final t = atlasText(context);
    final o = outcome;
    final today = candleStore[o.pick.storeKey];
    if (today == null || today.isEmpty) {
      return AtlasEmptyState(
        icon: Icons.signal_wifi_off_rounded,
        title: 'No candle data',
        message:
            'No 5-min candles in Supabase yet for ${o.pick.symbol} — ${o.pick.date}.',
      );
    }

    final shownDays = o.carryDays.isNotEmpty
        ? o.carryDays
        : (carryEnabled
            ? (chainMap[o.pick.storeKey] ?? const <String>[]).take(1).toList()
            : const <String>[]);
    final combined = <Candle>[...today];
    for (final d in shownDays) {
      final df = candleStore['${o.pick.ticker}|$d'];
      if (df != null) combined.addAll(df);
    }
    combined.sort((a, b) => a.ts.compareTo(b.ts));
    final plot = <Candle>[];
    for (final cndl in combined) {
      if (plot.isEmpty || plot.last.ts != cndl.ts) plot.add(cndl);
    }

    int? posOf(DateTime? ts) {
      if (ts == null || plot.isEmpty) return null;
      var best = 0;
      var bestDiff = plot[0].ts.difference(ts).abs();
      for (var i = 1; i < plot.length; i++) {
        final diff = plot[i].ts.difference(ts).abs();
        if (diff < bestDiff) {
          bestDiff = diff;
          best = i;
        }
      }
      return best;
    }

    final entryPos = posOf(o.pick.pickDt);
    final endPos = posOf(o.windowEndDt);
    final hitPos = o.hitTime != null ? posOf(o.hitTime) : null;
    final indexed =
        List.generate(plot.length, (i) => _IdxCandle(i, plot[i])).toList();

    final dayStarts = <MapEntry<int, DateTime>>[];
    DateTime? prevDay;
    for (var i = 0; i < plot.length; i++) {
      final d = DateTime.utc(plot[i].ts.year, plot[i].ts.month, plot[i].ts.day);
      if (prevDay == null || d != prevDay) {
        dayStarts.add(MapEntry(i, d));
        prevDay = d;
      }
    }

    return AtlasCard(
      padding: const EdgeInsets.all(Sp.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 260,
            child: SfCartesianChart(
              margin: EdgeInsets.zero,
              plotAreaBorderWidth: 0,
              primaryXAxis: NumericAxis(
                minimum: 0,
                maximum: (plot.length - 1).toDouble(),
                interval: math.max((plot.length / 6).floorToDouble(), 1),
                majorGridLines: const MajorGridLines(width: 0),
                axisLabelFormatter: (details) {
                  final i = details.value.round().clamp(0, plot.length - 1);
                  return ChartAxisLabel(
                      DateFormat('d MMM HH:mm').format(plot[i].ts),
                      details.textStyle);
                },
                labelStyle: TextStyle(color: c.textFaint, fontSize: 8),
                plotBands: <PlotBand>[
                  if (entryPos != null && endPos != null)
                    PlotBand(
                      isVisible: true,
                      start: math.min(entryPos, endPos).toDouble(),
                      end: math.max(entryPos, endPos).toDouble(),
                      color: (o.success ? c.bull : c.bear).withOpacity(0.10),
                    ),
                  for (final ds in dayStarts.skip(1))
                    PlotBand(
                      isVisible: true,
                      start: ds.key - 0.5,
                      end: ds.key - 0.5,
                      borderWidth: 1,
                      borderColor: c.border,
                      dashArray: const [3, 3],
                    ),
                ],
              ),
              primaryYAxis: NumericAxis(
                numberFormat: NumberFormat.compactCurrency(symbol: '₹'),
                majorGridLines:
                    MajorGridLines(color: c.border, dashArray: const [3, 4]),
              ),
              series: <CartesianSeries>[
                CandleSeries<_IdxCandle, int>(
                  dataSource: indexed,
                  xValueMapper: (d, _) => d.i,
                  openValueMapper: (d, _) => d.c.open,
                  highValueMapper: (d, _) => d.c.high,
                  lowValueMapper: (d, _) => d.c.low,
                  closeValueMapper: (d, _) => d.c.close,
                  bullColor: c.bull,
                  bearColor: c.bear,
                  enableSolidCandles: true,
                ),
                if (entryPos != null)
                  ScatterSeries<_IdxCandle, int>(
                    dataSource: [_IdxCandle(entryPos, plot[entryPos])],
                    xValueMapper: (d, _) => d.i,
                    yValueMapper: (_, __) => o.startPrice,
                    color: c.accent,
                    markerSettings: const MarkerSettings(
                        isVisible: true,
                        shape: DataMarkerType.triangle,
                        height: 10,
                        width: 10),
                  ),
                if (endPos != null)
                  ScatterSeries<_IdxCandle, int>(
                    dataSource: [_IdxCandle(endPos, plot[endPos])],
                    xValueMapper: (d, _) => d.i,
                    yValueMapper: (_, __) => o.exitPrice,
                    color: o.success ? c.bull : c.bear,
                    markerSettings: const MarkerSettings(
                        isVisible: true,
                        shape: DataMarkerType.rectangle,
                        height: 9,
                        width: 9),
                  ),
                if (hitPos != null && o.hitPrice != null)
                  ScatterSeries<_IdxCandle, int>(
                    dataSource: [_IdxCandle(hitPos, plot[hitPos])],
                    xValueMapper: (d, _) => d.i,
                    yValueMapper: (_, __) => o.hitPrice,
                    color: c.warn,
                    markerSettings: const MarkerSettings(
                        isVisible: true,
                        shape: DataMarkerType.diamond,
                        height: 11,
                        width: 11),
                  ),
              ],
              tooltipBehavior: TooltipBehavior(enable: true),
            ),
          ),
          const SizedBox(height: Sp.sm),
          Wrap(spacing: 6, runSpacing: 6, children: [
            _dot(c.accent, 'Entry', t),
            _dot(
                o.success ? c.bull : c.bear, o.success ? 'Success' : 'Fail', t),
            if (hitPos != null) _dot(c.warn, 'Call confirmed', t),
          ]),
          if (o.hitTime != null) ...[
            const SizedBox(height: Sp.sm),
            Container(
              padding: const EdgeInsets.all(Sp.sm),
              decoration: BoxDecoration(
                color: c.bullSoft(),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Hit ${fmtHm(o.hitTime!)} IST @ ₹${o.hitPrice?.toStringAsFixed(2) ?? '—'} · '
                'captured ${(((o.hitPrice ?? o.startPrice) - o.startPrice) / o.startPrice * 100).toStringAsFixed(2)}%',
                style: t.bodyMuted.copyWith(color: c.bull),
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: Sp.sm),
              child: Text(
                  'Predicted direction was never reached within this window.',
                  style: t.bodyMuted),
            ),
          if (o.carriedOver)
            Padding(
              padding: const EdgeInsets.only(top: Sp.xs),
              child: Text('Window carried into ${o.carryDays.join(', ')}.',
                  style: t.caption),
            ),
        ],
      ),
    );
  }

  Widget _dot(Color color, String label, AtlasText t) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(label, style: t.caption),
        ],
      );
}

class _IdxCandle {
  final int i;
  final Candle c;
  _IdxCandle(this.i, this.c);
}

// =============================================================================
// EXIT STRATEGY LAB SCREEN
// =============================================================================
class StockExitStrategyScreen extends StatefulWidget {
  final List<StockStrategyRow> rows;
  final Map<String, List<StockOutcome>> detailFrames;
  const StockExitStrategyScreen(
      {super.key, required this.rows, required this.detailFrames});
  @override
  State<StockExitStrategyScreen> createState() =>
      _StockExitStrategyScreenState();
}

class _StockExitStrategyScreenState extends State<StockExitStrategyScreen> {
  String? selected;

  @override
  Widget build(BuildContext context) {
    final c = atlasColors(context);
    final t = atlasText(context);
    final valid = widget.rows.where((r) => r.riskAdjScore != null).toList()
      ..sort((a, b) => b.riskAdjScore!.compareTo(a.riskAdjScore!));

    if (widget.rows.isEmpty || valid.isEmpty) {
      return const AtlasEmptyState(
        icon: Icons.science_outlined,
        title: 'Not enough data',
        message: 'Widen the lookback window to compare exit strategies.',
      );
    }
    final best = valid.first;
    selected ??= best.strategy;
    final detail = widget.detailFrames[selected] ?? [];

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
              label: 'Picks',
              icon: Icons.query_stats_rounded,
              value: '${best.picks}'),
        ]),
        AtlasSectionHeader(
          title: 'Compare strategies',
          icon: Icons.auto_graph_rounded,
          infoTitle: 'How strategies are compared',
          infoBuilder: (ctx) => Text(
            'Fixed-time exits close the trade after a set number of minutes. The '
            'structure stop exits if price breaks the recent 3-candle range. '
            'Gain/Risk is average % captured divided by average % adverse move — '
            'higher is better.',
            style: atlasText(ctx).bodyMuted,
          ),
        ),
        StrategyRankChart(rows: valid),
        const SizedBox(height: Sp.sm),
        ...valid.map((r) => StockStrategyCard(
              row: r,
              isBest: r.strategy == best.strategy,
              onTap: () => setState(() => selected = r.strategy),
              selected: r.strategy == selected,
            )),
        AtlasSectionHeader(
            title: 'Detail — $selected', icon: Icons.receipt_long_rounded),
        if (detail.isEmpty)
          const AtlasEmptyState(
            icon: Icons.inbox_rounded,
            title: 'No picks',
            message: 'No picks resolved under this strategy yet.',
          )
        else
          ...detail.take(20).map((o) => ExpandableCard(
                header: Row(children: [
                  DirectionPill(o.pick.sentiment == 'BULLISH' ? 'Bull' : 'Bear',
                      compact: true),
                  const SizedBox(width: Sp.sm),
                  Expanded(
                    child: Text('${o.pick.symbol} · ${o.pick.date}',
                        style: t.body),
                  ),
                  Text(
                      '${o.netGainPcnt >= 0 ? '+' : ''}${o.netGainPcnt.toStringAsFixed(2)}%',
                      style: t.numberSm.copyWith(color: c.pnl(o.netGainPcnt))),
                ]),
                details: Column(children: [
                  KvRow('Entry', '₹${o.startPrice.toStringAsFixed(2)}'),
                  KvRow('Exit', '₹${o.exitPrice.toStringAsFixed(2)}'),
                  if (o.stopLevel != null)
                    KvRow('Stop level', '₹${o.stopLevel!.toStringAsFixed(2)}'),
                  if (o.holdMinutes != null)
                    KvRow('Held', formatMinutes(o.holdMinutes)),
                ]),
              )),
        const SizedBox(height: Sp.md),
        const ProUpgradeButton(),
      ],
    );
  }
}

class StrategyRankChart extends StatelessWidget {
  final List<StockStrategyRow> rows;
  const StrategyRankChart({super.key, required this.rows});
  @override
  Widget build(BuildContext context) {
    final c = atlasColors(context);
    final top = rows.take(8).toList();
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
            ColumnSeries<StockStrategyRow, String>(
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

class StockStrategyCard extends StatelessWidget {
  final StockStrategyRow row;
  final bool isBest;
  final bool selected;
  final VoidCallback onTap;
  const StockStrategyCard({
    super.key,
    required this.row,
    required this.isBest,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = atlasColors(context);
    final t = atlasText(context);
    final r = row;
    return AtlasCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: Sp.lg, vertical: Sp.md),
      child: Row(
        children: [
          if (isBest)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Icon(Icons.emoji_events_rounded, size: 15, color: c.warn),
            ),
          if (selected && !isBest)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Icon(Icons.radio_button_checked_rounded,
                  size: 13, color: c.accent),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.strategy, style: t.body),
                Row(children: [
                  Icon(Icons.query_stats_rounded, size: 11, color: c.textFaint),
                  const SizedBox(width: 3),
                  Text('${r.picks} picks', style: t.caption),
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
    );
  }
}
