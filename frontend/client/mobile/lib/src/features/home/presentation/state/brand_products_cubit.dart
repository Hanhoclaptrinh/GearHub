import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/src/features/explore/domain/repositories/explore_repository.dart';
import 'package:mobile/src/features/home/domain/entities/brand_entity.dart';
import 'package:mobile/src/features/home/domain/entities/category_entity.dart';
import 'package:mobile/src/shared/models/product_model.dart';

abstract class BrandProductsState {}

class BrandProductsInitial extends BrandProductsState {}

class BrandProductsLoading extends BrandProductsState {}

class BrandProductsLoaded extends BrandProductsState {
  final List<ProductModel> allProducts;
  final List<ProductModel> displayProducts;
  final List<CategoryEntity> categories;
  final String? selectedCategoryId;

  BrandProductsLoaded({
    required this.allProducts,
    required this.displayProducts,
    required this.categories,
    this.selectedCategoryId,
  });

  BrandProductsLoaded copyWith({
    List<ProductModel>? allProducts,
    List<ProductModel>? displayProducts,
    List<CategoryEntity>? categories,
    String? selectedCategoryId,
  }) {
    return BrandProductsLoaded(
      allProducts: allProducts ?? this.allProducts,
      displayProducts: displayProducts ?? this.displayProducts,
      categories: categories ?? this.categories,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
    );
  }
}

class BrandProductsError extends BrandProductsState {
  final String message;
  BrandProductsError(this.message);
}

class BrandProductsCubit extends Cubit<BrandProductsState> {
  final ExploreRepository _exploreRepository;
  final BrandEntity brand;

  BrandProductsCubit(this._exploreRepository, this.brand) : super(BrandProductsInitial());

  Future<void> loadBrandData() async {
    emit(BrandProductsLoading());
    try {
      // fetch prod of brd
      final products = await _exploreRepository.getProducts(brandId: brand.id, limit: 100);
      
      // get unique cate from prod
      final Map<String, CategoryEntity> uniqueCatsMap = {};
      for (var p in products) {
        if (p.categoryId != null && p.categoryName != null) {
          uniqueCatsMap[p.categoryId!] = CategoryEntity(
            id: p.categoryId!,
            title: p.categoryName!,
            slug: p.categoryId!,
            totalSold: 0,
            iconUrl: '',
          );
        }
      }
      
      final List<CategoryEntity> categoriesList = uniqueCatsMap.values.toList();
      // show all first
      categoriesList.insert(0, const CategoryEntity(
        id: 'all', 
        title: 'Tất cả', 
        slug: 'all', 
        totalSold: 0,
        iconUrl: '',
      ));

      emit(BrandProductsLoaded(
        allProducts: products,
        displayProducts: products,
        categories: categoriesList,
        selectedCategoryId: 'all',
      ));
    } catch (e) {
      emit(BrandProductsError('Không thể kết nối với không gian thương hiệu: $e'));
    }
  }

  void filterByCategory(String categoryId) {
    if (state is! BrandProductsLoaded) return;
    final currentState = state as BrandProductsLoaded;
    
    final filtered = categoryId == 'all' 
      ? currentState.allProducts 
      : currentState.allProducts.where((p) => p.categoryId == categoryId).toList();
    
    emit(currentState.copyWith(
      displayProducts: filtered,
      selectedCategoryId: categoryId,
    ));
  }
}
