import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/src/shared/models/product.dart';

class ProductInfoSection extends StatefulWidget {
  final Product product;

  const ProductInfoSection({super.key, required this.product});

  @override
  State<ProductInfoSection> createState() => _ProductInfoSectionState();
}

class _ProductInfoSectionState extends State<ProductInfoSection> {
  bool _isDescriptionExpanded = false;

  int _selectedConfigIndex = 1;
  final List<String> _configurations = [
    '256GB / 8GB RAM',
    '512GB / 16GB RAM',
    '1TB / 24GB RAM',
    '2TB / 64GB RAM',
  ];

  final Map<String, String> _specs = {
    'Chip': 'Apple M2 Max',
    'RAM': '16GB Unified',
    'Storage': '512GB SSD',
    'Display': '14.2" Liquid Retina XDR',
  };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // tags
          if (widget.product.tag != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                ),
              ),
              child: Text(
                widget.product.tag!.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.primary,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],

          // configuration variants
          Text(
            'Configuration',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildVariantSelector(_configurations, _selectedConfigIndex, (i) {
            HapticFeedback.selectionClick();
            setState(() => _selectedConfigIndex = i);
          }, colorScheme),

          const SizedBox(height: 36),

          // description
          Text(
            'Description',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              setState(() {
                _isDescriptionExpanded = !_isDescriptionExpanded;
              });
            },
            child: AnimatedCrossFade(
              firstChild: Text(
                'Experience unparalleled performance and stunning visuals with the latest Apple silicon technology. Designed for professionals and enthusiasts who demand the absolute best in reliability, speed, and elegance.',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              secondChild: Text(
                'Experience unparalleled performance and stunning visuals with the latest Apple silicon technology. Designed for professionals and enthusiasts who demand the absolute best in reliability, speed, and elegance. This device seamlessly integrates into your workflow, providing exceptional battery life and an advanced thermal system to keep you going all day with blazing fast speeds and incredible efficiency.',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              crossFadeState: _isDescriptionExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              setState(() {
                _isDescriptionExpanded = !_isDescriptionExpanded;
              });
            },
            child: Text(
              _isDescriptionExpanded ? 'Show less' : 'Show more',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
              ),
            ),
          ),

          const SizedBox(height: 36),

          // specs
          Text(
            'Specifications',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildSpecsList(colorScheme),
        ],
      ),
    );
  }

  Widget _buildVariantSelector(
    List<String> options,
    int selectedIndex,
    Function(int) onSelect,
    ColorScheme colorScheme,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.none,
      child: Row(
        children: List.generate(options.length, (index) {
          final isSelected = selectedIndex == index;
          return GestureDetector(
            onTap: () => onSelect(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.only(right: 14),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              transform: Matrix4.identity()..scale(isSelected ? 1.02 : 1.0),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.onSurface
                    : colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? colorScheme.onSurface
                      : colorScheme.outline.withValues(alpha: 0.2),
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: colorScheme.onSurface.withValues(alpha: 0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : [],
              ),
              child: Text(
                options[index],
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected
                      ? colorScheme.surface
                      : colorScheme.onSurfaceVariant,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSpecsList(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Column(
        children: _specs.entries.map((entry) {
          final isLast = entry.key == _specs.entries.last.key;
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      entry.key,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      entry.value,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
              if (!isLast) ...[
                const SizedBox(height: 16),
                Divider(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                  height: 1,
                ),
                const SizedBox(height: 16),
              ],
            ],
          );
        }).toList(),
      ),
    );
  }
}
