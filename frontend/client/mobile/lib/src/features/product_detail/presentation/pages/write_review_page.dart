import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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

  //animations
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bottom = MediaQuery.of(context).padding.bottom;
    final Color bgColor = theme.scaffoldBackgroundColor;
    final Color textHigh = cs.onSurface;
    final Color textMid = cs.onSurfaceVariant;
    final Color textLow = cs.onSurfaceVariant.withValues(alpha: 0.6);
    final Color borderCol = cs.outlineVariant;
    final Color fillCol = cs.surfaceContainerHighest;

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
              backgroundColor: bgColor,
              extendBodyBehindAppBar: true,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                systemOverlayStyle: isDark
                    ? SystemUiOverlayStyle.light
                    : SystemUiOverlayStyle.dark,
                elevation: 0,
                scrolledUnderElevation: 0,
                centerTitle: true,
                title: Text(
                  'Đánh giá sản phẩm',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textHigh,
                    letterSpacing: 0.2,
                  ),
                ),
                leading: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: IconButton(
                    icon: Icon(Icons.close_rounded, color: textMid),
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

                      //prod header
                      if (widget.productName != null ||
                          widget.productImage != null)
                        _buildProductHeader(context, textHigh, textMid),

                      const SizedBox(height: 32),

                      //star rating
                      _buildStarSection(context, textHigh, textMid, textLow),

                      const SizedBox(height: 28),

                      //cmt
                      _buildCommentSection(
                        context,
                        textHigh,
                        textMid,
                        borderCol,
                      ),

                      const SizedBox(height: 28),

                      //img upload
                      _buildImageSection(
                        context,
                        textHigh,
                        textMid,
                        textLow,
                        fillCol,
                        borderCol,
                      ),

                      const SizedBox(height: 28),

                      //anonymous switch
                      _buildAnonymousSection(context, textHigh, textMid),

                      SizedBox(height: 32 + bottom),
                    ],
                  ),
                ),
              ),

              bottomNavigationBar: _buildSubmitBar(
                context,
                isSubmitting,
                bottom,
                bgColor,
                borderCol,
                isDark,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductHeader(
    BuildContext context,
    Color textHigh,
    Color textMid,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (widget.productImage != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: widget.productImage!,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                color: Colors.transparent,
                child: const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (_, __, ___) => Container(
                width: 56,
                height: 56,
                color: Colors.transparent,
                child: Icon(LucideIcons.package, color: textMid, size: 24),
              ),
            ),
          ),
          const SizedBox(width: 14),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Đánh giá cho:',
                style: TextStyle(
                  fontSize: 11,
                  color: textMid,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.productName ?? 'Sản phẩm',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textHigh,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStarSection(
    BuildContext context,
    Color textHigh,
    Color textMid,
    Color textLow,
  ) {
    return Column(
      children: [
        Text(
          'Bạn thấy sản phẩm thế nào?',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: textHigh,
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
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.elasticOut,
                  scale: _selectedRating == i + 1 ? 1.25 : 1.0,
                  child: Icon(
                    filled ? Icons.star : Icons.star_outline,
                    size: 44,
                    color: filled ? const Color(0xFFFFB800) : textLow,
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
            child: Text(
              _selectedRating > 0 ? _ratingLabels[_selectedRating] : '',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: textMid,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommentSection(
    BuildContext context,
    Color textHigh,
    Color textMid,
    Color borderCol,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(LucideIcons.messageSquare, size: 16, color: textMid),
            const SizedBox(width: 12),
            Text(
              'Cảm nhận của bạn',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: textHigh,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _commentController,
          maxLines: null,
          minLines: 3,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            height: 1.6,
            color: textHigh,
          ),
          cursorColor: textHigh,
          decoration: InputDecoration(
            hintText:
                'Sản phẩm dùng tốt không? Đóng gói thế nào?\nChia sẻ trải nghiệm thực tế cho mọi người...',
            hintStyle: TextStyle(
              color: textMid.withValues(alpha: 0.6),
              fontSize: 14,
              height: 1.6,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            border: InputBorder.none,
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection(
    BuildContext context,
    Color textHigh,
    Color textMid,
    Color textLow,
    Color fillCol,
    Color borderCol,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(LucideIcons.image, size: 16, color: textMid),
                const SizedBox(width: 12),
                Text(
                  'Hình ảnh thực tế',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textHigh,
                  ),
                ),
              ],
            ),
            Text(
              '${_selectedImages.length}/5',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: textMid,
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
                      color: fillCol,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderCol),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_rounded, size: 24, color: textMid),
                        const SizedBox(height: 4),
                        Text(
                          'Thêm ảnh',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: textMid,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ..._selectedImages.asMap().entries.map((e) {
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
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
                              color: Colors.black.withValues(alpha: 0.6),
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

  Widget _buildAnonymousSection(
    BuildContext context,
    Color textHigh,
    Color textMid,
  ) {
    return Row(
      children: [
        Icon(LucideIcons.hatGlasses, size: 20, color: textMid),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Đánh giá ẩn danh',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textHigh,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Tên tài khoản sẽ hiển thị dạng ẩn danh',
                style: TextStyle(fontSize: 11, color: textMid),
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
          activeColor: const Color(0xFF6366F1),
        ),
      ],
    );
  }

  Widget _buildSubmitBar(
    BuildContext context,
    bool isSubmitting,
    double bottomPadding,
    Color bgColor,
    Color borderCol,
    bool isDark,
  ) {
    final canSubmit = _selectedRating > 0 && !isSubmitting;

    final Color disabledBg = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);
    final Color disabledText = isDark
        ? Colors.white.withValues(alpha: 0.3)
        : Colors.black.withValues(alpha: 0.3);

    final cs = Theme.of(context).colorScheme;

    final Color enabledBg = cs.primary;
    final Color enabledText = cs.onPrimary;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomPadding),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(top: BorderSide(color: borderCol, width: 1)),
      ),
      child: ElevatedButton(
        onPressed: canSubmit ? () => _submitReview(context) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canSubmit ? enabledBg : disabledBg,
          foregroundColor: canSubmit ? enabledText : disabledText,
          disabledBackgroundColor: disabledBg,
          disabledForegroundColor: disabledText,
          elevation: 0,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: isSubmitting
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(enabledText),
                ),
              )
            : Text(
                canSubmit ? 'Gửi đánh giá' : 'Chọn số sao trước nhé',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
      ),
    );
  }
}
