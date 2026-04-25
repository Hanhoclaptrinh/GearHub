import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile/src/shared/models/product.dart';
import 'package:mobile/src/features/product_detail/presentation/pages/product_detail_page.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/hero_product_entity.dart';

class HeroCard extends StatelessWidget {
  final HeroProductEntity product;
  final double diff;
  final int index;

  const HeroCard({
    super.key,
    required this.product,
    required this.diff,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final double scale = (1 - (diff.abs() * 0.1)).clamp(0.8, 1.0);
    // chi su dung hero tag goc cho item dang duoc hien thi chinh (center)
    // de tranh loi trung lap tag trong PageView vo tan
    final String heroTag = diff.abs() < 0.5
        ? 'product_${product.id}'
        : 'product_${product.id}_$index';

    return Transform(
      // chuyen doi ma tran 3d cho hinh 2d
      transform:
          Matrix4.identity() // tao ma tran goc
            ..setEntry(3, 2, 0.001) // tao do sau cho hinh anh (3d mode)
            ..rotateY(diff * -0.2) // xoay hinh anh theo chieu doc
            ..scale(scale),
      alignment: FractionalOffset.center,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ProductDetailPage(
                product: Product(
                  id: product.id,
                  name: product.name,
                  tagline: product.tagline,
                  price: 0,
                  image: product.image,
                  bgGradient: product.gradient,
                ),
              ),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(40)),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // l1 - background
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: product.gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),

              // l2 - radial glow
              // tao hieu ung sang toa tu tam ra ngoai
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0.5, -0.3),
                        radius: 1.2,
                        colors: [
                          Colors.white.withValues(alpha: 0.12),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // l3 - title
              Positioned(
                top: 40,
                left: 30,
                right: 30,
                // parallax title
                // khi di chuyen sang trai thi title di chuyen sang phai va nguoc lai
                child: Transform.translate(
                  offset: Offset((diff * -60).clamp(-60.0, 60.0), 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name.toUpperCase(),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: const Color(0xFF1E293B),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                      ),
                      const SizedBox(height: 6),
                      Container(height: 3, width: 40, color: Colors.cyanAccent),
                    ],
                  ),
                ),
              ),

              // l4 - image
              Positioned.fill(
                // khi di chuyen sang trai thi anh di chuyen sang trai va nguoc lai
                child: Transform.translate(
                  offset: Offset(
                    diff * 120 + product.imageOffset.dx,
                    product.imageOffset.dy,
                  ),
                  child: FloatingAnimation(
                    child: Center(
                      child: Hero(
                        tag: heroTag,
                        child: product.image.startsWith('http')
                            ? CachedNetworkImage(
                                imageUrl: product.image,
                                fit: BoxFit.contain,
                                width: 240,
                                filterQuality: FilterQuality.medium,
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                errorWidget: (context, url, error) =>
                                    const Icon(
                                      Icons.broken_image_outlined,
                                      size: 40,
                                      color: Colors.black12,
                                    ),
                              )
                            : Image.asset(
                                product.image,
                                fit: BoxFit.contain,
                                width: 240,
                              ),
                      ),
                    ),
                  ),
                ),
              ),

              // l5 - glass bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        border: const Border(
                          top: BorderSide(color: Colors.white10),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            // di chuyen sang trai khi keo sang phai
                            child: Transform.translate(
                              offset: Offset(
                                (diff * -20).clamp(-30.0, 30.0),
                                0,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    product.tagline,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w500,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          _buildCTA(context),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCTA(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Khám phá',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.black,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class FloatingAnimation extends StatefulWidget {
  final Widget child;
  const FloatingAnimation({super.key, required this.child});

  @override
  State<FloatingAnimation> createState() => _FloatingAnimationState();
}

class _FloatingAnimationState extends State<FloatingAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // hieu ung san pham di chuyen len xuong
        double translationY =
            12 * Curves.easeInOut.transform(_controller.value);
        return Transform.translate(
          offset: Offset(0, translationY),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 0.5;

    for (double i = 0; i <= size.width; i += 25) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i <= size.height; i += 25) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
