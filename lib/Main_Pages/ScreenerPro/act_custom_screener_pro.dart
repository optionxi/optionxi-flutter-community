import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:optionxi/Components/cust_contact_us.dart';
import 'package:optionxi/Components/cust_floating_ai.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────

class GeneratedDataModel {
  final int id;
  final String stckname;
  final double? currMonthVol;
  final double? currMonthHigh;
  final double? currMonthLow;
  final double? currMonthClose;
  final double? currMonthOpen;
  final double? prevMonthHigh;
  final double? prevMonthLow;
  final double? prevMonthClose;
  final double? prevMonthOpen;
  final double? currWeekVol;
  final double? currWeekHigh;
  final double? currWeekLow;
  final double? currWeekClose;
  final double? currWeekOpen;
  final double? currWeekRsi14;
  final double? currWeekEma20;
  final double? currWeekSma20;
  final double? currWeekEma50;
  final double? currWeekSma50;
  final double? prevWeekVol;
  final double? prevWeekHigh;
  final double? prevWeekLow;
  final double? prevWeekClose;
  final double? prevWeekOpen;
  final double open;
  final double close;
  final double high;
  final double low;
  final double vol;
  final double pcnt;
  final double? ema10;
  final double? ema20;
  final double? ema50;
  final double? ema100;
  final double? ema150;
  final double? ema200;
  final double? sma10;
  final double? sma20;
  final double? sma50;
  final double? sma100;
  final double? sma150;
  final double? sma200;
  final double? rsi14;
  final double? prevDayHigh;
  final double? prevDay2High;
  final double? prevDay3High;
  final double? prevDay4High;
  final double? prevDay5High;
  final double? prevDayClose;
  final double? prevDay2Close;
  final double? prevDay3Close;
  final double? prevDay4Close;
  final double? prevDay5Close;
  final double? prevDay6Close;
  final double? prevDay7Close;
  final double? prevDayOpen;
  final double? prevDayLow;
  final double? prevDay2Low;
  final double? prevDay3Low;
  final double? prevDay4Low;
  final double? prevDay5Low;
  final double? prevDayVol;
  final double? prevDay2Vol;
  final double? prevDay3Vol;
  final double? prevDay4Vol;
  final double? prevDay5Vol;
  final double? max250High;
  final double? min250Low;
  final double? weekMax52High;
  final double? weekMin52Low;
  final double? currDaySma5Volume;
  final String? sec;

  GeneratedDataModel({
    required this.id,
    required this.stckname,
    this.currMonthVol,
    this.currMonthHigh,
    this.currMonthLow,
    this.currMonthClose,
    this.currMonthOpen,
    this.prevMonthHigh,
    this.prevMonthLow,
    this.prevMonthClose,
    this.prevMonthOpen,
    this.currWeekVol,
    this.currWeekHigh,
    this.currWeekLow,
    this.currWeekClose,
    this.currWeekOpen,
    this.currWeekRsi14,
    this.currWeekEma20,
    this.currWeekSma20,
    this.currWeekEma50,
    this.currWeekSma50,
    this.prevWeekVol,
    this.prevWeekHigh,
    this.prevWeekLow,
    this.prevWeekClose,
    this.prevWeekOpen,
    required this.open,
    required this.close,
    required this.high,
    required this.low,
    required this.vol,
    required this.pcnt,
    this.ema10,
    this.ema20,
    this.ema50,
    this.ema100,
    this.ema150,
    this.ema200,
    this.sma10,
    this.sma20,
    this.sma50,
    this.sma100,
    this.sma150,
    this.sma200,
    this.rsi14,
    this.prevDayHigh,
    this.prevDay2High,
    this.prevDay3High,
    this.prevDay4High,
    this.prevDay5High,
    this.prevDayClose,
    this.prevDay2Close,
    this.prevDay3Close,
    this.prevDay4Close,
    this.prevDay5Close,
    this.prevDay6Close,
    this.prevDay7Close,
    this.prevDayOpen,
    this.prevDayLow,
    this.prevDay2Low,
    this.prevDay3Low,
    this.prevDay4Low,
    this.prevDay5Low,
    this.prevDayVol,
    this.prevDay2Vol,
    this.prevDay3Vol,
    this.prevDay4Vol,
    this.prevDay5Vol,
    this.max250High,
    this.min250Low,
    this.weekMax52High,
    this.weekMin52Low,
    this.currDaySma5Volume,
    this.sec,
  });

  factory GeneratedDataModel.fromJson(Map<String, dynamic> json) {
    double? d(dynamic v) => v == null ? null : double.tryParse(v.toString());
    return GeneratedDataModel(
      id: json['id'] ?? 0,
      stckname: json['stckname'] ?? '',
      currMonthVol: d(json['curr_month_vol']),
      currMonthHigh: d(json['curr_month_high']),
      currMonthLow: d(json['curr_month_low']),
      currMonthClose: d(json['curr_month_close']),
      currMonthOpen: d(json['curr_month_open']),
      prevMonthHigh: d(json['prev_month_high']),
      prevMonthLow: d(json['prev_month_low']),
      prevMonthClose: d(json['prev_month_close']),
      prevMonthOpen: d(json['prev_month_open']),
      currWeekVol: d(json['curr_week_vol']),
      currWeekHigh: d(json['curr_week_high']),
      currWeekLow: d(json['curr_week_low']),
      currWeekClose: d(json['curr_week_close']),
      currWeekOpen: d(json['curr_week_open']),
      currWeekRsi14: d(json['curr_week_rsi14']),
      currWeekEma20: d(json['curr_week_ema20']),
      currWeekSma20: d(json['curr_week_sma20']),
      currWeekEma50: d(json['curr_week_ema50']),
      currWeekSma50: d(json['curr_week_sma50']),
      prevWeekVol: d(json['prev_week_vol']),
      prevWeekHigh: d(json['prev_week_high']),
      prevWeekLow: d(json['prev_week_low']),
      prevWeekClose: d(json['prev_week_close']),
      prevWeekOpen: d(json['prev_week_open']),
      open: d(json['open']) ?? 0,
      close: d(json['close']) ?? 0,
      high: d(json['high']) ?? 0,
      low: d(json['low']) ?? 0,
      vol: d(json['vol']) ?? 0,
      pcnt: d(json['pcnt']) ?? 0,
      ema10: d(json['ema10']),
      ema20: d(json['ema20']),
      ema50: d(json['ema50']),
      ema100: d(json['ema100']),
      ema150: d(json['ema150']),
      ema200: d(json['ema200']),
      sma10: d(json['sma10']),
      sma20: d(json['sma20']),
      sma50: d(json['sma50']),
      sma100: d(json['sma100']),
      sma150: d(json['sma150']),
      sma200: d(json['sma200']),
      rsi14: d(json['rsi14']),
      prevDayHigh: d(json['prev_day_high']),
      prevDay2High: d(json['prev_day2_high']),
      prevDay3High: d(json['prev_day3_high']),
      prevDay4High: d(json['prev_day4_high']),
      prevDay5High: d(json['prev_day5_high']),
      prevDayClose: d(json['prev_day_close']),
      prevDay2Close: d(json['prev_day2_close']),
      prevDay3Close: d(json['prev_day3_close']),
      prevDay4Close: d(json['prev_day4_close']),
      prevDay5Close: d(json['prev_day5_close']),
      prevDay6Close: d(json['prev_day6_close']),
      prevDay7Close: d(json['prev_day7_close']),
      prevDayOpen: d(json['prev_day_open']),
      prevDayLow: d(json['prev_day_low']),
      prevDay2Low: d(json['prev_day2_low']),
      prevDay3Low: d(json['prev_day3_low']),
      prevDay4Low: d(json['prev_day4_low']),
      prevDay5Low: d(json['prev_day5_low']),
      prevDayVol: d(json['prev_day_vol']),
      prevDay2Vol: d(json['prev_day2_vol']),
      prevDay3Vol: d(json['prev_day3_vol']),
      prevDay4Vol: d(json['prev_day4_vol']),
      prevDay5Vol: d(json['prev_day5_vol']),
      max250High: d(json['max_250_high']),
      min250Low: d(json['min_250_low']),
      weekMax52High: d(json['week_max_52_high']),
      weekMin52Low: d(json['week_min_52_low']),
      currDaySma5Volume: d(json['curr_day_sma5_volume']),
      sec: json['sec'],
    );
  }

  List<double> get performanceSeries => [
        prevDay7Close ?? close,
        prevDay6Close ?? close,
        prevDay5Close ?? close,
        prevDay4Close ?? close,
        prevDay3Close ?? close,
        prevDay2Close ?? close,
        prevDayClose ?? close,
        close,
      ];
}

class ColumnComparisonFilter {
  String indicatorL;
  String operator;
  String indicatorR;

  ColumnComparisonFilter({
    this.indicatorL = '',
    this.operator = '',
    this.indicatorR = '',
  });

  bool get isComplete =>
      indicatorL.isNotEmpty && operator.isNotEmpty && indicatorR.isNotEmpty;

  String get summary {
    if (!isComplete) return 'Incomplete filter';
    return '${_indicatorLabel(indicatorL)} ${_opLabel(operator)} ${_indicatorLabel(indicatorR)}';
  }

  static String _opLabel(String op) {
    const map = {'gt': '>', 'lt': '<', 'eq': '=', 'gte': '>=', 'lte': '<='};
    return map[op] ?? op;
  }

  Map<String, dynamic> toJson() => {
        'indicatorL': indicatorL,
        'operator': operator,
        'indicatorR': indicatorR,
      };

  factory ColumnComparisonFilter.fromJson(Map<String, dynamic> j) =>
      ColumnComparisonFilter(
        indicatorL: j['indicatorL'] ?? '',
        operator: j['operator'] ?? '',
        indicatorR: j['indicatorR'] ?? '',
      );
}

class SavedScanner {
  final String id;
  final String name;
  final String? description;
  final String? patternKey;
  final List<ColumnComparisonFilter> filters;
  final String searchTerm;
  final DateTime createdAt;

  SavedScanner({
    required this.id,
    required this.name,
    this.description,
    this.patternKey,
    required this.filters,
    required this.searchTerm,
    required this.createdAt,
  });

