import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:optionxi/DataModels/sample_stock_symbols.dart';
import 'package:optionxi/Helpers/badge_service.dart';
import 'package:optionxi/Main_Pages/MarketSentiments/act_market_sentiments.dart';
import 'package:optionxi/Main_Pages/Leaderboard/act_leaderboard.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

// ─── Design Tokens ───────────────────────────────────────────────────────────

class _Palette {
  // Accent
  static const indigo = Color(0xFF5B5FEF);
  static const violet = Color(0xFF7C3AED);
  static const indigoSoft = Color(0xFFEEEFFD);

  // Dark surface hierarchy
  static const darkBg = Color(0xFF080C14);
  static const darkCard = Color(0xFF0F1520);
  static const darkCardHover = Color(0xFF141C2B);
  static const darkBorder = Color(0xFF1E2A3D);

  // Light surface hierarchy
  static const lightBg = Color(0xFFF4F6FB);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightBorder = Color(0xFFE4E8F0);
  static const lightMuted = Color(0xFFA0AABF);
}

class _TextStyles {
  static TextStyle heading(bool isDark) => TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        color: isDark ? Colors.white : const Color(0xFF0D1117),
        height: 1.1,
      );

  static TextStyle cardTitle(bool isDark) => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: isDark ? Colors.white : const Color(0xFF0D1117),
        height: 1.3,
      );

  static TextStyle cardBody(bool isDark) => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: isDark ? const Color(0xFFAAB8CC) : const Color(0xFF4A5568),
        height: 1.55,
        letterSpacing: 0.1,
      );

  static TextStyle chip(bool isDark) => TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: isDark ? _Palette.indigo : _Palette.indigo,
      );

  static TextStyle timestamp(bool isDark) => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: isDark ? const Color(0xFF6B7FA3) : _Palette.lightMuted,
        letterSpacing: 0.2,
      );

  static TextStyle label(bool isDark) => TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: isDark ? const Color(0xFF4A6080) : _Palette.lightMuted,
      );
}

// ─── Page ────────────────────────────────────────────────────────────────────

class NotificationPage extends StatefulWidget {
  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage>
    with TickerProviderStateMixin {
  final SupabaseClient supabase = Supabase.instance.client;
  List<NotificationItem> notifications = [];
  bool isLoading = true;
  bool hasMore = true;
  int currentPage = 1;
  final int pageSize = 10;
  final ScrollController _scrollController = ScrollController();

  late AnimationController _shimmerController;
  late AnimationController _entryController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    )..repeat();

