import '../../domain/entities/category_entity.dart';

class CategoryModel extends CategoryEntity {
  const CategoryModel({
    required super.id,
    required super.title,
    required super.slug,
    super.iconUrl,
    super.description,
    required super.totalSold,
    super.children,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      title: json['name'] as String,
      slug: json['slug'] as String,
      iconUrl: json['iconUrl'] as String?,
      description: json['description'] as String?,
      totalSold: json['totalSold'] ?? 0,
      children: json['children'] != null
          ? (json['children'] as List)
                .map((i) => CategoryModel.fromJson(i as Map<String, dynamic>))
                .toList()
          : const [],
    );
  }
}
