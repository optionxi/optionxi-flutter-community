// lib/Helpers/analytics_helper.dart

import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsHelper {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Log a screen view. Call this in initState() of every page.
  static Future<void> logScreen(String screenName,
      {String? screenClass}) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass ?? screenName,
    );
  }

  /// Log a generic custom event.
  // static Future<void> logEvent(
  //   String eventName, {
  //   Map<String, Object>? params,
  // }) async {
  //   await _analytics.logEvent(name: eventName, parameters: params);
  // }

  /// Log when a user taps a stock.
  static Future<void> logStockViewed(String stockName) async {
    await _analytics.logEvent(
      name: 'stock_viewed',
      parameters: {'stock_name': stockName},
    );
  }

  static Future<void> logStockSearched(String stockName) async {
    await _analytics.logEvent(
      name: 'stock_searched',
      parameters: {'stock_name': stockName},
    );
  }

  static Future<void> logStockAied(String stockName) async {
    await _analytics.logEvent(
      name: 'stock_ai',
      parameters: {'stock_name': stockName},
    );
  }

  /// Log when a user taps a stock.
  static Future<void> logButtonClick(String whichbutton) async {
    await _analytics.logEvent(
      name: 'buttonclicked',
      parameters: {'buttonname': whichbutton},
    );
  }

  /// Log virtual trade placement.
  static Future<void> logTradeAction({
    required String stockName,
    required String action, // 'buy' | 'sell'
    required String segment, // 'equity' | 'fno'
  }) async {
    await _analytics.logEvent(
      name: 'virtual_trade_placed',
      parameters: {
        'stock_name': stockName,
        'action': action,
        'segment': segment,
      },
    );
  }
}
