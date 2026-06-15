import 'package:mobile/src/features/preferences/domain/entities/shopping_preferences.dart';

class BudgetRangePreferenceModel extends BudgetRangePreference {
  const BudgetRangePreferenceModel({super.min, super.max});

  factory BudgetRangePreferenceModel.fromJson(Map<String, dynamic> json) {
    return BudgetRangePreferenceModel(
      min: (json['min'] as num?)?.toInt(),
      max: (json['max'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'min': min,
    'max': max,
  };
}

class ShoppingPreferencesModel extends ShoppingPreferences {
  const ShoppingPreferencesModel({
    super.categoryIds,
    super.brandIds,
    super.styleTags,
    super.useCases,
    super.budgetRange,
    super.updatedAt,
    super.completedAt,
    super.skippedAt,
  });

  factory ShoppingPreferencesModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ShoppingPreferencesModel();

    return ShoppingPreferencesModel(
      categoryIds: _stringList(json['categoryIds']),
      brandIds: _stringList(json['brandIds']),
      styleTags: _stringList(json['styleTags']),
      useCases: _stringList(json['useCases']),
      budgetRange: json['budgetRange'] is Map<String, dynamic>
          ? BudgetRangePreferenceModel.fromJson(
              json['budgetRange'] as Map<String, dynamic>,
            )
          : null,
      updatedAt: _date(json['updatedAt']),
      completedAt: _date(json['completedAt']),
      skippedAt: _date(json['skippedAt']),
    );
  }

  factory ShoppingPreferencesModel.fromEntity(ShoppingPreferences value) {
    return ShoppingPreferencesModel(
      categoryIds: value.categoryIds,
      brandIds: value.brandIds,
      styleTags: value.styleTags,
      useCases: value.useCases,
      budgetRange: value.budgetRange,
      updatedAt: value.updatedAt,
      completedAt: value.completedAt,
      skippedAt: value.skippedAt,
    );
  }

  Map<String, dynamic> toJson({
    bool completed = false,
    bool skipped = false,
  }) {
    return {
      'categoryIds': categoryIds,
      'brandIds': brandIds,
      'styleTags': styleTags,
      'useCases': useCases,
      'budgetRange': budgetRange == null
          ? null
          : {
              'min': budgetRange!.min,
              'max': budgetRange!.max,
            },
      if (completed) 'completed': true,
      if (skipped) 'skipped': true,
    };
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<String>().where((item) => item.trim().isNotEmpty).toList();
  }

  static DateTime? _date(dynamic value) {
    if (value is! String) return null;
    return DateTime.tryParse(value)?.toLocal();
  }
}
