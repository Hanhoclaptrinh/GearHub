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

    String name = json['name'] as String? ?? '';
    String image = json['thumbnailUrl'] as String? ?? '';

    if (json['variants'] != null && (json['variants'] as List).isNotEmpty) {
      final variants = (json['variants'] as List);
      var firstVariant = variants.firstOrNull;
      for (final v in variants) {
        if (v['isActive'] == true || v['isActive'] == null) {
          firstVariant = v;
          break;
        }
      }

      if (firstVariant != null) {
        final attrs = firstVariant['attributes'] as Map<String, dynamic>? ?? {};
        final nonColorConfigs = <String>[];
        attrs.forEach((key, val) {
          final k = key.toLowerCase();
          if (!k.contains('màu') && !k.contains('color') && !k.contains('mau')) {
            nonColorConfigs.add(val.toString());
          }
        });
        if (nonColorConfigs.isNotEmpty) {
          name += ' ' + nonColorConfigs.join(' ');
        }

        if (firstVariant['imageUrl'] != null && firstVariant['imageUrl'].toString().isNotEmpty) {
          image = firstVariant['imageUrl'].toString();
        } else {
          for (final v in variants) {
            if (v['imageUrl'] != null && v['imageUrl'].toString().isNotEmpty) {
              image = v['imageUrl'].toString();
              break;
            }
          }
        }
      }
    }

    return HeroProductModel(
      id: json['id'],
      name: name,
      tagline: (apiTagline != null && apiTagline.isNotEmpty)
          ? apiTagline
          : _extractFirstSentence(description),
      image: image,
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
