import 'package:equatable/equatable.dart';
import '../../../../shared/models/product_model.dart';
import '../../../home/domain/entities/category_entity.dart';

abstract class CategoryDetailState extends Equatable {
  const CategoryDetailState();

  @override
  List<Object?> get props => [];
}

class CategoryDetailInitial extends CategoryDetailState {}

class CategoryDetailLoading extends CategoryDetailState {}

class CategoryDetailLoaded extends CategoryDetailState {
  final List<ProductModel> products;
  final CategoryEntity category;
  final CategoryEntity? selectedSubCategory;
  final double? minPrice;
  final double? maxPrice;
  final String sortBy;
  final bool isLoadingMore;
  final bool hasReachedMax;

  const CategoryDetailLoaded({
    required this.products,
    required this.category,
    this.selectedSubCategory,
    this.minPrice,
    this.maxPrice,
    this.sortBy = 'newest',
    this.isLoadingMore = false,
    this.hasReachedMax = false,
  });

  CategoryDetailLoaded copyWith({
    List<ProductModel>? products,
    CategoryEntity? category,
    CategoryEntity? Function()? selectedSubCategory,
    double? Function()? minPrice,
    double? Function()? maxPrice,
    String? sortBy,
    bool? isLoadingMore,
    bool? hasReachedMax,
  }) {
    return CategoryDetailLoaded(
      products: products ?? this.products,
      category: category ?? this.category,
      selectedSubCategory: selectedSubCategory != null
          ? selectedSubCategory()
          : this.selectedSubCategory,
      minPrice: minPrice != null ? minPrice() : this.minPrice,
      maxPrice: maxPrice != null ? maxPrice() : this.maxPrice,
      sortBy: sortBy ?? this.sortBy,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }

  @override
  List<Object?> get props => [
    products,
    category,
    selectedSubCategory,
    minPrice,
    maxPrice,
    sortBy,
    isLoadingMore,
    hasReachedMax,
  ];
}

class CategoryDetailError extends CategoryDetailState {
  final String message;

  const CategoryDetailError({required this.message});

  @override
  List<Object?> get props => [message];
}
