import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:optionxi/Helpers/browser_lite.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

// ─── API ──────────────────────────────────────────────────────────────────────
String get kApiBase => dotenv.env['AI_NIFTYSUMMARY_URL']!;

// ─── Design System (Theme-aware) ─────────────────────────────────────────────
class DS {
  // Semantic colours — same in both modes
  static const green = Color(0xFF00A86B);
  static const red = Color(0xFFE5303F);
  static const amber = Color(0xFFE8920D);
  static const blue = Color(0xFF2563EB);
  static const violet = Color(0xFF7C3AED);
  static const teal = Color(0xFF0891B2);
  static const orange = Color(0xFFEA580C);

  // ── Light palette ─────────────────────────────────────────────────────────
  static const _lBg = Color(0xFFF8F9FB);
  static const _lSurface = Color(0xFFFFFFFF);
  static const _lSurfaceAlt = Color(0xFFF0F2F7);
  static const _lBorder = Color(0xFFE4E8F0);
  static const _lDivider = Color(0xFFEEF1F7);
  static const _lTextPrimary = Color(0xFF0D1421);
  static const _lTextSec = Color(0xFF5A6480);
  static const _lTextTert = Color(0xFF9AA3BB);

  // ── Dark palette ──────────────────────────────────────────────────────────
  static const _dBg = Color(0xFF0F1117);
  static const _dSurface = Color(0xFF1A1D27);
  static const _dSurfaceAlt = Color(0xFF222536);
  static const _dBorder = Color(0xFF2E3348);
  static const _dDivider = Color(0xFF252840);
  static const _dTextPrimary = Color(0xFFEDF0F7);
  static const _dTextSec = Color(0xFF8A93B0);
  static const _dTextTert = Color(0xFF4E5670);

  // ── Context-aware getters ─────────────────────────────────────────────────
  static bool _isDark(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark;

  static Color bg(BuildContext ctx) => _isDark(ctx) ? _dBg : _lBg;
  static Color surface(BuildContext ctx) =>
      _isDark(ctx) ? _dSurface : _lSurface;
  static Color surfaceAlt(BuildContext ctx) =>
      _isDark(ctx) ? _dSurfaceAlt : _lSurfaceAlt;
  static Color border(BuildContext ctx) => _isDark(ctx) ? _dBorder : _lBorder;
  static Color divider(BuildContext ctx) =>
      _isDark(ctx) ? _dDivider : _lDivider;
  static Color textPrimary(BuildContext ctx) =>
      _isDark(ctx) ? _dTextPrimary : _lTextPrimary;
  static Color textSecondary(BuildContext ctx) =>
      _isDark(ctx) ? _dTextSec : _lTextSec;
  static Color textTertiary(BuildContext ctx) =>
      _isDark(ctx) ? _dTextTert : _lTextTert;

  // ── Semantic helpers ──────────────────────────────────────────────────────
  static Color confidence(String c) {
    switch (c.toLowerCase()) {
      case 'strong':
        return green;
      case 'moderate':
        return amber;
      case 'weak':
        return orange;
      case 'avoid':
        return red;
      default:
        return const Color(0xFF9AA3BB);
    }
  }

  static Color freshness(String label) {
    switch (label) {
      case 'fresh':
        return green;
      case 'aging':
        return amber;
      case 'stale':
        return red;
      default:
        return const Color(0xFF9AA3BB);
    }
  }

  static Color sentiment(String s) {
    if (s == 'Bullish') return green;
    if (s == 'Bearish') return red;
    return amber;
  }
}

// ─── Loading steps ────────────────────────────────────────────────────────────
const _kSteps = [
  (
    icon: Icons.link_rounded,
    label: 'Connecting',
    sub: 'Market data & version check'
  ),
  (
    icon: Icons.candlestick_chart_rounded,
    label: 'Nifty 5-min data',
    sub: 'Yahoo Finance live candles'
  ),
  (
    icon: Icons.shield_rounded,
    label: 'VIX Analysis',
    sub: 'India VIX volatility index'
  ),
  (
    icon: Icons.hub_rounded,
    label: 'ATLAS Indicators',
    sub: 'Advancing · Declining · Probability'
  ),
  (
    icon: Icons.bubble_chart_rounded,
    label: 'Bollinger Bands',
    sub: 'Signal freshness check'
  ),
  (
    icon: Icons.bar_chart_rounded,
    label: 'Chartink Signals',
    sub: 'Probability scores'
  ),
  (
    icon: Icons.show_chart_rounded,
    label: 'Live Indices',
    sub: 'Nifty · BankNifty · VIX · IT · Midcap'
  ),
  (
    icon: Icons.psychology_rounded,
    label: 'AI Analysis',
    sub: 'LLaMA 4 Scout generating insights'
  ),
];

// ─── Chart model ──────────────────────────────────────────────────────────────
class CandlePoint {
  final DateTime time;
  final double open, high, low, close;
  final int volume;
  const CandlePoint({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });
  factory CandlePoint.fromJson(Map<String, dynamic> j) => CandlePoint(
        time: DateTime.parse(j['timestamp'] as String),
        open: (j['open'] as num).toDouble(),
        high: (j['high'] as num).toDouble(),
        low: (j['low'] as num).toDouble(),
        close: (j['close'] as num).toDouble(),
        volume: (j['volume'] as num).toInt(),
      );
}

// ─── Data model ───────────────────────────────────────────────────────────────
class NiftySummary {
  final bool cached;
  final int? ttlSeconds;
  final bool marketOpen;
  final String lastUpdated;

  final double niftyLtp, niftyDayChangePct;

  final String marketSentiment, sentimentEmoji, oneLiner;
  final String shortTermTrend, intradayBias, confidence, timeframe;
  final double probabilityScore;
  final List<double> support, resistance;
  final Map<String, dynamic> tradeIdea;
  final List<String> keyObservations, riskFactors;
  final String atlasInterpretation, bollingerInterpretation;
  final String chartinkInterpretation, nifty5minInterpretation;
  final String vixInterpretation;
  final String advancingDecliningRatio;

  final Map<String, dynamic> bollingerAnalysis, atlasAnalysis, chartinkAnalysis;
  final Map<String, dynamic> nifty5minSummary;
  final Map<String, dynamic> vixAnalysis, vixSummary, signalVerdict;

  final List<Map<String, dynamic>> liveIndices, liveFno;
  final List<CandlePoint> candles, vixCandles;

  const NiftySummary({
    required this.cached,
    this.ttlSeconds,
    required this.marketOpen,
    required this.lastUpdated,
    required this.niftyLtp,
    required this.niftyDayChangePct,
    required this.marketSentiment,
    required this.sentimentEmoji,
    required this.oneLiner,
    required this.shortTermTrend,
    required this.intradayBias,
    required this.confidence,
    required this.timeframe,
    required this.probabilityScore,
    required this.support,
    required this.resistance,
    required this.tradeIdea,
    required this.keyObservations,
    required this.riskFactors,
    required this.atlasInterpretation,
    required this.bollingerInterpretation,
    required this.chartinkInterpretation,
    required this.nifty5minInterpretation,
    required this.vixInterpretation,
    required this.advancingDecliningRatio,
    required this.bollingerAnalysis,
    required this.atlasAnalysis,
    required this.chartinkAnalysis,
    required this.nifty5minSummary,
    required this.vixAnalysis,
    required this.vixSummary,
    required this.signalVerdict,
    required this.liveIndices,
    required this.liveFno,
    required this.candles,
    required this.vixCandles,
  });

