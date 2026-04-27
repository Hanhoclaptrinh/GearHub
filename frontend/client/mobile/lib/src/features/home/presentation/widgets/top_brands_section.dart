import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile/src/features/home/domain/entities/brand_entity.dart';
import 'package:mobile/src/shared/widgets/section_header.dart';
import '../state/home_cubit.dart';
import '../state/home_state.dart';

class TopBrandsSection extends StatelessWidget {
  const TopBrandsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        if (state is HomeLoaded) {
          final brands = state.topBrands;
          if (brands.isEmpty) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                title: 'Hệ sinh thái',
                actionText: 'Khám phá',
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 110,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  clipBehavior: Clip.none,
                  itemCount: brands.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 20),
                  itemBuilder: (context, index) =>
                      _BrandCard(brand: brands[index]),
                ),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _BrandCard extends StatefulWidget {
  final BrandEntity brand;
  const _BrandCard({required this.brand});

  @override
  State<_BrandCard> createState() => _BrandCardState();
}

class _BrandCardState extends State<_BrandCard>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        HapticFeedback.lightImpact();
        // chuyen toi trang brand tuong ung
        print('clicked ${widget.brand.name}');
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipOval(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white.withValues(alpha: 0.1),
                  child: widget.brand.logoUrl.isEmpty
                      ? _buildErrorLogo(colorScheme)
                      : SvgPicture.network(
                          widget.brand.logoUrl,
                          fit: BoxFit.contain,
                          placeholderBuilder: (_) => const Center(
                            child: SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.brand.name.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
                color: colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorLogo(ColorScheme colorScheme) {
    return Center(
      child: Text(
        widget.brand.name.isNotEmpty ? widget.brand.name.substring(0, 1) : '?',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: colorScheme.primary,
          fontSize: 24,
        ),
      ),
    );
  }
}
