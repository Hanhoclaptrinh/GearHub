import 'package:lottie/lottie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile/src/core/di/injection.dart';
import 'package:mobile/src/features/product_detail/data/datasources/product_detail_remote_datasource.dart';
import 'package:mobile/src/features/product_detail/presentation/pages/product_detail_page.dart';
import 'package:mobile/src/features/wishlist/presentation/state/wishlist_cubit.dart';
import 'package:mobile/src/features/wishlist/presentation/state/wishlist_state.dart';
import 'package:mobile/src/features/cart/presentation/state/cart_cubit.dart';
import 'package:mobile/src/shared/widgets/stock_limit_dialog.dart';
import 'package:mobile/src/shared/widgets/error_illustration_widget.dart';
import 'package:mobile/src/shared/widgets/small_product_card_shimmer.dart';
import 'package:mobile/src/shared/models/product_model.dart';
import 'package:mobile/src/core/utils/formatter_utils.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _headerAnim;
  late Animation<double> _headerFade;
  final Set<String> _addingProductIds = {};

  @override
  void initState() {
    super.initState();
    _headerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _headerFade = CurvedAnimation(parent: _headerAnim, curve: Curves.easeOut);
    _headerAnim.forward();
    context.read<WishlistCubit>().fetchWishlist(refresh: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _headerAnim.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) context.read<WishlistCubit>().fetchWishlist();
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    return _scrollController.offset >=
        (_scrollController.position.maxScrollExtent * 0.9);
  }

  Future<void> _handleAddToCart(
    BuildContext context,
    ProductModel productModel,
  ) async {
    if (_addingProductIds.contains(productModel.id)) return;

    final cartCubit = context.read<CartCubit>();
    final cartState = cartCubit.state;

    setState(() {
      _addingProductIds.add(productModel.id);
    });

    try {
      final fullProduct = await getIt<ProductDetailRemoteDatasource>()
          .getProductDetail(productModel.id);

      if (fullProduct.variants.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sản phẩm không có biến thể hợp lệ')),
          );
        }
        return;
      }

      final variant = fullProduct.variants.firstWhere(
        (v) => v.isActive,
        orElse: () => fullProduct.variants.first,
      );

      final existingQty =
          cartState.cart?.items
              .where((i) => i.productVariant.id == variant.id)
              .firstOrNull
              ?.quantity ??
          0;

      if (existingQty + 1 > variant.stock) {
        if (context.mounted) {
          StockLimitDialog.show(
            context,
            stockCount: variant.stock,
            currentQty: existingQty,
          );
        }
        return;
      }

      cartCubit.addToCart(variant, fullProduct, 1);
      HapticFeedback.heavyImpact();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã thêm sản phẩm vào giỏ hàng'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error adding to cart: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể thêm sản phẩm vào giỏ hàng')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _addingProductIds.remove(productModel.id);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final Color bgColor = theme.scaffoldBackgroundColor;
    final Color textHigh = cs.onSurface;
    final Color textMid = cs.onSurfaceVariant;
    final Color borderCol = cs.outlineVariant;
    final Color fillCol = cs.surfaceContainerHighest;

    return Scaffold(
      backgroundColor: bgColor,
      body: BlocBuilder<WishlistCubit, WishlistState>(
        builder: (context, state) {
          return CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                floating: true,
                snap: true,
                backgroundColor: bgColor,
                elevation: 0,
                scrolledUnderElevation: 0,
                centerTitle: true,
                leading: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: textHigh,
                    size: 22,
                  ),
                ),
                titleSpacing: 4,
                title: FadeTransition(
                  opacity: _headerFade,
                  child: Text(
                    'Yêu thích',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: textHigh,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

              //loading
              if (state is WishlistLoading)
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (_, __) => const SmallProductCardShimmer(),
                      childCount: 6,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.55,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 16,
                        ),
                  ),
                )
              else if (state is WishlistError)
                SliverFillRemaining(
                  child: ErrorIllustrationWidget(
                    message: state.message,
                    onRetry: () => context.read<WishlistCubit>().fetchWishlist(
                      refresh: true,
                    ),
                  ),
                )
              else if (state is WishlistLoaded && state.products.isEmpty)
                SliverFillRemaining(child: _buildEmpty())
              else if (state is WishlistLoaded) ...[
                //item count label
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: Text(
                      '${state.products.length} SẢN PHẨM ĐÃ LƯU',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: textMid,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index >= state.products.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(
                                color: Color(0xFFFFB800),
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        }
                        final productModel = state.products[index];
                        return _buildGridItem(
                          context,
                          productModel,
                          index,
                          textHigh,
                          textMid,
                          borderCol,
                          fillCol,
                        );
                      },
                      childCount: state.hasReachedMax
                          ? state.products.length
                          : state.products.length + 1,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.55,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 16,
                        ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildGridItem(
    BuildContext context,
    ProductModel productModel,
    int index,
    Color textHigh,
    Color textMid,
    Color borderCol,
    Color fillCol,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isAdding = _addingProductIds.contains(productModel.id);

    return GestureDetector(
      onTap: () async {
        HapticFeedback.mediumImpact();
        try {
          final pDetail = await getIt<ProductDetailRemoteDatasource>()
              .getProductDetail(productModel.id);
          if (context.mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProductDetailPage(product: pDetail),
              ),
            );
          }
        } catch (e) {
          debugPrint('Error fetching product detail: $e');
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.0,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: fillCol,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  width: double.infinity,
                  height: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Hero(
                      tag: 'wishlist_${productModel.id}_$index',
                      child: CachedNetworkImage(
                        imageUrl: productModel.image,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 1,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Icon(
                          Icons.image_not_supported_outlined,
                          color: textMid.withValues(alpha: 0.3),
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      context.read<WishlistCubit>().toggleWishlist(
                        productModel.id,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: Color(0xFFFF6B8A),
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            productModel.baseName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textHigh,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatVND(productModel.price),
            style: TextStyle(
              color: textMid,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 32,
            child: isAdding
                ? Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.onSurface,
                      ),
                    ),
                  )
                : TextButton.icon(
                    onPressed: () => _handleAddToCart(context, productModel),
                    icon: Icon(
                      LucideIcons.shoppingBag,
                      size: 12,
                      color: cs.onPrimary,
                    ),
                    label: Text(
                      '+ Giỏ hàng',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: cs.onPrimary,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: cs.primary,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textHigh = cs.onSurface;
    final textMid = cs.onSurfaceVariant;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/emptycart.json',
              width: 200,
              height: 200,
            ),
            const SizedBox(height: 28),
            Text(
              'Hub này trống trơn :)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: textHigh,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Lướt Hub một vòng và thả tim để lấp đầy góc máy mơ ước nào.',
              textAlign: TextAlign.center,
              style: TextStyle(color: textMid, fontSize: 13, height: 1.6),
            ),
            const SizedBox(height: 36),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.shoppingBag,
                      color: cs.onPrimary,
                      size: 16,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'KHÁM PHÁ NGAY',
                      style: TextStyle(
                        color: cs.onPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
