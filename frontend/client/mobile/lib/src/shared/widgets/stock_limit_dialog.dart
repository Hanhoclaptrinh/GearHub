import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

const _surface = Color(0xFF14141E);
const _border = Color(0xFF2A2A38);
const _accent = Color(0xFF6366F1);
const _textHigh = Color(0xFFF1F1F5);
const _textMid = Color(0xFF9191A8);

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
      builder: (context) => StockLimitDialog(
        stockCount: stockCount,
        currentQty: currentQty,
        message: message,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(32),
        side: const BorderSide(color: _border, width: 1.5),
      ),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 40,
              spreadRadius: 10,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: Lottie.asset(
                'assets/animations/warning.json',
                repeat: false,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'GIỚI HẠN TỒN KHO',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Color(0xFFEF4444),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'VƯỢT QUÁ SỐ LƯỢNG',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: _textHigh,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message ??
                  'Số lượng sản phẩm trong kho không đủ.\n\nKho hiện còn $stockCount sản phẩm và bạn đã có $currentQty sản phẩm trong giỏ.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _textMid.withValues(alpha: 0.8),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'ĐÃ HIỂU',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
