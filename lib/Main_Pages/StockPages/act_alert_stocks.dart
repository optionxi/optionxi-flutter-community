import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:meilisearch/meilisearch.dart' as meili;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:optionxi/DataModels/sample_stock_symbols.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ═════════════════════════════════════════════════════════════
// PALETTE  — warm paper (light) / soft charcoal (dark). No gradients.
// ═════════════════════════════════════════════════════════════

class _P {
  final Color bg, card, cardAlt, line, ink, inkSoft, inkFaint;
  final Color up, upSoft, down, downSoft, amber, amberSoft, onInk;

  const _P({
    required this.bg,
    required this.card,
    required this.cardAlt,
    required this.line,
    required this.ink,
    required this.inkSoft,
    required this.inkFaint,
    required this.up,
    required this.upSoft,
    required this.down,
    required this.downSoft,
    required this.amber,
    required this.amberSoft,
    required this.onInk,
  });

  static const light = _P(
    bg: Color(0xFFF6F4EF),
    card: Color(0xFFFFFFFF),
    cardAlt: Color(0xFFEFECE5),
    line: Color(0xFFE3DFD5),
    ink: Color(0xFF17181C),
    inkSoft: Color(0xFF5E6068),
    inkFaint: Color(0xFF9A9CA3),
    up: Color(0xFF0B8F5F),
    upSoft: Color(0xFFDDF3E9),
    down: Color(0xFFD6403F),
    downSoft: Color(0xFFFBE3E1),
    amber: Color(0xFF9A6A00),
    amberSoft: Color(0xFFFFF0CC),
    onInk: Color(0xFFF6F4EF),
  );

  static const dark = _P(
    bg: Color(0xFF0F1013),
    card: Color(0xFF17191E),
    cardAlt: Color(0xFF1F2228),
    line: Color(0xFF2A2D35),
    ink: Color(0xFFF2F0EA),
    inkSoft: Color(0xFFA6A9B1),
    inkFaint: Color(0xFF6E717A),
    up: Color(0xFF3DD68C),
    upSoft: Color(0xFF12291F),
    down: Color(0xFFFF7A78),
    downSoft: Color(0xFF32171A),
    amber: Color(0xFFF5C451),
    amberSoft: Color(0xFF2D2510),
    onInk: Color(0xFF0F1013),
  );

  static _P of(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark ? dark : light;
}

// ═════════════════════════════════════════════════════════════
// PLAIN-ENGLISH GLOSSARY
// ═════════════════════════════════════════════════════════════

const Map<String, String> _glossary = {
  'Bullish':
      'Traders are mostly buying. The price is moving up and momentum looks positive. It does not guarantee the rise will continue.',
  'Bearish':
      'Traders are mostly selling. The price is moving down and momentum looks weak. It does not guarantee the fall will continue.',
  'Previous close':
      'The price the stock ended at on the last trading day. Today\'s change is measured against this.',
  'Day range':
      'The lowest and highest prices the stock has touched today. The dot shows where the price is right now within that range.',
  '52-week range':
      'The lowest and highest prices over the past year. A dot near the right end means the stock is close to its yearly best.',
  'Volume':
      'How many shares changed hands today. Higher volume means more people are actively trading it.',
  'Volume vs normal':
      'Today\'s volume compared with the average of the last 5 days. 2x means twice as busy as usual — big moves on high volume are usually taken more seriously.',
  'Yesterday\'s high':
      'The highest price the stock reached yesterday. Rising above it is called a "breakout" — buyers pushed past a recent ceiling.',
  'Yesterday\'s low':
      'The lowest price the stock reached yesterday. Falling below it is called a "breakdown" — sellers pushed past a recent floor.',
  'Open': 'The price at the start of today\'s trading session.',
};

// ═════════════════════════════════════════════════════════════
// MODEL
// ═════════════════════════════════════════════════════════════

class AlertModel {
  final int id;
  final String date;
  final String description;
  final String? symbol;
  final String? sentiment;
  final double? close;
  final double? prevClose;
  final double? pcnt;
  final double? high;
  final double? low;
  final double? week52High;
  final double? week52Low;
  final double? prevDayLow;
  final double? prevDayHigh;
  final double? volume;
  final double? sma5Volume;
  final double? open;
  final String createdAt;
  final String updatedAt;

