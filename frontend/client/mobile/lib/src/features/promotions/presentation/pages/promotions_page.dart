import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/core/di/injection.dart';
import 'package:mobile/src/core/theme/app_colors.dart';
import 'package:mobile/src/core/theme/app_theme.dart';
import 'package:mobile/src/features/chat/presentation/widgets/concierge_entry_button.dart';
import 'package:mobile/src/features/promotions/data/models/flash_sale_product_model.dart';
import 'package:mobile/src/features/promotions/data/models/voucher_model.dart';
import 'package:mobile/src/features/promotions/presentation/state/promotions_cubit.dart';
import 'package:mobile/src/features/promotions/presentation/state/promotions_state.dart';
import 'package:mobile/src/features/promotions/presentation/widgets/section_header.dart';
import 'package:mobile/src/features/promotions/presentation/widgets/privilege_strip.dart';
import 'package:mobile/src/features/promotions/presentation/widgets/privilege_voucher_card.dart';
import 'package:mobile/src/features/promotions/presentation/widgets/flash_sale_product_card.dart';
import 'package:mobile/src/features/product_detail/data/datasources/product_detail_remote_datasource.dart';
import 'package:mobile/src/features/product_detail/presentation/pages/product_detail_page.dart';
import 'package:mobile/src/features/cart/presentation/state/cart_cubit.dart';
import 'package:mobile/src/shared/widgets/stock_limit_dialog.dart';
import 'package:mobile/src/shared/widgets/glassmorphic_header.dart';
import 'package:mobile/src/shared/widgets/error_illustration_widget.dart';

class PromotionsPage extends StatefulWidget {
  const PromotionsPage({super.key});

  @override
  State<PromotionsPage> createState() => _PromotionsPageState();
}

