// ─────────────────────────────────────────────────────────────────────────
// Backtest Screener — saved algos, condition builder, run/preview.
//
// Talks to the FastAPI service (main.py v2): every request carries the
// signed-in user's Firebase ID token, so the backend always knows who's
// asking without a user_id ever appearing in a request body.
//
// pubspec.yaml needs (in addition to firebase_auth, already used elsewhere):
//   http: ^1.2.0
//   syncfusion_flutter_charts: ^24.1.41
//
// Wire up with:
//   Navigator.push(context, MaterialPageRoute(
//     builder: (_) => SavedBacktestsPage(),
//   ));
// ─────────────────────────────────────────────────────────────────────────

import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:optionxi/Main_Pages/IndicatorBacktest/Alerts/alert-indicator-list.dart';
import 'package:optionxi/Main_Pages/IndicatorBacktest/algo_marketplace.dart';
import 'package:optionxi/Main_Pages/IndicatorBacktest/backtest-detailpage.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

// ─────────────────────────────────────────────
// PLAN LIMITS — saved algos
// ─────────────────────────────────────────────
const int kFreeAlgoLimit = 3;
const int kBasicAlgoLimit = 10;
const int kProAlgoLimit = 50;
const int kMaxAlgoLimit = 50;

const Map<String, int> kPlanAlgoLimits = {
  'basic': kBasicAlgoLimit,
  'pro': kProAlgoLimit,
  'max': kMaxAlgoLimit,
};

int algoLimitForPlan(String? planKey) {
  if (planKey == null) return kFreeAlgoLimit;
  return kPlanAlgoLimits[planKey.toLowerCase()] ?? kFreeAlgoLimit;
}

// ─────────────────────────────────────────────
// THEME
// ─────────────────────────────────────────────

class _T {
  static const accent = Color(0xFF5B7FFF);
  static const accentSoft = Color(0xFF8BA3FF);
  static const violet = Color(0xFF9B6DFF);
  static const green = Color(0xFF00C896);
  static const red = Color(0xFFFF4D6D);
  static const amber = Color(0xFFFFAB00);

  static Color bg(bool d) =>
      d ? const Color(0xFF0B0D15) : const Color(0xFFF0F2F8);
  static Color surface(bool d) => d ? const Color(0xFF161927) : Colors.white;
  static Color surface2(bool d) =>
      d ? const Color(0xFF1E2235) : const Color(0xFFF7F8FF);
  static Color border(bool d) =>
      d ? const Color(0xFF252840) : const Color(0xFFE4E7F2);
  static Color text(bool d) =>
      d ? const Color(0xFFEEF0FF) : const Color(0xFF0F1124);
  static Color sub(bool d) =>
      d ? const Color(0xFF7880A0) : const Color(0xFF8890B0);

  static const gradient = LinearGradient(colors: [accent, violet]);
}

// ─────────────────────────────────────────────
// INDICATOR SPECS (mirrors indicators.INDICATOR_SPECS / OPERATORS)
// ─────────────────────────────────────────────

const Map<String, List<List<dynamic>>> kIndicatorParamSpecs = {
  'close': [],
  'open': [],
  'high': [],
  'low': [],
  'volume': [],
  'sma': [
    ['length', 20]
  ],
  'ema': [
    ['length', 20]
  ],
  'rsi': [
    ['length', 14]
  ],
  'stochrsi': [
    ['length', 14]
  ],
  'adx': [
    ['length', 14]
  ],
  'plus_di': [
    ['length', 14]
  ],
  'minus_di': [
    ['length', 14]
  ],
  'aroon_up': [
    ['length', 25]
  ],
  'aroon_down': [
    ['length', 25]
  ],
  'psar': [
    ['start', 0.02],
    ['increment', 0.02],
    ['max', 0.2]
  ],
  'supertrend': [
    ['period', 10],
    ['multiplier', 3.0]
  ],
  'number': [
    ['value', 0.0]
  ],
};

const Map<String, String> kIndicatorLabels = {
  'close': 'Close',
  'open': 'Open',
  'high': 'High',
  'low': 'Low',
  'volume': 'Volume',
  'sma': 'SMA',
  'ema': 'EMA',
  'rsi': 'RSI',
  'stochrsi': 'StochRSI',
  'adx': 'ADX',
  'plus_di': 'ADX +DI',
  'minus_di': 'ADX -DI',
  'aroon_up': 'Aroon Up',
  'aroon_down': 'Aroon Down',
  'psar': 'Parabolic SAR',
  'supertrend': 'Supertrend',
  'number': 'Fixed number',
};

const Map<String, List<String>> kIndicatorGroups = {
  'Price': ['close', 'open', 'high', 'low', 'volume'],
  'Moving Averages': ['sma', 'ema'],
  'Momentum': ['rsi', 'stochrsi'],
  'Trend': [
    'adx',
    'plus_di',
    'minus_di',
    'aroon_up',
    'aroon_down',
    'supertrend',
    'psar'
  ],
  'Other': ['number'],
};

const List<String> kOperators = [
  '>',
  '<',
  '>=',
  '<=',
  '==',
  'crosses above',
  'crosses below'
];

String _opSymbol(String op) => op;

// ─────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────

class ExpressionModel {
  String kind;
  Map<String, dynamic> params;
  int shift;

  ExpressionModel({required this.kind, required this.params, this.shift = 0});

  static Map<String, dynamic> defaultParams(String kind) {
    final specs = kIndicatorParamSpecs[kind] ?? [];
    return {for (final p in specs) p[0] as String: p[1]};
  }

  factory ExpressionModel.forKind(String kind) =>
      ExpressionModel(kind: kind, params: defaultParams(kind));

  factory ExpressionModel.fromJson(Map<String, dynamic> j) => ExpressionModel(
        kind: j['kind'] ?? 'close',
        params: Map<String, dynamic>.from(j['params'] ?? {}),
        shift: j['shift'] ?? 0,
      );

  Map<String, dynamic> toJson() =>
      {'kind': kind, 'params': params, 'shift': shift};

  bool get hasParams => (kIndicatorParamSpecs[kind] ?? []).isNotEmpty;

  String get label {
    final base = kIndicatorLabels[kind] ?? kind;
    if (!hasParams) return shift > 0 ? '$base [-$shift]' : base;
    final vals = (kIndicatorParamSpecs[kind] ?? [])
        .map((p) => _fmtNum(params[p[0]] ?? p[1]))
        .join(', ');
    final withParams = '$base($vals)';
    return shift > 0 ? '$withParams [-$shift]' : withParams;
  }

  static String _fmtNum(dynamic v) {
    if (v is double) {
      return v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();
    }
    return v.toString();
  }
}

class ConditionModel {
  ExpressionModel left;
  String operator;
  ExpressionModel right;

  ConditionModel(
      {ExpressionModel? left, this.operator = '>', ExpressionModel? right})
      : left = left ?? ExpressionModel.forKind('close'),
        right = right ?? ExpressionModel.forKind('sma');

  factory ConditionModel.fromJson(Map<String, dynamic> j) => ConditionModel(
        left: ExpressionModel.fromJson(Map<String, dynamic>.from(j['left'])),
        operator: j['operator'] ?? '>',
        right: ExpressionModel.fromJson(Map<String, dynamic>.from(j['right'])),
      );

  Map<String, dynamic> toJson() =>
      {'left': left.toJson(), 'operator': operator, 'right': right.toJson()};

  String get summary => '${left.label}  $operator  ${right.label}';
}

class EntryModel {
  final DateTime time;
  final double open, high, low, close, volume;
  final double? fwdReturnPct;
  final String outcome;

  EntryModel({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
    required this.fwdReturnPct,
    required this.outcome,
  });

  factory EntryModel.fromJson(Map<String, dynamic> j) => EntryModel(
        time: DateTime.tryParse(j['time'] ?? '') ?? DateTime.now(),
        open: (j['open'] as num).toDouble(),
        high: (j['high'] as num).toDouble(),
        low: (j['low'] as num).toDouble(),
        close: (j['close'] as num).toDouble(),
        volume: (j['volume'] as num).toDouble(),
        fwdReturnPct: (j['fwd_return_pct'] as num?)?.toDouble(),
        outcome: j['outcome'] ?? 'Pending',
      );
}

