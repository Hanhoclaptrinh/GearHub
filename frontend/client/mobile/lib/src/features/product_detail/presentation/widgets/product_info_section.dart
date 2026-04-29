import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/src/shared/models/product_model.dart';
import 'package:mobile/src/shared/models/product_variant_model.dart';

class ProductInfoSection extends StatefulWidget {
  final ProductModel product;
  final Map<String, String> selectedAttributes;
  final Function(String, String) onAttributeChanged;
  final bool Function(String, String) isComboAvailable;
  final bool Function(String, String) isValueInStock;

  const ProductInfoSection({
    super.key,
    required this.product,
    required this.selectedAttributes,
    required this.onAttributeChanged,
    required this.isComboAvailable,
    required this.isValueInStock,
  });

  @override
  State<ProductInfoSection> createState() => _ProductInfoSectionState();
}

class _ProductInfoSectionState extends State<ProductInfoSection> {
  bool _isDescriptionExpanded = false;

  // color
  String _getColorKey() {
    if (widget.product.attributeConfig.isNotEmpty) {
      return widget.product.attributeConfig.firstWhere(
        (k) {
          final lower = k.toLowerCase();
          return lower.contains('color') ||
              lower.contains('màu') ||
              lower.contains('mau');
        },
        orElse: () => '',
      );
    }
    return '';
  }

  List<String> _getDisplayConfigKeys() {
    final colorKey = _getColorKey();
    return widget.product.attributeConfig
        .where((key) => key != colorKey)
        .toList();
  }

  List<String> _getUniqueValues(String key) {
    return widget.product.variants
        .where((v) => v.isActive)
        .map((v) => v.attributes[key]?.toString())
        .whereType<String>()
        .toSet()
        .toList();
  }

  ProductVariantModel? get _currentVariant {
    if (widget.product.variants.isEmpty) return null;
    for (final v in widget.product.variants) {
      final allMatch = widget.selectedAttributes.entries.every((entry) =>
          v.attributes[entry.key]?.toString() == entry.value);
      if (allMatch) return v;
    }
    return widget.product.variants.first;
  }

  Map<String, String> get _specs {
    final Map<String, String> display = {};
    final configKeys = widget.product.attributeConfig.toSet();

    final variant = _currentVariant;
    if (variant != null) {
      variant.attributes.forEach((key, value) {
        if (!configKeys.contains(key)) {
          final formattedKey = key[0].toUpperCase() + key.substring(1);
          display[formattedKey] = value.toString();
        }
      });
    }

    return display;
  }

  Map<String, String> get _fullSpecs {
    final Map<String, String> display = {};
    final variant = _currentVariant;
    if (variant != null) {
      variant.attributes.forEach((key, value) {
        final formattedKey = key[0].toUpperCase() + key.substring(1);
        display[formattedKey] = value.toString();
      });
    }
    return display.isEmpty ? _specs : display;
  }

  void _showFullSpecs() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thuộc tính sản phẩm',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  children: _fullSpecs.entries
                      .map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  e.key,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF8E8E93),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  e.value,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayKeys = _getDisplayConfigKeys();

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (displayKeys.isNotEmpty) ...[
            ...displayKeys.map((key) {
              final uniqueValues = _getUniqueValues(key);
              if (uniqueValues.isEmpty) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    key,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildConfigSelector(
                    key,
                    uniqueValues,
                    widget.selectedAttributes[key],
                  ),
                  const SizedBox(height: 36),
                ],
              );
            }),
          ],

          const Text(
            'Mô tả sản phẩm',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.black,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              setState(() {
                _isDescriptionExpanded = !_isDescriptionExpanded;
              });
            },
            child: AnimatedCrossFade(
              firstChild: Text(
                widget.product.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF3C3C43),
                  height: 1.5,
                ),
              ),
              secondChild: Text(
                widget.product.description,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF3C3C43),
                  height: 1.5,
                ),
              ),
              crossFadeState: _isDescriptionExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              setState(() {
                _isDescriptionExpanded = !_isDescriptionExpanded;
              });
            },
            child: Text(
              _isDescriptionExpanded ? 'Ẩn bớt' : 'Xem thêm',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.black,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const SizedBox(height: 36),

          if (_specs.isNotEmpty) ...[
            const Text(
              'Thuộc tính',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.black,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            _buildSpecsList(),
            const SizedBox(height: 20),
            Center(
              child: GestureDetector(
                onTap: _showFullSpecs,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE5E5EA)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Xem thêm thuộc tính',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConfigSelector(
    String key,
    List<String> values,
    String? selectedValue,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.none,
      child: Row(
        children: values.map((val) {
          final isSelected = selectedValue == val;

          final comboExists = widget.isComboAvailable(key, val);
          final hasStock = widget.isValueInStock(key, val);

          final isDisabled = !comboExists;
          final isOutOfStock = comboExists && !hasStock;

          return GestureDetector(
            onTap: isDisabled
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    widget.onAttributeChanged(key, val);
                  },
            child: Opacity(
              opacity: isDisabled ? 0.35 : (isOutOfStock ? 0.55 : 1.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.only(right: 14),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.black : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? Colors.black
                        : isDisabled
                            ? const Color(0xFFD1D1D6)
                            : const Color(0xFFE5E5EA),
                    width: 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ]
                      : [],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      val,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF3C3C43),
                        letterSpacing: -0.2,
                        decoration: isOutOfStock
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    if (isOutOfStock) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Hết hàng',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white60
                              : const Color(0xFFFF3B30),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSpecsList() {
    return Column(
      children: _specs.entries.map((entry) {
        final isLast = entry.key == _specs.entries.last.key;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      entry.value,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
            if (!isLast) Container(height: 0.5, color: const Color(0xFFE5E5EA)),
          ],
        );
      }).toList(),
    );
  }
}
