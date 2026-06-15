import 'package:equatable/equatable.dart';

class RecommendedProductEntity extends Equatable {
  final String id;
  final String name;
  final String? thumbnailUrl;
  final num price;
  final num? rating;
  final num? stock;

  const RecommendedProductEntity({
    required this.id,
    required this.name,
    this.thumbnailUrl,
    required this.price,
    this.rating,
    this.stock,
  });

  @override
  List<Object?> get props => [id, name, thumbnailUrl, price, rating, stock];
}

class ProductRecommendationEntity extends Equatable {
  final RecommendedProductEntity product;
  final String? reason;

  const ProductRecommendationEntity({required this.product, this.reason});

  @override
  List<Object?> get props => [product, reason];
}