    _shimmerAnimation = Tween<double>(begin: -1.5, end: 1.5).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    _entryController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    BadgeService.clearNotificationsBadge();
    loadNotifications();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _shimmerController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (hasMore && !isLoading) loadMoreNotifications();
    }
  }

  Future<void> loadNotifications() async {
    setState(() => isLoading = true);
    try {
      final response = await supabase
          .from('notifications')
          .select('*')
          .order('created_at', ascending: false)
          .range(0, pageSize - 1);

      final loaded = (response as List)
          .map((item) => NotificationItem.fromJson(item))
          .toList();

      setState(() {
        notifications = loaded;
        isLoading = false;
        hasMore = loaded.length == pageSize;
        currentPage = 1;
      });
      _entryController.forward(from: 0);
    } catch (_) {
      setState(() => isLoading = false);
      _showErrorSnackbar('Failed to load notifications');
    }
  }

  Future<void> loadMoreNotifications() async {
    if (isLoading || !hasMore) return;
    setState(() => isLoading = true);
    try {
      final from = currentPage * pageSize;
      final to = from + pageSize - 1;
      final response = await supabase
          .from('notifications')
          .select('*')
          .order('created_at', ascending: false)
          .range(from, to);

      final more = (response as List)
          .map((item) => NotificationItem.fromJson(item))
          .toList();

      setState(() {
        notifications.addAll(more);
        currentPage++;
        hasMore = more.length == pageSize;
        isLoading = false;
      });
    } catch (_) {
      setState(() => isLoading = false);
      _showErrorSnackbar('Failed to load more notifications');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text(message,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w500)),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: isDark ? _Palette.darkBg : _Palette.lightBg,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(isDark),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: loadNotifications,
                  color: _Palette.indigo,
                  strokeWidth: 2,
                  child: isLoading && notifications.isEmpty
                      ? _buildShimmerList()
                      : notifications.isEmpty
                          ? _buildEmptyState(isDark)
                          : _buildList(isDark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        children: [
          _BackButton(isDark: isDark),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Notifications', style: _TextStyles.heading(isDark)),
                if (notifications.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '${notifications.length} updates',
                      style: _TextStyles.label(isDark),
                    ),
                  ),
              ],
            ),
          ),
          _HeaderBadge(
            unreadCount: notifications
                .where((n) => !n.isRead && _isToday(n.createdAt))
                .length,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  // ── List ───────────────────────────────────────────────────────────────────

  Widget _buildList(bool isDark) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: notifications.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == notifications.length) return _buildLoadMore();
        return _AnimatedCard(
          index: index,
          child: _NotificationCard(
            notification: notifications[index],
            isDark: isDark,
            isToday: _isToday(notifications[index].createdAt),
            onTap: () => _handleTap(notifications[index]),
          ),
        );
      },
    );
  }

  void _handleTap(NotificationItem notification) {
    if (notification.stockData.isEmpty && notification.stockName.isEmpty)
      return;

    final name = notification.stockName.toUpperCase();

    if (name == 'NIFTY' || name == 'BANKNIFTY' || name == 'MARKET') {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => MarketSentimentPage()));
    } else if (name == 'LEADERBOARD') {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => LeaderboardPage()));
    } else if (checkStockExists(name)) {
      final matchedKey = totalStocks.keys.firstWhere(
        (key) =>
            key.contains(name) ||
            totalStocks[key]?['stock_name']?.contains(name) == true,
        orElse: () => name,
      );
      Get.toNamed('/stocks/$matchedKey');
    }
  }

  Widget _buildLoadMore() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(_Palette.indigo),
          ),
        ),
      ),
    );
  }

  // ── Shimmer ────────────────────────────────────────────────────────────────

  Widget _buildShimmerList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: 6,
      itemBuilder: (_, i) => _ShimmerCard(
        animation: _shimmerAnimation,
        isDark: isDark,
        index: i,
      ),
    );
  }

  // ── Empty ──────────────────────────────────────────────────────────────────

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: isDark ? _Palette.darkCard : const Color(0xFFEEEFFD),
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? _Palette.darkBorder : _Palette.indigoSoft,
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 44,
              color: isDark ? const Color(0xFF4A6080) : const Color(0xFF8B96C8),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'All caught up',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
              color: isDark ? Colors.white : const Color(0xFF0D1117),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'New alerts will appear here',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? const Color(0xFF6B7FA3) : _Palette.lightMuted,
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  bool checkStockExists(String upperCase) {
    if (totalStocks.containsKey(upperCase) &&
        totalStocks[upperCase]?['full_stock_name'] != null) return true;
    for (final entry in totalStocks.entries) {
      final sn = entry.value['stock_name'] ?? '';
      final fn = entry.value['full_stock_name'] ?? '';
      if (sn.contains(upperCase) || fn.contains(upperCase)) return true;
    }
    return false;
  }
}

// ─── Back Button ─────────────────────────────────────────────────────────────

class _BackButton extends StatelessWidget {
  final bool isDark;
  const _BackButton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark ? _Palette.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? _Palette.darkBorder : _Palette.lightBorder,
            width: 1,
          ),
        ),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 16,
          color: isDark ? Colors.white : const Color(0xFF0D1117),
        ),
      ),
    );
  }
}

// ─── Header Badge ─────────────────────────────────────────────────────────────

