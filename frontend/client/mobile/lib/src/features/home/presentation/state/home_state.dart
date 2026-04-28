import 'package:equatable/equatable.dart';
import '../../domain/entities/hero_product_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/brand_entity.dart';
import '../../../../shared/models/product_model.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final List<HeroProductEntity> featuredProducts;
  final List<CategoryEntity> topCategories;
  final List<BrandEntity> topBrands;
  final List<ProductModel> newArrivals;
  final List<ProductModel> topRatedProducts;
  final List<ProductModel> vaultProducts;

  const HomeLoaded({
    required this.featuredProducts,
    required this.topCategories,
    required this.topBrands,
    required this.newArrivals,
    required this.topRatedProducts,
    required this.vaultProducts,
  });

  HomeLoaded copyWith({
    List<HeroProductEntity>? featuredProducts,
    List<CategoryEntity>? topCategories,
    List<BrandEntity>? topBrands,
    List<ProductModel>? newArrivals,
    List<ProductModel>? topRatedProducts,
    List<ProductModel>? vaultProducts,
  }) {
    return HomeLoaded(
      featuredProducts: featuredProducts ?? this.featuredProducts,
      topCategories: topCategories ?? this.topCategories,
      topBrands: topBrands ?? this.topBrands,
      newArrivals: newArrivals ?? this.newArrivals,
      topRatedProducts: topRatedProducts ?? this.topRatedProducts,
      vaultProducts: vaultProducts ?? this.vaultProducts,
    );
  }

  @override
  List<Object?> get props => [
        featuredProducts,
        topCategories,
        topBrands,
        newArrivals,
        topRatedProducts,
        vaultProducts,
      ];
}

class HomeError extends HomeState {
  final String message;

  const HomeError({required this.message});

  @override
  List<Object> get props => [message];
}
