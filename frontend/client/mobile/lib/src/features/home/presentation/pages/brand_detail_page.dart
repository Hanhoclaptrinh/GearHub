import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile/src/core/di/injection.dart';
import 'package:mobile/src/core/utils/brand_identity_helper.dart';
import 'package:mobile/src/core/utils/formatter_utils.dart';
import 'package:mobile/src/features/home/domain/entities/brand_entity.dart';
import 'package:mobile/src/features/home/presentation/state/brand_products_cubit.dart';
import 'package:mobile/src/features/product_detail/presentation/pages/product_detail_page.dart';
import 'package:mobile/src/shared/models/product_model.dart';
import 'package:mobile/src/shared/widgets/glassmorphic_header.dart';
import 'package:mobile/src/shared/widgets/small_product_card.dart';

const _bg = Color(0xFF07070A);
const _textMid = Color(0xFF9191A8);

class BrandDetailPage extends StatelessWidget {
  final BrandEntity brand;

  const BrandDetailPage({super.key, required this.brand});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          getIt<BrandProductsCubit>(param1: brand)..loadBrandData(),
      child: BrandDetailStorytellingView(brand: brand),
    );
  }
}

class BrandDetailStorytellingView extends StatefulWidget {
  final BrandEntity brand;
  const BrandDetailStorytellingView({super.key, required this.brand});

  @override
  State<BrandDetailStorytellingView> createState() =>
      _BrandDetailStorytellingViewState();
}

