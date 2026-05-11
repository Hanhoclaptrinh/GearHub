import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/core/di/injection.dart';
import 'package:mobile/src/features/product_detail/data/datasources/product_detail_remote_datasource.dart';
import 'package:mobile/src/features/product_detail/presentation/pages/product_detail_page.dart';
import 'package:mobile/src/features/wishlist/presentation/state/wishlist_cubit.dart';
import 'package:mobile/src/features/wishlist/presentation/state/wishlist_state.dart';
import 'package:mobile/src/shared/widgets/small_product_card.dart';
import 'package:mobile/src/shared/widgets/small_product_card_shimmer.dart';

const _bg = Color(0xFF07070A);
const _accent = Color(0xFFFFCC00);
const _pink = Color(0xFFFF6B8A);
const _pinkSoft = Color(0x1FFF6B8A);
const _textHigh = Color(0xFFF1F1F5);
const _textMid = Color(0xFF9191A8);
const _textLow = Color(0xFF4A4A62);

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _headerAnim;
  late Animation<double> _headerFade;

  @override
  void initState() {
    super.initState();
    _headerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _headerFade = CurvedAnimation(parent: _headerAnim, curve: Curves.easeOut);
    _headerAnim.forward();
    context.read<WishlistCubit>().fetchWishlist(refresh: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _headerAnim.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) context.read<WishlistCubit>().fetchWishlist();
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    return _scrollController.offset >=
        (_scrollController.position.maxScrollExtent * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: BlocBuilder<WishlistCubit, WishlistState>(
        builder: (context, state) {
          return CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                floating: true,
                snap: true,
                backgroundColor: _bg,
                elevation: 0,
                scrolledUnderElevation: 0,
                centerTitle: true,
                leading: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                titleSpacing: 4,
                title: FadeTransition(
                  opacity: _headerFade,
                  child: const Text(
                    'Yêu thích',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: _textHigh,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),

              // loading
              if (state is WishlistLoading)
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (_, __) => const SmallProductCardShimmer(),
                      childCount: 6,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.6,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                  ),
                )
              else if (state is WishlistError)
                SliverFillRemaining(
                  child: Center(
                    child: Text(
                      state.message,
                      style: const TextStyle(color: _textMid),
                    ),
                  ),
                )
              else if (state is WishlistLoaded && state.products.isEmpty)
                SliverFillRemaining(child: _buildEmpty())
              else if (state is WishlistLoaded) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: Row(
                      children: [
                        Container(
                          width: 3,
                          height: 14,
                          decoration: BoxDecoration(
                            color: _pink,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${state.products.length} SẢN PHẨM ĐÃ LƯU',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _textLow,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index >= state.products.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(
                                color: _accent,
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        }
                        final productModel = state.products[index];
                        return SmallProductCard(
                          product: productModel,
                          heroTag: 'wishlist_${productModel.id}_$index',
                          onTap: () async {
                            HapticFeedback.mediumImpact();
                            try {
                              final pDetail =
                                  await getIt<ProductDetailRemoteDatasource>()
                                      .getProductDetail(productModel.id);
                              if (context.mounted) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ProductDetailPage(product: pDetail),
                                  ),
                                );
                              }
                            } catch (e) {
                              debugPrint('Error fetching product detail: $e');
                            }
                          },
                        );
                      },
                      childCount: state.hasReachedMax
                          ? state.products.length
                          : state.products.length + 1,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.6,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _pinkSoft,
                  ),
                ),
                const Icon(LucideIcons.heart, size: 52, color: _pink),
              ],
            ),
            const SizedBox(height: 28),
            const Text(
              'CHƯA CÓ YÊU THÍCH',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: _textHigh,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Những sản phẩm bạn yêu thích\nsẽ xuất hiện tại đây.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _textMid, fontSize: 13, height: 1.6),
            ),
            const SizedBox(height: 36),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: _pink,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _pink.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.shoppingBag,
                      color: Colors.white,
                      size: 16,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'KHÁM PHÁ NGAY',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
