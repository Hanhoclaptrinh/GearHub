import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/src/core/di/injection.dart';
import 'package:mobile/src/features/home/domain/entities/hero_product_entity.dart';
import 'package:mobile/src/features/product_detail/data/datasources/product_detail_remote_datasource.dart';
import 'package:mobile/src/features/product_detail/presentation/pages/product_detail_page.dart';
import '../state/home_cubit.dart';
import '../state/home_state.dart';

class HeroSection extends StatefulWidget {
  const HeroSection({super.key});

  @override
  State<HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<HeroSection> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;
  double _progress = 0.0;
  static const int kLoopRange = 10000;

  // mockup data
  final List<Map<String, String>> _fallbackBanners = [
    {
      'title': 'Tiêu chuẩn\nđỉnh cao',
      'subtitle': 'Nhận ngay ưu đãi màn hình 2026 độc quyền',
      'image':
          'https://res.cloudinary.com/dxgts0irt/image/upload/v1777626771/gearhub/media/file_uilydh.png',
    },
    {
      'title': 'Mượt mà\ntừng pixel',
      'subtitle': 'Trải nghiệm tần số quét siêu cao',
      'image':
          'https://res.cloudinary.com/dxgts0irt/image/upload/v1777626766/gearhub/media/file_ocxpbw.png',
    },
    {
      'title': 'Khẳng định\nbản lĩnh',
      'subtitle': 'Laptop gaming cấu hình tối thượng',
      'image':
          'https://res.cloudinary.com/dxgts0irt/image/upload/v1777624711/gearhub/media/file_ftwxso.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    final initialSlides = _fallbackBanners.length;
    _pageController = PageController(initialPage: initialSlides * 1000);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _progress = 0.0;
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (mounted) {
        setState(() {
          _progress += 50 / 4000;
          if (_progress >= 1.0) {
            _progress = 0.0;
            if (_pageController.hasClients) {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOutCubic,
              );
            }
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        if (state is HomeLoading || state is HomeInitial) {
          return Container(
            height: 540,
            color: Colors.white,
            child: const Center(
              child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
            ),
          );
        }

        if (state is HomeError) {
          return Container(
            height: 540,
            color: Colors.white,
            child: Center(
              child: Text(
                'Lỗi: ${state.message}',
                style: const TextStyle(color: Color(0xFF6B7280)),
              ),
            ),
          );
        }

        final featured = (state as HomeLoaded).featuredProducts;
        final totalSlides = _fallbackBanners.length + featured.length;

        return Stack(
          children: [
            SizedBox(
              height: 540,
              child: PageView.builder(
                controller: _pageController,
                itemCount: kLoopRange,
                onPageChanged: (index) {
                  if (totalSlides > 0) {
                    setState(() {
                      _currentPage = index % totalSlides;
                    });
                  }
                  HapticFeedback.lightImpact();
                  _startTimer(); // reset timer neu swipe thu cong
                },
                itemBuilder: (context, index) {
                  if (totalSlides == 0) return const SizedBox.shrink();
                  final actualIndex = index % totalSlides;

                  if (actualIndex < _fallbackBanners.length) {
                    return _buildBannerHeroSlide(
                      context,
                      _fallbackBanners[actualIndex],
                    );
                  } else {
                    final featuredIndex = actualIndex - _fallbackBanners.length;
                    return _buildProductHeroSlide(
                      context,
                      featured[featuredIndex],
                    );
                  }
                },
              ),
            ),
            _buildPageIndicator(totalSlides),
          ],
        );
      },
    );
  }

  Widget _buildProductHeroSlide(
    BuildContext context,
    HeroProductEntity product,
  ) {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.mediumImpact();
        try {
          final pDetail = await getIt<ProductDetailRemoteDatasource>()
              .getProductDetail(product.id);
          if (context.mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProductDetailPage(product: pDetail),
              ),
            );
          }
        } catch (e) {
          debugPrint('[Hero] Error fetching product detail: $e');
        }
      },
      child: Container(
        decoration: const BoxDecoration(color: Colors.white),
        child: Stack(
          children: [
            Positioned.fill(
              child: product.image.isNotEmpty
                  ? Image.network(product.image, fit: BoxFit.cover)
                  : Container(color: const Color(0xFFF3F4F6)),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.0),
                      Colors.black.withValues(alpha: 0.1),
                      Colors.black.withValues(alpha: 0.85),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 60,
              left: 24,
              right: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    product.tagline,
                    maxLines: 2,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Xem chi tiết',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0A0A0F),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerHeroSlide(
    BuildContext context,
    Map<String, String> banner,
  ) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              banner['image']!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: const Color(0xFFF3F4F6)),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.0),
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.85),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  banner['title']!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  banner['subtitle']!,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Tìm hiểu thêm',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A0A0F),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int length) {
    return Positioned(
      bottom: 24,
      left: 24,
      right: 24,
      child: Row(
        children: List.generate(length, (index) {
          final isSelected = index == _currentPage;
          return Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
              clipBehavior: Clip.antiAlias,
              child: isSelected
                  ? FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _progress,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    )
                  : (index < _currentPage
                        ? Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          )
                        : const SizedBox.shrink()),
            ),
          );
        }),
      ),
    );
  }
}
