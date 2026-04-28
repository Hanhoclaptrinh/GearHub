import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/src/features/home/presentation/state/home_cubit.dart';
import 'package:mobile/src/features/home/presentation/state/home_state.dart';
import 'package:mobile/src/features/home/presentation/widgets/vault_card.dart';
import 'package:mobile/src/shared/widgets/section_header.dart';

class VaultSection extends StatefulWidget {
  const VaultSection({super.key});

  @override
  State<VaultSection> createState() => _VaultSectionState();
}

class _VaultSectionState extends State<VaultSection> {
  late PageController _pageController;
  double _currentPage = 0.0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.97);
    _pageController.addListener(() {
      if (_pageController.hasClients) {
        setState(() {
          _currentPage = _pageController.page ?? 0.0;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        if (state is! HomeLoaded || state.vaultProducts.isEmpty) {
          return const SizedBox.shrink();
        }

        final products = state.vaultProducts;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(index: '05', title: 'LƯU TRỮ'),
            const SizedBox(height: 24),
            SizedBox(
              height: 350,
              child: PageView.builder(
                controller: _pageController,
                itemCount: products.length,
                clipBehavior: Clip.none,
                itemBuilder: (context, index) {
                  return VaultCard(
                    product: products[index],
                    index: index,
                    currentPage: _currentPage,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
