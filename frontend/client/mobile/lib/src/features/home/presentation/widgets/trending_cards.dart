import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/src/shared/models/product_model.dart';
import 'package:mobile/src/shared/widgets/add_circle_button.dart';
import 'package:mobile/src/shared/widgets/trending_badge.dart';
import 'package:mobile/src/features/product_detail/presentation/pages/product_detail_page.dart';

// tall card
class TrendingCardLarge extends StatefulWidget {
  final ProductModel product;
  const TrendingCardLarge({super.key, required this.product});

  @override
  State<TrendingCardLarge> createState() => _TrendingCardLargeState();
}

class _TrendingCardLargeState extends State<TrendingCardLarge> {
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
                        TrendingBadge(tag: widget.product.tag ?? 'HOT'),
                        const SizedBox(height: 12),
                        Text(
                          widget.product.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.product.tagline,
                          style: const TextStyle(
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
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const AddCircleButton(dark: false),
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
class TrendingCardSmall extends StatefulWidget {
  final ProductModel product;
  const TrendingCardSmall({super.key, required this.product});

  @override
  State<TrendingCardSmall> createState() => _TrendingCardSmallState();
}

class _TrendingCardSmallState extends State<TrendingCardSmall> {
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
                          TrendingBadge(tag: widget.product.tag ?? ''),
                          const SizedBox(height: 4),
                          Text(
                            widget.product.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF0A0A0A),
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
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0A0A0A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const AddCircleButton(dark: true),
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
