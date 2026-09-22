import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:optionxi/Dialogs/custom_atlas_detaildialog.dart';
import 'package:optionxi/Main_Pages/Achivements/fastapi_achivement.dart';
import 'package:optionxi/Main_Pages/MarketSentiments/act_market_sentiments_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

// ═════════════════════════════════════════════════════════════════════════════
// Shared design tokens + plain-English helpers (also used by the chart page)
// ═════════════════════════════════════════════════════════════════════════════
class Mood {
  final String headline, tag, plain, voteWord;
  final Color color, dimDark, dimLight;
  final IconData icon;
  const Mood({
    required this.headline,
    required this.tag,
    required this.plain,
    required this.voteWord,
    required this.color,
    required this.dimDark,
    required this.dimLight,
    required this.icon,
  });
  Color dim(bool dark) => dark ? dimDark : dimLight;
}

class SX {
  SX._();

  static const double rXS = 6, rSM = 10, rMD = 14, rLG = 20;

  /// One source of truth for "how sure is the engine".
  static const double strongProb = 70, mediumProb = 60;

  // Light
  static const Color lBg = Color(0xFFF4F5F9);
  static const Color lSurface = Color(0xFFFFFFFF);
  static const Color lBorder = Color(0xFFE2E5EE);
  static const Color lTextP = Color(0xFF111827);
  static const Color lTextS = Color(0xFF6B7280);

  // Dark
  static const Color dBg = Color(0xFF0D0F14);
  static const Color dSurface = Color(0xFF151820);
  static const Color dBorder = Color(0xFF252B3A);
  static const Color dTextP = Color(0xFFEDF0F7);
  static const Color dTextS = Color(0xFF828A9B);

  static const Color accent = Color(0xFF6366F1);
  static const Color accentDim = Color(0x1A6366F1);
  static const Color accentLight = Color(0xFFEEEEFF);

  static const Color bull = Color(0xFF3B82F6);
  static const Color bullDim = Color(0x153B82F6);
  static const Color bullDimL = Color(0xFFEFF4FF);

  static const Color bear = Color(0xFFF43F5E);
  static const Color bearDim = Color(0x15F43F5E);
  static const Color bearDimL = Color(0xFFFFF0F3);

  static const Color neutral = Color(0xFF14B8A6);
  static const Color neutralDim = Color(0x1514B8A6);
  static const Color neutralDimL = Color(0xFFEEFBF9);

  static const Color strong = Color(0xFFF59E0B);

  static const Color probHigh = Color(0xFF10B981);
  static const Color probMid = Color(0xFFEAB308);
  static const Color probLow = Color(0xFFF43F5E);

  static const Mood up = Mood(
    headline: 'Likely going up',
    tag: 'Bullish',
    plain: 'Buyers are in control',
    voteWord: 'up',
    color: bull,
    dimDark: bullDim,
    dimLight: bullDimL,
    icon: Icons.trending_up_rounded,
  );
  static const Mood down = Mood(
    headline: 'Likely going down',
    tag: 'Bearish',
    plain: 'Sellers are in control',
    voteWord: 'down',
    color: bear,
    dimDark: bearDim,
    dimLight: bearDimL,
    icon: Icons.trending_down_rounded,
  );
  static const Mood flat = Mood(
    headline: 'Undecided',
    tag: 'Neutral',
    plain: 'No clear winner yet',
    voteWord: 'unsure',
    color: neutral,
    dimDark: neutralDim,
    dimLight: neutralDimL,
    icon: Icons.trending_flat_rounded,
  );

  static Mood mood(String type) =>
      type == 'Bull' ? up : (type == 'Bear' ? down : flat);

  static Color probColor(double p) =>
      p >= strongProb ? probHigh : (p >= mediumProb ? probMid : probLow);

  static String confidenceShort(double p) =>
      p >= strongProb ? 'High' : (p >= mediumProb ? 'Medium' : 'Low');

  static String confidence(double p) => '${confidenceShort(p)} confidence';

  static String trendWord(String t) {
    final s = t.toLowerCase();
    if (s.contains('bull')) return 'Up';
    if (s.contains('bear')) return 'Down';
    return 'Sideways';
  }

  static Color trendColor(String t) {
    final s = t.toLowerCase();
    if (s.contains('bull')) return bull;
    if (s.contains('bear')) return bear;
    return neutral;
  }
}

