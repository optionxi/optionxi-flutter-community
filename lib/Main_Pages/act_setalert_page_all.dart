import 'dart:async';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:optionxi/Main_Pages/act_search_stocks_meili.dart';
import 'package:optionxi/PushNotification/notifcation_service_firebase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:optionxi/Helpers/constants.dart';
import 'package:optionxi/Main_Pages/act_set_alert.dart';
import 'package:timeago/timeago.dart' as timeago;

// ─────────────────────────────────────────────
//  Adaptive Design Tokens  (dark / light aware)
// ─────────────────────────────────────────────
class _T {
  // Surfaces
  static Color bg(bool d) =>
      d ? const Color(0xFF0A0D14) : const Color(0xFFF4F6FB);
  static Color surface(bool d) =>
      d ? const Color(0xFF11151F) : const Color(0xFFFFFFFF);
  static Color card(bool d) =>
      d ? const Color(0xFF161B29) : const Color(0xFFFFFFFF);
  static Color cardBorder(bool d) =>
      d ? const Color(0xFF222840) : const Color(0xFFE2E8F5);
  static Color divider(bool d) =>
      d ? const Color(0xFF1E2436) : const Color(0xFFECF0F9);
  static Color rowSurface(bool d) =>
      d ? const Color(0xFF0F1219) : const Color(0xFFF8FAFF);

  // Text
  static Color textPrimary(bool d) =>
      d ? const Color(0xFFF0F4FF) : const Color(0xFF0F172A);
  static Color textSecondary(bool d) =>
      d ? const Color(0xFF7B8DB0) : const Color(0xFF64748B);

  // Accent (same hue; bg adapts)
  static const accent = Color(0xFF4F7EFF);
  static Color accentBg(bool d) =>
      d ? const Color(0x334F7EFF) : const Color(0xFFEEF3FF);

  static const amber = Color(0xFFFFB547);
  static Color amberBg(bool d) =>
      d ? const Color(0x33FFB547) : const Color(0xFFFFF8ED);

  static const bullish = Color(0xFF16A968);
  static Color bullishBg(bool d) =>
      d ? const Color(0x1A22C987) : const Color(0xFFEDFBF3);

  static const bearish = Color(0xFFEF4444);
  static Color bearishBg(bool d) =>
      d ? const Color(0x1AFF5A6E) : const Color(0xFFFFF0F0);

  // Status foreground colours
  static Color statusFg(String status, bool d) {
    switch (status.toLowerCase()) {
      case 'triggered':
        return d ? const Color(0xFF22C987) : const Color(0xFF16A968);
      case 'processing':
        return accent;
      case 'expired':
        return d ? const Color(0xFFFF5A6E) : bearish;
      default: // pending / paused
        return d ? const Color(0xFF7B8DB0) : const Color(0xFF94A3B8);
    }
  }

  static IconData statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'triggered':
        return Icons.check_circle_rounded;
      case 'processing':
        return Icons.sync_rounded;
      case 'paused':
        return Icons.pause_circle_rounded;
      case 'expired':
        return Icons.timer_off_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }

  static String statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'triggered':
        return 'Triggered';
      case 'processing':
        return 'Processing';
      case 'paused':
        return 'Paused';
      case 'expired':
        return 'Expired';
      default:
        return 'Pending';
    }
  }

  // Radius
  static const r12 = 12.0;
  static const r16 = 16.0;
  static const r20 = 20.0;
}

// ─────────────────────────────────────────────
//  Alert-type helpers (top-level, no state)
// ─────────────────────────────────────────────
Color _alertColor(String type, bool d) {
  switch (type) {
    case 'price_above':
    case 'breaking_high':
    case 'breaking_52w_high':
    case 'breaking_week_high':
      return _T.bullish;
    case 'price_below':
    case 'breaking_low':
    case 'breaking_52w_low':
    case 'breaking_week_low':
      return _T.bearish;
    case 'premium':
      return _T.amber;
    default:
      return _T.accent;
  }
}

