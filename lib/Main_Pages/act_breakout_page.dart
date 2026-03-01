import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Initialize Supabase client
final supabase = Supabase.instance.client;

// ─────────────────────────────────────────
// Design Tokens
// ─────────────────────────────────────────
class AppColors {
  static const bull = Color(0xFF00C896);
  static const bear = Color(0xFFFF4D6A);
  static const bullSurface = Color(0x1400C896);
  static const bearSurface = Color(0x14FF4D6A);

  static const darkBg = Color(0xFF0D0F14);
  static const darkSurface = Color(0xFF161920);
  static const darkCard = Color(0xFF1C2029);
  static const darkBorder = Color(0xFF272B36);
  static const darkSubtle = Color(0xFF8B93A7);

  static const lightBg = Color(0xFFF4F6FA);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightBorder = Color(0xFFE4E8F0);
  static const lightSubtle = Color(0xFF8896AE);

  static const accent = Color(0xFF5B7FFF);
  static const accentSurface = Color(0x185B7FFF);
}

// ─────────────────────────────────────────
// Data Models
// ─────────────────────────────────────────
class BollingerBreakoutModel {
  final int id;
  final String createdAt;
  final String description;
  final String time;
  final String sentiment;
  final String? whichmode;

  BollingerBreakoutModel({
    required this.id,
    required this.createdAt,
    required this.description,
    required this.time,
    required this.sentiment,
    this.whichmode,
  });

  factory BollingerBreakoutModel.fromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.parse(json['created_at']).toLocal();
    return BollingerBreakoutModel(
      id: json['id'],
      createdAt: createdAt.toIso8601String(),
      description: json['description'],
      time: json['time'],
      sentiment: json['sentiment'],
      whichmode: json['whichmode'],
    );
  }
}

class BollingerResponse {
  final List<BollingerBreakoutModel> data;
  final int count;
  final int page;
  final int pageSize;

  BollingerResponse({
    required this.data,
    required this.count,
    required this.page,
    required this.pageSize,
  });
}

// ─────────────────────────────────────────
// Service
// ─────────────────────────────────────────
class BollingerService {
  static final _supabase = Supabase.instance.client;

  static Future<BollingerResponse> getBollingerBreakouts({
    int page = 1,
    int pageSize = 10,
    String? startDate,
    String? endDate,
    bool filterByEntry = false,
  }) async {
    final from = (page - 1) * pageSize;
    final to = from + pageSize - 1;

    var query = _supabase.from('bollinger_breakouts').select();
    if (startDate != null) query = query.gte('created_at', startDate);
    if (endDate != null) query = query.lte('created_at', endDate);
    if (filterByEntry) query = query.eq('whichmode', 'checkfirst');

    final countResponse = await query;
    final count = countResponse.length;
    final response =
        await query.order('created_at', ascending: false).range(from, to);

    return BollingerResponse(
      data: response
          .map((item) => BollingerBreakoutModel.fromJson(item))
          .toList(),
      count: count,
      page: page,
      pageSize: pageSize,
    );
  }

  static Future<BollingerResponse> getFilteredBollingerBreakouts({
    required String sentiment,
    int page = 1,
    int pageSize = 10,
    bool filterByEntry = false,
  }) async {
    final from = (page - 1) * pageSize;
    final to = from + pageSize - 1;

    var query = _supabase
        .from('bollinger_breakouts')
        .select()
        .eq('sentiment', sentiment);
    if (filterByEntry) query = query.eq('whichmode', 'checkfirst');

    final countResponse = await query;
    final count = countResponse.length;
    final response =
        await query.order('created_at', ascending: false).range(from, to);

    return BollingerResponse(
      data: response
          .map((item) => BollingerBreakoutModel.fromJson(item))
          .toList(),
      count: count,
      page: page,
      pageSize: pageSize,
    );
  }

