import 'package:flutter/material.dart';
import 'package:optionxi/Main_Pages/Achivements/fastapi_achivement.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

// ─────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────
class Screener {
  final String id;
  final String name;
  final String timeframe;
  final int signalCount;
  final String lastUpdate;
  final String description;
  final List<String> criteria;
  final String category;

  Screener({
    required this.id,
    required this.name,
    required this.timeframe,
    required this.signalCount,
    required this.lastUpdate,
    required this.description,
    required this.criteria,
    required this.category,
  });

  factory Screener.fromJson(Map<String, dynamic> json) {
    return Screener(
      id: json['id'],
      name: json['name'],
      timeframe: json['timeframe'],
      signalCount: json['signal_count'],
      lastUpdate: json['last_update'],
      description: json['description'],
      criteria: List<String>.from(json['criteria']),
      category: json['category'],
    );
  }
}

// ─────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────
class ScreenerService {
  final SupabaseClient _supabase;
  ScreenerService(this._supabase);

  Future<List<Screener>> fetchScreeners(String category) async {
    final response = await _supabase
        .from('screener_names')
        .select()
        .eq('category', category)
        .order('timeframe', ascending: true)
        .order('created_at', ascending: false);

    if (response.isNotEmpty) {
      return response.map((json) => Screener.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load screeners');
    }
  }
}

// ─────────────────────────────────────────────
// Design Tokens
// ─────────────────────────────────────────────
class AppTokens {
  // Bullish palette
  static const Color bullishPrimary = Color(0xFF00C853);
  static const Color bullishSurface = Color(0xFF00C853);

  // Bearish palette
  static const Color bearishPrimary = Color(0xFFFF3D57);
  static const Color bearishSurface = Color(0xFFFF3D57);

  // Neutral
  static const Color accent = Color(0xFF6C63FF);

  static BorderRadius cardRadius = BorderRadius.circular(16);
  static BorderRadius chipRadius = BorderRadius.circular(100);
  static BorderRadius badgeRadius = BorderRadius.circular(8);

  static Duration fast = const Duration(milliseconds: 150);
  static Duration normal = const Duration(milliseconds: 280);
  static Duration slow = const Duration(milliseconds: 450);
}

// ─────────────────────────────────────────────
// Timeframe Badge
// ─────────────────────────────────────────────
class TimeframeBadge extends StatelessWidget {
  final String timeframe;
  const TimeframeBadge({Key? key, required this.timeframe}) : super(key: key);