  factory SavedScanner.fromRealtimeDatabase(
      String id, Map<String, dynamic> map) {
    return SavedScanner(
      id: id,
      name: map['name'] ?? '',
      description: map['description'],
      patternKey: map['patternKey'],
      filters: ((map['filters'] as List?) ?? [])
          .map((f) => ColumnComparisonFilter.fromJson(
              f is Map ? Map<String, dynamic>.from(f) : {}))
          .toList(),
      searchTerm: map['searchTerm'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toRealtimeDatabase() => {
        'name': name,
        'description': description,
        'patternKey': patternKey,
        'filters': filters.map((f) => f.toJson()).toList(),
        'searchTerm': searchTerm,
        'createdAt': createdAt.toIso8601String(),
      };
}

class TechnicalPatternModel {
  final String key;
  final String label;
  final String iconName;
  final String description;
  final List<ColumnComparisonFilter> filters;
  final String category;
  final int sortOrder;

  TechnicalPatternModel({
    required this.key,
    required this.label,
    required this.iconName,
    required this.description,
    required this.filters,
    required this.category,
    required this.sortOrder,
  });

  factory TechnicalPatternModel.fromJson(Map<String, dynamic> j) {
    final rawFilters = (j['filters'] as List? ?? []);
    return TechnicalPatternModel(
      key: j['key'] ?? '',
      label: j['label'] ?? '',
      iconName: j['icon_name'] ?? 'auto_graph',
      description: j['description'] ?? '',
      filters: rawFilters
          .map(
              (f) => ColumnComparisonFilter.fromJson(f as Map<String, dynamic>))
          .toList(),
      category: j['category'] ?? 'General',
      sortOrder: j['sort_order'] ?? 0,
    );
  }

  IconData get icon {
    const map = {
      'rocket_launch': Icons.rocket_launch_rounded,
      'trending_up': Icons.trending_up_rounded,
      'bar_chart': Icons.bar_chart_rounded,
      'moving': Icons.moving_rounded,
      'trending_down': Icons.trending_down_rounded,
      'candlestick_chart': Icons.candlestick_chart_rounded,
      'show_chart': Icons.show_chart_rounded,
      'waterfall_chart': Icons.waterfall_chart_rounded,
      'auto_graph': Icons.auto_graph_rounded,
    };
    return map[iconName] ?? Icons.auto_graph_rounded;
  }
}

// ─────────────────────────────────────────────
// SERVICES
// ─────────────────────────────────────────────

class StockScreenerService {
  final _sb = Supabase.instance.client;

  static String _sqlOp(String op) {
    const map = {'gt': '>', 'lt': '<', 'eq': '=', 'gte': '>=', 'lte': '<='};
    return map[op] ?? '=';
  }

  String _buildQuery({
    required String searchTerm,
    required List<ColumnComparisonFilter> filters,
    int page = 1,
    int pageSize = 10,
    bool countOnly = false,
  }) {
    final select = countOnly ? 'SELECT COUNT(*)' : 'SELECT *';
    String q = '$select FROM generated_values';
    final conds = <String>[];
    if (searchTerm.isNotEmpty) {
      conds.add("stckname ILIKE '%$searchTerm%'");
    }
    final valid = filters.where((f) => f.isComplete).toList();
    if (valid.isNotEmpty) {
      final parts = valid
          .map((f) => '${f.indicatorL} ${_sqlOp(f.operator)} ${f.indicatorR}')
          .toList();
      conds.add('(${parts.join(' AND ')})');
    }
    if (conds.isNotEmpty) q += ' WHERE ${conds.join(' AND ')}';
    if (!countOnly) {
      q +=
          ' ORDER BY pcnt DESC LIMIT $pageSize OFFSET ${(page - 1) * pageSize}';
    }
    return q;
  }

  Future<List<GeneratedDataModel>> fetchStocks({
    required String searchTerm,
    required List<ColumnComparisonFilter> filters,
    int page = 1,
    int pageSize = 10,
  }) async {
    final q = _buildQuery(
        searchTerm: searchTerm,
        filters: filters,
        page: page,
        pageSize: pageSize);
    final res = await _sb.rpc('execute_query', params: {'query_text': q});
    final list = res as List? ?? [];
    return list
        .map((e) => GeneratedDataModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> fetchCount({
    required String searchTerm,
    required List<ColumnComparisonFilter> filters,
  }) async {
    final q =
        _buildQuery(searchTerm: searchTerm, filters: filters, countOnly: true);
    final res = await _sb.rpc('execute_count_query', params: {'query_text': q});
    return int.tryParse(res?.toString() ?? '0') ?? 0;
  }

  Future<List<TechnicalPatternModel>> fetchPatterns() async {
    final res = await _sb
        .from('technical_patterns')
        .select()
        .order('sort_order', ascending: true);
    return (res as List)
        .map((e) => TechnicalPatternModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

class ScannerFirebaseService {
  final _fb = FirebaseDatabase.instance;
  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  DatabaseReference get _ref =>
      _fb.ref().child('saved_scanners').child(_userId!);

  Future<bool> _isPremium() async {
    if (_userId == null) return false;
    try {
      final snap = await _fb.ref('subscriptions/$_userId/subscribed').get();
      return snap.value == true;
    } catch (_) {
      return false;
    }
  }

  Future<List<SavedScanner>> fetchScanners() async {
    if (_userId == null) return [];
    try {
      final snapshot = await _ref.orderByKey().get();
      if (!snapshot.exists) return [];
      final List<SavedScanner> scanners = [];
      final data = snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        data.forEach((key, value) {
          final map = Map<String, dynamic>.from(value as Map);
          scanners.add(SavedScanner.fromRealtimeDatabase(key, map));
        });
      }
      scanners.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return scanners;
    } catch (e) {
      rethrow;
    }
  }

  /// Returns null on success, or a [SaveError] on failure.
  Future<SaveError?> saveScanner(SavedScanner scanner) async {
    const _maxlimit = 50;
    const _freeLimit = 3;

    if (_userId == null) return SaveError.other('Not logged in');
    try {
      final snapshot = await _ref.get();
      final count = snapshot.exists ? (snapshot.value as Map?)?.length ?? 0 : 0;
      final premium = await _isPremium();
      final limit = premium ? _maxlimit : _freeLimit;
      if (count >= limit) {
        return premium
            ? SaveError.other(
                'You have reached the maximum of 50 saved scanners.')
            : SaveError.limitReached(isPremium: false);
      }
      final newRef = _ref.push();
      await newRef.set(scanner.toRealtimeDatabase());
      return null;
    } catch (e) {
      return SaveError.other('Failed to save scanner: $e');
    }
  }

  Future<String?> updateScanner(
      String id, String name, String? description) async {
    if (_userId == null) return 'Not logged in';
    try {
      await _ref.child(id).update({'name': name, 'description': description});
      return null;
    } catch (e) {
      return 'Failed to update scanner: $e';
    }
  }

  Future<String?> updateScannerFull(SavedScanner scanner) async {
    if (_userId == null) return 'Not logged in';
    try {
      await _ref.child(scanner.id).set(scanner.toRealtimeDatabase());
      return null;
    } catch (e) {
      return 'Failed to update scanner: $e';
    }
  }

  Future<void> deleteScanner(String id) async {
    if (_userId == null) return;
    try {
      await _ref.child(id).remove();
    } catch (_) {}
  }
}

// ─────────────────────────────────────────────
// SAVE ERROR
// ─────────────────────────────────────────────

class SaveError {
  final bool isLimitReached;
  final bool isPremium;
  final String? message;

  const SaveError._({
    required this.isLimitReached,
    required this.isPremium,
    this.message,
  });

  factory SaveError.limitReached({required bool isPremium}) =>
      SaveError._(isLimitReached: true, isPremium: isPremium);

  factory SaveError.other(String msg) =>
      SaveError._(isLimitReached: false, isPremium: false, message: msg);
}

// ─────────────────────────────────────────────
// PREMIUM DIALOG
// ─────────────────────────────────────────────

class _PremiumDialog extends StatelessWidget {
  const _PremiumDialog();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      backgroundColor: _T.surface(dark),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Icon ──
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFFFFB347), Color(0xFFE65100)]),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFFE65100).withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6))
                  ],
                ),
                child: const Icon(Icons.workspace_premium_rounded,
                    color: Colors.white, size: 34),
              ),
              const SizedBox(height: 16),
              Text('Upgrade to Premium',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _T.text(dark))),
              const SizedBox(height: 6),
              Text(
                'Free plan allows 10 saved scanners.\nUpgrade to save up to 50.',
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontSize: 13, color: _T.sub(dark), height: 1.5),
              ),
              const SizedBox(height: 22),
              // ── Starter plan ──
              _PlanCard(
                dark: dark,
                title: 'Starter',
                price: '₹399',
                period: '/month',
                color: _T.accent,
                features: const [
                  '10 → 50 saved scanners',
                  'All screener features',
                  'Priority support',
                ],
              ),
              const SizedBox(height: 20),
              // ── CTA ──
              SizedBox(
                width: double.infinity,
                height: 50,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFFFFB347), Color(0xFFE65100)]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFFE65100).withOpacity(0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4)),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      showContactOptions(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('View Plans & Subscribe',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Maybe later',
                    style: TextStyle(color: _T.sub(dark), fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final bool dark;
  final String title, price, period;
  final Color color;
  final List<String> features;
  final bool isRecommended = false;

  const _PlanCard({
    required this.dark,
    required this.title,
    required this.price,
    required this.period,
    required this.color,
    required this.features,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRecommended ? color.withOpacity(0.06) : _T.surface2(dark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRecommended ? color : _T.border(dark),
          width: isRecommended ? 2 : 1,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: _T.text(dark))),
          if (isRecommended) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(6)),
              child: const Text('BEST VALUE',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5)),
            ),
          ],
          const Spacer(),
          RichText(
            text: TextSpan(children: [
              TextSpan(
                  text: price,
                  style: TextStyle(
                      color: color, fontSize: 20, fontWeight: FontWeight.w800)),
              TextSpan(
                  text: period,
                  style: TextStyle(
                      color: _T.sub(dark),
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        ...features.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                Icon(Icons.check_circle_rounded, color: color, size: 14),
                const SizedBox(width: 6),
                Text(f,
                    style: TextStyle(
                        fontSize: 12,
                        color: _T.text(dark),
                        fontWeight: FontWeight.w500)),
              ]),
            )),
      ]),
    );
  }
}

// ─────────────────────────────────────────────
// HELPERS & THEME
// ─────────────────────────────────────────────

String formatVolume(double v) {
  if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(1)}B';
  if (v >= 1e7) return '${(v / 1e7).toStringAsFixed(1)}Cr';
  if (v >= 1e5) return '${(v / 1e5).toStringAsFixed(1)}L';
  if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
  return v.toStringAsFixed(0);
}

class _T {
  static const accent = Color(0xFF5B7FFF);
  static const accentSoft = Color(0xFF8BA3FF);
  static const green = Color(0xFF00C896);
  static const red = Color(0xFFFF4D6D);

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
}

// ─────────────────────────────────────────────
// INDICATOR LABELS & GROUPS
// ─────────────────────────────────────────────

const _indicatorGroups = {
  'Price': ['open', 'close', 'high', 'low'],
  'Moving Averages': [
    'ema10',
    'ema20',
    'ema50',
    'ema100',
    'ema150',
    'ema200',
    'sma10',
    'sma20',
    'sma50',
    'sma100',
    'sma150',
    'sma200',
  ],
  'Volume': ['vol', 'curr_month_vol', 'curr_week_vol', 'curr_day_sma5_volume'],
  'RSI': ['rsi14', 'curr_week_rsi14'],
  'Historical': [
    'max_250_high',
    'min_250_low',
    'week_max_52_high',
    'week_min_52_low'
  ],
  'Prev Days': [
    'prev_day_close',
    'prev_day2_close',
    'prev_day3_close',
    'prev_day_high',
    'prev_day2_high',
    'prev_day3_high',
    'prev_day_low',
    'prev_day2_low',
    'prev_day3_low',
    'prev_day_vol',
    'prev_day2_vol',
    'prev_day3_vol',
  ],
};

