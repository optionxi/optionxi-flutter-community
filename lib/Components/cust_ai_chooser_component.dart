// ─────────────────────────────────────────────────────────────
//  AI Action Sheet  (redesigned)
//
//  Step 1: Two choices — "Chat with AI" or "Analyse a Stock"
//  Step 2: (Analyse path) inline Meilisearch → pick stock → navigate
//
//  Usage:
//    showAIActionSheet(
//      context,
//      onChat: () => Navigator.push(context, MaterialPageRoute(
//        builder: (_) => ChatScreen(),
//      )),
//      onAnalyse: (symbol) => Navigator.push(context, MaterialPageRoute(
//        builder: (_) => StockAiAnalysisPage(symbol: symbol),
//      )),
//    );
// ─────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:meilisearch/meilisearch.dart' as meili;
import 'package:optionxi/Helpers/constants.dart';
import 'package:optionxi/Main_Pages/AISummary/act_nifty_ai_summary.dart';

// ─── Theme tokens ─────────────────────────────────────────────
class _T {
  static bool dark(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark;

  static Color card(BuildContext ctx) =>
      dark(ctx) ? const Color(0xFF13161F) : Colors.white;

  static Color cardAlt(BuildContext ctx) =>
      dark(ctx) ? const Color(0xFF1C2030) : const Color(0xFFF4F6FC);

  static Color border(BuildContext ctx) =>
      dark(ctx) ? const Color(0xFF252B3D) : const Color(0xFFE4E7F0);

  static Color textPrimary(BuildContext ctx) =>
      dark(ctx) ? const Color(0xFFF0F2FF) : const Color(0xFF141622);

  static Color textSecondary(BuildContext ctx) =>
      dark(ctx) ? const Color(0xFF7B85A3) : const Color(0xFF6B7490);

  static Color textMuted(BuildContext ctx) =>
      dark(ctx) ? const Color(0xFF3D4460) : const Color(0xFFB0B7CC);

  static Color bullBg(BuildContext ctx) =>
      dark(ctx) ? const Color(0x1400C896) : const Color(0xFFE6FBF5);

  static Color bearBg(BuildContext ctx) =>
      dark(ctx) ? const Color(0x14EF4565) : const Color(0xFFFEECEF);

  static const accent = Color(0xFF3B72F6);
  static const bull = Color(0xFF00C896);
  static const bear = Color(0xFFEF4565);

  // AI gradient colours
  static const aiStart = Color(0xFF7C3AED);
  static const aiEnd = Color(0xFFDB2777);
}

// ─────────────────────────────────────────────────────────────
//  Public entry point
// ─────────────────────────────────────────────────────────────
void showAIActionSheet(
  BuildContext context, {
  required VoidCallback onChat,
  required void Function(String symbol) onAnalyse,
  bool startOnSearch = false, // ← simple public bool instead of _Step
}) {
  HapticFeedback.mediumImpact();
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _AIActionSheet(
      onChat: onChat, onAnalyse: onAnalyse,
      initialStep:
          startOnSearch ? _Step.search : _Step.choose, // ← convert internally
    ),
  );
}

// ─────────────────────────────────────────────────────────────
//  Sheet widget
// ─────────────────────────────────────────────────────────────
enum _Step { choose, search }

class _AIActionSheet extends StatefulWidget {
  final VoidCallback onChat;
  final void Function(String symbol) onAnalyse;
  final _Step initialStep; // ← add

  const _AIActionSheet({
    required this.onChat,
    required this.onAnalyse,
    this.initialStep = _Step.choose,
  });

  @override
  State<_AIActionSheet> createState() => _AIActionSheetState();
}

class _AIActionSheetState extends State<_AIActionSheet> {
  // _Step _step = _Step.choose;
  late _Step _step = widget.initialStep; // ← was: _Step _step = _Step.choose;

  late final meili.MeiliSearchClient _client;
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  List<Map<String, dynamic>> _results = [];
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _client = meili.MeiliSearchClient(
      dotenv.env['MELIESEARCH_URL']!,
      dotenv.env['MELIE_API_KEY']!,
    );
    _ctrl.addListener(() => setState(() {})); // rebuild for clear button
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  String _clean(Map<String, dynamic> s) => (s['symbol'] ?? '')
      .toString()
      .replaceAll('NSE:', '')
      .replaceAll('-EQ', '')
      .replaceAll('-BE', '')
      .replaceAll('-BZ', '')
      .trim();

