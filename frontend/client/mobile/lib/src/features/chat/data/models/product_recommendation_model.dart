import 'package:mobile/src/features/chat/domain/entities/product_recommendation_entity.dart';

class RecommendedProductModel extends RecommendedProductEntity {
  const RecommendedProductModel({
    required super.id,
    required super.name,
    super.thumbnailUrl,
    required super.price,
    super.rating,
    super.stock,
  });

  factory RecommendedProductModel.fromJson(Map<String, dynamic> json) {
    return RecommendedProductModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      thumbnailUrl: json['thumbnailUrl']?.toString(),
      price: num.tryParse(json['price']?.toString() ?? '0') ?? 0,
      rating: num.tryParse(json['rating']?.toString() ?? ''),
      stock: num.tryParse(json['stock']?.toString() ?? ''),
    );
  }
}

class ProductRecommendationModel extends ProductRecommendationEntity {
  const ProductRecommendationModel({required super.product, super.reason});

  factory ProductRecommendationModel.fromJson(Map<String, dynamic> json) {
    final productVal = json['product'];
    final Map<String, dynamic> productMap = productVal is Map
        ? Map<String, dynamic>.from(productVal)
        : const {};
    return ProductRecommendationModel(
      product: RecommendedProductModel.fromJson(productMap),
      reason: json['reason']?.toString(),
    );
  }
}
