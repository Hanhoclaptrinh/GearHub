import 'package:flutter/material.dart';
import '../../domain/entities/hero_product_entity.dart';

class HeroProductModel extends HeroProductEntity {
  const HeroProductModel({
    required super.id,
    required super.name,
    required super.tagline,
    required super.image,
    required super.description,
    required super.gradient,
    super.imageOffset,
  });

  factory HeroProductModel.fromJson(Map<String, dynamic> json, {List<Color>? gradient}) {
    final String description = json['description'] ?? '';
    final String? apiTagline = json['tagline'];

    return HeroProductModel(
      id: json['id'],
      name: json['name'],
      tagline: (apiTagline != null && apiTagline.isNotEmpty)
          ? apiTagline
          : _extractFirstSentence(description),
      image: json['thumbnailUrl'] ?? '',
      description: description,
      gradient: gradient ?? [const Color(0xFFE2E8F0), const Color(0xFFCBD5E1)],
    );
  }

  HeroProductModel copyWith({List<Color>? gradient}) {
    return HeroProductModel(
      id: id,
      name: name,
      tagline: tagline,
      image: image,
      description: description,
      gradient: gradient ?? this.gradient,
      imageOffset: imageOffset,
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
