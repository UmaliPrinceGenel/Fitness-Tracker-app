import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.black,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    colorScheme: const ColorScheme.dark(
      background: Colors.black,
      surface: Color(0xFF191919),
      primary: Colors.orange,
      secondary: Colors.deepPurpleAccent,
    ),
    cardColor: const Color(0xFF191919),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white),
    ),
  );

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF5F5F7), // Apple-like light gray background
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF5F5F7),
      iconTheme: IconThemeData(color: Colors.black),
      titleTextStyle: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    colorScheme: const ColorScheme.light(
      background: Color(0xFFF5F5F7),
      surface: Colors.white,
      primary: Colors.orange,
      secondary: Colors.deepPurpleAccent,
    ),
    cardColor: Colors.white,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black),
      bodyMedium: TextStyle(color: Colors.black),
    ),
  );
}
