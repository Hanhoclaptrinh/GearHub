import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/core/utils/formatter_utils.dart';
import 'package:mobile/src/features/chat/presentation/widgets/concierge_entry_button.dart';
import 'package:mobile/src/features/profile/presentation/pages/invoice_page.dart';
import 'package:mobile/src/features/profile/presentation/pages/order_history_page.dart';
import 'package:mobile/src/features/profile/presentation/state/orders_cubit.dart';
import 'package:mobile/src/features/profile/presentation/state/orders_state.dart';

double _toDouble(dynamic val) {
  if (val == null) return 0.0;
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val) ?? 0.0;
  return 0.0;
}

const _darkCardBorder = Color(0xFF252A3A);

class OrderDetailPage extends StatefulWidget {
  final dynamic order;

  const OrderDetailPage({super.key, required this.order});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
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

  int _getStatusIndex(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 0;
      case 'CONFIRMED':
        return 1;
      case 'PROCESSING':
        return 2;
      case 'SHIPPING':
        return 3;
      case 'DELIVERED':
        return 4;
      case 'COMPLETED':
        return 5;
      case 'CANCELLED':
        return -1;
      default:
        return 0;
    }
  }

  String? _getTimestampForStatus(
    List<dynamic> trackingList,
    List<String> statusKeys,
  ) {
    final Map<String, List<String>> keyToLabels = {
      'PENDING': ['Chờ xác nhận', 'PENDING'],
      'CONFIRMED': ['Đã xác nhận', 'CONFIRMED'],
      'PROCESSING': ['Đang đóng gói', 'Đang xử lý', 'PROCESSING'],
      'SHIPPING': ['Đang giao hàng', 'SHIPPING'],
      'DELIVERED': ['Giao hàng thành công', 'Đã giao', 'DELIVERED'],
      'COMPLETED': ['Đã hoàn thành', 'Đã nhận hàng', 'COMPLETED'],
      'CANCELLED': ['Đã hủy đơn', 'Đã hủy', 'CANCELLED'],
    };

    for (var key in statusKeys) {
      final searchStrings = keyToLabels[key.toUpperCase()] ?? [key];
      final match = trackingList.firstWhere((t) {
        final statusVal = t['status']?.toString().toUpperCase();
        if (statusVal != null && statusVal == key.toUpperCase()) {
          return true;
        }
        final labelVal = t['statusLabel']?.toString().toLowerCase();
        if (labelVal != null) {
          for (var searchStr in searchStrings) {
            if (labelVal == searchStr.toLowerCase() ||
                labelVal.contains(searchStr.toLowerCase())) {
              return true;
            }
          }
        }
        return false;
      }, orElse: () => null);

      if (match != null && match['createdAt'] != null) {
        return DateTime.parse(
          match['createdAt'],
        ).toLocal().toString().substring(0, 16);
      }
    }
    return null;
  }

  List<TimelineStepData> _buildTimelineSteps(
    String status,
    List<dynamic> trackingList,
    String orderCreatedAt,
  ) {
    final steps = <TimelineStepData>[];
    final stepDefinitions = [
      {
        'title': 'Đã xác nhận',
        'keys': ['CONFIRMED'],
      },
      {
        'title': 'Đang xử lý',
        'keys': ['PROCESSING'],
      },
      {
        'title': 'Đang giao hàng',
        'keys': ['SHIPPING'],
      },
      {
        'title': 'Đã giao',
        'keys': ['DELIVERED'],
      },
      {
        'title': 'Đã nhận hàng',
        'keys': ['COMPLETED'],
      },
    ];

    if (status != 'CANCELLED') {
      final currentIdx = _getStatusIndex(status);
      for (int i = 0; i < 5; i++) {
        final def = stepDefinitions[i];
        final title = def['title'] as String;
        final keys = def['keys'] as List<String>;
        final stepNum = i + 1;

        final isCompleted = currentIdx >= stepNum;
        final isActive = currentIdx == stepNum;

        String? ts;
        if (isCompleted) {
          ts = _getTimestampForStatus(trackingList, keys);
          if (ts == null && stepNum == 1) {
            ts = orderCreatedAt;
          }
        }

        steps.add(
          TimelineStepData(
            statusKey: keys.first,
            title: title,
            timestamp: ts,
            isCompleted: isCompleted,
            isActive: isActive,
          ),
        );
      }
    } else {
      int lastNormalCompletedIndex = -1;
      final normalTimestamps = List<String?>.filled(5, null);

      for (int i = 0; i < 5; i++) {
        final def = stepDefinitions[i];
        final keys = def['keys'] as List<String>;
        String? ts = _getTimestampForStatus(trackingList, keys);
        normalTimestamps[i] = ts;
        if (ts != null) {
          lastNormalCompletedIndex = i;
        }
      }

      final cancelTs = _getTimestampForStatus(trackingList, ['CANCELLED']);

      for (int i = 0; i < 5; i++) {
        final def = stepDefinitions[i];
        final title = def['title'] as String;
        final keys = def['keys'] as List<String>;

        if (i <= lastNormalCompletedIndex) {
          steps.add(
            TimelineStepData(
              statusKey: keys.first,
              title: title,
              timestamp: normalTimestamps[i],
              isCompleted: true,
              isActive: false,
            ),
          );
        } else if (i == lastNormalCompletedIndex + 1) {
          steps.add(
            TimelineStepData(
              statusKey: 'CANCELLED',
              title: 'Đã hủy',
              timestamp: cancelTs ?? normalTimestamps[i],
              isCompleted: true,
              isActive: true,
              isCancelled: true,
            ),
          );
        } else {
          steps.add(
            TimelineStepData(
              statusKey: keys.first,
              title: title,
              timestamp: null,
              isCompleted: false,
              isActive: false,
            ),
          );
        }
      }
    }

    return steps;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<OrdersCubit, OrdersState>(
      builder: (context, state) {
        dynamic order = widget.order;
        if (state is OrdersLoaded) {
          final found = state.orders.firstWhere(
            (o) => o['id'] == widget.order['id'],
            orElse: () => null,
          );
          if (found != null) {
            order = found;
          }
        }

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
        double totalAmount = _toDouble(order['totalAmount'] ?? order['total']);
        if (totalAmount == 0.0) {
          totalAmount = subtotal + shipping - discount;
        }

        final String createdAt = order['createdAt'] != null
            ? DateTime.parse(
                order['createdAt'],
              ).toLocal().toString().substring(0, 16)
            : '';

        final String paymentMethod = order['paymentMethod'] ?? '';
        final bool isPaidGateway =
            paymentMethod == 'PAYMENT_GATEWAY' &&
            (order['paymentStatus'] ?? '') == 'PAID';
        final hasPrimaryButton = status != 'SHIPPING';

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: cs.onSurface,
                size: 22,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Chi tiết đơn hàng',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: cs.onSurface,
                letterSpacing: -0.1,
              ),
            ),
            actions: [
              if (status != 'CANCELLED')
                IconButton(
                  tooltip: 'Xuất hóa đơn điện tử',
                  icon: FaIcon(
                    FontAwesomeIcons.receipt,
                    color: cs.primary,
                    size: 22,
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => InvoicePage(order: order),
                      ),
                    );
                  },
                ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoBlock(context, order, isDark),
                        _buildAlertBanner(context, status, latestStatusLabel),
                        _buildProductListSection(context, items, isDark),
                        _buildTimelineSection(
                          context,
                          status,
                          trackingList,
                          createdAt,
                        ),
                        _buildPricingSummary(
                          context,
                          subtotal,
                          shipping,
                          discount,
                          totalAmount,
                          isDark,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: Container(
            padding: EdgeInsets.fromLTRB(
              24,
              12,
              24,
              MediaQuery.of(context).padding.bottom > 0
                  ? MediaQuery.of(context).padding.bottom + 8
                  : 24,
            ),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : const Color(0xFFE6E8EF),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: hasPrimaryButton ? 4 : 1,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: cs.outlineVariant),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                    ),
                    icon: Icon(Icons.headset_mic_rounded, color: cs.primary),
                    label: const Text(
                      'Hỗ trợ',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    onPressed: () {
                      ConciergeEntryButton.open(context);
                    },
                  ),
                ),
                if (hasPrimaryButton) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 6,
                    child: _buildFooterPrimaryButton(
                      context,
                      status,
                      latestStatusLabel,
                      isPaidGateway,
                      order,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoBlock(BuildContext context, dynamic order, bool isDark) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: cs.onSurfaceVariant,
    );
    final labelStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w800,
      color: cs.onSurface,
    );

    final String paymentMethod = order['paymentMethod'] ?? '';
    final isVNPAY =
        paymentMethod == 'PAYMENT_GATEWAY' || paymentMethod == 'VNPAY';
    final paymentText = isVNPAY
        ? 'Cổng thanh toán VNPAY'
        : 'Thanh toán khi nhận hàng (COD)';
    final paymentIconPath = isVNPAY
        ? 'assets/logo/vnpay.svg'
        : 'assets/logo/cash.svg';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "THÔNG TIN NHẬN HÀNG",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: cs.primary,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FaIcon(
                FontAwesomeIcons.solidUser,
                size: 16,
                color: cs.onSurfaceVariant.withValues(alpha: 0.62),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  order['receiverName'] ?? 'Chưa cập nhật',
                  style: labelStyle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FaIcon(
                FontAwesomeIcons.phone,
                size: 16,
                color: cs.onSurfaceVariant.withValues(alpha: 0.62),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  order['receiverPhone'] ?? 'Chưa cập nhật',
                  style: textStyle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FaIcon(
                FontAwesomeIcons.locationDot,
                size: 16,
                color: cs.onSurfaceVariant.withValues(alpha: 0.62),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  order['shippingAddress'] ?? 'Chưa cập nhật',
                  style: textStyle.copyWith(height: 1.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : const Color(0xFFE6E8EF),
          ),
          const SizedBox(height: 16),
          Text(
            "PHƯƠNG THỨC THANH TOÁN",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: cs.primary,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              SvgPicture.asset(
                paymentIconPath,
                width: 24,
                height: 24,
                errorBuilder: (context, error, stackTrace) => FaIcon(
                  isVNPAY
                      ? FontAwesomeIcons.solidCreditCard
                      : FontAwesomeIcons.moneyBill1,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(paymentText, style: labelStyle)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertBanner(
    BuildContext context,
    String status,
    String? latestStatusLabel,
  ) {
    if (status == 'SHIPPING') {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFEF4444).withValues(alpha: 0.2),
            ),
          ),
          child: const Row(
            children: [
              FaIcon(
                FontAwesomeIcons.triangleExclamation,
                size: 16,
                color: Color(0xFFEF4444),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Đơn hàng đang trên đường giao, không thể hủy. Vui lòng liên hệ Hotline/Chat để được hỗ trợ hoặc từ chối nhận hàng khi shipper gọi.",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFEF4444),
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if ((status == 'PENDING' || status == 'CONFIRMED') &&
        latestStatusLabel == 'Yêu cầu hủy') {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEA580C).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFEA580C).withValues(alpha: 0.2),
            ),
          ),
          child: const Row(
            children: [
              Icon(LucideIcons.clock, size: 16, color: Color(0xFFEA580C)),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Bạn đã gửi yêu cầu hủy đơn hàng này. Vui lòng chờ phản hồi từ cửa hàng.",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFEA580C),
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildProductListSection(
    BuildContext context,
    List<dynamic> items,
    bool isDark,
  ) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "SẢN PHẨM",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: cs.primary,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((i) => _buildProductItem(i, context, isDark)),
        ],
      ),
    );
  }

  Widget _buildProductItem(dynamic i, BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final cardBorder = isDark ? _darkCardBorder : const Color(0xFFE1E5EE);
    final imageUrl =
        i['productVariant']?['imageUrl'] ??
        i['productVariant']?['product']?['thumbnailUrl'];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cardBorder),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) =>
                          const Icon(LucideIcons.package),
                    )
                  : const Icon(LucideIcons.package),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  i['productVariant']?['product']?['name'] ??
                      'Sản phẩm GearHub',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: cs.onSurface,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  formatVND(_toDouble(i['priceAtPurchase'] ?? i['price'])),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            "x${i['quantity']}",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 13,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineSection(
    BuildContext context,
    String status,
    List<dynamic> trackingList,
    String createdAt,
  ) {
    final cs = Theme.of(context).colorScheme;
    final steps = _buildTimelineSteps(status, trackingList, createdAt);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "HÀNH TRÌNH ĐƠN HÀNG",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: cs.primary,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 20),
          ...List.generate(steps.length, (index) {
            final step = steps[index];
            final nextStep = index < steps.length - 1 ? steps[index + 1] : null;
            return _buildTimelineItem(
              step,
              index == steps.length - 1,
              context,
              nextStep,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    TimelineStepData step,
    bool isLast,
    BuildContext context,
    TimelineStepData? nextStep,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final isStepActiveOrCompleted = step.isCompleted;
    final titleColor = step.isCancelled
        ? const Color(0xFFEF4444)
        : (isStepActiveOrCompleted
              ? cs.onSurface
              : cs.onSurface.withValues(alpha: 0.38));
    final subtitleColor = step.isCancelled
        ? const Color(0xFFFCA5A5)
        : cs.onSurfaceVariant.withValues(alpha: 0.58);

    Widget iconWidget;
    if (step.isCancelled) {
      iconWidget = Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          color: Color(0xFFEF4444),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
      );
    } else if (step.isCompleted) {
      iconWidget = Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          color: Color(0xFF10B981),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
      );
    } else {
      iconWidget = Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: cs.onSurface.withValues(alpha: 0.16),
            width: 2,
          ),
        ),
      );
    }

    final bool isNextStepCompleted = nextStep?.isCompleted ?? false;
    final bool isNextStepCancelled = nextStep?.isCancelled ?? false;
    final bool useSolidLine = isStepActiveOrCompleted && isNextStepCompleted;

    Color lineColor;
    if (useSolidLine) {
      if (isNextStepCancelled) {
        lineColor = const Color(0xFFEF4444);
      } else {
        lineColor = const Color(0xFF10B981);
      }
    } else {
      lineColor = cs.onSurface.withValues(alpha: 0.12);
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              iconWidget,
              if (!isLast)
                Expanded(
                  child: CustomPaint(
                    size: const Size(2, double.infinity),
                    painter: _TimelineLinePainter(
                      color: lineColor,
                      isDashed: !useSolidLine,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: titleColor,
                  ),
                ),
                if (step.timestamp != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    step.timestamp!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: subtitleColor,
                    ),
                  ),
                ],
                const SizedBox(height: 28),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingSummary(
    BuildContext context,
    double subtotal,
    double shipping,
    double discount,
    double totalAmount,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "TỔNG HỢP CHI PHÍ",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: cs.primary,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 16),
          _priceRow(context, "Tạm tính", formatVND(subtotal)),
          const SizedBox(height: 10),
          _priceRow(context, "Phí vận chuyển", formatVND(shipping)),
          const SizedBox(height: 10),
          _priceRow(
            context,
            "Giảm giá",
            "-${formatVND(discount)}",
            valueColor: const Color(0xFF22C55E),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Divider(
              height: 1,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : const Color(0xFFE6E8EF),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Tổng cộng",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: cs.onSurface,
                ),
              ),
              Text(
                formatVND(totalAmount),
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  color: cs.primary,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              "(Giá đã bao gồm thuế VAT 8%)",
              style: TextStyle(
                fontSize: 11,
                color: cs.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: valueColor ?? Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildFooterPrimaryButton(
    BuildContext context,
    String status,
    String? latestStatusLabel,
    bool isPaidGateway,
    dynamic order,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (status == 'PENDING' || status == 'CONFIRMED') {
      if (latestStatusLabel == 'Yêu cầu hủy') {
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : const Color(0xFFF3F4F6),
            foregroundColor: cs.onSurfaceVariant.withValues(alpha: 0.5),
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
            ),
          ),
          onPressed: null,
          child: const Text(
            'Đang yêu cầu hủy',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
          ),
        );
      } else {
        final btnColor = isPaidGateway
            ? const Color(0xFFEA580C)
            : const Color(0xFFEF4444);
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: btnColor,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
            ),
          ),
          onPressed: () =>
              _showCancelOrderDialog(context, order['id'], isPaidGateway),
          child: Text(
            isPaidGateway ? 'Yêu cầu hủy' : 'Hủy đơn',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
          ),
        );
      }
    }

    if (status == 'DELIVERED') {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF10B981),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
        ),
        onPressed: () {
          context.read<OrdersCubit>().confirmReceipt(order['id']);
        },
        child: const Text(
          'Đã nhận hàng',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
        ),
      );
    }

    if (status == 'COMPLETED' || status == 'CANCELLED') {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
        ),
        onPressed: () => _showReorderBottomSheet(context, order),
        child: const Text(
          'Mua lại',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class TimelineStepData {
  final String statusKey;
  final String title;
  final String? timestamp;
  final bool isCompleted;
  final bool isActive;
  final bool isCancelled;

  TimelineStepData({
    required this.statusKey,
    required this.title,
    this.timestamp,
    required this.isCompleted,
    required this.isActive,
    this.isCancelled = false,
  });
}

class _TimelineLinePainter extends CustomPainter {
  final Color color;
  final bool isDashed;

  _TimelineLinePainter({required this.color, required this.isDashed});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    if (!isDashed) {
      canvas.drawLine(
        Offset(size.width / 2, 0),
        Offset(size.width / 2, size.height),
        paint,
      );
    } else {
      const dashHeight = 4.0;
      const dashSpace = 4.0;
      double startY = 0;
      while (startY < size.height) {
        canvas.drawLine(
          Offset(size.width / 2, startY),
          Offset(size.width / 2, startY + dashHeight),
          paint,
        );
        startY += dashHeight + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
