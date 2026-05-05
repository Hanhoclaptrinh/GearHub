import '../../../home/domain/entities/category_entity.dart';
import '../../../../shared/models/product_model.dart';

abstract class ExploreRepository {
  Future<List<CategoryEntity>> getParentCategories();
  Future<List<ProductModel>> getProducts({
    String? categoryId,
    String? brandId,
    String? search,
    double? minPrice,
    double? maxPrice,
    int? limit,
    int? page,
    String? sortBy,
  });
}
