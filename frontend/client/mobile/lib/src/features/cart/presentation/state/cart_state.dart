import 'package:equatable/equatable.dart';
import 'package:mobile/src/features/cart/domain/entities/cart_entity.dart';
import 'package:mobile/src/shared/models/product_model.dart';

abstract class CartState extends Equatable {
  const CartState();

  CartEntity? get cart => null;
  List<ProductModel> get recommendations => const [];
  bool get isRecommendationsLoading => false;

  @override
  List<Object?> get props => [];
}

class CartInitial extends CartState {}

class CartLoading extends CartState {}

class CartLoaded extends CartState {
  @override
  final CartEntity cart;
  @override
  final List<ProductModel> recommendations;
  @override
  final bool isRecommendationsLoading;

  const CartLoaded({
    required this.cart,
    this.recommendations = const [],
    this.isRecommendationsLoading = false,
  });

  @override
  List<Object?> get props => [
    cart,
    recommendations,
    isRecommendationsLoading,
  ];
}

class CartError extends CartState {
  final String message;
  const CartError({required this.message});

  @override
  List<Object?> get props => [message];
}

class CartAddSuccess extends CartState {
  @override
  final CartEntity cart;
  @override
  final List<ProductModel> recommendations;
  @override
  final bool isRecommendationsLoading;

  const CartAddSuccess({
    required this.cart,
    this.recommendations = const [],
    this.isRecommendationsLoading = false,
  });

  @override
  List<Object?> get props => [
    cart,
    recommendations,
    isRecommendationsLoading,
  ];
}
