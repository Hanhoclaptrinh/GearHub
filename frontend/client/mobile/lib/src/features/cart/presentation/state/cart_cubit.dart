import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/src/features/cart/domain/entities/cart_entity.dart';
import 'package:mobile/src/features/cart/domain/repositories/cart_repository.dart';
import 'package:mobile/src/shared/models/product_model.dart';
import 'package:mobile/src/shared/models/product_variant_model.dart';
import 'cart_state.dart';

class CartCubit extends Cubit<CartState> {
  final CartRepository repository;

  CartCubit({required this.repository}) : super(CartInitial());

  Future<void> loadCart() async {
    emit(CartLoading());
    final result = await repository.getCart();
    result.fold(
      (failure) => emit(CartError(message: failure.message)),
      (cart) => emit(CartLoaded(cart: cart)),
    );
  }

  Future<void> addToCart(
    ProductVariantModel variant,
    ProductModel product,
    int quantity,
  ) async {
    final result = await repository.addToCart(variant, product, quantity);
    result.fold((failure) => emit(CartError(message: failure.message)), (cart) {
      emit(CartLoaded(cart: cart));
      emit(CartAddSuccess(cart: cart));
    });
  }

  Future<void> updateQuantity(String itemId, int quantity) async {
    if (quantity <= 0) {
      await removeItem(itemId);
      return;
    }

    final result = await repository.updateQuantity(itemId, quantity);
    result.fold(
      (failure) => emit(CartError(message: failure.message)),
      (cart) => emit(CartLoaded(cart: cart)),
    );
  }

  Future<void> removeItem(String itemId) async {
    final result = await repository.removeItem(itemId);
    result.fold(
      (failure) => emit(CartError(message: failure.message)),
      (cart) => emit(CartLoaded(cart: cart)),
    );
  }

  Future<void> toggleItemSelection(String itemId) async {
    CartEntity? currentCart;
    if (state is CartLoaded) {
      currentCart = (state as CartLoaded).cart;
    } else if (state is CartAddSuccess) {
      currentCart = (state as CartAddSuccess).cart;
    }

    if (currentCart != null) {
      final updatedItems = currentCart.items.map((item) {
        if (item.id == itemId) {
          return item.copyWith(isSelected: !item.isSelected);
        }
        return item;
      }).toList();

      emit(CartLoaded(cart: currentCart.copyWith(items: updatedItems)));
    }
  }

  Future<void> toggleSelectAll(bool selectAll) async {
    CartEntity? currentCart;
    if (state is CartLoaded) {
      currentCart = (state as CartLoaded).cart;
    } else if (state is CartAddSuccess) {
      currentCart = (state as CartAddSuccess).cart;
    }

    if (currentCart != null) {
      final updatedItems = currentCart.items.map((item) {
        return item.copyWith(isSelected: selectAll);
      }).toList();

      emit(CartLoaded(cart: currentCart.copyWith(items: updatedItems)));
    }
  }

  Future<void> clearSelectedItems(List<String> variantIds) async {
    final result = await repository.clearSelectedItems(variantIds);
    result.fold(
      (failure) => emit(CartError(message: failure.message)),
      (cart) => emit(CartLoaded(cart: cart)),
    );
  }

  Future<void> syncCart() async {
    final result = await repository.syncCart();
    result.fold(
      (failure) => emit(CartError(message: failure.message)),
      (cart) => emit(CartLoaded(cart: cart)),
    );
  }

  Future<void> clearCart() async {
    emit(CartLoading());
    final result = await repository.clearCart();
    await result.fold(
      (failure) async => emit(CartError(message: failure.message)),
      (_) async => loadCart(),
    );
  }

  Future<void> changeVariant(
    String oldItemId,
    String oldVariantId,
    ProductVariantModel newVariant,
    ProductModel product,
    int currentQuantity,
  ) async {
    if (oldVariantId == newVariant.id) return;

    emit(CartLoading());

    final addResult = await repository.addToCart(
      newVariant,
      product,
      currentQuantity,
    );

    await addResult.fold(
      (failure) async => emit(CartError(message: failure.message)),
      (cartAfterAdd) async {
        final removeResult = await repository.removeItem(oldItemId);
        removeResult.fold(
          (failure) => emit(CartError(message: failure.message)),
          (finalCart) => emit(CartLoaded(cart: finalCart)),
        );
      },
    );
  }
}
