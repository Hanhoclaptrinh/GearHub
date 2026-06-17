import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/core/theme/app_theme.dart';
import 'package:mobile/src/features/promotions/data/models/voucher_model.dart';
import 'package:mobile/src/features/promotions/presentation/widgets/pressable_scale_button.dart';

class PrivilegeVoucherCard extends StatelessWidget {
  final VoucherModel voucher;
  final bool isClaiming;
  final bool isClaimed;
  final VoidCallback onClaim;

  const PrivilegeVoucherCard({
    super.key,
    required this.voucher,
    required this.isClaiming,
    required this.isClaimed,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bool isShipping =
        !voucher.isPercent ||
        voucher.name.toLowerCase().contains('ship') ||
        voucher.name.toLowerCase().contains('giao hàng') ||
        voucher.code.toLowerCase().contains('ship');

    final accent = isShipping
        ? theme.colorScheme.success
        : (isDark ? const Color(0xFF06B6D4) : const Color(0xFF0891B2));

    final icon = isShipping ? LucideIcons.truck : LucideIcons.badgePercent;
    final expiryText = _formatExpiry(voucher.expiresAt);

    return PressableScaleButton(
      onTap: (isClaimed || isClaiming) ? null : onClaim,
      child: CustomPaint(
        painter: VoucherPainter(
          leftWidth: 82,
          bgColor: theme.colorScheme.surface,
          leftColor: theme.colorScheme.surfaceContainerHighest,
          borderColor: isClaimed
              ? theme.colorScheme.success.withValues(alpha: 0.36)
              : theme.colorScheme.outlineVariant,
          dividerColor: theme.colorScheme.onSurface.withValues(alpha: 0.08),
          notchColor: theme.scaffoldBackgroundColor,
          notchRadius: 8,
          cornerRadius: 24,
        ),
        child: SizedBox(
          height: 116,
          child: Row(
            children: [
              SizedBox(
                width: 82,
                child: Center(
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.09),
                      shape: BoxShape.circle,
                      border: Border.all(color: accent.withValues(alpha: 0.2)),
                    ),
                    child: Icon(icon, color: accent, size: 19),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.09),
                                borderRadius: BorderRadius.circular(99),
                                border: Border.all(
                                  color: accent.withValues(alpha: 0.16),
                                ),
                              ),
                              child: Text(
                                voucher.code,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: accent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.75,
                                ),
                              ),
                            ),
                          ),
                          if (isClaimed) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.success.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(99),
                                border: Border.all(
                                  color: theme.colorScheme.success.withValues(
                                    alpha: 0.18,
                                  ),
                                ),
                              ),
                              child: Text(
                                'ĐÃ LƯU',
                                style: TextStyle(
                                  color: theme.colorScheme.success,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        voucher.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.15,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        voucher.summaryText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          height: 1.25,
                        ),
                      ),
                      const Spacer(),
                      if (expiryText != null)
                        Row(
                          children: [
                            const Icon(
                              LucideIcons.clock3,
                              color: Colors.grey,
                              size: 12,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              expiryText,
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: ClaimButton(
                  isClaiming: isClaiming,
                  isClaimed: isClaimed,
                  accentColor: accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _formatExpiry(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    final parsed = DateTime.tryParse(value);
    if (parsed == null) return null;

    return 'Hạn dùng ${DateFormat('dd/MM/yyyy').format(parsed)}';
  }
}

class ClaimButton extends StatelessWidget {
  final bool isClaiming;
  final bool isClaimed;
  final Color accentColor;

  const ClaimButton({
    super.key,
    required this.isClaiming,
    required this.isClaimed,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: 56,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isClaimed
            ? theme.colorScheme.success.withValues(alpha: 0.1)
            : isClaiming
            ? accentColor.withValues(alpha: 0.16)
            : accentColor,
        borderRadius: BorderRadius.circular(14),
        border: isClaimed
            ? Border.all(
                color: theme.colorScheme.success.withValues(alpha: 0.28),
              )
            : null,
      ),
      child: isClaiming
          ? SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: isDark ? Colors.black : Colors.white,
              ),
            )
          : isClaimed
          ? Icon(LucideIcons.check, color: theme.colorScheme.success, size: 17)
          : Text(
              'LƯU',
              style: TextStyle(
                color: isDark ? Colors.black : Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.55,
              ),
            ),
    );
  }
}

class VoucherPainter extends CustomPainter {
  final double leftWidth;
  final Color bgColor;
  final Color leftColor;
  final Color borderColor;
  final Color dividerColor;
  final Color notchColor;
  final double notchRadius;
  final double cornerRadius;

  const VoucherPainter({
    required this.leftWidth,
    required this.bgColor,
    required this.leftColor,
    required this.borderColor,
    required this.dividerColor,
    required this.notchColor,
    required this.notchRadius,
    required this.cornerRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildPath(size);

    canvas.drawPath(path, Paint()..color = bgColor);

    canvas.save();
    canvas.clipPath(path);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, leftWidth, size.height),
      Paint()..color = leftColor,
    );
    canvas.restore();

    canvas.drawCircle(
      Offset(leftWidth, -0.5),
      notchRadius,
      Paint()..color = notchColor,
    );
    canvas.drawCircle(
      Offset(leftWidth, size.height + 0.5),
      notchRadius,
      Paint()..color = notchColor,
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    final dashPaint = Paint()
      ..color = dividerColor
      ..strokeWidth = 1;

    const dash = 4.5;
    const gap = 4.0;

    double y = notchRadius + 6;
    final endY = size.height - notchRadius - 6;

    while (y < endY) {
      canvas.drawLine(
        Offset(leftWidth, y),
        Offset(leftWidth, math.min(y + dash, endY)),
        dashPaint,
      );
      y += dash + gap;
    }
  }

  Path _buildPath(Size size) {
    final r = cornerRadius;

    return Path()
      ..moveTo(r, 0)
      ..lineTo(size.width - r, 0)
      ..arcToPoint(Offset(size.width, r), radius: Radius.circular(r))
      ..lineTo(size.width, size.height - r)
      ..arcToPoint(
        Offset(size.width - r, size.height),
        radius: Radius.circular(r),
      )
      ..lineTo(r, size.height)
      ..arcToPoint(Offset(0, size.height - r), radius: Radius.circular(r))
      ..lineTo(0, r)
      ..arcToPoint(Offset(r, 0), radius: Radius.circular(r))
      ..close();
  }

  @override
  bool shouldRepaint(VoucherPainter oldDelegate) {
    return oldDelegate.borderColor != borderColor ||
        oldDelegate.bgColor != bgColor ||
        oldDelegate.leftColor != leftColor;
  }
}
