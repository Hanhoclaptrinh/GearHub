import 'package:flutter/material.dart';
import 'package:mobile/src/shared/widgets/section_header.dart';
import '../widgets/new_arrival_card.dart';
import 'package:mobile/src/features/product_detail/presentation/pages/product_detail_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../state/home_cubit.dart';
import '../state/home_state.dart';
import 'package:mobile/src/features/cart/presentation/state/cart_cubit.dart';

class NewArrivalsSection extends StatelessWidget {
  const NewArrivalsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(index: '02', title: 'SẢN PHẨM MỚI'),
        const SizedBox(height: 20),
        BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            if (state is HomeLoaded) {
              if (state.newArrivals.isEmpty) {
                return const SizedBox(
                  height: 380,
                  child: Center(child: Text('No new arrivals yet')),
                );
              }
              return SizedBox(
                height: 380,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  clipBehavior: Clip.none,
                  itemCount: state.newArrivals.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final product = state.newArrivals[index];
                    return NewArrivalsCard(
                      product: product,
                      onTap: () {
                        context.read<HomeCubit>().incrementView(product.id);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                ProductDetailPage(product: product),
                          ),
                        );
                      },
                      onAddToCart: () {
                        final variant = product.variants.where((v) => v.isActive).firstOrNull ??
                            (product.variants.isNotEmpty ? product.variants.first : null);
                        if (variant != null) {
                          final cartState = context.read<CartCubit>().state;
                          int existingQty = 0;
                          if (cartState.cart != null) {
                            final existing = cartState.cart!.items
                                .where((i) => i.productVariant.id == variant.id)
                                .firstOrNull;
                            existingQty = existing?.quantity ?? 0;
                          }

                          if (existingQty + 1 > variant.stock) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Sản phẩm ${product.name} chỉ còn ${variant.stock} sản phẩm (Bạn đã có $existingQty trong giỏ)',
                                ),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                            return;
                          }
                          context.read<CartCubit>().addToCart(variant, product, 1);
                        }
                      },
                    );
                  },
                ),
              );
            }
            if (state is HomeLoading) {
              return const SizedBox(
                height: 410,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return const SizedBox(height: 410);
          },
        ),
      ],
    );
  }
}
