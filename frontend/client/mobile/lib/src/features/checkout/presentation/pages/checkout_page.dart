import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/src/core/di/injection.dart';
import 'package:mobile/src/core/utils/formatter_utils.dart';
import 'package:mobile/src/features/cart/domain/entities/cart_item_entity.dart';
import 'package:mobile/src/features/cart/presentation/state/cart_cubit.dart';
import 'package:mobile/src/features/checkout/presentation/state/checkout_cubit.dart';
import 'package:mobile/src/features/checkout/presentation/state/checkout_state.dart';
import 'package:mobile/src/features/checkout/presentation/widgets/delivery_section.dart';
import 'package:mobile/src/features/checkout/presentation/widgets/checkout_items_section.dart';
import 'package:mobile/src/features/checkout/presentation/widgets/payment_selection_section.dart';
import 'package:mobile/src/features/checkout/presentation/widgets/price_breakdown_section.dart';
import 'package:mobile/src/features/checkout/presentation/widgets/edit_address_modal.dart';
import 'vnpay_payment_page.dart';
import 'package:mobile/src/features/profile/presentation/pages/order_history_page.dart';

class CheckoutArguments {
  final List<CartItemEntity> items;
  final bool isFromCart;

  CheckoutArguments({required this.items, required this.isFromCart});
}

class CheckoutPage extends StatefulWidget {
  final CheckoutArguments args;

  const CheckoutPage({super.key, required this.args});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  String _selectedPaymentMethod = "COD";
  bool _saveAsDefault = true;

  @override
  void initState() {
    super.initState();
    _loadDefaultShippingInfo();
  }

  Future<void> _loadDefaultShippingInfo() async {
    try {
      final prefs = getIt<SharedPreferences>();
      final savedName = prefs.getString('default_receiver_name');
      final savedPhone = prefs.getString('default_receiver_phone');
      final savedAddress = prefs.getString('default_shipping_address');

      if (savedName != null && savedName.isNotEmpty) {
        setState(() {
          _nameController.text = savedName;
          _phoneController.text = savedPhone ?? '';
          _addressController.text = savedAddress ?? '';
        });
      }
    } catch (_) {}
  }

