import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:optionxi/Main_Pages/Achivements/fastapi_achivement.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

// ═════════════════════════════════════════════════════════════════════════
// DESIGN NOTES
//
// Audience : everyday investors, many of them new to charts and jargon.
// Job      : help someone pick a ready-made stock search and understand it
//            without knowing what "RSI" or "bullish" means.
//
// Layout   : one pinned control strip (Rising / Falling + time range),
//            then each time range is ONE grouped surface with hairline-
//            divided rows, instead of a stack of identical cards.
// Anchor   : the stock count. It is the first thing the eye lands on
//            in every row, coloured by direction.
// Language : Bullish -> Rising, Bearish -> Falling, Daily/Weekly/Monthly ->
//            Short/Medium/Long-term, "criteria" -> "What it looks for".
//            Technical terms found in the data are explained in plain
//            words automatically (see kJargon).
// ═════════════════════════════════════════════════════════════════════════

// ─────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────
class Screener {
  final String id;
  final String name;
  final String timeframe;
  final int signalCount;
  final String lastUpdate;
  final String description;
  final List<String> criteria;
  final String category;

  Screener({
    required this.id,
    required this.name,
    required this.timeframe,
    required this.signalCount,
    required this.lastUpdate,
    required this.description,
    required this.criteria,
    required this.category,
  });

