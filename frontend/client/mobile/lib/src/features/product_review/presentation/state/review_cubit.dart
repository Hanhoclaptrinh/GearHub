import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/review_repository.dart';
import 'review_state.dart';

class ReviewCubit extends Cubit<ReviewState> {
  final ReviewRepository repository;

  ReviewCubit({required this.repository}) : super(ReviewInitial());

  Future<void> loadReviews(
    String productId, {
    int? rating,
    bool? hasImage,
  }) async {
    emit(ReviewLoading());

    final summaryResult = await repository.getReviewSummary(productId);
    final reviewsResult = await repository.getProductReviews(
      productId,
      rating: rating,
      hasImage: hasImage,
    );

    summaryResult.fold((failure) => emit(ReviewError(failure.message)), (
      summary,
    ) {
      reviewsResult.fold(
        (failure) => emit(ReviewError(failure.message)),
        (result) => emit(
          ReviewLoaded(
            reviews: result.$1,
            summary: summary,
            filteredTotal: result.$2,
          ),
        ),
      );
    });
  }

  Future<void> createReview({
    required String orderItemId,
    required String productId,
    required int rating,
    String? comment,
    List<String>? imagePaths,
    bool? isAnonymous,
  }) async {
    emit(ReviewLoading());
    final result = await repository.createReview(
      orderItemId: orderItemId,
      rating: rating,
      comment: comment,
      imagePaths: imagePaths,
      isAnonymous: isAnonymous,
    );

    result.fold((failure) => emit(ReviewError(failure.message)), (review) {
      emit(const ReviewActionSuccess('Đã gửi đánh giá thành công!'));
      loadReviews(productId);
    });
  }

  Future<void> updateReview({
    required String productId,
    required String reviewId,
    int? rating,
    String? comment,
  }) async {
    emit(ReviewLoading());
    final result = await repository.updateReview(
      reviewId: reviewId,
      rating: rating,
      comment: comment,
    );

    result.fold((failure) => emit(ReviewError(failure.message)), (review) {
      emit(const ReviewActionSuccess('Đã cập nhật đánh giá!'));
      loadReviews(productId);
    });
  }

  Future<void> deleteReview(String productId, String reviewId) async {
    emit(ReviewLoading());
    final result = await repository.deleteReview(reviewId);

    result.fold((failure) => emit(ReviewError(failure.message)), (_) {
      emit(const ReviewActionSuccess('Đã xóa đánh giá!'));
      loadReviews(productId);
    });
  }

  Future<void> loadPendingReviews() async {
    emit(ReviewLoading());
    final result = await repository.getPendingReviews();
    result.fold(
      (failure) => emit(ReviewError(failure.message)),
      (pending) => emit(PendingReviewsLoaded(pending)),
    );
  }

  Future<void> loadUserReviews() async {
    emit(ReviewLoading());
    final result = await repository.getUserReviews();
    result.fold(
      (failure) => emit(ReviewError(failure.message)),
      (reviews) => emit(UserReviewsLoaded(reviews)),
    );
  }

  Future<void> skipReview(String orderItemId) async {
    final result = await repository.skipReview(orderItemId);
    result.fold(
      (failure) => emit(ReviewError(failure.message)),
      (_) => loadMyReviewsData(),
    );
  }

  Future<void> loadMyReviewsData() async {
    emit(ReviewLoading());
    final pendingResult = await repository.getPendingReviews();
    final completedResult = await repository.getUserReviews();

    pendingResult.fold((failure) => emit(ReviewError(failure.message)), (
      pending,
    ) {
      completedResult.fold(
        (failure) => emit(ReviewError(failure.message)),
        (completed) => emit(
          MyReviewsState(pendingReviews: pending, completedReviews: completed),
        ),
      );
    });
  }
}
