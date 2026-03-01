import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:optionxi/Components/cust_contact_us.dart';
import 'package:optionxi/PushNotification/notifcation_service_firebase.dart';
import 'package:optionxi/browser_lite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:optionxi/Main_Pages/act_setalert_page_all.dart';
import 'package:timeago/timeago.dart' as timeago;

// ─────────────────────────────────────────────
// Design tokens
// ─────────────────────────────────────────────
class _AppTokens {
  static const radius = 16.0;
  static const radiusLg = 24.0;
  static const radiusSm = 10.0;

  static const amber = Color(0xFFF59E0B);
  static const amberDark = Color(0xFF92400E);
  static const purple = Color(0xFF7C3AED);
  static const green = Color(0xFF10B981);
  static const red = Color(0xFFEF4444);
  static const blue = Color(0xFF3B82F6);
}

// ─────────────────────────────────────────────
// Data models
// ─────────────────────────────────────────────
class ComplexCondition {
  String leftIndicator;
  String operator;
  String rightIndicator;
  String? logicalOperator;

  ComplexCondition({
    this.leftIndicator = 'close',
    this.operator = '>',
    this.rightIndicator = 'open',
    this.logicalOperator = 'AND',
  });

  bool isComplete() =>
      leftIndicator.isNotEmpty &&
      operator.isNotEmpty &&
      rightIndicator.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'left': leftIndicator,
        'operator': operator,
        'right': rightIndicator,
        'logical': logicalOperator,
      };
}

// ─────────────────────────────────────────────
// Main page
// ─────────────────────────────────────────────
class SetAlertPage extends StatefulWidget {
  final String stockName;
  final String segment;

  const SetAlertPage({
    Key? key,
    required this.stockName,
    this.segment = 'stock',
  }) : super(key: key);

  @override
  State<SetAlertPage> createState() => _SetAlertPageState();
}

