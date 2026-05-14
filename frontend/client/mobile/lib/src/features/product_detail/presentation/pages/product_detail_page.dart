import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/src/core/di/injection.dart';
import 'package:mobile/src/core/theme/app_colors.dart';
import 'package:mobile/src/core/utils/brand_identity_helper.dart';
import 'package:mobile/src/shared/models/product_model.dart';
import 'package:mobile/src/shared/models/product_variant_model.dart';
import '../widgets/product_hero_section.dart';
import '../widgets/product_info_section.dart';
import '../widgets/sticky_bottom_bar.dart';
import 'package:mobile/src/features/product_detail/presentation/widgets/product_reviews_preview_section.dart';
import 'package:mobile/src/features/product_detail/presentation/widgets/product_recommendations_section.dart';
import 'package:mobile/src/features/product_detail/presentation/widgets/product_trust_badges_section.dart';
import '../state/product_detail_cubit.dart';
import '../state/product_detail_state.dart';
import 'product_ar_view_page.dart';

class ProductDetailPage extends StatelessWidget {
  final ProductModel product;
  final Map<String, String>? initialAttributes;

  const ProductDetailPage({
    super.key,
    required this.product,
    this.initialAttributes,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ProductDetailCubit>()
        ..loadProduct(product.id)
        ..incrementView(product.id, 'device_id_placeholder'),
      child: ProductDetailView(
        initialProduct: product,
        initialAttributes: initialAttributes,
      ),
    );
  }
}

class ProductDetailView extends StatefulWidget {
  final ProductModel initialProduct;
  final Map<String, String>? initialAttributes;

  const ProductDetailView({
    super.key,
    required this.initialProduct,
    this.initialAttributes,
  });

  @override
  State<ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends State<ProductDetailView> {
  late final ScrollController _scrollController;
  bool _showHeader = false;
  bool _isBottomBarVisible = true;
  double _lastScrollOffset = 0;
  int _quantity = 1;
  Map<String, String> _selectedAttributes = {};
  bool _is3DMode = false;
  Timer? _quantityTimer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _initializeAttributes(widget.initialProduct);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final offset = _scrollController.offset;

    // hieu ung show hide cho header
    if (offset > 100 && !_showHeader) setState(() => _showHeader = true);
    if (offset <= 100 && _showHeader) setState(() => _showHeader = false);

    // show hide bottom bar
    if (offset > _lastScrollOffset && offset > 200) {
      if (_isBottomBarVisible) setState(() => _isBottomBarVisible = false);
    } else if (offset < _lastScrollOffset) {
      if (!_isBottomBarVisible) setState(() => _isBottomBarVisible = true);
    }
    _lastScrollOffset = offset;
  }