class _BrandDetailStorytellingViewState
    extends State<BrandDetailStorytellingView> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() => _scrollOffset = _scrollController.offset);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _getStoryConfig(String name) {
    final identity = BrandIdentityHelper.getIdentity(name);

    // ghi de data tu backend
    final String? remoteQuote = widget.brand.quote;
    final String? remotePhil = widget.brand.philosophy;

    return {
      'quote': (remoteQuote != null && remoteQuote.isNotEmpty)
          ? remoteQuote
          : identity.quote,
      'philosophy': (remotePhil != null && remotePhil.isNotEmpty)
          ? remotePhil
          : identity.philosophy,
      'accent': identity.accent,
    };
  }

  @override
  Widget build(BuildContext context) {
    final story = _getStoryConfig(widget.brand.name);
    final size = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top;

    // docking title
    const double startOffset = 0.0;
    const double endOffset = 250.0;
    final double t = ((_scrollOffset - startOffset) / (endOffset - startOffset))
        .clamp(0.0, 1.0);

    final double titleSize = lerpDouble(64, 20, t)!;
    final double titleTop = lerpDouble(size.height * 0.35, topPadding + 20, t)!;
    final double opacity = (1.0 - (_scrollOffset - 250) / 100).clamp(0.0, 1.0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _bg,
        body: Stack(
          children: [
            // bg
            _buildDynamicBackground(story['accent']),

            // content
            CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildIdentitySpace(size, story, t),

                _RevealSection(child: _buildPhilosophySection(story)),
                _RevealSection(child: _buildMasterpieceShowcase(story)),
                _RevealSection(child: _buildCollectionHeader()),
                _buildProductGrid(story['accent']),

                const SliverToBoxAdapter(child: SizedBox(height: 60)),
              ],
            ),

            GlassmorphicHeader(
              scrollOffset: _scrollOffset,
              title: _scrollOffset > 250 ? widget.brand.name.toUpperCase() : "",
              onBack: () => Navigator.pop(context),
              maxScroll: 250,
              centerTitle: true,
            ),

            Positioned(
              top: titleTop,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Opacity(
                  opacity: opacity,
                  child: Center(
                    child: Text(
                      widget.brand.name.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: lerpDouble(-4, 1.2, t)!,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicBackground(Color accent) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.7, -0.6),
            radius: 1.2,
            colors: [accent.withValues(alpha: 0.12), _bg],
          ),
        ),
      ),
    );
  }

  Widget _buildIdentitySpace(Size size, Map<String, dynamic> story, double t) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: size.height * 0.8,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // zoom-in portal logo
            Positioned(
              top: size.height * 0.15,
              child: Transform.scale(
                scale: 1 + (t * 2.5),
                child: Opacity(
                  opacity: (1 - t * 1.8).clamp(0.0, 1.0),
                  child: SvgPicture.network(
                    widget.brand.logoUrl,
                    width: size.width * 0.7,
                    colorFilter: ColorFilter.mode(
                      Colors.white.withValues(alpha: 0.02),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
            // quote
            Positioned(
              top: size.height * 0.5,
              left: 0,
              right: 0,
              child: Opacity(
                opacity: (1 - t * 3).clamp(0.0, 1.0),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: story['accent'].withValues(alpha: 0.4),
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      story['quote'],
                      style: TextStyle(
                        color: story['accent'],
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 40,
              child: Opacity(
                opacity: (1 - t * 5).clamp(0.0, 1.0),
                child: Container(
                  width: 1,
                  height: 60,
                  color: story['accent'].withValues(alpha: 0.3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhilosophySection(Map<String, dynamic> story) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 100),
      child: Column(
        children: [
          Icon(Icons.auto_awesome_rounded, color: story['accent'], size: 28),
          const SizedBox(height: 40),
          Text(
            "“${story['philosophy']}”",
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w300,
              height: 1.6,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMasterpieceShowcase(Map<String, dynamic> story) {
    return BlocBuilder<BrandProductsCubit, BrandProductsState>(
      builder: (context, state) {
        if (state is! BrandProductsLoaded) return const SizedBox.shrink();

        // totalsold -> top rating
        final masterpieces = List<ProductModel>.from(state.allProducts)
          ..sort((a, b) {
            int soldCmp = b.soldCount.compareTo(a.soldCount);
            if (soldCmp != 0) return soldCmp;
            return b.averageRating.compareTo(a.averageRating);
          });

        final top3 = masterpieces.take(3).toList();
        if (top3.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'SIGNATURES',
                style: TextStyle(
                  fontSize: 45,
                  fontWeight: FontWeight.w900,
                  color: story['accent'].withValues(alpha: 0.1),
                  letterSpacing: -2,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 380,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: masterpieces.length,
                itemBuilder: (context, index) {
                  final p = masterpieces[index];
                  return _MasterpieceCard(product: p, accent: story['accent']);
                },
              ),
            ),
            const SizedBox(height: 80),
          ],
        );
      },
    );
  }

  Widget _buildCollectionHeader() {
    return BlocBuilder<BrandProductsCubit, BrandProductsState>(
      builder: (context, state) {
        if (state is! BrandProductsLoaded) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: [
                  const Text(
                    'COLLECTIONS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                ],
              ),
            ),

            // cate filter
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                physics: const BouncingScrollPhysics(),
                itemCount: state.categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final item = state.categories[index];
                  final isSelected = state.selectedCategoryId == item.id;

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      context.read<BrandProductsCubit>().filterByCategory(
                        item.id,
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.05),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            color: isSelected ? Colors.white : _textMid,
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _buildProductGrid(Color accent) {
    return BlocBuilder<BrandProductsCubit, BrandProductsState>(
      builder: (context, state) {
        if (state is BrandProductsLoading) {
          return const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (state is BrandProductsLoaded) {
          if (state.displayProducts.isEmpty) {
            return SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 80,
                  horizontal: 40,
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.02),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Icon(
                        Icons.blur_on_rounded,
                        color: Colors.white.withValues(alpha: 0.2),
                        size: 64,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'MỘT TRẢI NGHIỆM MỚI ĐANG ĐẾN',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Bộ sưu tập huyền thoại đang được tinh tuyển.\nHãy sẵn sàng cho sự bùng nổ tiếp theo.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _textMid,
                        fontSize: 12,
                        height: 1.6,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.68,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    SmallProductCard(product: state.displayProducts[index]),
                childCount: state.displayProducts.length,
              ),
            ),
          );
        }
        return const SliverToBoxAdapter(child: SizedBox.shrink());
      },
    );
  }
}

class _RevealSection extends StatefulWidget {
  final Widget child;
  const _RevealSection({required this.child});

  @override
  State<_RevealSection> createState() => _RevealSectionState();
}

class _RevealSectionState extends State<_RevealSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _slide;
  late Animation<double> _blur;
  bool _hasRevealed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slide = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _blur = Tween<double>(begin: 15.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onVisibilityChanged(double visibility) {
    if (visibility > 0.1 && !_hasRevealed) {
      if (mounted) {
        setState(() => _hasRevealed = true);
        _controller.forward();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: _VisibilityDetector(
        onVisibilityChanged: _onVisibilityChanged,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _opacity.value,
              child: Transform.translate(
                offset: Offset(0, _slide.value),
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(
                    sigmaX: _blur.value,
                    sigmaY: _blur.value,
                  ),
                  child: widget.child,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _VisibilityDetector extends StatefulWidget {
  final Widget child;
  final Function(double) onVisibilityChanged;

  const _VisibilityDetector({
    required this.child,
    required this.onVisibilityChanged,
  });

  @override
  State<_VisibilityDetector> createState() => _VisibilityDetectorState();
}

class _VisibilityDetectorState extends State<_VisibilityDetector> {
  final GlobalKey _key = GlobalKey();
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
  }

  void _checkVisibility() {
    if (!mounted) return;
    final RenderObject? renderObject = _key.currentContext?.findRenderObject();
    if (renderObject is RenderBox) {
      final position = renderObject.localToGlobal(Offset.zero);
      final size = renderObject.size;
      final screenHeight = MediaQuery.of(context).size.height;

      final bool isVisible =
          position.dy < screenHeight && position.dy + size.height > 0;

      if (isVisible != _isVisible) {
        _isVisible = isVisible;
        if (_isVisible) widget.onVisibilityChanged(1.0);
      }
    }

    Future.delayed(const Duration(milliseconds: 250), _checkVisibility);
  }

  @override
  Widget build(BuildContext context) {
    return Container(key: _key, child: widget.child);
  }
}

class _MasterpieceCard extends StatelessWidget {
  final ProductModel product;
  final Color accent;

  const _MasterpieceCard({required this.product, required this.accent});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.heavyImpact();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductDetailPage(product: product),
          ),
        );
      },
      child: Container(
        width: 300,
        margin: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2A2D34),
              Color(0xFF141519),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: 60,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(
                          alpha: 0.15,
                        ),
                        blurRadius: 60,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(width: 16, height: 1, color: accent),
                      const SizedBox(width: 8),
                      Text(
                        'SIGNATURE SERIES',
                        style: TextStyle(
                          color: accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing:
                              2.5,
                        ),
                      ),
                    ],
                  ),

                  // img
                  Expanded(
                    child: Center(
                      child: Hero(
                        tag: 'masterpiece_${product.id}',
                        child: CachedNetworkImage(
                          imageUrl: product.image,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  Text(
                    product.baseName.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight
                          .w600,
                      letterSpacing: 1.2,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),

                  Container(
                    height: 1,
                    width: 48,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 16),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (product.variants.length > 1)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            'TỪ',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      Text(
                        formatVND(product.price),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
