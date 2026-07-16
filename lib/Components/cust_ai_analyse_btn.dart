import 'package:flutter/material.dart';

class AiAnalyseButton extends StatefulWidget {
  final VoidCallback onTap;
  const AiAnalyseButton({super.key, required this.onTap});

  @override
  State<AiAnalyseButton> createState() => _AiAnalyseButtonState();
}

class _AiAnalyseButtonState extends State<AiAnalyseButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          return CustomPaint(
            painter: _BorderPainter(_ctrl.value, isDark),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.04)
                    : Colors.black.withOpacity(0.03),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF3BF6C8),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3BF6C8).withOpacity(0.7),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Analyse with AI',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: isDark ? Colors.white38 : Colors.black26,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BorderPainter extends CustomPainter {
  final double progress;
  final bool isDark;

  _BorderPainter(this.progress, this.isDark);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(14));

    // Sweeping gradient colors
    const colors = [
      Color(0xFF6E3BF6),
      Color(0xFF3B8EF6),
      Color(0xFF3BF6C8),
      Color(0xFF6E3BF6),
    ];

    // Rotate the gradient based on progress
    final angle = progress * 2 * 3.141592653589793;

    final gradient = SweepGradient(
      colors: colors,
      stops: const [0.0, 0.33, 0.66, 1.0],
      transform: GradientRotation(angle),
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRRect(rrect, paint);

    // Soft glow layer
    final glowPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawRRect(rrect, glowPaint);
  }

  @override
  bool shouldRepaint(_BorderPainter old) => old.progress != progress;
}
