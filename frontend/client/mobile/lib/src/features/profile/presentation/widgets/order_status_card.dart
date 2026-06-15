import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/src/core/di/injection.dart';
import 'package:mobile/src/features/product_review/presentation/pages/pending_reviews_page.dart';
import 'package:mobile/src/features/product_review/presentation/state/review_cubit.dart';
import 'package:mobile/src/features/product_review/presentation/state/review_state.dart';
import 'package:mobile/src/features/profile/presentation/pages/order_history_page.dart';
import 'package:mobile/src/features/profile/presentation/state/orders_cubit.dart';
import 'package:mobile/src/features/profile/presentation/state/orders_state.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class OrderStatusCard extends StatelessWidget {
  const OrderStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrdersCubit, OrdersState>(
      builder: (context, state) {
        final theme = Theme.of(context);
        final cs = theme.colorScheme;
        int pendingCount = 0;
        int processingCount = 0;
        int shippingCount = 0;

        if (state is OrdersLoaded) {
          for (final order in state.orders) {
            final String s = order['status'] ?? 'PENDING';
            if (s == 'PENDING' || s == 'CONFIRMED') {
              pendingCount++;
            } else if (s == 'PROCESSING') {
              processingCount++;
            } else if (s == 'SHIPPING') {
              shippingCount++;
            }
          }
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          decoration: BoxDecoration(
            color: cs.onSurface.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: cs.onSurface.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      'QUẢN LÝ ĐƠN HÀNG',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: cs.onSurface,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              const OrderHistoryPage(initialStatus: 'ALL'),
                        ),
                      );
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Xem tất cả',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 14,
                          color: cs.onSurface.withValues(alpha: 0.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildStatusItem(
                      context,
                      FontAwesomeIcons.solidCreditCard,
                      'Chuẩn bị',
                      'PENDING',
                      pendingCount,
                    ),
                  ),
                  Expanded(
                    child: _buildStatusItem(
                      context,
                      FontAwesomeIcons.box,
                      'Chờ xử lý',
                      'PROCESSING',
                      processingCount,
                    ),
                  ),
                  Expanded(
                    child: _buildStatusItem(
                      context,
                      FontAwesomeIcons.solidTruck,
                      'Đang giao',
                      'SHIPPING',
                      shippingCount,
                    ),
                  ),
                  Expanded(
                    child: BlocProvider(
                      create: (context) =>
                          getIt<ReviewCubit>()..loadPendingReviews(),
                      child: BlocBuilder<ReviewCubit, ReviewState>(
                        builder: (context, state) {
                          int reviewCount = 0;
                          if (state is PendingReviewsLoaded) {
                            reviewCount = state.pendingReviews.length;
                          }

                          return _buildStatusItem(
                            context,
                            FontAwesomeIcons.solidMessage,
                            'Đánh giá',
                            'REVIEWS',
                            reviewCount,
                            onTap: () {
                              Navigator.of(context)
                                  .push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const PendingReviewsPage(),
                                    ),
                                  )
                                  .then((_) {
                                    if (context.mounted) {
                                      context
                                          .read<ReviewCubit>()
                                          .loadPendingReviews();
                                    }
                                  });
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusItem(
    BuildContext context,
    dynamic icon,
    String label,
    String status,
    int count, {
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bool isActive = count > 0;

    return GestureDetector(
      onTap:
          onTap ??
          () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => OrderHistoryPage(initialStatus: status),
              ),
            );
          },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isActive
                      ? cs.primary.withValues(alpha: 0.06)
                      : cs.onSurface.withValues(alpha: 0.02),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isActive
                        ? cs.primary.withValues(alpha: 0.12)
                        : cs.onSurface.withValues(alpha: 0.04),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: FaIcon(
                    icon,
                    size: 18,
                    color: isActive
                        ? cs.primary
                        : cs.onSurface.withValues(alpha: 0.3),
                  ),
                ),
              ),
              if (isActive)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: cs.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.scaffoldBackgroundColor,
                        width: 1.5,
                      ),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Center(
                      child: Text(
                        count.toString(),
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          color: cs.onPrimary,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isActive
                  ? cs.onSurface
                  : cs.onSurface.withValues(alpha: 0.3),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
