import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/core/di/injection.dart';
import 'package:mobile/src/features/product_review/presentation/pages/pending_reviews_page.dart';
import 'package:mobile/src/features/product_review/presentation/state/review_cubit.dart';
import 'package:mobile/src/features/product_review/presentation/state/review_state.dart';
import 'package:mobile/src/features/profile/presentation/pages/order_history_page.dart';
import 'package:mobile/src/features/profile/presentation/state/orders_cubit.dart';
import 'package:mobile/src/features/profile/presentation/state/orders_state.dart';

class OrderStatusCard extends StatelessWidget {
  const OrderStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrdersCubit, OrdersState>(
      builder: (context, state) {
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
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Đơn hàng của tôi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0A0A0F),
                      letterSpacing: -0.3,
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
                    child: const Text(
                      'Xem lịch sử mua hàng',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3B82F6),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatusItem(
                    context,
                    LucideIcons.wallet,
                    'Chờ xác nhận',
                    'PENDING',
                    badgeCount: pendingCount > 0
                        ? pendingCount.toString()
                        : null,
                  ),
                  _buildStatusItem(
                    context,
                    LucideIcons.package,
                    'Chờ xử lý',
                    'PROCESSING',
                    badgeCount: processingCount > 0
                        ? processingCount.toString()
                        : null,
                  ),
                  _buildStatusItem(
                    context,
                    LucideIcons.truck,
                    'Chờ giao hàng',
                    'SHIPPING',
                    badgeCount: shippingCount > 0
                        ? shippingCount.toString()
                        : null,
                  ),
                  BlocProvider(
                    create: (context) =>
                        getIt<ReviewCubit>()..loadPendingReviews(),
                    child: BlocBuilder<ReviewCubit, ReviewState>(
                      builder: (context, state) {
                        String? pendingCount;
                        if (state is PendingReviewsLoaded) {
                          pendingCount = state.pendingReviews.isNotEmpty
                              ? state.pendingReviews.length.toString()
                              : null;
                        }

                        return _buildStatusItem(
                          context,
                          LucideIcons.star,
                          'Đánh giá',
                          'PENDING_REVIEWS',
                          badgeCount: pendingCount,
                          onTap: () {
                            Navigator.of(context)
                                .push(
                                  MaterialPageRoute(
                                    builder: (_) => const PendingReviewsPage(),
                                  ),
                                )
                                .then((_) {
                                  // reload count sau khi quay lai
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
    IconData icon,
    String label,
    String status, {
    String? badgeCount,
    VoidCallback? onTap,
  }) {
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
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F5F7),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 24, color: const Color(0xFF4B5563)),
              ),
              if (badgeCount != null && badgeCount != '0')
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Text(
                      badgeCount,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}
