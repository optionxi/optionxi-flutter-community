import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:optionxi/Helpers/analytics_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────
// Theme Tokens
// ─────────────────────────────────────────────────────────────
abstract class _Tok {
  Color get bg;
  Color get surface;
  Color get surface2;
  Color get border;
  Color get text;
  Color get textSub;
  Color get textMuted;
  Color get green;
  Color get red;
  Color get amber;
  Color get blue;
  Color get purple;
  Color get shimmerBase;
  Color get shimmerHigh;
  Color get longBg;
  Color get shortBg;
  Color get longUnwindBg;
  Color get shortCoverBg;
}

class _Dark extends _Tok {
  _Dark();
  @override
  Color get bg => const Color(0xFF0E0F14);
  @override
  Color get surface => const Color(0xFF161820);
  @override
  Color get surface2 => const Color(0xFF1E2029);
  @override
  Color get border => const Color(0xFF2A2D3A);
  @override
  Color get text => const Color(0xFFF0F1F5);
  @override
  Color get textSub => const Color(0xFFAAADB8);
  @override
  Color get textMuted => const Color(0xFF5C6070);
  @override
  Color get green => const Color(0xFF26A65B);
  @override
  Color get red => const Color(0xFFE05252);
  @override
  Color get amber => const Color(0xFFE8A830);
  @override
  Color get blue => const Color(0xFF3B82F6);
  @override
  Color get purple => const Color(0xFFA855F7);
  @override
  Color get shimmerBase => const Color(0xFF1C1E28);
  @override
  Color get shimmerHigh => const Color(0xFF2A2D3A);
  @override
  Color get longBg => const Color(0xFF0D2318);
  @override
  Color get shortBg => const Color(0xFF2A1010);
  @override
  Color get longUnwindBg => const Color(0xFF1A1A0D);
  @override
  Color get shortCoverBg => const Color(0xFF0D1A2A);
}

class _Light extends _Tok {
  _Light();
  @override
  Color get bg => const Color(0xFFF4F5F8);
  @override
  Color get surface => const Color(0xFFFFFFFF);
  @override
  Color get surface2 => const Color(0xFFF0F1F6);
  @override
  Color get border => const Color(0xFFE2E4EE);
  @override
  Color get text => const Color(0xFF0F1117);
  @override
  Color get textSub => const Color(0xFF4B5168);
  @override
  Color get textMuted => const Color(0xFF9CA3B8);
  @override
  Color get green => const Color(0xFF16A34A);
  @override
  Color get red => const Color(0xFFDC2626);
  @override
  Color get amber => const Color(0xFFCA8A04);
  @override
  Color get blue => const Color(0xFF2563EB);
  @override
  Color get purple => const Color(0xFF9333EA);
  @override
  Color get shimmerBase => const Color(0xFFE8EAF0);
  @override
  Color get shimmerHigh => const Color(0xFFF4F5F8);
  @override
  Color get longBg => const Color(0xFFECFDF5);
  @override
  Color get shortBg => const Color(0xFFFEF2F2);
  @override
  Color get longUnwindBg => const Color(0xFFFFFBEB);
  @override
  Color get shortCoverBg => const Color(0xFFEFF6FF);
}

_Tok _tok(bool isDark) => isDark ? _Dark() : _Light();

// ─────────────────────────────────────────────────────────────
// Signal Enum
// ─────────────────────────────────────────────────────────────
enum OiSignal {
  activeCalls,
  activePuts,
  longBuildup,
  shortBuildup,
  longUnwinding,
  shortCovering,
  maxPain
}

extension OiSignalX on OiSignal {
  String get label => const {
        OiSignal.activeCalls: 'Active Calls',
        OiSignal.activePuts: 'Active Puts',
        OiSignal.longBuildup: 'Long Buildup',
        OiSignal.shortBuildup: 'Short Buildup',
        OiSignal.longUnwinding: 'Long Unwinding',
        OiSignal.shortCovering: 'Short Covering',
        OiSignal.maxPain: 'Max Pain',
      }[this]!;

  String get shortLabel => const {
        OiSignal.activeCalls: 'Calls',
        OiSignal.activePuts: 'Puts',
        OiSignal.longBuildup: 'Long BU',
        OiSignal.shortBuildup: 'Short BU',
        OiSignal.longUnwinding: 'Long UW',
        OiSignal.shortCovering: 'Short Cov',
        OiSignal.maxPain: 'Max Pain',
      }[this]!;

  String get description => const {
        OiSignal.activeCalls: 'CE options with highest OI + volume activity',
        OiSignal.activePuts: 'PE options with highest OI + volume activity',
        OiSignal.longBuildup: 'Price ↑ + OI ↑ → Fresh longs being added',
        OiSignal.shortBuildup: 'Price ↓ + OI ↑ → Fresh shorts being added',
        OiSignal.longUnwinding: 'Price ↓ + OI ↓ → Longs exiting positions',
        OiSignal.shortCovering: 'Price ↑ + OI ↓ → Shorts covering positions',
        OiSignal.maxPain: 'Strike where maximum option writers profit',
      }[this]!;

  IconData get icon => const {
        OiSignal.activeCalls: Icons.trending_up_rounded,
        OiSignal.activePuts: Icons.trending_down_rounded,
        OiSignal.longBuildup: Icons.rocket_launch_rounded,
        OiSignal.shortBuildup: Icons.arrow_downward_rounded,
        OiSignal.longUnwinding: Icons.exit_to_app_rounded,
        OiSignal.shortCovering: Icons.shield_rounded,
        OiSignal.maxPain: Icons.gps_fixed_rounded,
      }[this]!;
}

// ─────────────────────────────────────────────────────────────
// Instrument Filter
// ─────────────────────────────────────────────────────────────
enum InstrumentFilter { all, nifty, banknifty, finnifty, stocks }

extension InstrumentFilterX on InstrumentFilter {
  String get label => const {
        InstrumentFilter.all: 'All',
        InstrumentFilter.nifty: 'NIFTY',
        InstrumentFilter.banknifty: 'BANKNIFTY',
        InstrumentFilter.finnifty: 'FINNIFTY',
        InstrumentFilter.stocks: 'FNO Stocks',
      }[this]!;

  /// Symbols to pass to Supabase `.inFilter()`. null = no symbol filter (all / stocks use special handling).
  List<String>? get serverSymbols {
    switch (this) {
      case InstrumentFilter.nifty:
        return ['NIFTY'];
      case InstrumentFilter.banknifty:
        return ['BANKNIFTY'];
      case InstrumentFilter.finnifty:
        return ['FINNIFTY'];
      default:
        return null;
    }
  }

