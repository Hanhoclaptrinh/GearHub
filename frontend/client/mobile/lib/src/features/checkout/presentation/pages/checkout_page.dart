import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
import 'package:mobile/src/features/profile/presentation/pages/payment_methods_page.dart';
import 'dart:convert';
import 'package:mobile/src/features/profile/presentation/pages/order_history_page.dart';
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

  List<PaymentCard> _savedCards = [];
  PaymentCard? _selectedVnpayCard;
  bool _useSavedCardForVnpay = false;

  @override
  void initState() {
    super.initState();
    _loadDefaultShippingInfo();
    _loadSavedCards();
  }

  ///tải thông tin vận chuyển mặc định
  ///ưu tiên lấy từ api, nếu không có thì lấy từ bộ nhớ cục bộ
  Future<void> _loadDefaultShippingInfo() async {
    //lấy địa chỉ từ api
    try {
      final repository = getIt<AddressRepository>();
      final addresses = await repository.getAddresses();

      //nếu có địa chỉ thì tìm địa chỉ mặc định
      if (addresses.isNotEmpty) {
        final defaultAddr = addresses.firstWhere(
          (addr) => addr.isDefault,
          orElse: () => addresses.first,
        );

        //cập nhật giao diện với thông tin api
        setState(() {
          _nameController.text = defaultAddr.fullName;
          _phoneController.text = defaultAddr.phone;
          _addressController.text = defaultAddr.fullAddressText;
        });
        return;
      }
    } catch (_) {}

    //lấy thông tin từ local làm fallback
    try {
      final prefs = getIt<SharedPreferences>();
      final savedName = prefs.getString('default_receiver_name');
      final savedPhone = prefs.getString('default_receiver_phone');
      final savedAddress = prefs.getString('default_shipping_address');

      //nếu có thông tin lưu sẵn thì cập nhật
      if (savedName != null && savedName.isNotEmpty) {
        setState(() {
          _nameController.text = savedName;
          _phoneController.text = savedPhone ?? '';
          _addressController.text = savedAddress ?? '';
        });
      }
    } catch (_) {}
  }

  Future<void> _loadSavedCards() async {
    try {
      final prefs = getIt<SharedPreferences>();
      final jsonStr = prefs.getString('saved_payment_cards');
      if (jsonStr != null) {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        final cards = decoded
            .map((item) => PaymentCard.fromJson(item as Map<String, dynamic>))
            .toList();
        setState(() {
          _savedCards = cards;
          if (cards.isNotEmpty) {
            _selectedVnpayCard = cards.first;
            _useSavedCardForVnpay = true;
          }
        });
      }
    } catch (_) {}
  }

  void _showChangeCardDialog() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text(
          'Chọn thẻ thanh toán',
          style: TextStyle(fontWeight: FontWeight.w800, color: cs.onSurface, fontSize: 15),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _savedCards.length,
            itemBuilder: (context, index) {
              final card = _savedCards[index];
              return ListTile(
                title: Text(
                  "${card.bankName.toUpperCase()} (ATM)",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: cs.onSurface),
                ),
                subtitle: Text(
                  "•••• •••• •••• ${card.cardNumber.substring(card.cardNumber.length - 4)}",
                  style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: cs.onSurfaceVariant),
                ),
                trailing: card.id == _selectedVnpayCard?.id
                    ? Icon(Icons.check_circle_rounded, color: cs.primary)
                    : null,
                onTap: () {
                  setState(() {
                    _selectedVnpayCard = card;
                  });
                  Navigator.pop(dialogCtx);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildVnpayCardSelector(bool isDark) {
    final cs = Theme.of(context).colorScheme;
    if (_savedCards.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          "Cấu hình thanh toán VNPay",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        
        // Option 1: Saved card
        InkWell(
          onTap: () {
            setState(() {
              _useSavedCardForVnpay = true;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161619) : const Color(0xFFF9F9FB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _useSavedCardForVnpay ? cs.primary : cs.outlineVariant,
                width: _useSavedCardForVnpay ? 1.2 : 0.8,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _useSavedCardForVnpay ? Icons.radio_button_checked : Icons.radio_button_off,
                  size: 18,
                  color: _useSavedCardForVnpay ? cs.primary : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Sử dụng thẻ đã lưu",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      if (_selectedVnpayCard != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          "${_selectedVnpayCard!.bankName.toUpperCase()} •••• ${_selectedVnpayCard!.cardNumber.substring(_selectedVnpayCard!.cardNumber.length - 4)}",
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (_useSavedCardForVnpay && _savedCards.length > 1)
                  TextButton(
                    onPressed: _showChangeCardDialog,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      "Thay đổi",
                      style: TextStyle(fontSize: 11, color: cs.secondary, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 10),
        
        // Option 2: Manual input
        InkWell(
          onTap: () {
            setState(() {
              _useSavedCardForVnpay = false;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161619) : const Color(0xFFF9F9FB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: !_useSavedCardForVnpay ? cs.primary : cs.outlineVariant,
                width: !_useSavedCardForVnpay ? 1.2 : 0.8,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  !_useSavedCardForVnpay ? Icons.radio_button_checked : Icons.radio_button_off,
                  size: 18,
                  color: !_useSavedCardForVnpay ? cs.primary : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Text(
                  "Nhập thông tin thẻ thủ công khi thanh toán",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  ///lưu thông tin vận chuyển vào local
  ///chỉ thực hiện nếu người dùng chọn lưu làm mặc định
  Future<void> _saveDefaultShippingInfo() async {
    //kiểm tra điều kiện lưu
    if (!_saveAsDefault) return;

    try {
      final prefs = getIt<SharedPreferences>();

      //lưu lần lượt tên, số điện thoại và địa chỉ
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
      (_subtotal / 1.08); //trích xuất 8% thuế VAT từ tổng phụ đã bao gồm VAT

  //subtotal đã bao gồm VAT sẵn
  double get _subtotalWithVat => _subtotal;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<CheckoutCubit>()),
        //nạp cubit xử lý khuyến mãi và tải dữ liệu khuyến mãi ban đầu
        BlocProvider(
          create: (_) => getIt<CheckoutPromotionCubit>()..loadPromotionData(),
        ),
      ],
      child: BlocConsumer<CheckoutCubit, CheckoutState>(
        ///lắng nghe trạng thái từ checkoutcubit để xử lý điều hướng và thông báo
        ///bao gồm xử lý thanh toán vnpay và hoàn tất đơn hàng
        listener: (context, state) async {
          //xử lý khi đặt hàng thành công
          if (state is OrderPlacedSuccess) {
            //lưu thông tin mặc định nếu user chọn
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
                        selectedCard: _useSavedCardForVnpay ? _selectedVnpayCard : null,
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
                  SnackBar(
                    content: const Text(
                      'Thanh toán VNPay không thành công hoặc đã bị hủy.',
                    ),
                    backgroundColor: Theme.of(context).colorScheme.error,
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
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final bgColor = isDark ? const Color(0xFF121214) : Colors.white;

          return Scaffold(
            backgroundColor: bgColor,
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
                                    _buildSectionDivider(isDark),
                                    CheckoutItemsSection(
                                      items: widget.args.items,
                                    ),
                                    _buildSectionDivider(isDark),
                                    _buildNoteSection(),
                                    _buildSectionDivider(isDark),
                                    PaymentSelectionSection(
                                      selectedMethod: _selectedPaymentMethod,
                                      onMethodChanged: (method) {
                                        setState(
                                          () => _selectedPaymentMethod = method,
                                        );
                                      },
                                    ),
                                    if (_selectedPaymentMethod == "PAYMENT_GATEWAY")
                                      _buildVnpayCardSelector(isDark),
                                    _buildSectionDivider(isDark),
                                    PromotionSection(
                                      subtotal: _subtotalWithVat,
                                    ),
                                    _buildSectionDivider(isDark),
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

  Widget _buildSectionDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Divider(
        color: isDark ? const Color(0xFF2A2A2F) : const Color(0xFFE4E4E7),
        height: 1,
        thickness: 0.5,
      ),
    );
  }

  Widget _buildAppBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121214) : Colors.white;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF111111);

    return SliverAppBar(
      pinned: true,
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: bgColor,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: primaryTextColor,
          size: 22,
        ),
      ),
      title: Text(
        "Thanh toán",
        style: TextStyle(
          color: primaryTextColor,
          fontWeight: FontWeight.w800,
          fontSize: 20,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildNoteSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF111111);
    final secondaryTextColor = isDark
        ? const Color(0xFFA1A1AA)
        : const Color(0xFF71717A);
    final dividerColor = isDark
        ? const Color(0xFF2A2A2F)
        : const Color(0xFFE4E4E7);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Ghi chú",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: primaryTextColor,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _noteController,
          maxLines: 1,
          style: TextStyle(color: primaryTextColor, fontSize: 14),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            icon: FaIcon(
              FontAwesomeIcons.solidNoteSticky,
              size: 18,
              color: secondaryTextColor,
            ),
            hintText: "Thêm ghi chú cho đơn hàng...",
            hintStyle: TextStyle(color: secondaryTextColor, fontSize: 13),
            filled: false,
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: dividerColor, width: 1.0),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: primaryTextColor, width: 1.5),
            ),
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: dividerColor),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final barBgColor = isDark ? const Color(0xFF1A1A1E) : Colors.white;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF111111);
    final secondaryTextColor = isDark
        ? const Color(0xFFA1A1AA)
        : const Color(0xFF71717A);

    final buttonBgColor = isDark ? Colors.white : const Color(0xFF111111);
    final buttonTextColor = isDark ? const Color(0xFF111111) : Colors.white;

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
            decoration: BoxDecoration(
              color: barBgColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "TỔNG THANH TOÁN",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: secondaryTextColor,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatVND(total),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: primaryTextColor,
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
                                SnackBar(
                                  content: const Text(
                                    'Vui lòng thêm đầy đủ thông tin giao hàng.',
                                  ),
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.error,
                                ),
                              );
                              return;
                            }
                            _showConfirmOrderDialog(context, total);
                          },
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: buttonBgColor,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Center(
                        child: isLoading
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: buttonTextColor,
                                ),
                              )
                            : Text(
                                "ĐẶT HÀNG",
                                style: TextStyle(
                                  color: buttonTextColor,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  letterSpacing: 0.5,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF111111);
    final secondaryTextColor = isDark
        ? const Color(0xFFA1A1AA)
        : const Color(0xFF71717A);
    final buttonBgColor = isDark ? Colors.white : const Color(0xFF111111);
    final buttonTextColor = isDark ? const Color(0xFF111111) : Colors.white;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E22) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: isDark ? const Color(0xFF2A2A2F) : const Color(0xFFE4E4E7),
            width: 0.5,
          ),
        ),
        title: Text(
          "Xác nhận đặt hàng",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: primaryTextColor,
            letterSpacing: -0.5,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Bạn có chắc chắn muốn đặt đơn hàng này với tổng số tiền là ${formatVND(total)}?",
              style: TextStyle(
                color: secondaryTextColor,
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
                    color: Color(0xFF10B981),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Voucher: ${promoState.selectedVoucher!.code}",
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF10B981),
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
            child: Text(
              "Hủy",
              style: TextStyle(
                color: secondaryTextColor,
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
                color: buttonBgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                "Xác nhận",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: buttonTextColor,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF111111);
    final secondaryTextColor = isDark
        ? const Color(0xFFA1A1AA)
        : const Color(0xFF71717A);
    final buttonBgColor = isDark ? Colors.white : const Color(0xFF111111);
    final buttonTextColor = isDark ? const Color(0xFF111111) : Colors.white;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E22) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(
            color: isDark ? const Color(0xFF2A2A2F) : const Color(0xFFE4E4E7),
            width: 0.5,
          ),
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
            Text(
              "Đặt hàng thành công!",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: primaryTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Đơn hàng của bạn đang được xử lý.",
              textAlign: TextAlign.center,
              style: TextStyle(color: secondaryTextColor, fontSize: 14),
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
                  color: buttonBgColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    "XEM ĐƠN HÀNG",
                    style: TextStyle(
                      color: buttonTextColor,
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