const _indicatorLabels = <String, String>{
  'open': 'Open',
  'close': 'Close',
  'high': 'High',
  'low': 'Low',
  'ema10': 'EMA 10',
  'ema20': 'EMA 20',
  'ema50': 'EMA 50',
  'ema100': 'EMA 100',
  'ema150': 'EMA 150',
  'ema200': 'EMA 200',
  'sma10': 'SMA 10',
  'sma20': 'SMA 20',
  'sma50': 'SMA 50',
  'sma100': 'SMA 100',
  'sma150': 'SMA 150',
  'sma200': 'SMA 200',
  'vol': 'Volume (Today)',
  'curr_month_vol': 'Month Volume',
  'curr_week_vol': 'Week Volume',
  'curr_day_sma5_volume': 'Avg Volume (5D)',
  'rsi14': 'RSI 14',
  'curr_week_rsi14': 'Weekly RSI 14',
  'max_250_high': '250D High',
  'min_250_low': '250D Low',
  'week_max_52_high': '52W High',
  'week_min_52_low': '52W Low',
  'prev_day_close': 'Prev Day Close',
  'prev_day2_close': '2 Days Ago Close',
  'prev_day3_close': '3 Days Ago Close',
  'prev_day_high': 'Prev Day High',
  'prev_day2_high': '2 Days Ago High',
  'prev_day3_high': '3 Days Ago High',
  'prev_day_low': 'Prev Day Low',
  'prev_day2_low': '2 Days Ago Low',
  'prev_day3_low': '3 Days Ago Low',
  'prev_day_vol': 'Prev Day Volume',
  'prev_day2_vol': '2 Days Ago Volume',
  'prev_day3_vol': '3 Days Ago Volume',
};

String _indicatorLabel(String key) => _indicatorLabels[key] ?? key;

// ─────────────────────────────────────────────
// SPARKLINE
// ─────────────────────────────────────────────

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;
  _SparklinePainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final min = data.reduce((a, b) => a < b ? a : b);
    final max = data.reduce((a, b) => a > b ? a : b);
    final range = (max - min).abs();
    if (range == 0) return;
    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - ((data[i] - min) / range) * (size.height * 0.85);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.22), color.withOpacity(0.0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter o) =>
      o.data != data || o.color != color;
}

// ─────────────────────────────────────────────
// INDICATOR PICKER SHEET
// ─────────────────────────────────────────────

class _IndicatorSheet extends StatefulWidget {
  final String? current;
  final bool dark;
  final ValueChanged<String> onSelect;
  const _IndicatorSheet(
      {required this.current, required this.dark, required this.onSelect});

  @override
  State<_IndicatorSheet> createState() => _IndicatorSheetState();
}

class _IndicatorSheetState extends State<_IndicatorSheet> {
  String _q = '';
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = <String, List<String>>{};
    for (final e in _indicatorGroups.entries) {
      final items = e.value.where((i) {
        if (_q.isEmpty) return true;
        final q = _q.toLowerCase();
        return _indicatorLabel(i).toLowerCase().contains(q) ||
            i.toLowerCase().contains(q);
      }).toList();
      if (items.isNotEmpty) filtered[e.key] = items;
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      maxChildSize: 0.95,
      minChildSize: 0.45,
      expand: false,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: _T.surface(widget.dark),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(children: [
              Center(
                  child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                          color: _T.border(widget.dark),
                          borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 14),
              Text('Select Indicator',
                  style: TextStyle(
                      color: _T.text(widget.dark),
                      fontWeight: FontWeight.w700,
                      fontSize: 16)),
              const SizedBox(height: 12),
              Container(
                height: 42,
                decoration: BoxDecoration(
                    color: _T.surface2(widget.dark),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _T.border(widget.dark))),
                child: Row(children: [
                  const SizedBox(width: 12),
                  Icon(Icons.search_rounded,
                      size: 18, color: _T.sub(widget.dark)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: TextField(
                    controller: _ctrl,
                    onChanged: (v) => setState(() => _q = v),
                    style: TextStyle(fontSize: 14, color: _T.text(widget.dark)),
                    decoration: InputDecoration(
                        hintText: 'Search by name...',
                        hintStyle:
                            TextStyle(fontSize: 14, color: _T.sub(widget.dark)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero),
                  )),
                  if (_q.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _ctrl.clear();
                        setState(() => _q = '');
                      },
                      child: Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Icon(Icons.close_rounded,
                              size: 16, color: _T.sub(widget.dark))),
                    ),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.search_off_rounded,
                        size: 36, color: _T.sub(widget.dark)),
                    const SizedBox(height: 8),
                    Text('No indicators found',
                        style: TextStyle(
                            color: _T.sub(widget.dark), fontSize: 13)),
                  ]))
                : ListView(
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
                            children: entry.value.map((item) {
                              final sel = widget.current == item;
                              return GestureDetector(
                                onTap: () => widget.onSelect(item),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 11, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: sel
                                        ? _T.accent
                                        : _T.surface2(widget.dark),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: sel
                                            ? _T.accent
                                            : _T.border(widget.dark)),
                                  ),
                                  child: Text(_indicatorLabel(item),
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: sel
                                              ? Colors.white
                                              : _T.text(widget.dark))),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ]),
          ),
        ]),
      ),
    );
  }
}

class _OperatorSheet extends StatelessWidget {
  final String? current;
  final bool dark;
  final ValueChanged<String> onSelect;
  const _OperatorSheet(
      {required this.current, required this.dark, required this.onSelect});

  static const _ops = [
    ('gt', '>', 'Greater than'),
    ('lt', '<', 'Less than'),
    ('eq', '=', 'Equal to'),
    ('gte', '>=', 'Greater or equal'),
    ('lte', '<=', 'Less or equal'),
  ];

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
        ..._ops.map((op) {
          final sel = current == op.$1;
          return GestureDetector(
            onTap: () => onSelect(op.$1),
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
                SizedBox(
                    width: 32,
                    child: Text(op.$2,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: sel ? _T.accent : _T.text(dark)))),
                const SizedBox(width: 8),
                Text(op.$3,
                    style: TextStyle(fontSize: 13, color: _T.sub(dark))),
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
// INDICATOR BUTTON
// ─────────────────────────────────────────────

class _IndicatorBtn extends StatelessWidget {
  final String? value;
  final String hint;
  final bool dark;
  final bool isOperator;
  final VoidCallback onTap;

  const _IndicatorBtn(
      {required this.value,
      required this.hint,
      required this.dark,
      required this.onTap,
      this.isOperator = false});

  String get _display {
    if (value == null) return hint;
    if (isOperator) {
      const map = {'gt': '>', 'lt': '<', 'eq': '=', 'gte': '>=', 'lte': '<='};
      return map[value] ?? value!;
    }
    return _indicatorLabel(value!);
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: _T.surface2(dark),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: hasValue ? _T.accent.withOpacity(0.45) : _T.border(dark)),
        ),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Flexible(
              child: Text(_display,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: isOperator ? 14 : 12,
                      fontWeight:
                          isOperator ? FontWeight.w800 : FontWeight.w500,
                      color: hasValue ? _T.text(dark) : _T.sub(dark)))),
          if (!isOperator) ...[
            const SizedBox(width: 3),
            Icon(Icons.unfold_more_rounded, size: 13, color: _T.sub(dark))
          ],
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// FILTER ROW
// ─────────────────────────────────────────────

class FilterRow extends StatefulWidget {
  final ColumnComparisonFilter filter;
  final int index;
  final ValueChanged<ColumnComparisonFilter> onChange;
  final VoidCallback onRemove;

  const FilterRow(
      {super.key,
      required this.filter,
      required this.index,
      required this.onChange,
      required this.onRemove});

  @override
  State<FilterRow> createState() => _FilterRowState();
}

class _FilterRowState extends State<FilterRow> {
  bool _collapsed = false;

  void _pickIndicator(BuildContext ctx, bool dark, bool isLeft) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _IndicatorSheet(
        current: isLeft ? widget.filter.indicatorL : widget.filter.indicatorR,
        dark: dark,
        onSelect: (v) {
          Navigator.pop(ctx);
          final updated = ColumnComparisonFilter(
            indicatorL: isLeft ? v : widget.filter.indicatorL,
            operator: widget.filter.operator,
            indicatorR: isLeft ? widget.filter.indicatorR : v,
          );
          widget.onChange(updated);
          if (updated.isComplete) setState(() => _collapsed = true);
        },
      ),
    );
  }

  void _pickOperator(BuildContext ctx, bool dark) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (_) => _OperatorSheet(
        current: widget.filter.operator,
        dark: dark,
        onSelect: (v) {
          Navigator.pop(ctx);
          widget.onChange(ColumnComparisonFilter(
            indicatorL: widget.filter.indicatorL,
            operator: v,
            indicatorR: widget.filter.indicatorR,
          ));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final complete = widget.filter.isComplete;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _T.surface2(dark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: complete ? _T.accent.withOpacity(0.4) : _T.border(dark)),
      ),
      child:
          complete && _collapsed ? _collapsedView(dark) : _expandedView(dark),
    );
  }

  Widget _collapsedView(bool dark) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _collapsed = false),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(children: [
          Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                  color: _T.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(7)),
              child: Icon(Icons.tune_rounded, size: 13, color: _T.accent)),
          const SizedBox(width: 8),
          Expanded(
              child: Text(widget.filter.summary,
                  style: TextStyle(
                      color: _T.accent,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
                color: _T.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20)),
            child: Text('Active',
                style: TextStyle(
                    fontSize: 9,
                    color: _T.accent,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3)),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: widget.onRemove,
            child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                    color: _T.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(7)),
                child: Icon(Icons.close_rounded, size: 13, color: _T.red)),
          ),
        ]),
      ),
    );
  }

  Widget _expandedView(bool dark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('FILTER ${widget.index + 1}',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _T.sub(dark),
                  letterSpacing: 0.8)),
          const Spacer(),
          GestureDetector(
            onTap: widget.onRemove,
            child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                    color: _T.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6)),
                child: Icon(Icons.close_rounded, size: 12, color: _T.red)),
          ),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
              flex: 5,
              child: _IndicatorBtn(
                  value: widget.filter.indicatorL.isEmpty
                      ? null
                      : widget.filter.indicatorL,
                  hint: 'Left indicator',
                  dark: dark,
                  onTap: () => _pickIndicator(context, dark, true))),
          const SizedBox(width: 6),
          SizedBox(
              width: 74,
              child: _IndicatorBtn(
                  value: widget.filter.operator.isEmpty
                      ? null
                      : widget.filter.operator,
                  hint: 'Op',
                  dark: dark,
                  isOperator: true,
                  onTap: () => _pickOperator(context, dark))),
          const SizedBox(width: 6),
          Expanded(
              flex: 5,
              child: _IndicatorBtn(
                  value: widget.filter.indicatorR.isEmpty
                      ? null
                      : widget.filter.indicatorR,
                  hint: 'Right indicator',
                  dark: dark,
                  onTap: () => _pickIndicator(context, dark, false))),
        ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────