extension SxContext on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get sxBg => isDark ? SX.dBg : SX.lBg;
  Color get sxSurface => isDark ? SX.dSurface : SX.lSurface;
  Color get sxBorder => isDark ? SX.dBorder : SX.lBorder;
  Color get sxTextP => isDark ? SX.dTextP : SX.lTextP;
  Color get sxTextS => isDark ? SX.dTextS : SX.lTextS;
}

// ═════════════════════════════════════════════════════════════════════════════
// Shared atoms
// ═════════════════════════════════════════════════════════════════════════════
class SxTapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const SxTapScale({super.key, required this.child, this.onTap});
  @override
  State<SxTapScale> createState() => _SxTapScaleState();
}

class _SxTapScaleState extends State<SxTapScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 90));
  late final Animation<double> _s = Tween<double>(begin: 1, end: 0.97)
      .animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _c.forward(),
        onTapUp: (_) {
          _c.reverse();
          widget.onTap?.call();
        },
        onTapCancel: () => _c.reverse(),
        child: ScaleTransition(scale: _s, child: widget.child),
      );
}

class SxIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final double size;
  const SxIconBtn({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.size = 18,
  });

  @override
  Widget build(BuildContext context) {
    final btn = SxTapScale(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: context.sxSurface,
          borderRadius: BorderRadius.circular(SX.rMD),
          border: Border.all(color: context.sxBorder),
        ),
        child: Icon(icon, size: size, color: context.sxTextP),
      ),
    );
    return tooltip == null ? btn : Tooltip(message: tooltip!, child: btn);
  }
}

/// Labelled action pill (icon + text) for header actions.
class SxPillBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const SxPillBtn(
      {super.key,
      required this.icon,
      required this.label,
      required this.onTap});

  @override
  Widget build(BuildContext context) => SxTapScale(
        onTap: onTap,
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: SX.accent,
            borderRadius: BorderRadius.circular(SX.rMD),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ]),
        ),
      );
}

class SxRing extends StatelessWidget {
  final double value; // 0..100
  final double size;
  final Color color;
  final Color? track;
  final Color? textColor;
  const SxRing({
    super.key,
    required this.value,
    required this.color,
    this.size = 56,
    this.track,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: Stack(alignment: Alignment.center, children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: (value / 100).clamp(0.0, 1.0),
              strokeWidth: size * 0.11,
              strokeCap: StrokeCap.round,
              backgroundColor: track ?? color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          Text('${value.round()}%',
              style: TextStyle(
                fontSize: size * 0.26,
                fontWeight: FontWeight.w800,
                color: textColor ?? color,
              )),
        ]),
      );
}

class SxChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  const SxChip(
      {super.key, required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(SX.rXS + 2),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: TextStyle(
                  fontSize: 10.5, fontWeight: FontWeight.w600, color: color)),
        ]),
      );
}

class SxVoteBar extends StatelessWidget {
  final int pos, neut, neg;
  final double height;
  const SxVoteBar(
      {super.key,
      required this.pos,
      required this.neut,
      required this.neg,
      this.height = 6});

  @override
  Widget build(BuildContext context) {
    if (pos + neut + neg == 0) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: SizedBox(
        height: height,
        child: Row(children: [
          if (pos > 0)
            Expanded(flex: pos, child: const ColoredBox(color: SX.bull)),
          if (neut > 0)
            Expanded(flex: neut, child: const ColoredBox(color: SX.neutral)),
          if (neg > 0)
            Expanded(flex: neg, child: const ColoredBox(color: SX.bear)),
        ]),
      ),
    );
  }
}

class SxVoteLegend extends StatelessWidget {
  final int pos, neut, neg;
  const SxVoteLegend(
      {super.key, required this.pos, required this.neut, required this.neg});

  Widget _d(Color c, String t) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(t,
            style:
                TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c)),
      ]);

  @override
  Widget build(BuildContext context) =>
      Wrap(spacing: 12, runSpacing: 4, children: [
        _d(SX.bull, '$pos say up'),
        _d(SX.neutral, '$neut unsure'),
        _d(SX.bear, '$neg say down'),
      ]);
}

class SxMessage extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final String title, body;
  final String? actionLabel;
  final VoidCallback? onAction;
  const SxMessage({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.color,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.sxTextS;
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.sxSurface,
              shape: BoxShape.circle,
              border: Border.all(color: context.sxBorder),
            ),
            child: Icon(icon, size: 30, color: c),
          ),
          const SizedBox(height: 18),
          Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: context.sxTextP)),
          const SizedBox(height: 6),
          Text(body,
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 13, height: 1.4, color: context.sxTextS)),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: SX.accent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(SX.rMD)),
              ),
              child: Text(actionLabel!),
            ),
          ],
        ]),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// "How to read this" sheet
