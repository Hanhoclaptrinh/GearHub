import 'package:equatable/equatable.dart';
import 'package:mobile/src/features/product_compare/data/models/product_compare_models.dart';
import 'package:mobile/src/shared/models/product_model.dart';

class ProductCompareState extends Equatable {
  final List<ProductModel> selectedProducts;
  final Map<String, String> selectedVariantIds;
  final ProductCompareResultModel? compareResult;
  final bool isLoading;
  final String? errorMessage;

  const ProductCompareState({
    this.selectedProducts = const [],
    this.selectedVariantIds = const {},
    this.compareResult,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get canShowComparison => selectedProducts.length >= 2;
  bool get canAddMore => selectedProducts.length < 3;

  ProductCompareState copyWith({
    List<ProductModel>? selectedProducts,
    Map<String, String>? selectedVariantIds,
    ProductCompareResultModel? compareResult,
    bool? isLoading,
    String? errorMessage,
    bool clearCompareResult = false,
    bool clearError = false,
  }) {
    return ProductCompareState(
      selectedProducts: selectedProducts ?? this.selectedProducts,
      selectedVariantIds: selectedVariantIds ?? this.selectedVariantIds,
      compareResult: clearCompareResult
          ? null
          : compareResult ?? this.compareResult,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    selectedProducts,
    selectedVariantIds,
    compareResult,
    isLoading,
    errorMessage,
  ];
}
