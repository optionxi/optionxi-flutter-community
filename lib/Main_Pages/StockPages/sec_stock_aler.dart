import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

// ─────────────────────────────────────────────
// Data Model
// ─────────────────────────────────────────────
class AlertModel {
  final int id;
  final String date;
  final String description;
  final String createdAt;
  final String updatedAt;
  final String? symbol;
  final String? sentiment;
  final double? close;
  final double? prevClose;
  final double? pcnt;
  final double? high;
  final double? low;
  final double? week52High;
  final double? week52Low;
  final double? prevDayLow;
  final double? prevDayHigh;
  final double? volume;
  final double? sma5Volume;
  final double? open;

  AlertModel({
    required this.id,
    required this.date,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    this.symbol,
    this.sentiment,
    this.close,
    this.prevClose,
    this.pcnt,
    this.high,
    this.low,
    this.week52High,
    this.week52Low,
    this.prevDayLow,
    this.prevDayHigh,
    this.volume,
    this.sma5Volume,
    this.open,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'] ?? 0,
      date: json['date'] ?? '',
      description: json['description'] ?? '',
      createdAt: json['created_at'] ?? DateTime.now().toIso8601String(),
      updatedAt: json['updated_at'] ?? DateTime.now().toIso8601String(),
      symbol: json['symbol'],
      sentiment: json['sentiment'],
      close: json['close']?.toDouble(),
      prevClose: json['prev_close']?.toDouble(),
      pcnt: json['pcnt']?.toDouble(),
      high: json['high']?.toDouble(),
      low: json['low']?.toDouble(),
      week52High: json['week_52_high']?.toDouble(),
      week52Low: json['week_52_low']?.toDouble(),
      prevDayLow: json['prev_day_low']?.toDouble(),
      prevDayHigh: json['prev_day_high']?.toDouble(),
      volume: json['volume']?.toDouble(),
      sma5Volume: json['sma5_volume']?.toDouble(),
      open: json['open']?.toDouble(),
    );
  }

  String get cleanSymbol => (symbol ?? '')
      .replaceAll('NSE:', '')
      .replaceAll('-EQ', '')
      .replaceAll('-BE', '')
      .replaceAll('-BZ', '');
}

// ─────────────────────────────────────────────
// Supabase Service
// ─────────────────────────────────────────────
class AlertsService {
  static final _supabase = Supabase.instance.client;

  static Future<Map<String, dynamic>> getAlertsBySymbol(
    String symbol, {
    int page = 1,
    int pageSize = 30,
  }) async {
    try {
      final from = (page - 1) * pageSize;
      final to = from + pageSize - 1;

      final response = await _supabase
          .from('live_scanner')
          .select('*')
          .eq('symbol', symbol.toUpperCase().split('-')[0].split(':')[1])
          .order('created_at', ascending: false)
          .range(from, to);

      final List<AlertModel> alerts = (response as List)
          .map((item) => AlertModel.fromJson(item as Map<String, dynamic>))
          .toList();

      return {
        'data': alerts,
        'count': response.length,
        'page': page,
        'pageSize': pageSize,
      };
    } catch (error) {
      throw Exception('Error fetching alerts for $symbol: $error');
    }
  }
}

// ─────────────────────────────────────────────
// Adaptive Color Tokens
// Resolves all colors from the current theme brightness.
// Pass _T.of(context) into any widget that needs adaptive colors.
// ─────────────────────────────────────────────
class _T {
  final bool dark;
  const _T(this.dark);

  factory _T.of(BuildContext context) =>
      _T(Theme.of(context).brightness == Brightness.dark);

  // Surfaces
  Color get surface => dark ? const Color(0xFF181B24) : Colors.white;
  Color get surfaceElevated =>
      dark ? const Color(0xFF1E222D) : const Color(0xFFF5F7FA);
  Color get border => dark ? const Color(0xFF262B38) : const Color(0xFFE4E8F0);

  // Text
  Color get textPrimary =>
      dark ? const Color(0xFFEDF0F7) : const Color(0xFF111827);
  Color get textSecondary =>
      dark ? const Color(0xFF8A91A8) : const Color(0xFF52586B);
  Color get textMuted =>
      dark ? const Color(0xFF505670) : const Color(0xFFAAB0C4);

  // Accent (for retry button etc.)
  Color get accent => dark ? const Color(0xFF6366F1) : const Color(0xFF4F52D9);
  Color get accentBg =>
      dark ? const Color(0xFF1A1B3A) : const Color(0xFFEEEFFF);
  Color get accentBorder =>
      dark ? const Color(0xFF4244A0) : const Color(0xFFC7C8F5);

  // Bullish
  Color get bullishFg =>
      dark ? const Color(0xFF34D399) : const Color(0xFF059669);
  Color get bullishBg =>
      dark ? const Color(0xFF0D2B20) : const Color(0xFFF0FDF6);
  Color get bullishBorder =>
      dark ? const Color(0xFF1A4535) : const Color(0xFFBBF7D0);
  Color get bullishTag =>
      dark ? const Color(0xFF0E3328) : const Color(0xFFDCFCEE);

