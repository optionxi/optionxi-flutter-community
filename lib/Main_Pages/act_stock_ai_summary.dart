import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:optionxi/Helpers/open_url.dart';
import 'package:optionxi/browser_lite.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

// ─── API Base from env ────────────────────────────────────────────────────────
String get kApiBase => dotenv.env['AI_SUMMARY_URL']!;

// ─── Design System ────────────────────────────────────────────────────────────
class _DS {
  static const dBg = Color(0xFF080C12);
  static const dSurface = Color(0xFF0E1520);
  static const dCard = Color(0xFF111B2A);
  static const dBorder = Color(0xFF1C2E45);

  static const lBg = Color(0xFFF5F7FB);
  static const lSurface = Color(0xFFEDF0F7);
  static const lCard = Color(0xFFFFFFFF);
  static const lBorder = Color(0xFFE2E8F0);

  static const cyan = Color(0xFF00D4FF);
  static const green = Color(0xFF00E5A0);
  static const red = Color(0xFFFF4D6A);
  static const amber = Color(0xFFFFB340);
  static const violet = Color(0xFFA78BFA);

  static Color bg(bool d) => d ? dBg : lBg;
  static Color surface(bool d) => d ? dSurface : lSurface;
  static Color card(bool d) => d ? dCard : lCard;
  static Color border(bool d) => d ? dBorder : lBorder;
  static Color textPrimary(bool d) =>
      d ? const Color(0xFFE8F0FF) : const Color(0xFF0A1628);
  static Color textSecondary(bool d) =>
      d ? const Color(0xFF5E7A9E) : const Color(0xFF64748B);
  static Color textTertiary(bool d) =>
      d ? const Color(0xFF3A506B) : const Color(0xFF94A3B8);
  static Color divider(bool d) =>
      d ? const Color(0xFF172030) : const Color(0xFFE8EDF5);
}

// ─── Chart Data Model ─────────────────────────────────────────────────────────
class _ChartPoint {
  final DateTime date;
  final double close;
  const _ChartPoint({required this.date, required this.close});
}

// ─── Loading Steps ────────────────────────────────────────────────────────────
const _kSteps = [
  (
    icon: Icons.hub_rounded,
    label: 'Establishing connection',
    sub: 'Version check & market status'
  ),
  (
    icon: Icons.candlestick_chart_rounded,
    label: 'Loading price history',
    sub: 'Last 30 daily candles'
  ),
  (
    icon: Icons.analytics_rounded,
    label: 'Reading indicators',
    sub: 'RSI · EMA · SMA · Volume'
  ),
  (
    icon: Icons.notifications_active_rounded,
    label: 'Checking alerts',
    sub: 'Active conditions & targets'
  ),
  (
    icon: Icons.account_balance_rounded,
    label: 'Pulling financials',
    sub: 'Balance sheet & P&L — 3 years'
  ),
  (
    icon: Icons.manage_search_rounded,
    label: 'Running screeners',
    sub: 'Bullish / bearish pattern scan'
  ),
  (
    icon: Icons.psychology_rounded,
    label: 'Generating insights',
    sub: 'LLaMA 70B analysing everything'
  ),
];

// ─── Models ───────────────────────────────────────────────────────────────────
class ScreenerSignal {
  final String name, timeframe, scanDate;
  const ScreenerSignal(
      {required this.name, required this.timeframe, required this.scanDate});
  factory ScreenerSignal.fromJson(Map<String, dynamic> j) => ScreenerSignal(
      name: j['name'] ?? '',
      timeframe: j['timeframe'] ?? '',
      scanDate: j['scan_date'] ?? '');
}

class ScreenerAnalysis {
  final List<ScreenerSignal> bullish, bearish;
  final int bullishCount, bearishCount;
  final String bias, summary;
  final bool strongSignal;
  const ScreenerAnalysis({
    required this.bullish,
    required this.bearish,
    required this.bullishCount,
    required this.bearishCount,
    required this.bias,
    required this.strongSignal,
    required this.summary,
  });
  factory ScreenerAnalysis.fromJson(Map<String, dynamic> j) => ScreenerAnalysis(
        bullish: (j['bullish_signals'] as List? ?? [])
            .map((e) => ScreenerSignal.fromJson(e as Map<String, dynamic>))
            .toList(),
        bearish: (j['bearish_signals'] as List? ?? [])
            .map((e) => ScreenerSignal.fromJson(e as Map<String, dynamic>))
            .toList(),
        bullishCount: (j['bullish_count'] ?? 0) as int,
        bearishCount: (j['bearish_count'] ?? 0) as int,
        bias: j['screener_bias'] ?? 'Neutral',
        strongSignal: j['strong_signal'] ?? false,
        summary: j['signal_summary'] ?? '',
      );
}

class AlertSummary {
  final int triggeredCount, pendingCount;
  final List<String> proximityNotes;
  final String summary;
  const AlertSummary({
    required this.triggeredCount,
    required this.pendingCount,
    required this.proximityNotes,
    required this.summary,
  });
  factory AlertSummary.fromJson(Map<String, dynamic> j) => AlertSummary(
        triggeredCount: (j['triggered_alerts'] as List? ?? []).length,
        pendingCount: (j['pending_alerts'] as List? ?? []).length,
        proximityNotes: List<String>.from(j['proximity_notes'] ?? []),
        summary: j['alert_summary'] ?? '',
      );
}

class FetchCheck {
  final String source, detail;
  final bool found;
  final int count;
  const FetchCheck(
      {required this.source,
      required this.found,
      required this.count,
      required this.detail});
  factory FetchCheck.fromJson(Map<String, dynamic> j) => FetchCheck(
      source: j['source'] ?? '',
      found: j['found'] ?? false,
      count: j['count'] ?? 0,
      detail: j['detail'] ?? '');
}

class StockAnalysis {
  final String symbol,
      companyName,
      marketSentiment,
      sentimentEmoji,
      oneLiner,
      volumeAnalysis,
      indicatorSummary,
      timeframe,
      confidence,
      lastUpdated;
  final double currentPrice, dayChangePct;
  final List<PriceLevel> supportLevels, resistanceLevels;
  final List<EntryOpportunity> entries;
  final List<String> keyObservations, riskFactors;
  final bool cached;
  final int? ttlSeconds;
  final ScreenerAnalysis screenerAnalysis;
  final AlertSummary alertSummary;
  final List<FetchCheck> fetchChecks;
  final int fetchFound, fetchTotal;

  const StockAnalysis({
    required this.symbol,
    required this.companyName,
    required this.marketSentiment,
    required this.sentimentEmoji,
    required this.oneLiner,
    required this.currentPrice,
    required this.dayChangePct,
    required this.supportLevels,
    required this.resistanceLevels,
    required this.entries,
    required this.keyObservations,
    required this.riskFactors,
    required this.volumeAnalysis,
    required this.indicatorSummary,
    required this.timeframe,
    required this.confidence,
    required this.lastUpdated,
    required this.cached,
    this.ttlSeconds,
    required this.screenerAnalysis,
    required this.alertSummary,
    required this.fetchChecks,
    required this.fetchFound,
    required this.fetchTotal,
  });

  factory StockAnalysis.fromJson(Map<String, dynamic> r) {
    final d = r['data'] as Map<String, dynamic>;
    final sa = r['screener_analysis'] as Map<String, dynamic>? ?? {};
    final aa = r['alert_analysis'] as Map<String, dynamic>? ?? {};
    final fs = r['fetch_status'] as Map<String, dynamic>? ?? {};
    return StockAnalysis(
      symbol: d['symbol'] ?? '',
      companyName: d['company_name'] ?? '',
      marketSentiment: d['market_sentiment'] ?? '',
      sentimentEmoji: d['sentiment_emoji'] ?? '🟡',
      oneLiner: d['one_liner'] ?? '',
      currentPrice: (d['current_price'] ?? 0).toDouble(),
      dayChangePct: (d['day_change_pct'] ?? 0).toDouble(),
      supportLevels: (d['support_levels'] as List? ?? [])
          .map((e) => PriceLevel.fromJson(e))
          .toList(),
      resistanceLevels: (d['resistance_levels'] as List? ?? [])
          .map((e) => PriceLevel.fromJson(e))
          .toList(),
      entries: (d['entry_opportunities'] as List? ?? [])
          .map((e) => EntryOpportunity.fromJson(e))
          .toList(),
      keyObservations: List<String>.from(d['key_observations'] ?? []),
      riskFactors: List<String>.from(d['risk_factors'] ?? []),
      volumeAnalysis: d['volume_analysis'] ?? '',
      indicatorSummary: d['indicator_summary'] ?? '',
      timeframe: d['timeframe'] ?? '',
      confidence: d['confidence'] ?? '',
      lastUpdated: d['last_updated'] ?? '',
      cached: r['cached'] ?? false,
      ttlSeconds: r['ttl_seconds'] as int?,
      screenerAnalysis: ScreenerAnalysis.fromJson(sa),
      alertSummary: AlertSummary.fromJson(aa),
      fetchChecks: (fs['checks'] as List? ?? [])
          .map((e) => FetchCheck.fromJson(e as Map<String, dynamic>))
          .toList(),
      fetchFound: (fs['found_count'] ?? 0) as int,
      fetchTotal: (fs['total'] ?? 0) as int,
    );
  }
}

