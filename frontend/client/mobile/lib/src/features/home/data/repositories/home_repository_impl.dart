import 'package:flutter/material.dart';
import '../datasources/home_remote_datasource.dart';
import '../models/hero_product_model.dart';
import '../../domain/repositories/home_repository.dart';
import '../../domain/entities/hero_product_entity.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDatasource remoteDatasource;

  HomeRepositoryImpl({required this.remoteDatasource});

  @override
  Future<List<HeroProductEntity>> getFeaturedProducts() async {
    try {
      final data = await remoteDatasource.getFeaturedProducts();
      
      final List<List<Color>> gradients = [
        [const Color(0xFFE0E7FF), const Color(0xFFC7D2FE)],
        [const Color(0xFFE2E8F0), const Color(0xFFCBD5E1)],
        [const Color(0xFFCCFBFE), const Color(0xFF90E0EF)],
        [const Color(0xFFF5F3FF), const Color(0xFFDDD6FE)],
        [const Color(0xFFF0FDFA), const Color(0xFFCCFBF1)],
      ];

      return data.asMap().entries.map((entry) {
        return HeroProductModel.fromJson(
          entry.value,
          gradients[entry.key % gradients.length],
        );
      }).toList();
    } catch (e) {
      rethrow;
    }
  }
}
