import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/src/core/di/injection.dart';
import 'package:mobile/src/shared/models/product_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/shared/models/product_variant_model.dart';

import '../widgets/product_hero_section.dart';
import '../widgets/product_info_section.dart';
import '../widgets/sticky_bottom_bar.dart';
import '../widgets/product_reviews_preview_section.dart';
import '../widgets/product_recommendations_section.dart';
import '../state/product_detail_cubit.dart';
import '../state/product_detail_state.dart';
import 'product_ar_view_page.dart';

class ProductDetailPage extends StatelessWidget {
  final ProductModel product;

  const ProductDetailPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ProductDetailCubit>()
        ..loadProduct(product.id)
        ..incrementView(product.id, 'device_id_placeholder'),
      child: ProductDetailView(initialProduct: product),
    );
  }
}

class ProductDetailView extends StatefulWidget {
  final ProductModel initialProduct;

  const ProductDetailView({super.key, required this.initialProduct});

  @override
  State<ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends State<ProductDetailView> {
  late final ScrollController _scrollController;
  bool _showBottomBar = true;

  int _quantity = 1;
  Timer? _timer;

  int _selectedConfigIndex = 0;

  ProductVariantModel? _getCurrentVariant(ProductModel currentProduct) {
    if (currentProduct.variants.isEmpty) return null;
    if (_selectedConfigIndex >= currentProduct.variants.length) {
      return currentProduct.variants.first;
    }
    return currentProduct.variants[_selectedConfigIndex];
  }

  int _getEffectiveMaxQuantity(ProductModel currentProduct) {
    final v = _getCurrentVariant(currentProduct);
    return v?.stock ?? 0;
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      if (_showBottomBar) setState(() => _showBottomBar = false);
    } else if (_scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      if (!_showBottomBar) setState(() => _showBottomBar = true);
    }
  }

  void _startTimer(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (t) => action());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductDetailCubit, ProductDetailState>(
      builder: (context, state) {
        final currentProduct = state is ProductDetailLoaded
            ? state.product
            : widget.initialProduct;
        final relatedProducts = state is ProductDetailLoaded
            ? state.relatedProducts
            : <ProductModel>[];
        final maxQty = _getEffectiveMaxQuantity(currentProduct);

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Stack(
            children: [
              CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    expandedHeight: 0,
                    floating: true,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    leading: IconButton(
                      icon: const Icon(
                        LucideIcons.chevronLeft,
                        color: Colors.black,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(LucideIcons.box, color: Colors.black),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProductARViewPage(product: currentProduct),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          LucideIcons.share2,
                          color: Colors.black,
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  SliverToBoxAdapter(
                    child: ProductHeroSection(
                      product: currentProduct,
                      selectedVariantIndex: _selectedConfigIndex,
                      quantity: _quantity,
                      maxQuantity: maxQty,
                      onColorTarget: (index) {
                        setState(() {
                          _selectedConfigIndex = index;
                          if (_quantity > maxQty) _quantity = maxQty;
                          if (maxQty == 0) {
                            _quantity = 0;
                          } else if (_quantity == 0) {
                            _quantity = 1;
                          }
                        });
                      },
                      onIncrement: () {
                        if (_quantity < maxQty) {
                          setState(() => _quantity++);
                        }
                      },
                      onDecrement: () {
                        if (_quantity > 1) {
                          setState(() => _quantity--);
                        }
                      },
                      onLongPressIncrement: () => _startTimer(() {
                        if (_quantity < maxQty) {
                          setState(() => _quantity++);
                        }
                      }),
                      onLongPressDecrement: () => _startTimer(() {
                        if (_quantity > 1) {
                          setState(() => _quantity--);
                        }
                      }),
                      onLongPressEnd: () => _timer?.cancel(),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: ProductInfoSection(
                      product: currentProduct,
                      selectedConfigIndex: _selectedConfigIndex,
                      onConfigChanged: (index) {
                        setState(() {
                          _selectedConfigIndex = index;
                          if (_quantity > maxQty) _quantity = maxQty;
                          if (maxQty == 0) {
                            _quantity = 0;
                          } else if (_quantity == 0) {
                            _quantity = 1;
                          }
                        });
                      },
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: ProductReviewsPreviewSection(
                      product: currentProduct,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: ProductRecommendationsSection(
                      recommendations: relatedProducts,
                    ),
                  ),
                  const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
                ],
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: StickyBottomBar(
                  product: currentProduct,
                  isVisible: _showBottomBar,
                ),
              ),
              if (state is ProductDetailLoading)
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    minHeight: 2,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
