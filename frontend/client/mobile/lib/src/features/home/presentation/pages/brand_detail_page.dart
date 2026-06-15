import 'dart:math' as math;
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile/src/core/di/injection.dart';
import 'package:mobile/src/core/utils/brand_identity_helper.dart';
import 'package:mobile/src/core/utils/formatter_utils.dart';
import 'package:mobile/src/features/chat/presentation/widgets/concierge_entry_button.dart';
import 'package:mobile/src/features/home/domain/entities/brand_entity.dart';
import 'package:mobile/src/features/home/presentation/state/brand_products_cubit.dart';
import 'package:mobile/src/features/product_detail/presentation/pages/product_detail_page.dart';
import 'package:mobile/src/shared/models/product_model.dart';
import 'package:mobile/src/shared/widgets/error_illustration_widget.dart';

class BrandDetailPage extends StatelessWidget {
  final BrandEntity brand;
  const BrandDetailPage({super.key, required this.brand});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          getIt<BrandProductsCubit>(param1: brand)..loadBrandData(),
      child: _BrandDetailView(brand: brand),
    );
  }
}

class _BrandDetailView extends StatefulWidget {
  final BrandEntity brand;
  const _BrandDetailView({required this.brand});

  @override
  State<_BrandDetailView> createState() => _BrandDetailViewState();
}

