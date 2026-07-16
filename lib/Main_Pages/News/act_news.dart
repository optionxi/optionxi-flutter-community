// lib/pages/news_feed_page.dart
//
// TradeDesk News Feed
//  ✓ Skeleton shimmer loader (no third-party)
//  ✓ Full detail page on card tap (replaces inline expand)
//  ✓ Full-screen image viewer (no zoom)
//  ✓ Stock chip → Get.toNamed('/stocks/<SYMBOL>')
//  ✓ Infinite scroll pagination + pull-to-refresh
//  ✓ Error + empty states with Back button
// ─────────────────────────────────────────────────────────────
// Dependencies (pubspec.yaml):
//   supabase_flutter: ^2.5.0
//   google_fonts: ^6.2.1
//   get: ^4.6.6
//   url_launcher: ^6.2.0
//   cached_network_image: ^3.3.1
// ─────────────────────────────────────────────────────────────

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:optionxi/Main_Pages/Achivements/fastapi_achivement.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';

// ═══════════════════════════════════════════════════════════════
// MODEL
// ═══════════════════════════════════════════════════════════════

class NewsDigest {
  final String id;
  final String headline;
  final String summary;
  final String details;
  final String region;
  final String category;
  final List<String> sectors;
  final List<String> stocks;
  final String sentiment;
  final String impact;
  final List<String> sourceUrls;
  final String? imageUrl;
  final DateTime createdAt;

  const NewsDigest({
    required this.id,
    required this.headline,
    required this.summary,
    required this.details,
    required this.region,
    required this.category,
    required this.sectors,
    required this.stocks,
    required this.sentiment,
    required this.impact,
    required this.sourceUrls,
    this.imageUrl,
    required this.createdAt,
  });

  factory NewsDigest.fromJson(Map<String, dynamic> j) => NewsDigest(
        id: j['id'] as String,
        headline: j['headline'] as String,
        summary: j['summary'] as String,
        details: j['details'] as String,
        region: j['region'] as String? ?? 'international',
        category: j['category'] as String? ?? 'markets',
        sectors: List<String>.from(j['sectors'] ?? []),
        stocks: List<String>.from(j['stocks'] ?? []),
        sentiment: j['sentiment'] as String? ?? 'neutral',
        impact: j['impact'] as String? ?? 'medium',
        sourceUrls: List<String>.from(j['source_urls'] ?? []),
        imageUrl: j['image_url'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}

// ═══════════════════════════════════════════════════════════════
// SERVICE
// ═══════════════════════════════════════════════════════════════

class NewsService {
  final _sb = Supabase.instance.client;
  static const int pageSize = 20;

  Future<List<NewsDigest>> fetchDigests({
    String? region,
    String? category,
    int offset = 0,
    int limit = pageSize,
  }) async {
    var query = _sb.from('news_digests').select();
    if (region != null) query = query.eq('region', region);
    if (category != null) query = query.eq('category', category);
    final data = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return data.map((e) => NewsDigest.fromJson(e)).toList();
  }
}

// ═══════════════════════════════════════════════════════════════
// DESIGN TOKENS
// ═══════════════════════════════════════════════════════════════

class _Palette {
  static const blue = Color(0xFF3B82F6);
  static const bullish = Color(0xFF10B981);
  static const bearish = Color(0xFFEF4444);
  static const neutral = Color(0xFF6B7280);
  static const highImpact = Color(0xFFF97316);
  static const medImpact = Color(0xFFFBBF24);
  static const lowImpact = Color(0xFF94A3B8);

  static const darkBg = Color(0xFF0A0B0E);
  static const darkSurface = Color(0xFF111318);
  static const darkCard = Color(0xFF161A22);
  static const darkBorder = Color(0xFF1F2430);

  static const lightBg = Color(0xFFF0F2F5);
  static const lightSurface = Color(0xFFF8F9FC);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightBorder = Color(0xFFE4E7EE);
}

// ═══════════════════════════════════════════════════════════════
// THEME HELPERS
// ═══════════════════════════════════════════════════════════════

Color _sentimentColor(String s) => switch (s) {
      'bullish' => _Palette.bullish,
      'bearish' => _Palette.bearish,
      _ => _Palette.neutral,
    };

Color _impactColor(String i) => switch (i) {
      'high' => _Palette.highImpact,
      'medium' => _Palette.medImpact,
      _ => _Palette.lowImpact,
    };

IconData _categoryIcon(String c) => switch (c) {
      'markets' => Icons.show_chart_rounded,
      'economy' => Icons.account_balance_rounded,
      'commodities' => Icons.oil_barrel_rounded,
      'forex' => Icons.currency_exchange_rounded,
      'stocks' => Icons.candlestick_chart_rounded,
      _ => Icons.article_rounded,
    };

String _regionLabel(String r) => r == 'india' ? '🇮🇳 India' : '🌐 Global';

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}

// ═══════════════════════════════════════════════════════════════
// SHIMMER ENGINE  (zero dependencies)
// ═══════════════════════════════════════════════════════════════

class _Shimmer extends StatefulWidget {
  final Widget child;
  const _Shimmer({required this.child});

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _anim = Tween<double>(begin: -1.5, end: 2.5).animate(
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF1C2130) : const Color(0xFFE8EAF0);
    final highlight =
        isDark ? const Color(0xFF2A3245) : const Color(0xFFF5F6FA);

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) => LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [base, highlight, base],
          stops: [
            math.max(0.0, _anim.value - 0.4),
            _anim.value.clamp(0.0, 1.0),
            math.min(1.0, _anim.value + 0.4),
          ],
        ).createShader(bounds),
        child: widget.child,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SKELETON CARD
