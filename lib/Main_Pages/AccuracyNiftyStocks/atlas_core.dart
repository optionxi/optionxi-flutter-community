import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// -----------------------------------------------------------------------------
// CONFIG
// -----------------------------------------------------------------------------
const String kAtlasTable = 'atlas_output';
const String kOhlcvTable = 'nifty_ohlcv';
const String kOhlcvSymbol = 'NIFTY';
const String kYahooTicker = '^NSEI';

const List<int> kLookbackOptions = [5, 10, 15, 20, 30, 45, 60, 120, 180];
const int kDefaultLookback = 60;
const double kProbMin = 60, kProbMax = 90, kProbDefault = 70;
const int kExitMin = 5, kExitMax = 375, kExitDefault = 375;
const List<int> kFixedExitMinutes = [5, 10, 15, 20, 25, 30];
const int kStructureStopCandles = 3;
const int kYfMaxLookbackDays = 60;

const List<String> kEntryModes = [
  'First entry per day',
  'All entries',
  'Breakout entry (day H/L)',
];

class MarketHours {
  static const openHour = 9, openMinute = 15;
  static const closeHour = 15, closeMinute = 15;
}

// -----------------------------------------------------------------------------
// TIME HELPERS
// -----------------------------------------------------------------------------
DateTime msToIstWallClock(int ms) =>
    DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);

DateTime floorTo5(DateTime dt) =>
    DateTime.utc(dt.year, dt.month, dt.day, dt.hour, dt.minute - dt.minute % 5);

String fmtDate(DateTime dt) => DateFormat('yyyy-MM-dd').format(dt);
String fmtDateShort(DateTime dt) => DateFormat('d MMM').format(dt);
String fmtTime(DateTime dt) => DateFormat('HH:mm').format(dt);

String normalizeDirection(String? raw) {
  final s = (raw ?? '').toLowerCase();
  if (s.contains('bull')) return 'Bull';
  if (s.contains('bear')) return 'Bear';
  return 'Other';
}

String formatMinutes(double? mins) {
  if (mins == null || mins.isNaN) return '—';
  if (mins < 60) return '${mins.toStringAsFixed(0)}m';
  if (mins < 24 * 60) return '${(mins / 60).toStringAsFixed(1)}h';
  return '${(mins / (24 * 60)).toStringAsFixed(1)}d';
}

// -----------------------------------------------------------------------------
// MODELS
// -----------------------------------------------------------------------------
class Candle {
  final DateTime ts;
  final double open, high, low, close, volume;
  Candle(this.ts, this.open, this.high, this.low, this.close, this.volume);
}

class AtlasSignal {
  final DateTime dt;
  final String date;
  final String entryTimeIst;
  final DateTime candleLookupDt;
  final double probability;
  final String direction;
  final String? typeRaw;
  final int timeinmill;

  AtlasSignal({
    required this.dt,
    required this.date,
    required this.entryTimeIst,
    required this.candleLookupDt,
    required this.probability,
    required this.direction,
    this.typeRaw,
    required this.timeinmill,
  });

  static AtlasSignal fromRaw(Map<String, dynamic> r) {
    final ms = (r['timeinmill'] as num).toInt();
    final dt = msToIstWallClock(ms);
    return AtlasSignal(
      dt: dt,
      date: fmtDate(dt),
      entryTimeIst: fmtTime(dt),
      candleLookupDt: floorTo5(dt),
      probability: (r['probability'] as num?)?.toDouble() ?? 0,
      direction: normalizeDirection(r['type'] as String?),
      typeRaw: r['type']?.toString(),
      timeinmill: ms,
    );
  }
}

class Outcome {
  final AtlasSignal signal;
  final double startPrice, exitPrice, maxPrice, minPrice;
  final double netGainPcnt, maxProfitPcnt, maxLossPcnt;
  final bool success;
  final DateTime peakTime;
  final double timeToPeakMin;
  final DateTime windowEndDt;
  final int exitWindowMinutes;
  final double? stopLevel;
  final bool? stoppedOut;
  final double? dayHighSoFar, dayLowSoFar;
  final double? holdMinutes;

