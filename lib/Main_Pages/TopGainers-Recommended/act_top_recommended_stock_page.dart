import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:optionxi/Components/cust_stock_info_card.dart';
import 'package:optionxi/Main_Frags/home_sections/sec_trending_stocks.dart';
import 'package:optionxi/Main_Pages/TopGainers-Recommended/cust_tab_top_stocks_component.dart';

// ─────────────────────────────────────────────────────────────────────
//  Trending Stocks — redesigned
//
//  Idea: the whole page takes its mood from ONE choice the user makes —
//  "Going up" or "Going down". Green or red tint flows through the glow,
//  the switch, and the explainer, so people always know which side of the
//  market they're looking at without needing to know the words
//  "bullish" / "bearish".
//
//  Public API is unchanged: TopRecommendedStockPage({StockData? stock}).
// ─────────────────────────────────────────────────────────────────────

Color _a(Color c, double opacity) => c.withAlpha((opacity * 255).round());

class _P {
  final bool dark;
  const _P(this.dark);

  Color get bg => dark ? const Color(0xFF0A0C11) : const Color(0xFFF3F4F7);
  Color get surface => dark ? const Color(0xFF14171F) : Colors.white;
  Color get text => dark ? Colors.white : const Color(0xFF0E1116);
  Color get muted => dark ? const Color(0xB3FFFFFF) : const Color(0xB30E1116);
  Color get faint => dark ? const Color(0x66FFFFFF) : const Color(0x800E1116);
  Color get line => dark ? const Color(0x1AFFFFFF) : const Color(0x1A0E1116);
  Color get up => dark ? const Color(0xFF34D399) : const Color(0xFF059669);
  Color get down => dark ? const Color(0xFFFB7185) : const Color(0xFFE11D48);
}

enum _Trend {
  up(
    category: 'bullish',
    label: 'Going up',
    techName: 'Bullish',
    icon: Icons.trending_up_rounded,
    headline: 'Stocks that look like they’re rising',
    body:
        'Their recent price moves match patterns that often show up when a stock is climbing. Lots of chart checks flagged these.',
    thumb: [Color(0xFF10B981), Color(0xFF047857)],
  ),
  down(
    category: 'bearish',
    label: 'Going down',
    techName: 'Bearish',
    icon: Icons.trending_down_rounded,
    headline: 'Stocks that look like they’re sliding',
    body:
        'Their recent price moves match patterns that often show up when a stock is losing steam. Lots of chart checks flagged these.',
    thumb: [Color(0xFFF43F5E), Color(0xFFBE123C)],
  );

  const _Trend({
    required this.category,
    required this.label,
    required this.techName,
    required this.icon,
    required this.headline,
    required this.body,
    required this.thumb,
  });

  final String category;
  final String label;
  final String techName;
  final IconData icon;
  final String headline;
  final String body;
  final List<Color> thumb;

  Color color(_P p) => this == _Trend.up ? p.up : p.down;
}

class TopRecommendedStockPage extends StatefulWidget {
  final StockData? stock;

  const TopRecommendedStockPage({Key? key, this.stock}) : super(key: key);

  @override
  State<TopRecommendedStockPage> createState() =>
      _TopRecommendedStockPageState();
}