  /// For client-side display label on summary strip etc.
  bool matches(String symbol) {
    switch (this) {
      case InstrumentFilter.all:
        return true;
      case InstrumentFilter.nifty:
        return symbol == 'NIFTY';
      case InstrumentFilter.banknifty:
        return symbol == 'BANKNIFTY';
      case InstrumentFilter.finnifty:
        return symbol == 'FINNIFTY';
      case InstrumentFilter.stocks:
        return symbol != 'NIFTY' &&
            symbol != 'BANKNIFTY' &&
            symbol != 'FINNIFTY';
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Sort & Limit
// ─────────────────────────────────────────────────────────────
enum ActivitySort { oiChange, oi, volume, iv, ltp }

enum RowLimit { n20, n30, n50, all }
// enum RowLimit { n20, n30, n50 }

extension ActivitySortX on ActivitySort {
  String get label =>
      const ['OI Change', 'Open Interest', 'Volume', 'IV', 'LTP'][index];
}

extension RowLimitX on RowLimit {
  String get label => const ['Top 20', 'Top 30', 'Top 50', 'All'][index];
  // String get label => const ['Top 20', 'Top 30', 'Top 50'][index];
  int? get count => const [20, 30, 50, null][index];
}

// ─────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────
class OiRow {
  final String symbol, optionType, strikeLevel;
  final DateTime expiryDate;
  final double strikePrice;
  final double? spotPrice,
      ltp,
      closePrice,
      oi,
      prevOi,
      oiChange,
      iv,
      delta,
      theta,
      vega,
      pop,
      totalMargin,
      bidPrice,
      askPrice;
  final int? volume, lotSize;
  final bool isAtm, isItm, isOtm;
  final int strikesFromAtm;

  const OiRow({
    required this.symbol,
    required this.optionType,
    required this.expiryDate,
    required this.strikePrice,
    this.spotPrice,
    required this.strikeLevel,
    required this.isAtm,
    required this.isItm,
    required this.isOtm,
    this.ltp,
    this.closePrice,
    this.volume,
    this.oi,
    this.prevOi,
    this.oiChange,
    this.iv,
    this.delta,
    this.theta,
    this.vega,
    this.pop,
    this.lotSize,
    this.totalMargin,
    this.bidPrice,
    this.askPrice,
    required this.strikesFromAtm,
  });

  factory OiRow.fromMap(Map<String, dynamic> m) {
    double? _d(dynamic v) => v == null ? null : (v as num).toDouble();
    int? _i(dynamic v) => v == null ? null : (v as num).toInt();
    return OiRow(
      symbol: m['underlying_symbol'] as String,
      optionType: (m['option_type'] as String).trim(),
      expiryDate: DateTime.parse(m['expiry_date'] as String),
      strikePrice: (m['strike_price'] as num).toDouble(),
      spotPrice: _d(m['spot_price']),
      strikeLevel: (m['strike_level'] as String).trim(),
      isAtm: m['is_atm'] as bool? ?? false,
      isItm: m['is_itm'] as bool? ?? false,
      isOtm: m['is_otm'] as bool? ?? false,
      ltp: _d(m['ltp']),
      closePrice: _d(m['close_price']),
      volume: _i(m['volume']),
      oi: _d(m['oi']),
      prevOi: _d(m['prev_oi']),
      oiChange: _d(m['oi_change']),
      iv: _d(m['iv']),
      delta: _d(m['delta']),
      theta: _d(m['theta']),
      vega: _d(m['vega']),
      pop: _d(m['pop']),
      lotSize: _i(m['lot_size']),
      totalMargin: _d(m['total_margin']),
      bidPrice: _d(m['bid_price']),
      askPrice: _d(m['ask_price']),
      strikesFromAtm: (m['strikes_from_atm'] as num).toInt(),
    );
  }

  bool get isCE => optionType == 'CE';
  bool get isPE => optionType == 'PE';

  double get pctChange =>
      (ltp != null && closePrice != null && closePrice! != 0)
          ? ((ltp! - closePrice!) / closePrice!) * 100
          : 0;
  double get oiChangePct => (prevOi != null && prevOi! != 0 && oiChange != null)
      ? (oiChange! / prevOi!) * 100
      : 0;

  OiSignal? get signal {
    final priceUp = pctChange > 0.1;
    final priceDown = pctChange < -0.1;
    final oiUp = (oiChange ?? 0) > 0;
    final oiDown = (oiChange ?? 0) < 0;
    if (priceUp && oiUp) return OiSignal.longBuildup;
    if (priceDown && oiUp) return OiSignal.shortBuildup;
    if (priceDown && oiDown) return OiSignal.longUnwinding;
    if (priceUp && oiDown) return OiSignal.shortCovering;
    return null;
  }

  double get activityScore =>
      ((oi ?? 0) * 0.4) +
      ((volume ?? 0) * 0.4) +
      ((oiChange?.abs() ?? 0) * 0.2);

  String get moneyness => isAtm ? 'ATM' : (isItm ? 'ITM' : 'OTM');
}

// ─────────────────────────────────────────────────────────────
// Max Pain
// ─────────────────────────────────────────────────────────────
class MaxPainResult {
  final double strike, totalPain, spot;
  final String symbol;
  MaxPainResult(
      {required this.strike,
      required this.totalPain,
      required this.spot,
      required this.symbol});
}

List<MaxPainResult> calcMaxPain(List<OiRow> rows) {
  final bySymbol = <String, List<OiRow>>{};
  for (final r in rows) bySymbol.putIfAbsent(r.symbol, () => []).add(r);

  final results = <MaxPainResult>[];
  bySymbol.forEach((symbol, sRows) {
    final strikes = sRows.map((r) => r.strikePrice).toSet().toList()..sort();
    if (strikes.isEmpty) return;
    double minPain = double.infinity;
    double maxPainStrike = strikes.first;
    for (final ts in strikes) {
      double pain = 0;
      for (final r in sRows) {
        if (r.isCE && r.strikePrice < ts)
          pain += (ts - r.strikePrice) * (r.oi ?? 0);
        if (r.isPE && r.strikePrice > ts)
          pain += (r.strikePrice - ts) * (r.oi ?? 0);
      }
      if (pain < minPain) {
        minPain = pain;
        maxPainStrike = ts;
      }
    }
    results.add(MaxPainResult(
        strike: maxPainStrike,
        totalPain: minPain,
        spot: sRows.first.spotPrice ?? 0,
        symbol: symbol));
  });
  return results;
}

// ─────────────────────────────────────────────────────────────
// Controller  — server-side filtering, expiry reset on instrument change
// ─────────────────────────────────────────────────────────────
class _OiAnalyserController extends GetxController {
  final _db = Supabase.instance.client;

  final allRows = <OiRow>[].obs;
  final isLoading = true.obs;
  final isRefreshing = false.obs;
  final error = Rxn<String>();

  // Filters
  final tab = OiSignal.activeCalls.obs;
  final instrument = InstrumentFilter.all.obs;
  final sortBy = ActivitySort.oiChange.obs;
  final limit = RowLimit.n30.obs;
  final selectedExpiry = Rxn<String>();
  final availableExpiries = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    // Instrument change → reset expiry + re-fetch from server
    ever(instrument, (_) {
      selectedExpiry.value = null;
      fetchData();
    });
    // Expiry change → re-fetch from server with new expiry filter
    ever(selectedExpiry, (exp) {
      if (exp != null) fetchData();
    });
    fetchData();
  }

  // ── Server-side fetch ────────────────────────────────────────────────────
  Future<void> fetchData({bool refresh = false}) async {
    if (refresh) {
      isRefreshing.value = true;
    } else {
      isLoading.value = true;
    }
    error.value = null;

    try {
      var query = _db.from('option_chain').select();

      // Symbol filter
      final syms = instrument.value.serverSymbols;
      if (syms != null) {
        query = query.inFilter('underlying_symbol', syms);
      } else if (instrument.value == InstrumentFilter.stocks) {
        // Exclude index symbols
        query = query
            .neq('underlying_symbol', 'NIFTY')
            .neq('underlying_symbol', 'BANKNIFTY')
            .neq('underlying_symbol', 'FINNIFTY');
      }
      // InstrumentFilter.all → no symbol filter

      // Expiry filter (only if already chosen)
      if (selectedExpiry.value != null) {
        query = query.eq('expiry_date', selectedExpiry.value!);
      } else {
        // First load: grab only the nearest expiry to keep payload small
        // We'll expand expiry list from the result.
      }

      final res = await query
          .order('expiry_date', ascending: true)
          .order('strike_price', ascending: true)
          .limit(5000);

      final rows = (res as List)
          .map((m) => OiRow.fromMap(m as Map<String, dynamic>))
          .toList();

      // Build expiry list
      final expiries = rows.map((r) => _fmtDate(r.expiryDate)).toSet().toList()
        ..sort();
      availableExpiries.value = expiries;

      // Auto-select first if none selected or stale
      if (selectedExpiry.value == null ||
          !expiries.contains(selectedExpiry.value)) {
        // set without triggering the ever() re-fetch loop
        selectedExpiry.value = expiries.isNotEmpty ? expiries.first : null;
      }

      allRows.value = rows;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  // ── Local derived data (already server-filtered by instrument + expiry) ──
  List<OiRow> get _filtered {
    final exp = selectedExpiry.value;
    if (exp == null) return allRows;
    return allRows.where((r) => _fmtDate(r.expiryDate) == exp).toList();
  }

  List<OiRow> get displayed {
    var base = _filtered;
    switch (tab.value) {
      case OiSignal.activeCalls:
        base = base.where((r) => r.isCE).toList();
        base.sort((a, b) => b.activityScore.compareTo(a.activityScore));
        break;
      case OiSignal.activePuts:
        base = base.where((r) => r.isPE).toList();
        base.sort((a, b) => b.activityScore.compareTo(a.activityScore));
        break;
      case OiSignal.longBuildup:
        base = base.where((r) => r.signal == OiSignal.longBuildup).toList();
        base = _applySort(base);
        break;
      case OiSignal.shortBuildup:
        base = base.where((r) => r.signal == OiSignal.shortBuildup).toList();
        base = _applySort(base);
        break;
      case OiSignal.longUnwinding:
        base = base.where((r) => r.signal == OiSignal.longUnwinding).toList();
        base = _applySort(base);
        break;
      case OiSignal.shortCovering:
        base = base.where((r) => r.signal == OiSignal.shortCovering).toList();
        base = _applySort(base);
        break;
      case OiSignal.maxPain:
        return [];
    }
    final n = limit.value.count;
    if (n != null && base.length > n) base = base.sublist(0, n);
    return base;
  }

  List<MaxPainResult> get maxPainResults => calcMaxPain(_filtered);

  // Summary counts
  int get longBuCount =>
      _filtered.where((r) => r.signal == OiSignal.longBuildup).length;
  int get shortBuCount =>
      _filtered.where((r) => r.signal == OiSignal.shortBuildup).length;
  int get longUwCount =>
      _filtered.where((r) => r.signal == OiSignal.longUnwinding).length;
  int get shortCovCount =>
      _filtered.where((r) => r.signal == OiSignal.shortCovering).length;
  int get activeCallCount =>
      _filtered.where((r) => r.isCE && r.activityScore > 0).length;
  int get activePutCount =>
      _filtered.where((r) => r.isPE && r.activityScore > 0).length;

  double get totalCeOI =>
      _filtered.where((r) => r.isCE).fold(0, (s, r) => s + (r.oi ?? 0));
  double get totalPeOI =>
      _filtered.where((r) => r.isPE).fold(0, (s, r) => s + (r.oi ?? 0));
  double get pcr => totalCeOI == 0 ? 0 : totalPeOI / totalCeOI;

  double get totalOiAdded => _filtered
      .where((r) => (r.oiChange ?? 0) > 0)
      .fold(0, (s, r) => s + r.oiChange!);
  double get totalOiShed => _filtered
      .where((r) => (r.oiChange ?? 0) < 0)
      .fold(0, (s, r) => s + r.oiChange!.abs());

  List<OiRow> _applySort(List<OiRow> list) {
    list.sort((a, b) {
      switch (sortBy.value) {
        case ActivitySort.oiChange:
          return (b.oiChange?.abs() ?? 0).compareTo(a.oiChange?.abs() ?? 0);
        case ActivitySort.oi:
          return (b.oi ?? 0).compareTo(a.oi ?? 0);
        case ActivitySort.volume:
          return (b.volume ?? 0).compareTo(a.volume ?? 0);
        case ActivitySort.iv:
          return (b.iv ?? 0).compareTo(a.iv ?? 0);
        case ActivitySort.ltp:
          return (b.ltp ?? 0).compareTo(a.ltp ?? 0);
      }
    });
    return list;
  }

  static String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

// ─────────────────────────────────────────────────────────────
// Entry
// ─────────────────────────────────────────────────────────────
class OiActivityPage extends StatefulWidget {
  const OiActivityPage({super.key});

  @override
  State<OiActivityPage> createState() => _OiActivityPageState();
}

class _OiActivityPageState extends State<OiActivityPage> {
  late final _OiAnalyserController c;

  @override
  void initState() {
    super.initState();
    c = Get.put(_OiAnalyserController());
    AnalyticsHelper.logScreen('oi_analyser', screenClass: "OiActivityPage");

    // Show the setup dialog immediately after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showSetupSheet();
    });
  }

  void _showSetupSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = _tok(isDark);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _InitialSetupSheet(c: c, t: t),
    );
  }

  @override
  void dispose() {
    Get.delete<_OiAnalyserController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = _tok(isDark);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: t.bg,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopBar(c: c, t: t),
              _SummaryStrip(c: c, t: t),
              _InstrumentBar(c: c, t: t),
              _TabBar(c: c, t: t),
              Expanded(child: _Body(c: c, t: t)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Top Bar
// ─────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final _OiAnalyserController c;
  final _Tok t;
  const _TopBar({required this.c, required this.t});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: t.surface,
          border: Border(bottom: BorderSide(color: t.border))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Row 1: Back · Title · Refresh
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 8, 0),
          child: Row(children: [
            IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded,
                  size: 18, color: t.text),
              onPressed: Get.back,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
            const SizedBox(width: 2),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('OI Activity',
                      style: GoogleFonts.dmSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: t.text)),
                  Text(
                    'Options Flow Analysis',
                    style: GoogleFonts.dmSans(fontSize: 11, color: t.textMuted),
                  )
                ])),
            Obx(() => c.isRefreshing.value
                ? SizedBox(
                    width: 36,
                    height: 36,
                    child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: t.blue)))
                : IconButton(
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 36, minHeight: 36),
                    icon:
                        Icon(Icons.refresh_rounded, size: 20, color: t.textSub),
                    onPressed: () => c.fetchData(refresh: true))),
          ]),
        ),

        // Row 2: Expiry · Sort · Limit
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
          child: Row(children: [
            // ── Expiry picker uses availableExpiries (server-filtered) ──
            Obx(() {
              final list = c.availableExpiries;
              if (list.isEmpty) return const SizedBox.shrink();
              final sel = c.selectedExpiry.value ?? list.first;
              return _PickerChip(
                label: sel,
                icon: Icons.calendar_today_rounded,
                color: t.blue,
                t: t,
                onTap: () =>
                    _showSheet(context, 'Expiry', list, list.indexOf(sel), (i) {
                  // Only update selectedExpiry; the ever() in controller handles re-fetch
                  c.selectedExpiry.value = list[i];
                }),
              );
            }),
            const Spacer(),
            Obx(() => _PickerChip(
                  label: c.sortBy.value.label,
                  icon: Icons.sort_rounded,
                  color: t.purple,
                  t: t,
                  onTap: () => _showSheet(
                      context,
                      'Sort By',
                      ActivitySort.values.map((e) => e.label).toList(),
                      c.sortBy.value.index,
                      (i) => c.sortBy.value = ActivitySort.values[i]),
                )),
            const SizedBox(width: 8),
            Obx(() => _PickerChip(
                  label: c.limit.value.label,
                  icon: Icons.format_list_numbered_rounded,
                  color: t.amber,
                  t: t,
                  onTap: () => _showSheet(
                      context,
                      'Show',
                      RowLimit.values.map((e) => e.label).toList(),
                      c.limit.value.index,
                      (i) => c.limit.value = RowLimit.values[i]),
                )),
          ]),
        ),
      ]),
    );
  }

  void _showSheet(BuildContext ctx, String title, List<String> opts, int sel,
      Function(int) onSel) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (_) => _PickerSheet(
          title: title, options: opts, selected: sel, onSelect: onSel, t: t),
    );
  }
}

