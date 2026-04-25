import 'package:flutter/material.dart';

class CategoryEntity {
  final String title;
  final IconData icon;
  final String slug;

  const CategoryEntity({
    required this.title,
    required this.icon,
    required this.slug,
  });
}
