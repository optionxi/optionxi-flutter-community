// lib/pages/Community/community_home_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:optionxi/Main_Pages/AlgoDeploy/algo_page.dart';
import 'package:optionxi/Main_Pages/Community/dm_community_model.dart';
import 'package:optionxi/Main_Pages/Community/fastapi_discourse_service.dart';
import 'package:optionxi/Main_Pages/Community/loading_widget_community.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'topic_detail_page.dart';
import 'create_topic_page.dart';

// ─── Theme Token Helpers ───────────────────────────────────────────────────────
class _DarkTokens {
  static const bg = Color(0xFF0A0A0F);
  static const surface = Color(0xFF12121A);
  static const card = Color(0xFF1A1A26);
  static const border = Color(0xFF2A2A3A);
  static const text = Color(0xFFEEEEF5);
  static const muted = Color(0xFF8888AA);
}

class _LightTokens {
  static const bg = Color(0xFFF4F4FA);
  static const surface = Color(0xFFFFFFFF);
  static const card = Color(0xFFFFFFFF);
  static const border = Color(0xFFE0E0EE);
  static const text = Color(0xFF0F0F1A);
  static const muted = Color(0xFF7777AA);
}

const _kAccent = Color(0xFF6C63FF);
const _kAccent2 = Color(0xFF00D4AA);

// ─── Page ──────────────────────────────────────────────────────────────────────
class CommunityHomePage extends StatefulWidget {
  const CommunityHomePage({super.key});

  @override
  State<CommunityHomePage> createState() => _CommunityHomePageState();
}

