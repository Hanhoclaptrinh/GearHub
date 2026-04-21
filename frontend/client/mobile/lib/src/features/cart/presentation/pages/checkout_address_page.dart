import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CheckoutAddressPage extends StatefulWidget {
  const CheckoutAddressPage({super.key});

  @override
  State<CheckoutAddressPage> createState() => _CheckoutAddressPageState();
}

class _CheckoutAddressPageState extends State<CheckoutAddressPage>
    with SingleTickerProviderStateMixin {
  // input controller
  final TextEditingController _nameController = TextEditingController(
    text: "Alex Johnson",
  );
  final TextEditingController _phoneController = TextEditingController(
    text: "+1 (555) 000-1234",
  );
  final TextEditingController _addressController = TextEditingController(
    text: "123 Innovation Drive, Silicon Valley, CA",
  );
  final TextEditingController _noteController = TextEditingController();

  // state
  bool _isSummaryExpanded = false;
  bool _isDefaultAddress = true;
  final _selectedPayment = "Visa •••• 4242";

  // dummy items
  final List<Map<String, dynamic>> _cartItems = [
    {
      "name": "Vision Pro Special Edition",
      "variant": "Space Gray / 512GB",
      "price": 3499.0,
      "quantity": 1,
      "image": "assets/images/hero1.png",
    },
    {
      "name": "MagSafe Premium Charger",
      "variant": "Silver",
      "price": 129.0,
      "quantity": 2,
      "image": "assets/images/hero2.png",
    },
    {
      "name": "Leather Loop Band",
      "variant": "Midnight",
      "price": 99.0,
      "quantity": 1,
      "image": "assets/images/hero3.png",
    },
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // tong tien hang
  double get _subtotal => _cartItems.fold(
    0.0,
    (sum, item) => sum + (item['price'] * item['quantity']),
  );
  // tien ship
  double get _shipping => 15.0;
  // discount
  double get _discount => 45.0;
  // tong tien
  double get _total => _subtotal + _shipping - _discount;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

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
                      _buildDeliverySection(),
                      const SizedBox(height: 24),
                      _buildOrderSummary(),
                      const SizedBox(height: 24),
                      _buildNotePromo(),
                      const SizedBox(height: 24),
                      _buildPayment(),
                      const SizedBox(height: 24),
                      _buildPriceBreakdown(),
                      const SizedBox(height: 140),
                    ],
                  ),
                ),
              ),
            ],
          ),
          _buildBottomBar(bottomPadding),
        ],
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
        "CHECKOUT",
        style: TextStyle(
          color: Color(0xFF0F172A),
          fontWeight: FontWeight.w800,
          fontSize: 18,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildDeliverySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          "Delivery Address",
          onAction: () =>
              _showAddressEditor(), // man hinh chinh sua dia chi giao hang
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      LucideIcons.mapPin,
                      size: 20,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _nameController.text,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          _phoneController.text,
                          style: TextStyle(
                            color: const Color(
                              0xFF0F172A,
                            ).withValues(alpha: 0.6),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1, color: Color(0xFFF1F5F9)),
              ),
              Text(
                _addressController.text,
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 15,
                  height: 1.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // don hang - collapse
  Widget _buildOrderSummary() {
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _isSummaryExpanded = !_isSummaryExpanded),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: _cardDecoration(),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    LucideIcons.shoppingBag,
                    size: 20,
                    color: Color(0xFF6366F1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${_cartItems.length} items in package",
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        "Total: \$${_subtotal.toStringAsFixed(0)}",
                        style: TextStyle(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.6),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _isSummaryExpanded
                      ? LucideIcons.chevronUp
                      : LucideIcons.chevronDown,
                  size: 20,
                  color: const Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
        // expand don hang
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: _isSummaryExpanded
              ? Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(20),
                  decoration: _cardDecoration(),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _cartItems.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final item = _cartItems[index];
                      return Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              item['image'],
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    width: 60,
                                    height: 60,
                                    color: const Color(0xFFE2E8F0),
                                    child: const Icon(
                                      LucideIcons.image,
                                      size: 20,
                                    ),
                                  ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: Color(0xFF0F172A),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (item['variant'] != null)
                                  Text(
                                    item['variant'],
                                    style: const TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 12,
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                Text(
                                  "Qty: ${item['quantity']}",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            "\$${(item['price'] * item['quantity']).toStringAsFixed(0)}",
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  // note + promo section
  Widget _buildNotePromo() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          decoration: _cardDecoration(),
          child: TextField(
            controller: _noteController,
            style: const TextStyle(fontSize: 15),
            decoration: const InputDecoration(
              icon: Icon(
                LucideIcons.messageSquare,
                size: 20,
                color: Color(0xFF94A3B8),
              ),
              hintText: "Add note (optional)",
              hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: _cardDecoration(),
          child: const Row(
            children: [
              Icon(LucideIcons.tag, size: 20, color: Color(0xFF10B981)),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Apply voucher",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              Text(
                "Select",
                style: TextStyle(
                  color: Color(0xFF3B82F6),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // payment method section
  Widget _buildPayment() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Payment Method", onAction: () {}),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: _cardDecoration(),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  "VISA",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  _selectedPayment,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              const Icon(
                LucideIcons.circleCheck,
                size: 20,
                color: Color(0xFF10B981),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // price breakdown section
  Widget _buildPriceBreakdown() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _priceRow("Subtotal", "\$${_subtotal.toStringAsFixed(2)}"),
          const SizedBox(height: 12),
          _priceRow("Shipping fee", "\$${_shipping.toStringAsFixed(2)}"),
          const SizedBox(height: 12),
          _priceRow(
            "Discount",
            "-\$${_discount.toStringAsFixed(2)}",
            valueColor: const Color(0xFF10B981),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Total Amount",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Color(0xFF475569),
                ),
              ),
              Text(
                "\$${_total.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                  color: Color(0xFF3B82F6),
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // sticky bottom bar
  Widget _buildBottomBar(double bottomPadding) {
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
                  "TOTAL PAYABLE",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  "\$${_total.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _buildActionButton(
                "Place Order",
                onPressed: () => _handlePlaceOrder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // helper widgets
  Widget _buildSectionHeader(String title, {required VoidCallback onAction}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF3B82F6),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text("Change"),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 15,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _priceRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? const Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String text, {required VoidCallback onPressed}) {
    return _InteractiveButton(
      onPressed: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  // modal dialog
  void _showAddressEditor() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAddressBottomSheet(),
    );
  }

  Widget _buildAddressBottomSheet() {
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Edit Address",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 20),
              // custom map
              Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Stack(
                  children: [
                    const Center(
                      child: Icon(
                        LucideIcons.map,
                        size: 40,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: FloatingActionButton.small(
                        heroTag: "locate",
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                        },
                        backgroundColor: Colors.white,
                        child: const Icon(
                          LucideIcons.locateFixed,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildTextField(
                        _nameController,
                        "Full Name",
                        LucideIcons.user,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        _phoneController,
                        "Phone Number",
                        LucideIcons.phone,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        _addressController,
                        "Address Line",
                        LucideIcons.mapPin,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Checkbox(
                            value: _isDefaultAddress,
                            activeColor: const Color(0xFF3B82F6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            onChanged: (val) =>
                                setModalState(() => _isDefaultAddress = val!),
                          ),
                          const Text(
                            "Set as default address",
                            style: TextStyle(
                              color: Color(0xFF475569),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      _buildActionButton(
                        "Confirm Changes",
                        onPressed: () {
                          setState(() {});
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          icon: Icon(icon, size: 20, color: const Color(0xFF94A3B8)),
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  void _handlePlaceOrder() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.check,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Order Successful!",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              "Your premium gear is being prepared for shipment.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 32),
            _buildActionButton(
              "Track Order",
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _InteractiveButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;

  const _InteractiveButton({required this.child, required this.onPressed});

  @override
  State<_InteractiveButton> createState() => _InteractiveButtonState();
}

class _InteractiveButtonState extends State<_InteractiveButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _scale = 0.96);
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: widget.child,
      ),
    );
  }
}
