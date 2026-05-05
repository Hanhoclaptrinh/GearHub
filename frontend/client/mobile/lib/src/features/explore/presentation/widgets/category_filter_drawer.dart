import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';

class CategoryFilterDrawer extends StatefulWidget {
  final double? initialMinPrice;
  final double? initialMaxPrice;
  final String initialSortBy;
  final Function(double? min, double? max, String sort) onApply;

  const CategoryFilterDrawer({
    super.key,
    this.initialMinPrice,
    this.initialMaxPrice,
    required this.initialSortBy,
    required this.onApply,
  });

  @override
  State<CategoryFilterDrawer> createState() => _CategoryFilterDrawerState();
}

class _CategoryFilterDrawerState extends State<CategoryFilterDrawer> {
  late double _minPrice;
  late double _maxPrice;
  late String _sortBy;
  
  final List<Map<String, String>> _sortOptions = [
    {'value': 'newest', 'label': 'Mới nhất'},
    {'value': 'price_asc', 'label': 'Giá thấp đến cao'},
    {'value': 'price_desc', 'label': 'Giá cao đến thấp'},
    {'value': 'popular', 'label': 'Phổ biến nhất'},
  ];

  @override
  void initState() {
    super.initState();
    const maxLimit = 1000000000.0;
    _minPrice = (widget.initialMinPrice ?? 0).clamp(0, maxLimit).toDouble();
    _maxPrice = (widget.initialMaxPrice ?? maxLimit).clamp(_minPrice, maxLimit).toDouble();
    _sortBy = widget.initialSortBy;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final safeArea = MediaQuery.of(context).padding;

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.8,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          bottomLeft: Radius.circular(24),
        ),
      ),
      child: Container(
        padding: EdgeInsets.fromLTRB(24, safeArea.top + 20, 24, safeArea.bottom + 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Bộ lọc',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(LucideIcons.x, size: 24),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            const Text(
              'Sắp xếp theo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _sortOptions.map((opt) {
                final isSelected = _sortBy == opt['value'];
                return GestureDetector(
                  onTap: () => setState(() => _sortBy = opt['value']!),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.black : Colors.white,
                      border: Border.all(
                        color: isSelected ? Colors.black : const Color(0xFFE5E5EA),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      opt['label']!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 40),
            
            const Text(
              'Khoảng giá',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${currencyFormat.format(_minPrice)} - ${currencyFormat.format(_maxPrice)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(height: 8),
            RangeSlider(
              values: RangeValues(_minPrice, _maxPrice),
              min: 0,
              max: 1000000000,
              divisions: 100,
              activeColor: Colors.black,
              inactiveColor: const Color(0xFFE5E5EA),
              onChanged: (values) {
                setState(() {
                  _minPrice = values.start;
                  _maxPrice = values.end;
                });
              },
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _minPrice = 0;
                        _maxPrice = 1000000000;
                        _sortBy = 'newest';
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      side: const BorderSide(color: Color(0xFFE5E5EA)),
                    ),
                    child: const Text(
                      'Đặt lại',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onApply(_minPrice, _maxPrice, _sortBy);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Áp dụng',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
