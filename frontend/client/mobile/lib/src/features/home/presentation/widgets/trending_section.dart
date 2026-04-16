import 'package:flutter/material.dart';
import 'package:mobile/src/features/home/domain/models/product.dart';

class TrendingSection extends StatefulWidget {
  const TrendingSection({super.key});

  @override
  State<TrendingSection> createState() => _TrendingSectionState();
}

class _TrendingSectionState extends State<TrendingSection> {
  final List<Product> _trendingProducts = [
    const Product(
      id: '1',
      name: 'PS5 Console',
      tagline: 'PlayStation 5',
      price: 20.00,
      image: 'assets/images/hero1.png',
      tag: 'HOT',
    ),
    const Product(
      id: '2',
      name: 'Airpods Max',
      tagline: 'Apple',
      price: 40.00,
      image: 'assets/images/hero2.png',
      tag: 'TRENDING',
    ),
    const Product(
      id: '3',
      name: 'Asus ROG Strix Helios II',
      tagline: 'Mid-Tower ATX Gaming Case',
      price: 55.00,
      image: 'assets/images/hero3.png',
      tag: 'NEW',
    ),
    const Product(
      id: '4',
      name: 'Vision Pro',
      tagline: 'Apple VR Headset',
      price: 32.00,
      image: 'assets/images/hero4.png',
      tag: 'HOT',
    ),
    const Product(
      id: '5',
      name: 'MacBook Pro',
      tagline: 'Apple Laptop',
      price: 85.00,
      image: 'assets/images/hero1.png',
      tag: 'LIMITED',
    ),
    const Product(
      id: '6',
      name: 'Akko Keyboard',
      tagline: 'Mechanical Keyboard',
      price: 28.00,
      image: 'assets/images/hero2.png',
      tag: 'SLEEP',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 16.0;
              final gridItems = _trendingProducts.take(4).toList();
              final wideProduct = _trendingProducts.length > 4
                  ? _trendingProducts[4]
                  : null;

              final leftItems = <Widget>[];
              final rightItems = <Widget>[];

              // thuc hien logic chia cot
              for (int i = 0; i < gridItems.length; i++) {
                final product = gridItems[i];
                final isLeft = i % 2 == 0;

                // tao chieu cao so le cho bento grid
                double height;
                if (isLeft) {
                  height = (i == 0) ? 260 : 190;
                } else {
                  height = (i == 1) ? 190 : 260;
                }

                final item = Padding(
                  padding: const EdgeInsets.only(bottom: spacing),
                  child: _buildBentoItem(
                    product,
                    height: height,
                    isGlass: i % 2 == 0,
                  ),
                );

                if (isLeft) {
                  leftItems.add(item);
                } else {
                  rightItems.add(item);
                }
              }

              return Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Column(children: leftItems)),
                      const SizedBox(width: spacing),
                      Expanded(child: Column(children: rightItems)),
                    ],
                  ),

                  // hien thi san pham thu 5 - card lon chiem 2 cot
                  if (wideProduct != null) ...[
                    _buildBentoItem(
                      wideProduct,
                      height: 190,
                      isGlass: true,
                      isWide: true,
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBentoItem(
    Product product, {
    required double height,
    required bool isGlass,
    bool isWide = false,
  }) {
    return TrendingCard(
      product: product,
      height: height,
      isGlass: isGlass,
      isWide: isWide,
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Trending Now',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          GestureDetector(
            onTap: () {
              print('See All tapped');
            },
            child: Text(
              'See All',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TrendingCard extends StatelessWidget {
  final Product product;
  final double height;
  final bool isGlass;
  final bool isWide;

  const TrendingCard({
    super.key,
    required this.product,
    required this.height,
    this.isGlass = false,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: isGlass
            ? colorScheme.primaryContainer.withValues(alpha: 0.15)
            : colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isGlass
              ? colorScheme.primary.withValues(alpha: 0.1)
              : colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned.fill(
              child: isGlass
                  ? Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colorScheme.primaryContainer.withValues(alpha: 0.1),
                            colorScheme.surface,
                          ],
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            if (isWide)
              _buildWideContent(context, colorScheme)
            else
              _buildStandardContent(context, colorScheme),

            if (isGlass)
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStandardContent(BuildContext context, ColorScheme colorScheme) {
    return Stack(
      children: [
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          bottom: 80,
          child: Hero(
            tag: 'product_${product.id}',
            child: Image.asset(product.image, fit: BoxFit.contain),
          ),
        ),
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      product.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '\$${product.price.toInt()}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (product.tag != null) _buildTag(colorScheme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWideContent(BuildContext context, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (product.tag != null) ...[
                  _buildTag(colorScheme),
                  const SizedBox(height: 8),
                ],
                Text(
                  product.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  product.tagline,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Text(
                  '\$${product.price.toInt()}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: Hero(
              tag: 'product_${product.id}',
              child: Image.asset(product.image, fit: BoxFit.contain),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(ColorScheme colorScheme) {
    return Text(
      product.tag!.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        color: colorScheme.primary.withValues(alpha: 0.7),
        letterSpacing: 0.5,
      ),
    );
  }
}
