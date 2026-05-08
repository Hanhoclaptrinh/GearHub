import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/core/utils/formatter_utils.dart';
import 'package:mobile/src/features/cart/domain/entities/cart_item_entity.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/src/features/cart/presentation/state/cart_cubit.dart';
import 'package:mobile/src/shared/widgets/stock_limit_dialog.dart';
import 'quantity_selector.dart';

const _bg = Color(0xFF0A0A10);
const _surface = Color(0xFF14141E);
const _surfaceAlt = Color(0xFF1C1C28);
const _border = Color(0xFF2A2A38);
const _accent = Color(0xFFF59E0B);
const _indigo = Color(0xFF6366F1);
const _indigoSoft = Color(0x1A6366F1);
const _pink = Color(0xFFFF6B8A);
const _pinkSoft = Color(0x1FFF6B8A);
const _textHigh = Color(0xFFF1F1F5);
const _textMid = Color(0xFF9191A8);
const _textLow = Color(0xFF4A4A62);

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
  static const double _maxDragExtent = 160;

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
            color: _bg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: _border, width: 0.5)),
          ),
          padding: const EdgeInsets.only(top: 20, bottom: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _border,
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
                    color: _textHigh,
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
                          color: isSelected ? _indigoSoft : _surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? _indigo.withValues(alpha: 0.4)
                                : _border,
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
                                      color: isSelected ? _textHigh : _textMid,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    formatVND(variant.price),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected ? _accent : _textLow,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                LucideIcons.circleCheck,
                                color: _indigo,
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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Stack(
        clipBehavior: Clip.antiAlias,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Container(
                color: _surfaceAlt,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildActionButton(
                      icon: LucideIcons.sparkles,
                      label: 'Tương tự',
                      color: _indigo,
                      bgColor: _indigoSoft,
                      onTap: () {
                        _close();
                        widget.onViewSimilar();
                      },
                    ),
                    _buildActionButton(
                      icon: LucideIcons.trash2,
                      label: 'Xóa',
                      color: _pink,
                      bgColor: _pinkSoft,
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
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isSelected
                        ? _accent.withValues(alpha: 0.4)
                        : _border,
                    width: isSelected ? 1.5 : 0.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: _accent.withValues(alpha: 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 22,
                      height: 22,
                      margin: const EdgeInsets.only(top: 2, right: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? _accent : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? _accent : _textLow,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              size: 13,
                              color: Colors.black,
                            )
                          : null,
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
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: _textHigh,
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                formatVND(productPrice),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: _accent,
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
                                  style: const TextStyle(
                                    color: _textMid,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
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
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _surfaceAlt,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: _border,
                                        width: 0.5,
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Đổi',
                                          style: TextStyle(
                                            color: _textMid,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        SizedBox(width: 2),
                                        Icon(
                                          LucideIcons.chevronDown,
                                          size: 12,
                                          color: _textMid,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SizedBox(
                                width: 90,
                                height: 90,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: _surfaceAlt,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Hero(
                                      tag: 'product_${widget.item.product.id}',
                                      child: _buildProductImage(productImage),
                                    ),
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
    if (url.isEmpty) return const SizedBox();
    if (url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            const Icon(LucideIcons.image, color: _textLow, size: 28),
      );
    }
    return Image.asset(url, fit: BoxFit.contain);
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 75,
        height: double.infinity,
        margin: const EdgeInsets.only(left: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