// — Card chrome (bg, border, radius) is static.
// — Only the dynamic content slots (headline, summary, meta pills,
//   timestamp) are wrapped in _Shimmer, keeping the loader lean.
// ═══════════════════════════════════════════════════════════════

class _SkeletonCard extends StatelessWidget {
  final bool isDark;

  const _SkeletonCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? _Palette.darkCard : _Palette.lightCard;
    final border = isDark ? _Palette.darkBorder : _Palette.lightBorder;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.22 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Full-width image placeholder ─────────────────────
          _Shimmer(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(13)),
              child: _SBox(w: double.infinity, h: 160, r: 0, isDark: isDark),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Meta row: two badge slots + impact pill ──────────
                _Shimmer(
                  child: Row(children: [
                    _SBox(w: 72, h: 20, r: 6, isDark: isDark),
                    const SizedBox(width: 6),
                    _SBox(w: 58, h: 20, r: 6, isDark: isDark),
                    const Spacer(),
                    _SBox(w: 44, h: 20, r: 20, isDark: isDark),
                  ]),
                ),
                const SizedBox(height: 11),

                // ── Headline: 3 lines of varying width ───────────────
                _Shimmer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SBox(w: double.infinity, h: 13, r: 4, isDark: isDark),
                      const SizedBox(height: 5),
                      _SBox(w: double.infinity, h: 13, r: 4, isDark: isDark),
                      const SizedBox(height: 5),
                      _SBox(w: 180, h: 13, r: 4, isDark: isDark),
                    ],
                  ),
                ),
                const SizedBox(height: 9),

                // ── Summary: 2 lines ─────────────────────────────────
                _Shimmer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SBox(w: double.infinity, h: 11, r: 4, isDark: isDark),
                      const SizedBox(height: 5),
                      _SBox(w: 220, h: 11, r: 4, isDark: isDark),
                    ],
                  ),
                ),
                const SizedBox(height: 11),

                // ── Sentiment + 2 sector tags ────────────────────────
                _Shimmer(
                  child: Row(children: [
                    _SBox(w: 66, h: 20, r: 20, isDark: isDark),
                    const SizedBox(width: 6),
                    _SBox(w: 52, h: 20, r: 6, isDark: isDark),
                    const SizedBox(width: 5),
                    _SBox(w: 46, h: 20, r: 6, isDark: isDark),
                  ]),
                ),
                const SizedBox(height: 10),

                // ── Timestamp ────────────────────────────────────────
                _Shimmer(
                  child: _SBox(w: 56, h: 10, r: 4, isDark: isDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shorthand shimmer rectangle — colour comes from the parent [_Shimmer].
class _SBox extends StatelessWidget {
  final double? w;
  final double h;
  final double r;
  final bool isDark;

  const _SBox({
    this.w,
    required this.h,
    this.r = 6,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2130) : const Color(0xFFE8EAF0),
        borderRadius: BorderRadius.circular(r),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// NEWS DETAIL PAGE
// ═══════════════════════════════════════════════════════════════

class NewsDetailPage extends StatelessWidget {
  final NewsDigest digest;
  const NewsDetailPage({super.key, required this.digest});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final d = digest;
    final heroTag = 'news-img-${d.id}';
    final impColor = _impactColor(d.impact);
    final sentColor = _sentimentColor(d.sentiment);
    final textPrimary =
        isDark ? const Color(0xFFF1F3F9) : const Color(0xFF0D1117);
    final textSecondary =
        isDark ? const Color(0xFF8B95A7) : const Color(0xFF6B7280);
    final bg = isDark ? _Palette.darkBg : _Palette.lightBg;
    final surface = isDark ? _Palette.darkSurface : _Palette.lightSurface;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bg,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: d.imageUrl != null ? 260 : 0,
              pinned: true,
              stretch: true,
              backgroundColor: surface,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
              leading: Padding(
                padding: const EdgeInsets.all(8),
                child: _CircleBackButton(
                  onTap: () => Navigator.of(context).pop(),
                  forceDark: d.imageUrl != null,
                ),
              ),
              flexibleSpace: d.imageUrl != null
                  ? FlexibleSpaceBar(
                      stretchModes: const [StretchMode.zoomBackground],
                      background: GestureDetector(
                        // onTap: () => _openImage(context, d.imageUrl!, heroTag),
                        child: Hero(
                          tag: heroTag,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CachedNetworkImage(
                                imageUrl: d.imageUrl!,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  color: isDark
                                      ? const Color(0xFF1A1F2B)
                                      : const Color(0xFFEEF0F5),
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  color: isDark
                                      ? const Color(0xFF1A1F2B)
                                      : const Color(0xFFEEF0F5),
                                  child: const Center(
                                    child: Icon(
                                        Icons.image_not_supported_outlined,
                                        color: Colors.white24,
                                        size: 36),
                                  ),
                                ),
                              ),
                              // Bottom scrim
                              Positioned.fill(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.55),
                                      ],
                                      stops: const [0.5, 1.0],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : null,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 60),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badges
                    Wrap(spacing: 6, runSpacing: 6, children: [
                      _MetaBadge(
                          icon: _categoryIcon(d.category),
                          label: d.category.toUpperCase(),
                          color: _Palette.blue,
                          isDark: isDark),
                      _RegionBadge(region: d.region, isDark: isDark),
                      _ImpactChip(impact: d.impact, color: impColor),
                      _SentimentBadge(sentiment: d.sentiment, color: sentColor),
                    ]),
                    const SizedBox(height: 16),

                    // Headline
                    Text(
                      d.headline,
                      style: GoogleFonts.sora(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                        height: 1.3,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Timestamp
                    Row(children: [
                      Icon(Icons.access_time_rounded,
                          size: 11, color: textSecondary.withOpacity(0.6)),
                      const SizedBox(width: 4),
                      Text(_timeAgo(d.createdAt),
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              color: textSecondary.withOpacity(0.6))),
                    ]),
                    const SizedBox(height: 20),

                    // Summary
                    Text(
                      d.summary,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: isDark
                            ? const Color(0xFFCDD5E0)
                            : const Color(0xFF374151),
                        height: 1.65,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _DetailDivider(isDark: isDark),
                    const SizedBox(height: 20),

                    // Analysis
                    _SectionLabel(label: 'ANALYSIS', isDark: isDark),
                    const SizedBox(height: 10),
                    Text(
                      d.details,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: isDark
                            ? const Color(0xFFB0BBC9)
                            : const Color(0xFF374151),
                        height: 1.75,
                      ),
                    ),

                    // Sectors
                    if (d.sectors.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _DetailDivider(isDark: isDark),
                      const SizedBox(height: 20),
                      _SectionLabel(label: 'SECTORS', isDark: isDark),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: d.sectors
                            .map((s) => _TagChip(
                                label: s, isDark: isDark, color: textSecondary))
                            .toList(),
                      ),
                    ],

                    // Stocks — tappable
                    if (d.stocks.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _DetailDivider(isDark: isDark),
                      const SizedBox(height: 20),
                      _SectionLabel(label: 'RELATED STOCKS', isDark: isDark),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children:
                            d.stocks.map((s) => _StockChip(symbol: s)).toList(),
                      ),
                    ],

                    // Sources
                    if (d.sourceUrls.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _DetailDivider(isDark: isDark),
                      const SizedBox(height: 20),
                      _SectionLabel(label: 'SOURCES', isDark: isDark),
                      const SizedBox(height: 10),
                      ...d.sourceUrls
                          .take(5)
                          .map((url) => _SourceRow(url: url, isDark: isDark)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// MAIN FEED PAGE
// ═══════════════════════════════════════════════════════════════

class NewsFeedPage extends StatefulWidget {
  const NewsFeedPage({super.key});

  @override
  State<NewsFeedPage> createState() => _NewsFeedPageState();
}

class _NewsFeedPageState extends State<NewsFeedPage>
    with SingleTickerProviderStateMixin {
  final _service = NewsService();
  final _scrollController = ScrollController();

  String? _selectedRegion;
  String? _selectedCategory;
  List<NewsDigest> _digests = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;

  late TabController _tabController;
  final _tabs = ['All', 'India', 'Global'];
  static const _triggerOffset = 300.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {
        _selectedRegion = switch (_tabController.index) {
          1 => 'india',
          2 => 'international',
          _ => null,
        };
      });
      _reload();
    });
    _scrollController.addListener(_onScroll);
    _reload();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final remaining = _scrollController.position.maxScrollExtent -
        _scrollController.position.pixels;
    if (remaining <= _triggerOffset && !_loadingMore && _hasMore && !_loading) {
      _loadMore();
    }
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
      _digests = [];
      _hasMore = true;
    });
    try {
      final data = await _service.fetchDigests(
        region: _selectedRegion,
        category: _selectedCategory,
        offset: 0,
      );
      setState(() {
        _digests = data;
        _hasMore = data.length >= NewsService.pageSize;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final data = await _service.fetchDigests(
        region: _selectedRegion,
        category: _selectedCategory,
        offset: _digests.length,
      );
      setState(() {
        _digests.addAll(data);
        _hasMore = data.length >= NewsService.pageSize;
        _loadingMore = false;
      });
    } catch (_) {
      setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? _Palette.darkBg : _Palette.lightBg;

    AchievementEvents.openedNews();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bg,
        body: NestedScrollView(
          headerSliverBuilder: (ctx, _) => [_buildAppBar(isDark)],
          body: _buildBody(isDark),
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isDark) {
    final surface = isDark ? _Palette.darkSurface : _Palette.lightSurface;
    final borderColor = isDark ? _Palette.darkBorder : const Color(0xFFDDE1EA);

    return SliverAppBar(
      pinned: true,
      floating: false,
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: 56,
      titleSpacing: 20,
      title: Text(
        'Market News',
        style: GoogleFonts.sora(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : const Color(0xFF0D1117),
          letterSpacing: -0.4,
        ),
      ),
      actions: [
        _CategoryFilterChip(
          selected: _selectedCategory,
          isDark: isDark,
          onChanged: (cat) {
            setState(() => _selectedCategory = cat);
            _reload();
          },
        ),
        const SizedBox(width: 4),
        _IconBtn(icon: Icons.refresh_rounded, isDark: isDark, onTap: _reload),
        const SizedBox(width: 12),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(44),
        child: _buildTabBar(isDark, borderColor),
      ),
    );
  }

  Widget _buildTabBar(bool isDark, Color borderColor) {
    final surface = isDark ? _Palette.darkSurface : _Palette.lightSurface;
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: surface,
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      child: TabBar(
        controller: _tabController,
        labelStyle:
            GoogleFonts.sora(fontWeight: FontWeight.w600, fontSize: 13.5),
        unselectedLabelStyle:
            GoogleFonts.sora(fontWeight: FontWeight.w400, fontSize: 13.5),
        labelColor: _Palette.blue,
        unselectedLabelColor: isDark ? Colors.white38 : const Color(0xFF6B7280),
        indicatorColor: _Palette.blue,
        indicatorWeight: 2,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        tabs: _tabs.map((t) => Tab(text: t, height: 44)).toList(),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    // ── Skeleton loading ──────────────────────────────────
    if (_loading) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        itemCount: 5,
        itemBuilder: (_, __) => _SkeletonCard(isDark: isDark),
      );
    }

    // ── Error state ───────────────────────────────────────
    if (_error != null) {
      return _StateScreen(
        isDark: isDark,
        icon: Icons.wifi_off_rounded,
        iconColor: _Palette.bearish,
        title: 'Connection Error',
        subtitle: _error!,
        actionLabel: 'Retry',
        onAction: _reload,
      );
    }

    // ── Empty state ───────────────────────────────────────
    if (_digests.isEmpty) {
      return _StateScreen(
        isDark: isDark,
        icon: Icons.newspaper_rounded,
        iconColor: _Palette.neutral,
        title: 'No News Yet',
        subtitle: 'Check back soon for the latest market updates.',
        actionLabel: 'Refresh',
        onAction: _reload,
      );
    }

    // ── Feed ──────────────────────────────────────────────
    final itemCount = _digests.length + (_loadingMore || !_hasMore ? 1 : 0);

    return RefreshIndicator(
      onRefresh: _reload,
      color: _Palette.blue,
      backgroundColor: isDark ? _Palette.darkCard : Colors.white,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        itemCount: itemCount,
        itemBuilder: (ctx, i) {
          if (i == _digests.length) {
            return _BottomStatus(
                isLoading: _loadingMore, hasMore: _hasMore, isDark: isDark);
          }
          return _DigestCard(digest: _digests[i], isDark: isDark);
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// EMPTY / ERROR SCREEN
// ═══════════════════════════════════════════════════════════════

class _StateScreen extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  const _StateScreen({
    required this.isDark,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? const Color(0xFFF1F3F9) : const Color(0xFF0D1117);
    final textSecondary = isDark ? Colors.white38 : const Color(0xFF6B7280);
    final canPop = Navigator.of(context).canPop();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 30),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: GoogleFonts.sora(
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: textSecondary,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (canPop) ...[
                  _OutlineButton(
                    label: 'Back',
                    isDark: isDark,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 10),
                ],
                _PillButton(label: actionLabel, onTap: onAction),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PAGINATION BOTTOM STATUS
// ═══════════════════════════════════════════════════════════════

class _BottomStatus extends StatelessWidget {
  final bool isLoading;
  final bool hasMore;
  final bool isDark;

  const _BottomStatus(
      {required this.isLoading, required this.hasMore, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child:
                CircularProgressIndicator(color: _Palette.blue, strokeWidth: 2),
          ),
        ),
      );
    }
    if (!hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            _line(isDark),
            const SizedBox(width: 10),
            Text(
              'All caught up',
              style: GoogleFonts.sora(
                fontSize: 11,
                color: isDark ? Colors.white24 : const Color(0xFFBCC0CB),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 10),
            _line(isDark),
          ]),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _line(bool isDark) => Container(
        width: 40,
        height: 1,
        color: isDark
            ? Colors.white.withOpacity(0.08)
            : Colors.black.withOpacity(0.08),
      );
}

// ═══════════════════════════════════════════════════════════════
// DIGEST CARD  — tap opens NewsDetailPage
// ═══════════════════════════════════════════════════════════════

class _DigestCard extends StatelessWidget {
  final NewsDigest digest;
  final bool isDark;

  const _DigestCard({required this.digest, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final d = digest;
    final cardBg = isDark ? _Palette.darkCard : _Palette.lightCard;
    final borderColor = isDark ? _Palette.darkBorder : _Palette.lightBorder;
    final impColor = _impactColor(d.impact);
    final sentColor = _sentimentColor(d.sentiment);
    final textPrimary =
        isDark ? const Color(0xFFF1F3F9) : const Color(0xFF0D1117);
    final textSecondary =
        isDark ? const Color(0xFF8B95A7) : const Color(0xFF6B7280);
    final tagBg = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.04);
    final isHighImpact = d.impact == 'high';
    final heroTag = 'news-img-${d.id}';

    return GestureDetector(
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => NewsDetailPage(digest: d))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isHighImpact ? impColor.withOpacity(0.35) : borderColor,
            width: isHighImpact ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // High-impact bar
            if (isHighImpact)
              Container(
                height: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    impColor.withOpacity(0.9),
                    impColor.withOpacity(0.2),
                  ]),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(13)),
                ),
              ),

            // Image thumbnail with shimmer placeholder
            if (d.imageUrl != null && d.imageUrl!.isNotEmpty)
              Hero(
                tag: heroTag,
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(
                      top: Radius.circular(isHighImpact ? 0 : 13)),
                  child: CachedNetworkImage(
                    imageUrl: d.imageUrl!,
                    width: double.infinity,
                    height: 160,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _Shimmer(
                      child: Container(
                        height: 160,
                        color: isDark
                            ? const Color(0xFF1C2130)
                            : const Color(0xFFE8EAF0),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      height: 160,
                      color: isDark
                          ? const Color(0xFF1A1F2B)
                          : const Color(0xFFEEF0F5),
                      child: Center(
                        child: Icon(Icons.image_not_supported_outlined,
                            color: textSecondary.withOpacity(0.4), size: 28),
                      ),
                    ),
                  ),
                ),
              ),

            Padding(
              padding: EdgeInsets.fromLTRB(14, isHighImpact ? 12 : 14, 12, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Meta row
                  Row(children: [
                    _MetaBadge(
                        icon: _categoryIcon(d.category),
                        label: d.category.toUpperCase(),
                        color: _Palette.blue,
                        isDark: isDark),
                    const SizedBox(width: 6),
                    _RegionBadge(region: d.region, isDark: isDark),
                    const Spacer(),
                    _ImpactChip(impact: d.impact, color: impColor),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded,
                        size: 18, color: textSecondary),
                  ]),
                  const SizedBox(height: 10),

                  // Headline
                  Text(
                    d.headline,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.sora(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                      height: 1.35,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 7),

                  // Summary
                  Text(
                    d.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        fontSize: 13, color: textSecondary, height: 1.55),
                  ),
                  const SizedBox(height: 10),

                  // Sentiment + sector tags
                  Row(children: [
                    _SentimentBadge(sentiment: d.sentiment, color: sentColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: d.sectors.take(3).map((s) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 5),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: tagBg,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(s,
                                    style: GoogleFonts.inter(
                                        fontSize: 10.5,
                                        color: textSecondary,
                                        fontWeight: FontWeight.w500)),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ]),

                  // Stock chips
                  if (d.stocks.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 5,
                      runSpacing: 4,
                      children: d.stocks
                          .take(4)
                          .map((s) => _StockChip(symbol: s))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Row(children: [
                Icon(Icons.access_time_rounded,
                    size: 11, color: textSecondary.withOpacity(0.6)),
                const SizedBox(width: 4),
                Text(_timeAgo(d.createdAt),
                    style: GoogleFonts.inter(
                        fontSize: 10.5, color: textSecondary.withOpacity(0.6))),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SMALL REUSABLE WIDGETS
// ═══════════════════════════════════════════════════════════════

class _CircleBackButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool forceDark;

  const _CircleBackButton({required this.onTap, this.forceDark = false});

  @override
  Widget build(BuildContext context) {
    final dark = forceDark || Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: dark
              ? Colors.black.withOpacity(0.45)
              : Colors.black.withOpacity(0.06),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.arrow_back_rounded,
            size: 18, color: dark ? Colors.white : const Color(0xFF1F2937)),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  const _IconBtn(
      {required this.icon, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon,
            size: 18, color: isDark ? Colors.white70 : const Color(0xFF374151)),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PillButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: _Palette.blue,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(label,
            style: GoogleFonts.sora(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  const _OutlineButton(
      {required this.label, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.15)
                : Colors.black.withOpacity(0.12),
          ),
        ),
        child: Text(label,
            style: GoogleFonts.sora(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : const Color(0xFF374151),
            )),
      ),
    );
  }
}

// ─── Stock chip — tappable ────────────────────────────────────

class _StockChip extends StatelessWidget {
  final String symbol;
  const _StockChip({required this.symbol});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Get.toNamed('/stocks/NSE:${symbol.toUpperCase()}-EQ');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: _Palette.blue.withOpacity(0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _Palette.blue.withOpacity(0.22)),
        ),
        child: Text(
          symbol.toUpperCase(),
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: _Palette.blue,
          ),
        ),
      ),
    );
  }
}

// ─── Generic tag chip ────────────────────────────────────────

class _TagChip extends StatelessWidget {
  final String label;
  final bool isDark;
  final Color color;

  const _TagChip(
      {required this.label, required this.isDark, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.06)
            : Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: GoogleFonts.inter(
              fontSize: 11.5, color: color, fontWeight: FontWeight.w500)),
    );
  }
}

// ─── Category filter ─────────────────────────────────────────

class _CategoryFilterChip extends StatelessWidget {
  final String? selected;
  final bool isDark;
  final ValueChanged<String?> onChanged;

  const _CategoryFilterChip(
      {required this.selected, required this.isDark, required this.onChanged});

  static const _cats = [
    (null, 'All'),
    ('markets', 'Markets'),
    ('economy', 'Economy'),
    ('commodities', 'Commodities'),
    ('forex', 'Forex'),
    ('stocks', 'Stocks'),
  ];

  @override
  Widget build(BuildContext context) {
    final hasFilter = selected != null;
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: hasFilter
            ? _Palette.blue.withOpacity(0.15)
            : isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: hasFilter
            ? Border.all(color: _Palette.blue.withOpacity(0.4))
            : null,
      ),
      child: PopupMenuButton<String?>(
        padding: EdgeInsets.zero,
        tooltip: 'Filter category',
        onSelected: onChanged,
        color: isDark ? const Color(0xFF1C2130) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tune_rounded,
                size: 16,
                color: hasFilter
                    ? _Palette.blue
                    : isDark
                        ? Colors.white70
                        : const Color(0xFF374151)),
            if (hasFilter) ...[
              const SizedBox(width: 4),
              Text(
                selected![0].toUpperCase() + selected!.substring(1),
                style: GoogleFonts.sora(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _Palette.blue),
              ),
            ],
          ],
        ),
        itemBuilder: (_) => _cats
            .map((c) => PopupMenuItem<String?>(
                  value: c.$1,
                  child: Row(children: [
                    Icon(_categoryIcon(c.$1 ?? ''),
                        size: 16,
                        color: selected == c.$1
                            ? _Palette.blue
                            : isDark
                                ? Colors.white54
                                : const Color(0xFF6B7280)),
                    const SizedBox(width: 10),
                    Text(c.$2,
                        style: GoogleFonts.sora(
                          fontSize: 13,
                          fontWeight: selected == c.$1
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: selected == c.$1
                              ? _Palette.blue
                              : isDark
                                  ? Colors.white
                                  : const Color(0xFF111827),
                        )),
                    if (selected == c.$1) ...[
                      const Spacer(),
                      const Icon(Icons.check_rounded,
                          size: 14, color: _Palette.blue),
                    ],
                  ]),
                ))
            .toList(),
      ),
    );
  }
}

