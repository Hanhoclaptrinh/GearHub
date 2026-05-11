import 'package:mobile/src/features/home/domain/entities/brand_entity.dart';

class BrandModel extends BrandEntity {
  const BrandModel({
    required super.id,
    required super.name,
    super.slug,
    required super.logoUrl,
    super.quote,
    super.philosophy,
  });

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    return BrandModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown',
      slug: json['slug'] as String?,
      logoUrl: json['logoUrl'] as String? ?? json['logo_url'] as String? ?? '',
      quote: json['quote'] as String?,
      philosophy: json['philosophy'] as String?,
    );
  }
}
