import 'package:flutter/material.dart';
import 'package:mobile/src/core/utils/formatter_utils.dart';

const _surface  = Color(0xFF14141E);
const _border   = Color(0xFF2A2A38);
const _accent   = Color(0xFFF59E0B);
const _textHigh = Color(0xFFF1F1F5);
const _textMid  = Color(0xFF9191A8);
const _green    = Color(0xFF34D399);

class PriceBreakdownSection extends StatelessWidget {
  final double subtotal;
  final double shipping;
  final double discount;
  final double vat;
  final double total;

  const PriceBreakdownSection({
    super.key,
    required this.subtotal,
    required this.shipping,
    required this.discount,
    required this.vat,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border, width: 0.5),
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
              valueColor: _green,
            ),
          ],
          const SizedBox(height: 14),
          _priceRow("Thuế VAT (10%)", formatVND(vat)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Container(height: 1, color: _border),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Tổng số tiền",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: _textMid,
                ),
              ),
              Text(
                formatVND(total),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  color: _accent,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: _textMid, fontSize: 14),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: valueColor ?? _textHigh,
          ),
        ),
      ],
    );
  }
}
