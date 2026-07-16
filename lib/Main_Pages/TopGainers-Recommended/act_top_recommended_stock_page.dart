import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:optionxi/Components/cust_stock_info_card.dart';
import 'package:optionxi/Main_Frags/home_sections/sec_trending_stocks.dart';
import 'package:optionxi/Main_Pages/TopGainers-Recommended/cust_tab_top_stocks_component.dart';

class TopRecommendedStockPage extends StatefulWidget {
  final StockData? stock;

  const TopRecommendedStockPage({Key? key, this.stock}) : super(key: key);

  @override
  State<TopRecommendedStockPage> createState() =>
      _TopRecommendedStockPageState();
}

class _TopRecommendedStockPageState extends State<TopRecommendedStockPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF5F5F7),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(context, isDark)),
              if (widget.stock != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => Get.toNamed(
                              '/stocks/${widget.stock!.symbol.toUpperCase()}'),
                          child: ModernStockCard(stock: widget.stock!),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _buildDisclaimerRow(context, isDark),
                      const SizedBox(height: 24),
                      _buildTabSection(context, isDark),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
// ───────────────────────────── Header ─────────────────────────────

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Single row: back button + title + live badge
          Row(
            children: [
              _BackButton(isDark: isDark),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      'Trending ',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                        letterSpacing: -0.6,
                        color: isDark ? Colors.white : const Color(0xFF0D0D12),
                      ),
                    ),
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF4FC3F7), const Color(0xFF7986CB)]
                            : [
                                const Color(0xFF1565C0),
                                const Color(0xFF4527A0)
                              ],
                      ).createShader(bounds),
                      child: const Text(
                        'Stocks',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                          letterSpacing: -0.6,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Live badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C853).withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF00C853).withOpacity(0.28),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00C853),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'Live',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF00C853),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

// ───────────────────────── Disclaimer row ─────────────────────────

  Widget _buildDisclaimerRow(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.035)
            : Colors.black.withOpacity(0.035),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.07)
              : Colors.black.withOpacity(0.07),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 13,
            color: isDark
                ? Colors.white.withOpacity(0.3)
                : Colors.black.withOpacity(0.3),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Technical indicators only — not financial advice.',
              style: TextStyle(
                fontSize: 11.5,
                height: 1.4,
                color: isDark
                    ? Colors.white.withOpacity(0.4)
                    : Colors.black.withOpacity(0.4),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _showInfoDialog,
            child: Text(
              'Learn more',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? const Color(0xFF4FC3F7) : const Color(0xFF1565C0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── Tab section ────────────────────────────

  Widget _buildTabSection(BuildContext context, bool isDark) {
    return Column(
      children: [
        // Custom pill-style tab bar
        Container(
          height: 52,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF4FC3F7), const Color(0xFF7986CB)]
                    : [const Color(0xFF1565C0), const Color(0xFF4527A0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: (isDark
                          ? const Color(0xFF4FC3F7)
                          : const Color(0xFF1565C0))
                      .withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: isDark
                ? Colors.white.withOpacity(0.45)
                : Colors.black.withOpacity(0.45),
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              letterSpacing: 0.1,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
            tabs: const [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.trending_up_rounded, size: 18),
                    SizedBox(width: 7),
                    Text('Bullish'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.trending_down_rounded, size: 18),
                    SizedBox(width: 7),
                    Text('Bearish'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Tab content
        AnimatedBuilder(
          animation: _tabController,
          builder: (context, _) {
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: IndexedStack(
                key: ValueKey(_tabController.index),
                index: _tabController.index,
                children: const [
                  TopStocksHeatMap(category: 'bullish'),
                  TopStocksHeatMap(category: 'bearish'),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ───────────────────────── Info dialog ────────────────────────────

  void _showInfoDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: isDark ? const Color(0xFF16161E) : Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF4FC3F7).withOpacity(0.12)
                            : const Color(0xFF1565C0).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.bar_chart_rounded,
                        size: 18,
                        color: isDark
                            ? const Color(0xFF4FC3F7)
                            : const Color(0xFF1565C0),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Signal Count',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: isDark ? Colors.white : const Color(0xFF0D0D12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _dialogBody(
                  isDark,
                  'The signal count represents the number of technical screeners that have identified this stock with a bullish or bearish trend.',
                ),
                const SizedBox(height: 12),
                _dialogBody(
                  isDark,
                  'A higher count indicates stronger consensus across multiple indicators — suggesting a higher probability of directional movement.',
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: TextButton.styleFrom(
                      backgroundColor: isDark
                          ? const Color(0xFF4FC3F7).withOpacity(0.1)
                          : const Color(0xFF1565C0).withOpacity(0.08),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Got it',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: isDark
                            ? const Color(0xFF4FC3F7)
                            : const Color(0xFF1565C0),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _dialogBody(bool isDark, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        height: 1.6,
        color: isDark
            ? Colors.white.withOpacity(0.6)
            : Colors.black.withOpacity(0.6),
      ),
    );
  }
}

// ─────────────────────────── Back Button ──────────────────────────────

class _BackButton extends StatefulWidget {
  final bool isDark;
  const _BackButton({required this.isDark});

  @override
  State<_BackButton> createState() => _BackButtonState();
}

class _BackButtonState extends State<_BackButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        Navigator.pop(context);
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: widget.isDark
                ? Colors.white.withOpacity(0.07)
                : Colors.black.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.08),
              width: 1,
            ),
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 16,
            color: widget.isDark
                ? Colors.white.withOpacity(0.85)
                : Colors.black.withOpacity(0.75),
          ),
        ),
      ),
    );
  }
}
