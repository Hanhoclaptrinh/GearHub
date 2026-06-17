class ProductVariantModel {
  final String id;
  final String sku;
  final String name;
  final double price;
  final int stock;
  final Map<String, dynamic> attributes;
  final bool isActive;
  final String? imageUrl;
  final double? flashPrice;
  final int? flashStockLimit;
  final int? flashSoldCount;

  const ProductVariantModel({
    required this.id,
    required this.sku,
    required this.name,
    required this.price,
    required this.stock,
    required this.attributes,
    required this.isActive,
    this.imageUrl,
    this.flashPrice,
    this.flashStockLimit,
    this.flashSoldCount,
  });

  factory ProductVariantModel.fromJson(Map<String, dynamic> json) {
    final flashSaleList = json['flashSaleProducts'] as List?;
    double? parsedFlashPrice;
    int? parsedFlashStockLimit;
    int? parsedFlashSoldCount;

    if (flashSaleList != null && flashSaleList.isNotEmpty) {
      final fs = flashSaleList.first;
      final priceVal = fs['flashPrice'];
      parsedFlashPrice = priceVal is num ? priceVal.toDouble() : double.tryParse(priceVal?.toString() ?? '') ?? 0.0;
      parsedFlashStockLimit = fs['stockLimit'] as int?;
      parsedFlashSoldCount = fs['soldCount'] as int?;
    }

    return ProductVariantModel(
      id: json['id'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      name: json['name'] as String? ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      stock: json['stock'] as int? ?? 0,
      attributes: json['attributes'] != null
          ? Map<String, dynamic>.from(json['attributes'])
          : {},
      isActive: json['isActive'] as bool? ?? true,
      imageUrl: json['imageUrl'] as String?,
      flashPrice: parsedFlashPrice,
      flashStockLimit: parsedFlashStockLimit,
      flashSoldCount: parsedFlashSoldCount,
    );
  }

  bool get hasActiveFlashSale {
    if (flashPrice == null || flashStockLimit == null || flashSoldCount == null) return false;
    return flashSoldCount! < flashStockLimit!;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sku': sku,
      'name': name,
      'price': price,
      'stock': stock,
      'attributes': attributes,
      'isActive': isActive,
      'imageUrl': imageUrl,
      'flashPrice': flashPrice,
      'flashStockLimit': flashStockLimit,
      'flashSoldCount': flashSoldCount,
    };
  }
}
