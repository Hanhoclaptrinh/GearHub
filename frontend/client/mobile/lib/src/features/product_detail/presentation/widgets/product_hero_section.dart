import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/src/shared/models/product_asset_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:mobile/src/core/utils/formatter_utils.dart';
import 'package:mobile/src/shared/models/product_model.dart';
import 'package:mobile/src/shared/models/product_variant_model.dart';
import 'package:mobile/src/core/utils/brand_identity_helper.dart';

class ProductHeroSection extends StatefulWidget {
  final ProductModel product;
  final ProductVariantModel? currentVariant;
  final Map<String, String> selectedAttributes;
  final bool is3DMode;
  final double scrollOffset;
  final Function(String, String) onAttributeChanged;
  final VoidCallback on3DToggle;
  final VoidCallback onARPressed;

  const ProductHeroSection({
    super.key,
    required this.product,
    required this.currentVariant,
    required this.selectedAttributes,
    required this.is3DMode,
    required this.scrollOffset,
    required this.onAttributeChanged,
    required this.on3DToggle,
    required this.onARPressed,
  });

  @override
  State<ProductHeroSection> createState() => _ProductHeroSectionState();
}

class _ProductHeroSectionState extends State<ProductHeroSection> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final Color bgColor = theme.scaffoldBackgroundColor;
    final Color surfaceAlt = cs.surfaceContainerHighest;
    final Color borderCol = cs.outlineVariant;
    final Color textHigh = cs.onSurface;
    final Color textLow = cs.onSurfaceVariant;
    final Color brandAccent = BrandIdentityHelper.getIdentity(
      widget.product.brandName ?? '',
    ).accent;

    final size = MediaQuery.of(context).size;
    final currentVariant = widget.currentVariant;
    final isOutOfStock = (currentVariant?.stock ?? 0) <= 0;

    final List<String> galleryUrls = [];
    if (widget.currentVariant != null) {
      final variantAssets = widget.product.assets
          .where(
            (a) =>
                a.variantId == widget.currentVariant!.id &&
                a.type == AssetType.image,
          )
          .map((a) => a.url)
          .toList();
      if (variantAssets.isNotEmpty) {
        galleryUrls.addAll(variantAssets);
      } else if (widget.currentVariant!.imageUrl != null &&
          widget.currentVariant!.imageUrl!.isNotEmpty) {
        galleryUrls.add(widget.currentVariant!.imageUrl!);
      }
    }

    if (galleryUrls.isEmpty) {
      galleryUrls.addAll(widget.product.galleryUrls);
    }

    String displayName = widget.product.baseName;
    if (widget.currentVariant != null) {
      final nonColorConfigs = <String>[];
      widget.currentVariant!.attributes.forEach((key, val) {
        final k = key.toLowerCase();
        if (!k.contains('màu') && !k.contains('color') && !k.contains('mau')) {
          nonColorConfigs.add(val.toString());
        }
      });
      if (nonColorConfigs.isNotEmpty) {
        displayName += ' ' + nonColorConfigs.join(' ');
      }
    }

    //parallax scroll
    final double brandParallax = widget.scrollOffset < 150
        ? widget.scrollOffset * 0.1
        : (150 * 0.1) + (widget.scrollOffset - 150) * 0.8;

    return Container(
      width: double.infinity,
      color: Colors.transparent,
      child: Stack(
        children: [
          //brand name xoay dọc giữa
          Positioned(
            top: 80 + brandParallax,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: 0.08,
              child: Center(
                child: RotatedBox(
                  quarterTurns: 1,
                  child: SizedBox(
                    width: 600,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Text(
                        widget.product.brandName?.toUpperCase() ?? "GEARHUB",
                        maxLines: 1,
                        softWrap: false,
                        style: GoogleFonts.boldonse(
                          textStyle: TextStyle(
                            fontSize: 80,
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.italic,
                            color: textHigh,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top + 40),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: textHigh,
                        height: 1.1,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      height: 1,
                      width: 40,
                      color: brandAccent.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 24),
                    if (currentVariant != null && currentVariant.hasActiveFlashSale) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              Text(
                                formatVND(currentVariant.flashPrice!),
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFF59E0B),
                                  height: 1.0,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.flash_on_rounded, size: 12, color: Color(0xFFF59E0B)),
                                    SizedBox(width: 2),
                                    Text(
                                      "FLASH SALE",
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFFF59E0B),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                formatVND(currentVariant.price),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: textLow.withValues(alpha: 0.5),
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Tiết kiệm ${formatVND(currentVariant.price - currentVariant.flashPrice!)}",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF22C55E).withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatVND(
                              currentVariant?.price ?? widget.product.price,
                            ),
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w200,
                              color: textHigh,
                              height: 1.0,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6, left: 8),
                            child: Text(
                              "NIÊM YẾT",
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                color: textLow.withValues(alpha: 0.6),
                                letterSpacing: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 40),

              SizedBox(
                height: size.height * 0.4,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      top: 40,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: brandAccent.withValues(alpha: 0.08),
                              blurRadius: 100,
                              spreadRadius: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    (widget.is3DMode && widget.product.has3DModelForVariant(widget.currentVariant))
                        ? _build3DViewer()
                        : _buildImageGallery(galleryUrls, isOutOfStock),

                    if (widget.product.has3DModelForVariant(widget.currentVariant) || widget.product.hasARForVariant(widget.currentVariant))
                      Positioned(
                        top: 12,
                        right: 24,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.product.has3DModelForVariant(widget.currentVariant))
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  widget.on3DToggle();
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: widget.is3DMode
                                        ? textHigh
                                        : surfaceAlt.withValues(alpha: 0.85),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: widget.is3DMode
                                          ? Colors.transparent
                                          : borderCol.withValues(alpha: 0.5),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.05,
                                        ),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        widget.is3DMode
                                            ? LucideIcons.image
                                            : LucideIcons.rotate3d,
                                        size: 14,
                                        color: widget.is3DMode
                                            ? bgColor
                                            : textHigh,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        widget.is3DMode ? '2D' : '3D',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: widget.is3DMode
                                              ? bgColor
                                              : textHigh,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (widget.product.hasARForVariant(widget.currentVariant)) ...[
                              if (widget.product.has3DModelForVariant(widget.currentVariant))
                                const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  widget.onARPressed();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: surfaceAlt.withValues(alpha: 0.85),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: borderCol.withValues(alpha: 0.5),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.05,
                                        ),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        LucideIcons.box,
                                        size: 14,
                                        color: brandAccent,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'AR',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: textHigh,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              if (!widget.is3DMode && galleryUrls.length > 1) ...[
                const SizedBox(height: 16),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(galleryUrls.length, (i) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 2.5),
                          width: _currentPage == i ? 12 : 5,
                          height: 2,
                          decoration: BoxDecoration(
                            color: _currentPage == i
                                ? brandAccent
                                : textLow.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(2.5),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),
            ],
          ),
        ],
      ),
    );
  }

  //2d viewer
  Widget _buildImageGallery(List<String> urls, bool isOutOfStock) {
    if (urls.isEmpty) {
      return const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 48,
          color: Colors.grey,
        ),
      );
    }

    if (urls.length == 1) {
      return _buildSingleImage(urls.first, isOutOfStock);
    }

    return PageView.builder(
      controller: _pageController,
      itemCount: urls.length,
      onPageChanged: (i) => setState(() => _currentPage = i),
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => _openGallery(context, urls, index),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
            child: Center(
              child: _buildNetworkImage(
                urls[index],
                isOutOfStock,
                heroTag: index == 0
                    ? 'product_${widget.product.id}'
                    : 'product_gallery_$index',
              ),
            ),
          ),
        );
      },
    );
  }

  void _openGallery(BuildContext context, List<String> urls, int initialIndex) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16),
          backgroundColor: Colors.transparent,
          child: _ProductGalleryModal(images: urls, initialIndex: initialIndex),
        );
      },
    );
  }

  Widget _buildSingleImage(String url, bool isOutOfStock) {
    return GestureDetector(
      onTap: () => _openGallery(context, [url], 0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Hero(
            tag: 'product_${widget.product.id}',
            child: _buildFilteredImage(url, isOutOfStock),
          ),
        ),
      ),
    );
  }

  Widget _buildNetworkImage(String url, bool isOutOfStock, {String? heroTag}) {
    final imageWidget = _buildFilteredImage(url, isOutOfStock);
    if (heroTag != null) {
      return Hero(tag: heroTag, child: imageWidget);
    }
    return imageWidget;
  }

  Widget _buildFilteredImage(String url, bool isOutOfStock) {
    return ColorFiltered(
      colorFilter: isOutOfStock
          ? const ColorFilter.matrix([
              0.2126,
              0.7152,
              0.0722,
              0,
              0,
              0.2126,
              0.7152,
              0.0722,
              0,
              0,
              0.2126,
              0.7152,
              0.0722,
              0,
              0,
              0,
              0,
              0,
              1,
              0,
            ])
          : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
      child: url.startsWith('http')
          ? CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.contain,
              placeholder: (_, __) => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              errorWidget: (_, __, ___) => const Icon(
                Icons.broken_image_outlined,
                size: 40,
                color: Colors.grey,
              ),
            )
          : url.isNotEmpty
          ? Image.asset(
              url,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.broken_image_outlined,
                size: 40,
                color: Colors.grey,
              ),
            )
          : const Icon(
              Icons.image_not_supported_outlined,
              size: 40,
              color: Colors.grey,
            ),
    );
  }

  //3D viewer
  Widget _build3DViewer() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final glbAsset = widget.product.glbAssetForVariant(widget.currentVariant);
    if (glbAsset == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: ModelViewer(
          key: ValueKey(glbAsset.url),
          src: glbAsset.url,
          alt: widget.product.name,
          autoRotate: false,
          cameraControls: true,
          disableZoom: false,
          backgroundColor: Colors.transparent,
        ),
      ),
    );
  }
}

