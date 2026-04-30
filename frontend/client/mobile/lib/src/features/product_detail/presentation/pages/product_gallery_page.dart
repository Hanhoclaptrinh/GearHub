import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ProductGalleryPage extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final String heroTagPrefix;
  final String? mainHeroTag;

  const ProductGalleryPage({
    super.key,
    required this.images,
    this.initialIndex = 0,
    this.heroTagPrefix = 'product_gallery',
    this.mainHeroTag,
  });

  @override
  State<ProductGalleryPage> createState() => _ProductGalleryPageState();
}

class _ProductGalleryPageState extends State<ProductGalleryPage> {
  late PageController _pageController;
  late int _currentIndex;
  final Map<int, TransformationController> _transformationControllers = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (var controller in _transformationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TransformationController _getController(int index) {
    if (!_transformationControllers.containsKey(index)) {
      _transformationControllers[index] = TransformationController();
    }
    return _transformationControllers[index]!;
  }

  void _handleDoubleTap(int index) {
    final controller = _getController(index);
    if (controller.value != Matrix4.identity()) {
      controller.value = Matrix4.identity();
    } else {
      // Zoom in to 2x at the center
      final zoomMatrix = Matrix4.identity()..scale(2.0);
      controller.value = zoomMatrix;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemBuilder: (context, index) {
              final heroTag = (index == 0 && widget.mainHeroTag != null)
                  ? widget.mainHeroTag!
                  : '${widget.heroTagPrefix}_$index';

              return GestureDetector(
                onDoubleTap: () => _handleDoubleTap(index),
                child: InteractiveViewer(
                  transformationController: _getController(index),
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Hero(
                    tag: heroTag,
                    child: Center(
                      child: CachedNetworkImage(
                        imageUrl: widget.images[index],
                        fit: BoxFit.contain,
                        placeholder: (_, __) => const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white70,
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => const Icon(
                          Icons.broken_image_outlined,
                          color: Colors.white24,
                          size: 64,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.x,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${widget.images.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
