import 'dart:async';
import 'package:flutter/material.dart';
import 'package:optionxi/Main_Pages/act_full_index_page.dart';
import 'package:optionxi/Main_Pages/act_set_alert.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class IndicesGlance extends StatefulWidget {
  const IndicesGlance({super.key});

  @override
  State<IndicesGlance> createState() => _IndicesGlanceState();
}

class _IndicesGlanceState extends State<IndicesGlance>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> indices = [];
  bool loading = true;
  String? error;
  RealtimeChannel? _channel;

  // For infinite scroll
  late ScrollController _scrollController;
  Timer? _autoScrollTimer;
  bool _userInteracting = false;

  // Track flashing indices for price change animation
  final Map<String, AnimationController> _flashControllers = {};
  final Map<String, Color?> _lastColors = {};
  Map<String, double> _previousLtps = {};

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onUserScroll);
    fetchIndices();
    setupRealtimeSubscription();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.removeListener(_onUserScroll);
    _scrollController.dispose();
    for (final c in _flashControllers.values) {
      c.dispose();
    }
    _channel?.unsubscribe();
    super.dispose();
  }

  void _onUserScroll() {
    if (_scrollController.position.isScrollingNotifier.value) {
      _userInteracting = true;
      _autoScrollTimer?.cancel();
      // Resume auto-scroll after 3 seconds of inactivity
      _autoScrollTimer = Timer(const Duration(seconds: 3), () {
        _userInteracting = false;
        _startAutoScroll();
      });
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 30), (_) {
      if (_userInteracting) return;
      if (!_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      final current = _scrollController.offset;
      if (max <= 0) return;
      double next = current + 0.6;
      if (next >= max) next = 0;
      _scrollController.jumpTo(next);
    });
  }

  Future<void> fetchIndices() async {
    try {
      final data = await Supabase.instance.client
          .from('live_nifty_indices')
          .select('symbol, ltp, pcnt, l, h, pc')
          .inFilter('symbol',
              ['NIFTY50', 'NIFTYBANK', 'INDIAVIX', 'NIFTYIT', 'NIFTYMIDCAP50']);

      if (mounted) {
        final newList = List<Map<String, dynamic>>.from(data);

        for (final item in newList) {
          final sym = item['symbol'] as String;
          final newLtp = (item['ltp'] as num).toDouble();
          if (_previousLtps.containsKey(sym)) {
            final oldLtp = _previousLtps[sym]!;
            if (newLtp != oldLtp) {
              _triggerFlash(sym, newLtp > oldLtp);
            }
          }
          _previousLtps[sym] = newLtp;
        }

        setState(() {
          indices = newList;
          loading = false;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
          error = 'Failed to load indices';
        });
      }
    }
  }

  void _triggerFlash(String symbol, bool isUp) {
    _flashControllers[symbol]?.dispose();
    final ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _flashControllers[symbol] = ctrl;
    _lastColors[symbol] = isUp ? Colors.green : Colors.red;
    ctrl.forward().then((_) {
      if (mounted) setState(() => _lastColors[symbol] = null);
    });
    setState(() {});
  }

  void setupRealtimeSubscription() {
    _channel = Supabase.instance.client
        .channel('indices_updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'live_nifty_indices',
          callback: (payload) => fetchIndices(),
        )
        .subscribe();
  }

  String _getDisplayName(String symbol) {
    switch (symbol) {
      case 'NIFTY50':
        return 'NIFTY 50';
      case 'NIFTYBANK':
        return 'BANK NIFTY';
      case 'INDIAVIX':
        return 'INDIA VIX';
      case 'NIFTYIT':
        return 'NIFTY IT';
      case 'NIFTYMIDCAP50':
        return 'MIDCAP 50';
      default:
        return symbol;
    }
  }

  String _getShortName(String symbol) {
    switch (symbol) {
      case 'NIFTY50':
        return 'NF50';
      case 'NIFTYBANK':
        return 'BNKN';
      case 'INDIAVIX':
        return 'VIX';
      case 'NIFTYIT':
        return 'NFIT';
      case 'NIFTYMIDCAP50':
        return 'MC50';
      default:
        return symbol.substring(0, symbol.length.clamp(0, 4));
    }
  }

  Widget _buildSentimentSliver(bool isDark) {
    if (indices.isEmpty) return const SizedBox.shrink();

    // Calculate bullish vs bearish
    final total = indices.length;
    final bullish = indices.where((i) => (i['pcnt'] as num) >= 0).length;
    final bearish = total - bullish;
    final bullishRatio = total > 0 ? bullish / total : 0.5;

    // Theme colors
    final upColor = isDark ? const Color(0xFF00D4AA) : const Color(0xFF00897B);
    final downColor =
        isDark ? const Color(0xFFFF5C5C) : const Color(0xFFD32F2F);
    final labelColor =
        isDark ? const Color(0xFF5A6175) : const Color(0xFF9BA4B5);

    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, top: 12, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$bullish Bullish',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: upColor,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                'Sentiment',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: labelColor,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                '$bearish Bearish',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: downColor,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Gradient segmented progress bar
          Container(
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: LinearGradient(
                colors: [upColor, downColor],
                // Hard stops create a crisp line between the two colors
                stops: [bullishRatio, bullishRatio],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row: "Indices" title + "View More" button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 3,
                    height: 14,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF00D4AA)
                          : const Color(0xFF00897B),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Major Indices',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? const Color(0xFFEAEDF3)
                          : const Color(0xFF131722),
                      fontFamily: 'monospace',
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FullIndicesPage(),
                    ),
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF00D4AA).withOpacity(0.10)
                        : const Color(0xFF00897B).withOpacity(0.10),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF00D4AA).withOpacity(0.25)
                          : const Color(0xFF00897B).withOpacity(0.25),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFF00D4AA)
                              : const Color(0xFF00897B),
                          fontFamily: 'monospace',
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 9,
                        color: isDark
                            ? const Color(0xFF00D4AA)
                            : const Color(0xFF00897B),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // NEW: Sentiment Sliver (Only show when data is loaded)
        if (!loading && error == null)
          InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FullIndicesPage(),
                  ),
                );
              },
              child: _buildSentimentSliver(isDark)),

        // Scrollable indices strip
        _buildScrollStrip(isDark),
      ],
    );
  }

  Widget _buildScrollStrip(bool isDark) {
    if (loading) {
      return SizedBox(
        height: 84,
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: isDark ? Colors.tealAccent : Colors.teal,
            ),
          ),
        ),
      );
    }

    if (error != null) {
      return SizedBox(
        height: 84,
        child: Center(
          child: Text(
            error!,
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color: isDark ? Colors.red[300] : Colors.red[600],
            ),
          ),
        ),
      );
    }

    final displayList = [...indices, ...indices, ...indices];

    return GestureDetector(
      onHorizontalDragStart: (_) {
        _userInteracting = true;
        _autoScrollTimer?.cancel();
      },
      onHorizontalDragEnd: (_) {
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            _userInteracting = false;
            _startAutoScroll();
          }
        });
      },
      child: SizedBox(
        height: 84,
        child: ListView.builder(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(left: 16),
          itemCount: displayList.length,
          itemBuilder: (context, idx) {
            final index = displayList[idx % indices.length];
            final symbol = index['symbol'] as String;
            final ltp = (index['ltp'] as num).toDouble();
            final pcnt = (index['pcnt'] as num).toDouble();
            final low = (index['l'] as num?)?.toDouble() ?? ltp;
            final high = (index['h'] as num?)?.toDouble() ?? ltp;
            final previousclose = (index['pc'] as num?)?.toDouble() ?? ltp;
            final isPositive = pcnt >= 0;
            final change = ltp - previousclose;

            double progress = 0.5;
            if (high > low) {
              progress = ((ltp - low) / (high - low)).clamp(0.0, 1.0);
            }

            final flashColor = _lastColors[symbol];
            final flashCtrl = _flashControllers[symbol];

            return _IndexCard(
              symbol: symbol,
              displayName: _getDisplayName(symbol),
              shortName: _getShortName(symbol),
              ltp: ltp,
              pcnt: pcnt,
              change: change,
              low: low,
              high: high,
              progress: progress,
              isPositive: isPositive,
              isDark: isDark,
              flashColor: flashColor,
              flashController: flashCtrl,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SetAlertPage(
                    stockName: symbol,
                    segment: "index",
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _IndexCard extends StatelessWidget {
  final String symbol;
  final String displayName;
  final String shortName;
  final double ltp;
  final double pcnt;
  final double change;
  final double low;
  final double high;
  final double progress;
  final bool isPositive;
  final bool isDark;
  final Color? flashColor;
  final AnimationController? flashController;
  final VoidCallback onTap;

  const _IndexCard({
    required this.symbol,
    required this.displayName,
    required this.shortName,
    required this.ltp,
    required this.pcnt,
    required this.change,
    required this.low,
    required this.high,
    required this.progress,
    required this.isPositive,
    required this.isDark,
    required this.flashColor,
    required this.flashController,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final upColor = isDark ? const Color(0xFF00D4AA) : const Color(0xFF00897B);
    final downColor =
        isDark ? const Color(0xFFFF5C5C) : const Color(0xFFD32F2F);
    final accentColor = isPositive ? upColor : downColor;

    final bgColor = isDark ? const Color(0xFF0F1117) : const Color(0xFFF7F8FA);
    final borderColor =
        isDark ? const Color(0xFF1E2230) : const Color(0xFFE2E6ED);
    final labelColor =
        isDark ? const Color(0xFF5A6175) : const Color(0xFF9BA4B5);
    final valueColor =
        isDark ? const Color(0xFFEAEDF3) : const Color(0xFF131722);
    final trackColor =
        isDark ? const Color(0xFF1E2230) : const Color(0xFFE2E6ED);

    Color? overlayColor;
    double overlayOpacity = 0.0;
    if (flashColor != null && flashController != null) {
      overlayOpacity = (1 - flashController!.value) * 0.15;
      overlayColor = flashColor;
    }

    return Padding(
      padding: const EdgeInsets.only(right: 6, top: 3, bottom: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          splashColor: accentColor.withOpacity(0.08),
          highlightColor: accentColor.withOpacity(0.04),
          child: AnimatedBuilder(
            animation: flashController ?? kAlwaysCompleteAnimation,
            builder: (context, _) {
              return Container(
                width: 152,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: overlayColor != null
                      ? Color.lerp(bgColor, overlayColor, overlayOpacity)
                      : bgColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: labelColor,
                              letterSpacing: 0.4,
                              fontFamily: 'monospace',
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            '${isPositive ? '+' : ''}${pcnt.toStringAsFixed(2)}%',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: accentColor,
                              fontFamily: 'monospace',
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Flexible(
                          child: Text(
                            _formatLtp(ltp),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: valueColor,
                              fontFamily: 'monospace',
                              letterSpacing: -0.3,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${isPositive ? '+' : ''}${change.toStringAsFixed(1)}',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: accentColor,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: SizedBox(
                            height: 3,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final barWidth = constraints.maxWidth;
                                return Stack(
                                  clipBehavior: Clip.hardEdge,
                                  children: [
                                    Container(color: trackColor),
                                    FractionallySizedBox(
                                      widthFactor: progress,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              accentColor.withOpacity(0.5),
                                              accentColor,
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: (barWidth * progress - 2)
                                          .clamp(0.0, barWidth - 4),
                                      top: 0,
                                      bottom: 0,
                                      child: Container(
                                        width: 3,
                                        decoration: BoxDecoration(
                                          color: accentColor,
                                          borderRadius:
                                              BorderRadius.circular(1.5),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  String _formatLtp(double v) {
    if (v >= 10000) return v.toStringAsFixed(1);
    if (v >= 1000) return v.toStringAsFixed(2);
    return v.toStringAsFixed(2);
  }
}
