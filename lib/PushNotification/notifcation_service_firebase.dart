import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:optionxi/Helpers/badge_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optionxi/DB_Services/database_write.dart';
import 'package:optionxi/PushNotification/notifcation_service.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> handleMessageBackground(RemoteMessage? message) async {
  if (message == null) return;
  debugPrint("Background message received");
  navigatorKey.currentState?.pushNamed("/messages", arguments: message);
}

class NotificationServiceFirebase {
  static const String _tokenKey = 'fcm_token';
  static const String _pendingTokenKey = 'pending_fcm_token';

  String? _currentToken;
  bool _isInitialized = false;

  // Singleton pattern
  static final NotificationServiceFirebase _instance =
      NotificationServiceFirebase._internal();
  factory NotificationServiceFirebase() => _instance;
  NotificationServiceFirebase._internal();

  Future<void> initNotificationFirebase() async {
    if (_isInitialized) return;

    try {
      final messaging = FirebaseMessaging.instance;

      // Step 1: Request permissions first
      await _requestPermission(messaging);

      // Step 2: Get FCM token (regardless of auth state)
      await _getFCMToken(messaging);

      // Step 3: Setup token refresh listener
      _setupTokenRefreshListener(messaging);

      // Step 4: Setup other Firebase messaging features
      await _subscribeToTopic(messaging);
      await _setupForegroundOptions(messaging);
      _setupMessageHandlers(messaging);

      // Step 5: Setup auth state listener
      _setupAuthStateListener();

      _isInitialized = true;
      debugPrint("Firebase messaging initialized successfully");
    } catch (e) {
      debugPrint("Firebase messaging initialization error: $e");
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

        // Store token locally
        await _storeTokenLocally(token);

        // Try to update user's token if authenticated
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

  // Future<String?> _getStoredToken() async {
  //   try {
  //     final prefs = await SharedPreferences.getInstance();
  //     return prefs.getString(_tokenKey);
  //   } catch (e) {
  //     debugPrint("Get stored token error: $e");
  //     return null;
  //   }
  // }

  Future<void> _updateUserFCMToken(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // User is authenticated, update their token
        await DatabaseWriteService().updateUserFCM(user.uid, token);
        debugPrint("FCM token updated for user: ${user.uid}");

        // Clear any pending token
        await _clearPendingToken();
      } else {
        // User is not authenticated, store as pending
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
        debugPrint("User signed out");
        _onUserSignedOut();
      }
    });
  }

  Future<void> _onUserAuthenticated(User user) async {
    try {
      // Check if we have a pending token to update
      final prefs = await SharedPreferences.getInstance();
      final pendingToken = prefs.getString(_pendingTokenKey);

      if (pendingToken != null) {
        debugPrint("Updating pending FCM token for newly authenticated user");
        await DatabaseWriteService().updateUserFCM(user.uid, pendingToken);
        await _clearPendingToken();
      } else if (_currentToken != null) {
        // Use current token if available
        debugPrint("Updating current FCM token for authenticated user");
        await DatabaseWriteService().updateUserFCM(user.uid, _currentToken!);
      } else {
        // Get fresh token for authenticated user
        final messaging = FirebaseMessaging.instance;
        final token = await messaging.getToken();
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

  Future<void> _onUserSignedOut() async {
    try {
      // Optionally clear user-specific data
      // Keep the FCM token as it's device-specific, not user-specific
      debugPrint("User signed out, FCM token retained for device");
    } catch (e) {
      debugPrint("Error handling user sign out: $e");
    }
  }

  // Public method to manually sync token (call after login)
  Future<void> syncTokenWithUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _currentToken != null) {
      await DatabaseWriteService().updateUserFCM(user.uid, _currentToken!);
      debugPrint("Token manually synced with user: ${user.uid}");
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

  void _setupMessageHandlers(FirebaseMessaging messaging) {
    messaging.getInitialMessage().then((msg) {
      if (msg != null) {
        debugPrint("Initial message received");
        handleMessage(msg);
      }
    }).catchError((error) {
      debugPrint("Initial message error: $error");
      return null;
    });

    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      debugPrint("Background message opened");
      handleMessage(msg);
      _showNotification(msg);
    });

    FirebaseMessaging.onMessage.listen((msg) {
      debugPrint("Foreground message received");
      _showNotification(msg);
    });

    FirebaseMessaging.onBackgroundMessage(handleMessageBackground);
  }

  void _showNotification(RemoteMessage message) {
    try {
      // Increment the notifications badge count
      BadgeService.incrementNotificationsBadge();

      NotificationService().showNotificationBasic(
        id: 0,
        title: message.notification?.title ?? "Notification",
        body: message.notification?.body ?? "You have a new message",
        payLoad: jsonEncode(message.data),
      );
    } catch (e) {
      debugPrint("Notification display error: $e");
    }
  }

  // Update the handleMessage method in NotificationServiceFirebase
  void handleMessage(RemoteMessage? message) {
    if (message == null) return;

    try {
      navigatorKey.currentState?.pushNamed("/messages", arguments: message);
    } catch (e) {
      debugPrint("Message navigation error: $e");
    }
  }

  // Method to get current token
  String? getCurrentToken() => _currentToken;

  // Method to check if service is initialized
  bool get isInitialized => _isInitialized;
}
