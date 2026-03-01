import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:optionxi/Helpers/constants.dart';
import 'package:optionxi/Main_Pages/act_top_recommended_stock_page.dart';

class TrendingStocksSection extends StatefulWidget {
  const TrendingStocksSection({Key? key}) : super(key: key);

  @override
  State<TrendingStocksSection> createState() => _TrendingStocksSectionState();
}

class _TrendingStocksSectionState extends State<TrendingStocksSection>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  List<StockData> bullishStocks = [];
  List<StockData> bearishStocks = [];
  bool isLoading = true;
  String? error;

  StreamSubscription<User?>? _authSubscription;
  bool _isUserAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkAuthAndFetchData();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
  }

  void _checkAuthAndFetchData() {
    _authSubscription =
        FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        _isUserAuthenticated = true;
        if (mounted) _fetchTrendingStocks();
      } else {
        _isUserAuthenticated = false;
        if (mounted) {
          setState(() {
            error = 'Please log in to view trending stocks';
            isLoading = false;
          });
        }
      }
    });
  }

  Future<void> _fetchTrendingStocks() async {
    if (!_isUserAuthenticated || FirebaseAuth.instance.currentUser == null) {
      setState(() {
        error = 'User not authenticated';
        isLoading = false;
      });
      return;
    }

    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final DatabaseReference ref =
          FirebaseDatabase.instance.ref('trending_stocks');
      final DataSnapshot snapshot = await ref.get();

      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final aiRecommendedStocks =
            data['ai_recommended_stocks'] as Map<dynamic, dynamic>?;

        if (aiRecommendedStocks != null) {
          final bullishPositions =
              aiRecommendedStocks['bullish_long_positions'] as List<dynamic>?;
          final bearishPositions =
              aiRecommendedStocks['bearish_short_positions'] as List<dynamic>?;

          if (mounted) {
            final parsedBullish = bullishPositions
                    ?.map((stock) => StockData.fromRealtimeDatabase(
                        stock as Map<dynamic, dynamic>))
                    .toList() ??
                [];
            final parsedBearish = bearishPositions
                    ?.map((stock) => StockData.fromRealtimeDatabase(
                        stock as Map<dynamic, dynamic>))
                    .toList() ??
                [];

            // Sort by highest absolute percent change
            parsedBullish.sort((a, b) => b.pcnt.abs().compareTo(a.pcnt.abs()));
            parsedBearish.sort((a, b) => b.pcnt.abs().compareTo(a.pcnt.abs()));

            setState(() {
              bullishStocks = parsedBullish;
              bearishStocks = parsedBearish;
              isLoading = false;
            });

            _fadeController.forward();
          }
        } else {
          if (mounted) setState(() => isLoading = false);
        }
      } else {
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = 'Failed to load trending stocks';
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return _buildSkeleton();
    if (error != null) return _buildErrorWidget();

    final hasBullish = bullishStocks.isNotEmpty;
    final hasBearish = bearishStocks.isNotEmpty;

    if (!hasBullish && !hasBearish) {
      return const _EmptyState();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context),
          const SizedBox(height: 20),
          if (hasBullish) ...[
            _buildSectionLabel(context, isBullish: true),
            const SizedBox(height: 10),
            ...bullishStocks.asMap().entries.map(
                  (e) => _AnimatedStockCard(
                    key: ValueKey('bull_${e.value.symbol}'),
                    stock: e.value,
                    isBullish: true,
                    delay: Duration(milliseconds: e.key * 60),
                  ),
                ),
          ],
          if (hasBullish && hasBearish) const SizedBox(height: 20),
          if (hasBearish) ...[
            _buildSectionLabel(context, isBullish: false),
            const SizedBox(height: 10),
            ...bearishStocks.asMap().entries.map(
                  (e) => _AnimatedStockCard(
                    key: ValueKey('bear_${e.value.symbol}'),
                    stock: e.value,
                    isBullish: false,
                    delay: Duration(
                        milliseconds:
                            (hasBullish ? bullishStocks.length : 0) * 60 +
                                e.key * 60),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, {required bool isBullish}) {
    final theme = Theme.of(context);
    final color = isBullish ? const Color(0xFF00C896) : const Color(0xFFFF5B6B);
    final bgColor = color.withOpacity(0.08);
    final icon =
        isBullish ? Icons.trending_up_rounded : Icons.trending_down_rounded;
    final label = isBullish ? 'Bullish Picks' : 'Bearish Picks';
    final count = isBullish ? bullishStocks.length : bearishStocks.length;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.25), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trending Stocks',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'AI-powered technical analysis',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TopRecommendedStockPage()),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.3),
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'View All',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 10,
                  color: theme.colorScheme.onSurface.withOpacity(0.6)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(context),
        const SizedBox(height: 20),
        _SkeletonLoader(width: 120, height: 28, radius: 20),
        const SizedBox(height: 10),
        const _SkeletonCard(),
        const SizedBox(height: 8),
        const _SkeletonCard(),
        const SizedBox(height: 20),
        _SkeletonLoader(width: 120, height: 28, radius: 20),
        const SizedBox(height: 10),
        const _SkeletonCard(),
      ],
    );
  }

  Widget _buildErrorWidget() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: theme.colorScheme.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.wifi_off_rounded,
                size: 26, color: theme.colorScheme.error),
          ),
          const SizedBox(height: 14),
          Text(
            error!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              setState(() {
                isLoading = true;
                error = null;
              });
              _checkAuthAndFetchData();
            },
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// ─── Animated Stock Card ────────────────────────────────────────────────────

