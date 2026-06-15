import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/src/features/product_compare/domain/repositories/product_compare_repository.dart';
import 'package:mobile/src/shared/models/product_model.dart';

import 'product_compare_state.dart';

class ProductCompareCubit extends Cubit<ProductCompareState> {
  final ProductCompareRepository _repository;

  ProductCompareCubit({required ProductCompareRepository repository})
    : _repository = repository,
      super(const ProductCompareState());

  Future<void> startWithProduct(
    ProductModel product, [
    String? variantId,
  ]) async {
    final defaultVariantId =
        variantId ??
        (product.variants.isNotEmpty ? product.variants.first.id : '');
    final selectedProduct = _productWithSelectedVariant(
      product,
      defaultVariantId,
    );

    final existingIndex = state.selectedProducts.indexWhere(
      (p) => p.id == product.id,
    );
    if (existingIndex != -1) {
      final rollbackProducts = state.selectedProducts;
      final rollbackVariantIds = state.selectedVariantIds;
      final nextProducts = [...state.selectedProducts]
        ..[existingIndex] = selectedProduct;
      final nextVariantIds = Map<String, String>.from(state.selectedVariantIds)
        ..[product.id] = defaultVariantId;

      if (nextProducts.length < 2) {
        emit(
          state.copyWith(
            selectedProducts: nextProducts,
            selectedVariantIds: nextVariantIds,
            clearCompareResult: true,
            clearError: true,
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          selectedProducts: nextProducts,
          selectedVariantIds: nextVariantIds,
          clearError: true,
        ),
      );
      await _validateSelection(
        nextProducts,
        rollbackProducts: rollbackProducts,
        rollbackVariantIds: rollbackVariantIds,
        variantIds: nextProducts.map((p) => nextVariantIds[p.id]!).toList(),
        nextVariantIds: nextVariantIds,
      );
      return;
    }

    if (state.selectedProducts.isNotEmpty &&
        state.selectedProducts.length < 3) {
      final nextProducts = [...state.selectedProducts, selectedProduct];
      final nextVariantIds = Map<String, String>.from(state.selectedVariantIds)
        ..[product.id] = defaultVariantId;

      emit(state.copyWith(isLoading: true, clearError: true));
      try {
        final result = await _repository.compareProducts(
          nextProducts.map((p) => p.id).toList(),
          variantIds: nextProducts.map((p) => nextVariantIds[p.id]!).toList(),
        );
        emit(
          state.copyWith(
            selectedProducts: result.products,
            selectedVariantIds: nextVariantIds,
            compareResult: result,
            isLoading: false,
            clearError: true,
          ),
        );
        return;
      } catch (_) {}
    }

    emit(
      ProductCompareState(
        selectedProducts: [selectedProduct],
        selectedVariantIds: {product.id: defaultVariantId},
      ),
    );
  }

  Future<bool> addProduct(ProductModel product) async {
    final current = state.selectedProducts;

    if (current.any((item) => item.id == product.id)) {
      emit(state.copyWith(errorMessage: 'Sản phẩm đã có trong danh sách.'));
      return false;
    }

    if (current.length >= 3) {
      emit(state.copyWith(errorMessage: 'Chỉ được so sánh tối đa 3 sản phẩm.'));
      return false;
    }

    final defaultVariantId = product.variants.isNotEmpty
        ? product.variants.first.id
        : '';
    final selectedProduct = _productWithSelectedVariant(
      product,
      defaultVariantId,
    );
    final nextProducts = [...current, selectedProduct];
    final nextVariantIds = Map<String, String>.from(state.selectedVariantIds)
      ..[product.id] = defaultVariantId;

    if (nextProducts.length < 2) {
      emit(
        state.copyWith(
          selectedProducts: nextProducts,
          selectedVariantIds: nextVariantIds,
          clearError: true,
        ),
      );
      return true;
    }

    return _validateSelection(
      nextProducts,
      rollbackProducts: current,
      variantIds: nextProducts.map((p) => nextVariantIds[p.id]!).toList(),
      nextVariantIds: nextVariantIds,
    );
  }

  Future<void> removeProduct(String productId) async {
    final nextProducts = state.selectedProducts
        .where((product) => product.id != productId)
        .toList();
    final nextVariantIds = Map<String, String>.from(state.selectedVariantIds)
      ..remove(productId);

    if (nextProducts.length < 2) {
      emit(
        state.copyWith(
          selectedProducts: nextProducts,
          selectedVariantIds: nextVariantIds,
          isLoading: false,
          clearCompareResult: true,
          clearError: true,
        ),
      );
      return;
    }

    await _validateSelection(
      nextProducts,
      rollbackProducts: state.selectedProducts,
      variantIds: nextProducts.map((p) => nextVariantIds[p.id]!).toList(),
      nextVariantIds: nextVariantIds,
    );
  }

  Future<bool> _validateSelection(
    List<ProductModel> products, {
    required List<ProductModel> rollbackProducts,
    Map<String, String>? rollbackVariantIds,
    List<String>? variantIds,
    Map<String, String>? nextVariantIds,
  }) async {
    final previousVariantIds = rollbackVariantIds ?? state.selectedVariantIds;
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final ids = products.map((product) => product.id).toList();
      final vIds =
          variantIds ??
          products
              .map((p) => state.selectedVariantIds[p.id] ?? '')
              .where((id) => id.isNotEmpty)
              .toList();

      final result = await _repository.compareProducts(ids, variantIds: vIds);

      emit(
        state.copyWith(
          selectedProducts: result.products,
          selectedVariantIds: nextVariantIds ?? state.selectedVariantIds,
          compareResult: result,
          isLoading: false,
          clearError: true,
        ),
      );
      return true;
    } catch (error) {
      emit(
        state.copyWith(
          selectedProducts: rollbackProducts,
          selectedVariantIds: previousVariantIds,
          isLoading: false,
          errorMessage: _readErrorMessage(error),
        ),
      );
      return false;
    }
  }

  String _readErrorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is String && message.isNotEmpty) return message;
        if (message is List) return message.join('\n');
      }
    }

    return 'Không thể so sánh các sản phẩm đã chọn.';
  }

  ProductModel _productWithSelectedVariant(
    ProductModel product,
    String variantId,
  ) {
    if (variantId.isEmpty || product.variants.isEmpty) return product;

    final selectedVariant = product.variants
        .where((variant) => variant.id == variantId)
        .firstOrNull;
    if (selectedVariant == null) return product;

    final selectedImage = selectedVariant.imageUrl;
    return product.copyWith(
      price: selectedVariant.price,
      image: selectedImage != null && selectedImage.isNotEmpty
          ? selectedImage
          : product.baseImage,
      variants: [selectedVariant],
    );
  }
}
