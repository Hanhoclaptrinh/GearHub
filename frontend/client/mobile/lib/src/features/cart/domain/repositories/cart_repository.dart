import 'package:dartz/dartz.dart';
import 'package:mobile/src/core/error/failures.dart';
import 'package:mobile/src/features/cart/domain/entities/cart_entity.dart';
import 'package:mobile/src/shared/models/product_variant_model.dart';
import 'package:mobile/src/shared/models/product_model.dart';

abstract class CartRepository {
  ///lấy giỏ local hoặc remote tùy trạng thái auth
  Future<Either<Failure, CartEntity>> getCart();

  ///đếm số lượng sp
  Future<Either<Failure, int>> getCartCount();

  ///thêm sp vào cart
  Future<Either<Failure, CartEntity>> addToCart(
    ProductVariantModel variant,
    ProductModel product,
    int quantity,
  );

  //cập nhật số lượng của một cart item
  Future<Either<Failure, CartEntity>> updateQuantity(
    String itemId,
    int quantity,
  );

  ///xóa một sp khỏi giỏ hàng
  Future<Either<Failure, CartEntity>> removeItem(String itemId);

  ///xóa các sp được chọn khỏi giỏ - chủ động xóa hoặc auto xóa khi thanh toán xong
  Future<Either<Failure, CartEntity>> clearSelectedItems(
    List<String> variantIds,
  );

  ///clear all
  Future<Either<Failure, void>> clearCart();

  ///sync local cart to server
  Future<Either<Failure, CartEntity>> syncCart();

  ///gợi ý sp cho giỏ hàng
  Future<Either<Failure, List<ProductModel>>> getRecommendations({
    int limit = 8,
  });
}
