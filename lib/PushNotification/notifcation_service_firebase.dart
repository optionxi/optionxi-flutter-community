import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:optionxi/Helpers/badge_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optionxi/DB_Services/database_write.dart';
import 'package:optionxi/PushNotification/notifcation_service.dart';

// ─────────────────────────────────────────────────────────────
// Determine target route from message content
// ─────────────────────────────────────────────────────────────
String _getRouteForMessage(RemoteMessage message) {
  final type = message.data['type']?.toString().toLowerCase();

  if (type == null || type.isEmpty) {
    return '/home';
  }

  return '/$type';
}

// ─────────────────────────────────────────────────────────────
// Background handler — must be top-level, NO Get/context here
// ─────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
Future<void> handleMessageBackground(RemoteMessage message) async {
  debugPrint("Background message received: ${message.messageId}");

  final title = message.notification?.title?.toLowerCase() ?? '';
  if (title.contains('alert')) {
    BadgeService.incrementAlertBadge();
  } else {
    BadgeService.incrementNotificationsBadge();
  }

  // Store pending route so app can navigate when it opens
  final prefs = await SharedPreferences.getInstance();
  final route = _getRouteForMessage(message);
  await prefs.setString('pending_navigation_route', route);
  await prefs.setString('pending_navigation_data', jsonEncode(message.data));
  debugPrint("Background: stored pending route → $route");
}

// ─────────────────────────────────────────────────────────────
// Main Firebase notification service
// ─────────────────────────────────────────────────────────────
class NotificationServiceFirebase {
  static const String _tokenKey = 'fcm_token';
  static const String _pendingTokenKey = 'pending_fcm_token';
  String? _lastHandledMessageId;

  String? _currentToken;
  bool _isInitialized = false;

  static final NotificationServiceFirebase _instance =
      NotificationServiceFirebase._internal();
  factory NotificationServiceFirebase() => _instance;
  NotificationServiceFirebase._internal();

