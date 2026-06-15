import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/src/core/di/injection.dart';
import 'package:mobile/src/shared/models/product_model.dart';
import '../pages/product_reviews_page.dart';
import 'package:mobile/src/features/product_review/presentation/state/review_cubit.dart';
import 'package:mobile/src/features/product_review/presentation/state/review_state.dart';

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
          final theme = Theme.of(context);
          final cs = theme.colorScheme;
          if (state is ReviewLoaded) {
            final hasReviews = state.reviews.isNotEmpty;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ĐÁNH GIÁ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (hasReviews)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  product.averageRating.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w300,
                                    color: cs.onSurface,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '/ 5.0',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: cs.onSurface.withValues(alpha: 0.3),
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
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Text(
                              'XEM TẤT CẢ',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: cs.onSurface,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  if (hasReviews)
                    _buildReviewList(state.reviews.take(3).toList())
                  else
                    Text(
                      'Sản phẩm hiện chưa có đánh giá từ người dùng.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w300,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildReviewList(List<dynamic> reviews) {
    return Column(
      children: reviews.map((review) {
        return _ReviewItem(
          userName: review.userName,
          rating: review.rating,
          comment: review.comment ?? '',
          images: review.images,
        );
      }).toList(),
    );
  }
}

class _ReviewItem extends StatelessWidget {
  final String userName;
  final int rating;
  final String comment;
  final List<String> images;

  const _ReviewItem({
    required this.userName,
    required this.rating,
    required this.comment,
    required this.images,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Row(
                children: List.generate(5, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      index < rating ? Icons.star : Icons.star_outline,
                      size: 12,
                      color: index < rating
                          ? _starColor
                          : cs.onSurface.withValues(alpha: 0.1),
                    ),
                  );
                }),
              ),
              const Spacer(),
              Text(
                userName.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (comment.isNotEmpty)
            Text(
              comment,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w300,
                color: cs.onSurfaceVariant,
                height: 1.6,
              ),
            ),
          if (images.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        images[index],
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
