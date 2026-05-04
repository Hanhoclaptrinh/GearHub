import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SearchHistoryTagsWidget extends StatelessWidget {
  final List<String> searchHistory;
  final List<String> popularKeywords;
  final VoidCallback onClearAllHistory;
  final Function(String) onRemoveHistoryItem;
  final Function(String) onSearchKeyword;

  const SearchHistoryTagsWidget({
    super.key,
    required this.searchHistory,
    required this.popularKeywords,
    required this.onClearAllHistory,
    required this.onRemoveHistoryItem,
    required this.onSearchKeyword,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // recent searches
        if (searchHistory.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(LucideIcons.history, size: 16, color: Color(0xFF3B82F6)),
                  SizedBox(width: 8),
                  Text(
                    'Lịch sử tìm kiếm',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0A0A0F)),
                  ),
                ],
              ),
              TextButton(
                onPressed: onClearAllHistory,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 30),
                ),
                child: const Text(
                  'Xóa tất cả',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFFEF4444),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: searchHistory.map((k) {
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onSearchKeyword(k);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        k,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => onRemoveHistoryItem(k),
                        child: const Icon(
                          LucideIcons.x,
                          size: 14,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
        ],

        // rcm keyword/popular
        if (popularKeywords.isNotEmpty) ...[
          const Row(
            children: [
              Icon(LucideIcons.search, size: 16, color: Color(0xFF3B82F6)),
              SizedBox(width: 8),
              Text(
                'Có phải bạn muốn tìm',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0A0A0F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: popularKeywords.map((k) {
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onSearchKeyword(k);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Text(
                    k,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
