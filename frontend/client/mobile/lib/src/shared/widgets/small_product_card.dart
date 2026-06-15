import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/core/utils/formatter_utils.dart';
import 'package:mobile/src/shared/models/product_model.dart';
import 'package:mobile/src/features/product_detail/presentation/pages/product_detail_page.dart';

const _starColor = Color(0xFFFFCC00);

class SmallProductCard extends StatelessWidget {
  final ProductModel product;
  final Map<String, String>? initialAttributes;

  const SmallProductCard({
    super.key,
    required this.product,
    this.initialAttributes,
  });

  void _openDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailPage(
          product: product,
          initialAttributes: initialAttributes,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final brandName = product.brandName ?? '';
    final hasRating = product.averageRating > 0;
    return GestureDetector(
      onTap: () => _openDetail(context),
      child: Container(
        width: 176,
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Center(
                  child: product.image.startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: product.image,
                          fit: BoxFit.contain,
                          placeholder: (_, __) => const SizedBox.shrink(),
                          errorWidget: (_, __, ___) =>
                              const Icon(Icons.broken_image_outlined),
                        )
                      : Image.asset(product.image, fit: BoxFit.contain),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (brandName.isNotEmpty) ...[
              Text(
                brandName.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: cs.onSurfaceVariant,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 6),
            ],
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
                letterSpacing: -0.2,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  hasRating ? Icons.star_rounded : LucideIcons.star,
                  size: 14,
                  color: hasRating
                      ? _starColor
                      : cs.onSurface.withValues(alpha: 0.18),
                ),
                const SizedBox(width: 4),
                Text(
                  hasRating ? product.averageRating.toStringAsFixed(1) : 'Mới',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: hasRating ? _starColor : cs.onSurfaceVariant,
                  ),
                ),
                if (product.reviewCount > 0) ...[
                  const SizedBox(width: 4),
                  Text(
                    '(${product.reviewCount})',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              product.hasPriceRange
                  ? 'Từ ${formatVND(product.minPrice)}'
                  : formatVND(product.price),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: cs.onSurface,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
