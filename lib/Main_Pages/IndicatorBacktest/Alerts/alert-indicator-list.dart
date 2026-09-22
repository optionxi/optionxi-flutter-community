// ─────────────────────────────────────────────────────────────────────────
// Alerts list.
//
// IMPORTANT -- this used to be a separate CRUD system: its own
// AlertsApiService, its own condition/schedule builder
// (alert-indicator-edit.dart), a separate FastAPI service on
// ALERTS_API_BASE_URL. That never matched what's actually persisted --
// schema.sql only ever added three columns to `nifty_saved_backtests`
// (is_alert_enabled / last_checked_at / last_alerted_at). There is no
// separate `alerts` table, so there was nothing for that CRUD API to
// really own.
//
// An "alert" IS a saved algo with notifications turned on. This page is
// just a filtered view of BacktestApiService.listAlertAlgos() -- the
// exact same service SavedBacktestsPage already uses. Turning an alert on
// happens on the backtest detail page (SavedBacktestDetailPage), right
// next to the algo it belongs to, not in a separate creation flow here.
//
// alert-api-service.dart and alert-indicator-edit.dart are no longer
// needed -- delete them from the project.
// ─────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:optionxi/Components/cust_contact_us.dart';
import 'package:optionxi/Main_Pages/IndicatorBacktest/backtest-detailpage.dart';
import 'package:optionxi/Main_Pages/IndicatorBacktest/indicator-backtest.dart';
import 'package:optionxi/Main_Pages/SubscriptionsRazorpay/act_subscription_razorpay.dart';

class _AT {
  static const accent = Color(0xFF5B7FFF);
  static const violet = Color(0xFF9B6DFF);
  static const green = Color(0xFF00C896);
  static const red = Color(0xFFFF4D6D);
  static const amber = Color(0xFFFFAB00);

  static Color bg(bool d) =>
      d ? const Color(0xFF0B0D15) : const Color(0xFFF0F2F8);
  static Color surface(bool d) => d ? const Color(0xFF161927) : Colors.white;
  static Color border(bool d) =>
      d ? const Color(0xFF252840) : const Color(0xFFE4E7F2);
  static Color text(bool d) =>
      d ? const Color(0xFFEEF0FF) : const Color(0xFF0F1124);
  static Color sub(bool d) =>
      d ? const Color(0xFF7880A0) : const Color(0xFF8890B0);
  static Color shimmerBase(bool d) =>
      d ? const Color(0xFF1C2033) : const Color(0xFFE9EBF5);
  static Color shimmerHighlight(bool d) =>
      d ? const Color(0xFF272C46) : const Color(0xFFF6F7FC);
  static const gradient = LinearGradient(colors: [accent, violet]);

  static List<BoxShadow> cardShadow(bool d) => [
        BoxShadow(
          color: d
              ? Colors.black.withOpacity(0.28)
              : const Color(0xFF1B2559).withOpacity(0.06),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ];
}

void _launchContactUs(context) {
  showContactOptions(context, "Backtest Alert Notification");
}

class AlertsListPage extends StatefulWidget {
  /// Reuse the caller's BacktestApiService when we have one (e.g. coming
  /// from a detail page). Falls back to building one from
  /// BACKTEST_API_BASE_URL in .env, same as SavedBacktestsPage -- there is
  /// deliberately no separate ALERTS_API_BASE_URL anymore.
  final BacktestApiService? api;
  const AlertsListPage({super.key, this.api});

  @override
  State<AlertsListPage> createState() => _AlertsListPageState();
}

class _AlertsListPageState extends State<AlertsListPage> {
  late final BacktestApiService _api = widget.api ??
      BacktestApiService(baseUrl: dotenv.env['BACKTEST_API_BASE_URL']!);

