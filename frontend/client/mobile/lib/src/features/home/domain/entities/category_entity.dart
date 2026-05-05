class CategoryEntity {
  final String id;
  final String title;
  final String slug;
  final String? iconUrl;
  final String? description;
  final int totalSold;
  final List<CategoryEntity> children;

  const CategoryEntity({
    required this.id,
    required this.title,
    required this.slug,
    this.iconUrl,
    this.description,
    required this.totalSold,
    this.children = const [],
  });
}
