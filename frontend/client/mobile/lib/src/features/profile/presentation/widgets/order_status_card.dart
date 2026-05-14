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
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'QUẢN LÝ ĐƠN HÀNG',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatusItem(
                    context,
                    LucideIcons.wallet,
                    'CHUẨN BỊ',
                    'PENDING',
                    pendingCount,
                  ),
                  _buildStatusItem(
                    context,
                    LucideIcons.package,
                    'XỬ LÝ',
                    'PROCESSING',
                    processingCount,
                  ),
                  _buildStatusItem(
                    context,
                    LucideIcons.truck,
                    'GIAO HÀNG',
                    'SHIPPING',
                    shippingCount,
                  ),
                  BlocProvider(
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
                          LucideIcons.star,
                          'PHẢN HỒI',
                          'REVIEWS',
                          reviewCount,
                          onTap: () {
                            Navigator.of(context)
                                .push(
                                  MaterialPageRoute(
                                    builder: (_) => const PendingReviewsPage(),
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
    String status,
    int count, {
    VoidCallback? onTap,
  }) {
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
      child: SizedBox(
        width: 60,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFFFDE047).withValues(alpha: 0.05)
                        : Colors.white.withValues(alpha: 0.02),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: isActive
                        ? const Color(0xFFFDE047)
                        : Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                if (isActive)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFDE047),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        count.toString(),
                        style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          height: 1,
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
                fontSize: 8,
                fontWeight: FontWeight.w800,
                color: isActive
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.2),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
