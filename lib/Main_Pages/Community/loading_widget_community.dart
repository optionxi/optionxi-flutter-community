// lib/pages/Community/loading_widget_community.dart

import 'package:flutter/material.dart';

// ─── Shimmer Engine ────────────────────────────────────────────────────────────
class _ShimmerBase extends StatefulWidget {
  final Widget child;
  final bool isDark;
  const _ShimmerBase({required this.child, required this.isDark});

  @override
  State<_ShimmerBase> createState() => _ShimmerBaseState();
}

class _ShimmerBaseState extends State<_ShimmerBase>
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
    final base =
        widget.isDark ? const Color(0xFF1A1A26) : const Color(0xFFE8E8F0);
    final highlight =
        widget.isDark ? const Color(0xFF2A2A3E) : const Color(0xFFF2F2FA);

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) {
        return ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [base, highlight, base],
            stops: [
              (_anim.value - 0.5).clamp(0.0, 1.0),
              _anim.value.clamp(0.0, 1.0),
              (_anim.value + 0.5).clamp(0.0, 1.0),
            ],
          ).createShader(bounds),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

Widget _shimmerBox({
  required double width,
  required double height,
  required bool isDark,
  double radius = 8,
}) =>
    Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A26) : const Color(0xFFE8E8F0),
        borderRadius: BorderRadius.circular(radius),
      ),
    );

// ─── Topic Card Shimmer ────────────────────────────────────────────────────────
class TopicCardShimmer extends StatelessWidget {
  final bool isDark;
  const TopicCardShimmer({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardColor =
        isDark ? const Color(0xFF1A1A26) : const Color(0xFFF5F5FA);
    final borderColor =
        isDark ? const Color(0xFF2A2A3A) : const Color(0xFFE0E0EE);

    return _ShimmerBase(
      isDark: isDark,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar + username row
            Row(
              children: [
                _shimmerBox(width: 36, height: 36, radius: 18, isDark: isDark),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _shimmerBox(width: 100, height: 12, isDark: isDark),
                    const SizedBox(height: 4),
                    _shimmerBox(width: 60, height: 10, isDark: isDark),
                  ],
                ),
                const Spacer(),
                // Optional badge placeholder
                _shimmerBox(width: 56, height: 20, radius: 6, isDark: isDark),
              ],
            ),
            const SizedBox(height: 14),
            // Title lines
            _shimmerBox(width: double.infinity, height: 16, isDark: isDark),
            const SizedBox(height: 6),
            _shimmerBox(width: 200, height: 16, isDark: isDark),
            const SizedBox(height: 10),
            // Excerpt lines
            _shimmerBox(width: double.infinity, height: 12, isDark: isDark),
            const SizedBox(height: 4),
            _shimmerBox(width: 240, height: 12, isDark: isDark),
            const SizedBox(height: 14),
            // Stats row
            Row(
              children: [
                _shimmerBox(width: 8, height: 8, radius: 4, isDark: isDark),
                const SizedBox(width: 12),
                _shimmerBox(width: 40, height: 12, isDark: isDark),
                const SizedBox(width: 16),
                _shimmerBox(width: 40, height: 12, isDark: isDark),
                const SizedBox(width: 16),
                _shimmerBox(width: 40, height: 12, isDark: isDark),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Post Card Shimmer ─────────────────────────────────────────────────────────
class PostCardShimmer extends StatelessWidget {
  final bool isDark;
  const PostCardShimmer({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardColor =
        isDark ? const Color(0xFF1A1A26) : const Color(0xFFF5F5FA);
    final borderColor =
        isDark ? const Color(0xFF2A2A3A) : const Color(0xFFE0E0EE);

    return _ShimmerBase(
      isDark: isDark,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _shimmerBox(width: 36, height: 36, radius: 18, isDark: isDark),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _shimmerBox(width: 120, height: 12, isDark: isDark),
                    const SizedBox(height: 4),
                    _shimmerBox(width: 80, height: 10, isDark: isDark),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            _shimmerBox(width: double.infinity, height: 13, isDark: isDark),
            const SizedBox(height: 5),
            _shimmerBox(width: double.infinity, height: 13, isDark: isDark),
            const SizedBox(height: 5),
            _shimmerBox(width: 180, height: 13, isDark: isDark),
            const SizedBox(height: 14),
            Row(
              children: [
                _shimmerBox(width: 60, height: 28, radius: 20, isDark: isDark),
                const SizedBox(width: 8),
                _shimmerBox(width: 70, height: 28, radius: 20, isDark: isDark),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
