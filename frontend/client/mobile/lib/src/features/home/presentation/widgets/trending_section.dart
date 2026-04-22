// trending_section.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/shared/models/product.dart';
import 'package:mobile/src/shared/widgets/section_header.dart';
import 'package:mobile/src/features/product_detail/presentation/pages/product_detail_page.dart';

enum TrendingBadgeType { hot, trending, newArrival }

class TrendingSection extends StatelessWidget {
  const TrendingSection({super.key});

  static const List<Product> _products = [
    Product(
      id: 't1',
      name: 'ROG Strix Helios II',
      tagline: '2.4k bought this week',
      price: 3000,
      image: 'assets/images/hero3.png',
      tag: 'HOT',
    ),
    Product(
      id: 't2',
      name: 'AirPods Max',
      tagline: 'Trending in Audio',
      price: 549,
      image: 'assets/images/hero2.png',
      tag: 'TRENDING',
    ),
    Product(
      id: 't3',
      name: 'DualSense Edge',
      tagline: 'Most wished in Gear',
      price: 199,
      image: 'assets/images/hero1.png',
      tag: 'NEW',
    ),
    Product(
      id: 't4',
      name: 'Logitech MX Master 3S',
      tagline: 'Most wished · Mice',
      price: 99,
      image: 'assets/images/mouse_product.png',
      tag: '',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Trending Now', actionText: 'See All'),
        const SizedBox(height: 20),
        // grid - 3 card ben tren 1 wide card ben duoi
        StaggeredGrid.count(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: [
            // tall card - left
            StaggeredGridTile.count(
              crossAxisCellCount: 1,
              mainAxisCellCount: 2,
              child: _TrendingCardLarge(product: _products[0]),
            ),
            // 2 small card - right
            StaggeredGridTile.count(
              crossAxisCellCount: 1,
              mainAxisCellCount: 1,
              child: _TrendingCardSmall(product: _products[1]),
            ),
            StaggeredGridTile.count(
              crossAxisCellCount: 1,
              mainAxisCellCount: 1,
              child: _TrendingCardSmall(product: _products[2]),
            ),
            // wide card - full width
            StaggeredGridTile.count(
              crossAxisCellCount: 2,
              mainAxisCellCount: 0.72,
              child: _TrendingCardWide(product: _products[3]),
            ),
          ],
        ),
      ],
    );
  }
}

// tall card
class _TrendingCardLarge extends StatefulWidget {
  final Product product;
  const _TrendingCardLarge({required this.product});

  @override
  State<_TrendingCardLarge> createState() => _TrendingCardLargeState();
}

class _TrendingCardLargeState extends State<_TrendingCardLarge> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductDetailPage(product: widget.product),
          ),
        );
      },
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 140),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D1A),
            borderRadius: BorderRadius.circular(26),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Color(0x4D8C64FF), Colors.transparent],
                    ),
                  ),
                ),
              ),
              // Content
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TrendingBadge(tag: widget.product.tag ?? 'HOT'),
                        const SizedBox(height: 12),
                        Text(
                          widget.product.name,
                          style: GoogleFonts.bodoniModa(
                            fontSize: 20,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.product.tagline,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: Colors.white38,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // img
                  Expanded(
                    child: Hero(
                      tag: 'product_${widget.product.id}',
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
                        child: Image.asset(
                          widget.product.image,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Color(0x12FFFFFF), width: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$${widget.product.price.toInt()}',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const _AddButton(dark: false),
                      ],
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
}

// small card
class _TrendingCardSmall extends StatefulWidget {
  final Product product;
  const _TrendingCardSmall({required this.product});

  @override
  State<_TrendingCardSmall> createState() => _TrendingCardSmallState();
}

class _TrendingCardSmallState extends State<_TrendingCardSmall> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductDetailPage(product: widget.product),
          ),
        );
      },
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 140),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.05),
              width: 0.5,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _TrendingBadge(tag: widget.product.tag ?? ''),
                          const SizedBox(height: 4),
                          Text(
                            widget.product.name,
                            style: GoogleFonts.bodoniModa(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF0A0A0A),
                              height: 1.25,
                            ),
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: -6,
                      bottom: -4,
                      child: Hero(
                        tag: 'product_${widget.product.id}',
                        child: SizedBox(
                          width: 80,
                          height: 80,
                          child: Image.asset(
                            widget.product.image,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 13),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0x09000000), width: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${widget.product.price.toInt()}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0A0A0A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const _AddButton(dark: true),
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
class _TrendingCardWide extends StatefulWidget {
  final Product product;
  const _TrendingCardWide({required this.product});

  @override
  State<_TrendingCardWide> createState() => _TrendingCardWideState();
}

class _TrendingCardWideState extends State<_TrendingCardWide> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.98),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductDetailPage(product: widget.product),
          ),
        );
      },
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 140),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFEDEAE2),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.product.tagline.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.black38,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.product.name,
                      style: GoogleFonts.bodoniModa(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF0A0A0A),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${widget.product.price.toInt()}',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0A0A0A),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 80,
                height: 70,
                child: Image.asset(widget.product.image, fit: BoxFit.contain),
              ),
              const SizedBox(width: 8),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.14),
                    width: 0.5,
                  ),
                ),
                child: const Icon(
                  LucideIcons.arrowRight,
                  size: 13,
                  color: Colors.black45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrendingBadge extends StatelessWidget {
  final String tag;
  const _TrendingBadge({required this.tag});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tag) {
      'HOT' => (const Color(0x2EFF6B5B), const Color(0xFFFF6B5B)),
      'TRENDING' => (const Color(0x263CC878), const Color(0xFF3CC878)),
      'NEW' => (const Color(0x2E6EB0FF), const Color(0xFF6EB0FF)),
      _ => (Colors.transparent, Colors.transparent),
    };

    if (tag.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            tag,
            style: GoogleFonts.inter(
              fontSize: 8,
              fontWeight: FontWeight.w900,
              color: fg,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final bool dark;
  const _AddButton({required this.dark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: dark ? 28 : 34,
      height: dark ? 28 : 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: dark
            ? const Color(0xFF0D0D1A)
            : Colors.white.withValues(alpha: 0.1),
        border: dark
            ? null
            : Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 0.5,
              ),
      ),
      child: Icon(
        LucideIcons.plus,
        size: dark ? 12 : 14,
        color: dark ? Colors.white : Colors.white70,
      ),
    );
  }
}