  AlertModel({
    required this.id,
    required this.date,
    required this.description,
    this.symbol,
    this.sentiment,
    this.close,
    this.prevClose,
    this.pcnt,
    this.high,
    this.low,
    this.week52High,
    this.week52Low,
    this.prevDayLow,
    this.prevDayHigh,
    this.volume,
    this.sma5Volume,
    this.open,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) => AlertModel(
        id: json['id'] ?? 0,
        date: json['date'] ?? '',
        description: json['description'] ?? '',
        symbol: json['symbol'],
        sentiment: json['sentiment'],
        close: (json['close'] as num?)?.toDouble(),
        prevClose: (json['prev_close'] as num?)?.toDouble(),
        pcnt: (json['pcnt'] as num?)?.toDouble(),
        high: (json['high'] as num?)?.toDouble(),
        low: (json['low'] as num?)?.toDouble(),
        week52High: (json['52_week_high'] as num?)?.toDouble(),
        week52Low: (json['52_week_low'] as num?)?.toDouble(),
        prevDayLow: (json['prev_day_low'] as num?)?.toDouble(),
        prevDayHigh: (json['prev_day_high'] as num?)?.toDouble(),
        volume: (json['volume'] as num?)?.toDouble(),
        sma5Volume: (json['sma_5_volume'] as num?)?.toDouble(),
        open: (json['open'] as num?)?.toDouble(),
        createdAt: json['created_at'] ?? '',
        updatedAt: json['updated_at'] ?? '',
      );

  bool get isBullish => sentiment?.toLowerCase() == 'bullish';
  bool get isBearish => sentiment?.toLowerCase() == 'bearish';

  DateTime? get createdLocal => DateTime.tryParse(createdAt)?.toLocal();

  /// % change vs previous close (uses stored value, else computes it)
  double? get change {
    if (pcnt != null) return pcnt;
    if (close != null && prevClose != null && prevClose != 0) {
      return (close! - prevClose!) / prevClose! * 100;
    }
    return null;
  }

  double? get volumeRatio {
    if (volume == null || sma5Volume == null || sma5Volume == 0) return null;
    return volume! / sma5Volume!;
  }
}

// ═════════════════════════════════════════════════════════════
// HELPERS
// ═════════════════════════════════════════════════════════════

const int pageSize = 20;

enum SentimentFilter { all, bullish, bearish }

final NumberFormat _price =
    NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

String _fmtPrice(double? v) => v == null ? '—' : _price.format(v);

String _compact(double? v) {
  if (v == null) return '—';
  if (v >= 1e7) return '${(v / 1e7).toStringAsFixed(2)} Cr';
  if (v >= 1e5) return '${(v / 1e5).toStringAsFixed(2)} L';
  if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)} K';
  return v.toStringAsFixed(0);
}

String _cleanSym(dynamic raw) => (raw ?? '')
    .toString()
    .replaceAll('NSE:', '')
    .replaceAll('-EQ', '')
    .replaceAll('-BE', '')
    .replaceAll('-BZ', '')
    .trim();

String _ago(DateTime? d) {
  if (d == null) return '';
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24 && DateTime.now().day == d.day) {
    return DateFormat('h:mm a').format(d);
  }
  return DateFormat('h:mm a').format(d);
}

String _dayLabel(DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  return DateFormat('EEE, d MMM yyyy').format(d);
}

void _explain(BuildContext context, String term) {
  final p = _P.of(context);
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: p.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: p.line),
      ),
      title: Text(term,
          style: TextStyle(
              fontSize: 17, fontWeight: FontWeight.w700, color: p.ink)),
      content: Text(_glossary[term] ?? '',
          style: TextStyle(fontSize: 14, height: 1.5, color: p.inkSoft)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text('Got it',
              style: TextStyle(color: p.ink, fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
}

void _showGuide(BuildContext context) {
  final p = _P.of(context);
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: p.card,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      builder: (_, sc) => ListView(
        controller: sc,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: p.line, borderRadius: BorderRadius.circular(4)),
            ),
          ),
          const SizedBox(height: 18),
          Text('How to read these alerts',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: p.ink)),
          const SizedBox(height: 6),
          Text(
            'Our scanner watches the market all day and posts an alert when a stock does something worth noticing. Here is what the words mean.',
            style: TextStyle(fontSize: 14, height: 1.5, color: p.inkSoft),
          ),
          const SizedBox(height: 18),
          ..._glossary.entries.map(
            (e) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: p.cardAlt,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.key,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: p.ink)),
                  const SizedBox(height: 4),
                  Text(e.value,
                      style: TextStyle(
                          fontSize: 13, height: 1.45, color: p.inkSoft)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Alerts are automatic signals meant for learning and research. They are not investment advice.',
            style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: p.inkFaint,
                fontStyle: FontStyle.italic),
          ),
        ],
      ),
    ),
  );
}

// ═════════════════════════════════════════════════════════════
// PAGE
// ═════════════════════════════════════════════════════════════

class StockAlertsPage extends StatefulWidget {
  final String? stockname;
  const StockAlertsPage(this.stockname, {Key? key}) : super(key: key);

  @override
  _StockAlertsPageState createState() => _StockAlertsPageState();
}