class _AnimatedStockCard extends StatefulWidget {
  final StockData stock;
  final bool isBullish;
  final Duration delay;

  const _AnimatedStockCard({
    Key? key,
    required this.stock,
    required this.isBullish,
    required this.delay,
  }) : super(key: key);

  @override
  State<_AnimatedStockCard> createState() => _AnimatedStockCardState();
}

class _AnimatedStockCardState extends State<_AnimatedStockCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _slide = Tween<double>(begin: 24, end: 0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

    Future.delayed(widget.delay, () {
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
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _slide.value),
        child: Opacity(opacity: _fade.value, child: child),
      ),
      child: _StockCard(stock: widget.stock, isBullish: widget.isBullish),
    );
  }
}

// ─── Stock Card ─────────────────────────────────────────────────────────────

class _StockCard extends StatelessWidget {
  final StockData stock;
  final bool isBullish;

  const _StockCard({required this.stock, required this.isBullish});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor =
        isBullish ? const Color(0xFF00C896) : const Color(0xFFFF5B6B);
    final cleanSymbol = stock.symbol
        .replaceAll('-EQ', '')
        .replaceAll('-BZ', '')
        .replaceAll('NSE:', '');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => TopRecommendedStockPage(stock: stock)),
          ),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? theme.colorScheme.surface.withOpacity(0.9)
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.black.withOpacity(0.06),
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.25)
                      : Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  // Left accent bar
                  Container(
                    width: 3,
                    height: 42,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Logo
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: isDark
                          ? Colors.white.withOpacity(0.06)
                          : Colors.grey.shade100,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: CachedNetworkImage(
                      imageUrl: "${Constants.OptionXiS3Loc}$cleanSymbol.png",
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          _StockLogoFallback(symbol: cleanSymbol),
                      errorWidget: (_, __, ___) =>
                          _StockLogoFallback(symbol: cleanSymbol),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Name + sector
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cleanSymbol,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (stock.sector != 'N/A') ...[
                          const SizedBox(height: 2),
                          Text(
                            stock.sector,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.45),
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Signal strength badge
                  if (stock.signalStrength.isNotEmpty)
                    _SignalBadge(strength: stock.signalStrength),

                  const SizedBox(width: 10),

                  // Price + percent
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${stock.price.toStringAsFixed(2)}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      _PctBadge(pcnt: stock.pcnt, color: accentColor),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _StockLogoFallback extends StatelessWidget {
  final String symbol;
  const _StockLogoFallback({required this.symbol});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Text(
        symbol.isNotEmpty ? symbol[0] : '?',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 16,
          color: theme.colorScheme.onSurface.withOpacity(0.5),
        ),
      ),
    );
  }
}

