import '../entities/hero_product_entity.dart';
import '../entities/category_entity.dart';
import '../entities/brand_entity.dart';
import '../../../../shared/models/product_model.dart';

abstract class HomeRepository {
  Future<List<HeroProductEntity>> getFeaturedProducts();
  Future<List<CategoryEntity>> getTopCategories();
  Future<List<BrandEntity>> getTopBrands();
  Future<List<ProductModel>> getNewArrivalsProducts({int limit = 8});
  Future<List<ProductModel>> getTopRatedProducts({int limit = 5});
  Future<List<ProductModel>> getVaultProducts();
  Future<void> incrementProductView(String id, String deviceId);
}
