import 'cart_item_entity.dart';

class CartEntity {
  final String id;
  final String userId;
  final List<CartItemEntity> items;
  final double cartTotal;

  CartEntity({
    required this.id,
    required this.userId,
    required this.items,
    required this.cartTotal,
  });

  CartEntity copyWith({
    String? id,
    String? userId,
    List<CartItemEntity>? items,
    double? cartTotal,
  }) {
    return CartEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      cartTotal: cartTotal ?? this.cartTotal,
    );
  }
}
