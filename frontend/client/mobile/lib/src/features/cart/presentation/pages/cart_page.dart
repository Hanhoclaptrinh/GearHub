import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/features/cart/data/services/cart_service.dart';
import 'package:mobile/src/shared/models/product.dart';
import 'package:mobile/src/shared/widgets/small_product_card.dart';
import 'package:mobile/src/shared/styles/app_colors.dart';
import 'package:mobile/src/features/home/presentation/pages/main_screen.dart';
import 'package:mobile/src/features/product_detail/presentation/pages/product_detail_page.dart';
import 'package:lottie/lottie.dart';
import '../widgets/cart_item_card.dart';
import '../widgets/cart_extra_views.dart';

class CartPage extends StatefulWidget {
  final bool isNavVisible;
  const CartPage({super.key, this.isNavVisible = true});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final List<Product> _recommendations = [
    const Product(
      id: 'r1',
      name: 'USB-C Cable',
      tagline: 'Fast Charging 2m',
      price: 29,
      image: 'assets/images/hero1.png',
    ),
    const Product(
      id: 'r2',
      name: 'Leather Case',
      tagline: 'Premium Grade Leather',
      price: 59,
      image: 'assets/images/hero4.png',
    ),
    const Product(
      id: 'r3',
      name: 'Screen Protector',
      tagline: 'Tempered Glass',
      price: 19,
      image: 'assets/images/hero3.png',
    ),
  ];

  // xoa item khoi cart
  void _removeItem(String productId, String productName) {
    CartService().removeItem(productId);
    HapticFeedback.mediumImpact();
  }

