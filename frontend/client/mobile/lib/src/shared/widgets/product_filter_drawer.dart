import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/core/utils/formatter_utils.dart';

const _bg         = Color(0xFF0A0A10);
const _surface    = Color(0xFF14141E);
const _surfaceAlt = Color(0xFF1C1C28);
const _border     = Color(0xFF2A2A38);
const _accent     = Color(0xFF6366F1);
const _textHigh   = Color(0xFFF1F1F5);
const _textMid    = Color(0xFF9191A8);
const _textLow    = Color(0xFF4A4A62);

class ProductFilterDrawer extends StatefulWidget {
  final double? initialMinPrice;
  final double? initialMaxPrice;
  final String initialSortBy;
  final Function(double? min, double? max, String sort) onApply;

  const ProductFilterDrawer({
    super.key,
    this.initialMinPrice,
    this.initialMaxPrice,
    required this.initialSortBy,
    required this.onApply,
  });

  @override
  State<ProductFilterDrawer> createState() => _ProductFilterDrawerState();
}

class _ProductFilterDrawerState extends State<ProductFilterDrawer> {
  late double _minPrice;
  late double _maxPrice;
  late String _sortBy;
  
  final List<Map<String, String>> _sortOptions = [
    {'value': 'newest', 'label': 'Mới nhất'},
    {'value': 'price_asc', 'label': 'Giá: Thấp → Cao'},
    {'value': 'price_desc', 'label': 'Giá: Cao → Thấp'},
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
    final safeArea = MediaQuery.of(context).padding;

    return Drawer(
      backgroundColor: _bg,
      width: MediaQuery.of(context).size.width * 0.85,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          bottomLeft: Radius.circular(32),
        ),
      ),
      child: Container(
        padding: EdgeInsets.fromLTRB(28, safeArea.top + 24, 28, safeArea.bottom + 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Bộ lọc',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: _textHigh,
                    letterSpacing: -0.5,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _surfaceAlt,
                      shape: BoxShape.circle,
                      border: Border.all(color: _border),
                    ),
                    child: const Icon(LucideIcons.x, size: 20, color: _textHigh),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            
            _buildSectionHeader('Sắp xếp theo', LucideIcons.arrowUpDown),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _sortOptions.map((opt) {
                final isSelected = _sortBy == opt['value'];
                return GestureDetector(
                  onTap: () => setState(() => _sortBy = opt['value']!),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? _accent : _surfaceAlt,
                      border: Border.all(
                        color: isSelected ? _accent : _border,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: _accent.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ] : null,
                    ),
                    child: Text(
                      opt['label']!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? Colors.white : _textMid,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 48),
            
            _buildSectionHeader('Khoảng giá', LucideIcons.banknote),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _buildPriceIndicator('Từ', formatVND(_minPrice))),
                const SizedBox(width: 8),
                Container(width: 12, height: 1, color: _border),
                const SizedBox(width: 8),
                Expanded(child: _buildPriceIndicator('Đến', formatVND(_maxPrice))),
              ],
            ),
            const SizedBox(height: 24),
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 4,
                activeTrackColor: _accent,
                inactiveTrackColor: _border,
                thumbColor: _textHigh,
                overlayColor: _accent.withValues(alpha: 0.1),
                rangeThumbShape: const RoundRangeSliderThumbShape(
                  enabledThumbRadius: 10,
                  elevation: 4,
                ),
                rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
              ),
              child: RangeSlider(
                values: RangeValues(_minPrice, _maxPrice),
                min: 0,
                max: 1000000000,
                divisions: 100,
                onChanged: (values) {
                  setState(() {
                    _minPrice = values.start;
                    _maxPrice = values.end;
                  });
                },
              ),
            ),
            
            const Spacer(),
            
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _minPrice = 0;
                        _maxPrice = 1000000000;
                        _sortBy = 'newest';
                      });
                    },
                    child: Container(
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _surfaceAlt,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: _border),
                      ),
                      child: const Text(
                        'Đặt lại',
                        style: TextStyle(
                          color: _textMid,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: () {
                      widget.onApply(_minPrice, _maxPrice, _sortBy);
                      Navigator.pop(context);
                    },
                    child: Container(
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_accent, Color(0xFF4F46E5)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: _accent.withValues(alpha: 0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Text(
                        'Áp dụng',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
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

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _accent),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: _textHigh,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceIndicator(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: _textLow, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _textHigh,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
