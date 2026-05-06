import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/core/utils/formatter_utils.dart';
import 'package:mobile/src/features/cart/domain/entities/cart_item_entity.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/src/features/cart/presentation/state/cart_cubit.dart';
import 'package:mobile/src/shared/widgets/stock_limit_dialog.dart';
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
  static const double _maxDragExtent = 180;

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
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.only(top: 24, bottom: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Chọn phân loại hàng',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      title: Text(
                        variantName.isEmpty ? 'Mặc định' : variantName,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                      subtitle: Text(formatVND(variant.price)),
                      trailing: isSelected
                          ? Icon(
                              Icons.check_circle,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : null,
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
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = widget.item.isSelected;
    final productName = widget.item.product.baseName;
    final productPrice = widget.item.productVariant.price;
    final productImage =
        widget.item.productVariant.imageUrl ?? widget.item.product.image;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Stack(
        clipBehavior: Clip.antiAlias,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildActionButton(
                      icon: LucideIcons.sparkles,
                      label: 'Similar',
                      color: colorScheme.primary,
                      onTap: () {
                        _close();
                        widget.onViewSimilar();
                      },
                    ),
                    _buildActionButton(
                      icon: LucideIcons.trash2,
                      label: 'Delete',
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
          ),
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
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFF9FAFB)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 14,
                      height: 14,
                      margin: const EdgeInsets.only(top: 4, right: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.black
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? Colors.black
                              : const Color(0xFFC7C7CC),
                          width: 2,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  productName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Colors.black,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                formatVND(productPrice),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Color(0xFF0061FE),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  _getVariantComboName(
                                        widget.item.productVariant,
                                      ).isEmpty
                                      ? 'Mặc định'
                                      : _getVariantComboName(
                                          widget.item.productVariant,
                                        ),
                                  style: TextStyle(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (widget.item.product.variants.length > 1)
                                GestureDetector(
                                  onTap: () =>
                                      _showVariantSelectionSheet(context),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.black.withValues(alpha: 0.04),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Đổi',
                                          style: TextStyle(
                                            color: Colors.black
                                                .withValues(alpha: 0.7),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 2),
                                        Icon(
                                          LucideIcons.chevronDown,
                                          size: 13,
                                          color: Colors.black
                                              .withValues(alpha: 0.7),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SizedBox(
                                width: 100,
                                height: 100,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Hero(
                                    tag: 'product_${widget.item.product.id}',
                                    child: _buildProductImage(productImage),
                                  ),
                                ),
                              ),
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

  Widget _buildProductImage(String url) {
    if (url.isEmpty) {
      return const SizedBox();
    }
    if (url.startsWith('http')) {
      return Image.network(url, fit: BoxFit.contain);
    }
    return Image.asset(url, fit: BoxFit.contain);
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
        width: 85,
        height: double.infinity,
        margin: const EdgeInsets.only(left: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
