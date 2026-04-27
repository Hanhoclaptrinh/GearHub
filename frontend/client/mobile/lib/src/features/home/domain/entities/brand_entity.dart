class BrandEntity {
  final String id;
  final String name;
  final String? slug;
  final String logoUrl;

  const BrandEntity({
    required this.id,
    required this.name,
    this.slug,
    required this.logoUrl,
  });
}