  void _showCheckoutBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => const _CheckoutBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: CartService(),
      builder: (context, _) {
        final items = CartService().items;
        final selectedItemsCount = items.where((i) => i.isSelected).length;
        final hasSelection = selectedItemsCount > 0;

        // check cart empty
        if (items.isEmpty) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: _buildSimpleAppBar(), // simple appbar khi cart empty
            body: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.asset(
                      'assets/animations/emptycart.json',
                      height: 250,
                      repeat: true,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "YOUR CART IS EMPTY",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Looks like you haven't added any premium gear to your selection yet.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 48),
                    _buildEmptyStateButton(context),
                  ],
                ),
              ),
            ),
          );
        }

        // cart co item
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Stack(
            children: [
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildSliverAppBar(),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final item = items[index];
                        return CartItemCard(
                          item: item,
                          // tang giam so luong
                          onIncrement: () => CartService().updateQuantity(
                            item.product.id,
                            item.quantity + 1,
                          ),
                          onDecrement: () => CartService().updateQuantity(
                            item.product.id,
                            item.quantity - 1,
                          ),
                          // xoa item
                          onDelete: () =>
                              _removeItem(item.product.id, item.product.name),
                          // select/unselect item
                          onToggleSelected: () =>
                              CartService().toggleSelection(item.product.id),
                          // xem san pham tuong tu
                          onViewSimilar: () {
                            print("View similar for ${item.product.name}");
                          },
                          // long press xem chi tiet san pham
                          onLongPress: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    ProductDetailPage(product: item.product),
                              ),
                            );
                          },
                        );
                      }, childCount: items.length),
                    ),
                  ),
                  // promo section
                  const SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    sliver: SliverToBoxAdapter(child: PromoSection()),
                  ),
                  // recommendations section
                  _buildRecommendationsSection(),
                  const SliverToBoxAdapter(child: SizedBox(height: 180)),
                ],
              ),
              // checkout bar
              Builder(
                builder: (context) {
                  // kiem tra trang thai bottom bar
                  final bool isNavVisible = widget.isNavVisible;
                  final double bottomPadding = MediaQuery.of(
                    context,
                  ).padding.bottom;

                  final double targetBottom = isNavVisible
                      ? (bottomPadding + 16)
                      : (bottomPadding - 80);

                  return AnimatedPositioned(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOutCubic,
                    left: 0,
                    right: 0,
                    bottom: targetBottom,
                    child: _buildAnchoredCheckoutBar(
                      hasSelection,
                      CartService().subtotal,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildSimpleAppBar() {
    return AppBar(
      elevation: 0,
      centerTitle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      title: const Text(
        'MY CART',
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 18,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    const double expandedHeight = 120;
    const double collapsedHeight = kToolbarHeight;
    final colorScheme = Theme.of(context).colorScheme;

    return SliverAppBar(
      pinned: true,
      stretch: true,
      expandedHeight: expandedHeight,
      collapsedHeight: collapsedHeight,
      toolbarHeight: collapsedHeight,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final double currentExtent = constraints.maxHeight;
          final double progress =
              ((currentExtent - (collapsedHeight + statusBarHeight)) /
                      (expandedHeight - (collapsedHeight + statusBarHeight)))
                  .clamp(0.0, 1.0);

          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor.withValues(
                alpha: (1.0 - progress).clamp(0.0, 0.9),
              ),
            ),
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(top: statusBarHeight),
                child: Transform.scale(
                  scale: 1.0 + (progress * 0.3),
                  child: Text(
                    'MY CART',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnchoredCheckoutBar(bool hasSelection, double total) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.navyDark,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDark.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TOTAL SELECTION',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasSelection ? '\$${total.toStringAsFixed(0)}' : '\$0',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: hasSelection ? _showCheckoutBottomSheet : null,
                borderRadius: BorderRadius.circular(18),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: hasSelection
                        ? const Color(0xFF3B82F6)
                        : Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: hasSelection
                        ? [
                            BoxShadow(
                              color: const Color(
                                0xFF3B82F6,
                              ).withValues(alpha: 0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        hasSelection ? 'CHECKOUT' : 'BUY NOW',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        LucideIcons.arrowRight,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Text(
              'YOU MIGHT ALSO LIKE',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Colors.black38,
                letterSpacing: 1.5,
              ),
            ),
          ),
          SizedBox(
            height: 180,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _recommendations.length,
              separatorBuilder: (context, index) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                return SmallProductCard(
                  product: _recommendations[index],
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            ProductDetailPage(product: _recommendations[index]),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final mainScreen = context.findAncestorStateOfType<MainScreenState>();
        if (mainScreen != null) {
          mainScreen.onItemTapped(0);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.navyDark, AppColors.navyLight],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.navyDark.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.shoppingBag, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Text(
              "START SHOPPING",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 14,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckoutBottomSheet extends StatelessWidget {
  const _CheckoutBottomSheet();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Order Summary',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        _buildStepItem(
                          icon: LucideIcons.mapPin,
                          title: 'Shipping Address',
                          subtitle: '123 Luxury Street, Ho Chi Minh City',
                          onTap: () {},
                        ),
                        const SizedBox(height: 20),
                        _buildStepItem(
                          icon: LucideIcons.wallet,
                          title: 'Payment Method',
                          subtitle: 'VNPAY Wallet',
                          onTap: () {},
                          trailing: Image.asset(
                            'assets/images/hero1.png',
                            height: 20,
                            errorBuilder: (_, __, ___) =>
                                const Icon(LucideIcons.creditCard, size: 20),
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Divider(thickness: 0.5),
                        const SizedBox(height: 16),
                        _buildPriceRow(
                          'Subtotal',
                          '\$${CartService().subtotal.toStringAsFixed(0)}',
                        ),
                        _buildPriceRow('Shipping', '\$15.00'),
                        _buildPriceRow(
                          'Discount',
                          '-\$50.00',
                          color: Colors.green,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 30,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total to Pay',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '\$${(CartService().subtotal + 15 - 50).toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSlideToPay(context),
                    ],
                  ),
                ),
                SizedBox(height: bottomPadding + 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
            trailing ??
                const Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: Colors.grey,
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildSlideToPay(BuildContext context) {
    return _SlideToPayAction(
      onSuccess: () {
        HapticFeedback.heavyImpact();
        Navigator.pop(context);
        _showSuccessDialog(context);
      },
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  LucideIcons.circleCheckBig,
                  color: Colors.green,
                  size: 80,
                ),
                const SizedBox(height: 24),
                const Text(
                  'PAYMENT SUCCESS',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your premium gear is on the way!',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 16,
                    ),
                  ),
                  child: const Text(
                    'AWESOME',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SlideToPayAction extends StatefulWidget {
  final VoidCallback onSuccess;

  const _SlideToPayAction({required this.onSuccess});

  @override
  State<_SlideToPayAction> createState() => _SlideToPayActionState();
}

class _SlideToPayActionState extends State<_SlideToPayAction> {
  double _dragValue = 0.0;
  bool _isFinished = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        const double handleWidth = 100.0;
        final double maxDragDistance = totalWidth - handleWidth;

        return Container(
          width: double.infinity,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              const Center(
                child: Text(
                  'SLIDE TO PAY',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
              Positioned(
                left: _dragValue,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (_isFinished) return;
                    setState(() {
                      _dragValue += details.delta.dx;
                      _dragValue = _dragValue.clamp(0.0, maxDragDistance);
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (_isFinished) return;
                    if (_dragValue >= maxDragDistance * 0.9) {
                      setState(() {
                        _dragValue = maxDragDistance;
                        _isFinished = true;
                      });
                      widget.onSuccess();
                    } else {
                      setState(() {
                        _dragValue = 0;
                      });
                    }
                  },
                  child: Container(
                    width: handleWidth,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(4, 0),
                        ),
                      ],
                    ),
                    child: const Icon(
                      LucideIcons.arrowRight,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
