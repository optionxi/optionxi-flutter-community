import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:optionxi/Main_Pages/DeployedAlgos/Act_DeployedAlgos.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// =============================================================================
// GETX CONTROLLER
// =============================================================================
//
// Read/unread state is persisted in SharedPreferences per algo per day.
// On controller init, it only fetches today's notifications (not all history).
// The moment the user opens that algo's notification list, its badge is cleared
// for the rest of the day, even across app restarts.

class AlgoNotifBannerController extends GetxController {
  AlgoNotifBannerController({AlgoService? service})
      : _service = service ?? AlgoService();

  final AlgoService _service;
  final SupabaseClient _supabase = Supabase.instance.client;

  final RxBool subscriptionChecked = false.obs;
  final RxBool isSubscribed = false.obs;
  final RxBool isLoading = false.obs;

  final RxList<AlgoModel> algos = <AlgoModel>[].obs;

  // Only today's notification count per algo — fetched fresh each refresh,
  // never the full history.
  final RxMap<String, int> _todayCounts = <String, int>{}.obs;

  // How many of today's notifications the user has already seen.
  // Persisted in SharedPreferences (per algo, per day) so it survives
  // app restarts — not just session-local like before.
  final Map<String, int> _readCounts = {};

  StreamSubscription<List<AlgoModel>>? _algoSub;
  Timer? _pollTimer;
  SharedPreferences? _prefs;

  static const Duration _pollInterval = Duration(seconds: 45);
  static const String _prefsPrefix = 'algo_notif_read';

  @override
  void onInit() {
    super.onInit();
    _bootstrap();
  }

  String _todayKey() {
    final now = DateTime.now();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '${now.year}-$m-$d';
  }

  // Date is baked into the key, so a new day == a fresh, unread count —
  // no manual "reset" step needed.
  String _prefsKey(String algoId) => '${_prefsPrefix}_${algoId}_${_todayKey()}';

  Future<void> _bootstrap() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (_) {
      _prefs = null;
    }

    try {
      final limit = await _service.getAlgoLimit();
      isSubscribed.value = limit != null;
    } catch (_) {
      isSubscribed.value = false;
    } finally {
      subscriptionChecked.value = true;
    }

    if (isSubscribed.value) {
      _startWatching();
    }
  }

  void _startWatching() {
    isLoading.value = true;
    _algoSub = _service.watchAlgos().listen(
      (list) async {
        algos.value = list;
        await _refreshCounts();
        isLoading.value = false;
      },
      onError: (_) {
        isLoading.value = false;
      },
    );
    _pollTimer = Timer.periodic(_pollInterval, (_) => _refreshCounts());
  }

  /// Fetches only TODAY's notification count per algo (nothing older).
  /// Also lazily loads today's persisted "read" count from
  /// SharedPreferences the first time we see each algo.
  Future<void> _refreshCounts() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || algos.isEmpty) return;

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();

    for (final algo in algos) {
      try {
        final rows = await _supabase
            .from('algo_notifications')
            .select('id')
            .eq('uid_algo', '$uid:${algo.id}')
            .gte('created_at', startOfDay);
        _todayCounts[algo.id] = (rows as List).length;

        _readCounts.putIfAbsent(
          algo.id,
          () => _prefs?.getInt(_prefsKey(algo.id)) ?? 0,
        );
      } catch (_) {
        // Ignore a single algo's failure so one bad fetch doesn't
        // block the rest of the banner.
      }
    }
    _todayCounts.refresh();
  }

  int unreadFor(String algoId) {
    final today = _todayCounts[algoId] ?? 0;
    final read = _readCounts[algoId] ?? 0;
    final diff = today - read;
    return diff > 0 ? diff : 0;
  }

  /// True once we've actually checked today's count for this algo
  /// (as opposed to just not having loaded yet).
  bool hasCheckedToday(String algoId) => _todayCounts.containsKey(algoId);

  int get totalUnread => algos.fold<int>(0, (sum, a) => sum + unreadFor(a.id));

  List<AlgoModel> get algosWithUnread =>
      algos.where((a) => unreadFor(a.id) > 0).toList()
        ..sort((a, b) => unreadFor(b.id).compareTo(unreadFor(a.id)));

  /// Marks today's notifications as read for [algoId] and persists that
  /// to SharedPreferences, so the badge stays cleared even if the app is
  /// killed and reopened later today. A fresh signal arriving after this
  /// will still show up, since _todayCounts will grow past the saved value.
  void markRead(String algoId) {
    final today = _todayCounts[algoId] ?? 0;
    _readCounts[algoId] = today;
    _todayCounts.refresh();
    _prefs?.setInt(_prefsKey(algoId), today);
  }

  void handleTap(BuildContext context) {
    HapticFeedback.selectionClick();
    final unread = algosWithUnread;

    if (unread.length == 1) {
      final algo = unread.first;
      markRead(algo.id);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              AlgoNotificationsScreen(algo: algo, service: _service),
        ),
      );
      return;
    }

    if (unread.length > 1) {
      _showAlgoPicker(context, unread);
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DeployedAlgosScreen()),
    );
  }

  void _showAlgoPicker(BuildContext context, List<AlgoModel> unreadAlgos) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.outlineVariant.withOpacity(0.4)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.bolt_rounded, size: 18, color: cs.primary),
                ),
                const SizedBox(width: 10),
                Text(
                  'Conditions met',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'These algos hit a rule you set — tap one to see what triggered it.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant, height: 1.35),
            ),
            const SizedBox(height: 14),
            ...unreadAlgos.map((algo) {
              final count = unreadFor(algo.id);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: cs.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(14),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      markRead(algo.id);
                      Navigator.of(sheetContext).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AlgoNotificationsScreen(
                            algo: algo,
                            service: _service,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color:
                                  algo.status.color(context).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.auto_graph_rounded,
                                size: 17, color: algo.status.color(context)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              algo.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          _CountBadge(count: count),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  @override
  void onClose() {
    _pollTimer?.cancel();
    _algoSub?.cancel();
    super.onClose();
  }
}

// =============================================================================
// PUBLIC WIDGET — drop this into your homepage
// =============================================================================

class AlgoNotificationBanner extends StatefulWidget {
  const AlgoNotificationBanner({super.key});

  static const double kHeight = 76;

  @override
  State<AlgoNotificationBanner> createState() => _AlgoNotificationBannerState();
}

class _AlgoNotificationBannerState extends State<AlgoNotificationBanner> {
  final String _tag =
      'algo_notif_banner_${DateTime.now().microsecondsSinceEpoch}';
  late final AlgoNotifBannerController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(AlgoNotifBannerController(), tag: _tag);
  }

  @override
  void dispose() {
    Get.delete<AlgoNotifBannerController>(tag: _tag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.subscriptionChecked.value ||
          !controller.isSubscribed.value) {
        return const SizedBox.shrink();
      }

      return _BannerShell(
        loading: controller.isLoading.value,
        unreadTotal: controller.totalUnread,
        unreadAlgoCount: controller.algosWithUnread.length,
        totalAlgoCount: controller.algos.length,
        onTap: () => controller.handleTap(context),
      );
    });
  }
}

