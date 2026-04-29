import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4;
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/core/utils/formatter_utils.dart';
import 'package:mobile/src/shared/models/product_model.dart';

class ProductHeroSection extends StatefulWidget {
  final ProductModel product;
  final int selectedVariantIndex;
  final int quantity;
  final Function(int) onColorTarget;
  final Function() onIncrement;
  final Function() onDecrement;
  final Function() onLongPressIncrement;
  final Function() onLongPressDecrement;
  final Function() onLongPressEnd;
  final int maxQuantity;

  const ProductHeroSection({
    super.key,
    required this.product,
    required this.selectedVariantIndex,
    required this.quantity,
    required this.onColorTarget,
    required this.onIncrement,
    required this.onDecrement,
    required this.onLongPressIncrement,
    required this.onLongPressDecrement,
    required this.onLongPressEnd,
    this.maxQuantity = 10,
  });

  @override
  State<ProductHeroSection> createState() => _ProductHeroSectionState();
}

class _ProductHeroSectionState extends State<ProductHeroSection> {
  late final PageController _pageController;
  final ValueNotifier<double> _pageOffset = ValueNotifier<double>(0.0);

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: widget.selectedVariantIndex,
      viewportFraction: 0.9,
    );
    _pageOffset.value = widget.selectedVariantIndex.toDouble();

    _pageController.addListener(() {
      if (_pageController.hasClients) {
        _pageOffset.value = _pageController.page ?? 0.0;
      }
    });
  }

  @override
  void didUpdateWidget(ProductHeroSection oldWidget) {
    if (oldWidget.selectedVariantIndex != widget.selectedVariantIndex) {
      // logic for changing image if variants have different images
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pageOffset.dispose();
    super.dispose();
  }

  Color _parseColor(String? colorName) {
    if (colorName == null) return Colors.grey;
    final name = colorName.toLowerCase();
    if (name.contains('gray') || name.contains('xám')) {
      return const Color(0xFF1C1C1E);
    }
    if (name.contains('silver') || name.contains('bạc')) {
      return const Color(0xFFE5E5EA);
    }
    if (name.contains('gold') || name.contains('vàng')) {
      return const Color(0xFFFACC15);
    }
    if (name.contains('black') || name.contains('đen')) return Colors.black;
    if (name.contains('white') || name.contains('trắng')) return Colors.white;
    if (name.contains('blue') || name.contains('xanh')) return Colors.blue;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final currentVariant =
        widget.product.variants.isNotEmpty &&
            widget.selectedVariantIndex < widget.product.variants.length
        ? widget.product.variants[widget.selectedVariantIndex]
        : null;

    final isOutOfStock = (currentVariant?.stock ?? 0) <= 0;

    return Container(
      width: double.infinity,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // brand
                Text(
                  widget.product.brandName?.toUpperCase() ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8E8E93),
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 8),

                // prod name
                Text(
                  widget.product.name.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                    letterSpacing: -0.5,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),

                // availability
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isOutOfStock
                            ? const Color(0xFFFF3B30)
                            : const Color(0xFF34C759),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                                (isOutOfStock
                                        ? const Color(0xFFFF3B30)
                                        : const Color(0xFF34C759))
                                    .withValues(alpha: 0.3),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isOutOfStock
                          ? 'Hết hàng'
                          : 'Còn hàng - ${currentVariant?.stock} có sẵn',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isOutOfStock
                            ? const Color(0xFFFF3B30)
                            : const Color(0xFF34C759),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // price
                Text(
                  formatVND(currentVariant?.price ?? widget.product.price),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                    letterSpacing: -1.0,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // prod img
          SizedBox(
            height: size.height * 0.35,
            child: PageView.builder(
              controller: _pageController,
              itemCount: 1,
              itemBuilder: (context, index) {
                return ValueListenableBuilder<double>(
                  valueListenable: _pageOffset,
                  builder: (context, offset, child) {
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Hero(
                          tag: 'product_${widget.product.id}',
                          child: ColorFiltered(
                            colorFilter: isOutOfStock
                                ? const ColorFilter.matrix([
                                    0.2126,
                                    0.7152,
                                    0.0722,
                                    0,
                                    0,
                                    0.2126,
                                    0.7152,
                                    0.0722,
                                    0,
                                    0,
                                    0.2126,
                                    0.7152,
                                    0.0722,
                                    0,
                                    0,
                                    0,
                                    0,
                                    0,
                                    1,
                                    0,
                                  ])
                                : const ColorFilter.mode(
                                    Colors.transparent,
                                    BlendMode.multiply,
                                  ),
                            child: widget.product.image.startsWith('http')
                                ? CachedNetworkImage(
                                    imageUrl: widget.product.image,
                                    fit: BoxFit.contain,
                                    placeholder: (_, __) => const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    errorWidget: (_, __, ___) => const Icon(
                                      Icons.broken_image_outlined,
                                      size: 40,
                                      color: Colors.grey,
                                    ),
                                  )
                                : Image.asset(
                                    widget.product.image,
                                    fit: BoxFit.contain,
                                  ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // color & qty
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(widget.product.variants.length, (i) {
                    final variant = widget.product.variants[i];
                    final colorName =
                        variant.attributes['color'] ??
                        variant.attributes['Màu sắc'];
                    final dotColor = _parseColor(colorName);
                    final selected = widget.selectedVariantIndex == i;
                    final variantOutOfStock = variant.stock <= 0;

                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        widget.onColorTarget(i);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(right: 12),
                        width: selected ? 28 : 22,
                        height: selected ? 28 : 22,
                        decoration: BoxDecoration(
                          color: dotColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected
                                ? Colors.black
                                : Colors.grey.shade300,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: variantOutOfStock
                            ? Center(
                                child: Container(
                                  width: 1.5,
                                  height: 14,
                                  color: selected ? Colors.black : Colors.grey,
                                  transform: Matrix4.rotationZ(0.7),
                                ),
                              )
                            : null,
                      ),
                    );
                  }),
                ),
                _buildQuantitySelector(),
              ],
            ),
          ),

          const SizedBox(height: 32),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTrustBadge(LucideIcons.shieldCheck, 'Bảo hành 36 tháng'),
                const SizedBox(width: 8),
                _buildTrustBadge(LucideIcons.truck, 'Giao hàng hỏa tốc'),
                const SizedBox(width: 8),
                _buildTrustBadge(LucideIcons.badgeCheck, 'Cam kết chính hãng'),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // minus btn
          _qtyBtn(
            icon: LucideIcons.minus,
            onTap: widget.onDecrement,
            onLongPress: widget.onLongPressDecrement,
            onLongPressUp: widget.onLongPressEnd,
            disabled: widget.quantity <= 1,
          ),

          Container(
            constraints: const BoxConstraints(minWidth: 40),
            alignment: Alignment.center,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                );
              },
              child: Text(
                '${widget.quantity}',
                key: ValueKey<int>(widget.quantity),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  fontFeatures: [FontFeature.tabularFigures()],
                  color: Colors.black,
                ),
              ),
            ),
          ),

          // plus btn
          _qtyBtn(
            icon: LucideIcons.plus,
            onTap: widget.onIncrement,
            onLongPress: widget.onLongPressIncrement,
            onLongPressUp: widget.onLongPressEnd,
            disabled: widget.quantity >= widget.maxQuantity,
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn({
    required IconData icon,
    required VoidCallback onTap,
    required VoidCallback onLongPress,
    required VoidCallback onLongPressUp,
    bool disabled = false,
  }) {
    return GestureDetector(
      onTap: disabled
          ? null
          : () {
              HapticFeedback.lightImpact();
              onTap();
            },
      onLongPress: disabled ? null : onLongPress,
      onLongPressUp: disabled ? null : onLongPressUp,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
        ),
        child: Opacity(
          opacity: disabled ? 0.2 : 1.0,
          child: Icon(icon, size: 18, color: Colors.black),
        ),
      ),
    );
  }

  Widget _buildTrustBadge(IconData icon, String label) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1C1C1E)),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF8E8E93),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
