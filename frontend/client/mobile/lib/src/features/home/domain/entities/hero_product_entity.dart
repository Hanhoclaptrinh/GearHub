import 'package:flutter/material.dart';

class HeroProductEntity {
  final String id;
  final String name;
  final String baseName;
  final String brandName;
  final String tagline;
  final String image;
  final String description;
  final String? arUrl;
  final Offset imageOffset;

  const HeroProductEntity({
    required this.id,
    required this.name,
    required this.baseName,
    required this.brandName,
    required this.tagline,
    required this.image,
    required this.description,
    this.arUrl,
    this.imageOffset = Offset.zero,
  });
}
