import 'package:equatable/equatable.dart';
import 'package:mobile/src/features/cart/domain/entities/cart_entity.dart';

abstract class CartState extends Equatable {
  const CartState();

  CartEntity? get cart => null;

  @override
  List<Object?> get props => [];
}

class CartInitial extends CartState {}

class CartLoading extends CartState {}

class CartLoaded extends CartState {
  @override
  final CartEntity cart;
  const CartLoaded({required this.cart});

  @override
  List<Object?> get props => [cart];
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
  const CartAddSuccess({required this.cart});

  @override
  List<Object?> get props => [cart];
}
