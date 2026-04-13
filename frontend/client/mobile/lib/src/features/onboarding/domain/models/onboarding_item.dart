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
      title: 'Premium Gadgets',
      description: 'Explore our curated collection of high-end tech and electronics.',
      imageUrl: 'assets/images/onboarding1.png',
    ),
    OnboardingItem(
      title: 'Smart Trading',
      description: 'Buy and sell with AI-powered valuation and AR verification.',
      imageUrl: 'assets/images/onboarding1.png',
    ),
    OnboardingItem(
      title: 'Global Community',
      description: 'Connect with tech enthusiasts and find the gear you love.',
      imageUrl: 'assets/images/onboarding1.png',
    ),
  ];
}