class _StockAlertsPageState extends State<StockAlertsPage>
    with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  late meili.MeiliSearchClient _meili;

  final ScrollController _scroll = ScrollController();
  late AnimationController _shimmer;

  List<AlertModel> _alerts = [];
  bool _isLoading = true;
  String? _error;
  int _page = 1;
  int _total = 0;

  String _selectedStock = 'all';
  String _displayStockName = '';
  DateTime? _selectedDate;
  SentimentFilter _filter = SentimentFilter.all;

  RealtimeChannel? _channel;
  Timer? _rtDebounce;
  bool _showIntro = true;

  _P get p => _P.of(context);

  // ── lifecycle ──

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();

    _meili = meili.MeiliSearchClient(
      dotenv.env['MELIESEARCH_URL']!,
      dotenv.env['MELIE_API_KEY']!,
    );

    final s = widget.stockname;
    if (s != null && s.isNotEmpty && s != 'all') {
      _selectedStock = s;
      _displayStockName = totalStocks.containsKey(s)
          ? (totalStocks[s]?['full_stock_name'] ?? s)
          : s;
    }

    _fetchAlerts();
    _subscribe();
  }

  @override
  void dispose() {
    _rtDebounce?.cancel();
    _shimmer.dispose();
    _scroll.dispose();
    _channel?.unsubscribe();
    super.dispose();
  }

  // ── data ──

  PostgrestFilterBuilder<PostgrestList> _apply(
      PostgrestFilterBuilder<PostgrestList> q) {
    if (_filter == SentimentFilter.bullish) q = q.eq('sentiment', 'bullish');
    if (_filter == SentimentFilter.bearish) q = q.eq('sentiment', 'bearish');
    if (_selectedStock != 'all') q = q.eq('symbol', _selectedStock);
    if (_selectedDate != null) {
      final s = DateTime(
          _selectedDate!.year, _selectedDate!.month, _selectedDate!.day);
      final e = s
          .add(const Duration(days: 1))
          .subtract(const Duration(milliseconds: 1));
      q = q
          .gte('created_at', s.toIso8601String())
          .lte('created_at', e.toIso8601String());
    }
    return q;
  }

  Future<void> _fetchAlerts({bool silent = false}) async {
    if (!mounted) return;
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final from = (_page - 1) * pageSize;
      final to = from + pageSize - 1;
      var q = supabase.from('live_scanner').select();
      q = _apply(q);
      final response =
          await q.order('created_at', ascending: false).range(from, to);
      var cq = supabase.from('live_scanner').select('id');
      cq = _apply(cq);
      final count = (await cq).length;
      final data =
          (response as List).map((e) => AlertModel.fromJson(e)).toList();
      if (!mounted) return;
      setState(() {
        _alerts = data;
        _total = count;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _subscribe() {
    _channel?.unsubscribe();
    final ch = supabase.channel('live_scanner_v3');
    PostgresChangeFilter? f;
    if (_selectedStock != 'all') {
      f = PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'symbol',
          value: _selectedStock);
    } else if (_filter != SentimentFilter.all) {
      f = PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'sentiment',
        value: _filter == SentimentFilter.bullish ? 'bullish' : 'bearish',
      );
    }
    ch
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'live_scanner',
          filter: f,
          callback: (_) {
            // Batch bursts of updates & refresh quietly (no skeleton flicker)
            _rtDebounce?.cancel();
            _rtDebounce = Timer(const Duration(milliseconds: 600), () {
              if (mounted) _fetchAlerts(silent: true);
            });
          },
        )
        .subscribe();
    _channel = ch;
  }

  void _reload() {
    _page = 1;
    _fetchAlerts();
    _subscribe();
  }

  // ── handlers ──

  void _setFilter(SentimentFilter f) {
    HapticFeedback.selectionClick();
    setState(() => _filter = f);
    _reload();
  }

  void _pickStock(String sym, String name) {
    setState(() {
      _selectedStock = sym;
      _displayStockName = name;
    });
    _reload();
  }

  void _clearStock() {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedStock = 'all';
      _displayStockName = '';
    });
    _reload();
  }

  void _setDate(DateTime? d) {
    HapticFeedback.selectionClick();
    setState(() => _selectedDate = d);
    _reload();
  }

  Future<void> _openDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Show alerts from this day',
    );
    if (picked != null) _setDate(picked);
  }

  void _openSearch() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: p.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _StockSearchSheet(
        client: _meili,
        selected: _selectedStock,
        onSelect: (sym, name) {
          Navigator.pop(context);
          _pickStock(sym, name);
        },
        onShowAll: () {
          Navigator.pop(context);
          if (_selectedStock != 'all') _clearStock();
        },
      ),
    );
  }

  void _goToPage(int page) {
    HapticFeedback.selectionClick();
    setState(() => _page = page);
    _scroll.animateTo(0,
        duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
    _fetchAlerts();
  }

  bool get _isToday {
    final d = _selectedDate;
    if (d == null) return false;
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }

  // ── build ──

  @override
  Widget build(BuildContext context) {
    final t = p;
    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: t.ink,
          backgroundColor: t.card,
          onRefresh: () => _fetchAlerts(silent: true),
          child: CustomScrollView(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            slivers: [
              SliverToBoxAdapter(child: _header(t)),
              SliverPersistentHeader(
                pinned: true,
                delegate: _PinnedHeader(
                  height: 112,
                  color: t.bg,
                  line: t.line,
                  child: _filterBar(t),
                ),
              ),
              SliverToBoxAdapter(child: _helperLine(t)),
              ..._body(t),
            ],
          ),
        ),
      ),
    );
  }

  // ── header ──

  Widget _header(_P t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _RoundBtn(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.pop(context),
                t: t,
              ),
              const Spacer(),
              _RoundBtn(
                icon: Icons.help_outline_rounded,
                onTap: () => _showGuide(context),
                t: t,
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => Navigator.of(context).pushNamed('/alerts'),
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: t.ink,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(children: [
                    Icon(Icons.add_rounded, size: 18, color: t.onInk),
                    const SizedBox(width: 4),
                    Text('New alert',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: t.onInk)),
                  ]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Flexible(
                child: Text(
                  _selectedStock == 'all' ? 'Market alerts' : _displayStockName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                    color: t.ink,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const _LivePill(),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _selectedStock == 'all'
                ? 'Stocks that just made a notable move, updated live.'
                : 'Every notable move we spotted for ${_selectedStock}.',
            style: TextStyle(fontSize: 14, color: t.inkSoft, height: 1.4),
          ),
          if (_showIntro) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
              decoration: BoxDecoration(
                color: t.amberSoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline_rounded,
                      size: 20, color: t.amber),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('New to this?',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: t.amber)),
                        const SizedBox(height: 2),
                        Text(
                          'Tap any card to see the details in simple words. Tap the ? button for a mini dictionary.',
                          style: TextStyle(
                              fontSize: 12.5, height: 1.45, color: t.ink),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => setState(() => _showIntro = false),
                    icon: Icon(Icons.close_rounded, size: 18, color: t.amber),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── pinned filters ──

  Widget _filterBar(_P t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Column(
        children: [
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: [
                _FilterPill(
                  icon: Icons.search_rounded,
                  label:
                      _selectedStock == 'all' ? 'All stocks' : _selectedStock,
                  active: _selectedStock != 'all',
                  onTap: _openSearch,
                  onClear: _selectedStock != 'all' ? _clearStock : null,
                  t: t,
                ),
                const SizedBox(width: 8),
                _FilterPill(
                  icon: Icons.today_rounded,
                  label: 'Today',
                  active: _isToday,
                  onTap: () => _setDate(_isToday ? null : DateTime.now()),
                  t: t,
                ),
                const SizedBox(width: 8),
                _FilterPill(
                  icon: Icons.calendar_month_rounded,
                  label: (_selectedDate != null && !_isToday)
                      ? DateFormat('d MMM yyyy').format(_selectedDate!)
                      : 'Pick a date',
                  active: _selectedDate != null && !_isToday,
                  onTap: _openDatePicker,
                  onClear: (_selectedDate != null && !_isToday)
                      ? () => _setDate(null)
                      : null,
                  t: t,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _Segmented(
            t: t,
            value: _filter,
            onChanged: _setFilter,
          ),
        ],
      ),
    );
  }

  Widget _helperLine(_P t) {
    final text = switch (_filter) {
      SentimentFilter.all =>
        'Showing everything — both rising and falling stocks.',
      SentimentFilter.bullish =>
        'Rising stocks: buyers are stepping in (called “bullish”).',
      SentimentFilter.bearish =>
        'Falling stocks: sellers are stepping in (called “bearish”).',
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Text(text,
            key: ValueKey(_filter),
            style: TextStyle(fontSize: 12.5, color: t.inkFaint, height: 1.4)),
      ),
    );
  }

  // ── body ──

  List<Widget> _body(_P t) {
    if (_isLoading) {
      return [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _Skeleton(anim: _shimmer, t: t),
              childCount: 5,
            ),
          ),
        ),
      ];
    }
    if (_error != null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _Message(
            t: t,
            icon: Icons.wifi_off_rounded,
            title: 'Couldn\'t load alerts',
            body: 'Check your internet connection and try again.\n\n$_error',
            action: 'Try again',
            onAction: _fetchAlerts,
          ),
        ),
      ];
    }
    if (_alerts.isEmpty) {
      final filtered = _selectedStock != 'all' ||
          _selectedDate != null ||
          _filter != SentimentFilter.all;
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _Message(
            t: t,
            icon: Icons.notifications_none_rounded,
            title: 'Nothing here yet',
            body: filtered
                ? 'No alerts match these filters. Try removing one.'
                : 'Alerts appear when the market is open and a stock makes a notable move.',
            action: filtered ? 'Clear filters' : null,
            onAction: filtered
                ? () {
                    setState(() {
                      _selectedStock = 'all';
                      _displayStockName = '';
                      _selectedDate = null;
                      _filter = SentimentFilter.all;
                    });
                    _reload();
                  }
                : null,
          ),
        ),
      ];
    }

    // Build list with day headers
    final items = <Object>[];
    String? lastKey;
    for (final a in _alerts) {
      final d = a.createdLocal;
      final key = d == null ? '' : '${d.year}-${d.month}-${d.day}';
      if (key != lastKey && d != null) {
        items.add(_dayLabel(d));
        lastKey = key;
      }
      items.add(a);
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        sliver: SliverList.builder(
          itemCount: items.length,
          itemBuilder: (_, i) {
            final it = items[i];
            if (it is String) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(4, 14, 0, 8),
                child: Text(it.toUpperCase(),
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: t.inkFaint)),
              );
            }
            return _AlertCard(alert: it as AlertModel, t: t);
          },
        ),
      ),
      SliverToBoxAdapter(
        child: _Pager(
          t: t,
          page: _page,
          total: _total,
          onPage: _goToPage,
        ),
      ),
    ];
  }
}

