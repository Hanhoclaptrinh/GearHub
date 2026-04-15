import 'package:flutter/material.dart';
import 'package:mobile/src/features/home/domain/models/product.dart';
import 'product_card.dart';

class NewArrivalsSection extends StatelessWidget {
  const NewArrivalsSection({super.key});

  static const List<Product> _demoProducts = [
    Product(
      id: '1',
      name: 'Apple Airpods Max',
      tagline: 'Spatial Audio.',
      price: 549,
      image: 'assets/images/hero2.png',
      tag: 'NEW',
    ),
    Product(
      id: '2',
      name: 'ROG Strix Helios II',
      tagline: 'Premium Gaming Case',
      price: 3000,
      image: 'assets/images/hero3.png',
      tag: 'HOT',
    ),
    Product(
      id: '3',
      name: 'Apple Vision Pro',
      tagline: 'Spatial Computing',
      price: 3499,
      image: 'assets/images/hero4.png',
      tag: 'LIMIT',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        const SizedBox(height: 16),
        SizedBox(
          height: 280,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            clipBehavior: Clip.none,
            itemCount: _demoProducts.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              return ProductCard(
                product: _demoProducts[index],
                onTap: () {
                  print('Product tapped: ${_demoProducts[index].name}');
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'New Arrivals',
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
