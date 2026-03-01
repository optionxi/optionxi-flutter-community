import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:optionxi/Helpers/constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:cached_network_image/cached_network_image.dart';

// ─── Sector color mapping ────────────────────────────────────────────────────
Color _sectorColor(String sec) {
  const map = {
    'Information Technology': Color(0xFF6366F1),
    'Oil & Gas': Color(0xFFF59E0B),
    'Banking & Finance': Color(0xFF3B82F6),
    'NBFC': Color(0xFF8B5CF6),
    'Pharmaceuticals': Color(0xFF10B981),
    'Automobiles': Color(0xFFF97316),
    'FMCG': Color(0xFFEC4899),
    'Metals': Color(0xFF64748B),
    'Power': Color(0xFFEAB308),
    'Telecom': Color(0xFF06B6D4),
  };
  return map[sec] ?? const Color(0xFF94A3B8);
}

// ─── Model ───────────────────────────────────────────────────────────────────
class TopGainerLoserData {
  final String stckname;
  final double close;
  final double open;
  final double high;
  final double low;
  final double vol;
  final double vol2;
  final double vol3;
  final double vol4;
  final double vol5;
  final double pcnt;
  final String sec;
  final double pc;
  final double pc2;
  final double pc3;
  final double pc4;
  final double pc5;
  final double pc6;
  final double pc7;
  final String fname;
  final double max52;
  final double min52;

  TopGainerLoserData({
    required this.stckname,
    required this.close,
    required this.open,
    required this.high,
    required this.low,
    required this.vol,
    required this.vol2,
    required this.vol3,
    required this.vol4,
    required this.vol5,
    required this.pcnt,
    required this.sec,
    required this.pc,
    required this.pc2,
    required this.pc3,
    required this.pc4,
    required this.pc5,
    required this.pc6,
    required this.pc7,
    required this.fname,
    required this.max52,
    required this.min52,
  });

  factory TopGainerLoserData.fromJson(Map<String, dynamic> json) {
    return TopGainerLoserData(
      stckname: json['stckname'] ?? '',
      close: (json['close'] ?? 0).toDouble(),
      open: (json['open'] ?? 0).toDouble(),
      high: (json['high'] ?? 0).toDouble(),
      low: (json['low'] ?? 0).toDouble(),
      vol: (json['vol'] ?? 0).toDouble(),
      vol2: (json['vol2'] ?? 0).toDouble(),
      vol3: (json['vol3'] ?? 0).toDouble(),
      vol4: (json['vol4'] ?? 0).toDouble(),
      vol5: (json['vol5'] ?? 0).toDouble(),
      pcnt: (json['pcnt'] ?? 0).toDouble(),
      sec: json['sec'] ?? '',
      pc: (json['pc'] ?? 0).toDouble(),
      pc2: (json['pc2'] ?? 0).toDouble(),
      pc3: (json['pc3'] ?? 0).toDouble(),
      pc4: (json['pc4'] ?? 0).toDouble(),
      pc5: (json['pc5'] ?? 0).toDouble(),
      pc6: (json['pc6'] ?? 0).toDouble(),
      pc7: (json['pc7'] ?? 0).toDouble(),
      fname: json['fname'] ?? '',
      max52: (json['max52'] ?? 0).toDouble(),
      min52: (json['min52'] ?? 0).toDouble(),
    );
  }

  List<double> get closePrices => [pc7, pc6, pc5, pc4, pc3, pc2, pc, close];
  double get averageVolume => (vol + vol2 + vol3 + vol4 + vol5) / 5;

  String get symbol {
    try {
      return stckname.split('-')[0].split(':')[1];
    } catch (_) {
      return stckname;
    }
  }
}