Color _alertBg(String type, bool d) {
  switch (type) {
    case 'price_above':
    case 'breaking_high':
    case 'breaking_52w_high':
    case 'breaking_week_high':
      return _T.bullishBg(d);
    case 'price_below':
    case 'breaking_low':
    case 'breaking_52w_low':
    case 'breaking_week_low':
      return _T.bearishBg(d);
    case 'premium':
      return _T.amberBg(d);
    default:
      return _T.accentBg(d);
  }
}

IconData _alertIcon(String type) {
  switch (type) {
    case 'price_above':
      return Icons.north_east_rounded;
    case 'price_below':
      return Icons.south_east_rounded;
    case 'breaking_high':
      return Icons.rocket_launch_rounded;
    case 'breaking_low':
      return Icons.arrow_downward_rounded;
    case 'breaking_52w_high':
      return Icons.emoji_events_rounded;
    case 'breaking_52w_low':
      return Icons.south_rounded;
    case 'breaking_week_high':
      return Icons.show_chart_rounded;
    case 'breaking_week_low':
      return Icons.trending_down_rounded;
    case 'premium':
      return Icons.auto_awesome_rounded;
    default:
      return Icons.notifications_rounded;
  }
}

const Map<String, String> _alertTypeLabels = {
  'price_above': 'Price Above',
  'price_below': 'Price Below',
  'breaking_high': 'Breaking Day High',
  'breaking_low': 'Breaking Day Low',
  'breaking_52w_high': '52W High',
  'breaking_52w_low': '52W Low',
  'breaking_week_high': 'Week High',
  'breaking_week_low': 'Week Low',
  'premium': 'Premium',
};

const Set<String> _priceInputTypes = {'price_above', 'price_below'};

String _symbolDisplay(String s) =>
    s.replaceAll('-EQ', '').replaceAll('NSE:', '').replaceAll('-BZ', '');

// ─────────────────────────────────────────────
//  Page
// ─────────────────────────────────────────────
class AlertsPage extends StatefulWidget {
  const AlertsPage({Key? key}) : super(key: key);

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage>
    with SingleTickerProviderStateMixin {
  bool isLoading = true;
  bool hasError = false;
  Map<String, List<AlertModel>> alerts = {};
  List<AlertModel> ungroupedAlerts = [];
  final _supabase = Supabase.instance.client;
  bool _isPremium = false;
  bool _showTriggeredOnly = false;
  bool _groupBySymbol = true;

  RealtimeChannel? _alertsChannel;
  StreamSubscription? _premiumSubscription;
  late AnimationController _fadeCtrl;

  int get _total => ungroupedAlerts.length;
  int get _fired =>
      ungroupedAlerts.where((a) => a.status == 'triggered').length;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    NotificationServiceFirebase().forceRefreshAndSyncToken();
    _checkPremiumStatus();
    _setupRealtimeListener();
  }

