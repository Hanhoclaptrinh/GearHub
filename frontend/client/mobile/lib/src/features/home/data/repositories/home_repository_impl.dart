import '../datasources/home_remote_datasource.dart';
import '../../domain/repositories/home_repository.dart';
import '../../domain/entities/hero_product_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/brand_entity.dart';
import '../../../../shared/models/product_model.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDatasource remoteDatasource;

  HomeRepositoryImpl({required this.remoteDatasource});

  @override
  Future<List<HeroProductEntity>> getFeaturedProducts() async {
    try {
      return await remoteDatasource.getFeaturedProducts();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<CategoryEntity>> getTopCategories() async {
    try {
      return await remoteDatasource.getTopCategories();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<BrandEntity>> getTopBrands() async {
    try {
      return await remoteDatasource.getTopBrands();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<ProductModel>> getNewArrivalsProducts({int limit = 8}) async {
    try {
      return await remoteDatasource.getNewArrivalsProducts(limit: limit);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<ProductModel>> getTopRatedProducts({int limit = 5}) async {
    try {
      return await remoteDatasource.getTopRatedProducts(limit: limit);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<ProductModel>> getVaultProducts() async {
    try {
      return await remoteDatasource.getVaultProducts();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> incrementProductView(String id, String deviceId) async {
    try {
      await remoteDatasource.incrementProductView(id, deviceId);
    } catch (e) {
      rethrow;
    }
  }
}
