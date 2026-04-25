import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/src/core/di/injection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../state/home_cubit.dart';
import '../state/home_state.dart';
import 'hero_card.dart';

class HeroSection extends StatefulWidget {
  const HeroSection({super.key});

  @override
  State<HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<HeroSection> {
  late final PageController _pageController;
  // bien lang nghe su thay doi cua page
  final ValueNotifier<double> _pageOffset = ValueNotifier<double>(0.0);
  late final HomeCubit _homeCubit;

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
    _homeCubit = getIt<HomeCubit>()..fetchFeaturedProducts();
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
    _homeCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const int kLoopRange = 10000; // fake loop range (init o 5000 -> inf swipe)
    return BlocProvider.value(
      value: _homeCubit,
      child: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          if (state is HomeLoading || state is HomeInitial) {
            return const SizedBox(
              height: 500,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (state is HomeError) {
            return SizedBox(
              height: 500,
              child: Center(
                child: Text('Error loading products: ${state.message}'),
              ),
            );
          }

          final products = (state as HomeLoaded).featuredProducts;
          if (products.isEmpty) {
            return const SizedBox.shrink();
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 500,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: kLoopRange,
                  clipBehavior: Clip.none,
                  onPageChanged: (_) => HapticFeedback.lightImpact(),
                  itemBuilder: (context, index) {
                    final int actualIndex = index % products.length;
                    return ValueListenableBuilder<double>(
                      valueListenable: _pageOffset,
                      builder: (context, pageOffset, child) {
                        // tinh khoang cach giua index hien tai va index cua page
                        final double diff = index - pageOffset;
                        return HeroCard(
                          product: products[actualIndex],
                          diff: diff,
                          index: index,
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 30),
              _HeroPageIndicator(
                pageOffset: _pageOffset,
                itemCount: products.length,
              ),
            ],
          );
        },
      ),
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
