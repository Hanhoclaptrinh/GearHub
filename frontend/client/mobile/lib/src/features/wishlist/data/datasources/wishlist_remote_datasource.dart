import 'package:dio/dio.dart';

class WishlistRemoteDatasource {
  final Dio dio;

  WishlistRemoteDatasource({required this.dio});

  Future<void> toggleWishlist(String productId) async {
    try {
      await dio.post('/wishlist/toggle/$productId');
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> checkIsFavorite(String productId) async {
    try {
      final response = await dio.get('/wishlist/check/$productId');
      if (response.data is Map) {
        return response.data['isFavorite'] ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
