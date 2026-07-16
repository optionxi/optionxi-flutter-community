import 'package:flutter/material.dart';

/// A widget that shows a skeleton loading animation
class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final bool isCircle;

  const SkeletonLoader({
    Key? key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
    this.isCircle = false,
  }) : super(key: key);

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: !widget.isCircle
                ? BorderRadius.circular(widget.borderRadius)
                : null,
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: isDarkMode
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
              stops: [
                0.0,
                _animation.value,
                1.0,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A widget that shows a horizontal list of skeleton loaders for screener chips
class ScreenerChipsSkeleton extends StatelessWidget {
  const ScreenerChipsSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: SkeletonLoader(
            width: 80.0 + (index % 3) * 20, // Variable widths
            height: 32.0,
            borderRadius: 16.0,
          ),
        );
      },
    );
  }
}

/// A widget that shows a list of skeleton loaders for stock items
class StockListSkeleton extends StatelessWidget {
  final int itemCount;

  const StockListSkeleton({
    Key? key,
    this.itemCount = 10,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Stock Icon Skeleton
                const SkeletonLoader(
                  width: 40,
                  height: 40,
                  isCircle: true,
                ),
                const SizedBox(width: 12),

                // Stock Info Skeleton
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonLoader(
                        width: 80.0 + (index % 3) * 20,
                        height: 16,
                      ),
                      const SizedBox(height: 6),
                      SkeletonLoader(
                        width: 60.0,
                        height: 12,
                      ),
                    ],
                  ),
                ),

                // Price Info Skeleton
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: const [
                    SkeletonLoader(
                      width: 70,
                      height: 16,
                    ),
                    SizedBox(height: 6),
                    SkeletonLoader(
                      width: 50,
                      height: 12,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
