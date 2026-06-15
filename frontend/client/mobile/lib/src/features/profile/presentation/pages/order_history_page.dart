import 'package:lottie/lottie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/core/theme/app_colors.dart';
import 'package:mobile/src/core/di/injection.dart';
import 'package:mobile/src/core/utils/formatter_utils.dart';
import 'package:mobile/src/features/profile/presentation/state/orders_cubit.dart';
import 'package:mobile/src/features/profile/presentation/state/orders_state.dart';
import 'package:mobile/src/features/cart/presentation/state/cart_cubit.dart';
import 'package:mobile/src/features/checkout/presentation/pages/checkout_page.dart';
import 'package:mobile/src/shared/widgets/error_illustration_widget.dart';
import 'package:mobile/src/features/profile/presentation/pages/order_detail_page.dart';

double _toDouble(dynamic val) {
  if (val == null) return 0.0;
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val) ?? 0.0;
  return 0.0;
}

const _lightPageBg = Color(0xFFF5F6FA);
const _darkPageBg = Color(0xFF080A12);
const _darkCardBg = Color(0xFF12141E);
const _darkCardBorder = Color(0xFF252A3A);
const _techAccent = AppColors.gearBlue;

class OrderHistoryPage extends StatefulWidget {
  final String initialStatus;
  final String? initialOrderId;

  const OrderHistoryPage({
    super.key,
    this.initialStatus = 'ALL',
    this.initialOrderId,
  });

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<String> _expandedOrderIds = {};
  bool _hasOpenedInitialOrder = false;
  final List<Map<String, String>> _statusTabs = [
    {'label': 'Tất cả', 'status': 'ALL'},
    {'label': 'Chờ xác nhận', 'status': 'PENDING'},
    {'label': 'Đang xử lý', 'status': 'PROCESSING'},
    {'label': 'Đang giao', 'status': 'SHIPPING'},
    {'label': 'Đã giao', 'status': 'DELIVERED'},
    {'label': 'Đã hủy', 'status': 'CANCELLED'},
  ];

  @override
  void initState() {
    super.initState();
    int initialIndex = _statusTabs.indexWhere(
      (t) => t['status'] == widget.initialStatus,
    );
    if (initialIndex == -1) initialIndex = 0;

    _tabController = TabController(
      length: _statusTabs.length,
      vsync: this,
      initialIndex: initialIndex,
    );
    _tabController.addListener(_handleTabSelection);
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) return;
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pageBg = isDark ? _darkPageBg : _lightPageBg;

