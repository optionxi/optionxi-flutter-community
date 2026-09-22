// ─────────────────────────────────────────────────────────────────────────
// Strategy Builder — single-file Flutter page (mobile version).
//
// Drop this file into your app (e.g. lib/pages/strategy_builder_page.dart)
// and push/route to `const StrategyBuilderPage()`.
//
// Requirements:
//   - pubspec.yaml: supabase_flutter: ^2.0.0
//   - Supabase must already be initialized in main():
//       await Supabase.initialize(url: '...', anonKey: '...');
//   - Reads from two Postgres tables (same as the web version):
//       public.index_optionchain_historical  (option chain snapshots)
//       public.nifty_ohlcv                   (5-minute OHLCV, symbol =
//                                              "NIFTY" or "BANKNIFTY")
//
// What changed vs the Next.js web version, for mobile + "layman" clarity:
//   - Side-by-side layout (chain | chart | payoff) became 3 tabs at the top.
//   - The right-rail P&L card + payoff chart now live under a "Profit/Loss"
//     tab, scrollable.
//   - Positions moved to a bottom bar (count + total P&L) that opens a
//     draggable bottom sheet with the full leg list — same idea as the web
//     version's collapsed strip.
//   - A plain-English info banner explains CE/PE and Buy/Sell up front.
//   - Bid/ask/prev-OI/volume columns dropped from the option row (not shown
//     in the original UI either) to keep the model lean for mobile.
//   - Charts are hand-drawn with CustomPainter (no external chart package),
//     so behaviour matches the original SVG charts 1:1.
//
// ─── IST handling ──────────────────────────────────────────────────────
// Market data is always IST, independent of device timezone. DateTime.now()
// and DateTime.parse() on a bare (no-offset) string both silently assume the
// DEVICE's local zone in Dart — which is wrong for any non-IST device.
//
// Schema reality: both `ts` columns are Postgres `timestamptz` and store true
// UTC instants (with an explicit `+00` offset, e.g. `2026-09-11 03:45:00+00`).
// So:
//   * When reading a `ts` out of the DB, `parseIst()` sees the `Z`/offset,
//     shifts it by +05:30, and returns IST wall-clock tagged as UTC. This is
//     what every DateTime in this file represents internally.
//   * When sending a DateTime to Postgres, we must convert it BACK to a true
//     UTC instant first (subtract the IST offset), so the literal carries a
//     `Z` and PostgREST/Postgres compare it as the instant we mean.
//   * Sending a naive (no-offset) ISO string would be interpreted as UTC by
//     Postgres, silently shifting the comparison by 5:30. That was the bug.
// ─────────────────────────────────────────────────────────────────────────

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/* ════════════════════════════════════════════════════════════════════════
   IST handling
   ════════════════════════════════════════════════════════════════════════ */

const Duration _istOffset = Duration(hours: 5, minutes: 30);

/// Current wall-clock time in IST, regardless of the device's timezone.
DateTime nowIst() => DateTime.now().toUtc().add(_istOffset);

/// Parses a Supabase timestamp into an IST wall-clock DateTime. Handles:
///  - "2024-01-01T09:15:00"         (naive, treated as already IST)
///  - "2026-09-11T03:45:00+00"      (true UTC -> shift to IST)
///  - "...T03:45:00Z"               (true UTC -> shift to IST)
///
/// Both `ts` columns in this schema are `timestamptz` storing true UTC, so
/// the UTC/offset branch is the one that fires in practice.
DateTime? parseIst(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return null;
  final ist = parsed.isUtc ? parsed.add(_istOffset) : parsed;
  return DateTime.utc(
      ist.year, ist.month, ist.day, ist.hour, ist.minute, ist.second);
}

/// Converts an IST wall-clock DateTime (internally tagged as UTC) back into a
/// true UTC instant string with a trailing `Z`, suitable for comparing against
/// `timestamptz` columns that store real UTC instants.
String isoUtcFromIst(DateTime istWallClock) =>
    istWallClock.subtract(_istOffset).toIso8601String();

/* ════════════════════════════════════════════════════════════════════════
   Constants
   ════════════════════════════════════════════════════════════════════════ */

const List<String> kIndexOptions = ['NIFTY', 'BANKNIFTY'];
const Map<String, int> kLotSize = {'NIFTY': 65, 'BANKNIFTY': 30};
const double kRiskFreeRate = 0.065;
const int kStrikeSpan = 15; // strikes shown on each side of ATM

const String kChainTable = 'index_optionchain_historical';
const String kCandleTable = 'nifty_ohlcv';

const int kMarketOpenH = 9, kMarketOpenM = 15;
const int kMarketCloseH = 15, kMarketCloseM = 30;

DateTime clampToMarketHours(DateTime d) {
  final openMin = kMarketOpenH * 60 + kMarketOpenM;
  final closeMin = kMarketCloseH * 60 + kMarketCloseM;
  final curMin = d.hour * 60 + d.minute;
  if (curMin < openMin) {
    return DateTime.utc(d.year, d.month, d.day, kMarketOpenH, kMarketOpenM);
  }
  if (curMin > closeMin) {
    return DateTime.utc(d.year, d.month, d.day, kMarketCloseH, kMarketCloseM);
  }
  return DateTime.utc(d.year, d.month, d.day, d.hour, d.minute);
}

/// Returns the most recent weekday (Mon–Fri) at market open, walking
/// backwards from [d] if [d] itself falls on a weekend.
DateTime lastWeekdayMarketOpen(DateTime d) {
  var day = d;
  while (day.weekday == DateTime.saturday || day.weekday == DateTime.sunday) {
    day = day.subtract(const Duration(days: 1));
  }
  return DateTime.utc(day.year, day.month, day.day, kMarketOpenH, kMarketOpenM);
}

/// Initial `asOf` for page load: if today (IST) is a weekend, snap to the
/// last weekday's 9:15 AM; otherwise clamp the current time to market hours.
DateTime initialMarketAsOf() {
  final now = nowIst();
  if (now.weekday == DateTime.saturday || now.weekday == DateTime.sunday) {
    return lastWeekdayMarketOpen(now);
  }
  return clampToMarketHours(now);
}

