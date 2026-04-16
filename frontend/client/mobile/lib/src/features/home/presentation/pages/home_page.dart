import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/features/home/presentation/widgets/trending_section.dart';
import '../widgets/hero_section.dart';
import '../widgets/quick_categories.dart';
import '../widgets/new_arrivals_section.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    const double expandedHeight = 80.0;
    const double collapsedHeight = kToolbarHeight;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            stretch: true,
            expandedHeight: expandedHeight,
            collapsedHeight: collapsedHeight,
            toolbarHeight: collapsedHeight,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            scrolledUnderElevation: 4.0,
            automaticallyImplyLeading: false,
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                final double currentExtent = constraints.maxHeight;
                // progress: 1.0 (expanded) to 0.0 (collapsed)
                final double progress =
                    ((currentExtent - (collapsedHeight + statusBarHeight)) /
                            (expandedHeight - collapsedHeight))
                        .clamp(0.0, 1.0);

                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor.withValues(
                      alpha: progress < 0.05 ? 1.0 : 0.0,
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
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 22,
                                    letterSpacing: -0.5,
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
                                      print("Bell tapped");
                                    },
                                  ),
                                  const SizedBox(width: 12),
                                  _buildCircleIcon(
                                    context,
                                    LucideIcons.sparkles,
                                    progress,
                                    () {
                                      print("Sparkles tapped");
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
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const HeroSection(),
                const SizedBox(height: 32),
                const QuickCategories(),
                const SizedBox(height: 32),
                const NewArrivalsSection(),
                const SizedBox(height: 32),
                const TrendingSection(),
              ]),
            ),
          ),
        ],
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
