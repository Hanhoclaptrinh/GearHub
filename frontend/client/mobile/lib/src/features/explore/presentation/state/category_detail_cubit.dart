import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/src/features/explore/domain/repositories/explore_repository.dart';
import 'package:mobile/src/core/utils/error_formatter.dart';
import '../../../home/domain/entities/category_entity.dart';
import 'category_detail_state.dart';

class CategoryDetailCubit extends Cubit<CategoryDetailState> {
  final ExploreRepository repository;

  CategoryDetailCubit({required this.repository})
    : super(CategoryDetailInitial());

  int _currentPage = 1;
  static const int _limit = 20;

  Future<void> loadCategoryProducts(CategoryEntity category) async {
    emit(CategoryDetailLoading());
    _currentPage = 1;

    try {
      final products = await repository.getProducts(
        categoryId: category.id,
        limit: _limit,
        page: _currentPage,
        sortBy: 'newest',
      );

      emit(
        CategoryDetailLoaded(
          products: products,
          category: category,
          hasReachedMax: products.length < _limit,
        ),
      );
    } catch (e) {
      emit(CategoryDetailError(message: ErrorFormatter.format(e, 'Không thể tải danh sách sản phẩm.')));
    }
  }

  Future<void> filterBySubCategory(CategoryEntity? subCategory) async {
    final currentState = state;
    if (currentState is! CategoryDetailLoaded) return;

    emit(
      currentState.copyWith(
        selectedSubCategory: () => subCategory,
        products: [],
        isLoadingMore: true,
      ),
    );

    _currentPage = 1;

    try {
      final products = await repository.getProducts(
        categoryId: subCategory?.id ?? currentState.category.id,
        limit: _limit,
        page: _currentPage,
        minPrice: currentState.minPrice,
        maxPrice: currentState.maxPrice,
        sortBy: currentState.sortBy,
      );

      emit(
        currentState.copyWith(
          selectedSubCategory: () => subCategory,
          products: products,
          isLoadingMore: false,
          hasReachedMax: products.length < _limit,
        ),
      );
    } catch (e) {
      emit(CategoryDetailError(message: ErrorFormatter.format(e, 'Không thể lọc sản phẩm.')));
    }
  }

  Future<void> applyFilters({
    double? minPrice,
    double? maxPrice,
    String? sortBy,
  }) async {
    final currentState = state;
    if (currentState is! CategoryDetailLoaded) return;

    emit(
      currentState.copyWith(
        minPrice: minPrice,
        maxPrice: maxPrice,
        sortBy: sortBy,
        products: [],
        isLoadingMore: true,
      ),
    );

    _currentPage = 1;

    try {
      final products = await repository.getProducts(
        categoryId:
            currentState.selectedSubCategory?.id ?? currentState.category.id,
        limit: _limit,
        page: _currentPage,
        minPrice: minPrice,
        maxPrice: maxPrice,
        sortBy: sortBy ?? currentState.sortBy,
      );

      emit(
        currentState.copyWith(
          minPrice: minPrice,
          maxPrice: maxPrice,
          sortBy: sortBy ?? currentState.sortBy,
          products: products,
          isLoadingMore: false,
          hasReachedMax: products.length < _limit,
        ),
      );
    } catch (e) {
      emit(CategoryDetailError(message: ErrorFormatter.format(e, 'Không thể lọc sản phẩm.')));
    }
  }

  Future<void> loadMore() async {
    final currentState = state;
    if (currentState is! CategoryDetailLoaded ||
        currentState.isLoadingMore ||
        currentState.hasReachedMax) {
      return;
    }

    emit(currentState.copyWith(isLoadingMore: true));
    _currentPage++;

    try {
      final products = await repository.getProducts(
        categoryId:
            currentState.selectedSubCategory?.id ?? currentState.category.id,
        limit: _limit,
        page: _currentPage,
        minPrice: currentState.minPrice,
        maxPrice: currentState.maxPrice,
        sortBy: currentState.sortBy,
      );

      if (products.isEmpty) {
        emit(currentState.copyWith(isLoadingMore: false, hasReachedMax: true));
      } else {
        emit(
          currentState.copyWith(
            products: List.of(currentState.products)..addAll(products),
            isLoadingMore: false,
            hasReachedMax: products.length < _limit,
          ),
        );
      }
    } catch (e) {
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }
}
