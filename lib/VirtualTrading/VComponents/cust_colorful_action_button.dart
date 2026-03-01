// Modern subtle action button with muted colors
import 'package:flutter/material.dart';

Widget buildModernActionButton(
  BuildContext context,
  bool isDark,
  String label,
  IconData icon,
  VoidCallback onPressed,
  bool isChart,
) {
  // Define modern colors with subtle vibrancy
  final List<Color> gradientColors = isChart
      ? isDark
          ? [
              const Color(0xFF4C6EF5), // Modern blue
              const Color(0xFF3B5BDB), // Deeper blue
            ]
          : [
              const Color(0xFF6C7CE0), // Soft purple-blue
              const Color(0xFF5A67D8), // Rich purple-blue
            ]
      : isDark
          ? [
              const Color(0xFF51CF66), // Modern green
              const Color(0xFF40C057), // Deeper green
            ]
          : [
              const Color(0xFF69DB7C), // Soft green
              const Color(0xFF51CF66), // Medium green
            ];

  final Color shadowColor = isChart
      ? isDark
          ? const Color(0xFF4C6EF5).withOpacity(0.3)
          : const Color(0xFF6C7CE0).withOpacity(0.25)
      : isDark
          ? const Color(0xFF51CF66).withOpacity(0.3)
          : const Color(0xFF69DB7C).withOpacity(0.25);

  final Color iconColor = Colors.white.withOpacity(0.95);

  final Color textColor = Colors.white;

  final Color borderColor = Colors.white.withOpacity(0.2);

  return Container(
    height: 48,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: gradientColors,
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: borderColor,
        width: 0.5,
      ),
      boxShadow: [
        BoxShadow(
          color: shadowColor,
          blurRadius: 6,
          offset: const Offset(0, 2),
          spreadRadius: 0,
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        splashColor: Colors.white.withOpacity(0.15),
        highlightColor: Colors.white.withOpacity(0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: iconColor,
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    letterSpacing: 0.2,
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
