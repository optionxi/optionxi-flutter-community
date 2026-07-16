import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:optionxi/Helpers/constants.dart';

// ─── Data Model ────────────────────────────────────────────────────────────────

class StockData {
  final String stckname;
  final double pcnt;
  final double close;
  final double high;
  final double low;
  final double open;
  final int vol;
  final String? sector;
  final double? rsi14;
  final double? ema20;
  final double? sma20;

  const StockData({
    required this.stckname,
    required this.pcnt,
    required this.close,
    required this.high,
    required this.low,
    required this.open,
    required this.vol,
    this.sector,
    this.rsi14,
    this.ema20,
    this.sma20,
  });

  factory StockData.fromJson(Map<String, dynamic> json) => StockData(
        stckname: json['stckname'] as String,
        pcnt: (json['pcnt'] as num).toDouble(),
        close: (json['close'] as num).toDouble(),
        high: (json['high'] as num).toDouble(),
        low: (json['low'] as num).toDouble(),
        open: (json['open'] as num).toDouble(),
        vol: json['vol'] as int,
        sector: json['sec'] as String?,
        rsi14: json['rsi14'] != null ? (json['rsi14'] as num).toDouble() : null,
        ema20: json['ema20'] != null ? (json['ema20'] as num).toDouble() : null,
        sma20: json['sma20'] != null ? (json['sma20'] as num).toDouble() : null,
      );

  String get ticker {
    final parts = stckname.split('-')[0].split(':');
    return parts.length > 1 ? parts[1] : stckname;
  }
}

// ─── Design Tokens ─────────────────────────────────────────────────────────────

abstract class _DT {
  // Light
  static const lightBg = Color(0xFFF7F8FA);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceElevated = Color(0xFFF0F2F5);
  static const lightBorder = Color(0xFFE4E8EF);
  static const lightTextPrimary = Color(0xFF0D1117);
  static const lightTextSecondary = Color(0xFF6B7280);
  static const lightTextTertiary = Color(0xFF9CA3AF);

  // Dark
  static const darkBg = Color(0xFF0A0C0F);
  static const darkSurface = Color(0xFF111318);
  static const darkSurfaceElevated = Color(0xFF181C22);
  static const darkBorder = Color(0xFF1F2430);
  static const darkTextPrimary = Color(0xFFE8ECF4);
  static const darkTextSecondary = Color(0xFF8892A4);
  static const darkTextTertiary = Color(0xFF4B5567);

  // Accent — same in both modes, tuned per brightness
  static const gainDark = Color(0xFF00D4A0);
  static const gainLight = Color(0xFF00A878);
  static const lossDark = Color(0xFFFF4D6A);
  static const lossLight = Color(0xFFE0243E);

  // Geometry
  static const radius = 14.0;
}

// ─── Main Page ─────────────────────────────────────────────────────────────────

class SectorStocksPage extends StatefulWidget {
  final String sectorName;
  final List<StockData> stocks;

  const SectorStocksPage({
    Key? key,
    required this.sectorName,
    required this.stocks,
  }) : super(key: key);

  @override
  State<SectorStocksPage> createState() => _SectorStocksPageState();
}

class _SectorStocksPageState extends State<SectorStocksPage>
    with SingleTickerProviderStateMixin {
  late final List<StockData> _sorted;
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _sorted = [...widget.stocks]..sort((a, b) => b.pcnt.compareTo(a.pcnt));
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = isDark ? _DT.darkBg : _DT.lightBg;
    final textPrimary = isDark ? _DT.darkTextPrimary : _DT.lightTextPrimary;
    final textSecondary =
        isDark ? _DT.darkTextSecondary : _DT.lightTextSecondary;

    // Sector summary stats
    final gainers = _sorted.where((s) => s.pcnt > 0).length;
    final losers = _sorted.where((s) => s.pcnt < 0).length;
    final avgChange = _sorted.isEmpty
        ? 0.0
        : _sorted.fold(0.0, (sum, s) => sum + s.pcnt) / _sorted.length;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bg,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _SectorAppBar(
              sectorName: widget.sectorName,
              isDark: isDark,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              gainers: gainers,
              losers: losers,
              avgChange: avgChange,
              totalStocks: _sorted.length,
            ),
            if (_sorted.isEmpty)
              SliverFillRemaining(
                child:
                    _EmptyState(isDark: isDark, textSecondary: textSecondary),
              )
            else
              SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, index) {
                      final delay = index * 0.05;
                      final start = delay.clamp(0.0, 0.8);
                      final end = (start + 0.4).clamp(0.0, 1.0);

                      final fadeAnim = CurvedAnimation(
                        parent: _ctrl,
                        curve: Interval(start, end, curve: Curves.easeOut),
                      );
                      final slideAnim = Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: _ctrl,
                        curve: Interval(start, end, curve: Curves.easeOutCubic),
                      ));

                      return FadeTransition(
                        opacity: fadeAnim,
                        child: SlideTransition(
                          position: slideAnim,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _StockCard(
                              stock: _sorted[index],
                              index: index,
                              isDark: isDark,
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: _sorted.length,
                  ),
                ),
              ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
          ],
        ),
      ),
    );
  }
}

