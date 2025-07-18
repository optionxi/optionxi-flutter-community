import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:optionxi/Auth_Service/auth_service.dart';
import 'package:optionxi/Helpers/badge_service.dart';
import 'package:optionxi/Helpers/get_database.dart';
import 'package:optionxi/Login_Signup/login.dart';
import 'package:optionxi/Main_Pages/act_alert_stocks.dart';
import 'package:optionxi/Main_Pages/act_notifications.dart';
import 'package:optionxi/Main_Pages/act_scanner_result.dart';
import 'package:optionxi/Main_Pages/act_search_stocks.dart';
import 'package:optionxi/Main_Pages/act_stock_detail.dart';
import 'package:optionxi/PushNotification/notifcation_service.dart';
import 'package:optionxi/PushNotification/notifcation_service_firebase.dart';
import 'package:optionxi/Theme/theme_controller.dart';
import 'package:optionxi/homepage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest.dart' as tz_data;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _initializeApp();

  final themeController = Get.put(ThemeController());
  await themeController.initTheme();

  runApp(const MyApp());
}

Future<void> _initializeApp() async {
  try {
    // Step 1: Load environment variables
    await dotenv.load();

    // Step 2: Initialize Firebase (required for FCM)
    await Firebase.initializeApp();
    debugPrint("Firebase initialized");

    // Step 3: Initialize Supabase
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
    debugPrint("Supabase initialized");

    // Step 4: Initialize database
    await Get.put(Database()).initStorage();
    debugPrint("Database initialized");

    // Step 5: Initialize services in parallel
    await Future.wait([
      _requestNotificationPermission(),
      _initializeNotificationServices(),
      _initializeRemoteConfig(),
    ]);

    // Step 6: Initialize timezone data
    _initializeTimezones();

    // Initialize badge service
    await BadgeService
        .initializeBadgeStreams(); // For StreamController approach

    debugPrint("App initialization completed successfully");
  } catch (e) {
    debugPrint('App initialization error: $e');
  }
}

Future<void> _requestNotificationPermission() async {
  try {
    final isDenied = await Permission.notification.isDenied;
    if (isDenied) {
      final status = await Permission.notification.request();
      debugPrint("Notification permission status: $status");
    }
  } catch (e) {
    debugPrint('Permission error: $e');
  }
}

Future<void> _initializeNotificationServices() async {
  try {
    // Initialize both services in parallel
    await Future.wait([
      NotificationService().initNotification().timeout(
            const Duration(seconds: 2),
            onTimeout: () => debugPrint("NotificationService timeout"),
          ),
      NotificationServiceFirebase().initNotificationFirebase().timeout(
            const Duration(seconds: 2),
            onTimeout: () => debugPrint("NotificationServiceFirebase timeout"),
          ),
    ]);

    debugPrint("Notification services initialized");

    // Optional: Debug FCM status
    // await NotificationServiceFirebase().debugTokenStatus();
  } catch (e) {
    debugPrint('Notification services error: $e');
  }
}

Future<void> _initializeRemoteConfig() async {
  try {
    final remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: const Duration(hours: 1),
    ));

    await remoteConfig.fetchAndActivate().timeout(
          const Duration(seconds: 10),
        );

    debugPrint("Remote Config initialized");
  } catch (e) {
    debugPrint('Remote Config error: $e');
  }
}

void _initializeTimezones() {
  tz_data.initializeTimeZones();
  debugPrint("Timezones initialized");
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  @override
  Widget build(BuildContext context) {
    _setUserProperty();

    return GetX<ThemeController>(
      builder: (themeController) {
        return GetMaterialApp(
          title: 'Option Xi',
          debugShowCheckedModeBanner: false,
          theme: themeController.lightTheme,
          darkTheme: themeController.darkTheme,
          themeMode:
              themeController.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: AuthService().handleAuthState(),
          getPages: _buildRoutes(),
        );
      },
    );
  }

  List<GetPage> _buildRoutes() {
    return [
      GetPage(name: '/home', page: () => Homepage()),
      GetPage(name: '/login', page: () => ModernTradingLoginPage()),
      GetPage(name: '/messages', page: () => NotificationPage()),
      GetPage(name: '/stocks', page: () => StockSearchPage(false)),
      GetPage(
        name: '/stocks/:stockName',
        page: () {
          final stockName = Get.parameters['stockName'] ?? '';
          return StockDetailPage(stockname: stockName);
        },
        transition: Transition.rightToLeft,
      ),
      GetPage(
        name: '/alerts/:stockName',
        page: () {
          final stockName = Get.parameters['stockName'];
          return StockAlertsPage(stockName);
        },
        transition: Transition.rightToLeft,
      ),
      GetPage(
        name: '/scanners/:scanName',
        page: () {
          final scanName = Get.parameters['scanName'] ?? '';
          final arguments = Get.arguments as Map<String, dynamic>?;
          final category = arguments?['category'] as String?;

          return ScannerDetailPage(
            scanName: scanName,
            category: category,
          );
        },
      ),
      GetPage(
        name: '/trade/orders',
        page: () => Homepage(initialIndex: 1, tradeFragIndex: 1),
        transition: Transition.fade,
      ),
      GetPage(
        name: '/trade/watchlist',
        page: () => Homepage(initialIndex: 1, tradeFragIndex: 0),
        transition: Transition.fade,
      ),
    ];
  }

  void _setUserProperty() {
    analytics.setUserProperty(name: 'regular', value: 'user').catchError(
      (error) {
        debugPrint('Analytics error: $error');
        return null;
      },
    );
  }
}
