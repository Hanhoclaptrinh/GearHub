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
  // dung Set de luu cac productId da xem trong phien lam viec nay
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
      ]);

      emit(
        HomeLoaded(
          featuredProducts: results[0] as List<HeroProductEntity>,
          topCategories: results[1] as List<CategoryEntity>,
          newArrivals: results[2] as List<ProductModel>,
        ),
      );
    } catch (e) {
      emit(HomeError(message: e.toString()));
    }
  }

  Future<void> incrementView(String productId) async {
    // neu san pham nay da duoc tang view trong phien nay thi bo qua
    if (_viewedProducts.contains(productId)) return;

    final currentState = state;
    if (currentState is HomeLoaded) {
      // danh dau da xem de khong tang tiep tren UI va BE (tranh buff view ao)
      _viewedProducts.add(productId);

      // update local state ngay lap tuc
      final updatedNewArrivals = currentState.newArrivals.map((product) {
        if (product.id == productId) {
          return product.copyWith(viewsCount: product.viewsCount + 1);
        }
        return product;
      }).toList();

      emit(currentState.copyWith(newArrivals: updatedNewArrivals));

      try {
        final deviceId = await DeviceUtils.getDeviceId(
          getIt<SecureStorageService>(),
        );
        await _repository.incrementProductView(productId, deviceId);
      } catch (e) {
        // cho phep thu lai neu co loi
        _viewedProducts.remove(productId);
      }
    }
  }
}
