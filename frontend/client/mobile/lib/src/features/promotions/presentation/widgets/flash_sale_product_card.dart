import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/core/utils/formatter_utils.dart';
import 'package:mobile/src/features/promotions/data/models/flash_sale_product_model.dart';
import 'package:mobile/src/features/promotions/presentation/widgets/pressable_scale_button.dart';

class FlashSaleProductCard extends StatelessWidget {
  final FlashSaleProductModel product;
  final int percent;
  final bool isSoldOut;
  final double progress;
  final bool isUpcoming;
  final Function(String productId, Map<String, String>? initialAttributes)
  onTap;
  final Function(String productId, String variantId) onAddToCart;
  final VoidCallback onNotifyMe;

  const FlashSaleProductCard({
    super.key,
    required this.product,
    required this.percent,
    required this.isSoldOut,
    required this.progress,
    required this.isUpcoming,
    required this.onTap,
    required this.onAddToCart,
    required this.onNotifyMe,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSoldOut
              ? theme.colorScheme.outlineVariant.withValues(alpha: 0.5)
              : (isDark ? const Color(0xFF1E1E28) : const Color(0xFFE2E8F0)),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                final initialAttrs = product.productVariant.attributes.map(
                  (k, v) => MapEntry(k, v.toString()),
                );
                onTap(
                  product.productVariant.product.id,
                  initialAttrs.isNotEmpty ? initialAttrs : null,
                );
              },
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Stack(
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: isDark
                                ? const Color(0xFF171721)
                                : const Color(0xFFF1F5F9),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: CachedNetworkImage(
                              imageUrl:
                                  (product.productVariant.imageUrl != null &&
                                      product
                                          .productVariant
                                          .imageUrl!
                                          .isNotEmpty)
                                  ? product.productVariant.imageUrl!
                                  : (product
                                            .productVariant
                                            .product
                                            .thumbnailUrl ??
                                        ''),
                              width: 110,
                              height: 110,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: isDark
                                    ? const Color(0xFF171721)
                                    : const Color(0xFFF1F5F9),
                                child: Center(
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        theme.colorScheme.onSurfaceVariant
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: isDark
                                    ? const Color(0xFF171721)
                                    : const Color(0xFFF1F5F9),
                                child: Icon(
                                  LucideIcons.image,
                                  color: theme.colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.4),
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (percent > 0)
                          Positioned(
                            top: 6,
                            left: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Text(
                                '-$percent%',
                                style: TextStyle(
                                  color: theme.colorScheme.onPrimary,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Info Panel
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 4,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.productVariant.product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Builder(
                            builder: (context) {
                              String displayAttr = '';
                              if (product
                                  .productVariant
                                  .attributes
                                  .isNotEmpty) {
                                displayAttr = product
                                    .productVariant
                                    .attributes
                                    .values
                                    .map((e) => e.toString())
                                    .join(' / ');
                              } else {
                                displayAttr =
                                    product.productVariant.name
                                        .toLowerCase()
                                        .startsWith(
                                          product.productVariant.product.name
                                              .toLowerCase(),
                                        )
                                    ? product.productVariant.name
                                          .substring(
                                            product
                                                .productVariant
                                                .product
                                                .name
                                                .length,
                                          )
                                          .trim()
                                    : product.productVariant.name;
                              }

                              if (displayAttr.isEmpty ||
                                  displayAttr == 'Default Title' ||
                                  displayAttr == 'Default') {
                                return const SizedBox.shrink();
                              }

                              return Padding(
                                padding: const EdgeInsets.only(top: 1),
                                child: Text(
                                  displayAttr,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.5),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            },
                          ),
                          const Spacer(),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 6,
                                runSpacing: 2,
                                children: [
                                  Text(
                                    formatVND(product.flashPrice),
                                    style: TextStyle(
                                      color: isUpcoming
                                          ? theme.colorScheme.onSurfaceVariant
                                                .withValues(alpha: 0.9)
                                          : theme.colorScheme.onSurface,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    formatVND(product.productVariant.price),
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurfaceVariant
                                          .withValues(alpha: 0.5),
                                      fontSize: 10,
                                      decoration: TextDecoration.lineThrough,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Spacer(),

                          if (!isUpcoming) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                _buildSegmentedTracker(
                                  progress,
                                  isSoldOut,
                                  product.soldCount >= product.stockLimit - 1 &&
                                      !isSoldOut,
                                  theme,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isSoldOut
                                      ? 'HẾT HÀNG'
                                      : 'ĐÃ BÁN ${product.soldCount}/${product.stockLimit}',
                                  style: TextStyle(
                                    color: isSoldOut
                                        ? const Color(0xFFEF4444)
                                        : (product.soldCount >=
                                                  product.stockLimit - 1
                                              ? const Color(0xFFF97316)
                                              : theme
                                                    .colorScheme
                                                    .onSurfaceVariant
                                                    .withValues(alpha: 0.6)),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: Colors.green.withValues(
                                        alpha: 0.15,
                                      ),
                                    ),
                                  ),
                                  child: const Text(
                                    'GIÁ MỞ BÁN',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Text(
                                  'Mở bán: ${product.stockLimit} chiếc',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.6),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _buildActionBtn(
              product.productVariant.product.id,
              product.productVariant.id,
              theme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedTracker(
    double progress,
    bool isSoldOut,
    bool isAlmostSoldOut,
    ThemeData theme,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    const totalSegments = 5;
    final filledSegments = (progress * totalSegments).round();

    Color activeColor;
    if (isSoldOut) {
      activeColor = theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.25);
    } else if (isAlmostSoldOut) {
      activeColor = const Color(0xFFF97316);
    } else {
      activeColor = theme.colorScheme.primary.withValues(alpha: 0.8);
    }

    final inactiveColor = isDark
        ? const Color(0xFF22222A)
        : const Color(0xFFE2E8F0);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(totalSegments, (index) {
        final isActive = index < filledSegments;
        return Container(
          width: 10,
          height: 3,
          margin: const EdgeInsets.only(right: 2.5),
          decoration: BoxDecoration(
            color: isActive ? activeColor : inactiveColor,
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }

  Widget _buildActionBtn(String productId, String variantId, ThemeData theme) {
    if (isSoldOut) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(
          LucideIcons.slash,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
          size: 16,
        ),
      );
    }

    if (isUpcoming) {
      return PressableScaleButton(
        onTap: () {
          HapticFeedback.lightImpact();
          onNotifyMe();
        },
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF97316).withValues(alpha: 0.08),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFF97316).withValues(alpha: 0.18),
            ),
          ),
          child: const Center(
            child: Icon(LucideIcons.bell, color: Color(0xFFF97316), size: 16),
          ),
        ),
      );
    }

    return PressableScaleButton(
      onTap: () {
        HapticFeedback.mediumImpact();
        onAddToCart(productId, variantId);
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          LucideIcons.shoppingCart,
          color: theme.colorScheme.onPrimary,
          size: 16,
        ),
      ),
    );
  }
}
