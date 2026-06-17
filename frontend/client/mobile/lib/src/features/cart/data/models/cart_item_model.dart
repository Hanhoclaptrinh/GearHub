import 'package:mobile/src/features/cart/domain/entities/cart_item_entity.dart';
import 'package:mobile/src/shared/models/product_model.dart';
import 'package:mobile/src/shared/models/product_variant_model.dart';

class CartItemModel extends CartItemEntity {
  CartItemModel({
    required super.id,
    required super.cartId,
    required super.productVariant,
    required super.product,
    required super.quantity,
    super.isAvailable = true,
    super.isSelected = true,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    final variantMap = Map<String, dynamic>.from(json['productVariant'] ?? {});
    if (json['flashSale'] != null) {
      variantMap['flashSaleProducts'] = [json['flashSale']];
    }

    return CartItemModel(
      id: json['id'] ?? '',
      cartId: json['cartId'] ?? '',
      productVariant: ProductVariantModel.fromJson(variantMap),
      product: json['product'] != null
          ? ProductModel.fromJson(json['product'])
          : (json['productVariant']?['product'] != null
                ? ProductModel.fromJson(json['productVariant']['product'])
                : const ProductModel(
                    id: '',
                    name: '',
                    tagline: '',
                    price: 0,
                    image: '',
                    description: '',
                  )),
      quantity: json['quantity'] ?? 1,
      isAvailable: json['isAvailable'] ?? true,
      isSelected: json['isSelected'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cartId': cartId,
      'productVariant': productVariant.toJson(),
      'product': product.toJson(),
      'quantity': quantity,
      'isAvailable': isAvailable,
      'isSelected': isSelected,
    };
  }
}
