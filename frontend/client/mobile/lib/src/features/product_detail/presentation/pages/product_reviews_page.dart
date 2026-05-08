import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/core/utils/formatter_utils.dart';
import 'package:mobile/src/features/product_review/presentation/state/review_cubit.dart';
import 'package:mobile/src/features/product_review/presentation/state/review_state.dart';
import 'package:mobile/src/features/product_review/presentation/widgets/shop_reply_widget.dart';
import '../../../../core/di/injection.dart';

const _bg         = Color(0xFF0A0A10);
const _surface    = Color(0xFF14141E);
const _surfaceAlt = Color(0xFF1C1C28);
const _border     = Color(0xFF2A2A38);
const _accent     = Color(0xFFF59E0B);
const _accentSoft = Color(0x26F59E0B);
const _indigo     = Color(0xFF6366F1);
const _textHigh   = Color(0xFFF1F1F5);
const _textMid    = Color(0xFF9191A8);
const _textLow    = Color(0xFF4A4A62);

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
    return BlocProvider(
      create: (context) => getIt<ReviewCubit>()..loadReviews(widget.productId),
      child: Scaffold(
        backgroundColor: _bg,
        body: Stack(
          children: [
            BlocBuilder<ReviewCubit, ReviewState>(
              builder: (context, state) {
                if (state is ReviewLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: _accent, strokeWidth: 2),
                  );
                } else if (state is ReviewError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.circleAlert, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text(state.message, style: const TextStyle(color: _textMid)),
                      ],
                    ),
                  );
                } else if (state is ReviewLoaded) {
                  final reviews = state.reviews;
                  final summary = state.summary;
                  final filteredTotal = state.filteredTotal;
                  final avgRating = (summary['total'] ?? 0) > 0
                      ? (summary['average'] as num? ?? 0).toDouble()
                      : 0.0;

                  return CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      _buildSliverAppBar(),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 12),
                              _buildRatingSummary(avgRating, summary),
                              const SizedBox(height: 28),
                              const _SectionLabel(text: "BỘ LỌC ĐÁNH GIÁ"),
                              const SizedBox(height: 16),
                              _buildFilterChips(context),
                              const SizedBox(height: 32),
                              Row(
                                children: [
                                  const Text(
                                    'Tất cả đánh giá',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: _textHigh,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _surfaceAlt,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: _border, width: 0.5),
                                    ),
                                    child: Text(
                                      '$filteredTotal',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: _textMid,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              if (reviews.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 80),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        Icon(LucideIcons.messageSquareDashed, size: 48, color: _textLow),
                                        SizedBox(height: 16),
                                        Text(
                                          'Chưa có đánh giá nào phù hợp bộ lọc này.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(color: _textLow, fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                _buildReviewList(reviews),
                              const SizedBox(height: 50),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: _bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: const Icon(Icons.arrow_back_ios_new_rounded, color: _textMid),
      ),
      title: const Text(
        'Đánh giá sản phẩm',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: _textHigh,
          letterSpacing: 0.5,
        ),
      ),
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(color: Colors.transparent),
        ),
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        children: [
          _customChip(
            label: 'Tất cả',
            isSelected: _selectedRating == null && !_hasImage,
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                _selectedRating = null;
                _hasImage = false;
              });
              context.read<ReviewCubit>().loadReviews(widget.productId);
            },
          ),
          ...List.generate(5, (index) {
            final star = 5 - index;
            return _customChip(
              label: '$star sao',
              icon: Icons.star,
              isSelected: _selectedRating == star,
              onTap: () {
                HapticFeedback.lightImpact();
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
          _customChip(
            label: 'Có hình ảnh',
            icon: LucideIcons.image,
            isSelected: _hasImage,
            onTap: () {
              HapticFeedback.lightImpact();
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

  Widget _customChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _accent : _surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? _accent : _border,
            width: isSelected ? 1.5 : 0.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _accent.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.black : _textLow,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                color: isSelected ? Colors.black : _textMid,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSummary(
    double avgRating,
    Map<String, dynamic> summary,
  ) {
    final total = (summary['total'] ?? 0) as int;

    double getPct(int star) {
      if (total == 0) return 0.0;
      final count = (summary['$star'] ?? 0) as int;
      return count / total;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // large score
          Column(
            children: [
              Text(
                avgRating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                  color: _textHigh,
                  letterSpacing: -2,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  return Icon(
                    index < avgRating.floor() ? Icons.star : Icons.star_outline,
                    size: 16,
                    color: index < avgRating.floor() ? _accent : _textLow,
                  );
                }),
              ),
              const SizedBox(height: 8),
              Text(
                '$total đánh giá',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _textLow,
                ),
              ),
            ],
          ),
          const SizedBox(width: 32),
          // progress bars
          Expanded(
            child: Column(
              children: [
                _buildStarRow(5, getPct(5)),
                _buildStarRow(4, getPct(4)),
                _buildStarRow(3, getPct(3)),
                _buildStarRow(2, getPct(2)),
                _buildStarRow(1, getPct(1)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarRow(int stars, double pct) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        children: [
          SizedBox(
            width: 12,
            child: Text(
              '$stars',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: _textLow,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 5,
              decoration: BoxDecoration(
                color: _surfaceAlt,
                borderRadius: BorderRadius.circular(10),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: pct,
                child: Container(
                  decoration: BoxDecoration(
                    color: stars >= 4 ? _accent : _textLow,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: stars >= 4 ? [
                      BoxShadow(
                        color: _accent.withValues(alpha: 0.3),
                        blurRadius: 4,
                      )
                    ] : [],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewList(List<dynamic> reviews) {
    return Column(
      children: reviews.map((review) {
        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // avt
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _accent.withValues(alpha: 0.2), width: 1.5),
                    ),
                    child: CircleAvatar(
                      backgroundColor: _surfaceAlt,
                      backgroundImage: review.userAvatar != null
                          ? CachedNetworkImageProvider(review.userAvatar!)
                          : null,
                      child: review.userAvatar == null
                          ? Text(
                              review.userName.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: _accent,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // name & badge
                        Row(
                          children: [
                            Text(
                              review.userName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: _textHigh,
                              ),
                            ),
                            if (review.isVerifiedPurchase) ...[
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.verified_rounded,
                                size: 16,
                                color: _indigo,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        // date of review
                        Text(
                          formatDate(review.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _textLow,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // stars
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _accentSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, size: 14, color: _accent),
                        const SizedBox(width: 4),
                        Text(
                          '${review.rating}',
                          style: const TextStyle(
                            color: _accent,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // variant tag
              if (review.variantName != null && review.variantName!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _surfaceAlt,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _border, width: 0.5),
                  ),
                  child: Text(
                    "${review.variantName!}",
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _textMid,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              if (review.comment != null && review.comment!.isNotEmpty) ...[
                Text(
                  review.comment!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _textMid,
                    height: 1.6,
                  ),
                ),
              ],
              
              if (review.images.isNotEmpty) ...[
                const SizedBox(height: 16),
                SizedBox(
                  height: 90,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: review.images.length,
                    separatorBuilder: (context, _) => const SizedBox(width: 10),
                    itemBuilder: (context, imgIdx) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: review.images[imgIdx],
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: _surfaceAlt),
                          errorWidget: (context, url, error) => const Icon(LucideIcons.imageOff),
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
              
              const SizedBox(height: 24),
              Container(height: 1, color: _border.withValues(alpha: 0.5)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: _accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: _textLow,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}