  static Stream<BollingerBreakoutModel> subscribeToBollingerBreakouts() {
    final controller = StreamController<BollingerBreakoutModel>.broadcast();
    final channel = _supabase.channel('bollinger_breakouts_changes');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'bollinger_breakouts',
      callback: (payload) {
        if (payload.newRecord.isNotEmpty) {
          try {
            controller.add(BollingerBreakoutModel.fromJson(
                Map<String, dynamic>.from(payload.newRecord)));
          } catch (e) {
            debugPrint('Error parsing breakout: $e');
          }
        }
      },
    );

    channel.subscribe();
    controller.onCancel = () => channel.unsubscribe();
    return controller.stream;
  }
}

// ─────────────────────────────────────────
// Main Page
// ─────────────────────────────────────────
class BollingerBreakoutsPage extends StatefulWidget {
  const BollingerBreakoutsPage({Key? key}) : super(key: key);

  @override
  State<BollingerBreakoutsPage> createState() => _BollingerBreakoutsPageState();
}

class _BollingerBreakoutsPageState extends State<BollingerBreakoutsPage> {
  List<BollingerBreakoutModel> _data = [];
  bool _loading = true;
  String? _error;
  int _page = 1;
  int _totalCount = 0;
  DateTime? _selectedDate;
  String? _sentimentFilter;
  bool _filterByEntry = true;
  final int _pageSize = 10;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _setupSubscription();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _setupSubscription() {
    _subscription =
        BollingerService.subscribeToBollingerBreakouts().listen((newBreakout) {
      if (_page == 1 && mounted) {
        setState(() {
          _data = [newBreakout, ..._data.take(_pageSize - 1).toList()];
          _totalCount = _totalCount + 1;
        });
      }
    });
  }

  Future<void> _fetchData() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      BollingerResponse result;

      if (_sentimentFilter != null) {
        result = await BollingerService.getFilteredBollingerBreakouts(
          sentiment: _sentimentFilter!,
          page: _page,
          pageSize: _pageSize,
          filterByEntry: _filterByEntry,
        );
      } else {
        final startOfDay = _selectedDate != null
            ? DateTime(_selectedDate!.year, _selectedDate!.month,
                    _selectedDate!.day)
                .toIso8601String()
            : null;
        final endOfDay = _selectedDate != null
            ? DateTime(_selectedDate!.year, _selectedDate!.month,
                    _selectedDate!.day, 23, 59, 59, 999)
                .toIso8601String()
            : null;

        result = await BollingerService.getBollingerBreakouts(
          page: _page,
          pageSize: _pageSize,
          startDate: startOfDay,
          endDate: endOfDay,
          filterByEntry: _filterByEntry,
        );
      }