// ─── Badge / chip helpers ─────────────────────────────────────

class _MetaBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;

  const _MetaBadge(
      {required this.icon,
      required this.label,
      required this.color,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.sora(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: color,
                letterSpacing: 0.5)),
      ]),
    );
  }
}

class _RegionBadge extends StatelessWidget {
  final String region;
  final bool isDark;

  const _RegionBadge({required this.region, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.06)
            : Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(_regionLabel(region),
          style: GoogleFonts.sora(fontSize: 9.5, fontWeight: FontWeight.w500)),
    );
  }
}

class _ImpactChip extends StatelessWidget {
  final String impact;
  final Color color;

  const _ImpactChip({required this.impact, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(impact.toUpperCase(),
          style: GoogleFonts.sora(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.6)),
    );
  }
}

class _SentimentBadge extends StatelessWidget {
  final String sentiment;
  final Color color;

  const _SentimentBadge({required this.sentiment, required this.color});

  static IconData _icon(String s) => switch (s) {
        'bullish' => Icons.trending_up_rounded,
        'bearish' => Icons.trending_down_rounded,
        _ => Icons.trending_flat_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(_icon(sentiment), size: 11, color: color),
        const SizedBox(width: 4),
        Text(sentiment.toUpperCase(),
            style: GoogleFonts.sora(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: color,
                letterSpacing: 0.4)),
      ]),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;

  const _SectionLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: GoogleFonts.sora(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: isDark ? Colors.white24 : const Color(0xFF9CA3AF),
        ));
  }
}

class _DetailDivider extends StatelessWidget {
  final bool isDark;
  const _DetailDivider({required this.isDark});

  @override
  Widget build(BuildContext context) => Divider(
        height: 1,
        color: isDark
            ? Colors.white.withOpacity(0.07)
            : Colors.black.withOpacity(0.07),
      );
}

class _SourceRow extends StatelessWidget {
  final String url;
  final bool isDark;

  const _SourceRow({required this.url, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: () => launchUrl(Uri.parse(url)),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.04)
                : Colors.black.withOpacity(0.03),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.07)
                  : Colors.black.withOpacity(0.07),
            ),
          ),
          child: Row(children: [
            const Icon(Icons.open_in_new_rounded,
                size: 11, color: _Palette.blue),
            const SizedBox(width: 7),
            Expanded(
              child: Text(url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 10.5, color: _Palette.blue)),
            ),
          ]),
        ),
      ),
    );
  }
}
