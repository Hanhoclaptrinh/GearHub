import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/core/di/injection.dart';
import '../../../home/domain/entities/category_entity.dart';
import '../../../home/domain/repositories/home_repository.dart';
import '../state/category_detail_cubit.dart';
import '../state/category_detail_state.dart';
import '../widgets/category_product_card.dart';
import '../widgets/category_product_shimmer.dart';
import '../widgets/category_filter_drawer.dart';

class CategoryDetailPage extends StatelessWidget {
  final CategoryEntity category;

  const CategoryDetailPage({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          CategoryDetailCubit(repository: getIt<HomeRepository>())
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

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
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
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          endDrawer: state is CategoryDetailLoaded
              ? CategoryFilterDrawer(
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
          body: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                floating: true,
                pinned: true,
                elevation: 0,
                scrolledUnderElevation: 0,
                centerTitle: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  state is CategoryDetailLoaded ? state.category.title : 'Chi tiết',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(LucideIcons.messageCircle, color: Colors.black, size: 22),
                    onPressed: () {},
                  ),
                ],
              ),

              if (state is CategoryDetailLoading)
                SliverPadding(
                  padding: const EdgeInsets.all(12),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => const CategoryProductShimmer(),
                      childCount: 5,
                    ),
                  ),
                ),

              if (state is CategoryDetailError)
                SliverFillRemaining(
                  child: Center(child: Text(state.message)),
                ),

              if (state is CategoryDetailLoaded) ...[
                // sub-cate
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: _buildSubCategories(context, state),
                  ),
                ),

                SliverPersistentHeader(
                  pinned: true,
                  delegate: _StickySummaryDelegate(
                    child: Container(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tổng ${state.products.length}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                          IconButton(
                            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
                            icon: const Icon(LucideIcons.funnel, size: 20),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // prod list
                if (state.products.isEmpty && !state.isLoadingMore)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(context, state),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(12),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index == state.products.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(child: CircularProgressIndicator(color: Colors.black)),
                            );
                          }
                          return CategoryProductCard(product: state.products[index]);
                        },
                        childCount: state.products.length + (state.isLoadingMore ? 1 : 0),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, CategoryDetailLoaded state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              LucideIcons.packageOpen,
              size: 64,
              color: Colors.black.withValues(alpha: 0.2),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Chưa có sản phẩm nào',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Chúng tôi đang cập nhật hàng mới,\nfen quay lại sau nhé!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black.withValues(alpha: 0.5),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          if (state.selectedSubCategory != null)
            ElevatedButton(
              onPressed: () => context.read<CategoryDetailCubit>().filterBySubCategory(null),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text(
                'Xem tất cả sản phẩm',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubCategories(BuildContext context, CategoryDetailLoaded state) {
    final subCates = state.category.children;

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: subCates.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final item = isAll ? null : subCates[index - 1];
          final isSelected = isAll ? state.selectedSubCategory == null : state.selectedSubCategory?.id == item?.id;

          return GestureDetector(
            onTap: () => context.read<CategoryDetailCubit>().filterBySubCategory(item),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? Colors.transparent : Colors.white,
                border: Border.all(
                  color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFE5E5EA),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Text(
                  isAll ? 'Tất cả' : item!.title,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF3C3C43),
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StickySummaryDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _StickySummaryDelegate({required this.child});

  @override
  double get minExtent => 50;
  @override
  double get maxExtent => 50;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(_StickySummaryDelegate oldDelegate) => true;
}
