import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── base ──
  static const Color background = Color(0xFF07070A);
  static const Color surface = Color(0xFF101014);
  static const Color surfaceElevated = Color(0xFF151821);
  static const Color surfaceHover = Color(0xFF1C2230);

  // ── text ──
  static const Color textPrimary = Color(0xFFF5F7FA);
  static const Color textSecondary = Color(0xA6F5F7FA);
  static const Color textMuted = Color(0x6BF5F7FA);

  // ── signature accents ──
  static const Color accentSilver = Color(0xFFD6D9E0);
  static const Color accentTitanium = Color(0xFFAEB4C2);
  static const Color accentFrost = Color(0xFFE2E8F0);
  static const Color accentMutedBlue = Color(0xFF64748B);

  // ── primary CTA ──
  static const Color ctaPrimary = Color(0xFFF5F7FA);
  static const Color ctaPrimaryText = Color(0xFF0A0A0D);

  // ── depth & border ──
  static const Color borderSubtle = Color(0x0FFFFFFF);
  static const Color borderLight = Color(0x14FFFFFF);

  static const Color error = Color(0xFFFF4D4D);
  static const Color success = Color(0xFF10B981);

  // ── hero section ──
  static const Color heroBg1 = Color(0xFF0B1020);
  static const Color heroBg2 = Color(0xFF111827);

  static const Color glassStroke = Color(0x1AFFFFFF);
  static const Color glassFill = Color(0x0DFFFFFF);
  static const Color glassFillHover = Color(0x1AFFFFFF);

  static const Color heroTextPrimary = Color(0xF5FFFFFF);
  static const Color heroTextSecondary = Color(0x99FFFFFF);
  static const Color heroTextTertiary = Color(0x52FFFFFF);

  static const Color ambientGlow = Color(0x1A3B82F6);
  static const Color ambientFog = Color(0x0D6366F1);

  static const Color indicatorActive = Color(0xCCFFFFFF);
  static const Color indicatorBg = Color(0x26FFFFFF);

  static const LinearGradient luxuryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1A1F), Color(0xFF07070A)],
  );
}
