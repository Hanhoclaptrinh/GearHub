import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/src/core/di/injection.dart';
import 'package:mobile/src/shared/models/product_model.dart';
import '../pages/product_reviews_page.dart';
import 'package:mobile/src/features/product_review/presentation/state/review_cubit.dart';
import 'package:mobile/src/features/product_review/presentation/state/review_state.dart';

const _surface = Color(0xFF14141E);
const _border = Color(0xFF2A2A38);
const _textHigh = Color(0xFFF1F1F5);
const _textMid = Color(0xFF9191A8);
const _starColor = Color(0xFFFFCC00);

class ProductReviewsPreviewSection extends StatelessWidget {
  final ProductModel product;

  const ProductReviewsPreviewSection({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ReviewCubit>()..loadReviews(product.id),
      child: BlocBuilder<ReviewCubit, ReviewState>(
        builder: (context, state) {
          if (state is ReviewLoaded) {
            final hasReviews = state.reviews.isNotEmpty;

            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Đánh giá',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: _textHigh,
                              letterSpacing: -0.5,
                            ),
                          ),
                          if (hasReviews)
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 14,
                                  color: _starColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${product.averageRating} (${product.reviewCount} đánh giá)',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _textMid,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      if (hasReviews)
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    ProductReviewsPage(productId: product.id),
                              ),
                            );
                          },
                          child: const Row(
                            children: [
                              Text(
                                'Tất cả',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _textMid,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 10,
                                color: _textMid,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (hasReviews)
                    _buildReviewCards(state.reviews.take(3).toList())
                  else ...[
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0, bottom: 20.0),
                      child: Text(
                        'Chưa có đánh giá nào cho sản phẩm này.',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: _textMid,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildReviewCards(List<dynamic> reviews) {
    return Column(
      children: reviews.map((review) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: _ReviewCard(
            userName: review.userName,
            rating: review.rating,
            comment: review.comment ?? '',
            images: review.images,
          ),
        );
      }).toList(),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final String userName;
  final int rating;
  final String comment;
  final List<String> images;

  const _ReviewCard({
    required this.userName,
    required this.rating,
    required this.comment,
    required this.images,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _border, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ...List.generate(5, (index) {
                    return Icon(
                      index < rating ? Icons.star : Icons.star_outline,
                      size: 16,
                      color: _starColor,
                    );
                  }),
                  const Spacer(),
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _textMid,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (comment.isNotEmpty)
                Text(
                  comment,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: _textHigh,
                    height: 1.5,
                  ),
                ),
              if (images.isNotEmpty) ...[
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: images.map((url) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            url,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
