import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/src/core/utils/formatter_utils.dart';
import 'package:mobile/src/shared/models/product_model.dart';
import 'package:mobile/src/shared/models/product_variant_model.dart';
import 'package:mobile/src/features/cart/presentation/state/cart_cubit.dart';
import 'package:mobile/src/features/home/presentation/state/home_cubit.dart';
import 'package:mobile/src/features/product_detail/presentation/pages/product_detail_page.dart';
import 'package:mobile/src/shared/widgets/color_bubble_selector.dart';

const _surface = Color(0xFF14141E);
const _border = Color(0xFF2A2A38);
const _accent = Color(0xFFFDE047);
const _textHigh = Colors.white;
const _textMid = Color(0xFF94A3B8);

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
    return ColorBubbleSelector(
      product: widget.product,
      attributeKey: key,
      selectedValue: _selectedAttributes[key],
      onSelected: (val) {
        setState(() {
          _selectedAttributes[key] = val;
        });
      },
    );
  }

  Widget _buildChipRow(String key, List<String> values) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
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
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? _accent : _surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? _accent : _border,
                width: 1.2,
              ),
            ),
            child: Text(
              val,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                color: isSelected ? Colors.black : _textMid,
                letterSpacing: 0.5,
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
          color: _surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(28),
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
                        color: _accent,
                      ),
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.image_not_supported_outlined,
                      color: _textMid,
                      size: 64,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.product.baseName.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: _textHigh,
                letterSpacing: 0.5,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 16),
            // build cau hinh bien the
            ...options.entries.map((entry) {
              final k = entry.key;
              final vals = entry.value;
              if (k.toLowerCase().contains('color') ||
                  k.toLowerCase().contains('màu')) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: _buildColorBubbles(k, vals),
                );
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildChipRow(k, vals),
              );
            }),
            const SizedBox(height: 8),
            Text(
              formatVND(priceToDisplay),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: _accent,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 24),
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
                    _showLimitDialog(context, variant.stock, existingQty);
                    return;
                  }

                  cartCubit.addToCart(variant, widget.product, 1);
                  HapticFeedback.heavyImpact();
                }
              },
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'THÊM VÀO GIỎ HÀNG',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
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

  void _showLimitDialog(BuildContext context, int stock, int existing) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: _border, width: 0.5),
          ),
          title: const Text(
            'Giới hạn kho',
            style: TextStyle(fontWeight: FontWeight.w800, color: _textHigh),
          ),
          content: Text(
            'Kho hiện còn $stock sản phẩm và bạn đã có $existing trong giỏ hàng.',
            style: const TextStyle(color: _textMid, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Đã hiểu',
                style: TextStyle(color: _accent, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
    );
  }
}
