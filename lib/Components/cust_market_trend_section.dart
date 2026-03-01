import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:optionxi/Main_Pages/act_sectorwise_stocks.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';

// ─── Palette ──────────────────────────────────────────────────────────────────

class _P {
  static const bullDark = Color(0xFF00E5A0);
  static const bullLight = Color(0xFF00956A);
  static const bearDark = Color(0xFFFF4D6D);
  static const bearLight = Color(0xFFD6213F);

  static const cardDark = Color(0xFF131620);
  static const rimDark = Color(0xFF1E2232);
  static const cardLight = Color(0xFFFFFFFF);
  static const rimLight = Color(0xFFDDE3EF);

  static const muted = Color(0xFF8892A4);
}

// ─── Models ───────────────────────────────────────────────────────────────────

// Using the StockData from your separate file
class _SectorRow {
  final String name;
  final double avg;
  final int count;
  final List<StockData> stocks;
  _SectorRow(this.name, this.avg, this.count, this.stocks);
}

// ─── Root ─────────────────────────────────────────────────────────────────────

class MarketTrendsSection extends StatefulWidget {
  final VoidCallback? onViewAll;
  const MarketTrendsSection({Key? key, this.onViewAll}) : super(key: key);

  @override
  State<MarketTrendsSection> createState() => _MarketTrendsSectionState();
}

class _MarketTrendsSectionState extends State<MarketTrendsSection>
    with TickerProviderStateMixin {
  final _supabase = Supabase.instance.client;

  int _adv = 0, _dec = 0;
  List<_SectorRow> _bulls = [], _bears = [];
  bool _loading = true;
  String? _error;

  late final AnimationController _fadeCtrl;
  late final AnimationController _barCtrl;
  late final Animation<double> _fade;
  late final Animation<double> _bar;

  bool get _dark => Theme.of(context).brightness == Brightness.dark;
  Color get _bull => _dark ? _P.bullDark : _P.bullLight;
  Color get _bear => _dark ? _P.bearDark : _P.bearLight;
  Color get _card => _dark ? _P.cardDark : _P.cardLight;
  Color get _rim => _dark ? _P.rimDark : _P.rimLight;
  Color get _ink => _dark ? Colors.white : const Color(0xFF0B0D14);

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _barCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100));
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _bar = CurvedAnimation(parent: _barCtrl, curve: Curves.easeOutCubic);
    _fetchData();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _barCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final raw = await _supabase
          .from('generated_values')
          .select('*')
          .not('sec', 'is', null) as List<dynamic>;

      final Map<String, List<StockData>> bySec = {};
      for (final j in raw) {
        final s = StockData.fromJson(j);
        bySec.putIfAbsent(s.sector ?? 'Others', () => []).add(s);
      }

      int adv = 0, dec = 0;
      final rows = <_SectorRow>[];
      bySec.forEach((name, stocks) {
        adv += stocks.where((s) => s.pcnt > 0).length;
        dec += stocks.where((s) => s.pcnt < 0).length;
        final avg = stocks.fold(0.0, (a, s) => a + s.pcnt) / stocks.length;
        rows.add(_SectorRow(name, avg, stocks.length, stocks));
      });

      final bulls = rows.where((r) => r.avg > 0).toList()
        ..sort((a, b) => b.avg.compareTo(a.avg));
      final bears = rows.where((r) => r.avg < 0).toList()
        ..sort((a, b) => a.avg.compareTo(b.avg));

      setState(() {
        _adv = adv;
        _dec = dec;
        _bulls = bulls.take(5).toList();
        _bears = bears.take(5).toList();
        _loading = false;
      });

      _fadeCtrl.forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 60));
      _barCtrl.forward(from: 0);
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString();
          _loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _Skeleton(dark: _dark);
    if (_error != null) {
      return _ErrorView(
          onRetry: _fetchData,
          dark: _dark,
          bear: _bear,
          card: _card,
          rim: _rim,
          ink: _ink);
    }

    final total = _adv + _dec;
    final advRatio = total > 0 ? _adv / total : 0.5;

    return FadeTransition(
      opacity: _fade,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section header — same visual weight as "Top Leaderboard" ─────────
          _SectionHeader(
            title: 'Sector Trends',
            subtitle: 'Breadth & momentum',
            onViewAll: widget.onViewAll,
            bull: _bull,
            ink: _ink,
            rim: _rim,
          ),

          const SizedBox(height: 16),

          // ── Breadth card ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _BreadthCard(
              adv: _adv,
              dec: _dec,
              advRatio: advRatio,
              barAnim: _bar,
              bull: _bull,
              bear: _bear,
              card: _card,
              rim: _rim,
              ink: _ink,
              dark: _dark,
              onTap: () {
                HapticFeedback.lightImpact();
                widget.onViewAll?.call();
              },
            ),
          ),

          const SizedBox(height: 20),

          // ── Leading sectors ──────────────────────────────────────────────────
          if (_bulls.isNotEmpty) ...[
            _GroupLabel(
                label: 'LEADING SECTORS',
                icon: Icons.trending_up_rounded,
                color: _bull),
            const SizedBox(height: 6),
            for (int i = 0; i < _bulls.length; i++)
              _SectorTile(
                index: i,
                row: _bulls[i],
                positive: true,
                bull: _bull,
                bear: _bear,
                card: _card,
                rim: _rim,
                ink: _ink,
                onTap: () {
                  // Navigate to SectorStocksPage with the sector name and its stocks
                  Get.to(() => SectorStocksPage(
                        sectorName: _bulls[i].name,
                        stocks: _bulls[i].stocks,
                      ));
                },
              ),
            const SizedBox(height: 8),
          ],

          // ── Lagging sectors ──────────────────────────────────────────────────
          if (_bears.isNotEmpty) ...[
            _GroupLabel(
                label: 'LAGGING SECTORS',
                icon: Icons.trending_down_rounded,
                color: _bear),
            const SizedBox(height: 6),
            for (int i = 0; i < _bears.length; i++)
              _SectorTile(
                index: i,
                row: _bears[i],
                positive: false,
                bull: _bull,
                bear: _bear,
                card: _card,
                rim: _rim,
                ink: _ink,
                onTap: () {
                  // Navigate to SectorStocksPage with the sector name and its stocks
                  Get.to(() => SectorStocksPage(
                        sectorName: _bears[i].name,
                        stocks: _bears[i].stocks,
                      ));
                },
              ),
          ],

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────
// Matches the "Top Leaderboard" section header style exactly:
// thin divider → big bold title + muted subtitle → "View All" right-aligned.

