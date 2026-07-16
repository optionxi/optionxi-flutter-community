import 'package:flutter/material.dart';
import 'package:optionxi/Main_Pages/ScreenerPro/act_saved_screeners.dart';
import 'package:optionxi/Main_Pages/StockPages/act_setalert_page_all.dart';
import 'package:optionxi/VirtualTradeJournal/act_journal_analytics.dart';

// ─────────────────────────────────────────────
// Data model for a single inner tool
// ─────────────────────────────────────────────
class ToolItem {
  final String label;
  final String sublabel;
  final IconData icon;
  final Color lightColor;
  final Color darkColor;
  final String simpleDescription; // shown by default, plain language
  final List<String> features; // shown only when "Show more" is tapped
  final VoidCallback onOpen;

  ToolItem({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.lightColor,
    required this.darkColor,
    required this.simpleDescription,
    required this.features,
    required this.onOpen,
  });
}

// ─────────────────────────────────────────────
// Main Section Widget — a single homepage card
// ─────────────────────────────────────────────
class StockChipsSectionMyTools extends StatefulWidget {
  const StockChipsSectionMyTools({Key? key}) : super(key: key);

  @override
  State<StockChipsSectionMyTools> createState() =>
      _StockChipsSectionMyToolsState();
}

class _StockChipsSectionMyToolsState extends State<StockChipsSectionMyTools>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late List<ToolItem> _tools;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _buildTools();
  }

  void _buildTools() {
    _tools = [
      ToolItem(
        label: 'My Journal',
        sublabel: 'Track your trades',
        icon: Icons.menu_book_rounded,
        lightColor: const Color(0xFF8B5CF6),
        darkColor: const Color(0xFFC4B5FD),
        simpleDescription:
            "Add your stock trades here — even as practice, with no real money. We'll automatically work out your profit or loss for you.",
        features: const [
          'Add buy/sell trades virtually, no real money needed',
          'Automatic profit & loss (P&L) calculation for every trade',
          'See your overall performance over time',
          "Review past trades to learn what worked and what didn't",
        ],
        onOpen: () =>
            Navigator.push(context, _fadeRoute(JournalAnalyticsPage())),
      ),
      ToolItem(
        label: 'My Screeners',
        sublabel: 'Find stocks your way',
        icon: Icons.tune_rounded,
        lightColor: const Color(0xFF0EA5E9),
        darkColor: const Color(0xFF38BDF8),
        simpleDescription:
            "Set your own rules to find stocks — for example, show me stocks where a short-term trend line has crossed above a long-term one.",
        features: const [
          'Build custom conditions, e.g. EMA4 > EMA20',
          'Combine multiple conditions together, e.g. EMA50 > SMA50',
          'Create and save as many different screeners as you like',
          'Run any of them anytime to instantly see matching stocks',
        ],
        onOpen: () => Navigator.push(context, _fadeRoute(SavedScannersPage())),
      ),
      ToolItem(
        label: 'My Alerts',
        sublabel: 'Never miss a move',
        icon: Icons.notifications_active_rounded,
        lightColor: const Color(0xFFEF4444),
        darkColor: const Color(0xFFF87171),
        simpleDescription:
            "Tell us what you're watching for, like a breakout, and we'll notify you the moment it happens.",
        features: const [
          'Set alerts for stock breakouts or any price level',
          'Get notified the instant your condition is met',
          'See a full history of all the alerts you created',
          'Check whether each alert triggered, and exactly when',
        ],
        onOpen: () => Navigator.push(context, _fadeRoute(MyAlertsPage())),
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  PageRoute _fadeRoute(Widget page) => PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 280),
      );

  void _openToolsSheet(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ToolsBottomSheet(tools: _tools, isDark: isDark),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section header ──────────────────────
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Row(
              children: [
                Text(
                  'MY TOOLS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [Colors.white12, Colors.transparent]
                            : [Colors.black12, Colors.transparent],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Single card, fixed height ───────────
          FadeTransition(
            opacity: _fadeIn,
            child: _SingleToolsCard(
              tools: _tools,
              isDark: isDark,
              onTap: () => _openToolsSheet(isDark),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// One intuitive fixed-height card for the homepage
// Shows a stacked icon cluster + a hint of what's inside
// ─────────────────────────────────────────────
class _SingleToolsCard extends StatelessWidget {
  final List<ToolItem> tools;
  final bool isDark;
  final VoidCallback onTap;

  const _SingleToolsCard({
    required this.tools,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          height: 92,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.black12,
            ),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Row(
            children: [
              // overlapping icon stack — hints "3 things live here"
              SizedBox(
                width: 64,
                height: 64,
                child: Stack(
                  children: [
                    for (int i = 0; i < tools.length; i++)
                      Positioned(
                        left: i * 16.0,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                isDark ? const Color(0xFF1C1C1E) : Colors.white,
                            border: Border.all(
                              color: isDark ? Colors.white12 : Colors.black12,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              tools[i].icon,
                              size: 17,
                              color: isDark
                                  ? tools[i].darkColor
                                  : tools[i].lightColor,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // title + hint text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'My Tools',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Journal · Screeners · Alerts',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white38 : Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? Colors.white38 : Colors.black26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Bottom sheet: lists the 3 tools, each expandable
// ─────────────────────────────────────────────
class _ToolsBottomSheet extends StatefulWidget {
  final List<ToolItem> tools;
  final bool isDark;

  const _ToolsBottomSheet({required this.tools, required this.isDark});

  @override
  State<_ToolsBottomSheet> createState() => _ToolsBottomSheetState();
}

class _ToolsBottomSheetState extends State<_ToolsBottomSheet> {
  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            Text(
              'My Tools',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Tap a tool to open it, or show more to read what it does',
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? Colors.white38 : Colors.black45,
              ),
            ),
            const SizedBox(height: 14),

            for (int i = 0; i < widget.tools.length; i++)
              _ToolRow(
                tool: widget.tools[i],
                isDark: isDark,
                onOpen: () {
                  Navigator.pop(context);
                  widget.tools[i].onOpen();
                },
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Single row inside the bottom sheet.
// Tapping the row itself navigates straight to the tool.
// A separate "Show more" reveals a short description, and
// a nested "View more" inside that reveals the full detail —
// neither of those taps navigate anywhere.
// ─────────────────────────────────────────────
class _ToolRow extends StatefulWidget {
  final ToolItem tool;
  final bool isDark;
  final VoidCallback onOpen;

  const _ToolRow({
    required this.tool,
    required this.isDark,
    required this.onOpen,
  });

  @override
  State<_ToolRow> createState() => _ToolRowState();
}

class _ToolRowState extends State<_ToolRow> {
  bool _showDescription = false;
  bool _showDetail = false;

  @override
  Widget build(BuildContext context) {
    final tool = widget.tool;
    final isDark = widget.isDark;
    final color = isDark ? tool.darkColor : tool.lightColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color:
            isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF7F7F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // ── main tappable area: goes straight to the tool ──
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: widget.onOpen,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: color.withOpacity(isDark ? 0.18 : 0.12),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Icon(tool.icon, color: color, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tool.label,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              Text(
                                tool.sublabel,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color:
                                      isDark ? Colors.white38 : Colors.black45,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: isDark ? Colors.white38 : Colors.black26,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── separate toggle: reveals the description only ──
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => setState(() {
                  _showDescription = !_showDescription;
                  if (!_showDescription) _showDetail = false;
                }),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  child: Icon(
                    _showDescription
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.info_outline_rounded,
                    size: 18,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ),
            ],
          ),

          // ── short description ──
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: _showDescription
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tool.simpleDescription,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.45,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // ── nested toggle: reveals full feature detail ──
                        GestureDetector(
                          onTap: () =>
                              setState(() => _showDetail = !_showDetail),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _showDetail ? 'View less' : 'View more',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: color,
                                ),
                              ),
                              Icon(
                                _showDetail
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                size: 16,
                                color: color,
                              ),
                            ],
                          ),
                        ),

                        AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                          child: _showDetail
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: tool.features
                                        .map(
                                          (f) => Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 6),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 3),
                                                  child: Icon(
                                                      Icons
                                                          .check_circle_rounded,
                                                      size: 13,
                                                      color: color),
                                                ),
                                                const SizedBox(width: 7),
                                                Expanded(
                                                  child: Text(
                                                    f,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      height: 1.4,
                                                      color: isDark
                                                          ? Colors.white60
                                                          : Colors.black54,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
