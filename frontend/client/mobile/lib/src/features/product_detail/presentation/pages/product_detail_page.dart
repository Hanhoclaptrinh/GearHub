import 'package:flutter/material.dart';
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
  bool _isArViewOpen = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBody: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      bottomNavigationBar: StickyBottomBar(product: widget.product),
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        elevation: 0,
        scrolledUnderElevation: 0,

        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_rounded,
              color: colorScheme.onSurface,
            ),
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.surfaceContainerHigh.withValues(
                alpha: 0.5,
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0, top: 4.0, bottom: 4.0),
            child: TextButton.icon(
              onPressed: () async {
                HapticFeedback.mediumImpact();
                setState(() => _isArViewOpen = true);

                await Future.delayed(const Duration(milliseconds: 800));

                if (!mounted) return;

                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        ProductARViewPage(product: widget.product),
                  ),
                );

                if (mounted) {
                  setState(() => _isArViewOpen = false);
                }
              },
              icon: Icon(
                LucideIcons.box,
                size: 18,
                color: colorScheme.onSurface,
              ),
              label: Text(
                'AR View',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: colorScheme.surfaceContainerHigh.withValues(
                  alpha: 0.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: Icon(LucideIcons.heart, color: colorScheme.onSurface),
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.surfaceContainerHigh.withValues(
                  alpha: 0.5,
                ),
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
              },
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProductHeroSection(
              product: widget.product,
              display3DRender: !_isArViewOpen,
            ),
            ProductInfoSection(product: widget.product),
            const ProductReviewsPreviewSection(hasReviews: true),
            const ProductRecommendationsSection(),
            SizedBox(height: 100 + MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}