class PriceLevel {
  final double price;
  final String strength, note;
  const PriceLevel(
      {required this.price, required this.strength, required this.note});
  factory PriceLevel.fromJson(Map<String, dynamic> j) => PriceLevel(
      price: (j['price'] ?? 0).toDouble(),
      strength: j['strength'] ?? '',
      note: j['note'] ?? '');
}

class EntryOpportunity {
  final String type, entryZone, rationale, riskReward;
  final double stopLoss, target1, target2;
  const EntryOpportunity({
    required this.type,
    required this.entryZone,
    required this.rationale,
    required this.riskReward,
    required this.stopLoss,
    required this.target1,
    required this.target2,
  });
  factory EntryOpportunity.fromJson(Map<String, dynamic> j) => EntryOpportunity(
        type: j['type'] ?? '',
        entryZone: j['entry_zone'] ?? '',
        rationale: j['rationale'] ?? '',
        riskReward: j['risk_reward'] ?? '',
        stopLoss: (j['stop_loss'] ?? 0).toDouble(),
        target1: (j['target_1'] ?? 0).toDouble(),
        target2: (j['target_2'] ?? 0).toDouble(),
      );
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
Future<int> _getBuildNumber() async {
  try {
    final info = await PackageInfo.fromPlatform();
    return int.tryParse(info.buildNumber) ?? 0;
  } catch (_) {
    return 0;
  }
}

void _showUpdateDialog(BuildContext context, bool dark,
    {required bool compulsory, required String storeUrl}) {
  showDialog(
    context: context,
    barrierDismissible: !compulsory,
    builder: (_) => WillPopScope(
      onWillPop: () async => !compulsory,
      child:
          _UpdateDialog(dark: dark, compulsory: compulsory, storeUrl: storeUrl),
    ),
  );
}

// ─── Update Dialog ────────────────────────────────────────────────────────────
class _UpdateDialog extends StatelessWidget {
  final bool dark, compulsory;
  final String storeUrl;
  const _UpdateDialog(
      {required this.dark, required this.compulsory, required this.storeUrl});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: _DS.card(dark),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: _DS.cyan.withOpacity(.2)),
          boxShadow: [
            BoxShadow(
                color: _DS.cyan.withOpacity(.06),
                blurRadius: 48,
                spreadRadius: 8),
          ],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                  colors: [_DS.cyan.withOpacity(.2), Colors.transparent]),
              border: Border.all(color: _DS.cyan.withOpacity(.3)),
            ),
            child: const Icon(Icons.system_update_rounded,
                color: _DS.cyan, size: 28),
          ),
          const SizedBox(height: 22),
          Text(
            compulsory ? 'Update Required' : 'Update Available',
            style: GoogleFonts.dmSans(
                color: _DS.textPrimary(dark),
                fontSize: 20,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Text(
            compulsory
                ? 'A newer version is required to use AI Analysis. Please update to continue.'
                : 'A newer version is available with improvements and bug fixes.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
                color: _DS.textSecondary(dark), fontSize: 13, height: 1.65),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: () => OpenHelper.open_url(storeUrl),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF00D4FF), Color(0xFF0066FF)]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: _DS.cyan.withOpacity(.25),
                        blurRadius: 20,
                        offset: const Offset(0, 6))
                  ],
                ),
                child: Text('Update Now',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ),
          if (!compulsory) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('Maybe Later',
                    style: GoogleFonts.dmSans(
                        color: _DS.textSecondary(dark), fontSize: 13)),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

// ─── Main Page ────────────────────────────────────────────────────────────────
class StockAiAnalysisPage extends StatefulWidget {
  final String symbol;
  const StockAiAnalysisPage({super.key, required this.symbol});
  @override
  State<StockAiAnalysisPage> createState() => _StockAiAnalysisPageState();
}

