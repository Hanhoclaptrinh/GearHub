import 'package:flutter/material.dart';

class ProductModel {
  final String id;
  final String name;
  final String tagline;
  final double price;
  final String image;
  final List<Color> bgGradient;
  final String? tag;
  final int viewsCount;
  final double averageRating;
  final int reviewCount;

  const ProductModel({
    required this.id,
    required this.name,
    required this.tagline,
    required this.price,
    required this.image,
    this.bgGradient = const [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
    this.tag,
    this.viewsCount = 0,
    this.averageRating = 0.0,
    this.reviewCount = 0,
  });

  ProductModel copyWith({
    String? id,
    String? name,
    String? tagline,
    double? price,
    String? image,
    List<Color>? bgGradient,
    String? tag,
    int? viewsCount,
    double? averageRating,
    int? reviewCount,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      tagline: tagline ?? this.tagline,
      price: price ?? this.price,
      image: image ?? this.image,
      bgGradient: bgGradient ?? this.bgGradient,
      tag: tag ?? this.tag,
      viewsCount: viewsCount ?? this.viewsCount,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
    );
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    double price = 0.0;
    if (json['variants'] != null && (json['variants'] as List).isNotEmpty) {
      price =
          double.tryParse(json['variants'][0]['price']?.toString() ?? '0') ??
          0.0;
    } else if (json['price'] != null) {
      price = double.tryParse(json['price']?.toString() ?? '0') ?? 0.0;
    }

    final String description = json['description'] ?? '';
    final String? apiTagline = json['tagline'];

    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      tagline: (apiTagline != null && apiTagline.isNotEmpty)
          ? apiTagline
          : _extractFirstSentence(description),
      price: price,
      image: json['thumbnailUrl'] ?? '',
      tag: 'MỚI',
      viewsCount: json['viewsCount'] as int? ?? 0,
      averageRating: double.tryParse(json['averageRating']?.toString() ?? '0.0') ?? 0.0,
      reviewCount: json['reviewCount'] as int? ?? 0,
    );
  }

  static String _extractFirstSentence(String description) {
    if (description.isEmpty) return '';
    final String firstSentence = description.split(RegExp(r'[.!?]')).first;
    final String trimmed = firstSentence.trim();
    if (trimmed.length > 60) {
      return '${trimmed.substring(0, 57).trim()}...';
    }
    return trimmed;
  }
}
