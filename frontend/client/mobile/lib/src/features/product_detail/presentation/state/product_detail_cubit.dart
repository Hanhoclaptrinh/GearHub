import 'package:flutter_bloc/flutter_bloc.dart';
import 'product_detail_state.dart';
import '../../domain/repositories/product_detail_repository.dart';

class ProductDetailCubit extends Cubit<ProductDetailState> {
  final ProductDetailRepository _repository;

  ProductDetailCubit({
    required ProductDetailRepository repository,
  }) : _repository = repository,
       super(ProductDetailInitial());

  Future<void> loadProduct(String id) async {
    emit(ProductDetailLoading());
    try {
      final product = await _repository.getProductDetail(id);
      final related = await _repository.getRelatedProducts(id);
      
      emit(ProductDetailLoaded(
        product: product,
        relatedProducts: related,
      ));
    } catch (e) {
      emit(ProductDetailError(e.toString()));
    }
  }

  Future<void> incrementView(String id, String deviceId) async {
    try {
      await _repository.incrementView(id, deviceId);
    } catch (e) {
      // Implemented silently as in home feature
    }
  }
}