    return BlocProvider(
      create: (context) => getIt<OrdersCubit>()..fetchMyOrders(status: 'ALL'),
      child: Builder(
        builder: (context) {
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: isDark
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark,
            child: Scaffold(
              backgroundColor: pageBg,
              appBar: AppBar(
                backgroundColor: pageBg,
                elevation: 0,
                scrolledUnderElevation: 0,
                centerTitle: true,
                leading: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                    size: 24,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  'Lịch sử đơn hàng',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF161922),
                    letterSpacing: -0.1,
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(48),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : const Color(0xFFE6E8EF),
                        ),
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      physics: const BouncingScrollPhysics(),
                      tabAlignment: TabAlignment.start,
                      indicatorColor: _techAccent,
                      indicatorWeight: 3,
                      indicatorSize: TabBarIndicatorSize.label,
                      dividerColor: Colors.transparent,
                      labelColor: _techAccent,
                      unselectedLabelColor: isDark
                          ? Colors.white.withValues(alpha: 0.56)
                          : const Color(0xFF6B7280),
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      tabs: _statusTabs
                          .map((t) => Tab(text: t['label']))
                          .toList(),
                    ),
                  ),
                ),
              ),
              body: BlocConsumer<OrdersCubit, OrdersState>(
                listener: (context, state) {
                  if (state is OrderActionSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: const Color(0xFF10B981),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else if (state is ReorderSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: const Color(0xFF10B981),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    _handleReorderSuccess(context, state.variantIds);
                  }
                },
                builder: (context, state) {
                  if (state is OrdersLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.brandIndigo,
                      ),
                    );
                  }

                  if (state is OrdersLoaded) {
                    final orders = state.orders;

                    if (widget.initialOrderId != null &&
                        !_hasOpenedInitialOrder) {
                      _hasOpenedInitialOrder = true;
                      dynamic matchingOrder;
                      for (var o in orders) {
                        if (o['id'] == widget.initialOrderId) {
                          matchingOrder = o;
                          break;
                        }
                      }
                      if (matchingOrder != null) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _navigateToOrderDetail(context, matchingOrder);
                        });
                      }
                    }

                    return TabBarView(
                      controller: _tabController,
                      physics: const BouncingScrollPhysics(),
                      children: _statusTabs.map((tab) {
                        final filteredOrders = _filterOrdersForStatus(
                          orders,
                          tab['status']!,
                        );
                        return _buildOrdersTab(context, filteredOrders);
                      }).toList(),
                    );
                  }

                  if (state is OrdersError) {
                    return ErrorIllustrationWidget(
                      message: state.message,
                      onRetry: () => context.read<OrdersCubit>().fetchMyOrders(
                        status: 'ALL',
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          );
        },
      ),
    );
  }

  List<dynamic> _filterOrdersForStatus(List<dynamic> orders, String tabStatus) {
    return orders.where((order) {
      if (tabStatus == 'ALL') return true;
      final String status = order['status'] ?? 'PENDING';
      if (tabStatus == 'PENDING') {
        return status == 'PENDING' || status == 'CONFIRMED';
      }
      if (tabStatus == 'DELIVERED') {
        return status == 'DELIVERED' || status == 'COMPLETED';
      }
      return status == tabStatus;
    }).toList();
  }

  Widget _buildOrdersTab(BuildContext context, List<dynamic> orders) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      color: _techAccent,
      backgroundColor: isDark ? _darkCardBg : Colors.white,
      onRefresh: () async {
        await context.read<OrdersCubit>().fetchMyOrders(status: 'ALL');
      },
      child: orders.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return _buildOrderCard(context, order);
              },
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.22),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/animations/emptyorder.json',
                width: 200,
                height: 200,
              ),
              const SizedBox(height: 28),
              Text(
                'Góc này đang chờ chốt đơn!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: cs.onSurface,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Góc sáng tạo của fen vẫn chưa có gear mới à? Đi dạo một vòng Hub và chốt đơn ngay thôi fen!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderCard(BuildContext context, dynamic order) {
    final String status = order['status'] ?? 'PENDING';
    final String paymentMethod = order['paymentMethod'] ?? '';
    final String paymentStatus = order['paymentStatus'] ?? '';
    final bool isPaidGateway =
        paymentMethod == 'PAYMENT_GATEWAY' && paymentStatus == 'PAID';
    final List<dynamic> trackingList = order['tracking'] ?? [];
    final String? latestStatusLabel = trackingList.isNotEmpty
        ? trackingList.first['statusLabel']
        : null;
    final List<dynamic> items = order['items'] ?? [];
    double totalAmount = _toDouble(order['totalAmount'] ?? order['total']);
    if (totalAmount == 0.0) {
      totalAmount = items.fold(0.0, (sum, i) {
        final price = _toDouble(i['priceAtPurchase'] ?? i['price']);
        final qty = (i['quantity'] as num?)?.toInt() ?? 1;
        return sum + (price * qty);
      });
    }
    final String createdAt = order['createdAt'] != null
        ? DateTime.parse(
            order['createdAt'],
          ).toLocal().toString().substring(0, 16)
        : '';
    final bool isExpanded = _expandedOrderIds.contains(order['id']);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? _darkCardBg : Colors.white;
    final cardBorder = isDark ? _darkCardBorder : const Color(0xFFE1E5EE);
    final subtleText = isDark
        ? Colors.white.withValues(alpha: 0.58)
        : const Color(0xFF667085);

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.06),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _navigateToOrderDetail(context, order),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            "Mã đơn: #${order['id'].toString().substring(0, 8).toUpperCase()}",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              color: cs.onSurface,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        if (items.length > 1) ...[
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isExpanded) {
                                  _expandedOrderIds.remove(order['id']);
                                } else {
                                  _expandedOrderIds.add(order['id']);
                                }
                              });
                            },
                            child: Icon(
                              isExpanded
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              size: 20,
                              color: subtleText,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildStatusBadge(status),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                createdAt,
                style: TextStyle(
                  fontSize: 12,
                  color: subtleText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 22),
              if (items.isNotEmpty) ...[
                if (!isExpanded) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : const Color(0xFFF6F7FA),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: cardBorder),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child:
                              items.first['productVariant']?['imageUrl'] != null
                              ? Image.network(
                                  items.first['productVariant']['imageUrl'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) =>
                                      const Icon(LucideIcons.package),
                                )
                              : items.first['productVariant']?['product']?['thumbnailUrl'] !=
                                    null
                              ? Image.network(
                                  items
                                      .first['productVariant']['product']['thumbnailUrl'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) =>
                                      const Icon(LucideIcons.package),
                                )
                              : Icon(LucideIcons.package, color: subtleText),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              items.first['productVariant']?['product']?['name'] ??
                                  'Sản phẩm GearHub',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                color: cs.onSurface,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Số lượng: ${items.first['quantity']}",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: subtleText,
                              ),
                            ),
                            if (items.length > 1) ...[
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _expandedOrderIds.add(order['id']);
                                  });
                                },
                                child: Row(
                                  children: [
                                    Text(
                                      "và ${items.length - 1} sản phẩm khác (Xem thêm)...",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: _techAccent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      size: 16,
                                      color: _techAccent,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  ...items.map((i) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.04)
                                  : const Color(0xFFF6F7FA),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: cardBorder),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: i['productVariant']?['imageUrl'] != null
                                  ? Image.network(
                                      i['productVariant']['imageUrl'],
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) =>
                                          const Icon(LucideIcons.package),
                                    )
                                  : i['productVariant']?['product']?['thumbnailUrl'] !=
                                        null
                                  ? Image.network(
                                      i['productVariant']['product']['thumbnailUrl'],
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) =>
                                          const Icon(LucideIcons.package),
                                    )
                                  : const Icon(LucideIcons.package),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  i['productVariant']?['product']?['name'] ??
                                      'Sản phẩm',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: cs.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      formatVND(
                                        _toDouble(
                                          i['priceAtPurchase'] ?? i['price'],
                                        ),
                                      ),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: subtleText,
                                      ),
                                    ),
                                    Text(
                                      "x${i['quantity']}",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                        color: subtleText,
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
                  }),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _expandedOrderIds.remove(order['id']);
                      });
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Thu gọn",
                          style: TextStyle(
                            fontSize: 12,
                            color: subtleText,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_up_rounded,
                          size: 16,
                          color: subtleText,
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Tổng số tiền",
                          style: TextStyle(fontSize: 12, color: subtleText),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatVND(totalAmount),
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: cs.onSurface,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    children: [
                      if (status == 'PENDING' || status == 'CONFIRMED') ...[
                        if (latestStatusLabel == 'Yêu cầu hủy')
                          _buildActionButton(
                            context,
                            'Đang yêu cầu hủy',
                            Theme.of(context).colorScheme.onSurfaceVariant,
                            () {},
                          )
                        else
                          _buildActionButton(
                            context,
                            isPaidGateway ? 'Yêu cầu hủy' : 'Hủy đơn',
                            isPaidGateway
                                ? const Color(0xFFEA580C)
                                : const Color(0xFFEF4444),
                            () => _showCancelOrderDialog(
                              context,
                              order['id'],
                              isPaidGateway,
                            ),
                          ),
                      ],
                      if (status == 'DELIVERED')
                        _buildActionButton(
                          context,
                          'Đã nhận hàng',
                          const Color(0xFF10B981),
                          () => context.read<OrdersCubit>().confirmReceipt(
                            order['id'],
                          ),
                        ),
                      if (status == 'COMPLETED' || status == 'CANCELLED')
                        _buildActionButton(
                          context,
                          'Mua lại',
                          AppColors.brandIndigo,
                          () => _showReorderBottomSheet(context, order),
                        ),
                    ],
                  ),
                ],
              ),
              if (status == 'SHIPPING') ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Divider(
                    height: 1,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: Color(0xFFEF4444),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Đơn hàng đang trên đường giao, không thể hủy. Vui lòng liên hệ Hotline/Chat để được hỗ trợ hoặc từ chối nhận hàng khi shipper gọi.",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFEF4444),
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showReorderBottomSheet(BuildContext context, dynamic order) {
    final List<dynamic> items = order['items'] ?? [];
    if (items.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bCtx) {
        return ReorderBottomSheet(
          order: order,
          items: items,
          parentContext: context,
        );
      },
    );
  }

  Future<void> _handleReorderSuccess(
    BuildContext context,
    List<String> variantIds,
  ) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const Center(
          child: CircularProgressIndicator(color: AppColors.brandIndigo),
        ),
      );

      final cartCubit = context.read<CartCubit>();
      final result = await cartCubit.repository.getCart();

      if (context.mounted) {
        Navigator.of(context).pop();
      }

      await result.fold(
        (failure) async {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Không thể tải giỏ hàng: ${failure.message}'),
                backgroundColor: const Color(0xFFEF4444),
              ),
            );
          }
        },
        (cart) async {
          final checkoutItems = cart.items
              .where((item) => variantIds.contains(item.productVariant.id))
              .toList();

          if (checkoutItems.isEmpty) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Không tìm thấy sản phẩm hợp lệ trong giỏ hàng để thanh toán.',
                  ),
                  backgroundColor: Color(0xFFEF4444),
                ),
              );
            }
            return;
          }

          for (var item in checkoutItems) {
            item.isSelected = true;
          }

          cartCubit.loadCart();

          if (context.mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => CheckoutPage(
                  args: CheckoutArguments(
                    items: checkoutItems,
                    isFromCart: true,
                  ),
                ),
              ),
            );
          }
        },
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Có lỗi xảy ra: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Widget _buildStatusBadge(String status) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color base = isDark ? Colors.white : const Color(0xFF475467);
    Color bg = base.withValues(alpha: isDark ? 0.12 : 0.08);
    Color fg = base;
    String text = status;

    switch (status) {
      case 'PENDING':
        base = isDark ? const Color(0xFFFFB86B) : const Color(0xFFB45309);
        text = 'Chờ xác nhận';
        break;
      case 'CONFIRMED':
        base = isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4338CA);
        text = 'Đã xác nhận';
        break;
      case 'PROCESSING':
        base = isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D);
        text = 'Đang xử lý';
        break;
      case 'SHIPPING':
        base = isDark ? const Color(0xFF67E8F9) : const Color(0xFF0E7490);
        text = 'Đang giao';
        break;
      case 'DELIVERED':
        base = isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857);
        text = 'Đã giao';
        break;
      case 'COMPLETED':
        base = isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857);
        text = 'Hoàn thành';
        break;
      case 'CANCELLED':
        base = isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C);
        text = 'Đã hủy';
        break;
    }
    bg = base.withValues(alpha: isDark ? 0.15 : 0.12);
    fg = base;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: fg.withValues(alpha: isDark ? 0.26 : 0.18)),
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w900),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String text,
    Color color,
    VoidCallback onTap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isReorder = text == 'Mua lại';
    final isCancel = text.contains('hủy') || text.contains('Hủy');
    final fg = isReorder
        ? (isDark ? const Color(0xFF111827) : Colors.white)
        : isCancel
        ? (isDark
              ? Colors.white.withValues(alpha: 0.62)
              : const Color(0xFF667085))
        : color;
    final bg = isReorder
        ? (isDark ? Colors.white : const Color(0xFF111827))
        : Colors.transparent;
    final borderColor = isReorder
        ? Colors.transparent
        : isCancel
        ? (isDark
              ? Colors.white.withValues(alpha: 0.12)
              : const Color(0xFFD0D5DD))
        : color.withValues(alpha: isDark ? 0.32 : 0.22);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(32),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 11),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  void _showCancelOrderDialog(
    BuildContext context,
    String orderId,
    bool isProcessing,
  ) {
    showDialog<String>(
      context: context,
      builder: (dCtx) =>
          CancelOrderReasonDialog(orderId: orderId, isProcessing: isProcessing),
    ).then((reason) {
      if (reason != null && context.mounted) {
        context.read<OrdersCubit>().cancelOrder(orderId, reason);
      }
    });
  }

  void _navigateToOrderDetail(BuildContext context, dynamic order) {
    final ordersCubit = BlocProvider.of<OrdersCubit>(context);
    final cartCubit = BlocProvider.of<CartCubit>(context);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: ordersCubit),
            BlocProvider.value(value: cartCubit),
          ],
          child: OrderDetailPage(order: order),
        ),
      ),
    );
  }
}