  // Bearish
  Color get bearishFg =>
      dark ? const Color(0xFFF87171) : const Color(0xFFDC2626);
  Color get bearishBg =>
      dark ? const Color(0xFF2B0D0D) : const Color(0xFFFFF5F5);
  Color get bearishBorder =>
      dark ? const Color(0xFF4A1A1A) : const Color(0xFFFECACA);
  Color get bearishTag =>
      dark ? const Color(0xFF331111) : const Color(0xFFFFE4E4);

  // Neutral sentiment
  Color get neutralFg =>
      dark ? const Color(0xFF8A91A8) : const Color(0xFF52586B);
  Color get neutralBg =>
      dark ? const Color(0xFF181B24) : const Color(0xFFF9FAFB);
  Color get neutralBorder =>
      dark ? const Color(0xFF262B38) : const Color(0xFFE4E8F0);
  Color get neutralTag =>
      dark ? const Color(0xFF1E222D) : const Color(0xFFF3F4F6);

  // Shimmer
  Color get shimmerBase =>
      dark ? const Color(0xFF1E222D) : const Color(0xFFEDF0F7);
  Color get shimmerHighlight =>
      dark ? const Color(0xFF2A2F40) : const Color(0xFFDDE2EE);

  // Elevation shadows
  List<BoxShadow> get cardShadow => dark
      ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ]
      : [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ];
}

// ─────────────────────────────────────────────
// Sentiment Config
// ─────────────────────────────────────────────
class _SentimentConfig {
  final Color fg;
  final Color bg;
  final Color border;
  final Color tag;
  final IconData icon;

  const _SentimentConfig({
    required this.fg,
    required this.bg,
    required this.border,
    required this.tag,
    required this.icon,
  });
}

_SentimentConfig _resolveSentiment(String? sentiment, _T t) {
  switch (sentiment?.toLowerCase()) {
    case 'bullish':
      return _SentimentConfig(
        fg: t.bullishFg,
        bg: t.bullishBg,
        border: t.bullishBorder,
        tag: t.bullishTag,
        icon: Icons.trending_up_rounded,
      );
    case 'bearish':
      return _SentimentConfig(
        fg: t.bearishFg,
        bg: t.bearishBg,
        border: t.bearishBorder,
        tag: t.bearishTag,
        icon: Icons.trending_down_rounded,
      );
    default:
      return _SentimentConfig(
        fg: t.neutralFg,
        bg: t.neutralBg,
        border: t.neutralBorder,
        tag: t.neutralTag,
        icon: Icons.trending_flat_rounded,
      );
  }
}

