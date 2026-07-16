import 'package:flutter/material.dart';

import 'package:optionxi/Main_Pages/OptionCalculator/act_oi_analyser.dart';
import 'package:optionxi/Main_Pages/OptionCalculator/act_option_calculator.dart';
import 'package:optionxi/Main_Pages/OptionCalculator/act_optionchain_master.dart';

// ─────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────
class ToolCardData {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color>
      gradient; // light-mode & dark-mode share the hue, just adjust opacity below
  final bool
      live; // shows a pulsing "LIVE" badge — use for real-time data tools
  final Widget Function() pageBuilder;

  const ToolCardData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.pageBuilder,
    this.live = false,
  });
}

// ─────────────────────────────────────────────────────────────
// Section — drop this in place of the old grid / hub card.
// ─────────────────────────────────────────────────────────────
class OptionsToolsSection extends StatefulWidget {
  const OptionsToolsSection({Key? key}) : super(key: key);

  @override
  State<OptionsToolsSection> createState() => _OptionsToolsSectionState();
}

class _OptionsToolsSectionState extends State<OptionsToolsSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<Animation<double>> _anims = [];

  static final List<ToolCardData> _tools = [
    ToolCardData(
      title: 'Option Chain',
      subtitle: 'Strikes, OI, IV & Greeks for indices and stocks',
      icon: Icons.account_tree_rounded,
      gradient: const [Color(0xFFDB2777), Color(0xFFF472B6)],
      live: true,
      pageBuilder: () => const OptionChainPage(),
    ),
    ToolCardData(
      title: 'FNO Budget',
      subtitle: 'Enter ₹30,000 — see every strike that fits it',
      icon: Icons.calculate_rounded,
      gradient: const [Color(0xFF0D9488), Color(0xFF2DD4BF)],
      pageBuilder: () => const OptionCalculatorPage(),
    ),
    ToolCardData(
      title: 'OI Activity',
      subtitle: 'Gainers, losers, long build-up, short covering, max pain',
      icon: Icons.show_chart_rounded,
      gradient: const [Color(0xFF2563EB), Color(0xFF60A5FA)],
      live: true,
      pageBuilder: () => const OiActivityPage(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    for (int i = 0; i < _tools.length; i++) {
      final start = 0.12 * i;
      final end = (start + 0.55).clamp(0.0, 1.0);
      _anims.add(CurvedAnimation(
        parent: _controller,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      ));
    }
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Row(
              children: [
                Text(
                  'OPTION CHAIN',
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
          for (int i = 0; i < _tools.length; i++) ...[
            _AnimatedToolCard(
              animation: _anims[i],
              data: _tools[i],
              isDark: isDark,
              onTap: () => Navigator.of(context)
                  .push(_fadeRoute(_tools[i].pageBuilder())),
            ),
            if (i != _tools.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Entrance animation wrapper
// ─────────────────────────────────────────────────────────────
class _AnimatedToolCard extends StatelessWidget {
  final Animation<double> animation;
  final ToolCardData data;
  final bool isDark;
  final VoidCallback onTap;

  const _AnimatedToolCard({
    required this.animation,
    required this.data,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final v = animation.value;
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - v)),
            child: child,
          ),
        );
      },
      child: _ToolCard(data: data, isDark: isDark, onTap: onTap),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// The card itself — press-scale feedback + optional live pulse.
// ─────────────────────────────────────────────────────────────
class _ToolCard extends StatefulWidget {
  final ToolCardData data;
  final bool isDark;
  final VoidCallback onTap;

  const _ToolCard({
    required this.data,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_ToolCard> createState() => _ToolCardState();
}

class _ToolCardState extends State<_ToolCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final data = widget.data;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: isDark ? const Color(0xFF17151F) : Colors.white,
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.black.withOpacity(0.045),
            ),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : data.gradient.first)
                    .withOpacity(isDark ? 0.28 : 0.10),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon badge
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: data.gradient,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: data.gradient.first.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(data.icon, color: Colors.white, size: 23),
              ),
              const SizedBox(width: 13),
              // Text block
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          data.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color:
                                isDark ? Colors.white : const Color(0xFF111827),
                          ),
                        ),
                        if (data.live) ...[
                          const SizedBox(width: 7),
                          _LiveBadge(
                              pulse: _pulseCtrl, color: data.gradient.first),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.3,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? Colors.white30 : Colors.black26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Tiny pulsing "LIVE" dot + label
// ─────────────────────────────────────────────────────────────
class _LiveBadge extends StatelessWidget {
  final AnimationController pulse;
  final Color color;

  const _LiveBadge({required this.pulse, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: pulse,
            builder: (context, _) {
              final t = pulse.value;
              return Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.5 + 0.5 * t),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
          Text(
            'LIVE',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
