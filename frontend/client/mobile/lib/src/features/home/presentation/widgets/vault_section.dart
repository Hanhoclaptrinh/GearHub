import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/src/features/home/presentation/state/home_cubit.dart';
import 'package:mobile/src/features/home/presentation/state/home_state.dart';
import 'package:mobile/src/features/home/presentation/widgets/vault_card.dart';
import 'package:mobile/src/shared/models/product_model.dart';

class VaultSection extends StatelessWidget {
  const VaultSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        if (state is! HomeLoaded || state.vaultProducts.isEmpty) {
          return const SizedBox.shrink();
        }

        final products = state.vaultProducts;
        final screenHeight = MediaQuery.of(context).size.height;

        return Column(
          children: [
            const _ExhibitionHeader(),
            ...products.asMap().entries.map((entry) {
              return _ExhibitionSceneWrapper(
                index: entry.key,
                product: entry.value,
                screenHeight: screenHeight,
              );
            }),
            const SizedBox(height: 140),
          ],
        );
      },
    );
  }
}

class _ExhibitionSceneWrapper extends StatefulWidget {
  final int index;
  final ProductModel product;
  final double screenHeight;

  const _ExhibitionSceneWrapper({
    required this.index,
    required this.product,
    required this.screenHeight,
  });

  @override
  State<_ExhibitionSceneWrapper> createState() =>
      _ExhibitionSceneWrapperState();
}

class _ExhibitionSceneWrapperState extends State<_ExhibitionSceneWrapper> {
  late ScrollableState _scrollable;
  late final ValueNotifier<double> _progressNotifier;
  double _lastCalculatedProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _progressNotifier = ValueNotifier<double>(0.0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrollable = Scrollable.of(context);
    _scrollable.position.addListener(_updateProgress);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateProgress());
  }

  @override
  void dispose() {
    _scrollable.position.removeListener(_updateProgress);
    _progressNotifier.dispose();
    super.dispose();
  }

  void _updateProgress() {
    if (!mounted) return;
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final position = renderBox.localToGlobal(
      Offset.zero,
      ancestor: _scrollable.context.findRenderObject(),
    );
    final viewportHeight = _scrollable.position.viewportDimension;

    final widgetCenter = position.dy + (renderBox.size.height / 2);
    final viewportCenter = viewportHeight / 2;

    final newProgress = ((widgetCenter - viewportCenter) / viewportHeight)
        .clamp(-1.0, 1.0);

    if ((newProgress - _lastCalculatedProgress).abs() > 0.002) {
      _lastCalculatedProgress = newProgress;
      _progressNotifier.value = newProgress;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.screenHeight,
      child: RepaintBoundary(
        child: VaultCard(
          product: widget.product,
          index: widget.index,
          scrollProgressNotifier: _progressNotifier,
        ),
      ),
    );
  }
}

class _ExhibitionHeader extends StatelessWidget {
  const _ExhibitionHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(32, 80, 32, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'THE VAULT',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'KHOẢNG LẶNG\nCHO\nKIỆT TÁC',
            style: TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.w300,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Nơi những tạo tác tìm về sự tĩnh lặng nguyên bản.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 13,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