String dateStrOf(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String timeStrOf(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/* ════════════════════════════════════════════════════════════════════════
   Models
   ════════════════════════════════════════════════════════════════════════ */

enum OptionType { CE, PE }

enum LegAction { BUY, SELL }

class OptionChainRow {
  final String indexName;
  final DateTime ts;
  final String? expiryDate;
  final double? atmStrike;
  final double? strikePrice;
  final OptionType optionType;
  final double? ltp;
  final double? closePrice;
  final double? oi;
  final double? iv;

  OptionChainRow({
    required this.indexName,
    required this.ts,
    this.expiryDate,
    this.atmStrike,
    this.strikePrice,
    required this.optionType,
    this.ltp,
    this.closePrice,
    this.oi,
    this.iv,
  });

  static double? _num(dynamic v) => v == null ? null : (v as num).toDouble();

  factory OptionChainRow.fromMap(Map<String, dynamic> m) {
    return OptionChainRow(
      indexName: m['index_name']?.toString() ?? '',
      ts: parseIst(m['ts']?.toString()) ?? nowIst(),
      expiryDate: m['expiry_date']?.toString(),
      atmStrike: _num(m['atm_strike']),
      strikePrice: _num(m['strike_price']),
      optionType:
          m['option_type']?.toString() == 'PE' ? OptionType.PE : OptionType.CE,
      ltp: _num(m['ltp']),
      closePrice: _num(m['close_price']),
      oi: _num(m['oi']),
      iv: _num(m['iv']),
    );
  }
}

class ChainStrikeRow {
  final double strike;
  OptionChainRow? ce;
  OptionChainRow? pe;
  ChainStrikeRow({required this.strike, this.ce, this.pe});
}

class ChainSnapshot {
  final String? ts;
  final double? atmStrike;
  final List<ChainStrikeRow> rows;
  ChainSnapshot({this.ts, this.atmStrike, required this.rows});
  static ChainSnapshot empty() =>
      ChainSnapshot(ts: null, atmStrike: null, rows: []);
}

class Leg {
  final String legId;
  final double strike;
  final OptionType optionType;
  final LegAction action;
  int lots;
  final double entryPrice;
  final double? entryIv;
  final DateTime entryTs;
  final String? entryExpiry;
  double? currentPrice;
  double? currentIv;
  DateTime? currentTs;
  bool stale;

  Leg({
    required this.legId,
    required this.strike,
    required this.optionType,
    required this.action,
    required this.lots,
    required this.entryPrice,
    this.entryIv,
    required this.entryTs,
    this.entryExpiry,
    this.currentPrice,
    this.currentIv,
    this.currentTs,
    this.stale = false,
  });
}

class Candle {
  final DateTime ts;
  final double open, high, low, close;
  final double? volume;
  Candle(
      {required this.ts,
      required this.open,
      required this.high,
      required this.low,
      required this.close,
      this.volume});
}

class Greeks {
  final double delta, gamma, theta, vega;
  Greeks(this.delta, this.gamma, this.theta, this.vega);
}

class StrategyMetrics {
  final double maxProfit;
  final bool maxProfitUnlimited;
  final double maxLoss;
  final bool maxLossUnlimited;
  final List<double> breakevens;
  StrategyMetrics({
    required this.maxProfit,
    required this.maxProfitUnlimited,
    required this.maxLoss,
    required this.maxLossUnlimited,
    required this.breakevens,
  });
}

/* ════════════════════════════════════════════════════════════════════════
   Supabase queries (all read-only)
   ════════════════════════════════════════════════════════════════════════ */

Future<String?> findNearestSnapshotTs(String indexName, DateTime target) async {
  final supabase = Supabase.instance.client;
  // `target` is an IST wall-clock value tagged as UTC (see IST handling notes
  // above). The `ts` column is `timestamptz` holding true UTC instants, so we
  // must convert the IST wall-clock back to a real UTC instant (with a `Z`)
  // before querying — otherwise Postgres would read the literal as UTC and
  // silently shift the comparison by +05:30, pulling a later snapshot.
  final targetIso = isoUtcFromIst(target);

  final before = await supabase
      .from(kChainTable)
      .select('ts')
      .eq('index_name', indexName)
      .lte('ts', targetIso)
      .order('ts', ascending: false)
      .limit(1);
  if (before.isNotEmpty) return before[0]['ts'].toString();

  final after = await supabase
      .from(kChainTable)
      .select('ts')
      .eq('index_name', indexName)
      .gt('ts', targetIso)
      .order('ts', ascending: true)
      .limit(1);
  if (after.isNotEmpty) return after[0]['ts'].toString();

  return null;
}

Future<List<String>> fetchExpiries(String indexName) async {
  final supabase = Supabase.instance.client;
  final data = await supabase.rpc(
    'get_index_expiries',
    params: {'p_index_name': indexName},
  );
  final set = <String>{};
  for (final row in data as List) {
    final v = row['expiry_date'];
    if (v != null) set.add(v.toString());
  }
  final list = set.toList()..sort();
  return list;
}

Future<ChainSnapshot> fetchChainAtTs(
    String indexName, String expiryDate, String ts) async {
  final supabase = Supabase.instance.client;
  final data = await supabase
      .from(kChainTable)
      .select()
      .eq('index_name', indexName)
      .eq('expiry_date', expiryDate)
      .eq('ts', ts)
      .order('strike_price', ascending: true);

  final rows = data.map((m) => OptionChainRow.fromMap(m)).toList();
  final byStrike = <double, ChainStrikeRow>{};
  double? atmStrike;

  for (final row in rows) {
    if (row.strikePrice == null) continue;
    if (row.atmStrike != null) atmStrike = row.atmStrike;
    final strike = row.strikePrice!;
    final existing = byStrike[strike] ?? ChainStrikeRow(strike: strike);
    if (row.optionType == OptionType.CE) {
      existing.ce = row;
    } else {
      existing.pe = row;
    }
    byStrike[strike] = existing;
  }

  final sorted = byStrike.values.toList()
    ..sort((a, b) => a.strike.compareTo(b.strike));
  return ChainSnapshot(
      ts: rows.isNotEmpty ? ts : null, atmStrike: atmStrike, rows: sorted);
}

/// Looks up a single strike/option_type's price at (or before) [ts], used to
/// reprice an existing leg when the user moves the snapshot time.
///
/// [ts] is expected to be a `ts` string that came straight out of the DB
/// (with its `+00` offset intact), so no naive-string round-trip happens here.
Future<Map<String, dynamic>> fetchLegPrice(
  String indexName,
  String? expiryDate,
  double strike,
  OptionType type,
  String ts,
) async {
  final supabase = Supabase.instance.client;
  var builder = supabase
      .from(kChainTable)
      .select('ltp, close_price, iv, ts')
      .eq('index_name', indexName)
      .eq('strike_price', strike)
      .eq('option_type', type.name)
      .lte('ts', ts);
  final filtered =
      expiryDate != null ? builder.eq('expiry_date', expiryDate) : builder;
  final data = await filtered.order('ts', ascending: false).limit(1);

  if (data.isNotEmpty) {
    final row = data[0];
    final priceRaw = row['ltp'] ?? row['close_price'];
    return {
      'price': priceRaw != null ? (priceRaw as num).toDouble() : null,
      'iv': row['iv'] != null ? (row['iv'] as num).toDouble() : null,
      'ts': row['ts']?.toString(),
    };
  }
  return {'price': null, 'iv': null, 'ts': null};
}

Future<List<Candle>> fetchCandles(String symbol, String dateStr) async {
  final supabase = Supabase.instance.client;
  // `dateStr` is an IST calendar date ("yyyy-MM-dd"). The `ts` column is
  // `timestamptz` storing true UTC, so we build the IST day bounds and then
  // convert each to a real UTC instant (with a `Z`) before querying.
  final parts = dateStr.split('-').map(int.parse).toList();
  final dayStartIst = DateTime.utc(parts[0], parts[1], parts[2], 0, 0, 0);
  final dayEndIst = DateTime.utc(parts[0], parts[1], parts[2], 23, 59, 59);
  final dayStart = isoUtcFromIst(dayStartIst);
  final dayEnd = isoUtcFromIst(dayEndIst);

  final data = await supabase
      .from(kCandleTable)
      .select('ts, open, high, low, close, volume')
      .eq('symbol', symbol)
      .gte('ts', dayStart)
      .lte('ts', dayEnd)
      .order('ts', ascending: true)
      .limit(300);

  final list = <Candle>[];
  for (final r in data) {
    if (r['ts'] == null ||
        r['open'] == null ||
        r['high'] == null ||
        r['low'] == null ||
        r['close'] == null) continue;
    final ts = parseIst(r['ts'].toString());
    if (ts == null) continue;
    list.add(Candle(
      ts: ts,
      open: (r['open'] as num).toDouble(),
      high: (r['high'] as num).toDouble(),
      low: (r['low'] as num).toDouble(),
      close: (r['close'] as num).toDouble(),
      volume: r['volume'] != null ? (r['volume'] as num).toDouble() : null,
    ));
  }
  return list;
}

/* ════════════════════════════════════════════════════════════════════════
   Black-Scholes helpers (Greeks + repricing on the payoff chart)
   ════════════════════════════════════════════════════════════════════════ */

double erf(double x) {
  final sign = x < 0 ? -1.0 : 1.0;
  final ax = x.abs();
  const a1 = 0.254829592,
      a2 = -0.284496736,
      a3 = 1.421413741,
      a4 = -1.453152027,
      a5 = 1.061405429,
      p = 0.3275911;
  final t = 1 / (1 + p * ax);
  final y = 1 -
      ((((a5 * t + a4) * t + a3) * t + a2) * t + a1) * t * math.exp(-ax * ax);
  return sign * y;
}

double normCdf(double x) => 0.5 * (1 + erf(x / math.sqrt(2)));

double normPdf(double x) => math.exp(-0.5 * x * x) / math.sqrt(2 * math.pi);

double bsPrice(double spot, double strike, double t, double sigma, double r,
    OptionType type) {
  final intrinsic = type == OptionType.CE
      ? math.max(spot - strike, 0.0)
      : math.max(strike - spot, 0.0);
  if (t <= 0 || sigma <= 0 || spot <= 0 || strike <= 0) return intrinsic;
  final sqrtT = math.sqrt(t);
  final d1 = (math.log(spot / strike) + (r + (sigma * sigma) / 2) * t) /
      (sigma * sqrtT);
  final d2 = d1 - sigma * sqrtT;
  if (type == OptionType.CE) {
    return spot * normCdf(d1) - strike * math.exp(-r * t) * normCdf(d2);
  }
  return strike * math.exp(-r * t) * normCdf(-d2) - spot * normCdf(-d1);
}

Greeks bsGreeks(double spot, double strike, double t, double sigma, double r,
    OptionType type) {
  if (t <= 0 || sigma <= 0 || spot <= 0 || strike <= 0)
    return Greeks(0, 0, 0, 0);
  final sqrtT = math.sqrt(t);
  final d1 = (math.log(spot / strike) + (r + (sigma * sigma) / 2) * t) /
      (sigma * sqrtT);
  final d2 = d1 - sigma * sqrtT;
  final pdf = normPdf(d1);
  final delta = type == OptionType.CE ? normCdf(d1) : normCdf(d1) - 1;
  final gamma = pdf / (spot * sigma * sqrtT);
  final vega = (spot * pdf * sqrtT) / 100;
  final thetaYear = type == OptionType.CE
      ? -((spot * pdf * sigma) / (2 * sqrtT)) -
          r * strike * math.exp(-r * t) * normCdf(d2)
      : -((spot * pdf * sigma) / (2 * sqrtT)) +
          r * strike * math.exp(-r * t) * normCdf(-d2);
  return Greeks(delta, gamma, thetaYear / 365, vega);
}

/// Fractional days remaining to [expiryDate] ("yyyy-MM-dd"), assuming a
/// 15:30 close.
double daysToExpiry(String expiryDate, DateTime asOf) {
  final parts = expiryDate.split('-').map(int.parse).toList();
  final close = DateTime.utc(parts[0], parts[1], parts[2], 15, 30);
  final diffSeconds = close.difference(asOf).inSeconds;
  return math.max(0.0, diffSeconds / 86400);
}

/// Estimate underlying spot from ATM put-call parity: spot ≈ strike + CE - PE.
double? estimateSpotFromChain(ChainSnapshot chain) {
  if (chain.atmStrike == null) return null;
  ChainStrikeRow? atmRow;
  for (final r in chain.rows) {
    if (r.strike == chain.atmStrike) {
      atmRow = r;
      break;
    }
  }
  final ce = atmRow?.ce?.ltp;
  final pe = atmRow?.pe?.ltp;
  if (ce != null && pe != null) return chain.atmStrike! + ce - pe;
  return chain.atmStrike;
}

/// Latest candle close at-or-before [asOf] — the more reliable spot when available.
double? spotFromCandles(List<Candle> candles, DateTime asOf) {
  if (candles.isEmpty) return null;
  Candle? chosen;
  for (final c in candles) {
    if (!c.ts.isAfter(asOf)) {
      chosen = c;
    } else {
      break;
    }
  }
  return (chosen ?? candles.first).close;
}

double payoffAtSpot(List<Leg> legs, int lotSize, double spot) {
  double sum = 0;
  for (final leg in legs) {
    final qty = leg.lots * lotSize;
    final dir = leg.action == LegAction.BUY ? 1 : -1;
    final value = bsPrice(spot, leg.strike, 0, 0, 0, leg.optionType);
    sum += (value - leg.entryPrice) * qty * dir;
  }
  return sum;
}

StrategyMetrics? computeStrategyMetrics(List<Leg> legs, int lotSize) {
  if (legs.isEmpty) return null;
  final strikes = legs.map((l) => l.strike).toList();
  final minStrike = strikes.reduce(math.min);
  final maxStrike = strikes.reduce(math.max);
  final lo = math.max(0.0, minStrike - minStrike * 0.5);
  final hi = maxStrike * 2.5;

  const n = 400;
  final xs = <double>[];
  final ys = <double>[];
  for (int i = 0; i <= n; i++) {
    final x = lo + (hi - lo) * i / n;
    xs.add(x);
    ys.add(payoffAtSpot(legs, lotSize, x));
  }

  double maxProfit = double.negativeInfinity, maxLoss = double.infinity;
  for (final y in ys) {
    if (y > maxProfit) maxProfit = y;
    if (y < maxLoss) maxLoss = y;
  }

  final rightSlope = ys[n] - ys[n - 1];
  final epsilon = math.max(1.0, lotSize * 0.001);
  final maxProfitUnlimited = rightSlope > epsilon;
  final maxLossUnlimited = rightSlope < -epsilon;

  final breakevens = <double>[];
  for (int i = 1; i < ys.length; i++) {
    if ((ys[i - 1] < 0 && ys[i] >= 0) || (ys[i - 1] > 0 && ys[i] <= 0)) {
      final t = ys[i - 1] == ys[i] ? 0.0 : -ys[i - 1] / (ys[i] - ys[i - 1]);
      breakevens.add(xs[i - 1] + t * (xs[i] - xs[i - 1]));
    }
  }

  return StrategyMetrics(
    maxProfit: maxProfit,
    maxProfitUnlimited: maxProfitUnlimited,
    maxLoss: maxLoss,
    maxLossUnlimited: maxLossUnlimited,
    breakevens: breakevens,
  );
}

double stepGuess(List<ChainStrikeRow> rows, double atm) {
  final sorted = rows.map((r) => r.strike).toList()..sort();
  final idx = sorted.indexOf(atm);
  if (idx > 0) return sorted[idx] - sorted[idx - 1];
  if (sorted.length > 1) return sorted[1] - sorted[0];
  return 50;
}

/* ════════════════════════════════════════════════════════════════════════
   Formatting helpers (plain thousands-grouping, no intl dependency)
   ════════════════════════════════════════════════════════════════════════ */

String _groupThousands(String intPart) {
  final buf = StringBuffer();
  int count = 0;
  for (int i = intPart.length - 1; i >= 0; i--) {
    buf.write(intPart[i]);
    count++;
    if (count % 3 == 0 && i != 0) buf.write(',');
  }
  return buf.toString().split('').reversed.join();
}

String fmtNum(double? n, {int digits = 2}) {
  if (n == null || n.isNaN) return '—';
  final neg = n < 0;
  final fixed = n.abs().toStringAsFixed(digits);
  final dotIdx = fixed.indexOf('.');
  final intPart = dotIdx == -1 ? fixed : fixed.substring(0, dotIdx);
  final decPart = dotIdx == -1 ? '' : fixed.substring(dotIdx);
  return '${neg ? '-' : ''}${_groupThousands(intPart)}$decPart';
}

String fmtInt(num? n) =>
    n == null ? '—' : _groupThousands(n.round().toString());

String signed(double n) {
  final s = fmtNum(n.abs());
  return n >= 0 ? '+$s' : '-$s';
}

/* ════════════════════════════════════════════════════════════════════════
   Candlestick chart (tap / drag to jump the option-chain snapshot time)
   ════════════════════════════════════════════════════════════════════════ */

class CandleChartWidget extends StatefulWidget {
  final String symbol;
  final List<Candle> candles;
  final List<Leg> legs;
  final DateTime asOf;
  final ValueChanged<DateTime> onSelectTime;
  final bool loading;

  const CandleChartWidget({
    super.key,
    required this.symbol,
    required this.candles,
    required this.legs,
    required this.asOf,
    required this.onSelectTime,
    required this.loading,
  });

  @override
  State<CandleChartWidget> createState() => _CandleChartWidgetState();
}

class _CandleChartWidgetState extends State<CandleChartWidget> {
  static const _padLeft = 48.0, _padRight = 12.0;

  /// Index of the candle currently under the finger during a drag / tap.
  /// Purely local — no network, no re-price. Used both to drive the
  /// crosshair + tooltip and to commit a new snapshot time on gesture end.
  int? _previewIdx;

  int? _indexForX(double dx, double width) {
    final n = widget.candles.length;
    if (n == 0) return null;
    final slot = (width - _padLeft - _padRight) / n;
    return ((dx - _padLeft) / slot).floor().clamp(0, n - 1);
  }

  void _preview(Offset local, double width) {
    final idx = _indexForX(local.dx, width);
    if (idx == null || idx == _previewIdx) return;
    setState(() => _previewIdx = idx); // cheap local rebuild, no network
  }

  void _commit() {
    final idx = _previewIdx;
    if (idx != null && idx >= 0 && idx < widget.candles.length) {
      widget.onSelectTime(widget.candles[idx].ts);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loading) {
      return const SizedBox(
          height: 260, child: Center(child: CircularProgressIndicator()));
    }
    if (widget.candles.isEmpty) {
      return SizedBox(
        height: 220,
        child: Center(
          child: Text(
              'No 5-minute candles for this session yet.\nTry a different date for ${widget.symbol}.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey)),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${widget.symbol} · 5 min candles',
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          LayoutBuilder(builder: (context, constraints) {
            final width = constraints.maxWidth;
            const height = 260.0;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) {
                _preview(d.localPosition, width);
                _commit();
              },
              onPanStart: (d) => _preview(d.localPosition, width),
              onPanUpdate: (d) => _preview(d.localPosition, width),
              onPanEnd: (_) => _commit(),
              onPanCancel: _commit,
              child: CustomPaint(
                size: Size(width, height),
                painter: CandleChartPainter(
                  candles: widget.candles,
                  legs: widget.legs,
                  asOf: widget.asOf,
                  previewIdx: _previewIdx,
                  lotSize: kLotSize[widget.symbol] ?? 1,
                  isDark: Theme.of(context).brightness == Brightness.dark,
                ),
              ),
            );
          }),
          const SizedBox(height: 6),
          const Text(
              'Tap or drag the chart to preview that bar, release to jump the '
              'option chain and P&L to that time.',
              style: TextStyle(fontSize: 10, color: Colors.grey)),
          const SizedBox(height: 4),
          Row(children: const [
            Icon(Icons.arrow_drop_up, color: Colors.green, size: 16),
            Text('Buy', style: TextStyle(fontSize: 10)),
            SizedBox(width: 12),
            Icon(Icons.arrow_drop_down, color: Colors.red, size: 16),
            Text('Sell', style: TextStyle(fontSize: 10)),
          ]),
        ],
      ),
    );
  }
}

class CandleChartPainter extends CustomPainter {
  final List<Candle> candles;
  final List<Leg> legs;
  final DateTime asOf;
  final int? previewIdx;
  final int lotSize;
  final bool isDark;

  CandleChartPainter({
    required this.candles,
    required this.legs,
    required this.asOf,
    required this.previewIdx,
    required this.lotSize,
    required this.isDark,
  });

  static const _padLeft = 48.0,
      _padRight = 12.0,
      _padTop = 10.0,
      _padBottom = 20.0;

  @override
  void paint(Canvas canvas, Size size) {
    final n = candles.length;
    if (n == 0) return;
    final plotW = size.width - _padLeft - _padRight;
    final plotH = size.height - _padTop - _padBottom;
    final slot = plotW / n;
    final bodyW = math.max(2.0, slot * 0.6);

    final highs = candles.map((c) => c.high);
    final lows = candles.map((c) => c.low);
    final yMax = highs.reduce(math.max);
    final yMin = lows.reduce(math.min);
    final rawPad = (yMax - yMin) * 0.12;
    final yPad = rawPad == 0 ? 1.0 : rawPad;
    final scaleTop = yMax + yPad;
    final scaleBottom = yMin - yPad;

    double xFor(int i) => _padLeft + slot * (i + 0.5);
    double yScale(double y) =>
        _padTop + (1 - (y - scaleBottom) / (scaleTop - scaleBottom)) * plotH;

    final gridPaint = Paint()
      ..color = isDark ? Colors.white12 : Colors.black12
      ..strokeWidth = 1;
    final labelStyle =
        TextStyle(fontSize: 9, color: isDark ? Colors.white54 : Colors.black45);

    for (int i = 0; i <= 4; i++) {
      final f = i / 4;
      final y = _padTop + f * plotH;
      canvas.drawLine(
          Offset(_padLeft, y), Offset(size.width - _padRight, y), gridPaint);
      final val = scaleTop - f * (scaleTop - scaleBottom);
      final tp = TextPainter(
          text: TextSpan(text: val.toStringAsFixed(0), style: labelStyle),
          textDirection: TextDirection.ltr)
        ..layout();
      tp.paint(canvas, Offset(2, y - 4));
    }

    for (int i = 0; i < n; i++) {
      final c = candles[i];
      final up = c.close >= c.open;
      final color = up ? Colors.green : Colors.red;
      final x = xFor(i);
      canvas.drawLine(
          Offset(x, yScale(c.high)),
          Offset(x, yScale(c.low)),
          Paint()
            ..color = color
            ..strokeWidth = 1);
      final bodyTop = math.min(yScale(c.open), yScale(c.close));
      final bodyH = math.max(1.0, (yScale(c.open) - yScale(c.close)).abs());
      canvas.drawRect(Rect.fromLTWH(x - bodyW / 2, bodyTop, bodyW, bodyH),
          Paint()..color = color);
    }

    // ── Entry markers ─────────────────────────────────────────────────
    // Only draw a leg's marker if its entry date matches the session day
    // currently shown. Otherwise the "nearest by time" snap would land it
    // on a completely unrelated candle.
    for (final leg in legs) {
      if (n == 0) continue;
      final sessionDay = candles.first.ts;
      final sameDay = leg.entryTs.year == sessionDay.year &&
          leg.entryTs.month == sessionDay.month &&
          leg.entryTs.day == sessionDay.day;
      if (!sameDay) continue;

      int idx = 0;
      double best = double.infinity;
      for (int i = 0; i < n; i++) {
        final d = candles[i]
            .ts
            .difference(leg.entryTs)
            .inMilliseconds
            .abs()
            .toDouble();
        if (d < best) {
          best = d;
          idx = i;
        }
      }
      final x = xFor(idx);
      final isBuy = leg.action == LegAction.BUY;
      final cy =
          isBuy ? yScale(candles[idx].low) + 9 : yScale(candles[idx].high) - 9;
      final path = Path();
      if (isBuy) {
        path.moveTo(x - 4, cy + 4);
        path.lineTo(x + 4, cy + 4);
        path.lineTo(x, cy - 4);
      } else {
        path.moveTo(x - 4, cy - 4);
        path.lineTo(x + 4, cy - 4);
        path.lineTo(x, cy + 4);
      }
      path.close();
      canvas.drawPath(path, Paint()..color = isBuy ? Colors.green : Colors.red);
    }

    // Committed asOf marker (nearest candle to `asOf`).
    int nearestIdx = 0;
    double best = double.infinity;
    for (int i = 0; i < n; i++) {
      final d = candles[i].ts.difference(asOf).inMilliseconds.abs().toDouble();
      if (d < best) {
        best = d;
        nearestIdx = i;
      }
    }

    // Crosshair follows the finger while dragging, otherwise the committed
    // asOf position.
    final hoverIdx = (previewIdx != null && previewIdx! >= 0 && previewIdx! < n)
        ? previewIdx!
        : nearestIdx;
    final hoverX = xFor(hoverIdx);
    final hoverColor = previewIdx != null ? Colors.amberAccent : Colors.amber;
    canvas.drawLine(
        Offset(hoverX, _padTop),
        Offset(hoverX, size.height - _padBottom),
        Paint()
          ..color = hoverColor
          ..strokeWidth = previewIdx != null ? 2.0 : 1.5);

    // ── Tooltip: time / OHLC / local approximate P&L ──────────────────
    final c = candles[hoverIdx];
    final buf = StringBuffer()
      ..write(_hm(c.ts))
      ..write('  O:${c.open.toStringAsFixed(0)}')
      ..write(' H:${c.high.toStringAsFixed(0)}')
      ..write(' L:${c.low.toStringAsFixed(0)}')
      ..write(' C:${c.close.toStringAsFixed(0)}');

    Color chipTextColor = isDark ? Colors.white : Colors.black;
    if (legs.isNotEmpty) {
      final previewPnl = payoffAtSpot(legs, lotSize, c.close);
      buf.write('   •   P&L @ this bar: ${signed(previewPnl)}');
      chipTextColor = previewPnl >= 0
          ? (isDark ? Colors.greenAccent : Colors.green[800]!)
          : (isDark ? Colors.redAccent : Colors.red[800]!);
    }

    final tp = TextPainter(
      text: TextSpan(
        text: buf.toString(),
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.bold, color: chipTextColor),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final chipW = math.min(tp.width + 12, size.width - _padLeft - 4);
    final chipRect = Rect.fromLTWH(_padLeft + 2, 2, chipW, 16);
    canvas.drawRRect(
      RRect.fromRectAndRadius(chipRect, const Radius.circular(4)),
      Paint()
        ..color = (isDark ? Colors.black87 : Colors.white).withOpacity(0.9),
    );
    tp.paint(canvas, Offset(chipRect.left + 6, chipRect.top + 2));

    // ── X-axis labels ─────────────────────────────────────────────────
    final firstLbl = TextPainter(
        text: TextSpan(text: _hm(candles.first.ts), style: labelStyle),
        textDirection: TextDirection.ltr)
      ..layout();
    firstLbl.paint(canvas, Offset(_padLeft, size.height - _padBottom + 4));
    final lastLbl = TextPainter(
        text: TextSpan(text: _hm(candles.last.ts), style: labelStyle),
        textDirection: TextDirection.ltr)
      ..layout();
    lastLbl.paint(
        canvas,
        Offset(size.width - _padRight - lastLbl.width,
            size.height - _padBottom + 4));
  }

  String _hm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  bool shouldRepaint(covariant CandleChartPainter oldDelegate) => true;
}

/* ════════════════════════════════════════════════════════════════════════
   Payoff chart (drag to move target price, slider for days-to-expiry)
   ════════════════════════════════════════════════════════════════════════ */

class PayoffChartWidget extends StatefulWidget {
  final List<Leg> legs;
  final int lotSize;
  final double? spot;
  final double daysLeft;

  const PayoffChartWidget(
      {super.key,
      required this.legs,
      required this.lotSize,
      required this.spot,
      required this.daysLeft});

  @override
  State<PayoffChartWidget> createState() => _PayoffChartWidgetState();
}

class _PayoffChartWidgetState extends State<PayoffChartWidget> {
  double? targetSpot;
  double daysOffset = 0;

  @override
  void initState() {
    super.initState();
    targetSpot = widget.spot;
  }

  @override
  void didUpdateWidget(covariant PayoffChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    targetSpot ??= widget.spot;
  }

  void _setTargetFromX(double dx, double width, double lo, double hi) {
    const padLeft = 14.0, padRight = 14.0;
    final plotW = width - padLeft - padRight;
    final frac = ((dx - padLeft).clamp(0.0, plotW)) / plotW;
    final raw = lo + frac * (hi - lo);
    setState(() => targetSpot = (raw * 20).roundToDouble() / 20);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.legs.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'No legs yet.\nTap Buy / Sell in the Option Chain tab to build a strategy.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final metrics = computeStrategyMetrics(widget.legs, widget.lotSize);
    final strikes = widget.legs.map((l) => l.strike).toList();
    final center = targetSpot ?? widget.spot ?? strikes.first;
    final spread = strikes.isNotEmpty
        ? (strikes.reduce(math.max) - strikes.reduce(math.min))
        : center * 0.1;
    final range = math.max(spread * 1.6, math.max(center * 0.12, 100.0));
    final lo = math.max(0.0, center - range);
    final hi = center + range;
    final t = math.max(0.0, widget.daysLeft - daysOffset) / 365;

    double sigmaFor(Leg leg) => (leg.currentIv ?? leg.entryIv ?? 15) / 100;
    double bookValueAt(double spotX) {
      double sum = 0;
      for (final leg in widget.legs) {
        final qty = leg.lots * widget.lotSize;
        final dir = leg.action == LegAction.BUY ? 1 : -1;
        final value = bsPrice(
            spotX, leg.strike, t, sigmaFor(leg), kRiskFreeRate, leg.optionType);
        sum += (value - leg.entryPrice) * qty * dir;
      }
      return sum;
    }

    const n = 120;
    final xs = <double>[];
    final ys = <double>[];
    for (int i = 0; i <= n; i++) {
      final x = lo + (hi - lo) * i / n;
      xs.add(x);
      ys.add(bookValueAt(x));
    }
    final targetPnl = bookValueAt(targetSpot ?? center);
    final sliderMax = math.max(0.1, widget.daysLeft);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Payoff at Expiry',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text('${signed(targetPnl)} at target',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: targetPnl >= 0 ? Colors.green : Colors.red)),
          ]),
          const SizedBox(height: 8),
          LayoutBuilder(builder: (context, constraints) {
            final width = constraints.maxWidth;
            const height = 220.0;
            return GestureDetector(
              onPanDown: (d) =>
                  _setTargetFromX(d.localPosition.dx, width, lo, hi),
              onPanUpdate: (d) =>
                  _setTargetFromX(d.localPosition.dx, width, lo, hi),
              child: CustomPaint(
                size: Size(width, height),
                painter: PayoffChartPainter(
                  xs: xs,
                  ys: ys,
                  spot: widget.spot,
                  targetSpot: targetSpot,
                  breakevens: metrics?.breakevens ?? [],
                  isDark: Theme.of(context).brightness == Brightness.dark,
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          Row(children: [
            const Text('Target price:  ', style: TextStyle(fontSize: 12)),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, size: 18),
              onPressed: () => setState(
                  () => targetSpot = (targetSpot ?? widget.spot ?? 0) - 5),
            ),
            Text(fmtNum(targetSpot),
                style: const TextStyle(fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 18),
              onPressed: () => setState(
                  () => targetSpot = (targetSpot ?? widget.spot ?? 0) + 5),
            ),
            TextButton(
                onPressed: () => setState(() => targetSpot = widget.spot),
                child: const Text('Reset', style: TextStyle(fontSize: 12))),
          ]),
          Text(
              'Days to expiry: ${math.max(0.0, widget.daysLeft - daysOffset).toStringAsFixed(1)}',
              style: const TextStyle(fontSize: 12)),
          Slider(
            value: daysOffset.clamp(0.0, sliderMax),
            min: 0,
            max: sliderMax,
            onChanged: (v) => setState(() => daysOffset = v),
          ),
          if (metrics != null) ...[
            const Divider(),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Max Profit'),
              Text(
                  metrics.maxProfitUnlimited
                      ? 'Unlimited'
                      : fmtNum(metrics.maxProfit),
                  style: const TextStyle(
                      color: Colors.green, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 4),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Max Loss'),
              Text(
                  metrics.maxLossUnlimited
                      ? 'Unlimited'
                      : fmtNum(metrics.maxLoss),
                  style: const TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold)),
            ]),
            if (metrics.breakevens.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                    'Breakeven: ${metrics.breakevens.map((b) => fmtNum(b, digits: 0)).join(", ")}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ),
          ],
        ],
      ),
    );
  }
}

