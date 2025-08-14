import 'package:flutter/material.dart';
import 'package:optionxi/VirtualTrading/VComponents/cust_colorful_action_button.dart';

class StockTradingSkeleton extends StatefulWidget {
  final bool isDark;

  const StockTradingSkeleton({Key? key, required this.isDark})
      : super(key: key);

  @override
  State<StockTradingSkeleton> createState() => _StockTradingSkeletonState();
}

class _StockTradingSkeletonState extends State<StockTradingSkeleton>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Shimmer animation for loading elements
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _shimmerController.repeat();
    _animation =
        Tween<double>(begin: 0.0, end: 2.0).animate(_shimmerController);
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStockInfoSkeleton(),
                const SizedBox(height: 20),
                _buildQuantityInputSkeleton(),
                const SizedBox(height: 20),
                _buildOrderTypeSelectionSkeleton(),
                const SizedBox(height: 20),
                _buildProductTypeSelectionSkeleton(),
                const SizedBox(height: 20),
                _buildPriceTypeSelectionSkeleton(),
              ],
            ),
          ),
        ),
        _buildVirtualBalance(),
        const SizedBox(height: 4),
        _buildBottomBarSkeleton(),
      ],
    );
  }

  Container _buildVirtualBalance() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: widget.isDark ? Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              widget.isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE0E0E0),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            color: widget.isDark ? Colors.blue[300] : Colors.blue[700],
          ),
          const SizedBox(width: 12),
          Text(
            'Virtual Balance:',
            style: TextStyle(
              fontSize: 16,
              color: widget.isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          const Spacer(),
          _buildShimmerBox(90, 20, borderRadius: 6),
        ],
      ),
    );
  }

  Widget _buildShimmerBox(
    double width,
    double height, {
    double borderRadius = 8,
    bool isCircular = false,
  }) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: isCircular
                ? BorderRadius.circular(width / 2)
                : BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              colors: widget.isDark
                  ? [
                      Colors.grey[800]!,
                      Colors.grey[700]!,
                      Colors.grey[800]!,
                    ]
                  : [
                      Colors.grey[300]!,
                      Colors.grey[200]!,
                      Colors.grey[300]!,
                    ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment(-1.0 + _animation.value, 0.0),
              end: Alignment(-0.5 + _animation.value, 0.0),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStockInfoSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              widget.isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E5E5),
        ),
        boxShadow: [
          BoxShadow(
            color: widget.isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section with shimmer
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildShimmerBox(48, 48, isCircular: true),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildShimmerBox(120, 20, borderRadius: 6),
                  const SizedBox(height: 6),
                  Container(
                    width: 40,
                    height: 18,
                    decoration: BoxDecoration(
                      color:
                          (widget.isDark ? Colors.grey[700] : Colors.grey[200])!
                              .withOpacity(0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        'EQ',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: widget.isDark
                                ? Colors.grey[300]
                                : Colors.grey[600]),
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildShimmerBox(100, 24, borderRadius: 6),
                  const SizedBox(height: 6),
                  _buildShimmerBox(70, 22, borderRadius: 12),
                ],
              ),
            ],
          ),
          const Divider(height: 24),
          // OHLC section with shimmer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildOhlcItemSkeleton('Open'),
              _buildOhlcItemSkeleton('High'),
              _buildOhlcItemSkeleton('Low'),
              _buildOhlcItemSkeleton('Prev. Close'),
            ],
          ),
          const Divider(height: 24),
          // Static action buttons
          Row(
            children: [
              Expanded(
                child: buildModernActionButton(
                  context,
                  widget.isDark,
                  'View Chart',
                  Icons.trending_up_rounded,
                  () {},
                  true, // isChart button
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: buildModernActionButton(
                  context,
                  widget.isDark,
                  'Alerts',
                  Icons.analytics_outlined,
                  () {},
                  false, // isChart button
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOhlcItemSkeleton(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        const SizedBox(height: 4),
        _buildShimmerBox(60, 16, borderRadius: 4),
      ],
    );
  }

  Widget _buildQuantityInputSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Static Label
        Text(
          'Quantity',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: widget.isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        // Shimmer Box for TextFormField
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: widget.isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isDark
                  ? const Color(0xFF2E2E2E)
                  : const Color(0xFFE0E0E0),
            ),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Icon(Icons.format_list_numbered,
                    color: widget.isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
              _buildShimmerBox(100, 20, borderRadius: 6),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderTypeSelectionSkeleton() {
    return Container(
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: widget.isDark
                ? const Color(0xFF2E2E2E)
                : const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          // Static BUY Button (Selected state)
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.15),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              child: Text(
                'BUY',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade600,
                ),
              ),
            ),
          ),
          Container(
            width: 1,
            height: 35,
            color: widget.isDark
                ? const Color(0xFF2E2E2E)
                : const Color(0xFFE0E0E0),
          ),
          // Static SELL Button (Unselected state)
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Text(
                'SELL',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: widget.isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductTypeSelectionSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Product Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: widget.isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Static INTRADAY chip (selected)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color:
                    widget.isDark ? Colors.blue.shade700 : Colors.blue.shade600,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: widget.isDark
                        ? Colors.blue.shade600
                        : Colors.blue.shade500),
              ),
              child: const Text(
                'INTRADAY',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Static NORMAL chip (locked)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: widget.isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: widget.isDark
                        ? const Color(0xFF2E2E2E)
                        : Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Text(
                    'NORMAL',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: Icon(Icons.lock, size: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceTypeSelectionSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: widget.isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _buildStaticChip('MKT', true),
            _buildStaticChip('LIMIT', false, isLocked: true),
            _buildStaticChip('SL', false, isLocked: true),
            _buildStaticChip('SLM', false, isLocked: true),
          ],
        ),
      ],
    );
  }

  Widget _buildStaticChip(String type, bool isSelected,
      {bool isLocked = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? (widget.isDark ? Colors.blue.shade700 : Colors.blue.shade600)
            : (widget.isDark ? const Color(0xFF1E1E1E) : Colors.white),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isSelected
                ? (widget.isDark ? Colors.blue.shade600 : Colors.blue.shade500)
                : (widget.isDark
                    ? const Color(0xFF2E2E2E)
                    : Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            type,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : isLocked
                      ? Colors.grey.shade600
                      : (widget.isDark ? Colors.white70 : Colors.black87),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (isLocked)
            const Padding(
              padding: EdgeInsets.only(left: 6),
              child: Icon(Icons.lock, size: 14, color: Colors.grey),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomBarSkeleton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border(
          top: BorderSide(
              color: widget.isDark
                  ? const Color(0xFF2E2E2E)
                  : const Color(0xFFE0E0E0)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Margin Required',
                style: TextStyle(
                  fontSize: 16,
                  color: widget.isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              _buildShimmerBox(80, 20, borderRadius: 6),
            ],
          ),
          const SizedBox(height: 16),
          // Static BUY button appearance
          Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.green.shade600,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'BUY',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
