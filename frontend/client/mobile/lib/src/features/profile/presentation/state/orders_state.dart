abstract class OrdersState {}

class OrdersInitial extends OrdersState {}

class OrdersLoading extends OrdersState {}

class OrdersLoaded extends OrdersState {
  final List<dynamic> orders;
  OrdersLoaded({required this.orders});
}

class OrdersError extends OrdersState {
  final String message;
  OrdersError({required this.message});
}

class OrderActionSuccess extends OrdersState {
  final String message;
  OrderActionSuccess({required this.message});
}

class ReorderSuccess extends OrdersState {
  final String message;
  final List<String> variantIds;
  ReorderSuccess({required this.message, required this.variantIds});
}
