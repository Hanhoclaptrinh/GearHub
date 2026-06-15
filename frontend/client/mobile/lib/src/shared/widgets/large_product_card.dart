import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/core/utils/formatter_utils.dart';
import 'package:mobile/src/shared/models/product_model.dart';
import 'package:mobile/src/shared/models/product_variant_model.dart';
import 'package:mobile/src/features/cart/presentation/state/cart_cubit.dart';
import 'package:mobile/src/features/home/presentation/state/home_cubit.dart';
import 'package:mobile/src/features/product_detail/presentation/pages/product_detail_page.dart';
import 'package:mobile/src/shared/widgets/color_bubble_selector.dart';
import 'package:mobile/src/shared/widgets/stock_limit_dialog.dart';

class LargeProductCard extends StatefulWidget {
  final ProductModel product;
  const LargeProductCard({super.key, required this.product});

  @override
  State<LargeProductCard> createState() => _LargeProductCardState();
}

class _LargeProductCardState extends State<LargeProductCard>
    with SingleTickerProviderStateMixin {
  late final _VariantController _ctrl;
  late final AnimationController _pressCtrl;
  late final Animation<double> _pressScale;

  @override
  void initState() {
    super.initState();
    _ctrl = _VariantController(widget.product);

    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _pressScale = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);

    return AnimatedBuilder(
      animation: _pressScale,
      builder: (_, child) =>
          Transform.scale(scale: _pressScale.value, child: child),
      child: GestureDetector(
        onTapDown: (_) => _pressCtrl.forward(),
        onTapUp: (_) {
          _pressCtrl.reverse();
          _navigateToDetail(context);
        },
        onTapCancel: () => _pressCtrl.reverse(),
        child: Container(
          width: double.infinity,
          height: 480,
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border(
              bottom: BorderSide(color: dividerColor, width: 0.5),
              right: BorderSide(color: dividerColor, width: 0.5),
            ),
          ),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.product.brandName?.toUpperCase() ?? 'TECH',
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.6,
                      ),
                      letterSpacing: 1.5,
                    ),
                  ),
                  ValueListenableBuilder<ProductVariantModel?>(
                    valueListenable: _ctrl.currentVariant,
                    builder: (_, variant, __) {
                      final priceVal =
                          variant?.price ?? widget.product.basePrice;
                      final prefix = widget.product.hasPriceRange ? 'Từ ' : '';
                      return Text(
                        '$prefix${formatVND(priceVal)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                        ),
                      );
                    },
                  ),
                ],
              ),

              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: _ImageStage(
                      product: widget.product,
                      controller: _ctrl,
                    ),
                  ),
                ),
              ),

              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.baseName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),

                        ..._ctrl.attributeOptions.entries
                            .where(
                              (entry) =>
                                  entry.key.toLowerCase().contains('color') ||
                                  entry.key.toLowerCase().contains('màu'),
                            )
                            .map((entry) {
                              final k = entry.key;
                              return ValueListenableBuilder<
                                Map<String, String>
                              >(
                                valueListenable: _ctrl.selectedAttributes,
                                builder: (_, selected, __) {
                                  return ColorBubbleSelector(
                                    product: widget.product,
                                    attributeKey: k,
                                    selectedValue: selected[k],
                                    bubbleSize: 20,
                                    spacing: 4,
                                    onSelected: (val) =>
                                        _ctrl.updateAttribute(k, val),
                                  );
                                },
                              );
                            }),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  GestureDetector(
                    onTap: () => _handleAddToCart(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.03),
                        border: Border.all(color: dividerColor, width: 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Icon(
                          LucideIcons.shoppingBag300,
                          size: 14,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToDetail(BuildContext context) {
    context.read<HomeCubit>().incrementView(widget.product.id);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailPage(
          product: widget.product,
          initialAttributes: _ctrl.selectedAttributes.value,
        ),
      ),
    );
  }

  void _handleAddToCart(BuildContext context) {
    final variant = _ctrl.currentVariant.value;
    if (variant == null) return;

    final cartCubit = context.read<CartCubit>();
    final cartState = cartCubit.state;
    final existingQty =
        cartState.cart?.items
            .where((i) => i.productVariant.id == variant.id)
            .firstOrNull
            ?.quantity ??
        0;

    if (existingQty + 1 > variant.stock) {
      StockLimitDialog.show(
        context,
        stockCount: variant.stock,
        currentQty: existingQty,
      );
      return;
    }
    cartCubit.addToCart(variant, widget.product, 1);
    HapticFeedback.mediumImpact();
  }
}

