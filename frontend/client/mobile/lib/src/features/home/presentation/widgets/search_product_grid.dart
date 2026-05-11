import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/shared/models/product_model.dart';
import 'package:mobile/src/shared/widgets/product_card.dart';

const _bg = Color(0xFF07070A);
const _surfaceAlt = Color(0xFF1C1C28);
const _border = Color(0xFF2A2A38);
const _textHigh = Color(0xFFF1F1F5);
const _textMid = Color(0xFF9191A8);
const _textLow = Color(0xFF4A4A62);

class SearchProductGrid extends StatelessWidget {
  final List<ProductModel> searchResults;
  final VoidCallback onShowFilters;
  final String currentSortBy;
  final Function(String) onSortChanged;

  const SearchProductGrid({
    super.key,
    required this.searchResults,
    required this.onShowFilters,
    required this.currentSortBy,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(0, 14, 0, 0),
          decoration: const BoxDecoration(color: _bg),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${searchResults.length}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: _textHigh,
                            ),
                          ),
                          const TextSpan(
                            text: ' kết quả',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _textMid,
                            ),
                          ),
                        ],
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
                          color: _surfaceAlt,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _border),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              LucideIcons.slidersHorizontal,
                              size: 14,
                              color: _textMid,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Bộ lọc',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _textMid,
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
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _buildSortChip('newest', 'Mới nhất', LucideIcons.clock),
                    _buildSortChip('popular', 'Bán chạy', LucideIcons.flame),
                    _buildSortChip(
                      'price_asc',
                      'Giá thấp',
                      LucideIcons.trendingUp,
                    ),
                    _buildSortChip(
                      'price_desc',
                      'Giá cao',
                      LucideIcons.trendingDown,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
          ),
        ),
        const Divider(height: 1, color: _border, thickness: 0.5),
        Expanded(
          child:
              searchResults.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: _surfaceAlt,
                            shape: BoxShape.circle,
                            border: Border.all(color: _border),
                          ),
                          child: const Icon(
                            LucideIcons.packageSearch,
                            size: 48,
                            color: _textLow,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Không tìm thấy sản phẩm nào.',
                          style: TextStyle(
                            color: _textMid,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                  : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
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

  Widget _buildSortChip(String value, String label, IconData icon) {
    final isSelected = currentSortBy == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onSortChanged(value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color:
                isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : _textMid),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : _textMid,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
