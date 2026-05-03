import 'package:equatable/equatable.dart';

abstract class CheckoutState extends Equatable {
  const CheckoutState();

  @override
  List<Object?> get props => [];
}

class CheckoutInitial extends CheckoutState {}

class CheckoutLoading extends CheckoutState {}

class OrderPlacedSuccess extends CheckoutState {
  final String orderId;
  final String? paymentUrl;
  final String paymentMethod;

  const OrderPlacedSuccess({
    required this.orderId,
    this.paymentUrl,
    required this.paymentMethod,
  });

  @override
  List<Object?> get props => [orderId, paymentUrl, paymentMethod];
}

class CheckoutError extends CheckoutState {
  final String message;

  const CheckoutError({required this.message});

  @override
  List<Object?> get props => [message];
}