class _PickerChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final _Tok t;
  final VoidCallback onTap;
  const _PickerChip(
      {required this.label,
      required this.icon,
      required this.color,
      required this.t,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.dmSans(
                  fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          const SizedBox(width: 3),
          Icon(Icons.keyboard_arrow_down_rounded, size: 13, color: color),
        ]),
      ),
    );
  }
}

class _PickerSheet extends StatelessWidget {
  final String title;
  final List<String> options;
  final int selected;
  final Function(int) onSelect;
  final _Tok t;
  const _PickerSheet(
      {required this.title,
      required this.options,
      required this.selected,
      required this.onSelect,
      required this.t});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: t.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
                color: t.border, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 14),
        Text(title,
            style: GoogleFonts.dmSans(
                fontSize: 15, fontWeight: FontWeight.w600, color: t.text)),
        const SizedBox(height: 8),
        ...List.generate(
            options.length,
            (i) => ListTile(
                  dense: true,
                  title: Text(options[i],
                      style: GoogleFonts.dmSans(fontSize: 13, color: t.text)),
                  trailing: i == selected
                      ? Icon(Icons.check_circle_rounded,
                          color: t.blue, size: 18)
                      : null,
                  onTap: () {
                    onSelect(i);
                    Navigator.pop(context);
                  },
                )),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Summary Strip with Enhanced Loading State
