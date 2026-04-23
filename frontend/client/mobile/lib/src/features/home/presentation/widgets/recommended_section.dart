import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/src/shared/models/product.dart';
import 'package:mobile/src/features/product_detail/presentation/pages/product_detail_page.dart';
import 'package:mobile/src/shared/widgets/section_header.dart';
import 'package:mobile/src/shared/widgets/trending_badge.dart';

class RecommendedSection extends StatelessWidget {
  const RecommendedSection({super.key});

  static const List<Product> _recommendedProducts = [
    Product(
      id: 'r1',
      name: 'Keychron K2 Pro',
      tagline: 'Wireless Mechanical',
      price: 109,
      image: 'assets/images/keyboard_hero.png',
      tag: 'MATCH',
    ),
    Product(
      id: 'r2',
      name: 'MX Master 3S',
      tagline: 'Performance Mouse',
      price: 99,
      image: 'assets/images/mouse_product.png',
      tag: 'AI PICK',
    ),
    Product(
      id: 'r3',
      name: 'WH-1000XM5',
      tagline: 'Noise Cancelling',
      price: 399,
      image: 'assets/images/hero2.png',
      tag: 'AUDIO',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Curated For You', actionText: 'See All'),
        const SizedBox(height: 20),
        Column(
          children: [
            BentoHeroCard(product: _recommendedProducts[0]),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: BentoSquareCard(
                    product: _recommendedProducts[1],
                    isDark: false,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: BentoSquareCard(
                    product: _recommendedProducts[2],
                    isDark: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class BentoHeroCard extends StatefulWidget {
  final Product product;
  const BentoHeroCard({super.key, required this.product});

  @override
  State<BentoHeroCard> createState() => _BentoHeroCardState();
}

class _BentoHeroCardState extends State<BentoHeroCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.98),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailPage(product: widget.product),
          ),
        );
      },
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutExpo,
        child: Container(
          height: 220,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFE2E8F0), Color(0xFFF8FAFC)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // typo background
              Positioned(
                top: -20,
                right: -10,
                child: Text(
                  widget.product.tag ?? 'PRO',
                  style: TextStyle(
                    fontSize: 100,
                    fontWeight: FontWeight.w900,
                    color: Colors.white.withValues(alpha: 0.6),
                    letterSpacing: -4,
                  ),
                ),
              ),
              Positioned(
                right: -40,
                bottom: -20,
                top: 20,
                width: 240,
                child: Hero(
                  tag: 'bento_${widget.product.id}',
                  child: Image.asset(widget.product.image, fit: BoxFit.contain),
                ),
              ),
              // product info
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TrendingBadge(tag: widget.product.tag ?? 'MATCH'),
                    const Spacer(),
                    Text(
                      widget.product.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                        height: 1.1,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.product.tagline,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '\$${widget.product.price.toInt()}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
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

class BentoSquareCard extends StatefulWidget {
  final Product product;
  final bool isDark;

  const BentoSquareCard({
    super.key,
    required this.product,
    required this.isDark,
  });

  @override
  State<BentoSquareCard> createState() => _BentoSquareCardState();
}

class _BentoSquareCardState extends State<BentoSquareCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDark ? const Color(0xFF111111) : Colors.white;
    final textColor = widget.isDark ? Colors.white : Colors.black;
    final subTextColor = widget.isDark ? Colors.white54 : Colors.black54;

    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.95),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailPage(product: widget.product),
          ),
        );
      },
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutExpo,
        child: Container(
          height: 220,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(32),
            border: widget.isDark
                ? null
                : Border.all(
                    color: Colors.black.withValues(alpha: 0.04),
                    width: 1.5,
                  ),
            boxShadow: widget.isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : [],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned(
                top: -10,
                right: -20,
                left: 10,
                height: 140,
                child: Hero(
                  tag: 'bento_${widget.product.id}',
                  child: Image.asset(widget.product.image, fit: BoxFit.contain),
                ),
              ),
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        height: 1.1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.product.tagline,
                      style: TextStyle(
                        fontSize: 11,
                        color: subTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: widget.isDark ? Colors.white : Colors.black,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '\$${widget.product.price.toInt()}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: widget.isDark ? Colors.black : Colors.white,
                        ),
                      ),
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
