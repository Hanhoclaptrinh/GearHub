import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/src/features/cart/data/models/cart_model.dart';
import 'package:mobile/src/features/cart/data/models/cart_item_model.dart';
import 'package:mobile/src/shared/models/product_model.dart';
import 'package:mobile/src/shared/models/product_variant_model.dart';

abstract class CartLocalDataSource {
  Future<CartModel> getCart();
  Future<CartModel> addToCart(
    ProductVariantModel variant,
    ProductModel product,
    int quantity,
  );
  Future<CartModel> updateQuantity(String itemId, int quantity);
  Future<CartModel> removeItem(String itemId);
  Future<void> clearCart();
  Future<CartModel> clearSelectedItems(List<String> variantIds);
}

class CartLocalDataSourceImpl implements CartLocalDataSource {
  static const String CACHE_CART_KEY = 'CACHE_GUEST_CART';
  final SharedPreferences sharedPreferences;

  CartLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<CartModel> getCart() async {
    final jsonString = sharedPreferences.getString(CACHE_CART_KEY);
    if (jsonString != null) {
      try {
        final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
        return CartModel.fromJson(jsonMap);
      } catch (e) {
        return _emptyCart();
      }
    }
    return _emptyCart();
  }

  Future<void> _saveCart(CartModel cart) async {
    final jsonString = jsonEncode(cart.toJson());
    await sharedPreferences.setString(CACHE_CART_KEY, jsonString);
  }

  CartModel _emptyCart() {
    return CartModel(
      id: 'local_cart',
      userId: 'guest',
      items: [],
      cartTotal: 0.0,
    );
  }

  @override
  Future<CartModel> addToCart(
    ProductVariantModel variant,
    ProductModel product,
    int quantity,
  ) async {
    var cart = await getCart();

    final index = cart.items.indexWhere(
      (i) => i.productVariant.id == variant.id,
    );
    List<CartItemModel> newItems = List.from(cart.items);

    if (index >= 0) {
      final existingItem = newItems[index];
      newItems[index] = CartItemModel(
        id: existingItem.id,
        cartId: cart.id,
        productVariant: existingItem.productVariant,
        product: existingItem.product,
        quantity: existingItem.quantity + quantity,
      );
    } else {
      newItems.add(
        CartItemModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          cartId: cart.id,
          productVariant: variant,
          product: product,
          quantity: quantity,
        ),
      );
    }

    double newTotal = newItems.fold(0, (sum, item) => sum + item.itemTotal);

    final updatedCart = CartModel(
      id: cart.id,
      userId: cart.userId,
      items: newItems,
      cartTotal: newTotal,
    );

    await _saveCart(updatedCart);
    return updatedCart;
  }

  @override
  Future<CartModel> updateQuantity(String itemId, int quantity) async {
    var cart = await getCart();
    final index = cart.items.indexWhere((i) => i.id == itemId);
    if (index >= 0) {
      List<CartItemModel> newItems = List.from(cart.items);
      final item = newItems[index];
      newItems[index] = CartItemModel(
        id: item.id,
        cartId: item.cartId,
        productVariant: item.productVariant,
        product: item.product,
        quantity: quantity,
      );
      double newTotal = newItems.fold(0, (sum, item) => sum + item.itemTotal);
      final updatedCart = CartModel(
        id: cart.id,
        userId: cart.userId,
        items: newItems,
        cartTotal: newTotal,
      );
      await _saveCart(updatedCart);
      return updatedCart;
    }
    return cart;
  }

  @override
  Future<CartModel> removeItem(String itemId) async {
    var cart = await getCart();
    List<CartItemModel> newItems = List.from(cart.items)
      ..removeWhere((i) => i.id == itemId);
    double newTotal = newItems.fold(0, (sum, item) => sum + item.itemTotal);
    final updatedCart = CartModel(
      id: cart.id,
      userId: cart.userId,
      items: newItems,
      cartTotal: newTotal,
    );
    await _saveCart(updatedCart);
    return updatedCart;
  }

  @override
  Future<void> clearCart() async {
    await sharedPreferences.remove(CACHE_CART_KEY);
  }

  @override
  Future<CartModel> clearSelectedItems(List<String> variantIds) async {
    var cart = await getCart();
    List<CartItemModel> newItems = List.from(cart.items)
      ..removeWhere((i) => variantIds.contains(i.productVariant.id));
    double newTotal = newItems.fold(0, (sum, item) => sum + item.itemTotal);
    final updatedCart = CartModel(
      id: cart.id,
      userId: cart.userId,
      items: newItems,
      cartTotal: newTotal,
    );
    await _saveCart(updatedCart);
    return updatedCart;
  }
}
