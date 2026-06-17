import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/core/di/injection.dart';
import 'package:mobile/src/core/utils/brand_identity_helper.dart';
import 'package:mobile/src/features/chat/presentation/widgets/concierge_entry_button.dart';
import 'package:mobile/src/features/product_compare/presentation/pages/product_compare_page.dart';
import 'package:mobile/src/shared/models/product_model.dart';
import 'package:mobile/src/shared/models/product_variant_model.dart';
import 'package:mobile/src/shared/widgets/error_illustration_widget.dart';
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
    _saveRecentlyViewed(widget.initialProduct);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final offset = _scrollController.offset;

    //hiệu ứng show/hide cho header
    if (offset > 100 && !_showHeader) setState(() => _showHeader = true);
    if (offset <= 100 && _showHeader) setState(() => _showHeader = false);

    //show hide bottom bar
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

  void _saveRecentlyViewed(ProductModel product) async {
    try {
      final prefs = getIt<SharedPreferences>();
      final List<String> list = prefs.getStringList('recently_viewed') ?? [];
      final attributesJson = jsonEncode(_selectedAttributes);
      final entry =
          '${product.id}|${product.name}|${product.price}|${product.image}|$attributesJson';

      list.removeWhere((item) => item.startsWith('${product.id}|'));
      list.insert(0, entry);
      if (list.length > 10) {
        list.removeRange(10, list.length);
      }
      await prefs.setStringList('recently_viewed', list);
    } catch (e) {
      debugPrint('Error saving recently viewed: $e');
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

  void _navigateToCompare(ProductModel product) {
    final currentVariant = _getCurrentVariant(product);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductComparePage(
          initialProduct: product,
          initialVariant: currentVariant,
        ),
      ),
    );
  }

  Widget _buildDynamicAura(String brandName) {
    final theme = Theme.of(context);
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
              Container(color: theme.scaffoldBackgroundColor),
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
        if (state is ProductDetailError) {
          final theme = Theme.of(context);
          return Scaffold(
            appBar: AppBar(
              backgroundColor: theme.scaffoldBackgroundColor,
              elevation: 0,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: theme.colorScheme.onSurface,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'Lỗi tải sản phẩm',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              centerTitle: true,
            ),
            body: ErrorIllustrationWidget(
              message: state.message,
              onRetry: () => context.read<ProductDetailCubit>().loadProduct(
                widget.initialProduct.id,
              ),
            ),
          );
        }

        final product = state is ProductDetailLoaded
            ? state.product
            : widget.initialProduct;
        final variant = _getCurrentVariant(product);

        int maxStock = variant?.stock ?? 0;
        if (variant != null && variant.hasActiveFlashSale) {
          final remainingFlash = (variant.flashStockLimit ?? 0) - (variant.flashSoldCount ?? 0);
          maxStock = remainingFlash > 0 ? remainingFlash : 0;
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          extendBodyBehindAppBar: true,
          body: Stack(
            children: [
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
                          onARPressed: () {
                            setState(() => _is3DMode = false);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ProductARViewPage(product: product),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: ProductInfoSection(
                      product: product,
                      selectedAttributes: _selectedAttributes,
                      quantity: _quantity,
                      maxQuantity: maxStock,
                      onAttributeChanged: (k, v) {
                        setState(() {
                          _selectedAttributes[k] = v;
                          final newVariant = _getCurrentVariant(product);
                          int newMaxStock = newVariant?.stock ?? 0;
                          if (newVariant != null && newVariant.hasActiveFlashSale) {
                            final remainingFlash = (newVariant.flashStockLimit ?? 0) - (newVariant.flashSoldCount ?? 0);
                            newMaxStock = remainingFlash > 0 ? remainingFlash : 0;
                          }
                          if (_quantity > newMaxStock) {
                            _quantity = newMaxStock.clamp(1, 99);
                          }
                        });
                      },
                      isComboAvailable: (_, __) => true,
                      isValueInStock: (_, __) => true,
                      onIncrement: () {
                        if (_quantity < maxStock) {
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
                          _startUpdateQuantity(true, maxStock),
                      onLongPressDecrement: () =>
                          _startUpdateQuantity(false, maxStock),
                      onLongPressEnd: _stopUpdateQuantity,
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
                  SliverToBoxAdapter(
                    child: ProductTrustBadgesSection(
                      accentColor: BrandIdentityHelper.getIdentity(
                        product.brandName ?? '',
                      ).accent,
                    ),
                  ),
                  const SliverPadding(padding: EdgeInsets.only(bottom: 140)),
                ],
              ),

              _buildHeader(product),

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

  Widget _buildHeader(ProductModel product) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 400),
      opacity: _showHeader ? 1.0 : 0.0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 100,
            padding: const EdgeInsets.only(top: 40, left: 8, right: 8),
            color: theme.scaffoldBackgroundColor.withValues(alpha: 0.8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: cs.onSurface,
                    size: 24,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                Text(
                  "Trải nghiệm sản phẩm",
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        LucideIcons.gitCompare,
                        color: cs.onSurface,
                        size: 20,
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _navigateToCompare(product);
                      },
                    ),
                    const SizedBox(width: 4),
                    const ConciergeEntryButton(compact: true),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
