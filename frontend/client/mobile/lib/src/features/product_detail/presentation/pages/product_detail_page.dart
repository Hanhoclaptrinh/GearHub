import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/src/core/di/injection.dart';
import 'package:mobile/src/shared/models/product_model.dart';
import 'package:mobile/src/shared/models/product_variant_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../widgets/product_hero_section.dart';
import '../widgets/product_info_section.dart';
import '../widgets/sticky_bottom_bar.dart';
import 'package:mobile/src/features/product_detail/presentation/widgets/product_reviews_preview_section.dart';
import 'package:mobile/src/features/product_detail/presentation/widgets/product_trust_badges_section.dart';
import 'package:mobile/src/features/product_detail/presentation/widgets/product_recommendations_section.dart';
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

  // ma tran bien the - dua vao thuoc tinh tung bien the + thuoc tinh mac dinh
  Map<String, String> _selectedAttributes = {};

  // trang thai model 3d
  // tat khi dung che do ar - tranh tranh chap tai nguyen -> crash app
  bool _is3DMode = false;

  // selection matrix logic
  void _initializeAttributes(ProductModel product) {
    // kiem tra combo thuoc tinh dang duoc lua chon co trong khong
    // chi thuc hien neu combo hien tai chua duoc chon
    if (product.variants.isNotEmpty && _selectedAttributes.isEmpty) {
      final activeVariants = product.variants.where((v) => v.isActive).toList();
      if (activeVariants.isEmpty) return;

      final firstVariant = activeVariants.first;
      // danh sach thuoc tinh -> tao ma tran
      // eg: 3 color * 2 version -> 6 combo
      final configKeys = product.attributeConfig;

      // set combo cho bien the dau tien
      if (configKeys.isNotEmpty) {
        for (var key in configKeys) {
          if (firstVariant.attributes.containsKey(key)) {
            _selectedAttributes[key] = firstVariant.attributes[key].toString();
          }
        }
      } else {
        _selectedAttributes = Map<String, String>.from(
          firstVariant.attributes.map((k, v) => MapEntry(k, v.toString())),
        );
      }
    }
  }

  // lay bien the khop voi combo user chon
  ProductVariantModel? _getCurrentVariant(ProductModel product) {
    if (product.variants.isEmpty) return null;

    // lap qua danh sach bien the va tim combo khop voi lua chon user
    for (final v in product.variants) {
      if (!v.isActive) continue;

      final allMatch = _selectedAttributes.entries.every(
        (entry) => v.attributes[entry.key]?.toString() == entry.value,
      );
      if (allMatch) return v;
    }

    final activeVariants = product.variants.where((v) => v.isActive).toList();
    return activeVariants.isNotEmpty ? activeVariants.first : null;
  }

  void _onAttributeChanged(String key, String value, ProductModel product) {
    setState(() {
      _selectedAttributes[key] = value; // cap nhat thuoc tinh vua chon

      // kiem tra combo co ton tai khong
      final exactMatch = product.variants.any((v) {
        if (!v.isActive) return false;
        return _selectedAttributes.entries.every(
          (entry) => v.attributes[entry.key]?.toString() == entry.value,
        );
      });

      if (!exactMatch) {
        // neu khong co combo vua chon
        // tim mot bien the thay the
        // thay doi cac thuoc tinh con lai
        final fallback = product.variants
            .cast<ProductVariantModel?>()
            .firstWhere(
              (v) => v!.isActive && v.attributes[key]?.toString() == value,
              orElse: () => null,
            );
        if (fallback != null) {
          final configKeys = product.attributeConfig;
          if (configKeys.isNotEmpty) {
            final newMap = <String, String>{};
            for (var k in configKeys) {
              if (fallback.attributes.containsKey(k)) {
                newMap[k] = fallback.attributes[k].toString();
              }
            }
            _selectedAttributes = newMap;
          } else {
            _selectedAttributes = Map<String, String>.from(
              fallback.attributes.map((k, v) => MapEntry(k, v.toString())),
            );
          }
        }
      }

      // cap nhat so luong hang hoa theo tung combo bien the
      final newVariant = _getCurrentVariant(product);
      final maxQty = newVariant?.stock ?? 0;
      if (maxQty == 0) {
        _quantity = 0;
      } else if (_quantity > maxQty) {
        _quantity = maxQty;
      } else if (_quantity == 0) {
        _quantity = 1;
      }
    });
  }

  bool isComboAvailable(String key, String value, ProductModel product) {
    final hypothetical = Map<String, String>.from(_selectedAttributes);
    hypothetical[key] = value;

    final configKeys = product.attributeConfig;

    return product.variants.any((v) {
      if (!v.isActive) return false;

      if (configKeys.isNotEmpty) {
        return configKeys.every((k) {
          final targetValue = hypothetical[k];
          if (targetValue == null) return true;
          return v.attributes[k]?.toString() == targetValue;
        });
      }

      return hypothetical.entries.every(
        (entry) => v.attributes[entry.key]?.toString() == entry.value,
      );
    });
  }

  bool isValueInStock(String key, String value, ProductModel product) {
    return product.variants.any(
      (v) =>
          v.isActive && v.attributes[key]?.toString() == value && v.stock > 0,
    );
  }

  // xu ly truoc khi chuyen sang mode ar
  void _navigateToAR(ProductModel product) {
    if (_is3DMode) {
      // tat model 3d truoc de khong tranh chap tai nguyen phan cung voi ar mode
      setState(() => _is3DMode = false);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _pushARPage(product);
      });
    } else {
      _pushARPage(product);
    }
  }

  void _pushARPage(ProductModel product) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductARViewPage(product: product)),
    );
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _initializeAttributes(widget.initialProduct);
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

        if (state is ProductDetailLoaded && _selectedAttributes.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _initializeAttributes(currentProduct));
            }
          });
        }

        final relatedProducts = state is ProductDetailLoaded
            ? state.relatedProducts
            : <ProductModel>[];
        final currentVariant = _getCurrentVariant(currentProduct);
        final maxQty = currentVariant?.stock ?? 0;

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
                        Icons.arrow_back_ios_rounded,
                        color: Colors.black,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(LucideIcons.box, color: Colors.black),
                        onPressed: () => _navigateToAR(currentProduct),
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
                      currentVariant: currentVariant,
                      selectedAttributes: _selectedAttributes,
                      is3DMode: _is3DMode,
                      onAttributeChanged: (key, value) =>
                          _onAttributeChanged(key, value, currentProduct),
                      on3DToggle: () => setState(() => _is3DMode = !_is3DMode),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: ProductInfoSection(
                      product: currentProduct,
                      selectedAttributes: _selectedAttributes,
                      quantity: _quantity,
                      maxQuantity: maxQty,
                      onAttributeChanged: (key, value) =>
                          _onAttributeChanged(key, value, currentProduct),
                      isComboAvailable: (key, value) =>
                          isComboAvailable(key, value, currentProduct),
                      isValueInStock: (key, value) =>
                          isValueInStock(key, value, currentProduct),
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
                    child: ProductReviewsPreviewSection(
                      product: currentProduct,
                    ),
                  ),
                  const SliverToBoxAdapter(child: ProductTrustBadgesSection()),
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
                  selectedVariant: currentVariant,
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
