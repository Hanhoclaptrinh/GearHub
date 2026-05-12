import 'package:flutter/material.dart';
import '../../../../shared/widgets/large_product_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../state/home_cubit.dart';
import '../state/home_state.dart';

class NewArrivalsSection extends StatefulWidget {
  const NewArrivalsSection({super.key});

  @override
  State<NewArrivalsSection> createState() => _NewArrivalsSectionState();
}

class _NewArrivalsSectionState extends State<NewArrivalsSection>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  final ValueNotifier<double> _scrollOffset = ValueNotifier(0.0);

  late final AnimationController _headerCtrl;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);
    _pageController.addListener(() {
      if (mounted) _scrollOffset.value = _pageController.page ?? 0.0;
    });

    _headerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _headerFade = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollOffset.dispose();
    _headerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        if (state is HomeLoading) return _buildSkeleton();
        if (state is! HomeLoaded || state.newArrivals.isEmpty) {
          return const SizedBox.shrink();
        }

        final products = state.newArrivals;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeTransition(
              opacity: _headerFade,
              child: SlideTransition(
                position: _headerSlide,
                child: _SectionHeader(count: products.length),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              height: 500,
              child: ValueListenableBuilder<double>(
                valueListenable: _scrollOffset,
                builder: (context, offset, _) {
                  return PageView.builder(
                    controller: _pageController,
                    clipBehavior: Clip.none,
                    itemCount: products.length,
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    itemBuilder: (context, index) {
                      final diff = (index - offset).abs().clamp(0.0, 1.0);
                      final scale = 1.0 - diff * 0.04;
                      final fadeV = 1.0 - diff * 0.35;
                      final translateY = diff * 10.0;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Transform.translate(
                          offset: Offset(0, translateY),
                          child: Transform.scale(
                            scale: scale,
                            alignment: Alignment.topCenter,
                            child: Opacity(
                              opacity: fadeV.clamp(0.0, 1.0),
                              child: LargeProductCard(product: products[index]),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            ValueListenableBuilder<double>(
              valueListenable: _scrollOffset,
              builder: (context, offset, _) {
                final current = offset.round();
                return _PageDots(
                  count: products.length,
                  currentPage: current,
                  scrollOffset: offset,
                );
              },
            ),

            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildSkeleton() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SkeletonBox(width: 100, height: 14, radius: 4),
              SizedBox(height: 12),
              _SkeletonBox(width: 240, height: 28, radius: 8),
            ],
          ),
        ),
        SizedBox(height: 24),
        SizedBox(
          height: 640,
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 1.2,
                valueColor: AlwaysStoppedAnimation(Color(0x30FFFFFF)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final int count;
  const _SectionHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Đón đầu kỷ nguyên\ncông nghệ mới',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.6,
              height: 1.18,
            ),
          ),
        ],
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  final int count;
  final int currentPage;
  final double scrollOffset;

  const _PageDots({
    required this.count,
    required this.currentPage,
    required this.scrollOffset,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(count, (i) {
          final distance = (i - scrollOffset).abs().clamp(0.0, 1.0);
          final width = 20.0 - distance * 12.0;
          final opacity = 1.0 - distance * 0.6;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: width,
            height: 2,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1),
              color: Colors.white.withValues(alpha: opacity * 0.7),
            ),
          );
        }),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double width, height, radius;
  const _SkeletonBox({
    required this.width,
    required this.height,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}
