import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/core/di/injection.dart';
import 'package:mobile/src/features/explore/domain/repositories/explore_repository.dart';
import 'package:mobile/src/shared/widgets/glassmorphic_header.dart';
import '../../../home/domain/entities/category_entity.dart';
import '../state/category_detail_cubit.dart';
import '../state/category_detail_state.dart';
import '../../../../shared/widgets/product_card.dart';
import '../../../../shared/widgets/product_card_shimmer.dart';
import '../../../../shared/widgets/product_filter_drawer.dart';

const _bg = Color(0xFF07070A);
const _surfaceAlt = Color(0xFF1C1C28);
const _border = Color(0xFF2A2A38);
const _accent = Color(0xFFFFCC00);
const _accentSoft = Color(0x18F59E0B);
const _textHigh = Color(0xFFF1F1F5);
const _textMid = Color(0xFF9191A8);
const _textLow = Color(0xFF4A4A62);

class CategoryDetailPage extends StatelessWidget {
  final CategoryEntity category;

  const CategoryDetailPage({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          CategoryDetailCubit(repository: getIt<ExploreRepository>())
            ..loadCategoryProducts(category),
      child: const _CategoryDetailView(),
    );
  }
}

class _CategoryDetailView extends StatefulWidget {
  const _CategoryDetailView();

  @override
  State<_CategoryDetailView> createState() => _CategoryDetailViewState();
}

class _CategoryDetailViewState extends State<_CategoryDetailView> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (mounted) {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    }
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<CategoryDetailCubit>().loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoryDetailCubit, CategoryDetailState>(
      builder: (context, state) {
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: _bg,
          endDrawer: state is CategoryDetailLoaded
              ? ProductFilterDrawer(
                  initialMinPrice: state.minPrice,
                  initialMaxPrice: state.maxPrice,
                  initialSortBy: state.sortBy,
                  onApply: (min, max, sort) {
                    context.read<CategoryDetailCubit>().applyFilters(
                      minPrice: min,
                      maxPrice: max,
                      sortBy: sort,
                    );
                  },
                )
              : null,
          body: Stack(
            children: [
              CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  if (state is CategoryDetailLoading)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, __) => const ProductCardShimmer(),
                          childCount: 5,
                        ),
                      ),
                    ),

                  if (state is CategoryDetailError)
                    SliverFillRemaining(
                      child: Center(
                        child: Text(
                          state.message,
                          style: const TextStyle(color: _textMid),
                        ),
                      ),
                    ),

                  // sub cate
                  if (state is CategoryDetailLoaded) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: _buildSubCategories(context, state),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: Container(
                        color: _bg,
                        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                        child: Row(
                          children: [
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: '${state.products.length}',
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                      color: _textHigh,
                                    ),
                                  ),
                                  const TextSpan(
                                    text: ' sản phẩm',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: _textMid,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                _scaffoldKey.currentState?.openEndDrawer();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: _surfaceAlt,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: _border),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      LucideIcons.settings2,
                                      size: 14,
                                      color: _textMid,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Lọc',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: _textMid,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // prods
                    if (state.products.isEmpty && !state.isLoadingMore)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildEmptyState(context, state),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, index) {
                              if (index == state.products.length) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      color: _textLow,
                                    ),
                                  ),
                                );
                              }
                              return ProductCard(
                                product: state.products[index],
                              );
                            },
                            childCount:
                                state.products.length +
                                (state.isLoadingMore ? 1 : 0),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
              GlassmorphicHeader(
                scrollOffset: _scrollOffset,
                title: state is CategoryDetailLoaded
                    ? state.category.title
                    : '...',
                onBack: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubCategories(BuildContext context, CategoryDetailLoaded state) {
    final subCates = state.category.children;

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        physics: const BouncingScrollPhysics(),
        itemCount: subCates.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final item = isAll ? null : subCates[index - 1];
          final isSelected = isAll
              ? state.selectedSubCategory == null
              : state.selectedSubCategory?.id == item?.id;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              context.read<CategoryDetailCubit>().filterBySubCategory(item);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.05),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  isAll ? 'Tất cả' : item!.title,
                  style: TextStyle(
                    color: isSelected ? Colors.white : _textMid,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, CategoryDetailLoaded state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: _surfaceAlt,
                shape: BoxShape.circle,
                border: Border.all(color: _border),
              ),
              child: const Icon(
                LucideIcons.packageOpen,
                size: 52,
                color: _textLow,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Chưa có sản phẩm nào',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _textHigh,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Chúng tôi đang cập nhật hàng mới,\nfen quay lại sau nhé!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: _textMid, height: 1.6),
            ),
            if (state.selectedSubCategory != null) ...[
              const SizedBox(height: 28),
              GestureDetector(
                onTap: () => context
                    .read<CategoryDetailCubit>()
                    .filterBySubCategory(null),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: _accentSoft,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _accent.withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    'Xem tất cả sản phẩm',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _accent,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
