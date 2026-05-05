import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:mobile/src/core/utils/formatter_utils.dart';
import 'package:mobile/src/shared/models/product_model.dart';
import 'package:mobile/src/shared/models/product_variant_model.dart';
import 'package:mobile/src/features/cart/presentation/state/cart_cubit.dart';
import 'package:mobile/src/features/home/presentation/state/home_cubit.dart';
import 'package:mobile/src/features/product_detail/presentation/pages/product_detail_page.dart';

class LargeProductCard extends StatefulWidget {
  final ProductModel product;

  const LargeProductCard({super.key, required this.product});

  @override
  State<LargeProductCard> createState() => _LargeProductCardState();
}

class _LargeProductCardState extends State<LargeProductCard> {
  Map<String, String> _selectedAttributes = {};

  @override
  void initState() {
    super.initState();
    _initializeAttributes();
  }

  void _initializeAttributes() {
    if (widget.product.variants.isNotEmpty && _selectedAttributes.isEmpty) {
      final activeVariants = widget.product.variants
          .where((v) => v.isActive)
          .toList();
      if (activeVariants.isEmpty) return;

      final firstVariant = activeVariants.first;
      final configKeys = widget.product.attributeConfig;

      if (configKeys.isNotEmpty) {
        for (var key in configKeys) {
          if (firstVariant.attributes.containsKey(key)) {
            _selectedAttributes[key] = firstVariant.attributes[key].toString();
          }
        }
      } else {
        _selectedAttributes = Map<String, String>.from(
          firstVariant.attributes.map((k, v) => MapEntry(k, v.toString())),
        );
      }
    }
  }

  ProductVariantModel? _getCurrentVariant() {
    if (widget.product.variants.isEmpty) return null;

    for (final v in widget.product.variants) {
      if (!v.isActive) continue;

      final allMatch = _selectedAttributes.entries.every(
        (entry) => v.attributes[entry.key]?.toString() == entry.value,
      );
      if (allMatch) return v;
    }

    final activeVariants = widget.product.variants
        .where((v) => v.isActive)
        .toList();
    return activeVariants.isNotEmpty ? activeVariants.first : null;
  }

  Map<String, List<String>> _getAttributeOptions() {
    final Map<String, List<String>> options = {};
    for (final v in widget.product.variants) {
      if (!v.isActive) continue;
      v.attributes.forEach((k, vVal) {
        if (!options.containsKey(k)) options[k] = [];
        final strVal = vVal.toString();
        if (!options[k]!.contains(strVal)) {
          options[k]!.add(strVal);
        }
      });
    }
    return options;
  }

  Widget _buildColorBubbles(String key, List<String> values) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: values.map((val) {
        final isSelected = _selectedAttributes[key] == val;

        final variant = widget.product.variants.firstWhere(
          (v) => v.isActive && v.attributes[key]?.toString() == val,
          orElse: () => widget.product.variants.first,
        );

        final anyInStock = widget.product.variants.any(
          (v) =>
              v.isActive && v.attributes[key]?.toString() == val && v.stock > 0,
        );

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              _selectedAttributes[key] = val;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? Colors.black : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? Colors.black : const Color(0xFFE5E5EA),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F7),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white24 : Colors.black12,
                    ),
                    image:
                        (variant.imageUrl != null ||
                            widget.product.image.isNotEmpty)
                        ? DecorationImage(
                            image: CachedNetworkImageProvider(
                              variant.imageUrl ?? widget.product.image,
                            ),
                            fit: BoxFit.cover,
                            colorFilter: !anyInStock
                                ? const ColorFilter.mode(
                                    Colors.grey,
                                    BlendMode.saturation,
                                  )
                                : null,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  val,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChipRow(String key, List<String> values) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: values.map((val) {
        final isSelected = _selectedAttributes[key] == val;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              _selectedAttributes[key] = val;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.black : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? Colors.black : const Color(0xFFE5E5EA),
                width: 1.5,
              ),
            ),
            child: Text(
              val,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF4B5563),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentVariant = _getCurrentVariant();
    final priceToDisplay = currentVariant != null
        ? currentVariant.price
        : widget.product.basePrice;
    final imageToDisplay =
        currentVariant != null &&
            currentVariant.imageUrl != null &&
            currentVariant.imageUrl!.isNotEmpty
        ? currentVariant.imageUrl!
        : widget.product.image;

    final options = _getAttributeOptions();

    return GestureDetector(
      onTap: () {
        context.read<HomeCubit>().incrementView(widget.product.id);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(
              product: widget.product,
              initialAttributes: _selectedAttributes,
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 226, 227, 230),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Center(
                child: Hero(
                  tag:
                      'product_image_${widget.product.id}_${currentVariant?.id ?? "base"}',
                  child: CachedNetworkImage(
                    imageUrl: imageToDisplay,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black12,
                      ),
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.image_not_supported_outlined,
                      color: Color(0xFF9CA3AF),
                      size: 64,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.product.baseName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0A0A0F),
                letterSpacing: -0.6,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 12),
            // build cau hinh bien the
            ...options.entries.map((entry) {
              final k = entry.key;
              final vals = entry.value;
              if (k.toLowerCase().contains('color') ||
                  k.toLowerCase().contains('màu')) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 22),
                  child: _buildColorBubbles(k, vals),
                );
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildChipRow(k, vals),
              );
            }),
            const SizedBox(height: 12),
            Text(
              formatVND(priceToDisplay),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0A0A0F),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                final variant = _getCurrentVariant();
                if (variant != null) {
                  final cartCubit = context.read<CartCubit>();
                  final cartState = cartCubit.state;
                  int existingQty = 0;
                  if (cartState.cart != null) {
                    final existing = cartState.cart!.items
                        .where((i) => i.productVariant.id == variant.id)
                        .firstOrNull;
                    existingQty = existing?.quantity ?? 0;
                  }

                  if (existingQty + 1 > variant.stock) {
                    showDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (context) {
                        return Dialog(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                            side: const BorderSide(
                              color: Color(0xFFE5E5EA),
                              width: 1,
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
                                    color: Colors.black,
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
                                    color: Color(0xFF5C5C6B),
                                    height: 1.45,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
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
                    return;
                  }

                  cartCubit.addToCart(variant, widget.product, 1);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Đã thêm ${widget.product.baseName} vào giỏ hàng thành công!',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A0F),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const Center(
                  child: Text(
                    'Thêm vào giỏ hàng',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
