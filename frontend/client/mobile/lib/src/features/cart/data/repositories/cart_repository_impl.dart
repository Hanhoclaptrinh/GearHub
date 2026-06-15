import 'package:dartz/dartz.dart';
import 'package:mobile/src/core/error/failures.dart';
import 'package:mobile/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:mobile/src/features/cart/data/datasources/cart_local_datasource.dart';
import 'package:mobile/src/features/cart/data/datasources/cart_remote_datasource.dart';
import 'package:mobile/src/features/cart/domain/entities/cart_entity.dart';
import 'package:mobile/src/features/cart/domain/repositories/cart_repository.dart';
import 'package:mobile/src/shared/models/product_model.dart';
import 'package:mobile/src/shared/models/product_variant_model.dart';

class CartRepositoryImpl implements CartRepository {
  final CartRemoteDataSource remoteDataSource;
  final CartLocalDataSource localDataSource;
  final AuthRepository authRepository;

  CartRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.authRepository,
  });

  @override
  Future<Either<Failure, CartEntity>> getCart() async {
    try {
      final isLoggedIn = await authRepository.isLoggedIn();
      if (isLoggedIn) {
        try {
          final cart = await remoteDataSource.getCart();
          return right(cart);
        } catch (e) {
          if (e.toString().contains('401')) {
            await authRepository.logout();
            final localCart = await localDataSource.getCart();
            return right(localCart);
          }
          rethrow;
        }
      } else {
        final cart = await localDataSource.getCart();
        return right(cart);
      }
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> getCartCount() async {
    try {
      final isLoggedIn = await authRepository.isLoggedIn();
      if (isLoggedIn) {
        try {
          final count = await remoteDataSource.getCartCount();
          return right(count);
        } catch (e) {
          if (e.toString().contains('401')) {
            await authRepository.logout();
            final cart = await localDataSource.getCart();
            return right(cart.items.length);
          }
          rethrow;
        }
      } else {
        final cart = await localDataSource.getCart();
        return right(cart.items.length);
      }
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CartEntity>> addToCart(
    ProductVariantModel variant,
    ProductModel product,
    int quantity,
  ) async {
    try {
      final isLoggedIn = await authRepository.isLoggedIn();
      if (isLoggedIn) {
        try {
          final cart = await remoteDataSource.addToCart(variant.id, quantity);
          return right(cart);
        } catch (e) {
          if (e.toString().contains('401')) {
            await authRepository.logout();
            final cart = await localDataSource.addToCart(
              variant,
              product,
              quantity,
            );
            return right(cart);
          }
          rethrow;
        }
      } else {
        final cart = await localDataSource.addToCart(
          variant,
          product,
          quantity,
        );
        return right(cart);
      }
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CartEntity>> updateQuantity(
    String itemId,
    int quantity,
  ) async {
    try {
      final isLoggedIn = await authRepository.isLoggedIn();
      if (isLoggedIn) {
        try {
          final cart = await remoteDataSource.updateQuantity(itemId, quantity);
          return right(cart);
        } catch (e) {
          if (e.toString().contains('401')) {
            await authRepository.logout();
            final cart = await localDataSource.updateQuantity(itemId, quantity);
            return right(cart);
          }
          rethrow;
        }
      } else {
        final cart = await localDataSource.updateQuantity(itemId, quantity);
        return right(cart);
      }
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CartEntity>> removeItem(String itemId) async {
    try {
      final isLoggedIn = await authRepository.isLoggedIn();
      if (isLoggedIn) {
        final cart = await remoteDataSource.removeItem(itemId);
        return right(cart);
      } else {
        final cart = await localDataSource.removeItem(itemId);
        return right(cart);
      }
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CartEntity>> clearSelectedItems(
    List<String> variantIds,
  ) async {
    try {
      final isLoggedIn = await authRepository.isLoggedIn();
      if (isLoggedIn) {
        final cart = await remoteDataSource.clearSelectedItems(variantIds);
        return right(cart);
      } else {
        final cart = await localDataSource.clearSelectedItems(variantIds);
        return right(cart);
      }
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> clearCart() async {
    try {
      final isLoggedIn = await authRepository.isLoggedIn();
      if (isLoggedIn) {
        await remoteDataSource.clearCart();
        return right(null);
      } else {
        await localDataSource.clearCart();
        return right(null);
      }
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CartEntity>> syncCart() async {
    try {
      final isLoggedIn = await authRepository.isLoggedIn();
      if (!isLoggedIn) {
        //nếu chưa đăng nhập thì ko làm gì cả, trả về local cart
        final cart = await localDataSource.getCart();
        return right(cart);
      }

      final localCart = await localDataSource.getCart();
      if (localCart.items.isEmpty) {
        //không có gì ở local để sync, lấy luôn từ remote
        final cart = await remoteDataSource.getCart();
        return right(cart);
      }

      //convert local items to sync payload
      final syncPayload = localCart.items
          .map(
            (item) => {
              'variantId': item.productVariant.id,
              'quantity': item.quantity,
            },
          )
          .toList();

      //gọi remote sync
      final mergedCart = await remoteDataSource.syncCart(syncPayload);

      //xóa local sau khi sync xong
      await localDataSource.clearCart();

      return right(mergedCart);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ProductModel>>> getRecommendations({
    int limit = 8,
  }) async {
    try {
      final isLoggedIn = await authRepository.isLoggedIn();
      if (!isLoggedIn) {
        return right(const []);
      }

      try {
        final products = await remoteDataSource.getRecommendations(
          limit: limit,
        );
        return right(products);
      } catch (e) {
        if (e.toString().contains('401')) {
          await authRepository.logout();
          return right(const []);
        }
        rethrow;
      }
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }
}