// ═════════════════════════════════════════════════════════════
// ALERT CARD
// ═════════════════════════════════════════════════════════════

class _Signal {
  final String label;
  final IconData icon;
  final bool positive;
  const _Signal(this.label, this.icon, this.positive);
}

class _AlertCard extends StatefulWidget {
  final AlertModel alert;
  final _P t;
  const _AlertCard({required this.alert, required this.t});

  @override
  State<_AlertCard> createState() => _AlertCardState();
}

class _AlertCardState extends State<_AlertCard> {
  bool _open = false;

  List<_Signal> _signals(AlertModel a) {
    final s = <_Signal>[];
    if (a.close != null && a.prevDayHigh != null && a.close! > a.prevDayHigh!) {
      s.add(const _Signal(
          'Above yesterday\'s high', Icons.north_east_rounded, true));
    }
    if (a.close != null && a.prevDayLow != null && a.close! < a.prevDayLow!) {
      s.add(const _Signal(
          'Below yesterday\'s low', Icons.south_east_rounded, false));
    }
    if (a.close != null &&
        a.week52High != null &&
        a.week52High! > 0 &&
        a.close! >= a.week52High! * 0.98) {
      s.add(const _Signal(
          'Near 52-week high', Icons.emoji_events_outlined, true));
    }
    if (a.close != null &&
        a.week52Low != null &&
        a.week52Low! > 0 &&
        a.close! <= a.week52Low! * 1.02) {
      s.add(const _Signal(
          'Near 52-week low', Icons.warning_amber_rounded, false));
    }
    final r = a.volumeRatio;
    if (r != null && r >= 1.5) {
      s.add(_Signal('${r.toStringAsFixed(1)}× normal trading',
          Icons.bar_chart_rounded, a.isBullish));
    }
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    final a = widget.alert;
    final up = a.isBullish;
    final down = a.isBearish;
    final tone = up ? t.up : (down ? t.down : t.inkSoft);
    final toneSoft = up ? t.upSoft : (down ? t.downSoft : t.cardAlt);
    final sym = _cleanSym(a.symbol);
    final name = totalStocks.containsKey(a.symbol)
        ? (totalStocks[a.symbol]?['full_stock_name'] ?? sym)
        : sym;
    final chg = a.change;
    final chgUp = (chg ?? 0) >= 0;
    final signals = _signals(a);

    final headline = up
        ? 'Buyers are in control'
        : down
            ? 'Sellers are in control'
            : 'Market update';

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _open = !_open);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: t.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1 — sentiment + time
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: toneSoft,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(
                        up
                            ? Icons.trending_up_rounded
                            : down
                                ? Icons.trending_down_rounded
                                : Icons.remove_rounded,
                        size: 14,
                        color: tone),
                    const SizedBox(width: 5),
                    Text(headline,
                        style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: tone)),
                  ]),
                ),
                const Spacer(),
                Text(_ago(a.createdLocal),
                    style: TextStyle(fontSize: 12, color: t.inkFaint)),
              ],
            ),
            const SizedBox(height: 14),

            // Row 2 — name + price
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name.toString(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              color: t.ink,
                              height: 1.2)),
                      const SizedBox(height: 3),
                      Text(sym,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.6,
                              color: t.inkFaint)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_fmtPrice(a.close),
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: t.ink,
                            fontFeatures: const [
                              FontFeature.tabularFigures()
                            ])),
                    const SizedBox(height: 3),
                    if (chg != null)
                      Text(
                        '${chgUp ? '▲' : '▼'} ${chg.abs().toStringAsFixed(2)}%',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: chgUp ? t.up : t.down,
                            fontFeatures: const [FontFeature.tabularFigures()]),
                      ),
                  ],
                ),
              ],
            ),

            // Plain-English change sentence
            if (chg != null && a.prevClose != null) ...[
              const SizedBox(height: 8),
              Text(
                '${chgUp ? 'Up' : 'Down'} ${chg.abs().toStringAsFixed(2)}% from yesterday\'s closing price of ${_fmtPrice(a.prevClose)}.',
                style: TextStyle(fontSize: 12.5, height: 1.4, color: t.inkSoft),
              ),
            ],

            // Trigger description
            if (a.description.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: t.cardAlt,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('WHY WE ALERTED',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                            color: t.inkFaint)),
                    const SizedBox(height: 4),
                    Text(a.description,
                        style: TextStyle(
                            fontSize: 13.5, height: 1.45, color: t.ink)),
                  ],
                ),
              ),
            ],

            // Signals
            if (signals.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: signals
                    .map((s) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            border: Border.all(color: t.line),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(s.icon,
                                size: 13, color: s.positive ? t.up : t.down),
                            const SizedBox(width: 5),
                            Text(s.label,
                                style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: t.ink)),
                          ]),
                        ))
                    .toList(),
              ),
            ],

            // Expand hint
            const SizedBox(height: 12),
            Row(
              children: [
                Text(_open ? 'Hide details' : 'See details in simple terms',
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: t.inkSoft)),
                const SizedBox(width: 2),
                AnimatedRotation(
                  turns: _open ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.keyboard_arrow_down_rounded,
                      size: 18, color: t.inkSoft),
                ),
              ],
            ),

            // Details
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 220),
              crossFadeState:
                  _open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              firstChild: const SizedBox(width: double.infinity),
              secondChild: _details(a, t, tone),
            ),
          ],
        ),
      ),
    );
  }

  Widget _details(AlertModel a, _P t, Color tone) {
    final ratio = a.volumeRatio;
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: t.line, height: 1),
          const SizedBox(height: 14),
          if (a.low != null && a.high != null && a.close != null)
            _RangeBar(
              t: t,
              title: 'Day range',
              low: a.low!,
              high: a.high!,
              value: a.close!,
              color: tone,
              caption:
                  'Where today\'s price sits between the day\'s low and high.',
            ),
          if (a.week52Low != null &&
              a.week52High != null &&
              a.close != null) ...[
            const SizedBox(height: 16),
            _RangeBar(
              t: t,
              title: '52-week range',
              low: a.week52Low!,
              high: a.week52High!,
              value: a.close!,
              color: tone,
              caption: 'Where the price sits compared with the past year.',
            ),
          ],
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.3,
            children: [
              _Stat(t: t, term: 'Open', value: _fmtPrice(a.open)),
              _Stat(
                  t: t, term: 'Previous close', value: _fmtPrice(a.prevClose)),
              _Stat(
                  t: t,
                  term: 'Yesterday\'s high',
                  value: _fmtPrice(a.prevDayHigh)),
              _Stat(
                  t: t,
                  term: 'Yesterday\'s low',
                  value: _fmtPrice(a.prevDayLow)),
              _Stat(t: t, term: 'Volume', value: _compact(a.volume)),
              _Stat(
                t: t,
                term: 'Volume vs normal',
                value:
                    ratio == null ? '—' : '${ratio.toStringAsFixed(1)}× usual',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: t.cardAlt,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: t.inkSoft),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    a.isBullish
                        ? 'In short: more people are buying than selling right now, pushing the price up. Momentum can fade, so treat this as a clue, not a promise.'
                        : a.isBearish
                            ? 'In short: more people are selling than buying right now, pushing the price down. Momentum can reverse, so treat this as a clue, not a promise.'
                            : 'This is an automatic market update for this stock.',
                    style: TextStyle(
                        fontSize: 12.5, height: 1.45, color: t.inkSoft),
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

class _Stat extends StatelessWidget {
  final _P t;
  final String term;
  final String value;
  const _Stat({required this.t, required this.term, required this.value});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _explain(context, term),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: t.line),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(children: [
              Flexible(
                child: Text(term,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: t.inkFaint)),
              ),
              const SizedBox(width: 4),
              Icon(Icons.help_outline_rounded, size: 11, color: t.inkFaint),
            ]),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: t.ink,
                    fontFeatures: const [FontFeature.tabularFigures()])),
          ],
        ),
      ),
    );
  }
}