  factory NiftySummary.fromJson(Map<String, dynamic> r) {
    final d = r['data'] as Map<String, dynamic>;
    final kl = (d['key_levels'] as Map<String, dynamic>?) ?? {};
    final sup = List<double>.from(
        (kl['support'] as List? ?? []).map((e) => (e as num).toDouble()));
    final res = List<double>.from(
        (kl['resistance'] as List? ?? []).map((e) => (e as num).toDouble()));

    List<CandlePoint> parseCandles(List raw) => raw
        .map((e) => CandlePoint.fromJson(e as Map<String, dynamic>))
        .toList();

    return NiftySummary(
      cached: r['cached'] ?? false,
      ttlSeconds: r['ttl_seconds'] as int?,
      marketOpen: r['market_open'] ?? false,
      lastUpdated: d['last_updated'] ?? '',
      niftyLtp: (d['nifty_ltp'] ?? 0).toDouble(),
      niftyDayChangePct: (d['nifty_day_change_pct'] ?? 0).toDouble(),
      marketSentiment: d['market_sentiment'] ?? 'Neutral',
      sentimentEmoji: d['sentiment_emoji'] ?? '🟡',
      oneLiner: d['one_liner'] ?? '',
      shortTermTrend: d['short_term_trend'] ?? 'Sideways',
      intradayBias: d['intraday_bias'] ?? 'Neutral',
      confidence: d['confidence'] ?? 'Low',
      timeframe: d['timeframe'] ?? '',
      probabilityScore: (d['probability_score'] ?? 0).toDouble(),
      support: sup,
      resistance: res,
      tradeIdea: (d['trade_idea'] as Map<String, dynamic>?) ?? {},
      keyObservations: List<String>.from(d['key_observations'] ?? []),
      riskFactors: List<String>.from(d['risk_factors'] ?? []),
      atlasInterpretation: d['atlas_interpretation'] ?? '',
      bollingerInterpretation: d['bollinger_interpretation'] ?? '',
      chartinkInterpretation: d['chartink_interpretation'] ?? '',
      nifty5minInterpretation: d['nifty5min_interpretation'] ?? '',
      vixInterpretation: d['vix_interpretation'] ?? '',
      advancingDecliningRatio: d['advancing_declining_ratio'] ?? '—',
      bollingerAnalysis:
          (r['bollinger_analysis'] as Map<String, dynamic>?) ?? {},
      atlasAnalysis: (r['atlas_analysis'] as Map<String, dynamic>?) ?? {},
      chartinkAnalysis: (r['chartink_analysis'] as Map<String, dynamic>?) ?? {},
      nifty5minSummary:
          (r['nifty_5min_summary'] as Map<String, dynamic>?) ?? {},
      vixAnalysis: (r['vix_analysis'] as Map<String, dynamic>?) ?? {},
      vixSummary: (r['vix_summary'] as Map<String, dynamic>?) ?? {},
      signalVerdict: (r['signal_verdict'] as Map<String, dynamic>?) ?? {},
      liveIndices:
          List<Map<String, dynamic>>.from(r['live_nifty_indices'] ?? []),
      liveFno: List<Map<String, dynamic>>.from(r['live_fno'] ?? []),
      candles: parseCandles(r['nifty_5min_candles'] as List? ?? []),
      vixCandles: parseCandles(r['vix_5min_candles'] as List? ?? []),
    );
  }
}

// ─── Page ─────────────────────────────────────────────────────────────────────
class NiftyAiSummaryPage extends StatefulWidget {
  const NiftyAiSummaryPage({super.key});
  @override
  State<NiftyAiSummaryPage> createState() => _NiftyAiSummaryPageState();
}

class _NiftyAiSummaryPageState extends State<NiftyAiSummaryPage>
    with TickerProviderStateMixin {
  NiftySummary? _data;
  bool _loading = true;
  String? _error;
  int _stepIndex = 0;

  // Layman Simplification States
  bool _isAdvancedMode = false;
  int _advancedTabIndex = 0;

  late AnimationController _spinCtrl;
  late AnimationController _stepCtrl;
  late AnimationController _contentCtrl;
  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;
  late Animation<double> _stepFade;

  @override
  void initState() {
    super.initState();
    _spinCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat();
    _stepCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _contentCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _contentFade = CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut);
    _contentSlide = Tween(begin: const Offset(0, .035), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOutCubic));
    _stepFade = CurvedAnimation(parent: _stepCtrl, curve: Curves.easeOut);
    _load();
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    _stepCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  void _step(int i) {
    if (!mounted) return;
    _stepCtrl.forward(from: 0);
    setState(() => _stepIndex = i);
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
      _stepIndex = 0;
    });

    for (int i = 1; i < _kSteps.length - 1; i++) {
      await Future.delayed(const Duration(milliseconds: 420));
      _step(i);
    }

    try {
      final res = await http
          .get(Uri.parse('$kApiBase/nifty-summary'))
          .timeout(const Duration(seconds: 75));

      _step(_kSteps.length - 1);
      await Future.delayed(const Duration(milliseconds: 380));

      if (!mounted) return;
      if (res.statusCode == 200) {
        setState(() {
          _data = NiftySummary.fromJson(
              jsonDecode(res.body) as Map<String, dynamic>);
          _loading = false;
        });
        _contentCtrl.forward(from: 0);
      } else {
        final b = jsonDecode(res.body) as Map<String, dynamic>;
        setState(() {
          _error = b['detail']?.toString() ?? 'Server error ${res.statusCode}';
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

  // ── Bottom Sheet Explanation helper ──────────────────────────────────────────
  void _showExplanationSheet(BuildContext context, String title,
      String description, IconData icon, Color color) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: DS.surface(ctx),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: DS.border(ctx)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(isDark ? .4 : .1),
                  blurRadius: 20,
                  offset: const Offset(0, 10)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: DS.border(ctx),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  color: DS.textPrimary(ctx),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                description,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  color: DS.textSecondary(ctx),
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: TextButton.styleFrom(
                    backgroundColor: DS.surfaceAlt(ctx),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    'Got it',
                    style: GoogleFonts.dmSans(
                      color: DS.textPrimary(ctx),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: DS.bg(context),
        body: SafeArea(
          child: _loading
              ? _loader()
              : _error != null
                  ? _errorView()
                  : _content(),
        ),
      ),
    );
  }

  // ── Loader ───────────────────────────────────────────────────────────────────
  Widget _loader() {
    final step = _kSteps[_stepIndex.clamp(0, _kSteps.length - 1)];
    final pct = (_stepIndex + 1) / _kSteps.length;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(children: [
      _AppBar(title: 'Nifty AI Summary', onRefresh: null),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(children: [
            const SizedBox(height: 32),
            // Spinner
            SizedBox(
              width: 120,
              height: 120,
              child: AnimatedBuilder(
                animation: _spinCtrl,
                builder: (_, __) =>
                    Stack(alignment: Alignment.center, children: [
                  Transform.rotate(
                    angle: _spinCtrl.value * 2 * math.pi,
                    child: CustomPaint(
                      size: const Size(120, 120),
                      painter: _RingPainter(
                          color: DS.blue, strokeWidth: 2.5, dashFraction: .35),
                    ),
                  ),
                  Transform.rotate(
                    angle: -_spinCtrl.value * 2 * math.pi * .6,
                    child: CustomPaint(
                      size: const Size(84, 84),
                      painter: _RingPainter(
                          color: DS.violet,
                          strokeWidth: 1.5,
                          dashFraction: .45),
                    ),
                  ),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: DS.surface(context),
                      border: Border.all(color: DS.border(context), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                            color: DS.blue.withOpacity(isDark ? .15 : .08),
                            blurRadius: 16),
                      ],
                    ),
                    child: Icon(step.icon, color: DS.blue, size: 22),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 28),
            FadeTransition(
              opacity: _stepFade,
              child: Column(children: [
                Text('NIFTY 50 AI',
                    style: GoogleFonts.jetBrainsMono(
                        color: DS.blue,
                        fontSize: 10,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Text(step.label,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                        color: DS.textPrimary(context),
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        height: 1.2)),
                const SizedBox(height: 5),
                Text(step.sub,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                        color: DS.textSecondary(context),
                        fontSize: 13,
                        height: 1.5)),
              ]),
            ),
            const SizedBox(height: 28),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 3,
                backgroundColor: DS.border(context),
                valueColor: const AlwaysStoppedAnimation(DS.blue),
              ),
            ),
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('${_stepIndex + 1} of ${_kSteps.length}',
                  style: GoogleFonts.jetBrainsMono(
                      color: DS.textTertiary(context), fontSize: 10)),
              Text('${(pct * 100).round()}%',
                  style: GoogleFonts.jetBrainsMono(
                      color: DS.blue,
                      fontSize: 10,
                      fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 24),
            // Step list card
            Container(
              decoration: BoxDecoration(
                color: DS.surface(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: DS.border(context)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(isDark ? .25 : .04),
                      blurRadius: 12,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: List.generate(_kSteps.length, (i) {
                  final state = i < _stepIndex
                      ? 0
                      : i == _stepIndex
                          ? 1
                          : 2;
                  final c = state == 0
                      ? DS.green
                      : state == 1
                          ? DS.blue
                          : DS.textTertiary(context);
                  return Column(children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 11),
                      child: Row(children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: c.withOpacity(.10),
                          ),
                          child: Icon(_kSteps[i].icon, size: 14, color: c),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(_kSteps[i].label,
                              style: GoogleFonts.dmSans(
                                  color: c,
                                  fontSize: 13,
                                  fontWeight: state == 1
                                      ? FontWeight.w600
                                      : FontWeight.w400)),
                        ),
                        if (state == 0)
                          const Icon(Icons.check_rounded,
                              color: DS.green, size: 15)
                        else if (state == 1)
                          SizedBox(
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(
                                  strokeWidth: 1.8, color: DS.blue))
                        else
                          Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: DS.border(context))),
                      ]),
                    ),
                    if (i < _kSteps.length - 1)
                      Divider(
                          height: 1,
                          indent: 58,
                          endIndent: 16,
                          color: DS.divider(context)),
                  ]);
                }),
              ),
            ),
            const SizedBox(height: 32),
          ]),
        ),
      ),
    ]);
  }

  // ── Error ────────────────────────────────────────────────────────────────────
  Widget _errorView() => Column(children: [
        _AppBar(title: 'Nifty AI Summary', onRefresh: null),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: DS.red.withOpacity(.08),
                    border: Border.all(color: DS.red.withOpacity(.2)),
                  ),
                  child: const Icon(Icons.error_outline_rounded,
                      color: DS.red, size: 30),
                ),
                const SizedBox(height: 20),
                Text('Could not load market data',
                    style: GoogleFonts.dmSans(
                        color: DS.textPrimary(context),
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('Check your connection and try again.',
                    style: GoogleFonts.dmSans(
                        color: DS.textSecondary(context), fontSize: 14)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: DS.surfaceAlt(context),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: DS.border(context)),
                  ),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.terminal_rounded,
                            size: 12, color: DS.textSecondary(context)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_error!,
                              style: GoogleFonts.jetBrainsMono(
                                  color: DS.textSecondary(context),
                                  fontSize: 10.5,
                                  height: 1.6)),
                        ),
                      ]),
                ),
                const SizedBox(height: 24),
                _PrimaryButton(
                    label: 'Try Again',
                    icon: Icons.refresh_rounded,
                    onTap: _load),
              ]),
            ),
          ),
        ),
      ]);

  // ── Mode Toggle Widget (Simple vs Advanced) ──────────────────────────────────
  Widget _buildModeToggle() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: DS.surfaceAlt(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DS.border(context)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isAdvancedMode = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: !_isAdvancedMode
                      ? DS.surface(context)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: !_isAdvancedMode
                      ? [
                          BoxShadow(
                              color:
                                  Colors.black.withOpacity(isDark ? .15 : .05),
                              blurRadius: 4,
                              offset: const Offset(0, 2))
                        ]
                      : [],
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bolt,
                        size: 14,
                        color: !_isAdvancedMode
                            ? DS.blue
                            : DS.textSecondary(context)),
                    const SizedBox(width: 6),
                    Text(
                      'Simple (Layman)',
                      style: GoogleFonts.dmSans(
                        color: !_isAdvancedMode
                            ? DS.blue
                            : DS.textSecondary(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isAdvancedMode = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _isAdvancedMode
                      ? DS.surface(context)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _isAdvancedMode
                      ? [
                          BoxShadow(
                              color:
                                  Colors.black.withOpacity(isDark ? .15 : .05),
                              blurRadius: 4,
                              offset: const Offset(0, 2))
                        ]
                      : [],
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.analytics_outlined,
                        size: 14,
                        color: _isAdvancedMode
                            ? DS.blue
                            : DS.textSecondary(context)),
                    const SizedBox(width: 6),
                    Text(
                      'Advanced (Full)',
                      style: GoogleFonts.dmSans(
                        color: _isAdvancedMode
                            ? DS.blue
                            : DS.textSecondary(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Redesigned Advanced Segmented Tabs ───────────────────────────────────────
  Widget _buildAdvancedTabs() {
    final tabs = [
      (icon: Icons.stacked_line_chart, label: 'Charts'),
      (icon: Icons.settings_suggest_rounded, label: 'Algos'),
      (icon: Icons.assignment_rounded, label: 'Levels')
    ];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 14),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: DS.surfaceAlt(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DS.border(context)),
      ),
      child: Row(
        children: List.generate(tabs.length, (idx) {
          final isSelected = _advancedTabIndex == idx;
          final color = isSelected ? DS.blue : DS.textSecondary(context);

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _advancedTabIndex = idx),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? DS.surface(context) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                              color:
                                  Colors.black.withOpacity(isDark ? .15 : .05),
                              blurRadius: 4,
                              offset: const Offset(0, 2))
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(tabs[idx].icon, size: 14, color: color),
                    const SizedBox(width: 6),
                    Text(
                      tabs[idx].label,
                      style: GoogleFonts.dmSans(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Content ──────────────────────────────────────────────────────────────────
  Widget _content() {
    final s = _data!;
    return FadeTransition(
      opacity: _contentFade,
      child: SlideTransition(
        position: _contentSlide,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              backgroundColor: DS.bg(context),
              elevation: 0,
              pinned: true,
              automaticallyImplyLeading: false,
              expandedHeight: 0,
              leading: Padding(
                padding: const EdgeInsets.only(left: 8, top: 6, bottom: 6),
                child: _BackButton(),
              ),
              title: Row(children: [
                Text('Nifty AI Summary',
                    style: GoogleFonts.dmSans(
                        color: DS.textPrimary(context),
                        fontSize: 17,
                        fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                _PriceBadge(changePct: s.niftyDayChangePct),
              ]),
              actions: [
                GestureDetector(
                  onTap: _load,
                  child: Container(
                    margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: DS.surface(context),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: DS.border(context)),
                    ),
                    child: const Icon(Icons.refresh_rounded,
                        color: DS.blue, size: 17),
                  ),
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(height: 1, color: DS.border(context)),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _DisclaimerBanner(),
                  const SizedBox(height: 12),
                  _buildModeToggle(),
                  const SizedBox(height: 16),
                  _SignalVerdictCard(verdict: s.signalVerdict),
                  const SizedBox(height: 14),
                  _NiftyPriceCard(summary: s),
                  const SizedBox(height: 20),

                  // ─── SWITCH VIEWS: LAYMAN vs ADVANCED TABS ───────────────────
                  if (!_isAdvancedMode) ...[
                    // Simple Bottom Explore Callout Widget
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: DS.blue.withOpacity(.04),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: DS.blue.withOpacity(.12)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Want to explore underlying parameters, live technical indices, and predictive machine setups?',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSans(
                              color: DS.textSecondary(context),
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () => setState(() {
                              _isAdvancedMode = true;
                              _advancedTabIndex = 0;
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: DS.blue,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Analyze Advanced Indicators',
                                    style: GoogleFonts.dmSans(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.arrow_forward_rounded,
                                      color: Colors.white, size: 14),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ] else ...[
                    // Prominent Segmented Tabs
                    _buildAdvancedTabs(),

                    if (_advancedTabIndex == 0) ...[
                      // STEP 1: Charts & Volatility
                      _label(context, 'Nifty 5-Min Chart',
                          Icons.candlestick_chart_rounded, DS.blue,
                          infoText:
                              'Displays the intraday 5-minute candlestick chart, providing a highly responsive short-term view of current market price action.'),
                      const SizedBox(height: 8),
                      _ChartCard(summary: s),
                      const SizedBox(height: 8),
                      _tradingViewBtn(context),
                      const SizedBox(height: 16),
                      _label(context, 'India VIX Volatility',
                          Icons.shield_rounded, DS.violet,
                          infoText:
                              'The India Volatility Index (VIX) measures the market’s expectation of near-term volatility. A rising VIX often indicates market fear or incoming sharp moves.'),
                      const SizedBox(height: 8),
                      _VixCard(summary: s),
                    ] else if (_advancedTabIndex == 1) ...[
                      // STEP 2: Algorithmic Signals
                      _label(context, 'ATLAS Indicators', Icons.hub_rounded,
                          DS.violet,
                          infoText:
                              'A proprietary composite indicator analyzing advancing vs. declining stock ratios alongside probability metrics to evaluate overall market breadth and internal strength.'),
                      const SizedBox(height: 8),
                      _AtlasCard(summary: s),
                      const SizedBox(height: 20),
                      _label(context, 'Bollinger Breakouts',
                          Icons.bubble_chart_rounded, DS.teal,
                          infoText:
                              'Tracks standard deviation bands around the moving average to spot sudden volatility expansions or price breakouts, indicating potential momentum shifts.'),
                      const SizedBox(height: 8),
                      _BollingerCard(summary: s),
                      const SizedBox(height: 20),
                      _label(context, 'Chartink Probability',
                          Icons.bar_chart_rounded, DS.orange,
                          infoText:
                              'Aggregates signals from technical scanners, computing a statistical probability score to determine the likelihood of directional market continuation.'),
                      const SizedBox(height: 8),
                      _ChartinkCard(summary: s),
                    ] else if (_advancedTabIndex == 2) ...[
                      // STEP 3: Support, Strategies & Targets
                      _label(context, 'Trade Setup',
                          Icons.arrow_circle_right_rounded, DS.green),
                      const SizedBox(height: 8),
                      _TradeCard(idea: s.tradeIdea),
                      const SizedBox(height: 20),
                      _label(context, 'Key Levels', Icons.layers_rounded,
                          DS.textSecondary(context)),
                      const SizedBox(height: 8),
                      _KeyLevelsCard(
                          support: s.support, resistance: s.resistance),
                      const SizedBox(height: 20),
                      _label(context, 'Key Observations',
                          Icons.lightbulb_outline_rounded, DS.amber),
                      const SizedBox(height: 8),
                      _ObservationsCard(items: s.keyObservations),
                      const SizedBox(height: 20),
                      if (s.riskFactors.isNotEmpty) ...[
                        _label(context, 'Risk Factors',
                            Icons.warning_amber_rounded, DS.red),
                        const SizedBox(height: 8),
                        _RiskCard(risks: s.riskFactors),
                        const SizedBox(height: 20),
                      ],
                      _label(context, 'Live Watchlist',
                          Icons.show_chart_rounded, DS.textSecondary(context)),
                      const SizedBox(height: 8),
                      _LiveIndicesCard(indices: s.liveIndices),
                    ],
                    const SizedBox(height: 20),
                  ],

                  // Common Meta Card
                  _MetaCard(summary: s, onRefresh: _load),
                  const SizedBox(height: 8),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tradingViewBtn(BuildContext context) => GestureDetector(
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => BrowserLite_V(
                    'https://in.tradingview.com/chart/?symbol=NSE%3ANIFTY'))),
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            color: DS.blue,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: DS.blue.withOpacity(.28),
                  blurRadius: 12,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.candlestick_chart_rounded,
                color: Colors.white.withOpacity(.85), size: 16),
            const SizedBox(width: 8),
            Text('View on TradingView',
                style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: .2)),
            const SizedBox(width: 6),
            Icon(Icons.open_in_new_rounded,
                color: Colors.white.withOpacity(.55), size: 12),
          ]),
        ),
      );

  Widget _label(BuildContext context, String title, IconData icon, Color color,
      {String? infoText}) {
    return Row(children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 6),
      Text(title.toUpperCase(),
          style: GoogleFonts.dmSans(
              color: DS.textSecondary(context),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2)),
      if (infoText != null) ...[
        const Spacer(),
        GestureDetector(
          onTap: () =>
              _showExplanationSheet(context, title, infoText, icon, color),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: DS.surfaceAlt(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: DS.border(context)),
            ),
            child: Row(
              children: [
                Icon(Icons.help_outline_rounded,
                    size: 12, color: DS.textSecondary(context)),
                const SizedBox(width: 4),
                Text('Info',
                    style: GoogleFonts.dmSans(
                        color: DS.textSecondary(context),
                        fontSize: 10,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ]
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CARDS  — all use Builder / context to resolve DS colours
// ═══════════════════════════════════════════════════════════════════════════════

// ─── Signal Verdict ───────────────────────────────────────────────────────────
class _SignalVerdictCard extends StatelessWidget {
  final Map<String, dynamic> verdict;
  const _SignalVerdictCard({required this.verdict});

  @override
  Widget build(BuildContext context) {
    final confidence = verdict['entry_confidence'] as String? ?? 'Avoid';
    final bias = verdict['overall_bias'] as String? ?? 'Neutral';
    final text = verdict['verdict'] as String? ?? '';
    final sources = verdict['sources_actionable'] as int? ?? 0;
    final vixFear = verdict['vix_fear_active'] as bool? ?? false;
    final cc = DS.confidence(confidence);
    final atlasOk = verdict['atlas_actionable'] as bool? ?? false;
    final bollOk = verdict['bollinger_actionable'] as bool? ?? false;
    final chartOk = verdict['chartink_actionable'] as bool? ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: DS.surface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cc.withOpacity(.25), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: cc.withOpacity(isDark ? .10 : .06),
              blurRadius: 20,
              spreadRadius: 2),
          BoxShadow(
              color: Colors.black.withOpacity(isDark ? .3 : .04),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: cc, borderRadius: BorderRadius.circular(8)),
            child: Text(confidence.toUpperCase(),
                style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .5)),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: DS.sentiment(bias).withOpacity(.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: DS.sentiment(bias).withOpacity(.25)),
            ),
            child: Text(bias,
                style: GoogleFonts.dmSans(
                    color: DS.sentiment(bias),
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ),
          const Spacer(),
          if (vixFear)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                  color: DS.red.withOpacity(.10),
                  borderRadius: BorderRadius.circular(8)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.warning_amber_rounded,
                    color: DS.red, size: 12),
                const SizedBox(width: 3),
                Text('VIX ↑',
                    style: GoogleFonts.dmSans(
                        color: DS.red,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ]),
            ),
        ]),
        const SizedBox(height: 14),
        Text(text,
            style: GoogleFonts.dmSans(
                color: DS.textPrimary(context), fontSize: 13.5, height: 1.55)),
        const SizedBox(height: 16),
        Row(children: [
          _SourceDot(label: 'ATLAS', active: atlasOk),
          const SizedBox(width: 8),
          _SourceDot(label: 'Bollinger', active: bollOk),
          const SizedBox(width: 8),
          _SourceDot(label: 'Chartink', active: chartOk),
          const Spacer(),
          Text('$sources/3 active',
              style: GoogleFonts.jetBrainsMono(
                  color: DS.textSecondary(context), fontSize: 10)),
        ]),
      ]),
    );
  }
}

class _SourceDot extends StatelessWidget {
  final String label;
  final bool active;
  const _SourceDot({required this.label, required this.active});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: active ? DS.green.withOpacity(.10) : DS.surfaceAlt(context),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: active ? DS.green.withOpacity(.28) : DS.border(context)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active ? DS.green : DS.textTertiary(context))),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.dmSans(
                  color: active ? DS.green : DS.textSecondary(context),
                  fontSize: 10,
                  fontWeight: FontWeight.w600)),
        ]),
      );
}

