import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:optionxi/Components/custom_searchbar.dart';
import 'package:optionxi/Components/custom_watchlist_item.dart';
import 'package:optionxi/Controllers/watchlist_controller.dart';
import 'package:optionxi/Main_Pages/act_search_stocks.dart';

class WatchlistFragment extends StatefulWidget {
  const WatchlistFragment({Key? key}) : super(key: key);

  @override
  State<WatchlistFragment> createState() => _WatchlistFragmentState();
}

class _WatchlistFragmentState extends State<WatchlistFragment> {
  final WatchlistController watchlistController =
      Get.put(WatchlistController());
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    Get.delete<WatchlistController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    watchlistController.refreshLTP();
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(8, 0, 16, 8),
              sliver: Obx(() =>
                  watchlistController.filteredWatchlistStocks.isNotEmpty
                      ? SliverToBoxAdapter(child: _buildSearchBar(context))
                      : const SliverToBoxAdapter(child: SizedBox.shrink())),
            ),
            Obx(() {
              if (watchlistController.isLoading.value) {
                return const SliverFillRemaining(
                  child: Center(child: WatchlistShimmerLoader()),
                );
              }

              if (watchlistController.errorMessage.isNotEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Text(
                      watchlistController.errorMessage.value,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: Theme.of(context).textTheme.titleSmall?.color,
                      ),
                    ),
                  ),
                );
              }

              if (watchlistController.filteredWatchlistStocks.isEmpty) {
                return SliverFillRemaining(
                  child: _buildEmptyState(context),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final stock =
                        watchlistController.filteredWatchlistStocks[index];
                    return WatchlistItem(stock: stock);
                  },
                  childCount:
                      watchlistController.filteredWatchlistStocks.length,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Watchlist',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          IconButton(
            icon: Icon(Icons.add, color: Theme.of(context).iconTheme.color),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => StockSearchPage(true)),
              );
              // Refresh the watchlist after returning from StockSearchPage
              await watchlistController.loadWatchlist();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => StockSearchPage(true)),
        );
        // Optionally refresh watchlist after returning
        await watchlistController.loadWatchlist();
      },
      child: AbsorbPointer(child: ModernSearchBar()),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.remove_red_eye_outlined,
              size: 80,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.5)
                  : Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.7),
            ),
          ).animate().fadeIn(duration: 600.ms).scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.0, 1.0),
                duration: 600.ms,
                curve: Curves.easeOutBack,
              ),
          const SizedBox(height: 32),
          Text(
            'Your watchlist is empty',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ).animate().fadeIn(duration: 800.ms, delay: 200.ms),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Add stocks to your watchlist to track their performance in real-time',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: isDark
                    ? Colors.white70
                    : Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withValues(alpha: 0.7),
              ),
            ),
          ).animate().fadeIn(duration: 800.ms, delay: 400.ms),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => StockSearchPage(true)),
              );
              setState(() {
                watchlistController.loadWatchlist();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Add Stocks',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 800.ms, delay: 600.ms).slideY(
                begin: 0.2,
                end: 0,
                duration: 600.ms,
                curve: Curves.easeOutQuart,
              ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }
}

// Alternative shimmer effect skeleton (more sophisticated)
class WatchlistShimmerLoader extends StatefulWidget {
  const WatchlistShimmerLoader({Key? key}) : super(key: key);

  @override
  State<WatchlistShimmerLoader> createState() => _WatchlistShimmerLoaderState();
}

class _WatchlistShimmerLoaderState extends State<WatchlistShimmerLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 10,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return _buildShimmerWatchlistItem(context);
          },
        );
      },
    );
  }

  Widget _buildShimmerWatchlistItem(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Logo skeleton with shimmer
            _buildShimmerContainer(
              height: 48,
              width: 48,
              borderRadius: BorderRadius.circular(25),
              isDark: isDark,
            ),
            const SizedBox(width: 16),

            // Stock Info skeleton
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Stock symbol skeleton
                      _buildShimmerContainer(
                        height: 20,
                        width: 80,
                        borderRadius: BorderRadius.circular(4),
                        isDark: isDark,
                      ),
                      // Price skeleton
                      _buildShimmerContainer(
                        height: 20,
                        width: 70,
                        borderRadius: BorderRadius.circular(4),
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Company name skeleton
                      Expanded(
                        child: _buildShimmerContainer(
                          height: 16,
                          width: double.infinity,
                          borderRadius: BorderRadius.circular(4),
                          isDark: isDark,
                          margin: const EdgeInsets.only(right: 16),
                        ),
                      ),
                      // Percentage change skeleton
                      _buildShimmerContainer(
                        height: 26,
                        width: 60,
                        borderRadius: BorderRadius.circular(6),
                        isDark: isDark,
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

  Widget _buildShimmerContainer({
    required double height,
    required double width,
    required BorderRadius borderRadius,
    required bool isDark,
    EdgeInsetsGeometry? margin,
  }) {
    return Container(
      height: height,
      width: width,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          colors: isDark
              ? [
                  Colors.grey[800]!,
                  Colors.grey[700]!,
                  Colors.grey[800]!,
                ]
              : [
                  Colors.grey[300]!,
                  Colors.grey[200]!,
                  Colors.grey[300]!,
                ],
          stops: const [0.0, 0.5, 1.0],
          begin: Alignment(-1.0 + _animation.value, 0.0),
          end: Alignment(-0.5 + _animation.value, 0.0),
        ),
      ),
    );
  }
}
