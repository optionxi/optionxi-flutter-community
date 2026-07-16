import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:optionxi/Main_Pages/Achivements/fastapi_achivement.dart';
import 'package:optionxi/Main_Pages/Sectorwise/act_sectorwise_stocks.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design tokens
// ─────────────────────────────────────────────────────────────────────────────
class _T {
  // Accent
  static const bullishDark = Color(0xFF00D4A8);
  static const bullishLight = Color(0xFF00897B);
  static const bearishDark = Color(0xFFFF5C72);
  static const bearishLight = Color(0xFFD32F2F);
  static const warningDark = Color(0xFFF5A623);
  static const warningLight = Color(0xFFE65100);

  // Surfaces – dark
  static const surfaceDark = Color(0xFF0D1117);
  static const cardDark = Color(0xFF161B22);
  static const elevatedDark = Color(0xFF1C2230);
  static const borderDark = Color(0xFF21262D);

  // Surfaces – light
  static const surfaceLight = Color(0xFFF4F6F9);
  static const cardLight = Color(0xFFFFFFFF);
  static const elevatedLight = Color(0xFFEFF3F8);
  static const borderLight = Color(0xFFDEE3EC);

  // Text – dark
  static const p1Dark = Color(0xFFE6EDF3);
  static const p2Dark = Color(0xFF8B949E);
  static const p3Dark = Color(0xFF484F58);

  // Text – light
  static const p1Light = Color(0xFF0D1117);
  static const p2Light = Color(0xFF57606A);
  static const p3Light = Color(0xFFAFB8C1);

  static const r = 16.0;
  static const rSm = 10.0;
  static const rLg = 20.0;
}

// ─────────────────────────────────────────────────────────────────────────────
class SectorAnalysisPage extends StatefulWidget {
  const SectorAnalysisPage({Key? key}) : super(key: key);

  @override
  State<SectorAnalysisPage> createState() => _SectorAnalysisPageState();
}

