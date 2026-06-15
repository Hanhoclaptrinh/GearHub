import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/core/utils/formatter_utils.dart';
import 'package:mobile/src/core/theme/app_theme.dart';
import 'package:lottie/lottie.dart';
import '../../../../core/di/injection.dart';
import '../../../auth/presentation/state/auth_cubit.dart';
import '../../../auth/presentation/state/auth_state.dart';
import '../../../product_detail/presentation/pages/write_review_page.dart';
import '../state/review_cubit.dart';
import '../state/review_state.dart';
import '../widgets/shop_reply_widget.dart';
import 'package:mobile/src/shared/widgets/error_illustration_widget.dart';

class PendingReviewsPage extends StatefulWidget {
  const PendingReviewsPage({super.key});

  @override
  State<PendingReviewsPage> createState() => _PendingReviewsPageState();
}

class _PendingReviewsPageState extends State<PendingReviewsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final Color bgColor = theme.scaffoldBackgroundColor;
    final Color textHigh = cs.onSurface;
    const Color brandAccent = Color(0xFF6366F1);

    return BlocProvider(
      create: (context) => getIt<ReviewCubit>()..loadMyReviewsData(),
      child: Scaffold(
        backgroundColor: bgColor,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: bgColor.withValues(alpha: 0.8),
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          systemOverlayStyle: isDark
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark,
          title: Text(
            'Lịch sử đánh giá',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: textHigh,
            ),
          ),
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: textHigh,
              size: 22,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: BlocBuilder<ReviewCubit, ReviewState>(
          builder: (context, state) {
            if (state is ReviewLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: brandAccent,
                  strokeWidth: 2,
                ),
              );
            } else if (state is ReviewError) {
              return ErrorIllustrationWidget(
                message: state.message,
                title: 'Không thể tải lịch sử đánh giá',
                onRetry: () => context.read<ReviewCubit>().loadMyReviewsData(),
              );
            } else if (state is MyReviewsState) {
              return Column(
                children: [
                  const SizedBox(height: 100),
                  _buildHeader(context, state),
                  const SizedBox(height: 24),
                  _buildTabBar(context),
                  const SizedBox(height: 16),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildPendingTab(context, state.pendingReviews),
                        _buildCompletedTab(context, state.completedReviews),
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

  Widget _buildTabBar(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: cs.onPrimary,
        unselectedLabelColor: cs.onSurfaceVariant,
        indicator: BoxDecoration(
          color: cs.primary,
          borderRadius: BorderRadius.circular(32),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        tabs: const [
          Tab(text: 'CHƯA VIẾT'),
          Tab(text: 'ĐÃ HOÀN TẤT'),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, MyReviewsState state) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final borderCol = cs.outlineVariant;
    final textHigh = cs.onSurface;
    final fillCol = cs.surfaceContainerHighest;

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        if (authState is AuthAuthenticated) {
          final user = authState.user;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: borderCol, width: 1.5),
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: fillCol,
                    backgroundImage: user.avatarUrl != null
                        ? CachedNetworkImageProvider(user.avatarUrl!)
                        : null,
                    child: user.avatarUrl == null
                        ? Text(
                            (user.fullName ?? user.email)
                                .substring(0, 1)
                                .toUpperCase(),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: textHigh,
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
                        user.fullName ?? 'KHÁCH HÀNG',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: textHigh,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 15,
                            color: Color(0xFFFFB800),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${state.completedReviews.length} ĐÁNH GIÁ ĐÃ VIẾT',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: textHigh,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildPendingTab(
    BuildContext context,
    List<Map<String, dynamic>> items,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final Color cardBg = theme.cardColor;
    final Color borderCol = cs.outlineVariant;

    final Color textHigh = cs.onSurface;
    final Color textMid = cs.onSurfaceVariant;
    final Color textLow = cs.onSurfaceVariant.withValues(alpha: 0.6);

    final List<BoxShadow> cardShadow = isDark
        ? []
        : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ];

    if (items.isEmpty) {
      return _buildEmptyState(
        lottieAsset: 'assets/animations/emptyorder.json',
        message: 'Mọi thứ đã hoàn tất',
        subMessage: 'Bạn đã viết đánh giá cho toàn bộ sản phẩm đã mua rồi đó!',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 24),
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderCol),
            boxShadow: cardShadow,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 170,
                width: double.infinity,
                decoration: BoxDecoration(color: cs.surfaceContainerHighest),
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: item['image'],
                      width: 130,
                      height: 130,
                      fit: BoxFit.contain,
                      placeholder: (context, url) =>
                          Container(color: Colors.transparent),
                      errorWidget: (context, url, error) =>
                          Icon(LucideIcons.package, color: textLow),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: textHigh,
                        height: 1.2,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (item['variantName'] != null &&
                        item['variantName'].toString().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        item['variantName'].toString().toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: textLow,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: OutlinedButton(
                            onPressed: () {
                              context.read<ReviewCubit>().skipReview(
                                item['orderItemId'],
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: borderCol),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(32),
                              ),
                            ),
                            child: Text(
                              'BỎ QUA',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: textMid,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: ElevatedButton(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => WriteReviewPage(
                                    orderItemId: item['orderItemId'],
                                    productId: item['productId'],
                                    productName: item['name'],
                                    productImage: item['image'],
                                  ),
                                ),
                              );
                              if (result == true && context.mounted) {
                                context.read<ReviewCubit>().loadMyReviewsData();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: cs.primary,
                              foregroundColor: cs.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(32),
                              ),
                            ),
                            child: const Text(
                              'VIẾT ĐÁNH GIÁ',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompletedTab(BuildContext context, List<dynamic> reviews) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final Color borderCol = cs.outlineVariant;
    final Color textHigh = cs.onSurface;
    final Color textMid = cs.onSurfaceVariant;
    final Color textLow = cs.onSurfaceVariant.withValues(alpha: 0.6);
    final Color fillCol = cs.surfaceContainerHighest;

    if (reviews.isEmpty) {
      return _buildEmptyState(
        icon: LucideIcons.messageSquare,
        message: 'LỊCH SỬ TRỐNG',
        subMessage: 'Bạn chưa thực hiện đánh giá nào cho các đơn hàng.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: reviews.length,
      separatorBuilder: (_, __) =>
          Divider(height: 64, color: borderCol.withValues(alpha: 0.5)),
      itemBuilder: (context, index) {
        final review = reviews[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(1.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: borderCol),
                  ),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: fillCol,
                    backgroundImage: review.userAvatar != null
                        ? NetworkImage(review.userAvatar!)
                        : null,
                    child: review.userAvatar == null
                        ? Text(
                            review.userName.substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: textHigh,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            review.userName.toUpperCase(),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: textHigh,
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (review.isVerifiedPurchase) ...[
                            const SizedBox(width: 6),
                            Icon(
                              Icons.verified_rounded,
                              size: 14,
                              color: cs.info,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatDate(review.createdAt).toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: textLow,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: List.generate(
                    5,
                    (starIdx) => Padding(
                      padding: const EdgeInsets.only(left: 2),
                      child: Icon(
                        starIdx < review.rating
                            ? Icons.star
                            : Icons.star_outline,
                        size: 14,
                        color: starIdx < review.rating
                            ? const Color(0xFFFFB800)
                            : textLow,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (review.variantName != null &&
                review.variantName!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '${review.variantName!.toUpperCase()}',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: textMid,
                  letterSpacing: 1.0,
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (review.comment != null && review.comment!.isNotEmpty) ...[
              Text(
                review.comment!,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: textMid,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (review.images.isNotEmpty) ...[
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: review.images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, imgIdx) => Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderCol),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: CachedNetworkImage(
                      imageUrl: review.images[imgIdx],
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (review.reply != null && review.reply!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderCol),
                ),
                child: ShopReplyWidget(reply: review.reply!),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildEmptyState({
    IconData? icon,
    String? lottieAsset,
    required String message,
    required String subMessage,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final Color cardBg = theme.cardColor;
    final Color borderCol = cs.outlineVariant;
    final Color textHigh = cs.onSurface;
    final Color textLow = cs.onSurfaceVariant.withValues(alpha: 0.6);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (lottieAsset != null)
              Lottie.asset(
                lottieAsset,
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              )
            else if (icon != null)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: borderCol),
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: textLow.withValues(alpha: 0.5),
                ),
              ),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: textHigh,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: textLow,
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
