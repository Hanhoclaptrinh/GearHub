import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile/src/core/utils/formatter_utils.dart';
import 'package:mobile/src/features/product_detail/presentation/pages/product_detail_page.dart';
import '../state/home_cubit.dart';
import '../state/home_state.dart';

class RecommendedSection extends StatefulWidget {
  const RecommendedSection({super.key});

  @override
  State<RecommendedSection> createState() => _RecommendedSectionState();
}

class _RecommendedSectionState extends State<RecommendedSection> {
  late final PageController _pageController;
  double _currentPage = 5000.0;
  int _lastSnappedIndex = 5000;
  static const int _virtualItemCount = 10000;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 5000)
      ..addListener(() {
        setState(() {
          _currentPage = _pageController.page ?? 5000.0;
        });

        final snappedIndex = _currentPage.round();
        if (snappedIndex != _lastSnappedIndex) {
          HapticFeedback.selectionClick();
          _lastSnappedIndex = snappedIndex;
        }
      });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Color _getBrandColor(String? brandName) {
    if (brandName == null) return const Color(0xFF3B82F6);
    final name = brandName.toLowerCase();
    if (name.contains('keychron')) {
      return const Color(0xFFFFB300);
    } else if (name.contains('razer')) {
      return const Color(0xFF00FF66);
    } else if (name.contains('logitech')) {
      return const Color(0xFF00BFFF);
    } else if (name.contains('leopold')) {
      return const Color(0xFF4A90E2);
    } else if (name.contains('akko')) {
      return const Color(0xFFE056FD);
    } else if (name.contains('asus') ||
        name.contains('rog') ||
        name.contains('apple')) {
      return const Color(0xFF3B82F6);
    }
    return const Color(0xFF0076DF);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final glassBorder = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);

    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        if (state is! HomeLoaded || state.recommendedProducts.isEmpty) {
          return const SizedBox.shrink();
        }

        final products = state.recommendedProducts;
        final activeIndex = _currentPage.round() % products.length;
        final activeProduct = products[activeIndex];
        final activeBrandName = activeProduct.brandName ?? 'GEAR';
        final activeBrandColor = _getBrandColor(activeBrandName);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dành riêng cho bạn',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: -0.3,
                      height: 1.18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Được tinh chọn dựa trên sở thích mua sắm của bạn',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.55,
                      ),
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              height: 330,
              width: double.infinity,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double width = constraints.maxWidth;
                  final double cx = width / 2;

                  //tọa độ đĩa quay
                  const double rx = 125.0; //bán kính ngang
                  const double ry = 24.0; //bán kính dọc
                  const double cy = 230.0; //tâm đĩa

                  //tọa độ hình ảnh
                  const double imgCy = 110.0;
                  const double imgSize = 230.0;

                  //vị trí các thumbnail trên bục quay
                  final dialItems = List.generate(9, (offsetIndex) {
                    final int virtualIndex =
                        _currentPage.round() - 4 + offsetIndex;
                    final int actualProductIndex =
                        (virtualIndex % products.length + products.length) %
                        products.length;
                    final item = products[actualProductIndex];

                    final double diff = virtualIndex - _currentPage;
                    final double angle =
                        diff * (math.pi / 4.5); //khoảng cách các items

                    if (angle.abs() > math.pi / 2.1) return null;

                    final double x = cx + rx * math.sin(angle);
                    final double y = cy + ry * math.cos(angle);

                    final double scale = (1 - diff.abs() * 0.25).clamp(
                      0.6,
                      1.0,
                    );
                    final double opacity = (1 - diff.abs() * 0.6).clamp(
                      0.0,
                      1.0,
                    );
                    final bool isSelected = actualProductIndex == activeIndex;

                    const double size = 38;

                    final widget = Positioned(
                      left: x - (size / 2),
                      top: y - (size / 2),
                      child: Transform.scale(
                        scale: scale,
                        child: Opacity(
                          opacity: opacity,
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              _pageController.animateToPage(
                                virtualIndex,
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.decelerate,
                              );
                            },
                            child: Container(
                              width: size,
                              height: size,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E293B)
                                    : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? activeBrandColor
                                      : glassBorder,
                                  width: isSelected ? 1.5 : 0.8,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: isDark ? 0.2 : 0.03,
                                    ),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Padding(
                                  padding: const EdgeInsets.all(5.0),
                                  child: CachedNetworkImage(
                                    imageUrl: item.image,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );

                    return (y: y, widget: widget);
                  }).whereType<Record>().toList();

                  //z-inded cho dial
                  dialItems.sort(
                    (a, b) => (a as dynamic).y.compareTo((b as dynamic).y),
                  );
                  final showcaseImages = List.generate(3, (offsetIndex) {
                    final int virtualIndex =
                        _currentPage.round() - 1 + offsetIndex;
                    final int actualProductIndex =
                        (virtualIndex % products.length + products.length) %
                        products.length;
                    final item = products[actualProductIndex];

                    final double diff = virtualIndex - _currentPage;

                    //hình ảnh chính trượt theo trục x - ngang
                    final double x = cx + diff * (width * 0.7);
                    const double y = imgCy;

                    final double scale = (1 - diff.abs() * 0.15).clamp(
                      0.7,
                      1.0,
                    );
                    final double opacity = (1 - diff.abs() * 0.9).clamp(
                      0.0,
                      1.0,
                    );
                    final Matrix4 transformMatrix = Matrix4.identity()
                      ..scale(scale);

                    return Positioned(
                      left: x - (imgSize / 2),
                      top: y - (imgSize / 2),
                      child: Opacity(
                        opacity: opacity,
                        child: Transform(
                          transform: transformMatrix,
                          alignment: Alignment.center,
                          child: CachedNetworkImage(
                            imageUrl: item.image,
                            fit: BoxFit.contain,
                            width: imgSize,
                            height: imgSize,
                          ),
                        ),
                      ),
                    );
                  });

                  return Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      //watermark brand name
                      Positioned(
                        top: 0,
                        left: 24,
                        right: 24,
                        child: Container(
                          height: 90,
                          alignment: Alignment.center,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 500),
                              child: Text(
                                activeBrandName.toUpperCase(),
                                key: ValueKey<String>(activeBrandName),
                                style: GoogleFonts.outfit(
                                  fontSize: 84,
                                  fontWeight: FontWeight.w900,
                                  color: activeBrandColor.withValues(
                                    alpha: isDark ? 0.09 : 0.06,
                                  ),
                                  letterSpacing: 6.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      //glow effect
                      Positioned(
                        top: 30,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                activeBrandColor.withValues(
                                  alpha: isDark ? 0.26 : 0.16,
                                ),
                                activeBrandColor.withValues(alpha: 0.0),
                              ],
                              stops: const [0.2, 1.0],
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: CustomPaint(
                          painter: DialArcPainter(
                            cx: cx,
                            cy: cy,
                            rx: rx,
                            ry: ry,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.12)
                                : Colors.black.withValues(alpha: 0.07),
                          ),
                        ),
                      ),
                      //render hình ảnh trượt ngang
                      ...showcaseImages,
                      Positioned.fill(
                        child: PageView.builder(
                          controller: _pageController,
                          physics: const BouncingScrollPhysics(),
                          clipBehavior: Clip.none,
                          itemCount: _virtualItemCount,
                          itemBuilder: (context, index) {
                            final product = products[index % products.length];
                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ProductDetailPage(product: product),
                                  ),
                                );
                              },
                              child: Container(color: Colors.transparent),
                            );
                          },
                        ),
                      ),

                      //các thumbnail quay theo quỹ đạo
                      ...dialItems.map((e) => (e as dynamic).widget as Widget),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.0, 0.05),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Container(
                  key: ValueKey<String>(activeProduct.id),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: const BoxDecoration(color: Colors.transparent),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activeBrandName.toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: activeBrandColor,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Expanded(
                            child: Text(
                              activeProduct.baseName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            activeProduct.hasPriceRange
                                ? 'Từ ${formatVND(activeProduct.minPrice)}'
                                : formatVND(activeProduct.price),
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),

                      if (activeProduct.averageRating > 0 ||
                          activeProduct.tagline.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (activeProduct.averageRating > 0) ...[
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star_rounded,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.8),
                                    size: 15,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    activeProduct.averageRating.toStringAsFixed(
                                      1,
                                    ),
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ),

                              if (activeProduct.tagline.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                    vertical: 6.0,
                                  ),
                                  child: Container(
                                    width: 3,
                                    height: 3,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                ),
                            ],

                            if (activeProduct.tagline.isNotEmpty)
                              Expanded(
                                child: Text(
                                  activeProduct.tagline,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: theme.colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.6),
                                    height: 1.3,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class DialArcPainter extends CustomPainter {
  final double cx;
  final double cy;
  final double rx;
  final double ry;
  final Color color;

  DialArcPainter({
    required this.cx,
    required this.cy,
    required this.rx,
    required this.ry,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant DialArcPainter oldDelegate) {
    return oldDelegate.cx != cx ||
        oldDelegate.cy != cy ||
        oldDelegate.rx != rx ||
        oldDelegate.ry != ry ||
        oldDelegate.color != color;
  }
}
