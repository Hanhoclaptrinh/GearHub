import 'package:dio/dio.dart';

class HomeRemoteDatasource {
  final Dio dio;

  HomeRemoteDatasource({required this.dio});

  Future<List<dynamic>> getFeaturedProducts() async {
    final response = await dio.get('/products/featured');
    return response.data as List<dynamic>;
  }
}
