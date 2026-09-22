import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:optionxi/Helpers/constants.dart';
import 'package:optionxi/Main_Pages/Search/act_search_stocks_meili.dart';
import 'package:optionxi/Main_Pages/StockPages/act_set_alert.dart';
import 'package:optionxi/PushNotification/notifcation_service_firebase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

// ═════════════════════════════════════════════════════════════════════════════
//  DESIGN NOTES
//  • Flat "ledger" look: hairline borders, no gradients, no glow, no heavy
//    shadows. One teal accent for actions; green / red only mean up / down.
//  • Every alert is written as a plain sentence ("Goes above ₹2,900.00").
//  • Tap an alert to see "What this means" in everyday words.
//  • The "Guide" button explains every alert type, status and trading term.
// ═════════════════════════════════════════════════════════════════════════════

// ─────────────────────────────────────────────
//  Palette (dark / light aware)
// ─────────────────────────────────────────────
class _P {
  const _P(this.dark);
  final bool dark;

  static _P of(BuildContext c) => _P(Theme.of(c).brightness == Brightness.dark);

  Color get bg => dark ? const Color(0xFF0D1114) : const Color(0xFFF2F4F6);
  Color get surface => dark ? const Color(0xFF161B1F) : const Color(0xFFFFFFFF);
  Color get line => dark ? const Color(0xFF262D33) : const Color(0xFFE3E7EB);
  Color get ink => dark ? const Color(0xFFEAEEF1) : const Color(0xFF14191E);
  Color get muted => dark ? const Color(0xFF8B97A1) : const Color(0xFF5F6B76);

  Color get accent => dark ? const Color(0xFF4FC3CE) : const Color(0xFF0B7A85);
  Color get onAccent => dark ? const Color(0xFF0D1114) : Colors.white;

  Color get up => dark ? const Color(0xFF3DD68C) : const Color(0xFF128A5B);
  Color get down => dark ? const Color(0xFFFF6B6B) : const Color(0xFFD64545);
  Color get info => dark ? const Color(0xFF9A9BFF) : const Color(0xFF4F4FC9);
  Color get warn => dark ? const Color(0xFFF2B84B) : const Color(0xFFB7791F);
}

// ─────────────────────────────────────────────
//  Status  (what state an alert is in)
// ─────────────────────────────────────────────
enum _Status { waiting, checking, hit, paused, expired }

_Status _statusOf(String raw) {
  switch (raw.toLowerCase()) {
    case 'triggered':
      return _Status.hit;
    case 'processing':
      return _Status.checking;
    case 'paused':
      return _Status.paused;
    case 'expired':
      return _Status.expired;
    default:
      return _Status.waiting;
  }
}

extension _StatusX on _Status {
  String get label {
    switch (this) {
      case _Status.checking:
        return 'Checking now';
      case _Status.hit:
        return 'Target hit';
      case _Status.paused:
        return 'Paused';
      case _Status.expired:
        return 'Expired';
      default:
        return 'Waiting';
    }
  }