class _HeaderBadge extends StatelessWidget {
  final int unreadCount;
  final bool isDark;
  const _HeaderBadge({required this.unreadCount, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (unreadCount == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_Palette.indigo, _Palette.violet],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _Palette.indigo.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        '$unreadCount new',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ─── Animated Card Wrapper ────────────────────────────────────────────────────

class _AnimatedCard extends StatefulWidget {
  final int index;
  final Widget child;
  const _AnimatedCard({required this.index, required this.child});

  @override
  State<_AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<_AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    final curve = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _fade = Tween<double>(begin: 0, end: 1).animate(curve);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(curve);

    Future.delayed(Duration(milliseconds: widget.index * 60), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ─── Notification Card ────────────────────────────────────────────────────────

class _NotificationCard extends StatefulWidget {
  final NotificationItem notification;
  final bool isDark;
  final bool isToday;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.isDark,
    required this.isToday,
    required this.onTap,
  });

  @override
  State<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<_NotificationCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final n = widget.notification;
    final isDark = widget.isDark;
    final hasAction = n.stockData.isNotEmpty || n.stockName.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTapDown: hasAction ? (_) => setState(() => _pressed = true) : null,
        onTapUp: hasAction
            ? (_) {
                setState(() => _pressed = false);
                widget.onTap();
              }
            : null,
        onTapCancel: hasAction ? () => setState(() => _pressed = false) : null,
        child: AnimatedScale(
          scale: _pressed ? 0.975 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: isDark
                  ? (_pressed ? _Palette.darkCardHover : _Palette.darkCard)
                  : (_pressed ? const Color(0xFFF8F9FF) : _Palette.lightCard),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? _Palette.darkBorder : _Palette.lightBorder,
                width: 1,
              ),
              boxShadow: isDark
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: const Color(0xFF1A1F5E).withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: Colors.white,
                        blurRadius: 0,
                        offset: const Offset(0, 0),
                        spreadRadius: 0,
                      ),
                    ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top row: title + unread dot
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(n.heading,
                            style: _TextStyles.cardTitle(isDark)),
                      ),
                      if (widget.isToday && !n.isRead) ...[
                        const SizedBox(width: 10),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: _UnreadDot(),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ── Description
                  Text(n.description, style: _TextStyles.cardBody(isDark)),

                  // ── Stock section
                  if (n.stockData.isNotEmpty || n.stockName.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _StockSection(
                      notification: n,
                      isDark: isDark,
                    ),
                  ],

                  const SizedBox(height: 14),
                  // ── Divider
                  Container(
                    height: 1,
                    color: isDark
                        ? _Palette.darkBorder.withOpacity(0.6)
                        : _Palette.lightBorder.withOpacity(0.8),
                  ),
                  const SizedBox(height: 12),

                  // ── Timestamp
                  _TimestampRow(createdAt: n.createdAt, isDark: isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Unread Dot ───────────────────────────────────────────────────────────────

class _UnreadDot extends StatefulWidget {
  @override
  State<_UnreadDot> createState() => _UnreadDotState();
}

class _UnreadDotState extends State<_UnreadDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.7, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _Palette.indigo,
          boxShadow: [
            BoxShadow(
              color: _Palette.indigo.withOpacity(_pulse.value * 0.6),
              blurRadius: 8 * _pulse.value,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stock Section ────────────────────────────────────────────────────────────

class _StockSection extends StatelessWidget {
  final NotificationItem notification;
  final bool isDark;

  const _StockSection({required this.notification, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final chips = n.stockData.isNotEmpty
        ? n.stockData
        : (n.stockName.isNotEmpty ? [n.stockName] : <String>[]);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            children:
                chips.map((s) => _StockChip(text: s, isDark: isDark)).toList(),
          ),
        ),
      ],
    );
  }
}

class _StockChip extends StatelessWidget {
  final String text;
  final bool isDark;
  const _StockChip({required this.text, required this.isDark});

  String _extractSymbol(String input) {
    final parts = input.split(':');
    final symbolPart = parts.length == 2 ? parts[1] : parts[0];
    return symbolPart.split('-').first;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? _Palette.indigo.withOpacity(0.12) : _Palette.indigoSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? _Palette.indigo.withOpacity(0.25)
              : _Palette.indigo.withOpacity(0.18),
          width: 1,
        ),
      ),
      child: Text(
        _extractSymbol(text),
        style: _TextStyles.chip(isDark),
      ),
    );
  }
}

// ─── Timestamp Row ────────────────────────────────────────────────────────────