// ─── Nifty Price Card ─────────────────────────────────────────────────────────
class _NiftyPriceCard extends StatelessWidget {
  final NiftySummary summary;
  const _NiftyPriceCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final isUp = summary.niftyDayChangePct >= 0;
    final cc = isUp ? DS.green : DS.red;
    final sc = DS.sentiment(summary.marketSentiment);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: DS.surface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DS.border(context)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(isDark ? .3 : .04),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('NIFTY 50',
                  style: GoogleFonts.jetBrainsMono(
                      color: DS.textTertiary(context),
                      fontSize: 10,
                      letterSpacing: 2)),
              const SizedBox(height: 6),
              Text('₹${summary.niftyLtp.toStringAsFixed(2)}',
                  style: GoogleFonts.jetBrainsMono(
                      color: DS.textPrimary(context),
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: cc.withOpacity(.10),
                    borderRadius: BorderRadius.circular(7)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                      isUp
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 13,
                      color: cc),
                  const SizedBox(width: 4),
                  Text(
                      '${isUp ? "+" : ""}${summary.niftyDayChangePct.toStringAsFixed(2)}% today',
                      style: GoogleFonts.dmSans(
                          color: cc,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: sc.withOpacity(.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: sc.withOpacity(.22)),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(summary.sentimentEmoji,
                  style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 4),
              Text(summary.marketSentiment,
                  style: GoogleFonts.dmSans(
                      color: sc, fontSize: 11, fontWeight: FontWeight.w700)),
            ]),
          ),
        ]),
        const SizedBox(height: 16),
        Divider(height: 1, color: DS.divider(context)),
        const SizedBox(height: 14),
        Row(children: [
          _StatCell(label: 'A:D', value: summary.advancingDecliningRatio),
          _Vline(),
          _StatCell(
              label: 'Probability',
              value: '${summary.probabilityScore.toStringAsFixed(1)}%',
              color: summary.probabilityScore > 60
                  ? DS.green
                  : summary.probabilityScore < 40
                      ? DS.red
                      : DS.amber),
          _Vline(),
          _StatCell(
              label: 'Trend',
              value: summary.shortTermTrend,
              color: DS.sentiment(summary.shortTermTrend == 'Uptrend'
                  ? 'Bullish'
                  : summary.shortTermTrend == 'Downtrend'
                      ? 'Bearish'
                      : 'Neutral')),
          _Vline(),
          _StatCell(
              label: 'Confidence',
              value: summary.confidence,
              color: DS.confidence(summary.confidence)),
        ]),
        if (summary.oneLiner.isNotEmpty) ...[
          const SizedBox(height: 14),
          Divider(height: 1, color: DS.divider(context)),
          const SizedBox(height: 12),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.psychology_rounded, color: DS.blue, size: 15),
            const SizedBox(width: 8),
            Expanded(
              child: Text(summary.oneLiner,
                  style: GoogleFonts.dmSans(
                      color: DS.textSecondary(context),
                      fontSize: 13,
                      height: 1.55)),
            ),
          ]),
        ],
      ]),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label, value;
  final Color? color;
  const _StatCell({required this.label, required this.value, this.color});
  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: GoogleFonts.dmSans(
                  color: DS.textTertiary(context),
                  fontSize: 9,
                  letterSpacing: .3)),
          const SizedBox(height: 3),
          Text(value,
              style: GoogleFonts.jetBrainsMono(
                  color: color ?? DS.textPrimary(context),
                  fontSize: 11,
                  fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis),
        ]),
      );
}

