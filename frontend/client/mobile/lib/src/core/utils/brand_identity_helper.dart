import 'package:flutter/material.dart';

class BrandIdentity {
  final String quote;
  final String philosophy;
  final Color accent;

  const BrandIdentity({
    required this.quote,
    required this.philosophy,
    required this.accent,
  });
}

class BrandIdentityHelper {
  static const Color _defaultAccent = Color(0xFFFFCC00);

  static const Map<String, BrandIdentity> _universe = {
    'apple': BrandIdentity(
      quote: 'THINK DIFFERENT.',
      philosophy:
          'Sự giao thoa hoàn hảo giữa thẩm mỹ tối giản và hiệu năng đột phá.',
      accent: Color(0xFFFFFFFF),
    ),
    'samsung': BrandIdentity(
      quote: 'INSPIRE THE WORLD.',
      philosophy:
          'Không ngừng phá bỏ mọi giới hạn để mang đến những công nghệ tiên tiến nhất.',
      accent: Color(0xFF034EA2),
    ),
    'sony': BrandIdentity(
      quote: 'FILL THE WORLD WITH EMOTION.',
      philosophy:
          'Sử dụng sức mạnh của sự sáng tạo để lấp đầy thế giới bằng những cảm xúc thuần khiết.',
      accent: Color(0xFFFFFFFF),
    ),
    'razer': BrandIdentity(
      quote: 'FOR GAMERS. BY GAMERS.',
      philosophy:
          'Không chỉ là phần cứng, đó là một lối sống. Đỉnh cao của sự chính xác và tốc độ.',
      accent: Color(0xFF44D62C),
    ),
    'asus': BrandIdentity(
      quote: 'IN SEARCH OF INCREDIBLE.',
      philosophy:
          'Khát khao chinh phục những điều không thể qua từng bo mạch và linh kiện.',
      accent: Color(0xFF00539B),
    ),
    'rog': BrandIdentity(
      quote: 'FOR THOSE WHO DARE.',
      philosophy:
          'Đỉnh cao của phần cứng gaming, dành riêng cho những game thủ dũng cảm nhất.',
      accent: Color(0xFFEB0029),
    ),
    'logitech': BrandIdentity(
      quote: 'DEFY LOGIC.',
      philosophy:
          'Kỹ thuật chính xác Thụy Sĩ kết hợp cùng sự đổi mới không ngừng nghỉ.',
      accent: Color(0xFF00B2FF),
    ),
    'corsair': BrandIdentity(
      quote: 'PRECISION TO WIN.',
      philosophy:
          'Hệ sinh thái hoàn hảo cho những ai khao khát chiến thắng bằng sự bền bỉ.',
      accent: Color(0xFFF5C310),
    ),
    'msi': BrandIdentity(
      quote: 'TRUE GAMING.',
      philosophy:
          'DNA của chúng tôi là trò chơi. Mang đến sức mạnh thuần túy để làm chủ mọi trận chiến.',
      accent: Color(0xFFFF0000),
    ),
    'dell': BrandIdentity(
      quote: 'THE POWER TO DO MORE.',
      philosophy:
          'Cung cấp những công cụ mạnh mẽ và đáng tin cậy nhất để biến ý tưởng thành hiện thực.',
      accent: Color(0xFF007DB8),
    ),
    'alienware': BrandIdentity(
      quote: 'WE ARE NOT ALONE.',
      philosophy:
          'Thiết kế đến từ tương lai, hiệu năng vượt xa mọi quy luật vật lý thông thường.',
      accent: Color(0xFF00FFD8),
    ),
    'hp': BrandIdentity(
      quote: 'KEEP REINVENTING.',
      philosophy:
          'Không bao giờ dừng lại, không bao giờ hài lòng cho đến khi mọi thứ hoàn hảo.',
      accent: Color(0xFF0096D6),
    ),
    'lenovo': BrandIdentity(
      quote: 'FOR THOSE WHO DO.',
      philosophy:
          'Công nghệ thông minh hơn dành cho tất cả mọi người, thúc đẩy sự tiến bộ toàn cầu.',
      accent: Color(0xFFE22310),
    ),
    'keychron': BrandIdentity(
      quote: 'TYPING REIMAGINED.',
      philosophy:
          'Kết nối hoàn hảo giữa vẻ đẹp cổ điển và công nghệ hiện đại trên từng phím bấm.',
      accent: Color(0xFFFFD700),
    ),
    'steelseries': BrandIdentity(
      quote: 'FOR GLORY.',
      philosophy:
          'Thiết bị gaming chuyên nghiệp giúp bạn giành lấy vinh quang trong mọi giải đấu.',
      accent: Color(0xFFFF4E00),
    ),
    'hyperx': BrandIdentity(
      quote: 'WE\'RE ALL GAMERS.',
      philosophy:
          'Mang lại sự thoải mái và chất lượng âm thanh đỉnh cao cho mọi đối tượng game thủ.',
      accent: Color(0xFFFF0000),
    ),
    'nvidia': BrandIdentity(
      quote: 'POWERING THE FUTURE.',
      philosophy:
          'Dẫn đầu cuộc cách mạng đồ họa và trí tuệ nhân tạo, định hình tương lai số.',
      accent: Color(0xFF76B900),
    ),
    'intel': BrandIdentity(
      quote: 'DO SOMETHING WONDERFUL.',
      philosophy:
          'Sức mạnh xử lý tối thượng, nền tảng cho mọi sự đổi mới trong kỷ nguyên số.',
      accent: Color(0xFF0071C5),
    ),
    'amd': BrandIdentity(
      quote: 'TOGETHER WE ADVANCE.',
      philosophy:
          'Hiệu năng vượt trội và giá trị thực chất, phá bỏ mọi rào cản công nghệ.',
      accent: Color(0xFFED1C24),
    ),
    'microsoft': BrandIdentity(
      quote: 'BE WHAT\'S NEXT.',
      philosophy:
          'Trao quyền cho mọi cá nhân và tổ chức trên hành tinh để đạt được nhiều thành tựu hơn.',
      accent: Color(0xFF00A4EF),
    ),
    'google': BrandIdentity(
      quote: 'DO THE RIGHT THING.',
      philosophy:
          'Phổ cập thông tin và làm cho nó trở nên hữu ích, dễ tiếp cận trên toàn cầu.',
      accent: Color(0xFF4285F4),
    ),
    'akko': BrandIdentity(
      quote: 'TOUCH THE COLOR.',
      philosophy:
          'Đưa nghệ thuật vào bàn phím cơ bằng những bộ keycap đầy màu sắc và sáng tạo.',
      accent: Color(0xFFFFB7C5),
    ),
    'glorious': BrandIdentity(
      quote: 'BEYOND ASCENSION.',
      philosophy:
          'Phần cứng gaming cao cấp với mức giá dễ tiếp cận, dành cho những ai đam mê tùy biến.',
      accent: Color(0xFFFFCC00),
    ),
  };

  static BrandIdentity getIdentity(String name) {
    final n = name.toLowerCase();
    for (var entry in _universe.entries) {
      if (n.contains(entry.key)) {
        return entry.value;
      }
    }
    return const BrandIdentity(
      quote: 'PREMIUM EXPERIENCE.',
      philosophy:
          'Nơi công nghệ trở thành một tác phẩm nghệ thuật trong tay bạn.',
      accent: _defaultAccent,
    );
  }

  static Color getAdaptiveAccent(BuildContext context, Color baseColor) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    if (isDark) {
      if (baseColor.computeLuminance() < 0.15) {
        final hsl = HSLColor.fromColor(baseColor);
        if (hsl.saturation < 0.1) {
          return theme.colorScheme.primary;
        }
        return hsl.withLightness(0.65).toColor();
      }
      return baseColor;
    } else {
      if (baseColor.computeLuminance() > 0.5) {
        final hsl = HSLColor.fromColor(baseColor);
        if (hsl.saturation < 0.1) {
          return theme.colorScheme.primary;
        }
        return hsl.withLightness(0.4).toColor();
      }
      return baseColor;
    }
  }
}
