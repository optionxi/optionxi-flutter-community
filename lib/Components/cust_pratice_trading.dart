// Market-phase rules (IST, Asia/Kolkata = UTC+5:30), every day:
//   09:15 – 15:30  -> LIVE
//   16:00 – 22:15  -> LIVE
//   everything else -> CLOSED
//
// Both live windows show a "Previous day's data · For educational purposes
// only" disclaimer, since prev_nifty_indices holds a prior session's snapshot
// rather than a true live feed.
//
// For "Enable Realtime" on prev_nifty_indices in Supabase dashboard,
// run: alter publication supabase_realtime add table public.prev_nifty_indices;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================================
// COLOR TOKENS — dark / light aware
// ============================================================================

class PTColors {
  final Color bg;
  final Color surface;
  final Color surface2;
  final Color border;
  final Color text;
  final Color muted;
  final Color green;
  final Color red;
  final Color amber;
  final Color blue;
  final Color grey;

  const PTColors._({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.border,
    required this.text,
    required this.muted,
    required this.green,
    required this.red,
    required this.amber,
    required this.blue,
    required this.grey,
  });

  static const dark = PTColors._(
    bg: Color(0xFF0B0F14),
    surface: Color(0xFF131920),
    surface2: Color(0xFF181F28),
    border: Color(0xFF232B36),
    text: Color(0xFFEDEFF2),
    muted: Color(0xFF8B96A5),
    green: Color(0xFF00D68F),
    red: Color(0xFFFF4757),
    amber: Color(0xFFF5C544),
    blue: Color(0xFF4EA8FF),
    grey: Color(0xFF5B6472),
  );

  static const light = PTColors._(
    bg: Color(0xFFF5F6F8),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFF0F2F5),
    border: Color(0xFFE3E6EB),
    text: Color(0xFF14171C),
    muted: Color(0xFF667085),
    green: Color(0xFF0C9463),
    red: Color(0xFFDD3648),
    amber: Color(0xFFAD7A0C),
    blue: Color(0xFF2A66D9),
    grey: Color(0xFF8A93A3),
  );

  static PTColors of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }
}

// ============================================================================
// MARKET PHASE — IST-based session logic
// ============================================================================

enum MarketPhase { session1, session2, closed }

class MarketStatus {
  static const int _session1OpenMin = 9 * 60 + 15; // 09:15
  static const int _session1CloseMin = 15 * 60 + 30; // 15:30
  static const int _session2OpenMin = 16 * 60; // 16:00
  static const int _session2CloseMin = 22 * 60 + 15; // 22:15

  /// Current IST time, derived from device UTC clock (no dependency needed).
  static DateTime nowIst() {
    final utcNow = DateTime.now().toUtc();
    return utcNow.add(const Duration(hours: 5, minutes: 30));
  }

  /// Live windows run every day (no weekend exception):
  ///   09:15 – 15:30  and  16:00 – 22:15  IST.
  static MarketPhase currentPhase() {
    final ist = nowIst();
    final minutes = ist.hour * 60 + ist.minute;
    if (minutes >= _session1OpenMin && minutes <= _session1CloseMin) {
      return MarketPhase.session1;
    }
    if (minutes >= _session2OpenMin && minutes <= _session2CloseMin) {
      return MarketPhase.session2;
    }
    return MarketPhase.closed;
  }

  static bool isLive(MarketPhase phase) => phase != MarketPhase.closed;

  static ({String badge, String headline, String subtitle, String? note}) copy(
      MarketPhase phase) {
    switch (phase) {
      case MarketPhase.session1:
      case MarketPhase.session2:
        return (
          badge: 'LIVE',
          headline: 'Trade the real market.\nZero risk.',
          subtitle: 'Price update are delayed by 24 hours',
          note: "Previous day's data · For educational purposes only",
        );
      case MarketPhase.closed:
        return (
          badge: 'CLOSED',
          headline: 'Market is closed.\nPractice anytime.',
          subtitle: 'Live session resumes at 9:15 AM IST',
          note: null,
        );
    }
  }
}

