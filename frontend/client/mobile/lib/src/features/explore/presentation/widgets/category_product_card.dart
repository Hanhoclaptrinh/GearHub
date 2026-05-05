import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile/src/core/utils/formatter_utils.dart';
import 'package:mobile/src/features/product_detail/presentation/pages/product_detail_page.dart';
import 'package:mobile/src/shared/models/product_model.dart';

class CategoryProductCard extends StatefulWidget {
  final ProductModel product;

  const CategoryProductCard({super.key, required this.product});

  @override
  State<CategoryProductCard> createState() => _CategoryProductCardState();
}

class _CategoryProductCardState extends State<CategoryProductCard> {
  bool _isWishlisted = false;

  @override
  Widget build(BuildContext context) {
    final colorKey = _getColorKey(widget.product);
    final uniqueColors = colorKey.isNotEmpty ? _getUniqueValues(widget.product, colorKey) : [];
    final otherSpecs = _getOtherSpecs(widget.product, colorKey);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(product: widget.product),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.baseName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Color.fromARGB(255, 0, 0, 0), size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.product.averageRating} (${widget.product.reviewCount})',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        formatVND(widget.product.price),
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: CachedNetworkImage(
                          imageUrl: widget.product.image,
                          height: 130,
                          fit: BoxFit.contain,
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isWishlisted = !_isWishlisted;
                            });
                          },
                          child: Icon(
                            _isWishlisted ? Icons.favorite_rounded : LucideIcons.heart,
                            color: _isWishlisted ? Colors.red : Colors.black,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            if (uniqueColors.isNotEmpty)
              SizedBox(
                height: 32,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: uniqueColors.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        uniqueColors[index],
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
            if (uniqueColors.isNotEmpty) const SizedBox(height: 14),
            
            if (otherSpecs.isNotEmpty)
              Text(
                otherSpecs.join(' | '),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.black.withValues(alpha: 0.6),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getColorKey(ProductModel product) {
    if (product.attributeConfig.isNotEmpty) {
      return product.attributeConfig.firstWhere((k) {
        final lower = k.toLowerCase();
        return lower.contains('color') || lower.contains('màu') || lower.contains('mau');
      }, orElse: () => '');
    }
    return '';
  }

  List<String> _getUniqueValues(ProductModel product, String key) {
    return product.variants
        .where((v) => v.isActive)
        .map((v) => v.attributes[key]?.toString())
        .whereType<String>()
        .toSet()
        .toList();
  }

  List<String> _getOtherSpecs(ProductModel product, String colorKey) {
    final specs = <String>{};
    for (var variant in product.variants) {
      if (!variant.isActive) continue;
      variant.attributes.forEach((key, value) {
        if (key != colorKey) {
          specs.add(value.toString());
        }
      });
    }
    return specs.toList();
  }
}
