import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/src/core/utils/formatter_utils.dart';
import 'package:mobile/src/features/product_review/presentation/state/review_cubit.dart';
import 'package:mobile/src/features/product_review/presentation/state/review_state.dart';
import 'package:mobile/src/features/product_review/presentation/widgets/shop_reply_widget.dart';
import '../../../../core/di/injection.dart';

class ProductReviewsPage extends StatefulWidget {
  final String productId;

  const ProductReviewsPage({super.key, required this.productId});

  @override
  State<ProductReviewsPage> createState() => _ProductReviewsPageState();
}

class _ProductReviewsPageState extends State<ProductReviewsPage> {
  int? _selectedRating;
  bool _hasImage = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocProvider(
      create: (context) => getIt<ReviewCubit>()..loadReviews(widget.productId),
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          backgroundColor: colorScheme.surface,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          title: Text(
            'Đánh giá sản phẩm',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          leading: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        body: BlocBuilder<ReviewCubit, ReviewState>(
          builder: (context, state) {
            if (state is ReviewLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is ReviewError) {
              return Center(child: Text(state.message));
            } else if (state is ReviewLoaded) {
              final reviews = state.reviews;
              final summary = state.summary;
              final filteredTotal = state.filteredTotal;
              final avgRating = (summary['total'] ?? 0) > 0
                  ? (summary['average'] as num? ?? 0).toDouble()
                  : 0.0;

              return Stack(
                children: [
                  SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRatingSummary(colorScheme, avgRating, summary),
                        const SizedBox(height: 24),
                        _buildFilterChips(context, colorScheme),
                        const SizedBox(height: 32),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Text(
                            'Tất cả đánh giá ($filteredTotal)',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (reviews.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(48.0),
                            child: Center(
                              child: Text(
                                'Chưa có đánh giá nào phù hợp bộ lọc này.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        else
                          _buildReviewList(colorScheme, reviews),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context, ColorScheme colorScheme) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          _filterChip(
            label: 'Tất cả',
            isSelected: _selectedRating == null && !_hasImage,
            onTap: () {
              setState(() {
                _selectedRating = null;
                _hasImage = false;
              });
              context.read<ReviewCubit>().loadReviews(widget.productId);
            },
          ),
          ...List.generate(5, (index) {
            final star = 5 - index;
            return _filterChip(
              label: '$star sao',
              isSelected: _selectedRating == star,
              onTap: () {
                setState(() {
                  _selectedRating = star;
                  _hasImage = false;
                });
                context.read<ReviewCubit>().loadReviews(
                  widget.productId,
                  rating: star,
                );
              },
            );
          }),
          _filterChip(
            label: 'Có hình ảnh',
            isSelected: _hasImage,
            onTap: () {
              setState(() {
                _hasImage = true;
                _selectedRating = null;
              });
              context.read<ReviewCubit>().loadReviews(
                widget.productId,
                hasImage: true,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: colorScheme.primaryContainer,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected
              ? colorScheme.onPrimaryContainer
              : colorScheme.onSurface,
        ),
        backgroundColor: colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            width: 1,
          ),
        ),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildRatingSummary(
    ColorScheme colorScheme,
    double avgRating,
    Map<String, dynamic> summary,
  ) {
    final total = (summary['total'] ?? 0) as int;

    double getPct(int star) {
      if (total == 0) return 0.0;
      final count = (summary['$star'] ?? 0) as int;
      return count / total;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // large score
          Column(
            children: [
              Text(
                avgRating.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                  color: colorScheme.onSurface,
                  letterSpacing: -2,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  return Icon(
                    index < avgRating.floor() ? Icons.star : Icons.star_outline,
                    size: 18,
                    color: index < avgRating.floor()
                        ? Colors.amber
                        : Colors.black.withValues(alpha: 0.1),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(width: 32),
          // progress bars
          Expanded(
            child: Column(
              children: [
                _buildStarRow(5, getPct(5), colorScheme),
                _buildStarRow(4, getPct(4), colorScheme),
                _buildStarRow(3, getPct(3), colorScheme),
                _buildStarRow(2, getPct(2), colorScheme),
                _buildStarRow(1, getPct(1), colorScheme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarRow(int stars, double pct, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            '$stars',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: pct,
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // list danh gia
  Widget _buildReviewList(ColorScheme colorScheme, List<dynamic> reviews) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: reviews.length,
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      separatorBuilder: (context, _) => Divider(
        color: colorScheme.outlineVariant.withValues(alpha: 0.2),
        height: 48,
      ),
      itemBuilder: (context, index) {
        final review = reviews[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // avt
                CircleAvatar(
                  radius: 18,
                  backgroundColor: colorScheme.surfaceContainerHigh,
                  backgroundImage: review.userAvatar != null
                      ? NetworkImage(review.userAvatar!)
                      : null,
                  child: review.userAvatar == null
                      ? Text(
                          review.userName.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // name & badge
                      Row(
                        children: [
                          Text(
                            review.userName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          if (review.isVerifiedPurchase) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified_rounded,
                              size: 14,
                              color: Colors.blue,
                            ),
                          ],
                        ],
                      ),
                      // date of review
                      Text(
                        formatDate(review.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      // variant
                      if (review.variantName != null &&
                          review.variantName!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHigh.withValues(
                              alpha: 0.5,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            review.variantName!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.8,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // stars
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (starIdx) {
                    return Icon(
                      starIdx < review.rating ? Icons.star : Icons.star_outline,
                      size: 14,
                      color: Colors.amber,
                    );
                  }),
                ),
              ],
            ),
            if (review.comment != null && review.comment!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                review.comment!,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: colorScheme.onSurface,
                  height: 1.5,
                ),
              ),
            ],
            if (review.images.isNotEmpty) ...[
              const SizedBox(height: 16),
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: review.images.length,
                  separatorBuilder: (context, _) => const SizedBox(width: 8),
                  itemBuilder: (context, imgIdx) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: review.images[imgIdx],
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHigh,
                        ),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.error),
                      ),
                    );
                  },
                ),
              ),
            ],
            if (review.reply != null && review.reply!.isNotEmpty) ...[
              const SizedBox(height: 16),
              ShopReplyWidget(reply: review.reply!),
            ],
          ],
        );
      },
    );
  }
}
