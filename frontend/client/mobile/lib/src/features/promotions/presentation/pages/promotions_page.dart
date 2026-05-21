import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/core/di/injection.dart';
import 'package:mobile/src/core/theme/app_colors.dart';
import 'package:mobile/src/features/chat/presentation/widgets/concierge_entry_button.dart';
import 'package:mobile/src/features/promotions/data/models/reward_points_model.dart';
import 'package:mobile/src/features/promotions/data/models/voucher_model.dart';
import 'package:mobile/src/features/promotions/presentation/state/promotions_cubit.dart';
import 'package:mobile/src/features/promotions/presentation/state/promotions_state.dart';
import 'package:mobile/src/shared/widgets/glassmorphic_header.dart';

const _bg = Color(0xFF070708);
const _surface = Color(0xFF121216);
const _surfaceSoft = Color(0xFF19191F);
const _border = Color(0xFF2A2A31);

const _champagne = Color(0xFFD8B76A);
const _champagneSoft = Color(0xFFE7D4A2);
const _silver = Color(0xFFB8BDC7);
const _diamond = Color(0xFFA8D8FF);

const _textHigh = Color(0xFFF4F1EA);
const _textMid = Color(0xFFB6B2A8);
const _textLow = Color(0xFF77736A);

class PromotionsPage extends StatefulWidget {
  const PromotionsPage({super.key});

  @override
  State<PromotionsPage> createState() => _PromotionsPageState();
}

class _PromotionsPageState extends State<PromotionsPage> {
  final ScrollController _scrollController = ScrollController();

  double _scrollOffset = 0.0;
  String _selectedCategory = 'TẤT CẢ';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    if (!mounted) return;
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  List<VoucherModel> _getFilteredVouchers(
    List<VoucherModel> vouchers,
    String category,
  ) {
    if (category == 'TẤT CẢ') return vouchers;

    final cat = category.toLowerCase();

    return vouchers.where((v) {
      final name = v.name.toLowerCase();
      final code = v.code.toLowerCase();

      if (cat == 'giao hàng') {
        return name.contains('ship') ||
            name.contains('vận chuyển') ||
            name.contains('giao hàng') ||
            code.contains('ship');
      }

      if (cat == 'thiết bị') {
        return name.contains('tech') ||
            name.contains('laptop') ||
            name.contains('tai nghe') ||
            name.contains('bàn phím') ||
            name.contains('chuột') ||
            name.contains('màn hình') ||
            code.contains('tech');
      }

      if (cat == 'thành viên') {
        return name.contains('vip') ||
            name.contains('member') ||
            name.contains('thành viên') ||
            name.contains('gold') ||
            name.contains('kim cương') ||
            code.contains('vip');
      }

      return true;
    }).toList();
  }

