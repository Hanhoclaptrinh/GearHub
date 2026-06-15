import 'package:flutter/material.dart';
import '../../domain/entities/hero_product_entity.dart';

class HeroProductModel extends HeroProductEntity {
  const HeroProductModel({
    required super.id,
    required super.name,
    required super.baseName,
    required super.brandName,
    required super.tagline,
    required super.image,
    required super.description,
    super.arUrl,
    super.imageOffset,
  });

  factory HeroProductModel.fromJson(Map<String, dynamic> json) {
    final String description = json['description'] ?? '';
    final String? apiTagline = json['tagline'];
    final String brandName = json['brand']?['name'] as String? ?? '';

    final String baseName = json['name'] as String? ?? '';
    String name = baseName;
    String image = json['thumbnailUrl'] as String? ?? '';

    String? arUrl;
    if (json['assets'] != null) {
      for (final a in (json['assets'] as List)) {
        final type = a['type']?.toString();
        if (type == 'GLB' || type == 'USDZ') {
          arUrl = a['url']?.toString();
          break;
        }
      }
    }

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
          if (!k.contains('màu') &&
              !k.contains('color') &&
              !k.contains('mau')) {
            nonColorConfigs.add(val.toString());
          }
        });
        if (nonColorConfigs.isNotEmpty) {
          name += ' ' + nonColorConfigs.join(' ');
        }

        if (firstVariant['imageUrl'] != null &&
            firstVariant['imageUrl'].toString().isNotEmpty) {
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
      baseName: baseName,
      brandName: brandName,
      tagline: (apiTagline != null && apiTagline.isNotEmpty)
          ? apiTagline
          : _extractFirstSentence(description),
      image: image,
      description: description,
      arUrl: arUrl,
    );
  }

  HeroProductModel copyWith({Offset? imageOffset}) {
    return HeroProductModel(
      id: id,
      name: name,
      baseName: baseName,
      brandName: brandName,
      tagline: tagline,
      image: image,
      description: description,
      arUrl: arUrl,
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
