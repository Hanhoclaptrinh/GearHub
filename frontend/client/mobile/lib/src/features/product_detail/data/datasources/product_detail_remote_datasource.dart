import 'package:dio/dio.dart';
import '../../../../shared/models/product_model.dart';

class ProductDetailRemoteDatasource {
  final Dio dio;

  ProductDetailRemoteDatasource({required this.dio});

  Future<ProductModel> getProductDetail(String id) async {
    try {
      final response = await dio.get('/products/$id');
      return ProductModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ProductModel>> getRelatedProducts(String id) async {
    try {
      final response = await dio.get('/products/$id/related');
      final List data = response.data;
      return data
          .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> incrementView(String id, String deviceId) async {
    try {
      await dio.post('/products/$id/view', data: {'deviceId': deviceId});
    } catch (e) {
      rethrow;
    }
  }
}
