import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/features/home/data/models/category_model.dart';
import 'package:mobile/src/shared/widgets/section_header.dart';
import 'category_card.dart';

class QuickCategories extends StatefulWidget {
  const QuickCategories({super.key});

  @override
  State<QuickCategories> createState() => _QuickCategoriesState();
}

class _QuickCategoriesState extends State<QuickCategories> {
  int selectedIndex = 0;

  static const List<CategoryModel> _categories = [
    CategoryModel(
      title: 'Keyboard',
      icon: LucideIcons.keyboard,
      slug: 'keyboard',
    ),
    CategoryModel(title: 'Mouse', icon: LucideIcons.mouse, slug: 'mouse'),
    CategoryModel(title: 'Audio', icon: LucideIcons.headphones, slug: 'audio'),
    CategoryModel(title: 'Monitor', icon: LucideIcons.monitor, slug: 'monitor'),
    CategoryModel(title: 'Laptop', icon: LucideIcons.laptop, slug: 'laptop'),
    CategoryModel(title: 'Gaming', icon: LucideIcons.gamepad2, slug: 'gaming'),
    CategoryModel(title: 'Watch', icon: LucideIcons.watch, slug: 'smartwatch'),
    CategoryModel(
      title: 'Accessories',
      icon: LucideIcons.usb,
      slug: 'accessories',
    ),
  ];

  static const List<Color> _categoryColors = [
    Color(0xFF3B82F6),
    Color(0xFF06B6D4),
    Color(0xFFF59E0B),
    Color(0xFF10B981),
    Color(0xFF8B5CF6),
    Color(0xFFEF4444),
    Color(0xFF64748B),
    Color(0xFFEC4899),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Quick Access',
          actionText: 'See All',
          onActionTap: () {
            // chuyen huong toi trang all categories
          },
        ),
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
                  if (selectedIndex != index) {
                    setState(() => selectedIndex = index);
                    HapticFeedback.selectionClick();
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
