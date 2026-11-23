import 'package:flutter/material.dart';

class TerminalTheme {
  static const red = Color(0xFFFF0000);
  static const panel = Color(0xD9000000);

  static final dark = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.black,
    colorScheme: const ColorScheme.dark(
      primary: red,
      secondary: red,
      surface: Color(0xFF080808),
      error: red,
    ),
    fontFamily: 'monospace',
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white, fontFamily: 'monospace'),
      bodyMedium: TextStyle(color: Colors.white, fontFamily: 'monospace'),
      bodySmall: TextStyle(color: Colors.white70, fontFamily: 'monospace'),
      titleLarge: TextStyle(
        color: Colors.white,
        fontFamily: 'monospace',
        fontWeight: FontWeight.bold,
      ),
      titleMedium: TextStyle(
        color: Colors.white,
        fontFamily: 'monospace',
        fontWeight: FontWeight.bold,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      labelStyle: const TextStyle(color: red),
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: red.withValues(alpha: 0.3)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: red),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: red),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: red),
      ),
    ),
    dividerColor: red.withValues(alpha: 0.3),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.black,
      selectedItemColor: red,
      unselectedItemColor: Colors.white54,
      type: BottomNavigationBarType.fixed,
    ),
  );
}