// ═════════════════════════════════════════════════════════════════════════════
Future<void> showSentimentGuide(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _GuideSheet(),
    );

class _GuideItem {
  final IconData icon;
  final Color color;
  final String title, text;
  const _GuideItem(this.icon, this.color, this.title, this.text);
}

class _GuideSheet extends StatelessWidget {
  const _GuideSheet();

  static const _items = <_GuideItem>[
    _GuideItem(Icons.trending_up_rounded, SX.bull, 'Going up (bullish)',
        'More buyers than sellers. Prices tend to rise.'),
    _GuideItem(Icons.trending_down_rounded, SX.bear, 'Going down (bearish)',
        'More sellers than buyers. Prices tend to fall.'),
    _GuideItem(Icons.speed_rounded, SX.probHigh, 'Confidence',
        'How sure the Atlas engine is about its call. 70% or more is high. It is the engine\'s own estimate, not a promise.'),
    _GuideItem(Icons.how_to_vote_rounded, SX.accent, 'Market gauges',
        'Atlas checks many technical gauges (trend lines, momentum and so on). Each one votes up, down or unsure. The coloured bar shows the votes.'),
    _GuideItem(Icons.flag_rounded, SX.accent, 'Fresh move',
        'The first signal after the direction changes. It marks where a new move may be starting.'),
    _GuideItem(Icons.call_made_rounded, SX.bull, 'Breakout',
        'Price pushed past its recent high (up) or recent low (down).'),
    _GuideItem(Icons.schedule_rounded, SX.neutral, 'Short-term and long-term',
        'The direction of the quick trend versus the bigger trend. When both agree, the signal is easier to trust.'),
    _GuideItem(Icons.show_chart_rounded, SX.strong, 'On the chart',
        'Big triangles are fresh moves. Small diamonds and squares are regular signals. Up markers sit above a candle, down markers below it.'),
  ];

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    return Container(
      constraints: BoxConstraints(maxHeight: h * 0.88),
      decoration: BoxDecoration(
        color: context.sxSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SafeArea(
        top: false,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 14),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
                color: context.sxBorder,
                borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('How to read this screen',
                  style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: context.sxTextP)),
            ),
          ),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (_, i) {
                final it = _items[i];
                return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: it.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(SX.rSM + 2),
                        ),
                        child: Icon(it.icon, size: 18, color: it.color),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(it.title,
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: context.sxTextP)),
                              const SizedBox(height: 2),
                              Text(it.text,
                                  style: TextStyle(
                                      fontSize: 12.5,
                                      height: 1.4,
                                      color: context.sxTextS)),
                            ]),
                      ),
                    ]);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Text(
              'For learning only. Signals are not investment advice, and any call can be wrong.',
              style: TextStyle(fontSize: 11.5, color: context.sxTextS),
            ),
          ),
        ]),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Model (fields unchanged: AtlasDetailDialog depends on them)
// ═════════════════════════════════════════════════════════════════════════════
class AtlasOutput {
  final int id;
  final String createdAt;
  final int negativeIndicators;
  final String negativeIndicatorsList;
  final int neutralIndicators;
  final String neutralIndicatorsList;
  final int positiveIndicators;
  final String positiveIndicatorsList;
  final int totalCrossovers;
  final String totalCrossoversList;
  final int advancing;
  final int breakoutvalue;
  final int crossovers;
  final String date;
  final int declining;
  final bool entry;
  final String longterm;
  final bool lowbreakout;
  final double probability;
  final String shortterm;
  final String time;
  final int timeinmill;
  final String type;
  final bool upbreakout;

  AtlasOutput({
    required this.id,
    required this.createdAt,
    required this.negativeIndicators,
    required this.negativeIndicatorsList,
    required this.neutralIndicators,
    required this.neutralIndicatorsList,
    required this.positiveIndicators,
    required this.positiveIndicatorsList,
    required this.totalCrossovers,
    required this.totalCrossoversList,
    required this.advancing,
    required this.breakoutvalue,
    required this.crossovers,
    required this.date,
    required this.declining,
    required this.entry,
    required this.longterm,
    required this.lowbreakout,
    required this.probability,
    required this.shortterm,
    required this.time,
    required this.timeinmill,
    required this.type,
    required this.upbreakout,
  });

