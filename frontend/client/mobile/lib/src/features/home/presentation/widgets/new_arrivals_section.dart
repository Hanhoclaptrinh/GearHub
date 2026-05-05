import 'package:flutter/material.dart';
import '../../../../shared/widgets/large_product_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../state/home_cubit.dart';
import '../state/home_state.dart';

class NewArrivalsSection extends StatelessWidget {
  const NewArrivalsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Đón đầu kỷ nguyên công nghệ mới',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0A0A0F),
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 20),
        BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            if (state is HomeLoaded) {
              if (state.newArrivals.isEmpty) {
                return const SizedBox.shrink();
              }
              return SizedBox(
                height: 600,
                child: OverflowBox(
                  maxWidth: MediaQuery.of(context).size.width,
                  child: PageView.builder(
                    controller: PageController(viewportFraction: 1.0),
                    clipBehavior: Clip.none,
                    itemCount: state.newArrivals.length,
                    itemBuilder: (context, index) {
                      final product = state.newArrivals[index];
                      return FractionallySizedBox(
                        widthFactor: 0.92,
                        child: Center(
                          child: LargeProductCard(product: product),
                        ),
                      );
                    },
                  ),
                ),
              );
            }
            if (state is HomeLoading) {
              return const SizedBox(
                height: 610,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return const SizedBox(height: 610);
          },
        ),
      ],
    );
  }
}
