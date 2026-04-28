import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
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
            StaggeredGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                if (products.isNotEmpty)
                  StaggeredGridTile.count(
                    crossAxisCellCount: 1,
                    mainAxisCellCount: 2,
                    child: TopRatedCardLarge(product: products[0]),
                  ),
                if (products.length >= 2)
                  StaggeredGridTile.count(
                    crossAxisCellCount: 1,
                    mainAxisCellCount: 1,
                    child: TopRatedCardSmall(product: products[1]),
                  ),
                if (products.length >= 3)
                  StaggeredGridTile.count(
                    crossAxisCellCount: 1,
                    mainAxisCellCount: 1,
                    child: TopRatedCardSmall(product: products[2]),
                  ),
                if (products.length >= 4)
                  StaggeredGridTile.count(
                    crossAxisCellCount: 2,
                    mainAxisCellCount: 0.72,
                    child: TopRatedCardWide(product: products[3]),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}