  @override
  void dispose() {
    _alertsChannel?.unsubscribe();
    _premiumSubscription?.cancel();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Data ─────────────────────────────────────
  Future<void> _checkPremiumStatus() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final r = await _supabase
          .from('subscribed')
          .select('subscribed')
          .eq('user_id', userId)
          .maybeSingle();
      if (mounted && r != null) {
        setState(() => _isPremium = r['subscribed'] == true);
      }
      _premiumSubscription = _supabase
          .from('subscribed')
          .stream(primaryKey: ['user_id'])
          .eq('user_id', userId)
          .listen((data) {
            if (mounted && data.isNotEmpty) {
              setState(() => _isPremium = data.first['subscribed'] == true);
            }
          });
    } catch (e) {
      debugPrint('premium check: $e');
    }
  }

  void _setupRealtimeListener() {
    setState(() {
      isLoading = true;
      hasError = false;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          hasError = true;
          isLoading = false;
        });
        return;
      }
      _alertsChannel?.unsubscribe();
      _loadAlerts();
      _alertsChannel = _supabase
          .channel('alerts_${user.uid}')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'alerts',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: user.uid,
            ),
            callback: (_) => _loadAlerts(),
          )
          .subscribe();
    } catch (e) {
      debugPrint('realtime setup: $e');
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  Future<void> _loadAlerts() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          hasError = true;
          isLoading = false;
        });
        return;
      }
      var q = _supabase
          .from('alerts')
          .select()
          .eq('user_id', user.uid)
          .eq('is_deleted', false);
      if (_showTriggeredOnly) q = q.eq('status', 'triggered');
      final response = await q.order('updated_at', ascending: false);
      if (!mounted) return;

      Map<String, List<AlertModel>> grouped = {};
      List<AlertModel> flat = [];
      for (var row in response) {
        try {
          final a = AlertModel.fromJson(row);
          flat.add(a);
          grouped.putIfAbsent(a.symbol, () => []).add(a);
        } catch (e) {
          debugPrint('parse: $e');
        }
      }

      setState(() {
        alerts = grouped;
        ungroupedAlerts = flat;
        isLoading = false;
        hasError = false;
      });
      _fadeCtrl.forward(from: 0);
    } catch (e) {
      debugPrint('load alerts: $e');
      if (!mounted) return;
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  // ── Build ─────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final d = Theme.of(context).brightness == Brightness.dark;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: d ? Brightness.light : Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: _T.bg(d),
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context, d),
      floatingActionButton: _buildFAB(d),
      body: isLoading
          ? _buildSkeleton(d)
          : hasError
              ? _buildError(d)
              : (_groupBySymbol ? alerts.isEmpty : ungroupedAlerts.isEmpty)
                  ? _buildEmpty(d)
                  : _buildContent(d),
    );
  }

  // ── AppBar ────────────────────────────────────
  // Fixed height AppBar that NEVER overflows:
  //   • SizedBox constrains the inner content
  //   • Title column uses Expanded + overflow:ellipsis
  //   • No back button (per request)
  PreferredSizeWidget _buildAppBar(BuildContext context, bool d) {
    const double appBarHeight = 62;

    return PreferredSize(
      preferredSize: const Size.fromHeight(appBarHeight),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: _T.bg(d).withOpacity(d ? 0.88 : 0.94),
              border:
                  Border(bottom: BorderSide(color: _T.divider(d), width: 0.5)),
            ),
            child: SafeArea(
              bottom: false,
              // SafeArea adds top padding for the status bar.
              // The SizedBox below gives the *remaining* bar room.
              child: SizedBox(
                height: appBarHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // ── Back button ──────────────────────
                      if (Navigator.of(context).canPop()) ...[
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            width: 34,
                            height: 34,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              color: _T.surface(d),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _T.cardBorder(d)),
                            ),
                            child: Icon(Icons.arrow_back_ios_new_rounded,
                                size: 14, color: _T.textSecondary(d)),
                          ),
                        ),
                      ],
                      // ── Title + subtitle ────────────────
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Alerts',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: _T.textPrimary(d),
                                    letterSpacing: -0.5,
                                    height: 1.1,
                                  ),
                                ),
                                if (_isPremium) ...[
                                  const SizedBox(width: 8),
                                  _ProBadge(),
                                ],
                              ],
                            ),
                            if (!isLoading && !hasError) ...[
                              const SizedBox(height: 1),
                              Text(
                                '$_total alert${_total == 1 ? '' : 's'}'
                                '${_fired > 0 ? ' · $_fired fired' : ''}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _T.textSecondary(d),
                                  height: 1.1,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      // ── Controls ───────────────────────
                      _PillToggle(
                        active: _showTriggeredOnly,
                        label: _showTriggeredOnly ? 'Fired' : 'All',
                        icon: Icons.bolt_rounded,
                        isDark: d,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(
                              () => _showTriggeredOnly = !_showTriggeredOnly);
                          _loadAlerts();
                        },
                      ),
                      const SizedBox(width: 8),
                      _PillToggle(
                        active: _groupBySymbol,
                        label: _groupBySymbol ? 'Grouped' : 'List',
                        icon: _groupBySymbol
                            ? Icons.layers_rounded
                            : Icons.view_list_rounded,
                        isDark: d,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _groupBySymbol = !_groupBySymbol);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── FAB ───────────────────────────────────────
  Widget _buildFAB(bool d) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => AllSearchPageMeili()));
      },
      child: Container(
        height: 56,
        width: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6B9FFF), _T.accent],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: _T.accent.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 8))
          ],
        ),
        child: const Icon(Icons.add_rounded, size: 26, color: Colors.white),
      ),
    );
  }

  // ── States ────────────────────────────────────
  Widget _buildSkeleton(bool d) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          children: List.generate(8, (i) => _SkeletonCard(delay: i, isDark: d)),
        ),
      ),
    );
  }

  Widget _buildError(bool d) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: _T.bearishBg(d),
                borderRadius: BorderRadius.circular(_T.r20)),
            child: Icon(Icons.wifi_off_rounded, size: 44, color: _T.bearish),
          ),
          const SizedBox(height: 20),
          Text('Failed to load alerts',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _T.textPrimary(d))),
          const SizedBox(height: 8),
          Text('Check your connection and try again',
              style: TextStyle(fontSize: 14, color: _T.textSecondary(d))),
          const SizedBox(height: 24),
          _GlowButton(
              label: 'Retry',
              icon: Icons.refresh_rounded,
              onTap: _setupRealtimeListener),
        ],
      ),
    );
  }

  Widget _buildEmpty(bool d) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: _T.accentBg(d),
                shape: BoxShape.circle,
                border: Border.all(color: _T.accent.withOpacity(0.2), width: 1),
              ),
              child: Icon(Icons.notifications_none_rounded,
                  size: 56, color: _T.accent),
            ),
            const SizedBox(height: 28),
            Text('No alerts yet',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: _T.textPrimary(d),
                    letterSpacing: -0.5)),
            const SizedBox(height: 10),
            Text(
              'Get notified the moment a stock\nhits your target or crosses a key level.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 15, color: _T.textSecondary(d), height: 1.6),
            ),
            const SizedBox(height: 32),
            _GlowButton(
              label: 'Create your first alert',
              icon: Icons.add_rounded,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => AllSearchPageMeili())),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool d) => FadeTransition(
        opacity: _fadeCtrl,
        child: _groupBySymbol ? _buildGroupedList(d) : _buildUngroupedList(d),
      );

  Widget _buildGroupedList(bool d) {
    final topPad = MediaQuery.of(context).padding.top + 62 + 12;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: SizedBox(height: topPad)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) {
                final sym = alerts.keys.elementAt(i);
                return _SymbolCard(
                  symbol: sym,
                  displayName: _symbolDisplay(sym),
                  alerts: alerts[sym]!,
                  isDark: d,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SetAlertPage(
                        stockName: sym,
                        segment: sym.contains("NIFTY") ? "index" : "stock",
                      ),
                    ),
                  ),
                );
              },
              childCount: alerts.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildUngroupedList(bool d) {
    final topPad = MediaQuery.of(context).padding.top + 62 + 12;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: SizedBox(height: topPad)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) {
                final a = ungroupedAlerts[i];
                return _UngroupedAlertCard(
                  alert: a,
                  displayName: _symbolDisplay(a.symbol),
                  isDark: d,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => SetAlertPage(stockName: a.symbol)),
                  ),
                );
              },
              childCount: ungroupedAlerts.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Symbol Card  (grouped view)