class _Vline extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
      width: 1,
      height: 32,
      color: DS.border(context),
      margin: const EdgeInsets.symmetric(horizontal: 8));
}

// ─── Chart Card ───────────────────────────────────────────────────────────────
class _ChartCard extends StatelessWidget {
  final NiftySummary summary;
  const _ChartCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final candles = summary.candles;
    final isUp = summary.niftyDayChangePct >= 0;
    final cc = isUp ? DS.green : DS.red;
    final s5 = summary.nifty5minSummary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: DS.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DS.border(context)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(isDark ? .3 : .04),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Intraday · 5-min',
                        style: GoogleFonts.dmSans(
                            color: DS.textPrimary(context),
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    Text('Yahoo Finance · ^NSEI',
                        style: GoogleFonts.dmSans(
                            color: DS.textTertiary(context), fontSize: 11)),
                  ]),
            ),
            if (s5.isNotEmpty) ...[
              _MiniStat(
                  label: 'H',
                  value: '₹${(s5['day_high'] ?? 0).toStringAsFixed(0)}',
                  color: DS.green),
              const SizedBox(width: 12),
              _MiniStat(
                  label: 'L',
                  value: '₹${(s5['day_low'] ?? 0).toStringAsFixed(0)}',
                  color: DS.red),
            ],
          ]),
        ),
        if (s5.isNotEmpty) ...[
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: DS.surfaceAlt(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: DS.border(context)),
              ),
              child: Row(children: [
                _MiniStat(
                    label: 'O',
                    value: '₹${(s5['open'] ?? 0).toStringAsFixed(2)}'),
                const SizedBox(width: 16),
                _MiniStat(
                    label: 'LTP',
                    value: '₹${(s5['ltp'] ?? 0).toStringAsFixed(2)}',
                    color: cc),
                const SizedBox(width: 16),
                _MiniStat(
                    label: 'Chg',
                    value:
                        '${(s5['day_change'] ?? 0) >= 0 ? "+" : ""}${(s5['day_change'] ?? 0).toStringAsFixed(2)}',
                    color: cc),
                const Spacer(),
                _TrendChip(trend: s5['short_term_trend'] as String? ?? ''),
              ]),
            ),
          ),
        ],
        const SizedBox(height: 10),
        candles.isEmpty
            ? SizedBox(
                height: 80,
                child: Center(
                  child: Text('No intraday data',
                      style: TextStyle(
                          color: DS.textTertiary(context), fontSize: 12)),
                ))
            : _AreaChart(candles: candles, lineColor: cc),
        if (summary.nifty5minInterpretation.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.psychology_rounded, color: DS.blue, size: 13),
              const SizedBox(width: 8),
              Expanded(
                child: Text(summary.nifty5minInterpretation,
                    style: GoogleFonts.dmSans(
                        color: DS.textSecondary(context),
                        fontSize: 12,
                        height: 1.5)),
              ),
            ]),
          ),
        ] else
          const SizedBox(height: 14),
      ]),
    );
  }
}

