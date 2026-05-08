import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/core/utils/formatter_utils.dart';
import 'package:mobile/src/features/auth/presentation/pages/login_page.dart';
import 'package:mobile/src/features/auth/presentation/state/auth_cubit.dart';
import 'package:mobile/src/features/auth/presentation/state/auth_state.dart';
import 'package:mobile/src/features/cart/presentation/state/cart_cubit.dart';
import 'package:mobile/src/features/cart/presentation/state/cart_state.dart';
import 'package:mobile/src/features/cart/domain/entities/cart_item_entity.dart';
import 'package:mobile/src/features/cart/presentation/widgets/cart_extra_views.dart';
import 'package:mobile/src/features/cart/presentation/widgets/cart_item_card.dart';
import 'package:mobile/src/features/checkout/presentation/pages/checkout_page.dart';
import 'package:mobile/src/shared/models/product_model.dart';
import 'package:mobile/src/features/home/presentation/pages/main_screen.dart';
import 'package:mobile/src/features/product_detail/presentation/pages/product_detail_page.dart';
import 'package:mobile/src/shared/widgets/large_product_card.dart';

const _bg = Color(0xFF0A0A10);
const _surface = Color(0xFF14141E);
const _surfaceAlt = Color(0xFF1C1C28);
const _border = Color(0xFF2A2A38);
const _accent = Color(0xFFF59E0B);
const _accentSoft = Color(0x26F59E0B);
const _pink = Color(0xFFFF6B8A);
const _pinkSoft = Color(0x1FFF6B8A);
const _textHigh = Color(0xFFF1F1F5);
const _textMid = Color(0xFF9191A8);
const _textLow = Color(0xFF4A4A62);

class CartPage extends StatefulWidget {
  final bool isNavVisible;
  const CartPage({super.key, this.isNavVisible = true});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final List<ProductModel> _recommendations = [
    const ProductModel(
      id: 'r1',
      name: 'USB-C Cable',
      tagline: 'Fast Charging 2m',
      price: 29,
      image:
          'https://down-vn.img.susercontent.com/file/sg-11134201-7rd4p-lvd1g4prhxo5f0',
      description: "test",
    ),
    const ProductModel(
      id: 'r2',
      name: 'Leather Case',
      tagline: 'Premium Grade Leather',
      price: 59,
      image:
          'https://cdn.shopify.com/s/files/1/0384/6721/files/856504011970_C_iPhone_de13076c-73cb-4577-8ae4-4f8c322185dd.jpg?v=1758564505&width=2800&height=2800&crop=center',
      description: "test",
    ),
    const ProductModel(
      id: 'r3',
      name: 'Screen Protector',
      tagline: 'Tempered Glass',
      price: 19,
      image:
          'https://tse3.mm.bing.net/th/id/OIP.bhLhE--GloVMYckJl6LnZQHaHk?rs=1&pid=ImgDetMain&o=7&rm=3',
      description: "test",
    ),
  ];

  void _removeItem(String itemId) {
    context.read<CartCubit>().removeItem(itemId);
    HapticFeedback.mediumImpact();
  }