class _StockAiAnalysisPageState extends State<StockAiAnalysisPage>
    with TickerProviderStateMixin {
  StockAnalysis? _analysis;
  bool _loading = true;
  bool _showDebug = false;
  String? _error;
  int _stepIndex = 0;

  // ── Chart state ──
  List<_ChartPoint> _chartData = [];
  bool _chartLoading = false;

  late AnimationController _pulseCtrl;
  late AnimationController _spinCtrl;
  late AnimationController _stepCtrl;
  late AnimationController _contentCtrl;
  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;
  late Animation<double> _stepFade;

  String _androidStoreUrl =
      'https://play.google.com/store/apps/details?id=com.optionxi.app';
  String _iosStoreUrl = 'https://apps.apple.com/in/app/optionxi/id6447514602';

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat();
    _spinCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 6))
          ..repeat();
    _stepCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _contentCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _contentFade = CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut);
    _contentSlide = Tween(begin: const Offset(0, .04), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOutCubic));
    _stepFade = CurvedAnimation(parent: _stepCtrl, curve: Curves.easeOut);
    _load();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _spinCtrl.dispose();
    _stepCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  void _advanceStep(int i) {
    if (!mounted) return;
    _stepCtrl.forward(from: 0);
    setState(() => _stepIndex = i);
  }

  // ── Fetch 30-day chart from Supabase ──────────────────────────────────────
  Future<void> _fetchChart() async {
    if (!mounted) return;
    setState(() => _chartLoading = true);
    try {
      final supabase = Supabase.instance.client;
      // Format symbol: strip NSE: prefix, -EQ/-BE suffix, add .NS
      String sym = widget.symbol;
      if (sym.startsWith('NSE:')) sym = sym.substring(4);
      if (sym.endsWith('-EQ')) sym = sym.substring(0, sym.length - 3);
      if (sym.endsWith('-BE')) sym = sym.substring(0, sym.length - 3);
      if (!sym.endsWith('.NS')) sym = '$sym.NS';

      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 30));
      final response = await supabase
          .from('stock_data')
          .select('Timestamp, Close')
          .eq('Stock Symbol', sym)
          .gte('Timestamp', start.millisecondsSinceEpoch)
          .order('Timestamp', ascending: true);

      final pts = <_ChartPoint>[];
      for (final row in response) {
        try {
          final ts = row['Timestamp'];
          final cl = row['Close'];
          if (ts == null || cl == null) continue;
          final date = DateTime.fromMillisecondsSinceEpoch((ts as num).toInt(),
              isUtc: false);
          pts.add(_ChartPoint(date: date, close: (cl as num).toDouble()));
        } catch (_) {}
      }
      if (mounted) setState(() => _chartData = pts);
    } catch (_) {
      // silently ignore — chart is supplementary
    } finally {
      if (mounted) setState(() => _chartLoading = false);
    }
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
      _stepIndex = 0;
      _chartData = [];
    });

    // Remote Config
    try {
      final rc = FirebaseRemoteConfig.instance;
      await rc.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(seconds: 120),
      ));
      await rc.activate();
      await rc.fetch();
      final ios = rc.getString('ioslink');
      final android = rc.getString('androidlink');
      if (ios.isNotEmpty) _iosStoreUrl = ios;
      if (android.isNotEmpty) _androidStoreUrl = android;
    } catch (_) {}

    // Version gate
    try {
      final build = await _getBuildNumber();
      final cfgRes = await http
          .get(Uri.parse('$kApiBase/app-config'))
          .timeout(const Duration(seconds: 10));
      if (cfgRes.statusCode == 200) {
        final cfg = jsonDecode(cfgRes.body) as Map<String, dynamic>;
        final minVer = int.tryParse(cfg['min_version']?.toString() ?? '0') ?? 0;
        final latestVer =
            int.tryParse(cfg['latest_version']?.toString() ?? '0') ?? 0;
        if (!mounted) return;
        final dark = Theme.of(context).brightness == Brightness.dark;
        if (build < minVer) {
          setState(() => _loading = false);
          _showUpdateDialog(context, dark,
              compulsory: true,
              storeUrl: Platform.isIOS ? _iosStoreUrl : _androidStoreUrl);
          return;
        } else if (build < latestVer) {
          _showUpdateDialog(context, dark,
              compulsory: false,
              storeUrl: Platform.isIOS ? _iosStoreUrl : _androidStoreUrl);
        }
      }
    } catch (_) {}

    // Animated step walk
    const stepMs = Duration(milliseconds: 420);
    for (int i = 1; i < _kSteps.length - 1; i++) {
      await Future.delayed(stepMs);
      _advanceStep(i);
    }

    try {
      final res = await http
          .get(Uri.parse('$kApiBase/analysis/${widget.symbol}'))
          .timeout(const Duration(seconds: 60));

      _advanceStep(_kSteps.length - 1);
      await Future.delayed(const Duration(milliseconds: 400));

      if (res.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          _analysis = StockAnalysis.fromJson(
              jsonDecode(res.body) as Map<String, dynamic>);
          _loading = false;
        });
        _contentCtrl.forward(from: 0);
        // Fetch chart data after analysis loads
        _fetchChart();
      } else {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if (!mounted) return;
        setState(() {
          _error =
              body['detail']?.toString() ?? 'Server error ${res.statusCode}';
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  bool get _dark => Theme.of(context).brightness == Brightness.dark;

  @override
  Widget build(BuildContext context) {
    final dark = _dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _DS.bg(dark),
        body: SafeArea(
          child: _loading
              ? _buildLoader(dark)
              : _error != null
                  ? _buildError(dark)
                  : _buildContent(dark),
        ),
      ),
    );
  }

  // ─── Loader ─────────────────────────────────────────────────────────────────
  Widget _buildLoader(bool dark) {
    final step = _kSteps[_stepIndex.clamp(0, _kSteps.length - 1)];
    final pct = (_stepIndex + 1) / _kSteps.length;

    return Column(children: [
      _TopBar(dark: dark, symbol: widget.symbol, trailing: const SizedBox()),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(children: [
            const SizedBox(height: 32),
            SizedBox(
              width: 180,
              height: 180,
              child: AnimatedBuilder(
                animation: Listenable.merge([_pulseCtrl, _spinCtrl]),
                builder: (_, __) {
                  final pulse = math.sin(_pulseCtrl.value * 2 * math.pi);
                  final spin = _spinCtrl.value * 2 * math.pi;
                  return Stack(alignment: Alignment.center, children: [
                    Opacity(
                      opacity: (.05 + .04 * pulse).clamp(0, 1),
                      child: Container(
                        width: 178,
                        height: 178,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _DS.cyan, width: .5),
                        ),
                      ),
                    ),
                    Transform.rotate(
                      angle: spin,
                      child: CustomPaint(
                        size: const Size(138, 138),
                        painter: _ArcPainter(color: _DS.cyan, strokeWidth: 1.5),
                      ),
                    ),
                    Transform.rotate(
                      angle: -spin * .7,
                      child: CustomPaint(
                        size: const Size(100, 100),
                        painter: _ArcPainter(color: _DS.violet, strokeWidth: 1),
                      ),
                    ),
                    Transform.rotate(
                      angle: spin,
                      child: Transform.translate(
                        offset: const Offset(64, 0),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _DS.cyan,
                            boxShadow: [
                              BoxShadow(
                                  color: _DS.cyan.withOpacity(.6),
                                  blurRadius: 8)
                            ],
                          ),
                        ),
                      ),
                    ),
                    Transform.rotate(
                      angle: -spin * .7 + math.pi * .5,
                      child: Transform.translate(
                        offset: const Offset(44, 0),
                        child: Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _DS.violet,
                            boxShadow: [
                              BoxShadow(
                                  color: _DS.violet.withOpacity(.6),
                                  blurRadius: 6)
                            ],
                          ),
                        ),
                      ),
                    ),
                    Transform.rotate(
                      angle: spin * .5 + math.pi,
                      child: Transform.translate(
                        offset: const Offset(64, 0),
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _DS.green.withOpacity(.8),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _DS.card(dark),
                        border: Border.all(color: _DS.border(dark)),
                        boxShadow: [
                          BoxShadow(
                              color: _DS.cyan.withOpacity(.12), blurRadius: 24),
                        ],
                      ),
                      child: Icon(step.icon, color: _DS.cyan, size: 26),
                    ),
                  ]);
                },
              ),
            ),
            const SizedBox(height: 32),
            FadeTransition(
              opacity: _stepFade,
              child: Column(children: [
                Text(widget.symbol,
                    style: GoogleFonts.jetBrainsMono(
                        color: _DS.cyan,
                        fontSize: 11,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Text(step.label,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                        color: _DS.textPrimary(dark),
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        height: 1.2)),
                const SizedBox(height: 6),
                Text(step.sub,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                        color: _DS.textSecondary(dark),
                        fontSize: 14,
                        height: 1.5)),
              ]),
            ),
            const SizedBox(height: 28),
            Container(
              height: 3,
              decoration: BoxDecoration(
                color: _DS.border(dark),
                borderRadius: BorderRadius.circular(2),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      width: constraints.maxWidth * pct,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_DS.cyan, _DS.violet],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                              color: _DS.cyan.withOpacity(.4), blurRadius: 6)
                        ],
                      ),
                    ),
                  ]);
                },
              ),
            ),
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('${(_stepIndex + 1)} of ${_kSteps.length}',
                  style: GoogleFonts.jetBrainsMono(
                      color: _DS.textTertiary(dark), fontSize: 10)),
              Text('${(pct * 100).round()}%',
                  style: GoogleFonts.jetBrainsMono(
                      color: _DS.cyan,
                      fontSize: 10,
                      fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: _DS.card(dark),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _DS.border(dark)),
              ),
              child: Column(children: [
                for (int i = 0; i < _kSteps.length; i++) ...[
                  _LoadRow(
                    icon: _kSteps[i].icon,
                    label: _kSteps[i].label,
                    state: i < _stepIndex
                        ? _RowState.done
                        : i == _stepIndex
                            ? _RowState.active
                            : _RowState.pending,
                    dark: dark,
                    isFirst: i == 0,
                    isLast: i == _kSteps.length - 1,
                  ),
                  if (i < _kSteps.length - 1)
                    Divider(
                        height: 1,
                        indent: 48,
                        endIndent: 16,
                        color: _DS.divider(dark)),
                ],
              ]),
            ),
            const SizedBox(height: 32),
          ]),
        ),
      ),
    ]);
  }

  // ─── Error ──────────────────────────────────────────────────────────────────
  Widget _buildError(bool dark) {
    return Column(children: [
      _TopBar(dark: dark, symbol: widget.symbol, trailing: const SizedBox()),
      Expanded(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _DS.red.withOpacity(.08),
                  border: Border.all(color: _DS.red.withOpacity(.25)),
                ),
                child: const Icon(Icons.error_outline_rounded,
                    color: _DS.red, size: 34),
              ),
              const SizedBox(height: 24),
              Text('Analysis Failed',
                  style: GoogleFonts.dmSans(
                      color: _DS.textPrimary(dark),
                      fontSize: 22,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('Something went wrong while fetching the analysis.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                      color: _DS.textSecondary(dark),
                      fontSize: 14,
                      height: 1.6)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _DS.red.withOpacity(.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _DS.red.withOpacity(.12)),
                ),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.terminal_rounded,
                          color: _DS.red, size: 13),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(_error!,
                              style: GoogleFonts.jetBrainsMono(
                                  color: _DS.textSecondary(dark),
                                  fontSize: 11,
                                  height: 1.6))),
                    ]),
              ),
              const SizedBox(height: 28),
              _GradientButton(
                  label: 'Retry Analysis',
                  icon: Icons.refresh_rounded,
                  onTap: _load),
            ]),
          ),
        ),
      ),
    ]);
  }

  // ─── Content ────────────────────────────────────────────────────────────────
  Widget _buildContent(bool dark) {
    if (_analysis == null) {
      return Column(children: [
        _TopBar(dark: dark, symbol: widget.symbol, trailing: const SizedBox()),
        Expanded(
            child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.sentiment_dissatisfied_rounded,
                color: _DS.textTertiary(dark), size: 40),
            const SizedBox(height: 16),
            Text('No data available',
                style: GoogleFonts.dmSans(
                    color: _DS.textSecondary(dark), fontSize: 16)),
            const SizedBox(height: 24),
            _GradientButton(
                label: 'Try Again', icon: Icons.refresh_rounded, onTap: _load),
          ]),
        )),
      ]);
    }

    final a = _analysis!;
    return FadeTransition(
      opacity: _contentFade,
      child: SlideTransition(
        position: _contentSlide,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(a, dark),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
              sliver: SliverList(
                  delegate: SliverChildListDelegate([
                // Disclaimer
                _DisclaimerBanner(dark: dark),
                const SizedBox(height: 20),

                // Hero
                // _HeroCard(analysis: a, dark: dark),
                // const SizedBox(height: 12),

                // AI One-liner
                _OneLinerCard(text: a.oneLiner, dark: dark),
                const SizedBox(height: 24),

                // ── NEW: 30-Day Chart + OHLC + L-H Progress ──────────────
                _PriceChartCard(
                  analysis: a,
                  chartData: _chartData,
                  chartLoading: _chartLoading,
                  dark: dark,
                  symbol: widget.symbol,
                ),
                const SizedBox(height: 24),

                // Screener
                _SectionHeader(
                    title: 'Screener Signals',
                    icon: Icons.radar_rounded,
                    dark: dark),
                const SizedBox(height: 10),
                _ScreenerCard(sa: a.screenerAnalysis, dark: dark),
                const SizedBox(height: 24),

                // Alerts
                if (a.alertSummary.triggeredCount > 0 ||
                    a.alertSummary.pendingCount > 0) ...[
                  _SectionHeader(
                      title: 'Active Alerts',
                      icon: Icons.notifications_active_rounded,
                      dark: dark),
                  const SizedBox(height: 10),
                  _AlertCard(alert: a.alertSummary, dark: dark),
                  const SizedBox(height: 24),
                ],

                // Entries
                _SectionHeader(
                    title: 'Entry Opportunities',
                    icon: Icons.login_rounded,
                    dark: dark),
                const SizedBox(height: 10),
                ...a.entries.asMap().entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child:
                          _EntryCard(entry: e.value, dark: dark, index: e.key),
                    )),
                const SizedBox(height: 12),

                // S&R
                _SectionHeader(
                    title: 'Support & Resistance',
                    icon: Icons.layers_rounded,
                    dark: dark),
                const SizedBox(height: 10),
                _SRCard(
                    supports: a.supportLevels,
                    resistances: a.resistanceLevels,
                    dark: dark),
                const SizedBox(height: 24),

                // Observations
                _SectionHeader(
                    title: 'Key Observations',
                    icon: Icons.lightbulb_rounded,
                    dark: dark),
                const SizedBox(height: 10),
                _ObsCard(items: a.keyObservations, dark: dark),
                const SizedBox(height: 24),

                // Indicators
                _SectionHeader(
                    title: 'Indicators & Volume',
                    icon: Icons.bar_chart_rounded,
                    dark: dark),
                const SizedBox(height: 10),
                _TextCard(
                    content: a.indicatorSummary,
                    icon: Icons.analytics_rounded,
                    dark: dark),
                const SizedBox(height: 8),
                _TextCard(
                    content: a.volumeAnalysis,
                    icon: Icons.water_rounded,
                    label: 'Volume',
                    dark: dark),
                const SizedBox(height: 24),

                // Risk
                _SectionHeader(
                    title: 'Risk Factors',
                    icon: Icons.warning_amber_rounded,
                    dark: dark,
                    accent: _DS.red),
                const SizedBox(height: 10),
                _RiskCard(risks: a.riskFactors, dark: dark),
                const SizedBox(height: 24),

                // Data sources
                _SectionHeader(
                    title: 'Data Sources',
                    icon: Icons.storage_rounded,
                    dark: dark),
                const SizedBox(height: 10),
                _FetchStatusCard(
                  checks: a.fetchChecks,
                  found: a.fetchFound,
                  total: a.fetchTotal,
                  dark: dark,
                  expanded: _showDebug,
                  onToggle: () => setState(() => _showDebug = !_showDebug),
                ),
                const SizedBox(height: 24),

                // Meta
                _MetaRow(analysis: a, onRefresh: _load, dark: dark),
                const SizedBox(height: 8),
              ])),
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar(StockAnalysis a, bool dark) {
    final isUp = a.dayChangePct >= 0;
    final changeColor = isUp ? _DS.green : _DS.red;
    return SliverAppBar(
      backgroundColor: _DS.bg(dark),
      elevation: 0,
      pinned: true,
      expandedHeight: 0,
      automaticallyImplyLeading: false,
      leading: Padding(
        padding: const EdgeInsets.only(left: 10, top: 6, bottom: 6),
        child: _BackBtn(dark: dark),
      ),
      title: Row(children: [
        Text(a.symbol,
            style: GoogleFonts.jetBrainsMono(
                color: _DS.textPrimary(dark),
                fontSize: 18,
                fontWeight: FontWeight.w700)),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: changeColor.withOpacity(.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(
                isUp
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: 11,
                color: changeColor),
            const SizedBox(width: 3),
            Text('${isUp ? "+" : ""}${a.dayChangePct.toStringAsFixed(2)}%',
                style: GoogleFonts.jetBrainsMono(
                    color: changeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
      ]),
      actions: [
        GestureDetector(
          onTap: _load,
          child: Container(
            margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _DS.surface(dark),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: _DS.border(dark)),
            ),
            child: Icon(Icons.refresh_rounded, color: _DS.cyan, size: 18),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              Colors.transparent,
              _DS.divider(dark),
              Colors.transparent,
            ]),
          ),
        ),
      ),
    );
  }
}