// STOCK CARD
// ─────────────────────────────────────────────

class StockCard extends StatelessWidget {
  final GeneratedDataModel stock;
  final VoidCallback onTap;
  final VoidCallback onViewDetails;

  const StockCard(
      {super.key,
      required this.stock,
      required this.onTap,
      required this.onViewDetails});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final isPos = stock.pcnt >= 0;
    final gainColor = isPos ? _T.green : _T.red;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _T.surface(dark),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _T.border(dark)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(dark ? 0.22 : 0.05),
                blurRadius: 12,
                offset: const Offset(0, 3))
          ],
        ),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(stock.stckname,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: _T.text(dark),
                              letterSpacing: 0.1),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      if (stock.sec != null)
                        Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(stock.sec!,
                                style: TextStyle(
                                    fontSize: 11, color: _T.sub(dark)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis)),
                    ])),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                      color: gainColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: gainColor.withOpacity(0.22))),
                  child: Text(
                      '${isPos ? '+' : ''}${stock.pcnt.toStringAsFixed(2)}%',
                      style: TextStyle(
                          color: gainColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12)),
                ),
              ]),
              const SizedBox(height: 10),
              Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('₹${stock.close.toStringAsFixed(2)}',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _T.text(dark),
                          letterSpacing: -0.5)),
                  Text('Vol ${formatVolume(stock.vol)}',
                      style: TextStyle(fontSize: 11, color: _T.sub(dark))),
                ]),
                const Spacer(),
                SizedBox(
                    width: 110,
                    height: 38,
                    child: CustomPaint(
                        painter: _SparklinePainter(
                            data: stock.performanceSeries, color: gainColor))),
              ]),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  _MiniChip(
                      'H', '₹${stock.high.toStringAsFixed(1)}', _T.green, dark),
                  const SizedBox(width: 5),
                  _MiniChip(
                      'L', '₹${stock.low.toStringAsFixed(1)}', _T.red, dark),
                  if (stock.rsi14 != null) ...[
                    const SizedBox(width: 5),
                    _MiniChip(
                        'RSI', stock.rsi14!.toStringAsFixed(1), _T.accent, dark)
                  ],
                  if (stock.ema20 != null) ...[
                    const SizedBox(width: 5),
                    _MiniChip('EMA20', '₹${stock.ema20!.toStringAsFixed(0)}',
                        stock.close > stock.ema20! ? _T.green : _T.red, dark)
                  ],
                ]),
              ),
            ]),
          ),
          GestureDetector(
            onTap: onViewDetails,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: _T.accent.withOpacity(0.05),
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(18)),
                border: Border(top: BorderSide(color: _T.border(dark))),
              ),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('View Details',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _T.accent,
                        letterSpacing: 0.2)),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, size: 12, color: _T.accent),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

Widget _MiniChip(String label, String value, Color color, bool dark) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.18))),
    child: RichText(
        text: TextSpan(children: [
      TextSpan(
          text: '$label ',
          style: TextStyle(
              fontSize: 9,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3)),
      TextSpan(
          text: value,
          style: TextStyle(
              fontSize: 11,
              color: dark ? Colors.white70 : Colors.black87,
              fontWeight: FontWeight.w600)),
    ])),
  );
}

// ─────────────────────────────────────────────
// PATTERN TILE
// ─────────────────────────────────────────────

class _PatternTile extends StatelessWidget {
  final TechnicalPatternModel pattern;
  final bool isActive;
  final bool dark;
  final VoidCallback onTap;
  const _PatternTile(
      {super.key,
      required this.pattern,
      required this.isActive,
      required this.dark,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: isActive ? _T.accent : _T.bg(dark),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isActive ? _T.accent : _T.border(dark)),
          boxShadow: isActive
              ? [BoxShadow(color: _T.accent.withOpacity(0.28), blurRadius: 10)]
              : [],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(children: [
          Icon(pattern.icon,
              size: 13, color: isActive ? Colors.white : _T.accentSoft),
          const SizedBox(width: 6),
          Expanded(
              child: Text(pattern.label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : _T.text(dark)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis)),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SHARED CARD CONTAINER
// ─────────────────────────────────────────────

class _Card extends StatelessWidget {
  final bool dark;
  final Widget child;
  const _Card({required this.dark, required this.child});

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
                offset: const Offset(0, 3))
          ],
        ),
        child: child,
      );
}

// ─────────────────────────────────────────────
// SKELETON CARD
// ─────────────────────────────────────────────

class _SkeletonCard extends StatefulWidget {
  final bool dark;
  const _SkeletonCard({required this.dark});
  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sh = widget.dark ? const Color(0xFF252840) : const Color(0xFFE8EAF2);
    return FadeTransition(
      opacity: Tween(begin: 0.5, end: 1.0).animate(_anim),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
            color: _T.surface(widget.dark),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _T.border(widget.dark))),
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _Box(w: 130, h: 13, c: sh),
            const Spacer(),
            _Box(w: 58, h: 22, c: sh, r: 8)
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _Box(w: 100, h: 20, c: sh),
              const SizedBox(height: 5),
              _Box(w: 65, h: 10, c: sh)
            ]),
            const Spacer(),
            _Box(w: 110, h: 38, c: sh, r: 6),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _Box(w: 60, h: 22, c: sh, r: 6),
            const SizedBox(width: 5),
            _Box(w: 60, h: 22, c: sh, r: 6)
          ]),
        ]),
      ),
    );
  }
}

class _Box extends StatelessWidget {
  final double w, h;
  final Color c;
  final double r;
  const _Box({required this.w, required this.h, required this.c, this.r = 4});
  @override
  Widget build(BuildContext context) => Container(
      width: w,
      height: h,
      decoration:
          BoxDecoration(color: c, borderRadius: BorderRadius.circular(r)));
}

// ─────────────────────────────────────────────
// ALL PATTERNS PAGE
// ─────────────────────────────────────────────

class AllPatternsPage extends StatefulWidget {
  final List<TechnicalPatternModel> patterns;
  final String? activePatternKey;
  final ValueChanged<TechnicalPatternModel> onSelect;
  final bool dark;

  const AllPatternsPage(
      {super.key,
      required this.patterns,
      required this.activePatternKey,
      required this.onSelect,
      required this.dark});

  @override
  State<AllPatternsPage> createState() => _AllPatternsPageState();
}

class _AllPatternsPageState extends State<AllPatternsPage> {
  String _categoryFilter = 'All';
  String _search = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<String> get _categories {
    final cats = {'All', ...widget.patterns.map((p) => p.category)};
    return cats.toList();
  }

  List<TechnicalPatternModel> get _filtered {
    return widget.patterns.where((p) {
      final matchCat =
          _categoryFilter == 'All' || p.category == _categoryFilter;
      final matchSearch = _search.isEmpty ||
          p.label.toLowerCase().contains(_search.toLowerCase()) ||
          p.description.toLowerCase().contains(_search.toLowerCase());
      return matchCat && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.dark;
    return Scaffold(
      backgroundColor: _T.bg(dark),
      appBar: AppBar(
        backgroundColor: _T.surface(dark),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: _T.surface2(dark),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _T.border(dark))),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  size: 14, color: _T.text(dark))),
        ),
        title: Text('Technical Patterns',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: _T.text(dark))),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Divider(height: 1, color: _T.border(dark))),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Container(
            height: 42,
            decoration: BoxDecoration(
                color: _T.surface(dark),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _T.border(dark))),
            child: Row(children: [
              const SizedBox(width: 12),
              Icon(Icons.search_rounded, size: 18, color: _T.sub(dark)),
              const SizedBox(width: 8),
              Expanded(
                  child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _search = v),
                style: TextStyle(fontSize: 14, color: _T.text(dark)),
                decoration: InputDecoration(
                    hintText: 'Search patterns...',
                    hintStyle: TextStyle(fontSize: 14, color: _T.sub(dark)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero),
              )),
              if (_search.isNotEmpty)
                GestureDetector(
                    onTap: () {
                      _searchCtrl.clear();
                      setState(() => _search = '');
                    },
                    child: Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Icon(Icons.close_rounded,
                            size: 16, color: _T.sub(dark)))),
            ]),
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final cat = _categories[i];
              final sel = _categoryFilter == cat;
              return GestureDetector(
                onTap: () => setState(() => _categoryFilter = cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                      color: sel ? _T.accent : _T.surface(dark),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: sel ? _T.accent : _T.border(dark))),
                  child: Text(cat,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: sel ? Colors.white : _T.text(dark))),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: _filtered.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.search_off_rounded, size: 44, color: _T.sub(dark)),
                  const SizedBox(height: 12),
                  Text('No patterns found',
                      style: TextStyle(
                          color: _T.text(dark),
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                ]))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  itemCount: _filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final p = _filtered[i];
                    final isActive = widget.activePatternKey == p.key;
                    return GestureDetector(
                      onTap: () {
                        widget.onSelect(p);
                        Navigator.pop(context);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isActive
                              ? _T.accent.withOpacity(0.08)
                              : _T.surface(dark),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: isActive
                                  ? _T.accent.withOpacity(0.5)
                                  : _T.border(dark)),
                        ),
                        child: Row(children: [
                          Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                  color: isActive
                                      ? _T.accent
                                      : _T.accent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(11)),
                              child: Icon(p.icon,
                                  size: 20,
                                  color: isActive ? Colors.white : _T.accent)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Row(children: [
                                  Text(p.label,
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: _T.text(dark))),
                                  const SizedBox(width: 6),
                                  Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                          color: _T.accent.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(20)),
                                      child: Text(p.category,
                                          style: TextStyle(
                                              fontSize: 9,
                                              color: _T.accent,
                                              fontWeight: FontWeight.w700))),
                                ]),
                                const SizedBox(height: 3),
                                Text(p.description,
                                    style: TextStyle(
                                        fontSize: 12, color: _T.sub(dark))),
                                const SizedBox(height: 6),
                                Text(
                                    '${p.filters.length} condition${p.filters.length == 1 ? '' : 's'}',
                                    style: TextStyle(
                                        fontSize: 11, color: _T.sub(dark))),
                              ])),
                          if (isActive)
                            Icon(Icons.check_circle_rounded,
                                color: _T.accent, size: 20),
                        ]),
                      ),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────
// SAVE SCANNER DIALOG
// ─────────────────────────────────────────────

class _SaveScannerDialog extends StatefulWidget {
  final bool dark;
  const _SaveScannerDialog({required this.dark});

  @override
  State<_SaveScannerDialog> createState() => _SaveScannerDialogState();
}

