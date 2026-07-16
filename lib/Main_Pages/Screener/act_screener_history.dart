import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:optionxi/Theme/theme_controller.dart';
import 'package:optionxi/Helpers/browser_lite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

// ─────────────────────────────────────────────
//  MODELS
// ─────────────────────────────────────────────

class ScreenerEntry {
  final String id;
  final DateTime snapshotTime;
  final String stockName;
  final String? sec;
  final double? close;
  final double? pcnt;
  final int? vol;
  final int screenerCount;
  final String sentiment;
  final String screenerNames;
  final List<dynamic> screenerDetail;

  ScreenerEntry({
    required this.id,
    required this.snapshotTime,
    required this.stockName,
    this.sec,
    this.close,
    this.pcnt,
    this.vol,
    required this.screenerCount,
    required this.sentiment,
    required this.screenerNames,
    required this.screenerDetail,
  });

  factory ScreenerEntry.fromMap(Map<String, dynamic> map) {
    return ScreenerEntry(
      id: map['id'] as String,
      snapshotTime: DateTime.parse(map['snapshot_time'] as String).toLocal(),
      stockName: map['stckname'] as String,
      sec: map['sec'] as String?,
      close: map['close'] != null ? (map['close'] as num).toDouble() : null,
      pcnt: map['pcnt'] != null ? (map['pcnt'] as num).toDouble() : null,
      vol: map['vol'] as int?,
      screenerCount: map['screener_count'] as int,
      sentiment: map['sentiment'] as String,
      screenerNames: map['screener_names'] as String,
      screenerDetail: map['screener_detail'] as List<dynamic>? ?? [],
    );
  }
}

class StockSummary {
  final String stockName;
  final String? sec;
  final DateTime firstSeen;
  final String firstSentiment;
  final double? firstClose;
  final double? firstPcnt;
  final int maxScreenerCount;
  final int totalAppearances;
  final List<ScreenerEntry> allEntries;

  final double? maxUpPcnt;
  final double? maxDownPcnt;
  final double? maxGainFromEntry;
  final double? maxLossFromEntry;
  final double? immediateMoveDelta;

  StockSummary({
    required this.stockName,
    this.sec,
    required this.firstSeen,
    required this.firstSentiment,
    this.firstClose,
    this.firstPcnt,
    required this.maxScreenerCount,
    required this.totalAppearances,
    required this.allEntries,
    this.maxUpPcnt,
    this.maxDownPcnt,
    this.maxGainFromEntry,
    this.maxLossFromEntry,
    this.immediateMoveDelta,
  });
}

class ChartData {
  final DateTime time;
  final double close;

  ChartData(this.time, this.close);
}

// ─────────────────────────────────────────────
//  PCNT FILTER OPTION
// ─────────────────────────────────────────────

class PcntFilterOption {
  final String label;
  final String shortLabel;
  final double? maxAbsPcnt; // null = no filter (all)

  const PcntFilterOption({
    required this.label,
    required this.shortLabel,
    this.maxAbsPcnt,
  });
}

const List<PcntFilterOption> kPcntFilterOptions = [
  PcntFilterOption(
    label: 'All moves',
    shortLabel: 'All',
    maxAbsPcnt: null,
  ),
  PcntFilterOption(
    label: '2% and above',
    shortLabel: '2%+',
    maxAbsPcnt: 2.0,
  ),
  PcntFilterOption(
    label: '5% and above',
    shortLabel: '5%+',
    maxAbsPcnt: 5.0,
  ),
  PcntFilterOption(
    label: '10% and above',
    shortLabel: '10%+',
    maxAbsPcnt: 10.0,
  ),
];

// ─────────────────────────────────────────────
//  CONTROLLER
// ─────────────────────────────────────────────

class ScreenerHistoryController extends GetxController {
  final _supabase = Supabase.instance.client;

  final isLoading = true.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;
  final stockSummaries = <StockSummary>[].obs;
  final expandedStock = ''.obs;
  final selectedDate = DateTime.now().obs;

  final sentimentFilter = 'all'.obs;
  final searchQuery = ''.obs;

  // New: pcnt filter index (0 = all, 1 = ±2%, 2 = ±5%, 3 = ±10%)
  final pcntFilterIndex = 0.obs;

  final RxMap<String, List<ScreenerEntry>> stockDetails =
      <String, List<ScreenerEntry>>{}.obs;

  @override
  void onInit() {
    super.onInit();
    fetchData();
  }

  PcntFilterOption get currentPcntFilter =>
      kPcntFilterOptions[pcntFilterIndex.value];

// 09:25 IST = 03:55 UTC, 15:20 IST = 09:50 UTC — no midnight crossing, matches web logic
  DateTime get _startOfDay {
    final d = selectedDate.value;
    return DateTime.utc(d.year, d.month, d.day, 3, 55);
  }

  DateTime get _endOfDay {
    final d = selectedDate.value;
    return DateTime.utc(d.year, d.month, d.day, 9, 50);
  }

