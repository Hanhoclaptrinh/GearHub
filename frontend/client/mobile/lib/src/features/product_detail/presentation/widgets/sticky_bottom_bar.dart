import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/src/shared/models/product_model.dart';
import 'package:mobile/src/shared/models/product_variant_model.dart';
import 'package:mobile/src/features/onboarding/presentation/widgets/three_animated_arrow.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/src/features/cart/domain/entities/cart_item_entity.dart';
import 'package:mobile/src/features/checkout/presentation/pages/checkout_page.dart';
import 'package:mobile/src/features/cart/presentation/state/cart_cubit.dart';
import 'package:mobile/src/features/cart/presentation/state/cart_state.dart';
import 'package:mobile/src/features/auth/presentation/pages/login_page.dart';
import 'package:mobile/src/features/auth/presentation/state/auth_cubit.dart';
import 'package:mobile/src/features/auth/presentation/state/auth_state.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/shared/widgets/stock_limit_dialog.dart';

const _kSurface = Color(0xFFFFFFFF);
const _kBorder = Color(0xFFE5E5EA);
const _kGold = Color(0xFF0A0A0F);
const _kGoldDim = Color(0xFFF2F2F7);

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
  bool _isAdded = false;
  double _dragPosition = 0.0;
  double _sliderWidth = 0.0;
  final double _thumbSz = 52.0;

  @override
  Widget build(BuildContext context) {
    return BlocListener<CartCubit, CartState>(
      listener: (context, state) {
        if (state is CartAddSuccess) {
          setState(() {
            _isAdded = true;
          });
          Future.delayed(const Duration(milliseconds: 1200), () {
            if (mounted) {
              setState(() {
                _isAdded = false;
                _dragPosition = 0;
              });
            }
          });
        }
      },
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        offset: widget.isVisible ? Offset.zero : const Offset(0, 1.5),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
            child: Container(
              decoration: BoxDecoration(
                color: _kSurface.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(36),
                border: Border.all(color: _kBorder, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(36),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        _buildOrderBtn(),
                        const SizedBox(width: 8),
                        Expanded(child: _buildSlider()),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // order btn
  void _showAuthRequiredBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
            border: Border(
              top: BorderSide(color: Color(0xFFE5E5EA), width: 1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 32),
              Container(
                height: 64,
                width: 64,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.lock,
                  color: Colors.black,
                  size: 28,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'YÊU CẦU ĐĂNG NHẬP',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Vui lòng đăng nhập để tiếp tục thanh toán, lưu giỏ hàng và nhận các ưu đãi thành viên đặc biệt của GearHub.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF5C5C6B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                  },
                  child: const Text(
                    'ĐĂNG NHẬP NGAY',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF8E8E93),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'ĐỂ SAU',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrderBtn() => GestureDetector(
    onTap: () {
      HapticFeedback.lightImpact();
      final authState = context.read<AuthCubit>().state;
      if (authState is! AuthAuthenticated) {
        _showAuthRequiredBottomSheet(context);
        return;
      }

      final variant = widget.selectedVariant ??
          (widget.product.variants.where((v) => v.isActive).firstOrNull ??
              widget.product.variants.first);
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
    },
    child: Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        color: _kGoldDim,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE5E5EA), width: 1),
      ),
      child: const Center(
        child: Text(
          'MUA NGAY',
          style: TextStyle(
            color: Colors.black,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
      ),
    ),
  );

  // slide to add
  Widget _buildSlider() => LayoutBuilder(
    builder: (context, box) {
      _sliderWidth = box.maxWidth;
      final maxDrag = _sliderWidth - _thumbSz - 8;

      return Container(
        height: 60,
        decoration: BoxDecoration(
          color: _kGold,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            AnimatedContainer(
              duration: _dragPosition == 0
                  ? const Duration(milliseconds: 350)
                  : Duration.zero,
              curve: Curves.easeOutCubic,
              width: _isAdded ? _sliderWidth : _dragPosition + _thumbSz + 8,
              height: 60,
              decoration: BoxDecoration(
                color: _isAdded ? const Color(0xFF2EA44F) : _kGold,
                borderRadius: BorderRadius.circular(28),
              ),
            ),

            Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Padding(
                  key: ValueKey(_isAdded),
                  padding: EdgeInsets.only(left: _isAdded ? 0 : 48),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isAdded ? 'ĐÃ THÊM VÀO GIỎ' : 'THÊM VÀO GIỎ',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                      if (!_isAdded) ...[
                        const SizedBox(width: 8),
                        const ThreeAnimatedArrows(
                          color: Colors.white60,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            // thumb
            if (!_isAdded)
              AnimatedPositioned(
                duration: _dragPosition == 0
                    ? const Duration(milliseconds: 380)
                    : Duration.zero,
                curve: Curves.easeOutCubic,
                left: 4 + _dragPosition,
                child: GestureDetector(
                  onHorizontalDragUpdate: (d) => setState(() {
                    _dragPosition = (_dragPosition + d.delta.dx).clamp(
                      0,
                      maxDrag,
                    );
                  }),
                  onHorizontalDragEnd: (d) {
                    if (_dragPosition > maxDrag * 0.75) {
                      HapticFeedback.heavyImpact();
                      final variant =
                          widget.selectedVariant ??
                          (widget.product.variants
                                  .where((v) => v.isActive)
                                  .firstOrNull ??
                              widget.product.variants.first);

                      final cartState = context.read<CartCubit>().state;
                      int existingQty = 0;
                      if (cartState.cart != null) {
                        final existing = cartState.cart!.items
                            .where((i) => i.productVariant.id == variant.id)
                            .firstOrNull;
                        existingQty = existing?.quantity ?? 0;
                      }

                      if (existingQty + widget.quantity > variant.stock) {
                        StockLimitDialog.show(
                          context,
                          stockCount: variant.stock,
                          currentQty: existingQty,
                          message:
                              'Số lượng sản phẩm trong kho không đủ để thêm vào giỏ hàng.\n\nKho hiện còn ${variant.stock} sản phẩm và bạn đã có $existingQty sản phẩm trong giỏ.',
                        );
                        setState(() => _dragPosition = 0);
                        return;
                      }

                      setState(() {
                        _dragPosition = maxDrag;
                      });
                      context.read<CartCubit>().addToCart(
                        variant,
                        widget.product,
                        widget.quantity,
                      );
                    } else {
                      HapticFeedback.lightImpact();
                      setState(() => _dragPosition = 0);
                    }
                  },
                  child: Container(
                    width: _thumbSz,
                    height: _thumbSz,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.black,
                      size: 18,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}
