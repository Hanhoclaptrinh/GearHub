import 'package:mobile/src/features/product_compare/data/datasources/product_compare_remote_datasource.dart';
import 'package:mobile/src/features/product_compare/data/models/product_compare_models.dart';
import 'package:mobile/src/features/product_compare/domain/repositories/product_compare_repository.dart';

class ProductCompareRepositoryImpl implements ProductCompareRepository {
  final ProductCompareRemoteDatasource remoteDatasource;

  ProductCompareRepositoryImpl({required this.remoteDatasource});

  @override
  Future<ProductCompareResultModel> compareProducts(
    List<String> productIds, {
    List<String>? variantIds,
  }) {
    return remoteDatasource.compareProducts(productIds, variantIds: variantIds);
  }
}
