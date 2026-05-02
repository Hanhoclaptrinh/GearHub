import 'package:mobile/src/features/cart/domain/entities/cart_entity.dart';
import 'package:mobile/src/features/cart/data/models/cart_item_model.dart';

class CartModel extends CartEntity {
  CartModel({
    required super.id,
    required super.userId,
    required super.items,
    required super.cartTotal,
  });

  factory CartModel.fromJson(Map<String, dynamic> json) {
    return CartModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      items: (json['items'] as List?)
              ?.map((item) => CartItemModel.fromJson(item))
              .toList() ??
          [],
      cartTotal: double.tryParse(json['cartTotal']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'items': items.map((e) {
        return {
          'id': e.id,
          'cartId': e.cartId,
          'productVariant': e.productVariant.toJson(),
          'product': e.product.toJson(),
          'quantity': e.quantity,
          'isAvailable': e.isAvailable,
          'isSelected': e.isSelected,
        };
      }).toList(),
      'cartTotal': cartTotal,
    };
  }
}
