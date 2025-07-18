import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BadgeService {
  static const String _ordersKey = 'orders_badge_count';
  static const String _portfolioKey = 'portfolio_badge_count';
  static const String _notificationsKey = 'notifications_badge_count';

  // Stream controllers for real-time updates
  static final StreamController<int> _ordersController =
      StreamController<int>.broadcast();
  static final StreamController<int> _portfolioController =
      StreamController<int>.broadcast();
  static final StreamController<int> _notificationsController =
      StreamController<int>.broadcast();

  // Streams for listening to badge changes
  static Stream<int> get ordersStream => _ordersController.stream;
  static Stream<int> get portfolioStream => _portfolioController.stream;
  static Stream<int> get notificationsStream => _notificationsController.stream;

  // Get badge count for orders
  static Future<int> getOrdersBadgeCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_ordersKey) ?? 0;
    } catch (e) {
      debugPrint("Error getting orders badge count: $e");
      return 0;
    }
  }

  // Get badge count for portfolio
  static Future<int> getPortfolioBadgeCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_portfolioKey) ?? 0;
    } catch (e) {
      debugPrint("Error getting portfolio badge count: $e");
      return 0;
    }
  }

  // Get badge count for notifications
  static Future<int> getNotificationsBadgeCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_notificationsKey) ?? 0;
    } catch (e) {
      debugPrint("Error getting notifications badge count: $e");
      return 0;
    }
  }

  // Set badge count for orders
  static Future<void> setOrdersBadgeCount(int count) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_ordersKey, count);
      _ordersController.add(count); // Notify listeners
    } catch (e) {
      debugPrint("Error setting orders badge count: $e");
    }
  }

  // Set badge count for portfolio
  static Future<void> setPortfolioBadgeCount(int count) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_portfolioKey, count);
      _portfolioController.add(count); // Notify listeners
    } catch (e) {
      debugPrint("Error setting portfolio badge count: $e");
    }
  }

  // Set badge count for notifications
  static Future<void> setNotificationsBadgeCount(int count) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_notificationsKey, count);
      _notificationsController.add(count); // Notify listeners
    } catch (e) {
      debugPrint("Error setting notifications badge count: $e");
    }
  }

  // Increment orders badge
  static Future<void> incrementOrdersBadge() async {
    try {
      final current = await getOrdersBadgeCount();
      await setOrdersBadgeCount(current + 1);
    } catch (e) {
      debugPrint("Error incrementing orders badge: $e");
    }
  }

  // Increment portfolio badge
  static Future<void> incrementPortfolioBadge() async {
    try {
      final current = await getPortfolioBadgeCount();
      await setPortfolioBadgeCount(current + 1);
    } catch (e) {
      debugPrint("Error incrementing portfolio badge: $e");
    }
  }

  // Increment notifications badge
  static Future<void> incrementNotificationsBadge() async {
    try {
      final current = await getNotificationsBadgeCount();
      await setNotificationsBadgeCount(current + 1);
    } catch (e) {
      debugPrint("Error incrementing notifications badge: $e");
    }
  }

  // Clear orders badge
  static Future<void> clearOrdersBadge() async {
    try {
      await setOrdersBadgeCount(0);
    } catch (e) {
      debugPrint("Error clearing orders badge: $e");
    }
  }

  // Clear portfolio badge
  static Future<void> clearPortfolioBadge() async {
    try {
      await setPortfolioBadgeCount(0);
    } catch (e) {
      debugPrint("Error clearing portfolio badge: $e");
    }
  }

  // Clear notifications badge
  static Future<void> clearNotificationsBadge() async {
    try {
      await setNotificationsBadgeCount(0);
    } catch (e) {
      debugPrint("Error clearing notifications badge: $e");
    }
  }

  // Initialize streams with current values
  static Future<void> initializeBadgeStreams() async {
    try {
      final orders = await getOrdersBadgeCount();
      final portfolio = await getPortfolioBadgeCount();
      final notifications = await getNotificationsBadgeCount();

      _ordersController.add(orders);
      _portfolioController.add(portfolio);
      _notificationsController.add(notifications);
    } catch (e) {
      debugPrint("Error initializing badge streams: $e");
    }
  }

  // Dispose streams (call this when app is closing)
  static void dispose() {
    _ordersController.close();
    _portfolioController.close();
    _notificationsController.close();
  }

  // Get total badge count (sum of all badges)
  static Future<int> getTotalBadgeCount() async {
    try {
      final orders = await getOrdersBadgeCount();
      final portfolio = await getPortfolioBadgeCount();
      final notifications = await getNotificationsBadgeCount();
      return orders + portfolio + notifications;
    } catch (e) {
      debugPrint("Error getting total badge count: $e");
      return 0;
    }
  }

  // Clear all badges
  static Future<void> clearAllBadges() async {
    try {
      await Future.wait([
        clearOrdersBadge(),
        clearPortfolioBadge(),
        clearNotificationsBadge(),
      ]);
    } catch (e) {
      debugPrint("Error clearing all badges: $e");
    }
  }

  // Debug method to print all badge counts
  static Future<void> debugBadgeStatus() async {
    try {
      final orders = await getOrdersBadgeCount();
      final portfolio = await getPortfolioBadgeCount();
      final notifications = await getNotificationsBadgeCount();
      final total = await getTotalBadgeCount();

      debugPrint("=== BADGE STATUS DEBUG ===");
      debugPrint("Orders badge: $orders");
      debugPrint("Portfolio badge: $portfolio");
      debugPrint("Notifications badge: $notifications");
      debugPrint("Total badges: $total");
      debugPrint("=== END BADGE DEBUG ===");
    } catch (e) {
      debugPrint("Error in badge debug: $e");
    }
  }

// Enhanced stream getter that provides initial value
  static Stream<int> get notificationsStreamWithInitial async* {
    // First, yield the current stored value
    yield await getNotificationsBadgeCount();

    // Then, yield all future updates
    yield* _notificationsController.stream;
  }

// Enhanced stream getter for orders
  static Stream<int> get ordersStreamWithInitial async* {
    yield await getOrdersBadgeCount();
    yield* _ordersController.stream;
  }

// Enhanced stream getter for portfolio
  static Stream<int> get portfolioStreamWithInitial async* {
    yield await getPortfolioBadgeCount();
    yield* _portfolioController.stream;
  }
}