// ─── NEW: Price Chart Card ────────────────────────────────────────────────────
class _PriceChartCard extends StatelessWidget {
  final StockAnalysis analysis;
  final List<_ChartPoint> chartData;
  final bool chartLoading;
  final bool dark;
  final String symbol;

  const _PriceChartCard({
    required this.analysis,
    required this.chartData,
    required this.chartLoading,
    required this.dark,
    required this.symbol,
  });

  // Compute L-H progress from current price relative to chart 30d range
  // Falls back to dayChangePct sign if no chart data yet
  double get _progress {
    if (chartData.isEmpty) {
      return analysis.dayChangePct >= 0 ? 0.7 : 0.3;
    }
    final prices = chartData.map((p) => p.close).toList();
    final low = prices.reduce((a, b) => a < b ? a : b);
    final high = prices.reduce((a, b) => a > b ? a : b);
    final span = high - low;
    if (span == 0) return 0.5;
    return ((analysis.currentPrice - low) / span).clamp(0.0, 1.0);
  }

  double get _chartLow {
    if (chartData.isEmpty) return analysis.currentPrice * 0.97;
    return chartData.map((p) => p.close).reduce((a, b) => a < b ? a : b);
  }

  double get _chartHigh {
    if (chartData.isEmpty) return analysis.currentPrice * 1.03;
    return chartData.map((p) => p.close).reduce((a, b) => a > b ? a : b);
  }

  Color _rangeColor(bool dark) {
    final p = _progress;
    if (p < 0.33)
      return dark ? const Color(0xFFEF4444) : const Color(0xFFDC2626);
    if (p > 0.66)
      return dark ? const Color(0xFF22C55E) : const Color(0xFF16A34A);
    return const Color(0xFFF59E0B);
  }

  String _rangeLabel() {
    final p = _progress;
    if (p < 0.33) return 'Near 30d Low';
    if (p > 0.66) return 'Near 30d High';
    return 'Mid Range';
  }

  Color _changeColor(bool dark) => analysis.dayChangePct >= 0
      ? (dark ? const Color(0xFF22C55E) : const Color(0xFF16A34A))
      : (dark ? const Color(0xFFEF4444) : const Color(0xFFDC2626));

  Color _changeBg(bool dark) => analysis.dayChangePct >= 0
      ? (dark ? const Color(0xFF052E16) : const Color(0xFFDCFCE7))
      : (dark ? const Color(0xFF450A0A) : const Color(0xFFFEE2E2));

  void _openTradingView(BuildContext ctx) {
    final sym = symbol
        .replaceAll('NSE:', '')
        .replaceAll('-EQ', '')
        .replaceAll('-BE', '');
    Navigator.push(
        ctx,
        MaterialPageRoute(
            builder: (context) => BrowserLite_V(
                'https://in.tradingview.com/chart/?symbol=NSE%3A$sym')));
  }

