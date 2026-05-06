import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/src/core/di/injection.dart';
import 'package:mobile/src/features/cart/presentation/state/cart_cubit.dart';
import 'package:mobile/src/features/product_detail/data/datasources/product_detail_remote_datasource.dart';
import 'package:mobile/src/features/product_detail/presentation/pages/product_detail_page.dart';
import 'package:mobile/src/features/wishlist/presentation/state/wishlist_cubit.dart';
import 'package:mobile/src/features/wishlist/presentation/state/wishlist_state.dart';
import 'package:mobile/src/shared/models/product_model.dart';
import 'package:mobile/src/shared/widgets/small_product_card.dart';
import 'package:mobile/src/shared/widgets/stock_limit_dialog.dart';

class WishlistProductCard extends StatelessWidget {
  final ProductModel product;

  const WishlistProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WishlistCubit, WishlistState>(
      builder: (context, state) {
        final isFav =
            state is WishlistLoaded &&
            state.products.any((p) => p.id == product.id);

        return SmallProductCard(
          product: product,
          isFavorite: isFav,
          heroTag: 'wishlist_${product.id}',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailPage(product: product),
              ),
            );
          },
          onFavoriteTap: () {
            HapticFeedback.mediumImpact();
            context.read<WishlistCubit>().toggleWishlist(product.id);
          },
          onCartTap: () async {
            try {
              HapticFeedback.mediumImpact();
              final pDetail = await getIt<ProductDetailRemoteDatasource>()
                  .getProductDetail(product.id);

              if (context.mounted) {
                if (pDetail.variants.isNotEmpty) {
                  final targetVariant = pDetail.variants.first;

                  // check stock limit
                  final cartCubit = context.read<CartCubit>();
                  final existingItem = cartCubit.state.cart?.items
                      .where((i) => i.productVariant.id == targetVariant.id)
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
    );
  }
}
