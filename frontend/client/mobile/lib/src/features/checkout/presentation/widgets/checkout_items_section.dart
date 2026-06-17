import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/core/utils/formatter_utils.dart';
import 'package:mobile/src/features/cart/domain/entities/cart_item_entity.dart';

class CheckoutItemsSection extends StatefulWidget {
  final List<CartItemEntity> items;

  const CheckoutItemsSection({super.key, required this.items});

  @override
  State<CheckoutItemsSection> createState() => _CheckoutItemsSectionState();
}

class _CheckoutItemsSectionState extends State<CheckoutItemsSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF111111);
    final secondaryTextColor = isDark
        ? const Color(0xFFA1A1AA)
        : const Color(0xFF71717A);
    final dividerColor = isDark
        ? const Color(0xFF2A2A2F)
        : const Color(0xFFE4E4E7);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Tổng quan đơn hàng",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: primaryTextColor,
                ),
              ),
              Row(
                children: [
                  Text(
                    _isExpanded ? "Thu gọn" : "Chi tiết",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: secondaryTextColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      LucideIcons.chevronDown,
                      size: 16,
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AnimatedCrossFade(
          firstChild: _buildCollapsedDeck(context),
          secondChild: _buildExpandedList(context, dividerColor),
          crossFadeState: _isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
          firstCurve: Curves.easeInOutCubic,
          secondCurve: Curves.easeInOutCubic,
          sizeCurve: Curves.easeInOutCubic,
        ),
      ],
    );
  }

  Widget _buildCollapsedDeck(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF111111);
    final secondaryTextColor = isDark
        ? const Color(0xFFA1A1AA)
        : const Color(0xFF71717A);

    final displayItems = widget.items.take(3).toList();
    final totalQty = widget.items.fold<int>(0, (sum, i) => sum + i.quantity);

    return GestureDetector(
      onTap: () => setState(() => _isExpanded = true),
      child: Container(
        decoration: ShapeDecoration(
          color: isDark ? const Color(0xFF161619) : const Color(0xFFF9F9FB),
          shape: BeveledRectangleBorder(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
              bottomLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
            side: BorderSide(
              color: isDark ? const Color(0xFF2A2A2F) : const Color(0xFFE4E4E7),
              width: 0.8,
            ),
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            SizedBox(
              width: 48 + (displayItems.length - 1) * 14.0,
              height: 48,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (int i = 0; i < displayItems.length; i++)
                    Positioned(
                      left: i * 14.0,
                      top: 0,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E1E22)
                              : const Color(0xFFF4F4F5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF161619)
                                : const Color(0xFFF9F9FB),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: displayItems[i].productVariant.imageUrl != null
                              ? Image.network(
                                  displayItems[i].productVariant.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                    LucideIcons.image,
                                    color: secondaryTextColor,
                                    size: 16,
                                  ),
                                )
                              : Icon(
                                  LucideIcons.package,
                                  color: secondaryTextColor,
                                  size: 16,
                                ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Đơn hàng gồm $totalQty sản phẩm",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: primaryTextColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.items
                        .map((e) {
                          final attrs = e.productVariant.attributes.values.join(
                            ' / ',
                          );
                          return "${e.product.baseName}${attrs.isNotEmpty ? ' ($attrs)' : ''}";
                        })
                        .join(', '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: secondaryTextColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(LucideIcons.chevronRight, size: 16, color: secondaryTextColor),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedList(BuildContext context, Color dividerColor) {
    return Column(
      children: [
        for (int i = 0; i < widget.items.length; i++) ...[
          _buildSummaryItem(context, widget.items[i]),
          if (i < widget.items.length - 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: dividerColor, height: 1, thickness: 0.5),
            ),
        ],
      ],
    );
  }

  Widget _buildSummaryItem(BuildContext context, CartItemEntity item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF111111);
    final secondaryTextColor = isDark
        ? const Color(0xFFA1A1AA)
        : const Color(0xFF71717A);

    final variantParts = item.productVariant.attributes.values
        .map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E22) : const Color(0xFFF4F4F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: item.productVariant.imageUrl != null
                ? Image.network(
                    item.productVariant.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      LucideIcons.image,
                      color: secondaryTextColor,
                      size: 20,
                    ),
                  )
                : Icon(
                    LucideIcons.package,
                    color: secondaryTextColor,
                    size: 20,
                  ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.product.baseName,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: primaryTextColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (variantParts.isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: variantParts.map((part) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E1E22)
                            : const Color(0xFFF4F4F5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        part,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: secondaryTextColor,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (item.productVariant.hasActiveFlashSale) ...[
              Text(
                formatVND(item.productVariant.flashPrice!),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                formatVND(item.productVariant.price),
                style: TextStyle(
                  fontSize: 11,
                  color: secondaryTextColor.withValues(alpha: 0.5),
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ] else ...[
              Text(
                formatVND(item.productVariant.price),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: primaryTextColor,
                ),
              ),
            ],
            const SizedBox(height: 2),
            Text(
              "x${item.quantity}",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: secondaryTextColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
