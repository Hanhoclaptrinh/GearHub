import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/core/di/injection.dart';
import 'package:mobile/src/features/home/presentation/state/home_cubit.dart';
import 'package:mobile/src/features/home/presentation/state/home_state.dart';
import 'package:mobile/src/features/home/domain/entities/category_entity.dart';
import 'package:mobile/src/shared/widgets/search_bar_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'category_detail_page.dart';

const _bg = Color(0xFF0A0A10);
const _indigo = Color(0xFF6366F1);
const _textHigh = Color(0xFFF1F1F5);
const _textMid = Color(0xFF9191A8);
const _textLow = Color(0xFF4A4A62);

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<HomeCubit>()..loadHomeData(),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: _bg,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                floating: true,
                elevation: 0,
                scrolledUnderElevation: 0,
                backgroundColor: _bg,
                automaticallyImplyLeading: false,
                centerTitle: false,
                title: const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Text(
                    'Khám phá',
                    style: TextStyle(
                      color: _textHigh,
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(
                      LucideIcons.messageCircle,
                      color: _textMid,
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
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.9,
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
                        child: CircularProgressIndicator(color: _indigo),
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
                        color: _textLow,
                      ),
                    )
                  : const Icon(LucideIcons.package, size: 40, color: _textLow),
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
                color: _textHigh,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
