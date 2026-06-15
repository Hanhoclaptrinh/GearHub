class BrandEntity {
  final String id;
  final String name;
  final String? slug;
  final String logoUrl;
  final String? bannerUrl;
  final String? quote;
  final String? philosophy;
  final int? productCount;
  final bool? isActive;

  const BrandEntity({
    required this.id,
    required this.name,
    this.slug,
    required this.logoUrl,
    this.bannerUrl,
    this.quote,
    this.philosophy,
    this.productCount,
    this.isActive,
  });
}