  @override
  Widget build(BuildContext context) {
    final cc = _changeColor(dark);
    final cb = _changeBg(dark);
    final rc = _rangeColor(dark);
    final isUp = analysis.dayChangePct >= 0;

    // Line / fill colours for chart
    final lineColor = isUp
        ? (dark ? const Color(0xFF22C55E) : const Color(0xFF16A34A))
        : (dark ? const Color(0xFFEF4444) : const Color(0xFFDC2626));
    final fillColor = isUp
        ? (dark ? const Color(0xFF052E16) : const Color(0xFFDCFCE7))
        : (dark ? const Color(0xFF450A0A) : const Color(0xFFFEE2E2));

    return Container(
      decoration: BoxDecoration(
        color: _DS.card(dark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _DS.border(dark)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header row ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('30-Day Price',
                  style: GoogleFonts.dmSans(
                      color: _DS.textPrimary(dark),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2)),
              const SizedBox(height: 2),
              Text('Last 30 trading days',
                  style: GoogleFonts.dmSans(
                      color: _DS.textSecondary(dark), fontSize: 11.5)),
            ]),
            const Spacer(),
            // % change badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: cb,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                  isUp
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  color: cc,
                  size: 13,
                ),
                const SizedBox(width: 4),
                Text(
                  '${isUp ? "+" : ""}${analysis.dayChangePct.toStringAsFixed(2)}%',
                  style: GoogleFonts.jetBrainsMono(
                      color: cc, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ]),
            ),
          ]),
        ),

        const SizedBox(height: 14),

        // ── OHLC row ────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            _OhlcCell(label: 'OPEN', value: analysis.currentPrice, dark: dark),
            _divider(dark),
            _OhlcCell(
                label: 'HIGH',
                value: _chartHigh,
                dark: dark,
                color:
                    dark ? const Color(0xFF22C55E) : const Color(0xFF16A34A)),
            _divider(dark),
            _OhlcCell(
                label: 'LOW',
                value: _chartLow,
                dark: dark,
                color:
                    dark ? const Color(0xFFEF4444) : const Color(0xFFDC2626)),
            _divider(dark),
            _OhlcCell(
                label: 'LTP',
                value: analysis.currentPrice,
                dark: dark,
                color: cc),
          ]),
        ),

        const SizedBox(height: 14),

        // ── L-H Progress bar (30d range) ────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _LHProgressBar(
            low: _chartLow,
            high: _chartHigh,
            current: analysis.currentPrice,
            progress: _progress,
            rangeColor: rc,
            rangeLabel: _rangeLabel(),
            dark: dark,
          ),
        ),

        const SizedBox(height: 16),

        // ── Chart ────────────────────────────────────────────────────────────
        if (chartLoading)
          SizedBox(
            height: 180,
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child:
                    CircularProgressIndicator(strokeWidth: 2, color: _DS.cyan),
              ),
            ),
          )
        else if (chartData.isEmpty)
          SizedBox(
            height: 100,
            child: Center(
              child: Text('Chart data unavailable',
                  style: GoogleFonts.dmSans(
                      color: _DS.textTertiary(dark), fontSize: 12)),
            ),
          )
        else
          SizedBox(
            height: 190,
            child: SfCartesianChart(
              plotAreaBorderWidth: 0,
              margin: const EdgeInsets.only(right: 8),
              enableAxisAnimation: true,
              primaryXAxis: DateTimeAxis(
                dateFormat: DateFormat('MMM d'),
                intervalType: DateTimeIntervalType.days,
                interval: 7,
                majorGridLines: const MajorGridLines(width: 0),
                axisLine: const AxisLine(width: 0),
                majorTickLines: const MajorTickLines(size: 0),
                labelStyle:
                    TextStyle(color: _DS.textSecondary(dark), fontSize: 9.5),
              ),
              primaryYAxis: NumericAxis(
                numberFormat: NumberFormat.compactCurrency(symbol: '₹'),
                majorGridLines: MajorGridLines(
                  color: _DS.border(dark),
                  width: 1,
                  dashArray: const [3, 3],
                ),
                axisLine: const AxisLine(width: 0),
                majorTickLines: const MajorTickLines(size: 0),
                labelStyle:
                    TextStyle(color: _DS.textSecondary(dark), fontSize: 9.5),
                opposedPosition: true,
              ),
              series: <CartesianSeries<_ChartPoint, DateTime>>[
                AreaSeries<_ChartPoint, DateTime>(
                  dataSource: chartData,
                  xValueMapper: (d, _) => d.date,
                  yValueMapper: (d, _) => d.close,
                  color: fillColor,
                  borderColor: lineColor,
                  borderWidth: 2,
                  animationDuration: 600,
                  gradient: LinearGradient(
                    colors: [fillColor, fillColor.withOpacity(0)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ],
              tooltipBehavior: TooltipBehavior(
                enable: true,
                builder: (data, point, series, pointIndex, seriesIndex) {
                  if (pointIndex < 0 || pointIndex >= chartData.length) {
                    return const SizedBox.shrink();
                  }
                  final pt = chartData[pointIndex];
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: dark ? const Color(0xFF1E2128) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _DS.border(dark)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(dark ? 0.4 : 0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('MMM d, yyyy').format(pt.date),
                          style: TextStyle(
                              color: _DS.textSecondary(dark), fontSize: 10.5),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '₹${pt.close.toStringAsFixed(2)}',
                          style: GoogleFonts.jetBrainsMono(
                            color: lineColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

        // ── View on TradingView button ────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: GestureDetector(
            onTap: () => _openTradingView(context),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: _DS.surface(dark),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _DS.border(dark)),
              ),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.candlestick_chart_rounded,
                    color: _DS.cyan, size: 16),
                const SizedBox(width: 8),
                Text('View on TradingView',
                    style: GoogleFonts.dmSans(
                        color: _DS.textPrimary(dark),
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(width: 6),
                Icon(Icons.open_in_new_rounded,
                    color: _DS.textTertiary(dark), size: 13),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _divider(bool dark) => Container(
      width: 1,
      height: 32,
      color: _DS.border(dark),
      margin: const EdgeInsets.symmetric(horizontal: 8));
}

// ─── OHLC Cell ────────────────────────────────────────────────────────────────
class _OhlcCell extends StatelessWidget {
  final String label;
  final double value;
  final bool dark;
  final Color? color;

  const _OhlcCell(
      {required this.label,
      required this.value,
      required this.dark,
      this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? _DS.textPrimary(dark);
    return Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: GoogleFonts.dmSans(
                color: _DS.textTertiary(dark),
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8)),
        const SizedBox(height: 3),
        Text('₹${value.toStringAsFixed(2)}',
            style: GoogleFonts.jetBrainsMono(
                color: c, fontSize: 11.5, fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}

// ─── L-H Progress Bar ─────────────────────────────────────────────────────────
class _LHProgressBar extends StatelessWidget {
  final double low, high, current, progress;
  final Color rangeColor;
  final String rangeLabel;
  final bool dark;

  const _LHProgressBar({
    required this.low,
    required this.high,
    required this.current,
    required this.progress,
    required this.rangeColor,
    required this.rangeLabel,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    final bearRed = dark ? const Color(0xFFEF4444) : const Color(0xFFDC2626);
    final bullGreen = dark ? const Color(0xFF22C55E) : const Color(0xFF16A34A);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Labels
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        // Low
        Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 6,
              height: 6,
              decoration:
                  BoxDecoration(color: bearRed, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text('L  ₹${low.toStringAsFixed(2)}',
              style: GoogleFonts.jetBrainsMono(
                  color: bearRed, fontSize: 10, fontWeight: FontWeight.w600)),
        ]),
        // Range label + current
        Column(children: [
          Text(rangeLabel,
              style: GoogleFonts.dmSans(
                  color: rangeColor,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700)),
          Text('₹${current.toStringAsFixed(2)}',
              style: GoogleFonts.jetBrainsMono(
                  color: rangeColor,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700)),
        ]),
        // High
        Row(mainAxisSize: MainAxisSize.min, children: [
          Text('H  ₹${high.toStringAsFixed(2)}',
              style: GoogleFonts.jetBrainsMono(
                  color: bullGreen, fontSize: 10, fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
          Container(
              width: 6,
              height: 6,
              decoration:
                  BoxDecoration(color: bullGreen, shape: BoxShape.circle)),
        ]),
      ]),
      const SizedBox(height: 8),
      // Bar
      LayoutBuilder(builder: (ctx, constraints) {
        const thumbSize = 14.0;
        final totalWidth = constraints.maxWidth;
        final thumbX = (progress * totalWidth)
            .clamp(thumbSize / 2, totalWidth - thumbSize / 2);

        return SizedBox(
          height: thumbSize + 4,
          child: Stack(clipBehavior: Clip.none, children: [
            // Track
            Positioned(
              top: (thumbSize + 4 - 7) / 2,
              left: 0,
              right: 0,
              child: Container(
                height: 7,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: LinearGradient(
                      colors: [bearRed, const Color(0xFFFACC15), bullGreen]),
                ),
              ),
            ),
            // Thumb
            Positioned(
              left: thumbX - thumbSize / 2,
              top: 2,
              child: Container(
                width: thumbSize,
                height: thumbSize,
                decoration: BoxDecoration(
                  color: rangeColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _DS.card(dark),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: rangeColor.withOpacity(.45),
                        blurRadius: 6,
                        offset: const Offset(0, 2)),
                  ],
                ),
              ),
            ),
          ]),
        );
      }),
    ]);
  }
}

// ─── Top Bar (loader / error) ─────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final bool dark;
  final String symbol;
  final Widget trailing;
  const _TopBar(
      {required this.dark, required this.symbol, required this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Row(children: [
          _BackBtn(dark: dark),
          const SizedBox(width: 12),
          Text(symbol,
              style: GoogleFonts.jetBrainsMono(
                  color: _DS.textSecondary(dark),
                  fontSize: 13,
                  letterSpacing: 2)),
          const Spacer(),
          trailing,
        ]),
      );
}

// ─── Arc Painter ──────────────────────────────────────────────────────────────
class _ArcPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  const _ArcPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    for (int i = 0; i < 3; i++) {
      paint.color = color.withOpacity(.7 - i * .2);
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
          i * math.pi * .66, math.pi * .4, false, paint);
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) => false;
}

// ─── Loading Row ──────────────────────────────────────────────────────────────
enum _RowState { pending, active, done }

class _LoadRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final _RowState state;
  final bool dark, isFirst, isLast;
  const _LoadRow({
    required this.icon,
    required this.label,
    required this.state,
    required this.dark,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color color;
    final Widget trailing;
    switch (state) {
      case _RowState.done:
        color = _DS.green;
        trailing = const Icon(Icons.check_rounded, color: _DS.green, size: 16);
      case _RowState.active:
        color = _DS.cyan;
        trailing = SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: _DS.cyan),
        );
      case _RowState.pending:
        color = _DS.textTertiary(dark);
        trailing = Container(
            width: 6,
            height: 6,
            decoration:
                BoxDecoration(shape: BoxShape.circle, color: _DS.border(dark)));
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: state == _RowState.active
          ? _DS.cyan.withOpacity(.04)
          : Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              color: state == _RowState.active
                  ? _DS.cyan.withOpacity(.12)
                  : state == _RowState.done
                      ? _DS.green.withOpacity(.08)
                      : _DS.surface(dark),
            ),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Text(label,
                  style: GoogleFonts.dmSans(
                      color: color,
                      fontSize: 13,
                      fontWeight: state == _RowState.active
                          ? FontWeight.w600
                          : FontWeight.w400))),
          trailing,
        ]),
      ),
    );
  }
}