final _kIst = const Duration(hours: 5, minutes: 30);
DateTime _toIst(DateTime dt) => dt.toUtc().add(_kIst);

class _AreaChart extends StatelessWidget {
  final List<CandlePoint> candles;
  final Color lineColor;
  const _AreaChart({required this.candles, required this.lineColor});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gridColor =
        isDark ? const Color(0xFF252840) : const Color(0xFFEEF1F7);
    final lblColor = isDark ? const Color(0xFF4E5670) : const Color(0xFF9AA3BB);

    return SizedBox(
      height: 180,
      child: SfCartesianChart(
        plotAreaBorderWidth: 0,
        margin: const EdgeInsets.only(right: 8),
        backgroundColor: Colors.transparent,
        primaryXAxis: DateTimeAxis(
          dateFormat: DateFormat('HH:mm'),
          intervalType: DateTimeIntervalType.minutes,
          interval: 30,
          majorGridLines: const MajorGridLines(width: 0),
          axisLine: const AxisLine(width: 0),
          majorTickLines: const MajorTickLines(size: 0),
          labelStyle: TextStyle(color: lblColor, fontSize: 9),
        ),
        primaryYAxis: NumericAxis(
          numberFormat: NumberFormat.compact(),
          majorGridLines: MajorGridLines(
              color: gridColor, width: 1, dashArray: const [3, 3]),
          axisLine: const AxisLine(width: 0),
          majorTickLines: const MajorTickLines(size: 0),
          labelStyle: TextStyle(color: lblColor, fontSize: 9),
          opposedPosition: true,
        ),
        series: [
          AreaSeries<CandlePoint, DateTime>(
            dataSource: candles,
            xValueMapper: (d, _) => _toIst(d.time),
            yValueMapper: (d, _) => d.close,
            color: lineColor.withOpacity(.06),
            borderColor: lineColor,
            borderWidth: 2,
            animationDuration: 500,
            gradient: LinearGradient(
              colors: [
                lineColor.withOpacity(isDark ? .18 : .12),
                lineColor.withOpacity(0)
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ],
        tooltipBehavior: TooltipBehavior(
          enable: true,
          builder: (data, point, series, pIdx, sIdx) {
            if (pIdx < 0 || pIdx >= candles.length)
              return const SizedBox.shrink();
            final c = candles[pIdx];
            final istTime = _toIst(c.time);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: DS.surface(context),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: DS.border(context)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(isDark ? .4 : .08),
                      blurRadius: 8),
                ],
              ),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DateFormat('HH:mm').format(istTime),
                        style: TextStyle(
                            color: DS.textSecondary(context), fontSize: 9.5)),
                    Text('₹${c.close.toStringAsFixed(2)}',
                        style: GoogleFonts.jetBrainsMono(
                            color: lineColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                  ]),
            );
          },
        ),
      ),
    );
  }
}

// ─── VIX Card ─────────────────────────────────────────────────────────────────
class _VixCard extends StatelessWidget {
  final NiftySummary summary;
  const _VixCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final vix = summary.vixAnalysis;
    final ltp = (vix['ltp'] as num? ?? 0).toDouble();
    final trend = vix['trend'] as String? ?? 'Unknown';
    final level = vix['level'] as String? ?? 'Unknown';
    final fear = vix['fear_flag'] as bool? ?? false;
    final interp = vix['interpretation'] as String? ?? '';
    final chgPct = (vix['day_change_pct'] as num? ?? 0).toDouble();
    final isUp = chgPct >= 0;
    final vixUnavailable =
        vix.isEmpty || ltp == 0 || trend == 'Unknown' || level == 'Unknown';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final levelColor = level == 'Extreme' || level == 'High'
        ? DS.red
        : level == 'Moderate'
            ? DS.amber
            : DS.green;

    if (vixUnavailable) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DS.surface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DS.border(context)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(isDark ? .3 : .04),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: DS.textTertiary(context).withOpacity(.08),
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: DS.textTertiary(context).withOpacity(.2)),
            ),
            child: Icon(Icons.shield_outlined,
                color: DS.textTertiary(context), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('INDIA VIX',
                  style: GoogleFonts.jetBrainsMono(
                      color: DS.textTertiary(context),
                      fontSize: 10,
                      letterSpacing: 2)),
              const SizedBox(height: 3),
              Text('No VIX data available',
                  style: GoogleFonts.dmSans(
                      color: DS.textSecondary(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
              Text('Market may be closed or data unavailable',
                  style: GoogleFonts.dmSans(
                      color: DS.textTertiary(context), fontSize: 11)),
            ]),
          ),
        ]),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: DS.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: fear ? DS.red.withOpacity(.28) : DS.border(context)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(isDark ? .3 : .04),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('INDIA VIX',
                  style: GoogleFonts.jetBrainsMono(
                      color: DS.textTertiary(context),
                      fontSize: 10,
                      letterSpacing: 2)),
              const SizedBox(height: 4),
              Text(ltp.toStringAsFixed(2),
                  style: GoogleFonts.jetBrainsMono(
                      color: DS.textPrimary(context),
                      fontSize: 26,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Row(children: [
                Icon(
                    isUp
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    size: 11,
                    color: isUp ? DS.red : DS.green),
                const SizedBox(width: 3),
                Text('${isUp ? "+" : ""}${chgPct.toStringAsFixed(2)}%',
                    style: GoogleFonts.dmSans(
                        color: isUp ? DS.red : DS.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ]),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            _Chip(label: level, color: levelColor),
            const SizedBox(height: 6),
            _Chip(
                label: trend,
                color: trend == 'Uptrend'
                    ? DS.red
                    : trend == 'Downtrend'
                        ? DS.green
                        : DS.amber),
          ]),
        ]),
        if (summary.vixCandles.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: SfCartesianChart(
              plotAreaBorderWidth: 0,
              backgroundColor: Colors.transparent,
              primaryXAxis: DateTimeAxis(isVisible: false),
              primaryYAxis: NumericAxis(
                isVisible: false,
                minimum: summary.vixCandles.map((c) => c.low).reduce(math.min) *
                    .998,
                maximum:
                    summary.vixCandles.map((c) => c.high).reduce(math.max) *
                        1.002,
              ),
              series: [
                LineSeries<CandlePoint, DateTime>(
                  dataSource: summary.vixCandles,
                  xValueMapper: (d, _) => d.time,
                  yValueMapper: (d, _) => d.close,
                  color: fear ? DS.red : DS.green,
                  width: 2,
                  animationDuration: 400,
                ),
              ],
            ),
          ),
        ],
        if (interp.isNotEmpty) ...[
          const SizedBox(height: 10),
          Divider(height: 1, color: DS.divider(context)),
          const SizedBox(height: 10),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(
                fear
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_outline_rounded,
                color: fear ? DS.red : DS.green,
                size: 14),
            const SizedBox(width: 8),
            Expanded(
              child: Text(interp,
                  style: GoogleFonts.dmSans(
                      color: DS.textSecondary(context),
                      fontSize: 12,
                      height: 1.5)),
            ),
          ]),
        ],
      ]),
    );
  }
}