class _RangeBar extends StatelessWidget {
  final _P t;
  final String title;
  final double low, high, value;
  final Color color;
  final String caption;
  const _RangeBar({
    required this.t,
    required this.title,
    required this.low,
    required this.high,
    required this.value,
    required this.color,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    final span = high - low;
    final pos = span <= 0 ? 0.5 : ((value - low) / span).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _explain(context, title),
          child: Row(children: [
            Text(title,
                style: TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w700, color: t.ink)),
            const SizedBox(width: 4),
            Icon(Icons.help_outline_rounded, size: 12, color: t.inkFaint),
          ]),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(builder: (_, c) {
          final w = c.maxWidth;
          return SizedBox(
            height: 14,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: t.cardAlt,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                Container(
                  height: 6,
                  width: w * pos,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                Positioned(
                  left: (w - 14) * pos,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: t.card, width: 2.5),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Low ${_fmtPrice(low)}',
                style: TextStyle(fontSize: 11, color: t.inkSoft)),
            Text('High ${_fmtPrice(high)}',
                style: TextStyle(fontSize: 11, color: t.inkSoft)),
          ],
        ),
        const SizedBox(height: 2),
        Text(caption, style: TextStyle(fontSize: 11, color: t.inkFaint)),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════
// STOCK SEARCH SHEET
// ═════════════════════════════════════════════════════════════

class _StockSearchSheet extends StatefulWidget {
  final meili.MeiliSearchClient client;
  final String selected;
  final void Function(String sym, String name) onSelect;
  final VoidCallback onShowAll;
  const _StockSearchSheet({
    required this.client,
    required this.selected,
    required this.onSelect,
    required this.onShowAll,
  });

  @override
  State<_StockSearchSheet> createState() => _StockSearchSheetState();
}

class _StockSearchSheetState extends State<_StockSearchSheet> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  Timer? _deb;
  List<Map<String, dynamic>> _hits = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _run('');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _deb?.cancel();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String q) {
    _deb?.cancel();
    _deb = Timer(const Duration(milliseconds: 250), () => _run(q));
  }

  Future<void> _run(String query) async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final res = await widget.client.index('stocks').search(
            query,
            meili.SearchQuery(
              hitsPerPage: query.isEmpty ? 20 : 35,
              filter: 'type = "stock"',
            ),
          );
      var hits = res.hits.cast<Map<String, dynamic>>();
      if (query.isNotEmpty) {
        final q = query.toLowerCase();
        hits.sort((a, b) {
          final aS = _cleanSym(a['symbol']).toLowerCase();
          final bS = _cleanSym(b['symbol']).toLowerCase();
          if (aS == q && bS != q) return -1;
          if (bS == q && aS != q) return 1;
          if (aS.startsWith(q) && !bS.startsWith(q)) return -1;
          if (bS.startsWith(q) && !aS.startsWith(q)) return 1;
          return 0;
        });
      }
      if (mounted)
        setState(() {
          _hits = hits;
          _loading = false;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _hits = [];
          _loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _P.of(context);
    final kb = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: kb),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.82,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: t.line, borderRadius: BorderRadius.circular(4)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Choose a stock',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: t.ink)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                    'Search by company name or its short code (e.g. TCS).',
                    style: TextStyle(fontSize: 13, color: t.inkSoft)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: t.cardAlt,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(children: [
                  Icon(Icons.search_rounded, size: 20, color: t.inkSoft),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      focusNode: _focus,
                      onChanged: _onChanged,
                      style: TextStyle(fontSize: 15, color: t.ink),
                      cursorColor: t.ink,
                      decoration: InputDecoration(
                        hintText: 'Search stocks…',
                        hintStyle: TextStyle(color: t.inkFaint),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  if (_ctrl.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _ctrl.clear();
                        _run('');
                        setState(() {});
                      },
                      child: Icon(Icons.cancel_rounded,
                          size: 18, color: t.inkFaint),
                    ),
                ]),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: t.ink),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 24),
                      children: [
                        if (_ctrl.text.isEmpty)
                          ListTile(
                            leading: Container(
                              width: 44,
                              height: 36,
                              decoration: BoxDecoration(
                                color: t.ink,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.apps_rounded,
                                  size: 18, color: t.onInk),
                            ),
                            title: Text('All stocks',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700, color: t.ink)),
                            subtitle: Text('Show alerts for every stock',
                                style:
                                    TextStyle(fontSize: 12, color: t.inkSoft)),
                            trailing: widget.selected == 'all'
                                ? Icon(Icons.check_rounded, color: t.up)
                                : null,
                            onTap: widget.onShowAll,
                          ),
                        if (_hits.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(children: [
                              Icon(Icons.search_off_rounded,
                                  size: 32, color: t.inkFaint),
                              const SizedBox(height: 8),
                              Text('No stocks found',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: t.ink)),
                              const SizedBox(height: 4),
                              Text('Check the spelling or try the short code.',
                                  style: TextStyle(
                                      fontSize: 13, color: t.inkSoft)),
                            ]),
                          ),
                        ..._hits.map((h) {
                          final sym = _cleanSym(h['symbol']);
                          final name = (h['name'] ?? sym).toString();
                          final pct = (h['percent_change'] as num?)?.toDouble();
                          final sel = sym == widget.selected;
                          return ListTile(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              widget.onSelect(sym, name);
                            },
                            leading: Container(
                              constraints: const BoxConstraints(minWidth: 44),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 8),
                              decoration: BoxDecoration(
                                color: t.cardAlt,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(sym,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: t.ink)),
                            ),
                            title: Text(name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: t.ink)),
                            trailing: sel
                                ? Icon(Icons.check_rounded, color: t.up)
                                : (pct == null
                                    ? null
                                    : Text(
                                        '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(2)}%',
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: pct >= 0 ? t.up : t.down))),
                          );
                        }),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// SMALL COMPONENTS
