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
      imageUrl: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?q=80&w=1000&auto=format&fit=crop',
    ),
    OnboardingItem(
      title: 'Smart Trading',
      description: 'Buy and sell with AI-powered valuation and AR verification.',
      imageUrl: 'https://images.unsplash.com/photo-1546435770-a3e426bf472b?q=80&w=1000&auto=format&fit=crop',
    ),
    OnboardingItem(
      title: 'Global Community',
      description: 'Connect with tech enthusiasts and find the gear you love.',
      imageUrl: 'https://images.unsplash.com/photo-1593642632823-8f785ba67e45?q=80&w=1000&auto=format&fit=crop',
    ),
  ];
}
