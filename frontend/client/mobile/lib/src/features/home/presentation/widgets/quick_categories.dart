import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/features/home/domain/models/category_model.dart';
import 'category_card.dart';

class QuickCategories extends StatefulWidget {
  const QuickCategories({super.key});

  @override
  State<QuickCategories> createState() => _QuickCategoriesState();
}

class _QuickCategoriesState extends State<QuickCategories> {
  int selectedIndex = 0;

  static const List<CategoryModel> _categories = [
    CategoryModel(title: 'Audio', icon: LucideIcons.headphones, slug: 'audio'),
    CategoryModel(title: 'Laptop', icon: LucideIcons.laptop, slug: 'laptop'),
    CategoryModel(title: 'Gaming', icon: LucideIcons.gamepad2, slug: 'gaming'),
    CategoryModel(
      title: 'Accessories',
      icon: LucideIcons.usb,
      slug: 'accessories',
    ),
    CategoryModel(title: 'Watch', icon: LucideIcons.watch, slug: 'smartwatch'),
  ];

  static const List<Color> _categoryColors = [
    Color(0xFF3B82F6),
    Color(0xFF06B6D4),
    Color(0xFFF59E0B),
    Color(0xFF10B981),
    Color(0xFF64748B),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        const SizedBox(height: 20),
        SizedBox(
          height: 100,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            clipBehavior: Clip.none,
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return CategoryCard(
                category: _categories[index],
                isSelected: selectedIndex == index,
                accentColor: _categoryColors[index % _categoryColors.length],
                onTap: () {
                  // tranh render thua
                  if (selectedIndex != index) {
                    setState(() => selectedIndex = index);
                    HapticFeedback.selectionClick();
                  }
                  print('${_categories[index].title} tapped');
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
            'Collections',
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
