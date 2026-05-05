abstract class WishlistRepository {
  Future<void> toggleWishlist(String productId);
  Future<bool> checkIsFavorite(String productId);
}