class SavedBacktestModel {
  final String id;
  final String name;
  final String symbol;
  final int days;
  final String direction;
  final int confirmBars;
  final List<ConditionModel> conditions;

  final DateTime? lastRunAt;
  final int? totalBars, matchedBars, confirmed, failed, pending;
  final double? hitRate;
  final List<EntryModel> entries;

  // Notification state -- an "alert" is just this same algo with
  // is_alert_enabled = true server-side (see schema.sql). There is no
  // separate alert object.
  final bool isAlertEnabled;
  final DateTime? lastCheckedAt;
  final DateTime? lastAlertedAt;

  SavedBacktestModel({
    required this.id,
    required this.name,
    required this.symbol,
    required this.days,
    required this.direction,
    required this.confirmBars,
    required this.conditions,
    this.lastRunAt,
    this.totalBars,
    this.matchedBars,
    this.confirmed,
    this.failed,
    this.pending,
    this.hitRate,
    this.entries = const [],
    this.isAlertEnabled = false,
    this.lastCheckedAt,
    this.lastAlertedAt,
  });

  factory SavedBacktestModel.fromJson(Map<String, dynamic> j) =>
      SavedBacktestModel(
        id: j['id'].toString(),
        name: j['name'] ?? '',
        symbol: j['symbol'] ?? 'NIFTY',
        days: j['days'] ?? 14,
        direction: j['direction'] ?? 'Bullish',
        confirmBars: j['confirm_bars'] ?? 3,
        conditions: ((j['conditions'] as List?) ?? [])
            .map((c) => ConditionModel.fromJson(Map<String, dynamic>.from(c)))
            .toList(),
        lastRunAt: j['last_run_at'] != null
            ? DateTime.tryParse(j['last_run_at'])
            : null,
        totalBars: j['total_bars'],
        matchedBars: j['matched_bars'],
        confirmed: j['confirmed'],
        failed: j['failed'],
        pending: j['pending'],
        hitRate: (j['hit_rate'] as num?)?.toDouble(),
        entries: ((j['entries'] as List?) ?? [])
            .map((e) => EntryModel.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        isAlertEnabled: j['is_alert_enabled'] ?? false,
        lastCheckedAt: j['last_checked_at'] != null
            ? DateTime.tryParse(j['last_checked_at'])
            : null,
        lastAlertedAt: j['last_alerted_at'] != null
            ? DateTime.tryParse(j['last_alerted_at'])
            : null,
      );

  bool get hasRun => lastRunAt != null;

  SavedBacktestModel copyWith({
    bool? isAlertEnabled,
    DateTime? lastCheckedAt,
    DateTime? lastAlertedAt,
  }) =>
      SavedBacktestModel(
        id: id,
        name: name,
        symbol: symbol,
        days: days,
        direction: direction,
        confirmBars: confirmBars,
        conditions: conditions,
        lastRunAt: lastRunAt,
        totalBars: totalBars,
        matchedBars: matchedBars,
        confirmed: confirmed,
        failed: failed,
        pending: pending,
        hitRate: hitRate,
        entries: entries,
        isAlertEnabled: isAlertEnabled ?? this.isAlertEnabled,
        lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
        lastAlertedAt: lastAlertedAt ?? this.lastAlertedAt,
      );
}

/// `/alerts/limit` response -- tells the app exactly where the user
/// stands instead of the app hardcoding plan limits itself.
class AlertLimitModel {
  final String plan;
  final bool isAlertsAvailable;
  final int limit;
  final int used;
  final int remaining;

  AlertLimitModel({
    required this.plan,
    required this.isAlertsAvailable,
    required this.limit,
    required this.used,
    required this.remaining,
  });

  factory AlertLimitModel.fromJson(Map<String, dynamic> j) => AlertLimitModel(
        plan: j['plan'] ?? 'free',
        isAlertsAvailable: j['is_alerts_available'] ?? false,
        limit: j['limit'] ?? 0,
        used: j['used'] ?? 0,
        remaining: j['remaining'] ?? 0,
      );
}

// ─────────────────────────────────────────────
// API SERVICE
// ─────────────────────────────────────────────

class BacktestApiException implements Exception {
  final String message;
  BacktestApiException(this.message);
  @override
  String toString() => message;
}

class BacktestApiService {
  final String baseUrl;
  BacktestApiService({required this.baseUrl});

  Future<Map<String, String>> _headers() async {
    final user = FirebaseAuth.instance.currentUser;
    final token = await user?.getIdToken();
    if (token == null) {
      throw BacktestApiException('Not signed in');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    };
  }

  void _checkOk(http.Response res) {
    if (res.statusCode >= 400) {
      String msg = 'Request failed (${res.statusCode})';
      try {
        final body = jsonDecode(res.body);
        if (body is Map && body['detail'] != null) {
          msg = body['detail'].toString();
        }
      } catch (_) {}
      throw BacktestApiException(msg);
    }
  }

  // Uses real fetching to check user's plan. Relies on accurate backend responses.
  Future<String> getUserPlan() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/current-subscription'),
        headers: await _headers(),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return body['plan'] ?? 'free'; // 'free', 'pro', or 'max'
      }
    } catch (_) {}
    return 'free'; // default fallback
  }

  Future<List<SavedBacktestModel>> listAlgos() async {
    final res =
        await http.get(Uri.parse('$baseUrl/algos'), headers: await _headers());
    _checkOk(res);
    final list = jsonDecode(res.body) as List;
    return list
        .map((e) => SavedBacktestModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<SavedBacktestModel> createAlgo({
    required String name,
    required String symbol,
    required int days,
    required String direction,
    required int confirmBars,
    required List<ConditionModel> conditions,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/algos'),
      headers: await _headers(),
      body: jsonEncode({
        'name': name,
        'symbol': symbol,
        'days': days,
        'direction': direction,
        'confirm_bars': confirmBars,
        'conditions': conditions.map((c) => c.toJson()).toList(),
      }),
    );
    _checkOk(res);
    return SavedBacktestModel.fromJson(jsonDecode(res.body));
  }

  Future<SavedBacktestModel> updateAlgo({
    required String id,
    required String name,
    required String symbol,
    required int days,
    required String direction,
    required int confirmBars,
    required List<ConditionModel> conditions,
  }) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/algos/$id'),
      headers: await _headers(),
      body: jsonEncode({
        'name': name,
        'symbol': symbol,
        'days': days,
        'direction': direction,
        'confirm_bars': confirmBars,
        'conditions': conditions.map((c) => c.toJson()).toList(),
      }),
    );
    _checkOk(res);
    return SavedBacktestModel.fromJson(jsonDecode(res.body));
  }

  Future<void> deleteAlgo(String id) async {
    final res = await http.delete(Uri.parse('$baseUrl/algos/$id'),
        headers: await _headers());
    _checkOk(res);
  }

  Future<SavedBacktestModel> runAlgo(String id) async {
    final res = await http.post(Uri.parse('$baseUrl/algos/$id/run'),
        headers: await _headers());
    _checkOk(res);
    return SavedBacktestModel.fromJson(jsonDecode(res.body));
  }

  Future<SavedBacktestModel> preview({
    required String symbol,
    required int days,
    required String direction,
    required int confirmBars,
    required List<ConditionModel> conditions,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/backtest/preview'),
      headers: await _headers(),
      body: jsonEncode({
        'symbol': symbol,
        'days': days,
        'direction': direction,
        'confirm_bars': confirmBars,
        'conditions': conditions.map((c) => c.toJson()).toList(),
      }),
    );
    _checkOk(res);
    return SavedBacktestModel.fromJson(jsonDecode(res.body));
  }

  // ── Alerts / notifications ──────────────────────────────────────
  // An alert is just this same algo with is_alert_enabled = true --
  // there is no separate alert entity or endpoint family beyond these.

  Future<AlertLimitModel> getAlertLimit() async {
    final res = await http.get(Uri.parse('$baseUrl/alerts/limit'),
        headers: await _headers());
    _checkOk(res);
    return AlertLimitModel.fromJson(jsonDecode(res.body));
  }

  Future<List<SavedBacktestModel>> listAlertAlgos() async {
    final res = await http.get(Uri.parse('$baseUrl/algos/alerts'),
        headers: await _headers());
    _checkOk(res);
    final list = jsonDecode(res.body) as List;
    return list
        .map((e) => SavedBacktestModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<SavedBacktestModel> enableAlert(String algoId) async {
    final res = await http.post(
        Uri.parse('$baseUrl/algos/$algoId/alert/enable'),
        headers: await _headers());
    _checkOk(res);
    return SavedBacktestModel.fromJson(jsonDecode(res.body));
  }

  Future<SavedBacktestModel> disableAlert(String algoId) async {
    final res = await http.post(
        Uri.parse('$baseUrl/algos/$algoId/alert/disable'),
        headers: await _headers());
    _checkOk(res);
    return SavedBacktestModel.fromJson(jsonDecode(res.body));
  }
}

// ─────────────────────────────────────────────
// SMALL HELPERS
// ─────────────────────────────────────────────

Color _outcomeColor(String outcome) {
  switch (outcome) {
    case 'Confirmed':
      return _T.green;
    case 'Failed':
      return _T.red;
    default:
      return _T.amber;
  }
}

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
  if (diff.inDays > 0) return '${diff.inDays}d ago';
  if (diff.inHours > 0) return '${diff.inHours}h ago';
  if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
  return 'Just now';
}