// ─── ATLAS Card ───────────────────────────────────────────────────────────────
class _AtlasCard extends StatelessWidget {
  final NiftySummary summary;
  const _AtlasCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final atlas = summary.atlasAnalysis;
    final freshness = atlas['freshness'] as Map<String, dynamic>? ?? {};
    final pos = (atlas['positive_indicators'] ?? 0).toDouble();
    final neg = (atlas['negative_indicators'] ?? 0).toDouble();
    final adv = (atlas['advancing'] ?? 0).toDouble();
    final dec = (atlas['declining'] ?? 0).toDouble();
    final prob = (atlas['probability'] ?? 0.0).toDouble();
    final trend = atlas['trend'] as String? ?? 'Neutral';
    final actionable = atlas['actionable'] as bool? ?? false;
    final advice = atlas['action_advice'] as String? ?? '';
    final probStrong = atlas['probability_strong'] as bool? ?? false;
    final entry = atlas['entry_signal'] == true;
    final upbreak = atlas['upbreakout'] == true;
    final freshnessLabel = freshness['label'] as String? ?? 'unknown';
    final ageMin = freshness['age_minutes'];

    return _AnalysisCard(
      accent: DS.violet,
      actionable: actionable,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _FreshnessBadge(
              label: freshnessLabel,
              ageLabel: ageMin != null
                  ? '${(ageMin as num).toStringAsFixed(0)}m ago'
                  : ''),
          const Spacer(),
          _ProbBadge(prob: prob, strong: probStrong),
          const SizedBox(width: 8),
          _Chip(label: trend, color: DS.sentiment(trend)),
        ]),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('▲ ${adv.toInt()} Advancing',
              style: GoogleFonts.dmSans(
                  color: DS.green, fontSize: 11, fontWeight: FontWeight.w600)),
          Text('▼ ${dec.toInt()} Declining',
              style: GoogleFonts.dmSans(
                  color: DS.red, fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: (adv + dec) > 0 ? adv / (adv + dec) : 0.5,
            minHeight: 5,
            backgroundColor: DS.red.withOpacity(.15),
            valueColor: const AlwaysStoppedAnimation(DS.green),
          ),
        ),
        const SizedBox(height: 12),
        Row(children: [
          _StatPill(value: '${pos.toInt()}', label: '+ve', color: DS.green),
          const SizedBox(width: 8),
          _StatPill(value: '${neg.toInt()}', label: '-ve', color: DS.red),
          const SizedBox(width: 8),
          if (entry) _Chip(label: '⚡ Entry', color: DS.blue),
          const SizedBox(width: 4),
          if (upbreak) _Chip(label: '🔼 Breakout', color: DS.green),
        ]),
        const SizedBox(height: 12),
        _AdviceRow(text: advice),
        if (summary.atlasInterpretation.isNotEmpty) ...[
          const SizedBox(height: 10),
          Divider(height: 1, color: DS.divider(context)),
          const SizedBox(height: 10),
          _AiNote(text: summary.atlasInterpretation),
        ],
      ]),
    );
  }
}

// ─── Bollinger Card ───────────────────────────────────────────────────────────
class _BollingerCard extends StatelessWidget {
  final NiftySummary summary;
  const _BollingerCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final boll = summary.bollingerAnalysis;
    final actionable = boll['actionable'] as bool? ?? false;
    final advice = boll['action_advice'] as String? ?? '';
    final bias = boll['bias'] as String? ?? 'Neutral';
    final bkFresh = boll['breakout_fresh_count'] as int? ?? 0;
    final cfFresh = boll['checkfirst_fresh_count'] as int? ?? 0;
    final bkSigs = (boll['breakout_signals'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .take(3)
        .toList();
    final cfSigs = (boll['checkfirst_signals'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .take(3)
        .toList();

    return _AnalysisCard(
      accent: DS.teal,
      actionable: actionable,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _Chip(label: bias, color: DS.sentiment(bias)),
          const SizedBox(width: 8),
          if (bkFresh > 0)
            _Chip(label: '💥 $bkFresh fresh breakout', color: DS.teal),
          if (cfFresh > 0) ...[
            const SizedBox(width: 6),
            _Chip(label: '🔍 $cfFresh fresh check', color: DS.violet),
          ],
        ]),
        const SizedBox(height: 12),
        _AdviceRow(text: advice),
        if (bkSigs.isNotEmpty || cfSigs.isNotEmpty) ...[
          const SizedBox(height: 12),
          Divider(height: 1, color: DS.divider(context)),
          const SizedBox(height: 12),
          if (bkSigs.isNotEmpty) ...[
            _SigHeader(label: 'BREAKOUT', color: DS.teal),
            const SizedBox(height: 6),
            ...bkSigs.map((s) => _SignalRow(signal: s, color: DS.teal)),
          ],
          if (cfSigs.isNotEmpty) ...[
            if (bkSigs.isNotEmpty) const SizedBox(height: 10),
            _SigHeader(label: 'CHECK FIRST', color: DS.violet),
            const SizedBox(height: 6),
            ...cfSigs.map((s) => _SignalRow(signal: s, color: DS.violet)),
          ],
        ],
        if (summary.bollingerInterpretation.isNotEmpty) ...[
          const SizedBox(height: 10),
          Divider(height: 1, color: DS.divider(context)),
          const SizedBox(height: 10),
          _AiNote(text: summary.bollingerInterpretation),
        ],
      ]),
    );
  }
}

// ─── Chartink Card ────────────────────────────────────────────────────────────
class _ChartinkCard extends StatelessWidget {
  final NiftySummary summary;
  const _ChartinkCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final ci = summary.chartinkAnalysis;
    final avg = (ci['avg_probability'] ?? 0.0).toDouble();
    final fresh = ci['fresh_count'] as int? ?? 0;
    final actionable = ci['actionable'] as bool? ?? false;
    final advice = ci['action_advice'] as String? ?? '';
    final bc = ci['bullish_count'] as int? ?? 0;
    final berc = ci['bearish_count'] as int? ?? 0;
    final latest = (ci['latest'] as List? ?? []).cast<Map<String, dynamic>>();
    final probColor = avg > 60
        ? DS.green
        : avg < 40
            ? DS.red
            : DS.amber;

    return _AnalysisCard(
      accent: DS.orange,
      actionable: actionable,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _StatPill(value: '$bc', label: '↑', color: DS.green),
          const SizedBox(width: 8),
          _StatPill(value: '$berc', label: '↓', color: DS.red),
          const Spacer(),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('Avg Prob',
                style: GoogleFonts.dmSans(
                    color: DS.textTertiary(context),
                    fontSize: 9,
                    letterSpacing: .3)),
            Text('${avg.toStringAsFixed(1)}%',
                style: GoogleFonts.jetBrainsMono(
                    color: probColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w700)),
          ]),
        ]),
        if (fresh > 0) ...[
          const SizedBox(height: 8),
          _Chip(
              label: '⚡ $fresh fresh signal${fresh > 1 ? "s" : ""} (<5min)',
              color: DS.orange),
        ],
        const SizedBox(height: 10),
        _AdviceRow(text: advice),
        if (latest.isNotEmpty) ...[
          const SizedBox(height: 12),
          Divider(height: 1, color: DS.divider(context)),
          const SizedBox(height: 10),
          _SigHeader(label: 'LATEST SIGNALS', color: DS.orange),
          const SizedBox(height: 6),
          ...latest.map((s) {
            final sent = (s['sentiment'] as String? ?? '').toLowerCase();
            final c = sent == 'bullish'
                ? DS.green
                : sent == 'bearish'
                    ? DS.red
                    : DS.amber;
            final prob = (s['probability'] ?? 0.0).toDouble();
            final fr = s['_freshness'] as Map<String, dynamic>?;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Container(
                    width: 4,
                    height: 4,
                    decoration:
                        BoxDecoration(shape: BoxShape.circle, color: c)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(s['description'] ?? '',
                      style: GoogleFonts.dmSans(
                          color: DS.textPrimary(context), fontSize: 12)),
                ),
                const SizedBox(width: 8),
                if (fr != null)
                  _FreshnessLabel(label: fr['label'] as String? ?? ''),
                const SizedBox(width: 6),
                Text('${prob.toStringAsFixed(0)}%',
                    style: GoogleFonts.jetBrainsMono(
                        color: c, fontSize: 12, fontWeight: FontWeight.w700)),
              ]),
            );
          }),
        ],
        if (summary.chartinkInterpretation.isNotEmpty) ...[
          const SizedBox(height: 6),
          Divider(height: 1, color: DS.divider(context)),
          const SizedBox(height: 10),
          _AiNote(text: summary.chartinkInterpretation),
        ],
      ]),
    );
  }
}

