import 'package:mobile/src/shared/models/product_model.dart';
import 'package:mobile/src/shared/models/product_variant_model.dart';

class CartItemEntity {
  final String id;
  final String cartId;
  final ProductVariantModel productVariant;
  final ProductModel product;
  final int quantity;
  final bool isAvailable;
  bool isSelected;

  CartItemEntity({
    required this.id,
    required this.cartId,
    required this.productVariant,
    required this.product,
    required this.quantity,
    this.isAvailable = true,
    this.isSelected = true,
  });

  double get itemTotal => quantity * (productVariant.hasActiveFlashSale ? productVariant.flashPrice! : productVariant.price);

  CartItemEntity copyWith({
    String? id,
    String? cartId,
    ProductVariantModel? productVariant,
    ProductModel? product,
    int? quantity,
    bool? isAvailable,
    bool? isSelected,
  }) {
    return CartItemEntity(
      id: id ?? this.id,
      cartId: cartId ?? this.cartId,
      productVariant: productVariant ?? this.productVariant,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      isAvailable: isAvailable ?? this.isAvailable,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}
