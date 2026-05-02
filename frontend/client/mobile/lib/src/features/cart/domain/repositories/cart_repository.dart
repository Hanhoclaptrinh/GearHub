import 'package:dartz/dartz.dart';
import 'package:mobile/src/core/error/failures.dart';
import 'package:mobile/src/features/cart/domain/entities/cart_entity.dart';
import 'package:mobile/src/shared/models/product_variant_model.dart';
import 'package:mobile/src/shared/models/product_model.dart';

abstract class CartRepository {
  // lay gio hang local hoac remote tuy theo trang thai login
  Future<Either<Failure, CartEntity>> getCart();

  // dem so luong san pham
  Future<Either<Failure, int>> getCartCount();

  // them san pham vao gio hang
  Future<Either<Failure, CartEntity>> addToCart(
      ProductVariantModel variant, ProductModel product, int quantity);

  // cap nhat so luong cua mot cart item
  Future<Either<Failure, CartEntity>> updateQuantity(String itemId, int quantity);

  // xoa 1 san pham khoi gio hang
  Future<Either<Failure, CartEntity>> removeItem(String itemId);

  // xoa danh sach cac san pham da chon (thanh toan xong hoac chu dong xoa)
  Future<Either<Failure, CartEntity>> clearSelectedItems(List<String> variantIds);

  // xoa toan bo gio hang
  Future<Either<Failure, void>> clearCart();

  // dong bo local cart len server (sau khi auth)
  Future<Either<Failure, CartEntity>> syncCart();
}
