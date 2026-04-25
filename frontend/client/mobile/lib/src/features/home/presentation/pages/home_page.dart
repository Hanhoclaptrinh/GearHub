import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/hero_section.dart';
import '../widgets/top_categories_section.dart';
import '../widgets/new_arrivals_section.dart';
import '../widgets/trending_section.dart';
import '../widgets/recommended_section.dart';
import '../widgets/top_brands_section.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/src/core/di/injection.dart';
import '../state/home_cubit.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    const double expandedHeight = 120.0;
    const double collapsedHeight = kToolbarHeight;
    final colorScheme = Theme.of(context).colorScheme;

    return BlocProvider(
      create: (context) => getIt<HomeCubit>()..loadHomeData(),
      child: Scaffold(
        body: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverAppBar(
                  context,
                  statusBarHeight,
                  expandedHeight,
                  collapsedHeight,
                  colorScheme,
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SearchBarWidget(),
                      const SizedBox(height: 24),
                      const HeroSection(),
                      const SizedBox(height: 32),
                      const TopCategoriesSection(),
                      const SizedBox(height: 32),
                      const NewArrivalsSection(),
                      const SizedBox(height: 32),
                      const TopBrandsSection(),
                      const SizedBox(height: 32),
                      const TrendingSection(),
                      const SizedBox(height: 32),
                      const RecommendedSection(),
                      const SizedBox(height: 32),
                    ]),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(
    BuildContext context,
    double statusBarHeight,
    double expandedHeight,
    double collapsedHeight,
    ColorScheme colorScheme,
  ) {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      automaticallyImplyLeading: false,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double currentExtent = constraints.maxHeight;
              final double progress =
                  ((currentExtent - (collapsedHeight + statusBarHeight)) /
                          (expandedHeight - collapsedHeight))
                      .clamp(0.0, 1.0);

              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor.withValues(
                    alpha: (1.0 - progress).clamp(0.0, 0.3),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    top: statusBarHeight,
                    left: 16,
                    right: 16,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Transform.translate(
                            offset: Offset(0, progress * 15),
                            child: Transform.scale(
                              alignment: Alignment.centerLeft,
                              scale: 1.2 + (progress * 0.2),
                              child: Text(
                                'GearHub',
                                style: TextStyle(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 24,
                                  letterSpacing: -1.0,
                                ),
                              ),
                            ),
                          ),
                          Transform.translate(
                            offset: Offset(0, progress * 15),
                            child: Row(
                              children: [
                                _buildCircleIcon(
                                  context,
                                  LucideIcons.bell,
                                  progress,
                                  () {
                                    print('Bell clicked');
                                  },
                                ),
                                const SizedBox(width: 8),
                                _buildCircleIcon(
                                  context,
                                  LucideIcons.sparkles,
                                  progress,
                                  () {
                                    print('Sparkles clicked');
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCircleIcon(
    BuildContext context,
    IconData icon,
    double progress,
    VoidCallback onTap,
  ) {
    return Transform.scale(
      scale: 1.0 + (progress * 0.1),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(
          icon,
          size: 22 + (progress * 2),
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}
