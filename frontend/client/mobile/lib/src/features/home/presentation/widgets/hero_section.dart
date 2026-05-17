import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/src/core/di/injection.dart';
import 'package:mobile/src/core/utils/hero_banners_utils.dart';
import 'package:mobile/src/features/home/domain/entities/hero_product_entity.dart';
import 'package:mobile/src/features/product_detail/data/datasources/product_detail_remote_datasource.dart';
import 'package:mobile/src/features/product_detail/presentation/pages/product_detail_page.dart';
import 'package:mobile/src/core/theme/app_colors.dart';
import '../state/home_cubit.dart';
import '../state/home_state.dart';

const _kHeroH = 580.0;

enum _ProductBias { shiftRight, shiftLeft, centerSoft }

_ProductBias _biasFor(int index) => switch (index % 3) {
  0 => _ProductBias.shiftRight,
  1 => _ProductBias.shiftLeft,
  _ => _ProductBias.centerSoft,
};

(double, double) _marginsFor(_ProductBias bias, double width) => switch (bias) {
  _ProductBias.shiftRight => (-width * 0.08, width * 0.22),
  _ProductBias.shiftLeft => (width * 0.22, -width * 0.08),
  _ProductBias.centerSoft => (-width * 0.04, -width * 0.04),
};

class _Particle {
  final double x, baseY, size, speed, phase;
  const _Particle({
    required this.x,
    required this.baseY,
    required this.size,
    required this.speed,
    required this.phase,
  });
}

List<_Particle> _generateParticles(int count) {
  final rng = math.Random(42); // fixed seed = stable layout
  return List.generate(
    count,
    (_) => _Particle(
      x: rng.nextDouble(),
      baseY: rng.nextDouble() * 0.75, // avoid text area
      size: rng.nextDouble() * 1.0 + 0.4,
      speed: rng.nextDouble() * 0.4 + 0.15,
      phase: rng.nextDouble() * math.pi * 2,
    ),
  );
}

List<Offset> _generateGrainPoints(int count) {
  final rng = math.Random(7);
  return List.generate(
    count,
    (_) => Offset(rng.nextDouble(), rng.nextDouble()),
  );
}

class HeroSection extends StatefulWidget {
  const HeroSection({super.key});
  @override
  State<HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<HeroSection>
    with TickerProviderStateMixin {
  late final PageController _pageCtrl;
  Timer? _progressTimer;
  static const int _autoMs = 6000;
  static const int _tickMs = 30;
  double _progress = 0.0;
  int _currentPage = 0;
  static const int kLoopRange = 10000;

  late final AnimationController _floatCtrl;
  late final Animation<double> _floatAnim;

  late final AnimationController _revealCtrl;

  late final AnimationController _hazeCtrl;
  late final Animation<double> _hazeAnim;

  late final AnimationController _particleCtrl;
  late final Animation<double> _particleAnim;

  final List<_Particle> _particles = _generateParticles(18);
  final List<Offset> _grainPts = _generateGrainPoints(900);

  @override
  void initState() {
    super.initState();
    final initialSlides = HeroBannerUtils.fallbackBanners.length;
    _pageCtrl = PageController(initialPage: initialSlides * 1000);

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    )..repeat(reverse: true);
    _floatAnim = CurvedAnimation(
      parent: _floatCtrl,
      curve: Curves.easeInOutSine,
    );

    _revealCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _hazeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat(reverse: true);
    _hazeAnim = CurvedAnimation(parent: _hazeCtrl, curve: Curves.easeInOut);

    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
    _particleAnim = _particleCtrl;

    _startAutoplay();
    _revealCtrl.forward();
  }

  void _startAutoplay() {
    _progressTimer?.cancel();
    _progress = 0.0;
    _progressTimer = Timer.periodic(const Duration(milliseconds: _tickMs), (_) {
      if (!mounted) return;
      setState(() {
        _progress += _tickMs / _autoMs;
        if (_progress >= 1.0) {
          _progress = 0.0;
          if (_pageCtrl.hasClients) {
            _pageCtrl.nextPage(
              duration: const Duration(milliseconds: 1000),
              curve: Curves.fastOutSlowIn,
            );
          }
        }
      });
    });
  }

