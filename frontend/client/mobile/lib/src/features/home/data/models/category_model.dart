import '../../domain/entities/category_entity.dart';

class CategoryModel extends CategoryEntity {
  const CategoryModel({
    required super.title,
    required super.icon,
    required super.slug,
  });
}
