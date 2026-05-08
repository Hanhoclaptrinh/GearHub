import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/core/utils/formatter_utils.dart';
import 'package:mobile/src/features/cart/domain/entities/cart_item_entity.dart';

const _surface = Color(0xFF14141E);
const _surfaceAlt = Color(0xFF1C1C28);
const _border = Color(0xFF2A2A38);
const _accent = Color(0xFFF59E0B);
const _textHigh = Color(0xFFF1F1F5);
const _textMid = Color(0xFF9191A8);
const _textLow = Color(0xFF4A4A62);

class CheckoutItemsSection extends StatelessWidget {
  final List<CartItemEntity> items;

  const CheckoutItemsSection({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              "Tổng quan đơn hàng",
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: _textHigh,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${items.length}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: _accent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border, width: 0.5),
          ),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                _buildSummaryItem(items[i]),
                if (i < items.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Container(height: 1, color: _border),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(CartItemEntity item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: _surfaceAlt,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border, width: 0.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: item.productVariant.imageUrl != null
                ? Image.network(
                    item.productVariant.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      LucideIcons.image,
                      color: _textLow,
                      size: 20,
                    ),
                  )
                : const Icon(LucideIcons.package, color: _textLow, size: 20),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.product.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: _textHigh,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                item.productVariant.name,
                style: const TextStyle(fontSize: 11, color: _textLow),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatVND(item.productVariant.price),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: _accent,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              "x${item.quantity}",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: _textMid,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
