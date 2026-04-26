// trending_section.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/shared/models/product_model.dart';
import 'package:mobile/src/shared/widgets/section_header.dart';
import 'package:mobile/src/features/product_detail/presentation/pages/product_detail_page.dart';
import 'trending_cards.dart';

class TrendingSection extends StatelessWidget {
  const TrendingSection({super.key});

  static const List<ProductModel> _products = [
    ProductModel(
      id: 't1',
      name: 'ROG Strix Helios II',
      tagline: '2.4k bought this week',
      price: 3000,
      image: 'assets/images/hero3.png',
      tag: 'HOT',
    ),
    ProductModel(
      id: 't2',
      name: 'AirPods Max',
      tagline: 'Trending in Audio',
      price: 549,
      image: 'assets/images/hero2.png',
      tag: 'TRENDING',
    ),
    ProductModel(
      id: 't3',
      name: 'DualSense Edge',
      tagline: 'Most wished in Gear',
      price: 199,
      image: 'assets/images/hero1.png',
      tag: 'NEW',
    ),
    ProductModel(
      id: 't4',
      name: 'Logitech MX Master 3S',
      tagline: 'Most wished · Mice',
      price: 99,
      image: 'assets/images/mouse_product.png',
      tag: '',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Trending Now', actionText: 'See All'),
        const SizedBox(height: 20),
        // grid - 3 card ben tren 1 wide card ben duoi
        StaggeredGrid.count(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: [
            // tall card - left
            StaggeredGridTile.count(
              crossAxisCellCount: 1,
              mainAxisCellCount: 2,
              child: TrendingCardLarge(product: _products[0]),
            ),
            // 2 small card - right
            StaggeredGridTile.count(
              crossAxisCellCount: 1,
              mainAxisCellCount: 1,
              child: TrendingCardSmall(product: _products[1]),
            ),
            StaggeredGridTile.count(
              crossAxisCellCount: 1,
              mainAxisCellCount: 1,
              child: TrendingCardSmall(product: _products[2]),
            ),
            // wide card - full width
            StaggeredGridTile.count(
              crossAxisCellCount: 2,
              mainAxisCellCount: 0.72,
              child: _TrendingCardWide(product: _products[3]),
            ),
          ],
        ),
      ],
    );
  }
}

// wide card - specific to this layout
class _TrendingCardWide extends StatefulWidget {
  final ProductModel product;
  const _TrendingCardWide({required this.product});

  @override
  State<_TrendingCardWide> createState() => _TrendingCardWideState();
}

class _TrendingCardWideState extends State<_TrendingCardWide> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.98),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductDetailPage(product: widget.product),
          ),
        );
      },
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 140),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFEDEAE2),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.product.tagline.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.black38,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.product.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF0A0A0A),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${widget.product.price.toInt()}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0A0A0A),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 80,
                height: 70,
                child: Image.asset(widget.product.image, fit: BoxFit.contain),
              ),
              const SizedBox(width: 8),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.14),
                    width: 0.5,
                  ),
                ),
                child: const Icon(
                  LucideIcons.arrowRight,
                  size: 13,
                  color: Colors.black45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