// ─── Trade Card ───────────────────────────────────────────────────────────────
class _TradeCard extends StatelessWidget {
  final Map<String, dynamic> idea;
  const _TradeCard({required this.idea});
  @override
  Widget build(BuildContext context) {
    final dir = idea['direction'] as String? ?? 'Wait';
    final entry = idea['entry_zone'] as String? ?? '—';
    final sl = (idea['stop_loss'] ?? 0).toDouble();
    final t1 = (idea['target_1'] ?? 0).toDouble();
    final t2 = (idea['target_2'] ?? 0).toDouble();
    final rat = idea['rationale'] as String? ?? '';
    final isWait = dir == 'Wait' || dir == 'wait';
    final dc = dir == 'Long'
        ? DS.green
        : dir == 'Short'
            ? DS.red
            : DS.amber;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: DS.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dc.withOpacity(.22)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(isDark ? .3 : .04),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(children: [
        if (!isWait)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: dc.withOpacity(.06),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                    color: dc, borderRadius: BorderRadius.circular(7)),
                child: Text(dir,
                    style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800)),
              ),
              const Spacer(),
              Text('Entry: $entry',
                  style: GoogleFonts.jetBrainsMono(
                      color: DS.textSecondary(context), fontSize: 12)),
            ]),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: isWait
              ? _WaitState(rationale: rat)
              : Column(children: [
                  Row(children: [
                    Expanded(
                        child: _LevelBox(
                            label: 'Stop Loss',
                            value: '₹${sl.toStringAsFixed(0)}',
                            color: DS.red)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _LevelBox(
                            label: 'Target 1',
                            value: '₹${t1.toStringAsFixed(0)}',
                            color: DS.green)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _LevelBox(
                            label: 'Target 2',
                            value: '₹${t2.toStringAsFixed(0)}',
                            color: DS.green.withOpacity(.65))),
                  ]),
                  if (rat.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(rat,
                        style: GoogleFonts.dmSans(
                            color: DS.textSecondary(context),
                            fontSize: 13,
                            height: 1.55)),
                  ],
                ]),
        ),
      ]),
    );
  }
}

class _WaitState extends StatelessWidget {
  final String rationale;
  const _WaitState({required this.rationale});
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: DS.amber.withOpacity(.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: DS.amber.withOpacity(.22)),
              ),
              child: const Icon(Icons.hourglass_empty_rounded,
                  color: DS.amber, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('No trade setup right now',
                        style: GoogleFonts.dmSans(
                            color: DS.textPrimary(context),
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    Text('Conditions not yet met for entry',
                        style: GoogleFonts.dmSans(
                            color: DS.textTertiary(context), fontSize: 11)),
                  ]),
            ),
          ]),
          if (rationale.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: DS.surfaceAlt(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: DS.border(context)),
              ),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.psychology_rounded, color: DS.blue, size: 13),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(rationale,
                      style: GoogleFonts.dmSans(
                          color: DS.textSecondary(context),
                          fontSize: 12,
                          height: 1.5)),
                ),
              ]),
            ),
          ],
        ],
      );
}

class _LevelBox extends StatelessWidget {
  final String label, value;
  final Color color;
  const _LevelBox(
      {required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(.18)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: GoogleFonts.dmSans(
                  color: color.withOpacity(.75),
                  fontSize: 9,
                  letterSpacing: .3)),
          const SizedBox(height: 3),
          Text(value,
              style: GoogleFonts.jetBrainsMono(
                  color: color, fontSize: 12, fontWeight: FontWeight.w700)),
        ]),
      );
}

// ─── Key Levels ───────────────────────────────────────────────────────────────
class _KeyLevelsCard extends StatelessWidget {
  final List<double> support, resistance;
  const _KeyLevelsCard({required this.support, required this.resistance});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: DS.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DS.border(context)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(isDark ? .3 : .04),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(children: [
        _LevelRow(label: 'SUPPORT', levels: support, color: DS.green),
        Divider(height: 1, color: DS.divider(context)),
        _LevelRow(label: 'RESISTANCE', levels: resistance, color: DS.red),
      ]),
    );
  }
}

class _LevelRow extends StatelessWidget {
  final String label;
  final List<double> levels;
  final Color color;
  const _LevelRow(
      {required this.label, required this.levels, required this.color});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          IntrinsicWidth(
            child: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Row(children: [
                Icon(
                    label == 'SUPPORT'
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    size: 10,
                    color: color),
                const SizedBox(width: 4),
                Text(label,
                    style: GoogleFonts.dmSans(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .8)),
                const SizedBox(width: 12),
              ]),
            ),
          ),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: levels
                  .take(6)
                  .map((l) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: color.withOpacity(.07),
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(color: color.withOpacity(.20)),
                        ),
                        child: Text('₹${l.toStringAsFixed(0)}',
                            style: GoogleFonts.jetBrainsMono(
                                color: color,
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                      ))
                  .toList(),
            ),
          ),
        ]),
      );
}

// ─── Live Indices ─────────────────────────────────────────────────────────────
class _LiveIndicesCard extends StatelessWidget {
  final List<Map<String, dynamic>> indices;
  const _LiveIndicesCard({required this.indices});

  @override
  Widget build(BuildContext context) {
    if (indices.isEmpty) return _EmptyCard(message: 'No live index data');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: DS.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DS.border(context)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(isDark ? .3 : .04),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: List.generate(indices.length, (i) {
          final row = indices[i];
          final pct = (row['pcnt'] ?? 0.0) as double;
          final isUp = pct >= 0;
          final cc = isUp ? DS.green : DS.red;
          final sym = (row['symbol'] ?? '').toString().toUpperCase();
          final isVix = sym.contains('VIX');
          final dispColor = isVix ? (isUp ? DS.red : DS.green) : cc;

          return Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              child: Row(children: [
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(sym,
                            style: GoogleFonts.dmSans(
                                color: DS.textPrimary(context),
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                        if (isVix)
                          Text('Fear Index',
                              style: GoogleFonts.dmSans(
                                  color: DS.textTertiary(context),
                                  fontSize: 10)),
                      ]),
                ),
                Text('₹${(row['ltp'] ?? 0).toStringAsFixed(2)}',
                    style: GoogleFonts.jetBrainsMono(
                        color: DS.textPrimary(context), fontSize: 13)),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                      color: dispColor.withOpacity(.10),
                      borderRadius: BorderRadius.circular(5)),
                  child: Text('${isUp ? "+" : ""}${pct.toStringAsFixed(2)}%',
                      style: GoogleFonts.jetBrainsMono(
                          color: dispColor,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600)),
                ),
              ]),
            ),
            if (i < indices.length - 1)
              Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: DS.divider(context)),
          ]);
        }),
      ),
    );
  }
}

// ─── Observations + Risk ──────────────────────────────────────────────────────
class _ObservationsCard extends StatelessWidget {
  final List<String> items;
  const _ObservationsCard({required this.items});
  @override
  Widget build(BuildContext context) => _ListCard(
      items: items, icon: Icons.circle, iconColor: DS.amber, numbered: true);
}

class _RiskCard extends StatelessWidget {
  final List<String> risks;
  const _RiskCard({required this.risks});
  @override
  Widget build(BuildContext context) => _ListCard(
        items: risks,
        icon: Icons.priority_high_rounded,
        iconColor: DS.red,
        borderColor: DS.red.withOpacity(.18),
      );
}

class _ListCard extends StatelessWidget {
  final List<String> items;
  final IconData icon;
  final Color iconColor;
  final bool numbered;
  final Color? borderColor;
  const _ListCard(
      {required this.items,
      required this.icon,
      required this.iconColor,
      this.numbered = false,
      this.borderColor});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: DS.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor ?? DS.border(context)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(isDark ? .3 : .04),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: items
            .asMap()
            .entries
            .map((e) => Padding(
                  padding: EdgeInsets.only(
                      bottom: e.key < items.length - 1 ? 12 : 0),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              color: iconColor.withOpacity(.10)),
                          alignment: Alignment.center,
                          child: numbered
                              ? Text('${e.key + 1}',
                                  style: GoogleFonts.jetBrainsMono(
                                      color: iconColor,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700))
                              : Icon(icon, color: iconColor, size: 10),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(e.value,
                              style: GoogleFonts.dmSans(
                                  color: DS.textPrimary(context),
                                  fontSize: 13,
                                  height: 1.55)),
                        ),
                      ]),
                ))
            .toList(),
      ),
    );
  }
}

