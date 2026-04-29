import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/src/shared/models/product_model.dart';

class ProductInfoSection extends StatefulWidget {
  final ProductModel product;
  final int selectedConfigIndex;
  final Function(int) onConfigChanged;

  const ProductInfoSection({
    super.key,
    required this.product,
    required this.selectedConfigIndex,
    required this.onConfigChanged,
  });

  @override
  State<ProductInfoSection> createState() => _ProductInfoSectionState();
}

class _ProductInfoSectionState extends State<ProductInfoSection> {
  bool _isDescriptionExpanded = false;

  List<String> get _configurations {
    if (widget.product.variants.isEmpty) return ['Standard'];
    return widget.product.variants
        .map((v) => v.name.replaceAll('${widget.product.name} - ', ''))
        .toList();
  }

  Map<String, String> get _specs {
    final Map<String, String> display = {};

    // top specs lay tu vaulspecs
    if (widget.product.vaultSpecs != null) {
      final specs = widget.product.vaultSpecs!;
      if (specs.containsKey('processor')) {
        display['Processor'] = specs['processor'].toString();
      } else if (specs.containsKey('chip')) {
        display['Chip'] = specs['chip'].toString();
      }

      if (specs.containsKey('display')) {
        display['Display'] = specs['display'].toString();
      }
    }

    // attributes bien the
    if (widget.product.variants.isNotEmpty &&
        widget.selectedConfigIndex < widget.product.variants.length) {
      final currentVariant =
          widget.product.variants[widget.selectedConfigIndex];
      currentVariant.attributes.forEach((key, value) {
        final formattedKey = key[0].toUpperCase() + key.substring(1);
        display[formattedKey] = value.toString();
      });
    }

    return display;
  }

  Map<String, String> get _fullSpecs {
    final Map<String, String> display = {};
    if (widget.product.vaultSpecs != null) {
      widget.product.vaultSpecs!.forEach((key, value) {
        final formattedKey = key[0].toUpperCase() + key.substring(1);
        display[formattedKey] = value.toString();
      });
    }
    if (widget.product.variants.isNotEmpty &&
        widget.selectedConfigIndex < widget.product.variants.length) {
      final currentVariant =
          widget.product.variants[widget.selectedConfigIndex];
      currentVariant.attributes.forEach((key, value) {
        final formattedKey = key[0].toUpperCase() + key.substring(1);
        display[formattedKey] = value.toString();
      });
    }
    if (display.isEmpty) return _specs;
    return display;
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
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cấu hình',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.black,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildVariantSelector(_configurations, widget.selectedConfigIndex, (
            i,
          ) {
            HapticFeedback.selectionClick();
            widget.onConfigChanged(i);
          }),
          const SizedBox(height: 36),
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
      ),
    );
  }

  Widget _buildVariantSelector(
    List<String> options,
    int selectedIndex,
    Function(int) onSelect,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.none,
      child: Row(
        children: List.generate(options.length, (index) {
          final isSelected = selectedIndex == index;
          final variant =
              widget.product.variants.isNotEmpty &&
                  index < widget.product.variants.length
              ? widget.product.variants[index]
              : null;
          final isOutOfStock = (variant?.stock ?? 0) <= 0;

          return GestureDetector(
            onTap: isOutOfStock ? null : () => onSelect(index),
            child: Opacity(
              opacity: isOutOfStock ? 0.5 : 1.0,
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
                    color: isSelected ? Colors.black : const Color(0xFFE5E5EA),
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
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      options[index],
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
                  ],
                ),
              ),
            ),
          );
        }),
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
