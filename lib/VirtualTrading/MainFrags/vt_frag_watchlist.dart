import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:optionxi/VirtualTrading/VComponents/custom_collapsible_headers.dart';
import 'package:optionxi/VirtualTrading/VComponents/custom_fno_item.dart';
import 'package:optionxi/VirtualTrading/VComponents/custom_marque_text.dart';
import 'package:optionxi/VirtualTrading/VControllers/watchlist_prev_controller.dart';
import 'package:optionxi/VirtualTrading/VDataModel/v_prev_fnoitem.dart';

class FNOPage extends StatefulWidget {
  const FNOPage({Key? key}) : super(key: key);

  @override
  State<FNOPage> createState() => _FNOPageState();
}

class _FNOPageState extends State<FNOPage> with TickerProviderStateMixin {
  final FNOController fnoController = Get.put(FNOController());
  late TabController _tabController;
  late TabController _optionTabController; // Single tab controller for options

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _optionTabController =
        TabController(length: 2, vsync: this); // Call/Put tabs

    _tabController.addListener(() {
      fnoController.setActiveTab(_tabController.index);
    });

    _optionTabController.addListener(() {
      // Update the option sub-tab for both Bank Nifty and Nifty
      if (_tabController.index == 1 || _tabController.index == 2) {
        fnoController.setOptionSubTab(_optionTabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _optionTabController.dispose();
    Get.delete<FNOController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Fixed scrolling text at bottom
            Flexible(
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  // Collapsible header
                  // SliverPersistentHeader(
                  //   floating: false,
                  //   pinned: false,
                  //   delegate: CollapsibleHeaderDelegate(
                  //     minHeight: 0,
                  //     maxHeight: 80, // Adjust based on your header height
                  //     child: _buildHeader(context),
                  //   ),
                  // ),
                  // Collapsible search bar
                  // SliverPersistentHeader(
                  //   floating: false,
                  //   pinned: false,
                  //   delegate: CollapsibleHeaderDelegate(
                  //     minHeight: 0,
                  //     maxHeight: 60, // Adjust based on your search bar height
                  //     child: _buildSearchBar(context),
                  //   ),
                  // ),

                  // Pinned tab bar
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: TabBarDelegate(
                      tabBar: _buildTabBar(context),
                    ),
                  ),
                ],
                body: _buildTabBarView(context),
              ),
            ),
            // Fixed scrolling text at bottom
            buildScrollingText(context),
          ],
        ),
      ),
    );
  }

  // Widget _buildHeader(BuildContext context) {
  //   return Padding(
  //     padding: const EdgeInsets.all(16.0),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //       children: [
  //         Text(
  //           'Virtual Trade',
  //           style: GoogleFonts.poppins(
  //             fontSize: 28,
  //             fontWeight: FontWeight.bold,
  //             color: Theme.of(context).textTheme.titleLarge?.color,
  //           ),
  //         ),
  //         Container(
  //           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  //           decoration: BoxDecoration(
  //             color:
  //                 Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
  //             borderRadius: BorderRadius.circular(20),
  //           ),
  //           child: Row(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               Container(
  //                 width: 8,
  //                 height: 8,
  //                 decoration: BoxDecoration(
  //                   color: Colors.green,
  //                   shape: BoxShape.circle,
  //                 ),
  //               ),
  //               const SizedBox(width: 6),
  //               Text(
  //                 'DELAYED',
  //                 style: GoogleFonts.poppins(
  //                   fontSize: 12,
  //                   fontWeight: FontWeight.w600,
  //                   color: Theme.of(context).colorScheme.primary,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildSearchBar(BuildContext context) {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  //     child: TextField(
  //       onChanged: fnoController.updateSearchQuery,
  //       decoration: InputDecoration(
  //         hintText: 'Search stocks or options...',
  //         prefixIcon: Icon(Icons.search),
  //         filled: true,
  //         fillColor: Theme.of(context).cardColor,
  //         border: OutlineInputBorder(
  //           borderRadius: BorderRadius.circular(12),
  //           borderSide: BorderSide(color: Theme.of(context).dividerColor),
  //         ),
  //         enabledBorder: OutlineInputBorder(
  //           borderRadius: BorderRadius.circular(12),
  //           borderSide: BorderSide(color: Theme.of(context).dividerColor),
  //         ),
  //         focusedBorder: OutlineInputBorder(
  //           borderRadius: BorderRadius.circular(12),
  //           borderSide:
  //               BorderSide(color: Theme.of(context).colorScheme.primary),
  //         ),
  //       ),
  //       style: GoogleFonts.poppins(fontSize: 14),
  //     ),
  //   );
  // }

  Widget _buildTabBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Theme.of(context).colorScheme.primary,
        unselectedLabelColor: Theme.of(context).textTheme.titleSmall?.color,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        ),
        labelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: 'Nifty 50'),
          Tab(text: 'Bank Nifty'),
          Tab(text: 'Nifty'),
        ],
      ),
    );
  }

  Widget _buildTabBarView(BuildContext context) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildNifty50Tab(),
        _buildOptionsMainTab('BANKNIFTY'),
        _buildOptionsMainTab('NIFTY'),
      ],
    );
  }

  Widget _buildNifty50Tab() {
    return Obx(() {
      if (fnoController.isLoading.value) {
        return const Center(child: FNOShimmerLoader());
      }

      if (fnoController.errorMessage.isNotEmpty) {
        return _buildErrorState();
      }

      final stocks = fnoController.filteredNifty50Stocks;
      if (stocks.isEmpty) {
        return _buildEmptyState();
      }

      return RefreshIndicator(
        onRefresh: fnoController.refreshData,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: stocks.length,
          itemBuilder: (context, index) {
            return FNOItem(stock: stocks[index], type: FNOItemType.nifty50);
          },
        ),
      );
    });
  }

  Widget _buildOptionsMainTab(String underlying) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 1,
            ),
          ),
          child: TabBar(
            controller: _optionTabController,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context).textTheme.titleSmall?.color,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            ),
            labelStyle: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            tabs: const [
              Tab(text: 'Call Options'),
              Tab(text: 'Put Options'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _optionTabController,
            children: [
              _buildOptionsTab(underlying, 'CE'),
              _buildOptionsTab(underlying, 'PE'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOptionsTab(String underlying, String optionType) {
    return Obx(() {
      if (fnoController.isLoading.value) {
        return const Center(child: FNOShimmerLoader());
      }

      List<dynamic> options;
      FNOItemType itemType;

      // Get the appropriate options based on underlying and type
      if (underlying == 'BANKNIFTY') {
        if (optionType == 'CE') {
          options = fnoController.filteredBankNiftyCallOptions;
          itemType = FNOItemType.bankNiftyCall;
        } else {
          options = fnoController.filteredBankNiftyPutOptions;
          itemType = FNOItemType.bankNiftyPut;
        }
      } else {
        if (optionType == 'CE') {
          options = fnoController.filteredNiftyCallOptions;
          itemType = FNOItemType.niftyCall;
        } else {
          options = fnoController.filteredNiftyPutOptions;
          itemType = FNOItemType.niftyPut;
        }
      }

      if (options.isEmpty) {
        return _buildEmptyState();
      }

      return RefreshIndicator(
        onRefresh: fnoController.refreshData,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: options.length,
          itemBuilder: (context, index) {
            return FNOItem(stock: options[index], type: itemType);
          },
        ),
      );
    });
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 24),
          Text(
            'Something went wrong',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              fnoController.errorMessage.value,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Theme.of(context).textTheme.titleSmall?.color,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => fnoController.refreshData(),
            icon: Icon(Icons.refresh),
            label: Text('Retry'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.trending_up_outlined,
            size: 80,
            color: Theme.of(context)
                .textTheme
                .titleSmall
                ?.color
                ?.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'No data available',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please check back later or try refreshing',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Theme.of(context).textTheme.titleSmall?.color,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => fnoController.refreshData(),
            icon: Icon(Icons.refresh),
            label: Text('Refresh'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// Shimmer loader for FNO items
class FNOShimmerLoader extends StatefulWidget {
  const FNOShimmerLoader({Key? key}) : super(key: key);

  @override
  State<FNOShimmerLoader> createState() => _FNOShimmerLoaderState();
}

class _FNOShimmerLoaderState extends State<FNOShimmerLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
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
      itemCount: 8,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return _buildShimmerItem(context);
          },
        );
      },
    );
  }

  Widget _buildShimmerItem(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            _buildShimmerContainer(
              height: 40,
              width: 40,
              borderRadius: BorderRadius.circular(20),
              isDark: isDark,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildShimmerContainer(
                        height: 18,
                        width: 100,
                        borderRadius: BorderRadius.circular(4),
                        isDark: isDark,
                      ),
                      _buildShimmerContainer(
                        height: 18,
                        width: 80,
                        borderRadius: BorderRadius.circular(4),
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildShimmerContainer(
                        height: 14,
                        width: 120,
                        borderRadius: BorderRadius.circular(4),
                        isDark: isDark,
                      ),
                      _buildShimmerContainer(
                        height: 24,
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
