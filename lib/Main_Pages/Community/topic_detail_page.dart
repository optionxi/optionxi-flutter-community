// lib/pages/Community/topic_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:optionxi/Main_Pages/AlgoDeploy/algo_page.dart';
import 'package:optionxi/Main_Pages/Community/dm_community_model.dart';
import 'package:optionxi/Main_Pages/Community/fastapi_discourse_service.dart';
import 'package:optionxi/Main_Pages/Community/loading_widget_community.dart';
import 'package:timeago/timeago.dart' as timeago;

// ─── Theme Token Helpers ───────────────────────────────────────────────────────
class _DT {
  static const bg = Color(0xFF0A0A0F);
  static const surface = Color(0xFF12121A);
  static const card = Color(0xFF1A1A26);
  static const border = Color(0xFF2A2A3A);
  static const text = Color(0xFFEEEEF5);
  static const muted = Color(0xFF8888AA);
}

class _LT {
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
class TopicDetailPage extends StatefulWidget {
  final Topic topic;
  const TopicDetailPage({super.key, required this.topic});

  @override
  State<TopicDetailPage> createState() => _TopicDetailPageState();
}

class _TopicDetailPageState extends State<TopicDetailPage>
    with TickerProviderStateMixin {
  TopicDetail? _detail;
  bool _loading = true;
  bool _hasError = false;
  bool _sending = false;
  Post? _replyingTo;
  final TextEditingController _messageCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _focusNode = FocusNode();
  late AnimationController _inputAnim;

  bool get _isDark => ThemeController.instance.isDarkMode;

  Color get _bg => _isDark ? _DT.bg : _LT.bg;
  Color get _surface => _isDark ? _DT.surface : _LT.surface;
  Color get _card => _isDark ? _DT.card : _LT.card;
  Color get _border => _isDark ? _DT.border : _LT.border;
  Color get _text => _isDark ? _DT.text : _LT.text;
  Color get _muted => _isDark ? _DT.muted : _LT.muted;

  @override
  void initState() {
    super.initState();
    _inputAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadTopic();
  }

  Future<void> _loadTopic() async {
    setState(() {
      _loading = true;
      _hasError = false;
    });
    try {
      final detail = await CommunityService.getTopicDetail(widget.topic.id);
      if (mounted) {
        setState(() {
          _detail = detail;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _hasError = true;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    // Discourse minimum post length is 20 characters
    if (text.length < 20) {
      _showError('Reply must be at least 20 characters.');
      return;
    }

    final raw = _replyingTo != null
        ? '[quote="${_replyingTo!.username}"]\n${_replyingTo!.raw}\n[/quote]\n\n$text'
        : text;

    setState(() => _sending = true);
    try {
      await CommunityService.createPost(
        topicId: widget.topic.id,
        raw: raw,
      );
      _messageCtrl.clear();
      setState(() {
        _replyingTo = null;
        _sending = false;
      });
      await _loadTopic();
      _scrollToBottom();
    } catch (e) {
      setState(() => _sending = false);
      _showError('Failed to send: $e');
    }
  }

  Future<void> _toggleLike(Post post) async {
    final wasLiked = post.isLiked;
    setState(() {
      post.isLiked = !wasLiked;
      // Update count in place (likeCount is mutable on Post)
      if (post.isLiked) {
        post.likeCount++;
      } else if (post.likeCount > 0) {
        post.likeCount--;
      }
    });
    try {
      if (!wasLiked) {
        await CommunityService.likePost(post.id);
      } else {
        await CommunityService.unlikePost(post.id);
      }
    } catch (_) {
      // Revert optimistic update
      setState(() {
        post.isLiked = wasLiked;
        if (wasLiked) {
          post.likeCount++;
        } else if (post.likeCount > 0) {
          post.likeCount--;
        }
      });
    }
  }

  Future<void> _deletePost(Post post) async {
    final confirm = await _showDeleteConfirm();
    if (!confirm) return;
    try {
      await CommunityService.deletePost(post.id);
      await _loadTopic();
    } catch (e) {
      _showError('Failed to delete: $e');
    }
  }

  Future<bool> _showDeleteConfirm() async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: _card,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'Delete Post',
              style:
                  GoogleFonts.dmSans(color: _text, fontWeight: FontWeight.w600),
            ),
            content: Text(
              'This cannot be undone.',
              style: GoogleFonts.dmSans(color: _muted),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Cancel', style: GoogleFonts.dmSans(color: _muted)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Delete',
                    style: GoogleFonts.dmSans(color: Colors.redAccent)),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.dmSans(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// Returns a fully-qualified avatar URL.
  /// Discourse avatar templates may be relative (/user_avatar/...) or absolute.
  String _avatarUrl(String template, {int size = 80}) {
    if (template.isEmpty) return '';
    final sized = template.replaceAll('{size}', '$size');
    if (sized.startsWith('http://') || sized.startsWith('https://')) {
      return sized;
    }
    return '${CommunityService.discourseBaseUrl}$sized';
  }

  String _timeAgo(String? iso) {
    if (iso == null) return '';
    try {
      return timeago.format(DateTime.parse(iso));
    } catch (_) {
      return '';
    }
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    _inputAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _bg,
        body: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: _loading
                  ? _buildShimmer()
                  : _hasError
                      ? _buildError()
                      : _detail == null
                          ? _buildError()
                          : _buildContent(),
            ),
            if (!_loading &&
                !_hasError &&
                _detail != null &&
                !(_detail?.closed ?? false))
              _buildInputBar(),
          ],
        ),
      ),
    );
  }