class PayoffChartPainter extends CustomPainter {
  final List<double> xs, ys;
  final double? spot;
  final double? targetSpot;
  final List<double> breakevens;
  final bool isDark;

  PayoffChartPainter({
    required this.xs,
    required this.ys,
    required this.spot,
    required this.targetSpot,
    required this.breakevens,
    required this.isDark,
  });

  static const _padLeft = 14.0,
      _padRight = 14.0,
      _padTop = 10.0,
      _padBottom = 8.0;

  int _nearestIdx(double target) {
    int idx = 0;
    double best = double.infinity;
    for (int i = 0; i < xs.length; i++) {
      final d = (xs[i] - target).abs();
      if (d < best) {
        best = d;
        idx = i;
      }
    }
    return idx;
  }

  void _dashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dashLen = 4.0, gapLen = 3.0;
    final total = (b - a).distance;
    if (total == 0) return;
    final dir = (b - a) / total;
    double dist = 0;
    while (dist < total) {
      final start = a + dir * dist;
      final end = a + dir * math.min(dist + dashLen, total);
      canvas.drawLine(start, end, paint);
      dist += dashLen + gapLen;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (xs.isEmpty) return;
    final plotW = size.width - _padLeft - _padRight;
    final plotH = size.height - _padTop - _padBottom;
    final lo = xs.first, hi = xs.last;
    final yMin = math.min(0.0, ys.reduce(math.min));
    final yMax = math.max(0.0, ys.reduce(math.max));
    final rawPad = (yMax - yMin) * 0.15;
    final yPad = rawPad == 0 ? 1.0 : rawPad;
    final scaleBottom = yMin - yPad;
    final scaleTop = yMax + yPad;

    double xScale(double x) => _padLeft + (x - lo) / (hi - lo) * plotW;
    double yScale(double y) =>
        _padTop + (1 - (y - scaleBottom) / (scaleTop - scaleBottom)) * plotH;

    final zeroY = yScale(0);
    canvas.drawLine(
        Offset(_padLeft, zeroY),
        Offset(size.width - _padRight, zeroY),
        Paint()
          ..color = (isDark ? Colors.white30 : Colors.black26)
          ..strokeWidth = 1);

    if (spot != null) {
      final sx = xScale(spot!);
      _dashedLine(
          canvas,
          Offset(sx, _padTop),
          Offset(sx, size.height - _padBottom),
          Paint()
            ..color = (isDark ? Colors.white38 : Colors.black38)
            ..strokeWidth = 1);
    }

    final linePath = Path();
    final gainPath = Path()..moveTo(xScale(xs.first), zeroY);
    final lossPath = Path()..moveTo(xScale(xs.first), zeroY);
    for (int i = 0; i < xs.length; i++) {
      final px = xScale(xs[i]), py = yScale(ys[i]);
      if (i == 0) {
        linePath.moveTo(px, py);
      } else {
        linePath.lineTo(px, py);
      }
      gainPath.lineTo(px, py);
      lossPath.lineTo(px, py);
    }
    gainPath.lineTo(xScale(xs.last), zeroY);
    gainPath.close();
    lossPath.lineTo(xScale(xs.last), zeroY);
    lossPath.close();

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, zeroY));
    canvas.drawPath(gainPath, Paint()..color = Colors.green.withOpacity(0.15));
    canvas.restore();

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, zeroY, size.width, size.height - zeroY));
    canvas.drawPath(lossPath, Paint()..color = Colors.red.withOpacity(0.15));
    canvas.restore();

    canvas.drawPath(
        linePath,
        Paint()
          ..color = Colors.amber
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke);

    for (final be in breakevens) {
      canvas.drawCircle(Offset(xScale(be), zeroY), 3,
          Paint()..color = isDark ? Colors.white : Colors.black);
    }

    if (targetSpot != null) {
      final tx = xScale(targetSpot!);
      final ty = yScale(ys[_nearestIdx(targetSpot!)]);
      _dashedLine(
          canvas,
          Offset(tx, _padTop),
          Offset(tx, size.height - _padBottom),
          Paint()
            ..color = Colors.amber
            ..strokeWidth = 1);
      canvas.drawCircle(Offset(tx, ty), 5.5, Paint()..color = Colors.amber);
      canvas.drawCircle(
          Offset(tx, ty),
          5.5,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }
  }

  @override
  bool shouldRepaint(covariant PayoffChartPainter oldDelegate) => true;
}