class _SaveScannerDialogState extends State<_SaveScannerDialog> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.dark;
    return Dialog(
      backgroundColor: _T.surface(dark),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: _T.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.bookmark_add_rounded,
                    color: _T.accent, size: 18)),
            const SizedBox(width: 10),
            Text('Save Scanner',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _T.text(dark))),
          ]),
          const SizedBox(height: 18),
          _Field(ctrl: _nameCtrl, hint: 'Scanner name *', dark: dark),
          const SizedBox(height: 10),
          _Field(
              ctrl: _descCtrl,
              hint: 'Description (optional)',
              dark: dark,
              maxLines: 2),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(
                child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                    color: _T.surface2(dark),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _T.border(dark))),
                child: Center(
                    child: Text('Cancel',
                        style: TextStyle(
                            color: _T.sub(dark), fontWeight: FontWeight.w600))),
              ),
            )),
            const SizedBox(width: 10),
            Expanded(
                child: GestureDetector(
              onTap: () {
                if (_nameCtrl.text.trim().isEmpty) return;
                Navigator.pop(context, {
                  'name': _nameCtrl.text.trim(),
                  'desc': _descCtrl.text.trim()
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF5B7FFF), Color(0xFF9B6DFF)]),
                    borderRadius: BorderRadius.circular(12)),
                child: const Center(
                    child: Text('Save',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700))),
              ),
            )),
          ]),
        ]),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final bool dark;
  final int maxLines;
  const _Field(
      {required this.ctrl,
      required this.hint,
      required this.dark,
      this.maxLines = 1});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
            color: _T.surface2(dark),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _T.border(dark))),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: TextField(
          controller: ctrl,
          maxLines: maxLines,
          style: TextStyle(fontSize: 14, color: _T.text(dark)),
          decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(fontSize: 14, color: _T.sub(dark)),
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(vertical: maxLines > 1 ? 8 : 0)),
        ),
      );
}

// ─────────────────────────────────────────────
// ENUM
// ─────────────────────────────────────────────

enum _LoadState { idle, loading, error, loaded }

// ─────────────────────────────────────────────
// MAIN SCREENER PAGE
// ─────────────────────────────────────────────

class StockScreenerPagePro extends StatefulWidget {
  const StockScreenerPagePro({super.key});

  @override
  State<StockScreenerPagePro> createState() => _StockScreenerPageProState();
}

class _StockScreenerPageProState extends State<StockScreenerPagePro> {
  final _service = StockScreenerService();
  final _fbService = ScannerFirebaseService();
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  List<ColumnComparisonFilter> _filters = [];
  List<GeneratedDataModel> _stocks = [];
  List<TechnicalPatternModel> _patterns = [];
  _LoadState _patternsState = _LoadState.idle;

  String _searchTerm = '';
  String? _activePatternKey;
  String? _loadedScannerName; // tracks if a saved scanner is loaded
  String? _loadedScannerId; // Firebase key of the loaded scanner for updating
  bool _loading = false;
  bool _filtersApplied = false;
  bool _patternsExpanded = false;
  int _page = 1;
  int _total = 0;
  static const _pageSize = 10;
  static const _patternPreviewCount = 4;

  bool get _hasInput => _filters.isNotEmpty || _searchTerm.isNotEmpty;
  bool _isSaved =
      false; // true after a successful save, resets when filters change
  bool _isSubscribed = false;
  int _savedCount = 0;
  static const _freeScreenerLimit = 10;

