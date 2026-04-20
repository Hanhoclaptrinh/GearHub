import 'package:flutter/material.dart';

class Product {
  final String id;
  final String name;
  final String tagline;
  final double price;
  final String image;
  final List<Color> bgGradient;
  final String? tag;

  const Product({
    required this.id,
    required this.name,
    required this.tagline,
    required this.price,
    required this.image,
    this.bgGradient = const [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
    this.tag,
  });
}
