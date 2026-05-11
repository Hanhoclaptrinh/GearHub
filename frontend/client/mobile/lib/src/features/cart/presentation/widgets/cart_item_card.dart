import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/core/utils/formatter_utils.dart';
import 'package:mobile/src/features/cart/domain/entities/cart_item_entity.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/src/features/cart/presentation/state/cart_cubit.dart';
import 'package:mobile/src/shared/widgets/stock_limit_dialog.dart';
import 'quantity_selector.dart';

const _bg = Color(0xFF07070A);
const _surface = Color(0xFF0E0E18);
const _surfaceAlt = Color(0xFF14141E);
const _surfaceDeep = Color(0xFF1A1A28);
const _border = Color(0xFF252535);
const _accent = Color(0xFFFDE047);
const _accentSoft = Color(0x1AFDE047);
const _pink = Color(0xFFFF4D4D);
const _pinkSoft = Color(0x1AFF4D4D);
const _textHigh = Colors.white;
const _textMid = Color(0xFF94A3B8);
const _textLow = Color(0xFF475569);

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
                          color: isSelected ? _accentSoft : _surfaceAlt,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? _accent.withValues(alpha: 0.4)
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
                                      color: isSelected
                                          ? Colors.white
                                          : _textLow,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                LucideIcons.circleCheck,
                                color: _accent,
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                color: _surfaceDeep,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildActionButton(
                      icon: LucideIcons.sparkles,
                      label: 'Tương tự',
                      color: Colors.white,
                      bgColor: Colors.white.withValues(alpha: 0.05),
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
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected
                        ? _accent.withValues(alpha: 0.45)
                        : _border,
                    width: isSelected ? 1.5 : 0.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: _accent.withValues(alpha: 0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildImageBox(productImage),
                    const SizedBox(width: 14),

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
                                  productName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: _textHigh,
                                    height: 1.25,
                                    letterSpacing: 0.2,
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
                                      color: _textMid,
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
                                    size: 13,
                                    color: _textMid,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          const Text(
                            'GIÁ',
                            style: TextStyle(
                              color: _textLow,
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
                                      fontWeight: FontWeight.w900,
                                      fontSize: 20,
                                      color: Colors.white,
                                      letterSpacing: -1.0,
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

  Widget _buildImageBox(String url) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: _surfaceDeep,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border, width: 0.5),
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
        child: Icon(LucideIcons.image, color: _textLow, size: 28),
      );
    }
    if (url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(LucideIcons.image, color: _textLow, size: 28),
        ),
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