class _SectionHeader extends StatelessWidget {
  final String title, subtitle;
  final VoidCallback? onViewAll;
  final Color bull, ink, rim;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.onViewAll,
    required this.bull,
    required this.ink,
    required this.rim,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(height: 1, thickness: 0.5, color: rim),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: ink,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _P.muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (onViewAll != null)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onViewAll!();
                  },
                  child: Text(
                    'View All',
                    style: TextStyle(
                        color: bull, fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Group label ──────────────────────────────────────────────────────────────

class _GroupLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _GroupLabel(
      {required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(width: 6),
          Icon(icon, size: 14, color: color),
        ],
      ),
    );
  }
}

// ─── Breadth card ─────────────────────────────────────────────────────────────
class _BreadthCard extends StatelessWidget {
  final int adv, dec;
  final double advRatio;
  final Animation<double> barAnim;
  final Color bull, bear, card, rim, ink;
  final bool dark;
  final VoidCallback onTap;

  const _BreadthCard({
    required this.adv,
    required this.dec,
    required this.advRatio,
    required this.barAnim,
    required this.bull,
    required this.bear,
    required this.card,
    required this.rim,
    required this.ink,
    required this.dark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dividerColor =
        dark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.07);
    final subTextColor =
        dark ? Colors.white.withOpacity(0.30) : Colors.black.withOpacity(0.30);
    final dotColor =
        dark ? Colors.white.withOpacity(0.20) : Colors.black.withOpacity(0.20);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: rim, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(dark ? 0.30 : 0.05),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Row(
              children: [
                Text(
                  'MARKET BREADTH',
                  style: TextStyle(
                    color: ink.withOpacity(0.35),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const Spacer(),
                Icon(Icons.chevron_right_rounded,
                    color: ink.withOpacity(0.25), size: 18),
              ],
            ),
            const SizedBox(height: 20),

            AnimatedBuilder(
              animation: barAnim,
              builder: (_, __) {
                // Failsafe ratio calculation in case advRatio is NaN or Infinity
                final double safeRatio = advRatio.isNaN ? 0.5 : advRatio;
                final a = (safeRatio * barAnim.value).clamp(0.001, 0.999);
                final advPct = (a * 100).round();
                final decPct = 100 - advPct;

                // Clamp flex values to ensure they are strictly positive integers > 0
                final int flexAdv = (a * 1000).round().clamp(1, 1000);
                final int flexDec = ((1 - a) * 1000).round().clamp(1, 1000);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Big numbers ──
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        // Advancing
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              adv.toString(),
                              style: TextStyle(
                                color: bull,
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1.5,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Icon(Icons.arrow_upward_rounded,
                                    size: 11, color: bull.withOpacity(0.7)),
                                const SizedBox(width: 3),
                                Text(
                                  '$advPct%',
                                  style: TextStyle(
                                    color: bull.withOpacity(0.7),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const Spacer(),
                        Container(width: 1, height: 36, color: dividerColor),
                        const Spacer(),

                        // Declining
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              dec.toString(),
                              style: TextStyle(
                                color: bear,
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1.5,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Text(
                                  '$decPct%',
                                  style: TextStyle(
                                    color: bear.withOpacity(0.7),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Icon(Icons.arrow_downward_rounded,
                                    size: 11, color: bear.withOpacity(0.7)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── Pill bar ──
                    Container(
                      height: 8, // Increased slightly for better visibility
                      decoration: BoxDecoration(
                        color: dark
                            ? Colors.white.withOpacity(0.06)
                            : Colors.black.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: Row(
                          children: [
                            Expanded(
                              flex: flexAdv,
                              child: Container(
                                  color:
                                      bull), // Uses your bull (green) color dynamically
                            ),
                            Container(width: 2, color: card), // Spacer gap
                            Expanded(
                              flex: flexDec,
                              child: Container(
                                  color:
                                      bear), // Uses your bear (red) color dynamically
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ── Bar endpoint labels ──
                    Row(
                      children: [
                        Text(
                          'Advancing',
                          style: TextStyle(
                            color: subTextColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '·',
                          style: TextStyle(color: dotColor, fontSize: 10),
                        ),
                        const Spacer(),
                        Text(
                          'Declining',
                          style: TextStyle(
                            color: subTextColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sector tile ──────────────────────────────────────────────────────────────
// Full-width card row — Expanded on the name, badge pinned right. No overflow.

class _SectorTile extends StatefulWidget {
  final int index;
  final _SectorRow row;
  final bool positive;
  final Color bull, bear, card, rim, ink;
  final VoidCallback onTap;

  const _SectorTile({
    required this.index,
    required this.row,
    required this.positive,
    required this.bull,
    required this.bear,
    required this.card,
    required this.rim,
    required this.ink,
    required this.onTap,
  });

  @override
  State<_SectorTile> createState() => _SectorTileState();
}

class _SectorTileState extends State<_SectorTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _slide;
  late final Animation<double> _fade;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 480));
    _slide = Tween(begin: 20.0, end: 0.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    Future.delayed(Duration(milliseconds: 60 * widget.index), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.positive ? widget.bull : widget.bear;
    final pct = widget.row.avg;
    final sign = pct >= 0 ? '+' : '';

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Opacity(
        opacity: _fade.value,
        child:
            Transform.translate(offset: Offset(0, _slide.value), child: child),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) {
            setState(() => _pressed = false);
            HapticFeedback.lightImpact();
            widget.onTap();
          },
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            decoration: BoxDecoration(
              color: _pressed ? accent.withOpacity(0.06) : widget.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _pressed ? accent.withOpacity(0.35) : widget.rim,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                children: [
                  // Accent dot
                  Container(
                    width: 7,
                    height: 7,
                    decoration:
                        BoxDecoration(color: accent, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 14),

                  // Name + count — Expanded fills all remaining space
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.row.name,
                          style: TextStyle(
                            color: widget.ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.row.count} stocks',
                          style: const TextStyle(
                              color: _P.muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Badge — always right, never clipped
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      '$sign${pct.toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Skeleton ─────────────────────────────────────────────────────────────────

class _Skeleton extends StatefulWidget {
  final bool dark;
  const _Skeleton({required this.dark});
  @override
  State<_Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<_Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1300))
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _box(double? w, double h, {double r = 8}) => AnimatedBuilder(
        animation: _anim,
        builder: (_, __) {
          final base =
              widget.dark ? const Color(0xFF181B27) : const Color(0xFFE6EAF3);
          final hi =
              widget.dark ? const Color(0xFF22263A) : const Color(0xFFF0F3FA);
          return Container(
            width: w,
            height: h,
            decoration: BoxDecoration(
              color: Color.lerp(base, hi, _anim.value),
              borderRadius: BorderRadius.circular(r),
            ),
          );
        },
      );

  @override
  Widget build(BuildContext context) {
    final rim = widget.dark ? _P.rimDark : _P.rimLight;
    final card = widget.dark ? _P.cardDark : _P.cardLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(height: 1, thickness: 0.5, color: rim),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _box(160, 28, r: 6),
                const SizedBox(height: 6),
                _box(180, 13, r: 5),
              ]),
              const Spacer(),
              _box(60, 16, r: 5),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: rim),
            ),
            padding: const EdgeInsets.all(18),
            child: Column(children: [
              Row(children: [
                _box(110, 11, r: 5),
                const Spacer(),
                _box(18, 18, r: 5)
              ]),
              const SizedBox(height: 16),
              Row(children: [
                _box(90, 52, r: 10),
                const Spacer(),
                _box(90, 52, r: 10)
              ]),
              const SizedBox(height: 16),
              _box(double.infinity, 8, r: 6),
              const SizedBox(height: 8),
              Row(children: [
                _box(110, 11, r: 5),
                const Spacer(),
                _box(110, 11, r: 5)
              ]),
            ]),
          ),
        ),
        const SizedBox(height: 20),
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _box(140, 13, r: 5)),
        const SizedBox(height: 8),
        for (int i = 0; i < 4; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Container(
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: rim),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(children: [
                _box(7, 7, r: 4),
                const SizedBox(width: 14),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      _box(null, 14, r: 5),
                      const SizedBox(height: 5),
                      _box(55, 11, r: 4),
                    ])),
                const SizedBox(width: 12),
                _box(76, 30, r: 9),
              ]),
            ),
          ),
      ],
    );
  }
}

// ─── Error view ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  final bool dark;
  final Color bear, card, rim, ink;

  const _ErrorView({
    required this.onRetry,
    required this.dark,
    required this.bear,
    required this.card,
    required this.rim,
    required this.ink,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(height: 1, thickness: 0.5, color: rim),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Sector Trends',
                style: TextStyle(
                    color: ink,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8)),
            const SizedBox(height: 3),
            const Text('Breadth & momentum',
                style: TextStyle(
                    color: _P.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ]),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: rim),
            ),
            padding: const EdgeInsets.all(28),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: bear.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.wifi_off_rounded, color: bear, size: 28),
              ),
              const SizedBox(height: 14),
              Text('Unable to load trends',
                  style: TextStyle(
                      color: ink, fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              const Text('Check your connection and try again.',
                  style: TextStyle(color: _P.muted, fontSize: 12),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onRetry();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
                  decoration: BoxDecoration(
                      color: bear, borderRadius: BorderRadius.circular(12)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded,
                          color: Colors.white, size: 15),
                      SizedBox(width: 8),
                      Text('Retry',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}
