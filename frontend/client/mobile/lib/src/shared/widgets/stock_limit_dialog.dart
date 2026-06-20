import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class StockLimitDialog extends StatelessWidget {
  final int stockCount;
  final int currentQty;
  final String? message;

  const StockLimitDialog({
    super.key,
    required this.stockCount,
    required this.currentQty,
    this.message,
  });

  static Future<void> show(
    BuildContext context, {
    required int stockCount,
    required int currentQty,
    String? message,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => StockLimitDialog(
        stockCount: stockCount,
        currentQty: currentQty,
        message: message,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final dialogBg = isDark ? const Color(0xFF14141E) : const Color(0xFFFFFFFF);
    final borderColor = cs.outlineVariant.withValues(
      alpha: isDark ? 0.25 : 0.6,
    );
    final shadowColor = Colors.black.withValues(alpha: isDark ? 0.45 : 0.08);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: dialogBg,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: borderColor, width: 0.8),
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
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: cs.error.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: cs.error.withValues(alpha: 0.15),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Lottie.asset(
                    'assets/animations/warning.json',
                    repeat: false,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            //header title
            Text(
              'THÔNG BÁO TỒN KHO',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: cs.onSurface,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),

            //desc body
            Text(
              message ??
                  'Số lượng sản phẩm trong kho không đủ cho yêu cầu của bạn.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: cs.onSurfaceVariant.withValues(alpha: 0.85),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(
                  alpha: isDark ? 0.35 : 0.65,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 0.5),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatusColumn(
                      context,
                      'TRONG KHO',
                      '$stockCount',
                      cs.error,
                    ),
                  ),
                  Container(
                    width: 0.5,
                    height: 32,
                    color: cs.outlineVariant.withValues(alpha: 0.5),
                  ),
                  Expanded(
                    child: _buildStatusColumn(
                      context,
                      'GIỎ HÀNG',
                      '$currentQty',
                      cs.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Material(
                color: cs.primary,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    alignment: Alignment.center,
                    child: Text(
                      'XÁC NHẬN',
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
          ],
        ),
      ),
    );
  }

  Widget _buildStatusColumn(
    BuildContext context,
    String label,
    String value,
    Color valueColor,
  ) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: valueColor,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}