  Future<void> _saveDefaultShippingInfo() async {
    if (!_saveAsDefault) return;
    try {
      final prefs = getIt<SharedPreferences>();
      await prefs.setString(
        'default_receiver_name',
        _nameController.text.trim(),
      );
      await prefs.setString(
        'default_receiver_phone',
        _phoneController.text.trim(),
      );
      await prefs.setString(
        'default_shipping_address',
        _addressController.text.trim(),
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double get _subtotal =>
      widget.args.items.fold(0.0, (sum, item) => sum + item.itemTotal);

  double get _shipping => 0.0;
  double get _discount => 0.0;
  double get _vat => _subtotal * 0.1;
  double get _total => _subtotal + _shipping - _discount + _vat;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return BlocProvider(
      create: (context) => getIt<CheckoutCubit>(),
      child: BlocConsumer<CheckoutCubit, CheckoutState>(
        listener: (context, state) async {
          if (state is OrderPlacedSuccess) {
            if (_saveAsDefault) {
              await _saveDefaultShippingInfo();
            }
            if (state.paymentMethod == 'PAYMENT_GATEWAY' &&
                state.paymentUrl != null) {
              final bool? paymentResult = await Navigator.of(context)
                  .push<bool>(
                    MaterialPageRoute(
                      builder: (_) => VnpayPaymentPage(
                        paymentUrl: state.paymentUrl!,
                        orderId: state.orderId,
                      ),
                    ),
                  );

              if (paymentResult == true) {
                if (widget.args.isFromCart) {
                  final variantIds = widget.args.items
                      .map((i) => i.productVariant.id)
                      .toList();
                  context.read<CartCubit>().clearSelectedItems(variantIds);
                }
                _showSuccessDialog();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Thanh toán VNPay không thành công hoặc đã bị hủy.',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            } else {
              if (widget.args.isFromCart) {
                final variantIds = widget.args.items
                    .map((i) => i.productVariant.id)
                    .toList();
                context.read<CartCubit>().clearSelectedItems(variantIds);
              }
              _showSuccessDialog();
            }
          } else if (state is CheckoutError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Lỗi đặt hàng: ${state.message}')),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Stack(
              children: [
                CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _buildAppBar(),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            const SizedBox(height: 12),
                            DeliverySection(
                              name: _nameController.text,
                              phone: _phoneController.text,
                              address: _addressController.text,
                              onEdit: () => _showEditAddressModal(),
                            ),
                            const SizedBox(height: 24),
                            CheckoutItemsSection(items: widget.args.items),
                            const SizedBox(height: 24),
                            _buildNotePromo(),
                            const SizedBox(height: 24),
                            PaymentSelectionSection(
                              selectedMethod: _selectedPaymentMethod,
                              onMethodChanged: (method) {
                                setState(() => _selectedPaymentMethod = method);
                              },
                            ),
                            const SizedBox(height: 24),
                            PriceBreakdownSection(
                              subtotal: _subtotal,
                              shipping: _shipping,
                              discount: _discount,
                              vat: _vat,
                              total: _total,
                            ),
                            const SizedBox(height: 140),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                _buildBottomBar(bottomPadding, context, state),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(color: Colors.transparent),
        ),
      ),
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_rounded,
          color: Color(0xFF0F172A),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        "Thanh toán",
        style: TextStyle(
          color: Color(0xFF0F172A),
          fontWeight: FontWeight.w800,
          fontSize: 22,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildNotePromo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Ghi chú",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: _noteController,
            maxLines: 1,
            decoration: const InputDecoration(
              icon: Icon(
                LucideIcons.fileText,
                size: 20,
                color: Color(0xFF94A3B8),
              ),
              hintText: "Thêm ghi chú cho đơn hàng...",
              hintStyle: TextStyle(color: Color(0xFF94A3B8)),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(
    double bottomPadding,
    BuildContext context,
    CheckoutState state,
  ) {
    final bool isLoading = state is CheckoutLoading;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(24, 16, 24, bottomPadding + 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "TỔNG THANH TOÁN",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  formatVND(_total),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 24),
            Expanded(
              child: GestureDetector(
                onTap: isLoading
                    ? () {}
                    : () {
                        if (_nameController.text.trim().isEmpty ||
                            _addressController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Vui lòng thêm đầy đủ thông tin giao hàng.',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        _showConfirmOrderDialog(context);
                      },
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      isLoading ? "Đang xử lý..." : "Đặt hàng",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmOrderDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          "Xác nhận đặt hàng",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        content: Text(
          "Bạn có chắc chắn muốn đặt đơn hàng này với tổng số tiền là ${formatVND(_total)}?",
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 15,
            height: 1.5,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              "Hủy",
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              HapticFeedback.heavyImpact();
              context.read<CheckoutCubit>().placeOrder(
                    receiverName: _nameController.text,
                    receiverPhone: _phoneController.text,
                    shippingAddress: _addressController.text,
                    note: _noteController.text,
                    paymentMethod: _selectedPaymentMethod,
                    items: widget.args.items,
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              "Xác nhận",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditAddressModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return EditAddressModal(
          initialName: _nameController.text,
          initialPhone: _phoneController.text,
          initialAddress: _addressController.text,
          initialSaveAsDefault: _saveAsDefault,
          onSave: (name, phone, address, saveAsDefault) {
            setState(() {
              _nameController.text = name;
              _phoneController.text = phone;
              _addressController.text = address;
              _saveAsDefault = saveAsDefault;
            });
          },
        );
      },
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            SizedBox(
              height: 120,
              width: 120,
              child: Lottie.asset(
                'assets/animations/successfully.json',
                repeat: false,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Đặt hàng thành công!",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              "Đơn hàng của bạn đang được xử lý.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        const OrderHistoryPage(initialStatus: 'PENDING'),
                  ),
                );
              },
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    "Xem đơn hàng",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