// ─── Supabase service ────────────────────────────────────────────────────────
class StockDataService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<TopGainerLoserData>> fetchTopGainers(String category) async {
    final tableName = switch (category.toLowerCase()) {
      'nifty50' => 'top_gainers_nifty50',
      'nifty200' => 'top_gainers_nifty200',
      _ => 'top_gainers_all',
    };
    final response = await _supabase
        .from(tableName)
        .select()
        .order('pcnt', ascending: false);
    return (response as List)
        .map((r) => TopGainerLoserData.fromJson(r))
        .toList();
  }

  Future<List<TopGainerLoserData>> fetchTopLosers(String category) async {
    final tableName = switch (category.toLowerCase()) {
      'nifty50' => 'top_losers_nifty50',
      'nifty200' => 'top_losers_nifty200',
      _ => 'top_losers_all',
    };
    final response =
        await _supabase.from(tableName).select().order('pcnt', ascending: true);
    return (response as List)
        .map((r) => TopGainerLoserData.fromJson(r))
        .toList();
  }

  Future<List<TopGainerLoserData>> fetchTopVolume(String category) async {
    final tableName = switch (category.toLowerCase()) {
      'nifty50' => 'top_volume_nifty50',
      'nifty200' => 'top_volume_nifty200',
      _ => 'top_volume_all',
    };
    final response =
        await _supabase.from(tableName).select().order('vol', ascending: false);
    return (response as List)
        .map((r) => TopGainerLoserData.fromJson(r))
        .toList();
  }
}

// ─── Enums ───────────────────────────────────────────────────────────────────
enum StockMarketTab { topGainers, topLosers, topVolume }

// ─── Main Page ───────────────────────────────────────────────────────────────
class TopGainersLosersPage extends StatefulWidget {
  final StockMarketTab? initialTab;
  const TopGainersLosersPage({Key? key, this.initialTab}) : super(key: key);

  @override
  State<TopGainersLosersPage> createState() => _TopGainersLosersPageState();
}