class _PromotionsPageState extends State<PromotionsPage>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late final TabController _tabController;
  double _scrollOffset = 0.0;
  String _selectedCategory = 'TẤT CẢ';
  int _selectedTimeSlot = 0; //các khung giờ flashsale

  final List<String> _voucherCategories = const [
    'TẤT CẢ',
    'ĐÃ LƯU',
    'GIAO HÀNG',
    'THIẾT BỊ',
    'THÀNH VIÊN',
  ];

  final ValueNotifier<Duration> _countdownNotifier = ValueNotifier<Duration>(
    const Duration(hours: 1, minutes: 24, seconds: 59),
  );
  StreamSubscription<void>? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController.addListener(_handleScroll);

    _countdownTimer = Stream<void>.periodic(const Duration(seconds: 1)).listen((
      _,
    ) {
      if (!mounted) return;
      final current = _countdownNotifier.value;
      if (current.inSeconds > 0) {
        _countdownNotifier.value = current - const Duration(seconds: 1);
      }
    });
  }

  void _handleScroll() {
    if (!mounted) return;
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    _tabController.dispose();
    _countdownNotifier.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  List<Map<String, dynamic>> _getTimeSlots(
    List<FlashSaleProductModel> flashSales,
  ) {
    if (flashSales.isEmpty) return [];

    final Map<String, FlashSaleProductModel> uniqueSlots = {};
    for (final fs in flashSales) {
      if (fs.startsAt.isEmpty) continue;
      final starts = DateTime.tryParse(fs.startsAt)?.toLocal();
      if (starts == null) continue;

      final timeStr = DateFormat('HH:mm').format(starts);

      if (!uniqueSlots.containsKey(timeStr)) {
        uniqueSlots[timeStr] = fs;
      }
    }

    final sortedKeys = uniqueSlots.keys.toList()
      ..sort((a, b) {
        final fsA = uniqueSlots[a]!;
        final fsB = uniqueSlots[b]!;
        return fsA.startsAt.compareTo(fsB.startsAt);
      });

    final now = DateTime.now();
    return sortedKeys.map((timeStr) {
      final fs = uniqueSlots[timeStr]!;
      final starts = DateTime.parse(fs.startsAt).toLocal();
      final expires = DateTime.parse(fs.expiresAt).toLocal();

      String status = 'ĐANG DIỄN RA';
      if (now.isBefore(starts)) {
        status = 'SẮP DIỄN RA';
      } else if (now.isAfter(expires)) {
        status = 'ĐÃ KẾT THÚC';
      }

      return {
        'time': timeStr,
        'status': status,
        'startsAt': starts,
        'expiresAt': expires,
      };
    }).toList();
  }

  void _updateCountdownForSlot(Map<String, dynamic> slot) {
    final now = DateTime.now();
    final startsAt = slot['startsAt'] as DateTime;
    final expiresAt = slot['expiresAt'] as DateTime;
    if (now.isBefore(startsAt)) {
      _countdownNotifier.value = startsAt.difference(now);
    } else if (now.isBefore(expiresAt)) {
      _countdownNotifier.value = expiresAt.difference(now);
    } else {
      _countdownNotifier.value = Duration.zero;
    }
  }

  Future<void> _handleAddToCart(
    BuildContext context,
    String productId, {
    String? targetVariantId,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.champagne),
      ),
    );

    try {
      final fullProduct = await getIt<ProductDetailRemoteDatasource>()
          .getProductDetail(productId);

      if (!context.mounted) return;
      Navigator.of(context).pop();

      if (fullProduct.variants.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sản phẩm không có biến thể hợp lệ')),
        );
        return;
      }

      final variant = targetVariantId != null
          ? fullProduct.variants.firstWhere(
              (v) => v.id == targetVariantId,
              orElse: () => fullProduct.variants.firstWhere(
                (v) => v.isActive,
                orElse: () => fullProduct.variants.first,
              ),
            )
          : fullProduct.variants.firstWhere(
              (v) => v.isActive && v.hasActiveFlashSale,
              orElse: () => fullProduct.variants.firstWhere(
                (v) => v.isActive,
                orElse: () => fullProduct.variants.first,
              ),
            );

      final cartCubit = context.read<CartCubit>();
      final cartState = cartCubit.state;
      final existingQty =
          cartState.cart?.items
              .where((i) => i.productVariant.id == variant.id)
              .firstOrNull
              ?.quantity ??
          0;

      int maxStock = variant.stock;
      if (variant.hasActiveFlashSale) {
        final remainingFlash =
            (variant.flashStockLimit ?? 0) - (variant.flashSoldCount ?? 0);
        maxStock = remainingFlash > 0 ? remainingFlash : 0;
      }

      if (existingQty + 1 > maxStock) {
        StockLimitDialog.show(
          context,
          stockCount: maxStock,
          currentQty: existingQty,
          message: variant.hasActiveFlashSale
              ? "Vượt giới hạn Flash Sale còn lại."
              : "Vượt giới hạn kho.",
        );
        return;
      }

      await cartCubit.addToCart(variant, fullProduct, 1);
      HapticFeedback.heavyImpact();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã thêm sản phẩm vào giỏ hàng'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể thêm sản phẩm vào giỏ hàng')),
        );
      }
    }
  }

  Future<void> _navigateToDetail(
    BuildContext context,
    String productId, {
    Map<String, String>? initialAttributes,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.champagne),
      ),
    );

    try {
      final pDetail = await getIt<ProductDetailRemoteDatasource>()
          .getProductDetail(productId);

      if (!context.mounted) return;
      Navigator.of(context).pop();

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProductDetailPage(
            product: pDetail,
            initialAttributes: initialAttributes,
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể tải chi tiết sản phẩm')),
        );
      }
    }
  }

  List<VoucherModel> _getFilteredVouchers(
    List<VoucherModel> vouchers,
    String category,
    Set<String> claimedIds,
  ) {
    if (category == 'ĐÃ LƯU') {
      return vouchers.where((v) => claimedIds.contains(v.id)).toList();
    }

    if (category == 'TẤT CẢ') return vouchers;

    final cat = category.toLowerCase();

    return vouchers.where((v) {
      final name = v.name.toLowerCase();
      final code = v.code.toLowerCase();

      if (cat == 'giao hàng') {
        return name.contains('ship') ||
            name.contains('vận chuyển') ||
            name.contains('giao hàng') ||
            code.contains('ship');
      }

      if (cat == 'thiết bị') {
        return name.contains('tech') ||
            name.contains('laptop') ||
            name.contains('tai nghe') ||
            name.contains('bàn phím') ||
            name.contains('chuột') ||
            name.contains('màn hình') ||
            code.contains('tech');
      }

      if (cat == 'thành viên') {
        return name.contains('vip') ||
            name.contains('member') ||
            name.contains('thành viên') ||
            name.contains('gold') ||
            name.contains('kim cương') ||
            code.contains('vip');
      }

      return true;
    }).toList();
  }

  Future<void> _handleClaim(BuildContext context, String voucherId) async {
    HapticFeedback.lightImpact();
    final theme = Theme.of(context);

    try {
      await context.read<PromotionsCubit>().claimVoucher(voucherId);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                LucideIcons.circleCheck,
                color: theme.colorScheme.success,
                size: 18,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Đã lưu ưu đãi vào ví của bạn.',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          backgroundColor: theme.brightness == Brightness.dark
              ? const Color(0xFF101A12)
              : const Color(0xFFE8F5E9),
          behavior: SnackBarBehavior.floating,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: theme.colorScheme.success.withValues(alpha: 0.25),
            ),
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      String errorMsg = 'Không thể lưu ưu đãi lúc này.';

      if (e is DioException && e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map && data['message'] != null) {
          errorMsg = data['message'].toString();
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                LucideIcons.circleAlert,
                color: theme.colorScheme.danger,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  errorMsg,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          backgroundColor: theme.brightness == Brightness.dark
              ? const Color(0xFF1B0F0F)
              : const Color(0xFFFFEBEB),
          behavior: SnackBarBehavior.floating,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: theme.colorScheme.danger.withValues(alpha: 0.25),
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocProvider(
      create: (_) => getIt<PromotionsCubit>()..loadData(),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Stack(
          children: [
            BlocBuilder<PromotionsCubit, PromotionsState>(
              builder: (context, state) {
                if (state is PromotionsInitial || state is PromotionsLoading) {
                  return _buildLoadingView(context);
                }

                if (state is PromotionsError) {
                  return _buildErrorView(context, state.message);
                }

                if (state is PromotionsLoaded) {
                  final filteredVouchers = _getFilteredVouchers(
                    state.vouchers,
                    _selectedCategory,
                    state.claimedIds,
                  );

                  final slots = _getTimeSlots(state.flashSales);
                  if (slots.isNotEmpty) {
                    if (_selectedTimeSlot >= slots.length) {
                      _selectedTimeSlot = 0;
                    }
                    final currentSlot = slots[_selectedTimeSlot];
                    final startsAt = currentSlot['startsAt'] as DateTime;
                    final expiresAt = currentSlot['expiresAt'] as DateTime;
                    final now = DateTime.now();
                    final targetDuration = now.isBefore(startsAt)
                        ? startsAt.difference(now)
                        : (now.isBefore(expiresAt)
                              ? expiresAt.difference(now)
                              : Duration.zero);

                    if ((_countdownNotifier.value - targetDuration)
                            .abs()
                            .inSeconds >
                        5) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _countdownNotifier.value = targetDuration;
                      });
                    }
                  }

                  final List<FlashSaleProductModel> slotProducts = [];
                  if (slots.isNotEmpty) {
                    final selectedSlot = slots[_selectedTimeSlot];
                    final slotStart = selectedSlot['startsAt'] as DateTime;
                    slotProducts.addAll(
                      state.flashSales.where((fs) {
                        final starts = DateTime.tryParse(
                          fs.startsAt,
                        )?.toLocal();
                        return starts != null &&
                            starts.isAtSameMomentAs(slotStart);
                      }),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => context.read<PromotionsCubit>().loadData(),
                    color: theme.colorScheme.primary,
                    backgroundColor: theme.colorScheme.surface,
                    child: NestedScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      headerSliverBuilder: (context, innerBoxIsScrolled) {
                        return [
                          const SliverToBoxAdapter(
                            child: SizedBox(height: 104),
                          ),
                          //tabbar
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              child: _buildSegmentedControl(theme),
                            ),
                          ),

                          const SliverToBoxAdapter(child: SizedBox(height: 12)),
                        ];
                      },
                      body: TabBarView(
                        controller: _tabController,
                        children: [
                          //tab0: flash sale
                          CustomScrollView(
                            physics: const BouncingScrollPhysics(),
                            slivers: [
                              if (slots.isEmpty)
                                _buildEmptyFlashSales(context)
                              else ...[
                                SliverToBoxAdapter(
                                  child: _buildTimeSlotsBar(theme, slots),
                                ),
                                const SliverToBoxAdapter(
                                  child: SizedBox(height: 16),
                                ),
                                SliverPadding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  sliver: SliverToBoxAdapter(
                                    child: _buildCountdownHeader(
                                      theme,
                                      slots[_selectedTimeSlot],
                                    ),
                                  ),
                                ),
                                const SliverToBoxAdapter(
                                  child: SizedBox(height: 16),
                                ),
                                _buildFlashSaleProductsList(
                                  theme,
                                  slotProducts,
                                  slots[_selectedTimeSlot]['status'] ==
                                      'SẮP DIỄN RA',
                                ),
                              ],
                              const SliverToBoxAdapter(
                                child: SizedBox(height: 120),
                              ),
                            ],
                          ),
                          //tab1: vouchers & privileges
                          CustomScrollView(
                            physics: const BouncingScrollPhysics(),
                            slivers: [
                              const SliverPadding(
                                padding: EdgeInsets.symmetric(horizontal: 20),
                                sliver: SliverToBoxAdapter(
                                  child: PromotionSectionHeader(
                                    eyebrow: 'MEMBER PRIVILEGES',
                                    title: 'Đặc quyền dành cho bạn',
                                    subtitle:
                                        'Các quyền lợi được tuyển chọn theo hạng thành viên.',
                                  ),
                                ),
                              ),
                              const SliverToBoxAdapter(
                                child: SizedBox(height: 14),
                              ),
                              const SliverToBoxAdapter(child: PrivilegeStrip()),
                              const SliverToBoxAdapter(
                                child: SizedBox(height: 32),
                              ),
                              SliverPadding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                sliver: SliverToBoxAdapter(
                                  child: PromotionSectionHeader(
                                    eyebrow: 'CURATED OFFERS',
                                    title: 'Ưu đãi hiện có',
                                    subtitle:
                                        'Lưu voucher phù hợp trước khi hoàn tất đơn hàng.',
                                    trailing: '${filteredVouchers.length}',
                                  ),
                                ),
                              ),
                              const SliverToBoxAdapter(
                                child: SizedBox(height: 14),
                              ),
                              SliverToBoxAdapter(
                                child: _buildVoucherCategoryBar(theme),
                              ),
                              const SliverToBoxAdapter(
                                child: SizedBox(height: 18),
                              ),
                              if (filteredVouchers.isEmpty)
                                _buildEmptyVouchers(context)
                              else
                                SliverPadding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  sliver: SliverList(
                                    delegate: SliverChildBuilderDelegate((
                                      context,
                                      i,
                                    ) {
                                      final voucher = filteredVouchers[i];

                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 14,
                                        ),
                                        child: PrivilegeVoucherCard(
                                          voucher: voucher,
                                          isClaiming: state.claimingIds
                                              .contains(voucher.id),
                                          isClaimed: state.claimedIds.contains(
                                            voucher.id,
                                          ),
                                          onClaim: () =>
                                              _handleClaim(context, voucher.id),
                                        ),
                                      );
                                    }, childCount: filteredVouchers.length),
                                  ),
                                ),
                              const SliverToBoxAdapter(
                                child: SizedBox(height: 120),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
            GlassmorphicHeader(
              scrollOffset: _scrollOffset,
              title: 'Ưu đãi',
              isTransparentAtTop: false,
              actions: const [ConciergeEntryButton(compact: true)],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedControl(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: isDark ? Colors.white : cs.primary,
        unselectedLabelColor: isDark ? Colors.white60 : Colors.black45,
        indicator: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.2,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.2,
        ),
        tabs: const [
          Tab(text: 'FLASH SALE'),
          Tab(text: 'ƯU ĐÃI & VOUCHER'),
        ],
      ),
    );
  }

  Widget _buildEmptyFlashSales(BuildContext context) {
    final theme = Theme.of(context);
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Center(
                  child: Icon(
                    LucideIcons.flame,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Chưa có Flash Sale nào diễn ra',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Các chương trình Flash Sale siêu hot sẽ sớm xuất hiện tại đây!',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 13,
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSlotsBar(ThemeData theme, List<Map<String, dynamic>> slots) {
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        itemCount: slots.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final isSelected = _selectedTimeSlot == index;
          final isDark = theme.brightness == Brightness.dark;
          final item = slots[index];

          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                _selectedTimeSlot = index;
                _updateCountdownForSlot(item);
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              width: 108,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : (isDark ? const Color(0xFF14141E) : Colors.white),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : (isDark
                            ? const Color(0xFF22222A)
                            : const Color(0xFFE2E8F0)),
                  width: 0.8,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.12,
                          ),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item['time']!,
                    style: TextStyle(
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    item['status']!,
                    style: TextStyle(
                      color: isSelected
                          ? theme.colorScheme.onPrimary.withValues(alpha: 0.7)
                          : theme.colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.5,
                            ),
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCountdownHeader(
    ThemeData theme,
    Map<String, dynamic>? currentSlot,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    final isUpcoming =
        currentSlot != null && currentSlot['status'] == 'SẮP DIỄN RA';

    double timeProgress = 0.0;
    if (currentSlot != null) {
      final now = DateTime.now();
      final startsAt = currentSlot['startsAt'] as DateTime;
      final expiresAt = currentSlot['expiresAt'] as DateTime;

      if (now.isAfter(startsAt) && now.isBefore(expiresAt)) {
        final totalSecs = expiresAt.difference(startsAt).inSeconds;
        final elapsedSecs = now.difference(startsAt).inSeconds;
        timeProgress = totalSecs > 0 ? (elapsedSecs / totalSecs) : 0.0;
      }
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14141E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF22222A) : const Color(0xFFE2E8F0),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isUpcoming
                              ? const Color(0xFFF97316)
                              : const Color(0xFFEF4444),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (isUpcoming
                                          ? const Color(0xFFF97316)
                                          : const Color(0xFFEF4444))
                                      .withValues(alpha: 0.4),
                              blurRadius: 4,
                              spreadRadius: 1.5,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isUpcoming ? 'SẮP DIỄN RA' : 'ĐANG DIỄN RA',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isUpcoming
                        ? 'Đăng ký nhận thông báo ngay'
                        : 'Số lượng ưu đãi có giới hạn',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.6,
                      ),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              ValueListenableBuilder<Duration>(
                valueListenable: _countdownNotifier,
                builder: (context, duration, _) {
                  final h = duration.inHours.toString().padLeft(2, '0');
                  final m = (duration.inMinutes % 60).toString().padLeft(
                    2,
                    '0',
                  );
                  final s = (duration.inSeconds % 60).toString().padLeft(
                    2,
                    '0',
                  );

                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.clock,
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.5,
                        ),
                        size: 13,
                      ),
                      const SizedBox(width: 6),
                      _buildTimeBox(h, theme),
                      _buildTimeDivider(),
                      _buildTimeBox(m, theme),
                      _buildTimeDivider(),
                      _buildTimeBox(s, theme),
                    ],
                  );
                },
              ),
            ],
          ),
          if (timeProgress > 0.0 && timeProgress < 1.0) ...[
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: 1.0 - timeProgress,
                    minHeight: 2.5,
                    backgroundColor: isDark
                        ? const Color(0xFF1E1E28)
                        : const Color(0xFFF1F5F9),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Thời gian ưu đãi còn lại',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.4,
                        ),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${((1.0 - timeProgress) * 100).round()}% thời gian',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.5,
                        ),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 1.5),
      child: Text(
        ':',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 10,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildTimeBox(String value, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C24) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark ? const Color(0xFF2C2C36) : const Color(0xFFE2E8F0),
          width: 0.8,
        ),
      ),
      child: Text(
        value,
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Widget _buildFlashSaleProductsList(
    ThemeData theme,
    List<FlashSaleProductModel> products,
    bool isUpcoming,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final p = products[index];
          final percent = p.productVariant.price > 0
              ? (((p.productVariant.price - p.flashPrice) /
                            p.productVariant.price) *
                        100)
                    .round()
              : 0;

          final isSoldOut = p.soldCount >= p.stockLimit;
          final progress = p.stockLimit > 0 ? p.soldCount / p.stockLimit : 0.0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: FlashSaleProductCard(
              product: p,
              percent: percent,
              isSoldOut: isSoldOut,
              progress: progress,
              isUpcoming: isUpcoming,
              onTap: (productId, initialAttributes) {
                HapticFeedback.lightImpact();
                _navigateToDetail(
                  context,
                  productId,
                  initialAttributes: initialAttributes,
                );
              },
              onAddToCart: (productId, variantId) {
                _handleAddToCart(
                  context,
                  productId,
                  targetVariantId: variantId,
                );
              },
              onNotifyMe: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Đã đăng ký nhận thông báo khi Flash Sale bắt đầu',
                    ),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
          );
        }, childCount: products.length),
      ),
    );
  }

  Widget _buildLoadingView(BuildContext context) {
    final theme = Theme.of(context);
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 104)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: Container(
              height: 210,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 26)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, index) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _buildSkeletonCard(context),
              ),
              childCount: 4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonCard(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 112,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 82,
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.035),
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 18),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _skeletonLine(context, width: 92, height: 10),
                  const SizedBox(height: 10),
                  _skeletonLine(context, width: 180, height: 14),
                  const SizedBox(height: 10),
                  _skeletonLine(context, width: 130, height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _skeletonLine(
    BuildContext context, {
    required double width,
    required double height,
  }) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, String message) {
    return ErrorIllustrationWidget(
      message: message,
      onRetry: () => context.read<PromotionsCubit>().loadData(),
    );
  }

  Widget _buildEmptyVouchers(BuildContext context) {
    final theme = Theme.of(context);
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Center(
                  child: Icon(
                    _selectedCategory == 'ĐÃ LƯU'
                        ? LucideIcons.bookmark
                        : LucideIcons.ticket,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _selectedCategory == 'ĐÃ LƯU'
                    ? 'Bạn chưa lưu ưu đãi nào'
                    : 'Chưa có ưu đãi phù hợp',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedCategory == 'ĐÃ LƯU'
                    ? 'Lưu các voucher phía dưới để chuẩn bị mua sắm tiết kiệm hơn.'
                    : 'Các đặc quyền mới sẽ được cập nhật trong thời gian tới.',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 13,
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoucherCategoryBar(ThemeData theme) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        itemCount: _voucherCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = _voucherCategories[index];
          final isSelected = _selectedCategory == cat;
          final isDark = theme.brightness == Brightness.dark;

          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                _selectedCategory = cat;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? theme.colorScheme.primary : Colors.black)
                    : (isDark ? const Color(0xFF14141E) : Colors.white),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : (isDark
                            ? const Color(0xFF22222A)
                            : const Color(0xFFE2E8F0)),
                  width: 0.8,
                ),
              ),
              child: Text(
                cat,
                style: TextStyle(
                  color: isSelected
                      ? (isDark ? Colors.black : Colors.white)
                      : theme.colorScheme.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