  @override
  void initState() {
    super.initState();
    _loadPatterns();
    _loadSubscriptionStatus();
    // Check if launched with a saved scanner argument.
    // Arguments may arrive as:
    //   - a SavedScanner object (navigated from within this same file), or
    //   - a plain Map (navigated from act_saved_screeners.dart, which defines
    //     its own SavedScanner class — a different runtime type, so `is SavedScanner`
    //     would be false if we checked the object directly).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = Get.arguments;
      if (args is SavedScanner) {
        _loadScanner(args);
      } else if (args is Map) {
        final map = Map<String, dynamic>.from(args);
        final id = map['id']?.toString() ?? '';
        _loadScanner(SavedScanner.fromRealtimeDatabase(id, map));
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPatterns() async {
    setState(() => _patternsState = _LoadState.loading);
    try {
      final p = await _service.fetchPatterns();
      setState(() {
        _patterns = p;
        _patternsState = _LoadState.loaded;
      });
    } catch (_) {
      setState(() => _patternsState = _LoadState.error);
    }
  }

  Future<void> _loadSubscriptionStatus() async {
    try {
      final results = await Future.wait([
        _fbService._isPremium(),
        _fbService.fetchScanners(),
      ]);
      if (mounted) {
        setState(() {
          _isSubscribed = results[0] as bool;
          _savedCount = (results[1] as List).length;
        });
      }
    } catch (_) {}
  }

  Widget _buildUsageBanner(bool dark) {
    final max = _isSubscribed ? 15 : _freeScreenerLimit;
    final pct = (_savedCount / max).clamp(0.0, 1.0);
    final color = pct >= 1.0
        ? _T.red
        : pct >= 0.7
            ? Colors.orange
            : _T.green;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$_savedCount / $max screeners saved',
                    style: TextStyle(
                      color: _T.sub(dark),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (!_isSubscribed)
                    GestureDetector(
                      onTap: _openPremiumDialog,
                      child: const Row(
                        children: [
                          Text(
                            'Upgrade',
                            style: TextStyle(
                              color: Color(0xFFFFAB00),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 2),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Color(0xFFFFAB00),
                            size: 14,
                          ),
                        ],
                      ),
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
        ),
      ],
    );
  }

  void _openPremiumDialog() {
    showDialog(context: context, builder: (_) => const _PremiumDialog());
  }

  Future<void> _runFilters() async {
    if (!_hasInput) return;
    HapticFeedback.lightImpact();
    setState(() {
      _loading = true;
      _page = 1;
    });
    try {
      final stocks = await _service.fetchStocks(
          searchTerm: _searchTerm,
          filters: _filters,
          page: _page,
          pageSize: _pageSize);
      final count =
          await _service.fetchCount(searchTerm: _searchTerm, filters: _filters);
      setState(() {
        _stocks = stocks;
        _total = count;
        _filtersApplied = true;
      });
      _snack('$count stocks matched', ok: true);
    } catch (_) {
      _snack('Failed to fetch data', ok: false);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadPage(int p) async {
    setState(() {
      _page = p;
      _loading = true;
    });
    try {
      final stocks = await _service.fetchStocks(
          searchTerm: _searchTerm,
          filters: _filters,
          page: p,
          pageSize: _pageSize);
      setState(() => _stocks = stocks);
    } catch (_) {
      _snack('Failed to load page', ok: false);
    } finally {
      setState(() => _loading = false);
    }
    _scrollCtrl.animateTo(0,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  void _applyPattern(TechnicalPatternModel pattern) {
    HapticFeedback.selectionClick();
    setState(() {
      _activePatternKey = pattern.key;
      _filters = pattern.filters;
      _patternsExpanded = false;
      _loadedScannerName = null;
      _isSaved = false;
    });
    _runFilters();
  }

  void _clearAll() {
    setState(() {
      _filters = [];
      _searchTerm = '';
      _searchCtrl.clear();
      _activePatternKey = null;
      _loadedScannerName = null;
      _loadedScannerId = null;
      _stocks = [];
      _total = 0;
      _filtersApplied = false;
      _page = 1;
      _isSaved = false;
    });
  }

  Future<void> _saveScanner() async {
    if (!_hasInput) {
      _snack('Add filters or a search term first', ok: false);
      return;
    }

    // ── Update existing loaded scanner ──
    if (_loadedScannerId != null && _loadedScannerName != null) {
      final updated = SavedScanner(
        id: _loadedScannerId!,
        name: _loadedScannerName!,
        description: null,
        patternKey: _activePatternKey,
        filters: List.from(_filters),
        searchTerm: _searchTerm,
        createdAt: DateTime.now(),
      );
      final error = await _fbService.updateScannerFull(updated);
      if (error != null) {
        _snack(error, ok: false);
      } else {
        setState(() => _isSaved = true);
        _snack('Scanner updated!', ok: true);
      }
      return;
    }

    // ── Save as new scanner ──
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => _SaveScannerDialog(dark: _isDark),
    );
    if (result == null) return;
    final scanner = SavedScanner(
      id: '',
      name: result['name']!,
      description: result['desc'],
      patternKey: _activePatternKey,
      filters: List.from(_filters),
      searchTerm: _searchTerm,
      createdAt: DateTime.now(),
    );
    final error = await _fbService.saveScanner(scanner);
    if (error != null) {
      if (error.isLimitReached) {
        await showDialog(
            context: context, builder: (_) => const _PremiumDialog());
      } else {
        _snack(error.message ?? 'Failed to save', ok: false);
      }
    } else {
      setState(() => _isSaved = true);
      _snack('Scanner saved!', ok: true);
    }
  }

  void _loadScanner(SavedScanner s) {
    setState(() {
      _searchTerm = s.searchTerm;
      _searchCtrl.text = s.searchTerm;
      _filters = List.from(s.filters);
      _activePatternKey = s.patternKey;
      _loadedScannerName = s.name;
      _loadedScannerId = s.id;
      _isSaved = true; // already persisted
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _runFilters());
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  void _snack(String msg, {required bool ok}) {
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

  @override
  Widget build(BuildContext context) {
    final dark = _isDark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _T.bg(dark),
        body: CustomScrollView(
          controller: _scrollCtrl,
          slivers: [
            _appBar(dark),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Column(children: [
                  // ── Usage banner ──
                  _buildUsageBanner(dark),
                  const SizedBox(height: 12),
                  // Loaded scanner banner
                  if (_loadedScannerName != null) ...[
                    _LoadedScannerBanner(
                        name: _loadedScannerName!,
                        dark: dark,
                        onClear: _clearAll),
                    const SizedBox(height: 10),
                  ],
                  _SearchField(
                      ctrl: _searchCtrl,
                      dark: dark,
                      onChanged: (v) => setState(() {
                            _searchTerm = v;
                            _loadedScannerName = null;
                            _isSaved = false;
                          }),
                      onClear: _clearAll),
                  const SizedBox(height: 12),
                  _filtersCard(dark),
                  const SizedBox(height: 12),
                  _patternsCard(dark),
                  const SizedBox(height: 14),
                  // ── Run & Save action bar ──
                  _ActionBar(
                    hasInput: _hasInput,
                    loading: _loading,
                    isSaved: _isSaved,
                    isLoaded: _loadedScannerId != null,
                    dark: dark,
                    onRun: _runFilters,
                    onSave: _saveScanner,
                  ),
                  if (_filtersApplied && !_loading) ...[
                    const SizedBox(height: 8),
                    Text('$_total stocks found',
                        style: TextStyle(
                            fontSize: 12,
                            color: _T.sub(dark),
                            fontWeight: FontWeight.w500)),
                  ],
                  const SizedBox(height: 14),
                ]),
              ),
            ),
            _resultsList(dark),
            if (_total > _pageSize)
              SliverToBoxAdapter(child: _pagination(dark)),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  SliverAppBar _appBar(bool dark) {
    final canPop = Navigator.of(context).canPop();
    return SliverAppBar(
      pinned: true,
      backgroundColor: _T.surface(dark),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: 56,
      automaticallyImplyLeading: false,
      flexibleSpace: Container(
        decoration: BoxDecoration(
            color: _T.surface(dark),
            border: Border(bottom: BorderSide(color: _T.border(dark)))),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          height: 56,
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            if (canPop) ...[
              GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                        color: _T.surface2(dark),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _T.border(dark))),
                    child: Icon(Icons.arrow_back_ios_new_rounded,
                        size: 14, color: _T.text(dark))),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Screener Pro',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _T.text(dark),
                            letterSpacing: -0.3)),
                    if (_filtersApplied && _total > 0)
                      Text('$_total results',
                          style: TextStyle(fontSize: 11, color: _T.sub(dark))),
                  ]),
            ),
            // ── Saved Scanners nav button ──
            GestureDetector(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const _SavedScannersPageBridge())),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: _T.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _T.accent.withOpacity(0.3)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.bookmark_rounded, size: 14, color: _T.accent),
                  const SizedBox(width: 5),
                  Text('Saved',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _T.accent)),
                ]),
              ),
            ),
            if (_filtersApplied || _filters.isNotEmpty)
              GestureDetector(
                onTap: _clearAll,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                      color: _T.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: _T.red.withOpacity(0.2))),
                  child: Text('Clear',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _T.red)),
                ),
              ),
          ]),
        ),
      ),
    );
  }

  Widget _filtersCard(bool dark) {
    final cnt = _filters.where((f) => f.isComplete).length;
    return _Card(
        dark: dark,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.tune_rounded, size: 15, color: _T.accent),
            const SizedBox(width: 7),
            Text('Custom Filters',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: _T.text(dark))),
            const SizedBox(width: 6),
            if (cnt > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                    color: _T.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20)),
                child: Text('$cnt active',
                    style: TextStyle(
                        fontSize: 10,
                        color: _T.accent,
                        fontWeight: FontWeight.w600)),
              ),
          ]),
          const SizedBox(height: 12),
          if (_filters.isEmpty)
            Center(
                child: Column(children: [
              Icon(Icons.filter_list_off_rounded,
                  size: 28, color: _T.sub(dark)),
              const SizedBox(height: 6),
              Text('No filters yet',
                  style: TextStyle(color: _T.sub(dark), fontSize: 12)),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => setState(() {
                  _filters.add(ColumnComparisonFilter());
                  _isSaved = false;
                }),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                      color: _T.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: _T.accent.withOpacity(0.3))),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.add_rounded, size: 14, color: _T.accent),
                    const SizedBox(width: 5),
                    Text('Add Filter',
                        style: TextStyle(
                            fontSize: 12,
                            color: _T.accent,
                            fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
            ]))
          else ...[
            for (int i = 0; i < _filters.length; i++)
              FilterRow(
                  key: ValueKey(i),
                  filter: _filters[i],
                  index: i,
                  onChange: (u) => setState(() {
                        _filters[i] = u;
                        _isSaved = false;
                      }),
                  onRemove: () => setState(() {
                        _filters.removeAt(i);
                        _isSaved = false;
                      })),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => setState(() {
                _filters.add(ColumnComparisonFilter());
                _isSaved = false;
              }),
              child: Row(children: [
                Icon(Icons.add_circle_outline_rounded,
                    size: 14, color: _T.accent),
                const SizedBox(width: 5),
                Text('Add Filter',
                    style: TextStyle(
                        fontSize: 12,
                        color: _T.accent,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
          ],
        ]));
  }

  Widget _patternsCard(bool dark) {
    return _Card(
        dark: dark,
        child: Column(children: [
          GestureDetector(
            onTap: () => setState(() => _patternsExpanded = !_patternsExpanded),
            child: Row(children: [
              Text('Technical Patterns',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: _T.text(dark))),
              const SizedBox(width: 6),
              if (_activePatternKey != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                      color: _T.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(
                      _patterns
                          .firstWhere((p) => p.key == _activePatternKey,
                              orElse: () => TechnicalPatternModel(
                                  key: '',
                                  label: _activePatternKey!,
                                  iconName: '',
                                  description: '',
                                  filters: [],
                                  category: '',
                                  sortOrder: 0))
                          .label,
                      style: TextStyle(
                          fontSize: 10,
                          color: _T.green,
                          fontWeight: FontWeight.w600)),
                )
              ] else
                Text('None',
                    style: TextStyle(fontSize: 12, color: _T.sub(dark))),
              const Spacer(),
              AnimatedRotation(
                turns: _patternsExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(Icons.keyboard_arrow_down_rounded,
                    color: _T.sub(dark), size: 20),
              ),
            ]),
          ),
          if (_patternsExpanded) ...[
            const SizedBox(height: 14),
            if (_patternsState == _LoadState.loading)
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                      child: CircularProgressIndicator(
                          color: _T.accent, strokeWidth: 2)))
            else if (_patternsState == _LoadState.error)
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(children: [
                    Text('Failed to load patterns',
                        style: TextStyle(color: _T.sub(dark), fontSize: 13)),
                    const SizedBox(height: 8),
                    GestureDetector(
                        onTap: _loadPatterns,
                        child: Text('Retry',
                            style: TextStyle(
                                color: _T.accent,
                                fontSize: 13,
                                fontWeight: FontWeight.w600))),
                  ]))
            else if (_patterns.isEmpty)
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('No patterns available',
                      style: TextStyle(color: _T.sub(dark), fontSize: 13)))
            else ...[
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 3.2,
                children: _patterns
                    .take(_patternPreviewCount)
                    .map((p) => _PatternTile(
                          key: ValueKey(p.key),
                          pattern: p,
                          isActive: _activePatternKey == p.key,
                          dark: dark,
                          onTap: () => _applyPattern(p),
                        ))
                    .toList(),
              ),
              if (_patterns.length > _patternPreviewCount) ...[
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => AllPatternsPage(
                                patterns: _patterns,
                                activePatternKey: _activePatternKey,
                                onSelect: _applyPattern,
                                dark: dark,
                              ))),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                        color: _T.accent.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _T.accent.withOpacity(0.2))),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('View all ${_patterns.length} patterns',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _T.accent)),
                          const SizedBox(width: 5),
                          Icon(Icons.arrow_forward_rounded,
                              size: 13, color: _T.accent),
                        ]),
                  ),
                ),
              ],
            ],
          ],
        ]));
  }

  Widget _resultsList(bool dark) {
    if (_loading) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
          (_, i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _SkeletonCard(dark: dark)),
          childCount: 6,
        )),
      );
    }
    if (_stocks.isNotEmpty) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
          (_, i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: StockCard(
              stock: _stocks[i],
              onTap: () => _showSheet(_stocks[i]),
              onViewDetails: () =>
                  Get.toNamed('/stocks/${_stocks[i].stckname}'),
            ),
          ),
          childCount: _stocks.length,
        )),
      );
    }
    return SliverToBoxAdapter(
        child: _EmptyState(
      dark: dark,
      icon: _filtersApplied ? Icons.inbox_rounded : Icons.manage_search_rounded,
      title: _filtersApplied ? 'No stocks matched' : 'Ready to screen',
      subtitle: _filtersApplied
          ? 'Try adjusting your filters or search term'
          : 'Set filters or pick a pattern, then tap Run Screener',
    ));
  }

  Widget _pagination(bool dark) {
    final totalPages = (_total / _pageSize).ceil();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _PageBtn(
            icon: Icons.arrow_back_ios_new_rounded,
            enabled: _page > 1 && !_loading,
            dark: dark,
            onTap: () => _loadPage(_page - 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Text('Page $_page of $totalPages',
              style: TextStyle(
                  fontSize: 13,
                  color: _T.sub(dark),
                  fontWeight: FontWeight.w500)),
        ),
        _PageBtn(
            icon: Icons.arrow_forward_ios_rounded,
            enabled: _page * _pageSize < _total && !_loading,
            dark: dark,
            onTap: () => _loadPage(_page + 1)),
      ]),
    );
  }

  void _showSheet(GeneratedDataModel s) {
    final dark = _isDark;
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _DetailSheet(stock: s, dark: dark));
  }
}

// ─────────────────────────────────────────────
// BRIDGE: SavedScannersPage navigated to from screener
// (renders the full saved scanners page with its own state)
// ─────────────────────────────────────────────

class _SavedScannersPageBridge extends StatefulWidget {
  const _SavedScannersPageBridge();

  @override
  State<_SavedScannersPageBridge> createState() =>
      _SavedScannersPageBridgeState();
}

