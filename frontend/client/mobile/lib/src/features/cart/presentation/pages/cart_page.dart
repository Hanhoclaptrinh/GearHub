import 'dart:ui';
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
import 'package:mobile/src/shared/styles/app_colors.dart';
import 'package:mobile/src/features/home/presentation/pages/main_screen.dart';
import 'package:mobile/src/features/product_detail/presentation/pages/product_detail_page.dart';
import 'package:mobile/src/shared/widgets/large_product_card.dart';

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
            color: Color(0xFF0C0C18),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
            border: Border(top: BorderSide(color: Color(0xFF1A1A28), width: 1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 32),
              Container(
                height: 64,
                width: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4A843).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.lock,
                  color: Color(0xFFD4A843),
                  size: 28,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'YÊU CẦU ĐĂNG NHẬP',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Vui lòng đăng nhập để tiếp tục thanh toán, lưu giỏ hàng và nhận các ưu đãi thành viên đặc biệt của GearHub.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF8A8A9E),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4A843),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                  },
                  child: const Text(
                    'ĐĂNG NHẬP NGAY',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white54,
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
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is CartError) {
          return Scaffold(
            appBar: _buildSimpleAppBar(),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      'Lỗi: ${state.message}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<CartCubit>().loadCart(),
                    child: const Text('Thử lại'),
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

        // check cart empty
        if (items.isEmpty) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: _buildSimpleAppBar(),
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
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        LucideIcons.shoppingCart,
                        size: 100,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "GIỎ HÀNG RỖNG",
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
                      "Có vẻ như bạn chưa thêm bất kỳ sản phẩm nào vào giỏ hàng.",
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
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: allSelected
                                            ? Colors.black
                                            : Colors.transparent,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: allSelected
                                              ? Colors.black
                                              : const Color(0xFFC7C7CC),
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      allSelected
                                          ? 'Bỏ chọn tất cả'
                                          : 'Chọn tất cả',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
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
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext dialogContext) {
                                        return AlertDialog(
                                          backgroundColor: Colors.white,
                                          title: const Text(
                                            'Xóa giỏ hàng',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          content: const Text(
                                            'Bạn có chắc chắn muốn xóa toàn bộ sản phẩm trong giỏ hàng không?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(dialogContext),
                                              child: const Text('Hủy'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(dialogContext);
                                                context
                                                    .read<CartCubit>()
                                                    .clearCart();
                                              },
                                              child: const Text(
                                                'Xóa',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        LucideIcons.trash2,
                                        size: 14,
                                        color: Colors.red,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Xóa tất cả',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
                  const SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    sliver: SliverToBoxAdapter(child: PromoSection()),
                  ),
                  _buildRecommendationsSection(),
                  const SliverToBoxAdapter(child: SizedBox(height: 180)),
                ],
              ),
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

  PreferredSizeWidget _buildSimpleAppBar() {
    return AppBar(
      elevation: 0,
      centerTitle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      title: const Text(
        'Giỏ hàng',
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 24,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      floating: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      automaticallyImplyLeading: false,
      titleSpacing: 20,
      title: Text(
        'Giỏ hàng',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w900,
          color: Theme.of(context).colorScheme.onSurface,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildAnchoredCheckoutBar(
    bool hasSelection,
    double total,
    List<CartItemEntity> items,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
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
                  color: Color(0xFF1F2937),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Flexible(
                child: Text(
                  hasSelection ? formatVND(total) : '0 ₫',
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: hasSelection
                  ? () => _navigateToCheckout(
                      items.where((i) => i.isSelected).toList(),
                    )
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Thanh Toán',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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
            padding: EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Center(
              child: Text(
                'CÓ THỂ BẠN CŨNG THÍCH',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  letterSpacing: 1.2,
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
              "BẮT ĐẦU MUA SẮM",
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