/* ════════════════════════════════════════════════════════════════════════
   Option chain row (CE | Strike | PE, with Buy/Sell pills)
   ════════════════════════════════════════════════════════════════════════ */

class ChainRowTile extends StatelessWidget {
  final ChainStrikeRow row;
  final bool isAtm;
  final bool showGreeks;
  final double? spot;
  final double yearsToExpiry;
  final void Function(double strike, OptionType type, LegAction action) onTrade;

  const ChainRowTile({
    super.key,
    required this.row,
    required this.isAtm,
    required this.showGreeks,
    required this.spot,
    required this.yearsToExpiry,
    required this.onTrade,
  });

  Greeks? _greeksFor(OptionChainRow? r, OptionType type) {
    if (r == null || r.iv == null || spot == null) return null;
    return bsGreeks(spot!, r.strikePrice ?? 0, yearsToExpiry, r.iv! / 100,
        kRiskFreeRate, type);
  }

  @override
  Widget build(BuildContext context) {
    final ceG = _greeksFor(row.ce, OptionType.CE);
    final peG = _greeksFor(row.pe, OptionType.PE);
    return Container(
      color: isAtm ? Colors.amber.withOpacity(0.10) : null,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Row(children: [
        Expanded(child: _sideCell(row.ce, OptionType.CE, ceG, isCe: true)),
        SizedBox(
          width: 56,
          child: Text(
            row.strike.toStringAsFixed(0),
            textAlign: TextAlign.center,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isAtm ? Colors.amber[800] : null),
          ),
        ),
        Expanded(child: _sideCell(row.pe, OptionType.PE, peG, isCe: false)),
      ]),
    );
  }

  Widget _sideCell(OptionChainRow? r, OptionType type, Greeks? g,
      {required bool isCe}) {
    final disabled = r?.ltp == null;
    final color = isCe ? Colors.blue : Colors.teal;
    final priceCol = Column(
      crossAxisAlignment:
          isCe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(fmtNum(r?.ltp),
            style: TextStyle(
                fontWeight: FontWeight.bold, color: color, fontSize: 13)),
        if (showGreeks && g != null)
          Text('Δ${fmtNum(g.delta, digits: 2)} Θ${fmtNum(g.theta, digits: 1)}',
              style: const TextStyle(fontSize: 9, color: Colors.grey)),
        Text('OI ${fmtInt(r?.oi)}',
            style: const TextStyle(fontSize: 9, color: Colors.grey)),
      ],
    );
    final buttons = Row(mainAxisSize: MainAxisSize.min, children: [
      _pillButton('B', Colors.green, disabled,
          () => onTrade(row.strike, type, LegAction.BUY)),
      const SizedBox(width: 2),
      _pillButton('S', Colors.red, disabled,
          () => onTrade(row.strike, type, LegAction.SELL)),
    ]);
    return Row(
      mainAxisAlignment: isCe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: isCe
          ? [priceCol, const SizedBox(width: 6), buttons]
          : [buttons, const SizedBox(width: 6), priceCol],
    );
  }

  Widget _pillButton(
      String label, Color color, bool disabled, VoidCallback onTap) {
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: disabled
              ? Colors.grey.withOpacity(0.10)
              : color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: disabled ? Colors.grey : color)),
      ),
    );
  }
}