// ─── Back Button ──────────────────────────────────────────────────────────────
class _BackBtn extends StatelessWidget {
  final bool dark;
  const _BackBtn({required this.dark});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => Navigator.of(context).maybePop(),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _DS.surface(dark),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: _DS.border(dark)),
          ),
          child: Icon(Icons.arrow_back_ios_new_rounded,
              size: 15, color: _DS.textPrimary(dark)),
        ),
      );
}

// ─── Section Header ───────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool dark;
  final Color? accent;
  const _SectionHeader(
      {required this.title,
      required this.icon,
      required this.dark,
      this.accent});
  @override
  Widget build(BuildContext context) {
    final c = accent ?? _DS.cyan;
    return Row(children: [
      Icon(icon, size: 14, color: c),
      const SizedBox(width: 7),
      Text(title.toUpperCase(),
          style: GoogleFonts.dmSans(
              color: _DS.textSecondary(dark),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5)),
    ]);
  }
}

// ─── Disclaimer ───────────────────────────────────────────────────────────────
class _DisclaimerBanner extends StatelessWidget {
  final bool dark;
  const _DisclaimerBanner({required this.dark});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _DS.amber.withOpacity(.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _DS.amber.withOpacity(.18)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.info_outline_rounded, color: _DS.amber, size: 14),
          const SizedBox(width: 10),
          Expanded(
              child: Text(
            'For educational purposes only. Not financial advice. Consult a SEBI-registered advisor before trading.',
            style: GoogleFonts.dmSans(
                color: _DS.amber.withOpacity(.9), fontSize: 11, height: 1.5),
          )),
        ]),
      );
}

// // ─── Hero Card ────────────────────────────────────────────────────────────────
// class _HeroCard extends StatelessWidget {
//   final StockAnalysis analysis;
//   final bool dark;
//   const _HeroCard({required this.analysis, required this.dark});

//   @override
//   Widget build(BuildContext context) {
//     final a = analysis;
//     final isUp = a.dayChangePct >= 0;
//     final sentimentColor = a.marketSentiment == 'Bullish'
//         ? _DS.green
//         : a.marketSentiment == 'Bearish'
//             ? _DS.red
//             : _DS.amber;
//     final changeColor = isUp ? _DS.green : _DS.red;

//     return Container(
//       decoration: BoxDecoration(
//         color: _DS.card(dark),
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: _DS.border(dark)),
//       ),
//       padding: const EdgeInsets.all(20),
//       child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//         Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
//           Expanded(
//               child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                 Text(a.companyName,
//                     style: GoogleFonts.dmSans(
//                         color: _DS.textSecondary(dark),
//                         fontSize: 12,
//                         letterSpacing: .3)),
//                 const SizedBox(height: 6),
//                 Text('₹${a.currentPrice.toStringAsFixed(2)}',
//                     style: GoogleFonts.jetBrainsMono(
//                         color: _DS.textPrimary(dark),
//                         fontSize: 32,
//                         fontWeight: FontWeight.w700,
//                         letterSpacing: -1)),
//                 const SizedBox(height: 6),
//                 Container(
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                   decoration: BoxDecoration(
//                     color: changeColor.withOpacity(.1),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Row(mainAxisSize: MainAxisSize.min, children: [
//                     Icon(
//                         isUp
//                             ? Icons.trending_up_rounded
//                             : Icons.trending_down_rounded,
//                         size: 13,
//                         color: changeColor),
//                     const SizedBox(width: 4),
//                     Text(
//                         '${isUp ? "+" : ""}${a.dayChangePct.toStringAsFixed(2)}%  today',
//                         style: GoogleFonts.dmSans(
//                             color: changeColor,
//                             fontSize: 12,
//                             fontWeight: FontWeight.w600)),
//                   ]),
//                 ),
//               ])),
//           const SizedBox(width: 12),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//             decoration: BoxDecoration(
//               color: sentimentColor.withOpacity(.08),
//               borderRadius: BorderRadius.circular(16),
//               border: Border.all(color: sentimentColor.withOpacity(.2)),
//             ),
//             child: Column(mainAxisSize: MainAxisSize.min, children: [
//               Text(a.sentimentEmoji, style: const TextStyle(fontSize: 26)),
//               const SizedBox(height: 5),
//               Text(a.marketSentiment,
//                   style: GoogleFonts.dmSans(
//                       color: sentimentColor,
//                       fontSize: 11,
//                       fontWeight: FontWeight.w700)),
//             ]),
//           ),
//         ]),
//         const SizedBox(height: 16),
//         Wrap(spacing: 6, runSpacing: 6, children: [
//           _Tag(label: a.timeframe, color: _DS.cyan),
//           _Tag(
//             label: '${a.confidence} Confidence',
//             color: a.confidence == 'High'
//                 ? _DS.green
//                 : a.confidence == 'Low'
//                     ? _DS.red
//                     : _DS.amber,
//           ),
//           if (a.cached) _Tag(label: '⚡ Cached', color: _DS.violet),
//         ]),
//       ]),
//     );
//   }
// }

// ─── One-liner Card ───────────────────────────────────────────────────────────
class _OneLinerCard extends StatelessWidget {
  final String text;
  final bool dark;
  const _OneLinerCard({required this.text, required this.dark});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_DS.cyan.withOpacity(.06), _DS.violet.withOpacity(.04)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _DS.cyan.withOpacity(.15)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.psychology_rounded, color: _DS.cyan, size: 18),
          const SizedBox(width: 12),
          Expanded(
              child: Text(text,
                  style: GoogleFonts.dmSans(
                      color: _DS.textPrimary(dark),
                      fontSize: 13.5,
                      height: 1.6))),
        ]),
      );
}

