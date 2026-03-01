import 'package:flutter/material.dart';

class CustomShimmer extends StatefulWidget {
  final Widget child;
  final bool isDark;

  const CustomShimmer({
    Key? key,
    required this.child,
    required this.isDark,
  }) : super(key: key);

  @override
  State<CustomShimmer> createState() => _CustomShimmerState();
}

class _CustomShimmerState extends State<CustomShimmer>
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

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.isDark
                  ? [
                      Colors.grey[800]!,
                      Colors.grey[700]!,
                      Colors.grey[600]!,
                      Colors.grey[700]!,
                      Colors.grey[800]!,
                    ]
                  : [
                      Colors.grey[300]!,
                      Colors.grey[200]!,
                      Colors.grey[100]!,
                      Colors.grey[200]!,
                      Colors.grey[300]!,
                    ],
              stops: [
                0.0,
                0.35 + _animation.value * 0.15,
                0.5 + _animation.value * 0.15,
                0.65 + _animation.value * 0.15,
                1.0,
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class ShimmerContainer extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadius? borderRadius;
  final BoxShape shape;

  const ShimmerContainer({
    Key? key,
    this.width,
    required this.height,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: shape == BoxShape.rectangle ? borderRadius : null,
        shape: shape,
      ),
    );
  }
}
