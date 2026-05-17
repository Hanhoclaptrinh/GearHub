import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/core/theme/app_colors.dart';
import 'package:mobile/src/core/di/injection.dart';
import 'package:mobile/src/features/chat/presentation/widgets/concierge_entry_button.dart';
import 'package:mobile/src/features/home/presentation/state/home_cubit.dart';
import 'package:mobile/src/features/home/presentation/state/home_state.dart';
import 'package:mobile/src/features/home/domain/entities/category_entity.dart';
import 'package:mobile/src/shared/widgets/search_bar_widget.dart';
import 'package:mobile/src/shared/widgets/glassmorphic_header.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'category_detail_page.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (mounted) {
        setState(() {
          _scrollOffset = _scrollController.offset;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<HomeCubit>()..loadHomeData(),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
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
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 0.9,
                                ),
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
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
                              color: AppColors.brandIndigo,
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
              GlassmorphicHeader(
                scrollOffset: _scrollOffset,
                title: 'Khám phá',
                actions: const [ConciergeEntryButton(compact: true)],
              ),
            ],
          ),
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
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                CategoryDetailPage(category: category as CategoryEntity),
          ),
        );
      },
      child: Column(
        children: [
          Expanded(
            flex: 4,
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(12),
              child: category.iconUrl != null && category.iconUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: category.iconUrl!,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => Container(),
                      errorWidget: (context, url, error) => const Icon(
                        LucideIcons.package,
                        size: 32,
                        color: AppColors.textDim,
                      ),
                    )
                  : const Icon(
                      LucideIcons.package,
                      size: 40,
                      color: AppColors.textDim,
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: Text(
              category.title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