  Outcome({
    required this.signal,
    required this.startPrice,
    required this.exitPrice,
    required this.maxPrice,
    required this.minPrice,
    required this.netGainPcnt,
    required this.maxProfitPcnt,
    required this.maxLossPcnt,
    required this.success,
    required this.peakTime,
    required this.timeToPeakMin,
    required this.windowEndDt,
    required this.exitWindowMinutes,
    this.stopLevel,
    this.stoppedOut,
    this.dayHighSoFar,
    this.dayLowSoFar,
    this.holdMinutes,
  });
}

class DailySummary {
  final String date;
  final int signals;
  final int success;
  final double avgNetGain, avgMaxProfit, avgMaxLoss, avgTimeToPeak, accuracy;
  DailySummary({
    required this.date,
    required this.signals,
    required this.success,
    required this.avgNetGain,
    required this.avgMaxProfit,
    required this.avgMaxLoss,
    required this.avgTimeToPeak,
    required this.accuracy,
  });
}

class StrategyRow {
  final String strategy;
  final int signals;
  final double? winRate, avgGainPcnt, avgRiskPcnt, avgHoldMin, riskAdjScore;
  StrategyRow({
    required this.strategy,
    required this.signals,
    this.winRate,
    this.avgGainPcnt,
    this.avgRiskPcnt,
    this.avgHoldMin,
    this.riskAdjScore,
  });
}

// -----------------------------------------------------------------------------
// SETTINGS — one bag of state, passed around instead of 8 loose fields
// -----------------------------------------------------------------------------
class AtlasSettings {
  int lookbackDays;
  double minProbability;
  String entryMode;
  TimeOfDayLite entryStart;
  TimeOfDayLite entryEnd;
  int exitWindowMinutes;
  Set<String> directions;

  AtlasSettings({
    this.lookbackDays = kDefaultLookback,
    this.minProbability = kProbDefault,
    this.entryMode = 'Breakout entry (day H/L)',
    TimeOfDayLite? entryStart,
    TimeOfDayLite? entryEnd,
    this.exitWindowMinutes = kExitDefault,
    Set<String>? directions,
  })  : entryStart = entryStart ??
            const TimeOfDayLite(MarketHours.openHour, MarketHours.openMinute),
        entryEnd = entryEnd ??
            const TimeOfDayLite(MarketHours.closeHour, MarketHours.closeMinute),
        directions = directions ?? {'Bull', 'Bear'};

  AtlasSettings copy() => AtlasSettings(
        lookbackDays: lookbackDays,
        minProbability: minProbability,
        entryMode: entryMode,
        entryStart: entryStart,
        entryEnd: entryEnd,
        exitWindowMinutes: exitWindowMinutes,
        directions: {...directions},
      );
}

/// Lightweight stand-in for Flutter's TimeOfDay so this file has zero UI deps.
class TimeOfDayLite {
  final int hour, minute;
  const TimeOfDayLite(this.hour, this.minute);
  int get minutesOfDay => hour * 60 + minute;
  String get label =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

// -----------------------------------------------------------------------------
// SERVICES
// -----------------------------------------------------------------------------
class SupabaseService {
  final SupabaseClient? client;
  SupabaseService(this.client);

  Future<List<Map<String, dynamic>>> fetchAtlasEntries(
      int lookbackDays, double minProbability) async {
    if (client == null) return [];
    final today =
        DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
    final startDay = DateTime.utc(today.year, today.month, today.day)
        .subtract(Duration(days: lookbackDays - 1));
    final cutoffMs = startDay.millisecondsSinceEpoch;
    try {
      final resp = await client!
          .from(kAtlasTable)
          .select()
          .eq('entry', true)
          .gte('probability', minProbability)
          .gte('timeinmill', cutoffMs)
          .order('timeinmill', ascending: true);
      return List<Map<String, dynamic>>.from(resp as List);
    } catch (_) {
      return [];
    }
  }

