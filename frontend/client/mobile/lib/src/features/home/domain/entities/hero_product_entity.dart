import 'package:flutter/material.dart';

class HeroProductEntity {
  final String id;
  final String name;
  final String baseName;
  final String tagline;
  final String image;
  final String description;
  final Offset imageOffset;

  const HeroProductEntity({
    required this.id,
    required this.name,
    required this.baseName,
    required this.tagline,
    required this.image,
    required this.description,
    this.imageOffset = Offset.zero,
  });
}
