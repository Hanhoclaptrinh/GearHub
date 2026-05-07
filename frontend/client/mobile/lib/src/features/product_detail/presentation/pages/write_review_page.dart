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

const _bg = Color(0xFF0A0A10);
const _surface = Color(0xFF14141E);
const _surfaceAlt = Color(0xFF1C1C28);
const _border = Color(0xFF2A2A38);
const _accent = Color(0xFFF59E0B);
const _accentSoft = Color(0x26F59E0B);
const _indigo = Color(0xFF6366F1);
const _indigoSoft = Color(0x1A6366F1);
const _textHigh = Color(0xFFF1F1F5);
const _textMid = Color(0xFF9191A8);
const _textLow = Color(0xFF4A4A62);

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
              backgroundColor: _bg,
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
                    color: _textHigh,
                    letterSpacing: 0.2,
                  ),
                ),
                leading: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: _textMid),
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
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
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
                  color: _surfaceAlt,
                  child: const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 56,
                  height: 56,
                  color: _surfaceAlt,
                  child: const Icon(
                    LucideIcons.package,
                    color: _textLow,
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
                    color: _textLow,
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
                    color: _textHigh,
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
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          const Text(
            'Bạn thấy sản phẩm thế nào?',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _textMid,
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
                        filled
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 44,
                        color: filled ? _accent : _textLow,
                        shadows: filled
                            ? [
                                Shadow(
                                  color: _accent.withValues(alpha: 0.5),
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
                  color: _accentSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _selectedRating > 0 ? _ratingLabels[_selectedRating] : '',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _accent,
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
                color: _indigoSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(LucideIcons.image, size: 16, color: _indigo),
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
                      color: _textHigh,
                    ),
                  ),
                  Text(
                    'Tối đa 5 ảnh',
                    style: TextStyle(fontSize: 12, color: _textLow),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _surfaceAlt,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _border),
              ),
              child: Text(
                '${_selectedImages.length}/5',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _textMid,
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
                      color: _surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: _indigo.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: _indigoSoft,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            size: 20,
                            color: _indigo,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Thêm ảnh',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _indigo,
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
                color: _accentSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                LucideIcons.messageSquare,
                size: 16,
                color: _accent,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Cảm nhận của bạn',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _textHigh,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border),
          ),
          child: TextField(
            controller: _commentController,
            maxLines: 6,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.65,
              color: _textHigh,
            ),
            cursorColor: _indigo,
            decoration: const InputDecoration(
              hintText:
                  'Sản phẩm dùng tốt không? Đóng gói thế nào?\nChia sẻ trải nghiệm thực tế cho mọi người...',
              hintStyle: TextStyle(color: _textLow, fontSize: 14, height: 1.6),
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
        color: _surface,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        child: ElevatedButton(
          onPressed: canSubmit ? () => _submitReview(context) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: canSubmit ? _accent : _surfaceAlt,
            foregroundColor: canSubmit ? Colors.black : _textLow,
            disabledBackgroundColor: _surfaceAlt,
            disabledForegroundColor: _textLow,
            elevation: canSubmit ? 0 : 0,
            minimumSize: const Size(double.infinity, 58),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            shadowColor: _accent.withValues(alpha: 0.4),
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
                    Icon(
                      LucideIcons.send,
                      size: 17,
                      color: canSubmit ? Colors.black : _textLow,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      canSubmit ? 'Gửi đánh giá' : 'Chọn số sao trước nhé',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                        color: canSubmit ? Colors.black : _textLow,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
