import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/core/di/injection.dart';
import 'package:mobile/src/features/cart/presentation/state/cart_cubit.dart';
import 'package:mobile/src/features/product_detail/data/datasources/product_detail_remote_datasource.dart';
import 'package:mobile/src/features/product_detail/presentation/pages/product_detail_page.dart';
import 'package:mobile/src/features/wishlist/presentation/state/wishlist_cubit.dart';
import 'package:mobile/src/features/wishlist/presentation/state/wishlist_state.dart';
import 'package:mobile/src/shared/widgets/product_card_shimmer.dart';
import 'package:mobile/src/shared/widgets/small_product_card.dart';
import 'package:mobile/src/shared/widgets/stock_limit_dialog.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<WishlistCubit>().fetchWishlist(refresh: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<WishlistCubit>().fetchWishlist();
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Yêu thích',
          style: TextStyle(
            color: Color(0xFF0A0A0F),
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: BlocBuilder<WishlistCubit, WishlistState>(
        builder: (context, state) {
          if (state is WishlistLoading) {
            return _buildLoading();
          }

          if (state is WishlistError) {
            return Center(child: Text(state.message));
          }

          if (state is WishlistLoaded) {
            if (state.products.isEmpty) {
              return _buildEmpty();
            }

            return RefreshIndicator(
              onRefresh: () =>
                  context.read<WishlistCubit>().fetchWishlist(refresh: true),
              color: const Color(0xFF3B82F6),
              child: GridView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.6,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: state.hasReachedMax
                    ? state.products.length
                    : state.products.length + 1,
                itemBuilder: (context, index) {
                  if (index >= state.products.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }

                  final productModel = state.products[index];

                  return SmallProductCard(
                    product: productModel,
                    isFavorite: true,
                    heroTag: 'wishlist_${productModel.id}_$index',
                    onTap: () async {
                      HapticFeedback.mediumImpact();
                      try {
                        final pDetail =
                            await getIt<ProductDetailRemoteDatasource>()
                                .getProductDetail(productModel.id);
                        if (context.mounted) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProductDetailPage(product: pDetail),
                            ),
                          );
                        }
                      } catch (e) {
                        debugPrint('Error fetching product detail: $e');
                      }
                    },
                    onFavoriteTap: () {
                      context.read<WishlistCubit>().toggleWishlist(
                        productModel.id,
                      );
                    },
                    onCartTap: () async {
                      try {
                        final pDetail =
                            await getIt<ProductDetailRemoteDatasource>()
                                .getProductDetail(productModel.id);
                        if (context.mounted) {
                          if (pDetail.variants.isNotEmpty) {
                            final targetVariant = pDetail.variants.first;

                            final cartCubit = context.read<CartCubit>();
                            final existingItem = cartCubit.state.cart?.items
                                .where(
                                  (i) =>
                                      i.productVariant.id == targetVariant.id,
                                )
                                .firstOrNull;

                            final currentQty = existingItem?.quantity ?? 0;

                            if (currentQty + 1 > targetVariant.stock) {
                              StockLimitDialog.show(
                                context,
                                stockCount: targetVariant.stock,
                                currentQty: currentQty,
                                message:
                                    'Số lượng sản phẩm trong kho không đủ để thêm vào giỏ hàng.\n\nKho hiện còn ${targetVariant.stock} sản phẩm và bạn đã có $currentQty sản phẩm trong giỏ.',
                              );
                              return;
                            }

                            cartCubit.addToCart(targetVariant, pDetail, 1);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã thêm vào giỏ hàng'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        debugPrint('Error adding to cart from wishlist: $e');
                      }
                    },
                  );
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildLoading() {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.6,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => const ProductCardShimmer(),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.heart,
              size: 48,
              color: Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Chưa có sản phẩm yêu thích',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0A0A0F),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Hãy thêm những sản phẩm bạn yêu thích\nvào danh sách này nhé!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF6B7280), height: 1.5),
          ),
        ],
      ),
    );
  }
}
