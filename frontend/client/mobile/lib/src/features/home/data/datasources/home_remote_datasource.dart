import 'package:dio/dio.dart';
import '../models/category_model.dart';
import '../models/hero_product_model.dart';

class HomeRemoteDatasource {
  final Dio dio;

  HomeRemoteDatasource({required this.dio});

  Future<List<HeroProductModel>> getFeaturedProducts() async {
    try {
      final response = await dio.get('/products/featured');
      final List data = response.data;
      return data
          .map((json) => HeroProductModel.fromJson(json as Map<String, dynamic>))
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
}