  factory AtlasOutput.fromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.parse(json['created_at']).toLocal();
    return AtlasOutput(
      id: json['id'] as int,
      createdAt: createdAt.toIso8601String(),
      negativeIndicators: (json['Negative Indicators'] as num).toInt(),
      negativeIndicatorsList: json['Negative Indicators List'] as String,
      neutralIndicators: (json['Neutral Indicators'] as num).toInt(),
      neutralIndicatorsList: json['Neutral Indicators List'] as String,
      positiveIndicators: (json['Postive Indicators'] as num).toInt(),
      positiveIndicatorsList: json['Postive Indicators List'] as String,
      totalCrossovers: (json['Total Crossovers'] as num).toInt(),
      totalCrossoversList: json['Total Crossovers List'] as String,
      advancing: (json['advancing'] as num).toInt(),
      breakoutvalue: (json['breakoutvalue'] as num).toInt(),
      crossovers: (json['crossovers'] as num).toInt(),
      date: json['date'] as String,
      declining: (json['declining'] as num).toInt(),
      entry: json['entry'] as bool,
      longterm: json['longterm'] as String,
      lowbreakout: json['lowbreakout'] as bool,
      probability: (json['probability'] as num).toDouble(),
      shortterm: json['shortterm'] as String,
      time: json['time'] as String,
      timeinmill: (json['timeinmill'] as num).toInt(),
      type: json['type'] as String,
      upbreakout: json['upbreakout'] as bool,
    );
  }

  // ── plain-English helpers ──
  DateTime get ts => DateTime.parse(createdAt);
  Mood get mood => SX.mood(type);
  int get totalIndicators =>
      positiveIndicators + negativeIndicators + neutralIndicators;

  String get summary {
    final t = totalIndicators;
    if (t == 0) return mood.plain;
    final n = type == 'Bull'
        ? positiveIndicators
        : (type == 'Bear' ? negativeIndicators : neutralIndicators);
    return '$n of $t market gauges say ${mood.voteWord}.';
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Service
// ═════════════════════════════════════════════════════════════════════════════
class AtlasPage {
  final List<AtlasOutput> items;
  final int total;
  const AtlasPage(this.items, this.total);
}

class AtlasLogService {
  final SupabaseClient _client;
  AtlasLogService(this._client);

  PostgrestFilterBuilder _filters(
    PostgrestFilterBuilder q, {
    DateTime? date,
    required bool strong,
    required bool firstEntry,
    String? type,
  }) {
    if (date != null) {
      final s = DateTime(date.year, date.month, date.day);
      final e = s.add(const Duration(days: 1));
      // Send UTC so "today" means the user's local day, not the server's.
      q = q
          .gte('created_at', s.toUtc().toIso8601String())
          .lt('created_at', e.toUtc().toIso8601String());
    }
    if (strong) q = q.gte('probability', SX.strongProb);
    if (firstEntry) q = q.eq('entry', true);
    if (type != null) q = q.eq('type', type);
    return q;
  }

  Future<AtlasPage> fetch({
    required int page,
    required int pageSize,
    DateTime? date,
    bool strong = false,
    bool firstEntry = false,
    String? type,
  }) async {
    final from = (page - 1) * pageSize;
    final to = from + pageSize - 1;

    final rows = await _filters(
      _client.from('atlas_output').select(),
      date: date,
      strong: strong,
      firstEntry: firstEntry,
      type: type,
    ).order('created_at', ascending: false).range(from, to);

    final ids = await _filters(
      _client.from('atlas_output').select('id'),
      date: date,
      strong: strong,
      firstEntry: firstEntry,
      type: type,
    );

    return AtlasPage(
      (rows as List)
          .map((e) => AtlasOutput.fromJson(e as Map<String, dynamic>))
          .toList(),
      (ids as List).length,
    );
  }

  RealtimeChannel subscribe(void Function(AtlasOutput) onNew) {
    return _client
        .channel('atlas_feed_${DateTime.now().millisecondsSinceEpoch}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'atlas_output',
          callback: (payload) {
            if (payload.newRecord.isEmpty) return;
            try {
              onNew(AtlasOutput.fromJson(payload.newRecord));
            } catch (e) {
              debugPrint('atlas realtime parse error: $e');
            }
          },
        )
        .subscribe();
  }

  void unsubscribe(RealtimeChannel ch) => _client.removeChannel(ch);
}

// ═════════════════════════════════════════════════════════════════════════════
// Page
// ═════════════════════════════════════════════════════════════════════════════
class MarketSentimentPage extends StatefulWidget {
  /// true when opened from the chart page (header button then goes back).
  final bool fromChart;
  const MarketSentimentPage({super.key, this.fromChart = false});

  @override
  State<MarketSentimentPage> createState() => _MarketSentimentPageState();
}

class _MarketSentimentPageState extends State<MarketSentimentPage> {
  static const _pageSize = 10;
  final _svc = AtlasLogService(Supabase.instance.client);
  RealtimeChannel? _channel;
  int _req = 0;

  List<AtlasOutput> _items = [];
  bool _loading = true;
  String? _error;
  int _page = 1, _total = 0;
  DateTime? _date;
  bool _strong = true;
  bool _firstEntry = false;
  int _view = 0; // 0 all, 1 up, 2 down

  String? get _typeFilter => _view == 1 ? 'Bull' : (_view == 2 ? 'Bear' : null);
  bool get _hasFilters => _date != null || _strong || _firstEntry;
  int get _totalPages => (_total / _pageSize).ceil().clamp(1, 99999);

  @override
  void initState() {
    super.initState();
    AchievementEvents.openedSentiment(); // once, not on every rebuild
    _fetch();
    _channel = _svc.subscribe(_onLive);
  }

  @override
  void dispose() {
    final ch = _channel;
    if (ch != null) _svc.unsubscribe(ch);
    super.dispose();
  }

  bool _matches(AtlasOutput o) {
    if (_date != null) {
      final t = o.ts;
      if (t.year != _date!.year ||
          t.month != _date!.month ||
          t.day != _date!.day) {
        return false;
      }
    }
    if (_strong && o.probability < SX.strongProb) return false;
    if (_firstEntry && !o.entry) return false;
    if (_typeFilter != null && o.type != _typeFilter) return false;
    return true;
  }

  void _onLive(AtlasOutput o) {
    if (!mounted || _page != 1 || !_matches(o)) return;
    HapticFeedback.lightImpact();
    setState(() {
      _items =
          [o, ..._items.where((e) => e.id != o.id)].take(_pageSize).toList();
      _total++;
    });
  }

  Future<void> _fetch() async {
    final req = ++_req;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await _svc.fetch(
        page: _page,
        pageSize: _pageSize,
        date: _date,
        strong: _strong,
        firstEntry: _firstEntry,
        type: _typeFilter,
      );
      if (!mounted || req != _req) return;
      setState(() {
        _items = r.items;
        _total = r.total;
        _loading = false;
      });
    } catch (e) {
      debugPrint('atlas fetch error: $e');
      if (!mounted || req != _req) return;
      setState(() {
        _error =
            'We couldn\'t load the signals. Check your internet connection and try again.';
        _loading = false;
      });
    }
  }

  void _apply(VoidCallback change) {
    setState(() {
      change();
      _page = 1;
    });
    _fetch();
  }

  void _resetFilters() => _apply(() {
        _date = null;
        _strong = false;
        _firstEntry = false;
        _view = 0;
      });

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: SX.accent),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) _apply(() => _date = picked);
  }

  void _openChart({DateTime? date, bool allowPop = false}) {
    if (allowPop && widget.fromChart) {
      Navigator.of(context).maybePop();
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => MarketSentimentChartPage(
        initialDate: date ?? (_items.isNotEmpty ? _items.first.ts : null),
        fromList: true,
      ),
    ));
  }

  void _showDetail(AtlasOutput o) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => AtlasDetailDialog(output: o),
      );

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: context.sxBg,
        body: SafeArea(
          child: RefreshIndicator(
            color: SX.accent,
            onRefresh: _fetch,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _Header(
                    onBack: () => Navigator.of(context).maybePop(),
                    onHelp: () => showSentimentGuide(context),
                    onChart: () => _openChart(allowPop: true),
                  ),
                ),
                if (!_loading && _error == null && _items.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _Hero(
                      o: _items.first,
                      onChart: () => _openChart(date: _items.first.ts),
                      onGuide: () => showSentimentGuide(context),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: _Segmented(
                    value: _view,
                    onChanged: (v) => _apply(() => _view = v),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _Filters(
                    date: _date,
                    strong: _strong,
                    firstEntry: _firstEntry,
                    hasFilters: _hasFilters,
                    onDate: _pickDate,
                    onDateClear: () => _apply(() => _date = null),
                    onStrong: (v) => _apply(() => _strong = v),
                    onFirstEntry: (v) => _apply(() => _firstEntry = v),
                    onReset: _resetFilters,
                    onGuide: () => showSentimentGuide(context),
                  ),
                ),
                ..._body(),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _body() {
    if (_loading) {
      return [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((_, __) => const _Skeleton(),
                childCount: 4),
          ),
        ),
      ];
    }
    if (_error != null) {
      return [
        SliverToBoxAdapter(
          child: SxMessage(
            icon: Icons.cloud_off_rounded,
            color: SX.bear,
            title: 'Can\'t reach the server',
            body: _error!,
            actionLabel: 'Try again',
            onAction: _fetch,
          ),
        ),
      ];
    }
    if (_items.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: SxMessage(
            icon: Icons.inbox_rounded,
            title: 'No signals to show',
            body: _hasFilters || _view != 0
                ? 'Nothing matches your filters. Turn some off to see more.'
                : 'New signals appear here as soon as Atlas produces them.',
            actionLabel: _hasFilters || _view != 0 ? 'Clear filters' : null,
            onAction: _hasFilters || _view != 0 ? _resetFilters : null,
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) => _SignalCard(
              key: ValueKey(_items[i].id),
              o: _items[i],
              index: i,
              onTap: () => _showDetail(_items[i]),
              onChart: () => _openChart(date: _items[i].ts),
            ),
            childCount: _items.length,
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: _Pagination(
          page: _page,
          totalPages: _totalPages,
          total: _total,
          onPrev: _page > 1
              ? () {
                  setState(() => _page--);
                  _fetch();
                }
              : null,
          onNext: _page < _totalPages
              ? () {
                  setState(() => _page++);
                  _fetch();
                }
              : null,
        ),
      ),
    ];
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Header
// ═════════════════════════════════════════════════════════════════════════════
class _Header extends StatelessWidget {
  final VoidCallback onBack, onHelp, onChart;
  const _Header(
      {required this.onBack, required this.onHelp, required this.onChart});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(children: [
          SxIconBtn(
              icon: Icons.arrow_back_ios_new_rounded, size: 15, onTap: onBack),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Market mood',
                  style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: context.sxTextP)),
              const SizedBox(height: 2),
              Row(children: [
                const _LiveDot(),
                const SizedBox(width: 6),
                Text('Live, updates by itself',
                    style: TextStyle(fontSize: 11.5, color: context.sxTextS)),
              ]),
            ]),
          ),
          SxIconBtn(
              icon: Icons.help_outline_rounded,
              tooltip: 'How to read this',
              onTap: onHelp),
          const SizedBox(width: 8),
          SxPillBtn(
              icon: Icons.show_chart_rounded, label: 'Chart', onTap: onChart),
        ]),
      );
}

