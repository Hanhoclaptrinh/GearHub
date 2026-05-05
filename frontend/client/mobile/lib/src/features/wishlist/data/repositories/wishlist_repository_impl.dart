import '../datasources/wishlist_remote_datasource.dart';
import '../../domain/repositories/wishlist_repository.dart';

class WishlistRepositoryImpl implements WishlistRepository {
  final WishlistRemoteDatasource remoteDatasource;

  WishlistRepositoryImpl({required this.remoteDatasource});

  @override
  Future<void> toggleWishlist(String productId) async {
    return remoteDatasource.toggleWishlist(productId);
  }

  @override
  Future<bool> checkIsFavorite(String productId) async {
    return remoteDatasource.checkIsFavorite(productId);
  }
}
