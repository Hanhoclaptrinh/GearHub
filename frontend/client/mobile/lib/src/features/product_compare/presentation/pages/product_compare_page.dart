import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/core/di/injection.dart';
import 'package:mobile/src/core/theme/app_colors.dart';
import 'package:mobile/src/core/utils/formatter_utils.dart';
import 'package:mobile/src/features/explore/domain/repositories/explore_repository.dart';
import 'package:mobile/src/features/product_compare/presentation/state/product_compare_cubit.dart';
import 'package:mobile/src/features/product_compare/presentation/state/product_compare_state.dart';
import 'package:mobile/src/shared/models/product_model.dart';
import 'package:mobile/src/shared/models/product_variant_model.dart';

class ProductComparePage extends StatelessWidget {
  final ProductModel initialProduct;
  final ProductVariantModel? initialVariant;

  const ProductComparePage({
    super.key,
    required this.initialProduct,
    this.initialVariant,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<ProductCompareCubit>()
        ..startWithProduct(initialProduct, initialVariant?.id),
      child: const ProductCompareView(),
    );
  }
}

class ProductCompareView extends StatelessWidget {
  const ProductCompareView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 22,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'So sánh sản phẩm',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          actions: [
            BlocBuilder<ProductCompareCubit, ProductCompareState>(
              builder: (context, state) {
                return IconButton(
                  onPressed: state.canAddMore
                      ? () => _openProductPicker(context)
                      : null,
                  icon: Icon(
                    LucideIcons.plus,
                    color: state.canAddMore ? Colors.white : Colors.white24,
                  ),
                );
              },
            ),
          ],
        ),
        body: BlocConsumer<ProductCompareCubit, ProductCompareState>(
          listenWhen: (previous, current) =>
              previous.errorMessage != current.errorMessage &&
              current.errorMessage != null,
          listener: (context, state) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          },
          builder: (context, state) {
            return Stack(
              children: [
                ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(0, 12, 0, 32),
                  children: [
                    _SelectedProductsStrip(state: state),
                    const SizedBox(height: 18),
                    if (!state.canShowComparison)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _NeedMoreProductsCard(
                          onAddPressed: state.canAddMore
                              ? () => _openProductPicker(context)
                              : null,
                        ),
                      )
                    else if (state.compareResult != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _CompareTable(state: state),
                      )
                    else
                      const _ComparePlaceholder(),
                  ],
                ),
                if (state.isLoading)
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(
                      minHeight: 2,
                      color: AppColors.brandIndigo,
                      backgroundColor: Colors.transparent,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  static void _openProductPicker(BuildContext context) {
    final compareCubit = context.read<ProductCompareCubit>();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ProductPickerSheet(compareCubit: compareCubit),
    );
  }
}

class _SelectedProductsStrip extends StatelessWidget {
  final ProductCompareState state;

  const _SelectedProductsStrip({required this.state});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 122,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: state.selectedProducts.length + (state.canAddMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          if (index >= state.selectedProducts.length) {
            return _AddProductTile(
              onTap: () => ProductCompareView._openProductPicker(context),
            );
          }

          final product = state.selectedProducts[index];
          return _SelectedProductTile(product: product);
        },
      ),
    );
  }
}

class _SelectedProductTile extends StatelessWidget {
  final ProductModel product;

