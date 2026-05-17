import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/core/theme/app_colors.dart';

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
            color: AppColors.textPrimary,
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
          color: AppColors.cardSurfaceAlt,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? AppColors.brandBlue.withValues(alpha: 0.5)
                : AppColors.borderCardStrong,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.brandBlue.withValues(alpha: 0.15)
                    : AppColors.cardSurfaceAltAlt,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                size: 22,
                color: isSelected ? AppColors.brandBlue : AppColors.slate400,
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
                      color: isSelected
                          ? AppColors.textPrimary
                          : AppColors.slate400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.slate400,
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
                color: isSelected ? AppColors.brandBlue : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? AppColors.brandBlue
                      : AppColors.borderCardStrong,
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