class _ImageStage extends StatelessWidget {
  final ProductModel product;
  final _VariantController controller;

  const _ImageStage({required this.product, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ProductVariantModel?>(
      valueListenable: controller.currentVariant,
      builder: (_, variant, __) {
        final imageUrl = variant?.imageUrl?.isNotEmpty == true
            ? variant!.imageUrl!
            : product.image;
        return Hero(
          tag: 'product_image_${product.id}_${variant?.id ?? "base"}',
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.96, end: 1.0).animate(anim),
                child: child,
              ),
            ),
            child: CachedNetworkImage(
              key: ValueKey(imageUrl),
              imageUrl: imageUrl,
              fit: BoxFit.contain,
              alignment: Alignment.center,
              placeholder: (_, __) => const _ImagePlaceholder(),
              errorWidget: (_, __, ___) => const _ImageError(),
            ),
          ),
        );
      },
    );
  }
}

class _CartButton extends StatefulWidget {
  final VoidCallback onTap;
  const _CartButton({required this.onTap});

  @override
  State<_CartButton> createState() => _CartButtonState();
}

class _CartButtonState extends State<_CartButton>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final buttonBgColor = isDark
        ? const Color(0xFFF1F5F9)
        : const Color(0xFF0F172A);
    final iconColor = isDark
        ? const Color(0xFF0F172A)
        : const Color(0xFFF1F5F9);

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _pressed = true);
        HapticFeedback.selectionClick();
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.90 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: _pressed
                ? buttonBgColor.withValues(alpha: 0.85)
                : buttonBgColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: buttonBgColor.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: FaIcon(
              FontAwesomeIcons.cartPlus,
              size: 22,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _VariantController {
  final ProductModel product;
  final ValueNotifier<Map<String, String>> selectedAttributes = ValueNotifier(
    {},
  );
  final ValueNotifier<ProductVariantModel?> currentVariant = ValueNotifier(
    null,
  );
  late final Map<String, List<String>> attributeOptions;

  _VariantController(this.product) {
    attributeOptions = _computeOptions();
    _initDefaults();
    _updateVariant();
  }

  void _initDefaults() {
    final active = product.variants.where((v) => v.isActive).toList();
    if (active.isEmpty) return;
    final first = active.first;
    final keys = product.attributeConfig;
    final init = <String, String>{};
    if (keys.isNotEmpty) {
      for (final k in keys) {
        if (first.attributes.containsKey(k)) {
          init[k] = first.attributes[k].toString();
        }
      }
    } else {
      first.attributes.forEach((k, v) => init[k] = v.toString());
    }
    selectedAttributes.value = init;
  }

  Map<String, List<String>> _computeOptions() {
    final Map<String, List<String>> opts = {};
    for (final v in product.variants) {
      if (!v.isActive) continue;
      v.attributes.forEach((k, val) {
        opts.putIfAbsent(k, () => []);
        final s = val.toString();
        if (!opts[k]!.contains(s)) opts[k]!.add(s);
      });
    }
    return opts;
  }

  void updateAttribute(String key, String val) {
    if (selectedAttributes.value[key] == val) return;
    HapticFeedback.selectionClick();
    final next = Map<String, String>.from(selectedAttributes.value)
      ..[key] = val;
    selectedAttributes.value = next;
    _updateVariant();
  }

  void _updateVariant() {
    final sel = selectedAttributes.value;
    final match = product.variants.where((v) {
      if (!v.isActive) return false;
      return sel.entries.every(
        (e) => v.attributes[e.key]?.toString() == e.value,
      );
    }).firstOrNull;
    currentVariant.value =
        match ?? product.variants.where((v) => v.isActive).firstOrNull;
  }

  void dispose() {
    selectedAttributes.dispose();
    currentVariant.dispose();
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();
  @override
  Widget build(BuildContext context) => Center(
    child: SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(
        strokeWidth: 1.2,
        valueColor: AlwaysStoppedAnimation(
          Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
        ),
      ),
    ),
  );
}

class _ImageError extends StatelessWidget {
  const _ImageError();
  @override
  Widget build(BuildContext context) => Center(
    child: Icon(
      Icons.image_not_supported_outlined,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      size: 48,
    ),
  );
}
