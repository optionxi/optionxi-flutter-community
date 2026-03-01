import 'package:flutter/material.dart';

class StockTradingSkeleton extends StatefulWidget {
  final bool isDark;

  const StockTradingSkeleton({Key? key, required this.isDark})
      : super(key: key);

  @override
  State<StockTradingSkeleton> createState() => _StockTradingSkeletonState();
}

class _StockTradingSkeletonState extends State<StockTradingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat();

    _shimmerAnimation = Tween<double>(
      begin: -1.5,
      end: 2.5,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  // ── Core shimmer box ─────────────────────────────────────────────────────────
  Widget _shimmerBox(
    double width,
    double height, {
    double borderRadius = 8,
  }) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, _) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: const [0.0, 0.45, 0.55, 1.0],
              colors: widget.isDark
                  ? [
                      const Color(0xFF1E1E1E),
                      const Color(0xFF2A2A2A),
                      const Color(0xFF333333),
                      const Color(0xFF1E1E1E),
                    ]
                  : [
                      const Color(0xFFE8E8E8),
                      const Color(0xFFF0F0F0),
                      const Color(0xFFF8F8F8),
                      const Color(0xFFE8E8E8),
                    ],
              transform: _SlidingGradientTransform(_shimmerAnimation.value),
            ),
          ),
        );
      },
    );
  }

  // ── Stock header skeleton ────────────────────────────────────────────────────
  Widget _buildStockHeaderSkeleton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF0D0D0D) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isDark
              ? Colors.white.withOpacity(0.07)
              : Colors.black.withOpacity(0.06),
        ),
        boxShadow: widget.isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: stock name + price
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _shimmerBox(140, 15, borderRadius: 5),
              const Spacer(),
              _shimmerBox(80, 15, borderRadius: 5),
            ],
          ),
          const SizedBox(height: 10),
          // Row 2: segment chip + change badge + chevron
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _shimmerBox(34, 20, borderRadius: 6),
              const Spacer(),
              _shimmerBox(62, 20, borderRadius: 6),
              const SizedBox(width: 6),
              _shimmerBox(16, 16, borderRadius: 4),
            ],
          ),
        ],
      ),
    );
  }

  // ── Buy / Sell toggle skeleton ───────────────────────────────────────────────
  Widget _buildOrderTypeSkeleton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF111111) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          // BUY side — pre-highlighted
          Expanded(
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'BUY',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF10B981),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          Container(
            width: 1,
            height: 32,
            color: widget.isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05),
          ),
          // SELL side
          Expanded(
            child: Center(
              child: Text(
                'SELL',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: widget.isDark ? Colors.white38 : Colors.black38,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Quantity input skeleton ──────────────────────────────────────────────────
  Widget _buildQuantitySkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quantity',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: widget.isDark ? Colors.white70 : Colors.black54,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: widget.isDark ? const Color(0xFF111111) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.05),
            ),
          ),
          child: Row(
            children: [
              _buildQtyButtonSkeleton(Icons.remove_rounded),
              Expanded(
                child: Center(child: _shimmerBox(40, 24, borderRadius: 6)),
              ),
              _buildQtyButtonSkeleton(Icons.add_rounded),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQtyButtonSkeleton(IconData icon) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: widget.isDark
            ? Colors.white.withOpacity(0.08)
            : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: widget.isDark ? Colors.white38 : Colors.black38,
        size: 20,
      ),
    );
  }

  // ── Order type chips skeleton ────────────────────────────────────────────────
  Widget _buildPriceTypeSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Type',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: widget.isDark ? Colors.white70 : Colors.black54,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _buildChipSkeleton(isSelected: true), // MKT — active
            _buildChipSkeleton(isLocked: true),
            _buildChipSkeleton(isLocked: true),
            _buildChipSkeleton(isLocked: true),
          ],
        ),
      ],
    );
  }

  Widget _buildChipSkeleton({bool isSelected = false, bool isLocked = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF10B981)
            : (widget.isDark ? const Color(0xFF111111) : Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? Colors.transparent
              : (widget.isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.05)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Shimmer bar instead of static text for unselected chips
          isSelected
              ? const Text(
                  'MKT',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                )
              : _shimmerBox(32, 14, borderRadius: 4),
          if (isLocked) ...[
            const SizedBox(width: 6),
            Icon(
              Icons.lock_rounded,
              size: 14,
              color: widget.isDark ? Colors.white24 : Colors.black26,
            ),
          ],
        ],
      ),
    );
  }

  // ── Bottom bar skeleton ──────────────────────────────────────────────────────
  Widget _buildBottomBarSkeleton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF111111) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(
          top: BorderSide(
            color: widget.isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Balance row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Balance',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: widget.isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _shimmerBox(90, 22, borderRadius: 6),
                ],
              ),
              Icon(
                Icons.arrow_forward_rounded,
                color: widget.isDark ? Colors.white24 : Colors.black26,
                size: 20,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'After Order',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: widget.isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _shimmerBox(90, 22, borderRadius: 6),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Margin row
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.isDark
                  ? Colors.white.withOpacity(0.03)
                  : Colors.black.withOpacity(0.02),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Margin Required',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: widget.isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                _shimmerBox(80, 18, borderRadius: 5),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // CTA button
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'BUY',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

// ── Root build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStockHeaderSkeleton(),

                // Match the exact padding wrapper from the real UI
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOrderTypeSkeleton(),
                      const SizedBox(height: 24),

                      // Removed extra inner Padding here to match the main layout
                      _buildQuantitySkeleton(),
                      const SizedBox(height: 24),

                      // Moved Price Type inside the same block with equal spacing
                      _buildPriceTypeSkeleton(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildBottomBarSkeleton(),
      ],
    );
  }
}

// ── Gradient slide transform ─────────────────────────────────────────────────
class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;
  const _SlidingGradientTransform(this.slidePercent);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0, 0);
  }
}
