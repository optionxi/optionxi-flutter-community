import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Singleton
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> initNotification() async {
    debugPrint("Initing local notifications");

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('optionxilogo');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // ✅ When user taps local notification, route based on payload
        _handleNotificationTap(response.payload);
      },
    );
  }

  void _handleNotificationTap(String? payloadStr) {
    if (payloadStr == null || payloadStr.isEmpty) {
      Get.toNamed('/home');
      return;
    }

    try {
      final payload = jsonDecode(payloadStr) as Map<String, dynamic>;
      final route = payload['route'] as String? ?? '/home';
      final data = payload['data'];
      debugPrint("Local notification tapped → route: $route");
      Get.toNamed(route, arguments: data);
    } catch (e) {
      debugPrint("Notification tap parse error: $e");
      Get.toNamed('/home');
    }
  }

  NotificationDetails _notificationDetailsBasic() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'basic_notification',
        'Notifications',
        channelDescription: "To show notification from app",
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  Future<void> showNotificationBasic({
    int id = 0,
    String? title,
    String? body,
    String? payLoad, // ✅ payload carries route + data as JSON
  }) async {
    debugPrint("Showing notification: $title");
    await notificationsPlugin.show(
      id,
      title,
      body,
      _notificationDetailsBasic(),
      payload: payLoad, // ✅ pass it through so tap handler can read it
    );
  }
}
