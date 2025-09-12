import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BasketBadgeServiceObx extends GetxService {
  static const String _basketKey = 'basket_badge_count';

  // Reactive variable
  static RxInt basketBadgeCount = 0.obs;

  // Initialize the service and load stored count
  @override
  void onInit() {
    super.onInit();
    _loadBasketBadgeCount();
  }

  // Load badge count from SharedPreferences
  static Future<void> _loadBasketBadgeCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final count = prefs.getInt(_basketKey) ?? 0;
      basketBadgeCount.value = count;
    } catch (e) {
      debugPrint("Error loading basket badge count: $e");
    }
  }

  // Set badge count
  static Future<void> setBasketBadgeCount(int count) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_basketKey, count);
      basketBadgeCount.value = count;
    } catch (e) {
      debugPrint("Error setting basket badge count: $e");
    }
  }

  // Increment basket badge
  static Future<void> incrementBasketBadge() async {
    try {
      final newCount = basketBadgeCount.value + 1;
      await setBasketBadgeCount(newCount);
    } catch (e) {
      debugPrint("Error incrementing basket badge: $e");
    }
  }

  // Clear basket badge
  static Future<void> clearBasketBadge() async {
    try {
      await setBasketBadgeCount(0);
    } catch (e) {
      debugPrint("Error clearing basket badge: $e");
    }
  }

  // Get current count (synchronous)
  static int get currentCount => basketBadgeCount.value;
}
