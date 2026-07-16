import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:optionxi/Components/cust_contact_us.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

// =============================================================================
// DEPLOYED ALGOS — main screen
// =============================================================================

class DeployedAlgosScreen extends StatefulWidget {
  const DeployedAlgosScreen({super.key});

  @override
  State<DeployedAlgosScreen> createState() => _DeployedAlgosScreenState();
}

class _DeployedAlgosScreenState extends State<DeployedAlgosScreen> {
  final AlgoService _service = AlgoService();
  late Stream<List<AlgoModel>> _algosStream;
  late Future<int?> _limitFuture;

  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  bool _searchOpen = false;

  @override
  void initState() {
    super.initState();
    _algosStream = _service.watchAlgos();
    _limitFuture = _service.getAlgoLimit();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _retry() {
    setState(() {
      _algosStream = _service.watchAlgos();
      _limitFuture = _service.getAlgoLimit();
    });
  }

  void _toggleSearch() {
    setState(() {
      _searchOpen = !_searchOpen;
      if (!_searchOpen) {
        _searchController.clear();
        _query = '';
      }
    });
  }

  Future<void> _handleAddAlgoTap() async {
    HapticFeedback.selectionClick();
    final limit = await _service.getAlgoLimit();
    if (!mounted) return;

    if (limit == null) {
      _showSubscribeSheet();
      return;
    }

    final canAdd = await _service.canAddAlgo();
    if (!mounted) return;
    if (!canAdd) {
      _showLockedSheet();
      return;
    }

    final created = await showAddAlgoDialog(context, _service);
    if (created == true && mounted) {
      setState(() => _limitFuture = _service.getAlgoLimit());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('Algo deployed successfully'),
            ],
          ),
        ),
      );
    }
  }

  void _showLockedSheet() {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.outlineVariant.withOpacity(0.4)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child:
                  Icon(Icons.lock_outline_rounded, color: cs.primary, size: 22),
            ),
            const SizedBox(height: 16),
            Text('Algo slot locked',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              'You\'ve used all of your available deployment slots. '
              'Contact your admin to unlock additional capacity.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: cs.onSurfaceVariant, height: 1.45),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSubscribeSheet() {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.outlineVariant.withOpacity(0.4)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.workspace_premium_rounded,
                  color: cs.primary, size: 22),
            ),
            const SizedBox(height: 16),
            Text('Algo deployment is a premium feature',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              'Subscribe to deploy and monitor your own trading algos '
              'with live signal notifications.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: cs.onSurfaceVariant, height: 1.45),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text('₹1,500',
                      style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800, color: cs.primary)),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('/ month',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  showContactOptions(
                      context, "I want to subscribe to Algo Deployment");
                },
                child: const Text('Subscribe now'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Maybe later'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Deployed Algos'),
        centerTitle: false,
        scrolledUnderElevation: 1,
        actions: [
          IconButton(
            tooltip: _searchOpen ? 'Close search' : 'Search',
            icon:
                Icon(_searchOpen ? Icons.close_rounded : Icons.search_rounded),
            onPressed: _toggleSearch,
          ),
          IconButton.filledTonal(
            tooltip: 'Add algo',
            icon: const Icon(Icons.add_rounded),
            onPressed: _handleAddAlgoTap,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          FutureBuilder<int?>(
            future: _limitFuture,
            builder: (context, limitSnap) {
              return StreamBuilder<List<AlgoModel>>(
                stream: _service.watchAlgos(),
                builder: (context, snap) {
                  final total = snap.data?.length;
                  if (!limitSnap.hasData || total == null) {
                    return const SizedBox.shrink();
                  }
                  final limit = limitSnap.data;
                  if (limit == null) {
                    return _PremiumBanner(onTap: _showSubscribeSheet);
                  }
                  return _UsageHeader(used: total, limit: limit);
                },
              );
            },
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: _searchOpen
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search algos...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        isDense: true,
                        filled: true,
                        fillColor: cs.surfaceContainerHighest.withOpacity(0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: StreamBuilder<List<AlgoModel>>(
              stream: _algosStream,
              builder: (context, snapshot) {
                Widget child;

                if (snapshot.connectionState == ConnectionState.waiting) {
                  child = const _AlgoListSkeleton(key: ValueKey('loading'));
                } else if (snapshot.hasError) {
                  child = _ErrorState(
                      key: const ValueKey('error'), onRetry: _retry);
                } else {
                  final all = snapshot.data ?? [];
                  final filtered = all.where((a) {
                    final matchesQuery = _query.isEmpty ||
                        a.name.toLowerCase().contains(_query) ||
                        a.details.toLowerCase().contains(_query);
                    return matchesQuery;
                  }).toList();

                  if (all.isEmpty) {
                    child = _EmptyState(
                        key: const ValueKey('empty'), onTap: _handleAddAlgoTap);
                  } else if (filtered.isEmpty) {
                    child = _NoResultsState(key: const ValueKey('no-results'));
                  } else {
                    child = RefreshIndicator(
                      key: const ValueKey('list'),
                      onRefresh: () async => _retry(),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final algo = filtered[index];
                          return AlgoCard(
                            algo: algo,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => AlgoNotificationsScreen(
                                    algo: algo,
                                    service: _service,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    );
                  }
                }

                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: child,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Usage header — shows slot consumption
// -----------------------------------------------------------------------------

class _UsageHeader extends StatelessWidget {
  final int used;
  final int limit;
  const _UsageHeader({required this.used, required this.limit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ratio = limit == 0 ? 0.0 : (used / limit).clamp(0.0, 1.0);
    final isFull = used >= limit;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Deployment slots',
                        style: theme.textTheme.labelMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      Text(
                        '$used / $limit',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: isFull ? cs.error : cs.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 6,
                      backgroundColor: cs.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(
                        isFull ? cs.error : cs.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Premium banner — shown when user has no subscription record
// -----------------------------------------------------------------------------

class _PremiumBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _PremiumBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: cs.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(Icons.workspace_premium_rounded,
                  color: cs.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Deploy your first algo — ₹1,500/month',
                  style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700, color: cs.primary),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: cs.primary, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// SKELETON LOADING — subtle, professional pulse (no gradient sweep)
// =============================================================================

class _PulseBox extends StatefulWidget {
  final double? width;
  final double height;
  final BorderRadius borderRadius;

  const _PulseBox({
    this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(6)),
  });

  @override
  State<_PulseBox> createState() => _PulseBoxState();
}

class _PulseBoxState extends State<_PulseBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.45, end: 0.9).animate(
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
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: widget.borderRadius,
        ),
      ),
    );
  }
}

class _AlgoCardSkeleton extends StatelessWidget {
  const _AlgoCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const _PulseBox(
              width: 44,
              height: 44,
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _PulseBox(width: 130, height: 14),
                  const SizedBox(height: 8),
                  const _PulseBox(width: double.infinity, height: 11),
                  const SizedBox(height: 6),
                  const _PulseBox(width: 200, height: 11),
                  const SizedBox(height: 12),
                  Row(
                    children: const [
                      _PulseBox(
                        width: 72,
                        height: 20,
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      SizedBox(width: 8),
                      _PulseBox(
                        width: 38,
                        height: 20,
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlgoListSkeleton extends StatelessWidget {
  const _AlgoListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: 5,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) => const _AlgoCardSkeleton(),
    );
  }
}

class _NotificationCardSkeleton extends StatelessWidget {
  const _NotificationCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Expanded(child: _PulseBox(width: double.infinity, height: 13)),
              SizedBox(width: 12),
              _PulseBox(width: 44, height: 11),
            ],
          ),
          const SizedBox(height: 8),
          const _PulseBox(width: double.infinity, height: 11),
          const SizedBox(height: 6),
          _PulseBox(width: MediaQuery.of(context).size.width * 0.4, height: 11),
        ],
      ),
    );
  }
}

class _NotificationsListSkeleton extends StatelessWidget {
  const _NotificationsListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: 6,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => const _NotificationCardSkeleton(),
    );
  }
}

// =============================================================================
// EMPTY / ERROR / NO-RESULTS STATES
// =============================================================================

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: cs.errorContainer.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.wifi_off_rounded, size: 28, color: cs.error),
            ),
            const SizedBox(height: 18),
            Text(
              'Couldn\'t load your algos',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Check your connection and try again.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 22),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 17),
              label: const Text('Retry'),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                side: BorderSide(color: cs.outlineVariant),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyState({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child:
                  Icon(Icons.auto_graph_rounded, size: 34, color: cs.primary),
            ),
            const SizedBox(height: 20),
            Text(
              'No algos deployed yet',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Deploy your first trading algo to start receiving\nlive signal notifications.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant, height: 1.4),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.add_rounded, size: 19),
              label: const Text('Deploy an algo'),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoResultsState extends StatelessWidget {
  const _NoResultsState({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                size: 40, color: cs.onSurfaceVariant),
            const SizedBox(height: 14),
            Text(
              'No matching algos',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Try a different search term or filter.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// NOTIFICATIONS SCREEN — with pagination and loading states
// =============================================================================

class AlgoNotificationsScreen extends StatefulWidget {
  final AlgoModel algo;
  final AlgoService service;

  const AlgoNotificationsScreen({
    super.key,
    required this.algo,
    required this.service,
  });

  @override
  State<AlgoNotificationsScreen> createState() =>
      _AlgoNotificationsScreenState();
}

class _AlgoNotificationsScreenState extends State<AlgoNotificationsScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<AlgoNotificationModel> _items = [];
  int _page = 0;
  bool _loading = false;
  bool _hasMore = true;
  bool _initialLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPage();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_loading &&
        _hasMore) {
      _loadPage();
    }
  }

  Future<void> _loadPage() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final page = await widget.service.fetchNotificationsPage(
        algoId: widget.algo.id,
        page: _page,
      );

      if (!mounted) return;

      setState(() {
        _items.addAll(page);
        _page++;
        _hasMore = page.length == AlgoService.kPageSize;
        _initialLoading = false;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _initialLoading = false;
        _error = 'Failed to load notifications';
      });
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _items.clear();
      _page = 0;
      _hasMore = true;
      _error = null;
    });
    await _loadPage();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(widget.algo.name, overflow: TextOverflow.ellipsis),
        scrolledUnderElevation: 1,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: widget.algo.status.color(context).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(Icons.auto_graph_rounded,
                      color: widget.algo.status.color(context), size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.algo.details,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          StatusPill(status: widget.algo.status),
                          const SizedBox(width: 8),
                          _TimeframeChip(timeframe: widget.algo.timeframe),
                          const Spacer(),
                          Text(
                            'Deployed ${timeago.format(DateTime.fromMillisecondsSinceEpoch(widget.algo.createdAt))}',
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    // Initial loading state
    if (_initialLoading) {
      return const _NotificationsListSkeleton();
    }

    // Error state
    if (_error != null && _items.isEmpty) {
      return _buildErrorState();
    }

    // Empty state
    if (_items.isEmpty) {
      return _buildEmptyState();
    }

    // Notifications list with pagination
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: _items.length + (_hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          // Load more indicator at the bottom
          if (index >= _items.length) {
            return _buildLoadMoreIndicator();
          }

          final notification = _items[index];
          return _NotificationTile(notification: notification);
        },
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: _loading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildErrorState() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: cs.errorContainer.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child:
                  Icon(Icons.error_outline_rounded, size: 24, color: cs.error),
            ),
            const SizedBox(height: 14),
            Text(
              _error ?? 'Something went wrong',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Pull down to refresh, or try again shortly.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded, size: 17),
              label: const Text('Retry'),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.notifications_none_rounded,
                  size: 30, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Text(
              'No triggers yet',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Notifications will show up here once this\nalgo triggers a signal.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AlgoNotificationModel notification;
  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: cs.primary, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.bolt_rounded, size: 16, color: cs.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  notification.title,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                timeago.format(notification.dateTime),
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            notification.description,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: cs.onSurfaceVariant, height: 1.35),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// ADD ALGO DIALOG
// =============================================================================

const List<String> kTimeframes = ['1m', '5m', '15m', '1h', '4h', '1D'];

/// Shows the add-algo dialog. Returns true if an algo was created.
Future<bool?> showAddAlgoDialog(BuildContext context, AlgoService service) {
  return showDialog<bool>(
    context: context,
    builder: (_) => AddAlgoDialog(service: service),
  );
}

class AddAlgoDialog extends StatefulWidget {
  final AlgoService service;
  const AddAlgoDialog({super.key, required this.service});

  @override
  State<AddAlgoDialog> createState() => _AddAlgoDialogState();
}

class _AddAlgoDialogState extends State<AddAlgoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _detailsController = TextEditingController();
  String _timeframe = kTimeframes.first;
  bool _submitting = false;
  String? _errorText;

  @override
  void dispose() {
    _nameController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration(
    BuildContext context, {
    required String label,
    String? hint,
  }) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: cs.surfaceContainerHighest.withOpacity(0.45),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.error, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();
    setState(() {
      _submitting = true;
      _errorText = null;
    });
    try {
      await widget.service.addAlgo(
        name: _nameController.text,
        details: _detailsController.text,
        timeframe: _timeframe,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _errorText = 'Could not deploy algo. Please try again.';
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: cs.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(Icons.rocket_launch_rounded,
                          color: cs.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Deploy New Algo',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(
                            'This slot locks after deployment',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: _fieldDecoration(
                    context,
                    label: 'Algo name',
                    hint: 'e.g. Nifty Breakout Scalper',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Name is required'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _detailsController,
                  maxLines: 3,
                  decoration: _fieldDecoration(
                    context,
                    label: 'Details',
                    hint: 'Strategy logic, instruments, risk notes...',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Details are required'
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  'Time frame',
                  style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600, color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: kTimeframes.map((tf) {
                    final selected = tf == _timeframe;
                    return ChoiceChip(
                      label: Text(tf),
                      selected: selected,
                      showCheckmark: false,
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: selected ? cs.onPrimary : cs.onSurfaceVariant,
                      ),
                      selectedColor: cs.primary,
                      backgroundColor:
                          cs.surfaceContainerHighest.withOpacity(0.55),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      onSelected: (_) => setState(() => _timeframe = tf),
                    );
                  }).toList(),
                ),
                if (_errorText != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: cs.errorContainer.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline_rounded,
                            size: 17, color: cs.error),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_errorText!,
                              style: TextStyle(color: cs.error, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _submitting
                            ? null
                            : () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _submitting ? null : _submit,
                        child: _submitting
                            ? SizedBox(
                                width: 17,
                                height: 17,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation(cs.onPrimary),
                                ),
                              )
                            : const Text('Deploy'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// ALGO CARD + CHIPS
// =============================================================================

class AlgoCard extends StatelessWidget {
  final AlgoModel algo;
  final VoidCallback onTap;

  const AlgoCard({super.key, required this.algo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final statusColor = algo.status.color(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: statusColor, width: 3)),
            ),
            padding: const EdgeInsets.fromLTRB(13, 14, 14, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.auto_graph_rounded,
                      color: statusColor, size: 20),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        algo.name,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        algo.details,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant, height: 1.3),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          StatusPill(status: algo.status),
                          _TimeframeChip(timeframe: algo.timeframe),
                          Text(
                            timeago.format(DateTime.fromMillisecondsSinceEpoch(
                                algo.createdAt)),
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: cs.onSurfaceVariant.withOpacity(0.8)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 2),
                Icon(Icons.chevron_right_rounded,
                    color: cs.onSurfaceVariant.withOpacity(0.5), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeframeChip extends StatelessWidget {
  final String timeframe;
  const _TimeframeChip({required this.timeframe});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        timeframe,
        style: theme.textTheme.labelSmall
            ?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  final AlgoStatus status;
  const StatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status.color(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: TextStyle(
                color: color, fontSize: 11.5, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// DATA LAYER
// =============================================================================

/// Thin wrapper around Firebase Realtime Database for the "Deployed Algos"
/// feature.
///
/// Data shape:
/// algo_deployed/{uid}/{algoId}/{name, details, timeframe, status, createdAt}
/// algo_deployed/{uid}/{algoId}/notifications/{notifId}/{title, description, timestamp}
/// subscribed_algo_users/{uid}/{limit}

class AlgoService {
  AlgoService({FirebaseDatabase? database, FirebaseAuth? auth})
      : _database = database ?? FirebaseDatabase.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _supabase = Supabase.instance.client;

  final FirebaseDatabase _database;
  final FirebaseAuth _auth;
  final SupabaseClient _supabase;

  static const int kPageSize = 20;

  DatabaseReference get _root => _database.ref();

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('No authenticated user found.');
    }
    return uid;
  }

  /// Live stream of the current user's deployed algos.
  Stream<List<AlgoModel>> watchAlgos() {
    return _root.child('algo_deployed/$_uid').onValue.map((event) {
      final raw = event.snapshot.value;
      if (raw == null || raw is! Map) return <AlgoModel>[];

      final map = Map<dynamic, dynamic>.from(raw);
      final algos = map.entries
          .map((e) => AlgoModel.fromMap(
                e.key.toString(),
                Map<dynamic, dynamic>.from(e.value as Map),
              ))
          .toList();

      algos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return algos;
    });
  }

  /// Paginated fetch for notifications.
  Future<List<AlgoNotificationModel>> fetchNotificationsPage({
    required String algoId,
    required int page,
  }) async {
    final from = page * kPageSize;
    final to = from + kPageSize - 1;

    final rows = await _supabase
        .from('algo_notifications')
        .select()
        .eq('uid_algo', '$_uid:$algoId')
        .order('created_at', ascending: false)
        .range(from, to);

    return (rows as List)
        .map((r) =>
            AlgoNotificationModel.fromSupabase(Map<String, dynamic>.from(r)))
        .toList();
  }

  /// Returns the algo limit for the current user, or `null` if no subscription
  /// record exists (meaning the user is not subscribed at all).
  Future<int?> getAlgoLimit() async {
    final snap = await _root.child('subscribed_algo_users/$_uid').get();
    if (!snap.exists || snap.value == null) return null; // not subscribed
    final map = Map<dynamic, dynamic>.from(snap.value as Map);
    final value = map['limit'];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  /// Checks the current algo count against the allowed limit.
  /// Returns true if the user is still allowed to add another algo.
  Future<bool> canAddAlgo() async {
    final limit = await getAlgoLimit();
    if (limit == null) return false; // not subscribed at all
    final snap = await _root.child('algo_deployed/$_uid').get();
    final currentCount = (snap.exists && snap.value is Map)
        ? Map<dynamic, dynamic>.from(snap.value as Map).length
        : 0;
    return currentCount < limit;
  }

  /// Adds a new algo under algo_deployed/{uid}/{newId}.
  /// Caller should already have verified [canAddAlgo].
  Future<void> addAlgo({
    required String name,
    required String details,
    required String timeframe,
  }) async {
    final ref = _root.child('algo_deployed/$_uid').push();
    final algo = AlgoModel(
      id: ref.key ?? '',
      name: name.trim(),
      details: details.trim(),
      timeframe: timeframe,
      status: AlgoStatus.updated,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await ref.set(algo.toMap());
  }

  /// Ensures a subscribed_algo_users/{uid} record exists with a default
  /// limit of 1, so admins can find & edit it later without guessing.
  Future<void> ensureSubscriptionRecord() async {
    final ref = _root.child('subscribed_algo_users/$_uid');
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({'limit': 1});
    }
  }
}

class AlgoModel {
  final String id;
  final String name;
  final String details;
  final String timeframe;
  final AlgoStatus status;
  final int createdAt; // millisecondsSinceEpoch

  AlgoModel({
    required this.id,
    required this.name,
    required this.details,
    required this.timeframe,
    required this.status,
    required this.createdAt,
  });

  factory AlgoModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return AlgoModel(
      id: id,
      name: (map['name'] ?? '').toString(),
      details: (map['details'] ?? '').toString(),
      timeframe: (map['timeframe'] ?? '').toString(),
      status: AlgoStatus.fromValue(map['status']?.toString()),
      createdAt: map['createdAt'] is int
          ? map['createdAt']
          : int.tryParse(map['createdAt']?.toString() ?? '') ??
              DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'details': details,
      'timeframe': timeframe,
      'status': status.value,
      'createdAt': createdAt,
    };
  }
}

/// All lifecycle states an algo can be in.
/// Stored in Firebase as the raw string in [value].
enum AlgoStatus {
  updated('updated', 'Updated'),
  developerAssigned('developer_assigned', 'Developer Assigned'),
  onCall('on_call', 'On Call'),
  phase1('phase_1', 'Phase 1'),
  deployed('deployed', 'Deployed'),
  clientNotPickingUp('client_not_picking_up', 'Client Not Picking Up'),
  cancelling('cancelling', 'Cancelling'),
  cancelled('cancelled', 'Cancelled');

  final String value;
  final String label;
  const AlgoStatus(this.value, this.label);

  static AlgoStatus fromValue(String? raw) {
    return AlgoStatus.values.firstWhere(
      (s) => s.value == raw,
      orElse: () => AlgoStatus.updated,
    );
  }

  /// Theme-aware color so it reads correctly in both light & dark mode.
  Color color(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (this) {
      case AlgoStatus.updated:
        return isDark ? const Color(0xFF64B5F6) : const Color(0xFF1565C0);
      case AlgoStatus.developerAssigned:
        return isDark ? const Color(0xFFBA68C8) : const Color(0xFF6A1B9A);
      case AlgoStatus.onCall:
        return isDark ? const Color(0xFFFFB74D) : const Color(0xFFE65100);
      case AlgoStatus.phase1:
        return isDark ? const Color(0xFF4FC3F7) : const Color(0xFF0277BD);
      case AlgoStatus.deployed:
        return isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32);
      case AlgoStatus.clientNotPickingUp:
        return isDark ? const Color(0xFFE57373) : const Color(0xFFC62828);
      case AlgoStatus.cancelling:
        return isDark ? const Color(0xFFFF8A65) : const Color(0xFFD84315);
      case AlgoStatus.cancelled:
        return isDark ? const Color(0xFF90A4AE) : const Color(0xFF546E7A);
    }
  }
}

class AlgoNotificationModel {
  final String id;
  final String title;
  final String description;
  final int timestamp; // millisecondsSinceEpoch

  AlgoNotificationModel({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
  });

  factory AlgoNotificationModel.fromSupabase(Map<String, dynamic> row) {
    return AlgoNotificationModel(
      id: row['id'].toString(),
      title: (row['title'] ?? '').toString(),
      description: (row['description'] ?? '').toString(),
      timestamp:
          DateTime.parse(row['created_at'] as String).millisecondsSinceEpoch,
    );
  }

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(timestamp);
}