// ─────────────────────────────────────────────────────────────
class _SummaryStrip extends StatelessWidget {
  final _OiAnalyserController c;
  final _Tok t;
  const _SummaryStrip({required this.c, required this.t});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (c.isLoading.value) return _EnhancedShimmerStrip(t: t);
      return Container(
        margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: t.border),
        ),
        child: Column(children: [
          Row(children: [
            _SumCell(
                label: 'PCR',
                value: c.pcr.toStringAsFixed(2),
                color: c.pcr > 1 ? t.green : (c.pcr < 1 ? t.red : t.text),
                t: t),
            _Vdiv(t: t),
            _SumCell(
                label: 'Long BU',
                value: '${c.longBuCount}',
                color: t.green,
                t: t,
                icon: Icons.rocket_launch_rounded),
            _Vdiv(t: t),
            _SumCell(
                label: 'Short BU',
                value: '${c.shortBuCount}',
                color: t.red,
                t: t,
                icon: Icons.arrow_downward_rounded),
            _Vdiv(t: t),
            _SumCell(
                label: 'Long UW',
                value: '${c.longUwCount}',
                color: t.amber,
                t: t,
                icon: Icons.exit_to_app_rounded),
            _Vdiv(t: t),
            _SumCell(
                label: 'Short Cov',
                value: '${c.shortCovCount}',
                color: t.blue,
                t: t,
                icon: Icons.shield_rounded),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
                child: Row(children: [
              Icon(Icons.add_circle_outline_rounded, size: 11, color: t.green),
              const SizedBox(width: 3),
              Text('OI Added  ${_compact(c.totalOiAdded)}',
                  style: GoogleFonts.dmSans(
                      fontSize: 10,
                      color: t.green,
                      fontWeight: FontWeight.w600)),
            ])),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              Text('OI Shed  ${_compact(c.totalOiShed)}',
                  style: GoogleFonts.dmSans(
                      fontSize: 10, color: t.red, fontWeight: FontWeight.w600)),
              const SizedBox(width: 3),
              Icon(Icons.remove_circle_outline_rounded, size: 11, color: t.red),
            ]),
          ]),
          const SizedBox(height: 5),
          Builder(builder: (_) {
            final total = c.totalOiAdded + c.totalOiShed;
            final pct = total == 0 ? 0.5 : c.totalOiAdded / total;
            return ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                  height: 5,
                  child: Row(children: [
                    Expanded(
                        flex: (pct * 100).round(),
                        child: Container(color: t.green)),
                    Expanded(
                        flex: ((1 - pct) * 100).round(),
                        child: Container(color: t.red)),
                  ])),
            );
          }),
        ]),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────
// Enhanced Shimmer Strip with Detailed Placeholders
// ─────────────────────────────────────────────────────────────
class _EnhancedShimmerStrip extends StatefulWidget {
  final _Tok t;
  const _EnhancedShimmerStrip({required this.t});

  @override
  State<_EnhancedShimmerStrip> createState() => _EnhancedShimmerStripState();
}

class _EnhancedShimmerStripState extends State<_EnhancedShimmerStrip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ac, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final c = Color.lerp(t.shimmerBase, t.shimmerHigh, _anim.value)!;
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: t.border),
          ),
          child: Column(children: [
            // First row - PCR and 4 signal counts
            Row(children: [
              _ShimmerSumCell(label: 'PCR', color: c, t: t),
              _ShimmerVdiv(t: t, color: c),
              _ShimmerSumCell(label: 'Long BU', color: c, t: t, hasIcon: true),
              _ShimmerVdiv(t: t, color: c),
              _ShimmerSumCell(label: 'Short BU', color: c, t: t, hasIcon: true),
              _ShimmerVdiv(t: t, color: c),
              _ShimmerSumCell(label: 'Long UW', color: c, t: t, hasIcon: true),
              _ShimmerVdiv(t: t, color: c),
              _ShimmerSumCell(
                  label: 'Short Cov', color: c, t: t, hasIcon: true),
            ]),
            const SizedBox(height: 10),
            // Second row - OI Added and OI Shed
            Row(children: [
              Expanded(
                  child: Row(children: [
                Container(
                  width: 14,
                  height: 11,
                  decoration: BoxDecoration(
                    color: c,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 3),
                Container(
                  width: 60,
                  height: 10,
                  decoration: BoxDecoration(
                    color: c,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ])),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                Container(
                  width: 50,
                  height: 10,
                  decoration: BoxDecoration(
                    color: c,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 3),
                Container(
                  width: 14,
                  height: 11,
                  decoration: BoxDecoration(
                    color: c,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ]),
            ]),
            const SizedBox(height: 5),
            // Progress bar shimmer
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Container(
                height: 5,
                color: t.shimmerBase,
                child: FractionallySizedBox(
                  widthFactor: 0.5,
                  child: Container(color: c),
                ),
              ),
            ),
          ]),
        );
      },
    );
  }
}

