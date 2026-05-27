import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/core/theme/app_colors.dart';
import 'package:mobile/src/features/product_review/presentation/state/review_cubit.dart';
import 'package:mobile/src/features/product_review/presentation/state/review_state.dart';
import '../../../../core/di/injection.dart';

const _ratingLabels = [
  '',
  'Tệ lắm',
  'Không tốt',
  'Bình thường',
  'Hài lòng',
  'Tuyệt vời!',
];

class WriteReviewPage extends StatefulWidget {
  final String productId;
  final String orderItemId;
  final String? productName;
  final String? productImage;

  const WriteReviewPage({
    super.key,
    required this.productId,
    required this.orderItemId,
    this.productName,
    this.productImage,
  });

  @override
  State<WriteReviewPage> createState() => _WriteReviewPageState();
}

class _WriteReviewPageState extends State<WriteReviewPage>
    with TickerProviderStateMixin {
  int _selectedRating = 0;
  bool _isAnonymous = false;
  final TextEditingController _commentController = TextEditingController();
  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  // animations
  late final AnimationController _labelAnim;
  late final Animation<double> _labelFade;
  late final AnimationController _pageAnim;

  @override
  void initState() {
    super.initState();
    _labelAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _labelFade = CurvedAnimation(parent: _labelAnim, curve: Curves.easeOut);

    _pageAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _labelAnim.dispose();
    _pageAnim.dispose();
    super.dispose();
  }

  void _onStarTap(int index) {
    HapticFeedback.selectionClick();
    setState(() => _selectedRating = index + 1);
    _labelAnim.forward(from: 0);
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          if (_selectedImages.length + images.length > 5) {
            final remaining = 5 - _selectedImages.length;
            _selectedImages.addAll(images.take(remaining));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Chỉ được chọn tối đa 5 ảnh')),
            );
          } else {
            _selectedImages.addAll(images);
          }
        });
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
    }
  }

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  // gui danh gia
  void _submitReview(BuildContext context) {
    if (_selectedRating == 0) return;
    HapticFeedback.mediumImpact();
    context.read<ReviewCubit>().createReview(
      orderItemId: widget.orderItemId,
      productId: widget.productId,
      rating: _selectedRating,
      comment: _commentController.text.trim(),
      imagePaths: _selectedImages.map((e) => e.path).toList(),
      isAnonymous: _isAnonymous,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return BlocProvider(
      create: (_) => getIt<ReviewCubit>(),
      child: BlocListener<ReviewCubit, ReviewState>(
        listener: (context, state) {
          if (state is ReviewActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.of(context).pop();
          } else if (state is ReviewError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: Builder(
          builder: (context) {
            final state = context.watch<ReviewCubit>().state;
            final isSubmitting = state is ReviewLoading;

            return Scaffold(
              backgroundColor: AppColors.background,
              extendBodyBehindAppBar: true,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                systemOverlayStyle: SystemUiOverlayStyle.light,
                elevation: 0,
                scrolledUnderElevation: 0,
                centerTitle: true,
                title: const Text(
                  'Đánh giá sản phẩm',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.2,
                  ),
                ),
                leading: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.slate400,
                    ),
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ),

              body: SafeArea(
                bottom: false,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),

                      // prod header
                      if (widget.productName != null ||
                          widget.productImage != null)
                        _buildProductHeader(),

                      const SizedBox(height: 32),

                      // star rating
                      _buildStarSection(),

                      const SizedBox(height: 28),

                      // img upload
                      _buildImageSection(),

                      const SizedBox(height: 28),

                      // anonymous switch
                      _buildAnonymousSection(),

                      const SizedBox(height: 28),

                      // cmt
                      _buildCommentSection(),

                      SizedBox(height: 32 + bottom),
                    ],
                  ),
                ),
              ),

              bottomNavigationBar: _buildSubmitBar(
                context,
                isSubmitting,
                bottom,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurfaceAlt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderCardStrong),
      ),
      child: Row(
        children: [
          if (widget.productImage != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: widget.productImage!,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  color: AppColors.cardSurfaceAltAlt,
                  child: const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 56,
                  height: 56,
                  color: AppColors.cardSurfaceAltAlt,
                  child: const Icon(
                    LucideIcons.package,
                    color: AppColors.textDim,
                    size: 24,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Đánh giá cho',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textDim,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.productName ?? 'Sản phẩm',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.cardSurfaceAlt,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderCardStrong),
      ),
      child: Column(
        children: [
          const Text(
            'Bạn thấy sản phẩm thế nào?',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.slate400,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final filled = i < _selectedRating;
              return GestureDetector(
                onTap: () => _onStarTap(i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.elasticOut,
                    scale: _selectedRating == i + 1 ? 1.25 : 1.0,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        filled ? Icons.star : Icons.star_outline,
                        size: 44,
                        color: filled
                            ? AppColors.accentGold
                            : AppColors.textDim,
                        shadows: filled
                            ? [
                                Shadow(
                                  color: AppColors.accentGold.withValues(
                                    alpha: 0.5,
                                  ),
                                  blurRadius: 12,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),

          AnimatedBuilder(
            animation: _labelFade,
            builder: (_, __) => AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: _selectedRating > 0 ? 1.0 : 0.0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentGold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _selectedRating > 0 ? _ratingLabels[_selectedRating] : '',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accentGold,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.brandIndigoSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                LucideIcons.image,
                size: 16,
                color: AppColors.brandIndigo,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hình ảnh thực tế',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Tối đa 5 ảnh',
                    style: TextStyle(fontSize: 12, color: AppColors.textDim),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.cardSurfaceAltAlt,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderCardStrong),
              ),
              child: Text(
                '${_selectedImages.length}/5',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.slate400,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        SizedBox(
          height: 96,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              if (_selectedImages.length < 5)
                GestureDetector(
                  onTap: _pickImages,
                  child: Container(
                    width: 96,
                    height: 96,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: AppColors.cardSurfaceAlt,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.brandIndigo.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.brandIndigoSoft,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            size: 20,
                            color: AppColors.brandIndigo,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Thêm ảnh',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.brandIndigo,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // preview img
              ..._selectedImages.asMap().entries.map((e) {
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.file(
                          File(e.value.path),
                          width: 96,
                          height: 96,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: GestureDetector(
                          onTap: () => _removeImage(e.key),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.champagneSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                LucideIcons.messageSquare,
                size: 16,
                color: AppColors.champagne,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Cảm nhận của bạn',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardSurfaceAlt,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderCardStrong),
          ),
          child: TextField(
            controller: _commentController,
            maxLines: 6,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.65,
              color: AppColors.textPrimary,
            ),
            cursorColor: AppColors.brandIndigo,
            decoration: const InputDecoration(
              hintText:
                  'Sản phẩm dùng tốt không? Đóng gói thế nào?\nChia sẻ trải nghiệm thực tế cho mọi người...',
              hintStyle: TextStyle(
                color: AppColors.textDim,
                fontSize: 14,
                height: 1.6,
              ),
              contentPadding: EdgeInsets.all(20),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitBar(
    BuildContext context,
    bool isSubmitting,
    double bottomPadding,
  ) {
    final canSubmit = _selectedRating > 0 && !isSubmitting;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomPadding),
      decoration: const BoxDecoration(
        color: AppColors.cardSurfaceAlt,
        border: Border(top: BorderSide(color: AppColors.borderCardStrong)),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        child: ElevatedButton(
          onPressed: canSubmit ? () => _submitReview(context) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: canSubmit
                ? Colors.white
                : AppColors.cardSurfaceAltAlt,
            foregroundColor: canSubmit ? Colors.black : AppColors.textDim,
            disabledBackgroundColor: AppColors.cardSurfaceAltAlt,
            disabledForegroundColor: AppColors.textDim,
            elevation: canSubmit ? 0 : 0,
            minimumSize: const Size(double.infinity, 58),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            shadowColor: Colors.white.withValues(alpha: 0.4),
          ),
          child: isSubmitting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      canSubmit ? 'Gửi đánh giá' : 'Chọn số sao trước nhé',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                        color: canSubmit ? Colors.black : AppColors.textDim,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildAnonymousSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardSurfaceAlt,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderCardStrong),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.hatGlasses,
            size: 20,
            color: AppColors.textDim,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đánh giá ẩn danh',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Tên tài khoản sẽ hiển thị dạng ẩn danh',
                  style: TextStyle(fontSize: 11, color: AppColors.textDim),
                ),
              ],
            ),
          ),
          Switch(
            value: _isAnonymous,
            onChanged: (val) {
              setState(() {
                _isAnonymous = val;
              });
            },
            activeColor: AppColors.brandIndigo,
          ),
        ],
      ),
    );
  }
}
