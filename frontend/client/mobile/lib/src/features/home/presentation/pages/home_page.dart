import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/src/core/di/injection.dart';
import 'package:mobile/src/features/auth/presentation/state/auth_cubit.dart';
import 'package:mobile/src/features/auth/presentation/state/auth_state.dart';
import 'package:mobile/src/features/home/presentation/pages/search_page.dart';
import '../widgets/hero_section.dart';
import '../widgets/recently_viewed_section.dart';
import '../widgets/top_categories_section.dart';
import '../widgets/new_arrivals_section.dart';
import '../widgets/top_rated_section.dart';
import '../widgets/vault_section.dart';
import '../widgets/top_brands_section.dart';
import '../state/home_cubit.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  bool _showTrangChu = false;
  Timer? _titleTimer;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _titleTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showTrangChu = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _titleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colorScheme = Theme.of(context).colorScheme;

    return BlocProvider(
      create: (context) => getIt<HomeCubit>()..loadHomeData(),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(context, colorScheme),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverToBoxAdapter(child: _buildGreetingSection()),
            ),
            const SliverToBoxAdapter(child: HeroSection()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const RecentlyViewedSection(),
                  const SizedBox(height: 32),
                  const TopCategoriesSection(),
                  const SizedBox(height: 32),
                  const NewArrivalsSection(),
                  const SizedBox(height: 32),
                  const TopBrandsSection(),
                  const SizedBox(height: 32),
                  const TopRatedSection(),
                  const SizedBox(height: 32),
                  const VaultSection(),
                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, ColorScheme colorScheme) {
    return SliverAppBar(
      floating: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      automaticallyImplyLeading: false,
      title: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: Text(
          _showTrangChu ? 'Trang chủ' : 'GearHub',
          key: ValueKey<bool>(_showTrangChu),
          style: const TextStyle(
            color: Color(0xFF0A0A0F),
            fontWeight: FontWeight.w900,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SearchPage()));
          },
          icon: const Icon(
            LucideIcons.search,
            size: 24,
            color: Color(0xFF0A0A0F),
          ),
        ),
        IconButton(
          onPressed: () {
            // Chat/message action
          },
          icon: const Icon(
            LucideIcons.messageSquare,
            size: 24,
            color: Color(0xFF0A0A0F),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildGreetingSection() {
    final hour = DateTime.now().hour;
    String greeting = 'Chào buổi sáng';
    if (hour >= 11 && hour < 15) {
      greeting = 'Chào buổi trưa';
    } else if (hour >= 15 && hour < 19) {
      greeting = 'Chào buổi chiều';
    } else if (hour >= 19 && hour < 23) {
      greeting = 'Chào buổi tối';
    } else if (hour >= 23 || hour < 5) {
      greeting = 'Chúc ngủ ngon';
    }

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        String name = 'bạn';
        if (state is AuthAuthenticated) {
          name = state.user.fullName ?? 'bạn';
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting $name',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0A0A0F),
                  letterSpacing: -0.8,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
