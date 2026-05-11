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
    const textHigh = Color(0xFFF1F1F5);
    const textLow = Color(0xFF9191A8);

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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.05),
              width: 0.8,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'QUẢN LÝ ĐƠN HÀNG',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: textHigh,
                      letterSpacing: 1.5,
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
                    child: const Icon(
                      LucideIcons.chevronRight,
                      size: 14,
                      color: textLow,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildHubItem(
                    context,
                    LucideIcons.wallet,
                    'XÁC NHẬN',
                    'PENDING',
                    pendingCount,
                  ),
                  _buildHubItem(
                    context,
                    LucideIcons.package,
                    'XỬ LÝ',
                    'PROCESSING',
                    processingCount,
                  ),
                  _buildHubItem(
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

                        return _buildHubItem(
                          context,
                          LucideIcons.star,
                          'ĐÁNH GIÁ',
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

  Widget _buildHubItem(
    BuildContext context,
    IconData icon,
    String label,
    String status,
    int count, {
    VoidCallback? onTap,
  }) {
    const accent = Color(0xFF3B82F6);

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
      child: Container(
        color: Colors.transparent,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: count > 0
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.15),
                ),
                if (count > 0)
                  Positioned(
                    top: -6,
                    right: -10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.3),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        count.toString(),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
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
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: count > 0
                    ? Colors.white.withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.15),
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
