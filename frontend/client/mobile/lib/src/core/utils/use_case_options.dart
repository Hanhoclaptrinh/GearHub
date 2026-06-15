import 'package:flutter/material.dart';

class UseCaseOption {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final List<Color> gradientColors;
  final String tag;

  const UseCaseOption({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.gradientColors,
    required this.tag,
  });
}

const List<UseCaseOption> useCaseOptions = [
  UseCaseOption(
    id: 'gaming',
    title: 'Gaming & Esports',
    description:
        'PC cấu hình cao, màn hình tần số quét lớn, chuột phím cơ phản hồi siêu tốc.',
    icon: Icons.sports_esports_rounded,
    gradientColors: [Color(0xFFEC4899), Color(0xFFF43F5E)],
    tag: 'Gaming',
  ),
  UseCaseOption(
    id: 'workstation',
    title: 'Workstation & Coding',
    description:
        'Lập trình, phân tích dữ liệu, phím cơ gõ êm ái, màn hình bảo vệ mắt.',
    icon: Icons.code_rounded,
    gradientColors: [Color(0xFF3B82F6), Color(0xFF06B6D4)],
    tag: 'Workstation & Coding',
  ),
  UseCaseOption(
    id: 'creator',
    title: 'Creative & Studio',
    description:
        'Thiết kế đồ họa, dựng phim, làm nhạc, màn hình IPS/OLED chuẩn màu.',
    icon: Icons.palette_rounded,
    gradientColors: [Color(0xFFA855F7), Color(0xFF6366F1)],
    tag: 'Creative & Studio',
  ),
  UseCaseOption(
    id: 'office',
    title: 'Office & Productivity',
    description:
        'Văn phòng gọn nhẹ di động, chuột phím không dây yên tĩnh đa kết nối.',
    icon: Icons.business_center_rounded,
    gradientColors: [Color(0xFF10B981), Color(0xFF14B8A6)],
    tag: 'Office & Study',
  ),
  UseCaseOption(
    id: 'entertainment',
    title: 'Entertainment & Smart Life',
    description:
        'Xem phim 4K, âm thanh Bluetooth sống động, thiết bị smarthome tiện ích.',
    icon: Icons.settings_input_hdmi_rounded,
    gradientColors: [Color(0xFFF59E0B), Color(0xFFEab308)],
    tag: 'Entertainment',
  ),
];
