import 'package:dio/dio.dart';
import '../../../../shared/models/product_model.dart';
import '../../../home/data/models/category_model.dart';

class ExploreRemoteDatasource {
  final Dio dio;

  ExploreRemoteDatasource({required this.dio});

  Future<List<CategoryModel>> getParentCategories() async {
    try {
      final response = await dio.get('/categories');
      final List data = response.data;
      return data
          .map((json) => CategoryModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ProductModel>> getProducts({
    String? categoryId,
    String? brandId,
    String? search,
    double? minPrice,
    double? maxPrice,
    int? limit,
    int? page,
    String? sortBy,
  }) async {
    try {
      final Map<String, dynamic> params = {};
      if (categoryId != null) params['categoryId'] = categoryId;
      if (brandId != null) params['brandId'] = brandId;
      if (search != null) params['search'] = search;
      if (minPrice != null) params['minPrice'] = minPrice;
      if (maxPrice != null) params['maxPrice'] = maxPrice;
      if (limit != null) params['limit'] = limit;
      if (page != null) params['page'] = page;
      if (sortBy != null) params['sortBy'] = sortBy;

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
