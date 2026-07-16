import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:optionxi/Components/cust_ai_analyse_btn.dart';
import 'package:optionxi/DataModels/dm_converter.dart';
import 'package:optionxi/Helpers/constants.dart';
import 'package:optionxi/Helpers/volume_formater.dart';
import 'package:optionxi/Main_Pages/StockPages/act_set_alert.dart';
import 'package:optionxi/Main_Pages/AISummary/act_stock_ai_summary.dart';
import 'package:optionxi/Main_Pages/StockPages/sec_stock_aler.dart';
import 'package:optionxi/Main_Pages/StockPages/sec_stock_screener.dart';
import 'package:optionxi/VirtualTradeJournal/add_basket_page.dart';
import 'package:optionxi/Helpers/browser_lite.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import 'package:optionxi/DataModels/dm_stock_details.dart';
import 'package:optionxi/DataModels/sample_stock_symbols.dart';
import 'package:optionxi/Theme/theme_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────

class _AppTokens {
  // Radii
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;

  // Light palette
  static const Color lightBg = Color(0xFFF5F6FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE8EAF0);
  static const Color lightText = Color(0xFF0D0F14);
  static const Color lightSubtext = Color(0xFF6B7280);
  static const Color lightTertiary = Color(0xFFB0B7C3);
  static const Color lightAccent = Color(0xFF2563EB);

  // Dark palette
  static const Color darkBg = Color(0xFF0A0C10);
  static const Color darkSurface = Color(0xFF111318);
  static const Color darkBorder = Color(0xFF1E2128);
  static const Color darkText = Color(0xFFEEF0F5);
  static const Color darkSubtext = Color(0xFF8B92A5);
  static const Color darkTertiary = Color(0xFF3D4351);
  static const Color darkAccent = Color(0xFF3B82F6);

  // Semantic
  static const Color bullGreen = Color(0xFF16A34A);
  static const Color bullGreenDark = Color(0xFF22C55E);
  static const Color bullGreenBg = Color(0xFF052E16);
  static const Color bullGreenBgLight = Color(0xFFDCFCE7);

  static const Color bearRed = Color(0xFFDC2626);
  static const Color bearRedDark = Color(0xFFEF4444);
  static const Color bearRedBg = Color(0xFF450A0A);
  static const Color bearRedBgLight = Color(0xFFFEE2E2);
}

// ─── Controller (unchanged logic, cleaned up) ─────────────────────────────────

class StockController extends GetxController {
  final supabase = Supabase.instance.client;
  final isLoading = true.obs;
  final isChartLoading = false.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;
  final stock = Rx<StockModel?>(null);
  final showVolume = false.obs;
  final chartData = <ChartData>[].obs;
  final selectedTimeframe = '3M'.obs;
  final indicators = Rx<IndicatorModel?>(null);

  void toggleVolume() => showVolume.value = !showVolume.value;

  String formatStockSymbol(String symbol) {
    if (symbol.startsWith('NSE:')) symbol = symbol.substring(4);
    if (symbol.endsWith('-EQ')) symbol = symbol.substring(0, symbol.length - 3);
    if (symbol.endsWith('-BE')) symbol = symbol.substring(0, symbol.length - 3);
    if (!symbol.endsWith('.NS')) symbol = '$symbol.NS';
    return symbol;
  }

  void setTimeframe(String timeframe) async {
    selectedTimeframe.value = timeframe;
    isChartLoading.value = true;
    await fetchChartData(stock.value!.symbol, timeframe);
    isChartLoading.value = false;
  }

