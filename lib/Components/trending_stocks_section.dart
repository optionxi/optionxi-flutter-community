import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:optionxi/Main_Pages/act_top_recommended_stock_page.dart';

class TrendingStocksSection extends StatefulWidget {
  const TrendingStocksSection({Key? key}) : super(key: key);

  @override
  State<TrendingStocksSection> createState() => _TrendingStocksSectionState();
}

class _TrendingStocksSectionState extends State<TrendingStocksSection>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  List<StockData> bullishStocks = [];
  List<StockData> bearishStocks = [];
  bool isLoading = true;
  String? error;

  // Add these for authentication handling
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
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
  }

  // Method 1: Check authentication before fetching data
  void _checkAuthAndFetchData() {
    // Listen to auth state changes
    _authSubscription =
        FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        // User is authenticated, safe to fetch data
        _isUserAuthenticated = true;
        if (mounted) {
          _fetchTrendingStocks();
        }
      } else {
        // User is not authenticated
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

  // // Method 2: Alternative - Wait for authentication then fetch
  // Future<void> _waitForAuthAndFetch() async {
  //   try {
  //     // Wait for current user to be available
  //     User? currentUser = FirebaseAuth.instance.currentUser;

  //     if (currentUser == null) {
  //       // Wait for auth state to change
  //       await FirebaseAuth.instance.authStateChanges().first;
  //       currentUser = FirebaseAuth.instance.currentUser;
  //     }

  //     if (currentUser != null) {
  //       _isUserAuthenticated = true;
  //       await _fetchTrendingStocks();
  //     } else {
  //       setState(() {
  //         error = 'Authentication required';
  //         isLoading = false;
  //       });
  //     }
  //   } catch (e) {
  //     setState(() {
  //       error = 'Authentication error: ${e.toString()}';
  //       isLoading = false;
  //     });
  //   }
  // }

  Future<void> _fetchTrendingStocks() async {
    // Double-check authentication before proceeding
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

        // Parse AI recommended stocks with new structure
        final aiRecommendedStocks =
            data['ai_recommended_stocks'] as Map<dynamic, dynamic>?;

        if (aiRecommendedStocks != null) {
          // Extract bullish stocks from bullish_long_positions
          final bullishPositions =
              aiRecommendedStocks['bullish_long_positions'] as List<dynamic>?;

          // Extract bearish stocks from bearish_short_positions
          final bearishPositions =
              aiRecommendedStocks['bearish_short_positions'] as List<dynamic>?;

          if (mounted) {
            setState(() {
              // Parse bullish stocks
              bullishStocks = bullishPositions
                      ?.map((stock) => StockData.fromRealtimeDatabase(
                          stock as Map<dynamic, dynamic>))
                      .toList() ??
                  [];

              // Parse bearish stocks
              bearishStocks = bearishPositions
                      ?.map((stock) => StockData.fromRealtimeDatabase(
                          stock as Map<dynamic, dynamic>))
                      .toList() ??
                  [];

              isLoading = false;
            });

            // Start animations once data is loaded
            _fadeController.forward();
            await Future.delayed(const Duration(milliseconds: 200));
            if (mounted) {
              _slideController.forward();
            }
          }
        } else {
          if (mounted) {
            setState(() {
              error = 'No stock data available';
              isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            error = 'No trending stocks found';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = 'Failed to load trending stocks: ${e.toString()}';
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingAnimation();
    }

    if (error != null) {
      return _buildErrorWidget();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 20),
              if (bullishStocks.isNotEmpty) ...[
                _buildSectionTitle(
                    context, 'Bullish Stocks', Icons.trending_up, Colors.green),
                const SizedBox(height: 12),
                _buildStocksList(bullishStocks, true),
                const SizedBox(height: 24),
              ],
              if (bearishStocks.isNotEmpty) ...[
                _buildSectionTitle(
                    context, 'Bearish Stocks', Icons.trending_down, Colors.red),
                const SizedBox(height: 12),
                _buildStocksList(bearishStocks, false),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingAnimation() {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLoadingHeader(),
          const SizedBox(height: 20),
          _buildLoadingSection('Bullish Stocks'),
          const SizedBox(height: 24),
          _buildLoadingSection('Bearish Stocks'),
        ],
      ),
    );
  }

  Widget _buildLoadingHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnimatedPlaceholder(width: 150, height: 24),
            const SizedBox(height: 4),
            _buildAnimatedPlaceholder(width: 200, height: 16),
          ],
        ),
        _buildAnimatedPlaceholder(width: 70, height: 36),
      ],
    );
  }

  Widget _buildLoadingSection(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildAnimatedPlaceholder(width: 20, height: 20, isCircle: true),
            const SizedBox(width: 8),
            _buildAnimatedPlaceholder(width: 120, height: 20),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            itemBuilder: (context, index) => _buildLoadingCard(),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildAnimatedPlaceholder(width: 120, height: 20),
                  _buildAnimatedPlaceholder(width: 60, height: 24),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildAnimatedPlaceholder(width: 80, height: 24),
                  const SizedBox(width: 8),
                  _buildAnimatedPlaceholder(width: 50, height: 20),
                ],
              ),
              const SizedBox(height: 12),
              _buildAnimatedPlaceholder(width: 200, height: 16),
              const SizedBox(height: 4),
              _buildAnimatedPlaceholder(width: 150, height: 16),
              const SizedBox(height: 4),
              _buildAnimatedPlaceholder(width: 180, height: 16),
              const Spacer(),
              Row(
                children: [
                  _buildAnimatedPlaceholder(
                      width: 16, height: 16, isCircle: true),
                  const SizedBox(width: 4),
                  _buildAnimatedPlaceholder(width: 80, height: 16),
                  const Spacer(),
                  _buildAnimatedPlaceholder(
                      width: 14, height: 14, isCircle: true),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedPlaceholder({
    required double width,
    required double height,
    bool isCircle = false,
  }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1200),
      tween: Tween(begin: 0.3, end: 1.0),
      builder: (context, value, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 800),
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withOpacity(0.1 * value),
            borderRadius: isCircle
                ? BorderRadius.circular(height / 2)
                : BorderRadius.circular(8),
          ),
        );
      },
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            error!,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                isLoading = true;
                error = null;
              });
              _checkAuthAndFetchData();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trending Stocks',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Powered by technical analysis',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
            ),
          ],
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TopRecommendedStockPage(),
              ),
            );
          },
          child: const Text('View All'),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(
      BuildContext context, String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  Widget _buildStocksList(List<StockData> stocks, bool isBullish) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: stocks.length,
        itemBuilder: (context, index) {
          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 600 + (index * 100)),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: _buildStockCard(context, stocks[index], isBullish),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStockCard(
      BuildContext context, StockData stock, bool isBullish) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        elevation: isDark ? 8 : 2,
        shadowColor: isDark
            ? Colors.black.withOpacity(0.3)
            : Colors.grey.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TopRecommendedStockPage(stock: stock),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        theme.colorScheme.surface,
                        theme.colorScheme.surface.withOpacity(0.8),
                      ]
                    : [
                        Colors.white,
                        Colors.grey.shade50,
                      ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        stock.symbol
                            .replaceAll('-EQ', '')
                            .replaceAll('-BZ', '')
                            .replaceAll('NSE:', ''),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isBullish
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        stock.sentiment,
                        style: TextStyle(
                          color: isBullish ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '₹${stock.price.toStringAsFixed(2)}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: stock.pcnt >= 0 ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${stock.pcnt >= 0 ? '+' : ''}${stock.pcnt.toStringAsFixed(2)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (stock.sector != 'N/A') ...[
                  _buildInfoRow(context, 'Sector', stock.sector),
                  const SizedBox(height: 4),
                ],
                _buildInfoRow(context, 'Risk Level', stock.riskLevel),
                _buildInfoRow(context, 'Signal', stock.signalStrength),
                const Spacer(),
                Row(
                  children: [
                    Icon(
                      Icons.analytics,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${stock.dataChecked.length} signals',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
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

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}

// StockData class remains the same
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
