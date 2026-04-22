import 'package:flutter/material.dart';
import 'package:mobile/src/shared/models/product.dart';
import 'package:mobile/src/shared/widgets/section_header.dart';
import 'package:mobile/src/shared/widgets/product_card.dart';
import 'package:mobile/src/features/product_detail/presentation/pages/product_detail_page.dart';

class NewArrivalsSection extends StatelessWidget {
  const NewArrivalsSection({super.key});

  static const List<Product> _demoProducts = [
    Product(
      id: 'n1',
      name: 'Apple Airpods Max',
      tagline: 'Spatial Audio.',
      price: 549,
      image: 'assets/images/hero2.png',
      tag: 'NEW',
    ),
    Product(
      id: 'n2',
      name: 'ROG Strix Helios II',
      tagline: 'Premium Gaming Case',
      price: 3000,
      image: 'assets/images/hero3.png',
      tag: 'HOT',
    ),
    Product(
      id: 'n3',
      name: 'Apple Vision Pro',
      tagline: 'Spatial Computing',
      price: 3499,
      image: 'assets/images/hero4.png',
      tag: 'LIMIT',
    ),
    Product(
      id: 'n4',
      name: 'PS5 DualSense Edge',
      tagline: 'Pro Controller',
      price: 199,
      image: 'assets/images/hero1.png',
      tag: 'NEW',
    ),
    Product(
      id: 'n5',
      name: 'Keychron Q1 Max',
      tagline: 'Wireless QMK/VIA',
      price: 219,
      image: 'assets/images/keyboard_hero.png',
    ),
    Product(
      id: 'n6',
      name: 'Razer DeathAdder V3',
      tagline: 'Ultra-Light Mouse',
      price: 89,
      image: 'assets/images/mouse_product.png',
    ),
    Product(
      id: 'n7',
      name: 'GMK Keycap Set',
      tagline: 'Cherry Profile PBT',
      price: 110,
      image: 'assets/images/keycaps_product.png',
      tag: 'HOT',
    ),
    Product(
      id: 'n8',
      name: 'ROG Strix Scope II',
      tagline: 'Mechanical Keyboard',
      price: 179,
      image: 'assets/images/keyboard_hero.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'New Arrivals',
          actionText: 'See All',
          onActionTap: () {
            // chuyen huong toi trang new arrivals
          },
        ),
        const SizedBox(height: 20),
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
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          ProductDetailPage(product: _demoProducts[index]),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
