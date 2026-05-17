import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/core/theme/app_colors.dart';
import 'package:mobile/src/core/utils/formatter_utils.dart';
import 'package:mobile/src/features/cart/domain/entities/cart_item_entity.dart';

class CheckoutItemsSection extends StatelessWidget {
  final List<CartItemEntity> items;

  const CheckoutItemsSection({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Tổng quan đơn hàng",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardSurfaceAlt,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderCardStrong, width: 0.5),
          ),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                _buildSummaryItem(items[i]),
                if (i < items.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Container(
                      height: 1,
                      color: AppColors.borderCardStrong,
                    ),
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
            color: AppColors.cardSurfaceAltAlt,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderCardStrong, width: 0.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: item.productVariant.imageUrl != null
                ? Image.network(
                    item.productVariant.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      LucideIcons.image,
                      color: AppColors.textDim,
                      size: 20,
                    ),
                  )
                : const Icon(
                    LucideIcons.package,
                    color: AppColors.textDim,
                    size: 20,
                  ),
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
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                item.productVariant.name,
                style: const TextStyle(fontSize: 11, color: AppColors.textDim),
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
                color: AppColors.brandYellow,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              "x${item.quantity}",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: AppColors.slate400,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