  void _onQuery(String q) {
    _debounce?.cancel();
    if (q.isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    _debounce = Timer(const Duration(milliseconds: 280), () async {
      try {
        final res = await _client.index('stocks').search(
              q,
              meili.SearchQuery(filter: 'type = "stock"', hitsPerPage: 12),
            );
        final hits = res.hits.cast<Map<String, dynamic>>();
        final ql = q.toLowerCase();
        hits.sort((a, b) {
          final an = _clean(a).toLowerCase();
          final bn = _clean(b).toLowerCase();
          if (an == ql && bn != ql) return -1;
          if (bn == ql && an != ql) return 1;
          if (an.startsWith(ql) && !bn.startsWith(ql)) return -1;
          if (bn.startsWith(ql) && !an.startsWith(ql)) return 1;
          return 0;
        });
        if (mounted)
          setState(() {
            _results = hits;
            _isSearching = false;
          });
      } catch (_) {
        if (mounted) setState(() => _isSearching = false);
      }
    });
  }

  void _pickStock(Map<String, dynamic> stock) {
    final symbol = (stock['symbol'] as String?) ?? 'NSE:${_clean(stock)}-EQ';
    Navigator.pop(context);
    widget.onAnalyse(symbol);
  }

  void _goSearch() {
    HapticFeedback.selectionClick();
    setState(() => _step = _Step.search);
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _focus.requestFocus();
    });
  }

  void _goNifty() {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NiftyAiSummaryPage(),
        ));
  }

  void _goBack() {
    HapticFeedback.selectionClick();
    _ctrl.clear();
    _focus.unfocus();
    setState(() {
      _step = _Step.choose;
      _results = [];
      _isSearching = false;
    });
  }

  // ─────────────────────────────────────────────────────────────
  //  Root build
  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: _T.card(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: _T.border(context)),
            left: BorderSide(color: _T.border(context)),
            right: BorderSide(color: _T.border(context)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 32,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            ),
            child: _step == _Step.choose ? _buildChoose() : _buildSearch(),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Step 1 — Choose action
  // ─────────────────────────────────────────────────────────────
  Widget _buildChoose() {
    return Padding(
      key: const ValueKey('choose'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Handle(),
          const SizedBox(height: 24),

          // ── Header
          _ChooseHeader(),
          const SizedBox(height: 6),

          // ── Fade divider
          _FadeDivider(),
          const SizedBox(height: 20),

          // ── Option: Chat
          _ChoiceTile(
            onTap: () {
              Navigator.pop(context);
              widget.onChat();
            },
            icon: Icons.chat_bubble_rounded,
            iconColor: _T.accent,
            iconBg: _T.accent.withOpacity(0.12),
            gradientColors: [_T.accent.withOpacity(0.07), Colors.transparent],
            label: 'Chat with AI',
            sub: 'Ask about markets, strategy & ideas',
          ),
          const SizedBox(height: 10),

          // ── Option: Analyse
          _ChoiceTile(
            onTap: _goSearch,
            icon: Icons.candlestick_chart_rounded,
            iconColor: _T.bull,
            iconBg: _T.bullBg(context),
            gradientColors: [_T.bull.withOpacity(0.06), Colors.transparent],
            label: 'Analyse a Stock',
            sub: 'Search any NSE stock for AI insights',
            trailingIcon: Icons.search_rounded,
            badge: 'Beta',
          ),
          const SizedBox(height: 8),
          // ── Option: Analyse
          _ChoiceTile(
            onTap: _goNifty,
            icon: Icons.add_chart,
            iconColor: _T.aiStart,
            iconBg: _T.bullBg(context),
            gradientColors: [_T.bull.withOpacity(0.06), Colors.transparent],
            label: 'Analyse Nifty',
            sub: 'Get Insights into Nifty',
            trailingIcon: Icons.search_rounded,
            badge: 'Beta',
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Step 2 — Stock search
  // ─────────────────────────────────────────────────────────────
  Widget _buildSearch() {
    return Column(
      key: const ValueKey('search'),
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Top bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            children: [
              _Handle(),
              const SizedBox(height: 16),

              // Title row
              Row(
                children: [
                  _BackButton(onTap: _goBack),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Analyse a Stock',
                          style: TextStyle(
                            color: _T.textPrimary(context),
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Search any NSE listed company',
                          style: TextStyle(
                            color: _T.textSecondary(context),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Search field
              _SearchField(
                ctrl: _ctrl,
                focus: _focus,
                onChanged: _onQuery,
                onClear: () {
                  _ctrl.clear();
                  _onQuery('');
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),

        Divider(height: 1, color: _T.border(context)),
        _buildResultsArea(),
      ],
    );
  }

  // ── Results body ───────────────────────────────────────────
  Widget _buildResultsArea() {
    if (_ctrl.text.isEmpty) {
      return _EmptyPrompt(
        icon: Icons.candlestick_chart_rounded,
        title: 'Search for a stock',
        sub: 'Type a symbol or company name above',
      );
    }

    if (_isSearching) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 44),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _T.accent,
            ),
          ),
        ),
      );
    }

    if (_results.isEmpty) {
      return _EmptyPrompt(
        icon: Icons.search_off_rounded,
        title: 'No results found',
        sub: 'Try a different symbol or name',
      );
    }

    final mq = MediaQuery.of(context);
    final listHeight = (mq.size.height * 0.92 - mq.viewInsets.bottom - 160)
        .clamp(80.0, mq.size.height * 0.55);

    return SizedBox(
      height: listHeight,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 6),
        itemCount: _results.length,
        separatorBuilder: (_, __) => Divider(
            height: 1, indent: 70, endIndent: 16, color: _T.border(context)),
        itemBuilder: (_, i) => _StockTile(
          stock: _results[i],
          cleanSymbol: _clean(_results[i]),
          onTap: () => _pickStock(_results[i]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Search step sub-widgets (all stateless)
// ─────────────────────────────────────────────────────────────

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: _T.cardAlt(context),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: _T.border(context)),
        ),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 13,
          color: _T.textPrimary(context),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController ctrl;
  final FocusNode focus;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchField({
    required this.ctrl,
    required this.focus,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: focus,
      builder: (ctx, _) => AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 48,
        decoration: BoxDecoration(
          color: _T.cardAlt(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: focus.hasFocus
                ? _T.accent.withOpacity(0.5)
                : _T.border(context),
            width: 1.5,
          ),
          boxShadow: focus.hasFocus
              ? [BoxShadow(color: _T.accent.withOpacity(0.08), blurRadius: 12)]
              : [],
        ),
        child: TextField(
          controller: ctrl,
          focusNode: focus,
          onChanged: onChanged,
          style: TextStyle(
            color: _T.textPrimary(context),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: 'Search stocks, e.g. HDFC, RELIANCE…',
            hintStyle: TextStyle(color: _T.textMuted(context), fontSize: 13),
            prefixIcon: Icon(Icons.search_rounded,
                size: 20, color: _T.textSecondary(context)),
            suffixIcon: ctrl.text.isNotEmpty
                ? GestureDetector(
                    onTap: onClear,
                    child: Icon(Icons.close_rounded,
                        size: 16, color: _T.textSecondary(context)),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }
}

class _EmptyPrompt extends StatelessWidget {
  final IconData icon;
  final String title;
  final String sub;

  const _EmptyPrompt({
    required this.icon,
    required this.title,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 44),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _T.cardAlt(context),
              shape: BoxShape.circle,
              border: Border.all(color: _T.border(context)),
            ),
            child: Icon(icon, size: 24, color: _T.textMuted(context)),
          ),
          const SizedBox(height: 12),
          Text(title,
              style: TextStyle(
                  color: _T.textSecondary(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(sub,
              style: TextStyle(color: _T.textMuted(context), fontSize: 12)),
        ],
      ),
    );
  }
}

class _StockTile extends StatefulWidget {
  final Map<String, dynamic> stock;
  final String cleanSymbol;
  final VoidCallback onTap;

  const _StockTile({
    required this.stock,
    required this.cleanSymbol,
    required this.onTap,
  });

  @override
  State<_StockTile> createState() => _StockTileState();
}

class _StockTileState extends State<_StockTile> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final ltp = widget.stock['ltp']?.toDouble() ?? 0.0;
    final pct = widget.stock['percent_change']?.toDouble() ?? 0.0;
    final isPos = pct >= 0;
    final pctColor = isPos ? _T.bull : _T.bear;

    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) {
        setState(() => _down = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _down = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: _down ? _T.cardAlt(context) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            // ── Logo
            _StockLogo(symbol: widget.cleanSymbol),
            const SizedBox(width: 12),

            // ── Name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.cleanSymbol,
                    style: TextStyle(
                      color: _T.textPrimary(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.stock['name'] ?? '',
                    style:
                        TextStyle(color: _T.textMuted(context), fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // ── Price + change
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${ltp.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: _T.textPrimary(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                _PctBadge(
                    pct: pct,
                    color: pctColor,
                    bgColor: isPos ? _T.bullBg(context) : _T.bearBg(context)),
              ],
            ),
            const SizedBox(width: 10),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 12, color: _T.textMuted(context)),
          ],
        ),
      ),
    );
  }
}

class _StockLogo extends StatelessWidget {
  final String symbol;
  const _StockLogo({required this.symbol});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _T.cardAlt(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _T.border(context)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: CachedNetworkImage(
          imageUrl: '${Constants.OptionXiS3Loc}$symbol.png',
          fit: BoxFit.cover,
          placeholder: (_, __) => _LogoFallback(symbol: symbol),
          errorWidget: (_, __, ___) => _LogoFallback(symbol: symbol),
        ),
      ),
    );
  }
}

