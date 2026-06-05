import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lottie/lottie.dart';
import 'package:mobile/src/features/checkout/presentation/state/checkout_promotion_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/src/core/di/injection.dart';
import 'package:mobile/src/core/utils/formatter_utils.dart';
import 'package:mobile/src/features/cart/domain/entities/cart_item_entity.dart';
import 'package:mobile/src/features/cart/presentation/state/cart_cubit.dart';
import 'package:mobile/src/features/checkout/presentation/state/checkout_cubit.dart';
import 'package:mobile/src/features/checkout/presentation/state/checkout_state.dart';
import 'package:mobile/src/features/checkout/presentation/state/checkout_promotion_cubit.dart';
import 'package:mobile/src/features/checkout/presentation/widgets/delivery_section.dart';
import 'package:mobile/src/features/checkout/presentation/widgets/checkout_items_section.dart';
import 'package:mobile/src/features/checkout/presentation/widgets/payment_selection_section.dart';
import 'package:mobile/src/features/checkout/presentation/widgets/price_breakdown_section.dart';
import 'package:mobile/src/features/checkout/presentation/widgets/promotion_section.dart';
import 'vnpay_payment_page.dart';
import 'package:mobile/src/features/profile/presentation/pages/order_history_page.dart';
import 'package:mobile/src/core/theme/app_colors.dart';
import 'package:mobile/src/features/address/presentation/pages/addresses_page.dart';
import 'package:mobile/src/features/address/data/models/address_model.dart';
import 'package:mobile/src/features/address/domain/repositories/address_repository.dart';

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
  final bool _saveAsDefault = true;

  @override
  void initState() {
    super.initState();
    _loadDefaultShippingInfo();
  }

  Future<void> _loadDefaultShippingInfo() async {
    // địa chỉ mặc định từ api
    try {
      final repository = getIt<AddressRepository>();
      final addresses = await repository.getAddresses();
      if (addresses.isNotEmpty) {
        final defaultAddr = addresses.firstWhere(
          (addr) => addr.isDefault,
          orElse: () => addresses.first,
        );
        setState(() {
          _nameController.text = defaultAddr.fullName;
          _phoneController.text = defaultAddr.phone;
          _addressController.text = defaultAddr.fullAddressText;
        });
        return;
      }
    } catch (_) {}

    // fallback
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
  double get _vat =>
      _subtotal -
      (_subtotal / 1.08); // trích xuất 8% thuế VAT từ tổng phụ đã bao gồm VAT

  // subtotal đã bao gồm VAT sẵn
  double get _subtotalWithVat => _subtotal;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<CheckoutCubit>()),
        BlocProvider(
          create: (_) => getIt<CheckoutPromotionCubit>()..loadPromotionData(),
        ),
      ],
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
                    backgroundColor: AppColors.accentPink,
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
                backgroundColor: AppColors.accentPink,
              ),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Stack(
              children: [
                CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _buildAppBar(),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child:
                            BlocBuilder<
                              CheckoutPromotionCubit,
                              CheckoutPromotionState
                            >(
                              builder: (context, promoState) {
                                final voucherDiscount = promoState
                                    .calculateVoucherDiscount(_subtotalWithVat);
                                final total =
                                    (_subtotalWithVat +
                                            _shipping -
                                            voucherDiscount)
                                        .clamp(0.0, double.infinity);

                                return Column(
                                  children: [
                                    const SizedBox(height: 12),
                                    DeliverySection(
                                      name: _nameController.text,
                                      phone: _phoneController.text,
                                      address: _addressController.text,
                                      onEdit: () => _navigateToSelectAddress(),
                                    ),
                                    const SizedBox(height: 24),
                                    CheckoutItemsSection(
                                      items: widget.args.items,
                                    ),
                                    const SizedBox(height: 24),
                                    _buildNoteSection(),
                                    const SizedBox(height: 24),
                                    PaymentSelectionSection(
                                      selectedMethod: _selectedPaymentMethod,
                                      onMethodChanged: (method) {
                                        setState(
                                          () => _selectedPaymentMethod = method,
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 24),
                                    PromotionSection(
                                      subtotal: _subtotalWithVat,
                                    ),
                                    const SizedBox(height: 24),
                                    PriceBreakdownSection(
                                      subtotal: _subtotal,
                                      shipping: _shipping,
                                      vat: _vat,
                                      voucherDiscount: voucherDiscount,
                                      total: total,
                                    ),
                                    const SizedBox(height: 140),
                                  ],
                                );
                              },
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
      backgroundColor: AppColors.background,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: const Icon(
          Icons.arrow_back_rounded,
          color: AppColors.textPrimary,
          size: 22,
        ),
      ),
      title: const Text(
        "Thanh toán",
        style: TextStyle(
          color: AppColors.textPrimary,
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
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.cardSurfaceAlt,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderCardStrong, width: 0.5),
          ),
          child: TextField(
            controller: _noteController,
            maxLines: 1,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: const InputDecoration(
              icon: Icon(
                LucideIcons.fileText,
                size: 18,
                color: AppColors.textDim,
              ),
              hintText: "Thêm ghi chú cho đơn hàng...",
              hintStyle: TextStyle(color: AppColors.textDim, fontSize: 13),
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
      child: BlocBuilder<CheckoutPromotionCubit, CheckoutPromotionState>(
        builder: (context, promoState) {
          final voucherDiscount = promoState.calculateVoucherDiscount(
            _subtotalWithVat,
          );
          final total = (_subtotalWithVat + _shipping - voucherDiscount).clamp(
            0.0,
            double.infinity,
          );

          return Container(
            padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPadding + 16),
            decoration: const BoxDecoration(
              color: AppColors.background,
              border: Border(
                top: BorderSide(color: AppColors.borderCardStrong, width: 0.5),
              ),
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
                        color: AppColors.textDim,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatVND(total),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
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
                                  backgroundColor: AppColors.accentPink,
                                ),
                              );
                              return;
                            }
                            _showConfirmOrderDialog(context, total);
                          },
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.champagne,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.champagne.withValues(alpha: 0.3),
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
                                  color: AppColors.ctaPrimaryText,
                                ),
                              )
                            : const Text(
                                "ĐẶT HÀNG",
                                style: TextStyle(
                                  color: AppColors.ctaPrimaryText,
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
          );
        },
      ),
    );
  }

  void _showConfirmOrderDialog(BuildContext context, double total) {
    final promoState = context.read<CheckoutPromotionCubit>().state;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardSurfaceAlt,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.borderCardStrong, width: 0.5),
        ),
        title: const Text(
          "Xác nhận đặt hàng",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Bạn có chắc chắn muốn đặt đơn hàng này với tổng số tiền là ${formatVND(total)}?",
              style: const TextStyle(
                color: AppColors.slate400,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            if (promoState.selectedVoucher != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.local_offer_rounded,
                    size: 14,
                    color: AppColors.emerald400,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Voucher: ${promoState.selectedVoucher!.code}",
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.emerald400,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              "Hủy",
              style: TextStyle(
                color: AppColors.slate400,
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
                voucherId: promoState.selectedVoucher?.id,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.champagne,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                "Xác nhận",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: AppColors.ctaPrimaryText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToSelectAddress() async {
    final selectedAddress = await Navigator.of(context).push<AddressModel>(
      MaterialPageRoute(builder: (_) => const AddressesPage(selectMode: true)),
    );

    if (selectedAddress != null) {
      setState(() {
        _nameController.text = selectedAddress.fullName;
        _phoneController.text = selectedAddress.phone;
        _addressController.text = selectedAddress.fullAddressText;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardSurfaceAlt,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: AppColors.borderCardStrong, width: 0.5),
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
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Đơn hàng của bạn đang được xử lý.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.slate400, fontSize: 14),
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
                  color: AppColors.champagne,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.champagne.withValues(alpha: 0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    "XEM ĐƠN HÀNG",
                    style: TextStyle(
                      color: AppColors.ctaPrimaryText,
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
