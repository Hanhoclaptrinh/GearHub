import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:mobile/src/features/product_review/domain/entities/review_entity.dart';
import 'package:mobile/src/features/product_review/domain/repositories/review_repository.dart';
import '../../../../core/error/failures.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../datasources/review_remote_datasource.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  final ReviewRemoteDatasource remoteDatasource;
  final AuthRepository authRepository;

  ReviewRepositoryImpl({
    required this.remoteDatasource,
    required this.authRepository,
  });

  String _getErrorMessage(dynamic e) {
    if (e is DioException) {
      if (e.response?.data != null && e.response?.data is Map) {
        final message = e.response?.data['message'];
        if (message is List) return message.join(', ');
        if (message is String) return message;
      }
      return e.message ?? e.toString();
    }
    return e.toString();
  }

  @override
  Future<Either<Failure, (List<ReviewEntity>, int)>> getProductReviews(
    String productId, {
    int page = 1,
    int limit = 10,
    int? rating,
    bool? hasImage,
  }) async {
    try {
      final result = await remoteDatasource.getProductReviews(
        productId,
        page: page,
        limit: limit,
        rating: rating,
        hasImage: hasImage,
      );
      return right(result);
    } catch (e) {
      if (e.toString().contains('401')) {
        await authRepository.logout();
      }
      return left(Failure(_getErrorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, ReviewEntity>> createReview({
    required String orderItemId,
    required int rating,
    String? comment,
    List<String>? imagePaths,
  }) async {
    try {
      final List<File>? images = imagePaths?.map((path) => File(path)).toList();
      final review = await remoteDatasource.submitReview(
        orderItemId: orderItemId,
        rating: rating.toDouble(),
        comment: comment,
        images: images,
      );
      return right(review);
    } catch (e) {
      if (e.toString().contains('401')) {
        await authRepository.logout();
      }
      return left(Failure(_getErrorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, ReviewEntity>> updateReview({
    required String reviewId,
    int? rating,
    String? comment,
  }) async {
    try {
      final review = await remoteDatasource.updateReview(
        reviewId: reviewId,
        rating: rating,
        comment: comment,
      );
      return right(review);
    } catch (e) {
      if (e.toString().contains('401')) {
        await authRepository.logout();
      }
      return left(Failure(_getErrorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, void>> deleteReview(String reviewId) async {
    try {
      await remoteDatasource.deleteReview(reviewId);
      return right(null);
    } catch (e) {
      if (e.toString().contains('401')) {
        await authRepository.logout();
      }
      return left(Failure(_getErrorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, Map<String, int>>> getReviewSummary(
    String productId,
  ) async {
    try {
      final summary = await remoteDatasource.getReviewSummary(productId);
      return right(summary);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>>
  getPendingReviews() async {
    try {
      final pending = await remoteDatasource.getPendingReviews();
      return right(pending);
    } catch (e) {
      if (e.toString().contains('401')) {
        await authRepository.logout();
      }
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ReviewEntity>>> getUserReviews() async {
    try {
      final reviews = await remoteDatasource.getUserReviews();
      return right(reviews);
    } catch (e) {
      if (e.toString().contains('401')) {
        await authRepository.logout();
      }
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> skipReview(String orderItemId) async {
    try {
      await remoteDatasource.skipReview(orderItemId);
      return right(null);
    } catch (e) {
      if (e.toString().contains('401')) {
        await authRepository.logout();
      }
      return left(Failure(e.toString()));
    }
  }
}
