import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/src/core/di/injection.dart';
import 'package:mobile/src/core/utils/formatter_utils.dart';
import 'package:mobile/src/features/auth/presentation/state/auth_cubit.dart';
import 'package:mobile/src/features/auth/presentation/state/auth_state.dart';
import 'package:mobile/src/features/wishlist/domain/repositories/wishlist_repository.dart';
import 'package:mobile/src/features/product_detail/presentation/pages/product_detail_page.dart';
import 'package:mobile/src/shared/models/product_model.dart';
import 'package:mobile/src/shared/widgets/auth_required_modal.dart';
import 'package:mobile/src/shared/widgets/color_bubble_selector.dart';

const _surface = Color(0xFF14141E);
const _surfaceAlt = Color(0xFF1C1C28);
const _border = Color(0xFF2A2A38);
const _accent = Color(0xFFFFCC00);
const _textHigh = Color(0xFFF1F1F5);
const _textLow = Color(0xFF4A4A62);
const _starColor = Color(0xFFFFCC00);

class ProductCard extends StatefulWidget {
  final ProductModel product;

  const ProductCard({super.key, required this.product});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard>
    with SingleTickerProviderStateMixin {
  bool _isWishlisted = false;
  final _repository = getIt<WishlistRepository>();
  late final AnimationController _heartAnim;

  @override
  void initState() {
    super.initState();
    _heartAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      lowerBound: 0.8,
      upperBound: 1.0,
      value: 1.0,
    );
    _checkInitialWishlist();
  }

  @override
  void dispose() {
    _heartAnim.dispose();
    super.dispose();
  }

  Future<void> _checkInitialWishlist() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      final isFav = await _repository.checkIsFavorite(widget.product.id);
      if (mounted) setState(() => _isWishlisted = isFav);
    }
  }

  Future<void> _toggleWishlist() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      AuthRequiredModal.show(context);
      return;
    }
    HapticFeedback.lightImpact();
    // animation
    await _heartAnim.reverse();
    _heartAnim.forward();

    setState(() => _isWishlisted = !_isWishlisted);
    try {
      await _repository.toggleWishlist(widget.product.id);
    } catch (e) {
      if (mounted) {
        setState(() => _isWishlisted = !_isWishlisted);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi khi cập nhật danh sách yêu thích')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorKey = _getColorKey(widget.product);
    final otherSpecs = _getOtherSpecs(widget.product, colorKey);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailPage(product: widget.product),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _border, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // name
                    Text(
                      widget.product.baseName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _textHigh,
                        height: 1.3,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),

                    // rating row
                    Row(
                      children: [
                        const Icon(Icons.star, color: _starColor, size: 15),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.product.averageRating}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _accent,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${widget.product.reviewCount})',
                          style: const TextStyle(fontSize: 12, color: _textLow),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // price
                    Text(
                      formatVND(widget.product.price),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: _textHigh,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // color bubbles
                    if (colorKey.isNotEmpty)
                      ColorBubbleSelector(
                        product: widget.product,
                        attributeKey: colorKey,
                        bubbleSize: 30,
                        spacing: 6,
                        isReadOnly: true,
                      ),

                    if (colorKey.isNotEmpty && otherSpecs.isNotEmpty)
                      const SizedBox(height: 12),

                    // other specs
                    if (otherSpecs.isNotEmpty)
                      Text(
                        otherSpecs.join(' · '),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: _textLow,
                          height: 1.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // im & wishlist
              SizedBox(
                width: 120,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: _toggleWishlist,
                      child: ScaleTransition(
                        scale: _heartAnim,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: _isWishlisted
                                ? const Color(0x22EF4444)
                                : _surfaceAlt,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _isWishlisted
                                  ? const Color(0x55EF4444)
                                  : _border,
                            ),
                          ),
                          child: Icon(
                            _isWishlisted
                                ? Icons.favorite_rounded
                                : LucideIcons.heart,
                            color: _isWishlisted
                                ? const Color(0xFFEF4444)
                                : _textLow,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // img
                    CachedNetworkImage(
                      imageUrl: widget.product.image,
                      height: 110,
                      fit: BoxFit.contain,
                      placeholder: (_, __) => const SizedBox(
                        height: 110,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: _textLow,
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => const SizedBox(
                        height: 110,
                        child: Icon(
                          LucideIcons.package,
                          size: 36,
                          color: _textLow,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getColorKey(ProductModel product) {
    if (product.attributeConfig.isNotEmpty) {
      return product.attributeConfig.firstWhere((k) {
        final l = k.toLowerCase();
        return l.contains('color') || l.contains('màu') || l.contains('mau');
      }, orElse: () => '');
    }
    return '';
  }

  List<String> _getOtherSpecs(ProductModel product, String colorKey) {
    final specs = <String>{};
    for (final variant in product.variants) {
      if (!variant.isActive) continue;
      variant.attributes.forEach((k, v) {
        if (k != colorKey) specs.add(v.toString());
      });
    }
    return specs.toList();
  }
}