// ═════════════════════════════════════════════════════════════

class _PinnedHeader extends SliverPersistentHeaderDelegate {
  final double height;
  final Color color;
  final Color line;
  final Widget child;
  _PinnedHeader({
    required this.height,
    required this.color,
    required this.line,
    required this.child,
  });

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrink, bool overlaps) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        border: Border(
            bottom: BorderSide(
                color: overlaps ? line : Colors.transparent, width: 1)),
      ),
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedHeader old) => true;
}

class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final _P t;
  const _RoundBtn({required this.icon, required this.onTap, required this.t});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: t.card,
          shape: BoxShape.circle,
          border: Border.all(color: t.line),
        ),
        child: Icon(icon, size: 20, color: t.ink),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final _P t;
  const _FilterPill({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    required this.t,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.fromLTRB(12, 0, onClear != null ? 6 : 14, 0),
        decoration: BoxDecoration(
          color: active ? t.ink : t.card,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: active ? t.ink : t.line),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: active ? t.onInk : t.inkSoft),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: active ? t.onInk : t.ink)),
          if (onClear != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onClear,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.close_rounded, size: 16, color: t.onInk),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  final _P t;
  final SentimentFilter value;
  final ValueChanged<SentimentFilter> onChanged;
  const _Segmented(
      {required this.t, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget seg(SentimentFilter f, String label, IconData? icon, Color color) {
      final sel = value == f;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(f),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: sel ? t.card : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: sel ? t.line : Colors.transparent),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: sel ? color : t.inkFaint),
                  const SizedBox(width: 5),
                ],
                Text(label,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
                        color: sel ? t.ink : t.inkSoft)),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      height: 42,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: t.cardAlt,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(children: [
        seg(SentimentFilter.all, 'All', null, t.ink),
        seg(SentimentFilter.bullish, 'Rising', Icons.trending_up_rounded, t.up),
        seg(SentimentFilter.bearish, 'Falling', Icons.trending_down_rounded,
            t.down),
      ]),
    );
  }
}

