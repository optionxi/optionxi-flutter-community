import 'package:flutter/material.dart';

class MagicalAIButton extends StatefulWidget {
  final bool isDark;
  final VoidCallback? onPressed;

  const MagicalAIButton({
    Key? key,
    required this.isDark,
    this.onPressed,
  }) : super(key: key);

  @override
  State<MagicalAIButton> createState() => _MagicalAIButtonState();
}

class _MagicalAIButtonState extends State<MagicalAIButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Controls the speed of the border rotation
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // --- Configuration ---

    // 1. Text & Icon Colors (High Contrast)
    final textColor = widget.isDark ? Colors.white : const Color(0xFF1E1E2E);
    final iconColor = widget.isDark ? Colors.white : const Color(0xFF2563EB);

    // 2. Button Background Color (Solid)
    final buttonBgColor = widget.isDark
        ? const Color(0xFF121212) // Deep Black
        : const Color(0xFFFFFFFF); // Pure White

    // 3. The "Gemini" Gradient Colors for Border & Shadow
    final colors = widget.isDark
        ? [
            const Color(0xFF4285F4), // Google Blue
            const Color(0xFF9C27B0), // Purple
            const Color(0xFFF43F5E), // Pink
            const Color(0xFF4285F4), // Loop back to Blue
          ]
        : [
            const Color(0xFF2563EB), // Brighter Blue
            const Color(0xFF06B6D4), // Cyan
            const Color(0xFF7C3AED), // Violet
            const Color(0xFF2563EB), // Loop back
          ];

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          // Add a subtle glow behind the button that matches the current border color
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                // We pick a color from the gradient based on animation value for the shadow
                color: Color.lerp(colors[0], colors[1], _controller.value)!
                    .withOpacity(widget.isDark ? 0.5 : 0.3),
                blurRadius: 12,
                spreadRadius: -2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onPressed,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.all(
                    2), // This thickness determines border width
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  // The Animated Gradient Border
                  gradient: SweepGradient(
                    colors: colors,
                    stops: const [0.0, 0.33, 0.66, 1.0],
                    // This creates the rotation effect
                    transform: GradientRotation(_controller.value * 6.28),
                  ),
                ),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color:
                        buttonBgColor, // Solid background ensures readability
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, size: 20, color: iconColor),
                      const SizedBox(width: 12),
                      Text(
                        "AI Research",
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold, // Bold for better readability
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
