import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/core/di/injection.dart';
import 'package:mobile/src/features/home/presentation/state/home_cubit.dart';
import 'package:mobile/src/features/home/presentation/state/home_state.dart';
import 'package:mobile/src/shared/widgets/search_bar_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<HomeCubit>()..loadHomeData(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              floating: true,
              pinned: false,
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: Colors.white,
              automaticallyImplyLeading: false,
              centerTitle: false,
              title: const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Text(
                  'Cửa hàng',
                  style: TextStyle(
                    color: Color(0xFF0A0A0F),
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(
                    LucideIcons.messageCircle,
                    color: Color(0xFF0A0A0F),
                    size: 24,
                  ),
                  onPressed: () {},
                ),
                const SizedBox(width: 8),
              ],
            ),
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 24),
              sliver: SliverToBoxAdapter(child: SearchBarWidget()),
            ),
            BlocBuilder<HomeCubit, HomeState>(
              builder: (context, state) {
                if (state is HomeLoaded) {
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.82,
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final category = state.parentCategories[index];
                        return _CategoryCard(category: category);
                      }, childCount: state.parentCategories.length),
                    ),
                  );
                }
                if (state is HomeLoading) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF3B82F6),
                      ),
                    ),
                  );
                }
                if (state is HomeError) {
                  return SliverFillRemaining(
                    child: Center(child: Text(state.message)),
                  );
                }
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final dynamic category;
  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        print('cate ${category.title} clicked');
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: category.iconUrl != null && category.iconUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: category.iconUrl!,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      LucideIcons.package,
                      size: 32,
                      color: Color(0xFFCBD5E1),
                    ),
                  )
                : const Icon(
                    LucideIcons.package,
                    size: 40,
                    color: Color(0xFFCBD5E1),
                  ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.topCenter,
              child: Text(
                category.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                  height: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
