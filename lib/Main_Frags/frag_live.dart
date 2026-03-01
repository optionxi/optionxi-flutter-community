import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:optionxi/Helpers/badge_service_obx.dart';
import 'package:optionxi/VirtualTradeJournal/frag_watchlist.dart';
import 'package:optionxi/VirtualTradeJournal/vt_frag_portfolio_journal.dart';

class WatchlistFragmentMain extends StatefulWidget {
  final int? initialFragIndex;

  const WatchlistFragmentMain({Key? key, this.initialFragIndex})
      : super(key: key);

  @override
  State<WatchlistFragmentMain> createState() => _WatchlistFragmentMainState();
}

class _WatchlistFragmentMainState extends State<WatchlistFragmentMain>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentPageIndex = widget.initialFragIndex ?? 0;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onBottomNavItemTapped(int index) async {
    HapticFeedback.lightImpact();
    if (index == 1) {
      await BasketBadgeServiceObx.clearBasketBadge();
    }
    setState(() {
      _currentPageIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      WatchlistFragment(),
      PortfolioFragmentJournal(null),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
        child: KeyedSubtree(
          key: ValueKey(_currentPageIndex),
          child: pages[_currentPageIndex],
        ),
      ),
      bottomNavigationBar: _buildSecondaryNav(context),
    );
  }

  Widget _buildSecondaryNav(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0E0E18).withOpacity(0.97)
            : Colors.white.withOpacity(0.97),
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.07)
                : Colors.black.withOpacity(0.06),
            width: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.5)
                : Colors.black.withOpacity(0.08),
            blurRadius: isDark ? 40 : 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              // Watchlist tab
              _WJNavItem(
                label: 'Watchlist',
                icon: Icons.remove_red_eye_outlined,
                activeIcon: Icons.remove_red_eye_rounded,
                isSelected: _currentPageIndex == 0,
                isDark: isDark,
                primary: primary,
                onTap: () => _onBottomNavItemTapped(0),
              ),
              // Basket tab — uses Obx for reactive badge
              Obx(() {
                final badgeCount = BasketBadgeServiceObx.basketBadgeCount.value;
                return _WJNavItem(
                  label: 'Basket',
                  icon: Icons.pie_chart_outline_rounded,
                  activeIcon: Icons.pie_chart_rounded,
                  badge: badgeCount,
                  isSelected: _currentPageIndex == 1,
                  isDark: isDark,
                  primary: primary,
                  onTap: () => _onBottomNavItemTapped(1),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Nav Item Widget
// ─────────────────────────────────────────────────────────────────────────────

class _WJNavItem extends StatefulWidget {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final int badge;
  final bool isSelected;
  final bool isDark;
  final Color primary;
  final VoidCallback onTap;

  const _WJNavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    this.badge = 0,
    required this.isSelected,
    required this.isDark,
    required this.primary,
    required this.onTap,
  });

  @override
  State<_WJNavItem> createState() => _WJNavItemState();
}

class _WJNavItemState extends State<_WJNavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _iconScale;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _iconScale = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeOutBack),
    );
    if (widget.isSelected) _anim.value = 1.0;
  }

  @override
  void didUpdateWidget(_WJNavItem old) {
    super.didUpdateWidget(old);
    if (widget.isSelected && !old.isSelected) {
      _anim.forward(from: 0);
    } else if (!widget.isSelected && old.isSelected) {
      _anim.reverse();
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.primary;
    final isDark = widget.isDark;
    final isSelected = widget.isSelected;

    final inactiveColor = isDark
        ? Colors.white.withOpacity(0.32)
        : Colors.black.withOpacity(0.38);

    return Expanded(
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _anim,
          builder: (context, _) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4), // ← was 6, reduced
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? p.withOpacity(0.13) : p.withOpacity(0.08))
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize:
                      MainAxisSize.min, // ← KEY: don't expand beyond children
                  children: [
                    // ── Top accent line ──────────────────────────────
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      width: isSelected ? 28 : 0,
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(colors: [p, p.withOpacity(0.4)])
                            : null,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4), // ← was 6

                    // ── Icon + badge ─────────────────────────────────
                    Transform.scale(
                      scale: _iconScale.value,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOutCubic,
                            width: 40,
                            height: 30, // ← was 32, shaved 2px
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        p,
                                        Color.lerp(p, Colors.indigo, 0.35)!,
                                      ],
                                    )
                                  : null,
                              borderRadius: BorderRadius.circular(11),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: p.withOpacity(0.38),
                                        blurRadius: 14,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Icon(
                              isSelected ? widget.activeIcon : widget.icon,
                              size: 19,
                              color: isSelected ? Colors.white : inactiveColor,
                            ),
                          ),

                          // Badge
                          if (widget.badge > 0)
                            Positioned(
                              top: -6,
                              right: -10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(0xFF0E0E18)
                                        : Colors.white,
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withOpacity(0.45),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                constraints: const BoxConstraints(
                                    minWidth: 17, minHeight: 17),
                                child: Text(
                                  widget.badge > 99 ? '99+' : '${widget.badge}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    height: 1,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 4), // ← was 5

                    // ── Label ────────────────────────────────────────
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 220),
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? p : inactiveColor,
                        letterSpacing: isSelected ? 0.1 : 0,
                      ),
                      child: Text(
                        widget.label,
                        // ← Prevent system font scaling from blowing up the nav bar
                        textScaler: TextScaler.noScaling,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
