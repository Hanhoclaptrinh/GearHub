import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/src/shared/models/product_model.dart';
import 'package:mobile/src/features/product_detail/presentation/pages/product_detail_page.dart';
import 'package:mobile/src/core/utils/formatter_utils.dart';

class VaultCard extends StatefulWidget {
  final ProductModel product;
  final int index;
  final ValueNotifier<double> scrollProgressNotifier;

  const VaultCard({
    super.key,
    required this.product,
    required this.index,
    required this.scrollProgressNotifier,
  });

  @override
  State<VaultCard> createState() => _VaultCardState();
}

class _VaultCardState extends State<VaultCard> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    HapticFeedback.lightImpact();
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 900),
        reverseTransitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: ProductDetailPage(product: widget.product),
          );
        },
      ),
    );
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.maxHeight;
        final maxWidth = constraints.maxWidth;

        return GestureDetector(
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          behavior: HitTestBehavior.opaque,
          child: AnimatedScale(
            scale: _isPressed ? 0.98 : 1.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutQuart,
            child: SizedBox(
              width: maxWidth,
              height: maxHeight,
              child: ValueListenableBuilder<double>(
                valueListenable: widget.scrollProgressNotifier,
                builder: (context, scrollProgress, child) {
                  final absProgress = scrollProgress.abs();
                  final productY = scrollProgress * 100;
                  final atmosphereY = scrollProgress * 150;
                  final typoY = scrollProgress * 60;

                  final opacity = (1.0 - absProgress * 1.5).clamp(0.0, 1.0);
                  final focusScale = (1.0 - absProgress * 0.08).clamp(
                    0.92,
                    1.0,
                  );

                  return Stack(
                    children: [
                      _buildStudioEnvironment(maxWidth, atmosphereY, opacity),

                      Positioned(
                        top: maxHeight * 0.1,
                        right: -maxWidth * 0.1,
                        child: Opacity(
                          opacity: opacity * 0.02,
                          child: Transform.translate(
                            offset: Offset(typoY * 2.0, typoY),
                            child: Text(
                              (widget.index + 1).toString().padLeft(2, '0'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 320,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -20,
                              ),
                            ),
                          ),
                        ),
                      ),

                      _buildGroundingShadow(
                        maxWidth,
                        maxHeight,
                        opacity,
                        productY,
                      ),

                      Center(
                        child: Transform.translate(
                          offset: Offset(0, -productY),
                          child: Transform.scale(
                            scale: focusScale,
                            child: Opacity(
                              opacity: opacity,
                              child: Hero(
                                tag: 'vault_premium_card_${widget.product.id}',
                                child: CachedNetworkImage(
                                  imageUrl: widget.product.image,
                                  fit: BoxFit.contain,
                                  height: maxHeight * 0.45,
                                  filterQuality: FilterQuality.high,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      _buildEditorialLayout(
                        maxHeight,
                        maxWidth,
                        opacity,
                        typoY,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStudioEnvironment(
    double width,
    double parallaxY,
    double opacity,
  ) {
    return Positioned.fill(
      child: Opacity(
        opacity: opacity,
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0D0D0D), Color(0xFF050505)],
                ),
              ),
            ),
            Transform.translate(
              offset: Offset(width * 0.2, parallaxY * 0.4),
              child: Container(
                width: width * 1.6,
                height: width * 1.6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-0.35, -0.35),
                    colors: [
                      const Color(0xFF1E1E1E).withValues(alpha: 0.5),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.75],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroundingShadow(
    double width,
    double height,
    double opacity,
    double parallaxY,
  ) {
    return Positioned(
      bottom: height * 0.28,
      left: 0,
      right: 0,
      child: Opacity(
        opacity: opacity * 0.5,
        child: Transform.translate(
          offset: Offset(0, -parallaxY),
          child: Center(
            child: Container(
              width: width * 0.65,
              height: 24,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.9),
                    blurRadius: 45,
                    spreadRadius: 12,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditorialLayout(
    double height,
    double width,
    double opacity,
    double parallaxY,
  ) {
    return Stack(
      children: [
        Positioned(
          top: height * 0.08,
          left: 32,
          child: Opacity(
            opacity: opacity * 0.6,
            child: Transform.translate(
              offset: Offset(0, -parallaxY * 0.75),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'KHOẢNG LẶNG ${(widget.index + 1)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(width: 48, height: 1.2, color: Colors.white24),
                ],
              ),
            ),
          ),
        ),

        Positioned(
          bottom: height * 0.12,
          left: 32,
          right: 140,
          child: Opacity(
            opacity: opacity,
            child: Transform.translate(
              offset: Offset(0, -parallaxY * 1.1),
              child: Text(
                widget.product.baseName.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.w200,
                  letterSpacing: -1.5,
                  height: 0.9,
                ),
              ),
            ),
          ),
        ),

        Positioned(
          bottom: height * 0.12,
          right: 32,
          child: Opacity(
            opacity: opacity * 0.75,
            child: Transform.translate(
              offset: Offset(0, -parallaxY * 0.85),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'GIÁ TRỊ',
                    style: TextStyle(
                      color: Colors.white24,
                      fontSize: 7,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.product.price == 0
                        ? 'LIÊN HỆ'
                        : formatVND(widget.product.price),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