class _SectorAnalysisPageState extends State<SectorAnalysisPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final SupabaseClient _supabase = Supabase.instance.client;

  Map<String, List<StockData>> _sectorData = {};
  List<SectorTrend> _bullishSectors = [];
  List<SectorTrend> _bearishSectors = [];
  bool _isLoading = true;
  String? _error;

  late AnimationController _breadthAnimCtrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _breadthAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fetchData();
    AchievementEvents.openedSectorPulse();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _breadthAnimCtrl.dispose();
    super.dispose();
  }

  // ─── Theme helpers ────────────────────────────────────────────────────────
  bool get _dark => Theme.of(context).brightness == Brightness.dark;

  Color get _bull => _dark ? _T.bullishDark : _T.bullishLight;
  Color get _bear => _dark ? _T.bearishDark : _T.bearishLight;
  Color get _warn => _dark ? _T.warningDark : _T.warningLight;

  Color get _surface => _dark ? _T.surfaceDark : _T.surfaceLight;
  Color get _card => _dark ? _T.cardDark : _T.cardLight;
  Color get _elevated => _dark ? _T.elevatedDark : _T.elevatedLight;
  Color get _border => _dark ? _T.borderDark : _T.borderLight;

  Color get _t1 => _dark ? _T.p1Dark : _T.p1Light;
  Color get _t2 => _dark ? _T.p2Dark : _T.p2Light;
  Color get _t3 => _dark ? _T.p3Dark : _T.p3Light;

  Color _accentFor(bool isBullish) => isBullish ? _bull : _bear;

  // ─── Data ─────────────────────────────────────────────────────────────────
  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _supabase
          .from('generated_values')
          .select(
              'stckname, pcnt, close, high, low, open, vol, sec, rsi14, ema20, sma20')
          .not('sec', 'is', null);

      final data = response as List<dynamic>;
      final Map<String, List<StockData>> temp = {};

      for (final item in data) {
        final stock = StockData.fromJson(item);
        final sector = stock.sector ?? 'Others';
        temp.putIfAbsent(sector, () => []).add(stock);
      }

      final List<SectorTrend> bulls = [];
      final List<SectorTrend> bears = [];

      temp.forEach((sector, stocks) {
        final t = _calcTrend(sector, stocks);
        (t.bullishScore > 0 ? bulls : bears).add(t);
      });

      bulls.sort((a, b) => b.bullishScore.compareTo(a.bullishScore));
      bears.sort((a, b) => a.bearishScore.compareTo(b.bearishScore));

      setState(() {
        _sectorData = temp;
        _bullishSectors = bulls;
        _bearishSectors = bears;
        _isLoading = false;
      });

      _breadthAnimCtrl.forward(from: 0);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  SectorTrend _calcTrend(String sector, List<StockData> stocks) {
    final n = stocks.length;
    final pos = stocks.where((s) => s.pcnt > 0).length;
    final neg = stocks.where((s) => s.pcnt < 0).length;
    final a5 = stocks.where((s) => s.pcnt > 5).length;
    final a2 = stocks.where((s) => s.pcnt > 2).length;
    final b2 = stocks.where((s) => s.pcnt < -2).length;
    final b5 = stocks.where((s) => s.pcnt < -5).length;
    final avg = stocks.fold(0.0, (s, x) => s + x.pcnt) / n;
    final vol = stocks.fold(0.0, (s, x) => s + x.vol);

    double bull = 0, bear = 0;
    if (avg > 0) {
      bull = (pos / n * 40) + (a5 / n * 30) + (a2 / n * 20) + avg * 2;
    } else {
      bear = -(neg / n * 40) - (b5 / n * 30) - (b2 / n * 20) + avg * 2;
    }

    return SectorTrend(
      sectorName: sector,
      totalStocks: n,
      positiveStocks: pos,
      negativeStocks: neg,
      above5Percent: a5,
      above2Percent: a2,
      below2Percent: b2,
      below5Percent: b5,
      averageChange: avg,
      bullishScore: bull,
      bearishScore: bear,
      totalVolume: vol,
    );
  }

  // ─── Root build ───────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? _buildSkeleton()
                  : _error != null
                      ? _buildError()
                      : _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
      decoration: BoxDecoration(
        color: _card,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          // Back
          _iconBtn(Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.of(context).maybePop()),
          const SizedBox(width: 14),

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sector Pulse',
                  style: TextStyle(
                    color: _t1,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),
                Text(
                  'Market breadth by sector',
                  style: TextStyle(
                      color: _t2, fontSize: 12, fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),

          // Mood pill
          if (!_isLoading && _error == null) _buildMoodPill(),
          const SizedBox(width: 8),

          // Refresh
          _iconBtn(Icons.refresh_rounded, onTap: () {
            HapticFeedback.lightImpact();
            _fetchData();
          }),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _elevated,
          borderRadius: BorderRadius.circular(_T.rSm),
          border: Border.all(color: _border),
        ),
        child: Icon(icon, size: 16, color: _t2),
      ),
    );
  }

  Widget _buildMoodPill() {
    final total = _bullishSectors.length + _bearishSectors.length;
    if (total == 0) return const SizedBox.shrink();
    final bullPct = (_bullishSectors.length / total * 100).round();
    final bearPct = 100 - bullPct;
    // Show the DOMINANT direction and its percentage
    final isBullDominant = bullPct >= bearPct;
    final dominantPct = isBullDominant ? bullPct : bearPct;
    final c = isBullDominant ? _bull : _bear;
    final label = isBullDominant ? '$dominantPct% Bull' : '$dominantPct% Bear';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
                color: c,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2),
          ),
        ],
      ),
    );
  }

  // ─── Body ─────────────────────────────────────────────────────────────────
  Widget _buildBody() {
    return Column(
      children: [
        _buildBreadthBar(),
        _buildTabBar(),
        Expanded(
          child: AnimatedBuilder(
            animation: _tabController,
            builder: (ctx, _) => IndexedStack(
              index: _tabController.index,
              children: [
                _buildList(_bullishSectors, isBullish: true),
                _buildList(_bearishSectors, isBullish: false),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Breadth bar ──────────────────────────────────────────────────────────
  Widget _buildBreadthBar() {
    final total = (_bullishSectors.length + _bearishSectors.length).toDouble();
    if (total == 0) return const SizedBox.shrink();
    final bullRatio = _bullishSectors.length / total;
    final bearRatio = _bearishSectors.length / total;
    final bullPct = (bullRatio * 100).round();
    final bearPct = 100 - bullPct;

    return AnimatedBuilder(
      animation:
          CurvedAnimation(parent: _breadthAnimCtrl, curve: Curves.easeOutCubic),
      builder: (ctx, _) {
        final t = CurvedAnimation(
                parent: _breadthAnimCtrl, curve: Curves.easeOutCubic)
            .value;
        return Container(
          margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(_T.r),
            border: Border.all(color: _border),
          ),
          child: Column(
            children: [
              // Chips row: bull on left, bear on right, both showing their %
              Row(
                children: [
                  _breadthChip(
                    '${_bullishSectors.length} Bullish',
                    _bull,
                    Icons.trending_up_rounded,
                  ),
                  const SizedBox(width: 8),
                  _breadthChip(
                    '${_bearishSectors.length} Bearish',
                    _bear,
                    Icons.trending_down_rounded,
                  ),
                  const Spacer(),
                  // Show BOTH percentages side by side
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '$bullPct% ↑',
                          style: TextStyle(
                            color: _bull,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text: '  ·  ',
                          style: TextStyle(
                            color: _t3,
                            fontSize: 12,
                          ),
                        ),
                        TextSpan(
                          text: '$bearPct% ↓',
                          style: TextStyle(
                            color: _bear,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Segmented bar — proportional to actual sector split
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LayoutBuilder(
                  builder: (ctx, bc) {
                    final bullWidth = bc.maxWidth * bullRatio * t;
                    final bearWidth = bc.maxWidth * bearRatio * t;
                    // 2px gap between segments so tiny side is still visible
                    final gap = (bullWidth > 2 && bearWidth > 2) ? 2.0 : 0.0;
                    return SizedBox(
                      height: 8,
                      child: Row(
                        children: [
                          if (bullWidth > 0)
                            Container(
                              width:
                                  (bullWidth - gap / 2).clamp(0.0, bc.maxWidth),
                              height: 8,
                              decoration: BoxDecoration(
                                color: _bull,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(4),
                                  bottomLeft: const Radius.circular(4),
                                  topRight: gap == 0
                                      ? const Radius.circular(4)
                                      : Radius.zero,
                                  bottomRight: gap == 0
                                      ? const Radius.circular(4)
                                      : Radius.zero,
                                ),
                              ),
                            ),
                          SizedBox(width: gap),
                          if (bearWidth > 0)
                            Container(
                              width:
                                  (bearWidth - gap / 2).clamp(0.0, bc.maxWidth),
                              height: 8,
                              decoration: BoxDecoration(
                                color: _bear,
                                borderRadius: BorderRadius.only(
                                  topRight: const Radius.circular(4),
                                  bottomRight: const Radius.circular(4),
                                  topLeft: gap == 0
                                      ? const Radius.circular(4)
                                      : Radius.zero,
                                  bottomLeft: gap == 0
                                      ? const Radius.circular(4)
                                      : Radius.zero,
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
          ),
        );
      },
    );
  }

  Widget _breadthChip(String label, Color c, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: c),
        const SizedBox(width: 4),
        Text(label,
            style:
                TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  // ─── Tab bar ──────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      height: 46,
      decoration: BoxDecoration(
        color: _elevated,
        borderRadius: BorderRadius.circular(_T.r),
        border: Border.all(color: _border),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(_T.r - 2),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_dark ? 0.3 : 0.07),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(3),
        dividerColor: Colors.transparent,
        labelPadding: EdgeInsets.zero,
        labelColor: _t1,
        unselectedLabelColor: _t2,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        tabs: [
          _tab('Bullish', Icons.trending_up_rounded, _bullishSectors.length,
              _bull),
          _tab('Bearish', Icons.trending_down_rounded, _bearishSectors.length,
              _bear),
        ],
      ),
    );
  }

  Tab _tab(String label, IconData icon, int count, Color c) => Tab(
        height: 46,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: c),
            const SizedBox(width: 6),
            Text(label),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: c.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('$count',
                  style: TextStyle(
                      color: c, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );

  // ─── Sector list ──────────────────────────────────────────────────────────
  Widget _buildList(List<SectorTrend> sectors, {required bool isBullish}) {
    if (sectors.isEmpty) return _buildEmpty(isBullish);
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      itemCount: sectors.length,
      itemBuilder: (ctx, i) =>
          _buildCard(sectors[i], isBullish: isBullish, index: i),
    );
  }

  Widget _buildCard(SectorTrend s,
      {required bool isBullish, required int index}) {
    final accent = _accentFor(isBullish);
    final strength = isBullish
        ? (s.bullishScore / 100).clamp(0.0, 1.0)
        : (s.bearishScore.abs() / 100).clamp(0.0, 1.0);
    final upPct = (s.positiveStocks / s.totalStocks * 100).round();
    final downPct = (s.negativeStocks / s.totalStocks * 100).round();
    final adRatio = s.negativeStocks > 0
        ? s.positiveStocks / s.negativeStocks
        : s.positiveStocks.toDouble();

    final String momentumLabel;
    if (strength > 0.7) {
      momentumLabel = isBullish ? 'Strong Rally' : 'Heavy Sell-off';
    } else if (strength > 0.4) {
      momentumLabel = isBullish ? 'Advancing' : 'Declining';
    } else {
      momentumLabel = isBullish ? 'Mild Uptick' : 'Mild Dip';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(_T.rLg),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            Get.to(() => SectorStocksPage(
                  sectorName: s.sectorName,
                  stocks: _sectorData[s.sectorName] ?? [],
                ));
          },
          borderRadius: BorderRadius.circular(_T.rLg),
          child: Ink(
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(_T.rLg),
              border: Border.all(color: _border),
            ),
            child: Column(
              children: [
                // ── Header ────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + label
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.sectorName,
                              style: TextStyle(
                                color: _t1,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Text(
                                  '${s.totalStocks} stocks',
                                  style: TextStyle(
                                      color: _t2,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 7),
                                  child: Container(
                                    width: 3,
                                    height: 3,
                                    decoration: BoxDecoration(
                                        color: _t3, shape: BoxShape.circle),
                                  ),
                                ),
                                Text(
                                  momentumLabel,
                                  style: TextStyle(
                                    color: accent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Avg change
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(color: accent.withOpacity(0.3)),
                            ),
                            child: Text(
                              '${isBullish ? '+' : ''}${s.averageChange.toStringAsFixed(2)}%',
                              style: TextStyle(
                                color: accent,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'avg change',
                            style: TextStyle(
                                color: _t3,
                                fontSize: 10,
                                fontWeight: FontWeight.w400),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                Divider(height: 1, color: _border),

                // ── Stats row ─────────────────────────────────────────
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  child: Row(
                    children: [
                      _statCell(
                          value: '${s.positiveStocks}',
                          sub: '+$upPct%',
                          label: 'Gainers',
                          color: _bull,
                          icon: Icons.arrow_upward_rounded),
                      _vDivider(),
                      _statCell(
                          value: '${s.negativeStocks}',
                          sub: '-$downPct%',
                          label: 'Losers',
                          color: _bear,
                          icon: Icons.arrow_downward_rounded),
                      _vDivider(),
                      _adCell(adRatio),
                    ],
                  ),
                ),

                // ── Strength footer ───────────────────────────────────
                _buildStrengthFooter(strength, accent),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statCell({
    required String value,
    required String sub,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 14, color: color.withOpacity(0.7)),
          const SizedBox(height: 5),
          Text(value,
              style: TextStyle(
                  color: _t1,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5)),
          Text(sub,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 1),
          Text(label,
              style: TextStyle(
                  color: _t2, fontSize: 11, fontWeight: FontWeight.w400)),
        ],
      ),
    );
  }

  Widget _adCell(double ratio) {
    final Color c;
    final String label;
    if (ratio >= 2) {
      c = _bull;
      label = 'Strong';
    } else if (ratio >= 1) {
      c = _warn;
      label = 'Moderate';
    } else {
      c = _bear;
      label = 'Weak';
    }

    return Expanded(
      child: Column(
        children: [
          Icon(Icons.balance_rounded, size: 14, color: c.withOpacity(0.7)),
          const SizedBox(height: 5),
          Text(ratio.toStringAsFixed(1),
              style: TextStyle(
                  color: _t1,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5)),
          Text(label,
              style: TextStyle(
                  color: c, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 1),
          Text('A/D Ratio',
              style: TextStyle(
                  color: _t2, fontSize: 11, fontWeight: FontWeight.w400)),
        ],
      ),
    );
  }

  Widget _vDivider() => Container(width: 1, height: 50, color: _border);

  Widget _buildStrengthFooter(double strength, Color accent) {
    return Container(
      decoration: BoxDecoration(
        color: _elevated,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(_T.rLg),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.bolt_rounded, size: 13, color: _t2),
              const SizedBox(width: 4),
              Text(
                'Trend Strength',
                style: TextStyle(
                    color: _t2,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3),
              ),
              const Spacer(),
              Text(
                '${(strength * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                    color: accent, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 7),
          LayoutBuilder(
            builder: (ctx, bc) => Stack(
              children: [
                Container(
                  height: 5,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutExpo,
                  height: 5,
                  width: bc.maxWidth * strength,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accent.withOpacity(0.6), accent],
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Empty state ──────────────────────────────────────────────────────────
  Widget _buildEmpty(bool isBullish) {
    final c = _accentFor(isBullish);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: c.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: c.withOpacity(0.2)),
            ),
            child: Icon(
              isBullish
                  ? Icons.trending_up_rounded
                  : Icons.trending_down_rounded,
              size: 30,
              color: c,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No ${isBullish ? 'bullish' : 'bearish'} sectors today',
            style: TextStyle(
                color: _t1, fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back once sectors show\nclear directional movement.',
            style: TextStyle(color: _t2, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ─── Error state ──────────────────────────────────────────────────────────
  Widget _buildError() {
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
                color: _bear.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _bear.withOpacity(0.3)),
              ),
              child: Icon(Icons.cloud_off_rounded, color: _bear, size: 28),
            ),
            const SizedBox(height: 20),
            Text('Something went wrong',
                style: TextStyle(
                    color: _t1, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              style: TextStyle(color: _t2, fontSize: 13),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _fetchData,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                decoration: BoxDecoration(
                  color: _bull,
                  borderRadius: BorderRadius.circular(_T.r),
                ),
                child: Text(
                  'Try again',
                  style: TextStyle(
                    color: _dark ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Skeleton ─────────────────────────────────────────────────────────────
  Widget _buildSkeleton() {
    return Column(
      children: [
        _skel(margin: const EdgeInsets.fromLTRB(20, 16, 20, 0), height: 68),
        _skel(margin: const EdgeInsets.fromLTRB(20, 12, 20, 0), height: 46),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            itemCount: 5,
            itemBuilder: (_, i) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              height: 165,
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(_T.rLg),
                border: Border.all(color: _border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _skel(width: 44, height: 44, r: _T.rSm),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _skel(width: 130, height: 16),
                              const SizedBox(height: 6),
                              _skel(width: 80, height: 12),
                            ],
                          ),
                        ),
                        _skel(width: 72, height: 34, r: 8),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _skel(width: 55, height: 12),
                        const Spacer(),
                        _skel(width: 55, height: 12),
                        const Spacer(),
                        _skel(width: 55, height: 12),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _skel(width: double.infinity, height: 5, r: 3),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _skel({
    double? width,
    double? height,
    double r = _T.r,
    EdgeInsets margin = EdgeInsets.zero,
  }) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: _dark ? const Color(0xFF21262D) : const Color(0xFFE8EDF3),
        borderRadius: BorderRadius.circular(r),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────────────────────────────────────
class SectorTrend {
  final String sectorName;
  final int totalStocks;
  final int positiveStocks;
  final int negativeStocks;
  final int above5Percent;
  final int above2Percent;
  final int below2Percent;
  final int below5Percent;
  final double averageChange;
  final double bullishScore;
  final double bearishScore;
  final double totalVolume;

  const SectorTrend({
    required this.sectorName,
    required this.totalStocks,
    required this.positiveStocks,
    required this.negativeStocks,
    required this.above5Percent,
    required this.above2Percent,
    required this.below2Percent,
    required this.below5Percent,
    required this.averageChange,
    required this.bullishScore,
    required this.bearishScore,
    required this.totalVolume,
  });
}
