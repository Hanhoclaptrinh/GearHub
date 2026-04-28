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
                title: 'DANH MỤC',
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
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.15,
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
      [const Color(0xFF0B132B), const Color(0xFF152243)],
      [const Color(0xFF121212), const Color(0xFF242424)],
      [const Color(0xFF170F23), const Color(0xFF2D1A4A)],
      [const Color(0xFF1A0D0D), const Color(0xFF331717)],
    ];

    final gradient = gradients[index % gradients.length];

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        print('Category: ${category.slug}');
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: gradient.last.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // category img
            Positioned(
              right: -10,
              bottom: -10,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 0.5,
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: category.iconUrl != null
                      ? (category.iconUrl!.toLowerCase().endsWith('.svg')
                            ? SvgPicture.network(
                                category.iconUrl!,
                                fit: BoxFit.contain,
                                colorFilter: const ColorFilter.mode(
                                  Colors.white,
                                  BlendMode.srcIn,
                                ),
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
                                  color: Colors.white24,
                                  size: 36,
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
                          color: Colors.white24,
                          size: 36,
                        ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // cate name
                  Text(
                    category.title.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
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
                        'ĐÃ BÁN',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.4),
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${category.totalSold}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.amberAccent,
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