// ============================================================================
// MODELS
// ============================================================================

class IndexQuote {
  final String symbol;
  final double ltp;
  final double open;
  final double prevClose;
  final double high;
  final double low;
  final int volume;
  final double pChange;

  const IndexQuote({
    required this.symbol,
    required this.ltp,
    required this.open,
    required this.prevClose,
    required this.high,
    required this.low,
    required this.volume,
    required this.pChange,
  });

  bool get isUp => ltp >= prevClose;

  factory IndexQuote.fromMap(Map<String, dynamic> map) {
    return IndexQuote(
      symbol: map['symbol'] as String,
      ltp: _num(map['ltp']),
      open: _num(map['o']),
      prevClose: _num(map['pc']),
      high: _num(map['h']),
      low: _num(map['l']),
      volume: (map['v'] as num?)?.toInt() ?? 0,
      pChange: _num(map['pcnt']),
    );
  }

  static double _num(Object? v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}

class TraderInfo {
  final String suid;
  final String? displayName;
  final String? imgUrl;

  const TraderInfo({required this.suid, this.displayName, this.imgUrl});

  factory TraderInfo.fromMap(Map<String, dynamic> map) {
    return TraderInfo(
      suid: map['suid'] as String,
      displayName: map['displayname'] as String?,
      imgUrl: map['imgurl'] as String?,
    );
  }

  String get initial {
    final n = (displayName ?? '').trim();
    return n.isEmpty ? '?' : n[0].toUpperCase();
  }
}

// ============================================================================
// NUMBER FORMATTING — Indian grouping (no intl dependency required)
// ============================================================================

String formatIndianNumber(double value, {int decimals = 2}) {
  final isNeg = value < 0;
  final fixed = value.abs().toStringAsFixed(decimals);
  final parts = fixed.split('.');
  final intPart = parts[0];
  final decPart = parts.length > 1 ? parts[1] : '';

  String grouped;
  if (intPart.length <= 3) {
    grouped = intPart;
  } else {
    final last3 = intPart.substring(intPart.length - 3);
    final rest = intPart.substring(0, intPart.length - 3);
    grouped = '${_indianGroup(rest)},$last3';
  }
  final out = '$grouped${decPart.isNotEmpty ? '.$decPart' : ''}';
  return isNeg ? '-$out' : out;
}

String _indianGroup(String rest) {
  final chunks = <String>[];
  var s = rest;
  while (s.length > 2) {
    chunks.insert(0, s.substring(s.length - 2));
    s = s.substring(0, s.length - 2);
  }
  chunks.insert(0, s);
  return chunks.join(',');
}

// ============================================================================
// PRACTICE TRADE CARD
// ============================================================================

class PracticeTradeCard extends StatefulWidget {
  final VoidCallback? onTap;

  const PracticeTradeCard({super.key, this.onTap});

  @override
  State<PracticeTradeCard> createState() => _PracticeTradeCardState();
}

class _PracticeTradeCardState extends State<PracticeTradeCard> {
  static const _watchSymbols = ['NIFTY50', 'NIFTYBANK'];

  final SupabaseClient _client = Supabase.instance.client;
  RealtimeChannel? _channel;
  Timer? _phaseTimer;

  bool _loading = true;
  String? _error;

  Map<String, IndexQuote> _quotes = {};
  List<TraderInfo> _topTraders = [];
  int _traderCount = 0;

  MarketPhase _phase = MarketStatus.currentPhase();

