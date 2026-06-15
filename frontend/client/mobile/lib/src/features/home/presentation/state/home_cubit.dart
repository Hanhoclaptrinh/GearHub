import 'package:dio/dio.dart';
import 'package:mobile/src/features/home/domain/entities/brand_entity.dart';
import 'package:mobile/src/features/home/domain/entities/category_entity.dart';
import 'package:mobile/src/features/home/domain/entities/hero_product_entity.dart';
import 'package:mobile/src/features/home/domain/repositories/home_repository.dart';
import '../../../../shared/models/product_model.dart';
import 'package:mobile/src/core/di/injection.dart';
import 'package:mobile/src/core/storage/secure_storage_service.dart';
import 'package:mobile/src/core/utils/device_utils.dart';
import 'home_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeCubit extends Cubit<HomeState> {
  final HomeRepository _repository;
  //dùng set để lưu các id sp đã xem trong phiên
  final Set<String> _viewedProducts = {};

  HomeCubit({required HomeRepository repository})
    : _repository = repository,
      super(HomeInitial());

  Future<void> loadHomeData() async {
    emit(HomeLoading());
    try {
      final results = await Future.wait([
        _repository.getFeaturedProducts(),
        _repository.getTopCategories(),
        _repository.getNewArrivalsProducts(limit: 8),
        _repository.getTopBrands(),
        _repository.getTopRatedProducts(limit: 5),
        _loadRecommendedProducts(),
        _repository.getParentCategories(),
      ]);

      emit(
        HomeLoaded(
          featuredProducts: results[0] as List<HeroProductEntity>,
          topCategories: results[1] as List<CategoryEntity>,
          newArrivals: results[2] as List<ProductModel>,
          topBrands: results[3] as List<BrandEntity>,
          topRatedProducts: results[4] as List<ProductModel>,
          recommendedProducts: results[5] as List<ProductModel>,
          parentCategories: results[6] as List<CategoryEntity>,
        ),
      );
    } catch (e) {
      String errMsg = 'Không thể tải dữ liệu trang chủ.';
      if (e is DioException) {
        if (e.response?.data != null && e.response!.data is Map) {
          final data = e.response!.data;
          if (data['message'] != null) {
            errMsg = data['message'].toString();
          }
        } else {
          errMsg = e.toString();
        }
      } else {
        errMsg = e.toString();
      }
      emit(HomeError(message: errMsg));
    }
  }

  Future<List<ProductModel>> _loadRecommendedProducts() async {
    try {
      return await _repository.getRecommendedProducts(limit: 8);
    } catch (_) {
      return const [];
    }
  }

  Future<void> incrementView(String productId) async {
    //nếu sp đã được tăng view trong phiên thì skip
    if (_viewedProducts.contains(productId)) return;

    final currentState = state;
    if (currentState is HomeLoaded) {
      //mark đã xem tránh buff view
      _viewedProducts.add(productId);

      //cập nhật trạng thái local
      final updatedNewArrivals = currentState.newArrivals.map((product) {
        if (product.id == productId) {
          return product.copyWith(viewsCount: product.viewsCount + 1);
        }
        return product;
      }).toList();

      final updatedRecommendedProducts = currentState.recommendedProducts.map((
        product,
      ) {
        if (product.id == productId) {
          return product.copyWith(viewsCount: product.viewsCount + 1);
        }
        return product;
      }).toList();

      emit(
        currentState.copyWith(
          newArrivals: updatedNewArrivals,
          recommendedProducts: updatedRecommendedProducts,
        ),
      );

      try {
        final deviceId = await DeviceUtils.getDeviceId(
          getIt<SecureStorageService>(),
        );
        await _repository.incrementProductView(productId, deviceId);
      } catch (e) {
        _viewedProducts.remove(productId);
      }
    }
  }
}
