import 'package:mobile/src/shared/models/product_model.dart';

class CompareKeyModel {
  final String id;
  final String name;
  final String slug;
  final String strategy;

  const CompareKeyModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.strategy,
  });

  factory CompareKeyModel.fromJson(Map<String, dynamic> json) {
    return CompareKeyModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      strategy: json['strategy'] as String? ?? '',
    );
  }
}

class CompareSpecRowModel {
  final String label;
  final Map<String, String?> values;
  final bool isDifferent;

  const CompareSpecRowModel({
    required this.label,
    required this.values,
    required this.isDifferent,
  });

  factory CompareSpecRowModel.fromJson(Map<String, dynamic> json) {
    final rawValues = json['values'] as Map<String, dynamic>? ?? {};
    return CompareSpecRowModel(
      label: json['label'] as String? ?? '',
      values: rawValues.map((key, value) => MapEntry(key, value?.toString())),
      isDifferent: json['isDifferent'] as bool? ?? false,
    );
  }
}

class ProductCompareResultModel {
  final CompareKeyModel compareKey;
  final List<ProductModel> products;
  final List<CompareSpecRowModel> specRows;

  const ProductCompareResultModel({
    required this.compareKey,
    required this.products,
    required this.specRows,
  });

  factory ProductCompareResultModel.fromJson(Map<String, dynamic> json) {
    final productData = json['products'] as List? ?? [];
    final rowData = json['specRows'] as List? ?? [];

    return ProductCompareResultModel(
      compareKey: CompareKeyModel.fromJson(
        json['compareKey'] as Map<String, dynamic>? ?? {},
      ),
      products: productData
          .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      specRows: rowData
          .map(
            (item) =>
                CompareSpecRowModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}
