import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/src/shared/models/product_model.dart';
import 'package:mobile/src/shared/models/product_variant_model.dart';
import 'package:mobile/src/features/cart/presentation/state/cart_cubit.dart';
import 'package:mobile/src/shared/widgets/stock_limit_dialog.dart';

mixin CartMixin<T extends StatefulWidget> on State<T> {
  bool isAddingToCart = false;

  Future<void> handleAddToCart({
    required ProductVariantModel variant,
    required ProductModel product,
    int quantity = 1,
  }) async {
    HapticFeedback.mediumImpact();

    //lấy trạng thái giỏ hàng hiện tại
    final cartState = context.read<CartCubit>().state;
    int existingQty = 0;
    if (cartState.cart != null) {
      final existing = cartState.cart!.items
          .where((i) => i.productVariant.id == variant.id)
          .firstOrNull;
      existingQty = existing?.quantity ?? 0;
    }

    //check stock limit
    final remainingFlash =
        (variant.flashStockLimit ?? 0) - (variant.flashSoldCount ?? 0);
    final maxAvailable = variant.hasActiveFlashSale
        ? remainingFlash
        : variant.stock;

    if (existingQty + quantity > maxAvailable) {
      StockLimitDialog.show(
        context,
        stockCount: maxAvailable,
        currentQty: existingQty,
        message: variant.hasActiveFlashSale
            ? "Vượt giới hạn Flash Sale còn lại."
            : "Vượt giới hạn kho.",
      );
      return;
    }

    setState(() => isAddingToCart = true);
    context.read<CartCubit>().addToCart(variant, product, quantity);
  }
}
