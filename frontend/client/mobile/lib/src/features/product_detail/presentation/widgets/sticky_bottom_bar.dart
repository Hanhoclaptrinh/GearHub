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

const _surface = Color(0xFF14141E);
const _surfaceAlt = Color(0xFF1C1C28);
const _border = Color(0xFF2A2A38);
const _accent = Color(0xFF6366F1);
const _textHigh = Color(0xFFF1F1F5);
const _textMid = Color(0xFF9191A8);
const _textLow = Color(0xFF4A4A62);

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
                color: _surface.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(36),
                border: Border.all(color: _border, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
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
          padding: const EdgeInsets.fromLTRB(32, 12, 32, 32),
          decoration: const BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(40),
              topRight: Radius.circular(40),
            ),
            border: Border(top: BorderSide(color: _border, width: 1.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: _border,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 48),
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _accent.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: const Icon(LucideIcons.lock, color: _accent, size: 32),
              ),
              const SizedBox(height: 32),
              const Text(
                'YÊU CẦU ĐĂNG NHẬP',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: _accent,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'TIẾP TỤC TRẢI NGHIỆM',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: _textHigh,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Vui lòng đăng nhập để tiếp tục thanh toán, lưu giỏ hàng và nhận các ưu đãi thành viên đặc biệt của GearHub.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _textMid,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
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
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: _textLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: _border),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'ĐỂ SAU',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
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

      final variant =
          widget.selectedVariant ??
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
        color: _surfaceAlt,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _border, width: 1),
      ),
      child: const Center(
        child: Text(
          'MUA NGAY',
          style: TextStyle(
            color: _textHigh,
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
          color: _accent,
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
                color: _isAdded ? const Color(0xFF10B981) : _accent,
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
                        const ThreeAnimatedArrows(color: Colors.white60),
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
                      color: _surface,
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
                      color: _textHigh,
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