  Future<List<Candle>> fetchOhlcvArchive(
      DateTime startDate, DateTime endDateInclusive) async {
    if (client == null) return [];
    final startUtc =
        DateTime.utc(startDate.year, startDate.month, startDate.day)
            .subtract(const Duration(hours: 5, minutes: 30));
    final endUtc = DateTime.utc(
            endDateInclusive.year, endDateInclusive.month, endDateInclusive.day)
        .add(const Duration(days: 1))
        .subtract(const Duration(hours: 5, minutes: 30));
    List<Map<String, dynamic>> all = [];
    int offset = 0;
    const pageSize = 1000;
    try {
      while (true) {
        final resp = await client!
            .from(kOhlcvTable)
            .select('ts,open,high,low,close,volume')
            .eq('symbol', kOhlcvSymbol)
            .gte('ts', startUtc.toIso8601String())
            .lt('ts', endUtc.toIso8601String())
            .order('ts', ascending: true)
            .range(offset, offset + pageSize - 1);
        final rows = List<Map<String, dynamic>>.from(resp as List);
        all.addAll(rows);
        if (rows.length < pageSize) break;
        offset += pageSize;
      }
    } catch (_) {
      return [];
    }
    return all.map((r) {
      final tsUtc = DateTime.parse(r['ts'] as String).toUtc();
      final tsIst = tsUtc.add(const Duration(hours: 5, minutes: 30));
      final tsIstWall = DateTime.utc(tsIst.year, tsIst.month, tsIst.day,
          tsIst.hour, tsIst.minute, tsIst.second);
      return Candle(
        tsIstWall,
        (r['open'] as num).toDouble(),
        (r['high'] as num).toDouble(),
        (r['low'] as num).toDouble(),
        (r['close'] as num).toDouble(),
        (r['volume'] as num?)?.toDouble() ?? 0,
      );
    }).toList();
  }
}

// -----------------------------------------------------------------------------
// ENGINE
// -----------------------------------------------------------------------------
class AtlasEngine {
  static List<AtlasSignal> buildSignals(
      List<Map<String, dynamic>> rawRows, bool onlyFirstEntry) {
    final all = rawRows.map(AtlasSignal.fromRaw).toList();
    if (!onlyFirstEntry) {
      all.sort((a, b) => b.dt.compareTo(a.dt));
      return all;
    }
    final Map<String, AtlasSignal> byDay = {};
    for (final s in all) {
      if (!byDay.containsKey(s.date) || s.dt.isBefore(byDay[s.date]!.dt)) {
        byDay[s.date] = s;
      }
    }
    final list = byDay.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  static List<AtlasSignal> filterByEntryTimeWindow(
      List<AtlasSignal> signals, TimeOfDayLite start, TimeOfDayLite end) {
    final s0 = start.minutesOfDay, s1 = end.minutesOfDay;
    return signals.where((s) {
      final m = s.dt.hour * 60 + s.dt.minute;
      return m >= s0 && m <= s1;
    }).toList();
  }

  static int? nearestIndex(List<Candle> candles, DateTime target) {
    if (candles.isEmpty) return null;
    int best = 0;
    Duration bestDiff = candles[0].ts.difference(target).abs();
    for (int i = 1; i < candles.length; i++) {
      final diff = candles[i].ts.difference(target).abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        best = i;
      }
    }
    return best;
  }

  static DateTime _openDt(String day) {
    final p = day.split('-').map(int.parse).toList();
    return DateTime.utc(
        p[0], p[1], p[2], MarketHours.openHour, MarketHours.openMinute);
  }

  static DateTime _closeDt(String day) {
    final p = day.split('-').map(int.parse).toList();
    return DateTime.utc(
        p[0], p[1], p[2], MarketHours.closeHour, MarketHours.closeMinute);
  }

