import 'package:equatable/equatable.dart';
import 'package:mobile/src/features/product_review/domain/entities/review_entity.dart';

abstract class ReviewState extends Equatable {
  const ReviewState();
  @override
  List<Object?> get props => [];
}

class ReviewInitial extends ReviewState {}

class ReviewLoading extends ReviewState {}

class ReviewLoaded extends ReviewState {
  final List<ReviewEntity> reviews;
  final Map<String, dynamic> summary;
  final int filteredTotal;
  final bool hasMore;

  const ReviewLoaded({
    required this.reviews,
    required this.summary,
    required this.filteredTotal,
    this.hasMore = false,
  });

  @override
  List<Object?> get props => [reviews, summary, filteredTotal, hasMore];
}

class ReviewError extends ReviewState {
  final String message;
  const ReviewError(this.message);
  @override
  List<Object?> get props => [message];
}

class ReviewActionSuccess extends ReviewState {
  final String message;
  const ReviewActionSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class PendingReviewsLoaded extends ReviewState {
  final List<Map<String, dynamic>> pendingReviews;
  const PendingReviewsLoaded(this.pendingReviews);
  @override
  List<Object?> get props => [pendingReviews];
}

class UserReviewsLoaded extends ReviewState {
  final List<ReviewEntity> reviews;
  const UserReviewsLoaded(this.reviews);
  @override
  List<Object?> get props => [reviews];
}

class MyReviewsState extends ReviewState {
  final List<Map<String, dynamic>> pendingReviews;
  final List<ReviewEntity> completedReviews;
  final bool isLoading;
  const MyReviewsState({
    required this.pendingReviews,
    required this.completedReviews,
    this.isLoading = false,
  });
  @override
  List<Object?> get props => [pendingReviews, completedReviews, isLoading];
}
