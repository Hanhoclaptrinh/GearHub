import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile/src/core/utils/formatter_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/src/core/di/injection.dart';
import 'package:mobile/src/features/product_detail/data/datasources/product_detail_remote_datasource.dart';
import 'package:mobile/src/features/product_detail/presentation/pages/product_detail_page.dart';

class RecentlyViewedSection extends StatefulWidget {
  const RecentlyViewedSection({super.key});

  @override
  State<RecentlyViewedSection> createState() => _RecentlyViewedSectionState();
}

class _RecentlyViewedSectionState extends State<RecentlyViewedSection> {
  List<Map<String, String>> _recentProducts = [];

  @override
  void initState() {
    super.initState();
    _loadRecentlyViewed();
  }

  void _loadRecentlyViewed() {
    try {
      final prefs = getIt<SharedPreferences>();
      final List<String> list = prefs.getStringList('recently_viewed') ?? [];
      final List<Map<String, String>> parsed = [];

      for (final e in list) {
        final parts = e.split('|');
        if (parts.length >= 4) {
          parsed.add({
            'id': parts[0],
            'name': parts[1],
            'price': parts[2],
            'image': parts[3],
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Đã xem gần đây',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0A0A0F),
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
                  color: Color(0xFF6B7280),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 230,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _recentProducts.length,
            itemBuilder: (context, index) {
              final prod = _recentProducts[index];
              final double priceVal =
                  double.tryParse(prod['price'] ?? '0') ?? 0;

              return GestureDetector(
                onTap: () async {
                  HapticFeedback.mediumImpact();
                  try {
                    final pDetail = await getIt<ProductDetailRemoteDatasource>()
                        .getProductDetail(prod['id']!);
                    if (context.mounted) {
                      Navigator.of(context)
                          .push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProductDetailPage(product: pDetail),
                            ),
                          )
                          .then((_) => _loadRecentlyViewed());
                    }
                  } catch (e) {
                    debugPrint('Error fetching product detail on click: $e');
                  }
                },
                child: Container(
                  width: 156,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 164,
                        width: 156,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(110, 221, 221, 221),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        clipBehavior: Clip.none,
                        child: Center(
                          child:
                              prod['image'] != null && prod['image']!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: prod['image']!,
                                  fit: BoxFit.contain,
                                  height: 130,
                                  width: 130,
                                  placeholder: (context, url) =>
                                      const CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                  errorWidget: (context, url, error) =>
                                      const Icon(
                                        Icons.image_not_supported_outlined,
                                        color: Color(0xFF9CA3AF),
                                      ),
                                )
                              : const Icon(
                                  Icons.image_not_supported_outlined,
                                  color: Color(0xFF9CA3AF),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        prod['name'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0A0A0F),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatVND(priceVal),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0A0A0F),
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
