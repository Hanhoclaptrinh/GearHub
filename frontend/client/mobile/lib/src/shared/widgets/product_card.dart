import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/core/utils/currency_format.dart';
import 'package:mobile/src/shared/models/product_model.dart';

const _kSurface = Color(0xFF13131A);
const _kBorder = Color(0xFF1C1C26);
const _kText = Color(0xFFEDEDF5);
const _kMuted = Color(0xFF50506A);
const _kAccent = Color(0xFF7EE8C0);
const _kAccentBg = Color(0xFF0C1F1A);

class ProductCard extends StatefulWidget {
  final ProductModel product;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onAddToCart,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard>
    with TickerProviderStateMixin {
  late final AnimationController _press;
  late final AnimationController _breathe;
  late final Animation<double> _scale;
  late final Animation<double> _breath;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _press, curve: Curves.easeOut));

    _breathe = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _breath = CurvedAnimation(parent: _breathe, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _press.dispose();
    _breathe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _press.forward(),
      onTapUp: (_) => _press.reverse(),
      onTapCancel: _press.reverse,
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap?.call();
      },
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedBuilder(
          animation: _breath,
          builder: (context, child) => Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 270),
            decoration: BoxDecoration(
              color: _kSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                width: 1,
                color: Color.lerp(
                  _kBorder,
                  _kAccent.withValues(alpha: 0.4),
                  _breath.value,
                )!,
              ),
              boxShadow: [
                BoxShadow(
                  color: _kAccent.withValues(
                    alpha: 0.03 + 0.05 * _breath.value,
                  ),
                  blurRadius: 20 + 10 * _breath.value,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: child,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // main img
                AspectRatio(
                  aspectRatio: 1.0, // 1:1 ratio
                  child: _ImageSection(
                    product: widget.product,
                    breath: _breath,
                  ),
                ),
                Container(height: 1, width: double.infinity, color: _kBorder),
                _ContentSection(
                  product: widget.product,
                  breath: _breath,
                  onAddToCart: widget.onAddToCart,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ImageSection extends StatelessWidget {
  final ProductModel product;
  final Animation<double> breath;

  const _ImageSection({required this.product, required this.breath});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const CustomPaint(painter: _DotGridPainter()),
        AnimatedBuilder(
          animation: breath,
          builder: (_, __) => Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _kAccent.withValues(
                      alpha: 0.10 + 0.15 * breath.value,
                    ),
                    blurRadius: 40 + 20 * breath.value,
                    spreadRadius: 5 + 10 * breath.value,
                  ),
                ],
              ),
            ),
          ),
        ),

        // img with hero anim
        Hero(
          tag: 'product_${product.id}',
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _buildImage(),
          ),
        ),

        if (product.tag != null)
          Positioned(top: 12, left: 12, child: _TagBadge(label: product.tag!)),
      ],
    );
  }

  Widget _buildImage() {
    final url = product.image;
    if (url.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.contain,
        errorWidget: (_, __, ___) =>
            const Icon(LucideIcons.imageOff, color: _kMuted, size: 32),
      );
    }
    return Image.asset(url, fit: BoxFit.contain);
  }
}

class _ContentSection extends StatelessWidget {
  final ProductModel product;
  final Animation<double> breath;
  final VoidCallback? onAddToCart;

  const _ContentSection({
    required this.product,
    required this.breath,
    this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.name,
            style: const TextStyle(
              color: _kText,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.eye, size: 12, color: _kMuted),
                  const SizedBox(width: 4),
                  Text(
                    '${product.viewsCount} lượt xem',
                    style: const TextStyle(
                      color: _kMuted,
                      fontSize: 9,
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 1,
                    color: _kAccent.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 4),
                  Container(width: 4, height: 1, color: _kBorder),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'GIÁ BÁN',
                    style: TextStyle(
                      color: _kMuted,
                      fontSize: 8,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  AnimatedBuilder(
                    animation: breath,
                    builder: (_, __) => Text(
                      formatVND(product.price),
                      style: TextStyle(
                        color: Color.lerp(
                          _kAccent,
                          const Color(0xFFB8F5E2),
                          breath.value,
                        ),
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        height: 1,
                      ),
                    ),
                  ),
                ],
              ),

              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onAddToCart?.call();
                  print('add to cart');
                },
                child: AnimatedBuilder(
                  animation: breath,
                  builder: (_, __) => Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: _kAccentBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _kAccent.withValues(
                          alpha: 0.2 + 0.3 * breath.value,
                        ),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      LucideIcons.plus,
                      color: _kAccent,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TagBadge extends StatelessWidget {
  final String label;
  const _TagBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: _kAccentBg,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: _kAccent.withValues(alpha: 0.28), width: 0.5),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: _kAccent,
          fontSize: 8,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.9,
        ),
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  const _DotGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1C1C28)
      ..style = PaintingStyle.fill;

    const spacing = 13.0;
    const radius = 0.85;

    for (var x = spacing; x < size.width; x += spacing) {
      for (var y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter oldDelegate) => false;
}
