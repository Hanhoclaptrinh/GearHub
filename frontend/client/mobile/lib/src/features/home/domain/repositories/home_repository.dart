import '../entities/hero_product_entity.dart';

abstract class HomeRepository {
  Future<List<HeroProductEntity>> getFeaturedProducts();
}
