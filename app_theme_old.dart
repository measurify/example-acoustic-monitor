import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFF0F0F0F);
  static const Color surface = Color(0xFF171A20);
  static const Color surfaceAlt = Color(0xFF131922);
  static const Color stroke = Color(0xFF2A3342);

  static const Color textPrimary = Colors.white;
  static const Color textMuted = Colors.white70;

  static const Color cyan = Color(0xFF20D6C7);
  static const Color green = Color(0xFF34D399);
  static const Color blue = Color(0xFF60A5FA);
  static const Color orange = Color(0xFFFBBF24);
  static const Color red = Color(0xFFFF5D73);
  static const Color purple = Color(0xFFB388FF);

  static ThemeData get darkTheme {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: cyan,
      brightness: Brightness.dark,
      surface: surface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: stroke),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: cyan),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: cyan.withOpacity(0.18),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}