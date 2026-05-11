import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/src/core/di/injection.dart';
import 'package:mobile/src/features/auth/presentation/state/auth_cubit.dart';
import 'package:mobile/src/features/auth/presentation/state/auth_state.dart';
import 'package:mobile/src/shared/pages/search_page.dart';
import 'package:mobile/src/shared/widgets/glassmorphic_header.dart';
import '../widgets/hero_section.dart';
import '../widgets/recently_viewed_section.dart';
import '../widgets/top_categories_section.dart';
import '../widgets/new_arrivals_section.dart';
import '../widgets/top_rated_section.dart';
import '../widgets/vault_section.dart';
import '../widgets/top_brands_section.dart';
import '../state/home_cubit.dart';

const _bg = Color(0xFF07070A);
const _accent = Color(0xFFFDE047);
const _textMid = Color(0xFF9191A8);

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;
  bool _showTrangChu = false;
  Timer? _titleTimer;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });

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
    _scrollController.dispose();
    _titleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final topPadding = MediaQuery.of(context).padding.top;

    return BlocProvider(
      create: (context) => getIt<HomeCubit>()..loadHomeData(),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: _bg,
          body: Stack(
            children: [
              CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(child: HeroSection()),

                  SliverToBoxAdapter(child: _buildGreetingSection()),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(0, 16, 0, 60),
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

              _buildDockedHeader(topPadding),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDockedHeader(double topPadding) {
    return GlassmorphicHeader(
      scrollOffset: _scrollOffset,
      title: _showTrangChu ? 'Trang chủ' : 'GEARHUB',
      actions: [
        HeaderIconButton(
          icon: LucideIcons.search,
          onTap: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SearchPage()));
          },
        ),
        HeaderIconButton(icon: LucideIcons.bell, onTap: () {}),
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
        String name = 'Bạn';
        if (state is AuthAuthenticated) {
          name = state.user.fullName ?? 'Bạn';
        }
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black, _bg],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    greeting.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: _textMid,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Khám phá bộ sưu tập đẳng cấp mới nhất hôm nay.',
                style: TextStyle(
                  fontSize: 14,
                  color: _textMid,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