class _LogoFallback extends StatelessWidget {
  final String symbol;
  const _LogoFallback({required this.symbol});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        symbol.isNotEmpty ? symbol[0] : '?',
        style: const TextStyle(
          color: _T.accent,
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _PctBadge extends StatelessWidget {
  final double pct;
  final Color color;
  final Color bgColor;
  const _PctBadge(
      {required this.pct, required this.color, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(2)}%',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Choose step sub-widgets (all stateless)
// ─────────────────────────────────────────────────────────────

class _ChooseHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _AiBadge(),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [_T.aiStart, _T.aiEnd],
                ).createShader(bounds),
                child: const Text(
                  'AI Analyse',
                  style: TextStyle(
                    color: Colors.white, // masked by shader
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.7,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Builder(
                builder: (ctx) => Text(
                  'What would you like to do?',
                  style: TextStyle(
                    color: _T.textSecondary(ctx),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FadeDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              _T.border(context).withOpacity(0.7),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Choice tile
// ─────────────────────────────────────────────────────────────
class _ChoiceTile extends StatefulWidget {
  final VoidCallback onTap;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final List<Color> gradientColors;
  final String label;
  final String sub;
  final IconData? trailingIcon;
  final String? badge;

  const _ChoiceTile({
    required this.onTap,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.gradientColors,
    required this.label,
    required this.sub,
    this.trailingIcon,
    this.badge,
  });

  @override
  State<_ChoiceTile> createState() => _ChoiceTileState();
}

class _ChoiceTileState extends State<_ChoiceTile> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) {
        setState(() => _down = false);
        HapticFeedback.mediumImpact();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.968 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _down
                  ? [
                      widget.iconColor.withOpacity(0.14),
                      widget.iconColor.withOpacity(0.04),
                    ]
                  : widget.gradientColors,
            ),
            border: Border.all(
              color: _down
                  ? widget.iconColor.withOpacity(0.45)
                  : _T.border(context),
              width: 1.5,
            ),
            boxShadow: _down
                ? [
                    BoxShadow(
                      color: widget.iconColor.withOpacity(0.14),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          child: Row(
            children: [
              _TileIcon(
                icon: widget.icon,
                iconColor: widget.iconColor,
                iconBg: widget.iconBg,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _TileText(
                  label: widget.label,
                  sub: widget.sub,
                  badge: widget.badge,
                  accentColor: widget.iconColor,
                ),
              ),
              _TileTrailing(
                icon: widget.trailingIcon ?? Icons.arrow_forward_ios_rounded,
                isSearch: widget.trailingIcon != null,
                pressed: _down,
                accentColor: widget.iconColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TileIcon extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  const _TileIcon({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: iconBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.22),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: iconColor, size: 22),
    );
  }
}

class _TileText extends StatelessWidget {
  final String label;
  final String sub;
  final String? badge;
  final Color accentColor;

  const _TileText({
    required this.label,
    required this.sub,
    required this.accentColor,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: _T.textPrimary(context),
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 8),
              _BadgePill(label: badge!, color: accentColor),
            ],
          ],
        ),
        const SizedBox(height: 3),
        Text(
          sub,
          style: TextStyle(
            color: _T.textSecondary(context),
            fontSize: 12,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }
}

class _TileTrailing extends StatelessWidget {
  final IconData icon;
  final bool isSearch;
  final bool pressed;
  final Color accentColor;

  const _TileTrailing({
    required this.icon,
    required this.isSearch,
    required this.pressed,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: pressed
            ? accentColor.withOpacity(0.12)
            : _T.border(context).withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        size: isSearch ? 16 : 11,
        color: pressed ? accentColor : _T.textMuted(context),
      ),
    );
  }
}

class _BadgePill extends StatelessWidget {
  final String label;
  final Color color;
  const _BadgePill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.13),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Shared micro-widgets
// ─────────────────────────────────────────────────────────────

class _Handle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 3.5,
        decoration: BoxDecoration(
          color: _T.border(context),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _AiBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_T.aiStart, _T.aiEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _T.aiStart.withOpacity(0.32),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Center(
        child: Text('✦', style: TextStyle(color: Colors.white, fontSize: 20)),
      ),
    );
  }
}
