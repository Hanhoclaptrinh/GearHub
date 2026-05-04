import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mobile/src/shared/models/product_model.dart';
import '../pages/product_reviews_page.dart';
import '../pages/write_review_page.dart';

class ProductReviewsPreviewSection extends StatelessWidget {
  final ProductModel product;

  const ProductReviewsPreviewSection({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasReviews = product.reviewCount > 0;

    if (!hasReviews) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
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
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (hasReviews)
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 14, color: Colors.black),
                        const SizedBox(width: 4),
                        Text(
                          '${product.averageRating} (${product.reviewCount} đánh giá)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
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
                        builder: (context) => const ProductReviewsPage(),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Text(
                        'Tất cả',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 10,
                        color: Colors.grey.shade700,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (hasReviews)
            _buildReviewCards(colorScheme)
          else ...[
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 20.0),
              child: Text(
                'Chưa có đánh giá nào. Trở thành người đầu tiên!',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const WriteReviewPage(),
                  ),
                );
              },
              icon: const Icon(Icons.edit_note_rounded, size: 20, color: Colors.white),
              label: const Text(
                'Viết đánh giá đầu tiên',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewCards(ColorScheme colorScheme) {
    return const Column(
      children: [
        _ReviewCard(
          userName: 'Alex D.',
          rating: 5,
          comment: 'Absolutely phenomenal build quality. Exceeds expectations.',
        ),
        SizedBox(height: 12),
        _ReviewCard(
          userName: 'Sarah M.',
          rating: 5,
          comment: 'The display is just gorgeous. Very premium feel.',
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final String userName;
  final int rating;
  final String comment;

  const _ReviewCard({
    required this.userName,
    required this.rating,
    required this.comment,
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
            color: Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ...List.generate(5, (index) {
                    return Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: index < rating
                          ? Colors.black
                          : Colors.black.withValues(alpha: 0.2),
                    );
                  }),
                  const Spacer(),
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                comment,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