// ─────────────────────────────────────────────
// Shimmer Box Primitive
// Uses animated gradient stops instead of a GradientTransform to avoid
// the abstract class override incompatibility.
// ─────────────────────────────────────────────
class _ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  final Animation<double> anim;
  final _T t;

  const _ShimmerBox({
    required this.width,
    required this.height,
    required this.radius,
    required this.anim,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) {
        // Slide stops across [0,1] so the highlight sweeps left-to-right.
        final v = anim.value; // 0 → 1
        final s0 = (v - 0.4).clamp(0.0, 1.0);
        final s1 = v.clamp(0.0, 1.0);
        final s2 = (v + 0.4).clamp(0.0, 1.0);
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [s0, s1, s2],
              colors: [t.shimmerBase, t.shimmerHighlight, t.shimmerBase],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Shimmer Loader
// ─────────────────────────────────────────────
class StockAlertsShimmerLoader extends StatefulWidget {
  const StockAlertsShimmerLoader({Key? key}) : super(key: key);

  @override
  State<StockAlertsShimmerLoader> createState() =>
      _StockAlertsShimmerLoaderState();
}

class _StockAlertsShimmerLoaderState extends State<StockAlertsShimmerLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat();
    _anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _T.of(context);
    return Column(
      children: List.generate(3, (_) => _buildCard(t)),
    );
  }

  Widget _buildCard(_T t) {
    s(double w, double h, double r) =>
        _ShimmerBox(width: w, height: h, radius: r, anim: _anim, t: t);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.border),
        boxShadow: t.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          s(42, 42, 10),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [s(72, 14, 4), s(56, 18, 4)],
                ),
                const SizedBox(height: 10),
                s(double.infinity, 12, 3),
                const SizedBox(height: 6),
                s(160, 12, 3),
                const SizedBox(height: 14),
                Row(children: [
                  s(60, 20, 6),
                  const SizedBox(width: 8),
                  s(80, 12, 3)
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Alert Card
// ─────────────────────────────────────────────
class StockAlertSingleItem extends StatelessWidget {
  final AlertModel alert;
  final int index;
  final DateTime alertDatetime;

  const StockAlertSingleItem({
    Key? key,
    required this.alert,
    required this.index,
    required this.alertDatetime,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final t = _T.of(context);
    final cfg = _resolveSentiment(alert.sentiment, t);

    final ltp = alert.close;
    final pct = alert.pcnt;
    final pctPositive = (pct ?? 0) >= 0;
    final pctText = pct != null
        ? '${pctPositive ? '+' : ''}${pct.toStringAsFixed(2)}%'
        : '--';
    final pctColor =
        pct == null ? t.textMuted : (pctPositive ? t.bullishFg : t.bearishFg);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: cfg.bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cfg.border),
        boxShadow: t.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Left accent bar
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 3,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      cfg.fg.withOpacity(0.9),
                      cfg.fg.withOpacity(0.25),
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 16, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row: symbol + LTP
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    alert.cleanSymbol,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: t.textPrimary,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    alert.description,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: t.textSecondary,
                                      height: 1.45,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),

                            // LTP block
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'LTP',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: t.textMuted,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  ltp != null
                                      ? NumberFormat('#,##,##0.00').format(ltp)
                                      : '--',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: t.textPrimary,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: pctColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    pctText,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: pctColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Bottom row: sentiment + time
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (alert.sentiment != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: cfg.tag,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: cfg.fg.withOpacity(0.25),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(cfg.icon, size: 11, color: cfg.fg),
                                    const SizedBox(width: 4),
                                    Text(
                                      alert.sentiment!.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        color: cfg.fg,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              const SizedBox.shrink(),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.schedule_rounded,
                                    size: 12, color: t.textMuted),
                                const SizedBox(width: 4),
                                Text(
                                  '${timeago.format(alertDatetime.toLocal())}  ·  '
                                  '${DateFormat('h:mm a').format(alertDatetime.toLocal())}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: t.textMuted,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
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
// Error State
// ─────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final t = _T.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: t.bearishBorder),
          boxShadow: t.cardShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: t.bearishBg,
                shape: BoxShape.circle,
                border: Border.all(color: t.bearishBorder),
              ),
              child: Icon(Icons.error_outline_rounded,
                  size: 24, color: t.bearishFg),
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load alerts',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: t.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Something went wrong. Please try again.',
              style: TextStyle(fontSize: 13, color: t.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: t.accentBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: t.accentBorder),
                ),
                child: Text(
                  'Try again',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: t.accent,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String symbol;
  const _EmptyState({required this.symbol});

  @override
  Widget build(BuildContext context) {
    final t = _T.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(36),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: t.border),
          boxShadow: t.cardShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: t.surfaceElevated,
                shape: BoxShape.circle,
                border: Border.all(color: t.border),
              ),
              child: Icon(Icons.notifications_none_rounded,
                  size: 28, color: t.textMuted),
            ),
            const SizedBox(height: 18),
            Text(
              'No alerts yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: t.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'No scanner alerts found for $symbol.',
              style: TextStyle(
                fontSize: 13,
                color: t.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Section Header
// ─────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final int count;
  final bool showCount;
  final VoidCallback onViewAll;

  const _SectionHeader({
    required this.count,
    required this.showCount,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final t = _T.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Stock Alerts',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: t.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              if (showCount) ...[
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: t.bearishFg.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: t.bearishFg.withOpacity(0.25)),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: t.bearishFg,
                    ),
                  ),
                ),
              ],
            ],
          ),
          GestureDetector(
            onTap: onViewAll,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: t.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: t.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View all',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: t.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.chevron_right_rounded,
                      size: 16, color: t.textMuted),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Main Widget
// ─────────────────────────────────────────────
class StockAlertsSectionSub extends StatefulWidget {
  final String symbol;

  const StockAlertsSectionSub({Key? key, required this.symbol})
      : super(key: key);

  @override
  State<StockAlertsSectionSub> createState() => _StockAlertsSectionSubState();
}

class _StockAlertsSectionSubState extends State<StockAlertsSectionSub> {
  List<AlertModel> alerts = [];
  bool loading = true;
  String? error;
  int totalCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchAlerts();
  }

  Future<void> _fetchAlerts() async {
    try {
      setState(() {
        loading = true;
        error = null;
      });

      final result = await AlertsService.getAlertsBySymbol(
        widget.symbol,
        page: 1,
        pageSize: 5,
      );

      setState(() {
        alerts = result['data'] as List<AlertModel>;
        totalCount = result['count'] as int;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  String get _routeSymbol =>
      widget.symbol.toUpperCase().split('-')[0].split(':')[1];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          count: totalCount,
          showCount: !loading && alerts.isNotEmpty,
          onViewAll: () =>
              Navigator.pushNamed(context, '/alerts/$_routeSymbol'),
        ),
        if (error != null)
          _ErrorState(onRetry: _fetchAlerts)
        else if (loading)
          const StockAlertsShimmerLoader()
        else if (alerts.isEmpty)
          _EmptyState(symbol: widget.symbol)
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final alert = alerts[index];
              return StockAlertSingleItem(
                alert: alert,
                index: index,
                alertDatetime: DateTime.parse(alert.createdAt),
              );
            },
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}
