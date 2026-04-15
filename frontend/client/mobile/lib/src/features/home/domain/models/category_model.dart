import 'package:flutter/material.dart';

class CategoryModel {
  final String title;
  final IconData icon;
  final String slug;

  const CategoryModel({
    required this.title,
    required this.icon,
    required this.slug,
  });
}