void _snack(BuildContext context, String msg, {required bool ok}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Row(children: [
      Icon(ok ? Icons.check_circle_rounded : Icons.error_outline_rounded,
          color: ok ? _T.green : _T.red, size: 16),
      const SizedBox(width: 8),
      Expanded(
          child: Text(msg,
              style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFFEEF0FF),
                  fontWeight: FontWeight.w500))),
    ]),
    backgroundColor: const Color(0xFF252840),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    margin: const EdgeInsets.all(12),
    duration: const Duration(seconds: 3),
  ));
}

// ─────────────────────────────────────────────
// SHARED COMPONENTS
// ─────────────────────────────────────────────

class _Card extends StatelessWidget {
  final bool dark;
  final Widget child;
  const _Card({
    required this.dark,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _T.surface(dark),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _T.border(dark)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(dark ? 0.18 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3)),
          ],
        ),
        child: child,
      );
}

// Matches the real _AlgoCard's single-row shape exactly (icon block +
// two text lines + a circular gauge) so the list doesn't "jump" in
// height once real data replaces the loading placeholders.
class _SkeletonCard extends StatelessWidget {
  final bool dark;
  const _SkeletonCard({required this.dark});

  @override
  Widget build(BuildContext context) {
    final baseColor = dark ? const Color(0xFF252840) : const Color(0xFFE4E7F2);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _T.surface(dark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _T.border(dark)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: baseColor, borderRadius: BorderRadius.circular(12)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 14, width: 130, color: baseColor),
                const SizedBox(height: 8),
                Container(height: 10, width: 95, color: baseColor),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(color: baseColor, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SAVED BACKTESTS PAGE (list / entry point)
// ─────────────────────────────────────────────

class SavedBacktestsPage extends StatefulWidget {
  const SavedBacktestsPage({super.key});

  @override
  State<SavedBacktestsPage> createState() => _SavedBacktestsPageState();
}

class _SavedBacktestsPageState extends State<SavedBacktestsPage> {
  final apiBaseUrl = dotenv.env['BACKTEST_API_BASE_URL']!;

  late final BacktestApiService _api = BacktestApiService(baseUrl: apiBaseUrl);
  List<SavedBacktestModel> _algos = [];
  bool _loading = true;
  String? _error;
  final Set<String> _runningIds = {};

  // ── NEW: plan/limit tracking for the usage banner ──
  String? _plan;
  int _algoLimit = kFreeAlgoLimit;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _api.listAlgos(),
        _api.getUserPlan(),
      ]);
      if (!mounted) return;
      setState(() {
        _algos = results[0] as List<SavedBacktestModel>;
        _plan = results[1] as String;
        _algoLimit = algoLimitForPlan(_plan);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showUpgradeDialog(String currentPlan) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _T.surface(_isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Limit Reached',
            style: TextStyle(
                color: _T.text(_isDark), fontWeight: FontWeight.w700)),
        content: Text(
          currentPlan == 'max'
              ? 'You have reached the absolute maximum limit of $kMaxAlgoLimit algos.'
              : 'You have reached your limit of ${algoLimitForPlan(currentPlan)} algos. Upgrade to OptionXi Pro for ₹1500/month or Max to unlock more capacity.',
          style: TextStyle(color: _T.sub(_isDark), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: _T.sub(_isDark))),
          ),
          if (currentPlan != 'max')
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: _T.accent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              onPressed: () {
                Navigator.pop(context);
                // Trigger optionxi.com billing/upgrade flow here
                _snack(context, 'Redirecting to billing...', ok: true);
              },
              child: const Text('Upgrade Now',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }

  Widget _buildUsageBanner(bool dark) {
    final used = _algos.length;
    final max = _algoLimit;
    final pct = max == 0 ? 0.0 : (used / max).clamp(0.0, 1.0);
    final color = pct >= 1.0
        ? _T.red
        : pct >= 0.7
            ? _T.amber
            : _T.green;
    final showUpgrade = (_plan ?? 'free').toLowerCase() != 'max';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$used / $max algos saved',
                  style: TextStyle(
                      color: _T.sub(dark),
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
              if (showUpgrade)
                GestureDetector(
                  onTap: () => _showUpgradeDialog(_plan ?? 'free'),
                  child: Row(children: [
                    Text('Upgrade',
                        style: TextStyle(
                            color: _T.amber,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(width: 2),
                    Icon(Icons.arrow_forward_rounded,
                        color: _T.amber, size: 14),
                  ]),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: _T.border(dark).withOpacity(0.5),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _checkPlanAndCreate() async {
    final currentCount = _algos.length;
    if (currentCount >= _algoLimit) {
      _showUpgradeDialog(_plan ?? 'free');
      return;
    }
    _openEditor();
  }

  Future<void> _browseMajorAlgos() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CommunityAlgosBrowsePage(api: _api)),
    );
    if (saved == true) _load();
  }

  Future<void> _openEditor({SavedBacktestModel? algo}) async {
    final changed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
            builder: (_) => BacktestEditorPage(api: _api, algo: algo)));
    if (changed == true) _load();
  }

  void _viewResults(SavedBacktestModel algo) {
    if (!algo.hasRun) {
      _snack(context, 'Run the backtest first to see results.', ok: false);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SavedBacktestDetailPage(
          api: _api,
          algo: algo,
        ),
      ),
    );
  }

  Future<void> _run(SavedBacktestModel algo) async {
    setState(() => _runningIds.add(algo.id));
    HapticFeedback.lightImpact();
    try {
      final updated = await _api.runAlgo(algo.id);
      if (!mounted) return;
      setState(() {
        final i = _algos.indexWhere((a) => a.id == algo.id);
        if (i != -1) _algos[i] = updated;
      });
      _snack(context, 'Run complete — ${updated.matchedBars ?? 0} matches',
          ok: true);

      // Navigate to the results page now that data is ready
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SavedBacktestDetailPage(
            api: _api,
            algo: updated,
          ),
        ),
      );
    } catch (e) {
      if (mounted) _snack(context, e.toString(), ok: false);
    } finally {
      if (mounted) setState(() => _runningIds.remove(algo.id));
    }
  }

  Future<void> _delete(SavedBacktestModel algo) async {
    final dark = _isDark;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _T.surface(dark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Algo',
            style:
                TextStyle(color: _T.text(dark), fontWeight: FontWeight.w700)),
        content: Text('Delete "${algo.name}"? This cannot be undone.',
            style: TextStyle(color: _T.sub(dark), fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: TextStyle(color: _T.sub(dark)))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Delete',
                  style:
                      TextStyle(color: _T.red, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _api.deleteAlgo(algo.id);
      if (mounted) {
        setState(() => _algos.removeWhere((a) => a.id == algo.id));
        _snack(context, 'Algo deleted', ok: true);
      }
    } catch (e) {
      if (mounted) _snack(context, e.toString(), ok: false);
    }
  }

  // Opens the "what do you want to do with this algo" sheet. All of
  // Run / Edit / Delete / View results close the sheet first, then run
  // the exact same logic the old inline buttons used to call — nothing
  // about _run/_openEditor/_delete/_viewResults needed to change.
  Future<void> _openActionSheet(SavedBacktestModel algo) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => _AlgoActionSheet(
        api: _api,
        algo: algo,
        plan: _plan ?? 'free',
        running: _runningIds.contains(algo.id),
        onRun: () {
          Navigator.pop(sheetContext);
          _run(algo);
        },
        onEdit: () {
          Navigator.pop(sheetContext);
          _openEditor(algo: algo);
        },
        onDelete: () {
          Navigator.pop(sheetContext);
          _delete(algo);
        },
        onViewResults: () {
          Navigator.pop(sheetContext);
          _viewResults(algo);
        },
        onAlertChanged: (updated) {
          setState(() {
            final i = _algos.indexWhere((x) => x.id == updated.id);
            if (i != -1) _algos[i] = updated;
          });
        },
        onNeedsUpgrade: () => _showUpgradeDialog(_plan ?? 'free'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = _isDark;
    return Scaffold(
      backgroundColor: _T.bg(dark),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _checkPlanAndCreate(),
        backgroundColor: _T.accent,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New Algo',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      appBar: AppBar(
        backgroundColor: _T.surface(dark),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Backtest Algos',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _T.text(dark))),
          if (!_loading && _error == null)
            Text('${_algos.length} saved',
                style: TextStyle(fontSize: 11, color: _T.sub(dark))),
        ]),
        actions: [
          IconButton(
            tooltip: 'Alerts',
            icon: Icon(Icons.notifications_none_rounded, color: _T.text(dark)),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => AlertsListPage(api: _api))),
          ),
        ],
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Divider(height: 1, color: _T.border(dark))),
      ),
      body: Column(
        children: [
          if (!_loading && _error == null) _buildUsageBanner(dark),
          Expanded(
            child: _loading
                ? ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
                    itemCount: 4,
                    itemBuilder: (_, __) => _SkeletonCard(dark: dark),
                  )
                : _error != null
                    ? _ErrorState(dark: dark, error: _error!, onRetry: _load)
                    : _algos.isEmpty
                        ? _EmptyAlgosState(
                            dark: dark,
                            onCreate: () => _checkPlanAndCreate(),
                            onBrowse: () => _browseMajorAlgos())
                        : RefreshIndicator(
                            color: _T.accent,
                            onRefresh: _load,
                            child: ListView.separated(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 14, 16, 100),
                              itemCount: _algos.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (_, i) {
                                final a = _algos[i];
                                return GestureDetector(
                                  onTap: () => _openActionSheet(a),
                                  child: _AlgoCard(algo: a, dark: dark),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _EmptyAlgosState extends StatelessWidget {
  final bool dark;
  final VoidCallback onCreate;
  final VoidCallback onBrowse;
  const _EmptyAlgosState({
    required this.dark,
    required this.onCreate,
    required this.onBrowse,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = dark ? const Color(0xFF1C1F26) : Colors.white;
    final shadowColor = dark ? Colors.black : const Color(0xFF101828);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: shadowColor.withValues(alpha: dark ? 0.4 : 0.06),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
              border: Border.all(
                color: _T.sub(dark).withValues(alpha: 0.08),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ---- Icon with soft glow ----
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _T.accent.withValues(alpha: 0.14),
                        _T.accent.withValues(alpha: 0.04),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _T.accent.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: ShaderMask(
                      shaderCallback: (rect) => _T.gradient.createShader(rect),
                      child: const Icon(
                        Icons.auto_graph_rounded,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ---- Title & subtitle ----
                Text(
                  'No saved algos yet',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: _T.text(dark),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Browse ready-made backtest logics to get started fast,\nor build your own set of conditions from scratch.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: _T.sub(dark),
                  ),
                ),
                const SizedBox(height: 32),

                // ---- Primary CTA ----
                _FancyButton(
                  onTap: onBrowse,
                  gradient: _T.gradient,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.travel_explore_rounded,
                          size: 18, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Browse backtest logics',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // ---- Secondary CTA ----
                TextButton(
                  onPressed: onCreate,
                  style: TextButton.styleFrom(
                    foregroundColor: _T.sub(dark),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Create your own from scratch',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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

/// Tappable primary button with a subtle lift on press.
class _FancyButton extends StatefulWidget {
  final VoidCallback onTap;
  final Gradient gradient;
  final Widget child;
  const _FancyButton({
    required this.onTap,
    required this.gradient,
    required this.child,
  });

  @override
  State<_FancyButton> createState() => _FancyButtonState();
}

class _FancyButtonState extends State<_FancyButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4F46E5).withValues(alpha: 0.35),
                blurRadius: _pressed ? 8 : 16,
                offset: Offset(0, _pressed ? 2 : 6),
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final bool dark;
  final String error;
  final VoidCallback onRetry;
  const _ErrorState(
      {required this.dark, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.error_outline_rounded, size: 44, color: _T.red),
            const SizedBox(height: 12),
            Text('Something went wrong',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _T.text(dark))),
            const SizedBox(height: 4),
            Text(error,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: _T.sub(dark))),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                    color: _T.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _T.accent.withOpacity(0.3))),
                child: Text('Retry',
                    style: TextStyle(
                        fontSize: 13,
                        color: _T.accent,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      );
}

// ─────────────────────────────────────────────
// HIT RATE GAUGE (small circular "78%" indicator)
// ─────────────────────────────────────────────

class _HitRateGauge extends StatelessWidget {
  final double? value; // 0-100, null = not run yet
  final bool dark;
  final double size;
  const _HitRateGauge(
      {required this.value, required this.dark, this.size = 50});

  Color get _color {
    if (value == null) return _T.sub(dark);
    if (value! >= 60) return _T.green;
    if (value! >= 40) return _T.amber;
    return _T.red;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GaugePainter(
          progress: (value ?? 0) / 100,
          color: _color,
          trackColor: _T.border(dark),
        ),
        child: Center(
          child: value == null
              ? Icon(Icons.remove_rounded,
                  size: size * 0.34, color: _T.sub(dark))
              : Text('${value!.round()}%',
                  style: TextStyle(
                      fontSize: size * 0.24,
                      fontWeight: FontWeight.w800,
                      color: _color)),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  _GaugePainter(
      {required this.progress, required this.color, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final strokeWidth = size.shortestSide * 0.12;
    final radius = (size.shortestSide - strokeWidth) / 2;
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);
    const start = -3.14159265 / 2;
    final sweep = 2 * 3.14159265 * progress.clamp(0.0, 1.0);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start,
        sweep, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

// ─────────────────────────────────────────────
// ALGO CARD
// ─────────────────────────────────────────────

// A single algo, shown as one simple row. Tapping it is the ONLY
// interaction here — Run / Edit / Delete / Notify all live in the
// bottom sheet opened by the parent's onTap. Keeps the list scannable
// and puts the "dangerous" or "technical" actions behind one deliberate tap.
class _AlgoCard extends StatelessWidget {
  final SavedBacktestModel algo;
  final bool dark;

  const _AlgoCard({
    required this.algo,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    final bullish = algo.direction == 'Bullish';
    final dirColor = bullish ? _T.green : _T.red;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _T.surface(dark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _T.border(dark)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(dark ? 0.18 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
              color: _T.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(
              bullish ? Icons.trending_up_rounded : Icons.trending_down_rounded,
              color: dirColor,
              size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(algo.name,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _T.text(dark)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Text(
                bullish
                    ? 'Watching ${algo.symbol} for a move up'
                    : 'Watching ${algo.symbol} for a move down',
                style: TextStyle(fontSize: 12, color: _T.sub(dark)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            if (algo.isAlertEnabled)
              Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.notifications_active_rounded,
                    size: 11, color: _T.amber),
                const SizedBox(width: 4),
                Text('Notifying you',
                    style: TextStyle(
                        fontSize: 10,
                        color: _T.amber,
                        fontWeight: FontWeight.w600)),
              ])
            else
              Text(
                algo.hasRun
                    ? 'Checked ${_timeAgo(algo.lastRunAt!)}'
                    : 'Not run yet · tap to run',
                style: TextStyle(fontSize: 10, color: _T.sub(dark)),
              ),
          ]),
        ),
        const SizedBox(width: 10),
        _HitRateGauge(value: algo.hitRate, dark: dark, size: 50),
        const SizedBox(width: 2),
        Icon(Icons.chevron_right_rounded, size: 18, color: _T.sub(dark)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────
// ALGO ACTION SHEET — what you get when you tap a saved algo.
// Run / Edit / Delete / Notify-me all live here, in plain language,
// instead of as small icons crammed onto the card itself.
// ─────────────────────────────────────────────

class _AlgoActionSheet extends StatefulWidget {
  final BacktestApiService api;
  final SavedBacktestModel algo;
  final String plan;
  final bool running;
  final VoidCallback onRun;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onViewResults;
  final ValueChanged<SavedBacktestModel> onAlertChanged;
  final VoidCallback onNeedsUpgrade;

  const _AlgoActionSheet({
    required this.api,
    required this.algo,
    required this.plan,
    required this.running,
    required this.onRun,
    required this.onEdit,
    required this.onDelete,
    required this.onViewResults,
    required this.onAlertChanged,
    required this.onNeedsUpgrade,
  });

  @override
  State<_AlgoActionSheet> createState() => _AlgoActionSheetState();
}

class _AlgoActionSheetState extends State<_AlgoActionSheet> {
  late bool _alertOn = widget.algo.isAlertEnabled;
  bool _alertBusy = false;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  // Premium logic lives right here: before switching notifications on,
  // ask the backend if this plan even allows alerts and whether the
  // user has room left. Only call enable/disable once that's settled.
  Future<void> _toggleAlert(bool wantOn) async {
    setState(() => _alertBusy = true);
    try {
      if (wantOn) {
        final limit = await widget.api.getAlertLimit();
        if (!limit.isAlertsAvailable || limit.remaining <= 0) {
          if (mounted) {
            Navigator.pop(context); // close the sheet
            widget.onNeedsUpgrade(); // parent shows the upgrade dialog
          }
          return;
        }
        final updated = await widget.api.enableAlert(widget.algo.id);
        widget.onAlertChanged(updated);
        if (mounted) setState(() => _alertOn = true);
      } else {
        final updated = await widget.api.disableAlert(widget.algo.id);
        widget.onAlertChanged(updated);
        if (mounted) setState(() => _alertOn = false);
      }
    } catch (e) {
      if (mounted) _snack(context, e.toString(), ok: false);
    } finally {
      if (mounted) setState(() => _alertBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = _isDark;
    final algo = widget.algo;
    final bullish = algo.direction == 'Bullish';
    final dirColor = bullish ? _T.green : _T.red;
    final isFreePlan = widget.plan.toLowerCase() == 'free';

    return DraggableScrollableSheet(
      initialChildSize: 0.62,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
            color: _T.surface(dark),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(22))),
        child: ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Center(
                child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                        color: _T.border(dark),
                        borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 18),

            // ── Header: name + plain-language summary ──
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                    color: _T.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(13)),
                child: Icon(
                    bullish
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    color: dirColor,
                    size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(algo.name,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: _T.text(dark))),
                      const SizedBox(height: 3),
                      Text(
                        bullish
                            ? '${algo.symbol} · looking for a move up over ${algo.days} days'
                            : '${algo.symbol} · looking for a move down over ${algo.days} days',
                        style: TextStyle(fontSize: 12, color: _T.sub(dark)),
                      ),
                    ]),
              ),
            ]),

            const SizedBox(height: 20),

            // ── Hit rate, in plain language, with the round gauge ──
            if (algo.hasRun) ...[
              Row(children: [
                _HitRateGauge(value: algo.hitRate, dark: dark, size: 64),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('How often it was right',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _T.text(dark))),
                        const SizedBox(height: 3),
                        Text(
                          'Out of ${algo.matchedBars ?? 0} times this setup showed up, ${algo.confirmed ?? 0} played out and ${algo.failed ?? 0} did not.',
                          style: TextStyle(fontSize: 11, color: _T.sub(dark)),
                        ),
                      ]),
                ),
              ]),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: widget.onViewResults,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('See every match',
                      style: TextStyle(
                          fontSize: 12,
                          color: _T.accent,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 13, color: _T.accent),
                ]),
              ),
            ] else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: _T.surface2(dark),
                    borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  Icon(Icons.info_outline_rounded,
                      size: 16, color: _T.sub(dark)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(
                          'This hasn\'t been run yet — run it to see how it would have done recently.',
                          style: TextStyle(fontSize: 12, color: _T.sub(dark)))),
                ]),
              ),

            const SizedBox(height: 18),
            Divider(color: _T.border(dark)),
            const SizedBox(height: 4),

            // ── Actions, in plain language ──
            _sheetAction(
              dark: dark,
              icon: Icons.play_arrow_rounded,
              iconColor: _T.accent,
              title: algo.hasRun ? 'Run it again' : 'Run it now',
              subtitle: 'Checks how this would have done recently',
              trailing: widget.running
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _T.accent))
                  : Icon(Icons.chevron_right_rounded, color: _T.sub(dark)),
              onTap: widget.running ? null : widget.onRun,
            ),
            _sheetAction(
              dark: dark,
              icon: Icons.edit_rounded,
              iconColor: _T.accentSoft,
              title: 'Edit the setup',
              subtitle: 'Change the symbol, direction or conditions',
              trailing: Icon(Icons.chevron_right_rounded, color: _T.sub(dark)),
              onTap: widget.onEdit,
            ),

            // ── Notification toggle + premium logic ──
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                      color: _T.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.notifications_none_rounded,
                      size: 17, color: _T.amber),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text('Notify me',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _T.text(dark))),
                          if (isFreePlan) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                  color: _T.amber.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20)),
                              child: Text('PRO',
                                  style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w800,
                                      color: _T.amber)),
                            ),
                          ],
                        ]),
                        Text('Get a ping when this setup shows up again',
                            style:
                                TextStyle(fontSize: 10, color: _T.sub(dark))),
                      ]),
                ),
                _alertBusy
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: _T.accent))
                    : Switch(
                        value: _alertOn,
                        activeColor: _T.accent,
                        onChanged: (v) => _toggleAlert(v),
                      ),
              ]),
            ),

            Divider(color: _T.border(dark)),
            const SizedBox(height: 4),
            _sheetAction(
              dark: dark,
              icon: Icons.delete_outline_rounded,
              iconColor: _T.red,
              title: 'Delete this algo',
              subtitle: 'This cannot be undone',
              trailing: const SizedBox.shrink(),
              onTap: widget.onDelete,
              titleColor: _T.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheetAction({
    required bool dark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget trailing,
    required VoidCallback? onTap,
    Color? titleColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
        child: Row(children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 17, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: titleColor ?? _T.text(dark))),
              Text(subtitle,
                  style: TextStyle(fontSize: 10, color: _T.sub(dark))),
            ]),
          ),
          trailing,
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// EDITOR PAGE (create / edit + condition builder + preview + run)
// ─────────────────────────────────────────────

