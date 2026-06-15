import 'dart:ui' show ImageFilter;
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
import 'package:mobile/src/core/theme/app_colors.dart';
import 'package:mobile/src/shared/widgets/error_illustration_widget.dart';
import '../../../../core/di/injection.dart';

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
  final GlobalKey _filterKey = GlobalKey();

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider(
      create: (context) => getIt<ReviewCubit>()..loadReviews(widget.productId),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Stack(
          children: [
            _buildImmersiveBackground(isDark),

            BlocBuilder<ReviewCubit, ReviewState>(
              builder: (context, state) {
                if (state is ReviewLoading) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: isDark
                          ? const Color(0xFF818CF8)
                          : const Color(0xFF4F46E5),
                      strokeWidth: 2,
                    ),
                  );
                } else if (state is ReviewError) {
                  return Stack(
                    children: [
                      Center(
                        child: ErrorIllustrationWidget(
                          message: state.message,
                          onRetry: () => context
                              .read<ReviewCubit>()
                              .loadReviews(widget.productId),
                        ),
                      ),
                      GlassmorphicHeader(
                        scrollOffset: _scrollOffset,
                        title: 'Góc nhìn từ người dùng',
                        onBack: () => Navigator.pop(context),
                      ),
                    ],
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
                                  _buildRatingSummary(
                                    context,
                                    avgRating,
                                    summary,
                                    isDark,
                                  ),
                                  const SizedBox(height: 48),
                                  _buildFilterSection(context),
                                  const SizedBox(height: 40),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          'ĐÁNH GIÁ TỪ CỘNG ĐỒNG',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
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
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.3),
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

  Widget _buildImmersiveBackground(bool isDark) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.6),
            radius: 1.5,
            colors: [
              isDark ? const Color(0xFF161622) : const Color(0xFFEEF1F6),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
      ),
    );
  }

  //bảng avg rating
  Widget _buildRatingSummary(
    BuildContext context,
    double avgRating,
    Map<String, dynamic> summary,
    bool isDark,
  ) {
    final total = (summary['total'] as num? ?? 0).toInt();

    //tính phần trăm cho thanh rating
    double getPct(int star) {
      if (total == 0) return 0.0;
      final count = (summary['$star'] as num? ?? 0).toInt();
      return count / total;
    }

    const Color accentColor = AppColors.accentGold;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
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
                        style: TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.w300,
                          color: Theme.of(context).colorScheme.onSurface,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '/ 5.0',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.2),
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
                            ? accentColor
                            : Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.05),
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
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.3),
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
    const Color accentColor = AppColors.accentGold;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$stars',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(1),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: pct,
                child: Container(
                  decoration: BoxDecoration(
                    color: stars >= 4
                        ? accentColor
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(1),
                    boxShadow: stars >= 4
                        ? [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.3),
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    String filterLabel = 'TẤT CẢ';
    IconData filterIcon = LucideIcons.slidersHorizontal;
    if (_selectedRating != null) {
      filterLabel = '$_selectedRating SAO';
      filterIcon = Icons.star;
    } else if (_hasImage) {
      filterLabel = 'CÓ HÌNH ẢNH';
      filterIcon = LucideIcons.image;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BỘ LỌC ĐÁNH GIÁ',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: cs.onSurface.withValues(alpha: 0.4),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          key: _filterKey,
          onTap: () => _showFilterDialog(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? cs.onSurface.withValues(alpha: 0.03)
                  : cs.onSurface.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(filterIcon, size: 14, color: cs.onSurface),
                const SizedBox(width: 10),
                Text(
                  filterLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: cs.onSurface,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: cs.onSurface.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showFilterDialog(BuildContext parentContext) {
    final theme = Theme.of(parentContext);
    final cs = theme.colorScheme;

    final RenderBox? renderBox =
        _filterKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final screenWidth = MediaQuery.of(parentContext).size.width;

    showGeneralDialog(
      context: parentContext,
      barrierDismissible: true,
      barrierLabel: 'Dismiss Filter',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                behavior: HitTestBehavior.opaque,
                child: FadeTransition(
                  opacity: anim1,
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: offset.dy + size.height + 8,
              left: offset.dx.clamp(16.0, screenWidth - 220.0 - 16.0),
              width: 220,
              child: FadeTransition(
                opacity: anim1,
                child: ScaleTransition(
                  scale: anim1,
                  alignment: Alignment.topLeft,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.brightness == Brightness.dark
                            ? const Color(0xFF1E1E2E).withValues(alpha: 0.9)
                            : Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: cs.onSurface.withValues(alpha: 0.08),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildDialogOption(
                            context: context,
                            label: 'TẤT CẢ',
                            icon: LucideIcons.slidersHorizontal,
                            isSelected: _selectedRating == null && !_hasImage,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _selectedRating = null;
                                _hasImage = false;
                              });
                              parentContext.read<ReviewCubit>().loadReviews(
                                widget.productId,
                              );
                              Navigator.pop(context);
                            },
                          ),
                          ...List.generate(5, (index) {
                            final star = 5 - index;
                            return _buildDialogOption(
                              context: context,
                              label: '$star SAO',
                              icon: Icons.star,
                              isSelected: _selectedRating == star,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _selectedRating = star;
                                  _hasImage = false;
                                });
                                parentContext.read<ReviewCubit>().loadReviews(
                                  widget.productId,
                                  rating: star,
                                );
                                Navigator.pop(context);
                              },
                            );
                          }),
                          _buildDialogOption(
                            context: context,
                            label: 'CÓ HÌNH ẢNH',
                            icon: LucideIcons.image,
                            isSelected: _hasImage,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _hasImage = true;
                                _selectedRating = null;
                              });
                              parentContext.read<ReviewCubit>().loadReviews(
                                widget.productId,
                                hasImage: true,
                              );
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDialogOption({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return ListTile(
      onTap: onTap,
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Icon(
        icon,
        size: 14,
        color: isSelected
            ? AppColors.accentGold
            : cs.onSurface.withValues(alpha: 0.6),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
          color: isSelected ? AppColors.accentGold : cs.onSurface,
          letterSpacing: 0.5,
        ),
      ),
      trailing: isSelected
          ? const Icon(
              Icons.check_circle_rounded,
              size: 14,
              color: AppColors.accentGold,
            )
          : null,
    );
  }

  Widget _buildReviewList(List<dynamic> reviews) {
    final theme = Theme.of(context);

    return Column(
      children: reviews.map((review) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 32),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
              ),
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
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.12,
                        ),
                      ),
                    ),
                    child: CircleAvatar(
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      backgroundImage: review.userAvatar != null
                          ? CachedNetworkImageProvider(review.userAvatar!)
                          : null,
                      child: review.userAvatar == null
                          ? Text(
                              review.userName.substring(0, 1).toUpperCase(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.8,
                                ),
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
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatDate(review.createdAt).toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.3,
                            ),
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
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.04,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.08,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 12,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${review.rating}',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.8,
                            ),
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
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.45),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              if (review.comment != null)
                Text(
                  review.comment!,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w300,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
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
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 24),
            Text(
              'CHƯA CÓ DỮ LIỆU TRẢI NGHIỆM',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.2),
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
