import 'package:mobile/src/features/home/domain/entities/category_entity.dart';
import 'package:mobile/src/features/home/domain/entities/hero_product_entity.dart';
import 'package:mobile/src/features/home/domain/repositories/home_repository.dart';
import '../../../../shared/models/product_model.dart';
import 'home_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeCubit extends Cubit<HomeState> {
  final HomeRepository _repository;

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
}
