import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/src/shared/models/product_asset_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:mobile/src/core/utils/formatter_utils.dart';
import 'package:mobile/src/shared/models/product_model.dart';
import 'package:mobile/src/shared/models/product_variant_model.dart';

const _bg = Color(0xFF0A0A10);
const _surface = Color(0xFF14141E);
const _surfaceAlt = Color(0xFF1C1C28);
const _border = Color(0xFF2A2A38);
const _accent = Color(0xFF6366F1);
const _textHigh = Color(0xFFF1F1F5);
const _textLow = Color(0xFF4A4A62);

class ProductHeroSection extends StatefulWidget {
  final ProductModel product;
  final ProductVariantModel? currentVariant;
  final Map<String, String> selectedAttributes;
  final bool is3DMode;
  final Function(String, String) onAttributeChanged;
  final VoidCallback on3DToggle;
  final VoidCallback onARPressed;

  const ProductHeroSection({
    super.key,
    required this.product,
    required this.currentVariant,
    required this.selectedAttributes,
    required this.is3DMode,
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

    return Container(
      width: double.infinity,
      color: _bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- header: brand + name + availability + price ---
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _surfaceAlt,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _border),
                      ),
                      child: Text(
                        widget.product.brandName?.toUpperCase() ?? 'GEARHUB',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: _accent,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    _buildAvailabilityBadge(
                      isOutOfStock,
                      currentVariant?.stock ?? 0,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  displayName.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: _textHigh,
                    letterSpacing: -0.8,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'GIÁ HIỆN TẠI',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _textLow,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatVND(currentVariant?.price ?? widget.product.price),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: _textHigh,
                        letterSpacing: -1.5,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // --- image area: gallery / 3D viewer ---
          SizedBox(
            height: size.height * 0.35,
            child: widget.is3DMode && widget.product.has3DModel
                ? _build3DViewer()
                : _buildImageGallery(galleryUrls, isOutOfStock),
          ),

          // action button & indicator row
          if ((!widget.is3DMode && galleryUrls.length > 1) ||
              widget.product.has3DModel ||
              widget.product.hasAR)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // indicator
                  if (!widget.is3DMode && galleryUrls.length > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _surfaceAlt.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _border.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(galleryUrls.length, (i) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            width: _currentPage == i ? 16 : 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: _currentPage == i
                                  ? _accent
                                  : _textLow.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        }),
                      ),
                    )
                  else
                    const SizedBox.shrink(),

                  // toggle button
                  if (widget.product.has3DModel)
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        widget.on3DToggle();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: widget.is3DMode ? _textHigh : _surfaceAlt,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: widget.is3DMode
                                ? Colors.transparent
                                : _border,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.is3DMode
                                  ? LucideIcons.image
                                  : LucideIcons.rotate3d,
                              size: 16,
                              color: widget.is3DMode ? _bg : _textHigh,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.is3DMode ? '2D' : '3D',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: widget.is3DMode ? _bg : _textHigh,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (widget.product.hasAR)
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        widget.onARPressed();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _surfaceAlt,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _border),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.box, size: 16, color: _accent),
                            SizedBox(width: 6),
                            Text(
                              'AR Mode',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: _textHigh,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // 2d viwer
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
          : Image.asset(url, fit: BoxFit.contain),
    );
  }

  // 3D viewer
  Widget _build3DViewer() {
    final glbAsset = widget.product.glbAsset;
    if (glbAsset == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: _border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: ModelViewer(
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

  Widget _buildAvailabilityBadge(bool isOutOfStock, int stock) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color:
            (isOutOfStock ? const Color(0xFFEF4444) : const Color(0xFF10B981))
                .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color:
              (isOutOfStock ? const Color(0xFFEF4444) : const Color(0xFF10B981))
                  .withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isOutOfStock
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isOutOfStock ? 'HẾT HÀNG' : 'SẴN HÀNG',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: isOutOfStock
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF10B981),
              letterSpacing: 0.5,
            ),
          ),
        ],
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
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.58,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
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
                  color: _surfaceAlt,
                  shape: BoxShape.circle,
                  border: Border.all(color: _border),
                ),
                child: const Icon(LucideIcons.x, color: _textHigh, size: 20),
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
                              : Image.asset(url, fit: BoxFit.contain),
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
                        color: _currentIndex == index ? _textHigh : _textLow,
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
