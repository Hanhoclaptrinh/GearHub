import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/features/profile/presentation/widgets/order_status_card.dart';
import 'package:mobile/src/features/profile/presentation/widgets/profile_header.dart';
import 'package:mobile/src/features/profile/presentation/widgets/profile_menu_card.dart';
import 'package:mobile/src/features/profile/presentation/widgets/profile_stats.dart';
import 'package:mobile/src/features/profile/presentation/widgets/ultilities_grid.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 48, 16, 0),
                child: Column(
                  children: [
                    const ProfileHeader(),
                    const SizedBox(height: 24),
                    const ProfileStats(),
                    const SizedBox(height: 24),
                    const OrderStatusCard(),
                    const SizedBox(height: 24),
                    const UtilitiesGrid(),
                    const SizedBox(height: 24),
                    ProfileMenuCard(
                      groupLabel: 'PREFERENCES',
                      items: [
                        ProfileMenuItem(
                          title: 'Dark Mode',
                          icon: LucideIcons.moon,
                          isToggle: true,
                          toggleValue: _isDarkMode,
                          onToggle: (val) {
                            setState(() => _isDarkMode = val);
                            HapticFeedback.selectionClick();
                          },
                        ),
                        ProfileMenuItem(
                          title: 'Address Book',
                          icon: LucideIcons.mapPin,
                          onTap: () {},
                        ),
                        ProfileMenuItem(
                          title: 'Payment Methods',
                          icon: LucideIcons.creditCard,
                          onTap: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildLogoutButton(),
                    const SizedBox(height: 24),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFFF4D4D).withValues(alpha: 0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF4D4D).withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const Text(
          'Sign Out',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFFFF4D4D),
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return const Column(
      children: [
        Text(
          'GearHub v1.0.0',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFFC0C0C0),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