class _SetAlertPageState extends State<SetAlertPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final _scrollController = ScrollController();

  final _dio = Dio(BaseOptions(
    baseUrl: 'https://alerts.optionxi.com',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));
  final _supabase = Supabase.instance.client;

  String _selectedAlertType = 'price_above';
  String _alertCreationMode = 'basic';
  bool _isPremium = false;
  List<Map<String, dynamic>> _activeAlerts = [];
  int _totalUserAlerts = 0;
  bool _isLoading = false;
  List<ComplexCondition> _complexConditions = [];

  StreamSubscription<Map<String, dynamic>>? _alertStreamListener;
  StreamSubscription<List<Map<String, dynamic>>>? _alertsUpdateListener;

  late final AnimationController _fadeController;
  late final AnimationController _shimmerController;
  late final Animation<double> _fadeAnim;

  // ─── Constants ────────────────────────────
  final Map<String, String> _alertTypes = {
    'price_above': 'Price Above',
    'price_below': 'Price Below',
    'breaking_high': 'Breaking Day High',
    'breaking_low': 'Breaking Day Low',
    'breaking_52w_high': 'Breaking 52W High',
    'breaking_52w_low': 'Breaking 52W Low',
    'breaking_week_high': 'Breaking Week High',
    'breaking_week_low': 'Breaking Week Low',
    'premium': 'Premium Alert',
  };

  Map<String, String> get _filteredAlertTypes {
    if (widget.segment == 'fno' || widget.segment == 'index') {
      return {
        'price_above': 'Price Above',
        'price_below': 'Price Below',
        'breaking_high': 'Breaking Day High',
        'breaking_low': 'Breaking Day Low',
      };
    }
    return _alertTypes;
  }

  final Set<String> _priceInputTypes = {'price_above', 'price_below'};

  final Map<String, List<String>> _indicatorGroups = {
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
    'Volume': [
      'vol',
      'curr_month_vol',
      'curr_week_vol',
      'curr_day_sma5_volume'
    ],
    'RSI': ['rsi14', 'curr_week_rsi14'],
    'Historical': [
      'max_250_high',
      'min_250_low',
      'week_max_52_high',
      'week_min_52_low'
    ],
  };

  final List<String> _operators = ['>', '<', '>=', '<=', '=='];
  final List<String> _logicalOperators = ['AND', 'OR'];

  late final List<String> _allIndicators =
      _indicatorGroups.values.expand((l) => l).toList();

  String get _cleanStockName => widget.stockName
      .replaceAll('NSE:', '')
      .replaceAll('-EQ', '')
      .replaceAll('-BZ', '');

  // ─── Lifecycle ────────────────────────────
  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    NotificationServiceFirebase().forceRefreshAndSyncToken();
    _initializeData();
    _startRealTimeAlertMonitoring();
  }

  @override
  void dispose() {
    _priceController.dispose();
    _scrollController.dispose();
    _alertStreamListener?.cancel();
    _alertsUpdateListener?.cancel();
    _fadeController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    await _checkPremiumStatus();
    await _loadAlerts();
    _fadeController.forward();
  }

  Future<void> _checkPremiumStatus() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    try {
      final response = await _supabase
          .from('subscriptions')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .maybeSingle();
      if (mounted) setState(() => _isPremium = response != null);
    } catch (e) {
      debugPrint('Premium check error: $e');
      if (mounted) setState(() => _isPremium = false);
    }
  }

  void _startRealTimeAlertMonitoring() {
    _alertsUpdateListener?.cancel();
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    _alertsUpdateListener = _supabase
        .from('alerts')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .listen((List<Map<String, dynamic>> alerts) {
          if (!mounted) return;
          final filtered = alerts
              .where((a) =>
                  a['symbol'] == widget.stockName && a['is_deleted'] != true)
              .toList();
          setState(() => _activeAlerts = filtered);
        });
  }

  Future<void> _loadAlerts() async {
    if (_isLoading) return;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    setState(() => _isLoading = true);
    try {
      final alertsResponse = await _supabase
          .from('alerts')
          .select()
          .eq('user_id', userId)
          .eq('symbol', widget.stockName)
          .eq('is_deleted', false)
          .order('created_at', ascending: false);

      final totalResponse = await _supabase
          .from('alerts')
          .select('id')
          .eq('user_id', userId)
          .eq('is_deleted', false);

      if (mounted) {
        setState(() {
          _activeAlerts = List<Map<String, dynamic>>.from(alertsResponse);
          _totalUserAlerts = totalResponse.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Load alerts error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Failed to load alerts', isError: true);
      }
    }
  }

  Future<String?> _getFirebaseToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      return user != null ? await user.getIdToken() : null;
    } catch (e) {
      return null;
    }
  }

  // ─── Alert CRUD ───────────────────────────
  Future<void> _addAlert() async {
    if (!_formKey.currentState!.validate()) return;

    final token = await _getFirebaseToken();
    if (token == null) {
      _showSnackBar('Authentication failed. Please sign in again.',
          isError: true);
      return;
    }

    if (_alertCreationMode == 'premium' && !_isPremium) {
      _showUpgradeDialog();
      return;
    }

    final limit = _isPremium ? 300 : 30;
    if (_totalUserAlerts >= limit) {
      _isPremium
          ? _showSnackBar('Maximum 300 alerts reached', isError: true)
          : _showUpgradeDialog();
      return;
    }

    HapticFeedback.lightImpact();
    _showModernLoadingDialog();

    try {
      Map<String, dynamic> alertData = {
        'symbol': widget.stockName,
        'type': _selectedAlertType,
        'is_active': true,
      };

      if (_alertCreationMode == 'premium') {
        final validConditions =
            _complexConditions.where((c) => c.isComplete()).toList();
        if (validConditions.isEmpty) {
          _showSnackBar('Add at least one complete condition.', isError: true);
          if (mounted) Navigator.of(context, rootNavigator: true).pop();
          return;
        }
        if (!_isPremium) {
          _showUpgradeDialog();
          if (mounted) Navigator.of(context, rootNavigator: true).pop();
          return;
        }
        final conditionsToSave = validConditions.asMap().entries.map((entry) {
          final json = entry.value.toJson();
          if (entry.key == validConditions.length - 1) json.remove('logical');
          return json;
        }).toList();
        alertData['type'] = 'premium';
        alertData['complex_conditions'] = conditionsToSave;
      } else {
        final isPriceAlert = _priceInputTypes.contains(_selectedAlertType);
        final hasPriceInput = _priceController.text.isNotEmpty &&
            double.tryParse(_priceController.text) != null;
        if (isPriceAlert && !hasPriceInput) {
          _showSnackBar('Enter a valid target price.', isError: true);
          if (mounted) Navigator.of(context, rootNavigator: true).pop();
          return;
        }
        if (isPriceAlert && hasPriceInput) {
          alertData['target_price'] = double.parse(_priceController.text);
        }
      }

      await _dio.post('/alerts',
          data: alertData,
          options: Options(headers: {'Authorization': 'Bearer $token'}));

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        setState(() {
          _priceController.clear();
          _complexConditions = [];
          _alertCreationMode = 'basic';
        });
        HapticFeedback.mediumImpact();
        _showSnackBar('Alert created successfully ✓');
        await _loadAlerts();
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        _showSnackBar('Failed to create alert', isError: true);
      }
    }
  }

  Future<void> _deleteAlert(String alertId) async {
    final token = await _getFirebaseToken();
    if (token == null) {
      _showSnackBar('Auth failed', isError: true);
      return;
    }

    HapticFeedback.lightImpact();
    _showModernLoadingDialog();
    try {
      await _dio.delete('/alerts/$alertId',
          options: Options(headers: {'Authorization': 'Bearer $token'}));
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        _showSnackBar('Alert removed');
        await _loadAlerts();
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        _showSnackBar('Failed to delete alert', isError: true);
      }
    }
  }

  Future<void> _toggleAlert(String alertId, bool currentStatus) async {
    final token = await _getFirebaseToken();
    if (token == null) {
      _showSnackBar('Auth failed', isError: true);
      return;
    }

    HapticFeedback.selectionClick();
    _showModernLoadingDialog();
    try {
      await _dio.patch('/alerts/$alertId',
          data: {'is_active': !currentStatus},
          options: Options(headers: {'Authorization': 'Bearer $token'}));
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        await _loadAlerts();
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        _showSnackBar('Failed to update alert', isError: true);
      }
    }
  }

  // ─── Dialogs / Overlays ───────────────────
  void _showModernLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black38,
      builder: (context) => Center(
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                  color: Colors.black26,
                  blurRadius: 24,
                  offset: const Offset(0, 8)),
            ],
          ),
          child: Center(
            child: SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation(_AppTokens.purple),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_AppTokens.radiusLg)),
          backgroundColor: scheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _AppTokens.amber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.workspace_premium_rounded,
                        color: _AppTokens.amber, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Text('Go Premium',
                      style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                ]),
                const SizedBox(height: 20),
                Text(
                    'Unlock the full power of intelligent alerts and never miss a market move.',
                    style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface.withOpacity(0.65),
                        height: 1.5)),
                const SizedBox(height: 24),
                ...[
                  (
                    Icons.notifications_active_rounded,
                    '300 alerts per account'
                  ),
                  (
                    Icons.account_tree_rounded,
                    'Multi-condition complex alerts'
                  ),
                  (
                    Icons.candlestick_chart_rounded,
                    'Advanced technical indicators'
                  ),
                  (Icons.merge_type_rounded, 'AND / OR logic conditions'),
                ].map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _AppTokens.amber.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child:
                              Icon(item.$1, size: 16, color: _AppTokens.amber),
                        ),
                        const SizedBox(width: 12),
                        Text(item.$2,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500)),
                      ]),
                    )),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: TextButton.styleFrom(
                        foregroundColor: scheme.onSurface.withOpacity(0.5)),
                    child: const Text('Not now'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () => showContactOptions(context),
                    icon: const Icon(Icons.bolt_rounded, size: 18),
                    label: const Text('Upgrade Now'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _AppTokens.amber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Row(children: [
          Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_rounded,
              color: Colors.white,
              size: 18),
          const SizedBox(width: 10),
          Expanded(
              child: Text(message,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13))),
        ]),
        backgroundColor: isError ? _AppTokens.red : _AppTokens.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 2),
        elevation: 8,
      ));
  }

  // ─── Build ────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final usedLimit = _isPremium ? 300 : 30;
    final pct = (_totalUserAlerts / usedLimit).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: scheme.background,
      appBar: _buildAppBar(scheme, isDark, pct, usedLimit),
      body: RefreshIndicator(
        onRefresh: _loadAlerts,
        color: _AppTokens.purple,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.segment != 'fno' && widget.segment != 'index') ...[
                  _buildStatusBanner(scheme, isDark),
                  const SizedBox(height: 16),
                ],
                _buildCreateAlertCard(scheme, isDark),
                const SizedBox(height: 28),
                _buildAlertsSection(scheme, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      ColorScheme scheme, bool isDark, double pct, int limit) {
    return AppBar(
      backgroundColor: scheme.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _cleanStockName,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: scheme.onBackground,
              letterSpacing: -0.3,
            ),
          ),
          Text(
            'Price Alerts',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: scheme.onBackground.withOpacity(0.4),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$_totalUserAlerts / $limit',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: pct >= 1.0 ? _AppTokens.red : scheme.onBackground,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 52,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 3,
                    backgroundColor: scheme.onBackground.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation(
                      pct >= 1.0
                          ? _AppTokens.red
                          : pct >= 0.8
                              ? _AppTokens.amber
                              : _AppTokens.purple,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Status Banner ────────────────────────
  Widget _buildStatusBanner(ColorScheme scheme, bool isDark) {
    if (_isPremium) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _AppTokens.amber.withOpacity(isDark ? 0.25 : 0.15),
              _AppTokens.amber.withOpacity(isDark ? 0.1 : 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(_AppTokens.radius),
          border:
              Border.all(color: _AppTokens.amber.withOpacity(0.3), width: 1),
        ),
        child: Row(children: [
          const Icon(Icons.workspace_premium_rounded,
              color: _AppTokens.amber, size: 18),
          const SizedBox(width: 10),
          Text('Premium — All features unlocked',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? _AppTokens.amber : _AppTokens.amberDark,
              )),
        ]),
      );
    }
    return GestureDetector(
      onTap: _showUpgradeDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? scheme.surfaceVariant.withOpacity(0.4)
              : scheme.surfaceVariant.withOpacity(0.6),
          borderRadius: BorderRadius.circular(_AppTokens.radius),
          border: Border.all(
              color: scheme.outlineVariant.withOpacity(0.5), width: 1),
        ),
        child: Row(children: [
          Icon(Icons.lock_open_rounded,
              size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Upgrade for complex multi-condition alerts',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurfaceVariant,
                )),
          ),
          Icon(Icons.chevron_right_rounded,
              size: 18, color: scheme.onSurfaceVariant),
        ]),
      ),
    );
  }

  // ─── Create Alert Card ────────────────────
  Widget _buildCreateAlertCard(ColorScheme scheme, bool isDark) {
    final isPriceAlert = _priceInputTypes.contains(_selectedAlertType);
    return Container(
      decoration: BoxDecoration(
        color: isDark ? scheme.surfaceVariant.withOpacity(0.5) : scheme.surface,
        borderRadius: BorderRadius.circular(_AppTokens.radiusLg),
        border: Border.all(
          color: isDark
              ? scheme.outline.withOpacity(0.2)
              : scheme.outlineVariant.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 4))
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(children: [
                Expanded(
                  child: Text('Create Alert',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                ),
                _buildChartButton(scheme),
              ]),
              const SizedBox(height: 20),

              // Mode toggle (only for stock)
              if (widget.segment != 'fno' && widget.segment != 'index')
                _buildModeToggle(scheme, isDark),

              const SizedBox(height: 20),

              // Form content
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: _alertCreationMode == 'basic'
                    ? _buildBasicForm(scheme, isDark, isPriceAlert)
                    : _buildComplexForm(scheme, isDark),
              ),

              const SizedBox(height: 20),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartButton(ColorScheme scheme) {
    return GestureDetector(
      onTap: () {
        var name = _cleanStockName;
        if (name == 'NIFTY50') name = 'NIFTY';
        if (name == 'NIFTYBANK') name = 'BANKNIFTY';
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => BrowserLite_V(
                    'https://in.tradingview.com/chart/?symbol=NSE%3A$name')));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _AppTokens.purple.withOpacity(0.1),
          borderRadius: BorderRadius.circular(_AppTokens.radiusSm),
          border: Border.all(color: _AppTokens.purple.withOpacity(0.2)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.candlestick_chart_rounded,
              size: 15, color: _AppTokens.purple),
          const SizedBox(width: 6),
          Text('Chart',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _AppTokens.purple)),
        ]),
      ),
    );
  }

  Widget _buildModeToggle(ColorScheme scheme, bool isDark) {
    final isBasic = _alertCreationMode == 'basic';
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color:
            isDark ? scheme.background : scheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.4)),
      ),
      child: Row(children: [
        _toggleSegment('Basic Alert', Icons.flash_on_rounded, isBasic, () {
          setState(() => _alertCreationMode = 'basic');
        }, scheme, isDark),
        _toggleSegment('Premium', Icons.workspace_premium_rounded, !isBasic,
            () {
          setState(() {
            _alertCreationMode = 'premium';
            if (_complexConditions.isEmpty)
              _complexConditions.add(ComplexCondition());
          });
        }, scheme, isDark, isPremium: true),
      ]),
    );
  }

  Widget _toggleSegment(String label, IconData icon, bool selected,
      VoidCallback onTap, ColorScheme scheme, bool isDark,
      {bool isPremium = false}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? (isPremium
                    ? _AppTokens.amber.withOpacity(0.15)
                    : _AppTokens.purple.withOpacity(0.15))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: selected
                ? Border.all(
                    color: isPremium
                        ? _AppTokens.amber.withOpacity(0.4)
                        : _AppTokens.purple.withOpacity(0.3),
                    width: 1)
                : null,
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon,
                size: 15,
                color: selected
                    ? (isPremium ? _AppTokens.amber : _AppTokens.purple)
                    : scheme.onSurface.withOpacity(0.4)),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? (isPremium ? _AppTokens.amber : _AppTokens.purple)
                      : scheme.onSurface.withOpacity(0.5),
                )),
          ]),
        ),
      ),
    );
  }

  Widget _buildBasicForm(ColorScheme scheme, bool isDark, bool isPriceAlert) {
    return Column(
      key: const ValueKey('basic'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Alert Type', scheme),
        const SizedBox(height: 8),
        _buildStyledDropdown<String>(
          value: _selectedAlertType,
          icon: Icons.notifications_active_rounded,
          items: _filteredAlertTypes.entries
              .where((e) => e.key != 'premium')
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: (v) => setState(() => _selectedAlertType = v!),
          scheme: scheme,
          isDark: isDark,
        ),
        if (isPriceAlert) ...[
          const SizedBox(height: 16),
          _buildSectionLabel('Target Price', scheme),
          const SizedBox(height: 8),
          _buildPriceField(scheme, isDark),
        ],
      ],
    );
  }

  Widget _buildSectionLabel(String text, ColorScheme scheme) {
    return Text(text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface.withOpacity(0.5),
          letterSpacing: 0.5,
        ));
  }

  Widget _buildStyledDropdown<T>({
    required T value,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required ColorScheme scheme,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color:
            isDark ? scheme.background : scheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(_AppTokens.radius),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.5)),
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, size: 18, color: _AppTokens.purple),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 8), // Adjusted vertical padding
          isDense: true, // Added this
        ),
        dropdownColor: isDark ? scheme.surfaceVariant : scheme.surface,
        borderRadius: BorderRadius.circular(_AppTokens.radius),
        items: items,
        onChanged: onChanged,
        style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600, color: scheme.onSurface),
        icon: Icon(Icons.expand_more_rounded,
            color: scheme.onSurface.withOpacity(0.4)),
      ),
    );
  }

  Widget _buildPriceField(ColorScheme scheme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color:
            isDark ? scheme.background : scheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(_AppTokens.radius),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.5)),
      ),
      child: TextFormField(
        controller: _priceController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600, color: scheme.onSurface),
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(Icons.currency_rupee_rounded,
              size: 18, color: _AppTokens.purple),
          hintText: 'Enter target price',
          hintStyle: TextStyle(
              color: scheme.onSurface.withOpacity(0.35), fontSize: 14),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
        validator: (value) {
          if (_alertCreationMode != 'basic') return null;
          if (value == null || value.isEmpty) return 'Enter a price';
          final price = double.tryParse(value);
          if (price == null) return 'Enter a valid number';
          if (price > 100000) return 'Cannot exceed ₹1,00,000';
          if (price <= 0) return 'Must be greater than 0';
          return null;
        },
      ),
    );
  }

  Widget _buildComplexForm(ColorScheme scheme, bool isDark) {
    final validConditions =
        _complexConditions.where((c) => c.isComplete()).toList();
    return Column(
      key: const ValueKey('complex'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (validConditions.isNotEmpty) ...[
          _buildConditionSummary(validConditions, scheme),
          const SizedBox(height: 16),
        ],
        ..._complexConditions.asMap().entries.map((entry) =>
            _buildComplexConditionCard(entry.value, entry.key, scheme, isDark)),
        const SizedBox(height: 10),
        _buildAddConditionButton(scheme),
      ],
    );
  }

  Widget _buildAddConditionButton(ColorScheme scheme) {
    return GestureDetector(
      onTap: () {
        if (_complexConditions.length < 10) {
          setState(() => _complexConditions.add(ComplexCondition()));
        } else {
          _showSnackBar('Maximum 10 conditions allowed', isError: true);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_AppTokens.radius),
          border: Border.all(
              color: _AppTokens.purple.withOpacity(0.3),
              style: BorderStyle.solid),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.add_circle_outline_rounded,
              size: 16, color: _AppTokens.purple),
          const SizedBox(width: 8),
          Text('Add Condition',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _AppTokens.purple)),
        ]),
      ),
    );
  }

  Widget _buildConditionSummary(
      List<ComplexCondition> conditions, ColorScheme scheme) {
    List<InlineSpan> spans = [];
    for (int i = 0; i < conditions.length; i++) {
      final c = conditions[i];
      spans.addAll([
        TextSpan(
          text: c.leftIndicator.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        TextSpan(
          text: ' ${c.operator} ',
          style: TextStyle(
            color: _AppTokens.purple,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
        TextSpan(
          text: c.rightIndicator.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ]);
      if (i < conditions.length - 1 && c.logicalOperator != null) {
        spans.add(TextSpan(
          text: '  ${c.logicalOperator}  ',
          style: TextStyle(
            color: _AppTokens.red,
            fontWeight: FontWeight.w800,
            fontSize: 11,
          ),
        ));
      }
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _AppTokens.purple.withOpacity(0.06),
        borderRadius: BorderRadius.circular(_AppTokens.radius),
        border: Border.all(color: _AppTokens.purple.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.auto_awesome_rounded, size: 14, color: _AppTokens.purple),
          const SizedBox(width: 6),
          Text('Alert will trigger when (3 min delay)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _AppTokens.purple.withOpacity(0.8),
                letterSpacing: 0.2,
              )),
        ]),
        const SizedBox(height: 8),
        SelectableText.rich(TextSpan(children: spans)),
      ]),
    );
  }

  Widget _buildComplexConditionCard(
      ComplexCondition condition, int index, ColorScheme scheme, bool isDark) {
    final isLast = index == _complexConditions.length - 1;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? scheme.background : scheme.surface,
        borderRadius: BorderRadius.circular(_AppTokens.radius),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _AppTokens.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('IF ${index + 1}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: _AppTokens.purple,
                    letterSpacing: 0.5,
                  )),
            ),
            const Spacer(),
            if (_complexConditions.length > 1)
              GestureDetector(
                onTap: () => setState(() => _complexConditions.removeAt(index)),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _AppTokens.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.remove_rounded,
                      size: 16, color: _AppTokens.red),
                ),
              ),
          ]),
          const SizedBox(height: 12),
          _buildIndicatorDropdown(
            label: 'When',
            selectedValue: condition.leftIndicator,
            onChanged: (v) => setState(() => condition.leftIndicator = v!),
            scheme: scheme,
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          Row(children: [
            SizedBox(
              width: 90,
              child: _buildOperatorDropdown(condition, scheme, isDark),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildIndicatorDropdown(
                label: 'Compared to',
                selectedValue: condition.rightIndicator,
                onChanged: (v) => setState(() => condition.rightIndicator = v!),
                scheme: scheme,
                isDark: isDark,
              ),
            ),
          ]),
          if (!isLast) ...[
            const SizedBox(height: 14),
            _buildLogicalOperatorToggle(condition, scheme, isDark),
          ],
        ]),
      ),
    );
  }

  Widget _buildOperatorDropdown(
      ComplexCondition condition, ColorScheme scheme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? scheme.surfaceVariant.withOpacity(0.5)
            : scheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.5)),
      ),
      child: DropdownButtonFormField<String>(
        value: condition.operator,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          isDense: true,
        ),
        items: _operators
            .map((op) => DropdownMenuItem(
                  value: op,
                  child: Text(op,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                ))
            .toList(),
        onChanged: (v) => setState(() => condition.operator = v!),
        icon: const SizedBox.shrink(),
        dropdownColor: isDark ? scheme.surfaceVariant : scheme.surface,
      ),
    );
  }

  Widget _buildLogicalOperatorToggle(
      ComplexCondition condition, ColorScheme scheme, bool isDark) {
    return Row(children: [
      Text('Then',
          style: TextStyle(
              fontSize: 11, color: scheme.onSurface.withOpacity(0.4))),
      const SizedBox(width: 10),
      ..._logicalOperators.map((op) {
        final selected = condition.logicalOperator == op;
        final isAnd = op == 'AND';
        return GestureDetector(
          onTap: () => setState(() => condition.logicalOperator = op),
          child: Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: selected
                  ? (isAnd
                      ? _AppTokens.blue.withOpacity(0.15)
                      : _AppTokens.red.withOpacity(0.12))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: selected
                    ? (isAnd
                        ? _AppTokens.blue.withOpacity(0.4)
                        : _AppTokens.red.withOpacity(0.35))
                    : scheme.outlineVariant.withOpacity(0.4),
              ),
            ),
            child: Text(op,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? (isAnd ? _AppTokens.blue : _AppTokens.red)
                      : scheme.onSurface.withOpacity(0.4),
                )),
          ),
        );
      }),
    ]);
  }

  Widget _buildIndicatorDropdown({
    required String label,
    required String selectedValue,
    required ValueChanged<String?> onChanged,
    required ColorScheme scheme,
    required bool isDark,
  }) {
    final initial = _allIndicators.contains(selectedValue)
        ? selectedValue
        : _allIndicators.first;

    List<DropdownMenuItem<String>> items = [];
    _indicatorGroups.forEach((group, indicators) {
      items.add(DropdownMenuItem<String>(
        value: null,
        enabled: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(group.toUpperCase(),
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: _AppTokens.purple.withOpacity(0.7),
                  letterSpacing: 0.8)),
        ),
      ));
      items.addAll(indicators.map((ind) => DropdownMenuItem(
            value: ind,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(ind, style: const TextStyle(fontSize: 13)),
            ),
          )));
    });

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? scheme.surfaceVariant.withOpacity(0.4)
            : scheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.5)),
      ),
      child: DropdownButtonFormField<String>(
        value: initial,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
              fontSize: 12, color: scheme.onSurface.withOpacity(0.45)),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          isDense: true,
        ),
        items: items,
        onChanged: onChanged,
        isExpanded: true,
        dropdownColor: isDark ? scheme.surfaceVariant : scheme.surface,
        style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: scheme.onSurface),
        icon: Icon(Icons.expand_more_rounded,
            size: 18, color: scheme.onSurface.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(_AppTokens.radius),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: _addAlert,
        icon: const Icon(Icons.add_alert_rounded, size: 20),
        label: const Text('Set Alert',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.2)),
        style: FilledButton.styleFrom(
          backgroundColor: _AppTokens.purple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_AppTokens.radius)),
          elevation: 0,
        ),
      ),
    );
  }

  // ─── Alerts Section ───────────────────────
  Widget _buildAlertsSection(ColorScheme scheme, bool isDark) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Active Alerts',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3)),
          const SizedBox(height: 2),
          Text('For $_cleanStockName',
              style: TextStyle(
                  fontSize: 12,
                  color: scheme.onBackground.withOpacity(0.4),
                  fontWeight: FontWeight.w500)),
        ]),
        TextButton(
          onPressed: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const AlertsPage())),
          style: TextButton.styleFrom(foregroundColor: _AppTokens.purple),
          child: const Text('View All',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ]),
      const SizedBox(height: 16),
      _isLoading
          ? _buildShimmerList(scheme, isDark)
          : _activeAlerts.isEmpty
              ? Center(child: _buildEmptyState(scheme, isDark))
              : Column(
                  children: _activeAlerts
                      .map((a) => _buildAlertCard(a, scheme, isDark))
                      .toList()),
    ]);
  }

  Widget _buildShimmerList(ColorScheme scheme, bool isDark) {
    return Column(
      children: List.generate(
          4,
          (i) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                height: 100,
                decoration: BoxDecoration(
                  color: isDark
                      ? scheme.surfaceVariant.withOpacity(0.4)
                      : scheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(_AppTokens.radiusLg),
                ),
              )),
    );
  }

  Widget _buildEmptyState(ColorScheme scheme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: isDark
            ? scheme.surfaceVariant.withOpacity(0.3)
            : scheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(_AppTokens.radiusLg),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.3)),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.onBackground.withOpacity(0.06),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.notifications_none_rounded,
              size: 32, color: scheme.onBackground.withOpacity(0.3)),
        ),
        const SizedBox(height: 16),
        Text('No alerts set',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: scheme.onBackground.withOpacity(0.5))),
        const SizedBox(height: 6),
        Text('Create an alert above to get notified',
            style: TextStyle(
                fontSize: 12, color: scheme.onBackground.withOpacity(0.3))),
      ]),
    );
  }

  Widget _buildAlertCard(
      Map<String, dynamic> alert, ColorScheme scheme, bool isDark) {
    final isActive = alert['is_active'] as bool? ?? true;
    final type = alert['type'] as String;
    final targetPrice = alert['target_price'];
    final alertId = alert['id'] as String;
    final status = alert['status'] as String?;
    final complexList = alert['complex_conditions'] as List?;
    final hasComplex = complexList != null && complexList.isNotEmpty;

    final statusColor = _getStatusColor(status ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? scheme.surfaceVariant.withOpacity(0.4) : scheme.surface,
        borderRadius: BorderRadius.circular(_AppTokens.radiusLg),
        border: Border.all(
          color: isActive
              ? scheme.outlineVariant.withOpacity(0.5)
              : scheme.outlineVariant.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 3))
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Top row: type badge + controls
          Row(children: [
            // Alert type / info
            Expanded(
              child: hasComplex
                  ? _buildProBadge(complexList)
                  : _buildAlertTypeBadge(type, targetPrice, scheme, isDark),
            ),
            // Controls
            Row(mainAxisSize: MainAxisSize.min, children: [
              GestureDetector(
                onTap: () => _toggleAlert(alertId, isActive),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isActive ? _AppTokens.purple : scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 200),
                    alignment:
                        isActive ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _confirmDelete(alertId, scheme),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _AppTokens.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.delete_outline_rounded,
                      size: 16, color: _AppTokens.red.withOpacity(0.8)),
                ),
              ),
            ]),
          ]),

          // Status row
          if (status != null) ...[
            const SizedBox(height: 10),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withOpacity(0.2)),
                ),
                child: Text(status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                      letterSpacing: 0.5,
                    )),
              ),
              if (status.toLowerCase() == 'triggered' &&
                  alert['updated_at'] != null) ...[
                const SizedBox(width: 8),
                Icon(Icons.access_time_rounded,
                    size: 12, color: scheme.onSurface.withOpacity(0.4)),
                const SizedBox(width: 4),
                Text(timeago.format(_parseDateTime(alert['updated_at'])),
                    style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurface.withOpacity(0.5),
                        fontWeight: FontWeight.w500)),
                const SizedBox(width: 4),
                Text('· ${_formatDateTime(alert['updated_at'])}',
                    style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurface.withOpacity(0.3))),
              ],
            ]),
          ],

          // Expandable complex conditions
          if (hasComplex) ...[
            const SizedBox(height: 10),
            Theme(
              data:
                  Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(top: 8),
                dense: true,
                title: Row(children: [
                  Icon(Icons.visibility_outlined,
                      size: 14, color: _AppTokens.purple),
                  const SizedBox(width: 6),
                  Text('View conditions',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _AppTokens.purple)),
                ]),
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scheme.surfaceVariant.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                        children: complexList.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final cond =
                          Map<String, dynamic>.from(entry.value as Map);
                      final logicalOp = cond['logical'] as String?;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: scheme.surface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color:
                                          _AppTokens.purple.withOpacity(0.15)),
                                ),
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    _conditionChip(
                                        cond['left'].toString().toUpperCase(),
                                        _AppTokens.blue),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color:
                                            _AppTokens.purple.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(cond['operator'],
                                          style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                              color: _AppTokens.purple)),
                                    ),
                                    _conditionChip(
                                        cond['right'].toString().toUpperCase(),
                                        _AppTokens.purple),
                                  ],
                                ),
                              ),
                              if (idx < complexList.length - 1 &&
                                  logicalOp != null)
                                Padding(
                                  padding:
                                      const EdgeInsets.only(left: 12, top: 6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _AppTokens.red.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(5),
                                      border: Border.all(
                                          color:
                                              _AppTokens.red.withOpacity(0.2)),
                                    ),
                                    child: Text(logicalOp,
                                        style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: _AppTokens.red,
                                            letterSpacing: 0.5)),
                                  ),
                                ),
                            ]),
                      );
                    }).toList()),
                  ),
                ],
              ),
            ),
          ],
        ]),
      ),
    );
  }

  void _confirmDelete(String alertId, ColorScheme scheme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: scheme.outlineVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Text('Remove Alert',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('This alert will be permanently removed.',
              style: TextStyle(
                  fontSize: 14, color: scheme.onSurface.withOpacity(0.5))),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _deleteAlert(alertId);
                },
                style: FilledButton.styleFrom(
                    backgroundColor: _AppTokens.red,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: const Text('Remove',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _buildProBadge(List complexList) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text('PRO',
            style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8)),
      ),
      const SizedBox(width: 10),
      Icon(Icons.account_tree_rounded, size: 14, color: _AppTokens.amber),
      const SizedBox(width: 5),
      Text(
          '${complexList.length} ${complexList.length == 1 ? "rule" : "rules"}',
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _AppTokens.amber)),
    ]);
  }

  Widget _buildAlertTypeBadge(
      String type, dynamic targetPrice, ColorScheme scheme, bool isDark) {
    final bool hasPrice = targetPrice != null;
    if (hasPrice) {
      return Row(children: [
        Icon(Icons.track_changes_rounded, size: 14, color: _AppTokens.purple),
        const SizedBox(width: 6),
        Text(_alertTypes[type] ?? type,
            style: TextStyle(
                fontSize: 12, color: scheme.onSurface.withOpacity(0.5))),
        const SizedBox(width: 6),
        Text('₹${double.parse(targetPrice.toString()).toStringAsFixed(2)}',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface)),
      ]);
    }
    return Row(children: [
      Icon(Icons.bolt_rounded, size: 15, color: _AppTokens.purple),
      const SizedBox(width: 6),
      Text(_alertTypes[type] ?? type,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface)),
    ]);
  }

  Widget _conditionChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }

  // ─── Helpers ──────────────────────────────
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'processing':
        return _AppTokens.blue;
      case 'triggered':
        return _AppTokens.green;
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  DateTime _parseDateTime(dynamic ts) {
    try {
      if (ts is DateTime) return ts;
      return DateTime.parse(ts.toString());
    } catch (_) {
      return DateTime.now();
    }
  }

  String _formatDateTime(dynamic ts) {
    try {
      final dt = _parseDateTime(ts).toLocal();
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour < 12 ? 'AM' : 'PM';
      return '$h:$m $period';
    } catch (_) {
      return '';
    }
  }
}
