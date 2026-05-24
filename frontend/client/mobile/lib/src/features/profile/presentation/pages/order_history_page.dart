import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/core/theme/app_colors.dart';
import 'package:mobile/src/core/di/injection.dart';
import 'package:mobile/src/core/utils/formatter_utils.dart';
import 'package:mobile/src/features/chat/presentation/widgets/concierge_entry_button.dart';
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
    return BlocProvider(
      create: (context) => getIt<OrdersCubit>()..fetchMyOrders(status: 'ALL'),
      child: Builder(
        builder: (context) {
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light,
            child: Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(
                backgroundColor: AppColors.background,
                elevation: 0,
                scrolledUnderElevation: 0,
                centerTitle: true,
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                title: const Text(
                  'Lịch sử đơn hàng',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(48),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.borderCardStrong.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      physics: const BouncingScrollPhysics(),
                      tabAlignment: TabAlignment.start,
                      indicatorColor: AppColors.brandIndigo,
                      indicatorWeight: 3,
                      dividerColor: Colors.transparent,
                      labelColor: AppColors.brandIndigo,
                      unselectedLabelColor: AppColors.textDim,
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
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.brandIndigo,
                      ),
                    );
                  }

                  if (state is OrdersLoaded) {
                    final orders = state.orders;
                    final currentTab =
                        _statusTabs[_tabController.index]['status'];

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
                        color: AppColors.brandIndigo,
                        backgroundColor: AppColors.cardSurfaceAlt,
                        onRefresh: () async {
                          await context.read<OrdersCubit>().fetchMyOrders(
                            status: 'ALL',
                          );
                        },
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.25,
                            ),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: const BoxDecoration(
                                      color: AppColors.cardSurfaceAlt,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      LucideIcons.shoppingBag,
                                      size: 40,
                                      color: AppColors.textDim,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  const Text(
                                    'Trống trải quá fen',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Đơn hàng của fen sẽ hiện ở đây khi mua sắm.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textDim,
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
                      color: AppColors.brandIndigo,
                      backgroundColor: AppColors.cardSurfaceAlt,
                      onRefresh: () async {
                        await context.read<OrdersCubit>().fetchMyOrders(
                          status: 'ALL',
                        );
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
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
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, dynamic order) {
    final String status = order['status'] ?? 'PENDING';
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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardSurfaceAlt,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderCardStrong),
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
                    "Mã đơn: #${order['id'].toString().substring(0, 8).toUpperCase()}",
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
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
                  color: AppColors.textDim,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Divider(height: 1, color: AppColors.borderCardStrong),
              ),
              if (items.isNotEmpty) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: AppColors.cardSurfaceAltAlt,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderCardStrong),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(11),
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
                            : const Icon(
                                LucideIcons.package,
                                color: AppColors.textDim,
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            items.first['productVariant']?['product']?['name'] ??
                                'Sản phẩm GearHub',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Số lượng: ${items.first['quantity']}",
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: AppColors.textDim,
                            ),
                          ),
                          if (items.length > 1) ...[
                            const SizedBox(height: 6),
                            Text(
                              "và ${items.length - 1} sản phẩm khác...",
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textDim,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Divider(height: 1, color: AppColors.borderCardStrong),
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
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textDim,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatVND(totalAmount),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (status == 'PENDING' ||
                          status == 'CONFIRMED' ||
                          status == 'PROCESSING') ...[
                        if (status == 'PROCESSING' &&
                            latestStatusLabel == 'Yêu cầu hủy')
                          _buildActionButton(
                            context,
                            'Đang yêu cầu hủy',
                            AppColors.slate400,
                            () {},
                          )
                        else
                          _buildActionButton(
                            context,
                            status == 'PROCESSING' ? 'Yêu cầu hủy' : 'Hủy đơn',
                            status == 'PROCESSING'
                                ? const Color(0xFFEA580C)
                                : const Color(0xFFEF4444),
                            () => _showCancelOrderDialog(
                              context,
                              order['id'],
                              status == 'PROCESSING',
                            ),
                          ),
                      ],
                      if (status == 'DELIVERED' || status == 'CANCELLED')
                        _buildActionButton(
                          context,
                          'Mua lại',
                          AppColors.brandIndigo,
                          () =>
                              context.read<OrdersCubit>().reOrder(order['id']),
                        ),
                    ],
                  ),
                ],
              ),
              if (status == 'SHIPPING') ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1, color: AppColors.borderCardStrong),
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

  Widget _buildStatusBadge(String status) {
    Color bg = AppColors.borderCardStrong;
    Color fg = AppColors.slate400;
    String text = status;

    switch (status) {
      case 'PENDING':
        bg = const Color(0xFFEA580C).withValues(alpha: 0.15);
        fg = const Color(0xFFEA580C);
        text = 'Chờ xác nhận';
        break;
      case 'CONFIRMED':
        bg = AppColors.brandIndigo.withValues(alpha: 0.15);
        fg = AppColors.brandIndigo;
        text = 'Đã xác nhận';
        break;
      case 'PROCESSING':
        bg = const Color(0xFF22C55E).withValues(alpha: 0.15);
        fg = const Color(0xFF22C55E);
        text = 'Đang xử lý';
        break;
      case 'SHIPPING':
        bg = const Color(0xFF06B6D4).withValues(alpha: 0.15);
        fg = const Color(0xFF06B6D4);
        text = 'Đang giao';
        break;
      case 'DELIVERED':
        bg = const Color(0xFF10B981).withValues(alpha: 0.15);
        fg = const Color(0xFF10B981);
        text = 'Đã giao';
        break;
      case 'CANCELLED':
        bg = const Color(0xFFEF4444).withValues(alpha: 0.15);
        fg = const Color(0xFFEF4444);
        text = 'Đã hủy';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String text,
    Color color,
    VoidCallback onTap,
  ) {
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
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
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

  void _showCancelOrderDialog(
    BuildContext context,
    String orderId,
    bool isProcessing,
  ) {
    showDialog<String>(
      context: context,
      builder: (dCtx) => _CancelOrderReasonDialog(
        orderId: orderId,
        isProcessing: isProcessing,
      ),
    ).then((reason) {
      if (reason != null && context.mounted) {
        context.read<OrdersCubit>().cancelOrder(orderId, reason);
      }
    });
  }

  void _showOrderDetailModal(BuildContext context, dynamic order) {
    final String status = order['status'] ?? 'PENDING';
    final List<dynamic> trackingList = order['tracking'] ?? [];
    final String? latestStatusLabel = trackingList.isNotEmpty
        ? trackingList.first['statusLabel']
        : null;
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
    final double vat = subtotal * 0.1;
    double totalAmount = _toDouble(order['totalAmount'] ?? order['total']);
    if (totalAmount == 0.0) {
      totalAmount = subtotal + vat + shipping - discount;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
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
                  color: AppColors.borderCardStrong,
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
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                _buildStatusBadge(status),
              ],
            ),
            const SizedBox(height: 16),
            if (status == 'SHIPPING') ...[
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
            if (status == 'PROCESSING' &&
                latestStatusLabel == 'Yêu cầu hủy') ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEA580C).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFEA580C).withValues(alpha: 0.2),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(LucideIcons.clock, size: 16, color: Color(0xFFEA580C)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Bạn đã gửi yêu cầu hủy đơn hàng này. Vui lòng chờ phản hồi từ cửa hàng.",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFEA580C),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            const ConciergeEntryButton(label: 'Hỗ trợ đơn hàng'),
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
                        color: AppColors.cardSurfaceAlt,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.borderCardStrong),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Thông tin nhận hàng",
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: AppColors.textDim,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(
                                LucideIcons.user,
                                size: 16,
                                color: AppColors.slate400,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                order['receiverName'] ?? 'Chưa cập nhật',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                LucideIcons.phone,
                                size: 16,
                                color: AppColors.slate400,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                order['receiverPhone'] ?? 'Chưa cập nhật',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.slate400,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                LucideIcons.mapPin,
                                size: 16,
                                color: AppColors.slate400,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  order['shippingAddress'] ?? 'Chưa cập nhật',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.slate400,
                                    height: 1.4,
                                  ),
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
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
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
                                color: AppColors.cardSurfaceAltAlt,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.borderCardStrong,
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
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      color: AppColors.textPrimary,
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
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: AppColors.slate400,
                                        ),
                                      ),
                                      Text(
                                        "x${i['quantity']}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                          color: AppColors.textDim,
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
                    const SizedBox(height: 12),
                    // breakdown
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.cardSurfaceAlt,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.borderCardStrong),
                      ),
                      child: Column(
                        children: [
                          _priceRow("Tạm tính", formatVND(subtotal)),
                          const SizedBox(height: 8),
                          _priceRow("Phí vận chuyển", formatVND(shipping)),
                          const SizedBox(height: 8),
                          _priceRow("Thuế VAT (10%)", formatVND(vat)),
                          const SizedBox(height: 8),
                          _priceRow(
                            "Giảm giá",
                            "-${formatVND(discount)}",
                            valueColor: const Color(0xFF22C55E),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(
                              height: 1,
                              color: AppColors.borderCardStrong,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Tổng cộng",
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                formatVND(totalAmount),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20,
                                  color: AppColors.brandIndigo,
                                  letterSpacing: -0.2,
                                ),
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
          style: const TextStyle(
            color: AppColors.textDim,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _CancelOrderReasonDialog extends StatefulWidget {
  final String orderId;
  final bool isProcessing;

  const _CancelOrderReasonDialog({
    required this.orderId,
    required this.isProcessing,
  });

  @override
  State<_CancelOrderReasonDialog> createState() =>
      _CancelOrderReasonDialogState();
}

class _CancelOrderReasonDialogState extends State<_CancelOrderReasonDialog> {
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
      backgroundColor: AppColors.cardSurfaceAlt,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: const BorderSide(color: AppColors.borderCardStrong),
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
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Vui lòng chọn lý do hủy đơn hàng của fen:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDim,
                  ),
                ),
                const SizedBox(height: 12),
                ...List.generate(_predefinedReasons.length, (index) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      unselectedWidgetColor: AppColors.borderCardStrong,
                    ),
                    child: RadioListTile<int>(
                      value: index,
                      groupValue: _selectedReasonIndex,
                      activeColor: AppColors.brandIndigo,
                      title: Text(
                        _predefinedReasons[index],
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
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
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Nhập lý do khác của fen (tối đa 150 ký tự)...',
                      hintStyle: const TextStyle(color: AppColors.textDim),
                      filled: true,
                      fillColor: AppColors.cardSurfaceAltAlt,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppColors.borderCardStrong,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppColors.borderCardStrong,
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
                      child: const Text(
                        'Quay lại',
                        style: TextStyle(
                          color: AppColors.textDim,
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
