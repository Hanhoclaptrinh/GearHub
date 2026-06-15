import 'package:mobile/src/features/home/domain/entities/brand_entity.dart';

class BrandModel extends BrandEntity {
  const BrandModel({
    required super.id,
    required super.name,
    super.slug,
    required super.logoUrl,
    super.bannerUrl,
    super.quote,
    super.philosophy,
    super.productCount,
    super.isActive,
  });

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    final countMap = json['_count'] as Map<String, dynamic>?;
    final parsedCount = countMap?['products'] as int? ?? json['productCount'] as int?;

    return BrandModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown',
      slug: json['slug'] as String?,
      logoUrl: json['logoUrl'] as String? ?? json['logo_url'] as String? ?? '',
      bannerUrl: json['bannerUrl'] as String? ?? json['banner_url'] as String?,
      quote: json['quote'] as String?,
      philosophy: json['philosophy'] as String?,
      productCount: parsedCount,
      isActive: json['isActive'] as bool?,
    );
  }
}
