import '../../../../shared/models/product_model.dart';

abstract class ProductDetailRepository {
  Future<ProductModel> getProductDetail(String id);
  Future<List<ProductModel>> getRelatedProducts(String id);
  Future<void> incrementView(String id, String deviceId);
}