  Future<void> _handleClaim(BuildContext context, String voucherId) async {
    HapticFeedback.lightImpact();

    try {
      await context.read<PromotionsCubit>().claimVoucher(voucherId);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(LucideIcons.circleCheck, color: AppColors.success, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Đã lưu ưu đãi vào ví của bạn.',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF101A12),
          behavior: SnackBarBehavior.floating,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.success.withValues(alpha: 0.25)),
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      String errorMsg = 'Không thể lưu ưu đãi lúc này.';

      if (e is DioException && e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map && data['message'] != null) {
          errorMsg = data['message'].toString();
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                LucideIcons.circleAlert,
                color: AppColors.error,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  errorMsg,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1B0F0F),
          behavior: SnackBarBehavior.floating,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.error.withValues(alpha: 0.25)),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PromotionsCubit>()..loadData(),
      child: Scaffold(
        backgroundColor: _bg,
        body: Stack(
          children: [
            BlocBuilder<PromotionsCubit, PromotionsState>(
              builder: (context, state) {
                if (state is PromotionsInitial || state is PromotionsLoading) {
                  return _buildLoadingView();
                }

                if (state is PromotionsError) {
                  return _buildErrorView(context, state.message);
                }

                if (state is PromotionsLoaded) {
                  final filteredVouchers = _getFilteredVouchers(
                    state.vouchers,
                    _selectedCategory,
                  );

                  return RefreshIndicator(
                    onRefresh: () => context.read<PromotionsCubit>().loadData(),
                    color: _champagne,
                    backgroundColor: _surface,
                    child: CustomScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      slivers: [
                        const SliverToBoxAdapter(child: SizedBox(height: 104)),

                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          sliver: SliverToBoxAdapter(
                            child: _MembershipCard(points: state.rewardPoints),
                          ),
                        ),

                        const SliverToBoxAdapter(child: SizedBox(height: 28)),

                        const SliverPadding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          sliver: SliverToBoxAdapter(
                            child: _SectionHeader(
                              eyebrow: 'MEMBER PRIVILEGES',
                              title: 'Đặc quyền dành cho bạn',
                              subtitle:
                                  'Các quyền lợi được tuyển chọn theo hạng thành viên.',
                            ),
                          ),
                        ),

                        const SliverToBoxAdapter(child: SizedBox(height: 14)),

                        const SliverToBoxAdapter(child: _PrivilegeStrip()),

                        const SliverToBoxAdapter(child: SizedBox(height: 32)),

                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          sliver: SliverToBoxAdapter(
                            child: _SectionHeader(
                              eyebrow: 'CURATED OFFERS',
                              title: 'Ưu đãi hiện có',
                              subtitle:
                                  'Lưu voucher phù hợp trước khi hoàn tất đơn hàng.',
                              trailing: '${filteredVouchers.length}',
                            ),
                          ),
                        ),

                        const SliverToBoxAdapter(child: SizedBox(height: 16)),

                        SliverToBoxAdapter(
                          child: _CategoryFilter(
                            selectedCategory: _selectedCategory,
                            onCategoryChanged: (cat) {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _selectedCategory = cat;
                              });
                            },
                          ),
                        ),

                        const SliverToBoxAdapter(child: SizedBox(height: 18)),

                        if (filteredVouchers.isEmpty)
                          _buildEmptyVouchers()
                        else
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                i,
                              ) {
                                final voucher = filteredVouchers[i];

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: _PrivilegeVoucherCard(
                                    voucher: voucher,
                                    isClaiming: state.claimingIds.contains(
                                      voucher.id,
                                    ),
                                    isClaimed: state.claimedIds.contains(
                                      voucher.id,
                                    ),
                                    onClaim: () =>
                                        _handleClaim(context, voucher.id),
                                  ),
                                );
                              }, childCount: filteredVouchers.length),
                            ),
                          ),

                        const SliverToBoxAdapter(child: SizedBox(height: 120)),
                      ],
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
            GlassmorphicHeader(
              scrollOffset: _scrollOffset,
              title: 'Ưu đãi',
              isTransparentAtTop: false,
              actions: const [ConciergeEntryButton(compact: true)],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 104)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: Container(
              height: 210,
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: _border),
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 26)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, index) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _buildSkeletonCard(),
              ),
              childCount: 4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      height: 112,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 82,
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.035),
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 18),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _skeletonLine(width: 92, height: 10),
                  const SizedBox(height: 10),
                  _skeletonLine(width: 180, height: 14),
                  const SizedBox(height: 10),
                  _skeletonLine(width: 130, height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _skeletonLine({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: _surface,
                shape: BoxShape.circle,
                border: Border.all(color: _border),
              ),
              child: const Icon(
                LucideIcons.triangleAlert,
                color: AppColors.error,
                size: 30,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Không thể tải ưu đãi',
              style: TextStyle(
                color: _textHigh,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                color: _textLow,
                fontSize: 13,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _PressableButton(
              onTap: () => context.read<PromotionsCubit>().loadData(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: _champagne,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'THỬ LẠI',
                  style: TextStyle(
                    color: Color(0xFF17130A),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyVouchers() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: _surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: _border),
                ),
                child: const Center(
                  child: Icon(LucideIcons.ticket, color: _textLow, size: 28),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Chưa có ưu đãi phù hợp',
                style: TextStyle(
                  color: _textHigh,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Các đặc quyền mới sẽ được cập nhật trong thời gian tới.',
                style: TextStyle(color: _textLow, fontSize: 13, height: 1.45),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final String? trailing;

  const _SectionHeader({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: const TextStyle(
                  color: _champagne,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  color: _textHigh,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _textLow,
                  fontSize: 12,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: _border),
            ),
            child: Text(
              trailing!,
              style: const TextStyle(
                color: _textMid,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }
}

class _MembershipCard extends StatelessWidget {
  final RewardPointsModel? points;

  const _MembershipCard({required this.points});

  @override
  Widget build(BuildContext context) {
    final rewardPoints = points?.rewardPoints ?? 0;
    final formatted = NumberFormat('#,###').format(rewardPoints);
    final tier = points?.tierName ?? 'BẠC';
    final progress = (points?.tierProgress ?? 0.0).clamp(0.0, 1.0);

    final style = _TierStyle.fromTier(tier);

    return Container(
      height: 216,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: style.gradient,
        border: Border.all(color: style.color.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: Stack(
          children: [
            Positioned(
              right: -64,
              top: -84,
              child: _SoftOrb(color: style.color),
            ),
            Positioned(
              left: -80,
              bottom: -100,
              child: _SoftOrb(
                color: Colors.white.withValues(alpha: 0.18),
                size: 170,
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _SubtleLinesPainter(
                  color: Colors.white.withValues(alpha: 0.045),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _TierPill(tier: tier, color: style.color),
                      const Spacer(),
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.055),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.11),
                          ),
                        ),
                        child: Icon(
                          LucideIcons.gem,
                          color: style.color,
                          size: 17,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Text(
                    'REWARDS BALANCE',
                    style: TextStyle(
                      color: _textLow,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.55,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatted,
                        style: const TextStyle(
                          color: _textHigh,
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.0,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          'điểm',
                          style: TextStyle(
                            color: style.color,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 5,
                      backgroundColor: Colors.white.withValues(alpha: 0.09),
                      valueColor: AlwaysStoppedAnimation<Color>(style.color),
                    ),
                  ),
                  const SizedBox(height: 11),
                  const Text(
                    'Tích điểm sau mỗi đơn hàng để mở thêm đặc quyền thành viên.',
                    style: TextStyle(
                      color: _textLow,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TierStyle {
  final Color color;
  final Gradient gradient;

  const _TierStyle({required this.color, required this.gradient});

  factory _TierStyle.fromTier(String tier) {
    switch (tier.toUpperCase()) {
      case 'VÀNG':
        return const _TierStyle(
          color: _champagne,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2A2416), Color(0xFF11100C), Color(0xFF070708)],
          ),
        );
      case 'KIM CƯƠNG':
        return const _TierStyle(
          color: _diamond,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF182431), Color(0xFF0D1118), Color(0xFF070708)],
          ),
        );
      case 'VIP':
        return const _TierStyle(
          color: Color(0xFFFDE047),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2E2810), Color(0xFF15120A), Color(0xFF070708)],
          ),
        );
      default: // BẠC
        return const _TierStyle(
          color: _silver,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF23262C), Color(0xFF111217), Color(0xFF08080A)],
          ),
        );
    }
  }
}

class _TierPill extends StatelessWidget {
  final String tier;
  final Color color;

  const _TierPill({required this.tier, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.shieldCheck, color: color, size: 14),
          const SizedBox(width: 8),
          Text(
            tier.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftOrb extends StatelessWidget {
  final Color color;
  final double size;

  const _SoftOrb({required this.color, this.size = 210});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.18),
            blurRadius: 90,
            spreadRadius: 20,
          ),
        ],
      ),
    );
  }
}

class _PrivilegeStrip extends StatelessWidget {
  const _PrivilegeStrip();

  @override
  Widget build(BuildContext context) {
    final items = [
      const _PrivilegeItem(
        icon: LucideIcons.truck,
        title: 'Priority Delivery',
        subtitle: 'Ưu tiên giao hàng cho đơn đủ điều kiện',
      ),
      const _PrivilegeItem(
        icon: LucideIcons.headphones,
        title: 'Concierge Support',
        subtitle: 'Hỗ trợ tư vấn sản phẩm cao cấp',
      ),
      const _PrivilegeItem(
        icon: LucideIcons.badgePercent,
        title: 'Member Pricing',
        subtitle: 'Giá riêng cho thành viên thân thiết',
      ),
    ];

    return SizedBox(
      height: 142,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, index) => items[index],
      ),
    );
  }
}

class _PrivilegeItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _PrivilegeItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 178,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _champagne.withValues(alpha: 0.09),
              shape: BoxShape.circle,
              border: Border.all(color: _champagne.withValues(alpha: 0.18)),
            ),
            child: Icon(icon, color: _champagneSoft, size: 17),
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              color: _textHigh,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: _textLow,
              fontSize: 11,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;

  const _CategoryFilter({
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final categories = ['TẤT CẢ', 'GIAO HÀNG', 'THIẾT BỊ', 'THÀNH VIÊN'];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedCategory == category;

          return _PressableButton(
            onTap: () => onCategoryChanged(category),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? _champagne : _surface,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: isSelected ? _champagne : _border),
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF15120A) : _textMid,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.45,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PrivilegeVoucherCard extends StatelessWidget {
  final VoucherModel voucher;
  final bool isClaiming;
  final bool isClaimed;
  final VoidCallback onClaim;

  const _PrivilegeVoucherCard({
    required this.voucher,
    required this.isClaiming,
    required this.isClaimed,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final accent = voucher.isPercent ? _champagne : _silver;
    final icon = voucher.isPercent
        ? LucideIcons.badgePercent
        : LucideIcons.truck;
    final expiryText = _formatExpiry(voucher.expiresAt);

    return _PressableButton(
      onTap: (isClaimed || isClaiming) ? null : onClaim,
      child: CustomPaint(
        painter: _VoucherPainter(
          leftWidth: 82,
          bgColor: _surface,
          leftColor: _surfaceSoft,
          borderColor: isClaimed
              ? AppColors.success.withValues(alpha: 0.36)
              : _border,
          dividerColor: Colors.white.withValues(alpha: 0.08),
          notchColor: _bg,
          notchRadius: 8,
          cornerRadius: 24,
        ),
        child: SizedBox(
          height: 116,
          child: Row(
            children: [
              SizedBox(
                width: 82,
                child: Center(
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.09),
                      shape: BoxShape.circle,
                      border: Border.all(color: accent.withValues(alpha: 0.2)),
                    ),
                    child: Icon(icon, color: accent, size: 19),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.09),
                                borderRadius: BorderRadius.circular(99),
                                border: Border.all(
                                  color: accent.withValues(alpha: 0.16),
                                ),
                              ),
                              child: Text(
                                voucher.code,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: accent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.75,
                                ),
                              ),
                            ),
                          ),
                          if (isClaimed) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(99),
                                border: Border.all(
                                  color: AppColors.success.withValues(
                                    alpha: 0.18,
                                  ),
                                ),
                              ),
                              child: const Text(
                                'ĐÃ LƯU',
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        voucher.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _textHigh,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.15,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        voucher.summaryText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _textMid,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          height: 1.25,
                        ),
                      ),
                      const Spacer(),
                      if (expiryText != null)
                        Row(
                          children: [
                            const Icon(
                              LucideIcons.clock3,
                              color: _textLow,
                              size: 12,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              expiryText,
                              style: const TextStyle(
                                color: _textLow,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: _ClaimButton(
                  isClaiming: isClaiming,
                  isClaimed: isClaimed,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _formatExpiry(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    final parsed = DateTime.tryParse(value);
    if (parsed == null) return null;

    return 'Hạn dùng ${DateFormat('dd/MM/yyyy').format(parsed)}';
  }
}

class _ClaimButton extends StatelessWidget {
  final bool isClaiming;
  final bool isClaimed;

  const _ClaimButton({required this.isClaiming, required this.isClaimed});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: 56,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isClaimed
            ? AppColors.success.withValues(alpha: 0.1)
            : isClaiming
            ? _champagne.withValues(alpha: 0.16)
            : _champagne,
        borderRadius: BorderRadius.circular(14),
        border: isClaimed
            ? Border.all(color: AppColors.success.withValues(alpha: 0.28))
            : null,
      ),
      child: isClaiming
          ? const SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _champagne,
              ),
            )
          : isClaimed
          ? const Icon(LucideIcons.check, color: AppColors.success, size: 17)
          : const Text(
              'LƯU',
              style: TextStyle(
                color: Color(0xFF161207),
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.55,
              ),
            ),
    );
  }
}

class _VoucherPainter extends CustomPainter {
  final double leftWidth;
  final Color bgColor;
  final Color leftColor;
  final Color borderColor;
  final Color dividerColor;
  final Color notchColor;
  final double notchRadius;
  final double cornerRadius;

  const _VoucherPainter({
    required this.leftWidth,
    required this.bgColor,
    required this.leftColor,
    required this.borderColor,
    required this.dividerColor,
    required this.notchColor,
    required this.notchRadius,
    required this.cornerRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildPath(size);

    canvas.drawPath(path, Paint()..color = bgColor);

    canvas.save();
    canvas.clipPath(path);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, leftWidth, size.height),
      Paint()..color = leftColor,
    );
    canvas.restore();

    canvas.drawCircle(
      Offset(leftWidth, -0.5),
      notchRadius,
      Paint()..color = notchColor,
    );
    canvas.drawCircle(
      Offset(leftWidth, size.height + 0.5),
      notchRadius,
      Paint()..color = notchColor,
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    final dashPaint = Paint()
      ..color = dividerColor
      ..strokeWidth = 1;

    const dash = 4.5;
    const gap = 4.0;

    double y = notchRadius + 6;
    final endY = size.height - notchRadius - 6;

    while (y < endY) {
      canvas.drawLine(
        Offset(leftWidth, y),
        Offset(leftWidth, math.min(y + dash, endY)),
        dashPaint,
      );
      y += dash + gap;
    }
  }

  Path _buildPath(Size size) {
    final r = cornerRadius;

    return Path()
      ..moveTo(r, 0)
      ..lineTo(size.width - r, 0)
      ..arcToPoint(Offset(size.width, r), radius: Radius.circular(r))
      ..lineTo(size.width, size.height - r)
      ..arcToPoint(
        Offset(size.width - r, size.height),
        radius: Radius.circular(r),
      )
      ..lineTo(r, size.height)
      ..arcToPoint(Offset(0, size.height - r), radius: Radius.circular(r))
      ..lineTo(0, r)
      ..arcToPoint(Offset(r, 0), radius: Radius.circular(r))
      ..close();
  }

  @override
  bool shouldRepaint(_VoucherPainter oldDelegate) {
    return oldDelegate.borderColor != borderColor ||
        oldDelegate.bgColor != bgColor ||
        oldDelegate.leftColor != leftColor;
  }
}

class _SubtleLinesPainter extends CustomPainter {
  final Color color;

  const _SubtleLinesPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    for (double x = -size.height; x < size.width; x += 32) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SubtleLinesPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _PressableButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _PressableButton({required this.child, this.onTap});

  @override
  State<_PressableButton> createState() => _PressableButtonState();
}

class _PressableButtonState extends State<_PressableButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 110),
    lowerBound: 0.0,
    upperBound: 0.035,
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null ? null : (_) => _ctrl.forward(),
      onTapCancel: widget.onTap == null ? null : () => _ctrl.reverse(),
      onTapUp: widget.onTap == null
          ? null
          : (_) {
              _ctrl.reverse();
              widget.onTap?.call();
            },
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) {
          return Transform.scale(scale: 1.0 - _ctrl.value, child: child);
        },
        child: widget.child,
      ),
    );
  }
}
