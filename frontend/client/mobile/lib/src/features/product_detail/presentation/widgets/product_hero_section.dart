import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final int quantity;
  final int maxQuantity;
  final Function(String, String) onAttributeChanged;
  final VoidCallback on3DToggle;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onLongPressIncrement;
  final VoidCallback onLongPressDecrement;
  final VoidCallback onLongPressEnd;

  const ProductHeroSection({
    super.key,
    required this.product,
    required this.currentVariant,
    required this.selectedAttributes,
    required this.is3DMode,
    required this.quantity,
    required this.maxQuantity,
    required this.onAttributeChanged,
    required this.on3DToggle,
    required this.onIncrement,
    required this.onDecrement,
    required this.onLongPressIncrement,
    required this.onLongPressDecrement,
    required this.onLongPressEnd,
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

  // parse color --------------------
  String _getColorKey() {
    if (widget.product.attributeConfig.isNotEmpty) {
      return widget.product.attributeConfig.firstWhere((k) {
        final lower = k.toLowerCase();
        return lower.contains('color') ||
            lower.contains('màu') ||
            lower.contains('mau');
      }, orElse: () => widget.product.attributeConfig.first);
    }

    if (widget.product.variants.isEmpty) return 'color';
    return widget.product.variants.first.attributes.keys.firstWhere((k) {
      final lower = k.toLowerCase();
      return lower.contains('color') ||
          lower.contains('màu') ||
          lower.contains('mau');
    }, orElse: () => 'color');
  }

  List<String> _getUniqueColors() {
    final colorKey = _getColorKey();
    return widget.product.variants
        .where((v) => v.isActive)
        .map((v) => v.attributes[colorKey]?.toString())
        .whereType<String>()
        .toSet()
        .toList();
  }

  Color _parseColor(String? colorName) {
    if (colorName == null) return Colors.grey;
    final name = colorName.toLowerCase();
    if (name.contains('gray') || name.contains('xám')) {
      return const Color(0xFF1C1C1E);
    }
    if (name.contains('silver') || name.contains('bạc')) {
      return const Color(0xFFE5E5EA);
    }
    if (name.contains('gold') || name.contains('vàng')) {
      return const Color(0xFFFACC15);
    }
    if (name.contains('black') || name.contains('đen')) return Colors.black;
    if (name.contains('white') || name.contains('trắng')) return Colors.white;
    if (name.contains('blue') || name.contains('xanh dương')) {
      return const Color(0xFF007AFF);
    }
    if (name.contains('red') || name.contains('đỏ')) {
      return const Color(0xFFFF3B30);
    }
    if (name.contains('green') || name.contains('xanh lá')) {
      return const Color(0xFF34C759);
    }
    if (name.contains('pink') || name.contains('hồng')) {
      return const Color(0xFFFF6B8A);
    }
    return Colors.grey;
  }
  // ----------------------------------------

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final currentVariant = widget.currentVariant;
    final isOutOfStock = (currentVariant?.stock ?? 0) <= 0;
    final galleryUrls = widget.product.galleryUrls;
    final colorKey = _getColorKey();
    final uniqueColors = _getUniqueColors();

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
                  widget.product.name.toUpperCase(),
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

          const SizedBox(height: 24),

          // --- color dots + quantity ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (uniqueColors.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: uniqueColors.map((colorValue) {
                      final dotColor = _parseColor(colorValue);
                      final selectedColor = widget.selectedAttributes[colorKey];
                      final isSelected = selectedColor == colorValue;

                      // kiem tra so luong hang theo bien the
                      final anyInStock = widget.product.variants.any(
                        (v) =>
                            v.isActive &&
                            v.attributes[colorKey]?.toString() == colorValue &&
                            v.stock > 0,
                      );

                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          widget.onAttributeChanged(colorKey, colorValue);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.only(right: 12),
                          width: isSelected ? 28 : 22,
                          height: isSelected ? 28 : 22,
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.black
                                  : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: !anyInStock
                              ? Center(
                                  child: Container(
                                    width: 1.5,
                                    height: 14,
                                    color: isSelected
                                        ? Colors.black
                                        : Colors.grey,
                                    transform: Matrix4.rotationZ(0.7),
                                  ),
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                _buildQuantitySelector(),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // --- trust badges ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTrustBadge(LucideIcons.shieldCheck, 'Bảo hành 36 tháng'),
                const SizedBox(width: 8),
                _buildTrustBadge(LucideIcons.truck, 'Giao hàng hỏa tốc'),
                const SizedBox(width: 8),
                _buildTrustBadge(LucideIcons.badgeCheck, 'Cam kết chính hãng'),
              ],
            ),
          ),
          const SizedBox(height: 32),
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
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
          child: Center(
            child: _buildNetworkImage(
              urls[index],
              isOutOfStock,
              heroTag: index == 0 ? 'product_${widget.product.id}' : null,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSingleImage(String url, bool isOutOfStock) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Hero(
          tag: 'product_${widget.product.id}',
          child: _buildFilteredImage(url, isOutOfStock),
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

  // qty selector
  Widget _buildQuantitySelector() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _qtyBtn(
            icon: LucideIcons.minus,
            onTap: widget.onDecrement,
            onLongPress: widget.onLongPressDecrement,
            onLongPressUp: widget.onLongPressEnd,
            disabled: widget.quantity <= 1,
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 40),
            alignment: Alignment.center,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                );
              },
              child: Text(
                '${widget.quantity}',
                key: ValueKey<int>(widget.quantity),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  fontFeatures: [FontFeature.tabularFigures()],
                  color: Colors.black,
                ),
              ),
            ),
          ),
          _qtyBtn(
            icon: LucideIcons.plus,
            onTap: widget.onIncrement,
            onLongPress: widget.onLongPressIncrement,
            onLongPressUp: widget.onLongPressEnd,
            disabled: widget.quantity >= widget.maxQuantity,
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn({
    required IconData icon,
    required VoidCallback onTap,
    required VoidCallback onLongPress,
    required VoidCallback onLongPressUp,
    bool disabled = false,
  }) {
    return GestureDetector(
      onTap: disabled
          ? null
          : () {
              HapticFeedback.lightImpact();
              onTap();
            },
      onLongPress: disabled ? null : onLongPress,
      onLongPressUp: disabled ? null : onLongPressUp,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
        ),
        child: Opacity(
          opacity: disabled ? 0.2 : 1.0,
          child: Icon(icon, size: 18, color: Colors.black),
        ),
      ),
    );
  }

  Widget _buildTrustBadge(IconData icon, String label) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1C1C1E)),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF8E8E93),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