class BacktestEditorPage extends StatefulWidget {
  final BacktestApiService api;
  final SavedBacktestModel? algo;

  const BacktestEditorPage({super.key, required this.api, this.algo});

  @override
  State<BacktestEditorPage> createState() => _BacktestEditorPageState();
}

class _BacktestEditorPageState extends State<BacktestEditorPage> {
  late final _nameCtrl = TextEditingController(text: widget.algo?.name ?? '');
  late String _symbol = widget.algo?.symbol ?? 'NIFTY';
  late double _days = (widget.algo?.days ?? 14).toDouble();
  late String _direction = widget.algo?.direction ?? 'Bullish';
  late int _confirmBars = widget.algo?.confirmBars ?? 3;
  late List<ConditionModel> _conditions = widget.algo != null
      ? widget.algo!.conditions
          .map((c) => ConditionModel.fromJson(c.toJson()))
          .toList()
      : [ConditionModel()];

  bool _saving = false;
  bool _previewing = false;
  SavedBacktestModel? _previewResult;

  bool get _isEditing => widget.algo != null;
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  void _markDirty() => setState(() {
        _previewResult = null;
      });

  Future<void> _preview() async {
    if (_conditions.isEmpty) {
      _snack(context, 'Add at least one condition', ok: false);
      return;
    }
    setState(() => _previewing = true);
    try {
      final result = await widget.api.preview(
        symbol: _symbol,
        days: _days.round(),
        direction: _direction,
        confirmBars: _confirmBars,
        conditions: _conditions,
      );
      if (mounted) setState(() => _previewResult = result);
    } catch (e) {
      if (mounted) _snack(context, e.toString(), ok: false);
    } finally {
      if (mounted) setState(() => _previewing = false);
    }
  }

