import 'package:dio/dio.dart';
import 'package:mobile/src/features/product_compare/data/models/product_compare_models.dart';

class ProductCompareRemoteDatasource {
  final Dio dio;

  ProductCompareRemoteDatasource({required this.dio});

  Future<ProductCompareResultModel> compareProducts(
    List<String> productIds, {
    List<String>? variantIds,
  }) async {
    final response = await dio.post(
      '/products/compare',
      data: {
        'productIds': productIds,
        if (variantIds != null) 'variantIds': variantIds,
      },
    );

    return ProductCompareResultModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }
}