// Shimmer version of SumCell
class _ShimmerSumCell extends StatelessWidget {
  final String label;
  final Color color;
  final _Tok t;
  final bool hasIcon;

  const _ShimmerSumCell({
    required this.label,
    required this.color,
    required this.t,
    this.hasIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasIcon) ...[
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 2),
            ],
            Container(
              width: 40,
              height: 9,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Container(
          width: 30,
          height: 13,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ]),
    );
  }
}

// Shimmer version of vertical divider
class _ShimmerVdiv extends StatelessWidget {
  final _Tok t;
  final Color color;
  const _ShimmerVdiv({required this.t, required this.color});

  @override
  Widget build(BuildContext ctx) => Container(
      width: 1,
      height: 28,
      color: color,
      margin: const EdgeInsets.symmetric(horizontal: 4));
}

class _SumCell extends StatelessWidget {
  final String label, value;
  final Color color;
  final _Tok t;
  final IconData? icon;
  const _SumCell(
      {required this.label,
      required this.value,
      required this.color,
      required this.t,
      this.icon});
  @override
  Widget build(BuildContext context) => Expanded(
          child: Column(children: [
        Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon!, size: 10, color: color),
                const SizedBox(width: 2)
              ],
              Text(label,
                  style: GoogleFonts.dmSans(
                      fontSize: 9,
                      color: t.textMuted,
                      fontWeight: FontWeight.w500)),
            ]),
        const SizedBox(height: 2),
        Text(value,
            style: GoogleFonts.spaceMono(
                fontSize: 13, color: color, fontWeight: FontWeight.w700)),
      ]));
}

class _Vdiv extends StatelessWidget {
  final _Tok t;
  const _Vdiv({required this.t});
  @override
  Widget build(BuildContext ctx) => Container(
      width: 1,
      height: 28,
      color: t.border,
      margin: const EdgeInsets.symmetric(horizontal: 4));
}

// ─────────────────────────────────────────────────────────────
// Instrument Pill Bar
// ─────────────────────────────────────────────────────────────
class _InstrumentBar extends StatelessWidget {
  final _OiAnalyserController c;
  final _Tok t;
  const _InstrumentBar({required this.c, required this.t});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        children: InstrumentFilter.values
            .map((f) => Obx(() {
                  final active = c.instrument.value == f;
                  final color = active ? t.blue : t.textMuted;
                  return GestureDetector(
                    onTap: () => c.instrument.value = f,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: active ? t.blue.withOpacity(.12) : t.surface2,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: active ? t.blue.withOpacity(.5) : t.border),
                      ),
                      child: Text(f.label,
                          style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: color)),
                    ),
                  );
                }))
            .toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Signal Tab Bar
// ─────────────────────────────────────────────────────────────
class _TabBar extends StatelessWidget {
  final _OiAnalyserController c;
  final _Tok t;
  const _TabBar({required this.c, required this.t});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        children: OiSignal.values
            .map((s) => Obx(() {
                  final active = c.tab.value == s;
                  final color = _signalColor(s, t);
                  return GestureDetector(
                    onTap: () => c.tab.value = s,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: active ? color.withOpacity(.13) : t.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: active ? color.withOpacity(.5) : t.border,
                            width: active ? 1.5 : 1),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(s.icon,
                            size: 13, color: active ? color : t.textMuted),
                        const SizedBox(width: 5),
                        Text(s.shortLabel,
                            style: GoogleFonts.dmSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: active ? color : t.textSub)),
                      ]),
                    ),
                  );
                }))
            .toList(),
      ),
    );
  }
}

Color _signalColor(OiSignal s, _Tok t) {
  switch (s) {
    case OiSignal.activeCalls:
      return t.blue;
    case OiSignal.activePuts:
      return t.purple;
    case OiSignal.longBuildup:
      return t.green;
    case OiSignal.shortBuildup:
      return t.red;
    case OiSignal.longUnwinding:
      return t.amber;
    case OiSignal.shortCovering:
      return t.blue;
    case OiSignal.maxPain:
      return t.purple;
  }
}

// ─────────────────────────────────────────────────────────────
// Body
// ─────────────────────────────────────────────────────────────
class _Body extends StatelessWidget {
  final _OiAnalyserController c;
  final _Tok t;
  const _Body({required this.c, required this.t});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (c.isLoading.value) return _SkeletonList(t: t);
      if (c.error.value != null)
        return _ErrorView(msg: c.error.value!, t: t, onRetry: c.fetchData);
      if (c.tab.value == OiSignal.maxPain) return _MaxPainView(c: c, t: t);

      final rows = c.displayed;
      return Column(children: [
        _TabInfo(tab: c.tab.value, count: rows.length, t: t),
        Expanded(
          child: rows.isEmpty
              ? _EmptySignal(signal: c.tab.value, t: t)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 28),
                  itemCount: rows.length,
                  itemBuilder: (_, i) => _ActivityCard(
                      row: rows[i], signal: c.tab.value, t: t, rank: i + 1),
                ),
        ),
      ]);
    });
  }
}

// ─────────────────────────────────────────────────────────────
// Tab Info Bar
// ─────────────────────────────────────────────────────────────
class _TabInfo extends StatelessWidget {
  final OiSignal tab;
  final int count;
  final _Tok t;
  const _TabInfo({required this.tab, required this.count, required this.t});

