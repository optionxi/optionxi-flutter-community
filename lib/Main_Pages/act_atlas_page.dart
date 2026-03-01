import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:optionxi/Dialogs/custom_atlas_detaildialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

// ─────────────────────────────────────────────────────────────────────────────
// Design Tokens
// ─────────────────────────────────────────────────────────────────────────────
class _T {
  // Radii
  static const double rXS = 6.0;
  static const double rSM = 10.0;
  static const double rMD = 14.0;
  static const double rLG = 18.0;

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

  // Accent — warm indigo (comfortable on both modes)
  static const Color accent = Color(0xFF6366F1);
  static const Color accentDim = Color(0x1A6366F1);
  static const Color accentLight = Color(0xFFEEEEFF);

  // Bull — sapphire blue (calm on white, bright on dark)
  static const Color bull = Color(0xFF3B82F6);
  static const Color bullDim = Color(0x153B82F6);
  static const Color bullDimL = Color(0xFFEFF4FF);

  // Bear — warm rose
  static const Color bear = Color(0xFFF43F5E);
  static const Color bearDim = Color(0x15F43F5E);
  static const Color bearDimL = Color(0xFFFFF0F3);

  // Neutral — muted teal
  static const Color neutral = Color(0xFF14B8A6);
  static const Color neutralDim = Color(0x1514B8A6);
  static const Color neutralDimL = Color(0xFFEEFBF9);

  // Probability colour bands (numeric only, not background sentiment)
  static const Color probHigh = Color(0xFF10B981);
  static const Color probMid = Color(0xFFEAB308);
  static const Color probLow = Color(0xFFF43F5E);
}

// ─────────────────────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────────────────────
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────────────────────────────────────
class SupabaseService {
  final SupabaseClient _client;
  RealtimeChannel? _channel;

  SupabaseService(this._client);

  Future<Map<String, dynamic>> getAtlasOutputs({
    int page = 1,
    int pageSize = 10,
    DateTime? selectedDate,
    bool strongTrendOnly = false,
    bool firstEntryOnly = false,
  }) async {
    final from = (page - 1) * pageSize;
    final to = from + pageSize - 1;

    var q = _client.from('atlas_output').select();
    if (selectedDate != null) {
      final s =
          DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      final e = s
          .add(const Duration(days: 1))
          .subtract(const Duration(milliseconds: 1));
      q = q
          .gte('created_at', s.toIso8601String())
          .lte('created_at', e.toIso8601String());
    }
    if (strongTrendOnly) q = q.gt('probability', 50.0);
    if (firstEntryOnly) q = q.eq('entry', true);

    final resp = await q.order('created_at', ascending: false).range(from, to);
    final outputs = (resp as List).map((e) => AtlasOutput.fromJson(e)).toList();

    var cq = _client.from('atlas_output').select('id');
    if (selectedDate != null) {
      final s =
          DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      final e = s
          .add(const Duration(days: 1))
          .subtract(const Duration(milliseconds: 1));
      cq = cq
          .gte('created_at', s.toIso8601String())
          .lte('created_at', e.toIso8601String());
    }
    if (strongTrendOnly) cq = cq.gt('probability', 50.0);
    if (firstEntryOnly) cq = cq.eq('entry', true);

    final countResp = await cq;
    return {
      'data': outputs,
      'count': (countResp as List).length,
      'page': page,
      'pageSize': pageSize,
    };
  }

  StreamSubscription<dynamic> subscribeToAtlasOutputs(
    void Function(AtlasOutput) callback, {
    bool strongTrendOnly = false,
    DateTime? selectedDate,
  }) {
    _channel?.unsubscribe();
    final channel = _client.channel('atlas_output_changes');

    PostgresChangeFilter? filter;
    if (strongTrendOnly) {
      filter = PostgresChangeFilter(
        type: PostgresChangeFilterType.gt,
        column: 'probability',
        value: 50.0,
      );
    }

    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'atlas_output',
      filter: filter,
      callback: (payload) {
        if (payload.newRecord.isNotEmpty) {
          final out = AtlasOutput.fromJson(payload.newRecord);
          if (selectedDate != null) {
            final dt = DateTime.parse(out.createdAt);
            final s = DateTime(
                selectedDate.year, selectedDate.month, selectedDate.day);
            final e = s.add(const Duration(days: 1));
            if (dt.isAfter(s) && dt.isBefore(e)) callback(out);
          } else {
            callback(out);
          }
        }
      },
    );