// ─── Sliver App Bar ─────────────────────────────────────────────────────────────

class _SectorAppBar extends StatelessWidget {
  final String sectorName;
  final bool isDark;
  final Color textPrimary, textSecondary;
  final int gainers, losers, totalStocks;
  final double avgChange;

  const _SectorAppBar({
    required this.sectorName,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.gainers,
    required this.losers,
    required this.avgChange,
    required this.totalStocks,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? _DT.darkSurface : _DT.lightSurface;
    final border = isDark ? _DT.darkBorder : _DT.lightBorder;
    final gainColor = isDark ? _DT.gainDark : _DT.gainLight;
    final lossColor = isDark ? _DT.lossDark : _DT.lossLight;
    final avgPositive = avgChange >= 0;
    final avgColor = avgPositive ? gainColor : lossColor;

    return SliverToBoxAdapter(
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          border: Border(
            bottom: BorderSide(color: border, width: 1),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nav row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_new_rounded,
                          color: textSecondary, size: 18),
                      onPressed: () => Get.back(),
                      splashRadius: 20,
                    ),
                    const Spacer(),
                    _PillTag(
                      label: '$totalStocks stocks',
                      isDark: isDark,
                    ),
                  ],
                ),
              ),

              // Sector name + avg
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sectorName,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          avgPositive
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          color: avgColor,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Avg ${avgPositive ? '+' : ''}${avgChange.toStringAsFixed(2)}% today',
                          style: TextStyle(
                            color: avgColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Stats strip
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    _StatChip(
                      label: 'Gainers',
                      value: '$gainers',
                      color: gainColor,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 10),
                    _StatChip(
                      label: 'Losers',
                      value: '$losers',
                      color: lossColor,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 10),
                    _StatChip(
                      label: 'Flat',
                      value: '${totalStocks - gainers - losers}',
                      color: textSecondary,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Stock Card ─────────────────────────────────────────────────────────────────

class _StockCard extends StatelessWidget {
  final StockData stock;
  final int index;
  final bool isDark;

  const _StockCard({
    required this.stock,
    required this.index,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = stock.pcnt > 0;
    final isNeutral = stock.pcnt == 0;

    final surface = isDark ? _DT.darkSurface : _DT.lightSurface;
    final border = isDark ? _DT.darkBorder : _DT.lightBorder;
    final textPrimary = isDark ? _DT.darkTextPrimary : _DT.lightTextPrimary;
    final textSecondary =
        isDark ? _DT.darkTextSecondary : _DT.lightTextSecondary;
    final textTertiary = isDark ? _DT.darkTextTertiary : _DT.lightTextTertiary;

    final gainColor = isDark ? _DT.gainDark : _DT.gainLight;
    final lossColor = isDark ? _DT.lossDark : _DT.lossLight;
    final perfColor = isNeutral
        ? textSecondary
        : isPositive
            ? gainColor
            : lossColor;

    // Rank badge for top 3
    final showRank = index < 3 && isPositive;

    final prevClose = stock.close / (1 + stock.pcnt / 100);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          Get.toNamed('/stocks/${stock.stckname.toUpperCase()}');
        },
        borderRadius: BorderRadius.circular(_DT.radius),
        child: Ink(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(_DT.radius),
            border: Border.all(color: border, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Avatar
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _StockAvatar(stock: stock, isDark: isDark),
                    if (showRank)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: _RankBadge(rank: index + 1, isDark: isDark),
                      ),
                  ],
                ),

                const SizedBox(width: 14),

                // Info column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ticker + volume
                      Row(
                        children: [
                          Text(
                            stock.ticker,
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '${isPositive ? '+' : ''}${(stock.close - prevClose).toStringAsFixed(2)}',
                              style: TextStyle(
                                color: perfColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // H/L bar
                      _HLBar(
                        high: stock.high,
                        low: stock.low,
                        close: stock.close,
                        isDark: isDark,
                        gainColor: gainColor,
                        lossColor: lossColor,
                        textTertiary: textTertiary,
                        prevClose: prevClose,
                        volume: _formatVol(stock.vol), // pass vol as string
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Price column
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${_fmt(stock.close)}',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    _ChangeBadge(
                      pcnt: stock.pcnt,
                      color: perfColor,
                      isPositive: isPositive,
                      isNeutral: isNeutral,
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

  static String _fmt(double v) {
    if (v >= 1000) {
      return v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 1);
    }
    return v.toStringAsFixed(2);
  }

  static String _formatVol(int vol) {
    if (vol >= 10000000) return '${(vol / 10000000).toStringAsFixed(1)}Cr';
    if (vol >= 100000) return '${(vol / 100000).toStringAsFixed(1)}L';
    if (vol >= 1000) return '${(vol / 1000).toStringAsFixed(1)}K';
    return '$vol';
  }
}

// ─── Sub-widgets ────────────────────────────────────────────────────────────────

class _StockAvatar extends StatelessWidget {
  final StockData stock;
  final bool isDark;

  const _StockAvatar({required this.stock, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final elevated =
        isDark ? _DT.darkSurfaceElevated : _DT.lightSurfaceElevated;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 46,
        height: 46,
        color: elevated,
        child: CachedNetworkImage(
          imageUrl: Constants.OptionXiS3Loc + stock.ticker + '.png',
          width: 46,
          height: 46,
          fit: BoxFit.cover,
          placeholder: (_, __) =>
              _AvatarPlaceholder(ticker: stock.ticker, isDark: isDark),
          errorWidget: (_, __, ___) =>
              _AvatarPlaceholder(ticker: stock.ticker, isDark: isDark),
        ),
      ),
    );
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  final String ticker;
  final bool isDark;

  const _AvatarPlaceholder({required this.ticker, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? _DT.darkSurfaceElevated : _DT.lightSurfaceElevated;
    final textColor = isDark ? _DT.darkTextSecondary : _DT.lightTextSecondary;
    return Container(
      width: 46,
      height: 46,
      color: bg,
      alignment: Alignment.center,
      child: Text(
        ticker.isNotEmpty ? ticker[0] : '?',
        style: TextStyle(
          color: textColor,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _HLBar extends StatelessWidget {
  final double high, low, close, prevClose;
  final bool isDark;
  final Color gainColor, lossColor, textTertiary;
  final String volume;

  const _HLBar({
    required this.high,
    required this.low,
    required this.close,
    required this.prevClose,
    required this.isDark,
    required this.gainColor,
    required this.lossColor,
    required this.textTertiary,
    required this.volume,
  });

  @override
  Widget build(BuildContext context) {
    final range = high - low;
    final t = range > 0 ? ((close - low) / range).clamp(0.0, 1.0) : 0.5;
    final barColor = Color.lerp(lossColor, gainColor, t)!;
    final trackColor = isDark ? _DT.darkBorder : _DT.lightBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(builder: (ctx, constraints) {
          final totalWidth = constraints.maxWidth;
          return ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(height: 4, width: totalWidth, color: trackColor),
                Container(height: 4, width: totalWidth * t, color: barColor),
              ],
            ),
          );
        }),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'L',
              style: TextStyle(
                color: textTertiary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              volume,
              style: TextStyle(
                color: textTertiary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'H',
              style: TextStyle(
                color: textTertiary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _ChangeBadge extends StatelessWidget {
  final double pcnt;
  final Color color;
  final bool isPositive, isNeutral;

  const _ChangeBadge({
    required this.pcnt,
    required this.color,
    required this.isPositive,
    required this.isNeutral,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${isPositive ? '+' : ''}${pcnt.toStringAsFixed(2)}%',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;
  final bool isDark;

  const _RankBadge({required this.rank, required this.isDark});

  static const _colors = [
    Color(0xFFFFD700), // gold
    Color(0xFFB0B8C1), // silver
    Color(0xFFCD7F32), // bronze
  ];

  @override
  Widget build(BuildContext context) {
    final color = _colors[rank - 1];
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? _DT.darkSurface : _DT.lightSurface,
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        '$rank',
        style: const TextStyle(
          color: Colors.black,
          fontSize: 8,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label, value;
  final Color color;
  final bool isDark;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? _DT.darkSurfaceElevated : _DT.lightSurfaceElevated;
    final border = isDark ? _DT.darkBorder : _DT.lightBorder;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: isDark ? _DT.darkTextTertiary : _DT.lightTextTertiary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PillTag extends StatelessWidget {
  final String label;
  final bool isDark;

  const _PillTag({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? _DT.darkSurfaceElevated : _DT.lightSurfaceElevated;
    final textColor = isDark ? _DT.darkTextSecondary : _DT.lightTextSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  final Color textSecondary;

  const _EmptyState({required this.isDark, required this.textSecondary});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 52,
            color: textSecondary.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No stocks in this sector',
            style: TextStyle(
              color: textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
