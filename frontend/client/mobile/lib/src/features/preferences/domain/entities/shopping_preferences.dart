class BudgetRangePreference {
  final int? min;
  final int? max;

  const BudgetRangePreference({this.min, this.max});

  bool get isEmpty => min == null && max == null;
}

class ShoppingPreferences {
  final List<String> categoryIds;
  final List<String> brandIds;
  final List<String> styleTags;
  final List<String> useCases;
  final BudgetRangePreference? budgetRange;
  final DateTime? updatedAt;
  final DateTime? completedAt;
  final DateTime? skippedAt;

  const ShoppingPreferences({
    this.categoryIds = const [],
    this.brandIds = const [],
    this.styleTags = const [],
    this.useCases = const [],
    this.budgetRange,
    this.updatedAt,
    this.completedAt,
    this.skippedAt,
  });

  bool get hasSelections {
    return categoryIds.isNotEmpty ||
        brandIds.isNotEmpty ||
        styleTags.isNotEmpty ||
        useCases.isNotEmpty ||
        (budgetRange != null && !budgetRange!.isEmpty);
  }

  bool get isCompleted => completedAt != null;

  bool get isSkipped => skippedAt != null;

  bool get shouldAskOnboarding => !isCompleted && !isSkipped && !hasSelections;

  ShoppingPreferences copyWith({
    List<String>? categoryIds,
    List<String>? brandIds,
    List<String>? styleTags,
    List<String>? useCases,
    BudgetRangePreference? budgetRange,
    DateTime? updatedAt,
    DateTime? completedAt,
    DateTime? skippedAt,
  }) {
    return ShoppingPreferences(
      categoryIds: categoryIds ?? this.categoryIds,
      brandIds: brandIds ?? this.brandIds,
      styleTags: styleTags ?? this.styleTags,
      useCases: useCases ?? this.useCases,
      budgetRange: budgetRange ?? this.budgetRange,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      skippedAt: skippedAt ?? this.skippedAt,
    );
  }
}
