import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/core/utils/formatter_utils.dart';
import 'package:mobile/src/shared/models/product_model.dart';
import 'package:mobile/src/features/product_detail/presentation/pages/product_detail_page.dart';
import 'package:mobile/src/shared/widgets/rating_badge.dart';

const _kDark = Color(0xFF0F0F14);
const _kDarkAlt = Color(0xFF13131B);
const _kBorder = Color(0xFF1D1D27);
const _kGold = Color(0xFFCBA97A);
const _kGoldDim = Color(0xFF1C1508);
const _kWhite = Color(0xFFECECF4);
const _kMuted = Color(0xFF474760);
const _kCream = Color(0xFFF2ECE2);
const _kCreamBdr = Color(0xFFE2D9CC);
const _kDarkTxt = Color(0xFF0F0F13);
const _kMutedTxt = Color(0xFF8A7F72);

class _Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _Pressable({required this.child, this.onTap});

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 85),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.965,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => _ctrl.forward(),
    onTapUp: (_) => _ctrl.reverse(),
    onTapCancel: _ctrl.reverse,
    onTap: () {
      HapticFeedback.lightImpact();
      widget.onTap?.call();
    },
    child: ScaleTransition(scale: _scale, child: widget.child),
  );
}

class _AddBtn extends StatelessWidget {
  const _AddBtn();

  @override
  Widget build(BuildContext context) => Container(
    width: 34,
    height: 34,
    decoration: BoxDecoration(
      color: _kGoldDim,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _kGold.withValues(alpha: 0.28), width: 0.5),
    ),
    child: const Icon(LucideIcons.plus, color: _kGold, size: 15),
  );
}

Widget _img(ProductModel p, {Color errorColor = _kMuted}) {
  if (p.image.startsWith('http')) {
    return CachedNetworkImage(
      imageUrl: p.image,
      fit: BoxFit.contain,
      placeholder: (_, __) => const SizedBox.shrink(),
      errorWidget: (_, __, ___) =>
          Icon(LucideIcons.imageOff, color: errorColor, size: 22),
    );
  }
  return Image.asset(p.image, fit: BoxFit.contain);
}

void _push(BuildContext context, ProductModel p) => Navigator.of(
  context,
).push(MaterialPageRoute(builder: (_) => ProductDetailPage(product: p)));

// tall card
class TopRatedCardLarge extends StatelessWidget {
  final ProductModel product;
  const TopRatedCardLarge({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      onTap: () => _push(context, product),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_kDarkAlt, _kDark],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _kBorder, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RatingBadge(rating: product.averageRating),
                      const SizedBox(height: 12),
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _kWhite,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Center(
                    child: Hero(
                      tag: 'product_${product.id}',
                      child: _img(product),
                    ),
                  ),
                ),

                // price
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formatVND(product.price),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: _kWhite,
                        ),
                      ),
                      const _AddBtn(),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// small card
class TopRatedCardSmall extends StatelessWidget {
  final ProductModel product;
  const TopRatedCardSmall({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      onTap: () => _push(context, product),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _kDarkAlt,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _kBorder, width: 0.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: 'product_${product.id}',
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
                        child: _img(product),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: RatingBadge(
                        rating: product.averageRating,
                        isCompact: true,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: _kBorder, width: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _kWhite,
                        letterSpacing: -0.2,
                        height: 1.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formatVND(product.price),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: _kGold,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const _AddBtn(),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// wide card
// chi duoc dung khi co >= 4 sp
class TopRatedCardWide extends StatefulWidget {
  final ProductModel product;
  const TopRatedCardWide({required this.product, super.key});

  @override
  State<TopRatedCardWide> createState() => TopRatedCardWideState();
}

class TopRatedCardWideState extends State<TopRatedCardWide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 85),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) => _ctrl.reverse(),
      onTapCancel: _ctrl.reverse,
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ProductDetailPage(product: p)),
        );
      },
      child: ScaleTransition(
        scale: _scale,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _kCream,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _kCreamBdr, width: 0.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          (p.tagline).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: _kMutedTxt,
                            letterSpacing: 1.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          p.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _kDarkTxt,
                            height: 1.25,
                            letterSpacing: -0.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 22,
                          height: 1.5,
                          decoration: BoxDecoration(
                            color: _kGold,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          formatVND(p.price),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: _kDarkTxt,
                            letterSpacing: -0.5,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(
                  width: 90,
                  child: p.image.startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: p.image,
                          fit: BoxFit.contain,
                          placeholder: (_, __) => const SizedBox.shrink(),
                          errorWidget: (_, __, ___) => const Icon(
                            LucideIcons.imageOff,
                            color: _kMutedTxt,
                            size: 20,
                          ),
                        )
                      : Image.asset(p.image, fit: BoxFit.contain),
                ),

                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _kDarkTxt,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      LucideIcons.arrowRight,
                      color: _kCream,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