  static List<AtlasSignal> selectBreakoutSignals(
      List<AtlasSignal> signals, Map<String, List<Candle>> store) {
    final Map<String, List<AtlasSignal>> byDay = {};
    for (final s in signals) {
      byDay.putIfAbsent(s.date, () => []).add(s);
    }
    final List<AtlasSignal> kept = [];
    byDay.forEach((day, daySignals) {
      final candles = store[day];
      if (candles == null || candles.isEmpty) return;
      final sorted = [...daySignals]..sort((a, b) => a.dt.compareTo(b.dt));
      final dayOpen = _openDt(day);
      for (final sig in sorted) {
        if (sig.direction != 'Bull' && sig.direction != 'Bear') continue;
        final entryDt = sig.dt;
        final prior = candles
            .where((c) => !c.ts.isBefore(dayOpen) && c.ts.isBefore(entryDt))
            .toList();
        final atEntry = candles.where((c) => !c.ts.isAfter(entryDt)).toList();
        if (prior.isEmpty || atEntry.isEmpty) continue;
        final entryCandle = atEntry.last;
        final dayHigh = prior.map((c) => c.high).reduce(math.max);
        final dayLow = prior.map((c) => c.low).reduce(math.min);
        final brokeOut =
            (sig.direction == 'Bull' && entryCandle.high > dayHigh) ||
                (sig.direction == 'Bear' && entryCandle.low < dayLow);
        if (brokeOut) {
          kept.add(sig);
          break;
        }
      }
    });
    kept.sort((a, b) => b.date.compareTo(a.date));
    return kept;
  }

  static List<Outcome> computeOutcomes(List<AtlasSignal> signals,
      Map<String, List<Candle>> store, int exitWindowMinutes) {
    final List<Outcome> out = [];
    for (final sig in signals) {
      final candles = store[sig.date];
      if (candles == null || candles.isEmpty) continue;
      if (sig.direction != 'Bull' && sig.direction != 'Bear') continue;
      final entryDt = sig.dt;
      final closeDt = _closeDt(sig.date);
      DateTime windowEnd;
      if (exitWindowMinutes >= 375) {
        windowEnd = closeDt;
      } else {
        final cand = entryDt.add(Duration(minutes: exitWindowMinutes));
        windowEnd = cand.isBefore(closeDt) ? cand : closeDt;
      }
      final w = candles
          .where((c) => !c.ts.isBefore(entryDt) && !c.ts.isAfter(windowEnd))
          .toList();
      if (w.isEmpty) continue;
      final startPrice = w.first.open;
      final exitPrice = w.last.close;
      final maxPrice = w.map((c) => c.high).reduce(math.max);
      final minPrice = w.map((c) => c.low).reduce(math.min);
      double netGain, maxProfit, maxLoss;
      if (sig.direction == 'Bear') {
        netGain =
            startPrice != 0 ? (startPrice - exitPrice) / startPrice * 100 : 0;
        maxProfit =
            startPrice != 0 ? (startPrice - minPrice) / startPrice * 100 : 0;
        maxLoss =
            startPrice != 0 ? (startPrice - maxPrice) / startPrice * 100 : 0;
      } else {
        netGain =
            startPrice != 0 ? (exitPrice - startPrice) / startPrice * 100 : 0;
        maxProfit =
            startPrice != 0 ? (maxPrice - startPrice) / startPrice * 100 : 0;
        maxLoss =
            startPrice != 0 ? (minPrice - startPrice) / startPrice * 100 : 0;
      }
      final entryHigh = w.first.high;
      final entryLow = w.first.low;
      final postEntry = w.length > 1 ? w.sublist(1) : <Candle>[];
      bool success = false;
      for (final c in postEntry) {
        if (sig.direction == 'Bear' && c.low < entryLow) {
          success = true;
          break;
        }
        if (sig.direction == 'Bull' && c.high > entryHigh) {
          success = true;
          break;
        }
      }
      final peakCandle = sig.direction == 'Bear'
          ? w.reduce((a, b) => a.low <= b.low ? a : b)
          : w.reduce((a, b) => a.high >= b.high ? a : b);
      final timeToPeak = peakCandle.ts.difference(entryDt).inSeconds / 60.0;
      out.add(Outcome(
        signal: sig,
        startPrice: startPrice,
        exitPrice: exitPrice,
        maxPrice: maxPrice,
        minPrice: minPrice,
        netGainPcnt: netGain,
        maxProfitPcnt: maxProfit,
        maxLossPcnt: maxLoss,
        success: success,
        peakTime: peakCandle.ts,
        timeToPeakMin: timeToPeak,
        windowEndDt: windowEnd,
        exitWindowMinutes: exitWindowMinutes,
      ));
    }
    out.sort((a, b) => b.signal.date.compareTo(a.signal.date));
    return out;
  }

