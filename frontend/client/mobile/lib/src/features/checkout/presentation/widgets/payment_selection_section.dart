import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const _surface    = Color(0xFF14141E);
const _surfaceAlt = Color(0xFF1C1C28);
const _border     = Color(0xFF2A2A38);
const _indigo     = Color(0xFF6366F1);
const _indigoSoft = Color(0x1A6366F1);
const _textHigh   = Color(0xFFF1F1F5);
const _textMid    = Color(0xFF9191A8);

class PaymentSelectionSection extends StatelessWidget {
  final String selectedMethod;
  final ValueChanged<String> onMethodChanged;

  const PaymentSelectionSection({
    super.key,
    required this.selectedMethod,
    required this.onMethodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Phương thức thanh toán",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: _textHigh,
          ),
        ),
        const SizedBox(height: 12),
        _buildPaymentOption(
          id: "COD",
          title: "Thanh toán khi nhận hàng",
          subtitle: "COD (Cash On Delivery)",
          icon: LucideIcons.banknote,
        ),
        const SizedBox(height: 10),
        _buildPaymentOption(
          id: "PAYMENT_GATEWAY",
          title: "Cổng thanh toán online",
          subtitle: "VNPay Online Payment Gateway",
          icon: LucideIcons.creditCard,
        ),
      ],
    );
  }

  Widget _buildPaymentOption({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final bool isSelected = selectedMethod == id;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onMethodChanged(id);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected ? _indigoSoft : _surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? _indigo.withValues(alpha: 0.5)
                : _border,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected ? _indigo.withValues(alpha: 0.15) : _surfaceAlt,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                size: 22,
                color: isSelected ? _indigo : _textMid,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: isSelected ? _textHigh : _textMid,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: _textMid,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? _indigo : Colors.transparent,
                border: Border.all(
                  color: isSelected ? _indigo : _border,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
