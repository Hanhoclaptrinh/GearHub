import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/src/core/di/injection.dart';
import 'package:mobile/src/core/theme/app_colors.dart';
import 'package:mobile/src/features/home/domain/entities/hero_product_entity.dart';
import 'package:mobile/src/features/product_detail/data/datasources/product_detail_remote_datasource.dart';
import 'package:mobile/src/features/product_detail/presentation/pages/product_detail_page.dart';
import 'package:mobile/src/features/product_detail/presentation/pages/product_ar_view_page.dart';
import '../state/home_cubit.dart';
import '../state/home_state.dart';

class HeroSection extends StatefulWidget {
  const HeroSection({super.key});

  @override
  State<HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<HeroSection> {
  ScrollPosition? _scrollPosition;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newPosition = Scrollable.maybeOf(context)?.position;
    if (newPosition != _scrollPosition) {
      _scrollPosition?.removeListener(_onScroll);
      _scrollPosition = newPosition;
      _scrollPosition?.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    _scrollPosition?.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final double heroHeight = screenHeight - topPadding - bottomPadding;

    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        if (state is HomeLoading || state is HomeInitial) {
          return _buildLoading(heroHeight);
        }
        if (state is HomeError) {
          return _buildError(state.message, heroHeight);
        }

        final featured = (state as HomeLoaded).featuredProducts;
        final product = featured.firstOrNull;

        if (product == null) {
          return _buildFallback(heroHeight);
        }

        final offset = _scrollPosition?.pixels ?? 0.0;
        final double opacity = (1.0 - (offset / heroHeight)).clamp(0.0, 1.0);
        final double scale = (1.0 - (offset / heroHeight) * 0.15).clamp(
          0.85,
          1.0,
        );
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return RepaintBoundary(
          child: SizedBox(
            height: heroHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? null
                          : Theme.of(context).scaffoldBackgroundColor,
                      gradient: isDark
                          ? const RadialGradient(
                              center: Alignment.center,
                              radius: 1.2,
                              colors: [Color(0xFF141929), AppColors.background],
                            )
                          : null,
                    ),
                  ),
                ),
                //bg
                if (isDark) ...[
                  Positioned(
                    top: 100 - (offset * 0.15),
                    left: MediaQuery.of(context).size.width * 0.1,
                    child: Opacity(
                      opacity: opacity,
                      child: const _Glow(color: Color(0x183B82F6), radius: 250),
                    ),
                  ),
                  Positioned(
                    bottom: 120 + (offset * 0.15),
                    right: MediaQuery.of(context).size.width * 0.1,
                    child: Opacity(
                      opacity: opacity,
                      child: const _Glow(color: Color(0x106366F1), radius: 200),
                    ),
                  ),
                ],
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.0, 0.15, 0.85, 1.0],
                          colors: [
                            isDark
                                ? AppColors.background
                                : Theme.of(context).scaffoldBackgroundColor,
                            isDark
                                ? AppColors.background.withValues(alpha: .0)
                                : Theme.of(context).scaffoldBackgroundColor
                                      .withValues(alpha: .0),
                            isDark
                                ? AppColors.background.withValues(alpha: .0)
                                : Theme.of(context).scaffoldBackgroundColor
                                      .withValues(alpha: .0),
                            isDark
                                ? AppColors.background
                                : Theme.of(context).scaffoldBackgroundColor,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                //brand name
                Positioned(
                  top: (heroHeight * 0.12) - (offset * 0.45),
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: isDark
                          ? (0.09 * opacity).clamp(0.0, 1.0)
                          : opacity.clamp(0.0, 1.0),
                      child: Text(
                        product.brandName.isNotEmpty
                            ? product.brandName.toUpperCase()
                            : 'GEARHUB',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        style: GoogleFonts.shareTech(
                          fontSize: 130,
                          fontWeight: FontWeight.w900,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFFE4E4E7),
                          letterSpacing: 6,
                        ),
                      ),
                    ),
                  ),
                ),

                //prd image
                Positioned(
                  top: (heroHeight * 0.18) - (offset * 0.12),
                  left: 16,
                  right: 16,
                  height: heroHeight * 0.60,
                  child: GestureDetector(
                    onTap: () => _navigate(context, product),
                    child: Opacity(
                      opacity: opacity,
                      child: Transform.scale(
                        scale: scale,
                        child: Hero(
                          tag: 'product_hero_${product.id}',
                          child: CachedNetworkImage(
                            imageUrl: product.image,
                            fit: BoxFit.contain,
                            fadeInDuration: const Duration(milliseconds: 300),
                            placeholder: (_, __) => const Center(
                              child: SizedBox(
                                width: 32,
                                height: 32,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  valueColor: AlwaysStoppedAnimation(
                                    Colors.white30,
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (_, __, ___) => const Icon(
                              Icons.image_not_supported_outlined,
                              color: Colors.white24,
                              size: 48,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                //prd name
                Positioned(
                  top: (heroHeight * 0.60) - (offset * 0.22),
                  left: 28,
                  right: 28,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: opacity,
                      child: _buildProductName(product.baseName, context),
                    ),
                  ),
                ),

                //tagline & cta
                Positioned(
                  bottom: 0,
                  left: 28,
                  right: 28,
                  child: Opacity(
                    opacity: opacity,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'TIÊU ĐIỂM CÔNG NGHỆ',
                                style: GoogleFonts.outfit(
                                  color: isDark
                                      ? Colors.white70
                                      : const Color(
                                          0xFF111111,
                                        ).withValues(alpha: .7),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                product.tagline.isNotEmpty
                                    ? product.tagline
                                    : 'Khám phá ngay sản phẩm mới nhất tại GearHub',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  color: isDark
                                      ? Colors.white38
                                      : const Color(
                                          0xFF111111,
                                        ).withValues(alpha: .5),
                                  fontWeight: FontWeight.w400,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        //ar
                        if (product.arUrl != null &&
                            product.arUrl!.isNotEmpty) ...[
                          const SizedBox(width: 16),
                          _buildArButton(context, product),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductName(String name, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF111111);

    final words = name.trim().toUpperCase().split(' ');
    if (words.length <= 1) {
      return Text(
        name.toUpperCase(),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.outfit(
          fontSize: 40,
          fontWeight: FontWeight.w900,
          color: textColor,
          letterSpacing: -1.0,
          height: 1.0,
        ),
      );
    }

    final half = (words.length / 2).ceil();
    final solidPart = words.sublist(0, half).join(' ');
    final outlinePart = words.sublist(half).join(' ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          solidPart,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(
            fontSize: 42,
            fontWeight: FontWeight.w900,
            color: textColor,
            letterSpacing: -1.0,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          outlinePart,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(
            fontSize: 42,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.0,
            height: 1.0,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5
              ..color = textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildArButton(BuildContext context, HeroProductEntity product) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white : const Color(0xFF111111);

    return GestureDetector(
      onTap: () => _navigateAr(context, product),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: baseColor.withValues(alpha: .05),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: baseColor.withValues(alpha: .12), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.view_in_ar_outlined, color: baseColor, size: 16),
            const SizedBox(width: 6),
            Text(
              'THỬ NGAY AR',
              style: GoogleFonts.outfit(
                color: baseColor,
                fontWeight: FontWeight.w700,
                fontSize: 10,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigate(BuildContext context, HeroProductEntity product) {
    HapticFeedback.mediumImpact();
    getIt<ProductDetailRemoteDatasource>()
        .getProductDetail(product.id)
        .then((d) {
          if (context.mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ProductDetailPage(product: d)),
            );
          }
        })
        .catchError((e) {
          debugPrint('[Hero] $e');
        });
  }

  void _navigateAr(BuildContext context, HeroProductEntity product) {
    HapticFeedback.mediumImpact();
    getIt<ProductDetailRemoteDatasource>()
        .getProductDetail(product.id)
        .then((d) {
          if (context.mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ProductARViewPage(product: d)),
            );
          }
        })
        .catchError((e) {
          debugPrint('[Hero AR] $e');
        });
  }

  Widget _buildLoading(double height) => SizedBox(
    height: height,
    child: const Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          valueColor: AlwaysStoppedAnimation(Colors.white24),
        ),
      ),
    ),
  );

  Widget _buildError(String msg, double height) => SizedBox(
    height: height,
    child: Center(
      child: Text(
        msg,
        style: const TextStyle(color: Colors.white24, fontSize: 13),
      ),
    ),
  );

  Widget _buildFallback(double height) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF111111);

    return SizedBox(
      height: height,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? null
                    : Theme.of(context).scaffoldBackgroundColor,
                gradient: isDark
                    ? const RadialGradient(
                        center: Alignment.center,
                        radius: 1.2,
                        colors: [Color(0xFF141929), AppColors.background],
                      )
                    : null,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'GEARHUB',
                  style: GoogleFonts.shareTech(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: textColor.withValues(alpha: .15),
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'UPGRADE YOUR SETUP',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textColor.withValues(alpha: .3),
                    letterSpacing: 2.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final Color color;
  final double radius;
  const _Glow({required this.color, required this.radius});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: radius * 2,
      height: radius * 2,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, Colors.transparent]),
        ),
      ),
    );
  }
}
