import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/review_entity.dart';

abstract class ReviewRepository {
  Future<Either<Failure, (List<ReviewEntity>, int)>> getProductReviews(String productId, {int page = 1, int limit = 10, int? rating, bool? hasImage});
  
  Future<Either<Failure, ReviewEntity>> createReview({
    required String orderItemId,
    required int rating,
    String? comment,
    List<String>? imagePaths,
  });

  Future<Either<Failure, ReviewEntity>> updateReview({
    required String reviewId,
    int? rating,
    String? comment,
  });

  Future<Either<Failure, void>> deleteReview(String reviewId);
  Future<Either<Failure, Map<String, int>>> getReviewSummary(String productId);
  Future<Either<Failure, List<Map<String, dynamic>>>> getPendingReviews();
  Future<Either<Failure, List<ReviewEntity>>> getUserReviews();
  Future<Either<Failure, void>> skipReview(String orderItemId);
}
