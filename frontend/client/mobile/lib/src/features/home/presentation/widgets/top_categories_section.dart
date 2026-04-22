import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/src/shared/widgets/section_header.dart';

class TopCategoriesSection extends StatelessWidget {
  const TopCategoriesSection({super.key});

  static const List<_TopCategory> _categories = [
    _TopCategory(
      title: 'KEYBOARDS',
      subtitle: 'Mechanical & Custom',
      image: 'assets/images/keyboard_hero.png',
      gradient: [Color(0xFFE0E7FF), Color(0xFFC7D2FE)],
    ),
    _TopCategory(
      title: 'AUDIO',
      subtitle: 'Headphones & Speakers',
      image: 'assets/images/hero2.png',
      gradient: [Color(0xFFE2E8F0), Color(0xFFCBD5E1)],
    ),
    _TopCategory(
      title: 'GAMING',
      subtitle: 'PC & Console',
      image: 'assets/images/hero3.png',
      gradient: [Color(0xFFCCFBFE), Color(0xFF90E0EF)],
    ),
    _TopCategory(
      title: 'WEARABLES',
      subtitle: 'Watch & VR',
      image: 'assets/images/hero4.png',
      gradient: [Color(0xFFF5F3FF), Color(0xFFDDD6FE)],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Top Categories',
          actionText: 'See All',
          onActionTap: () {
            print('see all categories');
          },
        ),
        const SizedBox(height: 20),
        GridView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.95,
          ),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            return _TopCategoryCard(category: _categories[index]);
          },
        ),
      ],
    );
  }
}

class _TopCategory {
  final String title;
  final String subtitle;
  final String image;
  final List<Color> gradient;

  const _TopCategory({
    required this.title,
    required this.subtitle,
    required this.image,
    required this.gradient,
  });
}

class _TopCategoryCard extends StatelessWidget {
  final _TopCategory category;

  const _TopCategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        print('product list page filtered by category');
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            colors: category.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: category.gradient.first.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              right: -10,
              bottom: -10,
              width: 120,
              height: 120,
              child: Opacity(
                opacity: 0.6,
                child: Image.asset(category.image, fit: BoxFit.contain),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: colorScheme.onSurface,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category.subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Explore',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
