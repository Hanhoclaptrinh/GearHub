import '../entities/hero_product_entity.dart';
import '../entities/category_entity.dart';
import '../../../../shared/models/product_model.dart';

abstract class HomeRepository {
  Future<List<HeroProductEntity>> getFeaturedProducts();
  Future<List<CategoryEntity>> getTopCategories();
  Future<List<ProductModel>> getNewArrivalsProducts({int limit = 8});
}
