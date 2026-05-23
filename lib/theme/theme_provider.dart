import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  final ThemeMode _themeMode = ThemeMode.dark;

  ThemeProvider();

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => true;

  Future<void> toggleTheme(bool isDark) async {
    // Theme toggling is disabled.
  }
}
