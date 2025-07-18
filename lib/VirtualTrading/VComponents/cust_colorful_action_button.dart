// Colorful action button with vibrant gradients
import 'package:flutter/material.dart';

Widget buildColorfulActionButton(
  BuildContext context,
  bool isDark,
  String label,
  IconData icon,
  VoidCallback onPressed,
  bool isChart,
) {
  // Define colors based on button type
  final List<Color> gradientColors = isChart
      ? isDark
          ? [
              const Color(0xFF4A90E2), // Blue
              const Color(0xFF357ABD), // Darker blue
              const Color(0xFF2E6BA8), // Even darker blue
            ]
          : [
              const Color(0xFF5BA7F7), // Light blue
              const Color(0xFF4A90E2), // Medium blue
              const Color(0xFF357ABD), // Darker blue
            ]
      : isDark
          ? [
              const Color(0xFFFF6B6B), // Coral red
              const Color(0xFFE55A5A), // Darker coral
              const Color(0xFFD64545), // Even darker coral
            ]
          : [
              const Color(0xFFFF8A80), // Light coral
              const Color(0xFFFF6B6B), // Medium coral
              const Color(0xFFE55A5A), // Darker coral
            ];

  final Color shadowColor = isChart
      ? isDark
          ? Colors.blue.withOpacity(0.3)
          : Colors.blue.withOpacity(0.2)
      : isDark
          ? Colors.green.withOpacity(0.3)
          : Colors.green.withOpacity(0.2);

  final Color iconColor = isChart ? Colors.white : Colors.white;

  return Container(
    height: 50,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: gradientColors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: const [0.0, 0.5, 1.0],
      ),
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: shadowColor,
          blurRadius: 8,
          offset: const Offset(0, 3),
          spreadRadius: 1,
        ),
        BoxShadow(
          color: isDark
              ? Colors.black.withOpacity(0.2)
              : Colors.grey.withOpacity(0.1),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onPressed,
        splashColor: Colors.white.withOpacity(0.2),
        highlightColor: Colors.white.withOpacity(0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize:
                MainAxisSize.min, // Make the Row only as wide as its content

            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