  @override
  void initState() {
    super.initState();
    _bootstrap();
    // Re-evaluate market phase every 30s so the badge flips automatically
    // as the clock crosses session boundaries.
    _phaseTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      final next = MarketStatus.currentPhase();
      if (next != _phase && mounted) {
        setState(() => _phase = next);
      }
    });
  }

  @override
  void dispose() {
    _phaseTimer?.cancel();
    final ch = _channel;
    if (ch != null) {
      _client.removeChannel(ch);
    }
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await Future.wait([_fetchQuotes(), _fetchTraders()]);
      _subscribeRealtime();
      if (mounted) setState(() => _loading = false);
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = "Couldn't load market data. Check your connection.";
        });
      }
    }
  }

  Future<void> _fetchQuotes() async {
    final rows = await _client
        .from('prev_nifty_indices')
        .select()
        .inFilter('symbol', _watchSymbols);

    final map = <String, IndexQuote>{};
    for (final row in (rows as List)) {
      final q = IndexQuote.fromMap(row as Map<String, dynamic>);
      map[q.symbol] = q;
    }
    if (mounted) setState(() => _quotes = map);
  }

  Future<void> _fetchTraders() async {
    final rows = await _client
        .from('prev_balance')
        .select('suid, displayname, imgurl, updated_at')
        .order('updated_at', ascending: false)
        .limit(3);

    final traders = (rows as List)
        .map((r) => TraderInfo.fromMap(r as Map<String, dynamic>))
        .toList();

    final countRes = await _client
        .from('prev_balance')
        .select('id')
        .count(CountOption.exact);

    if (mounted) {
      setState(() {
        _topTraders = traders;
        _traderCount = countRes.count;
      });
    }
  }

  void _subscribeRealtime() {
    _channel = _client
        .channel('public:prev_nifty_indices')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'prev_nifty_indices',
          callback: (payload) {
            final newRow = payload.newRecord;
            if (newRow.isEmpty) return;
            final q = IndexQuote.fromMap(newRow);
            if (_watchSymbols.contains(q.symbol) && mounted) {
              setState(() => _quotes = {..._quotes, q.symbol: q});
            }
          },
        )
        .subscribe();
  }

  @override
  Widget build(BuildContext context) {
    final c = PTColors.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.border),
        ),
        child: _error != null
            ? _ErrorState(colors: c, message: _error!, onRetry: _bootstrap)
            : _LoadedContent(
                colors: c,
                phase: _phase,
                quotes: _quotes,
                topTraders: _topTraders,
                traderCount: _traderCount,
                isLoading: _loading,
              ),
      ),
    );
  }
}

// ============================================================================
// LOADED CONTENT
// ============================================================================

class _LoadedContent extends StatelessWidget {
  final PTColors colors;
  final MarketPhase phase;
  final Map<String, IndexQuote> quotes;
  final List<TraderInfo> topTraders;
  final int traderCount;
  final bool isLoading; // NEW

  const _LoadedContent({
    required this.colors,
    required this.phase,
    required this.quotes,
    required this.topTraders,
    required this.traderCount,
    required this.isLoading, // NEW
  });