  Future<void> initNotificationFirebase() async {
    if (_isInitialized) return;

    try {
      final messaging = FirebaseMessaging.instance;

      await _requestPermission(messaging);
      await _getFCMToken(messaging);
      _setupTokenRefreshListener(messaging);
      await _subscribeToTopic(messaging);
      await _setupForegroundOptions(messaging);
      _setupMessageHandlers(messaging);
      _setupAuthStateListener();

      _isInitialized = true;
      debugPrint("Firebase messaging initialized successfully");
    } catch (e) {
      debugPrint("Firebase messaging initialization error: $e");
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Call this from Homepage.initState via addPostFrameCallback
  // Handles the case where app was killed and user tapped notification
  // ─────────────────────────────────────────────────────────────

  void _setupMessageHandlers(FirebaseMessaging messaging) {
    messaging.getInitialMessage().then((msg) {
      if (msg != null) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _navigateForMessage(msg);
        });
      }
    }).catchError((error) {
      debugPrint("Initial message error: $error");
      return null;
    });

    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      _navigateForMessage(msg);
    });

    FirebaseMessaging.onMessage.listen((msg) {
      _showForegroundNotification(msg);
    });

    FirebaseMessaging.onBackgroundMessage(handleMessageBackground);
  }

  void _navigateForMessage(RemoteMessage message) {
    // Idempotency guard: same message can't navigate twice
    final id = message.messageId;
    if (id != null && id == _lastHandledMessageId) {
      debugPrint("Duplicate navigation suppressed for $id");
      return;
    }
    _lastHandledMessageId = id;

    final route = _getRouteForMessage(message);
    debugPrint("Navigating to: $route");
    try {
      Get.toNamed(route, arguments: message.data);
    } catch (e) {
      debugPrint("Navigation error: $e");
    }
  }

  void _showForegroundNotification(RemoteMessage message) {
    try {
      final title = message.notification?.title?.toLowerCase() ?? '';
      if (title.contains('alert')) {
        BadgeService.incrementAlertBadge();
      } else {
        BadgeService.incrementNotificationsBadge();
      }

      final route = _getRouteForMessage(message);

      // Encode route + data as payload so tap handler routes correctly
      NotificationService().showNotificationBasic(
        id: message.hashCode,
        title: message.notification?.title ?? "Notification",
        body: message.notification?.body ?? "You have a new message",
        payLoad: jsonEncode({
          'route': route,
          'data': message.data,
        }),
      );
    } catch (e) {
      debugPrint("Notification display error: $e");
    }
  }

  Future<void> _requestPermission(FirebaseMessaging messaging) async {
    try {
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      debugPrint("Permission status: ${settings.authorizationStatus}");
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint("User denied permission - FCM may not work");
      }
    } catch (e) {
      debugPrint("Permission request error: $e");
    }
  }

  Future<void> _getFCMToken(FirebaseMessaging messaging) async {
    try {
      debugPrint("Attempting to get FCM token...");
      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        debugPrint("FCM token obtained: ${token.substring(0, 20)}...");
        _currentToken = token;
        await _storeTokenLocally(token);
        await _updateUserFCMToken(token);
      } else {
        debugPrint("Failed to get FCM token");
      }
    } catch (e) {
      debugPrint("FCM token error: $e");
    }
  }

  void _setupTokenRefreshListener(FirebaseMessaging messaging) {
    messaging.onTokenRefresh.listen((newToken) {
      debugPrint("FCM token refreshed: ${newToken.substring(0, 20)}...");
      _currentToken = newToken;
      _storeTokenLocally(newToken);
      _updateUserFCMToken(newToken);
    }).onError((error) {
      debugPrint("Token refresh error: $error");
    });
  }

  Future<void> _storeTokenLocally(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      debugPrint("Token stored locally");
    } catch (e) {
      debugPrint("Local token storage error: $e");
    }
  }

  Future<void> _updateUserFCMToken(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await DatabaseWriteService().updateUserFCM(user.uid, token);
        debugPrint("FCM token updated for user: ${user.uid}");
        await _clearPendingToken();
      } else {
        await _storePendingToken(token);
        debugPrint("User not authenticated, token stored as pending");
      }
    } catch (e) {
      debugPrint("FCM token update error: $e");
    }
  }

  Future<void> _storePendingToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pendingTokenKey, token);
    } catch (e) {
      debugPrint("Pending token storage error: $e");
    }
  }

  Future<void> _clearPendingToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pendingTokenKey);
    } catch (e) {
      debugPrint("Clear pending token error: $e");
    }
  }

  void _setupAuthStateListener() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        debugPrint("User authenticated: ${user.uid}");
        _onUserAuthenticated(user);
      } else {
        debugPrint("User signed out, FCM token retained for device");
      }
    });
  }

  Future<void> _onUserAuthenticated(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingToken = prefs.getString(_pendingTokenKey);

      if (pendingToken != null) {
        debugPrint("Updating pending FCM token for newly authenticated user");
        await DatabaseWriteService().updateUserFCM(user.uid, pendingToken);
        await _clearPendingToken();
      } else if (_currentToken != null) {
        debugPrint("Updating current FCM token for authenticated user");
        await DatabaseWriteService().updateUserFCM(user.uid, _currentToken!);
      } else {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          await DatabaseWriteService().updateUserFCM(user.uid, token);
          _currentToken = token;
          await _storeTokenLocally(token);
        }
      }
    } catch (e) {
      debugPrint("Error updating token for authenticated user: $e");
    }
  }

  Future<void> syncTokenWithUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _currentToken != null) {
      await DatabaseWriteService().updateUserFCM(user.uid, _currentToken!);
      debugPrint("Token manually synced with user: ${user.uid}");
    }
  }

  Future<void> forceRefreshAndSyncToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        _currentToken = token;
        await _storeTokenLocally(token);
        await _updateUserFCMToken(token);
        debugPrint("Force-refreshed token synced");
      } else {
        debugPrint("Force-refresh failed: no token obtained");
      }
    } catch (e) {
      debugPrint("Force-refresh token error: $e");
    }
  }

  Future<void> _subscribeToTopic(FirebaseMessaging messaging) async {
    try {
      await messaging.subscribeToTopic("updates");
      debugPrint("Subscribed to updates topic");
    } catch (e) {
      debugPrint("Topic subscription error: $e");
    }
  }

  Future<void> _setupForegroundOptions(FirebaseMessaging messaging) async {
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  String? getCurrentToken() => _currentToken;
  bool get isInitialized => _isInitialized;

  // For algo refresh token
  static const String _lastForceRefreshKey = 'last_token_forced_refresh';
  static const int _forceRefreshIntervalDays = 7;

  Future<void> ensureFreshTokenForAlgos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastRefreshMillis = prefs.getInt(_lastForceRefreshKey);
      final now = DateTime.now();

      if (lastRefreshMillis != null) {
        final last = DateTime.fromMillisecondsSinceEpoch(lastRefreshMillis);
        if (now.difference(last).inDays < _forceRefreshIntervalDays) {
          debugPrint(
              "Token force-refresh skipped — last done ${now.difference(last).inDays}d ago");
          return; // still fresh enough, skip the round-trip
        }
      }

      debugPrint("Forcing FCM token rotation for algo portal...");
      await FirebaseMessaging.instance.deleteToken();
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        _currentToken = token;
        await _storeTokenLocally(token);
        await _updateUserFCMToken(token);
        await prefs.setInt(_lastForceRefreshKey, now.millisecondsSinceEpoch);
        debugPrint("Algo-portal token force-refresh complete");
      }
    } catch (e) {
      debugPrint("Algo-portal token force-refresh error: $e");
    }
  }

  // End For algo refresh token
}
