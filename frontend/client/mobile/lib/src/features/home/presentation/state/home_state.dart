import 'package:equatable/equatable.dart';
import '../../domain/entities/hero_product_entity.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final List<HeroProductEntity> featuredProducts;

  const HomeLoaded({required this.featuredProducts});

  @override
  List<Object> get props => [featuredProducts];
}

class HomeError extends HomeState {
  final String message;

  const HomeError({required this.message});

  @override
  List<Object> get props => [message];
}
