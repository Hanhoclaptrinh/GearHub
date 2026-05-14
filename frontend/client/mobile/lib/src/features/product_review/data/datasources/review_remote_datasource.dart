import 'dart:io';
import 'package:dio/dio.dart';
import '../models/review_model.dart';

class ReviewRemoteDatasource {
  final Dio _dio;

  ReviewRemoteDatasource({required Dio dio}) : _dio = dio;

  Future<(List<ReviewModel>, int)> getProductReviews(
    String productId, {
    int page = 1,
    int limit = 10,
    int? rating,
    bool? hasImage,
  }) async {
    final response = await _dio.get(
      '/reviews/products/$productId',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (rating != null) 'rating': rating,
        if (hasImage != null) 'hasImage': hasImage,
      },
    );

    final List<dynamic> data = response.data['data'];
    final int total = response.data['meta']['total'];
    return (data.map((e) => ReviewModel.fromJson(e)).toList(), total);
  }

  Future<ReviewModel> submitReview({
    required String orderItemId,
    required double rating,
    String? comment,
    List<File>? images,
  }) async {
    final formData = FormData.fromMap({
      'orderItemId': orderItemId,
      'rating': rating.toInt(),
      if (comment != null) 'comment': comment,
    });

    if (images != null && images.isNotEmpty) {
      for (int i = 0; i < images.length; i++) {
        formData.files.add(
          MapEntry(
            'files',
            await MultipartFile.fromFile(
              images[i].path,
              filename: images[i].path.split('/').last,
            ),
          ),
        );
      }
    }

    final response = await _dio.post('/reviews', data: formData);

    return ReviewModel.fromJson(response.data);
  }

  Future<ReviewModel> updateReview({
    required String reviewId,
    int? rating,
    String? comment,
  }) async {
    final Map<String, dynamic> data = {};
    if (rating != null) data['rating'] = rating;
    if (comment != null) data['comment'] = comment;

    final response = await _dio.patch('/reviews/$reviewId', data: data);

    return ReviewModel.fromJson(response.data);
  }

  Future<void> deleteReview(String reviewId) async {
    await _dio.delete('/reviews/$reviewId');
  }

  Future<Map<String, dynamic>> getReviewSummary(String productId) async {
    final response = await _dio.get('/reviews/product/$productId/summary');
    return Map<String, dynamic>.from(response.data);
  }

  Future<List<Map<String, dynamic>>> getPendingReviews() async {
    final response = await _dio.get('/reviews/pending');
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<List<ReviewModel>> getUserReviews() async {
    final response = await _dio.get('/reviews/my-reviews');
    final List<dynamic> data = response.data;
    return data.map((e) => ReviewModel.fromJson(e)).toList();
  }

  Future<void> skipReview(String orderItemId) async {
    await _dio.patch('/reviews/skip/$orderItemId');
  }
}