  Future<void> fetchData() async {
    isLoading.value = true;
    hasError.value = false;
    try {
      debugPrint(
          'Query window: ${_startOfDay.toIso8601String()} → ${_endOfDay.toIso8601String()}');
      final response = await _supabase
          .from('screener_history')
          .select()
          .gte('snapshot_time', _startOfDay.toIso8601String())
          .lt('snapshot_time', _endOfDay.toIso8601String())
          .order('snapshot_time', ascending: true);

      final entries =
          (response as List).map((e) => ScreenerEntry.fromMap(e)).toList();

      final Map<String, List<ScreenerEntry>> grouped = {};
      for (final entry in entries) {
        grouped.putIfAbsent(entry.stockName, () => []).add(entry);
      }

      stockSummaries.value = grouped.entries.map((e) {
        final sorted = e.value
          ..sort((a, b) => a.snapshotTime.compareTo(b.snapshotTime));
        final maxCount =
            sorted.map((s) => s.screenerCount).reduce((a, b) => a > b ? a : b);

        final firstPcnt = sorted.first.pcnt;

        final relativePcnts = (firstPcnt == null)
            ? <double>[]
            : sorted
                .where((s) => s.pcnt != null)
                .map((s) => s.pcnt! - firstPcnt)
                .toList();

        double? maxUp;
        double? maxDown;
        if (relativePcnts.isNotEmpty) {
          maxUp = relativePcnts.reduce((a, b) => a > b ? a : b);
          maxDown = relativePcnts.reduce((a, b) => a < b ? a : b);
        }

        final maxGain = (maxUp != null && maxUp > 0) ? maxUp : null;
        final maxLoss = (maxDown != null && maxDown < 0) ? maxDown : null;

        double? immDelta;
        if (firstPcnt != null) {
          for (int i = 1; i < sorted.length; i++) {
            final p = sorted[i].pcnt;
            if (p != null && (p - firstPcnt).abs() >= 0.01) {
              immDelta = p - firstPcnt;
              break;
            }
          }
        }

        return StockSummary(
          stockName: e.key,
          sec: sorted.first.sec,
          firstSeen: sorted.first.snapshotTime,
          firstSentiment: sorted.first.sentiment,
          firstClose: sorted.first.close,
          firstPcnt: firstPcnt,
          maxScreenerCount: maxCount,
          totalAppearances: sorted.length,
          allEntries: sorted,
          maxUpPcnt: maxUp,
          maxDownPcnt: maxDown,
          maxGainFromEntry: maxGain,
          maxLossFromEntry: maxLoss,
          immediateMoveDelta: immDelta,
        );
      }).toList()
        ..sort((a, b) => a.firstSeen.compareTo(b.firstSeen));

      isLoading.value = false;
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString();
      isLoading.value = false;
    }
  }

  void changeDate(int days) {
    selectedDate.value = selectedDate.value.add(Duration(days: days));
    expandedStock.value = '';
    stockDetails.clear();
    fetchData();
  }

  void toggleExpand(String stockName) {
    if (expandedStock.value == stockName) {
      expandedStock.value = '';
    } else {
      expandedStock.value = stockName;
    }
  }

  void cyclePcntFilter() {
    pcntFilterIndex.value =
        (pcntFilterIndex.value + 1) % kPcntFilterOptions.length;
  }

  void setPcntFilter(int index) {
    pcntFilterIndex.value = index;
  }

  List<StockSummary> get searchAndPcntFiltered {
    final maxAbs = currentPcntFilter.maxAbsPcnt;
    return stockSummaries.where((s) {
      final matchesSearch = searchQuery.value.isEmpty ||
          s.stockName.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
          (s.sec?.toLowerCase().contains(searchQuery.value.toLowerCase()) ??
              false);

      bool matchesPcnt = true;
      if (maxAbs != null && s.firstPcnt != null) {
        matchesPcnt = s.firstPcnt!.abs() >= maxAbs;
      }

      return matchesSearch && matchesPcnt;
    }).toList();
  }

  List<StockSummary> get filteredSummaries {
    return searchAndPcntFiltered.where((s) {
      return sentimentFilter.value == 'all' ||
          s.firstSentiment == sentimentFilter.value;
    }).toList();
  }

  Map<String, Map<String, int>> get accuracyStats {
    final result = <String, Map<String, int>>{
      'bullish': {'correct': 0, 'total': 0},
      'bearish': {'correct': 0, 'total': 0},
    };
    // Use filteredSummaries so accuracy reflects current filters
    for (final s in filteredSummaries) {
      if (s.immediateMoveDelta == null) continue;
      final key = s.firstSentiment;
      if (!result.containsKey(key)) continue;
      result[key]!['total'] = result[key]!['total']! + 1;
      final correct = (key == 'bullish' && s.immediateMoveDelta! > 0) ||
          (key == 'bearish' && s.immediateMoveDelta! < 0);
      if (correct) result[key]!['correct'] = result[key]!['correct']! + 1;
    }
    return result;
  }

  Map<String, int> get accuracyAll {
    final stats = accuracyStats;
    int correct = 0, total = 0;
    for (final v in stats.values) {
      correct += v['correct']!;
      total += v['total']!;
    }
    return {'correct': correct, 'total': total};
  }
}

// ─────────────────────────────────────────────
//  PAGE
// ─────────────────────────────────────────────

class ScreenerHistoryPage extends StatelessWidget {
  const ScreenerHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    final controller = Get.put(ScreenerHistoryController());

    return Obx(() {
      final isDark = themeController.isDarkMode;
      return _ScreenerHistoryView(
        isDark: isDark,
        controller: controller,
      );
    });
  }
}

class _ScreenerHistoryView extends StatefulWidget {
  final bool isDark;
  final ScreenerHistoryController controller;

  const _ScreenerHistoryView({required this.isDark, required this.controller});

  @override
  State<_ScreenerHistoryView> createState() => _ScreenerHistoryViewState();
}

