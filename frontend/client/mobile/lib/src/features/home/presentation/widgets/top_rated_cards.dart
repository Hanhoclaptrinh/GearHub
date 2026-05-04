import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/core/utils/formatter_utils.dart';
import 'package:mobile/src/shared/models/product_model.dart';
import 'package:mobile/src/features/product_detail/presentation/pages/product_detail_page.dart';
import 'package:mobile/src/shared/widgets/rating_badge.dart';

const _kMuted = Color(0xFF474760);

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

class TopRatedPremiumCard extends StatelessWidget {
  final ProductModel product;
  const TopRatedPremiumCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      onTap: () => _push(context, product),
      child: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(240, 245, 246, 248),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(child: _img(product)),
                    ),
                    Positioned(
                      top: 14,
                      left: 14,
                      child: RatingBadge(
                        rating: product.averageRating,
                        isCompact: true,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0A0A0F),
                        height: 1.25,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.shoppingBag,
                          size: 12,
                          color: Color(0xFF8A8A9E),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Đã bán ${formatCompactNumber(product.soldCount)}',
                          style: const TextStyle(
                            color: Color(0xFF8A8A9E),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      formatVND(product.price),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0A0A0F),
                        letterSpacing: -0.3,
                      ),
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
