class CategoryEntity {
  final String id;
  final String title;
  final String slug;
  final String? iconUrl;
  final int totalSold;

  const CategoryEntity({
    required this.id,
    required this.title,
    required this.slug,
    this.iconUrl,
    required this.totalSold,
  });
}
