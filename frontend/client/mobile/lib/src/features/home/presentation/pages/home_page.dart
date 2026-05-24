import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/src/core/di/injection.dart';
import 'package:mobile/src/core/theme/app_colors.dart';
import 'package:mobile/src/features/auth/presentation/state/auth_cubit.dart';
import 'package:mobile/src/features/auth/presentation/state/auth_state.dart';
import 'package:mobile/src/features/chat/presentation/widgets/concierge_entry_button.dart';
import 'package:mobile/src/shared/pages/search_page.dart';
import 'package:mobile/src/features/notifications/presentation/pages/notification_center_page.dart';
import 'package:mobile/src/shared/widgets/glassmorphic_header.dart';
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
          backgroundColor: AppColors.background,
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
        HeaderIconButton(
          icon: LucideIcons.bell,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationCenterPage()),
            );
          },
        ),
        const ConciergeEntryButton(compact: true),
      ],
    );
  }

  Widget _buildGreetingSection() {
    final hour = DateTime.now().hour;
    String greetingPrefix = 'Chào buổi sáng';
    String subtitle =
        'Khởi đầu ngày mới cùng những công nghệ được tuyển chọn dành riêng cho bạn.';

    if (hour >= 11 && hour < 15) {
      greetingPrefix = 'Chào buổi trưa';
      subtitle =
          'Những trải nghiệm flagship giúp không gian làm việc và giải trí trở nên liền mạch hơn.';
    } else if (hour >= 15 && hour < 19) {
      greetingPrefix = 'Chào buổi chiều';
      subtitle =
          'Tiếp tục nhịp sáng tạo với hệ sinh thái công nghệ mang đậm dấu ấn hiện đại.';
    } else if (hour >= 19 && hour < 23) {
      greetingPrefix = 'Chào buổi tối';
      subtitle =
          'Không gian công nghệ được thiết kế cho những khoảnh khắc thư giãn và tập trung nhất.';
    } else if (hour >= 23 || hour < 5) {
      greetingPrefix = 'Chúc ngủ ngon';
      subtitle =
          'Mọi ý tưởng lớn thường bắt đầu trong những khoảng lặng của màn đêm.';
    }

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        String name = 'Bạn';
        if (state is AuthAuthenticated) {
          name = state.user.fullName ?? 'Bạn';
        }

        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeOutCubic,
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 24 * (1.0 - value)),
                child: child,
              ),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(28, 64, 28, 48),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.45, 1.0],
                colors: [
                  AppColors.background.withValues(alpha: 0.0),
                  AppColors.background.withValues(alpha: 0.4),
                  AppColors.background,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greetingPrefix,',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                    color: Colors.white.withValues(alpha: 0.3),
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 6),

                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    letterSpacing: -1.2,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 20),

                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 280),
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.35),
                      fontWeight: FontWeight.w400,
                      height: 1.6,
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }
}