  Future<void> _save({bool andRun = false}) async {
    if (_nameCtrl.text.trim().isEmpty) {
      _snack(context, 'Give this algo a name', ok: false);
      return;
    }
    if (_conditions.isEmpty) {
      _snack(context, 'Add at least one condition', ok: false);
      return;
    }
    setState(() => _saving = true);
    try {
      SavedBacktestModel saved;
      if (_isEditing) {
        saved = await widget.api.updateAlgo(
          id: widget.algo!.id,
          name: _nameCtrl.text.trim(),
          symbol: _symbol,
          days: _days.round(),
          direction: _direction,
          confirmBars: _confirmBars,
          conditions: _conditions,
        );
      } else {
        saved = await widget.api.createAlgo(
          name: _nameCtrl.text.trim(),
          symbol: _symbol,
          days: _days.round(),
          direction: _direction,
          confirmBars: _confirmBars,
          conditions: _conditions,
        );
      }
      if (andRun) {
        saved = await widget.api.runAlgo(saved.id);
      }
      if (!mounted) return;
      _snack(context, andRun ? 'Saved and run!' : 'Saved!', ok: true);
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) _snack(context, e.toString(), ok: false);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = _isDark;
    return Scaffold(
      backgroundColor: _T.bg(dark),
      appBar: AppBar(
        backgroundColor: _T.surface(dark),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(_isEditing ? 'Edit Algo' : 'New Algo',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: _T.text(dark))),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Divider(height: 1, color: _T.border(dark))),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
        children: [
          _Card(
            dark: dark,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Details',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: _T.text(dark))),
              const SizedBox(height: 12),
              _LabeledField(
                dark: dark,
                label: 'Name',
                child: TextField(
                  controller: _nameCtrl,
                  onChanged: (_) => _markDirty(),
                  style: TextStyle(fontSize: 14, color: _T.text(dark)),
                  decoration: InputDecoration(
                    hintText: 'e.g. RSI + SMA cross',
                    hintStyle: TextStyle(fontSize: 14, color: _T.sub(dark)),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: _LabeledField(
                    dark: dark,
                    label: 'Symbol',
                    child: _SegmentedToggle(
                      options: const ['NIFTY', 'BANKNIFTY'],
                      value: _symbol,
                      dark: dark,
                      onChanged: (v) => setState(() {
                        _symbol = v;
                        _markDirty();
                      }),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              _LabeledField(
                dark: dark,
                label: 'Direction',
                child: _SegmentedToggle(
                  options: const ['Bullish', 'Bearish'],
                  value: _direction,
                  dark: dark,
                  colorFor: (v) => v == 'Bullish' ? _T.green : _T.red,
                  onChanged: (v) => setState(() {
                    _direction = v;
                    _markDirty();
                  }),
                ),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: _LabeledField(
                    dark: dark,
                    label: 'Lookback (days): ${_days.round()}',
                    child: SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: _T.accent,
                        inactiveTrackColor: _T.border(dark),
                        thumbColor: _T.accent,
                        overlayColor: _T.accent.withOpacity(0.15),
                        trackHeight: 3,
                      ),
                      child: Slider(
                        value: _days,
                        min: 1,
                        max: 120,
                        divisions: 119,
                        onChanged: (v) => setState(() {
                          _days = v;
                          _markDirty();
                        }),
                      ),
                    ),
                  ),
                ),
              ]),
              _LabeledField(
                dark: dark,
                label: 'Confirm within (bars): $_confirmBars',
                child: Row(children: [
                  _stepperBtn(dark, Icons.remove_rounded, () {
                    if (_confirmBars > 1) {
                      setState(() {
                        _confirmBars--;
                        _markDirty();
                      });
                    }
                  }),
                  const SizedBox(width: 10),
                  Text('$_confirmBars',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _T.text(dark))),
                  const SizedBox(width: 10),
                  _stepperBtn(dark, Icons.add_rounded, () {
                    if (_confirmBars < 20) {
                      setState(() {
                        _confirmBars++;
                        _markDirty();
                      });
                    }
                  }),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          _Card(
            dark: dark,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.tune_rounded, size: 15, color: _T.accent),
                const SizedBox(width: 7),
                Text('Conditions',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: _T.text(dark))),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                      color: _T.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text('${_conditions.length}',
                      style: TextStyle(
                          fontSize: 10,
                          color: _T.accent,
                          fontWeight: FontWeight.w600)),
                ),
              ]),
              const SizedBox(height: 12),
              for (int i = 0; i < _conditions.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ConditionCard(
                    key: ValueKey(i),
                    index: i,
                    condition: _conditions[i],
                    dark: dark,
                    onChange: () => _markDirty(),
                    onRemove: _conditions.length > 1
                        ? () => setState(() {
                              _conditions.removeAt(i);
                              _markDirty();
                            })
                        : null,
                  ),
                ),
              GestureDetector(
                onTap: () => setState(() {
                  _conditions.add(ConditionModel());
                  _markDirty();
                }),
                child: Row(children: [
                  Icon(Icons.add_circle_outline_rounded,
                      size: 14, color: _T.accent),
                  const SizedBox(width: 5),
                  Text('Add condition',
                      style: TextStyle(
                          fontSize: 12,
                          color: _T.accent,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _previewing ? null : _preview,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: _T.accent.withOpacity(0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: _previewing
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: _T.accent))
                    : Icon(Icons.visibility_outlined,
                        size: 16, color: _T.accent),
                label: Text('Preview',
                    style: TextStyle(
                        color: _T.accent, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                    gradient: _T.gradient,
                    borderRadius: BorderRadius.circular(14)),
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : () => _save(andRun: true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: _saving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_rounded,
                          size: 16, color: Colors.white),
                  label: const Text('Save',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          if (_previewResult != null) ...[
            const SizedBox(height: 6),
            _ResultPanel(
                dark: dark, result: _previewResult!, title: 'Preview result'),
          ],
        ],
      ),
    );
  }

  Widget _stepperBtn(bool dark, IconData icon, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
              color: _T.surface2(dark),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _T.border(dark))),
          child: Icon(icon, size: 15, color: _T.text(dark)),
        ),
      );
}

class _LabeledField extends StatelessWidget {
  final bool dark;
  final String label;
  final Widget child;
  const _LabeledField(
      {required this.dark, required this.label, required this.child});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _T.sub(dark))),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
                color: _T.surface2(dark),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: _T.border(dark))),
            child: child,
          ),
        ]),
      );
}

