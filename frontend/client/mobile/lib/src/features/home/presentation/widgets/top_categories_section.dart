import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile/src/core/di/injection.dart';
import 'package:mobile/src/shared/models/product_model.dart';
import 'package:mobile/src/features/explore/domain/repositories/explore_repository.dart';
import 'package:mobile/src/features/product_detail/presentation/pages/product_detail_page.dart';
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
          final categories = state.topCategories.take(3).toList();
          if (categories.isEmpty) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: categories.map((cat) {
              final index = categories.indexOf(cat);
              return _CategoryPromoRow(category: cat, index: index);
            }).toList(),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _CategoryPromoRow extends StatefulWidget {
  final CategoryEntity category;
  final int index;

  const _CategoryPromoRow({required this.category, required this.index});

  @override
  State<_CategoryPromoRow> createState() => _CategoryPromoRowState();
}

class _CategoryPromoRowState extends State<_CategoryPromoRow>
    with AutomaticKeepAliveClientMixin {
  late Future<List<ProductModel>> _productsFuture;

  @override
  bool get wantKeepAlive => true;

  final List<Color> _categoryColors = [
    const Color.fromARGB(255, 204, 188, 164),
    const Color.fromARGB(255, 204, 231, 232),
    const Color.fromARGB(255, 204, 186, 186),
  ];

  @override
  void initState() {
    super.initState();
    _productsFuture = _fetchCategoryProducts();
  }

  Future<List<ProductModel>> _fetchCategoryProducts() async {
    try {
      final repository = getIt<ExploreRepository>();
      final products = await repository.getProducts(
        categoryId: widget.category.id,
        limit: 6,
      );
      products.sort((a, b) => b.soldCount.compareTo(a.soldCount));
      return products;
    } catch (e) {
      debugPrint(
        '[Category Promo] Error fetching products for ${widget.category.title}: $e',
      );
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (widget.category.description == null || widget.category.description!.isEmpty) {
      return const SizedBox.shrink();
    }
    final bgColor = _categoryColors[widget.index % _categoryColors.length];
    final headerText = widget.category.description!;

    return FutureBuilder<List<ProductModel>>(
      future: _productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final products = snapshot.data ?? [];
        if (products.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                headerText,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0A0A0F),
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 440,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: products.length,
                  itemBuilder: (context, idx) {
                    final p = products[idx];
                    return _CategoryProductCard(product: p, color: bgColor);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CategoryProductCard extends StatelessWidget {
  final ProductModel product;
  final Color color;

  const _CategoryProductCard({required this.product, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      margin: const EdgeInsets.only(right: 18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.none,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Center(
                    child: CachedNetworkImage(
                      imageUrl: product.image,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.image_not_supported_outlined,
                        color: Colors.black26,
                        size: 64,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  product.baseName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0A0A0F),
                    letterSpacing: -0.8,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  product.tagline,
                  maxLines: 2,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF3B82F6),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ProductDetailPage(product: product),
                      ),
                    );
                  },
                  child: Container(
                    width: 100,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0A0F),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Center(
                      child: Text(
                        'Mua',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