      if (mounted) {
        setState(() {
          _data = result.data;
          _totalCount = result.count;
          _loading = false;
        });
      }
    } catch (err) {
      if (mounted) {
        setState(() {
          _error = err.toString();
          _loading = false;
        });
      }
    }
  }

  int get _totalPages => (_totalCount / _pageSize).ceil().clamp(1, 99999);
  bool get _hasActiveFilters =>
      _selectedDate != null || _sentimentFilter != null || !_filterByEntry;

  void _clearFilters() {
    setState(() {
      _selectedDate = null;
      _sentimentFilter = null;
      _filterByEntry = true;
      _page = 1;
    });
    _fetchData();
  }

  void _toggleSentiment(String value) {
    setState(() {
      _sentimentFilter = _sentimentFilter == value ? null : value;
      _page = 1;
    });
    _fetchData();
  }

  Future<void> _pickDate() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: isDark
              ? const ColorScheme.dark(primary: AppColors.accent)
              : const ColorScheme.light(primary: AppColors.accent),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _page = 1;
      });
      _fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBg : AppColors.lightBg;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isDark),
            const SizedBox(height: 4),
            _buildFilterBar(isDark),
            const SizedBox(height: 8),
            Expanded(child: _buildContent(isDark)),
          ],
        ),
      ),
    );
  }

  // ─── Header ────────────────────────────
  Widget _buildHeader(bool isDark) {
    final canPop = Navigator.of(context).canPop();
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final subtleColor = isDark ? AppColors.darkSubtle : AppColors.lightSubtle;
    final textColor = isDark ? Colors.white : const Color(0xFF0D0F14);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Back button
          if (canPop)
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Icon(Icons.arrow_back_ios_new_rounded,
                    size: 16, color: subtleColor),
              ),
            ),
          // Title block
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _PulsingDot(),
                    const SizedBox(width: 6),
                    const Text(
                      'LIVE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: AppColors.bull,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Breakouts',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
          // Signal count
          if (_totalCount > 0)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$_totalCount',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                    color: textColor,
                  ),
                ),
                Text(
                  'signals',
                  style: TextStyle(fontSize: 11, color: subtleColor),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ─── Filter Bar ────────────────────────
  Widget _buildFilterBar(bool isDark) {
    return SizedBox(
      height: 40,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        children: [
          _FilterChip(
            label: _selectedDate != null
                ? DateFormat('MMM d').format(_selectedDate!)
                : 'Date',
            icon: Icons.calendar_month_rounded,
            isActive: _selectedDate != null,
            isDark: isDark,
            activeColor: AppColors.accent,
            onTap: _pickDate,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Bullish',
            icon: Icons.trending_up_rounded,
            isActive: _sentimentFilter == 'bullish',
            isDark: isDark,
            activeColor: AppColors.bull,
            onTap: () => _toggleSentiment('bullish'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Bearish',
            icon: Icons.trending_down_rounded,
            isActive: _sentimentFilter == 'bearish',
            isDark: isDark,
            activeColor: AppColors.bear,
            onTap: () => _toggleSentiment('bearish'),
          ),
          const SizedBox(width: 8),
          _EntryToggleChip(
            value: _filterByEntry,
            isDark: isDark,
            onChanged: (v) {
              setState(() {
                _filterByEntry = v;
                _page = 1;
              });
              _fetchData();
            },
          ),
          if (_hasActiveFilters) ...[
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Clear',
              icon: Icons.close_rounded,
              isActive: false,
              isDark: isDark,
              activeColor: AppColors.bear,
              onTap: _clearFilters,
            ),
          ],
        ],
      ),
    );
  }

  // ─── Content ───────────────────────────
  Widget _buildContent(bool isDark) {
    if (_error != null) return _buildError(isDark);
    if (_loading) return _buildSkeleton(isDark);
    if (_data.isEmpty) return _buildEmpty(isDark);

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            itemCount: _data.length,
            itemBuilder: (context, index) => _BreakoutCard(
              item: _data[index],
              isDark: isDark,
              index: index,
            ),
          ),
        ),
        _buildPagination(isDark),
      ],
    );
  }

  // ─── Error ─────────────────────────────
  Widget _buildError(bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF0D0F14);
    final subtleColor = isDark ? AppColors.darkSubtle : AppColors.lightSubtle;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.bearSurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off_rounded,
                  color: AppColors.bear, size: 32),
            ),
            const SizedBox(height: 20),
            Text('Connection Error',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textColor)),
            const SizedBox(height: 8),
            Text('Could not load breakout signals',
                style: TextStyle(color: subtleColor)),
            const SizedBox(height: 24),
            _PrimaryButton(
                label: 'Retry', icon: Icons.refresh_rounded, onTap: _fetchData),
          ],
        ),
      ),
    );
  }

  // ─── Empty ─────────────────────────────
  Widget _buildEmpty(bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF0D0F14);
    final subtleColor = isDark ? AppColors.darkSubtle : AppColors.lightSubtle;
    final iconBg = isDark ? AppColors.darkCard : AppColors.lightBorder;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(Icons.radar_rounded, size: 32, color: subtleColor),
            ),
            const SizedBox(height: 20),
            Text('No Signals Found',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textColor)),
            const SizedBox(height: 8),
            Text('Try adjusting or clearing your filters',
                style: TextStyle(color: subtleColor)),
            const SizedBox(height: 24),
            _PrimaryButton(
                label: 'Clear Filters',
                icon: Icons.filter_alt_off_rounded,
                onTap: _clearFilters),
          ],
        ),
      ),
    );
  }

  // ─── Skeleton ──────────────────────────
  Widget _buildSkeleton(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      itemCount: 6,
      itemBuilder: (_, i) => _SkeletonCard(isDark: isDark, index: i),
    );
  }

  // ─── Pagination ────────────────────────
  Widget _buildPagination(bool isDark) {
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final subtleColor = isDark ? AppColors.darkSubtle : AppColors.lightSubtle;
    final textColor = isDark ? Colors.white : const Color(0xFF0D0F14);
    final bgColor = isDark ? AppColors.darkBg : AppColors.lightBg;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          _PageButton(
            icon: Icons.chevron_left_rounded,
            enabled: _page > 1,
            isDark: isDark,
            onTap: () {
              setState(() => _page--);
              _fetchData();
            },
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Page $_page of $_totalPages',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: textColor),
                ),
                const SizedBox(height: 2),
                Text('$_totalCount total signals',
                    style: TextStyle(fontSize: 11, color: subtleColor)),
              ],
            ),
          ),
          _PageButton(
            icon: Icons.chevron_right_rounded,
            enabled: _page < _totalPages,
            isDark: isDark,
            onTap: () {
              setState(() => _page++);
              _fetchData();
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Pulsing Dot (plain AnimationController — no Animate.repeat())
// ─────────────────────────────────────────
class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.25, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.bull,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Breakout Card
// ─────────────────────────────────────────
class _BreakoutCard extends StatelessWidget {
  final BollingerBreakoutModel item;
  final bool isDark;
  final int index;

  const _BreakoutCard({
    required this.item,
    required this.isDark,
    required this.index,
  });

  String? _extractNumber(String text) {
    final match = RegExp(r':\s*([\d,\.]+)').firstMatch(text);
    return match?.group(1);
  }

  String _descriptionText(String text) => text.split(':')[0].trim();

  String _getTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    final isBull = item.sentiment == 'bullish';
    final sentimentColor = isBull ? AppColors.bull : AppColors.bear;
    final sentimentSurface =
        isBull ? AppColors.bullSurface : AppColors.bearSurface;
    final isFirstEntry = item.whichmode == 'checkfirst';

    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final subtleColor = isDark ? AppColors.darkSubtle : AppColors.lightSubtle;
    final textColor = isDark ? Colors.white : const Color(0xFF0D0F14);
    final numBg = isDark ? AppColors.darkSurface : AppColors.lightBg;

    final createdAt = DateTime.parse(item.createdAt).toLocal();
    final formattedDate = DateFormat('MMM d, h:mm a').format(createdAt);
    final timeAgo = _getTimeAgo(createdAt);
    final number = _extractNumber(item.description);
    final descText = _descriptionText(item.description);

    return Animate(
      effects: [
        FadeEffect(
          delay: Duration(milliseconds: index * 60),
          duration: 350.ms,
          curve: Curves.easeOut,
        ),
        SlideEffect(
          delay: Duration(milliseconds: index * 60),
          duration: 350.ms,
          begin: const Offset(0, 0.05),
          end: Offset.zero,
          curve: Curves.easeOut,
        ),
      ],
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left accent bar
                Container(width: 4, color: sentimentColor),
                // Card content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Badges row
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: sentimentSurface,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isBull
                                        ? Icons.trending_up_rounded
                                        : Icons.trending_down_rounded,
                                    size: 13,
                                    color: sentimentColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    item.sentiment.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                      color: sentimentColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            if (isFirstEntry)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.accentSurface,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'ENTRY',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                    color: AppColors.accent,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Instrument
                        Text(
                          'NIFTY 50',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                            color: subtleColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Description + number
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Text(
                                descText,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                  color: textColor.withOpacity(0.85),
                                ),
                              ),
                            ),
                            if (number != null) ...[
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: numBg,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: borderColor),
                                ),
                                child: Text(
                                  number,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                    color: sentimentColor,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Footer
                        Row(
                          children: [
                            Icon(Icons.access_time_rounded,
                                size: 11, color: subtleColor),
                            const SizedBox(width: 4),
                            Text(formattedDate,
                                style: TextStyle(
                                    fontSize: 11, color: subtleColor)),
                            const Spacer(),
                            Text(
                              timeAgo,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: subtleColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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

// ─────────────────────────────────────────
// Filter Chip
// ─────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final bool isDark;
  final Color activeColor;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.isDark,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final inactiveBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final inactiveBorder =
        isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final inactiveText = isDark ? AppColors.darkSubtle : AppColors.lightSubtle;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.12) : inactiveBg,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: isActive ? activeColor : inactiveBorder,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isActive ? activeColor : inactiveText),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? activeColor : inactiveText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Entry Toggle Chip
// ─────────────────────────────────────────
class _EntryToggleChip extends StatelessWidget {
  final bool value;
  final bool isDark;
  final ValueChanged<bool> onChanged;

  const _EntryToggleChip({
    required this.value,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final inactiveBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final inactiveText = isDark ? AppColors.darkSubtle : AppColors.lightSubtle;

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: value ? AppColors.accent.withOpacity(0.12) : inactiveBg,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: value ? AppColors.accent : borderColor,
            width: value ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.electric_bolt_rounded,
                size: 14, color: value ? AppColors.accent : inactiveText),
            const SizedBox(width: 6),
            Text(
              'First Entry',
              style: TextStyle(
                fontSize: 13,
                fontWeight: value ? FontWeight.w700 : FontWeight.w500,
                color: value ? AppColors.accent : inactiveText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Page Button
// ─────────────────────────────────────────
class _PageButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final bool isDark;
  final VoidCallback onTap;

  const _PageButton({
    required this.icon,
    required this.enabled,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final activeText = isDark ? Colors.white : const Color(0xFF0D0F14);
    final inactiveText = isDark ? AppColors.darkSubtle : AppColors.lightSubtle;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Icon(icon, size: 22, color: enabled ? activeText : inactiveText),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Primary Button
// ─────────────────────────────────────────
class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(40),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Skeleton Card
// Uses LayoutBuilder for safe width — no double.infinity in Column
// ─────────────────────────────────────────
class _SkeletonCard extends StatelessWidget {
  final bool isDark;
  final int index;

  const _SkeletonCard({required this.isDark, required this.index});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final boneColor = isDark ? AppColors.darkBorder : const Color(0xFFE4E8F4);
    final shimmerColor = isDark
        ? Colors.white.withOpacity(0.04)
        : Colors.black.withOpacity(0.04);

    return Animate(
      onPlay: (controller) => controller.repeat(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Bone(w: 72, h: 26, r: 20, color: boneColor),
                _Bone(w: 48, h: 26, r: 20, color: boneColor),
              ],
            ),
            const SizedBox(height: 12),
            _Bone(w: 44, h: 10, r: 4, color: boneColor),
            const SizedBox(height: 8),
            // Safe full-width bones via LayoutBuilder
            LayoutBuilder(builder: (ctx, constraints) {
              final maxW = constraints.maxWidth;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Bone(w: maxW, h: 13, r: 4, color: boneColor),
                  const SizedBox(height: 6),
                  _Bone(w: maxW * 0.6, h: 13, r: 4, color: boneColor),
                ],
              );
            }),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Bone(w: 110, h: 10, r: 4, color: boneColor),
                _Bone(w: 50, h: 10, r: 4, color: boneColor),
              ],
            ),
          ],
        ),
      ),
    ).shimmer(
      delay: Duration(milliseconds: index * 80),
      duration: 1200.ms,
      color: shimmerColor,
    );
  }
}

class _Bone extends StatelessWidget {
  final double w;
  final double h;
  final double r;
  final Color color;

  const _Bone(
      {required this.w, required this.h, required this.r, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: w,
      height: h,
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(r)),
    );
  }
}