class _BrandDetailViewState extends State<_BrandDetailView>
    with TickerProviderStateMixin {
  final ScrollController _scroll = ScrollController();
  double _scrollOffset = 0.0;

  //float animation hero prod img
  late final AnimationController _floatController;
  late final Animation<double> _floatAnim;

  late final AnimationController _revealController;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _revealController.forward();
      });
    });
  }

  void _onScroll() {
    setState(() => _scrollOffset = _scroll.offset);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _floatController.dispose();
    _revealController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _storyConfig() {
    final identity = BrandIdentityHelper.getIdentity(widget.brand.name);
    return {
      'quote': (widget.brand.quote?.isNotEmpty == true)
          ? widget.brand.quote!
          : identity.quote,
      'philosophy': (widget.brand.philosophy?.isNotEmpty == true)
          ? widget.brand.philosophy!
          : identity.philosophy,
      'accent': identity.accent,
    };
  }

  @override
  Widget build(BuildContext context) {
    final story = _storyConfig();
    final size = MediaQuery.of(context).size;
    final topPad = MediaQuery.of(context).padding.top;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bg = isDark ? const Color(0xFF07070A) : const Color(0xFFF8F9FC);
    final Color surface = isDark ? const Color(0xFF0F0F14) : Colors.white;
    final Color border = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);
    final Color borderStrong = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.12);
    final Color textPrimary = isDark
        ? Colors.white.withValues(alpha: 0.95)
        : const Color(0xFF0A0A0F).withValues(alpha: 0.95);
    final Color textSecondary = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : const Color(0xFF0A0A0F).withValues(alpha: 0.45);
    final Color adaptiveAccent = BrandIdentityHelper.getAdaptiveAccent(
      context,
      story['accent'],
    );

    //hero dimention
    final double heroHeight = size.height * 0.58;
    final double collapseOffset = heroHeight - topPad - 56;
    final double t = (_scrollOffset / collapseOffset).clamp(0.0, 1.0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: bg,
        body: BlocBuilder<BrandProductsCubit, BrandProductsState>(
          builder: (context, state) {
            if (state is BrandProductsError) {
              return _buildError(context, state.message, bg, topPad, t);
            }
            return Stack(
              children: [
                CustomScrollView(
                  controller: _scroll,
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(
                      child: _HeroStage(
                        brand: widget.brand,
                        story: story,
                        isDark: isDark,
                        bg: bg,
                        surface: surface,
                        border: border,
                        borderStrong: borderStrong,
                        textSecondary: textSecondary,
                        adaptiveAccent: adaptiveAccent,
                        scrollOffset: _scrollOffset,
                        collapseT: t,
                        heroHeight: heroHeight,
                        floatAnim: _floatAnim,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: FadeTransition(
                        opacity: _revealController,
                        child: SlideTransition(
                          position:
                              Tween<Offset>(
                                begin: const Offset(0, 0.04),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: _revealController,
                                  curve: Curves.easeOutCubic,
                                ),
                              ),
                          child: _BodySheet(
                            brand: widget.brand,
                            story: story,
                            isDark: isDark,
                            bg: bg,
                            surface: surface,
                            border: border,
                            borderStrong: borderStrong,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            adaptiveAccent: adaptiveAccent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                _NavHeader(
                  t: t,
                  isDark: isDark,
                  bg: bg,
                  border: border,
                  topPad: topPad,
                  onBack: () => Navigator.pop(context),
                ),

                Positioned(
                  top: 0,
                  left: 0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 80),
                    height: 1.5,
                    width: state is BrandProductsLoaded
                        ? _progressWidth(size.width)
                        : 0,
                    color: adaptiveAccent.withValues(alpha: 0.7),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  double _progressWidth(double screenWidth) {
    if (!_scroll.hasClients || !_scroll.position.hasContentDimensions) return 0;
    final max = _scroll.position.maxScrollExtent;
    if (max <= 0) return 0;
    return ((_scroll.offset / max) * screenWidth).clamp(0, screenWidth);
  }

  Widget _buildError(
    BuildContext context,
    String message,
    Color bg,
    double topPad,
    double t,
  ) {
    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          Center(
            child: ErrorIllustrationWidget(
              message: message,
              onRetry: () => context.read<BrandProductsCubit>().loadBrandData(),
            ),
          ),
          _NavHeader(
            t: t,
            isDark: Theme.of(context).brightness == Brightness.dark,
            bg: bg,
            border: Colors.white.withValues(alpha: 0.06),
            topPad: topPad,
            onBack: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _HeroStage extends StatelessWidget {
  final BrandEntity brand;
  final Map<String, dynamic> story;
  final bool isDark;
  final Color bg, surface, border, borderStrong, textSecondary, adaptiveAccent;
  final double scrollOffset, collapseT, heroHeight;
  final Animation<double> floatAnim;

  const _HeroStage({
    required this.brand,
    required this.story,
    required this.isDark,
    required this.bg,
    required this.surface,
    required this.border,
    required this.borderStrong,
    required this.textSecondary,
    required this.adaptiveAccent,
    required this.scrollOffset,
    required this.collapseT,
    required this.heroHeight,
    required this.floatAnim,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double fadeOpacity = (1.0 - collapseT * 1.6).clamp(0.0, 1.0);

    return SizedBox(
      height: heroHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: bg),

          CustomPaint(
            painter: _MeshGridPainter(
              lineColor: isDark
                  ? Colors.white.withValues(alpha: 0.035)
                  : Colors.black.withValues(alpha: 0.04),
              gridSize: 38,
              fadeCenterX: size.width / 2,
              fadeCenterY: heroHeight * 0.38,
            ),
          ),

          Positioned(
            top: -heroHeight * 0.15,
            left: size.width * 0.1,
            width: size.width * 0.8,
            height: size.width * 0.8,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    adaptiveAccent.withValues(alpha: isDark ? 0.14 : 0.07),
                    adaptiveAccent.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -heroHeight * 0.15,
            left: size.width * 0.1,
            width: size.width * 0.8,
            height: size.width * 0.8,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: const SizedBox.expand(),
            ),
          ),

          Positioned(
            top: heroHeight * 0.33,
            left: 24,
            right: 24,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  brand.name.toUpperCase(),
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 80,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 10,
                    color: adaptiveAccent.withValues(
                      alpha: isDark ? 0.04 : 0.03,
                    ),
                    height: 1,
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            top: heroHeight * 0.14,
            left: (size.width - 200) / 2,
            width: 200,
            height: 200,
            child: AnimatedBuilder(
              animation: floatAnim,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, -6 + floatAnim.value * 12),
                  child: child,
                );
              },
              child: _buildProductStage(),
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: heroHeight * 0.52,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    bg.withValues(alpha: 0.0),
                    bg.withValues(alpha: 0.65),
                    bg,
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: fadeOpacity,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 36,
                      child: SvgPicture.network(
                        brand.logoUrl,
                        fit: BoxFit.contain,
                        colorFilter: ColorFilter.mode(
                          adaptiveAccent,
                          BlendMode.srcIn,
                        ),
                        placeholderBuilder: (_) => Text(
                          brand.name.substring(0, 2).toUpperCase(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: adaptiveAccent,
                          ),
                        ),
                      ),
                    ),

                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      width: 0.5,
                      height: 44,
                      color: borderStrong,
                    ),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            story['quote'].toString().toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.5,
                              color: adaptiveAccent,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '“${story['philosophy']}”',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w300,
                              fontStyle: FontStyle.italic,
                              height: 1.5,
                              letterSpacing: -0.1,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductStage() {
    return BlocBuilder<BrandProductsCubit, BrandProductsState>(
      builder: (context, state) {
        if (state is BrandProductsLoaded && state.allProducts.isNotEmpty) {
          final hero = state.allProducts.first;
          return Hero(
            tag: 'brand_hero_${brand.id}',
            child: CachedNetworkImage(
              imageUrl: hero.image,
              fit: BoxFit.contain,
              width: 200,
              height: 200,
              errorWidget: (_, __, ___) => const SizedBox.shrink(),
            ),
          );
        }
        return Opacity(
          opacity: 0.12,
          child: Container(
            width: 140,
            height: 140,
            margin: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}

class _NavHeader extends StatelessWidget {
  final double t, topPad;
  final bool isDark;
  final Color bg, border;
  final VoidCallback onBack;

  const _NavHeader({
    required this.t,
    required this.isDark,
    required this.bg,
    required this.border,
    required this.topPad,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final navBg = isDark
        ? Color.lerp(Colors.transparent, const Color(0x99070710), t)!
        : Color.lerp(Colors.transparent, const Color(0xD4F8F9FC), t)!;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: t * 20, sigmaY: t * 20),
          child: Container(
            color: navBg,
            padding: EdgeInsets.only(top: topPad),
            height: topPad + 52,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: border.withValues(alpha: t * 1.0),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onBack();
                    },
                    child: SizedBox(
                      width: 34,
                      height: 34,
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 22,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.8)
                            : Colors.black.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  const Spacer(),
                  const ConciergeEntryButton(compact: true),
                  const SizedBox(width: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BodySheet extends StatelessWidget {
  final BrandEntity brand;
  final Map<String, dynamic> story;
  final bool isDark;
  final Color bg, surface, border, borderStrong;
  final Color textPrimary, textSecondary, adaptiveAccent;

  const _BodySheet({
    required this.brand,
    required this.story,
    required this.isDark,
    required this.bg,
    required this.surface,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.adaptiveAccent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            eyebrow: 'Signature Series',
            title: 'Bộ Sưu Tập\nTiêu Biểu',
            isDark: isDark,
            textPrimary: textPrimary,
            adaptiveAccent: adaptiveAccent,
            topPadding: 44,
          ),
          const SizedBox(height: 20),
          _MasterpieceStrip(
            story: story,
            isDark: isDark,
            bg: bg,
            surface: surface,
            border: border,
            borderStrong: borderStrong,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            adaptiveAccent: adaptiveAccent,
          ),
          const SizedBox(height: 36),

          _HairlineDivider(color: borderStrong, horizontal: 24),

          _SectionHeader(
            eyebrow: 'Explore All',
            title: 'Tất Cả Sản Phẩm',
            isDark: isDark,
            textPrimary: textPrimary,
            adaptiveAccent: adaptiveAccent,
            topPadding: 36,
          ),
          const SizedBox(height: 20),

          _FilterTabs(
            isDark: isDark,
            border: border,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            adaptiveAccent: adaptiveAccent,
          ),
          const SizedBox(height: 20),

          _ProductMosaicGrid(
            isDark: isDark,
            border: border,
            bg: bg,
            textPrimary: textPrimary,
            adaptiveAccent: adaptiveAccent,
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String eyebrow, title;
  final bool isDark;
  final Color textPrimary, adaptiveAccent;
  final double topPadding;

  const _SectionHeader({
    required this.eyebrow,
    required this.title,
    required this.isDark,
    required this.textPrimary,
    required this.adaptiveAccent,
    this.topPadding = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, topPadding, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 14,
                height: 0.5,
                color: adaptiveAccent.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 8),
              Text(
                eyebrow.toUpperCase(),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3.0,
                  color: adaptiveAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w300,
              height: 1.15,
              letterSpacing: -0.7,
              color: textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MasterpieceStrip extends StatelessWidget {
  final Map<String, dynamic> story;
  final bool isDark;
  final Color bg, surface, border, borderStrong;
  final Color textPrimary, textSecondary, adaptiveAccent;

  const _MasterpieceStrip({
    required this.story,
    required this.isDark,
    required this.bg,
    required this.surface,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.adaptiveAccent,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BrandProductsCubit, BrandProductsState>(
      builder: (context, state) {
        if (state is BrandProductsLoading) {
          return _loadingStrip();
        }
        if (state is! BrandProductsLoaded || state.allProducts.isEmpty) {
          return const SizedBox.shrink();
        }

        final masterpieces = List<ProductModel>.from(state.allProducts)
          ..sort((a, b) {
            final sc = b.soldCount.compareTo(a.soldCount);
            return sc != 0 ? sc : b.averageRating.compareTo(a.averageRating);
          });

        return SizedBox(
          height: 310,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: masterpieces.length,
            separatorBuilder: (_, __) => Container(
              width: 0.5,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              color: border,
            ),
            itemBuilder: (context, i) => _MasterpieceCard(
              product: masterpieces[i],
              isDark: isDark,
              bg: bg,
              surface: surface,
              border: border,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              adaptiveAccent: adaptiveAccent,
            ),
          ),
        );
      },
    );
  }

  Widget _loadingStrip() {
    return SizedBox(
      height: 310,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 41),
        itemBuilder: (_, __) =>
            _ShimmerCard(isDark: isDark, surface: surface, border: border),
      ),
    );
  }
}

class _MasterpieceCard extends StatefulWidget {
  final ProductModel product;
  final bool isDark;
  final Color bg, surface, border, textPrimary, textSecondary, adaptiveAccent;

  const _MasterpieceCard({
    super.key,
    required this.product,
    required this.isDark,
    required this.bg,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.adaptiveAccent,
  });

  @override
  State<_MasterpieceCard> createState() => _MasterpieceCardState();
}

class _MasterpieceCardState extends State<_MasterpieceCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return GestureDetector(
      onTap: () {
        HapticFeedback.heavyImpact();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductDetailPage(product: p)),
        );
      },
      child: SizedBox(
        width: 240,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: Container(
                decoration: BoxDecoration(
                  color: widget.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: widget.border, width: 0.5),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: RadialGradient(
                            center: const Alignment(0, -0.3),
                            radius: 0.8,
                            colors: [
                              widget.adaptiveAccent.withValues(
                                alpha: widget.isDark ? 0.10 : 0.05,
                              ),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (p.soldCount > 100)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: widget.adaptiveAccent.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: widget.adaptiveAccent.withValues(
                                alpha: 0.2,
                              ),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            'BESTSELLER',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: widget.adaptiveAccent,
                            ),
                          ),
                        ),
                      ),
                    Center(
                      child: AnimatedBuilder(
                        animation: _float,
                        builder: (_, child) => Transform.translate(
                          offset: Offset(0, -4 + _float.value * 8),
                          child: child,
                        ),
                        child: Hero(
                          tag: 'masterpiece_${p.id}',
                          child: CachedNetworkImage(
                            imageUrl: p.image,
                            width: 110,
                            height: 110,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            Text(
              (p.brandName ?? '').toUpperCase(),
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.0,
                color: widget.adaptiveAccent,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              p.baseName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.3,
                color: widget.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  p.hasPriceRange
                      ? 'Từ ${formatVND(p.minPrice)}'
                      : formatVND(p.price),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                    color: widget.textPrimary,
                  ),
                ),
                if (p.averageRating > 0)
                  Row(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 11,
                        color: Colors.amber[600],
                      ),
                      const SizedBox(width: 3),
                      Text(
                        p.averageRating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 11,
                          color: widget.textSecondary,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterTabs extends StatelessWidget {
  final bool isDark;
  final Color border, textPrimary, textSecondary, adaptiveAccent;

  const _FilterTabs({
    required this.isDark,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.adaptiveAccent,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BrandProductsCubit, BrandProductsState>(
      builder: (context, state) {
        if (state is! BrandProductsLoaded) return const SizedBox.shrink();

        return Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: border, width: 0.5)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: state.categories.map((cat) {
                final isActive = state.selectedCategoryId == cat.id;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    context.read<BrandProductsCubit>().filterByCategory(cat.id);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 28),
                    padding: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isActive ? adaptiveAccent : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                    ),
                    child: Text(
                      cat.title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.w400,
                        letterSpacing: 0.2,
                        color: isActive ? textPrimary : textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

class _ProductMosaicGrid extends StatelessWidget {
  final bool isDark;
  final Color border, bg, textPrimary, adaptiveAccent;

  const _ProductMosaicGrid({
    required this.isDark,
    required this.border,
    required this.bg,
    required this.textPrimary,
    required this.adaptiveAccent,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BrandProductsCubit, BrandProductsState>(
      builder: (context, state) {
        if (state is BrandProductsLoading) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 60),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: adaptiveAccent.withValues(alpha: 0.6),
                ),
              ),
            ),
          );
        }

        if (state is! BrandProductsLoaded) return const SizedBox.shrink();

        if (state.displayProducts.isEmpty) {
          return _emptyState();
        }

        final products = state.displayProducts;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: border, width: 0.5),
              borderRadius: BorderRadius.circular(14),
            ),
            clipBehavior: Clip.hardEdge,
            child: Column(
              children: List.generate((products.length / 2).ceil(), (rowIdx) {
                final left = products[rowIdx * 2];
                final hasRight = rowIdx * 2 + 1 < products.length;
                final right = hasRight ? products[rowIdx * 2 + 1] : null;
                final isLastRow = rowIdx == (products.length / 2).ceil() - 1;

                return Container(
                  decoration: BoxDecoration(
                    border: isLastRow
                        ? null
                        : Border(bottom: BorderSide(color: border, width: 0.5)),
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _MosaicCell(
                            product: left,
                            isDark: isDark,
                            bg: bg,
                            textPrimary: textPrimary,
                            adaptiveAccent: adaptiveAccent,
                          ),
                        ),
                        Container(width: 0.5, color: border),
                        Expanded(
                          child: right != null
                              ? _MosaicCell(
                                  product: right,
                                  isDark: isDark,
                                  bg: bg,
                                  textPrimary: textPrimary,
                                  adaptiveAccent: adaptiveAccent,
                                )
                              : Container(color: bg),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 40),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: border, width: 0.5),
            ),
            child: Icon(
              Icons.blur_on_rounded,
              size: 18,
              color: textPrimary.withValues(alpha: 0.15),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Bộ sưu tập đang được\ntinh tuyển.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              height: 1.5,
              color: textPrimary.withValues(alpha: 0.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _MosaicCell extends StatelessWidget {
  final ProductModel product;
  final bool isDark;
  final Color bg, textPrimary, adaptiveAccent;

  const _MosaicCell({
    required this.product,
    required this.isDark,
    required this.bg,
    required this.textPrimary,
    required this.adaptiveAccent,
  });

  @override
  Widget build(BuildContext context) {
    final p = product;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductDetailPage(product: p)),
        );
      },
      child: Container(
        color: bg,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Center(
                child: CachedNetworkImage(
                  imageUrl: p.image,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              p.baseName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                height: 1.35,
                letterSpacing: -0.1,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              p.hasPriceRange
                  ? 'Từ ${formatVND(p.minPrice)}'
                  : formatVND(p.price),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
                color: adaptiveAccent,
              ),
            ),
            if (p.averageRating > 0) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.star_rounded, size: 9, color: Colors.amber[600]),
                  const SizedBox(width: 2),
                  Text(
                    p.averageRating.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 9,
                      color: textPrimary.withValues(alpha: 0.35),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HairlineDivider extends StatelessWidget {
  final Color color;
  final double horizontal;

  const _HairlineDivider({required this.color, this.horizontal = 0});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontal),
      child: Container(
        height: 0.5,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.transparent, color, Colors.transparent],
          ),
        ),
      ),
    );
  }
}

class _ShimmerCard extends StatefulWidget {
  final bool isDark;
  final Color surface, border;

  const _ShimmerCard({
    required this.isDark,
    required this.surface,
    required this.border,
  });

  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final opacity = 0.04 + _anim.value * 0.06;
        return SizedBox(
          width: 240,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 4 / 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: (widget.isDark ? Colors.white : Colors.black)
                        .withValues(alpha: opacity),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: widget.border, width: 0.5),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                height: 8,
                width: 60,
                decoration: BoxDecoration(
                  color: (widget.isDark ? Colors.white : Colors.black)
                      .withValues(alpha: opacity),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: 12,
                width: 140,
                decoration: BoxDecoration(
                  color: (widget.isDark ? Colors.white : Colors.black)
                      .withValues(alpha: opacity * 0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MeshGridPainter extends CustomPainter {
  final Color lineColor;
  final double gridSize, fadeCenterX, fadeCenterY;

  _MeshGridPainter({
    required this.lineColor,
    required this.gridSize,
    required this.fadeCenterX,
    required this.fadeCenterY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.5;

    final fadeRadius = size.width * 0.7;

    for (double x = 0; x <= size.width; x += gridSize) {
      final distFromCenter = math.sqrt(math.pow(x - fadeCenterX, 2));
      final alpha = (1.0 - (distFromCenter / fadeRadius)).clamp(0.0, 1.0);
      if (alpha <= 0) continue;
      paint.color = lineColor.withValues(alpha: lineColor.a * alpha * 0.8);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y <= size.height; y += gridSize) {
      final distFromCenter = math.sqrt(math.pow(y - fadeCenterY, 2) * 0.5);
      final alpha = (1.0 - (distFromCenter / (fadeRadius * 0.8))).clamp(
        0.0,
        1.0,
      );
      if (alpha <= 0) continue;
      paint.color = lineColor.withValues(alpha: lineColor.a * alpha * 0.6);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_MeshGridPainter old) =>
      old.lineColor != lineColor ||
      old.fadeCenterX != fadeCenterX ||
      old.fadeCenterY != fadeCenterY;
}
