import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/src/shared/widgets/section_header.dart';

class TopBrandsSection extends StatelessWidget {
  const TopBrandsSection({super.key});

  static const List<_Brand> _brands = [
    _Brand(name: 'Apple', letterColor: Color(0xFF1D1D1F)),
    _Brand(name: 'Razer', letterColor: Color(0xFF44D62C)),
    _Brand(name: 'Sony', letterColor: Color(0xFF000000)),
    _Brand(name: 'Logitech', letterColor: Color(0xFF00B8FC)),
    _Brand(name: 'ASUS', letterColor: Color(0xFF1E1E1E)),
    _Brand(name: 'Akko', letterColor: Color(0xFFFF6B35)),
    _Brand(name: 'Corsair', letterColor: Color(0xFFE2B030)),
    _Brand(name: 'HyperX', letterColor: Color(0xFFCC0000)),
    _Brand(name: 'SteelSeries', letterColor: Color(0xFFFF5200)),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Top Brands', actionText: 'See All'),
        const SizedBox(height: 20),
        SizedBox(
          height: 90,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            clipBehavior: Clip.none,
            itemCount: _brands.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return _BrandCard(brand: _brands[index]);
            },
          ),
        ),
      ],
    );
  }
}

class _Brand {
  final String name;
  final Color letterColor;

  const _Brand({required this.name, required this.letterColor});
}

class _BrandCard extends StatelessWidget {
  final _Brand brand;

  const _BrandCard({required this.brand});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        // chuyen huong toi trang top brands
      },
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: brand.letterColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                brand.name[0],
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: brand.letterColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              brand.name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
