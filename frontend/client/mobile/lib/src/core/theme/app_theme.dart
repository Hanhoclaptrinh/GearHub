import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // light theme
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color primaryText = Color(0xFF0F172A);
  static const Color secondaryText = Color(0xFF475569);
  static const Color accent = Color(0xFF3B82F6);

  // dark theme (splash & ob)
  static const Color darkBg = Color(0xFF101A32);
  static const Color darkSurface = Color(0xFF261E35);
  static const Color darkAccent = Color(0xFF6366F1);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkGlass = Color(0x33FFFFFF);

  static ThemeData theme(BuildContext context, {bool isDark = false}) {
    final baseTheme = isDark ? ThemeData.dark() : ThemeData.light();

    final textTheme = GoogleFonts.beVietnamProTextTheme(baseTheme.textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: isDark ? darkBg : background,
      colorScheme: isDark
          ? const ColorScheme.dark(
              primary: darkAccent,
              surface: darkSurface,
              onSurface: Colors.white,
            )
          : const ColorScheme.light(
              primary: accent,
              surface: surface,
              onSurface: primaryText,
            ),
      textTheme: textTheme.copyWith(
        headlineLarge: textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : primaryText,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? darkAccent : accent,
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