  static List<DailySummary> computeDailySummary(List<Outcome> outcomes) {
    final Map<String, List<Outcome>> byDay = {};
    for (final o in outcomes) {
      byDay.putIfAbsent(o.signal.date, () => []).add(o);
    }
    double avg(List<double> xs) =>
        xs.isEmpty ? 0 : xs.reduce((a, b) => a + b) / xs.length;
    final list = byDay.entries.map((e) {
      final os = e.value;
      final n = os.length;
      final succ = os.where((o) => o.success).length;
      return DailySummary(
        date: e.key,
        signals: n,
        success: succ,
        avgNetGain: avg(os.map((o) => o.netGainPcnt).toList()),
        avgMaxProfit: avg(os.map((o) => o.maxProfitPcnt).toList()),
        avgMaxLoss: avg(os.map((o) => o.maxLossPcnt).toList()),
        avgTimeToPeak: avg(os.map((o) => o.timeToPeakMin).toList()),
        accuracy: n == 0 ? 0 : succ / n * 100,
      );
    }).toList();
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  static List<Outcome> computeStructureStopOutcomes(
      List<AtlasSignal> signals, Map<String, List<Candle>> store,
      {int nCandles = kStructureStopCandles}) {
    final List<Outcome> out = [];
    for (final sig in signals) {
      final candles = store[sig.date];
      if (candles == null || candles.isEmpty) continue;
      if (sig.direction != 'Bull' && sig.direction != 'Bear') continue;
      final entryDt = sig.dt;
      final closeDt = _closeDt(sig.date);
      final entryIdx = nearestIndex(candles, sig.candleLookupDt);
      if (entryIdx == null || entryIdx < nCandles) continue;
      final prevCandles = candles.sublist(entryIdx - nCandles, entryIdx);
      final stopLevel = sig.direction == 'Bear'
          ? prevCandles.map((c) => c.high).reduce(math.max)
          : prevCandles.map((c) => c.low).reduce(math.min);
      final w = candles
          .where((c) => !c.ts.isBefore(entryDt) && !c.ts.isAfter(closeDt))
          .toList();
      if (w.isEmpty) continue;
      final startPrice = w.first.open;
      bool stoppedOut = false;
      double exitPrice = 0;
      DateTime exitTime = w.last.ts;
      for (final c in w) {
        if (sig.direction == 'Bear' && c.high >= stopLevel) {
          exitPrice = stopLevel;
          exitTime = c.ts;
          stoppedOut = true;
          break;
        }
        if (sig.direction == 'Bull' && c.low <= stopLevel) {
          exitPrice = stopLevel;
          exitTime = c.ts;
          stoppedOut = true;
          break;
        }
      }
      if (!stoppedOut) {
        exitPrice = w.last.close;
        exitTime = w.last.ts;
      }
      final maxPrice = w.map((c) => c.high).reduce(math.max);
      final minPrice = w.map((c) => c.low).reduce(math.min);
      double netGain, maxProfit, maxLoss;
      if (sig.direction == 'Bear') {
        netGain = (startPrice - exitPrice) / startPrice * 100;
        maxProfit = (startPrice - minPrice) / startPrice * 100;
        maxLoss = (startPrice - maxPrice) / startPrice * 100;
      } else {
        netGain = (exitPrice - startPrice) / startPrice * 100;
        maxProfit = (maxPrice - startPrice) / startPrice * 100;
        maxLoss = (minPrice - startPrice) / startPrice * 100;
      }
      final holdMin = exitTime.difference(entryDt).inSeconds / 60.0;
      out.add(Outcome(
        signal: sig,
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
        windowEndDt: exitTime,
        exitWindowMinutes: 0,
        stopLevel: stopLevel,
        stoppedOut: stoppedOut,
        holdMinutes: holdMin,
      ));
    }
    out.sort((a, b) => b.signal.date.compareTo(a.signal.date));
    return out;
  }

  static List<Outcome> computeBreakoutEntryOutcomes(
      List<AtlasSignal> signals, Map<String, List<Candle>> store) {
    final List<Outcome> out = [];
    final Map<String, List<AtlasSignal>> byDay = {};
    for (final s in signals) {
      byDay.putIfAbsent(s.date, () => []).add(s);
    }
    byDay.forEach((day, daySignals) {
      final candles = store[day];
      if (candles == null || candles.isEmpty) return;
      final sorted = [...daySignals]..sort((a, b) => a.dt.compareTo(b.dt));
      final dayOpen = _openDt(day);
      final closeDt = _closeDt(day);
      for (final sig in sorted) {
        if (sig.direction != 'Bull' && sig.direction != 'Bear') continue;
        final entryDt = sig.dt;
        final prior = candles
            .where((c) => !c.ts.isBefore(dayOpen) && c.ts.isBefore(entryDt))
            .toList();
        final atEntry = candles.where((c) => !c.ts.isAfter(entryDt)).toList();
        if (prior.isEmpty || atEntry.isEmpty) continue;
        final entryCandle = atEntry.last;
        final dayHigh = prior.map((c) => c.high).reduce(math.max);
        final dayLow = prior.map((c) => c.low).reduce(math.min);
        final brokeOut =
            (sig.direction == 'Bull' && entryCandle.high > dayHigh) ||
                (sig.direction == 'Bear' && entryCandle.low < dayLow);
        if (!brokeOut) continue;
        final w = candles
            .where((c) => !c.ts.isBefore(entryDt) && !c.ts.isAfter(closeDt))
            .toList();
        if (w.isEmpty) continue;
        final startPrice = w.first.open;
        final exitPrice = w.last.close;
        final maxPrice = w.map((c) => c.high).reduce(math.max);
        final minPrice = w.map((c) => c.low).reduce(math.min);
        double netGain, maxProfit, maxLoss;
        if (sig.direction == 'Bear') {
          netGain = (startPrice - exitPrice) / startPrice * 100;
          maxProfit = (startPrice - minPrice) / startPrice * 100;
          maxLoss = (startPrice - maxPrice) / startPrice * 100;
        } else {
          netGain = (exitPrice - startPrice) / startPrice * 100;
          maxProfit = (maxPrice - startPrice) / startPrice * 100;
          maxLoss = (minPrice - startPrice) / startPrice * 100;
        }
        final holdMin = w.last.ts.difference(entryDt).inSeconds / 60.0;
        out.add(Outcome(
          signal: sig,
          startPrice: startPrice,
          exitPrice: exitPrice,
          maxPrice: maxPrice,
          minPrice: minPrice,
          netGainPcnt: netGain,
          maxProfitPcnt: maxProfit,
          maxLossPcnt: maxLoss,
          success: netGain > 0,
          peakTime: w.last.ts,
          timeToPeakMin: holdMin,
          windowEndDt: w.last.ts,
          exitWindowMinutes: 0,
          dayHighSoFar: dayHigh,
          dayLowSoFar: dayLow,
          holdMinutes: holdMin,
        ));
      }
    });
    out.sort((a, b) => b.signal.date.compareTo(a.signal.date));
    return out;
  }

  static List<StrategyRow> buildExitStrategySummary(List<AtlasSignal> signals,
      Map<String, List<Candle>> store, Map<String, List<Outcome>> detailOut) {
    final rows = <StrategyRow>[];
    double? avgOf(Iterable<double> xs) {
      final l = xs.toList();
      return l.isEmpty ? null : l.reduce((a, b) => a + b) / l.length;
    }

    for (final m in kFixedExitMinutes) {
      final label = 'Exit @ ${m}min';
      final df = computeOutcomes(signals, store, m);
      detailOut[label] = df;
      if (df.isEmpty) {
        rows.add(
            StrategyRow(strategy: label, signals: 0, avgHoldMin: m.toDouble()));
        continue;
      }
      final winRate =
          df.where((o) => o.netGainPcnt > 0).length / df.length * 100;
      rows.add(StrategyRow(
        strategy: label,
        signals: df.length,
        winRate: winRate,
        avgGainPcnt: avgOf(df.map((o) => o.netGainPcnt)),
        avgRiskPcnt: avgOf(df.map((o) => o.maxLossPcnt)),
        avgHoldMin: m.toDouble(),
      ));
    }

    final structLabel = 'Structure Stop (${kStructureStopCandles}c)';
    final structDf = computeStructureStopOutcomes(signals, store);
    detailOut[structLabel] = structDf;
    if (structDf.isEmpty) {
      rows.add(StrategyRow(strategy: structLabel, signals: 0));
    } else {
      final winRate = structDf.where((o) => o.netGainPcnt > 0).length /
          structDf.length *
          100;
      rows.add(StrategyRow(
        strategy: structLabel,
        signals: structDf.length,
        winRate: winRate,
        avgGainPcnt: avgOf(structDf.map((o) => o.netGainPcnt)),
        avgRiskPcnt: avgOf(structDf.map((o) => o.maxLossPcnt)),
        avgHoldMin: avgOf(structDf.map((o) => o.holdMinutes ?? 0)),
      ));
    }

    const breakoutLabel = 'Breakout Entry';
    final breakoutDf = computeBreakoutEntryOutcomes(signals, store);
    detailOut[breakoutLabel] = breakoutDf;
    if (breakoutDf.isEmpty) {
      rows.add(StrategyRow(strategy: breakoutLabel, signals: 0));
    } else {
      final winRate = breakoutDf.where((o) => o.netGainPcnt > 0).length /
          breakoutDf.length *
          100;
      rows.add(StrategyRow(
        strategy: breakoutLabel,
        signals: breakoutDf.length,
        winRate: winRate,
        avgGainPcnt: avgOf(breakoutDf.map((o) => o.netGainPcnt)),
        avgRiskPcnt: avgOf(breakoutDf.map((o) => o.maxLossPcnt)),
        avgHoldMin: avgOf(breakoutDf.map((o) => o.holdMinutes ?? 0)),
      ));
    }

    return rows.map((r) {
      if (r.avgGainPcnt != null &&
          r.avgRiskPcnt != null &&
          r.avgRiskPcnt != 0) {
        return StrategyRow(
          strategy: r.strategy,
          signals: r.signals,
          winRate: r.winRate,
          avgGainPcnt: r.avgGainPcnt,
          avgRiskPcnt: r.avgRiskPcnt,
          avgHoldMin: r.avgHoldMin,
          riskAdjScore: r.avgGainPcnt! / r.avgRiskPcnt!.abs(),
        );
      }
      return r;
    }).toList();
  }
}

// -----------------------------------------------------------------------------
// CSV EXPORT
// -----------------------------------------------------------------------------
String outcomesToCsv(List<Outcome> rows) {
  final headers = [
    'date',
    'entry_time',
    'direction',
    'probability',
    'start_price',
    'exit_price',
    'net_gain_pcnt',
    'max_profit_pcnt',
    'max_loss_pcnt',
    'time_to_peak_min',
    'success',
  ];
  final buf = StringBuffer()..writeln(headers.join(','));
  for (final o in rows) {
    buf.writeln([
      o.signal.date,
      o.signal.entryTimeIst,
      o.signal.direction,
      o.signal.probability.toStringAsFixed(1),
      o.startPrice.toStringAsFixed(2),
      o.exitPrice.toStringAsFixed(2),
      o.netGainPcnt.toStringAsFixed(2),
      o.maxProfitPcnt.toStringAsFixed(2),
      o.maxLossPcnt.toStringAsFixed(2),
      o.timeToPeakMin.toStringAsFixed(1),
      o.success,
    ].join(','));
  }
  return buf.toString();
}

// A tiny wrapper class name kept for import ergonomics in the theme file.
typedef TimeOfDay = TimeOfDayLite;
