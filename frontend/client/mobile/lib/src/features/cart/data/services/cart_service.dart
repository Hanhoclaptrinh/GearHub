import 'package:flutter/material.dart';
import 'package:mobile/src/features/cart/domain/models/cart_item.dart';
import 'package:mobile/src/shared/models/product_model.dart';

class CartService extends ChangeNotifier {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get uniqueItemsCount => _items.length;

  // them sp vao cart
  void addItem(ProductModel product) {
    // kiem tra sp da co trong cart chua
    final index = _items.indexWhere((item) => item.product.id == product.id);
    // neu co roi thi tang so luong
    if (index != -1) {
      _items[index].quantity++;
    } else {
      // neu chua co thi them vao cart
      _items.add(CartItem(product: product));
    }
    notifyListeners();
  }

  // xoa sp khoi cart
  void removeItem(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  // cap nhat so luong sp
  void updateQuantity(String productId, int quantity) {
    // kiem tra sp da co trong cart chua
    final index = _items.indexWhere((item) => item.product.id == productId);
    // neu co roi thi cap nhat so luong
    if (index != -1) {
      _items[index].quantity = quantity;
      notifyListeners();
    }
  }

  void toggleSelection(String productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index != -1) {
      _items[index].isSelected = !_items[index].isSelected;
      notifyListeners();
    }
  }

  void selectAll() {
    final bool allSelected = _items.every((item) => item.isSelected);
    for (var item in _items) {
      item.isSelected = !allSelected;
    }
    notifyListeners();
  }

  // tinh tong gia tri sp duoc chon
  double get subtotal => _items
      .where((item) => item.isSelected)
      .fold(0, (sum, item) => sum + item.totalPrice);
}
