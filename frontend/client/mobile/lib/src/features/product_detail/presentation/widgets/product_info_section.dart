import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile/src/core/theme/app_colors.dart';
import 'package:mobile/src/shared/models/product_model.dart';

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
  bool _isSpecsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final colorKey = _getColorKey();
    final List<String> uniqueColors = colorKey.isNotEmpty
        ? _getUniqueValues(colorKey).cast<String>().toList()
        : <String>[];
    final otherConfigKeys = widget.product.attributeConfig
        .where((k) => k != colorKey)
        .toList();

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.only(top: 40, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (colorKey.isNotEmpty) ...[
            _buildSectionHeader("Màu sắc"),
            const SizedBox(height: 16),
            _buildColorSelector(colorKey, uniqueColors),
            const SizedBox(height: 40),
          ],

          if (otherConfigKeys.isNotEmpty) ...[
            ...otherConfigKeys.map((key) {
              final values = _getUniqueValues(key);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(key),
                  const SizedBox(height: 16),
                  _buildPillSelector(key, values),
                  const SizedBox(height: 40),
                ],
              );
            }),
          ],

          // qty config
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Số lượng",
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                _buildQuantityControl(),
              ],
            ),
          ),
          const SizedBox(height: 48),
          // specs config
          if (widget.product.commonSpecs != null &&
              widget.product.commonSpecs!.isNotEmpty) ...[
            _buildSectionHeader("THÔNG SỐ KỸ THUẬT"),
            const SizedBox(height: 24),
            _buildSpecsTable(widget.product.commonSpecs!),
            const SizedBox(height: 48),
          ],
          // desc config
          _buildSectionHeader("MÔ TẢ SẢN PHẨM"),
          const SizedBox(height: 16),
          _buildEditorialDescription(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildColorSelector(String key, List<String> values) {
    final selectedVal = widget.selectedAttributes[key] ?? "";

    return SizedBox(
      height: 75,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final val = values[index];
          final isSelected = selectedVal == val;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onAttributeChanged(key, val);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.fastOutSlowIn,
              padding: const EdgeInsets.symmetric(horizontal: 4),

              child: Row(
                children: [
                  // The Color Circle
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surface,
                        image: DecorationImage(
                          image: CachedNetworkImageProvider(
                            _getColorImageUrl(key, val),
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  // dynamic label
                  // click color -> hien ten mau ben duoi
                  ClipRect(
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOutCubic,
                      alignment: Alignment.centerLeft,
                      widthFactor: isSelected ? 1.0 : 0.0,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          val.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPillSelector(String key, List<String> values) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: values.map((val) {
          final isSelected = widget.selectedAttributes[key] == val;
          return GestureDetector(
            onTap: () => widget.onAttributeChanged(key, val),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : AppColors.surface,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                val,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSpecsTable(Map<String, dynamic> specs) {
    final entries = specs.entries.toList();
    final displayEntries = _isSpecsExpanded
        ? entries
        : entries.take(5).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: displayEntries.map((entry) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withValues(alpha: 0.05),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(
                        entry.key.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 6,
                      child: Text(
                        entry.value.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w300,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        if (entries.length > 5) ...[
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _isSpecsExpanded = !_isSpecsExpanded);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isSpecsExpanded ? "THU GỌN" : "XEM TẤT CẢ THÔNG SỐ",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _isSpecsExpanded
                        ? LucideIcons.chevronUp
                        : LucideIcons.chevronDown,
                    size: 14,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEditorialDescription() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedCrossFade(
            firstChild: Text(
              widget.product.description,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 15,
                height: 1.8,
                fontWeight: FontWeight.w300,
                fontStyle: FontStyle.italic,
              ),
            ),
            secondChild: Text(
              widget.product.description,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 15,
                height: 1.8,
                fontWeight: FontWeight.w300,
                fontStyle: FontStyle.italic,
              ),
            ),
            crossFadeState: _isDescriptionExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 400),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _isDescriptionExpanded = !_isDescriptionExpanded);
            },
            child: Text(
              _isDescriptionExpanded ? "ẨN BỚT" : "XEM CHI TIẾT",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityControl() {
    final atMax = widget.quantity >= widget.maxQuantity;
    final atMin = widget.quantity <= 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildQtyBtn(
                icon: LucideIcons.minus,
                isDisabled: atMin,
                onTap: widget.onDecrement,
                onLongPress: widget.onLongPressDecrement,
                onLongPressEnd: widget.onLongPressEnd,
              ),
              Container(
                width: 40,
                alignment: Alignment.center,
                child: Text(
                  "${widget.quantity}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _buildQtyBtn(
                icon: LucideIcons.plus,
                isDisabled: atMax,
                onTap: widget.onIncrement,
                onLongPress: widget.onLongPressIncrement,
                onLongPressEnd: widget.onLongPressEnd,
              ),
            ],
          ),
        ),
        if (atMax && widget.maxQuantity > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8, right: 4),
            child: Text(
              "Giới hạn kho: ${widget.maxQuantity} sản phẩm",
              style: const TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQtyBtn({
    required IconData icon,
    required bool isDisabled,
    required VoidCallback onTap,
    required VoidCallback onLongPress,
    required VoidCallback onLongPressEnd,
  }) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      onLongPress: isDisabled ? null : onLongPress,
      onLongPressUp: onLongPressEnd,
      onLongPressEnd: (_) => onLongPressEnd(),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isDisabled
              ? Colors.transparent
              : Colors.white.withValues(alpha: 0.05),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 16,
          color: isDisabled ? Colors.white24 : Colors.white,
        ),
      ),
    );
  }

  String _getColorKey() {
    return widget.product.attributeConfig.firstWhere(
      (k) =>
          k.toLowerCase().contains('màu') || k.toLowerCase().contains('color'),
      orElse: () => '',
    );
  }

  List<String> _getUniqueValues(String key) {
    return widget.product.variants
        .where((v) => v.isActive)
        .map((v) => v.attributes[key]?.toString())
        .whereType<String>()
        .toSet()
        .toList();
  }

  String _getColorImageUrl(String key, String val) {
    final v = widget.product.variants.firstWhere(
      (v) => v.attributes[key]?.toString() == val,
      orElse: () => widget.product.variants.first,
    );
    return v.imageUrl ?? widget.product.image;
  }
}
