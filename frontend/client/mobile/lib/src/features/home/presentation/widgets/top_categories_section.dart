import 'package:flutter/material.dart';
import 'package:mobile/src/core/theme/app_colors.dart';
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

    // sap xep theo totalSold
    final sortedParents = List<CategoryEntity>.from(state.parentCategories)
      ..sort((a, b) => b.totalSold.compareTo(a.totalSold));

    final parents = sortedParents.take(5).toList();

    final results = await Future.wait(
      parents.map((cat) => repo.getProducts(categoryId: cat.id, limit: 5)),
    );

    for (int i = 0; i < parents.length; i++) {
      final products = results[i];
      if (products.isNotEmpty) {
        products.sort((a, b) => b.soldCount.compareTo(a.soldCount));
        visibleItems.add({
          'category': parents[i],
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: visibleItems.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            return _CategoryVisibleRow(
              category: item['category'] as CategoryEntity,
              products: item['products'] as List<ProductModel>,
              index: idx,
            );
          }).toList(),
        );
      },
    );
  }
}

class _CategoryVisibleRow extends StatefulWidget {
  final CategoryEntity category;
  final List<ProductModel> products;
  final int index;

  const _CategoryVisibleRow({
    required this.category,
    required this.products,
    required this.index,
  });

  @override
  State<_CategoryVisibleRow> createState() => _CategoryVisibleRowState();
}

class _CategoryVisibleRowState extends State<_CategoryVisibleRow>
    with AutomaticKeepAliveClientMixin {
  late PageController _pageController;
  double _currentPage = 0.0;

  @override
  bool get wantKeepAlive => true;

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
    super.build(context);
    final rank = '#0${widget.index + 1}';

    return Container(
      margin: const EdgeInsets.only(bottom: 64),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rank,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.2),
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.category.title,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    letterSpacing: -0.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
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
        ],
      ),
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
    final double absPos = relativePosition.abs();
    final double scale = (1.0 - (absPos * 0.12)).clamp(0.85, 1.0);
    final double opacity = (1.0 - (absPos * 0.45)).clamp(0.6, 1.0);
    final double imageParallax = relativePosition * 140.0;

    // spotlight factor
    final bool isMain = absPos < 0.5;

    return Center(
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: opacity,
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
              height: 440,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.cardSurface, AppColors.background],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isMain ? 0.6 : 0.3),
                    blurRadius: 40,
                    offset: const Offset(0, 25),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 1.2,
                          colors: [
                            Colors.white.withValues(alpha: isMain ? 0.03 : 0.0),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ambient glow
                  if (isMain)
                    Positioned(
                      top: 40,
                      left: 60,
                      right: 60,
                      height: 160,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.brandBlue.withValues(alpha: 0.1),
                              blurRadius: 80,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                      ),
                    ),

                  // content
                  Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Center(
                            child: Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                if (isMain)
                                  Container(
                                    width: 120,
                                    height: 10,
                                    margin: const EdgeInsets.only(bottom: 20),
                                    decoration: BoxDecoration(
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.5,
                                          ),
                                          blurRadius: 25,
                                          spreadRadius: 5,
                                        ),
                                      ],
                                    ),
                                  ),
                                Transform.translate(
                                  offset: Offset(imageParallax * 0.4, -10),
                                  child: CachedNetworkImage(
                                    imageUrl: product.image,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // metadata
                        Text(
                          '${formatCompactNumber(product.soldCount)} đã bán'
                              .toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: AppColors.brandYellow.withValues(
                              alpha: isMain ? 0.5 : 0.2,
                            ),
                            letterSpacing: 1.8,
                          ),
                        ),
                        const SizedBox(height: 10),

                        Text(
                          product.baseName,
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: -0.6,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 6),

                        Text(
                          product.tagline,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // CTA
                        Row(
                          children: [
                            Text(
                              'Chi tiết'.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withValues(alpha: 0.8),
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 14,
                              color: Colors.white.withValues(alpha: 0.6),
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
