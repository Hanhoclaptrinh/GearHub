import 'package:dio/dio.dart';
import '../models/category_model.dart';
import '../models/brand_model.dart';
import '../models/hero_product_model.dart';
import '../../../../shared/models/product_model.dart';

class HomeRemoteDatasource {
  final Dio dio;

  HomeRemoteDatasource({required this.dio});

  Future<List<HeroProductModel>> getFeaturedProducts() async {
    try {
      final response = await dio.get('/products/featured');
      final List data = response.data;
      return data
          .map(
            (json) => HeroProductModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<CategoryModel>> getTopCategories() async {
    try {
      final response = await dio.get('/categories/top');
      final List data = response.data;
      return data
          .map((json) => CategoryModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<BrandModel>> getTopBrands() async {
    try {
      final response = await dio.get('/brands/top-brands');
      final List data = response.data;
      return data
          .map((json) => BrandModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ProductModel>> getNewArrivalsProducts({int limit = 8}) async {
    try {
      final response = await dio.get(
        '/products',
        queryParameters: {'limit': limit},
      );
      final List data = response.data['data'];
      return data
          .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ProductModel>> getTopRatedProducts({int limit = 5}) async {
    try {
      final response = await dio.get('/products/top-rated');
      final List data = response.data;
      return data
          .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ProductModel>> getVaultProducts() async {
    try {
      final response = await dio.get('/products/vault');
      final List data = response.data;
      return data
          .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> incrementProductView(String id, String deviceId) async {
    try {
      await dio.post(
        '/products/$id/view',
        data: {'deviceId': deviceId},
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ProductModel>> searchProducts({
    required String query,
    int limit = 40,
    double? minPrice,
    double? maxPrice,
  }) async {
    try {
      final Map<String, dynamic> params = {'search': query, 'limit': limit};
      if (minPrice != null) params['minPrice'] = minPrice;
      if (maxPrice != null) params['maxPrice'] = maxPrice;

      final response = await dio.get('/products', queryParameters: params);
      final List? data = response.data['data'];
      if (data == null) return [];
      return data
          .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
}
