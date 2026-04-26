import 'package:mobile/src/shared/models/product_model.dart';

class CartItem {
  final ProductModel product;
  int quantity;
  bool isSelected;

  CartItem({required this.product, this.quantity = 1, this.isSelected = true});

  double get totalPrice => product.price * quantity;
}
