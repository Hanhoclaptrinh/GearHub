import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/core/utils/formatter_utils.dart';
import '../../../../core/di/injection.dart';
import '../../../auth/presentation/state/auth_cubit.dart';
import '../../../auth/presentation/state/auth_state.dart';
import '../../../product_detail/presentation/pages/write_review_page.dart';
import '../state/review_cubit.dart';
import '../state/review_state.dart';
import '../widgets/shop_reply_widget.dart';

const _bg = Color(0xFF07070A);
const _surface = Color(0xFF0E0E14);
const _surfaceAlt = Color(0xFF161621);
const _border = Color(0xFF1F1F2C);
const _accent = Color(0xFFE2B93B);
const _starColor = Color(0xFFFFB800);
const _textHigh = Color(0xFFFFFFFF);
const _textMid = Color(0xFF9494A1);
const _textLow = Color(0xFF5A5A6E);

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
    return BlocProvider(
      create: (context) => getIt<ReviewCubit>()..loadMyReviewsData(),
      child: Scaffold(
        backgroundColor: _bg,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: _bg.withValues(alpha: 0.8),
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          title: const Text(
            'Lịch sử đánh giá',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _textHigh,
            ),
          ),
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
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
                  color: _accent,
                  strokeWidth: 2,
                ),
              );
            } else if (state is ReviewError) {
              return Center(
                child: Text(
                  state.message,
                  style: const TextStyle(color: _textMid),
                ),
              );
            } else if (state is MyReviewsState) {
              return Column(
                children: [
                  const SizedBox(height: 100),
                  _buildHeader(context, state),
                  const SizedBox(height: 24),
                  _buildTabBar(),
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

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.black,
        unselectedLabelColor: _textMid,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
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
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        if (authState is AuthAuthenticated) {
          final user = authState.user;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _accent.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: _surfaceAlt,
                        backgroundImage: user.avatarUrl != null
                            ? CachedNetworkImageProvider(user.avatarUrl!)
                            : null,
                        child: user.avatarUrl == null
                            ? Text(
                                (user.fullName ?? user.email)
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: _accent,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName ?? 'KHÁCH HÀNG',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: _textHigh,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_outline,
                            size: 15,
                            color: _starColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${state.completedReviews.length} ĐÁNH GIÁ ĐÃ VIẾT',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _accent,
                              letterSpacing: 1.0,
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
    if (items.isEmpty) {
      return _buildEmptyState(
        icon: Icons.star_outline,
        message: 'MỌI THỨ ĐÃ HOÀN TẤT',
        subMessage: 'Bạn không còn sản phẩm nào đang chờ đánh giá.',
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
            color: _surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Contained Image Composition
              Container(
                height: 170,
                width: double.infinity,
                color: _surfaceAlt,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.4,
                        child: CachedNetworkImage(
                          imageUrl: item['image'],
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CachedNetworkImage(
                            imageUrl: item['image'],
                            width: 140,
                            height: 140,
                            fit: BoxFit.contain,
                            placeholder: (context, url) =>
                                Container(color: Colors.transparent),
                            errorWidget: (context, url, error) => const Icon(
                              LucideIcons.package,
                              color: _textLow,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: _textHigh,
                        height: 1.2,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (item['variantName'] != null &&
                        item['variantName'].toString().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        item['variantName'].toString().toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _textLow,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextButton(
                            onPressed: () {
                              context.read<ReviewCubit>().skipReview(
                                item['orderItemId'],
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: _border),
                              ),
                            ),
                            child: const Text(
                              'BỎ QUA',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: _textMid,
                                letterSpacing: 1.0,
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
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'VIẾT ĐÁNH GIÁ',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
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
          Divider(height: 64, color: _border.withValues(alpha: 0.3)),
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
                    border: Border.all(color: _border),
                  ),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: _surfaceAlt,
                    backgroundImage: review.userAvatar != null
                        ? NetworkImage(review.userAvatar!)
                        : null,
                    child: review.userAvatar == null
                        ? Text(
                            review.userName.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: _textMid,
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
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _textHigh,
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (review.isVerifiedPurchase) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.verified_rounded,
                              size: 14,
                              color: Color(0xFF3B82F6),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatDate(review.createdAt).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _textLow,
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
                        color: starIdx < review.rating ? _starColor : _textLow,
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
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: _accent,
                  letterSpacing: 1.0,
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (review.comment != null && review.comment!.isNotEmpty) ...[
              Text(
                review.comment!,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: _textMid,
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
                      border: Border.all(color: _border),
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
                  color: _surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border),
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
    required IconData icon,
    required String message,
    required String subMessage,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _surface,
                shape: BoxShape.circle,
                border: Border.all(color: _border),
              ),
              child: Icon(
                icon,
                size: 40,
                color: _textLow.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: _textHigh,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: _textLow,
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
