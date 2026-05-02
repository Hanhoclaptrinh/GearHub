import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/src/shared/models/product_asset_model.dart';
import '../pages/product_gallery_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:mobile/src/core/utils/formatter_utils.dart';
import 'package:mobile/src/shared/models/product_model.dart';
import 'package:mobile/src/shared/models/product_variant_model.dart';

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
          .where((a) => a.variantId == widget.currentVariant!.id && a.type == AssetType.image)
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
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- header: brand + name + availability + price ---
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product.brandName?.toUpperCase() ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8E8E93),
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  displayName.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                    letterSpacing: -0.5,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isOutOfStock
                            ? const Color(0xFFFF3B30)
                            : const Color(0xFF34C759),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                                (isOutOfStock
                                        ? const Color(0xFFFF3B30)
                                        : const Color(0xFF34C759))
                                    .withValues(alpha: 0.3),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isOutOfStock
                          ? 'Hết hàng'
                          : 'Còn hàng - ${currentVariant?.stock} có sẵn',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isOutOfStock
                            ? const Color(0xFFFF3B30)
                            : const Color(0xFF34C759),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  formatVND(currentVariant?.price ?? widget.product.price),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                    letterSpacing: -1.0,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // --- image area: gallery / 3D viewer ---
          SizedBox(
            height: size.height * 0.35,
            child: Stack(
              children: [
                // change 2d / 3d mode
                if (widget.is3DMode && widget.product.has3DModel)
                  _build3DViewer()
                else
                  _buildImageGallery(galleryUrls, isOutOfStock),

                // 3D toggle button
                if (widget.product.has3DModel)
                  Positioned(
                    right: 24,
                    bottom: 12,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        widget.on3DToggle();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: widget.is3DMode ? Colors.black : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: widget.is3DMode
                                ? Colors.white24
                                : const Color(0xFFE5E5EA),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
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
                              size: 16,
                              color: widget.is3DMode
                                  ? Colors.white
                                  : Colors.black,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.is3DMode ? '2D' : '3D',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: widget.is3DMode
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else if (widget.product.hasAR)
                  Positioned(
                    right: 24,
                    bottom: 12,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        widget.onARPressed();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFE5E5EA)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(LucideIcons.box, size: 18, color: Theme.of(context).primaryColor),
                            const SizedBox(width: 8),
                            const Text(
                              'Thử trong không gian',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // indicator in 2d mode
                if (!widget.is3DMode && galleryUrls.length > 1)
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(galleryUrls.length, (i) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: _currentPage == i ? 20 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _currentPage == i
                                ? Colors.black
                                : Colors.black.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),
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
                heroTag: index == 0 ? 'product_${widget.product.id}' : 'product_gallery_$index',
              ),
            ),
          ),
        );
      },
    );
  }

  void _openGallery(BuildContext context, List<String> urls, int initialIndex) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => 
          ProductGalleryPage(
            images: urls, 
            initialIndex: initialIndex,
            mainHeroTag: 'product_${widget.product.id}',
          ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: ModelViewer(
        src: glbAsset.url,
        alt: widget.product.name,
        autoRotate: false,
        cameraControls: true,
        disableZoom: false,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
    );
  }
}
