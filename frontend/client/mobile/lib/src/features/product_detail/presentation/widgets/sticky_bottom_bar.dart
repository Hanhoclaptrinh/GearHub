import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:mobile/src/shared/models/product_model.dart';
import 'package:mobile/src/shared/models/product_variant_model.dart';
import 'package:mobile/src/features/onboarding/presentation/widgets/three_animated_arrow.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/src/features/cart/domain/entities/cart_item_entity.dart';
import 'package:mobile/src/features/checkout/presentation/pages/checkout_page.dart';
import 'package:mobile/src/features/cart/presentation/state/cart_cubit.dart';
import 'package:mobile/src/features/cart/presentation/state/cart_state.dart';

const _kSurface = Color(0xFF0C0C18);
const _kBorder = Color(0xFF1A1A28);
const _kGold = Color(0xFFD4A843);
const _kGoldDim = Color(0xFF1A1200);

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
          // When add is successful, show successful state for a short moment then pull thumb back
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
                color: _kSurface.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(36),
                border: Border.all(color: _kBorder, width: 0.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x40000000),
                    blurRadius: 28,
                    offset: Offset(0, 10),
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
  Widget _buildOrderBtn() => GestureDetector(
    onTap: () {
      HapticFeedback.lightImpact();
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
        border: Border.all(color: _kGold.withValues(alpha: 0.30), width: 0.5),
      ),
      child: const Center(
        child: Text(
          'MUA NGAY',
          style: TextStyle(
            color: _kGold,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
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
          color: _kGoldDim.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: _isAdded
                ? const Color(0xFF2A6A40)
                : _kGold.withValues(alpha: 0.22),
            width: 0.5,
          ),
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
                gradient: LinearGradient(
                  colors: _isAdded
                      ? [const Color(0xFF1A4A30), const Color(0xFF1F5A38)]
                      : [_kGoldDim, const Color(0xFF261A00)],
                ),
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
                        style: TextStyle(
                          color: _isAdded
                              ? const Color(0xFF5DBA88)
                              : _kGold.withValues(alpha: 0.70),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                      if (!_isAdded) ...[
                        const SizedBox(width: 8),
                        ThreeAnimatedArrows(
                          color: _kGold.withValues(alpha: 0.40),
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
                        showDialog(
                          context: context,
                          barrierDismissible: true,
                          builder: (context) {
                            return Dialog(
                              backgroundColor: const Color(0xFF0C0C18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                                side: const BorderSide(
                                  color: Color(0xFF1A1A28),
                                  width: 0.5,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFFFF3B30,
                                        ).withValues(alpha: 0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Lottie.asset(
                                        'assets/animations/warning.json',
                                        repeat: false,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    const Text(
                                      'Vượt quá giới hạn',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Số lượng sản phẩm trong kho không đủ để thêm vào giỏ hàng.\n\nKho hiện còn ${variant.stock} sản phẩm và bạn đã có $existingQty sản phẩm trong giỏ.',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w400,
                                        color: Color(0xFF8A8A9E),
                                        height: 1.45,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _kGold,
                                          foregroundColor: Colors.black,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                        ),
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text(
                                          'ĐÃ HIỂU',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
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
                      color: _kGoldDim,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _kGold.withValues(alpha: 0.45),
                        width: 0.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _kGold.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: _kGold,
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