class _ProductGalleryModal extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _ProductGalleryModal({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_ProductGalleryModal> createState() => _ProductGalleryModalState();
}

class _ProductGalleryModalState extends State<_ProductGalleryModal> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final surface = theme.cardColor;
    final border = cs.outlineVariant;
    final surfaceAlt = cs.surfaceContainerHighest;
    final textHigh = cs.onSurface;
    final textLow = cs.onSurfaceVariant.withValues(alpha: 0.4);

    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.58,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 24,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 16,
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: surfaceAlt,
                  shape: BoxShape.circle,
                  border: Border.all(color: border),
                ),
                child: Icon(LucideIcons.x, color: textHigh, size: 20),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 64, 16, 24),
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: widget.images.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final url = widget.images[index];
                      return Center(
                        child: InteractiveViewer(
                          clipBehavior: Clip.none,
                          minScale: 1.0,
                          maxScale: 4.0,
                          child: url.startsWith('http')
                              ? CachedNetworkImage(
                                  imageUrl: url,
                                  fit: BoxFit.contain,
                                  placeholder: (_, __) => const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  errorWidget: (_, __, ___) => const Icon(
                                    Icons.broken_image_outlined,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                )
                              : url.isNotEmpty
                              ? Image.asset(
                                  url,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.broken_image_outlined,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                )
                              : const Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.images.length, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: _currentIndex == index ? 8 : 6,
                      height: _currentIndex == index ? 8 : 6,
                      decoration: BoxDecoration(
                        color: _currentIndex == index ? textHigh : textLow,
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
