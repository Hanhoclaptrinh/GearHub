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
import 'package:mobile/src/shared/widgets/glassmorphic_header.dart';
import '../../../../core/di/injection.dart';

const _bg = Color(0xFF07070A);
const _starColor = Color(0xFFFFCC00);

class ProductReviewsPage extends StatefulWidget {
  final String productId;

  const ProductReviewsPage({super.key, required this.productId});

  @override
  State<ProductReviewsPage> createState() => _ProductReviewsPageState();
}

class _ProductReviewsPageState extends State<ProductReviewsPage> {
  late final ScrollController _scrollController;
  double _scrollOffset = 0;
  int? _selectedRating;
  bool _hasImage = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()
      ..addListener(() {
        setState(() {
          _scrollOffset = _scrollController.offset;
        });
      });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ReviewCubit>()..loadReviews(widget.productId),
      child: Scaffold(
        backgroundColor: _bg,
        body: Stack(
          children: [
            _buildImmersiveBackground(),

            BlocBuilder<ReviewCubit, ReviewState>(
              builder: (context, state) {
                if (state is ReviewLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: _starColor,
                      strokeWidth: 2,
                    ),
                  );
                } else if (state is ReviewLoaded) {
                  final reviews = state.reviews;
                  final summary = state.summary;
                  final filteredTotal = state.filteredTotal;
                  final avgRating = (summary['total'] ?? 0) > 0
                      ? (summary['average'] as num? ?? 0).toDouble()
                      : 0.0;

                  return Stack(
                    children: [
                      CustomScrollView(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          const SliverToBoxAdapter(
                            child: SizedBox(height: 100),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 24),
                                  _buildRatingSummary(avgRating, summary),
                                  const SizedBox(height: 48),
                                  _buildFilterSection(context),
                                  const SizedBox(height: 40),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      const Flexible(
                                        child: Text(
                                          'ĐÁNH GIÁ TỪ CỘNG ĐỒNG',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        '$filteredTotal KẾT QUẢ',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white.withValues(
                                            alpha: 0.3,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  if (reviews.isEmpty)
                                    _buildEmptyState()
                                  else
                                    _buildReviewList(reviews),
                                  const SizedBox(height: 100),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      GlassmorphicHeader(
                        scrollOffset: _scrollOffset,
                        title: 'Góc nhìn từ người dùng',
                        onBack: () => Navigator.pop(context),
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

  Widget _buildImmersiveBackground() {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.6),
            radius: 1.5,
            colors: [ Color(0xFF1A1A25), _bg],
          ),
        ),
      ),
    );
  }

  // bang avg rating
  Widget _buildRatingSummary(double avgRating, Map<String, dynamic> summary) {
    final total = (summary['total'] as num? ?? 0).toInt();

    // tinh phan tram cho thanh rating
    double getPct(int star) {
      if (total == 0) return 0.0;
      final count = (summary['$star'] as num? ?? 0).toInt();
      return count / total;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        avgRating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.w300,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '/ 5.0',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: List.generate(5, (index) {
                    final fill = (avgRating - index).clamp(0.0, 1.0);
                    return Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(
                        fill > 0.5 ? Icons.star : Icons.star_outline,
                        size: 14,
                        color: fill > 0.5
                            ? _starColor
                            : Colors.white.withValues(alpha: 0.05),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                Text(
                  '${formatCompactNumber(total)} BÀI ĐÁNH GIÁ',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 5,
            child: Column(
              children: List.generate(5, (index) {
                final star = 5 - index;
                return _buildStarProgress(star, getPct(star));
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarProgress(int stars, double pct) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$stars',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(1),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: pct,
                child: Container(
                  decoration: BoxDecoration(
                    color: stars >= 4
                        ? _starColor
                        : Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(1),
                    boxShadow: stars >= 4
                        ? [
                            BoxShadow(
                              color: _starColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                            ),
                          ]
                        : [],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'BỘ LỌC ĐÁNH GIÁ',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: [
              _customChip(
                label: 'TẤT CẢ',
                isSelected: _selectedRating == null && !_hasImage,
                onTap: () {
                  HapticFeedback.selectionClick();
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
                  label: '$star SAO',
                  icon: Icons.star_outline,
                  isSelected: _selectedRating == star,
                  onTap: () {
                    HapticFeedback.selectionClick();
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
                label: 'CÓ HÌNH ẢNH',
                icon: LucideIcons.image,
                isSelected: _hasImage,
                onTap: () {
                  HapticFeedback.selectionClick();
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
        ),
      ],
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
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.07),
          ),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 12,
                color: isSelected
                    ? Colors.black
                    : Colors.white.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: isSelected ? Colors.black : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewList(List<dynamic> reviews) {
    return Column(
      children: reviews.map((review) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 32),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _starColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: CircleAvatar(
                      backgroundColor: const Color(0xFF1A1A25),
                      backgroundImage: review.userAvatar != null
                          ? CachedNetworkImageProvider(review.userAvatar!)
                          : null,
                      child: review.userAvatar == null
                          ? Text(
                              review.userName.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: _starColor,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review.userName.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatDate(review.createdAt).toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _starColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _starColor.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, size: 12, color: _starColor),
                        const SizedBox(width: 6),
                        Text(
                          '${review.rating}',
                          style: const TextStyle(
                            color: _starColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (review.variantName != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    "${review.variantName!.toUpperCase()}",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: _starColor.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              if (review.comment != null)
                Text(
                  review.comment!,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w300,
                    color: Colors.white.withValues(alpha: 0.7),
                    height: 1.8,
                  ),
                ),
              if (review.images.isNotEmpty) ...[
                const SizedBox(height: 20),
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: review.images.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, idx) => ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CachedNetworkImage(
                        imageUrl: review.images[idx],
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ],
              if (review.reply != null) ...[
                const SizedBox(height: 24),
                ShopReplyWidget(reply: review.reply!),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 100),
      child: Center(
        child: Column(
          children: [
            Icon(
              LucideIcons.messageSquareDashed,
              size: 48,
              color: Colors.white.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 24),
            Text(
              'CHƯA CÓ DỮ LIỆU TRẢI NGHIỆM',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.2),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
