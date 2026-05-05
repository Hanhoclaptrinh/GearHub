import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/shared/models/product_model.dart';
import 'package:mobile/src/shared/widgets/product_card.dart';

class SearchProductGrid extends StatelessWidget {
  final List<ProductModel> searchResults;
  final VoidCallback onShowFilters;

  const SearchProductGrid({
    super.key,
    required this.searchResults,
    required this.onShowFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${searchResults.length} Kết quả tìm kiếm',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4B5563),
                ),
              ),
              GestureDetector(
                onTap: onShowFilters,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        LucideIcons.slidersHorizontal,
                        size: 14,
                        color: Color(0xFF0A0A0F),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Bộ lọc',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0A0A0F),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: searchResults.isEmpty
              ? const Center(
                  child: Text(
                    'Không tìm thấy sản phẩm nào khớp.',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  physics: const BouncingScrollPhysics(),
                  itemCount: searchResults.length,
                  itemBuilder: (context, index) {
                    final p = searchResults[index];
                    return ProductCard(product: p);
                  },
                ),
        ),
      ],
    );
  }
}