class _CommunityHomePageState extends State<CommunityHomePage>
    with TickerProviderStateMixin {
  List<Topic> _topics = [];
  List<Category> _categories = [];
  Category? _selectedCategory;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasError = false;
  int _page = 0;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _fabAnim;

  @override
  void initState() {
    super.initState();
    _fabAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scrollController.addListener(_onScroll);
    _init();
  }

  Future<void> _init() async {
    await Future.wait([_loadCategories(), _loadTopics(refresh: true)]);
    _fabAnim.forward();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await CommunityService.getCategories();
      if (mounted) setState(() => _categories = cats);
    } catch (_) {}
  }

  Future<void> _loadTopics({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _loading = true;
        _hasError = false;
        _page = 0;
        _hasMore = true;
      });
    }
    try {
      final topics = await CommunityService.getTopics(
        page: refresh ? 0 : _page,
        categoryId: _selectedCategory?.id,
      );
      if (mounted) {
        setState(() {
          if (refresh) {
            _topics = topics;
          } else {
            _topics.addAll(topics);
          }
          _page++;
          _hasMore = topics.length >= 30;
          _loading = false;
          _loadingMore = false;
          _hasError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
          _hasError = refresh && _topics.isEmpty;
        });
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_loadingMore &&
        _hasMore) {
      setState(() => _loadingMore = true);
      _loadTopics();
    }
  }

  void _selectCategory(Category? cat) {
    setState(() => _selectedCategory = cat);
    _loadTopics(refresh: true);
  }

  Color _categoryColor(String hex) {
    try {
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return _kAccent;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _fabAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeController.instance;
    final isDark = themeController.isDarkMode;
    final bg = isDark ? _DarkTokens.bg : _LightTokens.bg;
    final card = isDark ? _DarkTokens.card : _LightTokens.card;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: bg,
        body: RefreshIndicator(
          color: _kAccent,
          backgroundColor: card,
          onRefresh: () => _loadTopics(refresh: true),
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(isDark),
              _buildSearchBar(isDark),
              _buildCategoryChips(isDark),
              _buildTopicsHeader(isDark),
              if (_loading)
                _buildShimmerList(isDark)
              else if (_hasError)
                _buildErrorState(isDark)
              else if (_topics.isEmpty)
                _buildEmpty(isDark)
              else
                _buildTopicsList(isDark),
              if (_loadingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _kAccent,
                        ),
                      ),
                    ),
                  ),
                ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          ),
        ),
        floatingActionButton: _buildFAB(),
      ),
    );
  }

  // ─── App Bar ─────────────────────────────────────────────────────────────────
  // Uses a plain SliverAppBar (no FlexibleSpaceBar) so the title never clips
  // or overflows during the expand/collapse animation.
  Widget _buildAppBar(bool isDark) {
    final bg = isDark ? _DarkTokens.bg : _LightTokens.bg;
    final text = isDark ? _DarkTokens.text : _LightTokens.text;
    final muted = isDark ? _DarkTokens.muted : _LightTokens.muted;

    return SliverAppBar(
      pinned: true,
      floating: false,
      backgroundColor: bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 0,
      toolbarHeight: 56,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Text(
              'Community',
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 22,
                color: text,
                fontWeight: FontWeight.w400,
                height: 1,
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.notifications_outlined, color: muted, size: 22),
          onPressed: () {},
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ─── Search Bar ───────────────────────────────────────────────────────────────
  Widget _buildSearchBar(bool isDark) {
    final surface = isDark ? _DarkTokens.surface : _LightTokens.surface;
    final border = isDark ? _DarkTokens.border : _LightTokens.border;
    final text = isDark ? _DarkTokens.text : _LightTokens.text;
    final muted = isDark ? _DarkTokens.muted : _LightTokens.muted;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
          ),
          child: TextField(
            controller: _searchController,
            style: GoogleFonts.dmSans(color: text, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search topics…',
              hintStyle: GoogleFonts.dmSans(color: muted, fontSize: 14),
              prefixIcon: Icon(Icons.search, color: muted, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onSubmitted: (q) {
              if (q.trim().isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        _SearchPage(query: q.trim(), isDark: isDark),
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  // ─── Category Chips ───────────────────────────────────────────────────────────
  Widget _buildCategoryChips(bool isDark) => SliverToBoxAdapter(
        child: SizedBox(
          height: 56,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            scrollDirection: Axis.horizontal,
            children: [
              _CategoryChip(
                label: 'All',
                selected: _selectedCategory == null,
                color: _kAccent,
                isDark: isDark,
                onTap: () => _selectCategory(null),
              ),
              ..._categories.map((cat) => _CategoryChip(
                    label: cat.name,
                    selected: _selectedCategory?.id == cat.id,
                    color: _categoryColor(cat.color),
                    isDark: isDark,
                    onTap: () => _selectCategory(cat),
                  )),
            ],
          ),
        ),
      );

  // ─── Topics Header ────────────────────────────────────────────────────────────
  Widget _buildTopicsHeader(bool isDark) {
    final muted = isDark ? _DarkTokens.muted : _LightTokens.muted;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
        child: Row(
          children: [
            Text(
              _selectedCategory == null ? 'Latest' : _selectedCategory!.name,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: muted,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (!_loading && !_hasError) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _kAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_topics.length}',
                  style: GoogleFonts.spaceMono(
                    fontSize: 11,
                    color: _kAccent,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Shimmer List ─────────────────────────────────────────────────────────────
  Widget _buildShimmerList(bool isDark) => SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, __) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: TopicCardShimmer(isDark: isDark),
          ),
          childCount: 6,
        ),
      );

  // ─── Error State ──────────────────────────────────────────────────────────────
  Widget _buildErrorState(bool isDark) {
    final muted = isDark ? _DarkTokens.muted : _LightTokens.muted;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded,
                size: 56, color: muted.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(
              'Could not load topics',
              style: GoogleFonts.dmSerifDisplay(color: muted, fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              'Check your connection and try again',
              style: GoogleFonts.dmSans(color: muted, fontSize: 14),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => _loadTopics(refresh: true),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_kAccent, Color(0xFF9C88FF)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Retry',
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
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

  // ─── Empty State ──────────────────────────────────────────────────────────────
  Widget _buildEmpty(bool isDark) {
    final muted = isDark ? _DarkTokens.muted : _LightTokens.muted;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.forum_outlined, size: 56, color: muted.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(
              'No topics yet',
              style: GoogleFonts.dmSerifDisplay(color: muted, fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to start a conversation',
              style: GoogleFonts.dmSans(color: muted, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Topics List ──────────────────────────────────────────────────────────────
  Widget _buildTopicsList(bool isDark) => SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: _TopicCard(
              topic: _topics[index],
              categoryColor: _topics[index].categoryId != null
                  ? _categoryColor(
                      _categories
                          .firstWhere(
                            (c) => c.id == _topics[index].categoryId,
                            orElse: () => Category(
                              id: 0,
                              name: '',
                              slug: '',
                              color: '6C63FF',
                              description: '',
                              topicCount: 0,
                              postCount: 0,
                            ),
                          )
                          .color,
                    )
                  : _kAccent,
              isDark: isDark,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TopicDetailPage(topic: _topics[index]),
                  ),
                );
              },
            ),
          ),
          childCount: _topics.length,
        ),
      );

  // ─── FAB ──────────────────────────────────────────────────────────────────────
  Widget _buildFAB() => ScaleTransition(
        scale: CurvedAnimation(parent: _fabAnim, curve: Curves.elasticOut),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CreateTopicPage(categories: _categories),
              ),
            ).then((_) => _loadTopics(refresh: true));
          },
          backgroundColor: _kAccent,
          icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.white),
          label: Text(
            'New Topic',
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
}

// ─── Topic Card ────────────────────────────────────────────────────────────────
class _TopicCard extends StatelessWidget {
  final Topic topic;
  final Color categoryColor;
  final VoidCallback onTap;
  final bool isDark;

  const _TopicCard({
    required this.topic,
    required this.categoryColor,
    required this.onTap,
    required this.isDark,
  });

  String _timeAgo(String? iso) {
    if (iso == null) return '';
    try {
      return timeago.format(DateTime.parse(iso));
    } catch (_) {
      return '';
    }
  }

  /// Returns a fully-qualified avatar URL.
  /// Discourse avatar templates are relative paths like:
  ///   /user_avatar/forum.example.com/alice/{size}/42.png
  /// We must prepend the Discourse base URL for relative paths.
  String _avatarUrl(String template) {
    if (template.isEmpty) return '';
    final sized = template.replaceAll('{size}', '80');
    if (sized.startsWith('http://') || sized.startsWith('https://')) {
      return sized;
    }
    return '${CommunityService.discourseBaseUrl}$sized';
  }

  /// Strips Discourse emoji shortcodes like :wave: from text
  String _cleanText(String raw) {
    return raw.replaceAllMapped(
      RegExp(r':[a-zA-Z0-9_+-]+:'),
      (m) {
        const map = {
          ':wave:': '\u{1F44B}',
          ':tada:': '\u{1F389}',
          ':rocket:': '\u{1F680}',
          ':fire:': '\u{1F525}',
          ':+1:': '\u{1F44D}',
          ':thumbsup:': '\u{1F44D}',
          ':heart:': '\u2764\uFE0F',
          ':star:': '\u2B50',
          ':bulb:': '\u{1F4A1}',
          ':warning:': '\u26A0\uFE0F',
          ':white_check_mark:': '\u2705',
          ':x:': '\u274C',
          ':eyes:': '\u{1F440}',
          ':sunglasses:': '\u{1F60E}',
          ':chart_with_upwards_trend:': '\u{1F4C8}',
          ':moneybag:': '\u{1F4B0}',
          ':bar_chart:': '\u{1F4CA}',
        };
        return map[m.group(0)] ?? '';
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final card = isDark ? _DarkTokens.card : _LightTokens.card;
    final border = isDark ? _DarkTokens.border : _LightTokens.border;
    final text = isDark ? _DarkTokens.text : _LightTokens.text;
    final muted = isDark ? _DarkTokens.muted : _LightTokens.muted;
    final avatarUrl = _avatarUrl(topic.opAvatarTemplate);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            splashColor: _kAccent.withOpacity(0.08),
            highlightColor: _kAccent.withOpacity(0.04),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header row: avatar + username + badge ──
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: categoryColor.withOpacity(0.2),
                        backgroundImage: avatarUrl.isNotEmpty
                            ? NetworkImage(avatarUrl)
                            : null,
                        onBackgroundImageError:
                            avatarUrl.isNotEmpty ? (_, __) {} : null,
                        child: avatarUrl.isEmpty
                            ? Text(
                                topic.opUsername.isNotEmpty
                                    ? topic.opUsername[0].toUpperCase()
                                    : '?',
                                style: GoogleFonts.dmSans(
                                  color: categoryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              topic.opUsername,
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                color: text,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _timeAgo(topic.lastPostedAt ?? topic.createdAt),
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Pinned badge
                      if (topic.pinned)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _kAccent2.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'PINNED',
                            style: GoogleFonts.spaceMono(
                              fontSize: 9,
                              color: _kAccent2,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      // Closed badge
                      if (topic.closed)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: muted.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'CLOSED',
                            style: GoogleFonts.spaceMono(
                              fontSize: 9,
                              color: muted,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // ── Title ──
                  Text(
                    _cleanText(topic.title),
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      color: text,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // ── Excerpt ──
                  if (topic.excerpt.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      _cleanText(topic.excerpt),
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: muted,
                        height: 1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 14),
                  // ── Stats row ──
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: categoryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      _Stat(
                        icon: Icons.chat_bubble_outline,
                        value: topic.postsCount,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 12),
                      _Stat(
                        icon: Icons.remove_red_eye_outlined,
                        value: topic.views,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 12),
                      _Stat(
                        icon: Icons.favorite_border,
                        value: topic.likeCount,
                        isDark: isDark,
                      ),
                    ],
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

// ─── Stat Widget ───────────────────────────────────────────────────────────────
class _Stat extends StatelessWidget {
  final IconData icon;
  final int value;
  final bool isDark;
  const _Stat({
    required this.icon,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final muted = isDark ? _DarkTokens.muted : _LightTokens.muted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: muted),
        const SizedBox(width: 4),
        Text(
          _format(value),
          style: GoogleFonts.spaceMono(fontSize: 11, color: muted),
        ),
      ],
    );
  }

  String _format(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}

// ─── Category Chip ─────────────────────────────────────────────────────────────
class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final unselectedBg = isDark ? _DarkTokens.card : _LightTokens.surface;
    final unselectedBorder = isDark ? _DarkTokens.border : _LightTokens.border;
    final unselectedText = isDark ? _DarkTokens.muted : _LightTokens.muted;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.2) : unselectedBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : unselectedBorder,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            color: selected ? color : unselectedText,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ─── Search Page ───────────────────────────────────────────────────────────────
class _SearchPage extends StatefulWidget {
  final String query;
  final bool isDark;
  const _SearchPage({required this.query, required this.isDark});

  @override
  State<_SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<_SearchPage> {
  bool _loading = true;
  bool _hasError = false;
  List<dynamic> _results = [];

  @override
  void initState() {
    super.initState();
    _search();
  }

  Future<void> _search() async {
    setState(() {
      _loading = true;
      _hasError = false;
    });
    try {
      final res = await CommunityService.search(widget.query);
      setState(() {
        _results = res['topics'] as List? ?? [];
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bg = isDark ? _DarkTokens.bg : _LightTokens.bg;
    final card = isDark ? _DarkTokens.card : _LightTokens.card;
    final border = isDark ? _DarkTokens.border : _LightTokens.border;
    final text = isDark ? _DarkTokens.text : _LightTokens.text;
    final muted = isDark ? _DarkTokens.muted : _LightTokens.muted;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          '\u201C${widget.query}\u201D',
          style: GoogleFonts.dmSans(color: text, fontSize: 16),
        ),
        iconTheme: IconThemeData(color: muted),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: _kAccent),
            )
          : _hasError
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wifi_off_rounded,
                          size: 48, color: muted.withOpacity(0.4)),
                      const SizedBox(height: 12),
                      Text('Search failed',
                          style: GoogleFonts.dmSans(color: muted)),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _search,
                        child: Text('Retry',
                            style: GoogleFonts.dmSans(color: _kAccent)),
                      ),
                    ],
                  ),
                )
              : _results.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off,
                              size: 48, color: muted.withOpacity(0.4)),
                          const SizedBox(height: 12),
                          Text('No results found',
                              style: GoogleFonts.dmSans(color: muted)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _results.length,
                      itemBuilder: (_, i) {
                        final t = _results[i] as Map<String, dynamic>;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t['title'] as String? ?? '',
                                style: GoogleFonts.dmSans(
                                  color: text,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (t['excerpt'] != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  t['excerpt'] as String,
                                  style: GoogleFonts.dmSans(
                                    color: muted,
                                    fontSize: 13,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}