  factory Screener.fromJson(Map<String, dynamic> json) {
    return Screener(
      id: '${json['id']}',
      name: (json['name'] ?? '').toString(),
      timeframe: (json['timeframe'] ?? 'daily').toString().toLowerCase(),
      signalCount: (json['signal_count'] as num?)?.toInt() ?? 0,
      lastUpdate: (json['last_update'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      criteria: json['criteria'] == null
          ? const <String>[]
          : List<String>.from(json['criteria']),
      category: (json['category'] ?? '').toString(),
    );
  }

  DateTime? get updatedAt => DateTime.tryParse(lastUpdate);

  String get routeName =>
      '/scanners/${name.toLowerCase().replaceAll(' ', '-')}';
}

// ─────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────
class ScreenerService {
  final SupabaseClient _supabase;
  ScreenerService(this._supabase);

  /// Returns an empty list (instead of throwing) when a category has no
  /// screeners, so one empty tab never breaks the other one.
  Future<List<Screener>> fetchScreeners(String category) async {
    final response = await _supabase
        .from('screener_names')
        .select()
        .eq('category', category)
        .order('timeframe', ascending: true)
        .order('created_at', ascending: false);

    return (response as List)
        .map((j) => Screener.fromJson(Map<String, dynamic>.from(j as Map)))
        .toList();
  }
}

// ─────────────────────────────────────────────
// Plain-language content
// ─────────────────────────────────────────────
class TimeframeInfo {
  final String key;
  final String chip;
  final String title;
  final String subtitle;
  final IconData icon;
  const TimeframeInfo({
    required this.key,
    required this.chip,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

const List<TimeframeInfo> kTimeframes = [
  TimeframeInfo(
    key: 'daily',
    chip: 'Short-term',
    title: 'Short-term ideas',
    subtitle: 'Based on daily charts. Looks at moves over a few days.',
    icon: Icons.bolt_rounded,
  ),
  TimeframeInfo(
    key: 'weekly',
    chip: 'Medium-term',
    title: 'Medium-term ideas',
    subtitle: 'Based on weekly charts. Looks at moves over a few weeks.',
    icon: Icons.date_range_rounded,
  ),
  TimeframeInfo(
    key: 'monthly',
    chip: 'Long-term',
    title: 'Long-term ideas',
    subtitle: 'Based on monthly charts. Looks at moves over several months.',
    icon: Icons.calendar_month_rounded,
  ),
];

String _cap(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

TimeframeInfo timeframeInfo(String key) => kTimeframes.firstWhere(
      (t) => t.key == key,
      orElse: () => TimeframeInfo(
        key: key,
        chip: _cap(key),
        title: '${_cap(key)} ideas',
        subtitle: '',
        icon: Icons.schedule_rounded,
      ),
    );

class JargonTerm {
  final String name;
  final String meaning;
  final List<String> triggers;
  const JargonTerm(this.name, this.meaning, this.triggers);
}

/// Technical words that may appear in a screener's text, with a plain
/// explanation. Matching is automatic, so new screeners work without edits.
const List<JargonTerm> kJargon = [
  JargonTerm(
    'RSI',
    'A 0 to 100 gauge of how fast a stock has been rising or falling. '
        'Above 70 often means "run up too fast", below 30 means "dropped too fast".',
    ['rsi'],
  ),
  JargonTerm(
    'MACD',
    'A momentum gauge. When it turns up, buyers are usually gaining strength. '
        'When it turns down, sellers are.',
    ['macd'],
  ),
  JargonTerm(
    'Moving average (SMA, EMA, DMA)',
    'The average price over a set number of days. It smooths out daily noise, '
        'so a price above it usually means an uptrend.',
    ['moving average', 'sma', 'ema', 'dma'],
  ),
  JargonTerm(
    'Volume',
    'How many shares changed hands. High volume means lots of people are interested.',
    ['volume'],
  ),
  JargonTerm(
    'Breakout',
    'The price pushes above a level it kept failing to cross before.',
    ['breakout', 'breaks out', 'breaking out'],
  ),
  JargonTerm(
    'Breakdown',
    'The price drops below a level it used to hold above.',
    ['breakdown', 'breaks down', 'breaking down'],
  ),
  JargonTerm(
    'Support',
    'A price level where a falling stock has often stopped and bounced back.',
    ['support'],
  ),
  JargonTerm(
    'Resistance',
    'A price level where a rising stock has often stalled or turned back.',
    ['resistance'],
  ),
  JargonTerm(
    'Crossover',
    'One line on the chart crossing another. It often hints that the trend is changing.',
    [
      'crossover',
      'crosses above',
      'crosses below',
      'crossed above',
      'crossed below'
    ],
  ),
  JargonTerm(
    'Golden cross',
    'A short-term average moving above a long-term average. Seen as a positive sign.',
    ['golden cross'],
  ),
  JargonTerm(
    'Death cross',
    'A short-term average moving below a long-term average. Seen as a negative sign.',
    ['death cross'],
  ),
  JargonTerm(
    'Bollinger Bands',
    'A band around the price showing its normal range. Touching the edge means '
        'the move is unusually big.',
    ['bollinger'],
  ),
  JargonTerm(
    'ADX',
    'Measures how strong a trend is, not which way it points. Above 25 is a strong trend.',
    ['adx'],
  ),
  JargonTerm(
    'Supertrend',
    'A line that follows the price and flips sides when the trend changes direction.',
    ['supertrend'],
  ),
  JargonTerm(
    'Overbought',
    'The price rose so fast that a pause or dip may be coming.',
    ['overbought'],
  ),
  JargonTerm(
    'Oversold',
    'The price fell so fast that a bounce may be coming.',
    ['oversold'],
  ),
  JargonTerm(
    'Candlestick patterns',
    'Shapes formed by daily price bars, such as engulfing, hammer or doji. '
        'Traders read them as hints of a reversal.',
    ['engulfing', 'hammer', 'doji', 'harami', 'morning star', 'evening star'],
  ),
  JargonTerm(
    'Gap up / gap down',
    'The stock opens noticeably higher or lower than where it closed the day before.',
    ['gap up', 'gap down'],
  ),
  JargonTerm(
    '52-week high / low',
    'The highest or lowest price in the past year.',
    ['52 week', '52-week', '52w'],
  ),
  JargonTerm(
    'Consolidation',
    'The price moves sideways in a narrow range, like a stock catching its breath.',
    ['consolidation', 'consolidating'],
  ),
  JargonTerm(
    'VWAP',
    'The average price paid during the day, weighted by how much traded at each price.',
    ['vwap'],
  ),
  JargonTerm(
    'Stochastic',
    'Another gauge of whether a price has run too far, too fast, in either direction.',
    ['stochastic'],
  ),
];

List<JargonTerm> findJargon(Iterable<String> texts, {int limit = 5}) {
  final blob = texts.join('\n').toLowerCase();
  final found = <JargonTerm>[];
  for (final term in kJargon) {
    final hit = term.triggers.any(
      (t) => RegExp('\\b${RegExp.escape(t)}\\b').hasMatch(blob),
    );
    if (hit) found.add(term);
    if (found.length >= limit) break;
  }
  return found;
}

// ─────────────────────────────────────────────
// Theming helpers (work with any ColorScheme / Flutter version)
// ─────────────────────────────────────────────
class AppColors {
  static const Color rise = Color(0xFF0F9D6B);
  static const Color fall = Color(0xFFE5484D);
}

/// NOTE: This extension method was previously named `a`, which now collides
/// with the built-in `Color.a` getter on newer Flutter SDKs. It has been
/// renamed to `op` (opacity) to avoid the
/// "expression doesn't evaluate to a function" error.
extension _ColorAlpha on Color {
  Color op(double o) =>
      withAlpha(math.max(0, math.min(255, (o * 255).round())));
}

extension _Theming on BuildContext {
  ColorScheme get cs => Theme.of(this).colorScheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  /// Page background.
  Color get bg => isDark
      ? cs.surface
      : Color.alphaBlend(cs.onSurface.op(0.035), cs.surface);

  /// Grouped-surface background.
  Color get card =>
      isDark ? Color.alphaBlend(cs.onSurface.op(0.06), cs.surface) : cs.surface;

  Color get fill => cs.onSurface.op(0.05);
  Color get line => cs.onSurface.op(0.09);
  Color get muted => cs.onSurface.op(0.62);
  Color get faint => cs.onSurface.op(0.42);
}

// ─────────────────────────────────────────────
// Main screen
// ─────────────────────────────────────────────
class StockScreenerPage extends StatefulWidget {
  const StockScreenerPage({Key? key}) : super(key: key);

  @override
  State<StockScreenerPage> createState() => _StockScreenerPageState();
}

class _StockScreenerPageState extends State<StockScreenerPage> {
  String _category = 'bullish';
  String _timeframe = 'all';
  bool _loading = true;
  String? _error;
  List<Screener> _bullish = const [];
  List<Screener> _bearish = const [];

  late final ScreenerService _service;

  bool get _isRising => _category == 'bullish';

  @override
  void initState() {
    super.initState();
    _service = ScreenerService(Supabase.instance.client);
    _loadScreeners();
    // Fire once when the page opens (previously this ran on every rebuild).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AchievementEvents.openedScreener();
    });
  }

  Future<void> _loadScreeners({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final results = await Future.wait([
        _service.fetchScreeners('bullish'),
        _service.fetchScreeners('bearish'),
      ]);
      if (!mounted) return;
      setState(() {
        _bullish = results[0];
        _bearish = results[1];
        _loading = false;
        _error = null;
      });
    } catch (e) {
      debugPrint('Screener load failed: $e');
      if (!mounted) return;
      final hasData = _bullish.isNotEmpty || _bearish.isNotEmpty;
      if (silent && hasData) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Couldn't refresh. Showing the last results."),
          ),
        );
      } else {
        setState(() {
          _loading = false;
          _error = 'load_failed';
        });
      }
    }
  }

  void _setCategory(bool rising) {
    final next = rising ? 'bullish' : 'bearish';
    if (next == _category) return;
    HapticFeedback.selectionClick();
    setState(() => _category = next);
  }

  void _setTimeframe(String key) {
    if (key == _timeframe) return;
    HapticFeedback.selectionClick();
    setState(() => _timeframe = key);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => _loadScreeners(silent: true),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _Header(
                  onGuide: () => _showGuide(context),
                  onRefresh: () => _loadScreeners(),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _PinnedDelegate(
                  height: 120,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                    child: Column(
                      children: [
                        _DirectionToggle(
                          rising: _isRising,
                          onChanged: _setCategory,
                        ),
                        const SizedBox(height: 12),
                        _TimeRangeChips(
                          selected: _timeframe,
                          onSelected: _setTimeframe,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  child: _DirectionHint(
                    rising: _isRising,
                    onLearnMore: () => _showGuide(context),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                sliver: SliverToBoxAdapter(child: _buildBody(context)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const _SkeletonGroup();
    }

    if (_error != null) {
      return _MessageState(
        icon: Icons.cloud_off_rounded,
        title: "Couldn't load the lists",
        message: 'Check your internet connection, then try again.',
        actionLabel: 'Try again',
        onAction: () => _loadScreeners(),
      );
    }

    final all = _isRising ? _bullish : _bearish;
    final list = _timeframe == 'all'
        ? all
        : all.where((s) => s.timeframe == _timeframe).toList();

    if (list.isEmpty) {
      return _MessageState(
        icon: Icons.search_off_rounded,
        title: 'Nothing to show yet',
        message: all.isEmpty
            ? 'There are no lists here right now. Check back soon.'
            : 'No lists match this time range.',
        actionLabel: all.isEmpty ? null : 'Show all time ranges',
        onAction: all.isEmpty ? null : () => _setTimeframe('all'),
      );
    }

    final grouped = <String, List<Screener>>{};
    for (final s in list) {
      grouped.putIfAbsent(s.timeframe, () => []).add(s);
    }
    final known = kTimeframes.map((t) => t.key);
    final order = [
      ...known.where(grouped.containsKey),
      ...grouped.keys.where((k) => !known.contains(k)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final key in order)
          _TimeframeSection(
            info: timeframeInfo(key),
            items: grouped[key]!,
            rising: _isRising,
            category: _category,
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────
class _Header extends StatelessWidget {
  final VoidCallback onGuide;
  final VoidCallback onRefresh;
  const _Header({required this.onGuide, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (Navigator.of(context).canPop())
                _RoundButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Back',
                  onTap: () => Navigator.pop(context),
                ),
              const Spacer(),
              _RoundButton(
                icon: Icons.help_outline_rounded,
                tooltip: 'What do these words mean?',
                onTap: onGuide,
              ),
              const SizedBox(width: 8),
              _RoundButton(
                icon: Icons.refresh_rounded,
                tooltip: 'Refresh',
                onTap: onRefresh,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Stock Finder',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.2,
              height: 1.05,
              color: context.cs.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ready-made searches that scan the market and list stocks worth a closer look.',
            style: TextStyle(
              fontSize: 14.5,
              height: 1.45,
              color: context.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: context.card,
        shape: CircleBorder(side: BorderSide(color: context.line)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(icon, size: 20, color: context.cs.onSurface),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Pinned controls
// ─────────────────────────────────────────────
class _PinnedDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;
  _PinnedDelegate({required this.height, required this.child});

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        color: context.bg,
        border: overlapsContent
            ? Border(bottom: BorderSide(color: context.line))
            : null,
      ),
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedDelegate oldDelegate) => true;
}

class _DirectionToggle extends StatelessWidget {
  final bool rising;
  final ValueChanged<bool> onChanged;
  const _DirectionToggle({required this.rising, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.fill,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: rising ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: context.isDark
                      ? Color.alphaBlend(
                          context.cs.onSurface.op(0.1), context.cs.surface)
                      : context.cs.surface,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: context.isDark
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.op(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _Segment(
                  selected: rising,
                  color: AppColors.rise,
                  icon: Icons.trending_up_rounded,
                  label: 'Rising',
                  sub: 'Bullish',
                  onTap: () => onChanged(true),
                ),
              ),
              Expanded(
                child: _Segment(
                  selected: !rising,
                  color: AppColors.fall,
                  icon: Icons.trending_down_rounded,
                  label: 'Falling',
                  sub: 'Bearish',
                  onTap: () => onChanged(false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final bool selected;
  final Color color;
  final IconData icon;
  final String label;
  final String sub;
  final VoidCallback onTap;
  const _Segment({
    required this.selected,
    required this.color,
    required this.icon,
    required this.label,
    required this.sub,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? color : context.faint;
    return Semantics(
      button: true,
      selected: selected,
      label: '$label stocks, also called $sub',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: fg),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                      color: fg,
                    ),
                  ),
                  Text(
                    sub,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.2,
                      color: selected ? color.op(0.75) : context.faint,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeRangeChips extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;
  const _TimeRangeChips({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final options = <MapEntry<String, String>>[
      const MapEntry('all', 'All'),
      ...kTimeframes.map((t) => MapEntry(t.key, t.chip)),
    ];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final o = options[i];
          final isSel = o.key == selected;
          return GestureDetector(
            onTap: () => onSelected(o.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSel ? context.cs.onSurface : Colors.transparent,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: isSel ? context.cs.onSurface : context.line,
                ),
              ),
              child: Text(
                o.value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSel ? context.cs.surface : context.muted,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Direction hint (plain-English explanation of the current tab)
// ─────────────────────────────────────────────
class _DirectionHint extends StatelessWidget {
  final bool rising;
  final VoidCallback onLearnMore;
  const _DirectionHint({required this.rising, required this.onLearnMore});

  @override
  Widget build(BuildContext context) {
    final color = rising ? AppColors.rise : AppColors.fall;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            width: 3,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    rising
                        ? 'Prices here are climbing. People often use these lists to look for buying ideas.'
                        : 'Prices here are dropping. Useful for spotting stocks to avoid, or for experienced traders who bet on falls.',
                    key: ValueKey(rising),
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.5,
                      color: context.muted,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: onLearnMore,
                  child: Text(
                    'What do these words mean?',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: color,
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
// Time range section (one grouped surface, hairline rows)
// ─────────────────────────────────────────────
class _TimeframeSection extends StatelessWidget {
  final TimeframeInfo info;
  final List<Screener> items;
  final bool rising;
  final String category;
  const _TimeframeSection({
    required this.info,
    required this.items,
    required this.rising,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 0, 2, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(info.icon, size: 20, color: context.cs.onSurface),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        info.title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: context.cs.onSurface,
                        ),
                      ),
                      if (info.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          info.subtitle,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.4,
                            color: context.faint,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: context.card,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: context.line),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Column(
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    _ScreenerRow(
                      key: ValueKey(items[i].id),
                      screener: items[i],
                      rising: rising,
                      category: category,
                    ),
                    if (i != items.length - 1)
                      Divider(
                        height: 1,
                        thickness: 1,
                        indent: 16,
                        endIndent: 16,
                        color: context.line,
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Screener row
// ─────────────────────────────────────────────
class _ScreenerRow extends StatefulWidget {
  final Screener screener;
  final bool rising;
  final String category;
  const _ScreenerRow({
    Key? key,
    required this.screener,
    required this.rising,
    required this.category,
  }) : super(key: key);

  @override
  State<_ScreenerRow> createState() => _ScreenerRowState();
}

class _ScreenerRowState extends State<_ScreenerRow> {
  bool _expanded = false;
  late final List<JargonTerm> _terms;

  Color get _color => widget.rising ? AppColors.rise : AppColors.fall;

  @override
  void initState() {
    super.initState();
    final s = widget.screener;
    _terms = findJargon([s.name, s.description, ...s.criteria]);
  }

  void _open() {
    HapticFeedback.selectionClick();
    Navigator.pushNamed(
      context,
      widget.screener.routeName,
      arguments: {'category': widget.category},
    );
  }

  String _updatedText() {
    final dt = widget.screener.updatedAt;
    if (dt == null) return 'Updated recently';
    return 'Updated ${timeago.format(dt)}';
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.screener;
    final hasStocks = s.signalCount > 0;
    final hasDetails = s.criteria.isNotEmpty || _terms.isNotEmpty;

    return Material(
      type: MaterialType.transparency,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main tappable area
          InkWell(
            onTap: _open,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 12, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                            height: 1.25,
                            color: context.cs.onSurface,
                          ),
                        ),
                        if (s.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            s.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.45,
                              color: context.muted,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.schedule_rounded,
                                size: 13, color: context.faint),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                _updatedText(),
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.faint,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // The anchor: how many stocks match right now
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${s.signalCount}',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.4,
                          height: 1,
                          color: hasStocks ? _color : context.faint,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        s.signalCount == 1 ? 'stock' : 'stocks',
                        style: TextStyle(fontSize: 12, color: context.muted),
                      ),
                    ],
                  ),
                  Icon(Icons.chevron_right_rounded,
                      size: 22, color: context.faint),
                ],
              ),
            ),
          ),

          // "How this works" toggle
          if (hasDetails)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lightbulb_outline_rounded,
                          size: 16, color: _color),
                      const SizedBox(width: 6),
                      Text(
                        _expanded ? 'Hide details' : 'How does this work?',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _color,
                        ),
                      ),
                      const SizedBox(width: 2),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 220),
                        child: Icon(Icons.expand_more_rounded,
                            size: 20, color: _color),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            const SizedBox(height: 8),

          // Details
          AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _expanded ? _buildDetails(context) : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildDetails(BuildContext context) {
    final s = widget.screener;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (s.criteria.isNotEmpty) ...[
            Text(
              'What it looks for',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: context.cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            for (final c in s.criteria)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(Icons.check_rounded, size: 16, color: _color),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        c,
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.5,
                          color: context.cs.onSurface.op(0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (_terms.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.fill,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.tips_and_updates_rounded,
                          size: 16, color: context.cs.onSurface),
                      const SizedBox(width: 8),
                      Text(
                        'In plain words',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: context.cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  for (final t in _terms)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${t.name}: ',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            TextSpan(text: t.meaning),
                          ],
                        ),
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: context.cs.onSurface.op(0.8),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _open,
              style: FilledButton.styleFrom(
                backgroundColor: _color,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: Text(
                s.signalCount > 0
                    ? 'See the ${s.signalCount} ${s.signalCount == 1 ? 'stock' : 'stocks'}'
                    : 'Open this list',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Loading skeleton
// ─────────────────────────────────────────────
class _SkeletonGroup extends StatefulWidget {
  const _SkeletonGroup();

  @override
  State<_SkeletonGroup> createState() => _SkeletonGroupState();
}

class _SkeletonGroupState extends State<_SkeletonGroup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_ctrl.value);
        final shim = context.cs.onSurface.op(0.05 + 0.05 * t);

        Widget box(double w, double h, {double r = 6}) => Container(
              width: w,
              height: h,
              decoration: BoxDecoration(
                color: shim,
                borderRadius: BorderRadius.circular(r),
              ),
            );

        Widget row() => Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        box(170, 16),
                        const SizedBox(height: 10),
                        box(double.infinity, 12),
                        const SizedBox(height: 6),
                        box(120, 12),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  box(42, 32, r: 8),
                ],
              ),
            );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12, left: 2),
              child: box(150, 18),
            ),
            Container(
              decoration: BoxDecoration(
                color: context.card,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: context.line),
              ),
              child: Column(
                children: [
                  row(),
                  Divider(height: 1, color: context.line),
                  row(),
                  Divider(height: 1, color: context.line),
                  row(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Empty / error state
// ─────────────────────────────────────────────
class _MessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        children: [
          Icon(icon, size: 40, color: context.faint),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: context.cs.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, height: 1.5, color: context.muted),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(
                foregroundColor: context.cs.onSurface,
                side: BorderSide(color: context.line),
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 22),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              child: Text(
                actionLabel!,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Beginner's guide (bottom sheet)
// ─────────────────────────────────────────────
void _showGuide(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _GuideSheet(),
  );
}

class _GuideSheet extends StatelessWidget {
  const _GuideSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scroll) {
        return Container(
          decoration: BoxDecoration(
            color: ctx.cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ctx.line,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'New to this? Start here',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  color: ctx.cs.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              const _GuideRow(
                icon: Icons.filter_alt_rounded,
                color: null,
                title: 'What is a screener?',
                text:
                    'A ready-made search. It scans lots of stocks and lists only '
                    'the ones that match a pattern, so you don\'t have to check '
                    'each chart yourself.',
              ),
              const _GuideRow(
                icon: Icons.trending_up_rounded,
                color: AppColors.rise,
                title: 'Rising (bullish)',
                text:
                    'The price is going up, or looks ready to. "Bullish" is the '
                    'market word for feeling positive.',
              ),
              const _GuideRow(
                icon: Icons.trending_down_rounded,
                color: AppColors.fall,
                title: 'Falling (bearish)',
                text:
                    'The price is going down, or looks ready to. "Bearish" is '
                    'the market word for feeling negative.',
              ),
              const _GuideRow(
                icon: Icons.bolt_rounded,
                color: null,
                title: 'Short, medium and long-term',
                text:
                    'How far ahead a list looks. Short-term is days, medium-term '
                    'is weeks, long-term is months.',
              ),
              const _GuideRow(
                icon: Icons.numbers_rounded,
                color: null,
                title: 'The number on each row',
                text:
                    'How many stocks match that search right now. It changes as '
                    'prices move.',
              ),
              const SizedBox(height: 12),
              Text(
                'Common chart words',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: ctx.cs.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              for (final t in kJargon)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.name,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: ctx.cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        t.meaning,
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.5,
                          color: ctx.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ctx.fill,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'These lists are for learning and ideas. They are not advice to '
                  'buy or sell. Always do your own research first.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.5,
                    color: ctx.muted,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GuideRow extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final String title;
  final String text;
  const _GuideRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.cs.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: c.op(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: c),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: context.cs.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.5,
                    color: context.muted,
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