class _SegmentedToggle extends StatelessWidget {
  final List<String> options;
  final String value;
  final bool dark;
  final ValueChanged<String> onChanged;
  final Color Function(String)? colorFor;
  const _SegmentedToggle(
      {required this.options,
      required this.value,
      required this.dark,
      required this.onChanged,
      this.colorFor});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: options.map((o) {
            final sel = o == value;
            final c = colorFor?.call(o) ?? _T.accent;
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(o),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                      color: sel ? c : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: sel ? c : _T.border(dark))),
                  child: Center(
                      child: Text(o,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: sel ? Colors.white : _T.text(dark)))),
                ),
              ),
            );
          }).toList(),
        ),
      );
}

// ─────────────────────────────────────────────
// CONDITION CARD (left expr / operator / right expr)
// ─────────────────────────────────────────────

class _ConditionCard extends StatefulWidget {
  final int index;
  final ConditionModel condition;
  final bool dark;
  final VoidCallback onChange;
  final VoidCallback? onRemove;

  const _ConditionCard({
    super.key,
    required this.index,
    required this.condition,
    required this.dark,
    required this.onChange,
    required this.onRemove,
  });

  @override
  State<_ConditionCard> createState() => _ConditionCardState();
}

class _ConditionCardState extends State<_ConditionCard> {
  @override
  Widget build(BuildContext context) {
    final dark = widget.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: _T.surface2(dark),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _T.border(dark))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('CONDITION ${widget.index + 1}',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _T.sub(dark),
                  letterSpacing: 0.8)),
          const Spacer(),
          if (widget.onRemove != null)
            GestureDetector(
              onTap: widget.onRemove,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                    color: _T.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6)),
                child: Icon(Icons.close_rounded, size: 12, color: _T.red),
              ),
            ),
        ]),
        const SizedBox(height: 8),
        _ExpressionEditor(
          expr: widget.condition.left,
          dark: dark,
          onChange: () {
            setState(() {});
            widget.onChange();
          },
        ),
        const SizedBox(height: 8),
        Center(
          child: GestureDetector(
            onTap: () => _pickOperator(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                  color: _T.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _T.accent.withOpacity(0.4))),
              child: Text(widget.condition.operator,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _T.accent)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _ExpressionEditor(
          expr: widget.condition.right,
          dark: dark,
          onChange: () {
            setState(() {});
            widget.onChange();
          },
        ),
      ]),
    );
  }

  void _pickOperator(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _OperatorSheet(
        current: widget.condition.operator,
        dark: widget.dark,
        onSelect: (v) {
          Navigator.pop(context);
          setState(() => widget.condition.operator = v);
          widget.onChange();
        },
      ),
    );
  }
}

