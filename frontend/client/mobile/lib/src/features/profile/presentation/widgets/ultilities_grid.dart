import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/features/wishlist/presentation/pages/wishlist_page.dart';
import 'package:mobile/src/features/wishlist/presentation/state/wishlist_cubit.dart';
import 'package:mobile/src/features/wishlist/presentation/state/wishlist_state.dart';

const _surface = Color(0xFF14141E);
const _border = Color(0xFF2A2A38);
const _textHigh = Color(0xFFF1F1F5);
const _textLow = Color(0xFF4A4A62);

class UtilitiesGrid extends StatelessWidget {
  const UtilitiesGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Tiện ích',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: _textLow,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _buildGridCard(
                icon: LucideIcons.sparkles,
                title: 'Trợ lý AI',
                subtitle: 'Tìm kiếm thông minh',
                gradient: const [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                isPremium: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildGridCard(
                icon: LucideIcons.ticket,
                title: 'Vouchers',
                subtitle: '3 vouchers có sẵn',
                bgColor: _surface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildGridCard(
                icon: LucideIcons.shieldCheck,
                title: 'Bảo hành',
                subtitle: 'Thiết bị của tôi',
                bgColor: _surface,
                textColor: _textHigh,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildGridCard(
                icon: LucideIcons.headphones,
                title: 'Hỗ trợ',
                subtitle: 'Hỗ trợ 24/7',
                bgColor: _surface,
                textColor: _textHigh,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: BlocBuilder<WishlistCubit, WishlistState>(
                builder: (context, state) {
                  final favoriteCount = (state is WishlistLoaded) 
                      ? state.products.length 
                      : 0;
                  
                  return GestureDetector(
                    onTap: () {
                      try {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WishlistPage(),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Không thể mở danh sách yêu thích')),
                        );
                      }
                    },
                    child: _buildGridCard(
                      icon: LucideIcons.heart,
                      title: 'Yêu thích',
                      subtitle: '$favoriteCount sản phẩm',
                      gradient: const [Color(0xFFEC4899), Color(0xFFF43F5E)],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: SizedBox.shrink(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGridCard({
    required IconData icon,
    required String title,
    required String subtitle,
    List<Color>? gradient,
    Color? bgColor,
    Color textColor = Colors.white,
    bool isPremium = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        gradient: gradient != null
            ? LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: textColor, size: 24),
              if (isPremium)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'MỚI',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: textColor,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
