import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color primaryText = Color(0xFF0F172A);
  static const Color secondaryText = Color(0xFF475569);
  static const Color accent = Color(0xFF3B82F6);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: accent,
        secondary: accent,
        background: background,
        surface: surface,
        onBackground: primaryText,
        onSurface: primaryText,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: primaryText,
          fontFamily: 'Orbitron',
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: primaryText,
          fontFamily: 'Orbitron',
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(color: primaryText, fontFamily: 'Exo 2'),
        bodyMedium: TextStyle(color: secondaryText, fontFamily: 'Exo 2'),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 2,
          textStyle: const TextStyle(
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.bold,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
