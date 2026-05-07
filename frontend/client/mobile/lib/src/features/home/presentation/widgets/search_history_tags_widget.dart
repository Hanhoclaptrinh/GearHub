import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const _surface    = Color(0xFF14141E);
const _surfaceAlt = Color(0xFF1C1C28);
const _border     = Color(0xFF2A2A38);
const _accent     = Color(0xFF6366F1);
const _accentSoft = Color(0x186366F1);
const _textHigh   = Color(0xFFF1F1F5);
const _textMid    = Color(0xFF9191A8);
const _textLow    = Color(0xFF4A4A62);

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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: _accentSoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.history, size: 14, color: _accent),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Lịch sử tìm kiếm',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: _textHigh,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: onClearAllHistory,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(50, 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
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
          const SizedBox(height: 16),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: _surfaceAlt,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        k,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _textMid,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => onRemoveHistoryItem(k),
                        child: const Icon(
                          LucideIcons.x,
                          size: 14,
                          color: _textLow,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
        ],

        // rcm keyword/popular
        if (popularKeywords.isNotEmpty) ...[
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.sparkles, size: 14, color: Colors.orange),
              ),
              const SizedBox(width: 10),
              const Text(
                'Có phải bạn muốn tìm',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: _textHigh,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _border),
                  ),
                  child: Text(
                    k,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _textMid,
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
