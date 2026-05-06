import 'package:mobile/src/shared/models/product_model.dart';

abstract class WishlistState {
  const WishlistState();
}

class WishlistInitial extends WishlistState {}

class WishlistLoading extends WishlistState {}

class WishlistLoaded extends WishlistState {
  final List<ProductModel> products;
  final int total;
  final int page;
  final bool hasReachedMax;

  const WishlistLoaded({
    required this.products,
    required this.total,
    required this.page,
    required this.hasReachedMax,
  });

  WishlistLoaded copyWith({
    List<ProductModel>? products,
    int? total,
    int? page,
    bool? hasReachedMax,
  }) {
    return WishlistLoaded(
      products: products ?? this.products,
      total: total ?? this.total,
      page: page ?? this.page,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }
}

class WishlistError extends WishlistState {
  final String message;
  const WishlistError(this.message);
}
