import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/features/auth/presentation/pages/login_page.dart';

class AuthRequiredModal {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        final cs = theme.colorScheme;
        final isDark = theme.brightness == Brightness.dark;

        final dialogBg = isDark ? const Color(0xFF14141E) : const Color(0xFFFFFFFF);
        final borderColor = cs.outlineVariant.withValues(alpha: isDark ? 0.25 : 0.6);
        final shadowColor = Colors.black.withValues(alpha: isDark ? 0.45 : 0.08);

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 32),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            decoration: BoxDecoration(
              color: dialogBg,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: borderColor,
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Lock Icon with soft secondary color container
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: cs.secondary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: cs.secondary.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      LucideIcons.lock,
                      color: cs.secondary,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  'YÊU CẦU ĐĂNG NHẬP',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: cs.onSurface,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),

                // Body
                Text(
                  'Vui lòng đăng nhập để tiếp tục thanh toán, lưu giỏ hàng và nhận các ưu đãi thành viên đặc biệt.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.85),
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 32),

                // Primary Login Button
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Material(
                    color: cs.primary,
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const LoginPage(),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        alignment: Alignment.center,
                        child: Text(
                          'ĐĂNG NHẬP NGAY',
                          style: TextStyle(
                            color: cs.onPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Secondary Dismiss Button
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: double.infinity,
                        height: 48,
                        alignment: Alignment.center,
                        child: Text(
                          'TIẾP TỤC TRẢI NGHIỆM',
                          style: TextStyle(
                            color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
