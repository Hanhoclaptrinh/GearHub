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

  @override
  Future<Map<String, dynamic>> getWishlist({int page = 1, int limit = 20}) async {
    return remoteDatasource.getWishlist(page: page, limit: limit);
  }
}
