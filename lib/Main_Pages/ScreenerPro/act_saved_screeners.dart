import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:optionxi/Components/cust_contact_us.dart';
import 'package:optionxi/Components/cust_floating_ai.dart';

// ─────────────────────────────────────────────
// THEME HELPERS (self-contained copy)
// ─────────────────────────────────────────────

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
// DATA MODELS
// ─────────────────────────────────────────────

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

  SavedScanner copyWith({
    String? name,
    String? description,
  }) =>
      SavedScanner(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        patternKey: patternKey,
        filters: filters,
        searchTerm: searchTerm,
        createdAt: createdAt,
      );
}

// ─────────────────────────────────────────────
// INDICATOR LABEL MAP (for filter summaries)
// ─────────────────────────────────────────────

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
// FIREBASE SERVICE
// ─────────────────────────────────────────────

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
    if (_userId == null) return SaveError.other('Not logged in');
    try {
      final snapshot = await _ref.get();
      final count = snapshot.exists ? (snapshot.value as Map?)?.length ?? 0 : 0;
      final premium = await _isPremium();
      final limit = premium ? 50 : 3;
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
// EDIT SCANNER DIALOG
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
              child: Icon(Icons.edit_rounded, color: _T.accent, size: 18),
            ),
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
                              color: _T.sub(dark),
                              fontWeight: FontWeight.w600))),
                ),
              ),
            ),
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                      child: Text('Save',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700))),
                ),
              ),
            ),
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
// SAVED SCANNERS PAGE
// ─────────────────────────────────────────────

class SavedScannersPage extends StatefulWidget {
  const SavedScannersPage({super.key});

  @override
  State<SavedScannersPage> createState() => _SavedScannersPageState();
}

class _SavedScannersPageState extends State<SavedScannersPage> {
  final _svc = ScannerFirebaseService();
  List<SavedScanner> _scanners = [];
  bool _loading = true;
  String? _error;
  bool _isSubscribed = false;
  static const _freeLimit = 3;

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
      setState(() {
        _scanners = results[0] as List<SavedScanner>;
        _isSubscribed = results[1] as bool;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
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
    // Pass as a plain Map so there is no cross-file Dart type mismatch.
    // Both files define their own SavedScanner class; passing the object directly
    // causes `args is SavedScanner` in the screener's initState to always be
    // false because the two classes are different runtime types.
    Get.toNamed('/screenerpro',
        arguments: s.toRealtimeDatabase()..['id'] = s.id,
        preventDuplicates: false);
  }

  Widget _buildUsageBanner(bool dark) {
    final used = _scanners.length;
    final max = _isSubscribed ? 50 : _freeLimit;
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
      ),
    );
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
                size: 14, color: _T.text(dark)),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saved Scanners',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _T.text(dark))),
            if (!_loading && _error == null)
              Text(
                  '${_scanners.length} scanner${_scanners.length == 1 ? '' : 's'}',
                  style: TextStyle(fontSize: 11, color: _T.sub(dark))),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: _T.border(dark)),
        ),
      ),
      floatingActionButton: _scanners.isEmpty
          ? null
          : MagicalAIButton(
              label: "New Screener",
              onPressed: () =>
                  Get.toNamed('/screenerpro', preventDuplicates: false),
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
                          ? _EmptyState(dark: dark)
                          : RefreshIndicator(
                              color: _T.accent,
                              onRefresh: _load,
                              child: ListView.separated(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 14, 16, 96),
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
// SCANNER CARD
// ─────────────────────────────────────────────

class _ScannerCard extends StatefulWidget {
  final SavedScanner scanner;
  final bool dark;
  final VoidCallback onRun;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ScannerCard({
    required this.scanner,
    required this.dark,
    required this.onRun,
    required this.onEdit,
    required this.onDelete,
  });

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

class _EmptyState extends StatelessWidget {
  final bool dark;
  const _EmptyState({required this.dark});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                  color: _T.sub(dark).withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(Icons.bookmark_border_rounded,
                  size: 32, color: _T.sub(dark).withOpacity(0.7)),
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
                style: TextStyle(fontSize: 13, color: _T.sub(dark))),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => Get.toNamed('/screenerpro'),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D3250),
                  borderRadius: BorderRadius.circular(12),
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
      );
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
