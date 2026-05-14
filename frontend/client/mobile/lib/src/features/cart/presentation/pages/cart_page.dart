import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/core/utils/formatter_utils.dart';
import 'package:mobile/src/features/auth/presentation/state/auth_cubit.dart';
import 'package:mobile/src/features/auth/presentation/state/auth_state.dart';
import 'package:mobile/src/features/cart/presentation/state/cart_cubit.dart';
import 'package:mobile/src/features/cart/presentation/state/cart_state.dart';
import 'package:mobile/src/features/cart/domain/entities/cart_item_entity.dart';
import 'package:mobile/src/features/cart/presentation/widgets/cart_item_card.dart';
import 'package:mobile/src/features/checkout/presentation/pages/checkout_page.dart';
import 'package:mobile/src/shared/models/product_model.dart';
import 'package:mobile/src/features/home/presentation/pages/main_screen.dart';
import 'package:mobile/src/features/product_detail/presentation/pages/product_detail_page.dart';
import 'package:mobile/src/shared/widgets/large_product_card.dart';
import 'package:mobile/src/shared/widgets/auth_required_modal.dart';
import 'package:mobile/src/shared/widgets/glassmorphic_header.dart';

const _bg = Color(0xFF07070A);
const _surface = Color(0xFF14141E);
const _border = Color(0xFF2A2A38);
const _accent = Color(0xFFFDE047);
const _accentSoft = Color(0x1AFDE047);
const _pink = Color(0xFFFF4D4D);
const _textHigh = Colors.white;
const _textMid = Color(0xFF94A3B8);
const _textLow = Color(0xFF475569);

class CartPage extends StatefulWidget {
  final bool isNavVisible;
  const CartPage({super.key, this.isNavVisible = true});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

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

  void _navigateToCheckout(List<CartItemEntity> selectedItems) {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      AuthRequiredModal.show(context);
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
    _scrollController.addListener(() {
      if (mounted) {
        setState(() {
          _scrollOffset = _scrollController.offset;
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CartCubit>().loadCart();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
            body: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        LucideIcons.triangleAlert,
                        size: 48,
                        color: _pink,
                      ),
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
                const GlassmorphicHeader(scrollOffset: 0, title: 'Lỗi'),
              ],
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
            body: Stack(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Lottie.asset(
                          'assets/animations/emptycart.json',
                          height: 200,
                          repeat: true,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
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
                const GlassmorphicHeader(scrollOffset: 0, title: 'Giỏ hàng'),
              ],
            ),
          );
        }

        // cart with items
        return Scaffold(
          backgroundColor: _bg,
          body: Stack(
            children: [
              CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      child: BlocBuilder<CartCubit, CartState>(
                        builder: (context, state) {
                          bool allSelected = false;
                          if (state.cart != null) {
                            allSelected =
                                state.cart!.items.isNotEmpty &&
                                state.cart!.items.every((i) => i.isSelected);
                          }
                          return Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  context.read<CartCubit>().toggleSelectAll(
                                    !allSelected,
                                  );
                                },
                                child: Row(
                                  children: [
                                    const Text(
                                      'Giỏ hàng hiện tại',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        color: _textHigh,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      allSelected
                                          ? LucideIcons.circleCheck
                                          : LucideIcons.circle,
                                      size: 12,
                                      color: allSelected ? _accent : _textLow,
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () => _showClearCartDialog(context),
                                child: Text(
                                  'Xóa tất cả',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: _pink.withValues(alpha: 0.5),
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                '${items.length} sản phẩm',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: _textHigh.withValues(alpha: 0.3),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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
              GlassmorphicHeader(
                scrollOffset: _scrollOffset,
                title: 'Giỏ hàng',
                actions: [
                  HeaderIconButton(
                    icon: LucideIcons.messageCircle,
                    onTap: () {},
                  ),
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

  Widget _buildAnchoredCheckoutBar(
    bool hasSelection,
    double total,
    List<CartItemEntity> items,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.fromLTRB(24, 20, 20, 20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Tổng cộng',
                      style: TextStyle(
                        color: _textMid,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        hasSelection ? formatVND(total) : '0 ₫',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
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
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: hasSelection
                        ? _accent
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: hasSelection
                        ? [
                            BoxShadow(
                              color: _accent.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: Text(
                    'THANH TOÁN',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: hasSelection
                          ? Colors.black
                          : Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
            child: Row(
              children: [
                Container(width: 32, height: 1.5, color: _accent),
                const SizedBox(width: 12),
                const Text(
                  'KHÁM PHÁ THÊM',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: _textHigh,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 620,
            child: PageView.builder(
              controller: PageController(viewportFraction: 0.94),
              clipBehavior: Clip.none,
              itemCount: _recommendations.length,
              itemBuilder: (context, index) {
                final product = _recommendations[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: LargeProductCard(product: product),
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
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Text(
          "TIẾP TỤC MUA SẮM",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: Colors.black,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

class PromoSection extends StatelessWidget {
  const PromoSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.ticketPercent,
              color: _accent,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mã giảm giá',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _textHigh,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Chọn hoặc nhập mã khuyến mãi',
                  style: TextStyle(fontSize: 13, color: _textMid),
                ),
              ],
            ),
          ),
          const Icon(LucideIcons.chevronRight, color: _textLow, size: 20),
        ],
      ),
    );
  }
}