class _LiveDot extends StatefulWidget {
  const _LiveDot();
  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: Tween<double>(begin: 0.35, end: 1).animate(_c),
        child: Container(
          width: 6,
          height: 6,
          decoration:
              const BoxDecoration(color: SX.probHigh, shape: BoxShape.circle),
        ),
      );
}

// ═════════════════════════════════════════════════════════════════════════════
// Hero: the latest read in one glance
// ═════════════════════════════════════════════════════════════════════════════
class _Hero extends StatelessWidget {
  final AtlasOutput o;
  final VoidCallback onChart, onGuide;
  const _Hero({required this.o, required this.onChart, required this.onGuide});

  @override
  Widget build(BuildContext context) {
    final m = o.mood;
    final c2 = Color.lerp(m.color, SX.accent, 0.55)!;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [m.color, c2],
        ),
        borderRadius: BorderRadius.circular(SX.rLG + 4),
        boxShadow: [
          BoxShadow(
            color: m.color.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Latest read, ${timeago.format(o.ts)}',
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white70)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(m.icon, color: Colors.white, size: 28),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(m.headline,
                      style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: Colors.white)),
                ),
              ]),
              const SizedBox(height: 6),
              Text('${m.plain}. ${o.summary}',
                  style: const TextStyle(
                      fontSize: 13.5, height: 1.35, color: Colors.white)),
            ]),
          ),
          const SizedBox(width: 14),
          Column(children: [
            SxRing(
              value: o.probability,
              size: 68,
              color: Colors.white,
              track: Colors.white24,
            ),
            const SizedBox(height: 4),
            Text(SX.confidence(o.probability),
                style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70)),
          ]),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          FilledButton.icon(
            onPressed: onChart,
            icon: const Icon(Icons.show_chart_rounded, size: 18),
            label: const Text('See it on the chart'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: m.color,
              textStyle:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(SX.rMD)),
            ),
          ),
          const SizedBox(width: 6),
          TextButton(
            onPressed: onGuide,
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: const Text('Tell me more?',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
          ),
        ]),
      ]),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// All / Going up / Going down