  Future<void> fetchStockData(String symbol) async {
    isLoading.value = true;
    hasError.value = false;
    errorMessage.value = '';

    try {
      final liveStockResponse = await supabase
          .from('live_5000_stocks')
          .select()
          .eq('symbol', symbol.replaceAll('-BE', '-EQ'))
          .single();
      stock.value = StockModel.fromJson(liveStockResponse);
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Error fetching stock data: ${e.toString()}';
      isLoading.value = false;
      return;
    }

    try {
      final indicatorsResponse = await supabase
          .from('generated_values')
          .select()
          .eq('stckname', symbol)
          .single();
      indicators.value = IndicatorModel.fromJson(indicatorsResponse);
    } catch (e) {
      String? alt = symbol.endsWith('-BE')
          ? symbol.replaceAll('-BE', '-EQ')
          : symbol.endsWith('-EQ')
              ? symbol.replaceAll('-EQ', '-BE')
              : null;
      if (alt != null) {
        try {
          final r = await supabase
              .from('generated_values')
              .select()
              .eq('stckname', alt)
              .single();
          indicators.value = IndicatorModel.fromJson(r);
        } catch (_) {}
      }
    } finally {
      isLoading.value = false;
    }

    try {
      await fetchChartData(symbol, selectedTimeframe.value);
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Chart/RSI error: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchChartData(String symbol, String timeframe) async {
    final fullSymbol = formatStockSymbol(symbol);
    try {
      final now = DateTime.now();
      final startTime = _startTimeFor(timeframe, now);
      final response = await supabase
          .from('stock_data')
          .select()
          .eq('Stock Symbol', fullSymbol)
          .gte('Timestamp', startTime.millisecondsSinceEpoch)
          .order('Timestamp', ascending: true);

      if (response.isEmpty) {
        chartData.value = [];
        return;
      }
      List<ChartData> raw = [];
      for (var item in response) {
        try {
          raw.add(ChartData.fromJson(item));
        } catch (_) {}
      }
      chartData.value = raw;
      hasError.value = false;
    } catch (e) {
      chartData.value = [];
      hasError.value = true;
      errorMessage.value = 'Failed to load chart: ${e.toString()}';
    }
  }

  DateTime _startTimeFor(String tf, DateTime now) {
    switch (tf) {
      case '1D':
        return now.subtract(const Duration(days: 1));
      case '1W':
        return now.subtract(const Duration(days: 7));
      case '1M':
        return now.subtract(const Duration(days: 30));
      case '3M':
        return now.subtract(const Duration(days: 90));
      case '6M':
        return now.subtract(const Duration(days: 180));
      case '1Y':
        return now.subtract(const Duration(days: 365));
      case '3Y':
        return now.subtract(const Duration(days: 365 * 3));
      case '5Y':
        return now.subtract(const Duration(days: 365 * 5));
      case 'MAX':
        return DateTime(1970);
      default:
        return now.subtract(const Duration(days: 90));
    }
  }
}

// ─── Page ─────────────────────────────────────────────────────────────────────

class StockDetailPage extends StatefulWidget {
  final String stockname;
  const StockDetailPage({Key? key, required this.stockname}) : super(key: key);

  @override
  State<StockDetailPage> createState() => _StockDetailPageState();
}

class _StockDetailPageState extends State<StockDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final StockController _ctrl = Get.put(StockController());
  final ThemeController _theme = Get.put(ThemeController());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ));
    _ctrl.fetchStockData(widget.stockname);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Color _bg(bool dark) => dark ? _AppTokens.darkBg : _AppTokens.lightBg;
  Color _surface(bool dark) =>
      dark ? _AppTokens.darkSurface : _AppTokens.lightSurface;
  Color _border(bool dark) =>
      dark ? _AppTokens.darkBorder : _AppTokens.lightBorder;
  Color _text(bool dark) => dark ? _AppTokens.darkText : _AppTokens.lightText;
  Color _sub(bool dark) =>
      dark ? _AppTokens.darkSubtext : _AppTokens.lightSubtext;
  Color _tert(bool dark) =>
      dark ? _AppTokens.darkTertiary : _AppTokens.lightTertiary;
  Color _accent(bool dark) =>
      dark ? _AppTokens.darkAccent : _AppTokens.lightAccent;
  Color _bull(bool dark) =>
      dark ? _AppTokens.bullGreenDark : _AppTokens.bullGreen;
  Color _bear(bool dark) => dark ? _AppTokens.bearRedDark : _AppTokens.bearRed;
  Color _bullBg(bool dark) =>
      dark ? _AppTokens.bullGreenBg : _AppTokens.bullGreenBgLight;
  Color _bearBg(bool dark) =>
      dark ? _AppTokens.bearRedBg : _AppTokens.bearRedBgLight;

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: _bg(dark),
      appBar: _buildAppBar(dark),
      // floatingActionButton: MagicalAIButton(
      //   isDark: dark,
      //   onPressed: () {
      //     Navigator.push(
      //       context,
      //       MaterialPageRoute(
      //           builder: (_) => StockAiAnalysisPage(
      //                 symbol: widget.stockname,
      //               )),
      //     );
      //   },
      // ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: Obx(() {
          if (_ctrl.isLoading.value) return _buildLoading(dark);
          if (_ctrl.hasError.value && _ctrl.stock.value == null) {
            return _buildError(dark);
          }

          final stock = _ctrl.stock.value!;
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeroHeader(stock, dark)),
              SliverToBoxAdapter(child: _buildActionRow(stock, dark)),
              SliverToBoxAdapter(child: _buildAISummarySection(dark)),
              SliverToBoxAdapter(child: _buildChartSection(dark)),
              SliverToBoxAdapter(child: _buildPaperTradeCard(stock, dark)),
              SliverToBoxAdapter(
                child: StockScannersWidget(stockName: stock.symbol),
              ),
              SliverToBoxAdapter(
                child: StockAlertsSectionSub(symbol: stock.symbol),
              ),
              SliverToBoxAdapter(child: _buildTabs(stock, dark)),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        }),
      ),
    );
  }

  // ── App Bar ───────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(bool dark) {
    return AppBar(
      backgroundColor: _bg(dark),
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      title: Text(
        'Stock Details',
        style: TextStyle(
          color: _text(dark),
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
      ),
      iconTheme: IconThemeData(color: _accent(dark)),
      actions: [
        Obx(() => _IconBtn(
              icon: _theme.isDarkMode
                  ? Icons.wb_sunny_rounded
                  : Icons.nightlight_round,
              color: _accent(dark),
              onTap: _theme.toggleTheme,
            )),
        const SizedBox(width: 4),
      ],
    );
  }

  // ── Hero Header ───────────────────────────────────────────────────────────

  Widget _buildHeroHeader(StockModel stock, bool dark) {
    final isUp = stock.isUp;
    final priceColor = isUp ? _bull(dark) : _bear(dark);
    final priceBg = isUp ? _bullBg(dark) : _bearBg(dark);
    final symbolPart = stock.symbol.split(':').last.split('-').first;

    // L-H range computation
    final low = stock.low;
    final high = stock.high;
    final close = stock.close;
    final rangeSpan = (high - low).abs();
    final progress =
        rangeSpan > 0 ? ((close - low) / rangeSpan).clamp(0.0, 1.0) : 0.5;

    // Color: red if near low (progress < 0.33), green if near high (> 0.66), amber in between
    Color rangeBarColor;
    String rangeLabel;
    if (progress < 0.33) {
      rangeBarColor = _bear(dark);
      rangeLabel = 'Near Low';
    } else if (progress > 0.66) {
      rangeBarColor = _bull(dark);
      rangeLabel = 'Near High';
    } else {
      rangeBarColor = const Color(0xFFF59E0B);
      rangeLabel = 'Mid Range';
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface(dark),
        borderRadius: BorderRadius.circular(_AppTokens.radiusXl),
        border: Border.all(color: _border(dark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: logo + name + price ──────────────────────────────
          Row(
            children: [
              // Logo
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _bg(dark),
                  borderRadius: BorderRadius.circular(_AppTokens.radiusMd),
                  border: Border.all(color: _border(dark)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(_AppTokens.radiusMd - 1),
                  child: CachedNetworkImage(
                    imageUrl: Constants.OptionXiS3Loc + symbolPart + '.png',
                    fit: BoxFit.cover,
                    errorListener: (_) {},
                    placeholder: (_, __) => Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _accent(dark),
                        ),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Image.asset(
                      'assets/images/stockdefault.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Name + symbol
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      symbolPart,
                      style: TextStyle(
                        color: _text(dark),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      totalStocks[stock.symbol]?['full_stock_name'] ??
                          stock.stckname,
                      style: TextStyle(
                        color: _sub(dark),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Price block
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${stock.close.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: _text(dark),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: priceBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isUp
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          color: priceColor,
                          size: 11,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          stock.percentChangeFormatted,
                          style: TextStyle(
                            color: priceColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),
          // ── Divider ───────────────────────────────────────────────────
          Container(height: 1, color: _border(dark)),
          const SizedBox(height: 14),

          // ── Volume row ────────────────────────────────────────────────
          Row(
            children: [
              Icon(Icons.bar_chart_rounded, size: 13, color: _sub(dark)),
              const SizedBox(width: 4),
              Text(
                'Vol',
                style: TextStyle(
                  color: _sub(dark),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                formatVolume(stock.volume),
                style: TextStyle(
                  color: _text(dark),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const Spacer(),
              // Range label badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: rangeBarColor.withOpacity(dark ? 0.15 : 0.1),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  rangeLabel,
                  style: TextStyle(
                    color: rangeBarColor,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── L-H Progress Bar ──────────────────────────────────────────
          _LHRangeBar(
            low: low,
            high: high,
            current: close,
            progress: progress,
            rangeBarColor: rangeBarColor,
            dark: dark,
            subColor: _sub(dark),
            borderColor: _border(dark),
            bgColor: _bg(dark),
          ),
        ],
      ),
    );
  }

  // ── Action Row ────────────────────────────────────────────────────────────

  Widget _buildActionRow(StockModel stock, bool dark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              icon: Icons.candlestick_chart_rounded,
              label: 'Live Chart',
              dark: dark,
              accent: _accent(dark),
              surface: _surface(dark),
              border: _border(dark),
              textColor: _text(dark),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BrowserLite_V(
                    'https://in.tradingview.com/chart/?symbol=NSE%3A'
                    '${widget.stockname.split('-').first.split(':').last}',
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ActionButton(
              icon: Icons.notifications_active_rounded,
              label: 'Set Alert',
              dark: dark,
              accent: const Color(0xFFF59E0B),
              surface: _surface(dark),
              border: _border(dark),
              textColor: _text(dark),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SetAlertPage(stockName: stock.symbol),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Paper Trade Card ──────────────────────────────────────────────────────

  Widget _buildPaperTradeCard(StockModel stock, bool dark) {
    const buyGreen = Color(0xFF10B981);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface(dark),
        borderRadius: BorderRadius.circular(_AppTokens.radiusLg),
        border: Border.all(color: _border(dark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'Virtual Trade',
                      style: TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Paper Trading',
                style: TextStyle(
                  color: _text(dark),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const Spacer(),
              Text(
                '₹${stock.close.toStringAsFixed(2)}',
                style: TextStyle(
                  color: stock.isUp ? _bull(dark) : _bear(dark),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Simulate trades for educational purposes — no real money',
            style: TextStyle(color: _sub(dark), fontSize: 12),
          ),

          const SizedBox(height: 14),

          // ── BUY / SELL Buttons ──────────────────────────────────────────
          Row(
            children: [
              // BUY button
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddToBasketPage(
                          stock: convertDmStockToDataStockModel(stock),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: buyGreen,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: buyGreen.withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.trending_up_rounded,
                            color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Add to Virtual Basket',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Disclaimer ──────────────────────────────────────────────────
          Row(
            children: [
              Icon(Icons.school_outlined, size: 13, color: _sub(dark)),
              const SizedBox(width: 5),
              Text(
                'Educational use only — no real money involved',
                style: TextStyle(color: _sub(dark), fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // AI Section

  Widget _buildAISummarySection(bool dark) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: AiAnalyseButton(
        onTap: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, a, __) =>
                  StockAiAnalysisPage(symbol: widget.stockname),
              transitionsBuilder: (_, anim, __, child) => SlideTransition(
                position: Tween(begin: const Offset(0, 1), end: Offset.zero)
                    .animate(CurvedAnimation(
                        parent: anim, curve: Curves.easeOutCubic)),
                child: FadeTransition(opacity: anim, child: child),
              ),
              transitionDuration: const Duration(milliseconds: 400),
            ),
          );
        },
      ),
    );
  }

  // ── Chart Section ─────────────────────────────────────────────────────────

  Widget _buildChartSection(bool dark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface(dark),
        borderRadius: BorderRadius.circular(_AppTokens.radiusLg),
        border: Border.all(color: _border(dark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Price History',
                style: TextStyle(
                  color: _text(dark),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
              const Spacer(),
              Obx(() {
                final isUp = _ctrl.stock.value?.isUp ?? true;
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isUp ? _bullBg(dark) : _bearBg(dark),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _ctrl.selectedTimeframe.value,
                    style: TextStyle(
                      color: isUp ? _bull(dark) : _bear(dark),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 14),
          _buildTimeframeRow(dark),
          const SizedBox(height: 16),
          Obx(() {
            final loading = _ctrl.isChartLoading.value;
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.96, end: 1.0).animate(
                      CurvedAnimation(parent: animation, curve: Curves.easeOut),
                    ),
                    child: child,
                  ),
                );
              },
              child: loading
                  ? _buildChartSkeleton(dark)
                  : KeyedSubtree(
                      key: ValueKey(_ctrl.selectedTimeframe.value),
                      child: _buildChart(dark),
                    ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimeframeRow(bool dark) {
    const frames = ['3M', '6M', '1Y', '3Y', '5Y'];
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: frames.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final tf = frames[i];
          return Obx(() {
            final sel = _ctrl.selectedTimeframe.value == tf;
            return GestureDetector(
              onTap: () => _ctrl.setTimeframe(tf),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: sel ? _accent(dark) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: sel ? _accent(dark) : _border(dark),
                  ),
                ),
                child: Text(
                  tf,
                  style: TextStyle(
                    color: sel ? Colors.white : _sub(dark),
                    fontSize: 12.5,
                    fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            );
          });
        },
      ),
    );
  }

  Widget _buildChartSkeleton(bool dark) {
    return SizedBox(
      key: const ValueKey('chart-skeleton'),
      height: 220,
      child: _ShimmerChart(dark: dark),
    );
  }

  Widget _buildChart(bool dark) {
    if (_ctrl.chartData.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bar_chart_rounded, color: _tert(dark), size: 36),
              const SizedBox(height: 8),
              Text(
                'No chart data available',
                style: TextStyle(color: _sub(dark), fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    final isUp = _ctrl.stock.value!.isUp;
    final lineColor = isUp ? _bull(dark) : _bear(dark);
    final fillColor = isUp
        ? (dark ? const Color(0xFF052E16) : const Color(0xFFDCFCE7))
        : (dark ? const Color(0xFF450A0A) : const Color(0xFFFEE2E2));

    return SizedBox(
      height: 220,
      child: SfCartesianChart(
        plotAreaBorderWidth: 0,
        margin: EdgeInsets.zero,
        enableAxisAnimation: true,
        primaryXAxis: DateTimeAxis(
          dateFormat: _getDateFormat(_ctrl.selectedTimeframe.value),
          intervalType: _getIntervalType(_ctrl.selectedTimeframe.value),
          majorGridLines: const MajorGridLines(width: 0),
          axisLine: const AxisLine(width: 0),
          majorTickLines: const MajorTickLines(size: 0),
          labelStyle: TextStyle(color: _sub(dark), fontSize: 10),
        ),
        primaryYAxis: NumericAxis(
          numberFormat: NumberFormat.compactCurrency(symbol: '₹'),
          majorGridLines: MajorGridLines(
            color: _border(dark),
            width: 1,
            dashArray: const [4, 4],
          ),
          axisLine: const AxisLine(width: 0),
          majorTickLines: const MajorTickLines(size: 0),
          labelStyle: TextStyle(color: _sub(dark), fontSize: 10),
          opposedPosition: true,
        ),
        series: <CartesianSeries<ChartData, DateTime>>[
          AreaSeries<ChartData, DateTime>(
            dataSource: _ctrl.chartData,
            xValueMapper: (d, _) => d.date,
            yValueMapper: (d, _) => d.close,
            color: fillColor,
            borderColor: lineColor,
            borderWidth: 2,
            animationDuration: 500,
            animationDelay: 0,
            gradient: LinearGradient(
              colors: [fillColor, fillColor.withOpacity(0)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ],
        tooltipBehavior: TooltipBehavior(
          enable: true,
          builder: (data, point, series, pointIndex, seriesIndex) {
            if (pointIndex < 0 || pointIndex >= _ctrl.chartData.length) {
              return const SizedBox.shrink();
            }
            final pt = _ctrl.chartData[pointIndex];
            final dateStr =
                _tooltipDate(pt.date, _ctrl.selectedTimeframe.value);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF1E2128) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _border(dark)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(dark ? 0.4 : 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateStr,
                    style: TextStyle(color: _sub(dark), fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₹${pt.close.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: lineColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Tabs ──────────────────────────────────────────────────────────────────

  Widget _buildTabs(StockModel stock, bool dark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      decoration: BoxDecoration(
        color: _surface(dark),
        borderRadius: BorderRadius.circular(_AppTokens.radiusLg),
        border: Border.all(color: _border(dark)),
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: _border(dark)),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Oscillators'),
                Tab(text: 'Moving Avg'),
              ],
              labelColor: _text(dark),
              unselectedLabelColor: _sub(dark),
              labelStyle: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.1,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
              ),
              indicatorColor: _accent(dark),
              indicatorWeight: 2,
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: Colors.transparent,
            ),
          ),
          SizedBox(
            height: 420,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(stock, dark),
                _buildOscillatorsTab(stock, dark),
                _buildMovingAveragesTab(stock, dark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab: Overview ─────────────────────────────────────────────────────────

  Widget _buildOverviewTab(StockModel stock, bool dark) {
    final ind = _ctrl.indicators.value;
    final rsi = ind?.rsi14 ?? 0.0;

    String rsiLabel = 'Neutral';
    if (rsi > 70)
      rsiLabel = 'Overbought';
    else if (rsi < 30)
      rsiLabel = 'Oversold';
    else if (rsi > 50)
      rsiLabel = 'Bullish';
    else if (rsi < 50) rsiLabel = 'Bearish';

    String summary = 'Neutral';
    Color summaryColor = const Color(0xFFF59E0B);

    if (ind != null) {
      if (stock.isUp &&
          (ind.rsi14 ?? 0) > 50 &&
          stock.close > (ind.sma20 ?? 0)) {
        summary = 'Strong Buy';
        summaryColor = _bull(dark);
      } else if (!stock.isUp &&
          (ind.rsi14 ?? 100) < 50 &&
          stock.close < (ind.sma20 ?? double.infinity)) {
        summary = 'Strong Sell';
        summaryColor = _bear(dark);
      } else if (stock.isUp) {
        summary = 'Buy';
        summaryColor = _bull(dark);
      } else {
        summary = 'Sell';
        summaryColor = _bear(dark);
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildStatsGrid(stock, dark),
          const SizedBox(height: 16),
          _buildIndicatorCard(
            title: 'Summary',
            badge: summary,
            badgeColor: summaryColor,
            dark: dark,
            rows: [
              _IndicatorRowData(
                label: 'RSI (14)',
                value: ind?.rsi14?.toStringAsFixed(2) ?? 'N/A',
                tag: rsiLabel,
              ),
              _IndicatorRowData(
                label: 'MACD',
                value: ind?.ema20 != null && ind?.ema50 != null
                    ? (ind!.ema20! - ind.ema50!).toStringAsFixed(2)
                    : 'N/A',
                tag: ind?.ema20 != null && ind?.ema50 != null
                    ? (ind!.ema20! > ind.ema50! ? 'Bullish' : 'Bearish')
                    : 'N/A',
              ),
              _IndicatorRowData(
                label: 'Price vs SMA20',
                value: ind?.sma20 != null
                    ? '₹${ind!.sma20!.toStringAsFixed(2)}'
                    : 'N/A',
                tag: ind?.sma20 != null
                    ? (stock.close > ind!.sma20! ? 'Above' : 'Below')
                    : 'N/A',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(StockModel stock, bool dark) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        _StatCell(
            label: 'Open',
            value: '₹${stock.open.toStringAsFixed(2)}',
            dark: dark),
        _StatCell(
            label: 'High',
            value: '₹${stock.high.toStringAsFixed(2)}',
            dark: dark,
            positive: true),
        _StatCell(
            label: 'Low',
            value: '₹${stock.low.toStringAsFixed(2)}',
            dark: dark,
            negative: true),
        _StatCell(
            label: 'Volume', value: formatVolume(stock.volume), dark: dark),
      ],
    );
  }

  // ── Tab: Oscillators ──────────────────────────────────────────────────────

  Widget _buildOscillatorsTab(StockModel stock, bool dark) {
    final ind = _ctrl.indicators.value;
    final rsi = ind?.rsi14;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          if (rsi != null) _buildRsiGauge(rsi, dark),
          if (rsi != null) const SizedBox(height: 16),
          _buildIndicatorCard(
            title: 'RSI (14)',
            badge: rsi?.toStringAsFixed(1) ?? 'N/A',
            badgeColor: _getRsiColor(rsi, dark),
            dark: dark,
            rows: [
              _IndicatorRowData(
                  label: 'Overbought Zone', value: '> 70', tag: 'Sell Signal'),
              _IndicatorRowData(
                  label: 'Neutral Zone', value: '30–70', tag: 'Sideways'),
              _IndicatorRowData(
                  label: 'Oversold Zone', value: '< 30', tag: 'Buy Signal'),
            ],
          ),
          const SizedBox(height: 16),
          _buildIndicatorCard(
            title: 'MACD',
            badge: ind?.ema20 != null && ind?.ema50 != null
                ? (ind!.ema20! > ind.ema50! ? 'Bullish' : 'Bearish')
                : 'N/A',
            badgeColor: ind?.ema20 != null && ind?.ema50 != null
                ? (ind!.ema20! > ind.ema50! ? _bull(dark) : _bear(dark))
                : _sub(dark),
            dark: dark,
            rows: [
              _IndicatorRowData(
                label: 'Signal (EMA 20)',
                value: ind?.ema20?.toStringAsFixed(2) ?? 'N/A',
                tag: '',
              ),
              _IndicatorRowData(
                label: 'MACD (EMA 50)',
                value: ind?.ema50?.toStringAsFixed(2) ?? 'N/A',
                tag: '',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRsiGauge(double rsi, bool dark) {
    final color = _getRsiColor(rsi, dark);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(dark ? 0.08 : 0.06),
        borderRadius: BorderRadius.circular(_AppTokens.radiusMd),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RSI Meter',
                style: TextStyle(
                  color: _text(dark),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                rsi.toStringAsFixed(2),
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF22C55E),
                      Color(0xFFFACC15),
                      Color(0xFFEF4444),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: (rsi.clamp(0, 100) / 100) *
                        (MediaQuery.of(context).size.width - 96) -
                    6,
                top: -4,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _surface(dark),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Oversold (0)',
                  style: TextStyle(color: _sub(dark), fontSize: 10.5)),
              Text('Neutral (50)',
                  style: TextStyle(color: _sub(dark), fontSize: 10.5)),
              Text('Overbought (100)',
                  style: TextStyle(color: _sub(dark), fontSize: 10.5)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Tab: Moving Averages ──────────────────────────────────────────────────

  Widget _buildMovingAveragesTab(StockModel stock, bool dark) {
    final ind = _ctrl.indicators.value;

    String smaBadge =
        ind?.sma20 != null && stock.close > ind!.sma20! ? 'Bullish' : 'Bearish';
    Color smaColor = ind?.sma20 != null && stock.close > ind!.sma20!
        ? _bull(dark)
        : _bear(dark);

    String emaBadge =
        ind?.ema20 != null && stock.close > ind!.ema20! ? 'Bullish' : 'Bearish';
    Color emaColor = ind?.ema20 != null && stock.close > ind!.ema20!
        ? _bull(dark)
        : _bear(dark);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildIndicatorCard(
            title: 'Simple Moving Averages',
            badge: smaBadge,
            badgeColor: smaColor,
            dark: dark,
            rows: [
              _IndicatorRowData(
                label: 'SMA 10',
                value: '₹${ind?.sma10?.toStringAsFixed(2) ?? "N/A"}',
                tag: ind?.sma10 != null
                    ? (stock.close > ind!.sma10! ? 'Above' : 'Below')
                    : 'N/A',
              ),
              _IndicatorRowData(
                label: 'SMA 20',
                value: '₹${ind?.sma20?.toStringAsFixed(2) ?? "N/A"}',
                tag: ind?.sma20 != null
                    ? (stock.close > ind!.sma20! ? 'Above' : 'Below')
                    : 'N/A',
              ),
              _IndicatorRowData(
                label: 'SMA 50',
                value: '₹${ind?.sma50?.toStringAsFixed(2) ?? "N/A"}',
                tag: ind?.sma50 != null
                    ? (stock.close > ind!.sma50! ? 'Above' : 'Below')
                    : 'N/A',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildIndicatorCard(
            title: 'Exponential Moving Averages',
            badge: emaBadge,
            badgeColor: emaColor,
            dark: dark,
            rows: [
              _IndicatorRowData(
                label: 'EMA 10',
                value: '₹${ind?.ema10?.toStringAsFixed(2) ?? "N/A"}',
                tag: ind?.ema10 != null
                    ? (stock.close > ind!.ema10! ? 'Above' : 'Below')
                    : 'N/A',
              ),
              _IndicatorRowData(
                label: 'EMA 20',
                value: '₹${ind?.ema20?.toStringAsFixed(2) ?? "N/A"}',
                tag: ind?.ema20 != null
                    ? (stock.close > ind!.ema20! ? 'Above' : 'Below')
                    : 'N/A',
              ),
              _IndicatorRowData(
                label: 'EMA 50',
                value: '₹${ind?.ema50?.toStringAsFixed(2) ?? "N/A"}',
                tag: ind?.ema50 != null
                    ? (stock.close > ind!.ema50! ? 'Above' : 'Below')
                    : 'N/A',
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Shared Indicator Card ─────────────────────────────────────────────────

  Widget _buildIndicatorCard({
    required String title,
    required String badge,
    required Color badgeColor,
    required bool dark,
    required List<_IndicatorRowData> rows,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: dark ? _AppTokens.darkBg : _AppTokens.lightBg,
        borderRadius: BorderRadius.circular(_AppTokens.radiusMd),
        border: Border.all(color: _border(dark)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: _text(dark),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      color: badgeColor,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: _border(dark)),
          ...rows.asMap().entries.map((e) {
            final isLast = e.key == rows.length - 1;
            final row = e.value;
            return Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  child: Row(
                    children: [
                      Text(
                        row.label,
                        style: TextStyle(color: _sub(dark), fontSize: 13),
                      ),
                      const Spacer(),
                      Text(
                        row.value,
                        style: TextStyle(
                          color: _text(dark),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      if (row.tag.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          row.tag,
                          style: TextStyle(color: _tert(dark), fontSize: 11.5),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!isLast) Container(height: 1, color: _border(dark)),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ── States ────────────────────────────────────────────────────────────────

  Widget _buildLoading(bool dark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  strokeWidth: 3,
                  color: _accent(dark),
                  backgroundColor: _accent(dark).withOpacity(0.15),
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _accent(dark),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.candlestick_chart_rounded,
                    size: 15,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Analyzing ${widget.stockname.split(':').last.split('-').first}',
            style: TextStyle(
              color: _text(dark),
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Fetching real-time market data…',
            style: TextStyle(color: _sub(dark), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildError(bool dark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _bear(dark).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.signal_wifi_off_rounded,
                  color: _bear(dark), size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to Load',
              style: TextStyle(
                color: _text(dark),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Could not fetch data for ${widget.stockname}. Please check your connection.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _sub(dark), fontSize: 13.5, height: 1.5),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => _ctrl.fetchStockData(widget.stockname),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: _accent(dark),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Utility ───────────────────────────────────────────────────────────────

  Color _getRsiColor(double? rsi, bool dark) {
    if (rsi == null) return _sub(dark);
    if (rsi > 70) return _bear(dark);
    if (rsi < 30) return _bull(dark);
    if (rsi > 50) return _accent(dark);
    return const Color(0xFFF59E0B);
  }

  String _tooltipDate(DateTime date, String tf) {
    switch (tf) {
      case '1D':
        return DateFormat('MMM d, h:mm a').format(date);
      case '3Y':
      case '5Y':
        return DateFormat('MMM yyyy').format(date);
      case 'MAX':
        return DateFormat('yyyy').format(date);
      default:
        return DateFormat('MMM d, yyyy').format(date);
    }
  }

  DateFormat _getDateFormat(String tf) {
    switch (tf) {
      case '3M':
        return DateFormat('MMM');
      case '6M':
      case '1Y':
        return DateFormat('MMM y');
      case '3Y':
      case '5Y':
        return DateFormat('y');
      default:
        return DateFormat('MMM');
    }
  }

  DateTimeIntervalType _getIntervalType(String tf) {
    switch (tf) {
      case '3Y':
      case '5Y':
        return DateTimeIntervalType.years;
      default:
        return DateTimeIntervalType.months;
    }
  }
}

// ─── L-H Range Bar Widget ─────────────────────────────────────────────────────

class _LHRangeBar extends StatelessWidget {
  final double low;
  final double high;
  final double current;
  final double progress; // 0.0–1.0
  final Color rangeBarColor;
  final bool dark;
  final Color subColor;
  final Color borderColor;
  final Color bgColor;

  const _LHRangeBar({
    required this.low,
    required this.high,
    required this.current,
    required this.progress,
    required this.rangeBarColor,
    required this.dark,
    required this.subColor,
    required this.borderColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Labels row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Low label
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: dark ? _AppTokens.bearRedDark : _AppTokens.bearRed,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'L  ₹${low.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: dark ? _AppTokens.bearRedDark : _AppTokens.bearRed,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            // Current price in center (only if not at extremes)
            Text(
              '₹${current.toStringAsFixed(2)}',
              style: TextStyle(
                color: rangeBarColor,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            // High label
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'H  ₹${high.toStringAsFixed(2)}',
                  style: TextStyle(
                    color:
                        dark ? _AppTokens.bullGreenDark : _AppTokens.bullGreen,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color:
                        dark ? _AppTokens.bullGreenDark : _AppTokens.bullGreen,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 7),
        // The bar with thumb
        LayoutBuilder(
          builder: (context, constraints) {
            final totalWidth = constraints.maxWidth;
            final thumbSize = 14.0;
            // Thumb center position clamped so it stays within bar
            final thumbCenterX = (progress * totalWidth)
                .clamp(thumbSize / 2, totalWidth - thumbSize / 2);

            return SizedBox(
              height: thumbSize + 4,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.centerLeft,
                children: [
                  // Track background: red → amber → green gradient
                  Positioned(
                    top: (thumbSize + 4 - 7) / 2,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 7,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: LinearGradient(
                          colors: [
                            dark ? _AppTokens.bearRedDark : _AppTokens.bearRed,
                            const Color(0xFFFACC15),
                            dark
                                ? _AppTokens.bullGreenDark
                                : _AppTokens.bullGreen,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Filled portion overlay (subtle darkening of unvisited right side)
                  // Thumb circle
                  Positioned(
                    left: thumbCenterX - thumbSize / 2,
                    top: 2,
                    child: Container(
                      width: thumbSize,
                      height: thumbSize,
                      decoration: BoxDecoration(
                        color: rangeBarColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: dark
                              ? _AppTokens.darkSurface
                              : _AppTokens.lightSurface,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: rangeBarColor.withOpacity(0.45),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _IconBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool dark;
  final Color accent;
  final Color surface;
  final Color border;
  final Color textColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.dark,
    required this.accent,
    required this.surface,
    required this.border,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(_AppTokens.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_AppTokens.radiusMd),
        splashColor: accent.withOpacity(0.08),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_AppTokens.radiusMd),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: accent, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final bool dark;
  final bool positive;
  final bool negative;

  const _StatCell({
    required this.label,
    required this.value,
    required this.dark,
    this.positive = false,
    this.negative = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = dark ? _AppTokens.darkBg : _AppTokens.lightBg;
    final textC = dark ? _AppTokens.darkText : _AppTokens.lightText;
    final subC = dark ? _AppTokens.darkSubtext : _AppTokens.lightSubtext;
    final borderC = dark ? _AppTokens.darkBorder : _AppTokens.lightBorder;

    Color valueColor = textC;
    if (positive)
      valueColor = dark ? _AppTokens.bullGreenDark : _AppTokens.bullGreen;
    if (negative)
      valueColor = dark ? _AppTokens.bearRedDark : _AppTokens.bearRed;

    return Container(
      margin: const EdgeInsets.all(2),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(_AppTokens.radiusSm),
        border: Border.all(color: borderC),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(color: subC, fontSize: 11)),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IndicatorRowData {
  final String label;
  final String value;
  final String tag;
  const _IndicatorRowData({
    required this.label,
    required this.value,
    this.tag = '',
  });
}

// ─── Shimmer chart widget (loops via AnimationController) ────────────────────

class _ShimmerChart extends StatefulWidget {
  final bool dark;
  const _ShimmerChart({required this.dark});

  @override
  State<_ShimmerChart> createState() => _ShimmerChartState();
}

class _ShimmerChartState extends State<_ShimmerChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
    _anim = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor =
        widget.dark ? const Color(0xFF1A1D24) : const Color(0xFFEEF0F5);
    final shineColor =
        widget.dark ? const Color(0xFF2C3140) : const Color(0xFFFFFFFF);

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => CustomPaint(
        painter: _SkeletonPainter(
          shimmerX: _anim.value,
          baseColor: baseColor,
          shineColor: shineColor,
          isDark: widget.dark,
        ),
        size: const Size(double.infinity, 220),
      ),
    );
  }
}

// ─── Skeleton shimmer painter ─────────────────────────────────────────────────

class _SkeletonPainter extends CustomPainter {
  final double shimmerX;
  final Color baseColor;
  final Color shineColor;
  final bool isDark;

  const _SkeletonPainter({
    required this.shimmerX,
    required this.baseColor,
    required this.shineColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = baseColor;
    final shimmerGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [baseColor, shineColor, baseColor],
      stops: const [0.0, 0.5, 1.0],
    );

    void drawRect(Rect rect, {double radius = 6}) {
      final rRect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
      canvas.drawRRect(rRect, paint);
      final shimmerPaint = Paint()
        ..shader = shimmerGradient.createShader(
          Rect.fromLTWH(
            size.width * shimmerX - size.width,
            0,
            size.width * 2,
            size.height,
          ),
        );
      canvas.drawRRect(rRect, shimmerPaint);
    }

    for (int i = 0; i < 4; i++) {
      final y = size.height * 0.15 + (size.height * 0.65 / 3) * i;
      drawRect(Rect.fromLTWH(0, y - 1, size.width * 0.12, 8), radius: 4);
      drawRect(Rect.fromLTWH(size.width * 0.15, y - 0.5, size.width * 0.85, 1),
          radius: 1);
    }

    final pathPaint = Paint()
      ..shader = shimmerGradient.createShader(
        Rect.fromLTWH(
            size.width * shimmerX - size.width, 0, size.width * 2, size.height),
      )
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.75);
    path.cubicTo(
      size.width * 0.15,
      size.height * 0.6,
      size.width * 0.25,
      size.height * 0.35,
      size.width * 0.4,
      size.height * 0.45,
    );
    path.cubicTo(
      size.width * 0.5,
      size.height * 0.52,
      size.width * 0.6,
      size.height * 0.25,
      size.width * 0.75,
      size.height * 0.30,
    );
    path.cubicTo(
      size.width * 0.85,
      size.height * 0.33,
      size.width * 0.92,
      size.height * 0.45,
      size.width,
      size.height * 0.38,
    );
    path.lineTo(size.width, size.height * 0.85);
    path.lineTo(0, size.height * 0.85);
    path.close();
    canvas.drawPath(path, pathPaint);

    for (int i = 0; i < 5; i++) {
      final x = size.width * 0.05 + (size.width * 0.9 / 4) * i;
      drawRect(Rect.fromLTWH(x - 12, size.height * 0.9, 24, 8), radius: 4);
    }
  }

  @override
  bool shouldRepaint(_SkeletonPainter old) =>
      old.shimmerX != shimmerX || old.baseColor != baseColor;
}