// =============================================================================
// BANNER UI
// =============================================================================

class _BannerShell extends StatelessWidget {
  final bool loading;
  final int unreadTotal;
  final int unreadAlgoCount;
  final int totalAlgoCount;
  final VoidCallback onTap;

  const _BannerShell({
    required this.loading,
    required this.unreadTotal,
    required this.unreadAlgoCount,
    required this.totalAlgoCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hasUnread = !loading && unreadTotal > 0;

    return Material(
      color: cs.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: InkWell(
        onTap: loading ? null : onTap,
        splashColor: cs.primary.withOpacity(0.06),
        highlightColor: cs.primary.withOpacity(0.03),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: AlgoNotificationBanner.kHeight,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: hasUnread
                ? LinearGradient(
                    colors: [
                      cs.primary.withOpacity(0.08),
                      cs.surfaceContainerHigh,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            border: Border.all(
              color: hasUnread
                  ? cs.primary.withOpacity(0.25)
                  : cs.outlineVariant.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              _LeadingIcon(hasUnread: hasUnread, loading: loading),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Algo Signals',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                        if (hasUnread) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: cs.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _subtitle(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: hasUnread ? cs.primary : cs.onSurfaceVariant,
                        fontWeight:
                            hasUnread ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (loading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(
                        cs.onSurfaceVariant.withOpacity(0.5)),
                  ),
                )
              else ...[
                if (hasUnread) _CountBadge(count: unreadTotal),
                const SizedBox(width: 6),
                Icon(Icons.chevron_right_rounded,
                    color: cs.onSurfaceVariant.withOpacity(0.45), size: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Plain-language copy: this banner exists so a user always knows
  // "we're watching your algo's conditions, and here's what happened today."
  String _subtitle() {
    if (loading) return 'Checking your algo conditions…';
    if (unreadTotal > 0) {
      final signalWord = unreadTotal == 1 ? 'alert' : 'alerts';
      final algoWord = unreadAlgoCount == 1 ? 'algo' : 'algos';
      return '$unreadTotal new $signalWord — conditions met on $unreadAlgoCount $algoWord';
    }
    if (totalAlgoCount == 0) {
      return 'Set up an algo to start getting alerts';
    }
    return 'All quiet — no conditions triggered today';
  }
}

class _LeadingIcon extends StatefulWidget {
  final bool hasUnread;
  final bool loading;
  const _LeadingIcon({required this.hasUnread, required this.loading});

  @override
  State<_LeadingIcon> createState() => _LeadingIconState();
}

class _LeadingIconState extends State<_LeadingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = widget.hasUnread ? cs.primary : cs.onSurfaceVariant;

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withOpacity(widget.hasUnread ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.hasUnread && !widget.loading)
            FadeTransition(
              opacity: _pulse,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                      color: cs.primary.withOpacity(0.4), width: 1.5),
                ),
              ),
            ),
          Icon(
            widget.hasUnread
                ? Icons.notifications_active_rounded
                : Icons.notifications_none_rounded,
            color: color,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = count > 99 ? '99+' : '$count';

    return Container(
      constraints: const BoxConstraints(minWidth: 24),
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withOpacity(0.35),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: cs.onPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 1,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}