// ─────────────────────────────────────────────
class _SymbolCard extends StatefulWidget {
  const _SymbolCard({
    required this.symbol,
    required this.displayName,
    required this.alerts,
    required this.isDark,
    required this.onTap,
  });
  final String symbol;
  final String displayName;
  final List<AlertModel> alerts;
  final bool isDark;
  final VoidCallback onTap;

  @override
  State<_SymbolCard> createState() => _SymbolCardState();
}

class _SymbolCardState extends State<_SymbolCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final d = widget.isDark;
    final hasTriggered = widget.alerts.any((a) => a.status == 'triggered');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _T.card(d),
        borderRadius: BorderRadius.circular(_T.r20),
        border: Border.all(
          color: hasTriggered ? _T.bullish.withOpacity(0.35) : _T.cardBorder(d),
          width: hasTriggered ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(d ? 0.22 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4)),
          if (hasTriggered)
            BoxShadow(
                color: _T.bullish.withOpacity(0.08),
                blurRadius: 20,
                spreadRadius: 2),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(_T.r20),
        child: InkWell(
          borderRadius: BorderRadius.circular(_T.r20),
          onTap: widget.onTap,
          splashColor: _T.accent.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _SymbolAvatar(displayName: widget.displayName, isDark: d),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.displayName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _T.textPrimary(d),
                                letterSpacing: -0.3,
                              )),
                          const SizedBox(height: 2),
                          Text(
                            '${widget.alerts.length} alert${widget.alerts.length == 1 ? '' : 's'}',
                            style: TextStyle(
                                fontSize: 12, color: _T.textSecondary(d)),
                          ),
                        ],
                      ),
                    ),
                    _AlertStatusDots(alerts: widget.alerts, isDark: d),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _expanded = !_expanded);
                      },
                      child: AnimatedRotation(
                        duration: const Duration(milliseconds: 200),
                        turns: _expanded ? 0 : -0.25,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _T.divider(d),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.keyboard_arrow_down_rounded,
                              size: 16, color: _T.textSecondary(d)),
                        ),
                      ),
                    ),
                  ],
                ),
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 220),
                  crossFadeState: _expanded
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
                  firstChild: Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                          height: 1,
                          color: _T.divider(d),
                          margin: const EdgeInsets.only(bottom: 10)),
                      ...widget.alerts
                          .map((a) => _AlertRow(alert: a, isDark: d)),
                    ],
                  ),
                  secondChild: const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Ungrouped Alert Card
