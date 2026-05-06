import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile/src/core/utils/formatter_utils.dart';
import 'package:mobile/src/shared/models/product_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SmallProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onCartTap;
  final bool isFavorite;
  final double width;
  final String? heroTag;

  const SmallProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onFavoriteTap,
    this.onCartTap,
    this.isFavorite = false,
    this.width = 156,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 164,
              width: width,
              decoration: BoxDecoration(
                color: const Color.fromARGB(110, 221, 221, 221),
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: Center(
                child: Hero(
                  tag: heroTag ?? 'product_${product.id}',
                  child: CachedNetworkImage(
                    imageUrl: product.image,
                    fit: BoxFit.contain,
                    height: 130,
                    width: 130,
                    placeholder: (context, url) => const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF0A0A0F),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.image_not_supported_outlined,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              product.baseName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0A0A0F),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              formatVND(product.price),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0A0A0F),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // add to wishlist
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onFavoriteTap?.call();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isFavorite
                            ? const Color(0xFFFF4D4D).withValues(alpha: 0.1)
                            : const Color(0xFF0A0A0F).withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: isFavorite ? const Color(0xFFFF4D4D) : const Color(0xFF0A0A0F),
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // add to cart
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onCartTap?.call();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0A0F),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        LucideIcons.shoppingCart,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