// ═════════════════════════════════════════════════════════════════════════════
class _Segmented extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _Segmented({required this.value, required this.onChanged});

  static const _labels = ['All', 'Going up', 'Going down'];
  static const _icons = [
    Icons.apps_rounded,
    Icons.trending_up_rounded,
    Icons.trending_down_rounded,
  ];
  static const _colors = [SX.accent, SX.bull, SX.bear];

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: context.sxSurface,
          borderRadius: BorderRadius.circular(SX.rMD + 2),
          border: Border.all(color: context.sxBorder),
        ),
        child: Row(children: [
          for (var i = 0; i < 3; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: value == i ? _colors[i] : Colors.transparent,
                    borderRadius: BorderRadius.circular(SX.rMD - 2),
                  ),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_icons[i],
                            size: 15,
                            color: value == i ? Colors.white : context.sxTextS),
                        const SizedBox(width: 6),
                        Text(_labels[i],
                            style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: value == i
                                    ? Colors.white
                                    : context.sxTextS)),
                      ]),
                ),
              ),
            ),
        ]),
      );
}

// ═════════════════════════════════════════════════════════════════════════════
// Filters
// ═════════════════════════════════════════════════════════════════════════════
class _Filters extends StatelessWidget {
  final DateTime? date;
  final bool strong, firstEntry, hasFilters;
  final VoidCallback onDate, onDateClear, onReset, onGuide;
  final ValueChanged<bool> onStrong, onFirstEntry;

