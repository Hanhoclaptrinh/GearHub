import 'package:mobile/src/shared/models/product_variant_model.dart';

class ProductModel {
  final String id;
  final String name;
  final String tagline;
  final double price;
  final String image;
  final String? tag;
  final int viewsCount;
  final double averageRating;
  final int reviewCount;
  final String description;
  final Map<String, dynamic>? vaultSpecs;
  final String? brandName;
  final List<ProductVariantModel> variants;

  const ProductModel({
    required this.id,
    required this.name,
    required this.tagline,
    required this.price,
    required this.image,
    required this.description,
    this.tag,
    this.viewsCount = 0,
    this.averageRating = 0.0,
    this.reviewCount = 0,
    this.vaultSpecs,
    this.brandName,
    this.variants = const [],
  });

  ProductModel copyWith({
    String? id,
    String? name,
    String? tagline,
    double? price,
    String? image,
    String? tag,
    int? viewsCount,
    double? averageRating,
    int? reviewCount,
    String? description,
    Map<String, dynamic>? vaultSpecs,
    String? brandName,
    List<ProductVariantModel>? variants,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      tagline: tagline ?? this.tagline,
      price: price ?? this.price,
      image: image ?? this.image,
      tag: tag ?? this.tag,
      viewsCount: viewsCount ?? this.viewsCount,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
      description: description ?? this.description,
      vaultSpecs: vaultSpecs ?? this.vaultSpecs,
      brandName: brandName ?? this.brandName,
      variants: variants ?? this.variants,
    );
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    double price = 0.0;
    List<ProductVariantModel> variants = [];

    if (json['variants'] != null && (json['variants'] as List).isNotEmpty) {
      variants = (json['variants'] as List)
          .map((v) => ProductVariantModel.fromJson(v))
          .toList();
      price = variants.isNotEmpty ? variants.first.price : 0.0;
    } else if (json['price'] != null) {
      price = double.tryParse(json['price']?.toString() ?? '0') ?? 0.0;
    }

    final String desc = json['description'] ?? '';
    final String? apiTagline = json['tagline'];

    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      tagline: (apiTagline != null && apiTagline.isNotEmpty)
          ? apiTagline
          : _extractFirstSentence(desc),
      price: price,
      image: json['thumbnailUrl'] ?? '',
      tag: 'MỚI',
      viewsCount: json['viewsCount'] as int? ?? 0,
      averageRating:
          double.tryParse(json['averageRating']?.toString() ?? '0.0') ?? 0.0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      description: desc,
      vaultSpecs: json['vaultSpecs'] as Map<String, dynamic>?,
      brandName: json['brand']?['name'] as String?,
      variants: variants,
    );
  }

  static String _extractFirstSentence(String description) {
    if (description.isEmpty) return '';
    final String firstSentence = description.split(RegExp(r'[.!?]')).first;
    final String trimmed = firstSentence.trim();
    if (trimmed.length > 60) {
      return '${trimmed.substring(0, 57).trim()}...';
    }
    return trimmed;
  }
}