  @override
  Widget build(BuildContext context) {
    final color = _signalColor(tab, t);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(.2)),
      ),
      child: Row(children: [
        Icon(tab.icon, size: 14, color: color),
        const SizedBox(width: 8),
        Expanded(
            child: Text(tab.description,
                style: GoogleFonts.dmSans(fontSize: 11, color: t.textSub))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
              color: color.withOpacity(.15),
              borderRadius: BorderRadius.circular(12)),
          child: Text('$count',
              style: GoogleFonts.spaceMono(
                  fontSize: 11, color: color, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Activity Card
// ─────────────────────────────────────────────────────────────
class _ActivityCard extends StatelessWidget {
  final OiRow row;
  final OiSignal signal;
  final _Tok t;
  final int rank;
  const _ActivityCard(
      {required this.row,
      required this.signal,
      required this.t,
      required this.rank});

  @override
  Widget build(BuildContext context) {
    final signalColor = _signalColor(signal, t);
    final typeColor = row.isCE ? t.blue : t.purple;
    final pct = row.pctChange;
    final oiChg = row.oiChange ?? 0;
    final oiChgPct = row.oiChangePct;

    Color cardBg = t.surface;
    Color cardBorder = t.border;
    switch (signal) {
      case OiSignal.longBuildup:
        cardBg = t.longBg;
        cardBorder = t.green.withOpacity(.35);
        break;
      case OiSignal.shortBuildup:
        cardBg = t.shortBg;
        cardBorder = t.red.withOpacity(.35);
        break;
      case OiSignal.longUnwinding:
        cardBg = t.longUnwindBg;
        cardBorder = t.amber.withOpacity(.35);
        break;
      case OiSignal.shortCovering:
        cardBg = t.shortCoverBg;
        cardBorder = t.blue.withOpacity(.35);
        break;
      default:
        break;
    }

    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cardBorder),
        ),
        child: Column(children: [
          // ── Row 1: Name + LTP ──────────────────────────────
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Left: symbol name + strike + badges
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(row.symbol,
                          style: GoogleFonts.dmSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: t.text)),
                      const SizedBox(width: 6),
                      Text('${_fmt(row.strikePrice)}',
                          style: GoogleFonts.spaceMono(
                              fontSize: 12,
                              color: t.textSub,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(width: 6),
                      _Badge(text: row.optionType, color: typeColor),
                      const SizedBox(width: 4),
                      _Badge(
                          text: row.moneyness,
                          color: row.isAtm
                              ? t.amber
                              : (row.isItm ? signalColor : t.textMuted),
                          small: true),
                    ]),
                    const SizedBox(height: 3),
                    Row(children: [
                      Text(_fmtDateHuman(row.expiryDate),
                          style: GoogleFonts.dmSans(
                              fontSize: 11, color: t.textMuted)),
                    ]),
                  ]),
            ),
            // Right: LTP + change
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(row.ltp != null ? '${_fmt(row.ltp!)}' : '—',
                  style: GoogleFonts.spaceMono(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: t.text)),
              const SizedBox(height: 2),
              Text('${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(2)}%',
                  style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: pct >= 0 ? t.green : t.red)),
            ]),
          ]),

          const SizedBox(height: 10),
          Divider(height: 1, color: t.border),
          const SizedBox(height: 10),

          // ── Row 2: Stats grid ──────────────────────────────
          Row(children: [
            _StatCell(
                label: 'OI',
                value: row.oi != null ? _compact(row.oi!) : '—',
                color: t.textSub),
            _StatCell(
              label: 'OI Chg',
              value: '${oiChg >= 0 ? '+' : ''}${_compact(oiChg.abs())}',
              sub: '${oiChgPct >= 0 ? '+' : ''}${oiChgPct.toStringAsFixed(1)}%',
              color: oiChg > 0 ? t.green : (oiChg < 0 ? t.red : t.textMuted),
            ),
            _StatCell(
              label: 'Volume',
              value:
                  row.volume != null ? _compact(row.volume!.toDouble()) : '—',
              color: t.textSub,
            ),
            _StatCell(
              label: 'IV',
              value: (row.iv != null && row.iv! > 0)
                  ? '${row.iv!.toStringAsFixed(1)}%'
                  : '—',
              color: signalColor,
            ),
          ]),
        ]),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DetailSheet(row: row, signal: signal, t: t),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label, value;
  final String? sub;
  final Color color;
  const _StatCell(
      {required this.label,
      required this.value,
      this.sub,
      required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: GoogleFonts.dmSans(
                  fontSize: 10, color: const Color(0xFF9CA3B8))),
          const SizedBox(height: 3),
          Text(value,
              style: GoogleFonts.spaceMono(
                  fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          if (sub != null)
            Text(sub!, style: GoogleFonts.dmSans(fontSize: 10, color: color)),
        ]),
      );
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  final bool small;
  const _Badge({required this.text, required this.color, this.small = false});
  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(horizontal: small ? 4 : 6, vertical: 1),
        decoration: BoxDecoration(
            color: color.withOpacity(.15),
            borderRadius: BorderRadius.circular(4)),
        child: Text(text,
            style: GoogleFonts.spaceMono(
                fontSize: small ? 8 : 9,
                color: color,
                fontWeight: FontWeight.w700)),
      );
}

// ─────────────────────────────────────────────────────────────
// Detail Sheet
// ─────────────────────────────────────────────────────────────
class _DetailSheet extends StatelessWidget {
  final OiRow row;
  final OiSignal signal;
  final _Tok t;
  const _DetailSheet(
      {required this.row, required this.signal, required this.t});

  @override
  Widget build(BuildContext context) {
    final color = _signalColor(signal, t);
    final typeColor = row.isCE ? t.blue : t.purple;
    final pct = row.pctChange;
    final oiChg = row.oiChange ?? 0;

    return DraggableScrollableSheet(
      initialChildSize: .72,
      maxChildSize: .95,
      minChildSize: .4,
      builder: (_, sc) => Container(
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ListView(
            controller: sc,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            children: [
              Center(
                  child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: t.border, borderRadius: BorderRadius.circular(2)),
              )),
              Row(children: [
                _Badge(text: row.optionType, color: typeColor),
                const SizedBox(width: 8),
                Text(row.symbol,
                    style: GoogleFonts.dmSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: t.text)),
                const SizedBox(width: 8),
                Text('${_fmt(row.strikePrice)}',
                    style: GoogleFonts.spaceMono(
                        fontSize: 14,
                        color: t.textSub,
                        fontWeight: FontWeight.w600)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: color.withOpacity(.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color.withOpacity(.3))),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(signal.icon, size: 12, color: color),
                    const SizedBox(width: 5),
                    Text(signal.label,
                        style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: color,
                            fontWeight: FontWeight.w600)),
                  ]),
                ),
              ]),
              const SizedBox(height: 4),
              Text(
                  'Expiry: ${_fmtDateHuman(row.expiryDate)} · ${row.moneyness}',
                  style: GoogleFonts.dmSans(fontSize: 12, color: t.textMuted)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [color.withOpacity(.07), Colors.transparent],
                      begin: Alignment.topLeft),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withOpacity(.2)),
                ),
                child: Row(children: [
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('LTP',
                            style: GoogleFonts.dmSans(
                                fontSize: 11, color: t.textMuted)),
                        Text(row.ltp != null ? '${_fmt(row.ltp!)}' : '—',
                            style: GoogleFonts.spaceMono(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: t.text)),
                        Text('Close: ${_fmt(row.closePrice ?? 0)}',
                            style: GoogleFonts.dmSans(
                                fontSize: 10, color: t.textMuted)),
                      ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('Day Chg',
                        style: GoogleFonts.dmSans(
                            fontSize: 11, color: t.textMuted)),
                    Text('${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(2)}%',
                        style: GoogleFonts.spaceMono(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: pct >= 0 ? t.green : t.red)),
                    Text(
                        row.iv != null && row.iv! > 0
                            ? 'IV ${row.iv!.toStringAsFixed(1)}%'
                            : '',
                        style: GoogleFonts.dmSans(fontSize: 10, color: color)),
                  ]),
                ]),
              ),
              const SizedBox(height: 14),
              _Section(title: 'OI Activity', t: t, children: [
                _DRow('Open Interest', _compact(row.oi ?? 0), 'Prev OI',
                    _compact(row.prevOi ?? 0), t),
                _DRow(
                    'OI Change',
                    '${oiChg >= 0 ? '+' : ''}${_compact(oiChg.abs())}',
                    'OI Chg %',
                    '${row.oiChangePct.toStringAsFixed(2)}%',
                    t,
                    c1: oiChg > 0 ? t.green : t.red),
                _DRow('Volume', _compact((row.volume ?? 0).toDouble()),
                    'Lot Size', '${row.lotSize ?? '—'}', t),
              ]),
              const SizedBox(height: 12),
              _Section(title: 'Market Depth', t: t, children: [
                _DRow(
                    'Bid',
                    row.bidPrice != null ? '${_fmt(row.bidPrice!)}' : '—',
                    'Ask',
                    row.askPrice != null ? '${_fmt(row.askPrice!)}' : '—',
                    t,
                    c1: t.green,
                    c2: t.red),
                _DRow(
                    'POP',
                    row.pop != null ? '${row.pop!.toStringAsFixed(1)}%' : '—',
                    'Total Margin',
                    row.totalMargin != null
                        ? '${_compact(row.totalMargin!)}'
                        : '—',
                    t,
                    c1: (row.pop ?? 0) > 50 ? t.green : t.red,
                    c2: t.amber),
              ]),
              const SizedBox(height: 12),
              _Section(title: 'Greeks', t: t, children: [
                _DRow(
                    'Δ Delta',
                    row.delta != null ? row.delta!.toStringAsFixed(4) : '—',
                    'Θ Theta',
                    row.theta != null ? row.theta!.toStringAsFixed(4) : '—',
                    t),
                _DRow(
                    'ν Vega',
                    row.vega != null ? row.vega!.toStringAsFixed(4) : '—',
                    'Spot Price',
                    row.spotPrice != null ? '${_fmt(row.spotPrice!)}' : '—',
                    t),
              ]),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withOpacity(.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(.2)),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(Icons.info_outline_rounded,
                            size: 14, color: color),
                        const SizedBox(width: 6),
                        Text('Signal Interpretation',
                            style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: color,
                                fontWeight: FontWeight.w600)),
                      ]),
                      const SizedBox(height: 6),
                      Text(signal.description,
                          style: GoogleFonts.dmSans(
                              fontSize: 12, color: t.textSub)),
                      const SizedBox(height: 6),
                      Text(_signalAdvice(signal),
                          style: GoogleFonts.dmSans(
                              fontSize: 11, color: t.textMuted)),
                    ]),
              ),
            ]),
      ),
    );
  }
}