class _ScreenerHistoryViewState extends State<_ScreenerHistoryView>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  late TabController _tabController;

  bool get isDark => widget.isDark;
  ScreenerHistoryController get ctrl => widget.controller;

  Color get bg => isDark ? const Color(0xFF0D0F14) : const Color(0xFFF5F6FA);
  Color get surface =>
      isDark ? const Color(0xFF161B26) : const Color(0xFFFFFFFF);
  Color get surfaceAlt =>
      isDark ? const Color(0xFF1E2636) : const Color(0xFFF0F2F8);
  Color get border =>
      isDark ? const Color(0xFF2A3347) : const Color(0xFFE2E6F0);
  Color get textPrimary =>
      isDark ? const Color(0xFFEDF0F7) : const Color(0xFF0D1117);
  Color get textSecondary =>
      isDark ? const Color(0xFF7B8FAD) : const Color(0xFF6B7897);
  Color get accent => const Color(0xFF4F7FFF);
  Color get bullish => const Color(0xFF00D4A0);
  Color get bearish => const Color(0xFFFF5370);

  Color sentimentColor(String s) => s == 'bullish' ? bullish : bearish;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) return;
      switch (_tabController.index) {
        case 0:
          ctrl.sentimentFilter.value = 'all';
          break;
        case 1:
          ctrl.sentimentFilter.value = 'bullish';
          break;
        case 2:
          ctrl.sentimentFilter.value = 'bearish';
          break;
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            // ── Collapsible top section: header + date bar + search/filter
            SliverAppBar(
              automaticallyImplyLeading: false,
              backgroundColor: surface,
              surfaceTintColor: Colors.transparent,
              shadowColor: Colors.transparent,
              floating: true,
              snap: true,
              pinned: false,
              expandedHeight: _collapsibleHeight,
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: OverflowBox(
                  alignment: Alignment.topCenter,
                  minHeight: 0,
                  maxHeight: double.infinity,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeader(),
                      _buildDateBar(),
                      _buildSearchAndFilterRow(),
                    ],
                  ),
                ),
              ),
              title: const SizedBox.shrink(),
              bottom: PreferredSize(
                preferredSize: Size.zero,
                child: Container(height: 0),
              ),
            ),
            // ── Pinned tab bar — always visible
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyTabBarDelegate(
                tabBar: _buildTabBarWidget(),
                color: surface,
                borderColor: border,
              ),
            ),
          ],
          body: _buildBody(),
        ),
      ),
    );
  }

  // Approximate height of header + date bar + search/filter
  double get _collapsibleHeight =>
      56 + // header row
      52 + // date bar
      130; // search + filter chips + padding

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                size: 20, color: textPrimary),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Screener History',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                        letterSpacing: -0.5)),
                Obx(() {
                  final count = ctrl.filteredSummaries.length;
                  final total = ctrl.stockSummaries.length;
                  return Text(
                    count == total
                        ? '$count stocks'
                        : '$count of $total stocks',
                    style: TextStyle(fontSize: 12, color: textSecondary),
                  );
                }),
              ],
            ),
          ),
          Obx(() => ctrl.isLoading.value
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child:
                      CircularProgressIndicator(strokeWidth: 2, color: accent))
              : IconButton(
                  onPressed: ctrl.fetchData,
                  icon: Icon(Icons.refresh_rounded, color: accent, size: 22))),
        ],
      ),
    );
  }

  Widget _buildDateBar() {
    return Obx(() {
      final date = ctrl.selectedDate.value;
      final isToday = _isToday(date);
      final isAfterToday = date.isAfter(DateTime.now());
      final label =
          isToday ? 'Today' : DateFormat('EEE, MMM d, yyyy').format(date);

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            _navBtn(Icons.chevron_left_rounded,
                onTap: () => ctrl.changeDate(-1)),
            Expanded(
              child: GestureDetector(
                onTap: () => _pickDate(context),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: accent.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 14, color: accent),
                      const SizedBox(width: 6),
                      Text(label,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: accent)),
                    ],
                  ),
                ),
              ),
            ),
            _navBtn(
              Icons.chevron_right_rounded,
              onTap: isAfterToday ? null : () => ctrl.changeDate(1),
              disabled: isAfterToday,
            ),
          ],
        ),
      );
    });
  }

  Widget _navBtn(IconData icon, {VoidCallback? onTap, bool disabled = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: surfaceAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border),
        ),
        child:
            Icon(icon, size: 22, color: disabled ? textSecondary : textPrimary),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: ctrl.selectedDate.value,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(
            primary: accent,
            surface: surface,
            onSurface: textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      ctrl.selectedDate.value = picked;
      ctrl.expandedStock.value = '';
      ctrl.stockDetails.clear();
      ctrl.fetchData();
    }
  }

  // Returns the raw TabBar widget (used by the sticky delegate)
  TabBar _buildTabBarWidget() {
    return TabBar(
      controller: _tabController,
      indicatorColor: accent,
      indicatorWeight: 2.5,
      labelColor: accent,
      unselectedLabelColor: textSecondary,
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      unselectedLabelStyle:
          const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      tabs: [
        Obx(() {
          final count = ctrl.searchAndPcntFiltered.length;
          return Tab(text: 'All${count > 0 ? '  $count' : ''}');
        }),
        Obx(() {
          final count = ctrl.searchAndPcntFiltered
              .where((s) => s.firstSentiment == 'bullish')
              .length;
          return Tab(text: 'Bullish${count > 0 ? '  $count' : ''}');
        }),
        Obx(() {
          final count = ctrl.searchAndPcntFiltered
              .where((s) => s.firstSentiment == 'bearish')
              .length;
          return Tab(text: 'Bearish${count > 0 ? '  $count' : ''}');
        }),
      ],
    );
  }

  // ── Combined search + pcnt filter row (part of collapsible area)
  Widget _buildSearchAndFilterRow() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            style: TextStyle(color: textPrimary, fontSize: 14),
            onChanged: (v) => ctrl.searchQuery.value = v,
            decoration: InputDecoration(
              hintText: 'Search stock or sector…',
              hintStyle: TextStyle(color: textSecondary, fontSize: 14),
              prefixIcon:
                  Icon(Icons.search_rounded, color: textSecondary, size: 20),
              suffixIcon: Obx(() => ctrl.searchQuery.value.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        ctrl.searchQuery.value = '';
                      },
                      child: Icon(Icons.close_rounded,
                          color: textSecondary, size: 18))
                  : const SizedBox()),
              filled: true,
              fillColor: surfaceAlt,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: accent),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Pcnt filter chips row
          _buildPcntFilterRow(),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildPcntFilterRow() {
    return Obx(() {
      final sentiment = ctrl.sentimentFilter.value;
      final selectedIdx = ctrl.pcntFilterIndex.value;

      // Direction label based on tab
      final String dirLabel;
      final Color dirColor;
      if (sentiment == 'bullish') {
        dirLabel = '↑ Bullish entry';
        dirColor = bullish;
      } else if (sentiment == 'bearish') {
        dirLabel = '↓ Bearish entry';
        dirColor = bearish;
      } else {
        dirLabel = '⟷ Entry %';
        dirColor = textSecondary;
      }

      return Row(
        children: [
          // Label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: dirColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: dirColor.withOpacity(0.2)),
            ),
            child: Text(
              dirLabel,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: dirColor,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Filter chips
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(kPcntFilterOptions.length, (i) {
                  final opt = kPcntFilterOptions[i];
                  final isSelected = selectedIdx == i;

                  // Choose color based on option and sentiment
                  Color chipColor;
                  if (isSelected) {
                    if (i == 0) {
                      chipColor = accent;
                    } else if (sentiment == 'bearish') {
                      chipColor = bearish;
                    } else {
                      chipColor = bullish;
                    }
                  } else {
                    chipColor = textSecondary;
                  }

                  return GestureDetector(
                    onTap: () => ctrl.setPcntFilter(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? chipColor.withOpacity(0.14)
                            : surfaceAlt,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              isSelected ? chipColor.withOpacity(0.45) : border,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Icon(opt.icon, size: 11, color: chipColor),
                          const SizedBox(width: 4),
                          Text(
                            opt.shortLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: chipColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildBody() {
    return Obx(() {
      if (ctrl.isLoading.value) return _buildSkeleton();
      if (ctrl.hasError.value) return _buildError();
      final items = ctrl.filteredSummaries;
      if (items.isEmpty) return _buildEmpty();
      return _buildList(items);
    });
  }

  Widget _buildList(List<StockSummary> items) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: items.length + 1,
      itemBuilder: (ctx, i) {
        if (i == 0) return _buildAccuracyBar();
        return _StockCard(
          summary: items[i - 1],
          isDark: isDark,
          surface: surface,
          surfaceAlt: surfaceAlt,
          border: border,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          accent: accent,
          bullish: bullish,
          bearish: bearish,
          sentimentColor: sentimentColor,
          controller: ctrl,
        );
      },
    );
  }

  Widget _buildAccuracyBar() {
    return Obx(() {
      // Show skeleton while loading
      if (ctrl.isLoading.value) {
        return _AccuracySkeleton(
          isDark: isDark,
          surface: surface,
          border: border,
          textSecondary: textSecondary,
        );
      }

      final filter = ctrl.sentimentFilter.value;
      final stats = ctrl.accuracyStats;
      final allStats = ctrl.accuracyAll;

      int correct, total;
      String label;

      if (filter == 'bullish') {
        correct = stats['bullish']!['correct']!;
        total = stats['bullish']!['total']!;
        label = 'Bullish prediction accuracy';
      } else if (filter == 'bearish') {
        correct = stats['bearish']!['correct']!;
        total = stats['bearish']!['total']!;
        label = 'Bearish prediction accuracy';
      } else {
        correct = allStats['correct']!;
        total = allStats['total']!;
        label = 'Overall prediction accuracy';
      }

      if (total == 0) return const SizedBox(height: 4);

      final pct = correct / total;
      final pctDisplay = (pct * 100).toStringAsFixed(0);
      final wrong = total - correct;

      // Extra context: show active pcnt filter in accuracy bar
      final pcntOpt = ctrl.currentPcntFilter;
      final hasFilter = pcntOpt.maxAbsPcnt != null;

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.track_changes_rounded,
                          size: 13, color: textSecondary),
                      const SizedBox(width: 5),
                      Text(label,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: textSecondary,
                              letterSpacing: 0.3)),
                      // Show active pcnt filter badge
                      if (hasFilter) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: accent.withOpacity(0.25)),
                          ),
                          child: Text(
                            pcntOpt.shortLabel,
                            style: TextStyle(
                                fontSize: 9,
                                color: accent,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '$pctDisplay%',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: pct >= 0.6
                                ? bullish
                                : pct >= 0.4
                                    ? Colors.orange
                                    : bearish),
                      ),
                      TextSpan(
                        text: '  $correct/$total',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 10,
                child: Row(
                  children: [
                    Flexible(
                      flex: correct,
                      child: Container(color: bullish),
                    ),
                    if (wrong > 0)
                      Flexible(
                        flex: wrong,
                        child: Container(color: bearish.withOpacity(0.5)),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _AccuracyLegendDot(color: bullish, label: '$correct confirmed'),
                const SizedBox(width: 14),
                _AccuracyLegendDot(
                    color: bearish.withOpacity(0.6), label: '$wrong reversed'),
                const Spacer(),
                Text('Next 5-min snapshot',
                    style: TextStyle(fontSize: 10, color: textSecondary)),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: 6,
      itemBuilder: (_, i) => i == 0
          ? _AccuracySkeleton(
              isDark: isDark,
              surface: surface,
              border: border,
              textSecondary: textSecondary,
            )
          : _SkeletonCard(isDark: isDark, surface: surface, border: border),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: bearish.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.wifi_off_rounded, color: bearish, size: 34),
            ),
            const SizedBox(height: 16),
            Text('Failed to load data',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textPrimary)),
            const SizedBox(height: 8),
            Text(ctrl.errorMessage.value,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: textSecondary)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: ctrl.fetchData,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    final hasFilter = ctrl.currentPcntFilter.maxAbsPcnt != null;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasFilter ? Icons.filter_alt_off_rounded : Icons.bar_chart_outlined,
            size: 64,
            color: textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            hasFilter ? 'No stocks in range' : 'No screener data',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            hasFilter
                ? 'Try a wider % filter or remove it\nto see all stocks.'
                : 'No stocks matched the filters on\n${DateFormat('MMM d, yyyy').format(ctrl.selectedDate.value)}',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: textSecondary),
          ),
          if (hasFilter) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => ctrl.setPcntFilter(0),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: accent.withOpacity(0.3)),
                ),
                child: Text(
                  'Clear % filter',
                  style: TextStyle(
                      fontSize: 13, color: accent, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _isToday(DateTime d) {
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }
}

// ─────────────────────────────────────────────
//  STICKY TAB BAR DELEGATE
// ─────────────────────────────────────────────

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color color;
  final Color borderColor;

  const _StickyTabBarDelegate({
    required this.tabBar,
    required this.color,
    required this.borderColor,
  });

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        border: Border(
          bottom: BorderSide(color: borderColor),
          // Subtle top shadow when content scrolls beneath
          top: overlapsContent
              ? BorderSide(color: borderColor.withOpacity(0.5))
              : BorderSide.none,
        ),
        boxShadow: overlapsContent
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                )
              ]
            : null,
      ),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) =>
      tabBar != oldDelegate.tabBar ||
      color != oldDelegate.color ||
      borderColor != oldDelegate.borderColor;
}

