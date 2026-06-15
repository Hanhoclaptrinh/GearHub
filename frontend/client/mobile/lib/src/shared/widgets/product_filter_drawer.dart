import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ProductFilterDrawer extends StatefulWidget {
  final double? initialMinPrice;
  final double? initialMaxPrice;
  final String initialSortBy;
  final double? maxProductPrice;
  final Function(double? min, double? max, String sort) onApply;

  const ProductFilterDrawer({
    super.key,
    this.initialMinPrice,
    this.initialMaxPrice,
    required this.initialSortBy,
    this.maxProductPrice,
    required this.onApply,
  });

  @override
  State<ProductFilterDrawer> createState() => _ProductFilterDrawerState();
}

class _ProductFilterDrawerState extends State<ProductFilterDrawer>
    with SingleTickerProviderStateMixin {
  late double _maxLimit;
  late double _minPrice;
  late double _maxPrice;
  late String _sortBy;

  late TextEditingController _minCtrl;
  late TextEditingController _maxCtrl;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  //bộ lọc cơ bản
  final List<_SortOption> _sortOptions = const [
    _SortOption('newest', 'Mới nhất', 'Sản phẩm vừa cập nhật'),
    _SortOption('popular', 'Phổ biến', 'Bán chạy nhất'),
    _SortOption('price_asc', 'Giá tăng dần', 'Thấp đến cao'),
    _SortOption('price_desc', 'Giá giảm dần', 'Cao đến thấp'),
  ];

  @override
  void initState() {
    super.initState();
    //lọc theo khoảng giá
    _maxLimit = widget.maxProductPrice ?? 20000000.0;
    if (_maxLimit <= 0) _maxLimit = 20000000.0;

    _minPrice = (widget.initialMinPrice ?? 0.0).clamp(0.0, _maxLimit);
    _maxPrice = (widget.initialMaxPrice ?? _maxLimit).clamp(
      _minPrice,
      _maxLimit,
    );
    _sortBy = widget.initialSortBy;

    _minCtrl = TextEditingController(text: _formatToDisplay(_minPrice));
    _maxCtrl = TextEditingController(text: _formatToDisplay(_maxPrice));

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..forward();
    _fadeAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  String _formatToDisplay(double v) {
    if (v == 0) return '0';
    return v.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  double _parseFromInput(String text) {
    if (text.isEmpty) return 0.0;
    final clean = text.replaceAll('.', '').replaceAll(',', '');
    return double.tryParse(clean) ?? 0.0;
  }

  void _syncFromFields() {
    final minVal = _parseFromInput(_minCtrl.text);
    final maxVal = _parseFromInput(_maxCtrl.text);

    setState(() {
      _minPrice = minVal.clamp(0.0, _maxLimit);
      _maxPrice = maxVal.clamp(_minPrice, _maxLimit);
      _minCtrl.text = _formatToDisplay(_minPrice);
      _maxCtrl.text = _formatToDisplay(_maxPrice);
    });
  }

  void _syncFromSlider(RangeValues vals) {
    setState(() {
      _minPrice = vals.start;
      _maxPrice = vals.end;
      _minCtrl.text = _formatToDisplay(_minPrice);
      _maxCtrl.text = _formatToDisplay(_maxPrice);
    });
  }

  void _applyPreset(double min, double max) {
    HapticFeedback.selectionClick();
    setState(() {
      _minPrice = min.clamp(0.0, _maxLimit);
      _maxPrice = max.clamp(_minPrice, _maxLimit);
      _minCtrl.text = _formatToDisplay(_minPrice);
      _maxCtrl.text = _formatToDisplay(_maxPrice);
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
      _minPrice = 0.0;
      _maxPrice = _maxLimit;
      _sortBy = 'newest';
      _minCtrl.text = '0';
      _maxCtrl.text = _formatToDisplay(_maxLimit);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final safeArea = MediaQuery.of(context).padding;
    final activeCount = _activeFilterCount;

    final backgroundColor = isDark
        ? const Color(0xFF0F0F15)
        : const Color(0xFFF8F9FC);

    return Drawer(
      backgroundColor: Colors.transparent,
      width: MediaQuery.of(context).size.width * 0.88,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              bottomLeft: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.08),
                blurRadius: 40,
                spreadRadius: 0,
                offset: const Offset(-4, 0),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(safeArea, activeCount),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        _buildSectionTitle('SẮP XẾP SẢN PHẨM'),
                        const SizedBox(height: 14),
                        _buildSortSection(),
                        const SizedBox(height: 36),
                        _buildSectionTitle('KHOẢNG NGÂN SÁCH'),
                        const SizedBox(height: 20),
                        _buildPriceInputRow(),
                        const SizedBox(height: 24),
                        _buildSlider(),
                        const SizedBox(height: 16),
                        _buildPresetWrap(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
                _buildFooter(safeArea),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(EdgeInsets safeArea, int activeCount) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.fromLTRB(20, safeArea.top + 16, 12, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                'BỘ LỌC TÌM KIẾM',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: 1.2,
                ),
              ),
              if (activeCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$activeCount',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              LucideIcons.x,
              size: 20,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildSortSection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: _sortOptions.map((opt) {
        final isSel = _sortBy == opt.value;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _sortBy = opt.value);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isSel
                  ? theme.colorScheme.primary.withValues(
                      alpha: isDark ? 0.08 : 0.05,
                    )
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSel
                    ? theme.colorScheme.primary.withValues(alpha: 0.5)
                    : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                width: 1,
              ),
              boxShadow: isSel
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.05,
                        ),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        opt.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                          color: isSel
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        opt.sub,
                        style: TextStyle(
                          fontSize: 11,
                          color: isSel
                              ? theme.colorScheme.primary.withValues(alpha: 0.6)
                              : theme.colorScheme.onSurface.withValues(
                                  alpha: 0.4,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSel
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.2),
                      width: isSel ? 6 : 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPriceInputRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: _buildPriceField('TỪ', _minCtrl)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text('—', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ),
        Expanded(child: _buildPriceField('ĐẾN', _maxCtrl)),
      ],
    );
  }

  Widget _buildPriceField(String label, TextEditingController ctrl) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _CurrencyInputFormatter(),
            ],
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
            cursorColor: theme.colorScheme.primary,
            decoration: InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              fillColor: Colors.transparent,
              filled: false,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              suffixText: '₫',
              suffixStyle: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ),
            onEditingComplete: _syncFromFields,
            onTapOutside: (_) {
              FocusScope.of(context).unfocus();
              _syncFromFields();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSlider() {
    final theme = Theme.of(context);
    return SliderTheme(
      data: SliderThemeData(
        trackHeight: 3,
        activeTrackColor: theme.colorScheme.primary,
        inactiveTrackColor: theme.colorScheme.outlineVariant.withValues(
          alpha: 0.5,
        ),
        thumbColor: theme.colorScheme.surface,
        overlayColor: theme.colorScheme.primary.withValues(alpha: 0.1),
        rangeThumbShape: const RoundRangeSliderThumbShape(
          enabledThumbRadius: 9,
          elevation: 2,
          pressedElevation: 4,
        ),
      ),
      child: RangeSlider(
        values: RangeValues(_minPrice, _maxPrice),
        min: 0,
        max: _maxLimit,
        divisions: 100,
        onChanged: (vals) => _syncFromSlider(vals),
        onChangeEnd: (_) => HapticFeedback.lightImpact(),
      ),
    );
  }

  Widget _buildPresetWrap() {
    final theme = Theme.of(context);
    final step1 = (_maxLimit * 0.15).roundToDouble();
    final step2 = (_maxLimit * 0.4).roundToDouble();
    final step3 = (_maxLimit * 0.75).roundToDouble();

    String formatM(double val) {
      if (val >= 1000000) {
        final double mVal = val / 1000000;
        return '${mVal.toStringAsFixed(mVal % 1 == 0 ? 0 : 1)}tr';
      }
      return '${(val / 1000).toStringAsFixed(0)}k';
    }

    final List<_Preset> presets = [
      _Preset('Tất cả', 0.0, _maxLimit),
      _Preset('Dưới ${formatM(step1)}', 0.0, step1),
      _Preset('${formatM(step1)} - ${formatM(step2)}', step1, step2),
      _Preset('${formatM(step2)} - ${formatM(step3)}', step2, step3),
      _Preset('Trên ${formatM(step3)}', step3, _maxLimit),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: presets.map((preset) {
        final isSel = (_minPrice == preset.min && _maxPrice == preset.max);
        return GestureDetector(
          onTap: () => _applyPreset(preset.min, preset.max),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSel
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSel
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Text(
              preset.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                color: isSel
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFooter(EdgeInsets safeArea) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, safeArea.bottom + 20),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: OutlinedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                _reset();
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
              child: Text(
                'Thiết lập lại',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                _syncFromFields();
                final effectiveMin = _minPrice > 0 ? _minPrice : null;
                final effectiveMax = _maxPrice < _maxLimit ? _maxPrice : null;
                widget.onApply(effectiveMin, effectiveMax, _sortBy);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'XEM KẾT QUẢ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final int? value = int.tryParse(newValue.text.replaceAll('.', ''));
    if (value == null) return oldValue;

    final newText = value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class _Preset {
  final String label;
  final double min;
  final double max;
  const _Preset(this.label, this.min, this.max);
}

class _SortOption {
  final String value;
  final String label;
  final String sub;
  const _SortOption(this.value, this.label, this.sub);
}