  const _Filters({
    required this.date,
    required this.strong,
    required this.firstEntry,
    required this.hasFilters,
    required this.onDate,
    required this.onDateClear,
    required this.onReset,
    required this.onGuide,
    required this.onStrong,
    required this.onFirstEntry,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(spacing: 8, runSpacing: 8, children: [
            _FilterPill(
              icon: Icons.calendar_today_rounded,
              label: date == null
                  ? 'Any date'
                  : DateFormat('d MMM yyyy').format(date!),
              active: date != null,
              onTap: onDate,
              onClear: date != null ? onDateClear : null,
            ),
            _FilterPill(
              icon: Icons.bolt_rounded,
              label: 'High confidence',
              active: strong,
              onTap: () => onStrong(!strong),
            ),
            _FilterPill(
              icon: Icons.flag_rounded,
              label: 'Fresh moves',
              active: firstEntry,
              onTap: () => onFirstEntry(!firstEntry),
            ),
            if (hasFilters)
              _FilterPill(
                icon: Icons.filter_alt_off_rounded,
                label: 'Clear',
                active: false,
                danger: true,
                onTap: onReset,
              ),
          ]),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onGuide,
            child: Text(
              'High confidence means the engine is 70% or more sure. A fresh move is the first signal after a change in direction.',
              style: TextStyle(
                  fontSize: 11.5, height: 1.35, color: context.sxTextS),
            ),
          ),
        ]),
      );
}

class _FilterPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active, danger;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  const _FilterPill({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.onClear,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = danger ? SX.bear : (active ? SX.accent : context.sxTextS);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? SX.accent.withValues(alpha: 0.12) : context.sxSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: active
                  ? SX.accent.withValues(alpha: 0.45)
                  : context.sxBorder),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active || danger ? fg : context.sxTextP)),
          if (onClear != null) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onClear,
              child: Icon(Icons.close_rounded, size: 14, color: fg),
            ),
          ],
        ]),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Signal card
// ═════════════════════════════════════════════════════════════════════════════
class _SignalCard extends StatelessWidget {
  final AtlasOutput o;
  final int index;
  final VoidCallback onTap, onChart;
  const _SignalCard({
    super.key,
    required this.o,
    required this.index,
    required this.onTap,
    required this.onChart,
  });

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    final m = o.mood;
    final pc = SX.probColor(o.probability);

