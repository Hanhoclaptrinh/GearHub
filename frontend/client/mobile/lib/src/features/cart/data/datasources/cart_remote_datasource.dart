import 'package:mobile/src/core/network/api_client.dart';
import 'package:mobile/src/features/cart/data/models/cart_model.dart';
import 'package:mobile/src/shared/models/product_model.dart';

abstract class CartRemoteDataSource {
  Future<CartModel> getCart();
  Future<int> getCartCount();
  Future<CartModel> addToCart(String variantId, int quantity);
  Future<CartModel> updateQuantity(String itemId, int quantity);
  Future<CartModel> removeItem(String itemId);
  Future<CartModel> clearSelectedItems(List<String> variantIds);
  Future<void> clearCart();
  Future<CartModel> syncCart(List<Map<String, dynamic>> items);
  Future<List<ProductModel>> getRecommendations({int limit = 8});
}

class CartRemoteDataSourceImpl implements CartRemoteDataSource {
  final ApiClient apiClient;

  CartRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<CartModel> getCart() async {
    final response = await apiClient.dio.get('/cart');
    return CartModel.fromJson(response.data);
  }

  @override
  Future<int> getCartCount() async {
    final response = await apiClient.dio.get('/cart/count');
    return response.data['count'] ?? 0;
  }

  @override
  Future<CartModel> addToCart(String variantId, int quantity) async {
    final response = await apiClient.dio.post(
      '/cart',
      data: {'variantId': variantId, 'quantity': quantity},
    );
    return CartModel.fromJson(response.data);
  }

  @override
  Future<CartModel> updateQuantity(String itemId, int quantity) async {
    final response = await apiClient.dio.patch(
      '/cart/item/$itemId',
      data: {'quantity': quantity},
    );
    return CartModel.fromJson(response.data);
  }

  @override
  Future<CartModel> removeItem(String itemId) async {
    final response = await apiClient.dio.delete('/cart/item/$itemId');
    return CartModel.fromJson(response.data);
  }

  @override
  Future<CartModel> clearSelectedItems(List<String> variantIds) async {
    final response = await apiClient.dio.delete(
      '/cart/clear-selected',
      data: {'variantIds': variantIds},
    );
    return CartModel.fromJson(response.data);
  }

  @override
  Future<void> clearCart() async {
    await apiClient.dio.delete('/cart/clear-all');
  }

  @override
  Future<CartModel> syncCart(List<Map<String, dynamic>> items) async {
    final response = await apiClient.dio.post(
      '/cart/sync',
      data: {'items': items},
    );
    return CartModel.fromJson(response.data);
  }

  @override
  Future<List<ProductModel>> getRecommendations({int limit = 8}) async {
    final response = await apiClient.dio.get(
      '/cart/recommendations',
      queryParameters: {'limit': limit},
    );
    final data = response.data as List;
    return data
        .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