class CancelOrderReasonDialog extends StatefulWidget {
  final String orderId;
  final bool isProcessing;

  const CancelOrderReasonDialog({
    super.key,
    required this.orderId,
    required this.isProcessing,
  });

  @override
  State<CancelOrderReasonDialog> createState() =>
      CancelOrderReasonDialogState();
}

class CancelOrderReasonDialogState extends State<CancelOrderReasonDialog> {
  int _selectedReasonIndex = -1;
  final TextEditingController _customReasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final List<String> _predefinedReasons = [
    'Thay đổi thông tin nhận hàng (địa chỉ, số điện thoại).',
    'Muốn thay đổi sản phẩm trong đơn (màu sắc, kích thước, thêm/bớt sản phẩm).',
    'Quên áp dụng mã giảm giá / Tìm thấy mã giảm giá tốt hơn.',
    'Tìm thấy cửa hàng khác bán rẻ hơn.',
    'Không còn nhu cầu mua nữa.',
    'Khác (Nhập lý do chi tiết)',
  ];

  @override
  void dispose() {
    _customReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.error_outline,
                        color: Color(0xFFEF4444),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.isProcessing
                            ? 'Yêu cầu hủy đơn'
                            : 'Hủy đơn hàng',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Vui lòng chọn lý do hủy đơn hàng của fen:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                ...List.generate(_predefinedReasons.length, (index) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      unselectedWidgetColor: Theme.of(
                        context,
                      ).colorScheme.outlineVariant,
                    ),
                    child: RadioListTile<int>(
                      value: index,
                      groupValue: _selectedReasonIndex,
                      activeColor: AppColors.brandIndigo,
                      title: Text(
                        _predefinedReasons[index],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      onChanged: (val) {
                        setState(() {
                          _selectedReasonIndex = val!;
                        });
                      },
                    ),
                  );
                }),
                if (_selectedReasonIndex == 5) ...[
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _customReasonController,
                    maxLines: 3,
                    maxLength: 150,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Nhập lý do khác của fen (tối đa 150 ký tự)...',
                      hintStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      filled: true,
                      fillColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppColors.brandIndigo,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    validator: (value) {
                      if (_selectedReasonIndex == 5 &&
                          (value == null || value.trim().isEmpty)) {
                        return 'Vui lòng nhập lý do hủy';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Quay lại',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        if (_selectedReasonIndex == -1) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Vui lòng chọn một lý do hủy đơn'),
                              backgroundColor: Color(0xFFEF4444),
                            ),
                          );
                          return;
                        }
                        if (_formKey.currentState!.validate()) {
                          String reason = '';
                          if (_selectedReasonIndex == 5) {
                            reason = _customReasonController.text.trim();
                          } else {
                            reason =
                                '${_selectedReasonIndex + 1}. ${_predefinedReasons[_selectedReasonIndex]}';
                          }

                          Navigator.pop(context, reason);
                        }
                      },
                      child: Text(
                        widget.isProcessing ? 'Gửi yêu cầu' : 'Hủy đơn',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ReorderBottomSheet extends StatefulWidget {
  final dynamic order;
  final List<dynamic> items;
  final BuildContext parentContext;

  const ReorderBottomSheet({
    super.key,
    required this.order,
    required this.items,
    required this.parentContext,
  });

  @override
  State<ReorderBottomSheet> createState() => ReorderBottomSheetState();
}

class ReorderBottomSheetState extends State<ReorderBottomSheet> {
  final Map<String, bool> _selectedItemMap = {};

  @override
  void initState() {
    super.initState();
    for (var item in widget.items) {
      final String id = item['id']?.toString() ?? '';
      if (id.isNotEmpty) {
        _selectedItemMap[id] = true;
      }
    }
  }

  bool get _isAllSelected =>
      _selectedItemMap.values.every((isSelected) => isSelected);

  int get _selectedCount =>
      _selectedItemMap.values.where((isSelected) => isSelected).length;

  void _toggleSelectAll() {
    final bool nextValue = !_isAllSelected;
    setState(() {
      _selectedItemMap.updateAll((key, value) => nextValue);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Mua lại sản phẩm",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Chọn các sản phẩm fen muốn mua lại và thêm vào giỏ hàng:",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Theme(
            data: Theme.of(context).copyWith(
              unselectedWidgetColor: Theme.of(
                context,
              ).colorScheme.outlineVariant,
            ),
            child: CheckboxListTile(
              value: _isAllSelected,
              activeColor: AppColors.brandIndigo,
              checkColor: Colors.white,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              title: Text(
                "Chọn tất cả",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              onChanged: (val) {
                _toggleSelectAll();
              },
            ),
          ),
          Divider(
            color: Theme.of(context).colorScheme.outlineVariant,
            height: 1,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                final i = widget.items[index];
                final String itemId = i['id']?.toString() ?? '';
                final bool isSelected = _selectedItemMap[itemId] ?? false;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Theme(
                        data: Theme.of(context).copyWith(
                          unselectedWidgetColor: Theme.of(
                            context,
                          ).colorScheme.outlineVariant,
                        ),
                        child: Checkbox(
                          value: isSelected,
                          activeColor: AppColors.brandIndigo,
                          checkColor: Colors.white,
                          onChanged: (val) {
                            setState(() {
                              _selectedItemMap[itemId] = val ?? false;
                            });
                          },
                        ),
                      ),
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: i['productVariant']?['imageUrl'] != null
                              ? Image.network(
                                  i['productVariant']['imageUrl'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) =>
                                      const Icon(LucideIcons.package),
                                )
                              : i['productVariant']?['product']?['thumbnailUrl'] !=
                                    null
                              ? Image.network(
                                  i['productVariant']['product']['thumbnailUrl'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) =>
                                      const Icon(LucideIcons.package),
                                )
                              : const Icon(LucideIcons.package),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              i['productVariant']?['product']?['name'] ??
                                  'Sản phẩm',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  formatVND(
                                    _toDouble(
                                      i['priceAtPurchase'] ?? i['price'],
                                    ),
                                  ),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  "x${i['quantity']}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
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
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandIndigo,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                disabledBackgroundColor: Theme.of(
                  context,
                ).colorScheme.outlineVariant,
              ),
              onPressed: _selectedCount > 0
                  ? () {
                      final selectedIds = _selectedItemMap.entries
                          .where((e) => e.value)
                          .map((e) => e.key)
                          .toList();
                      Navigator.pop(context);
                      widget.parentContext.read<OrdersCubit>().reOrder(
                        widget.order['id'],
                        selectedIds,
                      );
                    }
                  : null,
              child: Text(
                _selectedCount > 0
                    ? "Mua ngay ($_selectedCount)"
                    : "Chọn ít nhất 1 sản phẩm",
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
