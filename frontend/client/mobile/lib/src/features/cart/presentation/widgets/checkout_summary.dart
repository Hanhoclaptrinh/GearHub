import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const _surface = Color(0xFF14141E);
const _border = Color(0xFF2A2A38);
const _accent = Color(0xFFFFCC00);
const _textHigh = Color(0xFFF1F1F5);
const _textMid = Color(0xFF9191A8);

class CheckoutSummary extends StatelessWidget {
  final double subtotal;
  final double shipping;
  final double discount;
  final double total;
  final VoidCallback onCheckout;
  final bool isLoading;

  const CheckoutSummary({
    super.key,
    required this.subtotal,
    required this.shipping,
    required this.discount,
    required this.total,
    required this.onCheckout,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: _surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSummaryRow(label: 'Tạm tính', amount: subtotal),
                const SizedBox(height: 12),
                _buildSummaryRow(label: 'Phí vận chuyển', amount: shipping),
                if (discount > 0) ...[
                  const SizedBox(height: 12),
                  _buildSummaryRow(
                    label: 'Giảm giá',
                    amount: -discount,
                    amountColor: const Color(0xFF34D399),
                  ),
                ],
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Container(height: 1, color: _border),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tổng cộng',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _textMid,
                      ),
                    ),
                    Text(
                      '${total.toStringAsFixed(0)} ₫',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: _accent,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildCheckoutButton(),
                SizedBox(height: padding.bottom > 0 ? padding.bottom - 16 : 0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow({
    required String label,
    required double amount,
    Color? amountColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: _textMid,
          ),
        ),
        Text(
          amount >= 0
              ? '${amount.toStringAsFixed(0)} ₫'
              : '-${(-amount).toStringAsFixed(0)} ₫',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: amountColor ?? _textHigh,
          ),
        ),
      ],
    );
  }

  Widget _buildCheckoutButton() {
    return GestureDetector(
      onTap: isLoading
          ? null
          : () {
              HapticFeedback.mediumImpact();
              onCheckout();
            },
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: _accent,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: _accent.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.black,
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'THANH TOÁN',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    SizedBox(width: 10),
                    Icon(LucideIcons.arrowRight, color: Colors.black, size: 18),
                  ],
                ),
        ),
      ),
    );
  }
}