  IconData get icon {
    switch (this) {
      case _Status.checking:
        return Icons.sync_rounded;
      case _Status.hit:
        return Icons.check_circle_rounded;
      case _Status.paused:
        return Icons.pause_circle_rounded;
      case _Status.expired:
        return Icons.timer_off_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }

  String get meaning {
    switch (this) {
      case _Status.checking:
        return "We're checking this alert against the latest prices right now.";
      case _Status.hit:
        return 'Your condition came true and we sent you a notification.';
      case _Status.paused:
        return "This alert is switched off. You won't be notified until it is switched on again.";
      case _Status.expired:
        return "This alert ended before your condition came true, so it's no longer watching.";
      default:
        return "We're watching the market for you. Nothing has happened yet, so no notification was sent.";
    }
  }

  Color color(_P p) {
    switch (this) {
      case _Status.checking:
        return p.accent;
      case _Status.hit:
        return p.up;
      case _Status.paused:
        return p.warn;
      default:
        return p.muted;
    }
  }
}

// ─────────────────────────────────────────────
//  Filters
// ─────────────────────────────────────────────
enum _Filter { all, waiting, hit, stopped }

String _filterLabel(_Filter f) {
  switch (f) {
    case _Filter.waiting:
      return 'Waiting';
    case _Filter.hit:
      return 'Target hit';
    case _Filter.stopped:
      return 'Stopped';
    default:
      return 'All';
  }
}

bool _matchesFilter(AlertModel a, _Filter f) {
  final s = _statusOf(a.status);
  switch (f) {
    case _Filter.waiting:
      return s == _Status.waiting || s == _Status.checking;
    case _Filter.hit:
      return s == _Status.hit;
    case _Filter.stopped:
      return s == _Status.paused || s == _Status.expired;
    default:
      return true;
  }
}

// ─────────────────────────────────────────────
//  Alert types in plain language
// ─────────────────────────────────────────────
enum _Dir { up, down, custom }

_Dir _dirOf(String type) {
  if (type == 'premium') return _Dir.custom;
  if (type.contains('above') || type.contains('high')) return _Dir.up;
  if (type.contains('below') || type.contains('low')) return _Dir.down;
  return _Dir.custom;
}

Color _dirColor(_Dir d, _P p) {
  switch (d) {
    case _Dir.up:
      return p.up;
    case _Dir.down:
      return p.down;
    default:
      return p.info;
  }
}

IconData _typeIcon(String type) {
  switch (type) {
    case 'price_above':
      return Icons.north_east_rounded;
    case 'price_below':
      return Icons.south_east_rounded;
    case 'breaking_high':
    case 'breaking_week_high':
    case 'breaking_52w_high':
      return Icons.trending_up_rounded;
    case 'breaking_low':
    case 'breaking_week_low':
    case 'breaking_52w_low':
      return Icons.trending_down_rounded;
    default:
      return Icons.tune_rounded;
  }
}

const List<String> _typeOrder = [
  'price_above',
  'price_below',
  'breaking_high',
  'breaking_low',
  'breaking_week_high',
  'breaking_week_low',
  'breaking_52w_high',
  'breaking_52w_low',
  'premium',
];

const Map<String, String> _typeName = {
  'price_above': 'Price above',
  'price_below': 'Price below',
  'breaking_high': "Today's high",
  'breaking_low': "Today's low",
  'breaking_week_high': 'One-week high',
  'breaking_week_low': 'One-week low',
  'breaking_52w_high': '52-week high',
  'breaking_52w_low': '52-week low',
  'premium': 'Custom conditions',
};

const Map<String, String> _typeGuide = {
  'price_above':
      'Notifies you when a stock rises to the price you pick, or higher. Good for catching a breakout or deciding when to book profit.',
  'price_below':
      'Notifies you when a stock drops to the price you pick, or lower. Good for spotting a buying chance or guarding against a bigger fall.',
  'breaking_high':
      "Notifies you when the stock trades higher than any price seen so far today. It often means buyers are in control.",
  'breaking_low':
      "Notifies you when the stock trades lower than any price seen so far today. It often means sellers are in control.",
  'breaking_week_high':
      "Notifies you when the stock goes higher than its highest price of the past week.",
  'breaking_week_low':
      "Notifies you when the stock goes lower than its lowest price of the past week.",
  'breaking_52w_high':
      "Notifies you when the stock reaches its highest price in the past 52 weeks (about a year).",
  'breaking_52w_low':
      "Notifies you when the stock falls to its lowest price in the past 52 weeks (about a year).",
  'premium':
      'A custom alert built from your own conditions. We notify you when the conditions you set come true.',
};

String _headline(AlertModel a) {
  switch (a.type) {
    case 'price_above':
      return 'Goes above ${_rupee(a.targetPrice)}';
    case 'price_below':
      return 'Falls below ${_rupee(a.targetPrice)}';
    case 'breaking_high':
      return "Crosses today's high";
    case 'breaking_low':
      return "Drops below today's low";
    case 'breaking_week_high':
      return "Crosses this week's high";
    case 'breaking_week_low':
      return "Drops below this week's low";
    case 'breaking_52w_high':
      return 'Reaches a new 52-week high';
    case 'breaking_52w_low':
      return 'Falls to a new 52-week low';
    case 'premium':
      return 'Your custom conditions come true';
    default:
      return _typeName[a.type] ?? a.type.replaceAll('_', ' ');
  }
}

String _meaningFor(AlertModel a) {
  final price = _rupee(a.targetPrice);
  switch (a.type) {
    case 'price_above':
      return "We'll notify you when the price rises to $price or higher. Useful for catching a breakout or deciding when to book profit.";
    case 'price_below':
      return "We'll notify you when the price drops to $price or lower. Useful for spotting a buying chance or guarding against a bigger fall.";
    default:
      return _typeGuide[a.type] ??
          "A custom alert. We'll notify you when your conditions come true.";
  }
}

// ─────────────────────────────────────────────
//  Small helpers
// ─────────────────────────────────────────────
String _symbolDisplay(String s) =>
    s.replaceAll('-EQ', '').replaceAll('NSE:', '').replaceAll('-BZ', '');

/// ₹1,23,456.00 (Indian digit grouping)
String _rupee(double v) {
  final parts = v.toStringAsFixed(2).split('.');
  var whole = parts[0];
  if (whole.length > 3) {
    final last3 = whole.substring(whole.length - 3);
    var rest = whole.substring(0, whole.length - 3);
    final chunks = <String>[];
    while (rest.length > 2) {
      chunks.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) chunks.insert(0, rest);
    whole = '${chunks.join(',')},$last3';
  }
  return '₹$whole.${parts[1]}';
}

class _Cond {
  const _Cond(this.text, this.logical);
  final String text;
  final String logical;
}

String _term(String raw) {
  final t = raw.trim();
  if (t.toLowerCase() == 'ltp') return 'Last price';
  return t.replaceAll('_', ' ').toUpperCase();
}

String _opWords(String op) {
  switch (op.toLowerCase().trim()) {
    case '>':
    case 'gt':
      return 'is above';
    case '<':
    case 'lt':
      return 'is below';
    case '>=':
    case 'gte':
      return 'is at or above';
    case '<=':
    case 'lte':
      return 'is at or below';
    case '==':
    case '=':
    case 'eq':
      return 'equals';
    case 'crosses_above':
    case 'cross_above':
    case 'crosses above':
      return 'crosses above';
    case 'crosses_below':
    case 'cross_below':
    case 'crosses below':
      return 'crosses below';
    default:
      return op.replaceAll('_', ' ');
  }
}

List<_Cond> _conditionLines(List<dynamic>? raw) {
  if (raw == null) return const [];
  final out = <_Cond>[];
  for (final c in raw) {
    if (c is! Map) continue;
    final left = c['left']?.toString() ?? '';
    final op = c['operator']?.toString() ?? '';
    final right = c['right']?.toString() ?? '';
    if (left.isEmpty || op.isEmpty || right.isEmpty) continue;
    out.add(_Cond('${_term(left)} ${_opWords(op)} ${_term(right)}',
        (c['logical']?.toString() ?? '').toLowerCase()));
  }
  return out;
}

// ─────────────────────────────────────────────
//  Page
// ─────────────────────────────────────────────
class MyAlertsPage extends StatefulWidget {
  const MyAlertsPage({Key? key}) : super(key: key);

