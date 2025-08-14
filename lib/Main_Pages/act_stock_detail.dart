import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:optionxi/DataModels/dm_converter.dart';
import 'package:optionxi/DataModels/dm_stock_model.dart';
import 'package:optionxi/Helpers/constants.dart';
import 'package:optionxi/Helpers/volume_formater.dart';
import 'package:optionxi/VirtualTradeJournal/add_basket_page.dart';
import 'package:optionxi/VirtualTrading/VComponents/cust_colorful_action_button.dart';
import 'package:optionxi/browser_lite.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import 'package:optionxi/DataModels/dm_stock_details.dart';
import 'package:optionxi/DataModels/sample_stock_symbols.dart';
import 'package:optionxi/Theme/theme_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StockController extends GetxController {
  final supabase = Supabase.instance.client;
  final isLoading = true.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;
  final stock = Rx<StockModel?>(null);
  final showVolume = false.obs;
  final chartData = <ChartData>[].obs;
  final selectedTimeframe = '6M'.obs; // Default to 3 months

  final indicators = Rx<IndicatorModel?>(null);

  void toggleVolume() {
    showVolume.value = !showVolume.value;
  }

  String formatStockSymbol(String symbol) {
    if (symbol.startsWith('NSE:')) {
      symbol = symbol.substring(4);
    }
    if (symbol.endsWith('-EQ')) {
      symbol = symbol.substring(0, symbol.length - 3);
    }
    if (symbol.endsWith('-BE')) {
      symbol = symbol.substring(0, symbol.length - 3);
    }
    if (!symbol.endsWith('.NS')) {
      symbol = '$symbol.NS';
    }
    return symbol;
  }

  void setTimeframe(String timeframe) {
    selectedTimeframe.value = timeframe;
    fetchChartData(stock.value!.symbol, timeframe);
  }

  Future<void> fetchStockData(String symbol) async {
    String fullsymbol = symbol;
    isLoading.value = true;
    hasError.value = false;
    errorMessage.value = '';

    try {
      String fullsymbol_ltp = fullsymbol.replaceAll("-BE", "-EQ");
      final liveStockResponse = await supabase
          .from('live_5000_stocks')
          .select()
          .eq('symbol', fullsymbol_ltp)
          .single();

      stock.value = StockModel.fromJson(liveStockResponse);
    } catch (e) {
      hasError.value = true;
      errorMessage.value =
          'Error fetching from live_5000_stocks: ${e.toString()}';
      isLoading.value = false;
      return;
    }

    try {
      final indicatorsResponse = await supabase
          .from('generated_values')
          .select()
          .eq('stckname', fullsymbol)
          .single();

      indicators.value = IndicatorModel.fromJson(indicatorsResponse);
    } catch (e) {
      // Determine alternate suffix
      String? alternateSymbol;
      if (fullsymbol.endsWith("-BE")) {
        alternateSymbol = fullsymbol.replaceAll("-BE", "-EQ");
      } else if (fullsymbol.endsWith("-EQ")) {
        alternateSymbol = fullsymbol.replaceAll("-EQ", "-BE");
      }

      if (alternateSymbol != null) {
        try {
          final indicatorsResponse = await supabase
              .from('generated_values')
              .select()
              .eq('stckname', alternateSymbol)
              .single();

          indicators.value = IndicatorModel.fromJson(indicatorsResponse);
        } catch (e2) {
          hasError.value = true;
          errorMessage.value =
              'Error fetching from generated_values (alternate): ${e2.toString()}';
        }
      } else {
        hasError.value = true;
        errorMessage.value =
            'Error fetching from generated_values: ${e.toString()}';
      }
    } finally {
      isLoading.value = false;
    }

    try {
      await fetchChartData(symbol, selectedTimeframe.value);
      calculateRSI();
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Error processing chart/RSI: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchChartData(String symbol, String timeframe) async {
    final fullSymbol = formatStockSymbol(symbol);
    try {
      final now = DateTime.now();
      DateTime startTime;

      // Determine the start time based on timeframe
      switch (timeframe) {
        case '1D':
          startTime = now.subtract(const Duration(days: 1));
          break;
        case '1W':
          startTime = now.subtract(const Duration(days: 7));
          break;
        case '1M':
          startTime = now.subtract(const Duration(days: 30));
          break;
        case '3M':
          startTime = now.subtract(const Duration(days: 90));
          break;
        case '6M':
          startTime = now.subtract(const Duration(days: 180));
          break;
        case '1Y':
          startTime = now.subtract(const Duration(days: 365));
          break;
        case '3Y':
          startTime = now.subtract(const Duration(days: 365 * 3));
          break;
        case '5Y':
          startTime = now.subtract(const Duration(days: 365 * 5));
          break;
        case 'MAX':
          // Get all available data
          startTime = DateTime(1970);
          break;
        default:
          startTime = now.subtract(const Duration(days: 90));
      }

      final startTimestamp = startTime.millisecondsSinceEpoch;

      // Fetch data from Supabase
      final response = await supabase
          .from('stock_data')
          .select()
          .eq('Stock Symbol', fullSymbol)
          .gte('Timestamp', startTimestamp)
          .order('Timestamp', ascending: true);

      print('Fetching chart data from: ' + startTimestamp.toString());

      // Handle empty response or null data
      if (response.isEmpty) {
        chartData.value = [];
        return;
      }

      // Safely process the data with null checks
      List<ChartData> rawData = [];
      for (var item in response) {
        try {
          rawData.add(ChartData.fromJson(item));
        } catch (e) {
          print('Error parsing chart data item: $e');
          // Continue with next item if one fails
        }
      }

      // Assign all data without sampling
      chartData.value = rawData;

      hasError.value = false;
    } catch (e) {
      print('Error fetching chart data for $symbol: $e');
      hasError.value = true;
      errorMessage.value =
          'Failed to load chart data for $symbol: ${e.toString()}';
      chartData.value = []; // Clear chart data on error
    }
  }

  void calculateRSI() {
    if (chartData.isEmpty || chartData.length < 15) return;
    // RSI calculation logic remains the same
  }
}

class StockDetailPage extends StatefulWidget {
  final String stockname;
  const StockDetailPage({Key? key, required this.stockname}) : super(key: key);

  @override
  State<StockDetailPage> createState() => _StockDetailPageState();
}

class _StockDetailPageState extends State<StockDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final StockController stockController = Get.put(StockController());
  final ThemeController themeController = Get.put(ThemeController());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            Get.isDarkMode ? Brightness.light : Brightness.dark,
      ),
    );
    stockController.fetchStockData(widget.stockname);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final textColor = theme.colorScheme.onBackground;

    return Scaffold(
      appBar: AppBar(
          title: Text(
            "Stock Details",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          iconTheme: IconThemeData(color: theme.colorScheme.primary),
          actions: [
            Obx(() => IconButton(
                  icon: Icon(
                    themeController.isDarkMode
                        ? Icons.light_mode
                        : Icons.dark_mode,
                    color: theme.colorScheme.primary,
                  ),
                  onPressed: () => themeController.toggleTheme(),
                )),
          ]),
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Obx(() {
          if (stockController.isLoading.value) {
            return _buildLoadingIndicator(context);
          }
          if (stockController.hasError.value) {
            return _buildErrorWidget(stockController.errorMessage.toString());
          }

          final stock = stockController.stock.value!;
          final priceChangeBgColor = stock.isUp
              ? (isDark ? Colors.green[900] : Colors.green[100])
              : (isDark ? Colors.red[900] : Colors.red[100]);
          final priceChangeTextColor = stock.isUp
              ? (isDark ? Colors.green[100] : Colors.green[800])
              : (isDark ? Colors.red[100] : Colors.red[800]);

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: backgroundColor,
                pinned: true,
                automaticallyImplyLeading: false,
                title: Row(
                  children: [
                    CachedNetworkImage(
                      height: 40,
                      width: 40,
                      imageUrl: Constants.OptionXiS3Loc +
                          stock.symbol.split("-")[0].split(":")[1] +
                          ".png",
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Center(
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) => ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          'assets/images/stockdefault.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stock.symbol.split(":")[1].split("-")[0],
                          style: TextStyle(
                            color: textColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          totalStocks[stock.symbol]?["full_stock_name"] ??
                              stock.stckname,
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.share_outlined, color: textColor),
                    onPressed: () {},
                  ),
                  // IconButton(
                  //   icon: Icon(Icons.star_outline_rounded,
                  //       color: Colors.amber[400]),
                  //   onPressed: () {},
                  // ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '\₹${stock.close.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                      ),
                      Column(
                        children: [
                          // _buildIndicatorButton(
                          //   stock.isUp ? 'Bullish' : 'Bearish',
                          //   stockController.showVolume.value,
                          //   () => stockController.toggleVolume(),
                          //   isDark,
                          //   stock.isUp,
                          // ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: priceChangeBgColor,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  stock.percentChangeFormatted,
                                  style: TextStyle(
                                    color: priceChangeTextColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Text(
                              //   stock.priceChangeFormatted,
                              //   style: TextStyle(
                              //     color: isDark
                              //         ? Colors.grey[400]
                              //         : Colors.grey[600],
                              //     fontSize: 14,
                              //   ),
                              // ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Modern TradingView Chart Button

                          // _buildViewChart(isDark, context),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // SliverToBoxAdapter(
              //   child: viewAlertandScreeners(stock, theme),
              // ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: buildModernActionButton(
                          context,
                          isDark,
                          'Chart',
                          Icons.trending_up_rounded,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => BrowserLite_V(
                                      "https://in.tradingview.com/chart/?symbol=NSE%3A" +
                                          widget.stockname
                                              .toString()
                                              .split("-")[0]
                                              .split(":")[1])),
                            );
                          },
                          true, // isChart button
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: buildModernActionButton(
                          context,
                          isDark,
                          'Alerts',
                          Icons.analytics_outlined,
                          () {
                            Get.toNamed(
                                '/alerts/${widget.stockname.toString().split("-")[0].split(":")[1]}');
                          },
                          false, // isChart button
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                  child: addToVirtualJournal(context, stock, theme)),
              SliverToBoxAdapter(
                child: _buildSyncfusionChartSection(context, isDark),
              ),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(text: 'Overview'),
                        Tab(text: 'Oscillators'),
                        Tab(text: 'Moving Averages'),
                      ],
                      labelColor: textColor,
                      unselectedLabelColor:
                          isDark ? Colors.grey[400] : Colors.grey[600],
                      indicatorColor: theme.colorScheme.primary,
                    ),
                    SizedBox(
                      height: 400,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildOverviewTab(context, isDark, stock),
                          _buildOscillatorsTab(context, isDark, stock),
                          _buildMovingAveragesTab(context, isDark, stock),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
      // bottomNavigationBar: Obx(() {
      //   if (stockController.isLoading.value || stockController.hasError.value) {
      //     return const SizedBox();
      //   }
      //   return _buildBottomButtons(context, isDark);
      // }),
    );
  }

  Container addToVirtualJournal(
      BuildContext context, StockModel stock, ThemeData theme) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.secondary,
            theme.colorScheme.secondary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.secondary.withValues(alpha: 0.3),
            offset: const Offset(0, 4),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            // Add haptic feedback for better UX
            HapticFeedback.lightImpact();
            // Convert dm_stock to DataStockModel
            final DataStockModel convertedStock =
                convertDmStockToDataStockModel(stock);

            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddToBasketPage(stock: convertedStock),
              ),
            );

            Navigator.pop(context);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated basket icon with modern styling
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.shopping_basket_outlined,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),

                // Main text with improved typography
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add to Virtual Basket',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                      Text(
                        'Track performance without real investment',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.8),
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),

                // Modern arrow with subtle animation hint
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Container viewAlertandScreeners(StockModel stock, ThemeData theme) {
    return Container(
      width: double.infinity,
      height: 44,
      margin: const EdgeInsets.only(bottom: 16, right: 16, left: 16),
      child: ElevatedButton(
        onPressed: () {
          Get.toNamed(
              '/alerts/${stock.stckname.split("-")[0].split(":")[1].toUpperCase()}');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ).copyWith(
          overlayColor: MaterialStateProperty.resolveWith<Color?>(
            (Set<MaterialState> states) {
              if (states.contains(MaterialState.pressed)) {
                return Colors.white.withValues(alpha: 0.1);
              }
              if (states.contains(MaterialState.hovered)) {
                return Colors.white.withValues(alpha: 0.05);
              }
              return null;
            },
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 18,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              'View Alerts and Screeners',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              children: [
                Center(
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.2),
                    ),
                  ),
                ),
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.bar_chart,
                          size: 16,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.5, end: 1.0),
            duration: const Duration(milliseconds: 800),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 10 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Column(
              children: [
                Text(
                  'Analyzing ${widget.stockname}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Fetching real-time market data...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String errormessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.red[400]),
          SizedBox(height: 16),
          Text(
            'Error Loading Data',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("Couldn't fetch data for ${widget.stockname}"),
          ),
          // Padding(
          //   padding: const EdgeInsets.all(8.0),
          //   child: Text("${errormessage}"),
          // ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
                textAlign: TextAlign.center,
                "Please try again later, If you are facing this issue again, kindly contact support at optionxi24@gmail.com"),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => stockController.fetchStockData(widget.stockname),
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncfusionChartSection(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final secondaryTextColor = isDark ? Colors.grey[400] : Colors.grey[600];
    // final accentColor = theme.colorScheme.primary;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: !isDark ? Border.all(color: Colors.grey[200]!) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTimeframeSelector(context, isDark),
          SizedBox(height: 16),
          Obx(() {
            if (stockController.chartData.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text(
                    'No chart data available',
                    style: TextStyle(color: secondaryTextColor),
                  ),
                ),
              );
            }

            return SizedBox(
              height: 250,
              child: SfCartesianChart(
                plotAreaBorderWidth: 0,
                primaryXAxis: DateTimeAxis(
                  dateFormat:
                      _getDateFormat(stockController.selectedTimeframe.value),
                  intervalType:
                      _getIntervalType(stockController.selectedTimeframe.value),
                  majorGridLines: const MajorGridLines(width: 0),
                  axisLine: const AxisLine(width: 0),
                  labelStyle: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 10,
                  ),
                  majorTickLines: const MajorTickLines(size: 0),
                ),
                primaryYAxis: NumericAxis(
                  numberFormat: NumberFormat.currency(symbol: '₹'),
                  majorGridLines: MajorGridLines(
                    color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                    width: 1,
                  ),
                  axisLine: const AxisLine(width: 0),
                  labelStyle: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 10,
                  ),
                  majorTickLines: const MajorTickLines(size: 0),
                ),
                series: <CartesianSeries<ChartData, DateTime>>[
                  AreaSeries<ChartData, DateTime>(
                    dataSource: stockController.chartData,
                    xValueMapper: (ChartData data, _) => data.date,
                    yValueMapper: (ChartData data, _) => data.close,
                    color: stockController.stock.value!.isUp
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderColor: stockController.stock.value!.isUp
                        ? Colors.green
                        : Colors.red,
                    borderWidth: 2,
                  ),
                ],
                tooltipBehavior: TooltipBehavior(
                  enable: true,
                  builder: (dynamic data, dynamic point, dynamic series,
                      int pointIndex, int seriesIndex) {
                    // Add safety check to prevent range errors
                    if (pointIndex < 0 ||
                        pointIndex >= stockController.chartData.length) {
                      // Return a fallback widget if the index is out of range
                      return Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Data unavailable',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      );
                    }

                    // Safe to access the data now
                    final ChartData pointData =
                        stockController.chartData[pointIndex];
                    String formattedDate = _formatTooltipDateDisplay(
                        pointData.date,
                        stockController.selectedTimeframe.value);
                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formattedDate,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${pointData.close.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimeframeSelector(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;
    final secondaryTextColor = isDark ? Colors.grey[400] : Colors.grey[600];

    final timeframes = ['3M', '6M', '1Y', '3Y', '5Y'];

    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: timeframes.length,
        itemBuilder: (context, index) {
          final timeframe = timeframes[index];
          return Obx(() {
            final isSelected =
                stockController.selectedTimeframe.value == timeframe;
            return GestureDetector(
              onTap: () => stockController.setTimeframe(timeframe),
              child: Container(
                margin: EdgeInsets.only(right: 8),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? accentColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : theme.dividerColor,
                  ),
                ),
                child: Text(
                  timeframe,
                  style: TextStyle(
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : secondaryTextColor,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          });
        },
      ),
    );
  }

// Add this new method to the StockDetailPage class
  String _formatTooltipDateDisplay(DateTime date, String timeframe) {
    switch (timeframe) {
      case '1D':
        return DateFormat('MMM d, yyyy hh:mm a').format(date);
      case '1W':
        return DateFormat('MMM d, yyyy').format(date);
      case '1M':
        return DateFormat('MMM d, yyyy').format(date);
      case '3M':
        return DateFormat('MMM d, yyyy').format(date);
      case '6M':
        return DateFormat('MMM d, yyyy').format(date);
      case '1Y':
        return DateFormat('MMM d, yyyy').format(date);
      case '3Y':
        return DateFormat('MMM yyyy').format(date);
      case '5Y':
        return DateFormat('MMM yyyy').format(date);
      case 'MAX':
        return DateFormat('yyyy').format(date);
      default:
        return DateFormat('MMM d, yyyy').format(date);
    }
  }

// Update date formatting
  DateFormat _getDateFormat(String timeframe) {
    switch (timeframe) {
      case '3M':
        return DateFormat('MMM');
      case '6M':
        return DateFormat('MMM y');
      case '1Y':
        return DateFormat('MMM y');
      case '3Y':
        return DateFormat('y');
      case '5Y':
        return DateFormat('y');
      default:
        return DateFormat('MMM');
    }
  }

// Update interval type detection
  DateTimeIntervalType _getIntervalType(String timeframe) {
    switch (timeframe) {
      case '3M':
        return DateTimeIntervalType.months;
      case '6M':
        return DateTimeIntervalType.months;
      case '1Y':
        return DateTimeIntervalType.months;
      case '3Y':
        return DateTimeIntervalType.years;
      case '5Y':
        return DateTimeIntervalType.years;
      default:
        return DateTimeIntervalType.months;
    }
  }

  Widget _buildOverviewTab(BuildContext context, bool isDark, dynamic stock) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onBackground;
    final secondaryTextColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final tertiaryTextColor = isDark ? Colors.grey[600] : Colors.grey[400];

    final indicators = stockController.indicators.value;
    final rsi = indicators?.rsi14 ?? 0.0;

    String rsiStatus = 'Neutral';
    if (rsi > 70) {
      rsiStatus = 'Overbought';
    } else if (rsi < 30) {
      rsiStatus = 'Oversold';
    } else if (rsi > 50) {
      rsiStatus = 'Bullish';
    } else if (rsi < 50) {
      rsiStatus = 'Bearish';
    }

    String summaryStatus = 'Neutral';
    Color summaryColor = Colors.yellow[isDark ? 700 : 800]!;

    if (indicators != null) {
      if (stock.isUp &&
          indicators.rsi14 != null &&
          indicators.rsi14! > 50 &&
          stock.close > (indicators.sma20 ?? 0)) {
        summaryStatus = 'Strong Buy';
        summaryColor = Colors.green[isDark ? 400 : 600]!;
      } else if (!stock.isUp &&
          indicators.rsi14 != null &&
          indicators.rsi14! < 50 &&
          stock.close < (indicators.sma20 ?? double.infinity)) {
        summaryStatus = 'Strong Sell';
        summaryColor = Colors.red[isDark ? 400 : 600]!;
      } else if (stock.isUp) {
        summaryStatus = 'Buy';
        summaryColor = Colors.green[isDark ? 400 : 600]!;
      } else {
        summaryStatus = 'Sell';
        summaryColor = Colors.red[isDark ? 400 : 600]!;
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildKeyStatistics(context, isDark, stock),
        const SizedBox(height: 24),
        _buildIndicatorSection(
          'Summary',
          summaryStatus,
          summaryColor,
          [
            _buildIndicatorRow(
                'RSI (14)',
                '₹${indicators?.rsi14?.toStringAsFixed(2) ?? "N/A"}',
                rsiStatus,
                textColor,
                secondaryTextColor,
                tertiaryTextColor),
            _buildIndicatorRow(
                'MACD',
                indicators?.ema20 != null && indicators?.ema50 != null
                    ? '₹${(indicators!.ema20! - indicators.ema50!).toStringAsFixed(2)}'
                    : 'N/A',
                indicators?.ema20 != null && indicators?.ema50 != null
                    ? (indicators!.ema20! > indicators.ema50! ? 'Buy' : 'Sell')
                    : 'N/A',
                textColor,
                secondaryTextColor,
                tertiaryTextColor),
            _buildIndicatorRow(
                'Price vs SMA20',
                indicators?.sma20 != null
                    ? '\₹${indicators!.sma20!.toStringAsFixed(2)}'
                    : 'N/A',
                indicators?.sma20 != null
                    ? (stock.close > indicators!.sma20! ? 'Above' : 'Below')
                    : 'N/A',
                textColor,
                secondaryTextColor,
                tertiaryTextColor),
          ],
          context,
        ),
        const SizedBox(height: 24),
        _buildIndicatorSection(
          'Moving Averages',
          stock.isUp ? 'Buy' : 'Sell',
          stock.isUp
              ? Colors.green[isDark ? 400 : 600]!
              : Colors.red[isDark ? 400 : 600]!,
          [
            _buildIndicatorRow(
                'SMA10',
                '\₹${indicators?.sma10?.toStringAsFixed(2) ?? "N/A"}',
                indicators?.sma10 != null
                    ? (stock.close > indicators!.sma10! ? 'Above' : 'Below')
                    : 'N/A',
                textColor,
                secondaryTextColor,
                tertiaryTextColor),
            _buildIndicatorRow(
                'SMA20',
                '\₹${indicators?.sma20?.toStringAsFixed(2) ?? "N/A"}',
                indicators?.sma20 != null
                    ? (stock.close > indicators!.sma20! ? 'Above' : 'Below')
                    : 'N/A',
                textColor,
                secondaryTextColor,
                tertiaryTextColor),
            _buildIndicatorRow(
                'SMA50',
                '\₹${indicators?.sma50?.toStringAsFixed(2) ?? "N/A"}',
                indicators?.sma50 != null
                    ? (stock.close > indicators!.sma50! ? 'Above' : 'Below')
                    : 'N/A',
                textColor,
                secondaryTextColor,
                tertiaryTextColor),
          ],
          context,
        ),
      ],
    );
  }

  Widget _buildKeyStatistics(BuildContext context, bool isDark, dynamic stock) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onBackground;
    final secondaryTextColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final cardColor = theme.cardColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: !isDark ? Border.all(color: Colors.grey[200]!) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Key Statistics',
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                    'Open',
                    '\₹${stock.open.toStringAsFixed(2)}',
                    secondaryTextColor,
                    textColor),
              ),
              Expanded(
                child: _buildStatItem(
                    'High',
                    '\₹${stock.high.toStringAsFixed(2)}',
                    secondaryTextColor,
                    textColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                    'Low',
                    '\₹${stock.low.toStringAsFixed(2)}',
                    secondaryTextColor,
                    textColor),
              ),
              Expanded(
                child: _buildStatItem('Volume', formatVolume(stock.volume),
                    secondaryTextColor, textColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, Color? labelColor, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildOscillatorsTab(
      BuildContext context, bool isDark, dynamic stock) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onBackground;
    final secondaryTextColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final tertiaryTextColor = isDark ? Colors.grey[600] : Colors.grey[400];

    final indicators = stockController.indicators.value;
    final rsi = indicators?.rsi14;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildIndicatorSection(
          'RSI (14)',
          rsi != null ? rsi.toStringAsFixed(2) : 'N/A',
          _getRsiColor(rsi, isDark),
          [
            _buildIndicatorRow('Overbought', '70+', 'Potential Sell Signal',
                textColor, secondaryTextColor, tertiaryTextColor),
            _buildIndicatorRow('Neutral', '30-70', 'No Strong Signal',
                textColor, secondaryTextColor, tertiaryTextColor),
            _buildIndicatorRow('Oversold', '30-', 'Potential Buy Signal',
                textColor, secondaryTextColor, tertiaryTextColor),
          ],
          context,
        ),
        const SizedBox(height: 24),
        _buildRsiProgressIndicator(context, isDark, rsi),
        const SizedBox(height: 24),
        _buildIndicatorSection(
          'MACD',
          indicators?.ema20 != null && indicators?.ema50 != null
              ? '${(indicators!.ema20! - indicators.ema50!).toStringAsFixed(2)}'
              : 'N/A',
          indicators?.ema20 != null && indicators?.ema50 != null
              ? (indicators!.ema20! > indicators.ema50!
                  ? Colors.green[isDark ? 400 : 600]!
                  : Colors.red[isDark ? 400 : 600]!)
              : Colors.grey,
          [
            _buildIndicatorRow(
                'Signal Line',
                indicators?.ema20?.toStringAsFixed(2) ?? 'N/A',
                'EMA 20',
                textColor,
                secondaryTextColor,
                tertiaryTextColor),
            _buildIndicatorRow(
                'MACD Line',
                indicators?.ema50?.toStringAsFixed(2) ?? 'N/A',
                'EMA 50',
                textColor,
                secondaryTextColor,
                tertiaryTextColor),
          ],
          context,
        ),
      ],
    );
  }

  Color _getRsiColor(double? rsi, bool isDark) {
    if (rsi == null) return Colors.grey;

    if (rsi > 70) {
      return Colors.red[isDark ? 400 : 600]!;
    } else if (rsi < 30) {
      return Colors.green[isDark ? 400 : 600]!;
    } else if (rsi > 50) {
      return Colors.blue[isDark ? 400 : 600]!;
    } else {
      return Colors.yellow[isDark ? 700 : 800]!;
    }
  }

  Widget _buildRsiProgressIndicator(
      BuildContext context, bool isDark, double? rsi) {
    if (rsi == null) return SizedBox();

    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final textColor = theme.colorScheme.onBackground;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: !isDark ? Border.all(color: Colors.grey[200]!) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RSI Indicator',
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16),
          Stack(
            children: [
              Container(
                height: 24,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      Colors.green[isDark ? 700 : 400]!,
                      Colors.yellow[isDark ? 700 : 400]!,
                      Colors.red[isDark ? 700 : 400]!,
                    ],
                  ),
                ),
              ),
              Positioned(
                left: (rsi / 100) * (MediaQuery.of(context).size.width - 64),
                child: Container(
                  width: 2,
                  height: 32,
                  color: Colors.white,
                ),
              ),
              Positioned(
                top: 4,
                left: 8,
                child: Text(
                  'Oversold',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 8,
                child: Text(
                  'Overbought',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '0',
                style: TextStyle(
                  color: textColor,
                  fontSize: 12,
                ),
              ),
              Text(
                rsi.toStringAsFixed(2),
                style: TextStyle(
                  color: _getRsiColor(rsi, isDark),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '100',
                style: TextStyle(
                  color: textColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMovingAveragesTab(
      BuildContext context, bool isDark, dynamic stock) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onBackground;
    final secondaryTextColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final tertiaryTextColor = isDark ? Colors.grey[600] : Colors.grey[400];

    final indicators = stockController.indicators.value;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildIndicatorSection(
          'Simple Moving Averages',
          indicators?.sma20 != null && stock.close > indicators!.sma20!
              ? 'Bullish'
              : 'Bearish',
          indicators?.sma20 != null && stock.close > indicators!.sma20!
              ? Colors.green[isDark ? 400 : 600]!
              : Colors.red[isDark ? 400 : 600]!,
          [
            _buildIndicatorRow(
                'SMA10',
                '\₹${indicators?.sma10?.toStringAsFixed(2) ?? "N/A"}',
                indicators?.sma10 != null
                    ? (stock.close > indicators!.sma10!
                        ? 'Price Above'
                        : 'Price Below')
                    : 'N/A',
                textColor,
                secondaryTextColor,
                tertiaryTextColor),
            _buildIndicatorRow(
                'SMA20',
                '\₹${indicators?.sma20?.toStringAsFixed(2) ?? "N/A"}',
                indicators?.sma20 != null
                    ? (stock.close > indicators!.sma20!
                        ? 'Price Above'
                        : 'Price Below')
                    : 'N/A',
                textColor,
                secondaryTextColor,
                tertiaryTextColor),
            _buildIndicatorRow(
                'SMA50',
                '\₹${indicators?.sma50?.toStringAsFixed(2) ?? "N/A"}',
                indicators?.sma50 != null
                    ? (stock.close > indicators!.sma50!
                        ? 'Price Above'
                        : 'Price Below')
                    : 'N/A',
                textColor,
                secondaryTextColor,
                tertiaryTextColor),
          ],
          context,
        ),
        const SizedBox(height: 24),
        _buildIndicatorSection(
          'Exponential Moving Averages',
          indicators?.ema20 != null && stock.close > indicators!.ema20!
              ? 'Bullish'
              : 'Bearish',
          indicators?.ema20 != null && stock.close > indicators!.ema20!
              ? Colors.green[isDark ? 400 : 600]!
              : Colors.red[isDark ? 400 : 600]!,
          [
            _buildIndicatorRow(
                'EMA10',
                '\₹${indicators?.ema10?.toStringAsFixed(2) ?? "N/A"}',
                indicators?.ema10 != null
                    ? (stock.close > indicators!.ema10!
                        ? 'Price Above'
                        : 'Price Below')
                    : 'N/A',
                textColor,
                secondaryTextColor,
                tertiaryTextColor),
            _buildIndicatorRow(
                'EMA20',
                '\₹${indicators?.ema20?.toStringAsFixed(2) ?? "N/A"}',
                indicators?.ema20 != null
                    ? (stock.close > indicators!.ema20!
                        ? 'Price Above'
                        : 'Price Below')
                    : 'N/A',
                textColor,
                secondaryTextColor,
                tertiaryTextColor),
            _buildIndicatorRow(
                'EMA50',
                '\₹${indicators?.ema50?.toStringAsFixed(2) ?? "N/A"}',
                indicators?.ema50 != null
                    ? (stock.close > indicators!.ema50!
                        ? 'Price Above'
                        : 'Price Below')
                    : 'N/A',
                textColor,
                secondaryTextColor,
                tertiaryTextColor),
          ],
          context,
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildIndicatorSection(
    String title,
    String value,
    Color valueColor,
    List<Widget> indicators,
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.cardColor;
    final textColor = theme.colorScheme.onBackground;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: !isDark ? Border.all(color: Colors.grey[200]!) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: valueColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...indicators,
        ],
      ),
    );
  }

  Widget _buildIndicatorRow(
    String label,
    String value,
    String description,
    Color textColor,
    Color? secondaryTextColor,
    Color? tertiaryTextColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: 14,
            ),
          ),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                description,
                style: TextStyle(
                  color: tertiaryTextColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget _buildBottomButtons(BuildContext context, bool isDark) {
  //   final stockSymbol = widget.stockname.split(":").length > 1
  //       ? widget.stockname.split(":")[1].split("-")[0]
  //       : widget.stockname;
  //   return Container(
  //     padding: const EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       color: Theme.of(context).scaffoldBackgroundColor,
  //       border: Border(
  //         top: BorderSide(
  //           color: Theme.of(context).dividerColor,
  //           width: 1,
  //         ),
  //       ),
  //     ),
  //     child: Row(
  //       children: [
  //         Expanded(
  //           child: FilledButton(
  //             onPressed: () {
  //               Navigator.push(
  //                 context,
  //                 MaterialPageRoute(
  //                     builder: (context) =>
  //                         BuyandSellPagePrev(stockSymbol, "EQ", false)),
  //               );
  //             },
  //             style: FilledButton.styleFrom(
  //               backgroundColor: Colors.green[isDark ? 600 : 500],
  //               padding: const EdgeInsets.symmetric(vertical: 16),
  //             ),
  //             child: const Text('Buy'),
  //           ),
  //         ),
  //         const SizedBox(width: 8),
  //         Expanded(
  //           child: OutlinedButton(
  //             onPressed: () {
  //               Navigator.push(
  //                 context,
  //                 MaterialPageRoute(
  //                     builder: (context) =>
  //                         BuyandSellPagePrev(stockSymbol, "EQ", true)),
  //               );
  //             },
  //             style: OutlinedButton.styleFrom(
  //               foregroundColor: Colors.red[isDark ? 400 : 500],
  //               side: BorderSide(color: Colors.red[isDark ? 400 : 500]!),
  //               padding: const EdgeInsets.symmetric(vertical: 16),
  //             ),
  //             child: const Text('Sell'),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildIndicatorButton(
  //     String label, bool isActive, VoidCallback onTap, bool isDark, bool isUp) {
  //   final color = isUp ? Colors.green : Colors.red;
  //   return InkWell(
  //     onTap: onTap,
  //     child: Container(
  //       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  //       decoration: BoxDecoration(
  //         color: isDark ? color[900] : color[100],
  //         borderRadius: BorderRadius.circular(6),
  //       ),
  //       child: Text(
  //         label,
  //         style: TextStyle(
  //           color: isDark ? color[100] : color[800],
  //           fontSize: 12,
  //           fontWeight: FontWeight.w500,
  //         ),
  //       ),
  //     ),
  //   );
  // }
}