class _TopGainersLosersPageState extends State<TopGainersLosersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab?.index ?? 0,
    );
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
    final bgColor = isDark ? const Color(0xFF080B11) : const Color(0xFFF0F4F8);

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // ── App Bar ──────────────────────────────────────────────────────
          _AppHeader(isDark: isDark),

          // ── Tab Bar ──────────────────────────────────────────────────────
          _ModernTabBar(controller: _tabController, isDark: isDark),

          const SizedBox(height: 10),

          // ── Category Selector ────────────────────────────────────────────
          _CategorySelector(
            selected: _selectedCategory,
            onChanged: (v) => setState(() => _selectedCategory = v),
            isDark: isDark,
          ),

          const SizedBox(height: 10),

          // ── Content ──────────────────────────────────────────────────────
          Expanded(
            child: AnimatedBuilder(
              animation: _tabController,
              builder: (context, _) => IndexedStack(
                index: _tabController.index,
                children: [
                  _StockList(
                    key: ValueKey('gainers-$_selectedCategory'),
                    fetcher: StockDataService().fetchTopGainers,
                    category: _selectedCategory,
                    isDark: isDark,
                  ),
                  _StockList(
                    key: ValueKey('losers-$_selectedCategory'),
                    fetcher: StockDataService().fetchTopLosers,
                    category: _selectedCategory,
                    isDark: isDark,
                  ),
                  _StockList(
                    key: ValueKey('volume-$_selectedCategory'),
                    fetcher: StockDataService().fetchTopVolume,
                    category: _selectedCategory,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── App Header ──────────────────────────────────────────────────────────────
class _AppHeader extends StatelessWidget {
  final bool isDark;
  const _AppHeader({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final now = DateFormat('EEE, d MMM').format(DateTime.now());
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Get.back(),
              icon: Icon(Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B)),
              style: IconButton.styleFrom(
                backgroundColor:
                    isDark ? const Color(0xFF1A1D27) : const Color(0xFFF1F5F9),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Market Movers',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: isDark
                          ? const Color(0xFFF1F5F9)
                          : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    '$now · NSE Market Movers',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFF4B5563)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            // Container(
            //   width: 36,
            //   height: 36,
            //   decoration: BoxDecoration(
            //     color:
            //         isDark ? const Color(0xFF1A1D27) : const Color(0xFFF1F5F9),
            //     borderRadius: BorderRadius.circular(10),
            //   ),
            //   child: Icon(Icons.notifications_none_rounded,
            //       size: 20,
            //       color: isDark
            //           ? const Color(0xFF64748B)
            //           : const Color(0xFF94A3B8)),
            // ),
          ],
        ),
      ),
    );
  }
}

// ─── Modern Tab Bar ───────────────────────────────────────────────────────────
class _ModernTabBar extends StatelessWidget {
  final TabController controller;
  final bool isDark;

  const _ModernTabBar({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0D1017) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? const Color(0xFF1A1D27) : const Color(0xFFE2E8F0),
          ),
        ),
        child: TabBar(
          controller: controller,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: isDark ? const Color(0xFF161924) : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          padding: const EdgeInsets.all(4),
          labelPadding: EdgeInsets.zero,
          tabs: [
            _TabItem(
                icon: Icons.trending_up_rounded,
                label: 'Gainers',
                color: const Color(0xFF22C55E),
                controller: controller,
                index: 0),
            _TabItem(
                icon: Icons.trending_down_rounded,
                label: 'Losers',
                color: const Color(0xFFEF4444),
                controller: controller,
                index: 1),
            _TabItem(
                icon: Icons.bar_chart_rounded,
                label: 'Volume',
                color: const Color(0xFF6366F1),
                controller: controller,
                index: 2),
          ],
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final TabController controller;
  final int index;

  const _TabItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.controller,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final isActive = controller.index == index;
        return Tab(
          height: 46,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 17,
                  color: isActive
                      ? color
                      : isDark
                          ? const Color(0xFF4B5563)
                          : const Color(0xFF94A3B8)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isActive
                      ? color
                      : isDark
                          ? const Color(0xFF4B5563)
                          : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Category Selector ───────────────────────────────────────────────────────
class _CategorySelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  final bool isDark;

  const _CategorySelector({
    required this.selected,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cats = [
      ('all', 'All'),
      ('nifty50', 'Nifty 50'),
      ('nifty200', 'Nifty 200'),
    ];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: cats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final isSelected = selected == cats[i].$1;
          return GestureDetector(
            onTap: () => onChanged(cats[i].$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      )
                    : null,
                color: isSelected
                    ? null
                    : isDark
                        ? const Color(0xFF1A1D27)
                        : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  cats[i].$2,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? Colors.white
                        : isDark
                            ? const Color(0xFF64748B)
                            : const Color(0xFF94A3B8),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Stock List (Fetches + Renders) ──────────────────────────────────────────
class _StockList extends StatefulWidget {
  final Future<List<TopGainerLoserData>> Function(String) fetcher;
  final String category;
  final bool isDark;

  const _StockList({
    Key? key,
    required this.fetcher,
    required this.category,
    required this.isDark,
  }) : super(key: key);

  @override
  State<_StockList> createState() => _StockListState();
}

class _StockListState extends State<_StockList> {
  List<TopGainerLoserData> _data = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await widget.fetcher(widget.category);
      if (mounted)
        setState(() {
          _data = data;
          _loading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString();
          _loading = false;
        });
    }
  }

  void _showDetail(TopGainerLoserData stock) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StockDetailSheet(stock: stock, isDark: widget.isDark),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: 6,
        itemBuilder: (_, i) => _SkeletonCard(isDark: widget.isDark),
      );
    }

    if (_error != null) {
      return _ErrorState(onRetry: _fetch, isDark: widget.isDark);
    }

    if (_data.isEmpty) {
      return _EmptyState(isDark: widget.isDark);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: _data.length,
      itemBuilder: (context, index) => _StockCard(
        stock: _data[index],
        rank: index + 1,
        isDark: widget.isDark,
        onTap: () => _showDetail(_data[index]),
      ),
    );
  }
}

// ─── Stock Card ───────────────────────────────────────────────────────────────
class _StockCard extends StatefulWidget {
  final TopGainerLoserData stock;
  final int rank;
  final bool isDark;
  final VoidCallback onTap;

  const _StockCard({
    required this.stock,
    required this.rank,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_StockCard> createState() => _StockCardState();
}

class _StockCardState extends State<_StockCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnim = Tween(begin: 1.0, end: 0.97).animate(
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
    final stock = widget.stock;
    final isDark = widget.isDark;
    final isUp = stock.pcnt >= 0;
    final accentColor =
        isUp ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
    final secColor = _sectorColor(stock.sec);
    final currFmt = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    final compactFmt = NumberFormat.compact();

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0D1017) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark ? const Color(0xFF1A1D27) : const Color(0xFFF1F5F9),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header row ──────────────────────────────────────────
                Row(
                  children: [
                    // Logo
                    _StockLogo(
                      stckname: stock.stckname,
                      secColor: secColor,
                      isDark: isDark,
                      size: 46,
                    ),
                    const SizedBox(width: 12),
                    // Symbol + sector
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stock.symbol,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                              color: isDark
                                  ? const Color(0xFFF1F5F9)
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 3),
                          if (stock.sec != "")
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: secColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: secColor.withOpacity(0.25)),
                              ),
                              child: Text(
                                stock.sec,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: secColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Rank badge
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E2130)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '#${widget.rank}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? const Color(0xFF4B5563)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // ── Price + % change ─────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currFmt.format(stock.close),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: isDark
                            ? const Color(0xFFF1F5F9)
                            : const Color(0xFF0F172A),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: accentColor.withOpacity(0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isUp
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            size: 13,
                            color: accentColor,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${stock.pcnt.abs().toStringAsFixed(2)}%',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── Area Chart ───────────────────────────────────────────
                SizedBox(
                  height: 72,
                  child: _AreaSparkline(
                    data: stock.closePrices,
                    color: accentColor,
                    isDark: isDark,
                  ),
                ),

                const SizedBox(height: 12),

                // ── Footer ───────────────────────────────────────────────
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0A0D14)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF1A1D27)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _FooterStat(
                          label: 'Day Range',
                          value:
                              '${currFmt.format(stock.low)} – ${currFmt.format(stock.high)}',
                          isDark: isDark,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 28,
                        color: isDark
                            ? const Color(0xFF1A1D27)
                            : const Color(0xFFE2E8F0),
                      ),
                      const SizedBox(width: 14),
                      _FooterStat(
                        label: 'Volume',
                        value: compactFmt.format(stock.vol),
                        isDark: isDark,
                        alignEnd: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Area Sparkline using Syncfusion AreaSeries ───────────────────────────────
class _AreaSparkline extends StatelessWidget {
  final List<double> data;
  final Color color;
  final bool isDark;

  const _AreaSparkline({
    required this.data,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final points =
        data.asMap().entries.map((e) => _ChartPoint(e.key, e.value)).toList();

    return SfCartesianChart(
      margin: EdgeInsets.zero,
      plotAreaBorderWidth: 0,
      plotAreaBackgroundColor: Colors.transparent,
      backgroundColor: Colors.transparent,
      primaryXAxis: NumericAxis(
        isVisible: false,
        majorGridLines: const MajorGridLines(width: 0),
        axisLine: const AxisLine(width: 0),
      ),
      primaryYAxis: NumericAxis(
        isVisible: false,
        majorGridLines: const MajorGridLines(width: 0),
        axisLine: const AxisLine(width: 0),
      ),
      series: <CartesianSeries>[
        AreaSeries<_ChartPoint, int>(
          dataSource: points,
          xValueMapper: (p, _) => p.x,
          yValueMapper: (p, _) => p.y,
          color: color.withOpacity(0.18),
          borderColor: color,
          borderWidth: 2.0,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withOpacity(0.35),
              color.withOpacity(0.0),
            ],
          ),
          animationDuration: 600,
          markerSettings: MarkerSettings(
            isVisible: true,
            shape: DataMarkerType.circle,
            color: color,
            borderColor: isDark ? const Color(0xFF0D1017) : Colors.white,
            borderWidth: 2,
            width: 7,
            height: 7,
            // Show only last point marker
          ),
        ),
      ],
    );
  }
}

class _ChartPoint {
  final int x;
  final double y;
  _ChartPoint(this.x, this.y);
}

// ─── Stock Logo ───────────────────────────────────────────────────────────────
class _StockLogo extends StatelessWidget {
  final String stckname;
  final Color secColor;
  final bool isDark;
  final double size;

  const _StockLogo({
    required this.stckname,
    required this.secColor,
    required this.isDark,
    this.size = 44,
  });

  String get _symbol {
    try {
      return stckname.split('-')[0].split(':')[1];
    } catch (_) {
      return stckname;
    }
  }

  String get _imageUrl {
    try {
      return Constants.OptionXiS3Loc + _symbol + '.png';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: secColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: secColor.withOpacity(0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: CachedNetworkImage(
          imageUrl: _imageUrl,
          fit: BoxFit.contain,
          placeholder: (_, __) => Center(
            child: Text(
              _symbol.isNotEmpty ? _symbol[0] : 'S',
              style: TextStyle(
                fontSize: size * 0.4,
                fontWeight: FontWeight.w800,
                color: secColor,
              ),
            ),
          ),
          errorWidget: (_, __, ___) => Center(
            child: Text(
              _symbol.isNotEmpty ? _symbol[0] : 'S',
              style: TextStyle(
                fontSize: size * 0.4,
                fontWeight: FontWeight.w800,
                color: secColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Footer Stat ──────────────────────────────────────────────────────────────
class _FooterStat extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final bool alignEnd;

  const _FooterStat({
    required this.label,
    required this.value,
    required this.isDark,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFF4B5563) : const Color(0xFF94A3B8),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}

// ─── Stock Detail Bottom Sheet ────────────────────────────────────────────────
class _StockDetailSheet extends StatefulWidget {
  final TopGainerLoserData stock;
  final bool isDark;

  const _StockDetailSheet({required this.stock, required this.isDark});

  @override
  State<_StockDetailSheet> createState() => _StockDetailSheetState();
}

class _StockDetailSheetState extends State<_StockDetailSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stock = widget.stock;
    final isDark = widget.isDark;
    final isUp = stock.pcnt >= 0;
    final accentColor =
        isUp ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
    final secColor = _sectorColor(stock.sec);
    final currFmt = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    final compactFmt = NumberFormat.compact();
    final bgColor = isDark ? const Color(0xFF0F1117) : Colors.white;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      maxChildSize: 0.96,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: isDark ? const Color(0xFF1E2130) : const Color(0xFFE2E8F0),
            ),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2D2D3A)
                        : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ── Header ─────────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StockLogo(
                      stckname: stock.stckname,
                      secColor: secColor,
                      isDark: isDark,
                      size: 54),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stock.symbol,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            color: isDark
                                ? const Color(0xFFF1F5F9)
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          stock.fname,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        if (stock.sec != "")
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: secColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                              border:
                                  Border.all(color: secColor.withOpacity(0.25)),
                            ),
                            child: Text(
                              stock.sec,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: secColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E2130)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.close_rounded,
                          size: 18,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Price row ───────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    currFmt.format(stock.close),
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.0,
                      color: isDark
                          ? const Color(0xFFF1F5F9)
                          : const Color(0xFF0F172A),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: accentColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isUp
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          size: 16,
                          color: accentColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${stock.pcnt.abs().toStringAsFixed(2)}%',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Chart ───────────────────────────────────────────────────
              Container(
                height: 160,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0A0D14)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF1E2130)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                child: Column(
                  children: [
                    Expanded(
                      child: _AreaSparkline(
                        data: stock.closePrices,
                        color: accentColor,
                        isDark: isDark,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('7 days ago',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: isDark
                                      ? const Color(0xFF4B5563)
                                      : const Color(0xFF94A3B8))),
                          Text('Today',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: isDark
                                      ? const Color(0xFF4B5563)
                                      : const Color(0xFF94A3B8))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── CTA button ──────────────────────────────────────────────
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  Get.toNamed('/stocks/${stock.stckname.toUpperCase()}');
                },
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isUp
                          ? [const Color(0xFF16A34A), const Color(0xFF22C55E)]
                          : [const Color(0xFFDC2626), const Color(0xFFEF4444)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.analytics_outlined,
                          color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'View Full Analysis',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward_ios_rounded,
                          color: Colors.white, size: 13),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Tabs: Overview / History ─────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1A1D27)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(4),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: isDark ? const Color(0xFF262938) : Colors.white,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: isDark
                      ? const Color(0xFFF1F5F9)
                      : const Color(0xFF0F172A),
                  unselectedLabelColor: isDark
                      ? const Color(0xFF64748B)
                      : const Color(0xFF94A3B8),
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13),
                  tabs: const [
                    Tab(height: 38, text: 'Overview'),
                    Tab(height: 38, text: 'History'),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                height: 340,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // ── Overview ────────────────────────────────────────
                    _OverviewTab(
                      stock: stock,
                      isDark: isDark,
                      currFmt: currFmt,
                      compactFmt: compactFmt,
                    ),
                    // ── History ─────────────────────────────────────────
                    _HistoryTab(
                      stock: stock,
                      isDark: isDark,
                      currFmt: currFmt,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Overview Tab ─────────────────────────────────────────────────────────────
class _OverviewTab extends StatelessWidget {
  final TopGainerLoserData stock;
  final bool isDark;
  final NumberFormat currFmt;
  final NumberFormat compactFmt;

  const _OverviewTab({
    required this.stock,
    required this.isDark,
    required this.currFmt,
    required this.compactFmt,
  });

  @override
  Widget build(BuildContext context) {
    final stats = [
      ('Open', currFmt.format(stock.open), null),
      ('Prev Close', currFmt.format(stock.pc), null),
      ('Day High', currFmt.format(stock.high), const Color(0xFF22C55E)),
      ('Day Low', currFmt.format(stock.low), const Color(0xFFEF4444)),
      ('52W High', currFmt.format(stock.max52), null),
      ('52W Low', currFmt.format(stock.min52), null),
    ];

    return Column(
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.8,
          children: stats
              .map((s) => _StatTile(
                    label: s.$1,
                    value: s.$2,
                    valueColor: s.$3,
                    isDark: isDark,
                  ))
              .toList(),
        ),
        const SizedBox(height: 10),
        _StatTile(
          label: 'Volume',
          value: compactFmt.format(stock.vol),
          isDark: isDark,
          fullWidth: true,
          subtitle: 'Avg 5D: ${compactFmt.format(stock.averageVolume)}',
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isDark;
  final bool fullWidth;
  final String? subtitle;

  const _StatTile({
    required this.label,
    required this.value,
    required this.isDark,
    this.valueColor,
    this.fullWidth = false,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131722) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF1E2130) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              color: isDark ? const Color(0xFF4B5563) : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: valueColor ??
                      (isDark
                          ? const Color(0xFFE2E8F0)
                          : const Color(0xFF0F172A)),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(width: 8),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? const Color(0xFF64748B)
                        : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─── History Tab ──────────────────────────────────────────────────────────────
class _HistoryTab extends StatelessWidget {
  final TopGainerLoserData stock;
  final bool isDark;
  final NumberFormat currFmt;

  const _HistoryTab({
    required this.stock,
    required this.isDark,
    required this.currFmt,
  });

  @override
  Widget build(BuildContext context) {
    final prices =
        stock.closePrices; // [pc7, pc6, pc5, pc4, pc3, pc2, pc, close]
    final labels = [
      'Day −7',
      'Day −6',
      'Day −5',
      'Day −4',
      'Day −3',
      'Day −2',
      'Day −1',
      'Today'
    ];

    final rows = List.generate(prices.length, (i) {
      final prev = i > 0 ? prices[i - 1] : null;
      final chg =
          prev != null && prev != 0 ? ((prices[i] - prev) / prev) * 100 : null;
      return (labels[i], prices[i], chg);
    }).reversed.toList();

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Expanded(
                  child:
                      _HistHeader('Period', isDark, CrossAxisAlignment.start)),
              Expanded(
                  child:
                      _HistHeader('Price', isDark, CrossAxisAlignment.center)),
              SizedBox(
                  width: 80,
                  child: _HistHeader('Chg %', isDark, CrossAxisAlignment.end)),
            ],
          ),
        ),
        // Rows
        Expanded(
          child: ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rows.length,
            itemBuilder: (context, i) {
              final (label, price, chg) = rows[i];
              final isToday = i == 0;
              final chgColor = chg == null
                  ? (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))
                  : chg >= 0
                      ? const Color(0xFF22C55E)
                      : const Color(0xFFEF4444);

              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isToday
                      ? (isDark
                          ? const Color(0xFF1A2235)
                          : const Color(0xFFEFFDF4))
                      : (isDark
                          ? const Color(0xFF131722)
                          : const Color(0xFFF8FAFC)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isToday
                        ? const Color(0xFF22C55E).withOpacity(0.3)
                        : (isDark
                            ? const Color(0xFF1E2130)
                            : const Color(0xFFE2E8F0)),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isToday ? FontWeight.w700 : FontWeight.w500,
                          color: isToday
                              ? const Color(0xFF22C55E)
                              : (isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B)),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        currFmt.format(price),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? const Color(0xFFE2E8F0)
                              : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: Text(
                        chg != null
                            ? '${chg >= 0 ? '+' : ''}${chg.toStringAsFixed(2)}%'
                            : '—',
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: chgColor,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _HistHeader(String text, bool isDark, CrossAxisAlignment align) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: isDark ? const Color(0xFF4B5563) : const Color(0xFF94A3B8),
      ),
      textAlign: align == CrossAxisAlignment.end
          ? TextAlign.end
          : align == CrossAxisAlignment.center
              ? TextAlign.center
              : TextAlign.start,
    );
  }
}

// ─── Skeleton Card ────────────────────────────────────────────────────────────
class _SkeletonCard extends StatefulWidget {
  final bool isDark;
  const _SkeletonCard({required this.isDark});

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _anim = Tween(begin: 0.4, end: 0.9)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base =
        widget.isDark ? const Color(0xFF1A1D27) : const Color(0xFFE2E8F0);
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: widget.isDark ? const Color(0xFF0D1017) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: base.withOpacity(0.5)),
          ),
          child: Column(children: [
            Row(children: [
              Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                      color: base, borderRadius: BorderRadius.circular(14))),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Container(
                        height: 14,
                        width: 80,
                        decoration: BoxDecoration(
                            color: base,
                            borderRadius: BorderRadius.circular(4))),
                    const SizedBox(height: 8),
                    Container(
                        height: 10,
                        width: 120,
                        decoration: BoxDecoration(
                            color: base,
                            borderRadius: BorderRadius.circular(4))),
                  ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Container(
                    height: 14,
                    width: 60,
                    decoration: BoxDecoration(
                        color: base, borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 8),
                Container(
                    height: 22,
                    width: 64,
                    decoration: BoxDecoration(
                        color: base, borderRadius: BorderRadius.circular(8))),
              ]),
            ]),
            const SizedBox(height: 16),
            Container(
                height: 72,
                width: double.infinity,
                decoration: BoxDecoration(
                    color: base, borderRadius: BorderRadius.circular(12))),
            const SizedBox(height: 12),
            Container(
                height: 46,
                width: double.infinity,
                decoration: BoxDecoration(
                    color: base, borderRadius: BorderRadius.circular(12))),
          ]),
        ),
      ),
    );
  }
}

// ─── Empty & Error States ─────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool isDark;
  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1D27) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.inbox_outlined,
                size: 36,
                color:
                    isDark ? const Color(0xFF4B5563) : const Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 16),
          Text('No stocks found',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? const Color(0xFF64748B)
                      : const Color(0xFF94A3B8))),
          const SizedBox(height: 6),
          Text('Try refreshing or check back later',
              style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? const Color(0xFF4B5563)
                      : const Color(0xFFCBD5E1))),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  final bool isDark;
  const _ErrorState({required this.onRetry, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.wifi_off_rounded,
                size: 36, color: Color(0xFFEF4444)),
          ),
          const SizedBox(height: 16),
          Text('Failed to load data',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? const Color(0xFF64748B)
                      : const Color(0xFF94A3B8))),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: const Text('Retry',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}