  @override
  State<MyAlertsPage> createState() => _MyAlertsPageState();
}

class _MyAlertsPageState extends State<MyAlertsPage> {
  bool isLoading = true;
  bool hasError = false;
  List<AlertModel> _all = [];
  final _supabase = Supabase.instance.client;
  bool _isPremium = false;
  bool _groupBySymbol = true;
  _Filter _filter = _Filter.all;

  RealtimeChannel? _alertsChannel;
  StreamSubscription? _premiumSubscription;

  @override
  void initState() {
    super.initState();
    NotificationServiceFirebase().forceRefreshAndSyncToken();
    _checkPremiumStatus();
    _setupRealtimeListener();
  }

  @override
  void dispose() {
    _alertsChannel?.unsubscribe();
    _premiumSubscription?.cancel();
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

  void _retry() {
    setState(() {
      isLoading = true;
      hasError = false;
    });
    _setupRealtimeListener();
  }

  Future<void> _loadAlerts() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (!mounted) return;
        setState(() {
          hasError = true;
          isLoading = false;
        });
        return;
      }
      final response = await _supabase
          .from('alerts')
          .select()
          .eq('user_id', user.uid)
          .eq('is_deleted', false)
          .order('updated_at', ascending: false);
      if (!mounted) return;

      final flat = <AlertModel>[];
      for (var row in response) {
        try {
          flat.add(AlertModel.fromJson(row));
        } catch (e) {
          debugPrint('parse: $e');
        }
      }

