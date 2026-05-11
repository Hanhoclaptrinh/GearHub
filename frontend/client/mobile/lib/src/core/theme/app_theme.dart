import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // static const Color background = Color(0xFF07070A);
  // static const Color surface = Color(0xFF14141E);
  // static const Color primaryText = Color(0xFFF1F1F5);
  // static const Color secondaryText = Color(0xFF9191A8);
  // static const Color accent = Color(0xFF6366F1);

  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color primaryText = Color(0xFF0F172A);
  static const Color secondaryText = Color(0xFF475569);
  static const Color accent = Color(0xFF3B82F6);

  static ThemeData theme(BuildContext context) {
    final baseTheme = ThemeData.dark();
    final textTheme = GoogleFonts.beVietnamProTextTheme(baseTheme.textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      cardColor: surface,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        surface: surface,
        onSurface: primaryText,
        surfaceContainerHigh: Color(0xFF1C1C28),
        outlineVariant: Color(0xFF2A2A38),
        secondary: Color(0xFFFFCC00),
      ),
      textTheme: textTheme.apply(
        bodyColor: primaryText,
        displayColor: primaryText,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