class _TopRecommendedStockPageState extends State<TopRecommendedStockPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _intro;
  late final Animation<double> _fade;

  _Trend _trend = _Trend.up;
  bool _guideOpen = false;

  @override
  void initState() {
    super.initState();
    // The page's single entrance moment: a soft fade in.
    _intro = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..forward();
    _fade = CurvedAnimation(parent: _intro, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  void _setTrend(_Trend t) {
    if (t == _trend) return;
    HapticFeedback.selectionClick();
    setState(() => _trend = t);
  }

  @override
  Widget build(BuildContext context) {
    final p = _P(Theme.of(context).brightness == Brightness.dark);
    final accent = _trend.color(p);

    return Scaffold(
      backgroundColor: p.bg,
      body: Stack(
        children: [
          // Ambient tint that follows the selected direction.
          Positioned(
            top: -140,
            left: -80,
            right: -80,
            height: 380,
            child: IgnorePointer(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    radius: 0.75,
                    colors: [
                      _a(accent, p.dark ? 0.20 : 0.13),
                      _a(accent, 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          FadeTransition(
            opacity: _fade,
            child: SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(p),
                          const SizedBox(height: 28),
                          if (widget.stock != null) ...[
                            _buildSpotlight(p),
                            const SizedBox(height: 24),
                          ],
                          _buildGuide(p),
                          const SizedBox(height: 24),
                          _TrendSwitch(
                            trend: _trend,
                            palette: p,
                            onChanged: _setTrend,
                          ),
                          const SizedBox(height: 16),
                          _buildExplainer(p),
                          const SizedBox(height: 20),
                          _buildResults(),
                          const SizedBox(height: 28),
                          _buildFooterNote(p),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── Header ───────────────────────────

  Widget _buildHeader(_P p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _RoundButton(
              icon: Icons.arrow_back_ios_new_rounded,
              label: 'Go back',
              palette: p,
              onTap: () => Navigator.maybePop(context),
            ),
            const Spacer(),
            _LiveChip(palette: p),
            const SizedBox(width: 8),
            _RoundButton(
              icon: Icons.help_outline_rounded,
              label: 'What do these words mean?',
              palette: p,
              onTap: _showJargonSheet,
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text(
          'What’s moving\nright now',
          style: TextStyle(
            fontSize: 38,
            height: 1.05,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.6,
            color: p.text,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Stocks where several chart checks agree on which way the price is heading.',
          style: TextStyle(
            fontSize: 15,
            height: 1.5,
            color: p.muted,
          ),
        ),
      ],
    );
  }

  // ───────────────────── Stock you came from ─────────────────────

  Widget _buildSpotlight(_P p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your stock',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: p.muted,
          ),
        ),
        const SizedBox(height: 10),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () =>
                Get.toNamed('/stocks/${widget.stock!.symbol.toUpperCase()}'),
            child: ModernStockCard(stock: widget.stock!),
          ),
        ),
      ],
    );
  }

  // ───────────────────── "New here?" explainer ─────────────────────

  Widget _buildGuide(_P p) {
    return Material(
      color: p.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: p.line),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _guideOpen = !_guideOpen);
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline_rounded,
                      size: 22, color: p.muted),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'New to stocks? Start here',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: p.text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'How this page works, in 3 quick steps',
                          style: TextStyle(fontSize: 13, color: p.faint),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _guideOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child:
                        Icon(Icons.keyboard_arrow_down_rounded, color: p.faint),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _guideOpen
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                    child: Column(
                      children: [
                        Divider(height: 1, color: p.line),
                        const SizedBox(height: 16),
                        _GuideStep(
                          number: 1,
                          title: 'We run many chart checks',
                          body:
                              'Each check scans stocks for one specific pattern in their recent prices.',
                          palette: p,
                        ),
                        _GuideStep(
                          number: 2,
                          title: 'Every hit counts as one signal',
                          body:
                              'If 6 different checks flag a stock, it shows 6 signals.',
                          palette: p,
                        ),
                        _GuideStep(
                          number: 3,
                          title: 'More signals means more agreement',
                          body:
                              'The pattern is clearer. It’s still a hint, not a promise.',
                          palette: p,
                          isLast: true,
                        ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity, height: 0),
          ),
        ],
      ),
    );
  }

  // ───────────────────── Explainer for the chosen side ─────────────────────

  Widget _buildExplainer(_P p) {
    final t = _trend;
    final c = t.color(p);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: Container(
        key: ValueKey(t),
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: _a(c, p.dark ? 0.09 : 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: c, width: 3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.headline,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: p.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              t.body,
              style: TextStyle(fontSize: 13.5, height: 1.5, color: p.muted),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Pill(text: 'Also called ${t.techName}', palette: p),
                _Pill(text: 'More signals = more agreement', palette: p),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────── The stock lists ─────────────────────────

  Widget _buildResults() {
    // Both lists stay alive so switching back is instant and doesn't reload,
    // but only the visible one takes up space.
    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 300),
      sizeCurve: Curves.easeOutCubic,
      crossFadeState: _trend == _Trend.up
          ? CrossFadeState.showFirst
          : CrossFadeState.showSecond,
      firstChild: const TopStocksHeatMap(category: 'bullish'),
      secondChild: const TopStocksHeatMap(category: 'bearish'),
    );
  }

  // ───────────────────────── Footer note ─────────────────────────

  Widget _buildFooterNote(_P p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(height: 1, color: p.line),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded, size: 16, color: p.faint),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'This is information, not financial advice. The patterns come from past prices and can’t predict the future. Do your own research before you invest.',
                style: TextStyle(fontSize: 12.5, height: 1.5, color: p.faint),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─────────────────────── Jargon-buster sheet ───────────────────────

  void _showJargonSheet() {
    final p = _P(Theme.of(context).brightness == Brightness.dark);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.78,
          minChildSize: 0.5,
          maxChildSize: 0.94,
          expand: false,
          builder: (_, scroll) {
            return Container(
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: p.line,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'What these words mean',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                      color: p.text,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Plain-English answers to the words you’ll see on this page.',
                    style: TextStyle(fontSize: 14, height: 1.5, color: p.muted),
                  ),
                  const SizedBox(height: 20),
                  _Term(
                    icon: Icons.trending_up_rounded,
                    color: p.up,
                    word: 'Bullish',
                    meaning:
                        'Investor slang for “going up”. A bullish stock’s chart is trending upward.',
                    palette: p,
                  ),
                  _Term(
                    icon: Icons.trending_down_rounded,
                    color: p.down,
                    word: 'Bearish',
                    meaning:
                        'The opposite. A bearish stock’s chart is trending downward.',
                    palette: p,
                  ),
                  _Term(
                    icon: Icons.manage_search_rounded,
                    color: p.muted,
                    word: 'Chart check (screener)',
                    meaning:
                        'An automatic scan that looks through lots of stocks for one specific price pattern.',
                    palette: p,
                  ),
                  _Term(
                    icon: Icons.bar_chart_rounded,
                    color: p.muted,
                    word: 'Signal count',
                    meaning:
                        'How many chart checks flagged a stock. A higher number means more checks agree. It’s not a guarantee.',
                    palette: p,
                  ),
                  _Term(
                    icon: Icons.show_chart_rounded,
                    color: p.muted,
                    word: 'Technical indicator',
                    meaning:
                        'A formula that reads past prices to spot patterns. It doesn’t look at company news or earnings.',
                    palette: p,
                    isLast: true,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _a(p.text, 0.05),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'Remember: this is information, not advice to buy or sell. Prices can move either way, whatever the pattern says.',
                      style:
                          TextStyle(fontSize: 13, height: 1.5, color: p.muted),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: p.text,
                        foregroundColor: p.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: const Text('Got it'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
//  Direction switch — the page's one bold element
// ═════════════════════════════════════════════════════════════════════

class _TrendSwitch extends StatelessWidget {
  final _Trend trend;
  final _P palette;
  final ValueChanged<_Trend> onChanged;

  const _TrendSwitch({
    required this.trend,
    required this.palette,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final p = palette;

    return Container(
      height: 68,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: p.line),
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth / 2;
          final selected = trend.index;

          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                left: selected * w,
                top: 0,
                bottom: 0,
                width: w,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(17),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: trend.thumb,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _a(trend.thumb.first, 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  for (final t in _Trend.values)
                    Expanded(
                      child: _SwitchSegment(
                        trend: t,
                        selected: t == trend,
                        palette: p,
                        onTap: () => onChanged(t),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SwitchSegment extends StatelessWidget {
  final _Trend trend;
  final bool selected;
  final _P palette;
  final VoidCallback onTap;

  const _SwitchSegment({
    required this.trend,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final target = selected ? Colors.white : palette.muted;

    return Semantics(
      button: true,
      selected: selected,
      label: '${trend.label}, also called ${trend.techName}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: TweenAnimationBuilder<Color?>(
          tween: ColorTween(end: target),
          duration: const Duration(milliseconds: 250),
          builder: (context, color, _) {
            final c = color ?? target;
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(trend.icon, size: 24, color: c),
                const SizedBox(width: 10),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trend.label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: c,
                      ),
                    ),
                    Text(
                      trend.techName,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: _a(c, selected ? 0.8 : 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
//  Small building blocks
// ═════════════════════════════════════════════════════════════════════

class _RoundButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final _P palette;
  final VoidCallback onTap;

  const _RoundButton({
    required this.icon,
    required this.label,
    required this.palette,
    required this.onTap,
  });

  @override
  State<_RoundButton> createState() => _RoundButtonState();
}

class _RoundButtonState extends State<_RoundButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;

    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _pressed ? 0.9 : 1,
          duration: const Duration(milliseconds: 120),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: p.surface,
              border: Border.all(color: p.line),
            ),
            child: Icon(widget.icon, size: 17, color: p.text),
          ),
        ),
      ),
    );
  }
}

class _LiveChip extends StatefulWidget {
  final _P palette;
  const _LiveChip({required this.palette});

  @override
  State<_LiveChip> createState() => _LiveChipState();
}

class _LiveChipState extends State<_LiveChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final green = widget.palette.up;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(21),
        color: _a(green, 0.12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, __) {
                final t = reduceMotion ? 0.0 : _c.value;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.scale(
                      scale: 1 + t * 0.9,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _a(green, (1 - t) * 0.5),
                        ),
                      ),
                    ),
                    Container(
                      width: 8,
                      height: 8,
                      decoration:
                          BoxDecoration(shape: BoxShape.circle, color: green),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Live',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: green,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideStep extends StatelessWidget {
  final int number;
  final String title;
  final String body;
  final _P palette;
  final bool isLast;

  const _GuideStep({
    required this.number,
    required this.title,
    required this.body,
    required this.palette,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = palette;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: p.text,
                ),
                child: Text(
                  '$number',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: p.surface,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 1.5, color: p.line),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: p.text,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    body,
                    style: TextStyle(fontSize: 13, height: 1.5, color: p.muted),
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

class _Pill extends StatelessWidget {
  final String text;
  final _P palette;
  const _Pill({required this.text, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _a(palette.text, 0.07),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: palette.muted,
        ),
      ),
    );
  }
}

class _Term extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String word;
  final String meaning;
  final _P palette;
  final bool isLast;

  const _Term({
    required this.icon,
    required this.color,
    required this.word,
    required this.meaning,
    required this.palette,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = palette;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: p.line),
          bottom: isLast ? BorderSide(color: p.line) : BorderSide.none,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  word,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: p.text,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  meaning,
                  style: TextStyle(fontSize: 13.5, height: 1.5, color: p.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