//  Layout:
//    [Avatar]  [Name]          [updated time]
//    ─────────────────────────────────────────
//    [Full-width _AlertRow]
// ─────────────────────────────────────────────
class _UngroupedAlertCard extends StatelessWidget {
  const _UngroupedAlertCard({
    required this.alert,
    required this.displayName,
    required this.isDark,
    required this.onTap,
  });
  final AlertModel alert;
  final String displayName;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final d = isDark;
    final isTriggered = alert.status.toLowerCase() == 'triggered';
    final statusColor = _T.statusFg(alert.status.toLowerCase(), d);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _T.card(d),
        borderRadius: BorderRadius.circular(_T.r20),
        border: Border.all(
          color: isTriggered ? _T.bullish.withOpacity(0.35) : _T.cardBorder(d),
          width: isTriggered ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(d ? 0.22 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4)),
          if (isTriggered)
            BoxShadow(
                color: _T.bullish.withOpacity(0.08),
                blurRadius: 20,
                spreadRadius: 2),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(_T.r20),
        child: InkWell(
          borderRadius: BorderRadius.circular(_T.r20),
          onTap: onTap,
          splashColor: _T.accent.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header row: avatar · name · time ──
                Row(
                  children: [
                    _SymbolAvatar(displayName: displayName, isDark: d),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _T.textPrimary(d),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            timeago.format(alert.updatedAt),
                            style: TextStyle(
                                fontSize: 11, color: _T.textSecondary(d)),
                          ),
                        ],
                      ),
                    ),
                    // Status dot
                    Icon(_T.statusIcon(alert.status.toLowerCase()),
                        size: 12, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      _T.statusLabel(alert.status.toLowerCase()),
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor),
                    ),
                  ],
                ),
                // ── Divider ───────────────────────────
                Container(
                    height: 1,
                    color: _T.divider(d),
                    margin: const EdgeInsets.symmetric(vertical: 12)),
                // ── Full-width alert row ───────────────
                _AlertRow(alert: alert, isDark: d, hideStatus: true),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Alert Row
//  Layout (stacked, no horizontal crowding):
//    [TypePill]          [status-icon · label]
//    ₹price              ← own line
//    condition chips     ← own line
//    ⚡ timestamp        ← only when triggered
// ─────────────────────────────────────────────
class _AlertRow extends StatelessWidget {
  const _AlertRow(
      {required this.alert, required this.isDark, this.hideStatus = false});
  final AlertModel alert;
  final bool isDark;
  final bool hideStatus;