  IconData get _icon {
    switch (timeframe.toLowerCase()) {
      case 'daily':
        return Icons.today_rounded;
      case 'weekly':
        return Icons.view_week_rounded;
      case 'monthly':
        return Icons.calendar_month_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }

  String get _label => '${timeframe[0].toUpperCase()}${timeframe.substring(1)}';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: AppTokens.badgeRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 14, color: cs.onSecondaryContainer),
          const SizedBox(width: 5),
          Text(
            _label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cs.onSecondaryContainer,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Signal Count Pill
// ─────────────────────────────────────────────
class SignalPill extends StatelessWidget {
  final int count;
  final bool bullish;
  const SignalPill({Key? key, required this.count, required this.bullish})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = bullish ? AppTokens.bullishPrimary : AppTokens.bearishPrimary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: AppTokens.chipRadius,
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$count stocks',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Scanner Card
// ─────────────────────────────────────────────
class ScannerCard extends StatefulWidget {
  final Screener screener;
  final String type;
  final bool defaultExpanded;
  final String category;

  const ScannerCard({
    Key? key,
    required this.screener,
    required this.type,
    this.defaultExpanded = false,
    required this.category,
  }) : super(key: key);

  @override
  State<ScannerCard> createState() => _ScannerCardState();
}

class _ScannerCardState extends State<ScannerCard>
    with SingleTickerProviderStateMixin {
  late bool _expanded;
  late AnimationController _expandCtrl;
  late Animation<double> _expandAnim;

  bool get _isBullish => widget.type == 'bullish';
  Color get _accentColor =>
      _isBullish ? AppTokens.bullishPrimary : AppTokens.bearishPrimary;

  @override
  void initState() {
    super.initState();
    _expanded = widget.defaultExpanded;
    _expandCtrl = AnimationController(
      vsync: this,
      duration: AppTokens.normal,
      value: _expanded ? 1.0 : 0.0,
    );
    _expandAnim = CurvedAnimation(
      parent: _expandCtrl,
      curve: Curves.easeInOut,
    );
  }

  @override
  void didUpdateWidget(ScannerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.defaultExpanded != widget.defaultExpanded) {
      setState(() => _expanded = widget.defaultExpanded);
      _expanded ? _expandCtrl.forward() : _expandCtrl.reverse();
    }
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _expandCtrl.forward() : _expandCtrl.reverse();
  }

  void _navigate() {
    Navigator.pushNamed(
      context,
      '/scanners/${widget.screener.name.toLowerCase().replaceAll(' ', '-')}',
      arguments: {'category': widget.category},
    );
  }

  @override
  void dispose() {
    _expandCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final timeAgo = timeago.format(DateTime.parse(widget.screener.lastUpdate));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? cs.surface : cs.surface,
        borderRadius: AppTokens.cardRadius,
        border: Border.all(
          color: isDark
              ? cs.outline.withOpacity(0.2)
              : cs.outline.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppTokens.cardRadius,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Accent top bar
            Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _accentColor.withOpacity(0.8),
                    _accentColor.withOpacity(0.2),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: title + expand button
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.screener.name,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                SignalPill(
                                  count: widget.screener.signalCount,
                                  bullish: _isBullish,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(
                                  Icons.schedule_rounded,
                                  size: 13,
                                  color: cs.onSurface.withOpacity(0.45),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$timeAgo',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: cs.onSurface.withOpacity(0.45),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Expand toggle
                      GestureDetector(
                        onTap: _toggle,
                        child: AnimatedContainer(
                          duration: AppTokens.fast,
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _expanded
                                ? _accentColor.withOpacity(0.12)
                                : cs.surfaceVariant,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _expanded
                                  ? _accentColor.withOpacity(0.3)
                                  : Colors.transparent,
                              width: 1,
                            ),
                          ),
                          child: AnimatedRotation(
                            turns: _expanded ? 0.5 : 0,
                            duration: AppTokens.normal,
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 20,
                              color: _expanded
                                  ? _accentColor
                                  : cs.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // CTA button
                  SizedBox(
                    width: double.infinity,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _navigate,
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: AppTokens.fast,
                          padding: const EdgeInsets.symmetric(
                              vertical: 11, horizontal: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _accentColor.withOpacity(0.9),
                                _accentColor.withOpacity(0.7),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isBullish
                                    ? Icons.trending_up_rounded
                                    : Icons.trending_down_rounded,
                                size: 17,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'View All Stocks',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Expand section
                  SizeTransition(
                    sizeFactor: _expandAnim,
                    child: FadeTransition(
                      opacity: _expandAnim,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          Divider(
                            color: cs.outline.withOpacity(0.15),
                            height: 1,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            widget.screener.description,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 13.5,
                              height: 1.6,
                              color: cs.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? cs.surfaceVariant.withOpacity(0.5)
                                  : cs.surfaceVariant.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: cs.outline.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.filter_list_rounded,
                                      size: 15,
                                      color: _accentColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Screening Criteria',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12.5,
                                        letterSpacing: 0.5,
                                        color: _accentColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                ...widget.screener.criteria
                                    .asMap()
                                    .entries
                                    .map((entry) => Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 7),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                margin: const EdgeInsets.only(
                                                    top: 6, right: 10),
                                                width: 5,
                                                height: 5,
                                                decoration: BoxDecoration(
                                                  color: _accentColor
                                                      .withOpacity(0.7),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  entry.value,
                                                  style: theme
                                                      .textTheme.bodySmall
                                                      ?.copyWith(
                                                    fontSize: 13,
                                                    height: 1.55,
                                                    color: cs.onSurface
                                                        .withOpacity(0.75),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ))
                                    .toList(),
                              ],
                            ),
                          ),
                        ],
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

// ─────────────────────────────────────────────
// Skeleton Card
// ─────────────────────────────────────────────
class ScannerCardSkeleton extends StatefulWidget {
  const ScannerCardSkeleton({Key? key}) : super(key: key);

  @override
  State<ScannerCardSkeleton> createState() => _ScannerCardSkeletonState();
}

class _ScannerCardSkeletonState extends State<ScannerCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimCtrl;
  late Animation<double> _shimAnim;

  @override
  void initState() {
    super.initState();
    _shimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _shimAnim = CurvedAnimation(parent: _shimCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _shimCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _shimAnim,
      builder: (context, child) {
        final shimColor = Color.lerp(
          cs.surfaceVariant,
          cs.surfaceVariant.withOpacity(0.5),
          _shimAnim.value,
        )!;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: AppTokens.cardRadius,
            border: Border.all(color: cs.outline.withOpacity(0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: AppTokens.cardRadius,
            child: Column(
              children: [
                Container(height: 3, color: shimColor),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _shimBox(shimColor, 160, 16),
                                const SizedBox(height: 12),
                                _shimBox(shimColor, 90, 28, radius: 100),
                                const SizedBox(height: 12),
                                _shimBox(shimColor, 120, 12),
                              ],
                            ),
                          ),
                          _shimBox(shimColor, 36, 36, radius: 10),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _shimBox(shimColor, double.infinity, 42, radius: 10),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _shimBox(Color color, double w, double h, {double radius = 6}) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Timeframe Section Header
// ─────────────────────────────────────────────
class TimeframeSectionHeader extends StatelessWidget {
  final String timeframe;
  final int count;
  const TimeframeSectionHeader(
      {Key? key, required this.timeframe, required this.count})
      : super(key: key);

  IconData get _icon {
    switch (timeframe.toLowerCase()) {
      case 'daily':
        return Icons.today_rounded;
      case 'weekly':
        return Icons.view_week_rounded;
      case 'monthly':
        return Icons.calendar_month_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(_icon, size: 15, color: cs.onPrimaryContainer),
          ),
          const SizedBox(width: 10),
          Text(
            '${timeframe[0].toUpperCase()}${timeframe.substring(1)} Screeners',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: cs.onPrimaryContainer,
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(left: 12),
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    cs.outline.withOpacity(0.2),
                    Colors.transparent,
                  ],
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
// Tab Indicator
// ─────────────────────────────────────────────
class _TabIndicator extends Decoration {
  final Color color;
  const _TabIndicator({required this.color});

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _TabIndicatorPainter(color: color);
}

class _TabIndicatorPainter extends BoxPainter {
  final Color color;
  const _TabIndicatorPainter({required this.color});

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration config) {
    final rect = offset & config.size!;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(10));
    canvas.drawRRect(rrect, Paint()..color = color);
  }
}

// ─────────────────────────────────────────────
// Main Screen
// ─────────────────────────────────────────────
class StockScreenerPage extends StatefulWidget {
  const StockScreenerPage({Key? key}) : super(key: key);

  @override
  State<StockScreenerPage> createState() => _StockScreenerPageState();
}

class _StockScreenerPageState extends State<StockScreenerPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'bullish';
  bool _loading = true;
  String? _error;
  List<Screener> _bullishScreeners = [];
  List<Screener> _bearishScreeners = [];

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  late final ScreenerService _screenerService;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() {
        if (!_tabController.indexIsChanging) {
          setState(() {
            _selectedCategory =
                _tabController.index == 0 ? 'bullish' : 'bearish';
          });
        }
      });

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: AppTokens.slow,
    )..forward();

    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(_fadeAnim);

    _screenerService = ScreenerService(Supabase.instance.client);
    _loadScreeners();
  }

  Future<void> _loadScreeners() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final results = await Future.wait([
        _screenerService.fetchScreeners('bullish'),
        _screenerService.fetchScreeners('bearish'),
      ]);

      if (mounted) {
        setState(() {
          _bullishScreeners = results[0];
          _bearishScreeners = results[1];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Map<String, List<Screener>> _groupByTimeframe(List<Screener> screeners) {
    final grouped = <String, List<Screener>>{};
    for (final s in screeners) {
      grouped.putIfAbsent(s.timeframe, () => []).add(s);
    }
    return grouped;
  }

  Widget _buildTimeframeSection(
      List<Screener>? screeners, String timeframe, String type) {
    if (screeners == null || screeners.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TimeframeSectionHeader(timeframe: timeframe, count: screeners.length),
        ...screeners.map((s) => ScannerCard(
              screener: s,
              type: type,
              category: _selectedCategory,
            )),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Back button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: cs.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: cs.outline.withOpacity(0.15),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      size: 18,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stock Screeners',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              // Refresh button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _loadScreeners,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: cs.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: cs.outline.withOpacity(0.15),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.refresh_rounded,
                      size: 18,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Text(
              'Discover stocks matching specific technical criteria.',
              style: TextStyle(
                fontSize: 13.5,
                color: cs.onSurface.withOpacity(0.5),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(isDark ? 0.6 : 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withOpacity(0.1), width: 1),
      ),
      padding: const EdgeInsets.all(4),
      child: TabBar(
        controller: _tabController,
        indicator: _TabIndicator(color: cs.surface),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        overlayColor: MaterialStateProperty.all(Colors.transparent),
        labelPadding: EdgeInsets.zero,
        tabs: [
          _buildTab(
            context,
            label: 'Bullish',
            icon: Icons.trending_up_rounded,
            color: AppTokens.bullishPrimary,
            selected: _selectedCategory == 'bullish',
          ),
          _buildTab(
            context,
            label: 'Bearish',
            icon: Icons.trending_down_rounded,
            color: AppTokens.bearishPrimary,
            selected: _selectedCategory == 'bearish',
          ),
        ],
      ),
    );
  }

  Widget _buildTab(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required bool selected,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Tab(
      child: AnimatedDefaultTextStyle(
        duration: AppTokens.fast,
        style: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          color: selected ? color : cs.onSurface.withOpacity(0.45),
          letterSpacing: 0.1,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? color : cs.onSurface.withOpacity(0.35),
            ),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(
    BuildContext context, {
    required List<Screener> screeners,
    required String type,
    required int skeletonCount,
  }) {
    final cs = Theme.of(context).colorScheme;

    if (_loading) {
      return ListView.builder(
        padding: const EdgeInsets.only(top: 4),
        itemCount: skeletonCount,
        itemBuilder: (_, __) => const ScannerCardSkeleton(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.errorContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.wifi_off_rounded,
                  size: 32, color: cs.onErrorContainer),
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load screeners',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _error!,
              style: TextStyle(
                color: cs.onSurface.withOpacity(0.5),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _loadScreeners,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final grouped = _groupByTimeframe(screeners);

    return ListView(
      padding: const EdgeInsets.only(top: 4, bottom: 24),
      children: [
        _buildTimeframeSection(grouped['daily'], 'daily', type),
        _buildTimeframeSection(grouped['weekly'], 'weekly', type),
        _buildTimeframeSection(grouped['monthly'], 'monthly', type),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    AchievementEvents.openedScreener();
    return Scaffold(
      backgroundColor: cs.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildTabBar(context),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTabContent(
                          context,
                          screeners: _bullishScreeners,
                          type: 'bullish',
                          skeletonCount: 5,
                        ),
                        _buildTabContent(
                          context,
                          screeners: _bearishScreeners,
                          type: 'bearish',
                          skeletonCount: 3,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }
}
