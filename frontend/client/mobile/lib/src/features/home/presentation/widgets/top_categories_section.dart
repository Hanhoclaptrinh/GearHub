import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile/src/shared/widgets/section_header.dart';
import '../state/home_cubit.dart';
import '../state/home_state.dart';
import '../../domain/entities/category_entity.dart';

class TopCategoriesSection extends StatelessWidget {
  const TopCategoriesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        if (state is HomeLoaded) {
          final categories = state.topCategories;
          if (categories.isEmpty) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                index: '01',
                title: 'Danh mục nổi bật',
                actionText: 'Tất cả',
                onActionTap: () => print('Go to categories'),
              ),
              const SizedBox(height: 16),
              // grid 2x2
              GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: categories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                ),
                itemBuilder: (context, index) {
                  return _ModernCategoryCard(
                    category: categories[index],
                    index: index,
                  );
                },
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _ModernCategoryCard extends StatelessWidget {
  final CategoryEntity category;
  final int index;

  const _ModernCategoryCard({required this.category, required this.index});

  @override
  Widget build(BuildContext context) {
    final List<List<Color>> gradients = [
      [const Color(0xFFF0F9FF), const Color(0xFFE0F2FE)],
      [const Color(0xFFFDF2F8), const Color(0xFFFCE7F3)],
      [const Color(0xFFF0FDF4), const Color(0xFFDCFCE7)],
      [const Color(0xFFFFF7ED), const Color(0xFFFFEDD5)],
    ];

    final gradient = gradients[index % gradients.length];

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        print('Category: ${category.slug}');
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          boxShadow: [
            BoxShadow(
              color: gradient.last.withValues(alpha: 0.5),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // category img
            Positioned(
              right: -20,
              bottom: -20,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(15),
                child: Center(
                  child: category.iconUrl != null
                      ? (category.iconUrl!.toLowerCase().endsWith('.svg')
                            ? SvgPicture.network(
                                category.iconUrl!,
                                fit: BoxFit.contain,
                                placeholderBuilder: (_) => const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : CachedNetworkImage(
                                imageUrl: category.iconUrl!,
                                fit: BoxFit.contain,
                                errorWidget: (_, __, ___) => const Icon(
                                  Icons.category_outlined,
                                  color: Colors.black26,
                                  size: 40,
                                ),
                                placeholder: (_, __) => const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ))
                      : const Icon(
                          Icons.category_outlined,
                          color: Colors.black26,
                          size: 40,
                        ),
                ),
              ),
            ),

            // 2. Text Content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // cate name
                  Text(
                    category.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                      letterSpacing: -0.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  // total sold
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đã bán',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B).withValues(alpha: 0.5),
                        ),
                      ),
                      Text(
                        '${category.totalSold}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
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
