import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/src/shared/models/product_model.dart';
import 'package:mobile/src/shared/models/product_variant_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/src/features/cart/domain/entities/cart_item_entity.dart';
import 'package:mobile/src/features/checkout/presentation/pages/checkout_page.dart';
import 'package:mobile/src/features/cart/presentation/state/cart_cubit.dart';
import 'package:mobile/src/features/cart/presentation/state/cart_state.dart';
import 'package:mobile/src/features/auth/presentation/state/auth_cubit.dart';
import 'package:mobile/src/features/auth/presentation/state/auth_state.dart';
import 'package:mobile/src/shared/widgets/auth_required_modal.dart';
import 'package:mobile/src/shared/widgets/stock_limit_dialog.dart';
import 'package:mobile/src/core/utils/formatter_utils.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class StickyBottomBar extends StatefulWidget {
  final ProductModel product;
  final ProductVariantModel? selectedVariant;
  final int quantity;
  final bool isVisible;

  const StickyBottomBar({
    super.key,
    required this.product,
    this.selectedVariant,
    this.quantity = 1,
    this.isVisible = true,
  });

  @override
  State<StickyBottomBar> createState() => _StickyBottomBarState();
}

class _StickyBottomBarState extends State<StickyBottomBar> {
  bool _isAdding = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final size = MediaQuery.of(context).size;
    final variant =
        widget.selectedVariant ??
        widget.product.variants.where((v) => v.isActive).firstOrNull ??
        widget.product.variants.firstOrNull;

    return BlocListener<CartCubit, CartState>(
      listener: (context, state) {
        if (state is CartAddSuccess && _isAdding) {
          setState(() => _isAdding = false);
          _showSuccessFeedback();
        }
        if (state is CartError && _isAdding) {
          setState(() => _isAdding = false);
        }
      },
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 800),
        curve: Curves.fastLinearToSlowEaseIn,
        offset: widget.isVisible ? Offset.zero : const Offset(0, 2.0),
        child: Container(
          width: size.width - 48,
          height: 72,
          decoration: BoxDecoration(
            color: theme.cardColor.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: cs.outlineVariant, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    _buildIconButton(
                      icon: _isAdding
                          ? LucideIcons.loader
                          : LucideIcons.shoppingBag,
                      onTap: variant != null
                          ? () => _handleAddToCart(variant)
                          : () {},
                      isLoading: _isAdding,
                    ),
                    const SizedBox(width: 8),

                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Thành tiền",
                            style: TextStyle(
                              color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            formatVND(
                              ((variant != null && variant.hasActiveFlashSale)
                                      ? variant.flashPrice!
                                      : (variant?.price ?? widget.product.price)) *
                                  widget.quantity,
                            ),
                            style: TextStyle(
                              color: cs.onSurface,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    _buildPrimaryButton(
                      label: "MUA NGAY",
                      onTap: variant != null
                          ? () => _handleBuyNow(variant)
                          : () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: cs.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: cs.onSurface,
                  ),
                )
              : Icon(icon, color: cs.onSurface, size: 20),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 28),
        decoration: BoxDecoration(
          color: cs.onSurface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: cs.onSurface.withValues(alpha: 0.1),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: theme.cardColor,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  void _handleAddToCart(ProductVariantModel variant) {
    HapticFeedback.mediumImpact();
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      AuthRequiredModal.show(context);
      return;
    }

    //lấy trạng thái giỏ hàng
    final cartState = context.read<CartCubit>().state;
    int existingQty = 0; //giá trị khởi tạo
    //lấy ra sp đầu tiên có chung id với sản phẩm thêm vào
    if (cartState.cart != null) {
      final existing = cartState.cart!.items
          .where((i) => i.productVariant.id == variant.id)
          .firstOrNull;
      existingQty = existing?.quantity ?? 0;
    }

    //cảnh báo nếu vượt limit stock
    final remainingFlash = (variant.flashStockLimit ?? 0) - (variant.flashSoldCount ?? 0);
    final maxAvailable = variant.hasActiveFlashSale ? remainingFlash : variant.stock;

    if (existingQty + widget.quantity > maxAvailable) {
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

    setState(() => _isAdding = true);
    context.read<CartCubit>().addToCart(
      variant,
      widget.product,
      widget.quantity,
    );
  }

  void _handleBuyNow(ProductVariantModel variant) {
    HapticFeedback.heavyImpact();
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      AuthRequiredModal.show(context);
      return;
    }

    //mang toàn bộ số lượng và thông tin sản phẩm qua trang thanh toán
    final item = CartItemEntity(
      id: "buy_now_${DateTime.now().millisecondsSinceEpoch}",
      cartId: "buy_now",
      productVariant: variant,
      product: widget.product,
      quantity: widget.quantity,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutPage(
          args: CheckoutArguments(items: [item], isFromCart: false),
        ),
      ),
    );
  }

  void _showSuccessFeedback() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(LucideIcons.circleCheck, color: cs.onPrimary, size: 20),
            const SizedBox(width: 12),
            Text(
              "Đã thêm sản phẩm vào giỏ hàng",
              style: TextStyle(color: cs.onPrimary),
            ),
          ],
        ),
        backgroundColor: cs.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 100),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
