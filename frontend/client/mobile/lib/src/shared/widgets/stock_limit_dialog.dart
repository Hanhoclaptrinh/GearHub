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
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(
          color: Color(0xFFE5E5EA),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFFF3B30).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Lottie.asset(
                'assets/animations/warning.json',
                repeat: false,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Vượt quá giới hạn',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.black,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message ??
                  'Số lượng sản phẩm trong kho không đủ.\n\nKho hiện còn $stockCount sản phẩm và bạn đã có $currentQty sản phẩm trong giỏ.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Color(0xFF5C5C6B),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'ĐÃ HIỂU',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
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
