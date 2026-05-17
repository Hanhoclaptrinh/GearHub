import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/core/utils/formatter_utils.dart';
import 'package:mobile/src/features/cart/domain/entities/cart_item_entity.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/src/features/cart/presentation/state/cart_cubit.dart';
import 'package:mobile/src/shared/widgets/stock_limit_dialog.dart';
import 'package:mobile/src/core/theme/app_colors.dart';
import 'quantity_selector.dart';

class CartItemCard extends StatefulWidget {
  final CartItemEntity item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onDelete;
  final VoidCallback onViewSimilar;
  final VoidCallback onToggleSelected;
  final VoidCallback onLongPress;

  const CartItemCard({
    super.key,
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onDelete,
    required this.onViewSimilar,
    required this.onToggleSelected,
    required this.onLongPress,
  });

  @override
  State<CartItemCard> createState() => _CartItemCardState();
}

class _CartItemCardState extends State<CartItemCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _dragController;
  late Animation<Offset> _contentAnimation;
  double _dragExtent = 0;
  static const double _maxDragExtent = 200;

  @override
  void initState() {
    super.initState();
    _dragController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _contentAnimation =
        Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(-_maxDragExtent, 0),
        ).animate(
          CurvedAnimation(parent: _dragController, curve: Curves.easeOutCubic),
        );
  }

  @override
  void dispose() {
    _dragController.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    _dragExtent += details.delta.dx;
    if (_dragExtent > 0) _dragExtent = 0;
    if (_dragExtent < -_maxDragExtent * 1.2) {
      _dragExtent = -_maxDragExtent * 1.2;
    }
    _dragController.value = _dragExtent.abs() / _maxDragExtent;
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_dragExtent.abs() > _maxDragExtent / 2) {
      _dragController.forward();
      _dragExtent = -_maxDragExtent;
    } else {
      _dragController.reverse();
      _dragExtent = 0;
    }
  }

  void _close() {
    _dragController.reverse();
    _dragExtent = 0;
  }

  String _getVariantComboName(dynamic variant) {
    if (variant == null) return '';
    final values = variant.attributes.values.map((e) => e.toString()).toList();
    return values.join(' / ');
  }

  void _showVariantSelectionSheet(BuildContext context) {
    final variants = widget.item.product.variants
        .where((v) => v.isActive)
        .toList();
    if (variants.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: AppColors.borderCardStrong, width: 0.5),
            ),
          ),
          padding: const EdgeInsets.only(top: 20, bottom: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderCardStrong,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Chọn phân loại hàng',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: variants.length,
                  itemBuilder: (context, index) {
                    final variant = variants[index];
                    final isSelected =
                        variant.id == widget.item.productVariant.id;
                    final variantName = _getVariantComboName(variant);

                    return GestureDetector(
                      onTap: () {
                        if (!isSelected) {
                          final cartState = context.read<CartCubit>().state;
                          int existingQty = 0;
                          if (cartState.cart != null) {
                            final existingItem = cartState.cart!.items
                                .where((i) => i.productVariant.id == variant.id)
                                .firstOrNull;
                            existingQty = existingItem?.quantity ?? 0;
                          }

                          if (existingQty + widget.item.quantity >
                              variant.stock) {
                            Navigator.pop(sheetContext);
                            StockLimitDialog.show(
                              context,
                              stockCount: variant.stock,
                              currentQty: existingQty,
                              message:
                                  'Số lượng sản phẩm trong kho không đủ.\n\nKho hiện còn ${variant.stock} sản phẩm và bạn đã có $existingQty sản phẩm trong giỏ.',
                            );
                            return;
                          }

                          context.read<CartCubit>().changeVariant(
                            widget.item.id,
                            widget.item.productVariant.id,
                            variant,
                            widget.item.product,
                            widget.item.quantity,
                          );
                        }
                        Navigator.pop(sheetContext);
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 4,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.brandYellowSoft
                              : AppColors.cardSurfaceAlt,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.brandYellow.withValues(alpha: 0.4)
                                : AppColors.borderCardStrong,
                            width: isSelected ? 1 : 0.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    variantName.isEmpty
                                        ? 'Mặc định'
                                        : variantName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: isSelected
                                          ? AppColors.textPrimary
                                          : AppColors.slate400,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    formatVND(variant.price),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? AppColors.textPrimary
                                          : AppColors.slate600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                LucideIcons.circleCheck,
                                color: AppColors.brandYellow,
                                size: 22,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
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
    final isSelected = widget.item.isSelected;
    final productName = widget.item.product.baseName;
    final productPrice = widget.item.productVariant.price;
    final productImage =
        widget.item.productVariant.imageUrl ?? widget.item.product.image;
    final variantName = _getVariantComboName(widget.item.productVariant);
    final hasMultipleVariants = widget.item.product.variants.length > 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Stack(
        clipBehavior: Clip.antiAlias,
        children: [
          Positioned.fill(
            child: Container(
              color: AppColors.cardSurface,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildActionButton(
                    icon: LucideIcons.sparkles,
                    label: 'Tương tự',
                    color: AppColors.slate400,
                    onTap: () {
                      _close();
                      widget.onViewSimilar();
                    },
                  ),
                  _buildActionButton(
                    icon: LucideIcons.trash2,
                    label: 'Xóa',
                    color: const Color(0xFFFF4D4D),
                    onTap: () {
                      _close();
                      widget.onDelete();
                    },
                  ),
                ],
              ),
            ),
          ),

          // content
          AnimatedBuilder(
            animation: _contentAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: _contentAnimation.value,
                child: child,
              );
            },
            child: GestureDetector(
              onHorizontalDragUpdate: _onHorizontalDragUpdate,
              onHorizontalDragEnd: _onHorizontalDragEnd,
              onLongPress: () {
                HapticFeedback.heavyImpact();
                widget.onLongPress();
              },
              onTap: () {
                HapticFeedback.lightImpact();
                widget.onToggleSelected();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.textPrimary.withValues(alpha: 0.05),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildSelectionIndicator(isSelected),
                    const SizedBox(width: 16),
                    _buildImageBox(productImage, isSelected),
                    const SizedBox(width: 20),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  productName.toUpperCase(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                    color: AppColors.textPrimary,
                                    letterSpacing: 1.0,
                                    height: 1.4,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // variant row
                          GestureDetector(
                            onTap: hasMultipleVariants
                                ? () => _showVariantSelectionSheet(context)
                                : null,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    variantName.isEmpty
                                        ? 'Mặc định'
                                        : variantName,
                                    style: const TextStyle(
                                      color: AppColors.slate400,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (hasMultipleVariants) ...[
                                  const SizedBox(width: 4),
                                  const Icon(
                                    LucideIcons.chevronDown,
                                    size: 10,
                                    color: AppColors.slate400,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          const Text(
                            'GIÁ',
                            style: TextStyle(
                              color: AppColors.slate600,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    formatVND(productPrice),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w200,
                                      fontSize: 22,
                                      color: AppColors.textPrimary,
                                      letterSpacing: -0.5,
                                      height: 1.0,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              QuantitySelector(
                                quantity: widget.item.quantity,
                                maxQuantity: widget.item.productVariant.stock,
                                onIncrement: widget.onIncrement,
                                onDecrement: widget.onDecrement,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageBox(String url, bool isSelected) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.cardSurfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? AppColors.brandYellow.withValues(alpha: 0.3)
              : AppColors.borderCardStrong,
          width: 0.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Hero(
        tag: 'product_${widget.item.product.id}',
        child: _buildProductImage(url),
      ),
    );
  }

  Widget _buildProductImage(String url) {
    if (url.isEmpty) {
      return const Center(
        child: Icon(LucideIcons.image, color: AppColors.slate600, size: 28),
      );
    }
    if (url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(LucideIcons.image, color: AppColors.slate600, size: 28),
        ),
      );
    }
    return Image.asset(url, fit: BoxFit.contain);
  }

  Widget _buildSelectionIndicator(bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? AppColors.brandYellow : Colors.transparent,
        border: Border.all(
          color: isSelected
              ? AppColors.brandYellow
              : AppColors.textPrimary.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: isSelected
          ? const Icon(Icons.check, size: 10, color: AppColors.ctaPrimaryText)
          : null,
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: double.infinity,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
