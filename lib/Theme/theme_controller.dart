// Updated ThemeController - remove the conflicting updateTheme method
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController {
  static ThemeController get instance => Get.find();

  final _isDarkMode = false.obs;
  bool get isDarkMode => _isDarkMode.value;

  // Your existing light and dark themes (keep as they are)
  final lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Color(0xFF2962FF),
      brightness: Brightness.light,
      primary: Color(0xFF2962FF),
      secondary: Color(0xFF6200EA),
      surface: Colors.white,
      onSurface: Colors.black,
    ),
    scaffoldBackgroundColor: Colors.white,
    cardColor: Colors.white,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: Color(0xFF2962FF)),
      titleTextStyle: TextStyle(
        color: Colors.black,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: Colors.black),
      bodyMedium: TextStyle(color: Colors.black),
      titleLarge: TextStyle(color: Colors.black),
      titleMedium: TextStyle(color: Colors.black),
      titleSmall: TextStyle(color: Colors.grey[800]),
    ),
    iconTheme: IconThemeData(
      color: Color(0xFF2962FF),
    ),
    dividerColor: Colors.grey[300],
  );

  final darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Color(0xFF2962FF),
      brightness: Brightness.dark,
      primary: Color(0xFF2962FF),
      secondary: Color(0xFF6200EA),
      surface: Color(0xFF1E1E1E),
      onSurface: Colors.white,
    ),
    scaffoldBackgroundColor: Color(0xFF121212),
    cardColor: Color(0xFF1E1E1E),
    dividerColor: Colors.grey[850],
    appBarTheme: AppBarTheme(
      backgroundColor: Color(0xFF121212),
      elevation: 0,
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white),
      titleLarge: TextStyle(color: Colors.white),
      titleMedium: TextStyle(color: Colors.white),
      titleSmall: TextStyle(color: Colors.grey[400]),
    ),
    iconTheme: IconThemeData(
      color: Color(0xFF2962FF),
    ),
  );

  // Initialize theme from shared preferences
  Future<void> initTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isDarkMode.value = prefs.getBool('isDarkMode') ?? true;
    // Remove the updateTheme() call from here
  }

  // Toggle theme method - simplified
  Future<void> toggleTheme() async {
    _isDarkMode.value = !_isDarkMode.value;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode.value);
    // The UI will automatically rebuild because MyApp is now wrapped with GetX
  }

  // Remove the updateTheme() method entirely since it conflicts with themeMode
}
