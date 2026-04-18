import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/src/features/home/domain/models/product.dart';

class ProductHeroSection extends StatefulWidget {
  final Product product;
  final bool display3DRender;

  const ProductHeroSection({
    super.key,
    required this.product,
    this.display3DRender = true,
  });

  @override
  State<ProductHeroSection> createState() => _ProductHeroSectionState();
}

class _ProductHeroSectionState extends State<ProductHeroSection> {
  int _selectedColorIndex = 1;

  final List<Color> _variantColors = [
    const Color(0xFFF5F5F7),
    const Color(0xFF4C4C4C),
    const Color(0xFFE5D5C5),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: size.height * 0.45,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // glow
          Positioned(
            bottom: 80,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: size.width * 0.65,
              height: size.width * 0.65,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _variantColors[_selectedColorIndex].withValues(
                  alpha: 0.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _variantColors[_selectedColorIndex].withValues(
                      alpha: 0.15,
                    ),
                    blurRadius: 100,
                    spreadRadius: 30,
                  ),
                ],
              ),
            ),
          ),

          // ground plate
          Positioned(
            bottom: 70,
            child: Container(
              width: size.width * 0.75,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(
                  Radius.elliptical(size.width * 0.75, 60),
                ),
                border: Border.all(
                  color: colorScheme.onSurface.withValues(alpha: 0.08),
                  width: 1.5,
                ),
              ),
            ),
          ),

          // high-res image fallback
          Positioned.fill(
            bottom: 60,
            child: Center(
              child: Hero(
                tag: 'product_${widget.product.id}',
                child: Image.asset(
                  widget.product.image,
                  height: size.height * 0.35,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // color variant selection
          Positioned(
            bottom: 12,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(_variantColors.length, (index) {
                return _buildColorSwatch(index, colorScheme);
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorSwatch(int index, ColorScheme colorScheme) {
    final isSelected = _selectedColorIndex == index;
    final color = _variantColors[index];

    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          HapticFeedback.selectionClick();
          setState(() {
            _selectedColorIndex = index;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        width: isSelected ? 36 : 28,
        height: isSelected ? 36 : 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
            strokeAlign: BorderSide.strokeAlignOutside,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
      ),
    );
  }
}
