import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

///color scheme for app
///usage: Theme.of(context).colorScheme.success
extension GearHubColorScheme on ColorScheme {
  Color get success => brightness == Brightness.dark
      ? const Color(0xFF22C55E)
      : const Color(0xFF15803D);

  Color get warning => brightness == Brightness.dark
      ? const Color(0xFFF59E0B)
      : const Color(0xFFB45309);

  Color get danger => brightness == Brightness.dark
      ? const Color(0xFFEF4444)
      : const Color(0xFFDC2626);

  Color get info => brightness == Brightness.dark
      ? const Color(0xFF3B82F6)
      : const Color(0xFF2563EB);
}

class AppTheme {
  AppTheme._();

  ///dark mode palette
  static const _darkBackground = Color(0xFF07070A);
  static const _darkSurface = Color(0xFF14141E);
  static const _darkSurfaceVariant = Color(0xFF1C1C28);
  static const _darkOnSurface = Color(0xFFF1F1F5);
  static const _darkOnSurfaceVariant = Color(0xFFA1A1AA);
  static const _darkOutlineVariant = Color(0xFF2A2A36);
  static const _darkPrimary = Color(0xFFF5F7FA);
  static const _darkOnPrimary = Color(0xFF07070A);
  static const _darkSecondary = Color(0xFFFFCC00);

  ///light mode palette
  static const _lightBackground = Color(0xFFF8F9FC);
  static const _lightSurface = Color(0xFFFFFFFF);
  static const _lightSurfaceVariant = Color(0xFFF1F3F7);
  static const _lightOnSurface = Color(0xFF1A1D26);
  static const _lightOnSurfaceVariant = Color(0xFF606575);
  static const _lightOutlineVariant = Color(0xFFE2E5EC);
  static const _lightPrimary = Color(0xFF111318);
  static const _lightOnPrimary = Color(0xFFFFFFFF);
  static const _lightSecondary = Color(0xFFD4A500);

  ///common accent
  static const accent = Color(0xFF6366F1);

  ///dark mode
  static ThemeData get darkTheme {
    final baseTheme = ThemeData.dark();
    final textTheme = GoogleFonts.beVietnamProTextTheme(baseTheme.textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _darkBackground,
      canvasColor: _darkBackground,
      cardColor: _darkSurface,
      colorScheme: const ColorScheme.dark(
        primary: _darkPrimary,
        onPrimary: _darkOnPrimary,
        secondary: _darkSecondary,
        surface: _darkSurface,
        onSurface: _darkOnSurface,
        onSurfaceVariant: _darkOnSurfaceVariant,
        surfaceContainerHighest: _darkSurfaceVariant,
        outlineVariant: _darkOutlineVariant,
      ),
      textTheme: textTheme.apply(
        bodyColor: _darkOnSurface,
        displayColor: _darkOnSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _darkBackground,
        foregroundColor: _darkOnSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          color: _darkOnSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _darkBackground,
        selectedItemColor: _darkOnSurface,
        unselectedItemColor: _darkOnSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _darkBackground,
        indicatorColor: _darkPrimary.withValues(alpha: 0.1),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _darkOnSurface,
            );
          }
          return const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: _darkOnSurfaceVariant,
          );
        }),
      ),
      cardTheme: CardThemeData(
        color: _darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _darkOutlineVariant, width: 0.5),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _darkSurfaceVariant,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: _darkOnSurface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkSurfaceVariant,
        hintStyle: const TextStyle(color: _darkOnSurfaceVariant),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _darkOutlineVariant, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _darkOutlineVariant, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _darkPrimary, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _darkPrimary,
          foregroundColor: _darkOnPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _darkOnSurface,
          side: const BorderSide(color: _darkOutlineVariant, width: 0.8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: _darkOnSurface),
      ),
      iconTheme: const IconThemeData(color: _darkOnSurface, size: 22),
      dividerTheme: const DividerThemeData(
        color: _darkOutlineVariant,
        thickness: 0.5,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _darkSurfaceVariant,
        labelStyle: const TextStyle(color: _darkOnSurface, fontSize: 12),
        side: const BorderSide(color: _darkOutlineVariant, width: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
    );
  }

  ///light mode
  static ThemeData get lightTheme {
    final baseTheme = ThemeData.light();
    final textTheme = GoogleFonts.beVietnamProTextTheme(baseTheme.textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: _lightBackground,
      canvasColor: _lightBackground,
      cardColor: _lightSurface,
      colorScheme: const ColorScheme.light(
        primary: _lightPrimary,
        onPrimary: _lightOnPrimary,
        secondary: _lightSecondary,
        surface: _lightSurface,
        onSurface: _lightOnSurface,
        onSurfaceVariant: _lightOnSurfaceVariant,
        surfaceContainerHighest: _lightSurfaceVariant,
        outlineVariant: _lightOutlineVariant,
      ),
      textTheme: textTheme.apply(
        bodyColor: _lightOnSurface,
        displayColor: _lightOnSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _lightBackground,
        foregroundColor: _lightOnSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          color: _lightOnSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _lightSurface,
        selectedItemColor: _lightOnSurface,
        unselectedItemColor: _lightOnSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _lightSurface,
        indicatorColor: _lightPrimary.withValues(alpha: 0.08),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _lightOnSurface,
            );
          }
          return const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: _lightOnSurfaceVariant,
          );
        }),
      ),
      cardTheme: CardThemeData(
        color: _lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _lightOutlineVariant, width: 0.5),
        ),
        shadowColor: Colors.black.withValues(alpha: 0.04),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _lightSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _lightOnSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: _lightSurface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightSurfaceVariant,
        hintStyle: const TextStyle(color: _lightOnSurfaceVariant),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _lightOutlineVariant, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _lightOutlineVariant, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _lightPrimary, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _lightPrimary,
          foregroundColor: _lightOnPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _lightOnSurface,
          side: const BorderSide(color: _lightOutlineVariant, width: 0.8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: _lightOnSurface),
      ),
      iconTheme: const IconThemeData(color: _lightOnSurface, size: 22),
      dividerTheme: const DividerThemeData(
        color: _lightOutlineVariant,
        thickness: 0.5,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _lightSurfaceVariant,
        labelStyle: const TextStyle(color: _lightOnSurface, fontSize: 12),
        side: const BorderSide(color: _lightOutlineVariant, width: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _lightSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
    );
  }
}
