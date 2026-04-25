import 'package:mobile/src/features/home/domain/repositories/home_repository.dart';
import 'home_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeCubit extends Cubit<HomeState> {
  final HomeRepository _repository;

  HomeCubit({required HomeRepository repository})
    : _repository = repository,
      super(HomeInitial());

  Future<void> fetchFeaturedProducts() async {
    emit(HomeLoading());
    try {
      final products = await _repository.getFeaturedProducts();
      emit(HomeLoaded(featuredProducts: products));
    } catch (e) {
      emit(HomeError(message: e.toString()));
    }
  }
}
