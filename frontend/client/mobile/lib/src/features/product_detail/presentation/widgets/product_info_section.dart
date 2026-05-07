import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile/src/shared/models/product_model.dart';
import 'package:mobile/src/shared/models/product_variant_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/src/features/cart/presentation/state/cart_cubit.dart';

const _bg         = Color(0xFF0A0A10);
const _surface    = Color(0xFF14141E);
const _surfaceAlt = Color(0xFF1C1C28);
const _border     = Color(0xFF2A2A38);
const _accent     = Color(0xFF6366F1);
const _textHigh   = Color(0xFFF1F1F5);
const _textMid    = Color(0xFF9191A8);
const _textLow    = Color(0xFF4A4A62);

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
      backgroundColor: _surface,
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
                  fontWeight: FontWeight.w900,
                  color: _textHigh,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
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
                                    color: _textMid,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  e.value,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: _textHigh,
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
      color: _bg,
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
                  fontWeight: FontWeight.w900,
                  color: _textHigh,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 54,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
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
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: isSelected ? _accent : _surfaceAlt,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? _accent : _border,
                          width: 1.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: _accent.withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ]
                            : [],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: _surface,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.white30 : _border,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                              image: (variant.imageUrl != null ||
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
                            child: !anyInStock
                                ? Center(
                                    child: Container(
                                      width: 2,
                                      height: 24,
                                      transform: Matrix4.rotationZ(0.785),
                                      color: isSelected ? Colors.white70 : _textLow,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            colorValue.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                              color: isSelected ? Colors.white : _textMid,
                              letterSpacing: 0.5,
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
                        fontWeight: FontWeight.w900,
                        color: _textHigh,
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
                    fontWeight: FontWeight.w900,
                    color: _textHigh,
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
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFEF4444),
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
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: _border, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          color: _accent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'MÔ TẢ SẢN PHẨM',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: _textHigh,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AnimatedCrossFade(
                    firstChild: Text(
                      widget.product.description,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: _textMid.withValues(alpha: 0.8),
                        height: 1.6,
                      ),
                    ),
                    secondChild: Text(
                      widget.product.description,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: _textMid.withValues(alpha: 0.8),
                        height: 1.6,
                      ),
                    ),
                    crossFadeState: _isDescriptionExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 300),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isDescriptionExpanded = !_isDescriptionExpanded;
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _surfaceAlt,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            (_isDescriptionExpanded
                                ? 'THU GỌN'
                                : 'XEM THÊM CHI TIẾT').toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: _textHigh,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            _isDescriptionExpanded
                                ? LucideIcons.chevronUp
                                : LucideIcons.chevronDown,
                            size: 14,
                            color: _textHigh,
                          ),
                        ],
                      ),
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
                  fontWeight: FontWeight.w900,
                  color: _textHigh,
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
                    color: _surfaceAlt,
                    border: Border.all(color: _border),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Xem thêm thuộc tính',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _textHigh,
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
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.only(right: 14),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? _accent : _surfaceAlt,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? _accent
                          : isDisabled
                          ? _border.withValues(alpha: 0.5)
                          : _border,
                      width: 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: _accent.withValues(alpha: 0.4),
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
                        val.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w900
                              : FontWeight.w800,
                          color: isSelected
                              ? Colors.white
                              : _textHigh,
                          letterSpacing: 0.5,
                          decoration: isOutOfStock
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      if (isOutOfStock) ...[
                        const SizedBox(height: 6),
                        Text(
                          'HẾT HÀNG',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: isSelected
                                ? Colors.white70
                                : const Color(0xFFEF4444),
                            letterSpacing: 0.5,
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
                        fontWeight: FontWeight.w500,
                        color: _textMid,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      entry.value,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _textHigh,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
            if (!isLast) Container(height: 1, color: _border),
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
        color: _surfaceAlt,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
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
                  fontWeight: FontWeight.w900,
                  fontFeatures: [FontFeature.tabularFigures()],
                  color: _textHigh,
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
          child: Icon(icon, size: 18, color: _textHigh),
        ),
      ),
    );
  }
}
