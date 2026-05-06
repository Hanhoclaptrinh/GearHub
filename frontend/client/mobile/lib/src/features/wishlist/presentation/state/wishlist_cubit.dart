import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/src/features/wishlist/domain/repositories/wishlist_repository.dart';
import 'package:mobile/src/shared/models/product_model.dart';
import 'wishlist_state.dart';

class WishlistCubit extends Cubit<WishlistState> {
  final WishlistRepository repository;

  WishlistCubit({required this.repository}) : super(WishlistInitial());

  Future<void> fetchWishlist({bool refresh = false}) async {
    if (state is WishlistLoading) return;

    final currentState = state;
    int page = 1;
    List<ProductModel> currentProducts = [];

    if (!refresh && currentState is WishlistLoaded) {
      if (currentState.hasReachedMax) return;
      page = currentState.page + 1;
      currentProducts = currentState.products;
    }

    if (refresh || currentState is WishlistInitial) {
      emit(WishlistLoading());
    }

    try {
      final result = await repository.getWishlist(page: page);
      final List<dynamic> data = result['data'] ?? [];
      final List<ProductModel> newProducts = data.map((item) {
        return ProductModel.fromJson(item['product']);
      }).toList();

      final meta = result['meta'];
      final total = meta['total'] ?? 0;
      final lastPage = meta['lastPage'] ?? 1;

      emit(WishlistLoaded(
        products: currentProducts + newProducts,
        total: total,
        page: page,
        hasReachedMax: page >= lastPage,
      ));
    } catch (e) {
      emit(WishlistError(e.toString()));
    }
  }

  Future<void> toggleWishlist(String productId) async {
    try {
      await repository.toggleWishlist(productId);
     
      fetchWishlist(refresh: true);
    } catch (e) {
      emit(WishlistError(e.toString()));
    }
  }
}
