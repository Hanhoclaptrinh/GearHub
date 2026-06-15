import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/src/core/di/injection.dart';
import 'package:mobile/src/core/utils/budget_options.dart';
import 'package:mobile/src/features/explore/domain/repositories/explore_repository.dart';

class BudgetOnboardingStep extends StatefulWidget {
  final int? currentMinPrice;
  final int? currentMaxPrice;
  final Function(int? min, int? max) onBudgetChanged;

  const BudgetOnboardingStep({
    super.key,
    required this.currentMinPrice,
    required this.currentMaxPrice,
    required this.onBudgetChanged,
  });

  @override
  State<BudgetOnboardingStep> createState() => _BudgetOnboardingStepState();
}

class _BudgetOnboardingStepState extends State<BudgetOnboardingStep>
    with SingleTickerProviderStateMixin {
  final List<BudgetTier> _tiers = budgetOptions;
  late int _selectedIndex;
  List<String> _realProducts = [];
  bool _isLoadingProducts = true;

  //animation
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _selectedIndex = _findInitialIndex();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _fetchRealProducts();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  int _findInitialIndex() {
    for (int i = 0; i < _tiers.length; i++) {
      if (_tiers[i].minPrice == widget.currentMinPrice &&
          _tiers[i].maxPrice == widget.currentMaxPrice) {
        return i;
      }
    }
    return 2; //default range 2
  }

  Future<void> _fetchRealProducts() async {
    if (!mounted) return;

    if (!_isLoadingProducts) {
      setState(() {
        _isLoadingProducts = true;
      });
    }

    try {
      final selectedTier = _tiers[_selectedIndex];
      final exploreRepo = getIt<ExploreRepository>();
      final products = await exploreRepo.getProducts(
        minPrice: selectedTier.minPrice?.toDouble(),
        maxPrice: selectedTier.maxPrice?.toDouble(),
        limit: 5,
      );

      if (mounted) {
        setState(() {
          if (products.isNotEmpty) {
            _realProducts = products.map((p) => p.baseName).toList();
          } else {
            _realProducts = selectedTier.fallbackItems;
          }
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _realProducts = _tiers[_selectedIndex].fallbackItems;
          _isLoadingProducts = false;
        });
      }
    }
  }

  void _selectTier(int index) {
    if (index == _selectedIndex) return;
    HapticFeedback.lightImpact();
    setState(() {
      _selectedIndex = index;
    });

    final tier = _tiers[index];
    widget.onBudgetChanged(tier.minPrice, tier.maxPrice);
    _fetchRealProducts();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeTier = _tiers[_selectedIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: size.height * 0.02),
        Text(
          'Ngân sách thiết lập',
          style: GoogleFonts.outfit(
            fontSize: size.width * 0.13,
            fontWeight: FontWeight.w500,
            height: 1.15,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Lựa chọn khoảng giá mong muốn để nhận các đề xuất sản phẩm phù hợp nhất với bạn.',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: theme.colorScheme.onSurface.withValues(alpha: .5),
          ),
        ),
        SizedBox(height: size.height * 0.04),

        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _tiers.length,
          separatorBuilder: (context, index) => Divider(
            color: isDark
                ? Colors.white.withValues(alpha: .06)
                : Colors.black.withValues(alpha: .06),
            height: 1,
          ),
          itemBuilder: (context, index) {
            final tier = _tiers[index];
            final isSelected = index == _selectedIndex;

            return GestureDetector(
              onTap: () => _selectTier(index),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 18.0,
                  horizontal: 4.0,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text(
                        tier.priceLabel,
                        style: GoogleFonts.outfit(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? tier.themeColor
                              : theme.colorScheme.onSurface.withValues(
                                  alpha: .7,
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tier.title,
                            style: GoogleFonts.outfit(
                              fontSize: 14.5,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isSelected
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.onSurface.withValues(
                                      alpha: 0.7,
                                    ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            tier.description,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.4,
                              ),
                              height: 1.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? tier.themeColor
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : (isDark ? Colors.white24 : Colors.black26),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        Divider(
          color: isDark
              ? Colors.white.withValues(alpha: .06)
              : Colors.black.withValues(alpha: .06),
          height: 1,
        ),

        const SizedBox(height: 36),

        Text(
          'SẢN PHẨM THỰC TẾ TRONG PHÂN KHÚC:',
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withValues(alpha: .4),
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 16),

        _isLoadingProducts
            ? _buildShimmerGrid()
            : Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _realProducts
                    .map(
                      (name) => _buildProductChip(name, activeTier.themeColor),
                    )
                    .toList(),
              ),
      ],
    );
  }

  Widget _buildProductChip(String name, Color themeColor) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: .03)
            : Colors.black.withValues(alpha: .02),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: themeColor.withValues(alpha: .12), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: themeColor.withValues(alpha: .7),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            name,
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface.withValues(alpha: .8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerGrid() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final opacity = 0.2 + (_shimmerController.value * 0.4);
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(4, (index) {
            final widths = [130.0, 95.0, 150.0, 110.0];
            return Opacity(
              opacity: opacity,
              child: Container(
                width: widths[index % widths.length],
                height: 33,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: .08)
                      : Colors.black.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
