import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:optionxi/Auth_Service/auth_service.dart';
import 'package:optionxi/Helpers/badge_service.dart';
import 'package:optionxi/Helpers/get_database.dart';
import 'package:optionxi/Login_Signup/login2.dart';
import 'package:optionxi/Main_Pages/act_alert_stocks.dart';
import 'package:optionxi/Main_Pages/act_notifications.dart';
import 'package:optionxi/Main_Pages/act_scanner_result.dart';
import 'package:optionxi/Main_Pages/act_search_stocks_meili.dart';
import 'package:optionxi/Main_Pages/act_stock_detail.dart';
import 'package:optionxi/PushNotification/notifcation_service.dart';
import 'package:optionxi/PushNotification/notifcation_service_firebase.dart';
import 'package:optionxi/Theme/theme_controller.dart';
import 'package:optionxi/VirtualTradeJournal/act_basket_fullpage.dart';
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

    // Step 2.5: Initialize Crashlytics
    await _initializeCrashlytics();

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

Future<void> _initializeCrashlytics() async {
  try {
    // Enable Crashlytics collection
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

    // Set up custom keys for better error tracking
    FirebaseCrashlytics.instance.setCustomKey('app_name', 'OptionXi');
    FirebaseCrashlytics.instance
        .setCustomKey('environment', kDebugMode ? 'debug' : 'production');

    debugPrint("Crashlytics initialized");
  } catch (e) {
    debugPrint('Crashlytics initialization error: $e');
  }
}

Future<void> _requestNotificationPermission() async {
  try {
    final status = await Permission.notification.status.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        debugPrint("Permission check timeout");
        return PermissionStatus.denied;
      },
    );

    if (status.isDenied) {
      final result = await Permission.notification.request().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint("Permission request timeout");
          return PermissionStatus.denied;
        },
      );
      debugPrint("Notification permission status: $result");
    }
  } catch (e) {
    debugPrint('Permission error: $e');
  }
}

Future<void> _initializeNotificationServices() async {
  try {
    await Future.wait([
      NotificationService().initNotification().timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          debugPrint("NotificationService timeout");
          return null; // Return null instead of throwing
        },
      ).catchError((e) {
        debugPrint("NotificationService error: $e");
        return null;
      }),
      NotificationServiceFirebase().initNotificationFirebase().timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          debugPrint("NotificationServiceFirebase timeout");
          return null;
        },
      ).catchError((e) {
        debugPrint("NotificationServiceFirebase error: $e");
        return null;
      }),
    ]);
    debugPrint("Notification services initialized");
  } catch (e) {
    debugPrint('Notification services error: $e');
    // Don't rethrow - allow app to continue
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
      GetPage(name: '/login', page: () => ModernLoginPage()),
      GetPage(name: '/messages', page: () => NotificationPage()),
      GetPage(name: '/basket', page: () => BasketFullPage()),
      GetPage(name: '/stocks', page: () => AllSearchPageMeili()),
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
