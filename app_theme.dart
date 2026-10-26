import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFF0B1020);
  static const Color surface = Color(0xFF121A2B);
  static const Color surfaceAlt = Color(0xFF182235);
  static const Color surfaceSoft = Color(0xFF1D2940);
  static const Color stroke = Color(0xFF2B3A57);

  static const Color textPrimary = Color(0xFFF6F8FC);
  static const Color textMuted = Color(0xFFB5C0D4);
  static const Color textSoft = Color(0xFF7E8BA3);

  static const Color cyan = Color(0xFF29D3C2);
  static const Color green = Color(0xFF3DDC97);
  static const Color blue = Color(0xFF6BA8FF);
  static const Color orange = Color(0xFFFFC857);
  static const Color red = Color(0xFFFF6B81);
  static const Color purple = Color(0xFFB79CFF);

  static const LinearGradient shellGradient = LinearGradient(
    colors: [Color(0xFF0B1020), Color(0xFF10192C), Color(0xFF0A1223)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static BoxDecoration panelDecoration({Color? borderColor}) {
    return BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: borderColor ?? stroke),
      boxShadow: const [
        BoxShadow(
          color: Color(0x22000000),
          blurRadius: 24,
          offset: Offset(0, 10),
        ),
      ],
    );
  }

  static ThemeData get darkTheme {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: cyan,
      brightness: Brightness.dark,
      surface: surface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme.copyWith(
        primary: cyan,
        secondary: blue,
        surface: surface,
      ),
      scaffoldBackgroundColor: background,
      splashFactory: InkSparkle.splashFactory,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: stroke),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceAlt,
        hintStyle: const TextStyle(color: textSoft),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: stroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: cyan, width: 1.4),
        ),
      ),
      dividerColor: stroke,
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: surfaceAlt,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 0,
        shape: StadiumBorder(),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceAlt,
        disabledColor: surfaceSoft,
        selectedColor: cyan.withOpacity(0.18),
        secondarySelectedColor: cyan.withOpacity(0.18),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: stroke),
        ),
        labelStyle: const TextStyle(
          color: textMuted,
          fontWeight: FontWeight.w700,
        ),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: textPrimary),
        bodySmall: TextStyle(color: textMuted),
        titleMedium: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
