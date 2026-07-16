import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:optionxi/Theme/theme_controller.dart';

class MagicalAIButton extends StatefulWidget {
  /// The label shown inside the button. Defaults to "AI Chat".
  final String label;

  final VoidCallback? onPressed;

  const MagicalAIButton({
    Key? key,
    this.label = 'Ask AI',
    this.onPressed,
  }) : super(key: key);

  @override
  State<MagicalAIButton> createState() => _MagicalAIButtonState();
}

class _MagicalAIButtonState extends State<MagicalAIButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final ThemeController _themeController = Get.find<ThemeController>();

  @override
  void initState() {
    super.initState();
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
    return Obx(() {
      final isDark = _themeController.isDarkMode;

      // 1. Text & Icon Colors
      final textColor = isDark ? Colors.white : const Color(0xFF1E1E2E);
      final iconColor = isDark ? Colors.white : const Color(0xFF2563EB);

      // 2. Button Background Color
      final buttonBgColor =
          isDark ? const Color(0xFF121212) : const Color(0xFFFFFFFF);

      // 3. Gradient Colors for Border & Shadow
      final colors = isDark
          ? [
              const Color(0xFF4285F4),
              const Color(0xFF9C27B0),
              const Color(0xFFF43F5E),
              const Color(0xFF4285F4),
            ]
          : [
              const Color(0xFF2563EB),
              const Color(0xFF06B6D4),
              const Color(0xFF7C3AED),
              const Color(0xFF2563EB),
            ];

      return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Color.lerp(colors[0], colors[1], _controller.value)!
                      .withOpacity(isDark ? 0.5 : 0.3),
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
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: SweepGradient(
                      colors: colors,
                      stops: const [0.0, 0.33, 0.66, 1.0],
                      transform: GradientRotation(_controller.value * 6.28),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: buttonBgColor,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, size: 20, color: iconColor),
                        const SizedBox(width: 12),
                        Text(
                          widget.label,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
    });
  }
}