      setState(() {
        _all = flat;
        isLoading = false;
        hasError = false;
      });
    } catch (e) {
      debugPrint('load alerts: $e');
      if (!mounted) return;
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  void _openStock(String symbol) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SetAlertPage(
          stockName: symbol,
          segment: symbol.contains('NIFTY') ? 'index' : 'stock',
        ),
      ),
    );
  }

  void _addAlert() {
    HapticFeedback.mediumImpact();
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => AllSearchPageMeili()));
  }

  void _showGuide(_P p) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: p.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _GuideSheet(p: p),
    );
  }

  // ── Build ─────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final p = _P.of(context);
    final showFab = !isLoading && !hasError && _all.isNotEmpty;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: p.dark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: p.bg,
        floatingActionButton: showFab
            ? FloatingActionButton.extended(
                onPressed: _addAlert,
                backgroundColor: p.accent,
                foregroundColor: p.onAccent,
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                icon: const Icon(Icons.add_rounded),
                label: const Text('New alert',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              )
            : null,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(p),
              Expanded(child: _buildBody(p)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────
  Widget _buildHeader(_P p) {
    final stocks = _all.map((a) => a.symbol).toSet().length;
    final hit = _all.where((a) => _statusOf(a.status) == _Status.hit).length;

    String sub;
    if (isLoading) {
      sub = 'Loading your alerts…';
    } else if (hasError) {
      sub = "We couldn't load your alerts.";
    } else if (_all.isEmpty) {
      sub = "You aren't watching any stocks yet.";
    } else {
      sub =
          'Watching $stocks stock${stocks == 1 ? '' : 's'} with ${_all.length} alert${_all.length == 1 ? '' : 's'}.';
      if (hit > 0) {
        sub += ' $hit ${hit == 1 ? 'has' : 'have'} reached your target.';
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (Navigator.of(context).canPop())
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.of(context).pop();
              },
              child: Container(
                width: 36,
                height: 36,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: p.line),
                ),
                child: Icon(Icons.arrow_back_ios_new_rounded,
                    size: 14, color: p.muted),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Alerts',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: p.ink,
                            letterSpacing: -0.8,
                            height: 1.1)),
                    if (_isPremium) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2B84B),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('PRO',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF14191E))),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(sub,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style:
                        TextStyle(fontSize: 13, color: p.muted, height: 1.35)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _showGuide(p),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: p.line),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.help_outline_rounded, size: 16, color: p.accent),
                  const SizedBox(width: 6),
                  Text('Guide',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: p.ink)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Body states ───────────────────────────────
  Widget _buildBody(_P p) {
    if (isLoading) return _SkeletonList(p: p);
    if (hasError) return _buildError(p);
    if (_all.isEmpty) return _buildEmpty(p);
    return _buildLoaded(p);
  }

  Widget _buildLoaded(_P p) {
    final visible = _all.where((a) => _matchesFilter(a, _filter)).toList();

    return Column(
      children: [
        // Filter chips
        const SizedBox(height: 4),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              for (final f in _Filter.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _FilterChipX(
                    label: _filterLabel(f),
                    count: _all.where((a) => _matchesFilter(a, f)).length,
                    selected: _filter == f,
                    p: p,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _filter = f);
                    },
                  ),
                ),
            ],
          ),
        ),
        // Count + view switch
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Showing ${visible.length} of ${_all.length}',
                  style: TextStyle(fontSize: 12, color: p.muted),
                ),
              ),
              _ViewSwitch(
                grouped: _groupBySymbol,
                p: p,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  setState(() => _groupBySymbol = v);
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: visible.isEmpty
              ? _buildNoMatches(p)
              : RefreshIndicator(
                  color: p.accent,
                  backgroundColor: p.surface,
                  onRefresh: _loadAlerts,
                  child: _groupBySymbol
                      ? _buildGrouped(p, visible)
                      : _buildFlat(p, visible),
                ),
        ),
      ],
    );
  }

  Widget _buildGrouped(_P p, List<AlertModel> visible) {
    final groups = <String, List<AlertModel>>{};
    for (final a in visible) {
      groups.putIfAbsent(a.symbol, () => []).add(a);
    }
    final keys = groups.keys.toList();

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
      itemCount: keys.length,
      itemBuilder: (_, i) {
        final sym = keys[i];
        return _StockSection(
          symbol: sym,
          alerts: groups[sym]!,
          p: p,
          onManage: () => _openStock(sym),
        );
      },
    );
  }

  Widget _buildFlat(_P p, List<AlertModel> visible) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
      children: [
        _Block(
          p: p,
          children: [
            for (final a in visible)
              _AlertTile(
                key: ValueKey(a.id),
                alert: a,
                p: p,
                showSymbol: true,
                onEdit: () => _openStock(a.symbol),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildNoMatches(_P p) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('No alerts in this view',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: p.ink)),
            const SizedBox(height: 6),
            Text('Try another filter to see the rest of your alerts.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: p.muted, height: 1.4)),
            const SizedBox(height: 16),
            _TextLink(
                label: 'Show all alerts',
                p: p,
                onTap: () => setState(() => _filter = _Filter.all)),
          ],
        ),
      ),
    );
  }

  Widget _buildError(_P p) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 36, color: p.down),
            const SizedBox(height: 16),
            Text("Couldn't load your alerts",
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800, color: p.ink)),
            const SizedBox(height: 8),
            Text(
                'This is usually a connection problem. Check your internet and try again. Your alerts are safe.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: p.muted, height: 1.45)),
            const SizedBox(height: 20),
            _PrimaryButton(
                label: 'Try again',
                icon: Icons.refresh_rounded,
                p: p,
                onTap: _retry),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(_P p) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none_rounded, size: 40, color: p.muted),
            const SizedBox(height: 16),
            Text("You aren't watching anything yet",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: p.ink,
                    letterSpacing: -0.4)),
            const SizedBox(height: 10),
            Text(
                "Pick a stock and tell us the price or level you care about. We'll send a notification the moment it happens, so you don't have to keep checking.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: p.muted, height: 1.5)),
            const SizedBox(height: 24),
            _PrimaryButton(
                label: 'Add your first alert',
                icon: Icons.add_rounded,
                p: p,
                onTap: _addAlert),
            const SizedBox(height: 8),
            _TextLink(
                label: 'How alerts work', p: p, onTap: () => _showGuide(p)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Filter chip + view switch
// ─────────────────────────────────────────────
class _FilterChipX extends StatelessWidget {
  const _FilterChipX({
    required this.label,
    required this.count,
    required this.selected,
    required this.p,
    required this.onTap,
  });
  final String label;
  final int count;
  final bool selected;
  final _P p;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? p.ink : p.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? p.ink : p.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? p.bg : p.ink)),
            const SizedBox(width: 6),
            Text('$count',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? p.bg.withOpacity(0.7) : p.muted)),
          ],
        ),
      ),
    );
  }
}