  @override
  Widget build(BuildContext context) {
    final d = isDark;
    final type = alert.type;
    final status = alert.status.toLowerCase();
    final color = _alertColor(type, d);
    final bg = _alertBg(type, d);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _T.rowSurface(d),
          borderRadius: BorderRadius.circular(_T.r12),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Row 1: type pill  +  status (icon + text only, no bg pill) ──
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_alertIcon(type), size: 12, color: color),
                      const SizedBox(width: 4),
                      Text(
                        _alertTypeLabels[type] ?? type,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Status: just icon + label, hidden when card header already shows it
                if (!hideStatus) ...[
                  Icon(_T.statusIcon(status),
                      size: 11, color: _T.statusFg(status, d)),
                  const SizedBox(width: 3),
                  Text(
                    _T.statusLabel(status),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _T.statusFg(status, d),
                    ),
                  ),
                ],
              ],
            ),

            // ── Row 2: price on its own line ──────────────────────────────
            if (_priceInputTypes.contains(type)) ...[
              const SizedBox(height: 7),
              Text(
                '₹${alert.targetPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: -0.4,
                ),
              ),
            ],

            // ── Conditions ────────────────────────────────────────────────
            if (alert.complexConditions != null &&
                alert.complexConditions!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _ConditionChips(conditions: alert.complexConditions!, isDark: d),
            ],

            // ── Triggered timestamp ───────────────────────────────────────
            if (status == 'triggered') ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.bolt_rounded,
                      size: 11, color: _T.statusFg('triggered', d)),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      '${timeago.format(alert.updatedAt)} · ${_formatDateTime(alert.updatedAt.toLocal())}',
                      style: TextStyle(
                          fontSize: 11, color: _T.statusFg('triggered', d)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Condition Chips
// ─────────────────────────────────────────────
class _ConditionChips extends StatelessWidget {
  const _ConditionChips({required this.conditions, required this.isDark});
  final List<dynamic> conditions;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final d = isDark;
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: conditions.map<Widget>((c) {
        final left = c['left']?.toString().toUpperCase() ?? '';
        final op = c['operator']?.toString() ?? '';
        final right = c['right']?.toString().toUpperCase() ?? '';
        final logical = c['logical']?.toString() ?? '';
        if (left.isEmpty || op.isEmpty || right.isEmpty) {
          return const SizedBox.shrink();
        }
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: d ? const Color(0xFF0D2040) : const Color(0xFFEEF4FF),
                borderRadius: BorderRadius.circular(6),
                border:
                    Border.all(color: _T.accent.withOpacity(d ? 0.2 : 0.25)),
              ),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 11),
                  children: [
                    TextSpan(
                        text: left,
                        style: TextStyle(
                            color: d
                                ? const Color(0xFF7BB3FF)
                                : const Color(0xFF3B6ECC),
                            fontWeight: FontWeight.w700)),
                    TextSpan(
                        text: ' $op ',
                        style: TextStyle(
                            color: d ? _T.amber : const Color(0xFFB45309),
                            fontWeight: FontWeight.w600)),
                    TextSpan(
                        text: right,
                        style: TextStyle(
                            color: d ? _T.bullish : const Color(0xFF15803D),
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
            if (logical.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  logical.toUpperCase(),
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: _T.bearish,
                      letterSpacing: 0.5),
                ),
              ),
          ],
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────
//  Status Dots  (grouped card header summary)
// ─────────────────────────────────────────────
class _AlertStatusDots extends StatelessWidget {
  const _AlertStatusDots({required this.alerts, required this.isDark});
  final List<AlertModel> alerts;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final d = isDark;
    final triggered = alerts.where((a) => a.status == 'triggered').length;
    final pending = alerts.where((a) => a.status == 'pending').length;
    final others = alerts.length - triggered - pending;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (triggered > 0)
          _Dot(color: _T.statusFg('triggered', d), count: triggered, isDark: d),
        if (pending > 0)
          _Dot(color: _T.statusFg('pending', d), count: pending, isDark: d),
        if (others > 0) _Dot(color: _T.accent, count: others, isDark: d),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.count, required this.isDark});
  final Color color;
  final int count;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.15 : 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count',
        style:
            TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Symbol Avatar
// ─────────────────────────────────────────────
class _SymbolAvatar extends StatelessWidget {
  const _SymbolAvatar({required this.displayName, required this.isDark});
  final String displayName;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(_T.r12),
      child: CachedNetworkImage(
        height: 44,
        width: 44,
        imageUrl: "${Constants.OptionXiS3Loc}$displayName.png",
        fit: BoxFit.cover,
        placeholder: (_, __) =>
            _FallbackAvatar(name: displayName, isDark: isDark),
        errorWidget: (_, __, ___) =>
            _FallbackAvatar(name: displayName, isDark: isDark),
      ),
    );
  }
}