String _signalAdvice(OiSignal s) {
  switch (s) {
    case OiSignal.activeCalls:
      return 'High CE activity suggests directional interest or hedging at this strike.';
    case OiSignal.activePuts:
      return 'High PE activity may indicate downside bets or portfolio protection.';
    case OiSignal.longBuildup:
      return 'Bulls are entering fresh positions. Watch for continuation above resistance.';
    case OiSignal.shortBuildup:
      return 'Bears adding positions. Potential breakdown below support.';
    case OiSignal.longUnwinding:
      return 'Longs exiting — potential reversal or profit-booking zone.';
    case OiSignal.shortCovering:
      return 'Short squeeze potential. Shorts are forced to cover — watch for sharp upside.';
    case OiSignal.maxPain:
      return 'Option writers profit maximally at this strike on expiry.';
  }
}

class _Section extends StatelessWidget {
  final String title;
  final _Tok t;
  final List<Widget> children;
  const _Section(
      {required this.title, required this.t, required this.children});
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
            color: t.surface2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: t.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
              child: Text(title,
                  style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: t.textMuted,
                      fontWeight: FontWeight.w600))),
          const Divider(height: 1),
          ...children,
        ]),
      );
}

class _DRow extends StatelessWidget {
  final String l1, v1, l2, v2;
  final _Tok t;
  final Color? c1, c2;
  const _DRow(this.l1, this.v1, this.l2, this.v2, this.t, {this.c1, this.c2});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: Row(children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(l1,
                    style:
                        GoogleFonts.dmSans(fontSize: 10, color: t.textMuted)),
                const SizedBox(height: 2),
                Text(v1,
                    style: GoogleFonts.spaceMono(
                        fontSize: 12,
                        color: c1 ?? t.text,
                        fontWeight: FontWeight.w600)),
              ])),
          Expanded(
              child:
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(l2,
                style: GoogleFonts.dmSans(fontSize: 10, color: t.textMuted)),
            const SizedBox(height: 2),
            Text(v2,
                style: GoogleFonts.spaceMono(
                    fontSize: 12,
                    color: c2 ?? t.text,
                    fontWeight: FontWeight.w600)),
          ])),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────
// Max Pain View
// ─────────────────────────────────────────────────────────────
class _MaxPainView extends StatelessWidget {
  final _OiAnalyserController c;
  final _Tok t;
  const _MaxPainView({required this.c, required this.t});

  @override
  Widget build(BuildContext context) {
    final results = c.maxPainResults;
    if (results.isEmpty) return _EmptySignal(signal: OiSignal.maxPain, t: t);
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: t.purple.withOpacity(.07),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: t.purple.withOpacity(.2)),
          ),
          child: Row(children: [
            Icon(Icons.gps_fixed_rounded, size: 14, color: t.purple),
            const SizedBox(width: 8),
            Expanded(
                child: Text(
                    'Max Pain = strike where total option buyer losses are maximum. '
                    'Prices tend to gravitate toward Max Pain near expiry.',
                    style: GoogleFonts.dmSans(fontSize: 11, color: t.textSub))),
          ]),
        ),
        ...results.map((r) => _MaxPainCard(r: r, t: t)),
      ],
    );
  }
}

class _MaxPainCard extends StatelessWidget {
  final MaxPainResult r;
  final _Tok t;
  const _MaxPainCard({required this.r, required this.t});

  @override
  Widget build(BuildContext context) {
    final diff = r.strike - r.spot;
    final diffPct = r.spot != 0 ? (diff / r.spot) * 100 : 0;
    final isAbove = diff >= 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.border)),
      child: Row(children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(r.symbol,
              style: GoogleFonts.dmSans(
                  fontSize: 15, fontWeight: FontWeight.w700, color: t.text)),
          const SizedBox(height: 3),
          Text('Spot: ${_fmt(r.spot)}',
              style: GoogleFonts.dmSans(fontSize: 11, color: t.textMuted)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('Max Pain',
              style: GoogleFonts.dmSans(fontSize: 10, color: t.textMuted)),
          Text('${_fmt(r.strike)}',
              style: GoogleFonts.spaceMono(
                  fontSize: 16, color: t.purple, fontWeight: FontWeight.w700)),
          Row(children: [
            Icon(
                isAbove
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: 11,
                color: isAbove ? t.green : t.red),
            Text(' ${diffPct.abs().toStringAsFixed(2)}% from spot',
                style: GoogleFonts.dmSans(
                    fontSize: 10, color: isAbove ? t.green : t.red)),
          ]),
        ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Empty / Error / Skeleton
// ─────────────────────────────────────────────────────────────
class _EmptySignal extends StatelessWidget {
  final OiSignal signal;
  final _Tok t;
  const _EmptySignal({required this.signal, required this.t});
  @override
  Widget build(BuildContext context) => Center(
          child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(signal.icon, size: 48, color: t.textMuted),
          const SizedBox(height: 12),
          Text('No ${signal.label} signals found',
              style: GoogleFonts.dmSans(
                  fontSize: 14, fontWeight: FontWeight.w600, color: t.text)),
          const SizedBox(height: 6),
          Text('Try changing the instrument filter or expiry',
              style: GoogleFonts.dmSans(fontSize: 12, color: t.textMuted),
              textAlign: TextAlign.center),
        ]),
      ));
}

