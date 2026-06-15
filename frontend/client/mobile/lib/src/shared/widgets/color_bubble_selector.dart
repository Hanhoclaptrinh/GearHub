import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile/src/shared/models/product_model.dart';

class ColorBubbleSelector extends StatelessWidget {
  final ProductModel product;
  final String attributeKey;
  final String? selectedValue;
  final ValueChanged<String>? onSelected;
  final double bubbleSize;
  final double spacing;
  final bool isReadOnly;

  const ColorBubbleSelector({
    super.key,
    required this.product,
    required this.attributeKey,
    this.selectedValue,
    this.onSelected,
    this.bubbleSize = 32,
    this.spacing = 10,
    this.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final values = _getUniqueValues();
    if (values.isEmpty) return const SizedBox.shrink();
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: values.take(isReadOnly ? 5 : 100).map((val) {
        final isSelected = selectedValue == val;

        final variant = product.variants.firstWhere(
          (v) => v.isActive && v.attributes[attributeKey]?.toString() == val,
          orElse: () => product.variants.first,
        );

        final anyInStock = product.variants.any(
          (v) =>
              v.isActive &&
              v.attributes[attributeKey]?.toString() == val &&
              v.stock > 0,
        );

        return GestureDetector(
          onTap: isReadOnly
              ? null
              : () {
                  if (onSelected != null) {
                    HapticFeedback.selectionClick();
                    onSelected!(val);
                  }
                },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? primaryColor
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Container(
              width: bubbleSize,
              height: bubbleSize,
              decoration: BoxDecoration(
                color: const Color(0xFF14141E),
                shape: BoxShape.circle,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.15),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ]
                    : [],
                image: (variant.imageUrl != null || product.image.isNotEmpty)
                    ? DecorationImage(
                        image: CachedNetworkImageProvider(
                          variant.imageUrl ?? product.image,
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
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 0.5,
                ),
              ),
              child: !anyInStock
                  ? Center(
                      child: Container(
                        width: bubbleSize,
                        height: 1.5,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    )
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }

  List<String> _getUniqueValues() {
    return product.variants
        .where((v) => v.isActive)
        .map((v) => v.attributes[attributeKey]?.toString())
        .whereType<String>()
        .toSet()
        .toList();
  }
}
