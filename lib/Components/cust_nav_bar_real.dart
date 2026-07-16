import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';

class ModernTradingBottomNavFloating extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const ModernTradingBottomNavFloating({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(isDarkMode ? 0.05 : 0.15),
          width: 0.6,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.white.withOpacity(0.6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0),
              child: Stack(
                children: [
                  // Animated floating indicator
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOutCubic,
                    left: _getIndicatorPosition(currentIndex, context),
                    top: 6,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOutCubic,
                      width: _getItemWidth(context),
                      height: 68,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primaryColor.withOpacity(0.18),
                            primaryColor.withOpacity(0.06),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: primaryColor.withOpacity(0.25),
                          width: 1,
                        ),
                      ),
                    )
                        .animate()
                        .scale(
                          begin: const Offset(0.9, 0.9),
                          end: const Offset(1, 1),
                          duration: 300.ms,
                          curve: Curves.easeOutBack,
                        )
                        .fadeIn(duration: 250.ms),
                  ),
                  // Navigation items
                  Row(
                    children: [
                      _buildNavItem(
                          0, FontAwesomeIcons.bookmark, "Watchlist", context),
                      _buildNavItem(1, FontAwesomeIcons.arrowRightArrowLeft,
                          "Orders", context),
                      _buildNavItem(
                          2, FontAwesomeIcons.chartLine, "Portfolio", context),
                      _buildNavItem(
                          3, FontAwesomeIcons.user, "Profile", context),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _getIndicatorPosition(int index, BuildContext context) {
    final itemWidth = _getItemWidth(context);
    return (index * itemWidth);
  }

  double _getItemWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final containerWidth = screenWidth - 40; // margin
    final availableWidth = containerWidth - 12; // padding
    return availableWidth / 4; // 4 items
  }

  Widget _buildNavItem(
      int index, IconData icon, String label, BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final isDarkMode = theme.brightness == Brightness.dark;
    final inactiveColor =
        theme.colorScheme.onSurface.withOpacity(isDarkMode ? 0.6 : 0.7);
    final isSelected = currentIndex == index;
    final isEdge = index == 0 || index == 3; // First or last item

    return Expanded(
      child: Container(
        // Add margin for edge items to prevent clipping
        margin: EdgeInsets.symmetric(
          horizontal: isEdge ? 2.0 : 0.0,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(isEdge ? 20 : 16),
          child: InkWell(
            onTap: () => onTap(index),
            borderRadius: BorderRadius.circular(isEdge ? 20 : 16),
            splashColor: primaryColor.withOpacity(0.12),
            highlightColor: primaryColor.withOpacity(0.08),
            child: Container(
              height: 80,
              width: double.infinity,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    alignment: Alignment.center,
                    child: AnimatedScale(
                      scale: isSelected ? 1.15 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutBack,
                      child: FaIcon(
                        icon,
                        size: 20,
                        color: isSelected ? primaryColor : inactiveColor,
                        shadows: isSelected
                            ? [
                                Shadow(
                                  color: primaryColor.withOpacity(0.4),
                                  blurRadius: 6,
                                )
                              ]
                            : [],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    alignment: Alignment.center,
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 250),
                      style: GoogleFonts.inter(
                        fontSize: isSelected ? 12 : 11,
                        letterSpacing: 0.2,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? primaryColor : inactiveColor,
                      ),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
