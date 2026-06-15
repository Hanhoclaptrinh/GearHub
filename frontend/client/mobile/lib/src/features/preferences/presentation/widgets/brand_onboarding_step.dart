import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/src/features/home/domain/entities/brand_entity.dart';

class BrandOnboardingStep extends StatelessWidget {
  final List<BrandEntity> brands;
  final Set<String> selectedBrandIds;
  final Function(String) onBrandToggled;
  final bool isLoading;

  const BrandOnboardingStep({
    super.key,
    required this.brands,
    required this.selectedBrandIds,
    required this.onBrandToggled,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: size.height * 0.2,
          left: size.width * 0.1,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(
                    0xFF818CF8,
                  ).withValues(alpha: isDark ? 0.08 : 0.12),
                  blurRadius: 70,
                  spreadRadius: 20,
                ),
              ],
            ),
          ),
        ),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: size.height * 0.02),
            Text(
              'Chọn thương hiệu\nyêu thích',
              style: GoogleFonts.outfit(
                fontSize: size.width * 0.13,
                fontWeight: FontWeight.w500,
                height: 1.15,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Bạn là fan cứng của nhà nào? Chọn những cái tên mà bạn tin tưởng nhất nhé.',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: theme.colorScheme.onSurface.withValues(alpha: .5),
              ),
            ),
            SizedBox(height: size.height * 0.04),
            //brand list
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              clipBehavior: Clip.none,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              itemCount: brands.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 18,
                crossAxisSpacing: 18,
                childAspectRatio: 0.92,
              ),
              itemBuilder: (context, index) {
                final brand = brands[index];
                final isSelected = selectedBrandIds.contains(brand.id);

                Color selectedColor;
                int colorIndex = index % 6;
                if (colorIndex == 0) {
                  selectedColor = const Color(0xFF818CF8);
                } else if (colorIndex == 1) {
                  selectedColor = const Color(0xFFF472B6);
                } else if (colorIndex == 2) {
                  selectedColor = const Color(0xFFFBBF24);
                } else if (colorIndex == 3) {
                  selectedColor = const Color(0xFF34D399);
                } else if (colorIndex == 4) {
                  selectedColor = const Color(0xFF60A5FA);
                } else {
                  selectedColor = const Color(0xFFF87171);
                }

                return GestureDetector(
                  onTap: () => onBrandToggled(brand.id),
                  child: AnimatedScale(
                    scale: isSelected ? 1.05 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutBack,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: selectedColor.withValues(alpha: .3),
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: isSelected
                                    ? [
                                        selectedColor.withValues(alpha: .25),
                                        selectedColor.withValues(alpha: .06),
                                      ]
                                    : (isDark
                                          ? [
                                              Colors.white.withValues(
                                                alpha: .08,
                                              ),
                                              Colors.white.withValues(
                                                alpha: .02,
                                              ),
                                            ]
                                          : [
                                              Colors.white.withValues(
                                                alpha: .85,
                                              ),
                                              Colors.white.withValues(
                                                alpha: .55,
                                              ),
                                            ]),
                              ),
                              border: Border.all(
                                color: isSelected
                                    ? selectedColor.withValues(alpha: .9)
                                    : (isDark
                                          ? Colors.white.withValues(alpha: .12)
                                          : Colors.black.withValues(
                                              alpha: .06,
                                            )),
                                width: isSelected ? 2.0 : 1.0,
                              ),
                            ),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(24),
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: const Alignment(0.2, 0.2),
                                        colors: [
                                          Colors.white.withValues(
                                            alpha: isDark ? 0.12 : 0.25,
                                          ),
                                          Colors.white.withValues(alpha: .0),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                //brand logo
                                Center(
                                  child: Container(
                                    width: 58,
                                    height: 58,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: .05,
                                          ),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(8),
                                    child: ClipOval(
                                      child: SvgPicture.network(
                                        brand.logoUrl,
                                        fit: BoxFit.contain,
                                        placeholderBuilder: (context) =>
                                            const Center(
                                              child: SizedBox(
                                                width: 14,
                                                height: 14,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              ),
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          if (isSelected)
                            Positioned(
                              top: -4,
                              right: -4,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: selectedColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: theme.scaffoldBackgroundColor,
                                    width: 2.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: .15,
                                      ),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 11,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: size.height * 0.05),
          ],
        ),
      ],
    );
  }
}
