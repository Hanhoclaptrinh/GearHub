import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile/src/shared/models/product_model.dart';
import 'package:mobile/src/shared/models/product_variant_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/src/features/cart/presentation/state/cart_cubit.dart';

class ProductInfoSection extends StatefulWidget {
  final ProductModel product;
  final Map<String, String> selectedAttributes;
  final int quantity;
  final int maxQuantity;
  final Function(String, String) onAttributeChanged;
  final bool Function(String, String) isComboAvailable;
  final bool Function(String, String) isValueInStock;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onLongPressIncrement;
  final VoidCallback onLongPressDecrement;
  final VoidCallback onLongPressEnd;

  const ProductInfoSection({
    super.key,
    required this.product,
    required this.selectedAttributes,
    required this.quantity,
    required this.maxQuantity,
    required this.onAttributeChanged,
    required this.isComboAvailable,
    required this.isValueInStock,
    required this.onIncrement,
    required this.onDecrement,
    required this.onLongPressIncrement,
    required this.onLongPressDecrement,
    required this.onLongPressEnd,
  });

  @override
  State<ProductInfoSection> createState() => _ProductInfoSectionState();
}

class _ProductInfoSectionState extends State<ProductInfoSection> {
  bool _isDescriptionExpanded = false;

  // color
  String _getColorKey() {
    if (widget.product.attributeConfig.isNotEmpty) {
      return widget.product.attributeConfig.firstWhere((k) {
        final lower = k.toLowerCase();
        return lower.contains('color') ||
            lower.contains('màu') ||
            lower.contains('mau');
      }, orElse: () => '');
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
      final allMatch = widget.selectedAttributes.entries.every(
        (entry) => v.attributes[entry.key]?.toString() == entry.value,
      );
      if (allMatch) return v;
    }
    return widget.product.variants.first;
  }

  Map<String, String> get _specs {
    final Map<String, String> display = {};
    if (widget.product.commonSpecs != null &&
        widget.product.commonSpecs!.isNotEmpty) {
      int count = 0;
      widget.product.commonSpecs!.forEach((key, value) {
        if (count < 7) {
          display[key] = value.toString();
          count++;
        }
      });
    }

    if (display.isEmpty) {
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
    }
    return display;
  }

  Map<String, String> get _fullSpecs {
    final Map<String, String> display = {};
    if (widget.product.commonSpecs != null) {
      widget.product.commonSpecs!.forEach((key, value) {
        display[key] = value.toString();
      });
    }

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
                  fontSize: 22,
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
    final colorKey = _getColorKey();
    final uniqueColors = colorKey.isNotEmpty ? _getUniqueValues(colorKey) : [];
    final displayKeys = _getDisplayConfigKeys();

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- color selection (mini thumbnails) ---
          if (colorKey.isNotEmpty && uniqueColors.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'Màu sắc',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 54,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                clipBehavior: Clip.none,
                itemCount: uniqueColors.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final colorValue = uniqueColors[index];
                  final isSelected =
                      widget.selectedAttributes[colorKey] == colorValue;

                  final variant = widget.product.variants.firstWhere(
                    (v) =>
                        v.isActive &&
                        v.attributes[colorKey]?.toString() == colorValue,
                    orElse: () => widget.product.variants.first,
                  );

                  final anyInStock = widget.product.variants.any(
                    (v) =>
                        v.isActive &&
                        v.attributes[colorKey]?.toString() == colorValue &&
                        v.stock > 0,
                  );

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      widget.onAttributeChanged(colorKey, colorValue);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.black : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? Colors.black
                              : const Color(0xFFE5E5EA),
                          width: 1.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2F2F7),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.white24
                                    : Colors.black.withValues(alpha: 0.05),
                              ),
                              image:
                                  (variant.imageUrl != null ||
                                      widget.product.image.isNotEmpty)
                                  ? DecorationImage(
                                      image: CachedNetworkImageProvider(
                                        variant.imageUrl ??
                                            widget.product.image,
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
                            child: !anyInStock
                                ? Center(
                                    child: Container(
                                      width: 1.5,
                                      height: 20,
                                      transform: Matrix4.rotationZ(0.785),
                                      color: isSelected
                                          ? Colors.white70
                                          : Colors.black38,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            colorValue,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 36),
          ],

          if (displayKeys.isNotEmpty) ...[
            ...displayKeys.map((key) {
              final uniqueValues = _getUniqueValues(key);
              if (uniqueValues.isEmpty) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      key,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                        letterSpacing: -0.5,
                      ),
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

          // --- quantity selector ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Số lượng',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                    letterSpacing: -0.5,
                  ),
                ),
                _buildQuantitySelector(),
              ],
            ),
          ),
          () {
            final cartState = context.watch<CartCubit>().state;
            int existingQty = 0;
            if (cartState.cart != null && _currentVariant != null) {
              final existing = cartState.cart!.items
                  .where((i) => i.productVariant.id == _currentVariant!.id)
                  .firstOrNull;
              existingQty = existing?.quantity ?? 0;
            }
            if (existingQty + widget.quantity >= widget.maxQuantity) {
              return Padding(
                padding: const EdgeInsets.only(top: 8, left: 24, right: 24),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Số lượng tối đa bạn có thể mua là ${widget.maxQuantity} sản phẩm\n(Bạn đã có $existingQty trong giỏ)',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFFF3B30),
                      height: 1.3,
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }(),
          const SizedBox(height: 36),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E5EA), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'Mô tả sản phẩm',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AnimatedCrossFade(
                    firstChild: Text(
                      widget.product.description,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF5C5C6B),
                        height: 1.5,
                      ),
                    ),
                    secondChild: Text(
                      widget.product.description,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF5C5C6B),
                        height: 1.5,
                      ),
                    ),
                    crossFadeState: _isDescriptionExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 300),
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isDescriptionExpanded = !_isDescriptionExpanded;
                      });
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isDescriptionExpanded
                              ? 'Thu gọn'
                              : 'Xem thêm chi tiết',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF007AFF),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _isDescriptionExpanded
                              ? LucideIcons.chevronUp
                              : LucideIcons.chevronDown,
                          size: 14,
                          color: const Color(0xFF007AFF),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 36),

          if (_specs.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'Thuộc tính chung',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: _buildSpecsList(),
            ),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
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
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
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

  // qty selector
  Widget _buildQuantitySelector() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
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
      onLongPressUp: onLongPressUp,
      onLongPressCancel: onLongPressUp,
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
}
