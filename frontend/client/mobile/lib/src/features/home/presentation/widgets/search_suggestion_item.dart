import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/core/theme/app_colors.dart';
import 'package:mobile/src/core/utils/formatter_utils.dart';
import 'package:mobile/src/shared/models/product_model.dart';
import 'package:mobile/src/features/product_detail/presentation/pages/product_detail_page.dart';

class SearchSuggestionItem extends StatelessWidget {
  final ProductModel product;

  const SearchSuggestionItem({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductDetailPage(product: product),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardSurfaceAlt,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderCardStrong),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.cardSurfaceAltAlt,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderCardStrong),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: product.image.isNotEmpty
                    ? Image.network(product.image, fit: BoxFit.cover)
                    : const Icon(
                        LucideIcons.image,
                        size: 20,
                        color: AppColors.textDim,
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatVND(product.price),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppColors.brandIndigo,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: AppColors.textDim,
            ),
          ],
        ),
      ),
    );
  }
}