class _ErrorView extends StatelessWidget {
  final String msg;
  final _Tok t;
  final VoidCallback onRetry;
  const _ErrorView({required this.msg, required this.t, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
          child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.cloud_off_rounded, size: 48, color: t.textMuted),
          const SizedBox(height: 12),
          Text('Could not load data',
              style: GoogleFonts.dmSans(
                  fontSize: 14, fontWeight: FontWeight.w600, color: t.text)),
          const SizedBox(height: 6),
          Text(msg,
              style: GoogleFonts.dmSans(fontSize: 11, color: t.textMuted),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry')),
        ]),
      ));
}

class _SkeletonList extends StatelessWidget {
  final _Tok t;
  const _SkeletonList({required this.t});
  @override
  Widget build(BuildContext context) => ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        itemCount: 8,
        itemBuilder: (_, __) => _SkeletonCard(t: t),
      );
}

class _SkeletonCard extends StatefulWidget {
  final _Tok t;
  const _SkeletonCard({required this.t});
  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final Animation<double> _anim;
  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ac, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final c = Color.lerp(t.shimmerBase, t.shimmerHigh, _anim.value)!;
        return Container(
          margin: const EdgeInsets.only(top: 6),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: t.border),
          ),
          child: Column(children: [
            // Row 1: Symbol + LTP area
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Left side - symbol info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      // Symbol name
                      Container(
                        height: 16,
                        width: 60,
                        decoration: BoxDecoration(
                          color: c,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Strike price
                      Container(
                        height: 12,
                        width: 45,
                        decoration: BoxDecoration(
                          color: c.withOpacity(.6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Option type badge
                      Container(
                        height: 16,
                        width: 28,
                        decoration: BoxDecoration(
                          color: c.withOpacity(.4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Moneyness badge
                      Container(
                        height: 16,
                        width: 32,
                        decoration: BoxDecoration(
                          color: c.withOpacity(.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 3),
                    // Expiry date
                    Container(
                      height: 11,
                      width: 80,
                      decoration: BoxDecoration(
                        color: c.withOpacity(.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              // Right side - LTP + change
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Container(
                  height: 16,
                  width: 55,
                  decoration: BoxDecoration(
                    color: c,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  height: 12,
                  width: 45,
                  decoration: BoxDecoration(
                    color: c.withOpacity(.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ]),
            ]),

            const SizedBox(height: 10),
            Divider(height: 1, color: t.border.withOpacity(.3)),
            const SizedBox(height: 10),

            // Row 2: Stats grid (4 cells)
            Row(children: [
              // OI cell
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 10,
                      width: 20,
                      decoration: BoxDecoration(
                        color: c.withOpacity(.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      height: 12,
                      width: 40,
                      decoration: BoxDecoration(
                        color: c,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              // OI Chg cell
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 10,
                      width: 35,
                      decoration: BoxDecoration(
                        color: c.withOpacity(.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      height: 12,
                      width: 50,
                      decoration: BoxDecoration(
                        color: c,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      height: 10,
                      width: 35,
                      decoration: BoxDecoration(
                        color: c.withOpacity(.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              // Volume cell
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 10,
                      width: 35,
                      decoration: BoxDecoration(
                        color: c.withOpacity(.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      height: 12,
                      width: 45,
                      decoration: BoxDecoration(
                        color: c,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              // IV cell
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 10,
                      width: 20,
                      decoration: BoxDecoration(
                        color: c.withOpacity(.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      height: 12,
                      width: 40,
                      decoration: BoxDecoration(
                        color: c,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          ]),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────
String _fmt(double v) {
  if (v == v.truncate()) return v.toStringAsFixed(0);
  return v.toStringAsFixed(2);
}

String _compact(double v) {
  final abs = v.abs();
  if (abs >= 10000000) return '${(v / 10000000).toStringAsFixed(2)}Cr';
  if (abs >= 100000) return '${(v / 100000).toStringAsFixed(2)}L';
  if (abs >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
  return v.toStringAsFixed(0);
}

String _fmtDateHuman(DateTime d) {
  const m = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  return '${d.day} ${m[d.month - 1]} ${d.year}';
}

// ─────────────────────────────────────────────────────────────
// Initial Setup Sheet (Layman Friendly Context)
// ─────────────────────────────────────────────────────────────

class _InitialSetupSheet extends StatelessWidget {
  final _OiAnalyserController c;
  final _Tok t;

  const _InitialSetupSheet({required this.c, required this.t});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: t.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Contextual Intro
          Text('Welcome to OI Analysis 👋',
              style: GoogleFonts.dmSans(
                  fontSize: 18, fontWeight: FontWeight.w700, color: t.text)),
          const SizedBox(height: 6),
          Text(
              'Let\'s quickly set up what you want to see. Don\'t worry, you can easily change these filters anytime at the top of the screen!',
              style: GoogleFonts.dmSans(fontSize: 13, color: t.textSub)),
          const SizedBox(height: 24),

          // Question 1: Instrument
          Text('1. Which index do you want to track?',
              style: GoogleFonts.dmSans(
                  fontSize: 14, fontWeight: FontWeight.w600, color: t.text)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: InstrumentFilter.values
                .map((f) => Obx(() {
                      final active = c.instrument.value == f;
                      final color = active ? t.blue : t.textMuted;
                      return GestureDetector(
                        onTap: () => c.instrument.value = f,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color:
                                active ? t.blue.withOpacity(.12) : t.surface2,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color:
                                    active ? t.blue.withOpacity(.5) : t.border),
                          ),
                          child: Text(f.label,
                              style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: color)),
                        ),
                      );
                    }))
                .toList(),
          ),
          const SizedBox(height: 24),

          // Question 2: Signal / View
          Text('2. What are you looking for right now?',
              style: GoogleFonts.dmSans(
                  fontSize: 14, fontWeight: FontWeight.w600, color: t.text)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            // Now mapping through all values to include Unwinding, Covering, and Max Pain
            children: OiSignal.values
                .map((s) => Obx(() {
                      final active = c.tab.value == s;
                      final color = _signalColor(s, t);
                      return GestureDetector(
                        onTap: () => c.tab.value = s,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: active ? color.withOpacity(.13) : t.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color:
                                    active ? color.withOpacity(.5) : t.border,
                                width: active ? 1.5 : 1),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(s.icon,
                                size: 14, color: active ? color : t.textMuted),
                            const SizedBox(width: 6),
                            Text(s.shortLabel,
                                style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: active ? color : t.textSub)),
                          ]),
                        ),
                      );
                    }))
                .toList(),
          ),
          const SizedBox(height: 32),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: t.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: () => Get.back(),
              child: Text('Apply & Explore Data',
                  style: GoogleFonts.dmSans(
                      fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          )
        ],
      ),
    );
  }
}