class _TimestampRow extends StatelessWidget {
  final DateTime createdAt;
  final bool isDark;
  const _TimestampRow({required this.createdAt, required this.isDark});

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final local = dt.toLocal();
    final diff = now.difference(local);
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final day = weekdays[local.weekday - 1];
    final h = local.hour;
    final m = local.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final dh = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    final t = '$dh:$m $period';
    if (diff.inDays < 7) return '$day · $t';
    return '${local.day}/${local.month}/${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.schedule_rounded,
          size: 13,
          color: isDark ? const Color(0xFF4A6080) : _Palette.lightMuted,
        ),
        const SizedBox(width: 5),
        Text(
          _formatTime(createdAt.toLocal()),
          style: _TextStyles.timestamp(isDark),
        ),
        const SizedBox(width: 10),
        Container(
          width: 3,
          height: 3,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF3A4A62) : _Palette.lightBorder,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          timeago.format(createdAt.toLocal()),
          style: _TextStyles.timestamp(isDark),
        ),
      ],
    );
  }
}

// ─── Shimmer Card ─────────────────────────────────────────────────────────────

class _ShimmerCard extends StatelessWidget {
  final Animation<double> animation;
  final bool isDark;
  final int index;

  const _ShimmerCard(
      {required this.animation, required this.isDark, required this.index});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedBuilder(
        animation: animation,
        builder: (_, __) {
          final shimmerColors = isDark
              ? [
                  Colors.white.withOpacity(0.04),
                  Colors.white.withOpacity(0.10),
                  Colors.white.withOpacity(0.04),
                ]
              : [
                  const Color(0xFFE8ECF4),
                  const Color(0xFFF4F6FB),
                  const Color(0xFFE8ECF4),
                ];

          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? _Palette.darkCard : _Palette.lightCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? _Palette.darkBorder : _Palette.lightBorder,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimmerBox(
                    isDark: isDark,
                    colors: shimmerColors,
                    width: 160 - (index % 3) * 20.0,
                    height: 16),
                const SizedBox(height: 12),
                _shimmerBox(
                    isDark: isDark,
                    colors: shimmerColors,
                    width: double.infinity,
                    height: 13),
                const SizedBox(height: 6),
                _shimmerBox(
                    isDark: isDark,
                    colors: shimmerColors,
                    width: double.infinity,
                    height: 13),
                const SizedBox(height: 6),
                _shimmerBox(
                    isDark: isDark,
                    colors: shimmerColors,
                    width: 220 - (index % 2) * 30.0,
                    height: 13),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _shimmerBox(
                        isDark: isDark,
                        colors: shimmerColors,
                        width: 68,
                        height: 26,
                        radius: 8),
                    const SizedBox(width: 8),
                    _shimmerBox(
                        isDark: isDark,
                        colors: shimmerColors,
                        width: 80,
                        height: 26,
                        radius: 8),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  height: 1,
                  color: isDark ? _Palette.darkBorder : _Palette.lightBorder,
                ),
                const SizedBox(height: 12),
                _shimmerBox(
                    isDark: isDark,
                    colors: shimmerColors,
                    width: 110,
                    height: 12,
                    radius: 6),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _shimmerBox({
    required bool isDark,
    required List<Color> colors,
    required double width,
    required double height,
    double radius = 6,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          colors: colors,
          stops: const [0.0, 0.5, 1.0],
          begin: Alignment(animation.value - 1, 0),
          end: Alignment(animation.value + 1, 0),
        ),
      ),
    );
  }
}

// ─── Data Model ───────────────────────────────────────────────────────────────

class NotificationItem {
  final String id;
  final String stockName;
  final String heading;
  final String description;
  final DateTime createdAt;
  final bool isRead;
  final List<String> stockData;

  NotificationItem({
    required this.id,
    required this.stockName,
    required this.heading,
    required this.description,
    required this.createdAt,
    required this.isRead,
    this.stockData = const [],
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'],
      stockName: json['stock_name'] ?? '',
      heading: json['heading'] ?? '',
      description: json['description'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      isRead: json['is_read'] ?? false,
      stockData: json['stock_data'] != null
          ? List<String>.from(json['stock_data'])
          : [],
    );
  }

  NotificationItem copyWith({
    String? id,
    String? stockName,
    String? heading,
    String? description,
    DateTime? createdAt,
    bool? isRead,
    List<String>? stockData,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      stockName: stockName ?? this.stockName,
      heading: heading ?? this.heading,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      stockData: stockData ?? this.stockData,
    );
  }
}
