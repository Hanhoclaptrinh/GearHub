import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/core/di/injection.dart';
import 'package:mobile/src/core/utils/formatter_utils.dart';
import 'package:mobile/src/features/profile/presentation/state/orders_cubit.dart';
import 'package:mobile/src/features/profile/presentation/state/orders_state.dart';

double _toDouble(dynamic val) {
  if (val == null) return 0.0;
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val) ?? 0.0;
  return 0.0;
}

class OrderHistoryPage extends StatefulWidget {
  final String initialStatus;

  const OrderHistoryPage({super.key, this.initialStatus = 'ALL'});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
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
    int initialIndex = _statusTabs.indexWhere((t) => t['status'] == widget.initialStatus);
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
    return BlocProvider(
      create: (context) => getIt<OrdersCubit>()..fetchMyOrders(status: 'ALL'),
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                'LỊCH SỬ ĐƠN HÀNG',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    physics: const BouncingScrollPhysics(),
                    tabAlignment: TabAlignment.start,
                    indicatorColor: const Color(0xFF3B82F6),
                    indicatorWeight: 3,
                    labelColor: const Color(0xFF3B82F6),
                    unselectedLabelColor: const Color(0xFF64748B),
                    labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    tabs: _statusTabs.map((t) => Tab(text: t['label'])).toList(),
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
                } else if (state is OrdersError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: const Color(0xFFEF4444),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is OrdersLoading) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)));
                }

                if (state is OrdersLoaded) {
                  final orders = state.orders;
                  final currentTab = _statusTabs[_tabController.index]['status'];

                  // filter the list on the client side dynamically
                  final filteredOrders = orders.where((order) {
                    if (currentTab == 'ALL') return true;
                    final String status = order['status'] ?? 'PENDING';
                    if (currentTab == 'PENDING') {
                      return status == 'PENDING' || status == 'CONFIRMED';
                    }
                    return status == currentTab;
                  }).toList();

                  if (filteredOrders.isEmpty) {
                    return RefreshIndicator(
                      color: const Color(0xFF3B82F6),
                      onRefresh: () async {
                        await context.read<OrdersCubit>().fetchMyOrders(status: 'ALL');
                      },
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                          const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(LucideIcons.shoppingBag, size: 64, color: Color(0xFFCBD5E1)),
                                SizedBox(height: 16),
                                Text(
                                  'Không có đơn hàng nào',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Đơn hàng của bạn ở mục này sẽ hiển thị tại đây.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: const Color(0xFF3B82F6),
                    onRefresh: () async {
                      await context.read<OrdersCubit>().fetchMyOrders(status: 'ALL');
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: filteredOrders.length,
                      itemBuilder: (context, index) {
                        final order = filteredOrders[index];
                        return _buildOrderCard(context, order);
                      },
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          );
        }
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, dynamic order) {
    final String status = order['status'] ?? 'PENDING';
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
        ? DateTime.parse(order['createdAt']).toLocal().toString().substring(0, 16)
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showOrderDetailModal(context, order),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Đơn hàng: #${order['id'].toString().substring(0, 8).toUpperCase()}",
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  _buildStatusBadge(status),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                createdAt,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Divider(height: 1, color: Color(0xFFF1F5F9)),
              ),
              if (items.isNotEmpty) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: items.first['productVariant']?['imageUrl'] != null
                            ? Image.network(
                                items.first['productVariant']['imageUrl'],
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => const Icon(LucideIcons.package),
                              )
                            : items.first['productVariant']?['product']?['thumbnailUrl'] != null
                                ? Image.network(
                                    items.first['productVariant']['product']['thumbnailUrl'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => const Icon(LucideIcons.package),
                                  )
                                : const Icon(LucideIcons.package, color: Color(0xFF64748B)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            items.first['productVariant']?['product']?['name'] ?? 'Sản phẩm GearHub',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Số lượng: ${items.first['quantity']}",
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          if (items.length > 1) ...[
                            const SizedBox(height: 6),
                            Text(
                              "và ${items.length - 1} sản phẩm khác...",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF94A3B8),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ]
                        ],
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                ),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Tổng số tiền",
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatVND(totalAmount),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF3B82F6),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (status == 'PENDING')
                        _buildActionButton(
                          context,
                          'Hủy đơn',
                          const Color(0xFFEF4444),
                          () => _confirmCancelOrder(context, order['id']),
                        ),
                      if (status == 'DELIVERED' || status == 'CANCELLED')
                        _buildActionButton(
                          context,
                          'Mua lại',
                          const Color(0xFF3B82F6),
                          () => context.read<OrdersCubit>().reOrder(order['id']),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = const Color(0xFFF1F5F9);
    Color fg = const Color(0xFF475569);
    String text = status;

    switch (status) {
      case 'PENDING':
        bg = const Color(0xFFFFF7ED);
        fg = const Color(0xFFEA580C);
        text = 'Chờ xác nhận';
        break;
      case 'CONFIRMED':
        bg = const Color(0xFFEFF6FF);
        fg = const Color(0xFF2563EB);
        text = 'Đã xác nhận';
        break;
      case 'PROCESSING':
        bg = const Color(0xFFF0FDF4);
        fg = const Color(0xFF16A34A);
        text = 'Đang xử lý';
        break;
      case 'SHIPPING':
        bg = const Color(0xFFEFF6FF);
        fg = const Color(0xFF3B82F6);
        text = 'Đang giao';
        break;
      case 'DELIVERED':
        bg = const Color(0xFFF0FDF4);
        fg = const Color(0xFF10B981);
        text = 'Đã giao';
        break;
      case 'CANCELLED':
        bg = const Color(0xFFFEF2F2);
        fg = const Color(0xFFEF4444);
        text = 'Đã hủy';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String text, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.only(left: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 0.8),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  void _confirmCancelOrder(BuildContext context, String orderId) {
    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Xác nhận', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('Bạn có chắc chắn muốn hủy đơn hàng này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: const Text('Quay lại', style: TextStyle(color: Color(0xFF64748B))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dCtx);
              context.read<OrdersCubit>().cancelOrder(orderId);
            },
            child: const Text('Hủy đơn', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _showOrderDetailModal(BuildContext context, dynamic order) {
    final List<dynamic> items = order['items'] ?? [];
    double subtotal = _toDouble(order['subtotal']);
    if (subtotal == 0.0) {
      subtotal = items.fold(0.0, (sum, i) {
        final price = _toDouble(i['priceAtPurchase'] ?? i['price']);
        final qty = (i['quantity'] as num?)?.toInt() ?? 1;
        return sum + (price * qty);
      });
    }
    final double shipping = _toDouble(order['shippingFee'] ?? 0.0);
    final double discount = _toDouble(order['discount']);
    double totalAmount = _toDouble(order['totalAmount'] ?? order['total']);
    if (totalAmount == 0.0) {
      totalAmount = subtotal + shipping - discount;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.82,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
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
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Chi tiết đơn hàng",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                _buildStatusBadge(order['status'] ?? 'PENDING'),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // thong tin nhan hang
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Thông tin nhận hàng",
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(LucideIcons.user, size: 16, color: Color(0xFF475569)),
                              const SizedBox(width: 8),
                              Text(
                                order['receiverName'] ?? 'Chưa cập nhật',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(LucideIcons.phone, size: 16, color: Color(0xFF475569)),
                              const SizedBox(width: 8),
                              Text(
                                order['receiverPhone'] ?? 'Chưa cập nhật',
                                style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(LucideIcons.mapPin, size: 16, color: Color(0xFF475569)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  order['shippingAddress'] ?? 'Chưa cập nhật',
                                  style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // list items
                    const Text(
                      "Sản phẩm",
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 10),
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
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: i['productVariant']?['imageUrl'] != null
                                    ? Image.network(
                                        i['productVariant']['imageUrl'],
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) => const Icon(LucideIcons.package),
                                      )
                                    : i['productVariant']?['product']?['thumbnailUrl'] != null
                                        ? Image.network(
                                            i['productVariant']['product']['thumbnailUrl'],
                                            fit: BoxFit.cover,
                                            errorBuilder: (c, e, s) => const Icon(LucideIcons.package),
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
                                    i['productVariant']?['product']?['name'] ?? 'Sản phẩm',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        formatVND(_toDouble(i['priceAtPurchase'] ?? i['price'])),
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF475569)),
                                      ),
                                      Text(
                                        "x${i['quantity']}",
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF64748B)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                    // breakdown
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          _priceRow("Tạm tính", formatVND(subtotal)),
                          const SizedBox(height: 8),
                          _priceRow("Phí vận chuyển", formatVND(shipping)),
                          const SizedBox(height: 8),
                          _priceRow("Giảm giá", "-${formatVND(discount)}", valueColor: const Color(0xFF10B981)),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Tổng cộng",
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
                              ),
                              Text(
                                formatVND(totalAmount),
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF3B82F6)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: valueColor ?? const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