    final card = SxTapScale(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
        decoration: BoxDecoration(
          color: context.sxSurface,
          borderRadius: BorderRadius.circular(SX.rLG),
          border: Border.all(color: context.sxBorder),
          boxShadow: dark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: m.dim(dark),
                borderRadius: BorderRadius.circular(SX.rMD),
              ),
              child: Icon(m.icon, size: 22, color: m.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.headline,
                        style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: context.sxTextP)),
                    const SizedBox(height: 2),
                    Text(
                        '${DateFormat('h:mm a').format(o.ts)}, ${timeago.format(o.ts)}',
                        style:
                            TextStyle(fontSize: 11.5, color: context.sxTextS)),
                  ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${o.probability.toStringAsFixed(0)}%',
                  style: TextStyle(
                      fontSize: 19, fontWeight: FontWeight.w800, color: pc)),
              Text(SX.confidence(o.probability),
                  style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w600, color: pc)),
            ]),
          ]),
          const SizedBox(height: 12),
          Text(o.summary,
              style: TextStyle(fontSize: 13, color: context.sxTextP)),
          const SizedBox(height: 10),
          SxVoteBar(
              pos: o.positiveIndicators,
              neut: o.neutralIndicators,
              neg: o.negativeIndicators),
          const SizedBox(height: 7),
          SxVoteLegend(
              pos: o.positiveIndicators,
              neut: o.neutralIndicators,
              neg: o.negativeIndicators),
          const SizedBox(height: 12),
          Wrap(spacing: 6, runSpacing: 6, children: [
            if (o.entry)
              const SxChip(
                  label: 'Fresh move',
                  icon: Icons.flag_rounded,
                  color: SX.accent),
            if (o.upbreakout)
              const SxChip(
                  label: 'Broke above recent high',
                  icon: Icons.north_rounded,
                  color: SX.bull),
            if (o.lowbreakout)
              const SxChip(
                  label: 'Broke below recent low',
                  icon: Icons.south_rounded,
                  color: SX.bear),
            SxChip(
                label: 'Short-term: ${SX.trendWord(o.shortterm)}',
                color: SX.trendColor(o.shortterm)),
            SxChip(
                label: 'Long-term: ${SX.trendWord(o.longterm)}',
                color: SX.trendColor(o.longterm)),
          ]),
          const SizedBox(height: 4),
          Divider(height: 16, color: context.sxBorder),
          Row(children: [
            TextButton.icon(
              onPressed: onChart,
              icon: const Icon(Icons.show_chart_rounded, size: 16),
              label: const Text('View on chart'),
              style: TextButton.styleFrom(
                foregroundColor: SX.accent,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                textStyle: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ),
            const Spacer(),
            const Text('Details',
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: SX.accent)),
            const Icon(Icons.chevron_right_rounded, size: 18, color: SX.accent),
          ]),
        ]),
      ),
    );

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 240 + index * 40),
      curve: Curves.easeOut,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child:
            Transform.translate(offset: Offset(0, (1 - v) * 10), child: child),
      ),
      child: card,
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Pagination
// ═════════════════════════════════════════════════════════════════════════════
class _Pagination extends StatelessWidget {
  final int page, totalPages, total;
  final VoidCallback? onPrev, onNext;
  const _Pagination({
    required this.page,
    required this.totalPages,
    required this.total,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: context.sxSurface,
            borderRadius: BorderRadius.circular(SX.rMD),
            border: Border.all(color: context.sxBorder),
          ),
          child: Row(children: [
            _PageBtn(icon: Icons.chevron_left_rounded, onTap: onPrev),
            Expanded(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('Page $page of $totalPages',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: context.sxTextP)),
                Text('$total signals in total',
                    style: TextStyle(fontSize: 11, color: context.sxTextS)),
              ]),
            ),
            _PageBtn(icon: Icons.chevron_right_rounded, onTap: onNext),
          ]),
        ),
      );
}

class _PageBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _PageBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => SxTapScale(
        onTap: onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: onTap != null ? 1 : 0.28,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(SX.rSM),
              border: Border.all(color: context.sxBorder),
            ),
            child: Icon(icon, size: 20, color: context.sxTextP),
          ),
        ),
      );
}

// ═════════════════════════════════════════════════════════════════════════════
// Skeleton
// ═════════════════════════════════════════════════════════════════════════════
class _Skeleton extends StatefulWidget {
  const _Skeleton();
  @override
  State<_Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<_Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _b(BuildContext ctx, double w, double h, {double r = 6}) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: ctx.isDark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.black.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(r),
        ),
      );

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: Tween<double>(begin: 0.4, end: 1).animate(_c),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.sxSurface,
            borderRadius: BorderRadius.circular(SX.rLG),
            border: Border.all(color: context.sxBorder),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _b(context, 42, 42, r: 14),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _b(context, 140, 14),
                const SizedBox(height: 6),
                _b(context, 90, 10),
              ]),
              const Spacer(),
              _b(context, 48, 30),
            ]),
            const SizedBox(height: 14),
            _b(context, double.infinity, 12),
            const SizedBox(height: 10),
            _b(context, double.infinity, 6),
            const SizedBox(height: 12),
            Row(children: [
              _b(context, 90, 22, r: 8),
              const SizedBox(width: 8),
              _b(context, 110, 22, r: 8),
            ]),
          ]),
        ),
      );
}