class _ViewSwitch extends StatelessWidget {
  const _ViewSwitch(
      {required this.grouped, required this.p, required this.onChanged});
  final bool grouped;
  final _P p;
  final ValueChanged<bool> onChanged;

  Widget _seg(String text, bool on, VoidCallback tap) {
    return GestureDetector(
      onTap: tap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: on ? p.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: on ? p.ink : p.muted)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: p.line,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _seg('By stock', grouped, () => onChanged(true)),
          _seg('Newest first', !grouped, () => onChanged(false)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Stock section  (grouped view)
// ─────────────────────────────────────────────
class _StockSection extends StatelessWidget {
  const _StockSection({
    required this.symbol,
    required this.alerts,
    required this.p,
    required this.onManage,
  });
  final String symbol;
  final List<AlertModel> alerts;
  final _P p;
  final VoidCallback onManage;

  String _summary() {
    final waiting = alerts.where((a) {
      final s = _statusOf(a.status);
      return s == _Status.waiting || s == _Status.checking;
    }).length;
    final hit = alerts.where((a) => _statusOf(a.status) == _Status.hit).length;
    final stopped = alerts.length - waiting - hit;
    final parts = <String>[];
    if (waiting > 0) parts.add('$waiting waiting');
    if (hit > 0) parts.add('$hit target hit');
    if (stopped > 0) parts.add('$stopped stopped');
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final name = _symbolDisplay(symbol);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onManage,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  _Avatar(name: name, size: 40, p: p),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: p.ink,
                                letterSpacing: -0.3)),
                        const SizedBox(height: 2),
                        Text(_summary(),
                            style: TextStyle(fontSize: 12, color: p.muted)),
                      ],
                    ),
                  ),
                  Text('Manage',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: p.accent)),
                  Icon(Icons.chevron_right_rounded, size: 18, color: p.accent),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          _Block(
            p: p,
            children: [
              for (final a in alerts)
                _AlertTile(
                  key: ValueKey(a.id),
                  alert: a,
                  p: p,
                  onEdit: onManage,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A flat bordered surface that stacks tiles with hairline dividers.
class _Block extends StatelessWidget {
  const _Block({required this.p, required this.children});
  final _P p;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) items.add(Divider(height: 1, thickness: 1, color: p.line));
      items.add(children[i]);
    }
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.line),
      ),
      child: Column(children: items),
    );
  }
}

