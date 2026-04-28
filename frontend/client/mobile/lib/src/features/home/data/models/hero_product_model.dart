import 'package:flutter/material.dart';
import '../../domain/entities/hero_product_entity.dart';

class HeroProductModel extends HeroProductEntity {
  const HeroProductModel({
    required super.id,
    required super.name,
    required super.tagline,
    required super.image,
    required super.description,
    super.imageOffset,
  });

  factory HeroProductModel.fromJson(Map<String, dynamic> json) {
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
    );
  }

  HeroProductModel copyWith({Offset? imageOffset}) {
    return HeroProductModel(
      id: id,
      name: name,
      tagline: tagline,
      image: image,
      description: description,
      imageOffset: imageOffset ?? this.imageOffset,
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
