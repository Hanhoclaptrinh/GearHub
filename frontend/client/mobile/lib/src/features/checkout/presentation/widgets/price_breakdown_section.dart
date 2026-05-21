import 'package:flutter/material.dart';
import 'package:mobile/src/core/utils/formatter_utils.dart';
import 'package:mobile/src/core/theme/app_colors.dart';

class PriceBreakdownSection extends StatelessWidget {
  final double subtotal;
  final double shipping;
  final double discount;
  final double vat;
  final double total;
  final double voucherDiscount;

  const PriceBreakdownSection({
    super.key,
    required this.subtotal,
    required this.shipping,
    this.discount = 0,
    required this.vat,
    required this.total,
    this.voucherDiscount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardSurfaceAlt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderCardStrong, width: 0.5),
      ),
      child: Column(
        children: [
          _priceRow("Tạm tính", formatVND(subtotal)),
          const SizedBox(height: 14),
          _priceRow("Phí vận chuyển", formatVND(shipping)),
          if (discount > 0) ...[
            const SizedBox(height: 14),
            _priceRow(
              "Giảm giá",
              "-${formatVND(discount)}",
              valueColor: AppColors.emerald400,
            ),
          ],
          const SizedBox(height: 14),
          _priceRow("Thuế VAT (10%)", formatVND(vat)),
          if (voucherDiscount > 0) ...[
            const SizedBox(height: 14),
            _priceRow(
              "Voucher giảm",
              "-${formatVND(voucherDiscount)}",
              valueColor: AppColors.emerald400,
              icon: Icons.local_offer_rounded,
            ),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Container(height: 1, color: AppColors.borderCardStrong),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Tổng số tiền",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: AppColors.slate400,
                ),
              ),
              Text(
                formatVND(total),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  color: AppColors.champagne,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceRow(
    String label,
    String value, {
    Color? valueColor,
    IconData? icon,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: valueColor ?? AppColors.slate400),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: const TextStyle(color: AppColors.slate400, fontSize: 14),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