class _SavedScannersPageBridgeState extends State<_SavedScannersPageBridge> {
  final _svc = ScannerFirebaseService();
  List<SavedScanner> _scanners = [];
  bool _loading = true;
  String? _error;
  bool _isSubscribed = false;
  static const _freeLimit = 3;
  static const _maxlimit = 50;

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
        _svc.fetchScanners(),
        _svc._isPremium(),
      ]);
      _scanners = results[0] as List<SavedScanner>;
      _isSubscribed = results[1] as bool;
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _buildUsageBanner(bool dark) {
    final used = _scanners.length;
    final max = _isSubscribed ? _maxlimit : _freeLimit;
    final pct = (used / max).clamp(0.0, 1.0);
    final color = pct >= 1.0
        ? _T.red
        : pct >= 0.7
            ? Colors.orange
            : _T.green;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$used / $max scanners saved',
                      style: TextStyle(
                        color: _T.sub(dark),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (!_isSubscribed)
                      GestureDetector(
                        onTap: () => showDialog(
                            context: context,
                            builder: (_) => const _PremiumDialog()),
                        child: Row(
                          children: [
                            Text(
                              'Upgrade',
                              style: TextStyle(
                                color: const Color(0xFFFFAB00),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: Color(0xFFFFAB00),
                              size: 14,
                            ),
                          ],
                        ),
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
          ),
        ],
      ),
    );
  }

  Future<void> _delete(SavedScanner s) async {
    final dark = _isDark;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _T.surface(dark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Scanner',
            style:
                TextStyle(color: _T.text(dark), fontWeight: FontWeight.w700)),
        content: Text('Delete "${s.name}"? This cannot be undone.',
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
    if (confirm == true) {
      await _svc.deleteScanner(s.id);
      _snack('Scanner deleted', ok: false);
      await _load();
    }
  }

  Future<void> _edit(SavedScanner s) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => _EditScannerDialog(scanner: s, dark: _isDark),
    );
    if (result == null) return;
    final error = await _svc.updateScanner(
        s.id, result['name']!, result['desc']!.isEmpty ? null : result['desc']);
    if (error != null) {
      _snack(error, ok: false);
    } else {
      _snack('Scanner updated', ok: true);
      await _load();
    }
  }

  void _runScanner(SavedScanner s) {
    // Client-side guard: block request if free limit reached
    if (!_isSubscribed && _scanners.length >= _freeLimit) {
      showDialog(context: context, builder: (_) => const _PremiumDialog());
      return;
    }
    Navigator.pop(context);
    // Navigate to a fresh screener page with scanner loaded
    Get.toNamed('/screenerpro', arguments: s);
  }

  void _snack(String msg, {required bool ok}) {
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

  @override
  Widget build(BuildContext context) {
    final dark = _isDark;
    return Scaffold(
      backgroundColor: _T.bg(dark),
      floatingActionButton: _scanners.isEmpty
          ? null
          : MagicalAIButton(
              label: "New Screener",
              onPressed: () {
                Navigator.pop(context);
                Get.toNamed('/screenerpro', preventDuplicates: false);
              }),
      appBar: AppBar(
        backgroundColor: _T.surface(dark),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: _T.surface2(dark),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _T.border(dark))),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  size: 14, color: _T.text(dark))),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Saved Scanners',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: _T.text(dark))),
          if (!_loading && _error == null)
            Text(
                '${_scanners.length} scanner${_scanners.length == 1 ? '' : 's'}',
                style: TextStyle(fontSize: 11, color: _T.sub(dark))),
        ]),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Divider(height: 1, color: _T.border(dark))),
      ),
      body: _loading
          ? Center(
              child:
                  CircularProgressIndicator(color: _T.accent, strokeWidth: 2))
          : _error != null
              ? _ErrorState(dark: dark, error: _error!, onRetry: _load)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_scanners.isNotEmpty) ...[
                      _buildUsageBanner(dark),
                      const SizedBox(height: 4),
                    ],
                    Expanded(
                      child: _scanners.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 72,
                                        height: 72,
                                        decoration: BoxDecoration(
                                            color:
                                                _T.sub(dark).withOpacity(0.1),
                                            shape: BoxShape.circle),
                                        child: Icon(
                                            Icons.bookmark_border_rounded,
                                            size: 32,
                                            color:
                                                _T.sub(dark).withOpacity(0.7)),
                                      ),
                                      const SizedBox(height: 16),
                                      Text('No saved scanners yet',
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: _T.text(dark))),
                                      const SizedBox(height: 6),
                                      Text(
                                          'Build a screener with filters or patterns,\nthen save it to reuse anytime.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontSize: 13,
                                              color: _T.sub(dark))),
                                      const SizedBox(height: 20),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.pop(context);
                                          Get.toNamed('/screenerpro',
                                              preventDuplicates: false);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 20, vertical: 11),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF2D3250),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Text('Go to Screener',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 14)),
                                        ),
                                      ),
                                    ]),
                              ),
                            )
                          : RefreshIndicator(
                              color: _T.accent,
                              onRefresh: _load,
                              child: ListView.separated(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 14, 16, 32),
                                itemCount: _scanners.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (_, i) => _ScannerCard(
                                  scanner: _scanners[i],
                                  dark: dark,
                                  onRun: () => _runScanner(_scanners[i]),
                                  onEdit: () => _edit(_scanners[i]),
                                  onDelete: () => _delete(_scanners[i]),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }
}

// ─────────────────────────────────────────────
// SCANNER CARD (used in bridge)
// ─────────────────────────────────────────────

class _ScannerCard extends StatefulWidget {
  final SavedScanner scanner;
  final bool dark;
  final VoidCallback onRun;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ScannerCard(
      {required this.scanner,
      required this.dark,
      required this.onRun,
      required this.onEdit,
      required this.onDelete});

  @override
  State<_ScannerCard> createState() => _ScannerCardState();
}

class _ScannerCardState extends State<_ScannerCard> {
  bool _filtersExpanded = false;

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    final scanner = widget.scanner;
    final dark = widget.dark;
    final activeFilters = scanner.filters.where((f) => f.isComplete).toList();
    final hasFilters = activeFilters.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: _T.surface(dark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _T.border(dark)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(dark ? 0.18 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ── Title row ──
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: _T.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(11)),
                  child: Icon(Icons.manage_search_rounded,
                      color: _T.accent, size: 20)),
              const SizedBox(width: 10),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(scanner.name,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _T.text(dark)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    if (scanner.description != null &&
                        scanner.description!.isNotEmpty)
                      Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(scanner.description!,
                              style:
                                  TextStyle(fontSize: 12, color: _T.sub(dark)),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis)),
                  ])),
              const SizedBox(width: 8),
              Text(_timeAgo(scanner.createdAt),
                  style: TextStyle(fontSize: 10, color: _T.sub(dark))),
            ]),
            const SizedBox(height: 10),

            // ── Meta chips + expandable filter toggle ──
            Row(children: [
              if (scanner.patternKey != null) ...[
                _MetaChip(
                    icon: Icons.auto_graph_rounded,
                    label: scanner.patternKey!,
                    color: _T.accentSoft,
                    dark: dark),
                const SizedBox(width: 6),
              ],
              if (scanner.searchTerm.isNotEmpty) ...[
                _MetaChip(
                    icon: Icons.search_rounded,
                    label: '"${scanner.searchTerm}"',
                    color: _T.sub(dark),
                    dark: dark),
                const SizedBox(width: 6),
              ],
              if (hasFilters)
                GestureDetector(
                  onTap: () =>
                      setState(() => _filtersExpanded = !_filtersExpanded),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _filtersExpanded
                          ? _T.accent.withOpacity(0.12)
                          : _T.sub(dark).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: _filtersExpanded
                              ? _T.accent.withOpacity(0.35)
                              : _T.sub(dark).withOpacity(0.18)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.tune_rounded,
                          size: 10,
                          color: _filtersExpanded ? _T.accent : _T.sub(dark)),
                      const SizedBox(width: 4),
                      Text(
                        '${activeFilters.length} filter${activeFilters.length == 1 ? '' : 's'}',
                        style: TextStyle(
                            fontSize: 10,
                            color: _filtersExpanded ? _T.accent : _T.sub(dark),
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 3),
                      AnimatedRotation(
                        turns: _filtersExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 150),
                        child: Icon(Icons.keyboard_arrow_down_rounded,
                            size: 12,
                            color: _filtersExpanded ? _T.accent : _T.sub(dark)),
                      ),
                    ]),
                  ),
                )
              else
                _MetaChip(
                    icon: Icons.tune_rounded,
                    label: 'No filters',
                    color: _T.sub(dark),
                    dark: dark),
            ]),

            // ── Expandable filter chips ──
            if (hasFilters)
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 200),
                crossFadeState: _filtersExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: activeFilters
                        .map((f) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _T.accent.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: _T.accent.withOpacity(0.2)),
                              ),
                              child: Text(f.summary,
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: _T.accent,
                                      fontWeight: FontWeight.w600)),
                            ))
                        .toList(),
                  ),
                ),
              ),
          ]),
        ),

        // ── Action bar ──
        Container(
          decoration: BoxDecoration(
            color: _T.surface2(dark),
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(16)),
            border: Border(top: BorderSide(color: _T.border(dark))),
          ),
          child: Row(children: [
            Expanded(
                child: GestureDetector(
              onTap: widget.onRun,
              child: Container(
                height: 46,
                decoration: const BoxDecoration(
                  borderRadius:
                      BorderRadius.only(bottomLeft: Radius.circular(16)),
                ),
                child:
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: _T.accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Icon(Icons.play_arrow_rounded,
                        color: _T.accent, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Run Scanner',
                    style: TextStyle(
                      fontSize: 13,
                      color: _T.accent,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                    ),
                  ),
                ]),
              ),
            )),
            Container(
                width: 1, height: 44, color: _T.border(dark).withOpacity(0.5)),
            GestureDetector(
                onTap: widget.onEdit,
                child: Container(
                    width: 52,
                    height: 44,
                    alignment: Alignment.center,
                    child:
                        Icon(Icons.edit_rounded, size: 17, color: _T.accent))),
            Container(
                width: 1, height: 44, color: _T.border(dark).withOpacity(0.5)),
            GestureDetector(
                onTap: widget.onDelete,
                child: Container(
                  width: 52,
                  height: 44,
                  decoration: const BoxDecoration(
                      borderRadius:
                          BorderRadius.only(bottomRight: Radius.circular(16))),
                  alignment: Alignment.center,
                  child: Icon(Icons.delete_outline_rounded,
                      size: 17, color: _T.red),
                )),
          ]),
        ),
      ]),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool dark;
  const _MetaChip(
      {required this.icon,
      required this.label,
      required this.color,
      required this.dark});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.18))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 10, color: color, fontWeight: FontWeight.w600)),
        ]),
      );
}

// ─────────────────────────────────────────────
// EDIT SCANNER DIALOG (used inside bridge)
// ─────────────────────────────────────────────

class _EditScannerDialog extends StatefulWidget {
  final SavedScanner scanner;
  final bool dark;
  const _EditScannerDialog({required this.scanner, required this.dark});

  @override
  State<_EditScannerDialog> createState() => _EditScannerDialogState();
}

class _EditScannerDialogState extends State<_EditScannerDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.scanner.name);
    _descCtrl = TextEditingController(text: widget.scanner.description ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.dark;
    return Dialog(
      backgroundColor: _T.surface(dark),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: _T.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.edit_rounded, color: _T.accent, size: 18)),
            const SizedBox(width: 10),
            Text('Edit Scanner',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _T.text(dark))),
          ]),
          const SizedBox(height: 18),
          _Field(ctrl: _nameCtrl, hint: 'Scanner name *', dark: dark),
          const SizedBox(height: 10),
          _Field(
              ctrl: _descCtrl,
              hint: 'Description (optional)',
              dark: dark,
              maxLines: 2),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(
                child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                    color: _T.surface2(dark),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _T.border(dark))),
                child: Center(
                    child: Text('Cancel',
                        style: TextStyle(
                            color: _T.sub(dark), fontWeight: FontWeight.w600))),
              ),
            )),
            const SizedBox(width: 10),
            Expanded(
                child: GestureDetector(
              onTap: () {
                if (_nameCtrl.text.trim().isEmpty) return;
                Navigator.pop(context, {
                  'name': _nameCtrl.text.trim(),
                  'desc': _descCtrl.text.trim()
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF5B7FFF), Color(0xFF9B6DFF)]),
                    borderRadius: BorderRadius.circular(12)),
                child: const Center(
                    child: Text('Save',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700))),
              ),
            )),
          ]),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ACTION BAR (Run + Save - clearly visible)
// ─────────────────────────────────────────────

class _ActionBar extends StatelessWidget {
  final bool hasInput;
  final bool loading;
  final bool isSaved;
  final bool isLoaded;
  final bool dark;
  final VoidCallback onRun;
  final VoidCallback onSave;