  @override
  Widget build(BuildContext context) {
    final copy = MarketStatus.copy(phase);
    final nifty = quotes['NIFTY50'];
    final bankNifty = quotes['NIFTYBANK'];

    return InkWell(
      onTap: () {
        Get.toNamed('/practice-trading');
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: label + phase badge
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: colors.amber,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'PRACTICE TRADING',
                style: TextStyle(
                  color: colors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              _PhaseBadge(colors: colors, phase: phase, label: copy.badge),
            ],
          ),
          const SizedBox(height: 14),

          // Headline
          Text(
            copy.headline,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: colors.text,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            copy.subtitle,
            style: TextStyle(color: colors.muted, fontSize: 12),
          ),
          if (copy.note != null) ...[
            const SizedBox(height: 8),
            _DisclaimerNote(colors: colors, text: copy.note!),
          ],
          const SizedBox(height: 16),

          // Price ticker row — only this reflects loading
          Row(
            children: [
              Expanded(
                child: _MiniTicker(
                  colors: colors,
                  label: 'NIFTY 50',
                  quote: nifty,
                  isLoading: isLoading, // NEW
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: _MiniTicker(
                  colors: colors,
                  label: 'BANKNIFTY',
                  quote: bankNifty,
                  isLoading: isLoading, // NEW
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Footer: traders + CTA — only avatar stack + count text reflect loading
          Row(
            children: [
              _TraderAvatarStack(
                colors: colors,
                traders: topTraders,
                isLoading: isLoading, // NEW
              ),
              const SizedBox(width: 8),
              Expanded(
                child: isLoading
                    ? _SkeletonBar(colors: colors, width: 140, height: 11)
                    : Text(
                        traderCount > 0
                            ? '₹300k virtual capital · ${formatIndianNumber(traderCount.toDouble(), decimals: 0)}+ traders'
                            : '₹300k virtual capital',
                        style: TextStyle(color: colors.muted, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
              // Start CTA button — UNCHANGED, always tappable/visible
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: colors.amber,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Start',
                      style: TextStyle(
                        color: colors.bg,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward, size: 14, color: colors.bg),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
// ============================================================================
// DISCLAIMER NOTE — "previous day's data, for educational purposes only"
// ============================================================================

class _DisclaimerNote extends StatelessWidget {
  final PTColors colors;
  final String text;

  const _DisclaimerNote({required this.colors, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: colors.surface2,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline_rounded, size: 12, color: colors.muted),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: colors.muted,
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// PHASE BADGE (with pulsing dot when a session is live/replaying)
// ============================================================================

class _PhaseBadge extends StatefulWidget {
  final PTColors colors;
  final MarketPhase phase;
  final String label;

  const _PhaseBadge({
    required this.colors,
    required this.phase,
    required this.label,
  });

  @override
  State<_PhaseBadge> createState() => _PhaseBadgeState();
}

class _PhaseBadgeState extends State<_PhaseBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _dotColor {
    switch (widget.phase) {
      case MarketPhase.session1:
      case MarketPhase.session2:
        return widget.colors.green;
      case MarketPhase.closed:
        return widget.colors.grey;
    }
  }

  bool get _pulses => widget.phase != MarketPhase.closed;

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              final opacity = _pulses ? 0.4 + (_ctrl.value * 0.6) : 1.0;
              return Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _dotColor.withOpacity(opacity),
                  shape: BoxShape.circle,
                ),
              );
            },
          ),
          const SizedBox(width: 5),
          Text(
            widget.label,
            style: TextStyle(
              color: c.muted,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// MINI TICKER
// ============================================================================

class _MiniTicker extends StatelessWidget {
  final PTColors colors;
  final String label;
  final IndexQuote? quote;
  final bool isLoading; // NEW

  const _MiniTicker({
    required this.colors,
    required this.label,
    required this.quote,
    required this.isLoading, // NEW
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: colors.muted, fontSize: 10.5)),
          const SizedBox(height: 4),
          _SkeletonBar(colors: colors, width: 70, height: 14),
          const SizedBox(height: 4),
          _SkeletonBar(colors: colors, width: 44, height: 10),
        ],
      );
    }

    if (quote == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: colors.muted, fontSize: 10.5)),
          const SizedBox(height: 2),
          Text('—', style: TextStyle(color: colors.muted, fontSize: 13)),
        ],
      );
    }

    final changeColor = quote!.isUp ? colors.green : colors.red;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.muted, fontSize: 10.5)),
        const SizedBox(height: 2),
        Row(
          children: [
            Flexible(
              child: Text(
                formatIndianNumber(quote!.ltp),
                style: TextStyle(
                  color: colors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'JetBrainsMono',
                  fontFamilyFallback: const ['monospace'],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              quote!.isUp ? Icons.arrow_drop_up : Icons.arrow_drop_down,
              size: 16,
              color: changeColor,
            ),
          ],
        ),
        Text(
          '${quote!.isUp ? '+' : ''}${quote!.pChange.toStringAsFixed(2)}%',
          style: TextStyle(
            color: changeColor,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// SHIMMER PRIMITIVES — reused by any widget that needs a skeleton state
// ============================================================================

class _Shimmer extends StatefulWidget {
  final PTColors colors;
  final Widget child;

  const _Shimmer({required this.colors, required this.child});

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

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
        return Opacity(
          opacity: 0.5 + _ctrl.value * 0.3,
          child: widget.child,
        );
      },
    );
  }
}

class _SkeletonBar extends StatelessWidget {
  final PTColors colors;
  final double width;
  final double height;

  const _SkeletonBar({
    required this.colors,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      colors: colors,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: colors.surface2,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}

// ============================================================================
// TRADER AVATAR STACK
// ============================================================================

class _TraderAvatarStack extends StatelessWidget {
  final PTColors colors;
  final List<TraderInfo> traders;
  final bool isLoading; // NEW

  const _TraderAvatarStack({
    required this.colors,
    required this.traders,
    required this.isLoading, // NEW
  });

  @override
  Widget build(BuildContext context) {
    const double size = 22;
    const double overlap = 12;

    if (isLoading) {
      return SizedBox(
        width: size + overlap * 2, // reserve space for ~3 avatars
        height: size,
        child: Stack(
          children: [
            for (int i = 0; i < 3; i++)
              Positioned(
                left: i * overlap,
                child: _Shimmer(
                  colors: colors,
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.surface, width: 1.5),
                      color: colors.surface2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    if (traders.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      width: size + overlap * (traders.length - 1),
      height: size,
      child: Stack(
        children: [
          for (int i = 0; i < traders.length; i++)
            Positioned(
              left: i * overlap,
              child: _Avatar(colors: colors, trader: traders[i], size: size),
            ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final PTColors colors;
  final TraderInfo trader;
  final double size;

  const _Avatar({
    required this.colors,
    required this.trader,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final hasImg = (trader.imgUrl ?? '').isNotEmpty;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: colors.surface, width: 1.5),
        color: colors.surface2,
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImg
          ? Image.network(
              trader.imgUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _initialAvatar(),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return _initialAvatar();
              },
            )
          : _initialAvatar(),
    );
  }

  Widget _initialAvatar() {
    return Center(
      child: Text(
        trader.initial,
        style: TextStyle(
          color: colors.muted,
          fontSize: size * 0.42,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ============================================================================
// LOADING STATE (skeleton)
// ============================================================================

class _LoadingState extends StatefulWidget {
  final PTColors colors;
  const _LoadingState({required this.colors});

  @override
  State<_LoadingState> createState() => _LoadingStateState();
}

class _LoadingStateState extends State<_LoadingState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final o = 0.5 + _ctrl.value * 0.3;
        Widget bar(double w, double h, {double radius = 6}) => Container(
              width: w,
              height: h,
              decoration: BoxDecoration(
                color: c.surface2.withOpacity(o),
                borderRadius: BorderRadius.circular(radius),
              ),
            );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                bar(120, 11),
                const Spacer(),
                bar(60, 18, radius: 999),
              ],
            ),
            const SizedBox(height: 16),
            bar(180, 18),
            const SizedBox(height: 8),
            bar(220, 12),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      bar(60, 10),
                      const SizedBox(height: 6),
                      bar(80, 14),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      bar(70, 10),
                      const SizedBox(height: 6),
                      bar(90, 14),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                bar(60, 22, radius: 11),
                const SizedBox(width: 8),
                Expanded(child: bar(100, 10)),
                bar(70, 26, radius: 8),
              ],
            ),
          ],
        );
      },
    );
  }
}

// ============================================================================
// ERROR STATE
// ============================================================================

class _ErrorState extends StatelessWidget {
  final PTColors colors;
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.colors,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.wifi_off_rounded, size: 18, color: colors.red),
            const SizedBox(width: 8),
            Text(
              "Couldn't load practice data",
              style: TextStyle(
                color: colors.text,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          message,
          style: TextStyle(color: colors.muted, fontSize: 12.5),
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: colors.amber,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              backgroundColor: colors.surface2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text(
              'Retry',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
            ),
          ),
        ),
      ],
    );
  }
}
