import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile/src/core/utils/formatter_utils.dart';
import 'package:mobile/src/shared/models/product_model.dart';
import 'package:mobile/src/features/product_detail/presentation/pages/product_detail_page.dart';
import 'package:mobile/src/core/theme/app_colors.dart';

class SmallProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onTap;
  final String? heroTag;
  final double width;

  const SmallProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.heroTag,
    this.width = 156,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:
          onTap ??
          () {
            HapticFeedback.lightImpact();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProductDetailPage(product: product),
              ),
            );
          },
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: AppColors.textPrimary.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.textPrimary.withValues(alpha: 0.05),
            width: 0.8,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // img
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary.withValues(alpha: 0.01),
                  ),
                  child: Hero(
                    tag: heroTag ?? 'collection_${product.id}',
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: CachedNetworkImage(
                        imageUrl: product.image,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 1,
                              color: AppColors.textPrimary.withValues(
                                alpha: 0.1,
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Icon(
                          Icons.image_not_supported_outlined,
                          color: AppColors.textPrimary.withValues(alpha: 0.05),
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // content
              Container(
                height: 110,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 32,
                      child: Text(
                        product.baseName.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Spacer(),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 12,
                          child:
                              (product.variants.isNotEmpty &&
                                  product.variants.length > 1)
                              ? const Text(
                                  'TỪ',
                                  style: TextStyle(
                                    color: Color(0x4DFFFFFF),
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                        Text(
                          formatVND(product.price),
                          style: TextStyle(
                            color: AppColors.textPrimary.withValues(alpha: 0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
