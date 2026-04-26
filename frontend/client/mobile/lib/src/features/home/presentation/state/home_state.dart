import 'package:equatable/equatable.dart';
import '../../domain/entities/hero_product_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../../../../shared/models/product_model.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final List<HeroProductEntity> featuredProducts;
  final List<CategoryEntity> topCategories;
  final List<ProductModel> newArrivals;

  const HomeLoaded({
    required this.featuredProducts,
    required this.topCategories,
    required this.newArrivals,
  });

  HomeLoaded copyWith({
    List<HeroProductEntity>? featuredProducts,
    List<CategoryEntity>? topCategories,
    List<ProductModel>? newArrivals,
  }) {
    return HomeLoaded(
      featuredProducts: featuredProducts ?? this.featuredProducts,
      topCategories: topCategories ?? this.topCategories,
      newArrivals: newArrivals ?? this.newArrivals,
    );
  }

  @override
  List<Object> get props => [featuredProducts, topCategories, newArrivals];
}

class HomeError extends HomeState {
  final String message;

  const HomeError({required this.message});

  @override
  List<Object> get props => [message];
}
