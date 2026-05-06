abstract class WishlistRepository {
  Future<void> toggleWishlist(String productId);
  Future<bool> checkIsFavorite(String productId);
  Future<Map<String, dynamic>> getWishlist({int page = 1, int limit = 20});
}
