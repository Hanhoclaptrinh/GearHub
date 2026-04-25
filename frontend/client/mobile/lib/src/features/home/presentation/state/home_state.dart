import 'package:equatable/equatable.dart';
import '../../domain/entities/hero_product_entity.dart';
import '../../domain/entities/category_entity.dart';

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

  const HomeLoaded({
    required this.featuredProducts,
    required this.topCategories,
  });

  @override
  List<Object> get props => [featuredProducts, topCategories];
}

class HomeError extends HomeState {
  final String message;

  const HomeError({required this.message});

  @override
  List<Object> get props => [message];
}
