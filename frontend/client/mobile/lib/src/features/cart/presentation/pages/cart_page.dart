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
import 'package:mobile/src/features/chat/presentation/widgets/concierge_entry_button.dart';
import 'package:mobile/src/features/checkout/presentation/pages/checkout_page.dart';
import 'package:mobile/src/shared/models/product_model.dart';
import 'package:mobile/src/features/home/presentation/pages/main_screen.dart';
import 'package:mobile/src/features/product_detail/presentation/pages/product_detail_page.dart';
import 'package:mobile/src/shared/widgets/large_product_card.dart';
import 'package:mobile/src/shared/widgets/auth_required_modal.dart';
import 'package:mobile/src/shared/widgets/glassmorphic_header.dart';
import 'package:mobile/src/shared/widgets/error_illustration_widget.dart';

class CartPage extends StatefulWidget {
  final bool isNavVisible;
  const CartPage({super.key, this.isNavVisible = true});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  ///xóa item khỏi giỏ hàng
  void _removeItem(String itemId) {
    context.read<CartCubit>().removeItem(itemId);
    HapticFeedback.mediumImpact();
  }

  ///xử lý chuyển hướng tới trang thanh toán
  void _navigateToCheckout(List<CartItemEntity> selectedItems) {
    final authState = context.read<AuthCubit>().state;
    //không cho phép thanh toán khi chưa có auth
    if (authState is! AuthAuthenticated) {
      AuthRequiredModal.show(context);
      return;
    }
    //chuyển sang màn hình thanh toán
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
    //init state
    //sync giỏ hàng tử local lúc người dùng thêm vào khi auth
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
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.onSurface,
                strokeWidth: 2,
              ),
            ),
          );
        }
        //giỏ hàng bị lỗi
        if (state is CartError) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Stack(
              children: [
                //hiển thị illustration tương ứng mã lỗi
                //trực quan hóa lỗi
                ErrorIllustrationWidget(
                  message: state.message,
                  onRetry: () => context.read<CartCubit>().loadCart(),
                ),
                const GlassmorphicHeader(scrollOffset: 0, title: 'Giỏ hàng'),
              ],
            ),
          );
        }
        List<CartItemEntity> items = []; //danh sách item trong giỏ hàng
        double totalSelection = 0.0; //tổng tiền các item trong giỏ
        bool hasSelection = false; //trạng thái item được chọn

        if (state.cart != null) {
          items = state.cart!.items;
          //lọc các item được chọn
          final selectedItems = items.where((i) => i.isSelected);
          hasSelection = selectedItems.isNotEmpty; //xác định trạng thái chọn
          //tính tổng các item được chọn
          totalSelection = selectedItems.fold(
            0.0,
            (sum, i) => sum + i.itemTotal,
          );
        }

        //cart rỗng
        if (items.isEmpty) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Stack(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        //animation trực qunn
                        Lottie.asset(
                          'assets/animations/emptycart.json',
                          height: 200,
                          repeat: true,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            LucideIcons.shoppingCart,
                            size: 80,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Giỏ hàng của bạn đang trống',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Khi bạn thêm sản phẩm hoặc phụ kiện,\nthông tin chi tiết về đơn hàng sẽ hiển thị tại đây.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 40),
                        _buildEmptyStateButton(context),
                      ],
                    ),
                  ),
                ),
                const GlassmorphicHeader(
                  scrollOffset: 0,
                  title: 'Giỏ hàng',
                  actions: [ConciergeEntryButton(compact: true)],
                ),
              ],
            ),
          );
        }
        //giỏ hàng có items
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                          bool allSelected =
                              false; //ban đầu set tất cả đều không được chọn - cho user tự chọn
                          if (state.cart != null) {
                            allSelected =
                                state.cart!.items.isNotEmpty &&
                                state.cart!.items.every((i) => i.isSelected);
                          }
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              //nút chọn tất cả
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  //set trạng thái all select bằng cách toggle
                                  context.read<CartCubit>().toggleSelectAll(
                                    !allSelected,
                                  );
                                },
                                behavior: HitTestBehavior.opaque,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      curve: Curves.easeOut,
                                      width: 18,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        color: allSelected
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.onSurface
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(5),
                                        border: Border.all(
                                          color: allSelected
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.onSurface
                                              : Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant
                                                    .withValues(alpha: 0.4),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: allSelected
                                          ? Icon(
                                              LucideIcons.check,
                                              size: 12,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.surface,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Chọn tất cả',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              //right section
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  //số lượng sản phẩm trong cart
                                  Text(
                                    '${items.length} sản phẩm',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    child: Text(
                                      '·',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant
                                            .withValues(alpha: 0.3),
                                      ),
                                    ),
                                  ),
                                  //xóa tất cả items trong cart
                                  GestureDetector(
                                    onTap: () => _showClearCartDialog(context),
                                    behavior: HitTestBehavior.opaque,
                                    child: Text(
                                      'Xóa tất cả',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .error
                                            .withValues(alpha: 0.55),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),

                  //cart items list
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
                          //xem sản phẩm tương đồng với sản phẩm được chọn
                          //skip tính năng này :))
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

                  //recommendations section
                  _buildRecommendationsSection(
                    state.recommendations,
                    state.isRecommendationsLoading,
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 180)),
                ],
              ),
              GlassmorphicHeader(
                scrollOffset: _scrollOffset,
                title: 'Giỏ hàng',
                actions: const [ConciergeEntryButton(compact: true)],
              ),
              //floating checkout bar
              Builder(
                builder: (context) {
                  final bool isNavVisible = widget.isNavVisible;
                  final double bottomPadding = MediaQuery.of(
                    context,
                  ).padding.bottom;

                  //vị trí thanh checkout dựa trên vị trí của thanh bottom navigation
                  //khi thanh navbar hiển thị thì thanh checkout nằm trên
                  //ngược lại thanh checkout nằm ngay vị trí của thanh bottom nav bả
                  final double targetBottom = isNavVisible
                      ? (bottomPadding + 16)
                      : (bottomPadding - 80);
                  //animate di chuyển thanh checkout
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
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 0.5,
            ),
          ),
          title: Text(
            'Xóa giỏ hàng',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          content: Text(
            'Bạn có chắc chắn muốn xóa toàn bộ sản phẩm trong giỏ hàng?',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Hủy',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.read<CartCubit>().clearCart();
              },
              child: Text(
                'Xóa',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w800,
                ),
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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bgColor = isDark
        ? const Color(0xFF1E1E22)
        : const Color(0xFFFFFFFF);

    final Color activeBtnBg = isDark
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF111111);
    final Color activeBtnText = isDark
        ? const Color(0xFF111111)
        : const Color(0xFFFFFFFF);

    final Color disabledBtnBg = isDark
        ? const Color(0xFF2C2C2F).withValues(alpha: 0.8)
        : const Color(0xFFEAEAEA).withValues(alpha: 0.8);
    final Color disabledBtnText = isDark
        ? const Color(0xFFFFFFFF).withValues(alpha: 0.35)
        : const Color(0xFF111111).withValues(alpha: 0.35);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(
            alpha: isDark ? 0.15 : 0.4,
          ),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Tổng cộng',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
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
                    style: TextStyle(
                      color: colorScheme.onSurface,
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
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                color: hasSelection ? activeBtnBg : disabledBtnBg,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                'THANH TOÁN',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: hasSelection ? activeBtnText : disabledBtnText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection(
    List<ProductModel> recommendations,
    bool isLoading,
  ) {
    if (!isLoading && recommendations.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 20),
            child: Row(
              children: [
                Text(
                  'Sản phẩm tương đồng',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: -0.6,
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
            SizedBox(
              height: 140,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 1.6,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            SizedBox(
              height: 620,
              child: PageView.builder(
                controller: PageController(viewportFraction: 0.94),
                clipBehavior: Clip.none,
                itemCount: recommendations.length,
                itemBuilder: (context, index) {
                  final product = recommendations[index];
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
    final theme = Theme.of(context);
    return OutlinedButton(
      onPressed: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: theme.colorScheme.primary,
        side: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.4),
          width: 1.2,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      ),
      child: const Text('Tiếp tục mua sắm'),
    );
  }
}