  bool _loading = true;
  String? _error;
  String _plan = 'free';
  AlertLimitModel? _limit;
  List<SavedBacktestModel> _algos = [];
  final Set<String> _togglingIds = {};

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  bool get _isSubscribed => _plan == 'pro' || _plan == 'max';

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
      final plan = await _api.getUserPlan();
      List<SavedBacktestModel> algos = [];
      AlertLimitModel? limit;
      if (plan == 'pro' || plan == 'max') {
        final results =
            await Future.wait([_api.listAlertAlgos(), _api.getAlertLimit()]);
        algos = results[0] as List<SavedBacktestModel>;
        limit = results[1] as AlertLimitModel;
      }
      if (!mounted) return;
      setState(() {
        _plan = plan;
        _algos = algos;
        _limit = limit;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _disable(SavedBacktestModel a) async {
    setState(() => _togglingIds.add(a.id));
    try {
      await _api.disableAlert(a.id);
      if (!mounted) return;
      setState(() => _algos.removeWhere((x) => x.id == a.id));
      final limit = await _api.getAlertLimit();
      if (mounted) setState(() => _limit = limit);
    } catch (e) {
      if (mounted) _snack(e.toString());
    } finally {
      if (mounted) setState(() => _togglingIds.remove(a.id));
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _openAlgo(SavedBacktestModel a) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SavedBacktestDetailPage(api: _api, algo: a),
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final dark = _isDark;
    return Scaffold(
      backgroundColor: _AT.bg(dark),
      appBar: AppBar(
        backgroundColor: _AT.surface(dark),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text('Alerts',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _AT.text(dark))),
        actions: [
          if (_limit != null && _isSubscribed)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      color: _AT.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text('${_limit!.used}/${_limit!.limit} used',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _AT.accent)),
                ),
              ),
            ),
          IconButton(
            tooltip: 'Contact us',
            onPressed: () {
              _launchContactUs(context);
            },
            icon: Icon(Icons.support_agent_rounded, color: _AT.sub(dark)),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Divider(height: 1, color: _AT.border(dark))),
      ),
      body: _loading
          ? const _AlertsSkeletonList()
          : _error != null
              ? _ErrorState(dark: dark, error: _error!, onRetry: _load)
              : !_isSubscribed
                  ? _UpsellState(
                      dark: dark,
                      onUpgrade: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  SubscriptionScreenRazorPay()),
                        );
                      },
                    )
                  : _algos.isEmpty
                      ? _EmptyAlertsState(dark: dark)
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                            itemCount: _algos.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, i) {
                              final a = _algos[i];
                              return _AlertCard(
                                algo: a,
                                dark: dark,
                                toggling: _togglingIds.contains(a.id),
                                onTap: () => _openAlgo(a),
                                onDisable: () => _disable(a),
                              );
                            },
                          ),
                        ),
    );
  }
}

// ─────────────────────────────────────────────
// Shimmer / skeleton loading
// ─────────────────────────────────────────────

class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;
  const _ShimmerBox({
    required this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base = _AT.shimmerBase(dark);
    final highlight = _AT.shimmerHighlight(dark);
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (rect) {
            final slide = _c.value * 2 - 1; // -1 .. 1
            return LinearGradient(
              colors: [base, highlight, base],
              stops: const [0.35, 0.5, 0.65],
              begin: Alignment(-1 + slide * 2, 0),
              end: Alignment(1 + slide * 2, 0),
            ).createShader(rect);
          },
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: base,
              borderRadius: BorderRadius.circular(widget.radius),
            ),
          ),
        );
      },
    );
  }
}

class _SkeletonAlertCard extends StatelessWidget {
  final bool dark;
  const _SkeletonAlertCard({required this.dark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _AT.surface(dark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _AT.border(dark)),
        boxShadow: _AT.cardShadow(dark),
      ),
      child: Row(children: [
        const _ShimmerBox(width: 40, height: 40, radius: 11),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const _ShimmerBox(width: 140, height: 13, radius: 4),
            const SizedBox(height: 8),
            const _ShimmerBox(width: 90, height: 10, radius: 4),
            const SizedBox(height: 8),
            const _ShimmerBox(width: 170, height: 10, radius: 4),
          ]),
        ),
        const SizedBox(width: 12),
        const _ShimmerBox(width: 40, height: 22, radius: 12),
      ]),
    );
  }
}

class _AlertsSkeletonList extends StatelessWidget {
  const _AlertsSkeletonList();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => _SkeletonAlertCard(dark: dark),
    );
  }
}

// ─────────────────────────────────────────────
// States
// ─────────────────────────────────────────────