class _LivePill extends StatefulWidget {
  const _LivePill();
  @override
  State<_LivePill> createState() => _LivePillState();
}

class _LivePillState extends State<_LivePill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _P.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: t.upSoft,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        FadeTransition(
          opacity: Tween(begin: 0.3, end: 1.0).animate(_c),
          child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: t.up, shape: BoxShape.circle)),
        ),
        const SizedBox(width: 5),
        Text('LIVE',
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: t.up)),
      ]),
    );
  }
}

class _Skeleton extends StatelessWidget {
  final AnimationController anim;
  final _P t;
  const _Skeleton({required this.anim, required this.t});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) {
        final v = (anim.value * 2 - 1).abs();
        final c = Color.lerp(t.cardAlt, t.line, v)!;
        Widget bone(double h, double? w) => Container(
              height: h,
              width: w,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                  color: c, borderRadius: BorderRadius.circular(8)),
            );
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: t.card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: t.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              bone(22, 130),
              const SizedBox(height: 4),
              bone(18, 220),
              bone(12, 90),
              bone(48, double.infinity),
            ],
          ),
        );
      },
    );
  }
}

class _Message extends StatelessWidget {
  final _P t;
  final IconData icon;
  final String title;
  final String body;
  final String? action;
  final VoidCallback? onAction;
  const _Message({
    required this.t,
    required this.icon,
    required this.title,
    required this.body,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration:
                  BoxDecoration(color: t.cardAlt, shape: BoxShape.circle),
              child: Icon(icon, size: 28, color: t.inkSoft),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: t.ink)),
            const SizedBox(height: 6),
            Text(body,
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontSize: 13.5, height: 1.5, color: t.inkSoft)),
            if (action != null) ...[
              const SizedBox(height: 18),
              GestureDetector(
                onTap: onAction,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                  decoration: BoxDecoration(
                    color: t.ink,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(action!,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: t.onInk)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Pager extends StatelessWidget {
  final _P t;
  final int page;
  final int total;
  final ValueChanged<int> onPage;
  const _Pager({
    required this.t,
    required this.page,
    required this.total,
    required this.onPage,
  });

  @override
  Widget build(BuildContext context) {
    final pages = (total / pageSize).ceil().clamp(1, 9999);
    final canPrev = page > 1;
    final canNext = page < pages;

    Widget btn(String label, IconData icon, bool enabled, VoidCallback f,
        {bool trailing = false}) {
      return Opacity(
        opacity: enabled ? 1 : 0.35,
        child: GestureDetector(
          onTap: enabled ? f : null,
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: t.card,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: t.line),
            ),
            child: Row(children: [
              if (!trailing) Icon(icon, size: 18, color: t.ink),
              if (!trailing) const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700, color: t.ink)),
              if (trailing) const SizedBox(width: 4),
              if (trailing) Icon(icon, size: 18, color: t.ink),
            ]),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              btn('Newer', Icons.chevron_left_rounded, canPrev,
                  () => onPage(page - 1)),
              Column(children: [
                Text('Page $page of $pages',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: t.ink)),
                Text('$total alerts',
                    style: TextStyle(fontSize: 11, color: t.inkFaint)),
              ]),
              btn('Older', Icons.chevron_right_rounded, canNext,
                  () => onPage(page + 1),
                  trailing: true),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            'Alerts are automatic signals for learning and research — not investment advice.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 11.5,
                height: 1.5,
                color: t.inkFaint,
                fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}