  // ─── App Bar ─────────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return Container(
      color: _bg,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: _border.withOpacity(0.5)),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_ios_new, size: 18, color: _muted),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text(
                  widget.topic.title,
                  style: GoogleFonts.dmSans(
                    color: _text,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_detail != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 14, color: _muted),
                      const SizedBox(width: 4),
                      Text(
                        '${_detail!.postsCount}',
                        style:
                            GoogleFonts.spaceMono(fontSize: 12, color: _muted),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Shimmer ─────────────────────────────────────────────────────────────────
  Widget _buildShimmer() => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: PostCardShimmer(isDark: _isDark),
        ),
      );

  // ─── Error ───────────────────────────────────────────────────────────────────
  Widget _buildError() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded,
                color: _muted.withOpacity(0.4), size: 56),
            const SizedBox(height: 16),
            Text('Failed to load topic',
                style: GoogleFonts.dmSerifDisplay(color: _muted, fontSize: 20)),
            const SizedBox(height: 8),
            Text('Check your connection and try again',
                style: GoogleFonts.dmSans(color: _muted, fontSize: 14)),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _loadTopic,
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
      );

  // ─── Content ─────────────────────────────────────────────────────────────────
  Widget _buildContent() {
    final posts = _detail!.posts;
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      physics: const BouncingScrollPhysics(),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        final isFirst = index == 0;
        return _PostCard(
          post: post,
          isOP: isFirst,
          topicTitle: isFirst ? _detail!.title : null,
          onLike: () => _toggleLike(post),
          onReply: () {
            setState(() => _replyingTo = post);
            _focusNode.requestFocus();
          },
          onDelete: post.canDelete ? () => _deletePost(post) : null,
          avatarUrl: _avatarUrl(post.avatarTemplate),
          timeAgo: _timeAgo(post.createdAt),
          isDark: _isDark,
        );
      },
    );
  }

  // ─── Input Bar ───────────────────────────────────────────────────────────────
  Widget _buildInputBar() {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reply banner
            if (_replyingTo != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: _kAccent.withOpacity(0.08),
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _kAccent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Replying to @${_replyingTo!.username}',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: _kAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _replyingTo!.raw,
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: _muted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, size: 16, color: _muted),
                      onPressed: () => setState(() => _replyingTo = null),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            // Input row
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      decoration: BoxDecoration(
                        color: _card,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: _border),
                      ),
                      child: TextField(
                        controller: _messageCtrl,
                        focusNode: _focusNode,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        style: GoogleFonts.dmSans(color: _text, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: _replyingTo != null
                              ? 'Write a reply… (min 20 chars)'
                              : 'Write a message… (min 20 chars)',
                          hintStyle:
                              GoogleFonts.dmSans(color: _muted, fontSize: 15),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 12),
                          border: InputBorder.none,
                        ),
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sending ? null : _sendMessage,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_kAccent, Color(0xFF9C88FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(23),
                        boxShadow: [
                          BoxShadow(
                            color: _kAccent.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _sending
                          ? const Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.send_rounded,
                              color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Post Card ─────────────────────────────────────────────────────────────────
class _PostCard extends StatefulWidget {
  final Post post;
  final bool isOP;
  final String? topicTitle;
  final VoidCallback onLike;
  final VoidCallback onReply;
  final VoidCallback? onDelete;
  final String avatarUrl;
  final String timeAgo;
  final bool isDark;

  const _PostCard({
    required this.post,
    required this.isOP,
    this.topicTitle,
    required this.onLike,
    required this.onReply,
    this.onDelete,
    required this.avatarUrl,
    required this.timeAgo,
    required this.isDark,
  });

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _likeAnim;

  Color get _card => widget.isDark ? _DT.card : _LT.card;
  Color get _border => widget.isDark ? _DT.border : _LT.border;
  Color get _text => widget.isDark ? _DT.text : _LT.text;
  Color get _muted => widget.isDark ? _DT.muted : _LT.muted;

  // Discourse base URL from env — used to fix relative image/link URLs
  static final _discourseBase = dotenv.env['DISCOURSE_URL']!;

  @override
  void initState() {
    super.initState();
    _likeAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _likeAnim.dispose();
    super.dispose();
  }

  void _handleLike() {
    _likeAnim.forward(from: 0);
    widget.onLike();
  }

  /// Fixes relative src/href attributes by prepending the Discourse base URL.
  /// Handles both /uploads/... paths and /user_avatar/... paths.
  String _fixRelativeUrls(String html) {
    return html.replaceAllMapped(
      RegExp(r'(src|href)="(\/[^"]*)"'),
      (m) => '${m[1]}="$_discourseBase${m[2]}"',
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isOP ? _kAccent.withOpacity(0.3) : _border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // OP topic title banner
          if (widget.isOP && widget.topicTitle != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _kAccent.withOpacity(0.15),
                    _kAccent2.withOpacity(0.05),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Text(
                widget.topicTitle!,
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 17,
                  color: _text,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),

          // Reply indicator
          if (post.replyToPostNumber != null)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _kAccent.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _kAccent.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.reply, size: 12, color: _kAccent),
                  const SizedBox(width: 4),
                  Text(
                    'Reply to #${post.replyToPostNumber}',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: _kAccent,
                    ),
                  ),
                ],
              ),
            ),

          // Header
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              post.replyToPostNumber != null ? 8 : 14,
              16,
              0,
            ),
            child: Row(
              children: [
                _buildAvatar(post),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            post.displayName.isNotEmpty
                                ? post.displayName
                                : post.username,
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              color: _text,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (widget.isOP) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: _kAccent.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'OP',
                                style: GoogleFonts.spaceMono(
                                  fontSize: 9,
                                  color: _kAccent,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                          if (post.yours) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: _kAccent2.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'YOU',
                                style: GoogleFonts.spaceMono(
                                  fontSize: 9,
                                  color: _kAccent2,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        '@${post.username} · ${widget.timeAgo}',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: _muted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (post.canDelete)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_horiz, color: _muted, size: 18),
                    color: _card,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete_outline,
                                color: Colors.redAccent, size: 16),
                            const SizedBox(width: 8),
                            Text('Delete',
                                style: GoogleFonts.dmSans(
                                    color: Colors.redAccent)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (v) {
                      if (v == 'delete') widget.onDelete?.call();
                    },
                  ),
              ],
            ),
          ),

          // Body (HTML from Discourse)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: post.cooked.isNotEmpty
                ? Html(
                    data: _fixRelativeUrls(post.cooked),
                    style: {
                      "body": Style(
                        color: _text,
                        fontFamily: GoogleFonts.dmSans().fontFamily,
                        fontSize: FontSize(14),
                        lineHeight: LineHeight(1.6),
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                      ),
                      "p": Style(
                        color: _text,
                        margin: Margins.only(bottom: 6),
                      ),
                      "a": Style(color: _kAccent),
                      "blockquote": Style(
                        color: _muted,
                        border: Border(
                          left: BorderSide(
                              color: _kAccent.withOpacity(0.5), width: 3),
                        ),
                        padding: HtmlPaddings.only(left: 12, top: 4, bottom: 4),
                        margin: Margins.only(top: 6, bottom: 6),
                      ),
                      "code": Style(
                        backgroundColor: widget.isDark
                            ? const Color(0xFF0D0D18)
                            : const Color(0xFFF0F0FF),
                        color: _kAccent2,
                        fontFamily: GoogleFonts.spaceMono().fontFamily,
                        fontSize: FontSize(12),
                        padding:
                            HtmlPaddings.symmetric(horizontal: 4, vertical: 2),
                      ),
                      "pre": Style(
                        backgroundColor: widget.isDark
                            ? const Color(0xFF0D0D18)
                            : const Color(0xFFF0F0FF),
                        padding: HtmlPaddings.all(12),
                      ),
                    },
                  )
                : Text(
                    post.raw,
                    style: GoogleFonts.dmSans(
                      color: _text,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Row(
              children: [
                _ActionBtn(
                  icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
                  label: post.likeCount > 0 ? '${post.likeCount}' : '',
                  color: post.isLiked ? Colors.pinkAccent : _muted,
                  onTap: _handleLike,
                ),
                const SizedBox(width: 4),
                _ActionBtn(
                  icon: Icons.reply_outlined,
                  label: 'Reply',
                  color: _muted,
                  onTap: widget.onReply,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(Post post) {
    final initials = post.displayName.isNotEmpty
        ? post.displayName[0].toUpperCase()
        : post.username.isNotEmpty
            ? post.username[0].toUpperCase()
            : '?';
    final url = widget.avatarUrl;

    return CircleAvatar(
      radius: 18,
      backgroundColor: _kAccent.withOpacity(0.2),
      backgroundImage: url.isNotEmpty ? NetworkImage(url) : null,
      onBackgroundImageError: url.isNotEmpty ? (_, __) {} : null,
      child: url.isEmpty
          ? Text(
              initials,
              style: GoogleFonts.dmSans(
                color: _kAccent,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            )
          : null,
    );
  }
}

// ─── Action Button ─────────────────────────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
