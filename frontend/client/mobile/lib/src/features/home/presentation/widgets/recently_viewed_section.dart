import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile/src/core/theme/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:mobile/src/shared/models/product_model.dart';
import 'package:mobile/src/shared/widgets/small_product_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/src/core/di/injection.dart';
import 'package:mobile/src/features/product_detail/data/datasources/product_detail_remote_datasource.dart';
import 'package:mobile/src/features/product_detail/presentation/pages/product_detail_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/src/features/wishlist/presentation/state/wishlist_cubit.dart';
import 'package:mobile/src/features/wishlist/presentation/state/wishlist_state.dart';

class RecentlyViewedSection extends StatefulWidget {
  const RecentlyViewedSection({super.key});

  @override
  State<RecentlyViewedSection> createState() => _RecentlyViewedSectionState();
}

class _RecentlyViewedSectionState extends State<RecentlyViewedSection> {
  List<Map<String, dynamic>> _recentProducts = [];

  @override
  void initState() {
    super.initState();
    _loadRecentlyViewed();
  }

  void _loadRecentlyViewed() {
    try {
      final prefs = getIt<SharedPreferences>();
      final List<String> list = prefs.getStringList('recently_viewed') ?? [];
      final List<Map<String, dynamic>> parsed = [];

      for (final e in list) {
        final parts = e.split('|');
        if (parts.length >= 4) {
          Map<String, String> attributes = {};
          if (parts.length >= 5) {
            try {
              attributes = Map<String, String>.from(jsonDecode(parts[4]));
            } catch (e) {
              debugPrint('Error decoding attributes: $e');
            }
          }
          parsed.add({
            'id': parts[0],
            'name': parts[1],
            'price': parts[2],
            'image': parts[3],
            'attributes': attributes,
          });
        }
      }

      setState(() {
        _recentProducts = parsed;
      });
    } catch (e) {
      debugPrint('Error loading recently viewed: $e');
    }
  }

  void _clearAll() async {
    try {
      final prefs = getIt<SharedPreferences>();
      await prefs.remove('recently_viewed');
      setState(() {
        _recentProducts = [];
      });
    } catch (e) {
      debugPrint('Error clearing recently viewed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_recentProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Đã xem gần đây',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _clearAll();
                },
                child: const Text(
                  'Xóa tất cả',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.slate400,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 280,
          child: OverflowBox(
            maxWidth: MediaQuery.of(context).size.width,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              clipBehavior: Clip.none,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _recentProducts.length,
              itemBuilder: (context, index) {
                final prod = _recentProducts[index];
                final double priceVal =
                    double.tryParse(prod['price']?.toString() ?? '0') ?? 0;
                final attributes =
                    (prod['attributes'] as Map<dynamic, dynamic>?)
                        ?.cast<String, String>() ??
                    {};

                final productModel = ProductModel(
                  id: prod['id']!,
                  name: prod['name']!,
                  price: priceVal,
                  image: prod['image']!,
                  tagline: '',
                  description: '',
                );

                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: BlocBuilder<WishlistCubit, WishlistState>(
                    builder: (context, state) {
                      return SmallProductCard(
                        product: productModel,
                        heroTag: 'recent_${productModel.id}_$index',
                        onTap: () async {
                          HapticFeedback.mediumImpact();
                          try {
                            final pDetail =
                                await getIt<ProductDetailRemoteDatasource>()
                                    .getProductDetail(prod['id']!);
                            if (context.mounted) {
                              Navigator.of(context)
                                  .push(
                                    MaterialPageRoute(
                                      builder: (_) => ProductDetailPage(
                                        product: pDetail,
                                        initialAttributes: attributes,
                                      ),
                                    ),
                                  )
                                  .then((_) => _loadRecentlyViewed());
                            }
                          } catch (e) {
                            debugPrint(
                              'Error fetching product detail on click: $e',
                            );
                          }
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
