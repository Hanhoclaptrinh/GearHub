import 'package:flutter/material.dart';
import 'package:mobile/src/core/utils/formatter_utils.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF111111);
    final secondaryTextColor = isDark
        ? const Color(0xFFA1A1AA)
        : const Color(0xFF71717A);
    final dividerColor = isDark
        ? const Color(0xFF2A2A2F)
        : const Color(0xFFE4E4E7);

    return Column(
      children: [
        _priceRow(context, "Tạm tính", formatVND(subtotal)),
        const SizedBox(height: 12),
        _priceRow(context, "Phí vận chuyển", formatVND(shipping)),
        if (discount > 0) ...[
          const SizedBox(height: 12),
          _priceRow(
            context,
            "Giảm giá",
            "-${formatVND(discount)}",
            valueColor: const Color(0xFF10B981),
          ),
        ],
        if (voucherDiscount > 0) ...[
          const SizedBox(height: 12),
          _priceRow(
            context,
            "Voucher giảm",
            "-${formatVND(voucherDiscount)}",
            valueColor: const Color(0xFF10B981),
            icon: Icons.local_offer_rounded,
          ),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Divider(color: dividerColor, height: 1, thickness: 0.5),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Tổng số tiền",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: secondaryTextColor,
              ),
            ),
            Text(
              formatVND(total),
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 22,
                color: primaryTextColor,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            "(Giá đã bao gồm thuế VAT 8%)",
            style: TextStyle(
              fontSize: 11,
              color: secondaryTextColor,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Widget _priceRow(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
    IconData? icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF111111);
    final secondaryTextColor = isDark
        ? const Color(0xFFA1A1AA)
        : const Color(0xFF71717A);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: valueColor ?? secondaryTextColor),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(color: secondaryTextColor, fontSize: 14),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: valueColor ?? primaryTextColor,
          ),
        ),
      ],
    );
  }
}
