import 'package:flutter/material.dart';

class HeroProductEntity {
  final String id;
  final String name;
  final String tagline;
  final String image;
  final String description;
  final List<Color> gradient;
  final Offset imageOffset;

  const HeroProductEntity({
    required this.id,
    required this.name,
    required this.tagline,
    required this.image,
    required this.description,
    required this.gradient,
    this.imageOffset = Offset.zero,
  });
}