    channel.subscribe((status, [error]) {
      if (status == RealtimeSubscribeStatus.subscribed) {
        debugPrint('subscribed atlas_output');
      }
    });

    _channel = channel;
    final ctrl = StreamController<dynamic>();
    final sub = ctrl.stream.listen((_) {});
    return _SubWrapper(sub, onCancel: () {
      channel.unsubscribe();
      ctrl.close();
    });
  }
}

class _SubWrapper implements StreamSubscription<dynamic> {
  final StreamSubscription<dynamic> _s;
  final VoidCallback onCancel;
  _SubWrapper(this._s, {required this.onCancel});

  @override
  Future<void> cancel() {
    onCancel();
    return _s.cancel();
  }

  @override
  Future<E> asFuture<E>([E? v]) => _s.asFuture(v);
  @override
  bool get isPaused => _s.isPaused;
  @override
  void onData(void Function(dynamic)? h) => _s.onData(h);
  @override
  void onDone(void Function()? h) => _s.onDone(h);
  @override
  void onError(Function? h) => _s.onError(h);
  @override
  void pause([Future<void>? r]) => _s.pause(r);
  @override
  void resume() => _s.resume();
}

// ─────────────────────────────────────────────────────────────────────────────
// Sentiment Style
// ─────────────────────────────────────────────────────────────────────────────
class _SStyle {
  final String label;
  final Color primary;
  final Color dimDark;
  final Color dimLight;
  final IconData icon;
  const _SStyle({
    required this.label,
    required this.primary,
    required this.dimDark,
    required this.dimLight,
    required this.icon,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────
class AtlasOutputPage extends StatefulWidget {
  const AtlasOutputPage({Key? key}) : super(key: key);

  @override
  State<AtlasOutputPage> createState() => _AtlasOutputPageState();
}

class _AtlasOutputPageState extends State<AtlasOutputPage>
    with SingleTickerProviderStateMixin {
  final _svc = SupabaseService(Supabase.instance.client);

  List<AtlasOutput> _outputs = [];
  bool _loading = true;
  String? _error;
  int _page = 1;
  int _totalPages = 1;
  DateTime? _selectedDate;
  bool _strongOnly = true;
  bool _firstEntry = false;
  TabController? _tab;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _fetch();
    _subscribe();
  }

  @override
  void dispose() {
    _tab?.dispose();
    _sub?.cancel();
    super.dispose();
  }

  void _subscribe() {
    _sub = _svc.subscribeToAtlasOutputs((out) {
      final dateOk = _selectedDate == null ||
          (DateTime.parse(out.createdAt).day == _selectedDate!.day &&
              DateTime.parse(out.createdAt).month == _selectedDate!.month &&
              DateTime.parse(out.createdAt).year == _selectedDate!.year);
      final trendOk = !_strongOnly || out.probability > 50;
      if (dateOk && trendOk && mounted) {
        setState(() => _outputs = [out, ..._outputs].take(10).toList());
      }
    });
  }

  Future<void> _fetch() async {
    if (mounted)
      setState(() {
        _loading = true;
        _error = null;
      });
    try {
      final r = await _svc.getAtlasOutputs(
        page: _page,
        pageSize: 10,
        selectedDate: _selectedDate,
        strongTrendOnly: _strongOnly,
        firstEntryOnly: _firstEntry,
      );
      if (mounted)
        setState(() {
          _outputs = r['data'];
          _totalPages = ((r['count'] as int) / 10).ceil().clamp(1, 99999);
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

  void _resetFilters() {
    setState(() {
      _selectedDate = null;
      _strongOnly = false;
      _firstEntry = false;
      _page = 1;
      _tab?.index = 0;
    });
    _fetch();
  }

  bool get _hasFilters => _selectedDate != null || _strongOnly || _firstEntry;

  _SStyle _styleFor(String type) {
    switch (type) {
      case 'Bull':
        return const _SStyle(
            label: 'Bullish',
            primary: _T.bull,
            dimDark: _T.bullDim,
            dimLight: _T.bullDimL,
            icon: Icons.arrow_upward_rounded);
      case 'Bear':
        return const _SStyle(
            label: 'Bearish',
            primary: _T.bear,
            dimDark: _T.bearDim,
            dimLight: _T.bearDimL,
            icon: Icons.arrow_downward_rounded);
      default:
        return const _SStyle(
            label: 'Neutral',
            primary: _T.neutral,
            dimDark: _T.neutralDim,
            dimLight: _T.neutralDimL,
            icon: Icons.remove_rounded);
    }
  }

  Color _probColor(double p) {
    if (p >= 65) return _T.probHigh;
    if (p >= 50) return _T.probMid;
    return _T.probLow;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: isDark ? _T.dBg : _T.lBg,
        body: SafeArea(
          child: Column(
            children: [
              // ── Only the tab bar is sticky ──────────────────────────
              _TopBar(
                tab: _tab!,
                isDark: isDark,
                outputs: _outputs,
              ),

              // ── Each tab scrolls independently ──────────────────────
              Expanded(
                child: TabBarView(
                  controller: _tab,
                  children: ['All', 'Bull', 'Bear']
                      .map((t) => _TabBody(
                            key: ValueKey(t),
                            tabType: t,
                            isDark: isDark,
                            loading: _loading,
                            error: _error,
                            outputs: _outputs,
                            page: _page,
                            totalPages: _totalPages,
                            hasFilters: _hasFilters,
                            selectedDate: _selectedDate,
                            strongOnly: _strongOnly,
                            firstEntry: _firstEntry,
                            styleFor: _styleFor,
                            probColor: _probColor,
                            onRetry: _fetch,
                            onReset: _resetFilters,
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
                            onDatePick: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                                builder: (ctx, child) => Theme(
                                  data: Theme.of(ctx).copyWith(
                                    colorScheme: Theme.of(ctx)
                                        .colorScheme
                                        .copyWith(primary: _T.accent),
                                  ),
                                  child: child!,
                                ),
                              );
                              if (picked != null && mounted) {
                                setState(() {
                                  _selectedDate = picked;
                                  _page = 1;
                                });
                                _fetch();
                              }
                            },
                            onDateClear: () {
                              setState(() {
                                _selectedDate = null;
                                _page = 1;
                              });
                              _fetch();
                            },
                            onStrongToggle: (v) {
                              setState(() {
                                _strongOnly = v;
                                _page = 1;
                              });
                              _fetch();
                            },
                            onFirstEntryToggle: (v) {
                              setState(() {
                                _firstEntry = v;
                                _page = 1;
                              });
                              _fetch();
                            },
                            onShowDetail: (out) => showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => AtlasDetailDialog(output: out),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top Bar — back button + title + tab pills (sticky)
// ─────────────────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final TabController tab;
  final bool isDark;
  final List<AtlasOutput> outputs;

  const _TopBar({
    required this.tab,
    required this.isDark,
    required this.outputs,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? _T.dSurface : _T.lSurface;
    final border = isDark ? _T.dBorder : _T.lBorder;
    final textP = isDark ? _T.dTextP : _T.lTextP;
    final textS = isDark ? _T.dTextS : _T.lTextS;

    final allC = outputs.length;
    final bullC = outputs.where((o) => o.type == 'Bull').length;
    final bearC = outputs.where((o) => o.type == 'Bear').length;

    return Container(
      color: isDark ? _T.dBg : _T.lBg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Back + title row
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 16, 6),
            child: Row(
              children: [
                // Back button
                _TapScale(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(_T.rSM),
                      border: Border.all(color: border),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 15,
                      color: textP,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Title + live dot
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Market Sentiments',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: textP,
                            letterSpacing: -0.3,
                          )),
                      Row(
                        children: [
                          _LiveDot(),
                          const SizedBox(width: 5),
                          Text('Live · Atlas Engine',
                              style: TextStyle(fontSize: 11, color: textS)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tab pill bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(_T.rMD),
                border: Border.all(color: border),
              ),
              child: TabBar(
                controller: tab,
                indicator: BoxDecoration(
                  color: _T.accent,
                  borderRadius: BorderRadius.circular(_T.rSM),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: textS,
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                unselectedLabelStyle:
                    const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                tabs: [
                  Tab(text: 'All  $allC'),
                  Tab(text: '↑ Bull  $bullC'),
                  Tab(text: '↓ Bear  $bearC'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated live dot
// ─────────────────────────────────────────────────────────────────────────────
class _LiveDot extends StatefulWidget {
  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Container(
          width: 5,
          height: 5,
          decoration: const BoxDecoration(
            color: _T.probHigh,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab Body — scrollable (filters + cards + pagination)
// ─────────────────────────────────────────────────────────────────────────────
class _TabBody extends StatelessWidget {
  final String tabType;
  final bool isDark;
  final bool loading;
  final String? error;
  final List<AtlasOutput> outputs;
  final int page;
  final int totalPages;
  final bool hasFilters;
  final DateTime? selectedDate;
  final bool strongOnly;
  final bool firstEntry;
  final _SStyle Function(String) styleFor;
  final Color Function(double) probColor;
  final VoidCallback onRetry;
  final VoidCallback onReset;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final VoidCallback onDatePick;
  final VoidCallback onDateClear;
  final ValueChanged<bool> onStrongToggle;
  final ValueChanged<bool> onFirstEntryToggle;
  final void Function(AtlasOutput) onShowDetail;

  const _TabBody({
    Key? key,
    required this.tabType,
    required this.isDark,
    required this.loading,
    required this.error,
    required this.outputs,
    required this.page,
    required this.totalPages,
    required this.hasFilters,
    required this.selectedDate,
    required this.strongOnly,
    required this.firstEntry,
    required this.styleFor,
    required this.probColor,
    required this.onRetry,
    required this.onReset,
    required this.onPrev,
    required this.onNext,
    required this.onDatePick,
    required this.onDateClear,
    required this.onStrongToggle,
    required this.onFirstEntryToggle,
    required this.onShowDetail,
  }) : super(key: key);

  List<AtlasOutput> get _filtered =>
      outputs.where((o) => tabType == 'All' || o.type == tabType).toList();

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: 5,
        itemBuilder: (_, __) => _SkeletonCard(isDark: isDark),
      );
    }
    if (error != null) return _buildError(context);

    final items = _filtered;

    return CustomScrollView(
      slivers: [
        // Filters scroll with content
        SliverToBoxAdapter(
          child: _FilterSection(
            isDark: isDark,
            selectedDate: selectedDate,
            strongOnly: strongOnly,
            firstEntry: firstEntry,
            hasFilters: hasFilters,
            onDatePick: onDatePick,
            onDateClear: onDateClear,
            onStrongToggle: onStrongToggle,
            onFirstEntryToggle: onFirstEntryToggle,
            onReset: onReset,
          ),
        ),

        if (items.isEmpty)
          SliverFillRemaining(child: _buildEmpty(context))
        else ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _SignalCard(
                  key: ValueKey(items[i].id),
                  output: items[i],
                  style: styleFor(items[i].type),
                  isDark: isDark,
                  index: i,
                  probColor: probColor,
                  onTap: () => onShowDetail(items[i]),
                ),
                childCount: items.length,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _Pagination(
              isDark: isDark,
              page: page,
              totalPages: totalPages,
              resultCount: outputs.length,
              onPrev: onPrev,
              onNext: onNext,
            ),
          ),
        ],

        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }

  Widget _buildError(BuildContext context) {
    final textP = isDark ? _T.dTextP : _T.lTextP;
    final textS = isDark ? _T.dTextS : _T.lTextS;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 44, color: _T.bear),
            const SizedBox(height: 16),
            Text('Connection error',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: textP)),
            const SizedBox(height: 6),
            Text(error!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: textS)),
            const SizedBox(height: 20),
            _TapScale(
              onTap: onRetry,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
                decoration: BoxDecoration(
                    color: _T.accent,
                    borderRadius: BorderRadius.circular(_T.rMD)),
                child: const Text('Retry',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final textP = isDark ? _T.dTextP : _T.lTextP;
    final textS = isDark ? _T.dTextS : _T.lTextS;
    final surface = isDark ? _T.dSurface : _T.lSurface;
    final border = isDark ? _T.dBorder : _T.lBorder;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: surface,
                shape: BoxShape.circle,
                border: Border.all(color: border),
              ),
              child: Icon(Icons.inbox_rounded, size: 28, color: textS),
            ),
            const SizedBox(height: 18),
            Text('No signals found',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: textP)),
            const SizedBox(height: 6),
            Text('Adjust your filters or select a different date.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: textS)),
            if (hasFilters) ...[
              const SizedBox(height: 22),
              _TapScale(
                onTap: onReset,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                      color: _T.accent,
                      borderRadius: BorderRadius.circular(_T.rMD)),
                  child: const Text('Clear Filters',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter Section (scrolls with content)
// ─────────────────────────────────────────────────────────────────────────────
class _FilterSection extends StatelessWidget {
  final bool isDark;
  final DateTime? selectedDate;
  final bool strongOnly;
  final bool firstEntry;
  final bool hasFilters;
  final VoidCallback onDatePick;
  final VoidCallback onDateClear;
  final ValueChanged<bool> onStrongToggle;
  final ValueChanged<bool> onFirstEntryToggle;
  final VoidCallback onReset;

  const _FilterSection({
    required this.isDark,
    required this.selectedDate,
    required this.strongOnly,
    required this.firstEntry,
    required this.hasFilters,
    required this.onDatePick,
    required this.onDateClear,
    required this.onStrongToggle,
    required this.onFirstEntryToggle,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? _T.dSurface : _T.lSurface;
    final border = isDark ? _T.dBorder : _T.lBorder;
    final textS = isDark ? _T.dTextS : _T.lTextS;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Column(
        children: [
          // Date filter row
          Row(
            children: [
              Expanded(
                child: _TapScale(
                  onTap: onDatePick,
                  child: _FilterPill(
                    isDark: isDark,
                    isActive: selectedDate != null,
                    icon: Icons.calendar_today_rounded,
                    label: selectedDate != null
                        ? DateFormat('MMM d, yyyy').format(selectedDate!)
                        : 'Filter by date',
                    trailing: selectedDate != null
                        ? GestureDetector(
                            onTap: onDateClear,
                            child: Icon(Icons.close_rounded,
                                size: 14, color: textS),
                          )
                        : Icon(Icons.expand_more_rounded,
                            size: 16, color: textS),
                  ),
                ),
              ),
              if (hasFilters) ...[
                const SizedBox(width: 8),
                _TapScale(
                  onTap: onReset,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(_T.rSM),
                      border: Border.all(color: border),
                    ),
                    child: Icon(Icons.filter_alt_off_rounded,
                        size: 16, color: _T.bear),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 8),

          // Two toggle chips
          Row(
            children: [
              Expanded(
                child: _ToggleChip(
                  isDark: isDark,
                  label: 'Strong Trend',
                  sublabel: '> 50% probability',
                  icon: Icons.bolt_rounded,
                  value: strongOnly,
                  onChanged: onStrongToggle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ToggleChip(
                  isDark: isDark,
                  label: 'First Entry',
                  sublabel: 'Entry signals only',
                  icon: Icons.flag_rounded,
                  value: firstEntry,
                  onChanged: onFirstEntryToggle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter Pill
// ─────────────────────────────────────────────────────────────────────────────
class _FilterPill extends StatelessWidget {
  final bool isDark;
  final bool isActive;
  final IconData icon;
  final String label;
  final Widget? trailing;

  const _FilterPill({
    required this.isDark,
    required this.isActive,
    required this.icon,
    required this.label,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? _T.dSurface : _T.lSurface;
    final border = isDark ? _T.dBorder : _T.lBorder;
    final textP = isDark ? _T.dTextP : _T.lTextP;
    final iconC = isActive ? _T.accent : (isDark ? _T.dTextS : _T.lTextS);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? _T.accentDim : surface,
        borderRadius: BorderRadius.circular(_T.rSM),
        border: Border.all(
          color: isActive ? _T.accent.withValues(alpha: 0.4) : border,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: iconC),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isActive ? _T.accent : textP,
                )),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Toggle Chip
// ─────────────────────────────────────────────────────────────────────────────
class _ToggleChip extends StatelessWidget {
  final bool isDark;
  final String label;
  final String sublabel;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleChip({
    required this.isDark,
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? _T.dSurface : _T.lSurface;
    final border = isDark ? _T.dBorder : _T.lBorder;
    final textP = isDark ? _T.dTextP : _T.lTextP;
    final textS = isDark ? _T.dTextS : _T.lTextS;

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
        decoration: BoxDecoration(
          color: value ? (isDark ? _T.accentDim : _T.accentLight) : surface,
          borderRadius: BorderRadius.circular(_T.rSM),
          border: Border.all(
            color: value ? _T.accent.withValues(alpha: 0.4) : border,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 13, color: value ? _T.accent : textS),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: value ? _T.accent : textP,
                      )),
                  Text(sublabel, style: TextStyle(fontSize: 9.5, color: textS)),
                ],
              ),
            ),
            // Compact toggle
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 28,
              height: 16,
              decoration: BoxDecoration(
                color: value ? _T.accent : (isDark ? _T.dBorder : _T.lBorder),
                borderRadius: BorderRadius.circular(8),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 180),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.all(2),
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Signal Card
// ─────────────────────────────────────────────────────────────────────────────
class _SignalCard extends StatefulWidget {
  final AtlasOutput output;
  final _SStyle style;
  final bool isDark;
  final int index;
  final Color Function(double) probColor;
  final VoidCallback onTap;

  const _SignalCard({
    Key? key,
    required this.output,
    required this.style,
    required this.isDark,
    required this.index,
    required this.probColor,
    required this.onTap,
  }) : super(key: key);

  @override
  State<_SignalCard> createState() => _SignalCardState();
}

class _SignalCardState extends State<_SignalCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 280 + widget.index * 45),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: _CardBody(
          output: widget.output,
          style: widget.style,
          isDark: widget.isDark,
          probColor: widget.probColor,
          onTap: widget.onTap,
        ),
      ),
    );
  }
}

class _CardBody extends StatelessWidget {
  final AtlasOutput output;
  final _SStyle style;
  final bool isDark;
  final Color Function(double) probColor;
  final VoidCallback onTap;

  const _CardBody({
    required this.output,
    required this.style,
    required this.isDark,
    required this.probColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? _T.dSurface : _T.lSurface;
    final border = isDark ? _T.dBorder : _T.lBorder;
    final textP = isDark ? _T.dTextP : _T.lTextP;
    final textS = isDark ? _T.dTextS : _T.lTextS;
    final dim = isDark ? style.dimDark : style.dimLight;
    final pc = probColor(output.probability);
    final total = output.positiveIndicators +
        output.negativeIndicators +
        output.neutralIndicators;

    return _TapScale(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(_T.rLG),
          border: Border.all(color: border),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          children: [
            // Accent strip
            Container(
              height: 3,
              decoration: BoxDecoration(
                color: style.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(_T.rLG),
                  topRight: Radius.circular(_T.rLG),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: icon + label + time + prob badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: dim,
                          borderRadius: BorderRadius.circular(_T.rSM),
                        ),
                        child: Icon(style.icon, size: 15, color: style.primary),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${style.label} Signal',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: textP,
                              )),
                          Text(
                            timeago.format(DateTime.parse(output.createdAt)),
                            style: TextStyle(fontSize: 11, color: textS),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Probability badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: pc.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(_T.rXS),
                          border: Border.all(color: pc.withValues(alpha: 0.28)),
                        ),
                        child: Text(
                          '${output.probability.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: pc,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded, size: 16, color: textS),
                    ],
                  ),

                  const SizedBox(height: 11),
                  Divider(height: 1, color: border),
                  const SizedBox(height: 11),

                  // Row 2: timestamp + term pills
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded, size: 12, color: textS),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM d · h:mm a')
                            .format(DateTime.parse(output.createdAt)),
                        style: TextStyle(fontSize: 11, color: textS),
                      ),
                      const Spacer(),
                      _TermPill(label: 'S', type: output.shortterm),
                      const SizedBox(width: 5),
                      _TermPill(label: 'L', type: output.longterm),
                    ],
                  ),

                  // Breakout chips
                  if (output.upbreakout || output.lowbreakout) ...[
                    const SizedBox(height: 9),
                    Wrap(spacing: 6, children: [
                      if (output.upbreakout)
                        _BreakoutChip(
                          label: 'Up Breakout',
                          icon: Icons.north_rounded,
                          color: _T.bull,
                          dim: isDark ? _T.bullDim : _T.bullDimL,
                        ),
                      if (output.lowbreakout)
                        _BreakoutChip(
                          label: 'Low Breakout',
                          icon: Icons.south_rounded,
                          color: _T.bear,
                          dim: isDark ? _T.bearDim : _T.bearDimL,
                        ),
                    ]),
                  ],

                  // First Entry badge
                  if (output.entry) ...[
                    const SizedBox(height: 9),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? _T.accentDim : _T.accentLight,
                        borderRadius: BorderRadius.circular(_T.rXS),
                        border:
                            Border.all(color: _T.accent.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.flag_rounded, size: 10, color: _T.accent),
                          const SizedBox(width: 4),
                          Text('First Entry',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _T.accent,
                              )),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 11),

                  // Indicator bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Indicators',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: textS)),
                      Text('$total total',
                          style: TextStyle(fontSize: 10, color: textS)),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: SizedBox(
                      height: 5,
                      child: Row(children: [
                        if (output.positiveIndicators > 0)
                          Expanded(
                              flex: output.positiveIndicators,
                              child: Container(color: _T.bull)),
                        if (output.neutralIndicators > 0)
                          Expanded(
                              flex: output.neutralIndicators,
                              child: Container(color: _T.neutral)),
                        if (output.negativeIndicators > 0)
                          Expanded(
                              flex: output.negativeIndicators,
                              child: Container(color: _T.bear)),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(children: [
                    _IndLabel(
                        color: _T.bull, label: '+${output.positiveIndicators}'),
                    const SizedBox(width: 10),
                    _IndLabel(
                        color: _T.neutral,
                        label: '~${output.neutralIndicators}'),
                    const SizedBox(width: 10),
                    _IndLabel(
                        color: _T.bear, label: '-${output.negativeIndicators}'),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pagination
// ─────────────────────────────────────────────────────────────────────────────
class _Pagination extends StatelessWidget {
  final bool isDark;
  final int page;
  final int totalPages;
  final int resultCount;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const _Pagination({
    required this.isDark,
    required this.page,
    required this.totalPages,
    required this.resultCount,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? _T.dSurface : _T.lSurface;
    final border = isDark ? _T.dBorder : _T.lBorder;
    final textP = isDark ? _T.dTextP : _T.lTextP;
    final textS = isDark ? _T.dTextS : _T.lTextS;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(_T.rMD),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            _PageBtn(
              isDark: isDark,
              icon: Icons.chevron_left_rounded,
              enabled: onPrev != null,
              onTap: onPrev ?? () {},
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$page / $totalPages',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: textP)),
                  Text('$resultCount results',
                      style: TextStyle(fontSize: 10, color: textS)),
                ],
              ),
            ),
            _PageBtn(
              isDark: isDark,
              icon: Icons.chevron_right_rounded,
              enabled: onNext != null,
              onTap: onNext ?? () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _PageBtn extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _PageBtn({
    required this.isDark,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final border = isDark ? _T.dBorder : _T.lBorder;
    final textP = isDark ? _T.dTextP : _T.lTextP;

    return _TapScale(
      onTap: enabled ? onTap : () {},
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: enabled ? 1.0 : 0.28,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_T.rSM),
            border: Border.all(color: border),
          ),
          child: Icon(icon, size: 18, color: textP),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Atoms
// ─────────────────────────────────────────────────────────────────────────────
class _TermPill extends StatelessWidget {
  final String label;
  final String type;
  const _TermPill({required this.label, required this.type});

  @override
  Widget build(BuildContext context) {
    Color c;
    IconData ico;
    switch (type) {
      case 'Bull':
        c = _T.bull;
        ico = Icons.north_rounded;
        break;
      case 'Bear':
        c = _T.bear;
        ico = Icons.south_rounded;
        break;
      default:
        c = _T.neutral;
        ico = Icons.remove_rounded;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(_T.rXS),
        border: Border.all(color: c.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 9, fontWeight: FontWeight.w700, color: c)),
          const SizedBox(width: 2),
          Icon(ico, size: 9, color: c),
        ],
      ),
    );
  }
}

class _BreakoutChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color dim;
  const _BreakoutChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.dim,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: dim,
        borderRadius: BorderRadius.circular(_T.rXS),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

class _IndLabel extends StatelessWidget {
  final Color color;
  final String label;
  const _IndLabel({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Skeleton Card
// ─────────────────────────────────────────────────────────────────────────────
class _SkeletonCard extends StatefulWidget {
  final bool isDark;
  const _SkeletonCard({required this.isDark});
  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.35, end: 0.85).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: widget.isDark ? _T.dSurface : _T.lSurface,
            borderRadius: BorderRadius.circular(_T.rLG),
            border: Border.all(color: widget.isDark ? _T.dBorder : _T.lBorder),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _sk(32, 32, circle: true),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _sk(110, 13),
                const SizedBox(height: 5),
                _sk(65, 10),
              ]),
              const Spacer(),
              _sk(52, 24),
            ]),
            const SizedBox(height: 11),
            _sk(double.infinity, 1),
            const SizedBox(height: 11),
            Row(children: [
              _sk(130, 10),
              const Spacer(),
              _sk(34, 18),
              const SizedBox(width: 5),
              _sk(34, 18),
            ]),
            const SizedBox(height: 11),
            _sk(double.infinity, 5),
            const SizedBox(height: 6),
            Row(children: [
              _sk(35, 10),
              const SizedBox(width: 10),
              _sk(35, 10),
              const SizedBox(width: 10),
              _sk(35, 10),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _sk(double w, double h, {bool circle = false}) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: widget.isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.07),
          borderRadius:
              circle ? BorderRadius.circular(h / 2) : BorderRadius.circular(4),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Tap Scale
// ─────────────────────────────────────────────────────────────────────────────
class _TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _TapScale({required this.child, required this.onTap});
  @override
  State<_TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<_TapScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 90));
    _scale = Tween<double>(begin: 1.0, end: 0.95)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
