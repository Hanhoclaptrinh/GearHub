import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/core/di/injection.dart';
import 'package:mobile/src/features/chat/presentation/widgets/concierge_entry_button.dart';
import 'package:mobile/src/features/explore/domain/repositories/explore_repository.dart';
import 'package:mobile/src/shared/widgets/glassmorphic_header.dart';
import 'package:lottie/lottie.dart';
import '../../../home/domain/entities/category_entity.dart';
import '../state/category_detail_cubit.dart';
import '../state/category_detail_state.dart';
import '../../../../shared/widgets/product_card.dart';
import '../../../../shared/widgets/product_card_shimmer.dart';
import '../../../../shared/widgets/product_filter_drawer.dart';
import '../../../../shared/widgets/error_illustration_widget.dart';

class CategoryDetailPage extends StatelessWidget {
  final CategoryEntity category;

  const CategoryDetailPage({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          CategoryDetailCubit(repository: getIt<ExploreRepository>())
            ..loadCategoryProducts(category),
      child: _CategoryDetailView(category: category),
    );
  }
}

class _CategoryDetailView extends StatefulWidget {
  final CategoryEntity category;
  const _CategoryDetailView({required this.category});

  @override
  State<_CategoryDetailView> createState() => _CategoryDetailViewState();
}

class _CategoryDetailViewState extends State<_CategoryDetailView> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey _subCategoryKey = GlobalKey();
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!mounted) return;
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
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
              ? ProductFilterDrawer(
                  initialMinPrice: state.minPrice,
                  initialMaxPrice: state.maxPrice,
                  initialSortBy: state.sortBy,
                  maxProductPrice: state.products.isNotEmpty
                      ? state.products
                            .map((p) => p.maxPrice)
                            .reduce((a, b) => a > b ? a : b)
                      : null,
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
                        child: ErrorIllustrationWidget(
                          message: state.message,
                          onRetry: () => context
                              .read<CategoryDetailCubit>()
                              .loadCategoryProducts(widget.category),
                        ),
                      ),
                    ),

                  //sub cate
                  if (state is CategoryDetailLoaded) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: _buildSubCategories(context, state),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: Container(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Row(
                          children: [
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: '${state.products.length}',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' sản phẩm',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
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
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 24,
                                  ),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                );
                              }
                              return ProductCard(
                                product: state.products[index],
                                borderless: true,
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
                actions: const [ConciergeEntryButton(compact: true)],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubCategories(BuildContext context, CategoryDetailLoaded state) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final isAll = state.selectedSubCategory == null;
    final filterLabel = isAll
        ? 'TẤT CẢ PHÂN LOẠI'
        : state.selectedSubCategory!.title.toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          GestureDetector(
            key: _subCategoryKey,
            onTap: () => _showSubCategoryDialog(context, state),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                    ? cs.onSurface.withValues(alpha: 0.03)
                    : cs.onSurface.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.layoutGrid, size: 14, color: cs.onSurface),
                  const SizedBox(width: 8),
                  Text(
                    filterLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: cs.onSurface,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: cs.onSurface.withValues(alpha: 0.4),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              _scaffoldKey.currentState?.openEndDrawer();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                    ? cs.onSurface.withValues(alpha: 0.03)
                    : cs.onSurface.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.settings2,
                    size: 14,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Lọc',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSubCategoryDialog(
    BuildContext parentContext,
    CategoryDetailLoaded state,
  ) {
    final theme = Theme.of(parentContext);
    final cs = theme.colorScheme;
    final subCates = state.category.children;

    final RenderBox? renderBox =
        _subCategoryKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final screenWidth = MediaQuery.of(parentContext).size.width;

    showGeneralDialog(
      context: parentContext,
      barrierDismissible: true,
      barrierLabel: 'Dismiss SubCategory Filter',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) {
        final accentColor = theme.brightness == Brightness.dark
            ? const Color(0xFF818CF8)
            : const Color(0xFF4F46E5);

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                behavior: HitTestBehavior.opaque,
                child: FadeTransition(
                  opacity: anim1,
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: offset.dy + size.height + 8,
              left: offset.dx.clamp(16.0, screenWidth - 240.0 - 16.0),
              width: 240,
              child: FadeTransition(
                opacity: anim1,
                child: ScaleTransition(
                  scale: anim1,
                  alignment: Alignment.topLeft,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.brightness == Brightness.dark
                            ? const Color(0xFF1E1E2E).withValues(alpha: 0.9)
                            : Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: cs.onSurface.withValues(alpha: 0.08),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildDialogOption(
                            context: context,
                            label: 'TẤT CẢ PHÂN LOẠI',
                            icon: LucideIcons.layoutGrid,
                            isSelected: state.selectedSubCategory == null,
                            accentColor: accentColor,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              parentContext
                                  .read<CategoryDetailCubit>()
                                  .filterBySubCategory(null);
                              Navigator.pop(context);
                            },
                          ),
                          ...subCates.map((item) {
                            final isSelected =
                                state.selectedSubCategory?.id == item.id;
                            return _buildDialogOption(
                              context: context,
                              label: item.title.toUpperCase(),
                              icon: LucideIcons.tag,
                              isSelected: isSelected,
                              accentColor: accentColor,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                parentContext
                                    .read<CategoryDetailCubit>()
                                    .filterBySubCategory(item);
                                Navigator.pop(context);
                              },
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDialogOption({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return ListTile(
      onTap: onTap,
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Icon(
        icon,
        size: 14,
        color: isSelected ? accentColor : cs.onSurface.withValues(alpha: 0.6),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
          color: isSelected ? accentColor : cs.onSurface,
          letterSpacing: 0.5,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle_rounded, size: 14, color: accentColor)
          : null,
    );
  }

  Widget _buildEmptyState(BuildContext context, CategoryDetailLoaded state) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/emptybox.json',
              width: 200,
              height: 200,
              fit: BoxFit.contain,
              alignment: Alignment.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Danh mục hiện chưa có sản phẩm',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'GearHub đang cập nhật thêm sản phẩm mới cho nhóm này.\nBạn vui lòng quay lại sau nhé!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.8,
                ),
                height: 1.6,
              ),
            ),
            if (state.selectedSubCategory != null) ...[
              const SizedBox(height: 28),
              OutlinedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  context.read<CategoryDetailCubit>().filterBySubCategory(null);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                  side: BorderSide(
                    color: theme.colorScheme.primary.withValues(alpha: 0.4),
                    width: 1.2,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                ),
                child: const Text('Xem tất cả sản phẩm'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