  const _ActionBar(
      {required this.hasInput,
      required this.loading,
      required this.isSaved,
      required this.isLoaded,
      required this.dark,
      required this.onRun,
      required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      // ── Run Screener (primary) ──
      Expanded(
        child: GestureDetector(
          onTap: (loading || !hasInput) ? null : onRun,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 52,
            decoration: BoxDecoration(
              color: hasInput ? const Color(0xFF5B7FFF) : _T.surface2(dark),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: hasInput ? const Color(0xFF5B7FFF) : _T.border(dark),
              ),
              boxShadow: hasInput
                  ? [
                      BoxShadow(
                          color: const Color(0xFF5B7FFF).withOpacity(0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4)),
                      BoxShadow(
                          color: const Color(0xFF5B7FFF).withOpacity(0.10),
                          blurRadius: 24,
                          offset: const Offset(0, 8)),
                    ]
                  : [],
            ),
            child: loading
                ? const Center(
                    child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white)))
                : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: hasInput
                            ? Colors.white.withOpacity(0.15)
                            : _T.border(dark),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: hasInput ? Colors.white : _T.sub(dark),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Run Screener',
                      style: TextStyle(
                        color: hasInput ? Colors.white : _T.sub(dark),
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ]),
          ),
        ),
      ),
      // ── Save / Update / Saved (secondary icon button) ──
      if (hasInput) ...[
        const SizedBox(width: 10),
        GestureDetector(
          onTap: isSaved ? null : onSave,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isSaved ? _T.green.withOpacity(0.10) : _T.surface(dark),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: isSaved
                      ? _T.green.withOpacity(0.45)
                      : _T.accent.withOpacity(0.35)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(dark ? 0.14 : 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3)),
              ],
            ),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(
                isSaved
                    ? Icons.bookmark_rounded
                    : isLoaded
                        ? Icons.save_rounded
                        : Icons.bookmark_add_outlined,
                color: isSaved ? _T.green : _T.accent,
                size: 19,
              ),
              const SizedBox(height: 2),
              Text(
                isSaved
                    ? 'Saved'
                    : isLoaded
                        ? 'Update'
                        : 'Save',
                style: TextStyle(
                    fontSize: 9,
                    color: isSaved ? _T.green : _T.accent,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2),
              ),
            ]),
          ),
        ),
      ],
    ]);
  }
}

// ─────────────────────────────────────────────
// LOADED SCANNER BANNER
// ─────────────────────────────────────────────

class _LoadedScannerBanner extends StatelessWidget {
  final String name;
  final bool dark;
  final VoidCallback onClear;

  const _LoadedScannerBanner(
      {required this.name, required this.dark, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _T.accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _T.accent.withOpacity(0.25)),
      ),
      child: Row(children: [
        Icon(Icons.bookmark_rounded, size: 16, color: _T.accent),
        const SizedBox(width: 8),
        Expanded(
            child: RichText(
                text: TextSpan(children: [
          TextSpan(
              text: 'Loaded: ',
              style: TextStyle(
                  fontSize: 12,
                  color: _T.sub(dark),
                  fontWeight: FontWeight.w500)),
          TextSpan(
              text: name,
              style: TextStyle(
                  fontSize: 12, color: _T.accent, fontWeight: FontWeight.w700)),
        ]))),
        GestureDetector(
          onTap: onClear,
          child: Icon(Icons.close_rounded, size: 16, color: _T.sub(dark)),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────

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

class _EmptyState extends StatelessWidget {
  final bool dark;
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyState(
      {required this.dark,
      required this.icon,
      required this.title,
      required this.subtitle});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
        child: Column(children: [
          Icon(icon, size: 44, color: _T.sub(dark)),
          const SizedBox(height: 12),
          Text(title,
              style: TextStyle(
                  fontSize: 15,
                  color: _T.text(dark),
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: _T.sub(dark))),
        ]),
      );
}

class _SearchField extends StatelessWidget {
  final TextEditingController ctrl;
  final bool dark;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  const _SearchField(
      {required this.ctrl,
      required this.dark,
      required this.onChanged,
      required this.onClear});

  @override
  Widget build(BuildContext context) => Container(
        height: 46,
        decoration: BoxDecoration(
          color: _T.surface(dark),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: _T.border(dark)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(dark ? 0.16 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(children: [
          const SizedBox(width: 12),
          Icon(Icons.search_rounded, size: 18, color: _T.sub(dark)),
          const SizedBox(width: 8),
          Expanded(
              child: TextField(
            controller: ctrl,
            onChanged: onChanged,
            style: TextStyle(fontSize: 14, color: _T.text(dark)),
            decoration: InputDecoration(
                hintText: 'Search stocks by name...',
                hintStyle: TextStyle(fontSize: 14, color: _T.sub(dark)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero),
          )),
          if (ctrl.text.isNotEmpty)
            GestureDetector(
                onTap: onClear,
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.close_rounded,
                        size: 16, color: _T.sub(dark)))),
        ]),
      );
}

class _PageBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final bool dark;
  final VoidCallback onTap;
  const _PageBtn(
      {required this.icon,
      required this.enabled,
      required this.dark,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedOpacity(
          opacity: enabled ? 1.0 : 0.3,
          duration: const Duration(milliseconds: 150),
          child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                  color: _T.surface(dark),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _T.border(dark))),
              child: Icon(icon, size: 14, color: _T.text(dark))),
        ),
      );
}

// ─────────────────────────────────────────────
// DETAIL BOTTOM SHEET
// ─────────────────────────────────────────────

class _DetailSheet extends StatelessWidget {
  final GeneratedDataModel stock;
  final bool dark;
  const _DetailSheet({required this.stock, required this.dark});

  @override
  Widget build(BuildContext context) {
    final isPos = stock.pcnt >= 0;
    final gc = isPos ? _T.green : _T.red;
    return Container(
      decoration: BoxDecoration(
          color: _T.surface(dark),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.35,
        expand: false,
        builder: (_, ctrl) => Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
            child: Column(children: [
              Center(
                  child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                          color: _T.border(dark),
                          borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(stock.stckname,
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: _T.text(dark),
                              letterSpacing: -0.4)),
                      if (stock.sec != null)
                        Text(stock.sec!,
                            style:
                                TextStyle(fontSize: 12, color: _T.sub(dark))),
                    ])),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                  decoration: BoxDecoration(
                      color: gc.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: gc.withOpacity(0.28))),
                  child: Text(
                      '${isPos ? '+' : ''}${stock.pcnt.toStringAsFixed(2)}%',
                      style: TextStyle(
                          color: gc,
                          fontWeight: FontWeight.w800,
                          fontSize: 14)),
                ),
              ]),
              const SizedBox(height: 4),
              Align(
                  alignment: Alignment.centerLeft,
                  child: Text('₹${stock.close.toStringAsFixed(2)}',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: _T.text(dark),
                          letterSpacing: -1))),
              const SizedBox(height: 10),
              SizedBox(
                  width: double.infinity,
                  height: 72,
                  child: CustomPaint(
                      painter: _SparklinePainter(
                          data: stock.performanceSeries, color: gc))),
              const SizedBox(height: 14),
              SizedBox(
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFF5B7FFF), Color(0xFF9B6DFF)]),
                        borderRadius: BorderRadius.circular(12)),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Get.toNamed('/stocks/${stock.stckname}');
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12)),
                      icon: const Icon(Icons.open_in_new_rounded,
                          color: Colors.white, size: 15),
                      label: const Text('View Full Details',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                    ),
                  )),
            ]),
          ),
          Divider(height: 1, color: _T.border(dark)),
          Expanded(
              child: ListView(
            controller: ctrl,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              _InfoGrid(stock: stock, dark: dark),
              if (stock.weekMin52Low != null &&
                  stock.weekMax52High != null) ...[
                const SizedBox(height: 12),
                _WeekRange(stock: stock, dark: dark)
              ],
              if (stock.ema20 != null ||
                  stock.ema50 != null ||
                  stock.ema200 != null) ...[
                const SizedBox(height: 12),
                _MASection(stock: stock, dark: dark)
              ],
            ],
          )),
        ]),
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  final GeneratedDataModel stock;
  final bool dark;
  const _InfoGrid({required this.stock, required this.dark});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Open', '₹${stock.open.toStringAsFixed(2)}', null),
      ('High', '₹${stock.high.toStringAsFixed(2)}', _T.green),
      ('Low', '₹${stock.low.toStringAsFixed(2)}', _T.red),
      ('Volume', formatVolume(stock.vol), null),
      ('RSI 14', stock.rsi14?.toStringAsFixed(1) ?? '—', null),
      (
        'Change',
        '${stock.pcnt >= 0 ? '+' : ''}${stock.pcnt.toStringAsFixed(2)}%',
        stock.pcnt >= 0 ? _T.green : _T.red
      ),
    ];
    return Container(
      decoration: BoxDecoration(
          color: _T.surface2(dark),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _T.border(dark))),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        childAspectRatio: 2.0,
        children: items
            .map((item) => Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(item.$1,
                            style:
                                TextStyle(fontSize: 10, color: _T.sub(dark))),
                        const SizedBox(height: 3),
                        Text(item.$2,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: item.$3 ?? _T.text(dark))),
                      ]),
                ))
            .toList(),
      ),
    );
  }
}

class _WeekRange extends StatelessWidget {
  final GeneratedDataModel stock;
  final bool dark;
  const _WeekRange({required this.stock, required this.dark});

  @override
  Widget build(BuildContext context) {
    final lo = stock.weekMin52Low!, hi = stock.weekMax52High!;
    final pos =
        (hi - lo) == 0 ? 0.0 : ((stock.close - lo) / (hi - lo)).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: _T.surface2(dark),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _T.border(dark))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('52 Week Range',
            style: TextStyle(
                fontSize: 11,
                color: _T.sub(dark),
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('₹${lo.toStringAsFixed(2)}',
              style: TextStyle(
                  color: _T.red, fontWeight: FontWeight.w700, fontSize: 13)),
          Text('₹${hi.toStringAsFixed(2)}',
              style: TextStyle(
                  color: _T.green, fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
        const SizedBox(height: 7),
        ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
                value: pos,
                backgroundColor: _T.red.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(_T.green),
                minHeight: 5)),
      ]),
    );
  }
}

class _MASection extends StatelessWidget {
  final GeneratedDataModel stock;
  final bool dark;
  const _MASection({required this.stock, required this.dark});

  @override
  Widget build(BuildContext context) {
    final mas = [
      if (stock.ema20 != null) ('EMA 20', stock.ema20!),
      if (stock.ema50 != null) ('EMA 50', stock.ema50!),
      if (stock.ema100 != null) ('EMA 100', stock.ema100!),
      if (stock.ema200 != null) ('EMA 200', stock.ema200!),
      if (stock.sma20 != null) ('SMA 20', stock.sma20!),
      if (stock.sma50 != null) ('SMA 50', stock.sma50!),
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: _T.surface2(dark),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _T.border(dark))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Moving Averages',
            style: TextStyle(
                fontSize: 11,
                color: _T.sub(dark),
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Wrap(
            spacing: 6,
            runSpacing: 6,
            children: mas.map((ma) {
              final above = stock.close > ma.$2;
              final color = above ? _T.green : _T.red;
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withOpacity(0.22))),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ma.$1,
                          style: TextStyle(
                              fontSize: 9,
                              color: color,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('₹${ma.$2.toStringAsFixed(1)}',
                          style: TextStyle(
                              fontSize: 12,
                              color: _T.text(dark),
                              fontWeight: FontWeight.w600)),
                    ]),
              );
            }).toList()),
      ]),
    );
  }
}
