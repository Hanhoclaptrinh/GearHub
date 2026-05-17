import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/src/core/utils/formatter_utils.dart';
import 'package:mobile/src/shared/models/product_model.dart';
import 'package:mobile/src/shared/models/product_variant_model.dart';
import 'package:mobile/src/features/cart/presentation/state/cart_cubit.dart';
import 'package:mobile/src/features/home/presentation/state/home_cubit.dart';
import 'package:mobile/src/features/product_detail/presentation/pages/product_detail_page.dart';
import 'package:mobile/src/shared/widgets/color_bubble_selector.dart';
import 'package:mobile/src/shared/widgets/stock_limit_dialog.dart';
import 'package:mobile/src/core/theme/app_colors.dart';

class LargeProductCard extends StatefulWidget {
  final ProductModel product;
  const LargeProductCard({super.key, required this.product});

  @override
  State<LargeProductCard> createState() => _LargeProductCardState();
}

class _LargeProductCardState extends State<LargeProductCard>
    with SingleTickerProviderStateMixin {
  late final _VariantController _ctrl;

  // press-to-scale for the whole card tapped
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
      end: 0.984,
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
    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) {
        _pressCtrl.reverse();
        _navigateToDetail(context);
      },
      onTapCancel: () => _pressCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _pressScale,
        builder: (_, child) =>
            Transform.scale(scale: _pressScale.value, child: child),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.cardBorder, width: 0.8),
            boxShadow: [
              BoxShadow(
                color: AppColors.ctaPrimaryText.withValues(alpha: 0.35),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
              // subtle inner top highlight
              BoxShadow(
                color: AppColors.textPrimary.withValues(alpha: 0.025),
                blurRadius: 0,
                spreadRadius: 0,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // img
                _ImageStage(product: widget.product, controller: _ctrl),

                // content
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // prd name
                      Text(
                        widget.product.baseName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // variant selectors
                      ..._ctrl.attributeOptions.entries.map((entry) {
                        final k = entry.key;
                        final vals = entry.value;
                        final isColor =
                            k.toLowerCase().contains('color') ||
                            k.toLowerCase().contains('màu');
                        return Padding(
                          padding: EdgeInsets.only(bottom: isColor ? 20 : 14),
                          child: ValueListenableBuilder<Map<String, String>>(
                            valueListenable: _ctrl.selectedAttributes,
                            builder: (_, selected, __) {
                              if (isColor) {
                                return ColorBubbleSelector(
                                  product: widget.product,
                                  attributeKey: k,
                                  selectedValue: selected[k],
                                  onSelected: (val) =>
                                      _ctrl.updateAttribute(k, val),
                                );
                              }
                              return _ChipRow(
                                options: vals,
                                selectedVal: selected[k],
                                onSelected: (val) =>
                                    _ctrl.updateAttribute(k, val),
                              );
                            },
                          ),
                        );
                      }),

                      // price + CTA
                      _PriceCtaRow(
                        controller: _ctrl,
                        product: widget.product,
                        onCartTap: () => _handleAddToCart(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
    HapticFeedback.heavyImpact();
  }
}

class _ImageStage extends StatelessWidget {
  final ProductModel product;
  final _VariantController controller;

  const _ImageStage({required this.product, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, 0.2),
                  radius: 0.9,
                  colors: [
                    AppColors.brandBlue.withValues(alpha: 0.07),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // img
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: ValueListenableBuilder<ProductVariantModel?>(
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
                          scale: Tween<double>(
                            begin: 0.96,
                            end: 1.0,
                          ).animate(anim),
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
              ),
            ),
          ),

          // badge
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.textPrimary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: AppColors.textPrimary.withValues(alpha: 0.10),
                  width: 0.5,
                ),
              ),
              child: const Text(
                'NEW',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSlate,
                  letterSpacing: 2.0,
                ),
              ),
            ),
          ),

          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 60,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, AppColors.cardSurface],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceCtaRow extends StatelessWidget {
  final _VariantController controller;
  final ProductModel product;
  final VoidCallback onCartTap;

  const _PriceCtaRow({
    required this.controller,
    required this.product,
    required this.onCartTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: ValueListenableBuilder<ProductVariantModel?>(
            valueListenable: controller.currentVariant,
            builder: (_, variant, __) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product.hasPriceRange)
                    const Text(
                      'Giá từ',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textDim,
                        letterSpacing: 0.3,
                      ),
                    ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      formatVND(variant?.price ?? product.basePrice),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brandYellow,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(width: 16),

        _CartButton(onTap: onCartTap),
      ],
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
        scale: _pressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          decoration: BoxDecoration(
            color: _pressed
                ? AppColors.textPrimary.withValues(alpha: 0.88)
                : AppColors.textPrimary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: _pressed
                ? []
                : [
                    BoxShadow(
                      color: AppColors.textPrimary.withValues(alpha: 0.12),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_shopping_cart_rounded,
                size: 15,
                color: AppColors.ctaPrimaryText,
              ),
              SizedBox(width: 8),
              Text(
                'Thêm vào giỏ',
                style: TextStyle(
                  color: AppColors.ctaPrimaryText,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChipRow extends StatelessWidget {
  final List<String> options;
  final String? selectedVal;
  final Function(String) onSelected;

  const _ChipRow({
    required this.options,
    this.selectedVal,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: options.map((val) {
        final isSelected = selectedVal == val;
        return GestureDetector(
          onTap: () => onSelected(val),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.textPrimary.withValues(alpha: 0.10)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? AppColors.textPrimary.withValues(alpha: 0.28)
                    : AppColors.cardBorder,
                width: isSelected ? 0.8 : 0.6,
              ),
            ),
            child: Text(
              val,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.textPrimary : AppColors.textSlate,
                letterSpacing: 0.3,
              ),
            ),
          ),
        );
      }).toList(),
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
  Widget build(BuildContext context) => const Center(
    child: SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(
        strokeWidth: 1.2,
        valueColor: AlwaysStoppedAnimation(Color(0x40FFFFFF)),
      ),
    ),
  );
}

class _ImageError extends StatelessWidget {
  const _ImageError();
  @override
  Widget build(BuildContext context) => const Center(
    child: Icon(
      Icons.image_not_supported_outlined,
      color: AppColors.textDim,
      size: 48,
    ),
  );
}