/* ════════════════════════════════════════════════════════════════════════
   P&L summary card
   ════════════════════════════════════════════════════════════════════════ */

class PnLSummaryCard extends StatelessWidget {
  final List<Leg> legs;
  final int lotSize;

  const PnLSummaryCard({super.key, required this.legs, required this.lotSize});

  @override
  Widget build(BuildContext context) {
    double totalPnl = 0, netCash = 0;
    int pricedCount = 0;
    for (final leg in legs) {
      final qty = leg.lots * lotSize;
      final dir = leg.action == LegAction.BUY ? 1 : -1;
      if (leg.currentPrice != null) {
        totalPnl += (leg.currentPrice! - leg.entryPrice) * qty * dir;
        pricedCount++;
      }
      netCash += leg.entryPrice * qty * (leg.action == LegAction.BUY ? -1 : 1);
    }
    final allPriced = legs.isNotEmpty && pricedCount == legs.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Total Profit / Loss',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text('${legs.length} leg${legs.length == 1 ? '' : 's'}',
                style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ]),
          const SizedBox(height: 4),
          Text(
            legs.isEmpty
                ? '—'
                : (allPriced ? signed(totalPnl) : '${signed(totalPnl)}*'),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: legs.isEmpty
                  ? Colors.grey
                  : (totalPnl >= 0 ? Colors.green : Colors.red),
            ),
          ),
          if (legs.isNotEmpty && !allPriced)
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Text('*some legs are unpriced at this snapshot',
                  style: TextStyle(fontSize: 10, color: Colors.grey)),
            ),
          const Divider(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Net Premium',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text(
              legs.isEmpty
                  ? '—'
                  : '${netCash >= 0 ? 'Received ' : 'Paid '}${fmtNum(netCash.abs())}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ]),
        ]),
      ),
    );
  }
}

