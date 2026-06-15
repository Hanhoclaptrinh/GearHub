import 'package:flutter/material.dart';

class BudgetTier {
  final String id;
  final String title;
  final String priceLabel;
  final String description;
  final int? minPrice;
  final int? maxPrice;
  final Color themeColor;
  final List<String> fallbackItems;

  const BudgetTier({
    required this.id,
    required this.title,
    required this.priceLabel,
    required this.description,
    this.minPrice,
    this.maxPrice,
    required this.themeColor,
    required this.fallbackItems,
  });
}

const List<BudgetTier> budgetOptions = [
  BudgetTier(
    id: 'budget_accessories',
    title: 'Phụ kiện & Phổ thông',
    priceLabel: '< 2 TRIỆU',
    description: 'Chuột văn phòng, bàn phím cơ bản, phụ kiện và lưu trữ.',
    minPrice: 0,
    maxPrice: 2000000,
    themeColor: Color(0xFF2DD4BF),
    fallbackItems: [
      'Chuột Silent',
      'Bàn phím cơ Entry',
      'Thẻ nhớ 128GB',
      'Pad chuột cỡ lớn',
    ],
  ),
  BudgetTier(
    id: 'entry_smart_tech',
    title: 'Thiết bị nhập môn',
    priceLabel: '2M - 10M',
    description:
        'Điện thoại thông minh cơ bản, màn hình văn phòng và thiết bị thông minh.',
    minPrice: 2000000,
    maxPrice: 10000000,
    themeColor: Color(0xFF60A5FA),
    fallbackItems: [
      'Màn hình 24" IPS',
      'Điện thoại phổ thông',
      'Loa Bluetooth',
      'CPU 4 nhân',
    ],
  ),
  BudgetTier(
    id: 'mid_performance',
    title: 'Hiệu năng tầm trung',
    priceLabel: '10M - 25M',
    description:
        'Laptop học tập, điện thoại cận cao cấp và linh kiện đồ họa tầm trung.',
    minPrice: 10000000,
    maxPrice: 25000000,
    themeColor: Color(0xFF818CF8),
    fallbackItems: [
      'Màn hình Gaming 144Hz',
      'Bàn phím Custom',
      'CPU tầm trung',
      'Chuột MX Master',
    ],
  ),
  BudgetTier(
    id: 'high_end_gaming',
    title: 'Chuyên nghiệp & Cận cao cấp',
    priceLabel: '25M - 50M',
    description:
        'Laptop gaming mạnh mẽ, điện thoại flagship và linh kiện đồ họa cao cấp.',
    minPrice: 25000000,
    maxPrice: 50000000,
    themeColor: Color(0xFFC084FC),
    fallbackItems: [
      'iPhone Flagship',
      'Laptop Gaming 16GB',
      'Card RTX 4070',
      'Ghế Ergonomic',
    ],
  ),
  BudgetTier(
    id: 'ultra_premium',
    title: 'Đỉnh cao & Độc bản',
    priceLabel: '> 50 TRIỆU',
    description:
        'Siêu máy tính chuyên dụng, laptop tối tân và thiết bị công nghệ đỉnh cao.',
    minPrice: 50000000,
    maxPrice: null,
    themeColor: Color(0xFFFB923C),
    fallbackItems: [
      'MacBook Pro M-Max',
      'Màn OLED 49" Cong',
      'Kính Apple Vision Pro',
      'Workstation Dual-CPU',
    ],
  ),
];