// ─── Screener Card ────────────────────────────────────────────────────────────
class _ScreenerCard extends StatelessWidget {
  final ScreenerAnalysis sa;
  final bool dark;
  const _ScreenerCard({required this.sa, required this.dark});

  @override
  Widget build(BuildContext context) {
    final total = sa.bullishCount + sa.bearishCount;
    if (total == 0) {
      return _EmptyState(dark: dark, message: 'No screener signals found');
    }
    final biasColor = sa.bullishCount > sa.bearishCount
        ? _DS.green
        : sa.bearishCount > sa.bullishCount
            ? _DS.red
            : _DS.amber;

    return Container(
      decoration: BoxDecoration(
        color: _DS.card(dark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: sa.strongSignal
                ? biasColor.withOpacity(.25)
                : _DS.border(dark)),
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            _StatPill(
                value: '${sa.bullishCount}',
                label: 'Bullish',
                color: _DS.green),
            const SizedBox(width: 8),
            _StatPill(
                value: '${sa.bearishCount}', label: 'Bearish', color: _DS.red),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: biasColor.withOpacity(.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: biasColor.withOpacity(.25)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (sa.strongSignal) ...[
                  Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle, color: biasColor)),
                  const SizedBox(width: 6),
                ],
                Text(sa.bias,
                    style: GoogleFonts.dmSans(
                        color: biasColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ]),
            ),
          ]),
        ),
        if (sa.summary.isNotEmpty) ...[
          Divider(height: 1, color: _DS.divider(dark)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Text(sa.summary,
                style: GoogleFonts.dmSans(
                    color: _DS.textSecondary(dark), fontSize: 12, height: 1.5)),
          ),
        ],
        if (sa.bullish.isNotEmpty) ...[
          Divider(height: 1, color: _DS.divider(dark)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.arrow_upward_rounded,
                    color: _DS.green, size: 12),
                const SizedBox(width: 5),
                Text('BULLISH',
                    style: GoogleFonts.dmSans(
                        color: _DS.green,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1)),
              ]),
              const SizedBox(height: 8),
              Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: sa.bullish
                      .map((s) => _SignalChip(
                          name: s.name, tf: s.timeframe, color: _DS.green))
                      .toList()),
            ]),
          ),
        ],
        if (sa.bearish.isNotEmpty) ...[
          Divider(height: 1, color: _DS.divider(dark)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.arrow_downward_rounded,
                    color: _DS.red, size: 12),
                const SizedBox(width: 5),
                Text('BEARISH',
                    style: GoogleFonts.dmSans(
                        color: _DS.red,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1)),
              ]),
              const SizedBox(height: 8),
              Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: sa.bearish
                      .map((s) => _SignalChip(
                          name: s.name, tf: s.timeframe, color: _DS.red))
                      .toList()),
            ]),
          ),
        ],
      ]),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String value, label;
  final Color color;
  const _StatPill(
      {required this.value, required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(.18)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(value,
              style: GoogleFonts.jetBrainsMono(
                  color: color, fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.dmSans(
                  color: color.withOpacity(.7), fontSize: 11)),
        ]),
      );
}

class _SignalChip extends StatelessWidget {
  final String name, tf;
  final Color color;
  const _SignalChip(
      {required this.name, required this.tf, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(.2)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(name,
              style: GoogleFonts.dmSans(
                  color: color, fontSize: 11, fontWeight: FontWeight.w600)),
          if (tf.isNotEmpty) ...[
            const SizedBox(width: 5),
            Container(width: 1, height: 10, color: color.withOpacity(.25)),
            const SizedBox(width: 5),
            Text(tf,
                style: GoogleFonts.jetBrainsMono(
                    color: color.withOpacity(.65), fontSize: 9)),
          ],
        ]),
      );
}

// ─── Alert Card ───────────────────────────────────────────────────────────────
class _AlertCard extends StatelessWidget {
  final AlertSummary alert;
  final bool dark;
  const _AlertCard({required this.alert, required this.dark});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _DS.card(dark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: alert.proximityNotes.isNotEmpty
                ? _DS.amber.withOpacity(.25)
                : _DS.border(dark)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _StatPill(
              value: '${alert.triggeredCount}',
              label: 'Triggered',
              color: _DS.red),
          const SizedBox(width: 8),
          _StatPill(
              value: '${alert.pendingCount}',
              label: 'Pending',
              color: _DS.amber),
        ]),
        if (alert.proximityNotes.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...alert.proximityNotes.map((n) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: _DS.amber, size: 14),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(n,
                              style: GoogleFonts.dmSans(
                                  color: _DS.amber.withOpacity(.9),
                                  fontSize: 12,
                                  height: 1.5))),
                    ]),
              )),
        ],
        if (alert.summary.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(alert.summary,
              style: GoogleFonts.dmSans(
                  color: _DS.textSecondary(dark), fontSize: 12, height: 1.5)),
        ],
      ]),
    );
  }
}

// ─── Entry Card ───────────────────────────────────────────────────────────────
class _EntryCard extends StatelessWidget {
  final EntryOpportunity entry;
  final bool dark;
  final int index;
  const _EntryCard(
      {required this.entry, required this.dark, required this.index});

  Color get _tc => entry.type == 'Aggressive'
      ? _DS.red
      : entry.type == 'Conservative'
          ? _DS.green
          : _DS.cyan;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _DS.card(dark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _DS.border(dark)),
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _tc.withOpacity(.05),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(children: [
            _Tag(label: entry.type, color: _tc),
            const Spacer(),
            Text('R:R  ${entry.riskReward}',
                style: GoogleFonts.jetBrainsMono(
                    color: _DS.textSecondary(dark),
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
        Divider(height: 1, color: _DS.divider(dark)),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            _LevelRow(
                label: 'Entry Zone',
                value: entry.entryZone,
                color: _DS.textPrimary(dark),
                dark: dark),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                  child: _LevelBox(
                      label: 'Stop Loss',
                      value: '₹${entry.stopLoss.toStringAsFixed(2)}',
                      color: _DS.red,
                      dark: dark)),
              const SizedBox(width: 8),
              Expanded(
                  child: _LevelBox(
                      label: 'Target 1',
                      value: '₹${entry.target1.toStringAsFixed(2)}',
                      color: _DS.green,
                      dark: dark)),
              const SizedBox(width: 8),
              Expanded(
                  child: _LevelBox(
                      label: 'Target 2',
                      value: '₹${entry.target2.toStringAsFixed(2)}',
                      color: _DS.green.withOpacity(.6),
                      dark: dark)),
            ]),
            const SizedBox(height: 12),
            Text(entry.rationale,
                style: GoogleFonts.dmSans(
                    color: _DS.textSecondary(dark),
                    fontSize: 13,
                    height: 1.55)),
          ]),
        ),
      ]),
    );
  }
}

class _LevelRow extends StatelessWidget {
  final String label, value;
  final Color color;
  final bool dark;
  const _LevelRow(
      {required this.label,
      required this.value,
      required this.color,
      required this.dark});
  @override
  Widget build(BuildContext context) => Row(children: [
        Text(label,
            style: GoogleFonts.dmSans(
                color: _DS.textSecondary(dark), fontSize: 12)),
        const Spacer(),
        Text(value,
            style: GoogleFonts.jetBrainsMono(
                color: color, fontSize: 13, fontWeight: FontWeight.w600)),
      ]);
}

class _LevelBox extends StatelessWidget {
  final String label, value;
  final Color color;
  final bool dark;
  const _LevelBox(
      {required this.label,
      required this.value,
      required this.color,
      required this.dark});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(.15)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: GoogleFonts.dmSans(
                  color: color.withOpacity(.6),
                  fontSize: 9,
                  letterSpacing: .5)),
          const SizedBox(height: 3),
          Text(value,
              style: GoogleFonts.jetBrainsMono(
                  color: color, fontSize: 12, fontWeight: FontWeight.w700)),
        ]),
      );
}

// ─── S&R Card ─────────────────────────────────────────────────────────────────
class _SRCard extends StatelessWidget {
  final List<PriceLevel> supports, resistances;
  final bool dark;
  const _SRCard(
      {required this.supports, required this.resistances, required this.dark});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: _DS.card(dark),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _DS.border(dark)),
        ),
        child: Column(children: [
          _SRSection(
              levels: supports, label: 'SUPPORT', color: _DS.green, dark: dark),
          Divider(height: 1, color: _DS.divider(dark)),
          _SRSection(
              levels: resistances,
              label: 'RESISTANCE',
              color: _DS.red,
              dark: dark),
        ]),
      );
}