class _FallbackAvatar extends StatelessWidget {
  const _FallbackAvatar({required this.name, required this.isDark});
  final String name;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      width: 44,
      decoration: BoxDecoration(
        color: _T.accentBg(isDark),
        borderRadius: BorderRadius.circular(_T.r12),
      ),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.w800, color: _T.accent),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  PRO Badge
// ─────────────────────────────────────────────
class _ProBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFFFFB547), Color(0xFFFF8C00)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text('PRO',
          style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: Colors.black,
              letterSpacing: 0.5)),
    );
  }
}

// ─────────────────────────────────────────────
//  Pill Toggle
// ─────────────────────────────────────────────
class _PillToggle extends StatelessWidget {
  const _PillToggle({
    required this.active,
    required this.label,
    required this.icon,
    required this.isDark,
    required this.onTap,
  });
  final bool active;
  final String label;
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final d = isDark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? _T.accentBg(d) : _T.surface(d),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: active ? _T.accent.withOpacity(0.45) : _T.cardBorder(d)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 13, color: active ? _T.accent : _T.textSecondary(d)),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: active ? _T.accent : _T.textSecondary(d))),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Glow Button
// ─────────────────────────────────────────────
class _GlowButton extends StatelessWidget {
  const _GlowButton(
      {required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: _T.accent,
          borderRadius: BorderRadius.circular(_T.r16),
          boxShadow: [
            BoxShadow(
                color: _T.accent.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8))
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Skeleton Card
// ─────────────────────────────────────────────
class _SkeletonCard extends StatefulWidget {
  const _SkeletonCard({required this.delay, required this.isDark});
  final int delay;
  final bool isDark;

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
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
    final d = widget.isDark;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final shimmer = Color.lerp(_T.card(d), _T.surface(d), _anim.value)!;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: shimmer,
            borderRadius: BorderRadius.circular(_T.r20),
            border: Border.all(color: _T.cardBorder(d)),
          ),
          child: Row(
            children: [
              Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                      color: _T.divider(d),
                      borderRadius: BorderRadius.circular(_T.r12))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        height: 13,
                        width: 100,
                        decoration: BoxDecoration(
                            color: _T.divider(d),
                            borderRadius: BorderRadius.circular(4))),
                    const SizedBox(height: 8),
                    Container(
                        height: 10,
                        width: 60,
                        decoration: BoxDecoration(
                            color: _T.divider(d),
                            borderRadius: BorderRadius.circular(4))),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
//  Models
// ─────────────────────────────────────────────
class StatusConfig {
  final String label;
  final IconData icon;
  final MaterialColor color;
  StatusConfig({required this.label, required this.icon, required this.color});
}

class AlertModel {
  final String id;
  final String userId;
  final String symbol;
  final String type;
  final double targetPrice;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final String status;
  final List<dynamic>? complexConditions;

  AlertModel({
    required this.id,
    required this.userId,
    required this.symbol,
    required this.type,
    required this.targetPrice,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    required this.status,
    this.complexConditions,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    double parsePrice(dynamic v) {
      if (v == null) return 0.0;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    DateTime parseDT(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is String) return DateTime.parse(v);
      if (v is DateTime) return v;
      return DateTime.now();
    }

    return AlertModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      symbol: json['symbol']?.toString() ?? '',
      type: json['type']?.toString() ?? 'unknown',
      targetPrice: parsePrice(json['target_price']),
      createdAt: parseDT(json['created_at']),
      updatedAt: parseDT(json['updated_at']),
      isActive: json['is_active'] == true,
      status: json['status']?.toString() ?? 'pending',
      complexConditions: json['complex_conditions'] as List<dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'symbol': symbol,
        'type': type,
        'target_price': targetPrice,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'is_active': isActive,
        'status': status,
        'complex_conditions': complexConditions,
      };
}

String _formatDateTime(DateTime dt) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final check = DateTime(dt.year, dt.month, dt.day);
  final time =
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  if (check == today) return 'Today $time';
  if (check == today.subtract(const Duration(days: 1)))
    return 'Yesterday $time';
  return '${dt.day}/${dt.month}/${dt.year} $time';
}