// ─────────────────────────────────────────────
//  ACCURACY SKELETON  (shown while loading)
// ─────────────────────────────────────────────

class _AccuracySkeleton extends StatefulWidget {
  final bool isDark;
  final Color surface, border, textSecondary;

  const _AccuracySkeleton({
    required this.isDark,
    required this.surface,
    required this.border,
    required this.textSecondary,
  });

  @override
  State<_AccuracySkeleton> createState() => _AccuracySkeletonState();
}

class _AccuracySkeletonState extends State<_AccuracySkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.35, end: 0.85)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shimmer =
        widget.isDark ? const Color(0xFF252D3D) : const Color(0xFFE8ECF5);

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: widget.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: widget.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: label + pct placeholder
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _shimmer(shimmer, 13, 13, radius: 3),
                      const SizedBox(width: 6),
                      _shimmer(shimmer, 160, 10),
                    ],
                  ),
                  _shimmer(shimmer, 60, 15),
                ],
              ),
              const SizedBox(height: 10),
              // Progress bar placeholder
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  height: 10,
                  width: double.infinity,
                  color: shimmer.withOpacity(_anim.value),
                ),
              ),
              const SizedBox(height: 10),
              // Legend row
              Row(
                children: [
                  _shimmer(shimmer, 80, 10),
                  const SizedBox(width: 14),
                  _shimmer(shimmer, 70, 10),
                  const Spacer(),
                  _shimmer(shimmer, 100, 10),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _shimmer(Color color, double w, double h, {double radius = 6}) =>
      Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: color.withOpacity(_anim.value),
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}

// ─────────────────────────────────────────────
//  ACCURACY LEGEND DOT
// ─────────────────────────────────────────────

class _AccuracyLegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _AccuracyLegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  STOCK CARD
// ─────────────────────────────────────────────

class _StockCard extends StatefulWidget {
  final StockSummary summary;
  final bool isDark;
  final Color surface,
      surfaceAlt,
      border,
      textPrimary,
      textSecondary,
      accent,
      bullish,
      bearish;
  final Color Function(String) sentimentColor;
  final ScreenerHistoryController controller;

  const _StockCard({
    required this.summary,
    required this.isDark,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    required this.bullish,
    required this.bearish,
    required this.sentimentColor,
    required this.controller,
  });

  @override
  State<_StockCard> createState() => _StockCardState();
}

class _StockCardState extends State<_StockCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    _expandAnim =
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOutCubic);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    widget.controller.toggleExpand(widget.summary.stockName);
    if (widget.controller.expandedStock.value == widget.summary.stockName) {
      _animCtrl.forward();
    } else {
      _animCtrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.summary;
    final sColor = widget.sentimentColor(s.firstSentiment);

    return Obx(() {
      final expanded = widget.controller.expandedStock.value == s.stockName;
      if (expanded && _animCtrl.status == AnimationStatus.dismissed) {
        _animCtrl.forward();
      } else if (!expanded && _animCtrl.status == AnimationStatus.completed) {
        _animCtrl.reverse();
      }

      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: widget.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: expanded ? sColor.withOpacity(0.4) : widget.border,
              width: expanded ? 1.5 : 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(widget.isDark ? 0.25 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            InkWell(
              onTap: _toggle,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Sentiment indicator bar
                        Container(
                          width: 3,
                          height: 44,
                          decoration: BoxDecoration(
                            color: sColor,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Stock name + sector
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.stockName.split(":")[1].split("-")[0],
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: widget.textPrimary,
                                    letterSpacing: -0.3),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Icon(Icons.access_time_rounded,
                                      size: 11, color: widget.textSecondary),
                                  const SizedBox(width: 3),
                                  Text(
                                    DateFormat('h:mm a').format(s.firstSeen),
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: widget.textSecondary),
                                  ),
                                  if (s.sec != null) ...[
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 5, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: widget.surfaceAlt,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          border:
                                              Border.all(color: widget.border),
                                        ),
                                        child: Text(
                                          s.sec!,
                                          style: TextStyle(
                                              fontSize: 10,
                                              color: widget.textSecondary,
                                              fontWeight: FontWeight.w500),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        // LTP + % change
                        SizedBox(
                          width: 88,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (s.firstClose != null)
                                Text(
                                  '₹${s.firstClose!.toStringAsFixed(2)}',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: widget.textPrimary),
                                ),
                              if (s.firstPcnt != null) ...[
                                const SizedBox(height: 2),
                                _PcntBadge(
                                  pcnt: s.firstPcnt!,
                                  bullish: widget.bullish,
                                  bearish: widget.bearish,
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(width: 6),

                        // Count badge + chevron
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ScreenerCountBadge(
                              count: s.maxScreenerCount,
                              appearances: s.totalAppearances,
                              color: widget.accent,
                            ),
                            const SizedBox(height: 4),
                            AnimatedRotation(
                              turns: expanded ? 0.5 : 0,
                              duration: const Duration(milliseconds: 280),
                              child: Icon(Icons.expand_more_rounded,
                                  color: widget.textSecondary, size: 18),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // ── Range + P&L + immediate move strip
                    const SizedBox(height: 8),
                    _RangeProgressStrip(
                      summary: s,
                      bullish: widget.bullish,
                      bearish: widget.bearish,
                      textSecondary: widget.textSecondary,
                      textPrimary: widget.textPrimary,
                      surfaceAlt: widget.surfaceAlt,
                      border: widget.border,
                    ),
                  ],
                ),
              ),
            ),

            // ── Expanded detail
            SizeTransition(
              sizeFactor: _expandAnim,
              child: _ExpandedDetail(
                summary: s,
                isDark: widget.isDark,
                surface: widget.surface,
                surfaceAlt: widget.surfaceAlt,
                border: widget.border,
                textPrimary: widget.textPrimary,
                textSecondary: widget.textSecondary,
                accent: widget.accent,
                bullish: widget.bullish,
                bearish: widget.bearish,
                sentimentColor: widget.sentimentColor,
              ),
            ),
          ],
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────
//  RANGE PROGRESS STRIP
// ─────────────────────────────────────────────

class _RangeProgressStrip extends StatelessWidget {
  final StockSummary summary;
  final Color bullish, bearish, textSecondary, textPrimary, surfaceAlt, border;

  const _RangeProgressStrip({
    required this.summary,
    required this.bullish,
    required this.bearish,
    required this.textSecondary,
    required this.textPrimary,
    required this.surfaceAlt,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final hasRange = s.maxDownPcnt != null && s.maxUpPcnt != null;
    final hasGainLoss =
        s.maxGainFromEntry != null || s.maxLossFromEntry != null;
    final hasImmediate = s.immediateMoveDelta != null;

    if (!hasRange && !hasGainLoss && !hasImmediate) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasRange) ...[
          _RangeBar(
            low: s.maxDownPcnt!,
            high: s.maxUpPcnt!,
            entry: s.firstPcnt ?? 0.0,
            bullish: bullish,
            bearish: bearish,
            textSecondary: textSecondary,
          ),
          const SizedBox(height: 5),
        ],
        if (hasGainLoss) ...[
          _PLRow(
            gain: s.maxGainFromEntry,
            loss: s.maxLossFromEntry,
            bullish: bullish,
            bearish: bearish,
            textSecondary: textSecondary,
          ),
          const SizedBox(height: 4),
        ],
        if (hasImmediate)
          _ImmediateMoveRow(
            delta: s.immediateMoveDelta!,
            sentiment: s.firstSentiment,
            firstClose: s.firstClose,
            bullish: bullish,
            bearish: bearish,
            textSecondary: textSecondary,
          ),
      ],
    );
  }
}

class _RangeBar extends StatelessWidget {
  final double low, high, entry;
  final Color bullish, bearish, textSecondary;

  const _RangeBar({
    required this.low,
    required this.high,
    required this.entry,
    required this.bullish,
    required this.bearish,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final span = high - low;
    final entryPos = span > 0 ? ((entry - low) / span).clamp(0.0, 1.0) : 0.5;
    final zeroPos = span > 0 ? ((0.0 - low) / span).clamp(0.0, 1.0) : 0.5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${low.toStringAsFixed(2)}%',
                style: TextStyle(
                    fontSize: 9.5,
                    color: bearish,
                    fontWeight: FontWeight.w600)),
            Text('Range', style: TextStyle(fontSize: 9, color: textSecondary)),
            Text('+${high.toStringAsFixed(2)}%',
                style: TextStyle(
                    fontSize: 9.5,
                    color: bullish,
                    fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 3),
        LayoutBuilder(builder: (ctx, constraints) {
          final totalWidth = constraints.maxWidth;
          final entryX = totalWidth * entryPos;
          final zeroX = totalWidth * zeroPos;

          return SizedBox(
            height: 6,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: Row(
                    children: [
                      Flexible(
                        flex: (zeroPos * 100).round().clamp(0, 100),
                        child: Container(color: bearish.withOpacity(0.22)),
                      ),
                      Flexible(
                        flex: ((1 - zeroPos) * 100).round().clamp(0, 100),
                        child: Container(color: bullish.withOpacity(0.18)),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: zeroX - 0.75,
                  top: 0,
                  child: Container(
                      width: 1.5,
                      height: 6,
                      color: textSecondary.withOpacity(0.4)),
                ),
                Positioned(
                  left: entryX - 4,
                  top: -1,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: entry >= 0 ? bullish : bearish,
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _PLRow extends StatelessWidget {
  final double? gain, loss;
  final Color bullish, bearish, textSecondary;

  const _PLRow({
    this.gain,
    this.loss,
    required this.bullish,
    required this.bearish,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (gain != null)
          _MiniChip(
            label: '+${gain!.toStringAsFixed(2)}%',
            icon: Icons.trending_up_rounded,
            color: bullish,
            prefix: 'Max gain',
          ),
        if (gain != null && loss != null) const SizedBox(width: 6),
        if (loss != null)
          _MiniChip(
            label: '${loss!.toStringAsFixed(2)}%',
            icon: Icons.trending_down_rounded,
            color: bearish,
            prefix: 'Max loss',
          ),
        const Spacer(),
      ],
    );
  }
}

class _ImmediateMoveRow extends StatelessWidget {
  final double delta;
  final String sentiment;
  final double? firstClose;
  final Color bullish, bearish, textSecondary;

  const _ImmediateMoveRow({
    required this.delta,
    required this.sentiment,
    this.firstClose,
    required this.bullish,
    required this.bearish,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final confirmed = (sentiment == 'bullish' && delta > 0) ||
        (sentiment == 'bearish' && delta < 0);
    final color = confirmed ? bullish : bearish;
    final icon = confirmed ? Icons.bolt_rounded : Icons.warning_amber_rounded;
    final sign = delta >= 0 ? '+' : '';

    String? priceDelta;
    if (firstClose != null && firstClose! > 0) {
      final priceChange = firstClose! * delta / 100;
      priceDelta =
          '${priceChange >= 0 ? '+' : ''}₹${priceChange.abs().toStringAsFixed(2)}';
    }

    return Row(
      children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 3),
        Text('Next snap',
            style: TextStyle(
                fontSize: 9.5,
                color: textSecondary,
                fontWeight: FontWeight.w500)),
        const SizedBox(width: 4),
        Text('$sign${delta.toStringAsFixed(2)}%',
            style: TextStyle(
                fontSize: 10, color: color, fontWeight: FontWeight.w700)),
        if (priceDelta != null) ...[
          const SizedBox(width: 4),
          Text(priceDelta,
              style: TextStyle(
                  fontSize: 9.5,
                  color: color.withOpacity(0.75),
                  fontWeight: FontWeight.w600)),
        ],
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Text(
            confirmed ? 'Confirmed' : 'Reversed',
            style: TextStyle(
                fontSize: 9,
                color: color,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2),
          ),
        ),
      ],
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label, prefix;
  final IconData icon;
  final Color color;

  const _MiniChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.prefix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 2, 6, 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color.withOpacity(0.85)),
          const SizedBox(width: 2),
          Text(prefix,
              style: TextStyle(
                  fontSize: 9,
                  color: color.withOpacity(0.7),
                  fontWeight: FontWeight.w500)),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(
                  fontSize: 10, color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SCREENER COUNT BADGE
// ─────────────────────────────────────────────

class _ScreenerCountBadge extends StatelessWidget {
  final int count;
  final int appearances;
  final Color color;

  const _ScreenerCountBadge({
    required this.count,
    required this.appearances,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('$count',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800, color: color)),
        ),
        const SizedBox(height: 2),
        Text('${appearances}×',
            style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: color.withOpacity(0.7))),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  PCNT BADGE
// ─────────────────────────────────────────────

class _PcntBadge extends StatelessWidget {
  final double pcnt;
  final Color bullish, bearish;

  const _PcntBadge(
      {required this.pcnt, required this.bullish, required this.bearish});

  @override
  Widget build(BuildContext context) {
    final isUp = pcnt >= 0;
    final color = isUp ? bullish : bearish;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${isUp ? '+' : ''}${pcnt.toStringAsFixed(2)}%',
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  EXPANDED DETAIL
// ─────────────────────────────────────────────

class _ExpandedDetail extends StatelessWidget {
  final StockSummary summary;
  final bool isDark;
  final Color surface,
      surfaceAlt,
      border,
      textPrimary,
      textSecondary,
      accent,
      bullish,
      bearish;
  final Color Function(String) sentimentColor;

  const _ExpandedDetail({
    required this.summary,
    required this.isDark,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    required this.bullish,
    required this.bearish,
    required this.sentimentColor,
  });

  Color get liveAccent => const Color(0xFFFF9F43);

  @override
  Widget build(BuildContext context) {
    final entries = summary.allEntries;
    final hasClose = entries.any((e) => e.close != null);

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: border)),
      ),
      child: Column(
        children: [
          if (hasClose && entries.length > 1) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  Icon(Icons.show_chart_rounded,
                      size: 14, color: textSecondary),
                  const SizedBox(width: 6),
                  Text('Price Movement',
                      style: TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3)),
                ],
              ),
            ),
            _PriceChart(
              entries: entries,
              isDark: isDark,
              accent: accent,
              bullish: bullish,
              bearish: bearish,
              textSecondary: textSecondary,
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Icon(Icons.timeline_rounded, size: 14, color: textSecondary),
                const SizedBox(width: 6),
                Text('Appearance Timeline',
                    style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ...entries.asMap().entries.map((e) {
            final idx = e.key;
            final entry = e.value;
            final prev = idx > 0 ? entries[idx - 1] : null;
            double? delta;
            if (entry.close != null && prev?.close != null) {
              delta = entry.close! - prev!.close!;
            }
            return _TimelineRow(
              entry: entry,
              isFirst: idx == 0,
              isLast: idx == entries.length - 1,
              delta: delta,
              isDark: isDark,
              surfaceAlt: surfaceAlt,
              border: border,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              accent: accent,
              bullish: bullish,
              bearish: bearish,
              sentimentColor: sentimentColor,
            );
          }),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: surfaceAlt,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Screeners',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 6),
                  Text(entries.first.screenerNames,
                      style: TextStyle(fontSize: 13, color: textPrimary)),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => BrowserLite_V(
                                  "https://in.tradingview.com/chart/?symbol=NSE%3A${summary.stockName.split(":")[1].split("-")[0]}")));
                    },
                    icon: Icon(Icons.electric_bolt_rounded,
                        size: 15, color: liveAccent),
                    label: Text('Live Chart',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: liveAccent)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: liveAccent.withOpacity(0.45)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        Get.toNamed('/stocks/${summary.stockName}'),
                    icon: Icon(Icons.candlestick_chart_outlined,
                        size: 15, color: accent),
                    label: Text('Stock Details',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: accent)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: accent.withOpacity(0.45)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  PRICE CHART
// ─────────────────────────────────────────────

class _PriceChart extends StatelessWidget {
  final List<ScreenerEntry> entries;
  final bool isDark;
  final Color accent, bullish, bearish, textSecondary;

  const _PriceChart({
    required this.entries,
    required this.isDark,
    required this.accent,
    required this.bullish,
    required this.bearish,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final chartData = entries
        .where((e) => e.close != null)
        .map((e) => ChartData(e.snapshotTime, e.close!))
        .toList();

    if (chartData.isEmpty) return const SizedBox();

    final first = chartData.first.close;
    final last = chartData.last.close;
    final isUp = last >= first;
    final lineColor = isUp ? bullish : bearish;

    return SizedBox(
      height: 140,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
        child: SfCartesianChart(
          margin: EdgeInsets.zero,
          plotAreaBorderWidth: 0,
          primaryXAxis: DateTimeAxis(
            isVisible: true,
            axisLine: const AxisLine(width: 0),
            majorGridLines: const MajorGridLines(width: 0),
            majorTickLines: const MajorTickLines(size: 0),
            labelStyle: TextStyle(fontSize: 10, color: textSecondary),
            dateFormat: DateFormat('h:mm'),
            intervalType: DateTimeIntervalType.auto,
            edgeLabelPlacement: EdgeLabelPlacement.shift,
          ),
          primaryYAxis: NumericAxis(
            isVisible: true,
            axisLine: const AxisLine(width: 0),
            majorGridLines: MajorGridLines(
                width: 1,
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.black.withOpacity(0.06)),
            majorTickLines: const MajorTickLines(size: 0),
            labelStyle: TextStyle(fontSize: 10, color: textSecondary),
            numberFormat: NumberFormat.compact(),
          ),
          series: <CartesianSeries>[
            AreaSeries<ChartData, DateTime>(
              dataSource: chartData,
              xValueMapper: (d, _) => d.time,
              yValueMapper: (d, _) => d.close,
              color: lineColor.withOpacity(0.1),
              borderColor: lineColor,
              borderWidth: 2,
              markerSettings: MarkerSettings(
                isVisible: chartData.length <= 10,
                shape: DataMarkerType.circle,
                height: 5,
                width: 5,
                color: lineColor,
                borderWidth: 0,
              ),
            ),
          ],
          tooltipBehavior: TooltipBehavior(
            enable: true,
            format: 'point.y',
            color: isDark ? const Color(0xFF1E2636) : const Color(0xFF0D1117),
            textStyle: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  TIMELINE ROW
// ─────────────────────────────────────────────

class _TimelineRow extends StatelessWidget {
  final ScreenerEntry entry;
  final bool isFirst, isLast;
  final double? delta;
  final bool isDark;
  final Color surfaceAlt,
      border,
      textPrimary,
      textSecondary,
      accent,
      bullish,
      bearish;
  final Color Function(String) sentimentColor;

  const _TimelineRow({
    required this.entry,
    required this.isFirst,
    required this.isLast,
    required this.delta,
    required this.isDark,
    required this.surfaceAlt,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    required this.bullish,
    required this.bearish,
    required this.sentimentColor,
  });

  @override
  Widget build(BuildContext context) {
    final sColor = sentimentColor(entry.sentiment);
    final hasUp = delta != null && delta! > 0;
    final hasDown = delta != null && delta! < 0;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 36,
            child: Column(
              children: [
                if (!isFirst)
                  Expanded(
                      child: Center(child: Container(width: 2, color: border))),
                Container(
                  width: 10,
                  height: 10,
                  decoration:
                      BoxDecoration(color: sColor, shape: BoxShape.circle),
                ),
                if (!isLast)
                  Expanded(
                      child: Center(child: Container(width: 2, color: border))),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 16, bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: isFirst ? sColor.withOpacity(0.07) : surfaceAlt,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: isFirst ? sColor.withOpacity(0.3) : border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('h:mm a').format(entry.snapshotTime),
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${entry.screenerCount} screener${entry.screenerCount != 1 ? 's' : ''}',
                            style:
                                TextStyle(fontSize: 11, color: textSecondary),
                          ),
                        ],
                      ),
                    ),
                    if (entry.close != null) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${entry.close!.toStringAsFixed(2)}',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: textPrimary),
                          ),
                          if (entry.pcnt != null) ...[
                            const SizedBox(height: 2),
                            _PcntBadge(
                              pcnt: entry.pcnt!,
                              bullish: bullish,
                              bearish: bearish,
                            ),
                          ] else if (delta != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  hasUp
                                      ? Icons.arrow_upward_rounded
                                      : hasDown
                                          ? Icons.arrow_downward_rounded
                                          : Icons.remove_rounded,
                                  size: 11,
                                  color: hasUp
                                      ? bullish
                                      : hasDown
                                          ? bearish
                                          : textSecondary,
                                ),
                                Text(
                                  '${delta! >= 0 ? '+' : ''}${delta!.toStringAsFixed(2)}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: hasUp
                                          ? bullish
                                          : hasDown
                                              ? bearish
                                              : textSecondary,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (isFirst)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: sColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('FIRST',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: sColor,
                                letterSpacing: 0.5)),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SKELETON CARD
// ─────────────────────────────────────────────

class _SkeletonCard extends StatefulWidget {
  final bool isDark;
  final Color surface, border;

  const _SkeletonCard(
      {required this.isDark, required this.surface, required this.border});

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
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shimmer =
        widget.isDark ? const Color(0xFF252D3D) : const Color(0xFFE8ECF5);
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: widget.border),
        ),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 44,
              decoration: BoxDecoration(
                color: shimmer.withOpacity(_anim.value),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _shimmerBox(shimmer, 130, 14),
                  const SizedBox(height: 6),
                  _shimmerBox(shimmer, 80, 10),
                  const SizedBox(height: 8),
                  _shimmerBox(shimmer, double.infinity, 6),
                  const SizedBox(height: 5),
                  _shimmerBox(shimmer, 160, 10),
                  const SizedBox(height: 4),
                  _shimmerBox(shimmer, 120, 10),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _shimmerBox(shimmer, 70, 14),
                const SizedBox(height: 6),
                _shimmerBox(shimmer, 45, 10),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _shimmerBox(Color color, double w, double h) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
            color: color.withOpacity(_anim.value),
            borderRadius: BorderRadius.circular(6)),
      );
}
