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

  // ── status & feedback ──
  static const Color error = Color(0xFFFF4D4D);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // ── brand & semantic accents ──
  static const Color brandBlue = Color(0xFF3B82F6);
  static const Color brandIndigo = Color(0xFF6366F1);
  static const Color brandIndigoSoft = Color(0x1A6366F1);
  static const Color accentPink = Color(0xFFFF6B8A);
  static const Color accentGold = Color(0xFFFFCC00);
  static const Color accentGoldSoft = Color(0x18F59E0B);
  static const Color accentGoldDim = Color(0xFF1A1200);
  static const Color emerald400 = Color(0xFF34D399);
  static const Color champagne = Color(0xFFD8B76A);
  static const Color champagneSoft = Color(0xFFE7D4A2);
  static const Color silver = Color(0xFFB8BDC7);
  static const Color diamond = Color(0xFFA8D8FF);

  // ── cards & containers ──
  static const Color cardSurface = Color(0xFF0E0E18);
  static const Color cardSurfaceAlt = Color(0xFF14141E);
  static const Color cardSurfaceAltAlt = Color(0xFF1C1C28);
  static const Color cardBorder = Color(0xFF1E1E2E);
  static const Color borderCardStrong = Color(0xFF2A2A38);

  // ── additional text & utility ──
  static const Color textSlate = Color(0xFF8892A4);
  static const Color textDim = Color(0xFF4A5263);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate600 = Color(0xFF475569);

  // ── gradients ──
  static const LinearGradient luxuryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1A1F), Color(0xFF07070A)],
  );
}
