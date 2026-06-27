import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
import 'package:mobile/src/core/di/injection.dart';
import 'package:mobile/src/core/theme/app_theme.dart';
import 'package:mobile/src/shared/widgets/glassmorphic_header.dart';
import 'package:mobile/src/features/chat/presentation/pages/concierge_screen.dart';
import 'package:mobile/src/features/chat/presentation/state/concierge_cubit.dart';
import 'package:mobile/src/features/profile/presentation/pages/order_history_page.dart';
import 'package:mobile/src/features/promotions/presentation/pages/promotions_page.dart';
import 'package:mobile/src/features/home/presentation/pages/main_screen.dart';
import 'package:mobile/src/shared/widgets/error_illustration_widget.dart';
import '../widgets/notification_tile.dart';
import '../state/notification_cubit.dart';
import '../state/notification_state.dart';
import '../../data/models/notification_model.dart';

class NotificationCenterPage extends StatefulWidget {
  const NotificationCenterPage({super.key});

  @override
  State<NotificationCenterPage> createState() => _NotificationCenterPageState();
}

class _NotificationCenterPageState extends State<NotificationCenterPage> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;
  String _selectedTab = 'ALL';

  final List<(String type, String label, IconData icon)> _tabs = const [
    ('ALL', 'Tất cả', LucideIcons.bell),
    ('ORDER', 'Đơn hàng', LucideIcons.package),
    ('PROMOTION', 'Ưu đãi', LucideIcons.ticket),
    ('SYSTEM', 'Hệ thống', LucideIcons.shieldAlert),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<NotificationCubit>().loadNotifications(type: _selectedTab);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<NotificationCubit>().loadMoreNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Builder(
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Stack(
            children: [
              //danh sách thông báo chính
              RefreshIndicator(
                color: cs.primary,
                backgroundColor: cs.surfaceContainerHighest,
                edgeOffset: topPadding + 120,
                onRefresh: () async {
                  await context.read<NotificationCubit>().loadNotifications(
                    type: _selectedTab,
                  );
                },
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(
                      child: SizedBox(height: topPadding + 130),
                    ),

                    //danh sách chính hoặc các trạng thái khác
                    BlocBuilder<NotificationCubit, NotificationState>(
                      builder: (context, state) {
                        if (state is NotificationInitial ||
                            state is NotificationLoading) {
                          return SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => _buildShimmerTile(),
                              childCount: 6,
                            ),
                          );
                        }

                        if (state is NotificationError) {
                          return SliverFillRemaining(
                            hasScrollBody: false,
                            child: _buildErrorPlaceholder(
                              context,
                              state.message,
                            ),
                          );
                        }

                        if (state is NotificationLoaded) {
                          final notifications = state.notifications;

                          if (notifications.isEmpty) {
                            return SliverFillRemaining(
                              hasScrollBody: false,
                              child: _buildEmptyPlaceholder(context),
                            );
                          }

                          return SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                if (index >= notifications.length) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    child: Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                final noti = notifications[index];
                                return NotificationTile(
                                  notification: noti,
                                  onTap: () =>
                                      _handleNotificationTap(context, noti),
                                  onDelete: () {
                                    context
                                        .read<NotificationCubit>()
                                        .deleteNotification(noti.id);
                                  },
                                );
                              },
                              childCount: state.hasReachedMax
                                  ? notifications.length
                                  : notifications.length + 1,
                            ),
                          );
                        }

                        return const SliverToBoxAdapter(
                          child: SizedBox.shrink(),
                        );
                      },
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 50)),
                  ],
                ),
              ),

              _buildHeader(context),
              _buildTabs(context, topPadding),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return GlassmorphicHeader(
      scrollOffset: _scrollOffset,
      title: 'Thông báo',
      onBack: () => Navigator.of(context).pop(),
      actions: [
        //mark all read
        BlocBuilder<NotificationCubit, NotificationState>(
          builder: (context, state) {
            final hasUnread =
                state is NotificationLoaded && state.unreadCount > 0;
            return HeaderIconButton(
              icon: Icons.done_all_rounded,
              color: hasUnread
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              onTap: () {
                if (!hasUnread) return;
                HapticFeedback.lightImpact();
                _confirmMarkAllRead(context);
              },
            );
          },
        ),
        //clear all
        BlocBuilder<NotificationCubit, NotificationState>(
          builder: (context, state) {
            final hasNotifications =
                state is NotificationLoaded &&
                state.notifications.isNotEmpty;
            return HeaderIconButton(
              icon: LucideIcons.trash2,
              color: hasNotifications
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              onTap: () {
                if (!hasNotifications) return;
                HapticFeedback.lightImpact();
                _confirmClearAll(context);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildTabs(BuildContext context, double topPadding) {
    return Positioned(
      top: topPadding + 60,
      left: 0,
      right: 0,
      child: Container(
        height: 60,
        width: double.infinity,
        color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: _tabs
                .map((tab) => _buildTabChip(context, tab))
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildTabChip(
    BuildContext context,
    (String type, String label, IconData icon) tab,
  ) {
    final isSelected = _selectedTab == tab.$1;

    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Row(
          children: [
            Icon(
              tab.$3,
              size: 14,
              color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(tab.$2),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            HapticFeedback.selectionClick();
            setState(() {
              _selectedTab = tab.$1;
            });
            context.read<NotificationCubit>().loadNotifications(type: tab.$1);
          }
        },
        selectedColor: cs.primary,
        backgroundColor: cs.surfaceContainerHighest,
        disabledColor: Colors.transparent,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
          color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected ? Colors.transparent : cs.outlineVariant,
            width: 1,
          ),
        ),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      ),
    );
  }

  Widget _buildShimmerTile() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant, width: 0.5),
        ),
      ),
      child: Shimmer.fromColors(
        baseColor: cs.onSurface.withValues(alpha: 0.05),
        highlightColor: cs.onSurface.withValues(alpha: 0.02),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 100,
                        height: 16,
                        color: cs.surfaceContainerHighest,
                      ),
                      Container(
                        width: 50,
                        height: 12,
                        color: cs.surfaceContainerHighest,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 12,
                    color: cs.surfaceContainerHighest,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 150,
                    height: 12,
                    color: cs.surfaceContainerHighest,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPlaceholder(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                shape: BoxShape.circle,
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Icon(
                LucideIcons.bellOff,
                size: 48,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Không có thông báo nào',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Các cập nhật về đơn hàng, khuyến mãi và thông báo tài khoản của bạn sẽ xuất hiện ở đây.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder(BuildContext context, String message) {
    return ErrorIllustrationWidget(
      message: message,
      onRetry: () {
        context.read<NotificationCubit>().loadNotifications(type: _selectedTab);
      },
    );
  }

  void _handleNotificationTap(BuildContext context, NotificationModel noti) {
    // dấu đã đọc trên cubit & db
    context.read<NotificationCubit>().markAsRead(noti.id);

    //điều hướng dựa theo loại thông báo
    final type = noti.type.toUpperCase();

    if (type == 'ORDER' || type == 'PAYMENT') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const OrderHistoryPage(initialStatus: 'ALL'),
        ),
      );
    } else if (type == 'CHAT') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => getIt<ConciergeCubit>()..open(),
            child: const ConciergeScreen(),
          ),
        ),
      );
    } else if (type == 'VOUCHER' || type == 'PROMOTION') {
      final mainState = context.findAncestorStateOfType<MainScreenState>();
      if (mainState != null) {
        Navigator.of(context).pop();
        mainState.onItemTapped(3);
      } else {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const PromotionsPage()));
      }
    } else {
      _showSystemDetailBottomSheet(context, noti);
    }
  }

  void _showSystemDetailBottomSheet(
    BuildContext context,
    NotificationModel noti,
  ) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border(top: BorderSide(color: cs.outlineVariant)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cs.info.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.shieldAlert,
                    color: cs.info,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    noti.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              noti.body,
              style: TextStyle(
                fontSize: 14,
                color: cs.onSurfaceVariant,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.surfaceContainerHighest,
                  foregroundColor: cs.onSurface,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: cs.outlineVariant),
                  ),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Đã hiểu',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmMarkAllRead(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: cs.outlineVariant),
        ),
        title: Text(
          'Đọc tất cả',
          style: TextStyle(fontWeight: FontWeight.w900, color: cs.onSurface),
        ),
        content: Text(
          'Bạn muốn đánh dấu tất cả các thông báo là đã đọc?',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: Text('Hủy', style: TextStyle(color: cs.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dCtx);
              context.read<NotificationCubit>().markAllAsRead();
            },
            child: Text(
              'Đồng ý',
              style: TextStyle(color: cs.primary, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmClearAll(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: cs.outlineVariant),
        ),
        title: Text(
          'Xóa tất cả',
          style: TextStyle(fontWeight: FontWeight.w900, color: cs.onSurface),
        ),
        content: Text(
          'Hành động này sẽ xóa sạch toàn bộ lịch sử thông báo của bạn. Bạn chắc chắn chứ?',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: Text('Hủy', style: TextStyle(color: cs.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dCtx);
              context.read<NotificationCubit>().clearAllNotifications();
            },
            child: Text(
              'Xóa sạch',
              style: TextStyle(color: cs.error, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
