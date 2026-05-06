import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/features/wishlist/presentation/state/wishlist_cubit.dart';
import 'package:mobile/src/features/wishlist/presentation/state/wishlist_state.dart';
import 'package:mobile/src/features/wishlist/presentation/widgets/wishlist_product_card.dart';
import 'package:mobile/src/shared/widgets/product_card_shimmer.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<WishlistCubit>().fetchWishlist(refresh: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<WishlistCubit>().fetchWishlist();
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Yêu thích',
          style: TextStyle(
            color: Color(0xFF0A0A0F),
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: BlocBuilder<WishlistCubit, WishlistState>(
        builder: (context, state) {
          if (state is WishlistLoading) {
            return _buildLoading();
          }

          if (state is WishlistError) {
            return Center(child: Text(state.message));
          }

          if (state is WishlistLoaded) {
            if (state.products.isEmpty) {
              return _buildEmpty();
            }

            return RefreshIndicator(
              onRefresh: () => context.read<WishlistCubit>().fetchWishlist(refresh: true),
              color: const Color(0xFF3B82F6),
              child: GridView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.72,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: state.hasReachedMax 
                    ? state.products.length 
                    : state.products.length + 1,
                itemBuilder: (context, index) {
                  if (index >= state.products.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }
                  return WishlistProductCard(product: state.products[index]);
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildLoading() {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => const ProductCardShimmer(),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.heart,
              size: 48,
              color: Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Chưa có sản phẩm yêu thích',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0A0A0F),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Hãy thêm những sản phẩm bạn yêu thích\nvào danh sách này nhé!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
