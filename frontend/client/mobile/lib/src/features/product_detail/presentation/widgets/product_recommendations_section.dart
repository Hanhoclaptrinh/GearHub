import 'package:flutter/material.dart';
import 'package:mobile/src/shared/models/product_model.dart';
import 'package:mobile/src/core/utils/formatter_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../pages/product_detail_page.dart';

const _surfaceAlt = Color(0xFF1C1C28);
const _border     = Color(0xFF2A2A38);
const _textHigh   = Color(0xFFF1F1F5);
const _textMid    = Color(0xFF9191A8);

class ProductRecommendationsSection extends StatelessWidget {
  final List<ProductModel> recommendations;

  const ProductRecommendationsSection({
    super.key,
    required this.recommendations,
  });

  @override
  Widget build(BuildContext context) {
    if (recommendations.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              'Có thể bạn cũng thích',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: _textHigh,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: recommendations.map((product) {
                return _RecommendationCard(product: product);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final ProductModel product;

  const _RecommendationCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailPage(product: product),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _surfaceAlt,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _border),
                ),
                child: Center(
                  child: product.image.startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: product.image,
                          fit: BoxFit.contain,
                          placeholder: (_, __) => const SizedBox.shrink(),
                          errorWidget: (_, __, ___) => const Icon(Icons.broken_image_outlined),
                        )
                      : Image.asset(product.image, fit: BoxFit.contain),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: _textHigh,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              formatVND(product.price),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _textMid,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