class _ExpressionEditor extends StatelessWidget {
  final ExpressionModel expr;
  final bool dark;
  final VoidCallback onChange;
  const _ExpressionEditor(
      {required this.expr, required this.dark, required this.onChange});

  void _pickKind(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _IndicatorSheet(
        current: expr.kind,
        dark: dark,
        onSelect: (kind) {
          Navigator.pop(context);
          expr.kind = kind;
          expr.params = ExpressionModel.defaultParams(kind);
          onChange();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final specs = kIndicatorParamSpecs[expr.kind] ?? [];
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: _T.surface(dark),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _T.border(dark))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _pickKind(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                decoration: BoxDecoration(
                    color: _T.accent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: _T.accent.withOpacity(0.3))),
                child: Row(children: [
                  Expanded(
                      child: Text(kIndicatorLabels[expr.kind] ?? expr.kind,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _T.text(dark)))),
                  Icon(Icons.unfold_more_rounded,
                      size: 15, color: _T.sub(dark)),
                ]),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 78,
            child: _MiniNumberField(
              label: 'Shift',
              value: expr.shift.toDouble(),
              dark: dark,
              isInt: true,
              onChanged: (v) {
                expr.shift = v.round();
                onChange();
              },
            ),
          ),
        ]),
        if (specs.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: specs.map((p) {
              final key = p[0] as String;
              final defVal = p[1];
              final val = (expr.params[key] ?? defVal) as num;
              return SizedBox(
                width: 100,
                child: _MiniNumberField(
                  label: key,
                  value: val.toDouble(),
                  dark: dark,
                  isInt: defVal is int,
                  onChanged: (v) {
                    expr.params[key] = defVal is int ? v.round() : v;
                    onChange();
                  },
                ),
              );
            }).toList(),
          ),
        ],
      ]),
    );
  }
}

class _MiniNumberField extends StatefulWidget {
  final String label;
  final double value;
  final bool dark;
  final bool isInt;
  final ValueChanged<double> onChanged;
  const _MiniNumberField(
      {required this.label,
      required this.value,
      required this.dark,
      required this.isInt,
      required this.onChanged});

  @override
  State<_MiniNumberField> createState() => _MiniNumberFieldState();
}

class _MiniNumberFieldState extends State<_MiniNumberField> {
  late final TextEditingController _ctrl =
      TextEditingController(text: _fmt(widget.value));

  String _fmt(double v) => widget.isInt
      ? v.round().toString()
      : (v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString());

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.dark;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(widget.label,
          style: TextStyle(
              fontSize: 9, color: _T.sub(dark), fontWeight: FontWeight.w600)),
      const SizedBox(height: 3),
      Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
            color: _T.surface2(dark),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _T.border(dark))),
        child: TextField(
          controller: _ctrl,
          keyboardType: TextInputType.numberWithOptions(
              decimal: !widget.isInt, signed: true),
          inputFormatters: widget.isInt
              ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9-]'))]
              : [FilteringTextInputFormatter.allow(RegExp(r'[0-9.-]'))],
          style: TextStyle(
              fontSize: 12, color: _T.text(dark), fontWeight: FontWeight.w600),
          decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero),
          onChanged: (v) {
            final parsed = double.tryParse(v);
            if (parsed != null) widget.onChanged(parsed);
          },
        ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────
// PICKER SHEETS
// ─────────────────────────────────────────────

class _IndicatorSheet extends StatefulWidget {
  final String current;
  final bool dark;
  final ValueChanged<String> onSelect;
  const _IndicatorSheet(
      {required this.current, required this.dark, required this.onSelect});

  @override
  State<_IndicatorSheet> createState() => _IndicatorSheetState();
}

class _IndicatorSheetState extends State<_IndicatorSheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final dark = widget.dark;
    final filtered = <String, List<String>>{};
    for (final e in kIndicatorGroups.entries) {
      final items = e.value.where((k) {
        if (_q.isEmpty) return true;
        final q = _q.toLowerCase();
        return (kIndicatorLabels[k] ?? k).toLowerCase().contains(q);
      }).toList();
      if (items.isNotEmpty) filtered[e.key] = items;
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
            color: _T.surface(dark),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(22))),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(children: [
              Center(
                  child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                          color: _T.border(dark),
                          borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 14),
              Text('Select Indicator',
                  style: TextStyle(
                      color: _T.text(dark),
                      fontWeight: FontWeight.w700,
                      fontSize: 16)),
              const SizedBox(height: 12),
              Container(
                height: 42,
                decoration: BoxDecoration(
                    color: _T.surface2(dark),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _T.border(dark))),
                child: Row(children: [
                  const SizedBox(width: 12),
                  Icon(Icons.search_rounded, size: 18, color: _T.sub(dark)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: TextField(
                    onChanged: (v) => setState(() => _q = v),
                    style: TextStyle(fontSize: 14, color: _T.text(dark)),
                    decoration: InputDecoration(
                        hintText: 'Search indicators...',
                        hintStyle: TextStyle(fontSize: 14, color: _T.sub(dark)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero),
                  )),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ListView(
              controller: ctrl,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                for (final entry in filtered.entries) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
                    child: Text(entry.key.toUpperCase(),
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: _T.accent.withOpacity(0.7))),
                  ),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: entry.value.map((k) {
                      final sel = widget.current == k;
                      return GestureDetector(
                        onTap: () => widget.onSelect(k),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 11, vertical: 7),
                          decoration: BoxDecoration(
                              color: sel ? _T.accent : _T.surface2(dark),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: sel ? _T.accent : _T.border(dark))),
                          child: Text(kIndicatorLabels[k] ?? k,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: sel ? Colors.white : _T.text(dark))),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _OperatorSheet extends StatelessWidget {
  final String current;
  final bool dark;
  final ValueChanged<String> onSelect;
  const _OperatorSheet(
      {required this.current, required this.dark, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: _T.surface(dark),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22))),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(
            child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: _T.border(dark),
                    borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        Text('Select Operator',
            style: TextStyle(
                color: _T.text(dark),
                fontWeight: FontWeight.w700,
                fontSize: 16)),
        const SizedBox(height: 14),
        ...kOperators.map((op) {
          final sel = current == op;
          return GestureDetector(
            onTap: () => onSelect(op),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: sel ? _T.accent.withOpacity(0.1) : _T.surface2(dark),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: sel ? _T.accent.withOpacity(0.5) : _T.border(dark)),
              ),
              child: Row(children: [
                Text(_opSymbol(op),
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: sel ? _T.accent : _T.text(dark))),
                if (sel) ...[
                  const Spacer(),
                  Icon(Icons.check_rounded, color: _T.accent, size: 18)
                ],
              ]),
            ),
          );
        }),
      ]),
    );
  }
}