  void _onPageChanged(int index, int totalSlides) {
    if (totalSlides > 0) setState(() => _currentPage = index % totalSlides);
    HapticFeedback.selectionClick();
    _startAutoplay();
    _revealCtrl
      ..reset()
      ..forward();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _pageCtrl.dispose();
    _floatCtrl.dispose();
    _revealCtrl.dispose();
    _hazeCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        if (state is HomeLoading || state is HomeInitial) {
          return _buildLoading();
        }
        if (state is HomeError) return _buildError(state.message);

        final featured = (state as HomeLoaded).featuredProducts;
        final slides = <dynamic>[...featured];
        if (slides.length < 5) {
          slides.addAll(
            HeroBannerUtils.fallbackBanners.take(5 - slides.length),
          );
        }
        final finalSlides = slides.take(5).toList();
        final total = finalSlides.length;

        return RepaintBoundary(
          child: SizedBox(
            height: _kHeroH,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // page view
                PageView.builder(
                  controller: _pageCtrl,
                  itemCount: kLoopRange,
                  onPageChanged: (i) => _onPageChanged(i, total),
                  itemBuilder: (context, index) {
                    if (total == 0) return const SizedBox.shrink();
                    final actual = index % total;
                    final item = finalSlides[actual];
                    final bias = _biasFor(actual);

                    return AnimatedBuilder(
                      animation: _pageCtrl,
                      builder: (ctx, _) {
                        double offset = 0;
                        if (_pageCtrl.position.haveDimensions) {
                          offset = (index - (_pageCtrl.page ?? 0))
                              .clamp(-1.5, 1.5)
                              .toDouble();
                        }
                        return item is Map<String, String>
                            ? _CinematicBannerSlide(
                                banner: item,
                                offset: offset,
                                floatAnim: _floatAnim,
                                revealCtrl: _revealCtrl,
                              )
                            : _CinematicProductSlide(
                                product: item as HeroProductEntity,
                                offset: offset,
                                floatAnim: _floatAnim,
                                revealCtrl: _revealCtrl,
                                bias: bias,
                              );
                      },
                    );
                  },
                ),

                Positioned.fill(
                  child: IgnorePointer(child: _AnimatedHaze(anim: _hazeAnim)),
                ),

                Positioned.fill(
                  child: IgnorePointer(
                    child: _ParticleField(
                      anim: _particleAnim,
                      particles: _particles,
                    ),
                  ),
                ),

                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(painter: _GrainPainter(_grainPts)),
                  ),
                ),

                const Positioned.fill(child: IgnorePointer(child: _Vignette())),

                const Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: [0.0, 0.14, 0.86, 1.0],
                          colors: [
                            AppColors.background,
                            Colors.transparent,
                            Colors.transparent,
                            AppColors.background,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                _buildIndicators(total),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIndicators(int length) {
    return Positioned(
      bottom: 16,
      left: 24,
      right: 24,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '0${_currentPage + 1}',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: List.generate(length, (i) {
                final isActive = i == _currentPage;
                final isPast = i < _currentPage;
                return Expanded(
                  child: Container(
                    height: 1.5,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: AppColors.textPrimary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(1),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: isActive
                        ? FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _progress,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: AppColors.textPrimary,
                                borderRadius: BorderRadius.circular(1),
                                boxShadow: const [
                                  BoxShadow(
                                    color: AppColors.textPrimary,
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : isPast
                        ? ColoredBox(
                            color: AppColors.textPrimary.withValues(
                              alpha: 0.45,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '0$length',
            style: TextStyle(
              color: AppColors.textPrimary.withValues(alpha: 0.3),
              fontWeight: FontWeight.w500,
              fontSize: 11,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() => const SizedBox(
    height: _kHeroH,
    child: ColoredBox(
      color: AppColors.background,
      child: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 1,
            valueColor: AlwaysStoppedAnimation(Color(0x60FFFFFF)),
          ),
        ),
      ),
    ),
  );

  Widget _buildError(String msg) => SizedBox(
    height: _kHeroH,
    child: ColoredBox(
      color: AppColors.background,
      child: Center(
        child: Text(
          msg,
          style: const TextStyle(color: Color(0x40FFFFFF), fontSize: 13),
        ),
      ),
    ),
  );
}

class _CinematicProductSlide extends StatelessWidget {
  final HeroProductEntity product;
  final double offset;
  final Animation<double> floatAnim;
  final AnimationController revealCtrl;
  final _ProductBias bias;

  const _CinematicProductSlide({
    required this.product,
    required this.offset,
    required this.floatAnim,
    required this.revealCtrl,
    required this.bias,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final clamped = offset.clamp(-1.0, 1.0);
    final fade = (1.0 - clamped.abs() * 0.65).clamp(0.0, 1.0);
    final (mLeft, mRight) = _marginsFor(bias, width);
    final px = clamped * width * 0.22;

    return GestureDetector(
      onTap: () => _navigate(context),
      child: ColoredBox(
        color: AppColors.background,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: _kHeroH * 0.08,
              left: width * 0.25 - px * 0.4,
              child: const _Glow(color: Color(0x0F3B82F6), radius: 220),
            ),
            Positioned(
              top: _kHeroH * 0.2,
              right: width * 0.1 + px * 0.3,
              child: const _Glow(color: Color(0x086366F1), radius: 160),
            ),

            Positioned(
              top: -24,
              bottom: _kHeroH * 0.26,
              left: mLeft + px,
              right: mRight - px,
              child: AnimatedBuilder(
                animation: floatAnim,
                builder: (_, child) {
                  final t = floatAnim.value;
                  final floatY =
                      math.sin(t * math.pi) * 10 +
                      math.sin(t * math.pi * 2.3 + 1.1) * 3.5;
                  final floatR = math.sin(t * math.pi * 1.7 + 0.5) * 0.009;

                  return Transform(
                    alignment: Alignment.bottomCenter,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(-clamped * 0.45)
                      ..rotateZ(clamped * 0.04 + floatR)
                      ..translate(0.0, floatY, 0.0),
                    child: Opacity(opacity: fade, child: child),
                  );
                },
                child: product.image.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: product.image,
                        fit: BoxFit.contain,
                        alignment: Alignment.bottomCenter,
                        fadeInDuration: const Duration(milliseconds: 500),
                        placeholder: (_, __) => const SizedBox.shrink(),
                        errorWidget: (_, __, ___) => const SizedBox.shrink(),
                      )
                    : const SizedBox.shrink(),
              ),
            ),

            Positioned(
              bottom: _kHeroH * 0.29,
              left: width * 0.22 + px * 0.5,
              right: width * 0.22 - px * 0.5,
              child: AnimatedBuilder(
                animation: floatAnim,
                builder: (_, __) {
                  final lift = floatAnim.value;
                  return Opacity(
                    opacity: (fade * (0.55 - lift * 0.3)).clamp(0, 1),
                    child: Transform.scale(
                      scaleX: 1.0 - lift * 0.28,
                      child: Container(
                        height: 1,
                        decoration: const BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.ctaPrimaryText,
                              blurRadius: 22,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.28, 0.52, 1.0],
                      colors: [
                        Colors.transparent,
                        AppColors.background.withValues(alpha: 0.65),
                        AppColors.background,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            Positioned(
              top: _kHeroH * 0.56,
              left: 28,
              width: width * 0.63,
              child: _StaggeredReveal(
                ctrl: revealCtrl,
                offset: clamped,
                headline: product.baseName,
                subtitle: product.tagline,
                ctaLabel: 'Khám phá',
                onTap: () => _navigate(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigate(BuildContext context) {
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
          return null;
        });
  }
}

class _CinematicBannerSlide extends StatelessWidget {
  final Map<String, String> banner;
  final double offset;
  final Animation<double> floatAnim;
  final AnimationController revealCtrl;

  const _CinematicBannerSlide({
    required this.banner,
    required this.offset,
    required this.floatAnim,
    required this.revealCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final clamped = offset.clamp(-1.0, 1.0);
    final fade = (1.0 - clamped.abs() * 0.6).clamp(0.0, 1.0);

    return ColoredBox(
      color: AppColors.background,
      child: Stack(
        children: [
          Positioned.fill(
            child: Transform.translate(
              offset: Offset(clamped * width * 0.35, 0),
              child: Transform.scale(
                scale: 1.04 - clamped.abs() * 0.04,
                child: Opacity(
                  opacity: fade,
                  child: CachedNetworkImage(
                    imageUrl: banner['image']!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const SizedBox.shrink(),
                    errorWidget: (_, __, ___) =>
                        const ColoredBox(color: Color(0xFF0B1020)),
                  ),
                ),
              ),
            ),
          ),

          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.05, 0.45, 1.0],
                  colors: [
                    AppColors.background.withValues(alpha: 0.4),
                    AppColors.background.withValues(alpha: 0.65),
                    AppColors.background.withValues(alpha: 0.96),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            top: _kHeroH * 0.55,
            left: 28,
            width: width * 0.65,
            child: _StaggeredReveal(
              ctrl: revealCtrl,
              offset: clamped,
              headline: banner['title']!,
              subtitle: banner['subtitle']!,
              ctaLabel: 'Tìm hiểu thêm',
            ),
          ),
        ],
      ),
    );
  }
}

class _StaggeredReveal extends StatelessWidget {
  final AnimationController ctrl;
  final double offset;
  final String headline, subtitle, ctaLabel;
  final VoidCallback? onTap;

  const _StaggeredReveal({
    required this.ctrl,
    required this.offset,
    required this.headline,
    required this.subtitle,
    required this.ctaLabel,
    this.onTap,
  });

  Animation<double> _fade(double s, double e) => CurvedAnimation(
    parent: ctrl,
    curve: Interval(s, e, curve: Curves.easeOut),
  );

  Animation<Offset> _slide(double s, double e) =>
      Tween<Offset>(begin: const Offset(0, 0.07), end: Offset.zero).animate(
        CurvedAnimation(
          parent: ctrl,
          curve: Interval(s, e, curve: Curves.easeOutCubic),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    const m = [0.7, 0.45, 0.28, 0.14];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.translate(
          offset: Offset(offset * w * m[1], 0),
          child: FadeTransition(
            opacity: _fade(0.12, 0.55),
            child: SlideTransition(
              position: _slide(0.12, 0.55),
              child: Text(
                headline,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.8,
                  height: 1.12,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 9),

        Transform.translate(
          offset: Offset(offset * w * m[2], 0),
          child: FadeTransition(
            opacity: _fade(0.28, 0.70),
            child: SlideTransition(
              position: _slide(0.28, 0.70),
              child: Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textPrimary.withValues(alpha: 0.55),
                  letterSpacing: 0.1,
                  height: 1.45,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),

        Transform.translate(
          offset: Offset(offset * w * m[3], 0),
          child: FadeTransition(
            opacity: _fade(0.48, 1.0),
            child: SlideTransition(
              position: _slide(0.48, 1.0),
              child: _EditorialCTA(label: ctaLabel, onTap: onTap),
            ),
          ),
        ),
      ],
    );
  }
}

class _EditorialCTA extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  const _EditorialCTA({required this.label, this.onTap});

  @override
  State<_EditorialCTA> createState() => _EditorialCTAState();
}

class _EditorialCTAState extends State<_EditorialCTA>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: _pressed ? 0.65 : 1.0,
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 130),
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.textPrimary.withValues(
                alpha: _pressed ? 0.10 : 0.04,
              ),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: AppColors.textPrimary.withValues(alpha: 0.14),
                width: 0.6,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedSlide(
                  offset: _pressed ? const Offset(0.3, 0) : Offset.zero,
                  duration: const Duration(milliseconds: 130),
                  child: Icon(
                    Icons.arrow_forward,
                    size: 11,
                    color: AppColors.textPrimary.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedHaze extends StatelessWidget {
  final Animation<double> anim;
  const _AnimatedHaze({required this.anim});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) {
        final t = anim.value;
        final dx = math.sin(t * math.pi) * 38;
        final dy = math.cos(t * math.pi * 0.65) * 18;
        return Stack(
          children: [
            Positioned(
              top: 60 + dy,
              left: width * 0.25 + dx,
              child: const _Glow(color: Color(0x0C3B82F6), radius: 190),
            ),
            Positioned(
              top: 180 - dy * 0.7,
              right: width * 0.05 - dx * 0.6,
              child: const _Glow(color: Color(0x086366F1), radius: 150),
            ),
            Positioned(
              bottom: 100 + dy * 0.4,
              left: width * 0.1 + dx * 0.4,
              child: const _Glow(color: Color(0x071E3A5F), radius: 200),
            ),
          ],
        );
      },
    );
  }
}

class _ParticleField extends StatelessWidget {
  final Animation<double> anim;
  final List<_Particle> particles;
  const _ParticleField({required this.anim, required this.particles});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) => CustomPaint(
        painter: _ParticlePainter(anim.value, particles),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double t;
  final List<_Particle> particles;
  _ParticlePainter(this.t, this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final dy = math.sin(t * 2 * math.pi * p.speed + p.phase) * 14;
      final opacity = (0.03 + math.sin(t * math.pi + p.phase) * 0.015).clamp(
        0.01,
        0.055,
      );
      canvas.drawCircle(
        Offset(p.x * size.width, p.baseY * size.height + dy),
        p.size,
        Paint()..color = AppColors.textPrimary.withValues(alpha: opacity),
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.t != t;
}

class _GrainPainter extends CustomPainter {
  final List<Offset> points;
  _GrainPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textPrimary.withValues(alpha: 0.022)
      ..strokeWidth = 0.6
      ..strokeCap = StrokeCap.round;

    canvas.drawPoints(
      ui.PointMode.points,
      points.map((p) => Offset(p.dx * size.width, p.dy * size.height)).toList(),
      paint,
    );
  }

  @override
  bool shouldRepaint(_GrainPainter old) => false; // static, never repaint
}

class _Vignette extends StatelessWidget {
  const _Vignette();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.1,
          colors: [
            Colors.transparent,
            Colors.transparent,
            AppColors.ctaPrimaryText.withValues(alpha: 0.35),
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
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
