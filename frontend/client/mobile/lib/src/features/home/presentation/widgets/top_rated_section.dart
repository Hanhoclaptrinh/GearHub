import 'package:flutter/material.dart';
import 'package:mobile/src/shared/widgets/section_header.dart';
import 'top_rated_cards.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../state/home_cubit.dart';
import '../state/home_state.dart';

class TopRatedSection extends StatelessWidget {
  const TopRatedSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        if (state is! HomeLoaded) return const SizedBox.shrink();
        final products = state.topRatedProducts;
        if (products.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              index: '04',
              title: 'DẪN ĐẦU',
              actionText: 'Xem tất cả',
            ),
            const SizedBox(height: 16),
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.63,
              ),
              itemCount: products.length > 4 ? 4 : products.length,
              itemBuilder: (context, index) {
                return TopRatedPremiumCard(product: products[index]);
              },
            ),
          ],
        );
      },
    );
  }
}
