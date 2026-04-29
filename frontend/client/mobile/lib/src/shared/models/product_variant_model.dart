class ProductVariantModel {
  final String id;
  final String sku;
  final String name;
  final double price;
  final int stock;
  final Map<String, dynamic> attributes;

  const ProductVariantModel({
    required this.id,
    required this.sku,
    required this.name,
    required this.price,
    required this.stock,
    required this.attributes,
  });

  factory ProductVariantModel.fromJson(Map<String, dynamic> json) {
    return ProductVariantModel(
      id: json['id'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      name: json['name'] as String? ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      stock: json['stock'] as int? ?? 0,
      attributes: json['attributes'] as Map<String, dynamic>? ?? {},
    );
  }
}