// ─── Meta Card ────────────────────────────────────────────────────────────────
class _MetaCard extends StatelessWidget {
  final NiftySummary summary;
  final VoidCallback onRefresh;
  const _MetaCard({required this.summary, required this.onRefresh});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: DS.surfaceAlt(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: DS.border(context)),
        ),
        child: Row(children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.access_time_rounded,
                    color: DS.textTertiary(context), size: 12),
                const SizedBox(width: 5),
                Text(summary.lastUpdated,
                    style: GoogleFonts.jetBrainsMono(
                        color: DS.textTertiary(context), fontSize: 10)),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                _Chip(
                    label: summary.cached ? '⚡ Cached' : '🤖 Live AI',
                    color: summary.cached ? DS.amber : DS.blue),
              ]),
            ]),
          ),
        ]),
      );
}

// ═══════════════════════════════════════════════════════════════════════════════
// SHARED SMALL WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

class _AnalysisCard extends StatelessWidget {
  final Widget child;
  final Color accent;
  final bool actionable;
  const _AnalysisCard(
      {required this.child, required this.accent, this.actionable = false});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: DS.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: actionable ? accent.withOpacity(.32) : DS.border(context)),
        boxShadow: [
          if (actionable)
            BoxShadow(
                color: accent.withOpacity(isDark ? .08 : .05),
                blurRadius: 16,
                spreadRadius: 2),
          BoxShadow(
              color: Colors.black.withOpacity(isDark ? .3 : .04),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

class _FreshnessBadge extends StatelessWidget {
  final String label, ageLabel;
  const _FreshnessBadge({required this.label, required this.ageLabel});
  @override
  Widget build(BuildContext context) {
    final color = DS.freshness(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(.22)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 5),
        Text(
            '${label[0].toUpperCase()}${label.substring(1)}${ageLabel.isNotEmpty ? " · $ageLabel" : ""}',
            style: GoogleFonts.dmSans(
                color: color, fontSize: 10, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _FreshnessLabel extends StatelessWidget {
  final String label;
  const _FreshnessLabel({required this.label});
  @override
  Widget build(BuildContext context) {
    final color = DS.freshness(label);
    return Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color));
  }
}

class _ProbBadge extends StatelessWidget {
  final double prob;
  final bool strong;
  const _ProbBadge({required this.prob, required this.strong});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: strong ? DS.green.withOpacity(.10) : DS.surfaceAlt(context),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: strong ? DS.green.withOpacity(.22) : DS.border(context)),
        ),
        child: Text('${prob.toStringAsFixed(1)}%${strong ? " ✓" : ""}',
            style: GoogleFonts.jetBrainsMono(
                color: strong ? DS.green : DS.textSecondary(context),
                fontSize: 11,
                fontWeight: FontWeight.w700)),
      );
}

class _AdviceRow extends StatelessWidget {
  final String text;
  const _AdviceRow({required this.text});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: DS.surfaceAlt(context),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: DS.border(context)),
        ),
        child: Text(text,
            style: GoogleFonts.dmSans(
                color: DS.textPrimary(context), fontSize: 12.5, height: 1.4)),
      );
}

class _AiNote extends StatelessWidget {
  final String text;
  const _AiNote({required this.text});
  @override
  Widget build(BuildContext context) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.psychology_rounded, color: DS.blue, size: 13),
        const SizedBox(width: 7),
        Expanded(
          child: Text(text,
              style: GoogleFonts.dmSans(
                  color: DS.textSecondary(context), fontSize: 12, height: 1.5)),
        ),
      ]);
}

class _SignalRow extends StatelessWidget {
  final Map<String, dynamic> signal;
  final Color color;
  const _SignalRow({required this.signal, required this.color});
  @override
  Widget build(BuildContext context) {
    final fresh = signal['_freshness'] as Map<String, dynamic>?;
    final freshLabel = fresh?['label'] as String? ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(signal['description'] ?? '',
              style: GoogleFonts.dmSans(
                  color: DS.textPrimary(context), fontSize: 12, height: 1.4)),
        ),
        const SizedBox(width: 6),
        _FreshnessLabel(label: freshLabel),
        const SizedBox(width: 4),
        Text(signal['time'] ?? '',
            style: GoogleFonts.jetBrainsMono(
                color: DS.textTertiary(context), fontSize: 10)),
      ]),
    );
  }
}

class _SigHeader extends StatelessWidget {
  final String label;
  final Color color;
  const _SigHeader({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Text(label,
      style: GoogleFonts.dmSans(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1));
}

class _StatPill extends StatelessWidget {
  final String value, label;
  final Color color;
  const _StatPill(
      {required this.value, required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(.20)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(value,
              style: GoogleFonts.jetBrainsMono(
                  color: color, fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.dmSans(
                  color: color.withOpacity(.75), fontSize: 11)),
        ]),
      );
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(.10),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(.22)),
        ),
        child: Text(label,
            style: GoogleFonts.dmSans(
                color: color, fontSize: 10.5, fontWeight: FontWeight.w600)),
      );
}

class _TrendChip extends StatelessWidget {
  final String trend;
  const _TrendChip({required this.trend});
  @override
  Widget build(BuildContext context) {
    final c = trend == 'uptrend'
        ? DS.green
        : trend == 'downtrend'
            ? DS.red
            : DS.amber;
    return _Chip(label: trend, color: c);
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final Color? color;
  const _MiniStat({required this.label, required this.value, this.color});
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: TextStyle(color: DS.textTertiary(context), fontSize: 9)),
        Text(value,
            style: GoogleFonts.jetBrainsMono(
                color: color ?? DS.textPrimary(context),
                fontSize: 11,
                fontWeight: FontWeight.w600)),
      ]);
}

class _PriceBadge extends StatelessWidget {
  final double changePct;
  const _PriceBadge({required this.changePct});
  @override
  Widget build(BuildContext context) {
    final isUp = changePct >= 0;
    final cc = isUp ? DS.green : DS.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
          color: cc.withOpacity(.10), borderRadius: BorderRadius.circular(6)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 10, color: cc),
        const SizedBox(width: 2),
        Text('${isUp ? "+" : ""}${changePct.toStringAsFixed(2)}%',
            style: GoogleFonts.jetBrainsMono(
                color: cc, fontSize: 10, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _DisclaimerBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: DS.amber.withOpacity(.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: DS.amber.withOpacity(.22)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.info_outline_rounded, color: DS.amber, size: 13),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'For educational purposes only. Not financial advice. Consult a SEBI-registered advisor.',
              style: GoogleFonts.dmSans(
                  color: DS.amber, fontSize: 11, height: 1.4),
            ),
          ),
        ]),
      );
}

class _EmptyCard extends StatelessWidget {
  final String message;
  const _EmptyCard({required this.message});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DS.surfaceAlt(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: DS.border(context)),
        ),
        child: Row(children: [
          Icon(Icons.search_off_rounded,
              color: DS.textTertiary(context), size: 16),
          const SizedBox(width: 8),
          Text(message,
              style: GoogleFonts.dmSans(
                  color: DS.textSecondary(context), fontSize: 13)),
        ]),
      );
}

class _AppBar extends StatelessWidget {
  final String title;
  final VoidCallback? onRefresh;
  const _AppBar({required this.title, this.onRefresh});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Row(children: [
          _BackButton(),
          const SizedBox(width: 12),
          Text(title,
              style: GoogleFonts.dmSans(
                  color: DS.textPrimary(context),
                  fontSize: 17,
                  fontWeight: FontWeight.w700)),
        ]),
      );
}

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => Navigator.of(context).maybePop(),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: DS.surface(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: DS.border(context)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(isDark ? .25 : .04),
                blurRadius: 6),
          ],
        ),
        child: Icon(Icons.arrow_back_ios_new_rounded,
            size: 14, color: DS.textPrimary(context)),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _PrimaryButton(
      {required this.label, required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          decoration: BoxDecoration(
            color: DS.blue,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: DS.blue.withOpacity(.25),
                  blurRadius: 14,
                  offset: const Offset(0, 5)),
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

// ─── Ring painter ─────────────────────────────────────────────────────────────
class _RingPainter extends CustomPainter {
  final Color color;
  final double strokeWidth, dashFraction;
  const _RingPainter(
      {required this.color,
      required this.strokeWidth,
      required this.dashFraction});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final arc = 2 * math.pi * dashFraction;
    final gap = 2 * math.pi * (1 - dashFraction) / 3;
    for (int i = 0; i < 3; i++) {
      paint.color = color.withOpacity(.6 - i * .15);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * (arc + gap),
        arc,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => false;
}
