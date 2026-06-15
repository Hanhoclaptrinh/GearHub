import '../entities/hero_product_entity.dart';
import '../entities/category_entity.dart';
import '../entities/brand_entity.dart';
import '../../../../shared/models/product_model.dart';

abstract class HomeRepository {
  Future<List<HeroProductEntity>> getFeaturedProducts();
  Future<List<CategoryEntity>> getTopCategories();
  Future<List<CategoryEntity>> getParentCategories();
  Future<List<BrandEntity>> getTopBrands();
  Future<List<BrandEntity>> getBrands();
  Future<List<ProductModel>> getNewArrivalsProducts({int limit = 8});
  Future<List<ProductModel>> getTopRatedProducts({int limit = 5});
  Future<List<ProductModel>> getRecommendedProducts({int limit = 8});
  Future<List<ProductModel>> imageSearchProducts({
    required String imageBase64,
    int limit = 20,
  });
  Future<void> incrementProductView(String id, String deviceId);
}