  const _SelectedProductTile({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: product.image,
              width: 70,
              height: 84,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                width: 70,
                height: 84,
                color: AppColors.surface,
                child: Icon(
                  LucideIcons.image,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 12,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => context
                      .read<ProductCompareCubit>()
                      .removeProduct(product.id),
                  child: Icon(
                    LucideIcons.trash2,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddProductTile extends StatelessWidget {
  final VoidCallback onTap;

  const _AddProductTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 122,
        decoration: BoxDecoration(
          color: AppColors.brandIndigoSoft,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.brandIndigo.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              LucideIcons.plus,
              color: AppColors.brandIndigo,
              size: 26,
            ),
            const SizedBox(height: 10),
            Text(
              'Thêm',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NeedMoreProductsCard extends StatelessWidget {
  final VoidCallback? onAddPressed;

  const _NeedMoreProductsCard({required this.onAddPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.compare_arrows_rounded,
            color: Colors.white,
            size: 40,
          ),
          const SizedBox(height: 14),
          Text(
            'Cần ít nhất 2 sản phẩm',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Chọn thêm sản phẩm cùng nhóm để xem bảng so sánh.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onAddPressed,
            icon: const Icon(LucideIcons.plus, size: 18),
            label: const Text('Thêm sản phẩm'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.ctaPrimary,
              foregroundColor: AppColors.ctaPrimaryText,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparePlaceholder extends StatelessWidget {
  const _ComparePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 80),
      child: Center(
        child: CircularProgressIndicator(color: AppColors.brandIndigo),
      ),
    );
  }
}

class _CompareTable extends StatelessWidget {
  final ProductCompareState state;

  const _CompareTable({required this.state});

  @override
  Widget build(BuildContext context) {
    final result = state.compareResult!;
    final products = result.products;
    final rows = [
      _CompareRowData(
        label: 'Giá',
        values: {
          for (final product in products) product.id: formatVND(product.price),
        },
      ),
      _CompareRowData(
        label: 'Thương hiệu',
        values: {
          for (final product in products) product.id: product.brandName ?? '-',
        },
      ),
      _CompareRowData(
        label: 'Đánh giá',
        values: {
          for (final product in products)
            product.id:
                '${product.averageRating.toStringAsFixed(1)} (${product.reviewCount})',
        },
      ),
      ...result.specRows.map(
        (row) => _CompareRowData(label: row.label, values: row.values),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 14),
          child: Text(
            result.compareKey.name,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            color: Theme.of(context).colorScheme.surface,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProductHeaderRow(products: products),
                  ...rows.map((row) => _SpecRow(products: products, row: row)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProductHeaderRow extends StatelessWidget {
  final List<ProductModel> products;

  const _ProductHeaderRow({required this.products});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: 120, height: 178),
        ...products.map(
          (product) => Container(
            width: 190,
            height: 178,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: product.image,
                    width: 88,
                    height: 80,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      width: 88,
                      height: 80,
                      color: AppColors.surface,
                      child: Icon(
                        LucideIcons.image,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  product.name,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 12,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SpecRow extends StatelessWidget {
  final List<ProductModel> products;
  final _CompareRowData row;

  const _SpecRow({required this.products, required this.row});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 120,
            constraints: const BoxConstraints(minHeight: 66),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
            child: Text(
              row.label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 11,
                height: 1.3,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          ...products.map(
            (product) => Container(
              width: 190,
              constraints: const BoxConstraints(minHeight: 66),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ),
              child: Text(
                row.values[product.id]?.isNotEmpty == true
                    ? row.values[product.id]!
                    : '-',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 12,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompareRowData {
  final String label;
  final Map<String, String?> values;

  const _CompareRowData({required this.label, required this.values});
}

class _ProductPickerSheet extends StatefulWidget {
  final ProductCompareCubit compareCubit;

  const _ProductPickerSheet({required this.compareCubit});

  @override
  State<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<_ProductPickerSheet> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  bool _isLoading = false;
  List<ProductModel> _results = [];

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 320), () {
      _search(value.trim());
    });
  }

  Future<void> _search(String keyword) async {
    if (keyword.isEmpty) {
      setState(() => _results = []);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repository = getIt<ExploreRepository>();
      final firstProduct = widget.compareCubit.state.selectedProducts.isNotEmpty
          ? widget.compareCubit.state.selectedProducts.first
          : null;
      final categoryId = firstProduct?.categoryId;

      final items = await repository.getProducts(
        search: keyword,
        categoryId: categoryId,
        limit: 12,
      );
      if (!mounted) return;
      setState(() => _results = items);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 14,
          bottom: MediaQuery.of(context).viewInsets.bottom + 18,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.72,
          child: Column(
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _controller,
                autofocus: true,
                onChanged: _onChanged,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'Tìm sản phẩm để so sánh',
                  hintStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  prefixIcon: Icon(
                    LucideIcons.search,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 18,
                  ),
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const LinearProgressIndicator(
                  minHeight: 2,
                  color: AppColors.brandIndigo,
                  backgroundColor: Colors.transparent,
                ),
              Expanded(
                child: _results.isEmpty && !_isLoading
                    ? Center(
                        child: Text(
                          'Nhập tên sản phẩm để thêm vào so sánh.',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final product = _results[index];
                          return _PickerProductTile(
                            product: product,
                            onTap: () async {
                              final added = await widget.compareCubit
                                  .addProduct(product);
                              if (!context.mounted) return;
                              if (added) Navigator.pop(context);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickerProductTile extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const _PickerProductTile({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: product.image,
          width: 58,
          height: 58,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => Container(
            width: 58,
            height: 58,
            color: AppColors.surface,
            child: Icon(
              LucideIcons.image,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
      title: Text(
        product.name,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Text(
        formatVND(product.price),
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      trailing: Icon(
        LucideIcons.plus,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}