class _PctBadge extends StatelessWidget {
  final double pcnt;
  final Color color;
  const _PctBadge({required this.pcnt, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${pcnt >= 0 ? '+' : ''}${pcnt.toStringAsFixed(2)}%',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _SignalBadge extends StatelessWidget {
  final String strength;
  const _SignalBadge({required this.strength});

  static Color _colorFor(String s) {
    switch (s.toLowerCase()) {
      case 'strong':
        return const Color(0xFF00C896);
      case 'weak':
        return const Color(0xFFFF8C42);
      default:
        return const Color(0xFF5B8CFF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(strength);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        strength,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.bar_chart_rounded,
                size: 40, color: theme.colorScheme.onSurface.withOpacity(0.2)),
            const SizedBox(height: 10),
            Text(
              'No trending stocks right now',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Skeleton ────────────────────────────────────────────────────────────────

class _SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final double radius;
  const _SkeletonLoader(
      {required this.width, required this.height, this.radius = 8});

  @override
  State<_SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<_SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 0.9)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black)
              .withOpacity(0.07 * _anim.value * 1.5),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.04)
              : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05),
          ),
        ),
        child: Row(
          children: [
            _SkeletonLoader(width: 3, height: 42, radius: 99),
            const SizedBox(width: 12),
            _SkeletonLoader(width: 40, height: 40, radius: 10),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkeletonLoader(width: 90, height: 14),
                  const SizedBox(height: 6),
                  _SkeletonLoader(width: 120, height: 11),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _SkeletonLoader(width: 64, height: 14),
                const SizedBox(height: 5),
                _SkeletonLoader(width: 50, height: 22, radius: 6),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── StockData Model ─────────────────────────────────────────────────────────

class StockData {
  final String symbol;
  final double price;
  final double pcnt;
  final String sentiment;
  final String sector;
  final String riskLevel;
  final String signalStrength;
  final List<String> dataChecked;
  final String shortDescription;
  final String alertTime;
  final String longDescription;
  final String aiRationale;
  final String positionType;
  final String alertType;
  final int signalCount;

  StockData({
    required this.symbol,
    required this.price,
    required this.pcnt,
    required this.sentiment,
    required this.sector,
    required this.riskLevel,
    required this.signalStrength,
    required this.dataChecked,
    required this.shortDescription,
    this.alertTime = '',
    this.longDescription = '',
    this.aiRationale = '',
    this.positionType = '',
    this.alertType = '',
    this.signalCount = 0,
  });

  factory StockData.fromRealtimeDatabase(Map<dynamic, dynamic> data) {
    return StockData(
      symbol: data['symbol']?.toString() ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      pcnt: (data['pcnt'] ?? 0.0).toDouble(),
      sentiment: data['sentiment']?.toString() ?? 'BULL',
      sector: data['sector']?.toString() ?? 'N/A',
      riskLevel: data['risk_level']?.toString() ?? 'Medium',
      signalStrength: data['signal_strength']?.toString() ?? 'Medium',
      dataChecked: data['data_checked'] != null
          ? List<String>.from(data['data_checked'])
          : [],
      shortDescription: data['short_description']?.toString() ?? '',
      alertTime: data['alert_time']?.toString() ?? '',
      longDescription: data['long_description']?.toString() ?? '',
      aiRationale: data['ai_rationale']?.toString() ?? '',
      positionType: data['position_type']?.toString() ?? '',
      alertType: data['alert_type']?.toString() ?? '',
      signalCount: data['signal_count'] ?? 0,
    );
  }
}
