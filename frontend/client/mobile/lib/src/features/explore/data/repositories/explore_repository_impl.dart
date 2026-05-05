import '../datasources/explore_remote_datasource.dart';
import '../../domain/repositories/explore_repository.dart';
import '../../../home/domain/entities/category_entity.dart';
import '../../../../shared/models/product_model.dart';

class ExploreRepositoryImpl implements ExploreRepository {
  final ExploreRemoteDatasource remoteDatasource;

  ExploreRepositoryImpl({required this.remoteDatasource});

  @override
  Future<List<CategoryEntity>> getParentCategories() async {
    return remoteDatasource.getParentCategories();
  }

  @override
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
    return remoteDatasource.getProducts(
      categoryId: categoryId,
      brandId: brandId,
      search: search,
      minPrice: minPrice,
      maxPrice: maxPrice,
      limit: limit,
      page: page,
      sortBy: sortBy,
    );
  }
}
