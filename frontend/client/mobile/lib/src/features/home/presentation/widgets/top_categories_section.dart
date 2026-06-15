import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile/src/core/di/injection.dart';
import 'package:mobile/src/core/utils/formatter_utils.dart';
import 'package:mobile/src/shared/models/product_model.dart';
import 'package:mobile/src/features/explore/domain/repositories/explore_repository.dart';
import 'package:mobile/src/features/product_detail/presentation/pages/product_detail_page.dart';
import '../state/home_cubit.dart';
import '../state/home_state.dart';
import '../../domain/entities/category_entity.dart';

class TopCategoriesSection extends StatefulWidget {
  const TopCategoriesSection({super.key});

  @override
  State<TopCategoriesSection> createState() => _TopCategoriesSectionState();
}

class _TopCategoriesSectionState extends State<TopCategoriesSection> {
  late Future<List<Map<String, dynamic>>> _visibleCategoriesFuture;
  int _selectedCategoryIndex = 0;

  @override
  void initState() {
    super.initState();
    _visibleCategoriesFuture = _loadVisibleCategories();
  }

  Future<List<Map<String, dynamic>>> _loadVisibleCategories() async {
    final homeCubit = context.read<HomeCubit>();
    final state = homeCubit.state;
    if (state is! HomeLoaded) return [];

    final repo = getIt<ExploreRepository>();
    final List<Map<String, dynamic>> visibleItems = [];

    final categories = List<CategoryEntity>.from(state.topCategories);

    final results = await Future.wait(
      categories.map((cat) => repo.getProducts(categoryId: cat.id, limit: 5)),
    );

    for (int i = 0; i < categories.length; i++) {
      final products = results[i];
      if (products.isNotEmpty) {
        products.sort((a, b) => b.soldCount.compareTo(a.soldCount));
        visibleItems.add({
          'category': categories[i],
          'products': products.take(5).toList(),
        });
      }
      if (visibleItems.length >= 3) break;
    }

    return visibleItems;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _visibleCategoriesFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData || (snapshot.data?.isEmpty ?? true)) {
          return const SizedBox.shrink();
        }

        final visibleItems = snapshot.data!;

        if (_selectedCategoryIndex >= visibleItems.length) {
          _selectedCategoryIndex = 0;
        }

        final activeItem = visibleItems[_selectedCategoryIndex];
        final activeCategory = activeItem['category'] as CategoryEntity;
        final activeProducts = activeItem['products'] as List<ProductModel>;

        return Container(
          margin: const EdgeInsets.only(bottom: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Danh mục nổi bật',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              SizedBox(
                height: 48,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: visibleItems.length,
                  itemBuilder: (context, idx) {
                    final item = visibleItems[idx];
                    final cat = item['category'] as CategoryEntity;
                    final rank = '#0${idx + 1}';
                    final isSelected = idx == _selectedCategoryIndex;

                    return _CategoryTab(
                      label: cat.title,
                      rank: rank,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          _selectedCategoryIndex = idx;
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.03, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _CategoryProductsDeck(
                  key: ValueKey<String>(activeCategory.id),
                  products: activeProducts,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CategoryTab extends StatelessWidget {
  final String label;
  final String rank;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryTab({
    required this.label,
    required this.rank,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: isSelected
              ? (isDark ? Colors.white : Colors.black)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03)),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05)),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              rank,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? (isDark
                          ? Colors.black.withValues(alpha: 0.6)
                          : Colors.white.withValues(alpha: 0.6))
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.3)
                          : Colors.black.withValues(alpha: 0.3)),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? (isDark ? Colors.black : Colors.white)
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.7)
                          : Colors.black.withValues(alpha: 0.7)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryProductsDeck extends StatefulWidget {
  final List<ProductModel> products;

  const _CategoryProductsDeck({super.key, required this.products});

  @override
  State<_CategoryProductsDeck> createState() => _CategoryProductsDeckState();
}

class _CategoryProductsDeckState extends State<_CategoryProductsDeck> {
  late PageController _pageController;
  double _currentPage = 0.0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.82);
    _pageController.addListener(() {
      if (mounted) {
        setState(() {
          _currentPage = _pageController.page ?? 0.0;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 480,
          child: PageView.builder(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            itemCount: widget.products.length,
            itemBuilder: (context, idx) {
              final p = widget.products[idx];
              final double relativePosition = idx - _currentPage;
              return _CategoryProductCard(
                product: p,
                relativePosition: relativePosition,
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        _PageIndicator(
          count: widget.products.length,
          currentPage: _currentPage,
        ),
      ],
    );
  }
}

class _CategoryProductCard extends StatelessWidget {
  final ProductModel product;
  final double relativePosition;

  const _CategoryProductCard({
    required this.product,
    required this.relativePosition,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;

    final double absPos = relativePosition.abs();
    final double scale = (1.0 - (absPos * 0.08)).clamp(0.9, 1.0);
    final double opacity = (1.0 - (absPos * 0.5)).clamp(0.4, 1.0);

    final double imageParallax = relativePosition * 80.0;

    return Center(
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: scale,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProductDetailPage(product: product),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              height: 460,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: Colors.transparent,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: 20,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        'GEAR',
                        style: TextStyle(
                          fontSize: screenSize.width * 0.24,
                          fontWeight: FontWeight.w900,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : Colors.black.withValues(alpha: 0.03),
                          letterSpacing: -2,
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Center(
                            child: Transform.translate(
                              offset: Offset(imageParallax, -10),
                              child: CachedNetworkImage(
                                imageUrl: product.image,
                                width: screenSize.width * 0.65,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Text(
                          '${formatCompactNumber(product.soldCount)} đã bán'
                              .toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.5),
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 6),

                        Text(
                          product.baseName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.onSurface,
                            letterSpacing: -0.5,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),

                        Text(
                          product.tagline,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Chi tiết'.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 12,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
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
          ),
        ),
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  final int count;
  final double currentPage;

  const _PageIndicator({required this.count, required this.currentPage});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final double delta = (index - currentPage).abs();
        final double width = ((1.0 - delta).clamp(0.0, 1.0) * 12.0) + 6.0;
        final double opacity = (1.0 - delta).clamp(0.2, 1.0);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 2,
          width: width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2.5),
            color: (isDark ? Colors.white : Colors.black).withValues(
              alpha: opacity * (isDark ? 0.8 : 0.6),
            ),
          ),
        );
      }),
    );
  }
}