// ─────────────────────────────────────────────
//  Alert tile
//    ▍ Goes above ₹2,900.00                    ⌄
//    ▍ ● Waiting, set 2 days ago
//    ▍ (tap) → what this means, status, edit
// ─────────────────────────────────────────────
class _AlertTile extends StatefulWidget {
  const _AlertTile({
    Key? key,
    required this.alert,
    required this.p,
    required this.onEdit,
    this.showSymbol = false,
  }) : super(key: key);
  final AlertModel alert;
  final _P p;
  final VoidCallback onEdit;
  final bool showSymbol;

  @override
  State<_AlertTile> createState() => _AlertTileState();
}

class _AlertTileState extends State<_AlertTile> {
  bool _open = false;

  Widget _mini(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Text(t,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: widget.p.ink)),
      );

  @override
  Widget build(BuildContext context) {
    final a = widget.alert;
    final p = widget.p;
    final status = _statusOf(a.status);
    final statusColor = status.color(p);
    final barColor = _dirColor(_dirOf(a.type), p);
    final conds = _conditionLines(a.complexConditions);
    final hasLogical = conds.any((c) => c.logical.isNotEmpty);

    final when = status == _Status.hit
        ? '${timeago.format(a.updatedAt)}, ${_formatDateTime(a.updatedAt.toLocal())}'
        : 'set ${timeago.format(a.createdAt)}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _open = !_open);
        },
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(17, 14, 12, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.showSymbol) ...[
                    Row(
                      children: [
                        _Avatar(name: _symbolDisplay(a.symbol), size: 26, p: p),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_symbolDisplay(a.symbol),
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: p.ink)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(_headline(a),
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: p.ink,
                                height: 1.25,
                                letterSpacing: -0.2)),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                          _open
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          size: 20,
                          color: p.muted),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 5,
                    runSpacing: 2,
                    children: [
                      Icon(status.icon, size: 14, color: statusColor),
                      Text(status.label,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: statusColor)),
                      Text(when,
                          style: TextStyle(fontSize: 12, color: p.muted)),
                    ],
                  ),
                  if (conds.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _ConditionList(conds: conds, p: p),
                  ],
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    alignment: Alignment.topCenter,
                    child: _open
                        ? Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(top: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: p.bg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _mini('What this means'),
                                Text(_meaningFor(a),
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: p.muted,
                                        height: 1.45)),
                                const SizedBox(height: 10),
                                _mini('Status: ${status.label}'),
                                Text(status.meaning,
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: p.muted,
                                        height: 1.45)),
                                if (hasLogical) ...[
                                  const SizedBox(height: 10),
                                  _mini('"and" vs "or"'),
                                  Text(
                                      '"and" means every condition must be true. "or" means any one of them is enough.',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: p.muted,
                                          height: 1.45)),
                                ],
                                const SizedBox(height: 12),
                                _OutlineButton(
                                  label: 'Edit this alert',
                                  icon: Icons.edit_outlined,
                                  p: p,
                                  onTap: widget.onEdit,
                                ),
                              ],
                            ),
                          )
                        : const SizedBox(width: double.infinity),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 3, color: barColor),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Custom conditions written as sentences
// ─────────────────────────────────────────────
class _ConditionList extends StatelessWidget {
  const _ConditionList({required this.conds, required this.p});
  final List<_Cond> conds;
  final _P p;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Notify me only when',
            style: TextStyle(fontSize: 12, color: p.muted)),
        const SizedBox(height: 4),
        for (var i = 0; i < conds.length; i++) ...[
          Text(conds[i].text,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: p.ink)),
          if (i < conds.length - 1 && conds[i].logical.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(conds[i].logical,
                  style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: p.muted)),
            )
          else if (i < conds.length - 1)
            const SizedBox(height: 4),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Guide bottom sheet (plain-language help)