  void _startUpdateQuantity(bool increment, int maxStock) {
    _quantityTimer?.cancel();
    _quantityTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        if (increment) {
          if (_quantity < maxStock) {
            _quantity++;
            HapticFeedback.lightImpact();
          }
        } else {
          if (_quantity > 1) {
            _quantity--;
            HapticFeedback.lightImpact();
          }
        }
      });
    });
  }

  void _stopUpdateQuantity() {
    _quantityTimer?.cancel();
  }

  void _initializeAttributes(ProductModel product) {
    if (widget.initialAttributes != null &&
        widget.initialAttributes!.isNotEmpty) {
      _selectedAttributes = Map<String, String>.from(widget.initialAttributes!);
      return;
    }
    if (product.variants.isNotEmpty) {
      final v = product.variants.firstWhere(
        (v) => v.isActive,
        orElse: () => product.variants.first,
      );
      _selectedAttributes = Map<String, String>.from(
        v.attributes.map((k, v) => MapEntry(k, v.toString())),
      );
    }
  }

  ProductVariantModel? _getCurrentVariant(ProductModel product) {
    for (final v in product.variants) {
      if (v.isActive &&
          _selectedAttributes.entries.every(
            (e) => v.attributes[e.key]?.toString() == e.value,
          )) {
        return v;
      }
    }
    return product.variants.isNotEmpty ? product.variants.first : null;
  }

  Widget _buildDynamicAura(String brandName) {
    final identity = BrandIdentityHelper.getIdentity(brandName);
    final accent = identity.accent;

    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _scrollController,
        builder: (context, child) {
          final offset = _scrollController.hasClients
              ? _scrollController.offset
              : 0.0;
          final auraTop = -offset * 0.35;

          return Stack(
            children: [
              Container(color: const Color(0xFF07070A)),
              Positioned(
                top: auraTop - 50,
                right: -150,
                child: Container(
                  width: 600,
                  height: 600,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        accent.withValues(alpha: 0.18),
                        accent.withValues(alpha: 0.05),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: auraTop + 450,
                left: -200,
                child: Container(
                  width: 500,
                  height: 500,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        accent.withValues(alpha: 0.14),
                        accent.withValues(alpha: 0.03),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: auraTop + 200,
                left: 100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        accent.withValues(alpha: 0.06),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductDetailCubit, ProductDetailState>(
      builder: (context, state) {
        final product = state is ProductDetailLoaded
            ? state.product
            : widget.initialProduct;
        final variant = _getCurrentVariant(product);

        return Scaffold(
          backgroundColor: AppColors.background,
          extendBodyBehindAppBar: true,
          body: Stack(
            children: [
              // dynamic bg
              _buildDynamicAura(product.brandName ?? ""),

              CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: AnimatedBuilder(
                      animation: _scrollController,
                      builder: (context, child) {
                        return ProductHeroSection(
                          product: product,
                          currentVariant: variant,
                          selectedAttributes: _selectedAttributes,
                          is3DMode: _is3DMode,
                          scrollOffset: _scrollController.hasClients
                              ? _scrollController.offset
                              : 0.0,
                          onAttributeChanged: (k, v) =>
                              setState(() => _selectedAttributes[k] = v),
                          on3DToggle: () =>
                              setState(() => _is3DMode = !_is3DMode),
                          onARPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProductARViewPage(product: product),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: ProductInfoSection(
                      product: product,
                      selectedAttributes: _selectedAttributes,
                      quantity: _quantity,
                      maxQuantity: variant?.stock ?? 0,
                      onAttributeChanged: (k, v) {
                        setState(() {
                          _selectedAttributes[k] = v;
                          // reset qty neu vuot qua stock
                          final newVariant = _getCurrentVariant(product);
                          if (_quantity > (newVariant?.stock ?? 0)) {
                            _quantity = (newVariant?.stock ?? 0).clamp(1, 99);
                          }
                        });
                      },
                      isComboAvailable: (_, __) => true,
                      isValueInStock: (_, __) => true,
                      onIncrement: () {
                        if (_quantity < (variant?.stock ?? 0)) {
                          setState(() => _quantity++);
                          HapticFeedback.lightImpact();
                        }
                      },
                      onDecrement: () {
                        if (_quantity > 1) {
                          setState(() => _quantity--);
                          HapticFeedback.lightImpact();
                        }
                      },
                      onLongPressIncrement: () =>
                          _startUpdateQuantity(true, variant?.stock ?? 0),
                      onLongPressDecrement: () =>
                          _startUpdateQuantity(false, variant?.stock ?? 0),
                      onLongPressEnd: _stopUpdateQuantity,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: ProductTrustBadgesSection(
                      accentColor: BrandIdentityHelper.getIdentity(
                        product.brandName ?? '',
                      ).accent,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: ProductReviewsPreviewSection(product: product),
                  ),
                  SliverToBoxAdapter(
                    child: ProductRecommendationsSection(
                      recommendations: state is ProductDetailLoaded
                          ? state.relatedProducts
                          : [],
                    ),
                  ),
                  const SliverPadding(padding: EdgeInsets.only(bottom: 140)),
                ],
              ),

              _buildHeader(),

              Positioned(
                bottom: 32,
                left: 24,
                right: 24,
                child: StickyBottomBar(
                  product: product,
                  selectedVariant: variant,
                  quantity: _quantity,
                  isVisible: _isBottomBarVisible,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 400),
      opacity: _showHeader ? 1.0 : 0.0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 100,
            padding: const EdgeInsets.only(top: 40, left: 16, right: 16),
            color: AppColors.background.withValues(alpha: 0.8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text(
                  "Trải nghiệm sản phẩm",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
