import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'hero_card.dart';
import '../../domain/models/hero_product.dart';

class HeroSection extends StatefulWidget {
  const HeroSection({super.key});

  @override
  State<HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<HeroSection> {
  late final PageController _pageController;
  // bien lang nghe su thay doi cua page
  final ValueNotifier<double> _pageOffset = ValueNotifier<double>(0.0);

  final List<HeroProduct> _products = [
    HeroProduct(
      name: 'PS5 Controller',
      tagline: 'Precision control, immersive haptics.',
      image: 'assets/images/hero1.png',
      gradient: const [Color(0xFFE0E7FF), Color(0xFFC7D2FE)],
    ),
    HeroProduct(
      name: 'AirPods Max',
      tagline: 'High-fidelity audio, ultimate comfort.',
      image: 'assets/images/hero2.png',
      gradient: const [Color(0xFFE2E8F0), Color(0xFFCBD5E1)],
    ),
    HeroProduct(
      name: 'ASUS ROG Strix PC',
      tagline: 'Ultimate performance, gaming unleashed.',
      image: 'assets/images/hero3.png',
      gradient: const [Color(0xFFCCFBFE), Color(0xFF90E0EF)],
    ),
    HeroProduct(
      name: 'Apple Vision Pro',
      tagline: 'The era of spatial computing.',
      image: 'assets/images/hero4.png',
      gradient: const [Color(0xFFF5F3FF), Color(0xFFDDD6FE)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    const int initialPage = 5000; // fake infinite carousel
    _pageController = PageController(
      viewportFraction: 0.85, // moi card chiem 85% man hinh
      initialPage: initialPage,
    );
    _pageOffset.value = initialPage
        .toDouble(); // lang nghe su thay doi cua page -> dong bo voi indicator
    _pageController.addListener(_updateOffset); // lang nghe khi swipe
  }

  void _updateOffset() {
    // check pageview da duoc cho vao UI chua - tranh crash app
    if (_pageController.hasClients) {
      // cap nhat vi tri cua page theo realtime
      // update lien tuc theo tung pixel scroll
      _pageOffset.value = _pageController.page ?? 0.0;
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_updateOffset);
    _pageController.dispose();
    _pageOffset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const int kLoopRange = 10000; // fake loop range (init o 5000 -> inf swipe)
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 500,
          child: PageView.builder(
            controller: _pageController,
            itemCount: kLoopRange,
            clipBehavior: Clip.none,
            onPageChanged: (_) =>
                HapticFeedback.lightImpact(), // rung nhe khi snap
            itemBuilder: (context, index) {
              // lay index that cua product
              // map lai so voi fake index - [d, a, b, c, d, a]
              final int actualIndex = index % _products.length;
              return ValueListenableBuilder<double>(
                valueListenable: _pageOffset,
                builder: (context, pageOffset, child) {
                  // tinh khoang cach giua index hien tai va index cua page
                  final double diff = index - pageOffset;
                  return HeroCard(product: _products[actualIndex], diff: diff);
                },
              );
            },
          ),
        ),
        const SizedBox(height: 30),
        _HeroPageIndicator(
          pageOffset: _pageOffset,
          itemCount: _products.length,
        ),
      ],
    );
  }
}

class _HeroPageIndicator extends StatelessWidget {
  final ValueNotifier<double> pageOffset;
  final int itemCount;

  const _HeroPageIndicator({required this.pageOffset, required this.itemCount});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: pageOffset,
      builder: (context, offset, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(itemCount, (index) {
            final double diff = (index - (offset % itemCount)).abs();
            final double distance = diff > 0.5
                ? (diff - itemCount).abs()
                : diff;
            final double activeFactor = (1 - distance.clamp(0.0, 1.0));

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 4,
              width: 8 + (activeFactor * 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(
                  alpha: 0.3 + (activeFactor * 0.7),
                ),
                borderRadius: BorderRadius.circular(2),
                boxShadow: activeFactor > 0.5
                    ? [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 4,
                        ),
                      ]
                    : [],
              ),
            );
          }),
        );
      },
    );
  }
}
