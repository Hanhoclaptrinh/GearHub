import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:mobile/src/features/home/domain/models/product.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../widgets/product_hero_section.dart';
import '../widgets/product_info_section.dart';
import '../widgets/sticky_bottom_bar.dart';
import '../widgets/product_reviews_preview_section.dart';
import '../widgets/product_recommendations_section.dart';
import 'product_ar_view_page.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;

  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late final ScrollController _scrollController;
  bool _showBottomBar = true;

  int _quantity = 1;
  final int _maxQuantity = 10;
  Timer? _timer; // timer cho long press tang so luong

  int _selectedColorIndex = 1;
  final List<Color> _variantColors = [
    const Color.fromARGB(255, 195, 195, 255),
    const Color.fromARGB(255, 255, 185, 185),
    const Color.fromARGB(255, 255, 193, 131),
  ];

  // xu ly an/hien thanh bottom bar khi scroll
  bool _handleScrollNotification(ScrollNotification notification) {
    // chi xu ly khi co su tuong tac tu nguoi dung
    if (notification is UserScrollNotification) {
      // neu scroll ngang -> khong lam gi
      if (notification.metrics.axis != Axis.vertical) return false;
      // neu cuon len -> an bottom bar
      if (notification.direction == ScrollDirection.reverse) {
        if (_showBottomBar) setState(() => _showBottomBar = false);
      }
      // neu cuon xuong -> hien bottom bar
      else if (notification.direction == ScrollDirection.forward) {
        if (!_showBottomBar) setState(() => _showBottomBar = true);
      }
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _incrementQuantity() {
    if (_quantity < _maxQuantity) {
      HapticFeedback.lightImpact();
      setState(() => _quantity++);
    } else {
      _stopContinuous();
    }
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      HapticFeedback.lightImpact();
      setState(() => _quantity--);
    } else {
      _stopContinuous();
    }
  }

  // bat dau tang/giam moi 150ms khi long press
  void _startContinuous(VoidCallback action) {
    action();
    _timer = Timer.periodic(const Duration(milliseconds: 150), (_) => action());
  }

  void _stopContinuous() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    const double expandedHeight = 120;
    const double collapsedHeight = kToolbarHeight;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBody: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      bottomNavigationBar: AnimatedSlide(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
        offset: _showBottomBar ? Offset.zero : const Offset(0, 2),
        child: StickyBottomBar(product: widget.product),
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              stretch: true,
              expandedHeight: expandedHeight,
              collapsedHeight: collapsedHeight,
              toolbarHeight: collapsedHeight,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              elevation: 0,
              scrolledUnderElevation: 0,
              automaticallyImplyLeading: false,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: IconButton(
                    icon: const Icon(LucideIcons.box, size: 20),
                    onPressed: () async {
                      HapticFeedback.mediumImpact();
                      await Future.delayed(const Duration(milliseconds: 300));
                      if (!mounted) return;
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              ProductARViewPage(product: widget.product),
                        ),
                      );
                    },
                  ),
                ),
              ],
              flexibleSpace: LayoutBuilder(
                builder: (context, constraints) {
                  final double currentExtent = constraints.maxHeight;
                  final double progress =
                      ((currentExtent - (collapsedHeight + statusBarHeight)) /
                              (expandedHeight -
                                  (collapsedHeight + statusBarHeight)))
                          .clamp(0.0, 1.0);

                  return Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor
                          .withValues(alpha: (1.0 - progress).clamp(0.0, 0.9)),
                    ),
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: statusBarHeight),
                        child: Transform.scale(
                          scale:
                              1.0 +
                              (progress *
                                  0.3), // ten sp to hon 30% khi expand appbar
                          child: Text(
                            widget.product.name.toUpperCase(),
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  ProductHeroSection(
                    product: widget.product,
                    selectedColorIndex: _selectedColorIndex,
                    variantColors: _variantColors,
                    quantity: _quantity,
                    onColorTarget: (index) {
                      setState(() => _selectedColorIndex = index);
                    },
                    onIncrement: _incrementQuantity,
                    onDecrement: _decrementQuantity,
                    onLongPressIncrement: () =>
                        _startContinuous(_incrementQuantity),
                    onLongPressDecrement: () =>
                        _startContinuous(_decrementQuantity),
                    onLongPressEnd: _stopContinuous,
                    maxQuantity: _maxQuantity,
                  ),
                  const SizedBox(height: 8),
                  ProductInfoSection(product: widget.product),
                  const ProductReviewsPreviewSection(hasReviews: true),
                  const ProductRecommendationsSection(),
                  SizedBox(height: 100 + MediaQuery.of(context).padding.bottom),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
