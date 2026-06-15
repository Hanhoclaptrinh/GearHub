import 'package:flutter/material.dart';

class StyleOption {
  final String id;
  final String title;
  final String description;
  final List<Color> gradientColors;
  final String imageUrl;
  final String tag;

  const StyleOption({
    required this.id,
    required this.title,
    required this.description,
    required this.gradientColors,
    required this.imageUrl,
    required this.tag,
  });
}

const List<StyleOption> techStyleOptions = [
  StyleOption(
    id: 'hardcore_gaming',
    title: 'GAMING & PERFORMANCE',
    description: 'Chiến thần RGB. Hiệu năng tối đa, tản nhiệt hầm hố. Dành cho game thủ và lập trình viên cày hiệu năng.',
    gradientColors: [Color(0xFFF70FFF), Color(0xFF0AFFF9)],
    imageUrl: 'https://images.unsplash.com/photo-1542751371-adc38448a05e?q=80&w=400',
    tag: 'Gaming',
  ),
  StyleOption(
    id: 'pro_creator',
    title: 'STUDIO & CREATOR',
    description: 'Hệ sáng tạo. Màn hình chuẩn màu chuyên nghiệp, xử lý đồ họa mượt mà. Dành cho Designer, Editor.',
    gradientColors: [Color(0xFF8E9EAB), Color(0xFFEEF2F3)],
    imageUrl: 'https://images.unsplash.com/photo-1558655146-d09347e92766?q=80&w=400',
    tag: 'Creator',
  ),
  StyleOption(
    id: 'tech_minimalist',
    title: 'DESK SETUP & OFFICE',
    description: 'Hệ tinh tế. Thiết kế mỏng nhẹ, tối giản không gian, làm việc cơ động. Dành cho dân văn phòng, coder.',
    gradientColors: [Color(0xFF3A6073), Color(0xFF3A7BD5)],
    imageUrl: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?q=80&w=400',
    tag: 'Workspace',
  ),
  StyleOption(
    id: 'hardware_beast',
    title: 'PC BUILDER & HARDWARE',
    description: 'Hệ vọc vạch. Tự tay tối ưu cấu hình, linh kiện phần cứng độc chất, GPU khủng, tản nước custom.',
    gradientColors: [Color(0xFFD3A25D), Color(0xFF553C1B)],
    imageUrl: 'https://images.unsplash.com/photo-1587202372775-e229f172b9d7?q=80&w=400',
    tag: 'Hardware',
  ),
  StyleOption(
    id: 'smart_eco',
    title: 'SMART ECOSYSTEM',
    description: 'Hệ sinh thái thông minh. Điện thoại flagship, tablet, smarthome và các món đồ hi-tech phục vụ cuộc sống.',
    gradientColors: [Color(0xFF4ADE80), Color(0xFF22C55E)],
    imageUrl: 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?q=80&w=400',
    tag: 'Ecosystem',
  ),
  StyleOption(
    id: 'stealth_tech',
    title: 'STEALTH & ALL-BLACK',
    description: 'Cơn lốc bóng đêm. Đen nhám matte black u tối lì lợm, không phản quang, tập trung tối đa.',
    gradientColors: [Color(0xFF2C3E50), Color(0xFF000000)],
    imageUrl: 'https://images.unsplash.com/photo-1527443224154-c4a3942d3acf?q=80&w=400',
    tag: 'Stealth',
  ),
  StyleOption(
    id: 'retro_geek',
    title: 'RETRO TECH & GEEK',
    description: 'Hoài cổ cơ học. Bàn phím cơ clicky cổ điển, tone màu retro xám beige đậm chất kỹ thuật thập niên 90.',
    gradientColors: [Color(0xFF8B7E74), Color(0xFFC7B198)],
    imageUrl: 'https://images.unsplash.com/photo-1618384887929-16ec33fab9ef?q=80&w=400',
    tag: 'Retro',
  ),
];