class _UpsellState extends StatelessWidget {
  final bool dark;
  final VoidCallback onUpgrade;
  const _UpsellState({required this.dark, required this.onUpgrade});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _AT.accent.withOpacity(0.16),
                    _AT.violet.withOpacity(0.16),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.notifications_active_rounded,
                  size: 32, color: _AT.accent),
            ),
            const SizedBox(height: 18),
            Text('Alerts are a Pro/Max feature',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _AT.text(dark))),
            const SizedBox(height: 6),
            Text(
              'Turn on notifications for any saved backtest and get pinged\n'
              'the moment that setup shows up again — no manual checking.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: _AT.sub(dark), height: 1.4),
            ),
            const SizedBox(height: 22),
            GestureDetector(
              onTap: onUpgrade,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                decoration: BoxDecoration(
                  gradient: _AT.gradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _AT.accent.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Text('Upgrade to unlock alerts',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () {
                _launchContactUs(context);
              },
              icon: Icon(Icons.support_agent_rounded,
                  size: 17, color: _AT.sub(dark)),
              label: Text('Contact us',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _AT.sub(dark))),
            ),
          ]),
        ),
      );
}

class _EmptyAlertsState extends StatelessWidget {
  final bool dark;
  const _EmptyAlertsState({required this.dark});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _AT.sub(dark).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.notifications_none_rounded,
                  size: 30, color: _AT.sub(dark)),
            ),
            const SizedBox(height: 14),
            Text('No alerts yet',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _AT.text(dark))),
            const SizedBox(height: 6),
            Text(
              'Open any saved backtest and flip on "Notify me" to\n'
              'get alerted whenever that setup happens again.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: _AT.sub(dark), height: 1.4),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                _launchContactUs(context);
              },
              icon: Icon(Icons.support_agent_rounded,
                  size: 17, color: _AT.accent),
              label: Text('Contact us',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _AT.accent)),
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
            Icon(Icons.error_outline_rounded, size: 40, color: _AT.red),
            const SizedBox(height: 10),
            Text(error,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: _AT.sub(dark))),
            const SizedBox(height: 14),
            Row(mainAxisSize: MainAxisSize.min, children: [
              TextButton(onPressed: onRetry, child: const Text('Retry')),
              const SizedBox(width: 4),
              TextButton.icon(
                onPressed: () {
                  _launchContactUs(context);
                },
                icon: Icon(Icons.support_agent_rounded,
                    size: 16, color: _AT.sub(dark)),
                label: Text('Contact us',
                    style: TextStyle(fontSize: 12, color: _AT.sub(dark))),
              ),
            ]),
          ]),
        ),
      );
}

// ─────────────────────────────────────────────
// Alert card -- one per algo with notifications on
// ─────────────────────────────────────────────

class _AlertCard extends StatelessWidget {
  final SavedBacktestModel algo;
  final bool dark;
  final bool toggling;
  final VoidCallback onTap;
  final VoidCallback onDisable;

  const _AlertCard({
    required this.algo,
    required this.dark,
    required this.toggling,
    required this.onTap,
    required this.onDisable,
  });

  String _scheduleSummary() {
    if (algo.lastAlertedAt != null) {
      return 'Last fired ${_timeAgo(algo.lastAlertedAt!)}';
    }
    if (algo.lastCheckedAt != null) {
      return 'Checked ${_timeAgo(algo.lastCheckedAt!)} · no match yet';
    }
    return 'Watching — checked every 5 min during market hours';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _AT.surface(dark),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _AT.border(dark)),
          boxShadow: _AT.cardShadow(dark),
        ),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _AT.green.withOpacity(0.18),
                  _AT.green.withOpacity(0.06),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(11),
            ),
            child:
                Icon(Icons.notifications_rounded, color: _AT.green, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(algo.name,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _AT.text(dark)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Text('${algo.symbol} · ${algo.direction}',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _AT.sub(dark))),
              const SizedBox(height: 3),
              Text(_scheduleSummary(),
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _AT.amber)),
            ]),
          ),
          toggling
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Switch(
                    value: true,
                    activeColor: _AT.accent,
                    onChanged: (_) => onDisable(),
                  ),
                ),
        ]),
      ),
    );
  }
}

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
  if (diff.inDays > 0) return '${diff.inDays}d ago';
  if (diff.inHours > 0) return '${diff.inHours}h ago';
  if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
  return 'just now';
}
