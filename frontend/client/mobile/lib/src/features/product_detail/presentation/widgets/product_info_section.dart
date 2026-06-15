import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
            _buildSectionHeader(context, "Màu sắc"),
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
                  _buildSectionHeader(context, key),
                  const SizedBox(height: 16),
                  _buildPillSelector(context, key, values),
                  const SizedBox(height: 40),
                ],
              );
            }),
          ],

          //qty config
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Số lượng",
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                _buildQuantityControl(context),
              ],
            ),
          ),
          const SizedBox(height: 48),
          //specs config
          if (widget.product.commonSpecs != null &&
              widget.product.commonSpecs!.isNotEmpty) ...[
            _buildSectionHeader(context, "THÔNG SỐ KỸ THUẬT"),
            const SizedBox(height: 24),
            _buildSpecsTable(context, widget.product.commonSpecs!),
            const SizedBox(height: 48),
          ],

          //desc config
          _buildSectionHeader(context, "MÔ TẢ SẢN PHẨM"),
          const SizedBox(height: 16),
          _buildEditorialDescription(context),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Text(
        title,
        style: TextStyle(
          color: theme.colorScheme.onSurface,
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
          final theme = Theme.of(context);
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
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.onSurface
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.surfaceContainerHighest,
                        image: DecorationImage(
                          image: CachedNetworkImageProvider(
                            _getColorImageUrl(key, val),
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
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
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
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

  Widget _buildPillSelector(
    BuildContext context,
    String key,
    List<String> values,
  ) {
    final theme = Theme.of(context);
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
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                val,
                style: TextStyle(
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
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

  Widget _buildSpecsTable(BuildContext context, Map<String, dynamic> specs) {
    final theme = Theme.of(context);
    final entries = specs.entries.toList();
    final displayEntries = entries.take(4).toList();

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
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.05,
                      ),
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
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.7,
                          ),
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
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
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
        if (entries.length > 4) ...[
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _showSpecsBottomSheet(context, specs);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "XEM TẤT CẢ THÔNG SỐ",
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    LucideIcons.chevronRight,
                    size: 14,
                    color: theme.colorScheme.onSurface,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showSpecsBottomSheet(BuildContext context, Map<String, dynamic> specs) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final entries = specs.entries.toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: theme.cardColor.withValues(alpha: 0.85),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                border: Border(
                  top: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.5),
                  ),
                  left: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.5),
                  ),
                  right: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  //drag handle
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: cs.onSurface.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 24),
                  //header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'THÔNG SỐ CHI TIẾT',
                          style: TextStyle(
                            color: cs.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest.withValues(
                                alpha: 0.5,
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: cs.outlineVariant.withValues(alpha: 0.5),
                              ),
                            ),
                            child: const Icon(LucideIcons.x, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                      physics: const BouncingScrollPhysics(),
                      itemCount: entries.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 0),
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: cs.onSurface.withValues(alpha: 0.05),
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
                                    color: cs.onSurfaceVariant.withValues(
                                      alpha: 0.7,
                                    ),
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
                                  style: TextStyle(
                                    color: cs.onSurface,
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
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEditorialDescription(BuildContext context) {
    final theme = Theme.of(context);
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
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 15,
                height: 1.8,
                fontWeight: FontWeight.w300,
                fontStyle: FontStyle.italic,
              ),
            ),
            secondChild: Text(
              widget.product.description,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
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
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityControl(BuildContext context) {
    final theme = Theme.of(context);
    final atMax = widget.quantity >= widget.maxQuantity;
    final atMin = widget.quantity <= 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.4,
            ),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildQtyBtn(
                context,
                icon: LucideIcons.minus,
                isDisabled: atMin,
                onTap: widget.onDecrement,
                onLongPress: widget.onLongPressDecrement,
                onLongPressEnd: widget.onLongPressEnd,
              ),
              Container(
                width: 44,
                alignment: Alignment.center,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutBack,
                              ),
                            ),
                            child: child,
                          ),
                        );
                      },
                  child: Text(
                    "${widget.quantity}",
                    key: ValueKey<int>(widget.quantity),
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              _buildQtyBtn(
                context,
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
              style: TextStyle(
                color: theme.colorScheme.error,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQtyBtn(
    BuildContext context, {
    required IconData icon,
    required bool isDisabled,
    required VoidCallback onTap,
    required VoidCallback onLongPress,
    required VoidCallback onLongPressEnd,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      onLongPress: isDisabled ? null : onLongPress,
      onLongPressUp: onLongPressEnd,
      onLongPressEnd: (_) => onLongPressEnd(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isDisabled ? Colors.transparent : theme.colorScheme.surface,
          shape: BoxShape.circle,
          boxShadow: isDisabled
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
          border: isDisabled
              ? null
              : Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
        ),
        child: Center(
          child: Icon(
            icon,
            size: 14,
            color: isDisabled
                ? theme.colorScheme.onSurface.withValues(alpha: 0.25)
                : theme.colorScheme.onSurface,
          ),
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