// ─────────────────────────────────────────────
// RESULT PANEL (used for both preview and after Run)
// ─────────────────────────────────────────────

class _ResultPanel extends StatelessWidget {
  final bool dark;
  final SavedBacktestModel result;
  final String title;
  const _ResultPanel(
      {required this.dark, required this.result, required this.title});

  @override
  Widget build(BuildContext context) {
    final hitRate = result.hitRate;
    Color hitColor = _T.sub(dark);
    if (hitRate != null) {
      hitColor = hitRate >= 60 ? _T.green : (hitRate >= 40 ? _T.amber : _T.red);
    }

    final sortedEntries = List<EntryModel>.from(result.entries)
      ..sort((a, b) => a.time.compareTo(b.time));

    return _Card(
      dark: dark,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.insights_rounded, size: 15, color: _T.accent),
          const SizedBox(width: 7),
          Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: _T.text(dark))),
        ]),
        const SizedBox(height: 12),

        // Detailed metrics
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          childAspectRatio: 1.7,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: [
            _stat('Matched', '${result.matchedBars ?? 0}', _T.text(dark)),
            _stat('Confirmed', '${result.confirmed ?? 0}', _T.green),
            _stat('Failed', '${result.failed ?? 0}', _T.red),
            _stat('Pending', '${result.pending ?? 0}', _T.amber),
            _stat('Total bars', '${result.totalBars ?? 0}', _T.sub(dark)),
            _stat(
                'Hit rate',
                hitRate != null ? '${hitRate.toStringAsFixed(1)}%' : '—',
                hitColor),
          ],
        ),

        // Result Chart Integration
        if (sortedEntries.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('Entry Breakdown (Chart)',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _T.text(dark))),
          const SizedBox(height: 8),
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: _T.surface2(dark),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _T.border(dark)),
            ),
            padding: const EdgeInsets.only(top: 10, right: 10),
            child: SfCartesianChart(
              margin: EdgeInsets.zero,
              plotAreaBorderWidth: 0,
              zoomPanBehavior: ZoomPanBehavior(
                enablePanning: true,
                enablePinching: true,
                zoomMode: ZoomMode.x,
              ),
              trackballBehavior: TrackballBehavior(
                enable: true,
                activationMode: ActivationMode.singleTap,
                tooltipSettings: InteractiveTooltip(
                  format: 'point.x : ₹point.y',
                  color: _T.surface(dark),
                  textStyle: TextStyle(color: _T.text(dark), fontSize: 11),
                ),
              ),
              primaryXAxis: DateTimeAxis(
                edgeLabelPlacement: EdgeLabelPlacement.shift,
                majorGridLines: const MajorGridLines(width: 0),
                axisLine: const AxisLine(width: 0),
                labelStyle: TextStyle(color: _T.sub(dark), fontSize: 9),
              ),
              primaryYAxis: NumericAxis(
                majorGridLines: MajorGridLines(
                    color: _T.border(dark), dashArray: const [5, 5]),
                axisLine: const AxisLine(width: 0),
                labelStyle: TextStyle(color: _T.sub(dark), fontSize: 9),
              ),
              series: <CartesianSeries>[
                ScatterSeries<EntryModel, DateTime>(
                  dataSource: sortedEntries,
                  xValueMapper: (e, _) => e.time,
                  yValueMapper: (e, _) => e.close,
                  pointColorMapper: (e, _) => _outcomeColor(e.outcome),
                  markerSettings: const MarkerSettings(
                    shape: DataMarkerType.circle,
                    width: 7,
                    height: 7,
                  ),
                  name: 'Entries',
                )
              ],
            ),
          ),

          // Result List
          const SizedBox(height: 20),
          Text('Matched entries (${result.entries.length})',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _T.text(dark))),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: sortedEntries.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: _T.border(dark)),
              itemBuilder: (_, i) {
                final e = sortedEntries[i];
                final oc = _outcomeColor(e.outcome);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                          '${e.time.day}/${e.time.month} ${e.time.hour.toString().padLeft(2, '0')}:${e.time.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(fontSize: 11, color: _T.sub(dark))),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text('₹${e.close.toStringAsFixed(2)}',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _T.text(dark))),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                          e.fwdReturnPct != null
                              ? '${e.fwdReturnPct! >= 0 ? '+' : ''}${e.fwdReturnPct!.toStringAsFixed(2)}%'
                              : '—',
                          style: TextStyle(
                              fontSize: 11,
                              color: (e.fwdReturnPct ?? 0) >= 0
                                  ? _T.green
                                  : _T.red)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: oc.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: oc.withOpacity(0.3))),
                      child: Text(e.outcome,
                          style: TextStyle(
                              fontSize: 10,
                              color: oc,
                              fontWeight: FontWeight.w700)),
                    ),
                  ]),
                );
              },
            ),
          ),
        ],
      ]),
    );
  }

  Widget _stat(String label, String value, Color color) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: color.withOpacity(0.07),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.2))),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800, color: color)),
              Text(label, style: TextStyle(fontSize: 9, color: _T.sub(dark))),
            ]),
      );
}
// ─────────────────────────────────────────────────────────────────────────
// Algos Action Sheet — bottom sheet offering "Browse backtest logics" or
// "Create your own from scratch".
//
// Usage:
//   showAlgosActionSheet(
//     context,
//     dark: dark,
//     onCreate: () => ...,
//     onBrowse: () => ...,
//   );
//
// Assumes `_T` (theme helper: _T.accent, _T.gradient, _T.text(dark), _T.sub(dark))
// is already available in this library, same as in the empty-state widget.
// ─────────────────────────────────────────────────────────────────────────

Future<void> showAlgosActionSheet(
  BuildContext context, {
  required bool dark,
  required VoidCallback onCreate,
  required VoidCallback onBrowse,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _AlgosActionSheet(
      dark: dark,
      onCreate: onCreate,
      onBrowse: onBrowse,
    ),
  );
}

class _AlgosActionSheet extends StatelessWidget {
  final bool dark;
  final VoidCallback onCreate;
  final VoidCallback onBrowse;

  const _AlgosActionSheet({
    required this.dark,
    required this.onCreate,
    required this.onBrowse,
  });

  void _run(BuildContext context, VoidCallback action) {
    Navigator.pop(context);
    action();
  }

  @override
  Widget build(BuildContext context) {
    final sheetColor = dark ? const Color(0xFF1C1F26) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: sheetColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).padding.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _T.sub(dark).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'What do you want to do?',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: _T.text(dark),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Start from a ready-made logic or build your own.',
            style: TextStyle(fontSize: 12.5, color: _T.sub(dark)),
          ),
          const SizedBox(height: 20),
          _AlgoActionCard(
            dark: dark,
            icon: Icons.travel_explore_rounded,
            label: 'Browse backtest logics',
            subtitle: 'Ready-made algos',
            onTap: () => _run(context, onBrowse),
          ),
          const SizedBox(height: 12),
          _AlgoActionCard(
            dark: dark,
            icon: Icons.auto_graph_rounded,
            label: 'Create your own',
            subtitle: 'Build from scratch',
            onTap: () => _run(context, onCreate),
          ),
        ],
      ),
    );
  }
}

class _AlgoActionCard extends StatelessWidget {
  final bool dark;
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _AlgoActionCard({
    required this.dark,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = _T.accent;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: accent.withValues(alpha: 0.25)),
          borderRadius: BorderRadius.circular(16),
          color: accent.withValues(alpha: dark ? 0.10 : 0.06),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ShaderMask(
                shaderCallback: (rect) => _T.gradient.createShader(rect),
                child: Icon(icon, size: 22, color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: _T.text(dark),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11.5, color: _T.sub(dark)),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: accent),
          ],
        ),
      ),
    );
  }
}
