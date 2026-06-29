class OnboardingItem {
  final String title;
  final String description;
  final String imageUrl;

  const OnboardingItem({
    required this.title,
    required this.description,
    required this.imageUrl,
  });
}

class OnboardingData {
  static const List<OnboardingItem> items = [
    OnboardingItem(
      title: 'Thiết Bị Cao Cấp',
      description:
          'Khám phá bộ sưu tập thiết bị công nghệ và gaming gear hàng đầu từ các thương hiệu lớn.',
      imageUrl: 'assets/images/onboarding1.png',
    ),
    OnboardingItem(
      title: 'Giao Dịch Thông Minh',
      description:
          'Mua bán an tâm hơn nhờ công nghệ định giá AI và ướm thử 3D AR thực tế ảo.',
      imageUrl: 'assets/images/onboarding2.png',
    ),
    OnboardingItem(
      title: 'Kết Nối Đam Mê',
      description: 'Tham gia cộng đồng yêu công nghệ, tìm kiếm và chia sẻ những bộ gear độc đáo.',
      imageUrl: 'assets/images/onboarding1.png',
    ),
  ];
}
