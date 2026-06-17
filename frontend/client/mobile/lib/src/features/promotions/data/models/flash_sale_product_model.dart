class FlashSaleProductModel {
  final String id;
  final String productVariantId;
  final double flashPrice;
  final int stockLimit;
  final int soldCount;
  final String startsAt;
  final String expiresAt;
  final String createdAt;
  final String updatedAt;
  final FlashSaleProductVariantModel productVariant;

  const FlashSaleProductModel({
    required this.id,
    required this.productVariantId,
    required this.flashPrice,
    required this.stockLimit,
    required this.soldCount,
    required this.startsAt,
    required this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
    required this.productVariant,
  });

  factory FlashSaleProductModel.fromJson(Map<String, dynamic> json) {
    return FlashSaleProductModel(
      id: json['id'] as String? ?? '',
      productVariantId: json['productVariantId'] as String? ?? '',
      flashPrice: _toDouble(json['flashPrice']),
      stockLimit: (json['stockLimit'] as num?)?.toInt() ?? 0,
      soldCount: (json['soldCount'] as num?)?.toInt() ?? 0,
      startsAt: json['startsAt'] as String? ?? '',
      expiresAt: json['expiresAt'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
      productVariant: FlashSaleProductVariantModel.fromJson(
        json['productVariant'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  static double _toDouble(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0;
    return 0;
  }
}

class FlashSaleProductVariantModel {
  final String id;
  final String name;
  final String sku;
  final double price;
  final int stock;
  final String? imageUrl;
  final Map<String, dynamic> attributes;
  final FlashSaleProductInfoModel product;

  const FlashSaleProductVariantModel({
    required this.id,
    required this.name,
    required this.sku,
    required this.price,
    required this.stock,
    this.imageUrl,
    required this.attributes,
    required this.product,
  });

  factory FlashSaleProductVariantModel.fromJson(Map<String, dynamic> json) {
    return FlashSaleProductVariantModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      price: _toDouble(json['price']),
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      imageUrl: json['imageUrl'] as String?,
      attributes: json['attributes'] != null
          ? Map<String, dynamic>.from(json['attributes'])
          : {},
      product: FlashSaleProductInfoModel.fromJson(
        json['product'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  static double _toDouble(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0;
    return 0;
  }
}

class FlashSaleProductInfoModel {
  final String id;
  final String name;
  final String slug;
  final String? thumbnailUrl;

  const FlashSaleProductInfoModel({
    required this.id,
    required this.name,
    required this.slug,
    this.thumbnailUrl,
  });

  factory FlashSaleProductInfoModel.fromJson(Map<String, dynamic> json) {
    return FlashSaleProductInfoModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String?,
    );
  }
}
