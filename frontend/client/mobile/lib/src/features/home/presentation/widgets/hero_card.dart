import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile/src/shared/models/product_model.dart';
import 'package:mobile/src/features/product_detail/presentation/pages/product_detail_page.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/src/features/home/presentation/state/home_cubit.dart';
import 'package:mobile/src/features/home/presentation/state/home_state.dart';
import '../../domain/entities/hero_product_entity.dart';

const _kBg = Color(0xFF080810);
const _kSurface = Color(0xFF0C0C18);
const _kBorder = Color(0xFF1A1A2E);
const _kLine = Color(0xFF20203A);
const _kWhite = Color(0xFFF0F0F8);
const _kMuted = Color(0xFF4A4A6A);
const _kGold = Color(0xFFD4A843);
const _kGoldDim = Color(0xFF1A1200);

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
    final double scale = (1 - diff.abs() * 0.10).clamp(0.8, 1.0);
    final String heroTag = diff.abs() < 0.5
        ? 'product_${product.id}'
        : 'product_${product.id}_$index';

    return Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateY(diff * -0.2)
        ..scale(scale),
      alignment: FractionalOffset.center,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          final state = context.read<HomeCubit>().state;
          ProductModel? fullProduct;
          if (state is HomeLoaded) {
            fullProduct = state.newArrivals.where((p) => p.id == product.id).firstOrNull ??
                state.vaultProducts.where((p) => p.id == product.id).firstOrNull;
          }
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProductDetailPage(
                product: fullProduct ?? ProductModel(
                  id: product.id,
                  name: product.name,
                  tagline: product.tagline,
                  price: 0,
                  image: product.image,
                  description: product.description,
                ),
              ),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: _kBorder, width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.50),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
              if (diff.abs() < 0.3)
                BoxShadow(
                  color: _kGold.withValues(alpha: 0.06),
                  blurRadius: 30,
                  spreadRadius: 4,
                ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // l1 - background
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_kBg, _kSurface],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),

              // l2 - dot grid texture
              Positioned.fill(
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.35,
                    child: CustomPaint(painter: GridPainter()),
                  ),
                ),
              ),

              // l3 - radial glow
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0.4, -0.4),
                        radius: 1.1,
                        colors: [
                          Colors.white.withValues(alpha: 0.07),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // l4 - corner marks
              const Positioned(
                top: 20,
                left: 20,
                child: _CornerMark(flip: false, flipV: false),
              ),
              const Positioned(
                top: 20,
                right: 20,
                child: _CornerMark(flip: true, flipV: false),
              ),
              const Positioned(
                bottom: 100,
                left: 20,
                child: _CornerMark(flip: false, flipV: true),
              ),
              const Positioned(
                bottom: 100,
                right: 20,
                child: _CornerMark(flip: true, flipV: true),
              ),

              // l5 - title & accent line
              Positioned(
                top: 44,
                left: 36,
                right: 36,
                child: Transform.translate(
                  offset: Offset((diff * -60).clamp(-60.0, 60.0), 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'FEATURED',
                            style: TextStyle(
                              color: _kMuted,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.6,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            '//',
                            style: TextStyle(
                              color: Color(0xFF2A2A45),
                              fontSize: 9,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            product.id.length > 8
                                ? product.id
                                      .substring(product.id.length - 8)
                                      .toUpperCase()
                                : product.id.toUpperCase(),
                            style: const TextStyle(
                              color: _kGold,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // prod name
                      Text(
                        product.name.toUpperCase(),
                        style: const TextStyle(
                          color: _kWhite,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            height: 2,
                            width: 32,
                            decoration: BoxDecoration(
                              color: _kGold,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            height: 2,
                            width: 10,
                            decoration: BoxDecoration(
                              color: _kGold.withValues(alpha: 0.30),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // l6 - prod img
              Positioned.fill(
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
                                placeholder: (_, __) => const SizedBox.shrink(),
                                errorWidget: (_, __, ___) => const Icon(
                                  Icons.broken_image_outlined,
                                  size: 40,
                                  color: _kMuted,
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

              // l7 - bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 22),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.28),
                        border: const Border(
                          top: BorderSide(color: _kBorder, width: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
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
                                    style: const TextStyle(
                                      color: _kMuted,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.1,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.fade,
                                    softWrap: false,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: List.generate(
                                      4,
                                      (i) => Container(
                                        width: i == 0 ? 16 : 6,
                                        height: 1,
                                        margin: const EdgeInsets.only(right: 3),
                                        color: _kLine,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),

                          const _CTAButton(),
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
}

// CTA button
class _CTAButton extends StatelessWidget {
  const _CTAButton();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
    decoration: BoxDecoration(
      color: _kGoldDim,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _kGold.withValues(alpha: 0.35), width: 0.5),
    ),
    child: const Text(
      'KHÁM PHÁ',
      style: TextStyle(
        color: _kGold,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      ),
    ),
  );
}

// corner mark
class _CornerMark extends StatelessWidget {
  final bool flip, flipV;
  const _CornerMark({required this.flip, required this.flipV});

  @override
  Widget build(BuildContext context) => Transform.scale(
    scaleX: flip ? -1 : 1,
    scaleY: flipV ? -1 : 1,
    child: CustomPaint(size: const Size(14, 14), painter: _CornerPainter()),
  );
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF252538)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    canvas.drawLine(Offset(0, size.height), const Offset(0, 0), paint);
    canvas.drawLine(const Offset(0, 0), Offset(size.width, 0), paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// hieu ung di chuyen len xuong
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
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (_, child) => Transform.translate(
      offset: Offset(0, 12 * Curves.easeInOut.transform(_controller.value)),
      child: child,
    ),
    child: widget.child,
  );
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A1A2E)
      ..strokeWidth = 0.4;

    for (double x = 0; x <= size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