/* ════════════════════════════════════════════════════════════════════════
   Positions bottom sheet (full leg blotter)
   ════════════════════════════════════════════════════════════════════════ */

class PositionsSheetContent extends StatelessWidget {
  final List<Leg> legs;
  final int lotSize;
  final double? spot;
  final DateTime asOf;
  final bool showGreeks;
  final void Function(String legId) onRemove;
  final void Function(String legId, int lots) onLotsChange;
  final VoidCallback onClearAll;

  const PositionsSheetContent({
    super.key,
    required this.legs,
    required this.lotSize,
    required this.spot,
    required this.asOf,
    required this.showGreeks,
    required this.onRemove,
    required this.onLotsChange,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Your Positions (${legs.length})',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  if (legs.isNotEmpty)
                    TextButton(
                        onPressed: onClearAll,
                        child: const Text('Clear all',
                            style: TextStyle(color: Colors.red, fontSize: 12))),
                ]),
          ),
          const Divider(),
          Expanded(
            child: legs.isEmpty
                ? const Center(
                    child: Text(
                        'No legs yet.\nTap B / S in the Option Chain tab to add one.',
                        textAlign: TextAlign.center))
                : ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: legs.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, i) => _legTile(legs[i]),
                  ),
          ),
        ]);
      },
    );
  }

  Widget _legTile(Leg leg) {
    final qty = leg.lots * lotSize;
    final dir = leg.action == LegAction.BUY ? 1 : -1;
    final pnl = leg.currentPrice != null
        ? (leg.currentPrice! - leg.entryPrice) * qty * dir
        : null;
    Greeks? g;
    if (spot != null && leg.entryExpiry != null) {
      final t = daysToExpiry(leg.entryExpiry!, asOf) / 365;
      final sigma = (leg.currentIv ?? leg.entryIv ?? 0) / 100;
      if (sigma > 0)
        g = bsGreeks(
            spot!, leg.strike, t, sigma, kRiskFreeRate, leg.optionType);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (leg.action == LegAction.BUY ? Colors.green : Colors.red)
                    .withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(leg.action == LegAction.BUY ? 'BUY' : 'SELL',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: leg.action == LegAction.BUY
                          ? Colors.green
                          : Colors.red)),
            ),
            const SizedBox(width: 6),
            Text(leg.strike.toStringAsFixed(0),
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 4),
            Text(leg.optionType.name,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: leg.optionType == OptionType.CE
                        ? Colors.blue
                        : Colors.teal)),
            if (leg.stale)
              const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Text('stale',
                      style: TextStyle(fontSize: 10, color: Colors.grey))),
          ]),
          IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => onRemove(leg.legId)),
        ]),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            const Text('Lots ', style: TextStyle(fontSize: 12)),
            IconButton(
                icon: const Icon(Icons.remove, size: 14),
                onPressed: () =>
                    onLotsChange(leg.legId, math.max(1, leg.lots - 1))),
            Text('${leg.lots}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            IconButton(
                icon: const Icon(Icons.add, size: 14),
                onPressed: () => onLotsChange(leg.legId, leg.lots + 1)),
          ]),
          Text(
              '${fmtNum(leg.entryPrice)} → ${leg.currentPrice != null ? fmtNum(leg.currentPrice) : '—'}',
              style: const TextStyle(fontSize: 12)),
          Text(pnl != null ? signed(pnl) : '—',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: pnl == null
                      ? Colors.grey
                      : (pnl >= 0 ? Colors.green : Colors.red))),
        ]),
        if (showGreeks && g != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
                'Δ ${fmtNum(g.delta, digits: 3)}  Γ ${fmtNum(g.gamma, digits: 4)}  Θ ${fmtNum(g.theta, digits: 2)}  V ${fmtNum(g.vega, digits: 2)}',
                style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ),
      ]),
    );
  }
}