  void _showAuthRequiredBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(32),
          decoration: const BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
            border: Border(top: BorderSide(color: _border, width: 0.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _border,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 32),
              Container(
                height: 64,
                width: 64,
                decoration: const BoxDecoration(
                  color: _accentSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.lock, color: _accent, size: 28),
              ),
              const SizedBox(height: 24),
              const Text(
                'YÊU CẦU ĐĂNG NHẬP',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: _textHigh,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Vui lòng đăng nhập để tiếp tục thanh toán, lưu giỏ hàng và nhận các ưu đãi thành viên đặc biệt.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: _textMid,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const LoginPage()));
                },
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _accent,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: _accent.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'ĐĂNG NHẬP NGAY',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: _textLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'ĐỂ SAU',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _navigateToCheckout(List<CartItemEntity> selectedItems) {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      _showAuthRequiredBottomSheet(context);
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CheckoutPage(
          args: CheckoutArguments(items: selectedItems, isFromCart: true),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CartCubit>().loadCart();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, state) {
        if (state is CartLoading) {
          return const Scaffold(
            backgroundColor: _bg,
            body: Center(
              child: CircularProgressIndicator(color: _accent, strokeWidth: 2),
            ),
          );
        }

        if (state is CartError) {
          return Scaffold(
            backgroundColor: _bg,
            appBar: _buildSimpleAppBar(),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.triangleAlert, size: 48, color: _pink),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: _textMid, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () => context.read<CartCubit>().loadCart(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: _accentSoft,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _accent.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Text(
                        'Thử lại',
                        style: TextStyle(
                          color: _accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        List<CartItemEntity> items = [];
        double totalSelection = 0.0;
        bool hasSelection = false;

        if (state.cart != null) {
          items = state.cart!.items;
          final selectedItems = items.where((i) => i.isSelected);
          hasSelection = selectedItems.isNotEmpty;
          totalSelection = selectedItems.fold(
            0.0,
            (sum, i) => sum + i.itemTotal,
          );
        }

        // empty state
        if (items.isEmpty) {
          return Scaffold(
            backgroundColor: _bg,
            appBar: _buildSimpleAppBar(),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.asset(
                      'assets/animations/emptycart.json',
                      height: 200,
                      repeat: true,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        LucideIcons.shoppingCart,
                        size: 80,
                        color: _textLow,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      "GIỎ HÀNG RỖNG",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: _textHigh,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Chưa có sản phẩm nào trong giỏ hàng.\nHãy khám phá ngay!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: _textMid,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildEmptyStateButton(context),
                  ],
                ),
              ),
            ),
          );
        }

        // cart with items
        return Scaffold(
          backgroundColor: _bg,
          body: Stack(
            children: [
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildSliverAppBar(),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: BlocBuilder<CartCubit, CartState>(
                        builder: (context, state) {
                          bool allSelected = false;
                          if (state.cart != null) {
                            allSelected =
                                state.cart!.items.isNotEmpty &&
                                state.cart!.items.every((i) => i.isSelected);
                          }
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  context.read<CartCubit>().toggleSelectAll(
                                    !allSelected,
                                  );
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: allSelected
                                            ? _accent
                                            : Colors.transparent,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: allSelected
                                              ? _accent
                                              : _textLow,
                                          width: 2,
                                        ),
                                      ),
                                      child: allSelected
                                          ? const Icon(
                                              Icons.check,
                                              size: 12,
                                              color: Colors.black,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      allSelected
                                          ? 'Bỏ chọn tất cả'
                                          : 'Chọn tất cả',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: _textMid,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (state.cart != null &&
                                  state.cart!.items.isNotEmpty)
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.heavyImpact();
                                    _showClearCartDialog(context);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _pinkSoft,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          LucideIcons.trash2,
                                          size: 13,
                                          color: _pink,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          'Xóa tất cả',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: _pink,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),

                  // cart items
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final item = items[index];
                        return CartItemCard(
                          item: item,
                          onIncrement: () => context
                              .read<CartCubit>()
                              .updateQuantity(item.id, item.quantity + 1),
                          onDecrement: () => context
                              .read<CartCubit>()
                              .updateQuantity(item.id, item.quantity - 1),
                          onDelete: () => _removeItem(item.id),
                          onToggleSelected: () => context
                              .read<CartCubit>()
                              .toggleItemSelection(item.id),
                          onViewSimilar: () {
                            debugPrint("View similar for ${item.product.name}");
                          },
                          onLongPress: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ProductDetailPage(
                                  product: item.product,
                                  initialAttributes: item
                                      .productVariant
                                      .attributes
                                      .map((k, v) => MapEntry(k, v.toString())),
                                ),
                              ),
                            );
                          },
                        );
                      }, childCount: items.length),
                    ),
                  ),

                  // promo
                  const SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    sliver: SliverToBoxAdapter(child: PromoSection()),
                  ),

                  // recommendations
                  _buildRecommendationsSection(),

                  const SliverToBoxAdapter(child: SizedBox(height: 180)),
                ],
              ),

              // floating checkout bar
              Builder(
                builder: (context) {
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
                      totalSelection,
                      items,
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

  void _showClearCartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: _surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: _border, width: 0.5),
          ),
          title: const Text(
            'Xóa giỏ hàng',
            style: TextStyle(fontWeight: FontWeight.w800, color: _textHigh),
          ),
          content: const Text(
            'Bạn có chắc chắn muốn xóa toàn bộ sản phẩm trong giỏ hàng?',
            style: TextStyle(color: _textMid, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Hủy',
                style: TextStyle(color: _textMid, fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.read<CartCubit>().clearCart();
              },
              child: const Text(
                'Xóa',
                style: TextStyle(color: _pink, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
    );
  }

  PreferredSizeWidget _buildSimpleAppBar() {
    return AppBar(
      elevation: 0,
      centerTitle: true,
      backgroundColor: _bg,
      title: const Text(
        'Giỏ hàng',
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 22,
          color: _textHigh,
          letterSpacing: -0.5,
        ),
      ),
      iconTheme: const IconThemeData(color: _textMid),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      floating: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: _bg,
      automaticallyImplyLeading: false,
      titleSpacing: 20,
      title: const Text(
        'Giỏ hàng',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w900,
          color: _textHigh,
          letterSpacing: -0.5,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(
            LucideIcons.messageCircle,
            color: _textMid,
            size: 24,
          ),
          onPressed: (){},
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildAnchoredCheckoutBar(
    bool hasSelection,
    double total,
    List<CartItemEntity> items,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng cộng',
                style: TextStyle(
                  color: _textMid,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Flexible(
                child: Text(
                  hasSelection ? formatVND(total) : '0 ₫',
                  style: const TextStyle(
                    color: _accent,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: hasSelection
                ? () {
                    HapticFeedback.mediumImpact();
                    _navigateToCheckout(
                      items.where((i) => i.isSelected).toList(),
                    );
                  }
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                color: hasSelection ? _accent : _surfaceAlt,
                borderRadius: BorderRadius.circular(18),
                border: hasSelection
                    ? null
                    : Border.all(color: _border, width: 0.5),
                boxShadow: hasSelection
                    ? [
                        BoxShadow(
                          color: _accent.withValues(alpha: 0.25),
                          blurRadius: 5,
                        ),
                      ]
                    : [],
              ),
              child: Center(
                child: Text(
                  'THANH TOÁN',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: hasSelection ? Colors.black : _textLow,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 28, 20, 16),
            child: Center(
              child: Text(
                'CÓ THỂ BẠN CŨNG THÍCH',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _textMid,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 600,
            child: PageView.builder(
              controller: PageController(viewportFraction: 1.0),
              clipBehavior: Clip.none,
              itemCount: _recommendations.length,
              itemBuilder: (context, index) {
                final product = _recommendations[index];
                return FractionallySizedBox(
                  widthFactor: 0.92,
                  child: Center(child: LargeProductCard(product: product)),
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
          color: _accent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _accent.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.shoppingBag, color: Colors.black, size: 18),
            SizedBox(width: 10),
            Text(
              "BẮT ĐẦU MUA SẮM",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w900,
                fontSize: 13,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
