import '../datasources/product_detail_remote_datasource.dart';
import '../../domain/repositories/product_detail_repository.dart';
import '../../../../shared/models/product_model.dart';

class ProductDetailRepositoryImpl implements ProductDetailRepository {
  final ProductDetailRemoteDatasource remoteDatasource;

  ProductDetailRepositoryImpl({required this.remoteDatasource});

  @override
  Future<ProductModel> getProductDetail(String id) {
    return remoteDatasource.getProductDetail(id);
  }

  @override
  Future<List<ProductModel>> getRelatedProducts(String id) {
    return remoteDatasource.getRelatedProducts(id);
  }

  @override
  Future<void> incrementView(String id, String deviceId) {
    return remoteDatasource.incrementView(id, deviceId);
  }
}