/* ════════════════════════════════════════════════════════════════════════
   Page
   ════════════════════════════════════════════════════════════════════════ */

class StrategyBuilderPage extends StatefulWidget {
  final String? initialIndex;

  const StrategyBuilderPage({super.key, this.initialIndex});

  @override
  State<StrategyBuilderPage> createState() => _StrategyBuilderPageState();
}

class _StrategyBuilderPageState extends State<StrategyBuilderPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String indexName = kIndexOptions[0];
  List<String> expiries = [];
  String expiryDate = '';
  bool showGreeks = true;

  DateTime asOf = initialMarketAsOf();
  ChainSnapshot chain = ChainSnapshot.empty();
  List<Leg> legs = [];
  bool loadingChain = false;
  bool hasLoadedOnce = false;
  bool loadingExpiries = false;
  String? error;

  List<Candle> candles = [];
  bool loadingCandles = false;

  int get lotSize => kLotSize[indexName] ?? 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    indexName = widget.initialIndex ?? kIndexOptions[0];
    _loadExpiries();
    _loadCandles();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadExpiries() async {
    setState(() {
      loadingExpiries = true;
      legs = [];
      hasLoadedOnce = false;
    });
    try {
      final list = await fetchExpiries(indexName);
      final currentDateStr = dateStrOf(asOf);
      setState(() {
        expiries = list;
        final validUpcoming = list.firstWhere(
            (d) => d.compareTo(currentDateStr) >= 0,
            orElse: () => '');
        expiryDate = validUpcoming.isNotEmpty
            ? validUpcoming
            : (list.isNotEmpty ? list.last : '');
      });
      if (expiryDate.isNotEmpty) await _loadChain();
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loadingExpiries = false);
    }
  }

  Future<void> _loadChain() async {
    if (expiryDate.isEmpty) return;
    setState(() {
      loadingChain = true;
      error = null;
    });
    try {
      final nearestTs = await findNearestSnapshotTs(indexName, asOf);
      if (nearestTs == null) {
        if (mounted) setState(() => chain = ChainSnapshot.empty());
        return;
      }
      final snapshot = await fetchChainAtTs(indexName, expiryDate, nearestTs);
      if (mounted) setState(() => chain = snapshot);

      final repriceTs = snapshot.ts ?? nearestTs;
      if (legs.isNotEmpty) {
        for (final leg in legs) {
          try {
            final r = await fetchLegPrice(indexName, leg.entryExpiry,
                leg.strike, leg.optionType, repriceTs);
            leg.currentPrice = r['price'] as double?;
            leg.currentIv = r['iv'] as double?;
            leg.currentTs = parseIst(r['ts'] as String?);
            leg.stale = leg.currentPrice == null;
          } catch (_) {
            leg.stale = true;
          }
        }
        if (mounted) setState(() {});
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) {
        setState(() {
          loadingChain = false;
          hasLoadedOnce = true;
        });
      }
    }
  }

  Future<void> _loadCandles() async {
    setState(() => loadingCandles = true);
    try {
      final list = await fetchCandles(indexName, dateStrOf(asOf));
      if (mounted) setState(() => candles = list);
    } catch (_) {
      if (mounted) setState(() => candles = []);
    } finally {
      if (mounted) setState(() => loadingCandles = false);
    }
  }

  void _onIndexChange(String v) {
    if (v == indexName) return;
    setState(() => indexName = v);
    _loadExpiries();
    _loadCandles();
  }

  void _applyAsOf(DateTime next) {
    final newDateStr = dateStrOf(next);
    final dateChanged = newDateStr != dateStrOf(asOf);
    final adjusted = dateChanged
        ? DateTime.utc(
            next.year, next.month, next.day, kMarketOpenH, kMarketOpenM)
        : next;
    final clamped = clampToMarketHours(adjusted);

    setState(() {
      asOf = clamped;
      if (dateChanged &&
          expiries.isNotEmpty &&
          expiryDate.compareTo(newDateStr) < 0) {
        final nextValid = expiries
            .firstWhere((d) => d.compareTo(newDateStr) >= 0, orElse: () => '');
        if (nextValid.isNotEmpty) expiryDate = nextValid;
      }
    });

    _loadChain();
    if (dateChanged) _loadCandles();
  }

  void _handleTrade(double strike, OptionType type, LegAction action) {
    final idx = legs.indexWhere((l) =>
        l.strike == strike && l.optionType == type && l.action == action);
    if (idx >= 0) {
      setState(() => legs[idx].lots += 1);
      return;
    }
    ChainStrikeRow? row;
    for (final r in chain.rows) {
      if (r.strike == strike) {
        row = r;
        break;
      }
    }
    final sourceRow = type == OptionType.CE ? row?.ce : row?.pe;
    final entryPrice = sourceRow?.ltp ?? sourceRow?.closePrice;
    if (entryPrice == null) return;
    final newLeg = Leg(
      legId:
          '${DateTime.now().microsecondsSinceEpoch}-${math.Random().nextInt(99999)}',
      strike: strike,
      optionType: type,
      action: action,
      lots: 1,
      entryPrice: entryPrice,
      entryIv: sourceRow?.iv,
      entryTs: chain.ts != null ? (parseIst(chain.ts) ?? asOf) : asOf,
      entryExpiry: expiryDate.isNotEmpty ? expiryDate : null,
      currentPrice: entryPrice,
      currentIv: sourceRow?.iv,
      currentTs: chain.ts != null ? parseIst(chain.ts) : null,
    );
    setState(() => legs = [...legs, newLeg]);
  }

  void _removeLeg(String legId) =>
      setState(() => legs.removeWhere((l) => l.legId == legId));

  void _updateLegLots(String legId, int lots) {
    setState(() {
      final leg = legs.firstWhere((l) => l.legId == legId);
      leg.lots = lots;
    });
  }

  void _openPositionsSheet(double? estSpot) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModalState) {
          return PositionsSheetContent(
            legs: legs,
            lotSize: lotSize,
            spot: estSpot,
            asOf: asOf,
            showGreeks: showGreeks,
            onRemove: (id) {
              _removeLeg(id);
              setModalState(() {});
            },
            onLotsChange: (id, lots) {
              _updateLegLots(id, lots);
              setModalState(() {});
            },
            onClearAll: () {
              setState(() => legs = []);
              Navigator.pop(ctx);
            },
          );
        });
      },
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      color: Colors.red.withOpacity(0.08),
      padding: const EdgeInsets.all(8),
      child: Text(error ?? '',
          style: const TextStyle(fontSize: 11, color: Colors.red)),
    );
  }

  Widget _buildControlsRow(double? estSpot, double remainingDays) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          ToggleButtons(
            isSelected: kIndexOptions.map((i) => i == indexName).toList(),
            onPressed: (i) => _onIndexChange(kIndexOptions[i]),
            borderRadius: BorderRadius.circular(8),
            constraints: const BoxConstraints(minHeight: 32, minWidth: 40),
            children: kIndexOptions
                .map((i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(i)))
                .toList(),
          ),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: expiryDate.isEmpty ? null : expiryDate,
            hint: const Text('Expiry'),
            underline: const SizedBox.shrink(),
            items: expiries
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: loadingExpiries
                ? null
                : (v) {
                    if (v != null) {
                      setState(() => expiryDate = v);
                      _loadChain();
                    }
                  },
          ),
          const SizedBox(width: 8),
          Chip(label: Text('Lot $lotSize')),
          const SizedBox(width: 8),
          Chip(label: Text('Spot ${fmtNum(estSpot)}')),
          const SizedBox(width: 8),
          Chip(
              label: Text('ATM ${chain.atmStrike?.toStringAsFixed(0) ?? '—'}'),
              backgroundColor: Colors.amber.withOpacity(0.15)),
          const SizedBox(width: 8),
          Chip(label: Text('${remainingDays.toStringAsFixed(1)}d to expiry')),
        ]),
      ),
    );
  }

  Widget _timeControls() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(children: [
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today, size: 14),
              label: Text(dateStrOf(asOf)),
              onPressed: () async {
                final picked = await showDatePicker(
                    context: context,
                    initialDate: asOf,
                    firstDate: DateTime(2015),
                    lastDate: DateTime.now());
                if (picked != null) {
                  _applyAsOf(
                      DateTime.utc(picked.year, picked.month, picked.day));
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.access_time, size: 14),
              label: Text(timeStrOf(asOf)),
              onPressed: () async {
                final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(asOf));
                if (picked != null) {
                  _applyAsOf(DateTime.utc(asOf.year, asOf.month, asOf.day,
                      picked.hour, picked.minute));
                }
              },
            ),
          ),
        ]),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          IconButton(
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Previous day',
              onPressed: () =>
                  _applyAsOf(asOf.subtract(const Duration(days: 1)))),
          ...[-15, -5, 5, 15].map((m) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: OutlinedButton(
                  onPressed: () => _applyAsOf(asOf.add(Duration(minutes: m))),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: m < 0 ? Colors.red : Colors.green,
                    minimumSize: const Size(0, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text(m > 0 ? '+${m}m' : '${m}m',
                      style: const TextStyle(fontSize: 11)),
                ),
              )),
          IconButton(
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Next day',
              onPressed: () => _applyAsOf(asOf.add(const Duration(days: 1)))),
        ]),
        Text(
          loadingChain
              ? 'Loading snapshot…'
              : (chain.ts != null
                  ? 'Snapshot: ${chain.ts}'
                  : 'No snapshot at this time'),
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
        const Text('Market hours only: 9:15 AM – 3:30 PM',
            style: TextStyle(fontSize: 9, color: Colors.grey)),
      ]),
    );
  }

  Widget _buildChainTab(double? estSpot, double remainingDays) {
    final atm = chain.atmStrike;
    final visible = atm != null
        ? chain.rows
            .where((r) =>
                (r.strike - atm).abs() <=
                kStrikeSpan * stepGuess(chain.rows, atm))
            .toList()
        : chain.rows;
    return Column(children: [
      _timeControls(),
      Container(
        color: Colors.grey.withOpacity(0.08),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        child: const Row(children: [
          Expanded(
              child: Text('CALLS',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue))),
          SizedBox(
              width: 56,
              child: Text('STRIKE',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
          Expanded(
              child: Text('PUTS',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal))),
        ]),
      ),
      Expanded(
        child: (loadingChain && !hasLoadedOnce)
            ? const Center(child: CircularProgressIndicator())
            : visible.isEmpty
                ? const Center(
                    child: Text(
                        'No chain data for this index / expiry / time yet.'))
                : ListView.separated(
                    itemCount: visible.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final row = visible[i];
                      return ChainRowTile(
                        row: row,
                        isAtm: atm != null && row.strike == atm,
                        showGreeks: showGreeks,
                        spot: estSpot,
                        yearsToExpiry: remainingDays / 365,
                        onTrade: _handleTrade,
                      );
                    },
                  ),
      ),
    ]);
  }

  Widget _buildChartTab() {
    return SingleChildScrollView(
      child: CandleChartWidget(
        symbol: indexName,
        candles: candles,
        legs: legs,
        asOf: asOf,
        onSelectTime: _applyAsOf,
        loading: loadingCandles,
      ),
    );
  }

  Widget _buildPnlTab(double? estSpot, double remainingDays) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(children: [
        PnLSummaryCard(legs: legs, lotSize: lotSize),
        const SizedBox(height: 12),
        Card(
            child: PayoffChartWidget(
                legs: legs,
                lotSize: lotSize,
                spot: estSpot,
                daysLeft: remainingDays)),
      ]),
    );
  }

  Widget _buildPositionsBar(double? estSpot) {
    double totalPnl = 0;
    int pricedCount = 0;
    for (final leg in legs) {
      final qty = leg.lots * lotSize;
      final dir = leg.action == LegAction.BUY ? 1 : -1;
      if (leg.currentPrice != null) {
        totalPnl += (leg.currentPrice! - leg.entryPrice) * qty * dir;
        pricedCount++;
      }
    }
    final allPriced = legs.isNotEmpty && pricedCount == legs.length;

    return SafeArea(
      child: InkWell(
        onTap: () => _openPositionsSheet(estSpot),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border:
                Border(top: BorderSide(color: Colors.grey.withOpacity(0.2))),
          ),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              const Text('Positions',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 6),
              CircleAvatar(
                  radius: 10,
                  backgroundColor: Colors.grey.withOpacity(0.2),
                  child: Text('${legs.length}',
                      style: const TextStyle(fontSize: 11))),
            ]),
            Row(children: [
              Text(
                legs.isEmpty
                    ? '—'
                    : (allPriced ? signed(totalPnl) : '${signed(totalPnl)}*'),
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: legs.isEmpty
                        ? Colors.grey
                        : (totalPnl >= 0 ? Colors.green : Colors.red)),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_up),
            ]),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chainSpot = estimateSpotFromChain(chain);
    final estSpot = spotFromCandles(candles, asOf) ?? chainSpot;
    final remainingDays =
        expiryDate.isNotEmpty ? daysToExpiry(expiryDate, asOf) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Strategy Builder'),
        // actions: [
        //   Row(children: [
        //     const Text('Greeks', style: TextStyle(fontSize: 12)),
        //     Switch(
        //         value: showGreeks,
        //         onChanged: (v) => setState(() => showGreeks = v)),
        //     const SizedBox(width: 8),
        //   ]),
        // ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Option Chain', icon: Icon(Icons.list_alt)),
            Tab(text: 'Price Chart', icon: Icon(Icons.candlestick_chart)),
            Tab(text: 'Profit/Loss', icon: Icon(Icons.trending_up)),
          ],
        ),
      ),
      body: Column(children: [
        // _buildInfoBanner(),
        _buildControlsRow(estSpot, remainingDays),
        if (error != null) _buildErrorBanner(),
        Expanded(
          child: TabBarView(controller: _tabController, children: [
            _buildChainTab(estSpot, remainingDays),
            _buildChartTab(),
            _buildPnlTab(estSpot, remainingDays),
          ]),
        ),
      ]),
      bottomNavigationBar: _buildPositionsBar(estSpot),
    );
  }
}
