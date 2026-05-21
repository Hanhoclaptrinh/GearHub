import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/core/theme/app_colors.dart';
import 'package:mobile/src/core/utils/formatter_utils.dart';

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

class _ProductFilterDrawerState extends State<ProductFilterDrawer>
    with SingleTickerProviderStateMixin {
  static const double _maxLimit = 1000000000.0;

  late double _minPrice;
  late double _maxPrice;
  late String _sortBy;

  late TextEditingController _minCtrl;
  late TextEditingController _maxCtrl;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  final List<_SortOption> _sortOptions = const [
    _SortOption('newest', 'Mới nhất', LucideIcons.clock3, 'Vừa cập nhật'),
    _SortOption('popular', 'Phổ biến nhất', LucideIcons.flame, 'Bán chạy'),
    _SortOption(
      'price_asc',
      'Giá tăng dần',
      LucideIcons.trendingUp,
      'Rẻ trước',
    ),
    _SortOption(
      'price_desc',
      'Giá giảm dần',
      LucideIcons.trendingDown,
      'Đắt trước',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _minPrice = (widget.initialMinPrice ?? 0).clamp(0, _maxLimit);
    _maxPrice = (widget.initialMaxPrice ?? _maxLimit).clamp(
      _minPrice,
      _maxLimit,
    );
    _sortBy = widget.initialSortBy;

    _minCtrl = TextEditingController(text: _rawNumber(_minPrice));
    _maxCtrl = TextEditingController(text: _rawNumber(_maxPrice));

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  String _rawNumber(double v) => v == 0 ? '0' : v.toInt().toString();

  void _syncFromFields() {
    final minVal =
        double.tryParse(
          _minCtrl.text.replaceAll('.', '').replaceAll(',', ''),
        ) ??
        _minPrice;
    final maxVal =
        double.tryParse(
          _maxCtrl.text.replaceAll('.', '').replaceAll(',', ''),
        ) ??
        _maxPrice;
    setState(() {
      _minPrice = minVal.clamp(0, _maxLimit);
      _maxPrice = maxVal.clamp(_minPrice, _maxLimit);
    });
  }

  void _syncFromSlider(RangeValues vals) {
    setState(() {
      _minPrice = vals.start;
      _maxPrice = vals.end;
      _minCtrl.text = _rawNumber(_minPrice);
      _maxCtrl.text = _rawNumber(_maxPrice);
    });
  }

  int get _activeFilterCount {
    int c = 0;
    if (_sortBy != 'newest') c++;
    if (_minPrice > 0) c++;
    if (_maxPrice < _maxLimit) c++;
    return c;
  }

  void _reset() {
    setState(() {
      _minPrice = 0;
      _maxPrice = _maxLimit;
      _sortBy = 'newest';
      _minCtrl.text = '0';
      _maxCtrl.text = _rawNumber(_maxLimit);
    });
  }

  @override
  Widget build(BuildContext context) {
    final safeArea = MediaQuery.of(context).padding;
    final activeCount = _activeFilterCount;

    return Drawer(
      backgroundColor: AppColors.background,
      width: MediaQuery.of(context).size.width * 0.88,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          bottomLeft: Radius.circular(28),
        ),
      ),
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              bottomLeft: Radius.circular(28),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(safeArea, activeCount),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      _buildSectionLabel('SẮP XẾP THEO'),
                      const SizedBox(height: 8),
                      _buildSortList(),
                      const SizedBox(height: 32),
                      _buildSectionLabel('KHOẢNG GIÁ'),
                      const SizedBox(height: 12),
                      _buildPriceInputRow(),
                      const SizedBox(height: 20),
                      _buildSlider(),
                      const SizedBox(height: 8),
                      _buildSliderLabels(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),

              _buildFooter(safeArea),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(EdgeInsets safeArea, int activeCount) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, safeArea.top + 28, 20, 24),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.cardBorder, width: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Bộ lọc',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        letterSpacing: -1,
                        height: 1,
                      ),
                    ),
                    if (activeCount > 0) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.champagne,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$activeCount',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  activeCount == 0
                      ? 'Chưa áp dụng bộ lọc nào'
                      : '$activeCount bộ lọc đang được áp dụng',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSlate,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.cardSurfaceAltAlt,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.cardBorder, width: 0.5),
              ),
              child: const Icon(
                LucideIcons.x,
                size: 18,
                color: AppColors.textSlate,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: AppColors.textDim,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildSortList() {
    return Column(
      children: _sortOptions.asMap().entries.map((entry) {
        final i = entry.key;
        final opt = entry.value;
        final isSelected = _sortBy == opt.value;
        final isLast = i == _sortOptions.length - 1;

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _sortBy = opt.value);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: EdgeInsets.fromLTRB(16, i == 0 ? 0 : 0, 16, isLast ? 0 : 0),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.champagneSoft : Colors.transparent,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: isSelected
                        ? AppColors.champagne
                        : Colors.transparent,
                    width: 2,
                  ),
                  bottom: BorderSide(
                    color: isLast ? Colors.transparent : AppColors.cardBorder,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.champagne
                          : AppColors.cardSurfaceAltAlt,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.champagne
                            : AppColors.cardBorder,
                        width: 0.5,
                      ),
                    ),
                    child: Icon(
                      opt.icon,
                      size: 17,
                      color: isSelected ? Colors.white : AppColors.textSlate,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          opt.label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: isSelected
                                ? AppColors.textPrimary
                                : AppColors.textSlate,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          opt.sub,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textDim,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedOpacity(
                    opacity: isSelected ? 1 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.champagne,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPriceInputRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(child: _buildPriceField('Từ', _minCtrl)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              width: 20,
              height: 1.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.cardBorder,
                    AppColors.champagne.withValues(alpha: 0.5),
                    AppColors.cardBorder,
                  ],
                ),
              ),
            ),
          ),
          Expanded(child: _buildPriceField('Đến', _maxCtrl)),
        ],
      ),
    );
  }

  Widget _buildPriceField(String label, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.textDim,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardSurfaceAltAlt,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder, width: 0.5),
          ),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 12),
                child: Text(
                  '₫',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSlate,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  cursorColor: AppColors.champagne,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                    isDense: true,
                  ),
                  onEditingComplete: _syncFromFields,
                  onTapOutside: (_) {
                    FocusScope.of(context).unfocus();
                    _syncFromFields();
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSlider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SliderTheme(
        data: const SliderThemeData(
          trackHeight: 3,
          activeTrackColor: AppColors.champagne,
          inactiveTrackColor: AppColors.cardBorder,
          thumbColor: AppColors.textPrimary,
          overlayColor: AppColors.champagneSoft,
          rangeThumbShape: RoundRangeSliderThumbShape(
            enabledThumbRadius: 11,
            elevation: 6,
          ),
          rangeTrackShape: RoundedRectRangeSliderTrackShape(),
          overlayShape: RoundSliderOverlayShape(overlayRadius: 22),
        ),
        child: RangeSlider(
          values: RangeValues(_minPrice, _maxPrice),
          min: 0,
          max: _maxLimit,
          divisions: 200,
          onChanged: (vals) {
            HapticFeedback.selectionClick();
            _syncFromSlider(vals);
          },
        ),
      ),
    );
  }

  Widget _buildSliderLabels() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '0 ₫',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textDim,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            formatVND(_maxLimit),
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textDim,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(EdgeInsets safeArea) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, safeArea.bottom + 20),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.cardBorder, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _reset();
            },
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.cardSurfaceAltAlt,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder, width: 0.5),
              ),
              child: const Icon(
                LucideIcons.rotateCcw,
                size: 18,
                color: AppColors.textSlate,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                _syncFromFields();
                widget.onApply(_minPrice, _maxPrice, _sortBy);
                Navigator.pop(context);
              },
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFDE047), Color(0xFFB49B00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.champagne.withValues(alpha: 0.35),
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.settings2, size: 16, color: Colors.black),
                    SizedBox(width: 8),
                    Text(
                      'Áp dụng bộ lọc',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SortOption {
  final String value;
  final String label;
  final IconData icon;
  final String sub;

  const _SortOption(this.value, this.label, this.icon, this.sub);
}
