import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/core/di/injection.dart';
import 'package:mobile/src/core/theme/app_colors.dart';
import 'package:mobile/src/core/theme/app_theme.dart';
import 'package:mobile/src/features/chat/presentation/widgets/concierge_entry_button.dart';
import 'package:mobile/src/features/promotions/data/models/voucher_model.dart';
import 'package:mobile/src/features/promotions/presentation/state/promotions_cubit.dart';
import 'package:mobile/src/features/promotions/presentation/state/promotions_state.dart';
import 'package:mobile/src/shared/widgets/glassmorphic_header.dart';
import 'package:mobile/src/shared/widgets/error_illustration_widget.dart';

class PromotionsPage extends StatefulWidget {
  const PromotionsPage({super.key});

  @override
  State<PromotionsPage> createState() => _PromotionsPageState();
}

class _PromotionsPageState extends State<PromotionsPage> {
  final ScrollController _scrollController = ScrollController();

  double _scrollOffset = 0.0;
  final String _selectedCategory = 'TẤT CẢ';

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
    final theme = Theme.of(context);

    try {
      await context.read<PromotionsCubit>().claimVoucher(voucherId);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                LucideIcons.circleCheck,
                color: theme.colorScheme.success,
                size: 18,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Đã lưu ưu đãi vào ví của bạn.',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          backgroundColor: theme.brightness == Brightness.dark
              ? const Color(0xFF101A12)
              : const Color(0xFFE8F5E9),
          behavior: SnackBarBehavior.floating,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: theme.colorScheme.success.withValues(alpha: 0.25),
            ),
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
              Icon(
                LucideIcons.circleAlert,
                color: theme.colorScheme.danger,
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
          backgroundColor: theme.brightness == Brightness.dark
              ? const Color(0xFF1B0F0F)
              : const Color(0xFFFFEBEB),
          behavior: SnackBarBehavior.floating,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: theme.colorScheme.danger.withValues(alpha: 0.25),
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocProvider(
      create: (_) => getIt<PromotionsCubit>()..loadData(),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Stack(
          children: [
            BlocBuilder<PromotionsCubit, PromotionsState>(
              builder: (context, state) {
                if (state is PromotionsInitial || state is PromotionsLoading) {
                  return _buildLoadingView(context);
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
                    color: AppColors.champagne,
                    backgroundColor: theme.colorScheme.surface,
                    child: CustomScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      slivers: [
                        const SliverToBoxAdapter(child: SizedBox(height: 104)),
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

                        const SliverToBoxAdapter(child: SizedBox(height: 18)),

                        if (filteredVouchers.isEmpty)
                          _buildEmptyVouchers(context)
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

  Widget _buildLoadingView(BuildContext context) {
    final theme = Theme.of(context);
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
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: theme.colorScheme.outlineVariant),
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
                child: _buildSkeletonCard(context),
              ),
              childCount: 4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonCard(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 112,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 82,
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.035),
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
                  _skeletonLine(context, width: 92, height: 10),
                  const SizedBox(height: 10),
                  _skeletonLine(context, width: 180, height: 14),
                  const SizedBox(height: 10),
                  _skeletonLine(context, width: 130, height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _skeletonLine(
    BuildContext context, {
    required double width,
    required double height,
  }) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, String message) {
    return ErrorIllustrationWidget(
      message: message,
      onRetry: () => context.read<PromotionsCubit>().loadData(),
    );
  }

  Widget _buildEmptyVouchers(BuildContext context) {
    final theme = Theme.of(context);
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
                  color: theme.colorScheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Center(
                  child: Icon(
                    LucideIcons.ticket,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Chưa có ưu đãi phù hợp',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Các đặc quyền mới sẽ được cập nhật trong thời gian tới.',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 13,
                  height: 1.45,
                ),
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
    final theme = Theme.of(context);
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
                  color: AppColors.champagne,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
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
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Text(
              trailing!,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
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
    final theme = Theme.of(context);
    return Container(
      width: 178,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.champagne.withValues(alpha: 0.09),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.champagne.withValues(alpha: 0.18),
              ),
            ),
            child: Icon(icon, color: AppColors.champagneSoft, size: 17),
          ),
          const Spacer(),
          Text(
            title,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
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
    final theme = Theme.of(context);
    final accent = voucher.isPercent ? AppColors.champagne : AppColors.silver;
    final icon = voucher.isPercent
        ? LucideIcons.badgePercent
        : LucideIcons.truck;
    final expiryText = _formatExpiry(voucher.expiresAt);

    return _PressableButton(
      onTap: (isClaimed || isClaiming) ? null : onClaim,
      child: CustomPaint(
        painter: _VoucherPainter(
          leftWidth: 82,
          bgColor: theme.colorScheme.surface,
          leftColor: theme.colorScheme.surfaceContainerHighest,
          borderColor: isClaimed
              ? theme.colorScheme.success.withValues(alpha: 0.36)
              : theme.colorScheme.outlineVariant,
          dividerColor: theme.colorScheme.onSurface.withValues(alpha: 0.08),
          notchColor: theme.scaffoldBackgroundColor,
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
                                color: theme.colorScheme.success.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(99),
                                border: Border.all(
                                  color: theme.colorScheme.success.withValues(
                                    alpha: 0.18,
                                  ),
                                ),
                              ),
                              child: Text(
                                'ĐÃ LƯU',
                                style: TextStyle(
                                  color: theme.colorScheme.success,
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
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
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
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
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
                              color: Colors.grey,
                              size: 12,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              expiryText,
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
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
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: 56,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isClaimed
            ? theme.colorScheme.success.withValues(alpha: 0.1)
            : isClaiming
            ? AppColors.champagne.withValues(alpha: 0.16)
            : AppColors.champagne,
        borderRadius: BorderRadius.circular(14),
        border: isClaimed
            ? Border.all(
                color: theme.colorScheme.success.withValues(alpha: 0.28),
              )
            : null,
      ),
      child: isClaiming
          ? const SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.champagne,
              ),
            )
          : isClaimed
          ? Icon(LucideIcons.check, color: theme.colorScheme.success, size: 17)
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
