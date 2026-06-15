import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/src/features/home/domain/entities/category_entity.dart';

class CategoryOnboardingStep extends StatelessWidget {
  final List<CategoryEntity> categories;
  final Set<String> selectedCategoryIds;
  final Function(String) onCategoryToggled;
  final bool isLoading;

  const CategoryOnboardingStep({
    super.key,
    required this.categories,
    required this.selectedCategoryIds,
    required this.onCategoryToggled,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: size.height * 0.02),
        Text(
          'Chọn danh mục\nquan tâm',
          style: GoogleFonts.outfit(
            fontSize: size.width * 0.13,
            fontWeight: FontWeight.w500,
            height: 1.15,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Bắt đầu hành trình cá nhân hóa thiết bị công nghệ của bạn bằng cách chọn danh mục mong muốn',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: theme.colorScheme.onSurface.withValues(alpha: .5),
          ),
        ),
        SizedBox(height: size.height * 0.04),

        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 16,
            children: List.generate(categories.length, (index) {
              final category = categories[index];
              final isSelected = selectedCategoryIds.contains(category.id);

              Color selectedBg;
              int colorIndex = index % 6;
              if (colorIndex == 0) {
                selectedBg = isDark
                    ? const Color(0xFF818CF8)
                    : const Color(0xFFC7D2FE);
              } else if (colorIndex == 1) {
                selectedBg = isDark
                    ? const Color(0xFFF472B6)
                    : const Color(0xFFFBCFE8);
              } else if (colorIndex == 2) {
                selectedBg = isDark
                    ? const Color(0xFFFDE047)
                    : const Color(0xFFFEF08A);
              } else if (colorIndex == 3) {
                selectedBg = isDark
                    ? const Color(0xFF4ADE80)
                    : const Color(0xFFBBF7D0);
              } else if (colorIndex == 4) {
                selectedBg = isDark
                    ? const Color(0xFF60A5FA)
                    : const Color(0xFFBFDBFE);
              } else {
                selectedBg = isDark
                    ? const Color(0xFFF87171)
                    : const Color(0xFFFECACA);
              }

              return GestureDetector(
                onTap: () => onCategoryToggled(category.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? selectedBg : Colors.transparent,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: isSelected
                          ? (isDark ? Colors.white : Colors.black)
                          : (isDark ? Colors.white24 : Colors.black12),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    category.title,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected
                          ? (isDark
                                ? Colors.black
                                : theme.colorScheme.onSurface)
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        SizedBox(height: size.height * 0.02),
      ],
    );
  }
}
