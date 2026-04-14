import 'package:flutter/material.dart';

class HeroProduct {
  final String name;
  final String tagline;
  final String image;
  final List<Color> gradient;
  final Offset imageOffset;

  HeroProduct({
    required this.name,
    required this.tagline,
    required this.image,
    required this.gradient,
    this.imageOffset = Offset.zero,
  });
}
