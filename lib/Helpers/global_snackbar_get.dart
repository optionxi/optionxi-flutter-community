import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GlobalSnackBarGet {
  // Modern design constants
  static const _animationDuration = Duration(milliseconds: 600);
  static const _borderRadius = 16.0;
  static const _padding =
      EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0);
  static final _defaultMargin = EdgeInsets.only(
    top: Get.height * 0.02,
    left: 16,
    right: 16,
  );
  static final _bottomMargin = EdgeInsets.only(
    bottom: Get.height * 0.1,
    left: 16,
    right: 16,
  );

  // Enhanced shadow for depth
  static final List<BoxShadow> _shadows = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.03),
      offset: const Offset(0, 4),
      blurRadius: 12,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.02),
      offset: const Offset(0, 2),
      blurRadius: 6,
      spreadRadius: 0,
    ),
  ];

  // Modern color palette with glass effect
  static final _errorBackground = Colors.red.shade50.withValues(alpha: 0.95);
  static final _successBackground =
      Colors.green.shade50.withValues(alpha: 0.95);

  void showGetError(String head, String title) {
    Get.snackbar(
      '',
      '',
      titleText: Text(
        head,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
          letterSpacing: -0.5,
        ),
      ),
      messageText: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black54,
          height: 1.4,
          letterSpacing: -0.2,
        ),
      ),
      snackPosition: SnackPosition.TOP,
      backgroundColor: _errorBackground,
      borderRadius: _borderRadius,
      margin: _defaultMargin,
      padding: _padding,
      duration: const Duration(seconds: 2),
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      forwardAnimationCurve: Curves.easeOutCubic,
      reverseAnimationCurve: Curves.easeInCubic,
      animationDuration: _animationDuration,
      overlayBlur: 2.0,
      overlayColor: Colors.black.withValues(alpha: 0.05),
      icon: Icon(
        Icons.error_outline_rounded,
        color: Colors.red.shade300,
        size: 28,
      ),
      shouldIconPulse: true,
      boxShadows: _shadows,
      barBlur: 8.0,
      snackStyle: SnackStyle.FLOATING,
    );
  }

  void showGetSucess(String head, String title, {int durationMs = 2000}) {
    Get.snackbar(
      '',
      '',
      titleText: Text(
        head,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
          letterSpacing: -0.5,
        ),
      ),
      messageText: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black54,
          height: 1.4,
          letterSpacing: -0.2,
        ),
      ),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: _successBackground,
      borderRadius: _borderRadius,
      margin: _bottomMargin,
      padding: _padding,
      duration: Duration(milliseconds: durationMs),
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      forwardAnimationCurve: Curves.easeOutCubic,
      reverseAnimationCurve: Curves.easeInCubic,
      animationDuration: _animationDuration,
      overlayBlur: 3.0,
      overlayColor: Colors.black.withValues(alpha: 0.05),
      icon: Icon(
        Icons.check_circle_outline_rounded,
        color: Colors.green.shade300,
        size: 28,
      ),
      shouldIconPulse: true,
      boxShadows: _shadows,
      barBlur: 8.0,
      snackStyle: SnackStyle.FLOATING,
    );
  }

  void showGetSuccessOnTop(String head, String title,
      {Color? backgroundColor}) {
    Get.snackbar(
      '',
      '',
      titleText: Text(
        head,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
          letterSpacing: -0.5,
        ),
      ),
      messageText: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black54,
          height: 1.4,
          letterSpacing: -0.2,
        ),
      ),
      snackPosition: SnackPosition.TOP,
      backgroundColor:
          backgroundColor ?? _successBackground, // <-- uses default if null
      borderRadius: _borderRadius,
      margin: _defaultMargin,
      padding: _padding,
      duration: const Duration(seconds: 2),
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      forwardAnimationCurve: Curves.easeOutCubic,
      reverseAnimationCurve: Curves.easeInCubic,
      animationDuration: _animationDuration,
      overlayBlur: 2.0,
      overlayColor: Colors.black.withOpacity(0.05),
      icon: Icon(
        Icons.check_circle_outline_rounded,
        color: Colors.green.shade300,
        size: 28,
      ),
      shouldIconPulse: true,
      boxShadows: _shadows,
      barBlur: 8.0,
      snackStyle: SnackStyle.FLOATING,
    );
  }

  void showGetSuccess2(String head, String title, int duration) {
    Get.snackbar(
      '',
      '',
      titleText: Text(
        head,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
          letterSpacing: -0.5,
        ),
      ),
      messageText: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black54,
          height: 1.4,
          letterSpacing: -0.2,
        ),
      ),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: _successBackground,
      borderRadius: _borderRadius,
      margin: _bottomMargin,
      padding: _padding,
      duration: Duration(seconds: duration),
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      forwardAnimationCurve: Curves.easeOutCubic,
      reverseAnimationCurve: Curves.easeInCubic,
      animationDuration: _animationDuration,
      overlayBlur: 2.0,
      overlayColor: Colors.black.withValues(alpha: 0.05),
      icon: Icon(
        Icons.check_circle_outline_rounded,
        color: Colors.green.shade300,
        size: 28,
      ),
      shouldIconPulse: true,
      boxShadows: _shadows,
      barBlur: 8.0,
      snackStyle: SnackStyle.FLOATING,
    );
  }
}