class _SRSection extends StatelessWidget {
  final List<PriceLevel> levels;
  final String label;
  final Color color;
  final bool dark;
  const _SRSection(
      {required this.levels,
      required this.label,
      required this.color,
      required this.dark});

  double _opacity(String s) => s == 'Strong'
      ? 1.0
      : s == 'Moderate'
          ? .6
          : .35;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(
                label == 'SUPPORT'
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: 12,
                color: color),
            const SizedBox(width: 5),
            Text(label,
                style: GoogleFonts.dmSans(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          ...levels.map((l) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  Container(
                    width: 3,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withOpacity(_opacity(l.strength)),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('₹${l.price.toStringAsFixed(2)}',
                            style: GoogleFonts.jetBrainsMono(
                                color: _DS.textPrimary(dark),
                                fontSize: 15,
                                fontWeight: FontWeight.w700)),
                        Text(l.strength,
                            style: GoogleFonts.dmSans(
                                color: color.withOpacity(.6), fontSize: 11)),
                      ]),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(l.note,
                          style: GoogleFonts.dmSans(
                              color: _DS.textSecondary(dark),
                              fontSize: 12,
                              height: 1.4))),
                ]),
              )),
        ]),
      );
}

// ─── Observations ─────────────────────────────────────────────────────────────
class _ObsCard extends StatelessWidget {
  final List<String> items;
  final bool dark;
  const _ObsCard({required this.items, required this.dark});
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: _DS.card(dark),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _DS.border(dark)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
            children: items
                .asMap()
                .entries
                .map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _DS.cyan.withOpacity(.1),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Text('${e.key + 1}',
                                  style: GoogleFonts.jetBrainsMono(
                                      color: _DS.cyan,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Text(e.value,
                                    style: GoogleFonts.dmSans(
                                        color: _DS.textPrimary(dark),
                                        fontSize: 13,
                                        height: 1.55))),
                          ]),
                    ))
                .toList()),
      );
}

// ─── Text Card ────────────────────────────────────────────────────────────────
class _TextCard extends StatelessWidget {
  final String content;
  final IconData icon;
  final bool dark;
  final String? label;
  const _TextCard(
      {required this.content,
      required this.icon,
      required this.dark,
      this.label});
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: _DS.card(dark),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _DS.border(dark)),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: _DS.cyan, size: 16),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                if (label != null) ...[
                  Text(label!,
                      style: GoogleFonts.dmSans(
                          color: _DS.textTertiary(dark),
                          fontSize: 10,
                          letterSpacing: .8)),
                  const SizedBox(height: 4),
                ],
                Text(content,
                    style: GoogleFonts.dmSans(
                        color: _DS.textPrimary(dark),
                        fontSize: 13,
                        height: 1.6)),
              ])),
        ]),
      );
}

// ─── Risk Card ────────────────────────────────────────────────────────────────
class _RiskCard extends StatelessWidget {
  final List<String> risks;
  final bool dark;
  const _RiskCard({required this.risks, required this.dark});
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: _DS.card(dark),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _DS.red.withOpacity(.15)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
            children: risks
                .map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _DS.red.withOpacity(.1)),
                              child: const Icon(Icons.priority_high_rounded,
                                  color: _DS.red, size: 10),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Text(r,
                                    style: GoogleFonts.dmSans(
                                        color: _DS.textPrimary(dark),
                                        fontSize: 13,
                                        height: 1.55))),
                          ]),
                    ))
                .toList()),
      );
}

// ─── Fetch Status Card ────────────────────────────────────────────────────────
class _FetchStatusCard extends StatelessWidget {
  final List<FetchCheck> checks;
  final int found, total;
  final bool dark, expanded;
  final VoidCallback onToggle;
  const _FetchStatusCard({
    required this.checks,
    required this.found,
    required this.total,
    required this.dark,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = total > 0 ? found / total : 0.0;
    final barColor = ratio == 1
        ? _DS.green
        : ratio > 0.5
            ? _DS.amber
            : _DS.red;

    return Container(
      decoration: BoxDecoration(
        color: _DS.card(dark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _DS.border(dark)),
      ),
      child: Column(children: [
        GestureDetector(
          onTap: onToggle,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  color: barColor.withOpacity(.1),
                ),
                child: Icon(
                    ratio == 1
                        ? Icons.check_rounded
                        : Icons.warning_amber_rounded,
                    color: barColor,
                    size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('$found of $total sources available',
                        style: GoogleFonts.dmSans(
                            color: _DS.textPrimary(dark),
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: ratio,
                        backgroundColor: barColor.withOpacity(.1),
                        valueColor: AlwaysStoppedAnimation(barColor),
                        minHeight: 3,
                      ),
                    ),
                  ])),
              const SizedBox(width: 12),
              Icon(
                  expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: _DS.textSecondary(dark),
                  size: 20),
            ]),
          ),
        ),
        if (expanded) ...[
          Divider(height: 1, color: _DS.divider(dark)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
                children: checks
                    .map((c) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(children: [
                            Icon(
                                c.found
                                    ? Icons.check_circle_rounded
                                    : Icons.cancel_rounded,
                                color: c.found ? _DS.green : _DS.red,
                                size: 14),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Text(c.source,
                                    style: GoogleFonts.jetBrainsMono(
                                        color: _DS.textPrimary(dark),
                                        fontSize: 11))),
                            if (c.count > 0)
                              Text('${c.count} rows',
                                  style: GoogleFonts.dmSans(
                                      color: _DS.textSecondary(dark),
                                      fontSize: 11)),
                            if (!c.found)
                              Text('missing',
                                  style: GoogleFonts.dmSans(
                                      color: _DS.red, fontSize: 11)),
                          ]),
                        ))
                    .toList()),
          ),
        ],
      ]),
    );
  }
}

// ─── Meta Row ─────────────────────────────────────────────────────────────────
class _MetaRow extends StatelessWidget {
  final StockAnalysis analysis;
  final VoidCallback onRefresh;
  final bool dark;
  const _MetaRow(
      {required this.analysis, required this.onRefresh, required this.dark});

  @override
  Widget build(BuildContext context) {
    final a = analysis;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _DS.card(dark),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _DS.border(dark)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _MetaItem(
              k: 'Source', v: a.cached ? '⚡ Cache' : '🤖 Live AI', dark: dark),
          const SizedBox(width: 24),
          _MetaItem(
              k: 'TTL',
              v: a.ttlSeconds != null ? '${a.ttlSeconds}s' : '—',
              dark: dark),
          const SizedBox(width: 24),
          _MetaItem(k: 'Timeframe', v: a.timeframe, dark: dark),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Icon(Icons.access_time_rounded,
              color: _DS.textTertiary(dark), size: 12),
          const SizedBox(width: 6),
          Text('Updated  ${a.lastUpdated}',
              style: GoogleFonts.jetBrainsMono(
                  color: _DS.textTertiary(dark), fontSize: 10)),
        ]),
      ]),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final String k, v;
  final bool dark;
  const _MetaItem({required this.k, required this.v, required this.dark});
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(k,
            style: GoogleFonts.dmSans(
                color: _DS.textTertiary(dark),
                fontSize: 10,
                letterSpacing: .5)),
        const SizedBox(height: 2),
        Text(v,
            style: GoogleFonts.dmSans(
                color: _DS.textPrimary(dark),
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      ]);
}

// ─── Empty State ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool dark;
  final String message;
  const _EmptyState({required this.dark, required this.message});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _DS.card(dark),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _DS.border(dark)),
        ),
        child: Row(children: [
          Icon(Icons.search_off_rounded,
              color: _DS.textTertiary(dark), size: 18),
          const SizedBox(width: 10),
          Text(message,
              style: GoogleFonts.dmSans(
                  color: _DS.textSecondary(dark), fontSize: 13)),
        ]),
      );
}

// ─── Reusable Widgets ─────────────────────────────────────────────────────────
class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(.22)),
        ),
        child: Text(label,
            style: GoogleFonts.dmSans(
                color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      );
}

class _GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _GradientButton(
      {required this.label, required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF00D4FF), Color(0xFF0055FF)]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: _DS.cyan.withOpacity(.2),
                  blurRadius: 16,
                  offset: const Offset(0, 5))
            ],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(label,
                style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
          ]),
        ),
      );
}