// ─────────────────────────────────────────────
class _GuideSheet extends StatelessWidget {
  const _GuideSheet({required this.p});
  final _P p;

  Widget _title(String t) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 8),
        child: Text(t,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: p.ink,
                letterSpacing: -0.2)),
      );

  Widget _row(IconData icon, Color color, String name, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: p.ink)),
                const SizedBox(height: 2),
                Text(text,
                    style:
                        TextStyle(fontSize: 13, color: p.muted, height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _term2(String term, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(term,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: p.ink)),
          const SizedBox(height: 2),
          Text(text,
              style: TextStyle(fontSize: 13, color: p.muted, height: 1.45)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      child: SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: p.line, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text('How alerts work',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: p.ink,
                    letterSpacing: -0.6)),
            const SizedBox(height: 8),
            Text(
                "An alert watches a stock for you. When the condition you chose happens, we send a notification, so you don't have to keep checking the screen.",
                style: TextStyle(fontSize: 14, color: p.muted, height: 1.5)),
            _title('Kinds of alerts'),
            for (final t in _typeOrder)
              _row(_typeIcon(t), _dirColor(_dirOf(t), p), _typeName[t]!,
                  _typeGuide[t]!),
            _title('What the status means'),
            for (final s in _Status.values)
              _row(s.icon, s.color(p), s.label, s.meaning),
            _title('Words you may see'),
            _term2('Target price',
                'The price you pick. When the stock reaches it, we notify you.'),
            _term2('Breakout',
                'When a price pushes past a level it has struggled to cross before. Traders often see it as the start of a bigger move.'),
            _term2("Today's high / low",
                'The highest and lowest prices the stock has traded at so far today.'),
            _term2('52-week high / low',
                'The highest and lowest prices the stock has traded at in the past year.'),
            const SizedBox(height: 12),
            Text('Alerts are notifications, not advice to buy or sell.',
                style: TextStyle(fontSize: 12, color: p.muted)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Avatar
// ─────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.size, required this.p});
  final String name;
  final double size;
  final _P p;

  Widget _fallback() => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: p.accent.withOpacity(0.12),
          borderRadius: BorderRadius.circular(size * 0.28),
        ),
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
              fontSize: size * 0.42,
              fontWeight: FontWeight.w800,
              color: p.accent),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.28),
        child: CachedNetworkImage(
          imageUrl: "${Constants.OptionXiS3Loc}$name.png",
          fit: BoxFit.cover,
          placeholder: (_, __) => _fallback(),
          errorWidget: (_, __, ___) => _fallback(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Buttons
// ─────────────────────────────────────────────
class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton(
      {required this.label,
      required this.icon,
      required this.p,
      required this.onTap});
  final String label;
  final IconData icon;
  final _P p;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: p.accent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: p.onAccent),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: p.onAccent)),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton(
      {required this.label,
      required this.icon,
      required this.p,
      required this.onTap});
  final String label;
  final IconData icon;
  final _P p;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: p.accent.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: p.accent),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: p.accent)),
          ],
        ),
      ),
    );
  }
}

class _TextLink extends StatelessWidget {
  const _TextLink({required this.label, required this.p, required this.onTap});
  final String label;
  final _P p;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      child: Text(label,
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, color: p.accent)),
    );
  }
}

// ─────────────────────────────────────────────
//  Loading skeleton (one shared pulse)
// ─────────────────────────────────────────────
class _SkeletonList extends StatefulWidget {
  const _SkeletonList({required this.p});
  final _P p;

  @override
  State<_SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<_SkeletonList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _bone(double w, double h, Color c, {double r = 6}) => Container(
        width: w,
        height: h,
        decoration:
            BoxDecoration(color: c, borderRadius: BorderRadius.circular(r)),
      );

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final bone = Color.lerp(p.line, p.surface, _c.value * 0.8)!;
        return ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          children: List.generate(3, (_) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _bone(40, 40, bone, r: 11),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _bone(110, 14, bone),
                          const SizedBox(height: 6),
                          _bone(70, 10, bone),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: p.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: p.line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _bone(180, 14, bone),
                        const SizedBox(height: 8),
                        _bone(120, 10, bone),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
//  Models  (unchanged, other files may import these)
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
  if (check == today.subtract(const Duration(days: 1))) {
    return 'Yesterday $time';
  }
  return '${dt.day}/${dt.month}/${dt.year} $time';
}
