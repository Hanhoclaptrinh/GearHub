import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/features/home/domain/models/product.dart';

class ProductHeroSection extends StatefulWidget {
  final Product product;
  final int selectedColorIndex;
  final List<Color> variantColors;
  final int quantity;
  final Function(int) onColorTarget;
  final Function() onIncrement;
  final Function() onDecrement;
  final Function() onLongPressIncrement;
  final Function() onLongPressDecrement;
  final Function() onLongPressEnd;
  final int maxQuantity;

  const ProductHeroSection({
    super.key,
    required this.product,
    required this.selectedColorIndex,
    required this.variantColors,
    required this.quantity,
    required this.onColorTarget,
    required this.onIncrement,
    required this.onDecrement,
    required this.onLongPressIncrement,
    required this.onLongPressDecrement,
    required this.onLongPressEnd,
    this.maxQuantity = 10,
  });

  @override
  State<ProductHeroSection> createState() => _ProductHeroSectionState();
}

class _ProductHeroSectionState extends State<ProductHeroSection> {
  late final PageController _pageController;
  final ValueNotifier<double> _pageOffset = ValueNotifier<double>(0.0);

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: widget
          .selectedColorIndex, // nhay den hinh anh cua mau duoc chon tu truoc
      viewportFraction: 0.8, // 80% chieu ngang
    );
    _pageOffset.value = widget.selectedColorIndex.toDouble();

    // su kien scroll hero
    _pageController.addListener(() {
      if (_pageController.hasClients) {
        _pageOffset.value = _pageController.page ?? 0.0;
      }
    });
  }

  @override
  void didUpdateWidget(ProductHeroSection oldWidget) {
    // chi thay doi khi co su thay doi bien the mau sac
    if (oldWidget.selectedColorIndex != widget.selectedColorIndex) {
      // scroll toi trang anh tuong ung voi mau sac duoc chon
      if (_pageController.hasClients &&
          _pageController.page?.toInt() != widget.selectedColorIndex) {
        _pageController.animateToPage(
          widget.selectedColorIndex,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
        );
      }
    }
    super.didUpdateWidget(oldWidget); // cap nhat widget
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pageOffset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final colorScheme = Theme.of(context).colorScheme;
    final selectedColor = widget.variantColors[widget.selectedColorIndex];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // qty col
              _buildVerticalQty(colorScheme),
              // color dots
              _buildColorDots(colorScheme),
              // fav button
              _buildFavButton(colorScheme),
            ],
          ),
          const SizedBox(height: 20),
          // main img area
          SizedBox(
            height: size.height * 0.3,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // glow
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  width: size.width * 0.5,
                  height: size.width * 0.5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selectedColor.withValues(alpha: 0.15),
                    boxShadow: [
                      BoxShadow(
                        color: selectedColor.withValues(alpha: 0.1),
                        blurRadius: 80,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                ),

                // swipable img
                PageView.builder(
                  controller: _pageController,
                  itemCount: widget.variantColors.length,
                  onPageChanged: widget.onColorTarget,
                  clipBehavior: Clip.none,
                  itemBuilder: (context, index) {
                    return ValueListenableBuilder<double>(
                      valueListenable: _pageOffset,
                      builder: (context, offset, child) {
                        // tinh khoang cach hien tai cua anh toi tam man hinh
                        final double diff = index - offset;
                        // cang xa tam anh cang nho dan
                        final double scale = (1 - (diff.abs() * 0.2)).clamp(
                          0.7,
                          1.0,
                        );

                        return Transform(
                          // dung ma tran vector de xoay anh
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001)
                            ..rotateY(diff * -0.15)
                            ..scale(scale),
                          alignment: Alignment.center,
                          child: Hero(
                            tag: index == widget.selectedColorIndex
                                ? 'product_${widget.product.id}'
                                : 'product_${widget.product.id}_$index',
                            child: Image.asset(
                              widget.product.image,
                              fit: BoxFit.contain,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // price
          Column(
            children: [
              Text(
                'Price',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
              Text(
                '\$${widget.product.price.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalQty(ColorScheme colorScheme) {
    final bool isMin = widget.quantity <= 1;
    final bool isMax = widget.quantity >= widget.maxQuantity;

    return Column(
      children: [
        Text(
          'Qty',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 8),
        _circleControl(
          LucideIcons.plus,
          isMax ? null : widget.onIncrement,
          isMax ? null : widget.onLongPressIncrement,
          isMax,
          colorScheme,
        ),
        const SizedBox(height: 8),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: colorScheme.onSurface,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${widget.quantity}',
              style: TextStyle(
                color: colorScheme.surface,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _circleControl(
          LucideIcons.minus,
          isMin ? null : widget.onDecrement,
          isMin ? null : widget.onLongPressDecrement,
          isMin,
          colorScheme,
        ),
      ],
    );
  }

  Widget _circleControl(
    IconData icon,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    bool disabled,
    ColorScheme colorScheme,
  ) {
    return GestureDetector(
      onTap: onTap,
      onLongPressStart: onLongPress != null ? (_) => onLongPress() : null,
      onLongPressEnd: (_) => widget.onLongPressEnd(),
      onLongPressCancel: widget.onLongPressEnd,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: disabled ? 0.2 : 1.0,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
            shape: BoxShape.circle,
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Icon(icon, size: 18, color: colorScheme.onSurface),
        ),
      ),
    );
  }

  Widget _buildColorDots(ColorScheme colorScheme) {
    return Column(
      children: [
        Text(
          'Active',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(widget.variantColors.length, (index) {
            final isSelected = widget.selectedColorIndex == index;
            final color = widget.variantColors[index];
            return GestureDetector(
              onTap: () => widget.onColorTarget(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isSelected ? 24 : 14,
                height: isSelected ? 24 : 14,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: colorScheme.onSurface, width: 2)
                      : null,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildFavButton(ColorScheme colorScheme) {
    return Column(
      children: [
        Text(
          'Fav',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
            shape: BoxShape.circle,
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Icon(
            LucideIcons.heart,
            size: 20,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
