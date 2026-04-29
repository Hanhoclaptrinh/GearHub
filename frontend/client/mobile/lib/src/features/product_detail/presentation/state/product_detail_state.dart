import 'package:equatable/equatable.dart';
import '../../../../shared/models/product_model.dart';

abstract class ProductDetailState extends Equatable {
  const ProductDetailState();

  @override
  List<Object?> get props => [];
}

class ProductDetailInitial extends ProductDetailState {}

class ProductDetailLoading extends ProductDetailState {}

class ProductDetailLoaded extends ProductDetailState {
  final ProductModel product;
  final List<ProductModel> relatedProducts;

  const ProductDetailLoaded({
    required this.product,
    required this.relatedProducts,
  });

  @override
  List<Object?> get props => [product, relatedProducts];
}

class ProductDetailError extends ProductDetailState {
  final String message;

  const ProductDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
