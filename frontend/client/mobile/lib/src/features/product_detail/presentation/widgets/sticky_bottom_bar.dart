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
    final size = MediaQuery.of(context).size;
    final variant =
        widget.selectedVariant ??
        (widget.product.variants.where((v) => v.isActive).firstOrNull ??
            widget.product.variants.first);

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
            color: const Color(0xFF07070A).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
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
                      onTap: () => _handleAddToCart(variant),
                      isLoading: _isAdding,
                    ),
                    const SizedBox(width: 8),

                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Thành tiền",
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            formatVND(variant.price * widget.quantity),
                            style: const TextStyle(
                              color: Colors.white,
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
                      onTap: () => _handleBuyNow(variant),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.1),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF07070A),
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

    // lay trang thai cart
    final cartState = context.read<CartCubit>().state;
    int existingQty = 0; // gia tri khoi tao
    // lay ra san pham dau tien trung id voi sp them vao
    if (cartState.cart != null) {
      final existing = cartState.cart!.items
          .where((i) => i.productVariant.id == variant.id)
          .firstOrNull;
      existingQty = existing?.quantity ?? 0;
    }

    // vuot limit stock
    if (existingQty + widget.quantity > variant.stock) {
      StockLimitDialog.show(
        context,
        stockCount: variant.stock,
        currentQty: existingQty,
        message: "Vượt giới hạn kho.",
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

    // dem toan bo thong tin va so luong cua san pham qua trang thanh toan
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(LucideIcons.circleCheck, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Text("Đã thêm sản phẩm vào giỏ hàng"),
          ],
        ),
        backgroundColor: Colors.black,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 100),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
