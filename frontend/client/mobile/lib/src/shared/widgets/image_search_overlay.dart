import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class ImageSearchOverlay extends StatelessWidget {
  final File imageFile;

  const ImageSearchOverlay({super.key, required this.imageFile});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black.withValues(alpha: 0.9),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFFDE047), width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                children: [
                  Image.file(
                    imageFile,
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                  Lottie.network(
                    'https://assets5.lottiefiles.com/packages/lf20_t9ucl9.json', // scanning animation mockup
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
          const Text(
            'ĐANG PHÂN TÍCH HÌNH ẢNH',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFFFDE047),
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Đang tìm kiếm sản phẩm tương đương...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
