import '../entities/hero_product_entity.dart';
import '../entities/category_entity.dart';

abstract class HomeRepository {
  Future<List<HeroProductEntity>> getFeaturedProducts();
  Future<List<CategoryEntity>> getTopCategories();
}
