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

const _bg = Color(0xFF07070A);
const _surface = Color(0xFF14141E);
const _border = Color(0xFF2A2A38);
const _accent = Color(0xFFFDE047);
const _pink = Color(0xFFFF6B8A);
const _textHigh = Color(0xFFF1F1F5);
const _textMid = Color(0xFF9191A8);
const _textLow = Color(0xFF4A4A62);

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
                    backgroundColor: _pink,
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
              SnackBar(
                content: Text('Lỗi đặt hàng: ${state.message}'),
                backgroundColor: _pink,
              ),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: _bg,
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
                              onEdit: () => _navigateToEditAddress(),
                            ),
                            const SizedBox(height: 24),
                            CheckoutItemsSection(items: widget.args.items),
                            const SizedBox(height: 24),
                            _buildNoteSection(),
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
      backgroundColor: _bg,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: const Icon(
          Icons.arrow_back_rounded,
          color: Colors.white,
          size: 22,
        ),
      ),
      title: const Text(
        "Thanh toán",
        style: TextStyle(
          color: _textHigh,
          fontWeight: FontWeight.w800,
          fontSize: 20,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildNoteSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Ghi chú",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: _textHigh,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _border, width: 0.5),
          ),
          child: TextField(
            controller: _noteController,
            maxLines: 1,
            style: const TextStyle(color: _textHigh, fontSize: 14),
            decoration: const InputDecoration(
              icon: Icon(LucideIcons.fileText, size: 18, color: _textLow),
              hintText: "Thêm ghi chú cho đơn hàng...",
              hintStyle: TextStyle(color: _textLow, fontSize: 13),
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
        padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPadding + 16),
        decoration: const BoxDecoration(
          color: _bg,
          border: Border(top: BorderSide(color: _border, width: 0.5)),
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
                    color: _textLow,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatVND(_total),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: _textHigh,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
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
                              backgroundColor: _pink,
                            ),
                          );
                          return;
                        }
                        _showConfirmOrderDialog(context);
                      },
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: _accent,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: _accent.withValues(alpha: 0.3),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.black,
                            ),
                          )
                        : const Text(
                            "ĐẶT HÀNG",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
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
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: _border, width: 0.5),
        ),
        title: const Text(
          "Xác nhận đặt hàng",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: _textHigh,
            letterSpacing: -0.5,
          ),
        ),
        content: Text(
          "Bạn có chắc chắn muốn đặt đơn hàng này với tổng số tiền là ${formatVND(_total)}?",
          style: const TextStyle(color: _textMid, fontSize: 14, height: 1.5),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              "Hủy",
              style: TextStyle(
                color: _textMid,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
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
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: _accent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                "Xác nhận",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToEditAddress() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditAddressPage(
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
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: _border, width: 0.5),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
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
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: _textHigh,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Đơn hàng của bạn đang được xử lý.",
              textAlign: TextAlign.center,
              style: TextStyle(color: _textMid, fontSize: 14),
            ),
            const SizedBox(height: 28),
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
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: _accent,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _accent.withValues(alpha: 0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    "XEM ĐƠN HÀNG",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 1,
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
